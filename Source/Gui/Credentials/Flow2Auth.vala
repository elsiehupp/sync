/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QDesktopServices>
// #include <QApplication>
// #include <QClipboard>
// #include <QTimer>
// #include <QBuffer>
// #include <QJsonObject>
// #include <QJsonDocument>

// #pragma once
// #include <QPointer>
// #include <GLib.Uri>
// #include <QTimer>

namespace Occ {

/***********************************************************
Job that does the authorization, grants and fetches the
access token via Login Flow v2

See: https://docs.nextcloud.com/server/latest/developer_manual/client_apis/LoginFlow/index.html#login-flow-v2
***********************************************************/
class Flow2Auth : GLib.Object {

    public enum TokenAction {
        action_open_browser = 1,
        action_copy_link_to_clipboard
    };
    public enum PollStatus {
        status_poll_countdown = 1,
        status_poll_now,
        status_fetch_token,
        status_copy_link_to_clipboard
    };

    public Flow2Auth (Account account, GLib.Object parent);
    ~Flow2Auth () override;

    public enum Result {
        NotSupported,
        LoggedIn,
        Error
    };

    public void on_start ();


    public void open_browser ();


    public void copy_link_to_clipboard ();


    public GLib.Uri authorisation_link ();

signals:
    /***********************************************************
    The state has changed.
    when logged in, app_password has the value of the app password.
    ***********************************************************/
    void result (Flow2Auth.Result result, string error_string = string (),
                const string user = string (), string app_password = string ());

    void status_changed (PollStatus status, int seconds_left);

    public void on_poll_now ();


    private void on_poll_timer_timeout ();


    private void fetch_new_token (TokenAction action);

    private Account _account;
    private GLib.Uri _login_url;
    private string _poll_token;
    private string _poll_endpoint;
    private QTimer _poll_timer;
    private int64 _seconds_left;
    private int64 _seconds_interval;
    private bool _is_busy;
    private bool _has_token;
    private bool _enforce_https = false;
};



    Flow2Auth.Flow2Auth (Account account, GLib.Object parent)
        : GLib.Object (parent)
        , _account (account)
        , _is_busy (false)
        , _has_token (false) {
        _poll_timer.set_interval (1000);
        GLib.Object.connect (&_poll_timer, &QTimer.timeout, this, &Flow2Auth.on_poll_timer_timeout);
    }

    Flow2Auth.~Flow2Auth () = default;

    void Flow2Auth.on_start () {
        // Note: All startup code is in open_browser () to allow reinitiate a new request with
        //       fresh tokens. Opening the same poll_endpoint link twice triggers an expiration
        //       message by the server (security, intended design).
        open_browser ();
    }

    GLib.Uri Flow2Auth.authorisation_link () {
        return _login_url;
    }

    void Flow2Auth.open_browser () {
        fetch_new_token (TokenAction.action_open_browser);
    }

    void Flow2Auth.copy_link_to_clipboard () {
        fetch_new_token (TokenAction.action_copy_link_to_clipboard);
    }

