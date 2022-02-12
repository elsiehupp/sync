/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QDesktopServices>
//  #include <QApplication>
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
class Flow2Auth : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum TokenAction {
        action_open_browser = 1,
        action_copy_link_to_clipboard
    }
    public enum PollStatus {
        status_poll_countdown = 1,
        status_poll_now,
        status_fetch_token,
        status_copy_link_to_clipboard
    }

    /***********************************************************
    ***********************************************************/
    public Flow2Auth (Account account, GLib.Object parent);

    /***********************************************************
    ***********************************************************/
    public enum Result {
        NotSupported,
        LoggedIn,
        Error
    }

    /***********************************************************
    ***********************************************************/
    public void on_signal_start ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void copy_link_to_clipboard ();


    public GLib.Uri authorisation_link ();

signals:
    /***********************************************************
    The state has changed.
    when logged in, app_password has the value of the app password.
    ***********************************************************/
    void signal_result (Flow2Auth.Result result, string error_string = "",
                const string user = "", string app_password = "");

    void signal_status_changed (PollStatus status, int seconds_left);

    /***********************************************************
    ***********************************************************/
    public void on_signal_poll_now ();


    /***********************************************************
    ***********************************************************/
    private void on_signal_poll_timer_timeout ();

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 
    private Account this.account;
    private GLib.Uri this.login_url;
    private string this.poll_token;
    private string this.poll_endpoint;
    private QTimer this.poll_timer;
    private int64 this.seconds_left;
    private int64 this.seconds_interval;
    private bool this.is_busy;
    private bool this.has_token;
    private bool this.enforce_https = false;
}



    Flow2Auth.Flow2Auth (Account account, GLib.Object parent)
        : GLib.Object (parent)
        this.account (account)
        this.is_busy (false)
        this.has_token (false) {
        this.poll_timer.interval (1000);
        GLib.Object.connect (&this.poll_timer, &QTimer.timeout, this, &Flow2Auth.on_signal_poll_timer_timeout);
    }

    Flow2Auth.~Flow2Auth () = default;

    void Flow2Auth.on_signal_start () {
        // Note: All startup code is in open_browser () to allow reinitiate a new request with
        //       fresh tokens. Opening the same poll_endpoint link twice triggers an expiration
        //       message by the server (security, intended design).
        open_browser ();
    }

    GLib.Uri Flow2Auth.authorisation_link () {
        return this.login_url;
    }

    void Flow2Auth.open_browser () {
        fetch_new_token (TokenAction.action_open_browser);
    }

    void Flow2Auth.copy_link_to_clipboard () {
        fetch_new_token (TokenAction.action_copy_link_to_clipboard);
    }

    void Flow2Auth.fetch_new_token (TokenAction action) {
        if (this.is_busy)
            return;

        this.is_busy = true;
        this.has_token = false;

        /* emit */ signal_status_changed (PollStatus.status_fetch_token, 0);

        // Step 1 : Initiate a login, do an anonymous POST request
        GLib.Uri url = Utility.concat_url_path (this.account.url ().to_string (), QLatin1String ("/index.php/login/v2"));
        this.enforce_https = url.scheme () == QStringLiteral ("https");

        // add 'Content-Length : 0' header (see https://github.com/nextcloud/desktop/issues/1473)
        QNetworkRequest req;
        req.header (QNetworkRequest.ContentLengthHeader, "0");
        req.header (QNetworkRequest.UserAgentHeader, Utility.friendly_user_agent_string ());

        var job = this.account.send_request ("POST", url, req);
        job.on_signal_timeout (q_min (30 * 1000ll, job.timeout_msec ()));

        GLib.Object.connect (job, &SimpleNetworkJob.finished_signal, this, [this, action] (Soup.Reply reply) {
            var json_data = reply.read_all ();
            QJsonParseError json_parse_error;
            QJsonObject json = QJsonDocument.from_json (json_data, json_parse_error).object ();
            string poll_token, poll_endpoint, login_url;

            if (reply.error () == Soup.Reply.NoError && json_parse_error.error == QJsonParseError.NoError
                && !json.is_empty ()) {
                poll_token = json.value ("poll").to_object ().value ("token").to_string ();
                poll_endpoint = json.value ("poll").to_object ().value ("endpoint").to_string ();
                if (this.enforce_https && GLib.Uri (poll_endpoint).scheme () != QStringLiteral ("https")) {
                    GLib.warning ("Can not poll endpoint because the returned url" + poll_endpoint + "does not on_signal_start with https";
                    /* emit */ signal_result (Error, _("The polling URL does not on_signal_start with HTTPS despite the login URL started with HTTPS. Login will not be possible because this might be a security issue. Please contact your administrator."));
                    return;
                }
                login_url = json["login"].to_string ();
            }

            if (reply.error () != Soup.Reply.NoError || json_parse_error.error != QJsonParseError.NoError
                || json.is_empty () || poll_token.is_empty () || poll_endpoint.is_empty () || login_url.is_empty ()) {
                string error_reason;
                string error_from_json = json["error"].to_string ();
                if (!error_from_json.is_empty ()) {
                    error_reason = _("Error returned from the server : <em>%1</em>")
                                      .arg (error_from_json.to_html_escaped ());
                } else if (reply.error () != Soup.Reply.NoError) {
                    error_reason = _("There was an error accessing the \"token\" endpoint : <br><em>%1</em>")
                                      .arg (reply.error_string ().to_html_escaped ());
                } else if (json_parse_error.error != QJsonParseError.NoError) {
                    error_reason = _("Could not parse the JSON returned from the server : <br><em>%1</em>")
                                      .arg (json_parse_error.error_string ());
                } else {
                    error_reason = _("The reply from the server did not contain all expected fields");
                }
                GLib.warning ("Error when getting the login_url" + json + error_reason;
                /* emit */ signal_result (Error, error_reason);
                this.poll_timer.stop ();
                this.is_busy = false;
                return;
            }

            this.login_url = login_url;

            if (this.account.is_username_prefill_supported ()) {
                const var user_name = Utility.get_current_user_name ();
                if (!user_name.is_empty ()) {
                    var query = QUrlQuery (this.login_url);
                    query.add_query_item (QStringLiteral ("user"), user_name);
                    this.login_url.query (query);
                }
            }

            this.poll_token = poll_token;
            this.poll_endpoint = poll_endpoint;

            // Start polling
            ConfigFile config;
            std.chrono.milliseconds polltime = config.remote_poll_interval ();
            GLib.info ("setting remote poll timer interval to" + polltime.count ("msec";
            this.seconds_interval = (polltime.count () / 1000);
            this.seconds_left = this.seconds_interval;
            /* emit */ signal_status_changed (PollStatus.status_poll_countdown, this.seconds_left);

            if (!this.poll_timer.is_active ()) {
                this.poll_timer.on_signal_start ();
            }

            switch (action) {
            case action_open_browser:
                // Try to open Browser
                if (!Utility.open_browser (authorisation_link ())) {
                    // We cannot open the browser, then we claim we don't support Flow2Auth.
                    // Our UI callee will ask the user to copy and open the link.
                    /* emit */ signal_result (NotSupported);
                }
                break;
            case action_copy_link_to_clipboard:
                QApplication.clipboard ().on_signal_text (authorisation_link ().to_string (GLib.Uri.FullyEncoded));
                /* emit */ signal_status_changed (PollStatus.status_copy_link_to_clipboard, 0);
                break;
            }

            this.is_busy = false;
            this.has_token = true;
        });
    }

    void Flow2Auth.on_signal_poll_timer_timeout () {
        if (this.is_busy || !this.has_token)
            return;

        this.is_busy = true;

        this.seconds_left--;
        if (this.seconds_left > 0) {
            /* emit */ signal_status_changed (PollStatus.status_poll_countdown, this.seconds_left);
            this.is_busy = false;
            return;
        }
        /* emit */ signal_status_changed (PollStatus.status_poll_now, 0);

        // Step 2 : Poll
        QNetworkRequest req;
        req.header (QNetworkRequest.ContentTypeHeader, "application/x-www-form-urlencoded");

        var request_body = new QBuffer;
        QUrlQuery arguments (string ("token=%1").arg (this.poll_token));
        request_body.data (arguments.query (GLib.Uri.FullyEncoded).to_latin1 ());

        var job = this.account.send_request ("POST", this.poll_endpoint, req, request_body);
        job.on_signal_timeout (q_min (30 * 1000ll, job.timeout_msec ()));

        GLib.Object.connect (job, &SimpleNetworkJob.finished_signal, this, [this] (Soup.Reply reply) {
            var json_data = reply.read_all ();
            QJsonParseError json_parse_error;
            QJsonObject json = QJsonDocument.from_json (json_data, json_parse_error).object ();
            GLib.Uri server_url;
            string login_name, app_password;

            if (reply.error () == Soup.Reply.NoError && json_parse_error.error == QJsonParseError.NoError
                && !json.is_empty ()) {
                server_url = json["server"].to_string ();
                if (this.enforce_https && server_url.scheme () != QStringLiteral ("https")) {
                    GLib.warning ("Returned server url" + server_url + "does not on_signal_start with https";
                    /* emit */ signal_result (Error, _("The returned server URL does not on_signal_start with HTTPS despite the login URL started with HTTPS. Login will not be possible because this might be a security issue. Please contact your administrator."));
                    return;
                }
                login_name = json["login_name"].to_string ();
                app_password = json["app_password"].to_string ();
            }

            if (reply.error () != Soup.Reply.NoError || json_parse_error.error != QJsonParseError.NoError
                || json.is_empty () || server_url.is_empty () || login_name.is_empty () || app_password.is_empty ()) {
                string error_reason;
                string error_from_json = json["error"].to_string ();
                if (!error_from_json.is_empty ()) {
                    error_reason = _("Error returned from the server : <em>%1</em>")
                                      .arg (error_from_json.to_html_escaped ());
                } else if (reply.error () != Soup.Reply.NoError) {
                    error_reason = _("There was an error accessing the \"token\" endpoint : <br><em>%1</em>")
                                      .arg (reply.error_string ().to_html_escaped ());
                } else if (json_parse_error.error != QJsonParseError.NoError) {
                    error_reason = _("Could not parse the JSON returned from the server : <br><em>%1</em>")
                                      .arg (json_parse_error.error_string ());
                } else {
                    error_reason = _("The reply from the server did not contain all expected fields");
                }
                GLib.debug ("Error when polling for the app_password" + json + error_reason;

                // We get a 404 until authentication is done, so don't show this error in the GUI.
                if (reply.error () != Soup.Reply.ContentNotFoundError)
                    /* emit */ signal_result (Error, error_reason);

                // Forget sensitive data
                app_password.clear ();
                login_name.clear ();

                // Failed : poll again
                this.seconds_left = this.seconds_interval;
                this.is_busy = false;
                return;
            }

            this.poll_timer.stop ();

            // Success
            GLib.info ("Success getting the app_password for user : " + login_name + ", server : " + server_url.to_string ();

            this.account.url (server_url);

            /* emit */ signal_result (LoggedIn, "", login_name, app_password);

            // Forget sensitive data
            app_password.clear ();
            login_name.clear ();

            this.login_url.clear ();
            this.poll_token.clear ();
            this.poll_endpoint.clear ();

            this.is_busy = false;
            this.has_token = false;
        });
    }

    void Flow2Auth.on_signal_poll_now () {
        // poll now if we're not already doing so
        if (this.is_busy || !this.has_token)
            return;

        this.seconds_left = 1;
        on_signal_poll_timer_timeout ();
    }

    } // namespace Occ
    