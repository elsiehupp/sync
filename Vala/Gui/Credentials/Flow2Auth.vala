/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QDesktopServices>
//  #include <Gtk.Application>
//  #include <QClipboard>
//  #include <QTimer>
//  #include <QBuffer>
//  #include <QJsonObject>
//  #include <QJsonDocument>

//  #include <QPointer>
//  #include <QTimer>

namespace Occ {
namespace Ui {

/***********************************************************
Job that does the authorization, grants and fetches the
access token via Login Flow v2

See: https://docs.nextcloud.com/server/latest/developer_manual/client_apis/LoginFlow/index.html#login-flow-v2
***********************************************************/
public class Flow2Auth : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum TokenAction {
        OPEN_BROWSER = 1,
        COPY_LINK_TO_CLIPBOARD
    }

    /***********************************************************
    ***********************************************************/
    public enum PollStatus {
        POLL_COUNTDOWN = 1,
        POLL_NOW,
        FETCH_TOKEN,
        COPY_LINK_TO_CLIPBOARD
    }


    /***********************************************************
    ***********************************************************/
    public enum Result {
        NOT_SUPPORTED,
        LOGGED_IN,
        ERROR
    }


    /***********************************************************
    ***********************************************************/
    private Account account;
    private GLib.Uri login_url;
    private string poll_token;
    private string poll_endpoint;
    private QTimer poll_timer;
    private int64 seconds_left;
    private int64 seconds_interval;
    private bool is_busy;
    private bool has_token;
    private bool enforce_https = false;


    /***********************************************************
    The state has changed.
    when logged in, app_password has the value of the app password.
    ***********************************************************/
    internal signal void signal_result (
        Flow2Auth.Result result, string error_string = "",
        string user = "", string app_password = "");


    /***********************************************************
    ***********************************************************/
    internal signal void signal_status_changed (PollStatus status, int seconds_left);


    /***********************************************************
    ***********************************************************/
    public Flow2Auth (Account account, GLib.Object parent) {
        base (parent);
        this.account = account;
        this.is_busy = false;
        this.has_token = false;
        this.poll_timer.interval (1000);
        connect (this.poll_timer, QTimer.timeout, this, Flow2Auth.on_signal_poll_timer_timeout);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        // Note: All startup code is in open_browser () to allow reinitiate a new request with
        //       fresh tokens. Opening the same poll_endpoint link twice triggers an expiration
        //       message by the server (security, intended design).
        open_browser ();
    }