    void Flow2Auth.fetch_new_token (TokenAction action) {
        if (_is_busy)
            return;

        _is_busy = true;
        _has_token = false;

        emit status_changed (PollStatus.status_fetch_token, 0);

        // Step 1 : Initiate a login, do an anonymous POST request
        GLib.Uri url = Utility.concat_url_path (_account.url ().to_string (), QLatin1String ("/index.php/login/v2"));
        _enforce_https = url.scheme () == QStringLiteral ("https");

        // add 'Content-Length : 0' header (see https://github.com/nextcloud/desktop/issues/1473)
        QNetworkRequest req;
        req.set_header (QNetworkRequest.ContentLengthHeader, "0");
        req.set_header (QNetworkRequest.UserAgentHeader, Utility.friendly_user_agent_string ());

        var job = _account.send_request ("POST", url, req);
        job.on_set_timeout (q_min (30 * 1000ll, job.timeout_msec ()));

        GLib.Object.connect (job, &SimpleNetworkJob.finished_signal, this, [this, action] (QNetworkReply reply) {
            var json_data = reply.read_all ();
            QJsonParseError json_parse_error;
            QJsonObject json = QJsonDocument.from_json (json_data, &json_parse_error).object ();
            string poll_token, poll_endpoint, login_url;

            if (reply.error () == QNetworkReply.NoError && json_parse_error.error == QJsonParseError.NoError
                && !json.is_empty ()) {
                poll_token = json.value ("poll").to_object ().value ("token").to_string ();
                poll_endpoint = json.value ("poll").to_object ().value ("endpoint").to_string ();
                if (_enforce_https && GLib.Uri (poll_endpoint).scheme () != QStringLiteral ("https")) {
                    GLib.warn (lc_flow2auth) << "Can not poll endpoint because the returned url" << poll_endpoint << "does not on_start with https";
                    emit result (Error, _("The polling URL does not on_start with HTTPS despite the login URL started with HTTPS. Login will not be possible because this might be a security issue. Please contact your administrator."));
                    return;
                }
                login_url = json["login"].to_string ();
            }

            if (reply.error () != QNetworkReply.NoError || json_parse_error.error != QJsonParseError.NoError
                || json.is_empty () || poll_token.is_empty () || poll_endpoint.is_empty () || login_url.is_empty ()) {
                string error_reason;
                string error_from_json = json["error"].to_string ();
                if (!error_from_json.is_empty ()) {
                    error_reason = _("Error returned from the server : <em>%1</em>")
                                      .arg (error_from_json.to_html_escaped ());
                } else if (reply.error () != QNetworkReply.NoError) {
                    error_reason = _("There was an error accessing the \"token\" endpoint : <br><em>%1</em>")
                                      .arg (reply.error_string ().to_html_escaped ());
                } else if (json_parse_error.error != QJsonParseError.NoError) {
                    error_reason = _("Could not parse the JSON returned from the server : <br><em>%1</em>")
                                      .arg (json_parse_error.error_string ());
                } else {
                    error_reason = _("The reply from the server did not contain all expected fields");
                }
                GLib.warn (lc_flow2auth) << "Error when getting the login_url" << json << error_reason;
                emit result (Error, error_reason);
                _poll_timer.stop ();
                _is_busy = false;
                return;
            }

            _login_url = login_url;

            if (_account.is_username_prefill_supported ()) {
                const var user_name = Utility.get_current_user_name ();
                if (!user_name.is_empty ()) {
                    var query = QUrlQuery (_login_url);
                    query.add_query_item (QStringLiteral ("user"), user_name);
                    _login_url.set_query (query);
                }
            }

            _poll_token = poll_token;
            _poll_endpoint = poll_endpoint;

            // Start polling
            ConfigFile cfg;
            std.chrono.milliseconds polltime = cfg.remote_poll_interval ();
            q_c_info (lc_flow2auth) << "setting remote poll timer interval to" << polltime.count () << "msec";
            _seconds_interval = (polltime.count () / 1000);
            _seconds_left = _seconds_interval;
            emit status_changed (PollStatus.status_poll_countdown, _seconds_left);

            if (!_poll_timer.is_active ()) {
                _poll_timer.on_start ();
            }

            switch (action) {
            case action_open_browser:
                // Try to open Browser
                if (!Utility.open_browser (authorisation_link ())) {
                    // We cannot open the browser, then we claim we don't support Flow2Auth.
                    // Our UI callee will ask the user to copy and open the link.
                    emit result (NotSupported);
                }
                break;
            case action_copy_link_to_clipboard:
                QApplication.clipboard ().on_set_text (authorisation_link ().to_string (GLib.Uri.FullyEncoded));
                emit status_changed (PollStatus.status_copy_link_to_clipboard, 0);
                break;
            }

            _is_busy = false;
            _has_token = true;
        });
    }

