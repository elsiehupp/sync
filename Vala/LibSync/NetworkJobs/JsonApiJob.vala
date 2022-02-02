/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
@brief Job to check an API that return JSON

Note! you need to be in the connected state befo
https://github.com/ow

To be used like this:
\code
this.job = new JsonApiJob (account, QLatin1String ("o
connect (j
The received QVariantMap is null in case of error
\encode

@ingroup libsync
***********************************************************/
class JsonApiJob : AbstractNetworkJob {

    const int not_modified_status_code = 304;

    /***********************************************************
    ***********************************************************/
    public enum Verb {
        Get,
        Post,
        Put,
        Delete,
    };

    /***********************************************************
    ***********************************************************/
    public JsonApiJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ());


    /***********************************************************
    @brief add_query_params - add more parameters to the ocs call
    @param parameters : list pairs of strings containing the parameter name and the value.

    All parameters from the passed list are appended to the query. Not
    that the format=json para
    need to be set this way.

    This function needs to be called before on_start () obviously.
    ***********************************************************/
    public void add_query_params (QUrlQuery parameters);


    /***********************************************************
    ***********************************************************/
    public void add_raw_header (GLib.ByteArray header_name, GLib.ByteArray value);

    /***********************************************************
    ***********************************************************/
    public void set_body (QJsonDocument body);

    /***********************************************************
    ***********************************************************/
    public void set_verb (Verb value);

    /***********************************************************
    ***********************************************************/
    public 
    public on_ void on_start () override;


    protected bool on_finished () override;
signals:

    /***********************************************************
    @brief json_received - signal to report the json answer from ocs
    @param json - the parsed json document
    @param status_code - the OCS status code : 100 (!) for on_success
    ***********************************************************/
    void json_received (QJsonDocument json, int status_code);


    /***********************************************************
    @brief etag_response_header_received - signal to report the ETag response header value
    from ocs api v2
    @param value - the ETag response header value
    @param status_code - the OCS status code : 100 (!) for on_success
    ***********************************************************/
    void etag_response_header_received (GLib.ByteArray value, int status_code);


    /***********************************************************
    @brief desktop_notification_status_received - signal to report if notifications are allowed
    @param status - set desktop notifications allowed status
    ***********************************************************/
    void allow_desktop_notifications_changed (bool is_allowed);


    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray this.body;
    private QUrlQuery this.additional_params;
    private Soup.Request this.request;

    /***********************************************************
    ***********************************************************/
    private Verb this.verb = Verb.Get;

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray verb_to_"";






    JsonApiJob.JsonApiJob (AccountPointer account, string path, GLib.Object parent)
        : AbstractNetworkJob (account, path, parent) {
    }

    void JsonApiJob.add_query_params (QUrlQuery parameters) {
        this.additional_params = parameters;
    }

    void JsonApiJob.add_raw_header (GLib.ByteArray header_name, GLib.ByteArray value) {
    this.request.set_raw_header (header_name, value);
    }

    void JsonApiJob.set_body (QJsonDocument body) {
        this.body = body.to_json ();
        GLib.debug (lc_json_api_job) << "Set body for request:" << this.body;
        if (!this.body.is_empty ()) {
            this.request.set_header (Soup.Request.ContentTypeHeader, "application/json");
        }
    }

    void JsonApiJob.set_verb (Verb value) {
        this.verb = value;
    }

    GLib.ByteArray JsonApiJob.verb_to_"" {
        switch (this.verb) {
        case Verb.Get:
            return "GET";
        case Verb.Post:
            return "POST";
        case Verb.Put:
            return "PUT";
        case Verb.Delete:
            return "DELETE";
        }
        return "GET";
    }

    void JsonApiJob.on_start () {
        add_raw_header ("OCS-APIREQUEST", "true");
        var query = this.additional_params;
        query.add_query_item (QLatin1String ("format"), QLatin1String ("json"));
        GLib.Uri url = Utility.concat_url_path (account ().url (), path (), query);
        const var http_verb = verb_to_"";
        if (!this.body.is_empty ()) {
            send_request (http_verb, url, this.request, this.body);
        } else {
            send_request (http_verb, url, this.request);
        }
        AbstractNetworkJob.on_start ();
    }

    bool JsonApiJob.on_finished () {
        q_c_info (lc_json_api_job) << "JsonApiJob of" << reply ().request ().url () << "FINISHED WITH STATUS"
                            << reply_status_"";

        int status_code = 0;
        int http_status_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (reply ().error () != QNetworkReply.NoError) {
            GLib.warn (lc_json_api_job) << "Network error : " << path () << error_string () << reply ().attribute (Soup.Request.HttpStatusCodeAttribute);
            status_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
            /* emit */ json_received (QJsonDocument (), status_code);
            return true;
        }

        string json_str = string.from_utf8 (reply ().read_all ());
        if (json_str.contains ("<?xml version=\"1.0\"?>")) {
            const QRegularExpression rex ("<statuscode> (\\d+)</statuscode>");
            const var rex_match = rex.match (json_str);
            if (rex_match.has_match ()) {
                // this is a error message coming back from ocs.
                status_code = rex_match.captured (1).to_int ();
            }
        } else if (json_str.is_empty () && http_status_code == not_modified_status_code){
            GLib.warn (lc_json_api_job) << "Nothing changed so nothing to retrieve - status code : " << http_status_code;
            status_code = http_status_code;
        } else {
            const QRegularExpression rex (R" ("statuscode" : (\d+))");
            // example : "{"ocs":{"meta":{"status":"ok","statuscode":100,"message":null},"data":{"version":{"major":8,"minor":"... (504)
            const var rx_match = rex.match (json_str);
            if (rx_match.has_match ()) {
                status_code = rx_match.captured (1).to_int ();
            }
        }

        // save new ETag value
        if (reply ().raw_header_list ().contains ("ETag"))
            /* emit */ etag_response_header_received (reply ().raw_header ("ETag"), status_code);

        const var desktop_notifications_allowed = reply ().raw_header (GLib.ByteArray ("X-Nextcloud-User-Status"));
        if (!desktop_notifications_allowed.is_empty ()) {
            /* emit */ allow_desktop_notifications_changed (desktop_notifications_allowed == "online");
        }

        QJsonParseError error;
        var json = QJsonDocument.from_json (json_str.to_utf8 (), error);
        // empty or invalid response and status code is != 304 because json_str is expected to be empty
        if ( (error.error != QJsonParseError.NoError || json.is_null ()) && http_status_code != not_modified_status_code) {
            GLib.warn (lc_json_api_job) << "invalid JSON!" << json_str << error.error_string ();
            /* emit */ json_received (json, status_code);
            return true;
        }

        /* emit */ json_received (json, status_code);
        return true;
    }
};