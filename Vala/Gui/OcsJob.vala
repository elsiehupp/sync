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
@brief The OcsShareJob class
@ingroup gui

Base class for jobs that talk to the OCS endpoints on th
All the communication logic is handled in this class.

All OCS jobs (e.g. sharing) should extend this class.
***********************************************************/
public class OcsJob : AbstractNetworkJob {

    private const int OCS_SUCCESS_STATUS_CODE = 100;

    /***********************************************************
    Apparantly the v2.php URLs can return that
    ***********************************************************/
    private const int OCS_SUCCESS_STATUS_CODE_V2 = 200;

    /***********************************************************
    Not modified when using ETag
    ***********************************************************/
    private const int OCS_NOT_MODIFIED_STATUS_CODE_V2 = 304;

    /***********************************************************
    Set the verb for the job

    @param verb currently supported PUT POST DELETE
    ***********************************************************/
    string verb { private get; protected set; }

    private GLib.List<QPair<string, string>> params;
    private GLib.List<int> pass_status_codes;
    private Soup.Request request;


    /***********************************************************
    Result of the OCS request

    @param reply the reply
    ***********************************************************/
    internal signal void signal_job_finished (QJsonDocument reply, int status_code);
    

    /***********************************************************
    ***********************************************************/
    protected OcsJob (unowned Account account) {
        base (account, "");
        this.pass_status_codes.append (OCS_SUCCESS_STATUS_CODE);
        this.pass_status_codes.append (OCS_SUCCESS_STATUS_CODE_V2);
        this.pass_status_codes.append (OCS_NOT_MODIFIED_STATUS_CODE_V2);
        ignore_credential_failure (true);
    }


    /***********************************************************
    Add a new parameter to the request.
    Depending on the verb this is GET or POST parameter

    @param name The name of the parameter
    @param value The value of the parameter
    ***********************************************************/
    protected void add_param (string name, string value) {
        this.params.append (q_make_pair (name, value));
    }


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
    protected void add_pass_status_code (int code) {
        this.pass_status_codes.append (code);
    }


    /***********************************************************
    The base path for an OcsJob is always the same. But it could be the case that
    certain operations need to append something to the URL.

    This function appends the common identifier. so <PATH>/<ID>
    ***********************************************************/
    protected void append_path (string identifier) {
        path (path () + '/' + identifier);
    }


    /***********************************************************
    Parse the response and return the status code and the
    message of the reply (metadata)

    @param json The reply from OCS
    @param message The message that is set in the metadata
    @return The statuscode of the OCS response
    ***********************************************************/
    public static int json_return_code (QJsonDocument json, string message) {
        // TODO proper checking
        var meta = json.object ().value ("ocs").to_object ().value ("meta").to_object ();
        int code = meta.value ("statuscode").to_int ();
        message = meta.value ("message").to_string ();

        return code;
    }


    /***********************************************************
    @brief Adds header to the request e.g. "If-None-Match"
    @param header_name a string with the header name
    @param value a string with the value
    ***********************************************************/
    public void add_raw_header (string header_name, string value) {
        this.request.raw_header (header_name, value);
    }


    /***********************************************************
    Start the OCS request
    ***********************************************************/
    protected override void on_signal_start () {
        add_raw_header ("Ocs-APIREQUEST", "true");
        add_raw_header ("Content-Type", "application/x-www-form-urlencoded");

        var buffer = new QBuffer ();

        QUrlQuery query_items;
        if (this.verb == "GET") {
            query_items = percent_encode_query_items (this.params);
        } else if (this.verb == "POST" || this.verb == "PUT") {
            // Url encode the this.post_params and put them in a buffer.
            string post_data;
            foreach (var tmp in this.params) {
                if (!post_data == "") {
                    post_data.append ("&");
                }
                post_data.append (GLib.Uri.to_percent_encoding (tmp.first));
                post_data.append ("=");
                post_data.append (GLib.Uri.to_percent_encoding (tmp.second));
            }
            buffer.data (post_data);
        }
        query_items.add_query_item ("format", "json");
        GLib.Uri url = Utility.concat_url_path (account.url, path (), query_items);
        send_request (this.verb, url, this.request, buffer);
        AbstractNetworkJob.on_signal_start ();
    }


    /***********************************************************
    The status code was not one of the expected (passing)
    status code for this command

    @param status_code The actual status code
    @param message The message provided by the server
    ***********************************************************/
    private void ocs_error (int status_code, string message);


    /***********************************************************
    @brief etag_response_header_received - signal to report the ETag response header value
    from ocs api v2
    @param value - the ETag response header value
    @param status_code - the OCS status code : 100 (!) for on_signal_success
    ***********************************************************/
    private void etag_response_header_received (string value, int status_code);


    /***********************************************************
    ***********************************************************/
    private override bool on_signal_finished () {
        const string reply_data = this.reply.read_all ();

        QJsonParseError error;
        string message;
        int status_code = 0;
        var json = QJsonDocument.from_json (reply_data, error);

        // when it is null we might have a 304 so get status code from this.reply and gives a warning...
        if (error.error != QJsonParseError.NoError) {
            status_code = this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
            GLib.warning ("Could not parse reply to "
                        + this.verb
                        + Utility.concat_url_path (account.url, path ())
                        + this.params
                        + error.error_string ()
                        + ":" + reply_data);
        } else {
            status_code  = json_return_code (json, message);
        }

        //... then it checks for the status_code
        if (!this.pass_status_codes.contains (status_code)) {
            GLib.warning ("Reply to"
                        + this.verb
                        + Utility.concat_url_path (account.url, path ())
                        + this.params
                        + " has unexpected status code: " + status_code + reply_data);
            /* emit */ ocs_error (status_code, message);

        } else {
            // save new ETag value
            if (this.reply.raw_header_list ().contains ("ETag"))
                /* emit */ etag_response_header_received (this.reply.raw_header ("ETag"), status_code);

            /* emit */ signal_job_finished (json, status_code);
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    private static QUrlQuery percent_encode_query_items (
        GLib.List<QPair<string, string>> items) {
        QUrlQuery result;
        // Note: QUrlQuery.query_items () does not fully percent encode
        // the query items, see #5042
        foreach (var item in items) {
            result.add_query_item (
                GLib.Uri.to_percent_encoding (item.first),
                GLib.Uri.to_percent_encoding (item.second)
            );
        }
        return result;
    }

} // class OcsJob

} // namespace Ui
} // namespace Occ
