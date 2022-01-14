/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QBuffer>
// #include <QJsonDocument>
// #include <QJsonObject>

// #include <QVector>
// #include <QList>
// #include <QPair>
// #include <QUrl>

const int OCS_SUCCESS_STATUS_CODE 100
// Apparantly the v2.php URLs can return that
const int OCS_SUCCESS_STATUS_CODE_V2 200
// not modified when using  ETag
const int OCS_NOT_MODIFIED_STATUS_CODE_V2 304


namespace Occ {

/***********************************************************
@brief The Ocs_share_job class
@ingroup gui

Base class for jobs that talk to the OCS endpoints on th
All the communication logic is handled in this class.

All OCS jobs (e.g. sharing) should extend this class.
***********************************************************/
class Ocs_job : AbstractNetworkJob {

protected:
    Ocs_job (AccountPtr account);

    /***********************************************************
    Set the verb for the job
    
    @param verb currently supported PUT POST DELETE
    ***********************************************************/
    void set_verb (QByteArray &verb);

    /***********************************************************
    Add a new parameter to the request.
    Depending on the verb this is GET or POST parameter
    
    @param name The name of the parameter
    @param value The value of the parameter
    ***********************************************************/
    void add_param (string &name, string &value);

    /***********************************************************
    Set the post parameters
    
    @param post_params list of pairs to add (url_encoded) to the body of the
    request
    ***********************************************************/
    void set_post_params (QList<QPair<string, string>> &post_params);

    /***********************************************************
    List of expected statuscodes for this request
    A warning will be printed to the debug log if a different status code is
    encountered
    
    @param code Accepted status code
    ***********************************************************/
    void add_pass_status_code (int code);

    /***********************************************************
    The base path for an Ocs_job is always the same. But it could be the case that
    certain operations need to append something to the URL.
    
    This function appends the common id. so <PATH>/<ID>
    ***********************************************************/
    void append_path (string &id);

public:
    /***********************************************************
    Parse the response and return the status code and the message of the
    reply (metadata)
    
    @param json The reply from OCS
    @param message The message that is set in the metadata
    @return The statuscode of the OCS response
    ***********************************************************/
    static int get_json_return_code (QJsonDocument &json, string &message);

    /***********************************************************
    @brief Adds header to the request e.g. "If-None-Match"
    @param header_name a string with the header name
    @param value a string with the value
    ***********************************************************/
    void add_raw_header (QByteArray &header_name, QByteArray &value);

protected slots:

    /***********************************************************
    Start the OCS request
    ***********************************************************/
    void start () override;

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
    void ocs_error (int status_code, string &message);

    /***********************************************************
    @brief etag_response_header_received - signal to report the ETag response header value
    from ocs api v2
    @param value - the ETag response header value
    @param status_code - the OCS status code : 100 (!) for success
    ***********************************************************/
    void etag_response_header_received (QByteArray &value, int status_code);

private slots:
    bool finished () override;

private:
    QByteArray _verb;
    QList<QPair<string, string>> _params;
    QVector<int> _pass_status_codes;
    QNetworkRequest _request;
};

    Ocs_job.Ocs_job (AccountPtr account)
        : AbstractNetworkJob (account, "") {
        _pass_status_codes.append (OCS_SUCCESS_STATUS_CODE);
        _pass_status_codes.append (OCS_SUCCESS_STATUS_CODE_V2);
        _pass_status_codes.append (OCS_NOT_MODIFIED_STATUS_CODE_V2);
        set_ignore_credential_failure (true);
    }
    
    void Ocs_job.set_verb (QByteArray &verb) {
        _verb = verb;
    }
    
    void Ocs_job.add_param (string &name, string &value) {
        _params.append (q_make_pair (name, value));
    }
    
    void Ocs_job.add_pass_status_code (int code) {
        _pass_status_codes.append (code);
    }
    
    void Ocs_job.append_path (string &id) {
        set_path (path () + QLatin1Char ('/') + id);
    }
    
    void Ocs_job.add_raw_header (QByteArray &header_name, QByteArray &value) {
        _request.set_raw_header (header_name, value);
    }
    
    static QUrlQuery percent_encode_query_items (
        const QList<QPair<string, string>> &items) {
        QUrlQuery result;
        // Note : QUrlQuery.set_query_items () does not fully percent encode
        // the query items, see #5042
        foreach (auto &item, items) {
            result.add_query_item (
                QUrl.to_percent_encoding (item.first),
                QUrl.to_percent_encoding (item.second));
        }
        return result;
    }
    
    void Ocs_job.start () {
        add_raw_header ("Ocs-APIREQUEST", "true");
        add_raw_header ("Content-Type", "application/x-www-form-urlencoded");
    
        auto *buffer = new QBuffer;
    
        QUrlQuery query_items;
        if (_verb == "GET") {
            query_items = percent_encode_query_items (_params);
        } else if (_verb == "POST" || _verb == "PUT") {
            // Url encode the _post_params and put them in a buffer.
            QByteArray post_data;
            Q_FOREACH (auto tmp, _params) {
                if (!post_data.is_empty ()) {
                    post_data.append ("&");
                }
                post_data.append (QUrl.to_percent_encoding (tmp.first));
                post_data.append ("=");
                post_data.append (QUrl.to_percent_encoding (tmp.second));
            }
            buffer.set_data (post_data);
        }
        query_items.add_query_item (QLatin1String ("format"), QLatin1String ("json"));
        QUrl url = Utility.concat_url_path (account ().url (), path (), query_items);
        send_request (_verb, url, _request, buffer);
        AbstractNetworkJob.start ();
    }
    
    bool Ocs_job.finished () {
        const QByteArray reply_data = reply ().read_all ();
    
        QJsonParseError error;
        string message;
        int status_code = 0;
        auto json = QJsonDocument.from_json (reply_data, &error);
    
        // when it is null we might have a 304 so get status code from reply () and gives a warning...
        if (error.error != QJsonParseError.NoError) {
            status_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
            q_c_warning (lc_ocs) << "Could not parse reply to"
                             << _verb
                             << Utility.concat_url_path (account ().url (), path ())
                             << _params
                             << error.error_string ()
                             << ":" << reply_data;
        } else {
            status_code  = get_json_return_code (json, message);
        }
    
        //... then it checks for the status_code
        if (!_pass_status_codes.contains (status_code)) {
            q_c_warning (lc_ocs) << "Reply to"
                             << _verb
                             << Utility.concat_url_path (account ().url (), path ())
                             << _params
                             << "has unexpected status code:" << status_code << reply_data;
            emit ocs_error (status_code, message);
    
        } else {
            // save new ETag value
            if (reply ().raw_header_list ().contains ("ETag"))
                emit etag_response_header_received (reply ().raw_header ("ETag"), status_code);
    
            emit job_finished (json, status_code);
        }
        return true;
    }
    
    int Ocs_job.get_json_return_code (QJsonDocument &json, string &message) {
        //TODO proper checking
        auto meta = json.object ().value ("ocs").to_object ().value ("meta").to_object ();
        int code = meta.value ("statuscode").to_int ();
        message = meta.value ("message").to_string ();
    
        return code;
    }
    }
    