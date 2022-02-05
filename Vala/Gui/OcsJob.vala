/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QBuffer>
//  #include <QJsonDocument>
//  #include <QJsonObject>
//  #include <QPair>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The Ocs_share_job class
@ingroup gui

Base class for jobs that talk to the OCS endpoints on th
All the communication logic is handled in this class.

All OCS jobs (e.g. sharing) should extend this class.
***********************************************************/
class Ocs_job : AbstractNetworkJob {

    const int OCS_SUCCESS_STATUS_CODE 100
    // Apparantly the v2.php URLs can return that
    const int OCS_SUCCESS_STATUS_CODE_V2 200
    // not modified when using  ETag
    const int OCS_NOT_MODIFIED_STATUS_CODE_V2 304
    

    protected Ocs_job (AccountPointer account);


    /***********************************************************
    Set the verb for the job

    @param verb currently supported PUT POST DELETE
    ***********************************************************/
    protected void verb (GLib.ByteArray verb);


    /***********************************************************
    Add a new parameter to the request.
    Depending on the verb this is GET or POST parameter

    @param name The name of the parameter
    @param value The value of the parameter
    ***********************************************************/
    protected void add_param (string name, string value);


    /***********************************************************
    Set the post parameters

    @param post_params list of pairs to add (url_encoded) to the body of the
    request
    ***********************************************************/
    protected void post_params (GLib.List<QPair<string, string>> post_params);


    /***********************************************************
    List of expected statuscodes for this request
    A warning will be printed to the debug log if a different status code is
    encountered

    @param code Accepted status code
    ***********************************************************/
    protected void add_pass_status_code (int code);


    /***********************************************************
    The base path for an Ocs_job is always the same. But it could be the case that
    certain operations need to append something to the URL.

    This function appends the common identifier. so <PATH>/<ID>
    ***********************************************************/
    protected void append_path (string identifier);


    /***********************************************************
    Parse the response and return the status code and the message of the
    reply (metadata)

    @param json The reply from OCS
    @param message The message that is set in the metadata
    @return The statuscode of the OCS response
    ***********************************************************/
    public static int get_json_return_code (QJsonDocument json, string message);


    /***********************************************************
    @brief Adds header to the request e.g. "If-None-Match"
    @param header_name a string with the header name
    @param value a string with the value
    ***********************************************************/
    public void add_raw_header (GLib.ByteArray header_name, GLib.ByteArray value);

protected slots:

    /***********************************************************
    Start the OCS request
    ***********************************************************/
    void on_start () override;

signals:

    /***********************************************************
    Result of the OCS request

    @param reply the reply
    ***********************************************************/
    void job_finished (QJsonDocument reply, int status_code);


    /***********************************************************
    The status code was not one of the expected (passing)
    status code for this command

    @param status_code The actual status code
    @param message The message provided by the server
    ***********************************************************/
    void ocs_error (int status_code, string message);


    /***********************************************************
    @brief etag_response_header_received - signal to report the ETag response header value
    from ocs api v2
    @param value - the ETag response header value
    @param status_code - the OCS status code : 100 (!) for on_success
    ***********************************************************/
    void etag_response_header_received (GLib.ByteArray value, int status_code);


    /***********************************************************
    ***********************************************************/
    private bool on_finished () override;

    /***********************************************************
    ***********************************************************/
    private 
    private GLib.ByteArray this.verb;
    private GLib.List<QPair<string, string>> this.params;
    private GLib.Vector<int> this.pass_status_codes;
    private QNetworkRequest this.request;
}

    Ocs_job.Ocs_job (AccountPointer account)
        : base (account, "") {
        this.pass_status_codes.append (OCS_SUCCESS_STATUS_CODE);
        this.pass_status_codes.append (OCS_SUCCESS_STATUS_CODE_V2);
        this.pass_status_codes.append (OCS_NOT_MODIFIED_STATUS_CODE_V2);
        ignore_credential_failure (true);
    }

    void Ocs_job.verb (GLib.ByteArray verb) {
        this.verb = verb;
    }

    void Ocs_job.add_param (string name, string value) {
        this.params.append (q_make_pair (name, value));
    }

    void Ocs_job.add_pass_status_code (int code) {
        this.pass_status_codes.append (code);
    }

    void Ocs_job.append_path (string identifier) {
        path (path () + '/' + identifier);
    }

    void Ocs_job.add_raw_header (GLib.ByteArray header_name, GLib.ByteArray value) {
        this.request.raw_header (header_name, value);
    }


    /***********************************************************
    ***********************************************************/
    static QUrlQuery percent_encode_query_items (
        const GLib.List<QPair<string, string>> items) {
        QUrlQuery result;
        // Note: QUrlQuery.query_items () does not fully percent encode
        // the query items, see #5042
        foreach (var item, items) {
            result.add_query_item (
                GLib.Uri.to_percent_encoding (item.first),
                GLib.Uri.to_percent_encoding (item.second));
        }
        return result;
    }

    void Ocs_job.on_start () {
        add_raw_header ("Ocs-APIREQUEST", "true");
        add_raw_header ("Content-Type", "application/x-www-form-urlencoded");

        var buffer = new QBuffer;

        QUrlQuery query_items;
        if (this.verb == "GET") {
            query_items = percent_encode_query_items (this.params);
        } else if (this.verb == "POST" || this.verb == "PUT") {
            // Url encode the this.post_params and put them in a buffer.
            GLib.ByteArray post_data;
            Q_FOREACH (var tmp, this.params) {
                if (!post_data.is_empty ()) {
                    post_data.append ("&");
                }
                post_data.append (GLib.Uri.to_percent_encoding (tmp.first));
                post_data.append ("=");
                post_data.append (GLib.Uri.to_percent_encoding (tmp.second));
            }
            buffer.data (post_data);
        }
        query_items.add_query_item (QLatin1String ("format"), QLatin1String ("json"));
        GLib.Uri url = Utility.concat_url_path (account ().url (), path (), query_items);
        send_request (this.verb, url, this.request, buffer);
        AbstractNetworkJob.on_start ();
    }

    bool Ocs_job.on_finished () {
        const GLib.ByteArray reply_data = reply ().read_all ();

        QJsonParseError error;
        string message;
        int status_code = 0;
        var json = QJsonDocument.from_json (reply_data, error);

        // when it is null we might have a 304 so get status code from reply () and gives a warning...
        if (error.error != QJsonParseError.NoError) {
            status_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
            GLib.warn (lc_ocs) << "Could not parse reply to"
                             << this.verb
                             << Utility.concat_url_path (account ().url (), path ())
                             << this.params
                             << error.error_string ()
                             << ":" << reply_data;
        } else {
            status_code  = get_json_return_code (json, message);
        }

        //... then it checks for the status_code
        if (!this.pass_status_codes.contains (status_code)) {
            GLib.warn (lc_ocs) << "Reply to"
                             << this.verb
                             << Utility.concat_url_path (account ().url (), path ())
                             << this.params
                             << "has unexpected status code:" << status_code << reply_data;
            /* emit */ ocs_error (status_code, message);

        } else {
            // save new ETag value
            if (reply ().raw_header_list ().contains ("ETag"))
                /* emit */ etag_response_header_received (reply ().raw_header ("ETag"), status_code);

            /* emit */ job_finished (json, status_code);
        }
        return true;
    }

    int Ocs_job.get_json_return_code (QJsonDocument json, string message) {
        //TODO proper checking
        var meta = json.object ().value ("ocs").to_object ().value ("meta").to_object ();
        int code = meta.value ("statuscode").to_int ();
        message = meta.value ("message").to_string ();

        return code;
    }
    }
    