namespace Occ {
namespace LibSync {

/***********************************************************
@class JsonApiJob

@brief Job to check an API that return JSON

Note! you need to be in the connected state befo
https://github.com/ow

To be used like this:
\code
this.job = new JsonApiJob (account, "o
connectThe received GLib.HashTable<string, GLib.Variant> is null in case of error
\encode

@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class JsonApiJob : AbstractNetworkJob {

    const int NOT_MODIFIED_STATUS_CODE = 304;

    /***********************************************************
    ***********************************************************/
    public enum Verb {
        GET = "GET",
        POST = "POST",
        PUT = "PUT",
        DELETE = "DELETE"
    }


    /***********************************************************
    ***********************************************************/
    string body {
        private get {
            return this.body;
        }
        public set {
            this.body = value.to_json ();
            GLib.debug ("Set body for request:" + this.body);
            if (!this.body == "") {
                this.request.header (Soup.Request.ContentTypeHeader, "application/json");
            }
        }
    }

    private QUrlQuery additional_params;
    private Soup.Request request = new Soup.Request ();

    /***********************************************************
    ***********************************************************/
    Verb verb { private get; public set; }

    public JsonApiJob () {
        base ();
        this.verb = Verb.GET;
    }

    /***********************************************************
    @brief signal_json_received - signal to report the json answer from ocs
    @param json - the parsed json document
    @param status_code - the OCS status code : 100 (!) for on_signal_success
    ***********************************************************/
    internal signal void signal_json_received (QJsonDocument json, int return_code);


    /***********************************************************
    @brief etag_response_header_received - signal to report the ETag response header value
    from ocs api v2
    @param value - the ETag response header value
    @param status_code - the OCS status code : 100 (!) for on_signal_success
    ***********************************************************/
    internal signal void etag_response_header_received (string value, int status_code);


    /***********************************************************
    @brief desktop_notification_status_received - signal to report if notifications are allowed
    @param status - set desktop notifications allowed status
    ***********************************************************/
    internal signal void allow_desktop_notifications_changed (bool is_allowed);


    /***********************************************************
    ***********************************************************/
    public JsonApiJob.for_account (Account account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    @brief add_query_params - add more parameters to the ocs call
    @param parameters : list pairs of strings containing the parameter name and the value.

    All parameters from the passed list are appended to the query. Not
    that the format=json para
    need to be set this way.

    This function needs to be called before start () obviously.
    ***********************************************************/
    public void add_query_params (QUrlQuery parameters) {
        this.additional_params = parameters;
    }



    /***********************************************************
    ***********************************************************/
    public void add_raw_header (string header_name, string value) {
        this.request.raw_header (header_name, value);
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        add_raw_header ("OCS-APIREQUEST", "true");
        var query = this.additional_params;
        query.add_query_item ("format", "json");
        GLib.Uri url = Utility.concat_url_path (account.url, this.path, query);
        const string http_verb = this.verb.to_string ();
        if (!this.body == "") {
            send_request (http_verb, url, this.request, this.body);
        } else {
            send_request (http_verb, url, this.request);
        }
        AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    protected bool on_signal_finished () {
        GLib.info ("JsonApiJob of" + this.reply.request ().url
            + " finished with status " + reply_status_string ());

        int status_code = 0;
        int http_status_code = this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (this.reply.error != GLib.InputStream.NoError) {
            GLib.warning ("Network error: " + this.path + this.error_string + this.reply.attribute (Soup.Request.HttpStatusCodeAttribute));
            status_code = this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
            /* emit */ signal_json_received (QJsonDocument (), status_code);
            return true;
        }

        string json_str = string.from_utf8 (this.reply.read_all ());
        if (json_str.contains ("<?xml version=\"1.0\"?>")) {
            const GLib.Regex regular_expression = new GLib.Regex ("<statuscode> (\\d+)</statuscode>");
            var rex_match = regular_expression.match (json_str);
            if (rex_match.has_match ()) {
                // this is a error message coming back from ocs.
                status_code = rex_match.captured (1).to_int ();
            }
        } else if (json_str == "" && http_status_code == NOT_MODIFIED_STATUS_CODE) {
            GLib.warning ("Nothing changed so nothing to retrieve - status code: " + http_status_code);
            status_code = http_status_code;
        } else {
            const GLib.Regex regular_expression = new GLib.Regex (" (\"statuscode\" : (\\d+))");
            // example: "{"ocs":{"meta":{"status":"ok","statuscode":100,"message":null},"data":{"version":{"major":8,"minor":"... (504)
            var regular_expression_match = regular_expression.match (json_str);
            if (regular_expression_match.has_match ()) {
                status_code = regular_expression_match.captured (1).to_int ();
            }
        }

        // save new ETag value
        if (this.reply.raw_header_list ().contains ("ETag"))
            /* emit */ etag_response_header_received (this.reply.raw_header ("ETag"), status_code);

        var desktop_notifications_allowed = this.reply.raw_header ("X-Nextcloud-User-Status");
        if (!desktop_notifications_allowed == "") {
            /* emit */ allow_desktop_notifications_changed (desktop_notifications_allowed == "online");
        }

        QJsonParseError error;
        var json = QJsonDocument.from_json (json_str.to_utf8 (), error);
        // empty or invalid response and status code is != 304 because json_str is expected to be empty
        if ( (error.error != QJsonParseError.NoError || json == null) && http_status_code != NOT_MODIFIED_STATUS_CODE) {
            GLib.warning ("Invalid JSON! " + json_str + error.error_string);
            /* emit */ signal_json_received (json, status_code);
            return true;
        }

        /* emit */ signal_json_received (json, status_code);
        return true;
    }

} // class JsonApiJob

} // namespace LibSync
} // namespace Occ