    void Flow2Auth.on_poll_timer_timeout () {
        if (_is_busy || !_has_token)
            return;

        _is_busy = true;

        _seconds_left--;
        if (_seconds_left > 0) {
            emit status_changed (PollStatus.status_poll_countdown, _seconds_left);
            _is_busy = false;
            return;
        }
        emit status_changed (PollStatus.status_poll_now, 0);

        // Step 2 : Poll
        QNetworkRequest req;
        req.set_header (QNetworkRequest.ContentTypeHeader, "application/x-www-form-urlencoded");

        var request_body = new QBuffer;
        QUrlQuery arguments (string ("token=%1").arg (_poll_token));
        request_body.set_data (arguments.query (GLib.Uri.FullyEncoded).to_latin1 ());

        var job = _account.send_request ("POST", _poll_endpoint, req, request_body);
        job.on_set_timeout (q_min (30 * 1000ll, job.timeout_msec ()));

        GLib.Object.connect (job, &SimpleNetworkJob.finished_signal, this, [this] (QNetworkReply reply) {
            var json_data = reply.read_all ();
            QJsonParseError json_parse_error;
            QJsonObject json = QJsonDocument.from_json (json_data, &json_parse_error).object ();
            GLib.Uri server_url;
            string login_name, app_password;

            if (reply.error () == QNetworkReply.NoError && json_parse_error.error == QJsonParseError.NoError
                && !json.is_empty ()) {
                server_url = json["server"].to_string ();
                if (_enforce_https && server_url.scheme () != QStringLiteral ("https")) {
                    GLib.warn (lc_flow2auth) << "Returned server url" << server_url << "does not on_start with https";
                    emit result (Error, _("The returned server URL does not on_start with HTTPS despite the login URL started with HTTPS. Login will not be possible because this might be a security issue. Please contact your administrator."));
                    return;
                }
                login_name = json["login_name"].to_string ();
                app_password = json["app_password"].to_string ();
            }

            if (reply.error () != QNetworkReply.NoError || json_parse_error.error != QJsonParseError.NoError
                || json.is_empty () || server_url.is_empty () || login_name.is_empty () || app_password.is_empty ()) {
                string error_reason;
                string error_from_json = json["error"].to_string ();
                if (!error_from_json.is_empty ()) {
                    error_reason = _("Error returned from the server : <em>%1</em>")
                                      .arg (error_from_json.to_html_escaped ());
                } else if (reply.error () != QNetworkReply.NoError) {
                    error_reason = _("There was an error accessing the \"token\" endpoint : <br><em>%1</em>")
                                      .arg (reply.error_string ().to_html_escaped ());
                } else if (json_parse_error.error != QJsonParseError.NoError) {
                    error_reason = _("Could not parse the JSON returned from the server : <br><em>%1</em>")
                                      .arg (json_parse_error.error_string ());
                } else {
                    error_reason = _("The reply from the server did not contain all expected fields");
                }
                GLib.debug (lc_flow2auth) << "Error when polling for the app_password" << json << error_reason;

                // We get a 404 until authentication is done, so don't show this error in the GUI.
                if (reply.error () != QNetworkReply.ContentNotFoundError)
                    emit result (Error, error_reason);

                // Forget sensitive data
                app_password.clear ();
                login_name.clear ();

                // Failed : poll again
                _seconds_left = _seconds_interval;
                _is_busy = false;
                return;
            }

            _poll_timer.stop ();

            // Success
            q_c_info (lc_flow2auth) << "Success getting the app_password for user : " << login_name << ", server : " << server_url.to_string ();

            _account.set_url (server_url);

            emit result (LoggedIn, string (), login_name, app_password);

            // Forget sensitive data
            app_password.clear ();
            login_name.clear ();

            _login_url.clear ();
            _poll_token.clear ();
            _poll_endpoint.clear ();

            _is_busy = false;
            _has_token = false;
        });
    }

    void Flow2Auth.on_poll_now () {
        // poll now if we're not already doing so
        if (_is_busy || !_has_token)
            return;

        _seconds_left = 1;
        on_poll_timer_timeout ();
    }

    } // namespace Occ
    