    /***********************************************************
    ***********************************************************/
    public void fetch_new_token (TokenAction action) {
        if (this.is_busy)
            return;

        this.is_busy = true;
        this.has_token = false;

        /* emit */ signal_status_changed (PollStatus.PollStatus.FETCH_TOKEN, 0);

        // Step 1 : Initiate a login, do an anonymous POST request
        GLib.Uri url = Utility.concat_url_path (this.account.url ().to_string (), "/index.php/login/v2");
        this.enforce_https = url.scheme () == "https";

        // add 'Content-Length : 0' header (see https://github.com/nextcloud/desktop/issues/1473)
        Soup.Request req;
        req.header (Soup.Request.ContentLengthHeader, "0");
        req.header (Soup.Request.UserAgentHeader, Utility.friendly_user_agent_string ());

        var job = this.account.send_request ("POST", url, req);
        job.on_signal_timeout (q_min (30 * 1000ll, job.timeout_msec ()));

        connect (
            job,
            SimpleNetworkJob.finished_signal,
            this,
            on_network_job_finished
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_network_job_finished (TokenAction action, Soup.Reply reply) {
        var json_data = reply.read_all ();
        QJsonParseError json_parse_error;
        QJsonObject json = QJsonDocument.from_json (json_data, json_parse_error).object ();
        string poll_token, poll_endpoint, login_url;

        if (reply.error () == Soup.Reply.NoError && json_parse_error.error == QJsonParseError.NoError
            && !json == "") {
            poll_token = json.value ("poll").to_object ().value ("token").to_string ();
            poll_endpoint = json.value ("poll").to_object ().value ("endpoint").to_string ();
            if (this.enforce_https && GLib.Uri (poll_endpoint).scheme () != "https") {
                GLib.warning ("Can not poll endpoint because the returned url " + poll_endpoint + " does not on_signal_start with https.");
                /* emit */ signal_result (Result.ERROR, _("The polling URL does not on_signal_start with HTTPS despite the login URL started with HTTPS. Login will not be possible because this might be a security issue. Please contact your administrator."));
                return;
            }
            login_url = json["login"].to_string ();
        }

        if (reply.error () != Soup.Reply.NoError || json_parse_error.error != QJsonParseError.NoError
            || json == "" || poll_token == "" || poll_endpoint == "" || login_url == "") {
            string error_reason;
            string error_from_json = json["error"].to_string ();
            if (!error_from_json == "") {
                error_reason = _("Error returned from the server : <em>%1</em>")
                                  .printf (error_from_json.to_html_escaped ());
            } else if (reply.error () != Soup.Reply.NoError) {
                error_reason = _("There was an error accessing the \"token\" endpoint : <br><em>%1</em>")
                                  .printf (reply.error_string ().to_html_escaped ());
            } else if (json_parse_error.error != QJsonParseError.NoError) {
                error_reason = _("Could not parse the JSON returned from the server : <br><em>%1</em>")
                                  .printf (json_parse_error.error_string ());
            } else {
                error_reason = _("The reply from the server did not contain all expected fields");
            }
            GLib.warning ("Error when getting the login_url " + json + error_reason);
            /* emit */ signal_result (Result.ERROR, error_reason);
            this.poll_timer.stop ();
            this.is_busy = false;
            return;
        }

        this.login_url = login_url;

        if (this.account.is_username_prefill_supported ()) {
            const var user_name = Utility.current_user_name ();
            if (!user_name == "") {
                var query = QUrlQuery (this.login_url);
                query.add_query_item ("user", user_name);
                this.login_url.query (query);
            }
        }

        this.poll_token = poll_token;
        this.poll_endpoint = poll_endpoint;

        // Start polling
        ConfigFile config;
        std.chrono.milliseconds polltime = config.remote_poll_interval ();
        GLib.info ("setting remote poll timer interval to " + polltime.count () + "msec.");
        this.seconds_interval = (polltime.count () / 1000);
        this.seconds_left = this.seconds_interval;
        /* emit */ signal_status_changed (PollStatus.PollStatus.POLL_COUNTDOWN, this.seconds_left);

        if (!this.poll_timer.is_active ()) {
            this.poll_timer.on_signal_start ();
        }

        switch (action) {
        case TokenAction.OPEN_BROWSER:
            // Try to open Browser
            if (!Utility.open_browser (authorisation_link ())) {
                // We cannot open the browser, then we claim we don't support Flow2Auth.
                // Our UI callee will ask the user to copy and open the link.
                /* emit */ signal_result (Result.NOT_SUPPORTED);
            }
            break;
        case TokenAction.COPY_LINK_TO_CLIPBOARD:
            Gtk.Application.clipboard ().on_signal_text (authorisation_link ().to_string (GLib.Uri.FullyEncoded));
            /* emit */ signal_status_changed (PollStatus.PollStatus.COPY_LINK_TO_CLIPBOARD, 0);
            break;
        }

        this.is_busy = false;
        this.has_token = true;
    }


    /***********************************************************
    ***********************************************************/
    public void open_browser () {
        fetch_new_token (TokenAction.TokenAction.OPEN_BROWSER);
    }


    /***********************************************************
    ***********************************************************/
    public void copy_link_to_clipboard () {
        fetch_new_token (TokenAction.TokenAction.COPY_LINK_TO_CLIPBOARD);
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Uri authorisation_link () {
        return this.login_url;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_poll_now () {
        // poll now if we're not already doing so
        if (this.is_busy || !this.has_token)
            return;

        this.seconds_left = 1;
        on_signal_poll_timer_timeout ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_poll_timer_timeout () {
        if (this.is_busy || !this.has_token)
            return;

        this.is_busy = true;

        this.seconds_left--;
        if (this.seconds_left > 0) {
            /* emit */ signal_status_changed (PollStatus.PollStatus.POLL_COUNTDOWN, this.seconds_left);
            this.is_busy = false;
            return;
        }
        /* emit */ signal_status_changed (PollStatus.PollStatus.POLL_NOW, 0);

        // Step 2 : Poll
        Soup.Request req;
        req.header (Soup.Request.ContentTypeHeader, "application/x-www-form-urlencoded");

        var request_body = new QBuffer ();
        QUrlQuery arguments = new QUrlQuery ("token=%1".printf (this.poll_token));
        request_body.data (arguments.query (GLib.Uri.FullyEncoded).to_latin1 ());

        var job = this.account.send_request ("POST", this.poll_endpoint, req, request_body);
        job.on_signal_timeout (q_min (30 * 1000ll, job.timeout_msec ()));

        connect (
            job,
            SimpleNetworkJob.finished_signal,
            this,
            on_signal_simple_finished
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_simple_finished (Soup.Reply reply) {
        var json_data = reply.read_all ();
        QJsonParseError json_parse_error;
        QJsonObject json = QJsonDocument.from_json (json_data, json_parse_error).object ();
        GLib.Uri server_url;
        string login_name, app_password;

        if (reply.error () == Soup.Reply.NoError && json_parse_error.error == QJsonParseError.NoError
            && !json == "") {
            server_url = json["server"].to_string ();
            if (this.enforce_https && server_url.scheme () != "https") {
                GLib.warning ("Returned server url " + server_url + " does not start with https.");
                /* emit */ signal_result (Result.ERROR, _("The returned server URL does not on_signal_start with HTTPS despite the login URL started with HTTPS. Login will not be possible because this might be a security issue. Please contact your administrator."));
                return;
            }
            login_name = json["login_name"].to_string ();
            app_password = json["app_password"].to_string ();
        }

        if (reply.error () != Soup.Reply.NoError || json_parse_error.error != QJsonParseError.NoError
            || json == "" || server_url == "" || login_name == "" || app_password == "") {
            string error_reason;
            string error_from_json = json["error"].to_string ();
            if (!error_from_json == "") {
                error_reason = _("Error returned from the server : <em>%1</em>")
                                  .printf (error_from_json.to_html_escaped ());
            } else if (reply.error () != Soup.Reply.NoError) {
                error_reason = _("There was an error accessing the \"token\" endpoint : <br><em>%1</em>")
                                  .printf (reply.error_string ().to_html_escaped ());
            } else if (json_parse_error.error != QJsonParseError.NoError) {
                error_reason = _("Could not parse the JSON returned from the server : <br><em>%1</em>")
                                  .printf (json_parse_error.error_string ());
            } else {
                error_reason = _("The reply from the server did not contain all expected fields");
            }
            GLib.debug ("Error when polling for the app_password " + json + error_reason);

            // We get a 404 until authentication is done, so don't show this error in the GUI.
            if (reply.error () != Soup.Reply.ContentNotFoundError) {
                /* emit */ signal_result (Result.ERROR, error_reason);
            }

            // Forget sensitive data
            app_password = "";
            login_name = "";

            // Failed: poll again
            this.seconds_left = this.seconds_interval;
            this.is_busy = false;
            return;
        }

        this.poll_timer.stop ();

        // Success
        GLib.info ("Success getting the app_password for user: " + login_name + ", server: " + server_url.to_string ());

        this.account.url (server_url);

        /* emit */ signal_result (Result.LOGGED_IN, "", login_name, app_password);

        // Forget sensitive data
        app_password = "";
        login_name = "";

        this.login_url = "";
        this.poll_token = "";
        this.poll_endpoint = "";

        this.is_busy = false;
        this.has_token = false;
    }

} // class Flow2Auth

} // namespace Ui
} // namespace Occ
