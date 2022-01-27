/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QDesktopServices>
// #include <QNetworkReply>
// #include <QTimer>
// #include <QBuffer>
// #include <QJsonObject>
// #include <QJsonDocument>

// #pragma once
// #include <QPointer>
// #include <QTcpServer>
// #include <QUrl>

namespace Occ {

/***********************************************************
Job that do the authorization grant and fetch the access token

Normal workfl

  -. on_start ()
      |
      +---. open_browser () open the browser to the login page, redirects to http://localhost
      |
      +---. _ser
               |
               v
            requ
               |
               v
             emit result (...)

***********************************************************/
class OAuth : GLib.Object {

    public OAuth (Account *account, GLib.Object *parent)
        : GLib.Object (parent)
        , _account (account) {
    }
    ~OAuth () override;

    public enum Result {
        NotSupported,
        LoggedIn,
        Error
    };

    public void on_start ();
    public bool open_browser ();
    public QUrl authorisation_link ();

signals:
    /***********************************************************
    The state has changed.
    when logged in, token has the value of the token.
    ***********************************************************/
    void result (OAuth.Result result, string user = string (), string token = string (), string refresh_token = string ());


    private Account _account;
    private QTcpServer _server;

    private public string _expected_user;
};


    OAuth.~OAuth () = default;

    static void http_reply_and_close (QTcpSocket *socket, char *code, char *html,
        const char *more_headers = nullptr) {
        if (!socket)
            return; // socket can have been deleted if the browser was closed
        socket.write ("HTTP/1.1 ");
        socket.write (code);
        socket.write ("\r\n_content-Type : text/html\r\n_connection : close\r\n_content-Length : ");
        socket.write (GLib.ByteArray.number (qstrlen (html)));
        if (more_headers) {
            socket.write ("\r\n");
            socket.write (more_headers);
        }
        socket.write ("\r\n\r\n");
        socket.write (html);
        socket.disconnect_from_host ();
        // We don't want that deleting the server too early prevent queued data to be sent on this socket.
        // The socket will be deleted after disconnection because disconnected is connected to delete_later
        socket.set_parent (nullptr);
    }

    void OAuth.on_start () {
        // Listen on the socket to get a port which will be used in the redirect_uri
        if (!_server.listen (QHostAddress.LocalLost)) {
            emit result (NotSupported, string ());
            return;
        }

        if (!open_browser ())
            return;

        GLib.Object.connect (&_server, &QTcpServer.new_connection, this, [this] {
            while (QPointer<QTcpSocket> socket = _server.next_pending_connection ()) {
                GLib.Object.connect (socket.data (), &QTcpSocket.disconnected, socket.data (), &QTcpSocket.delete_later);
                GLib.Object.connect (socket.data (), &QIODevice.ready_read, this, [this, socket] {
                    GLib.ByteArray peek = socket.peek (q_min (socket.bytes_available (), 4000LL)); //The code should always be within the first 4K
                    if (peek.index_of ('\n') < 0)
                        return; // wait until we find a \n
                    const QRegularExpression rx ("^GET /\\?code= ([a-z_a-Z0-9]+)[& ]"); // Match a  /?code=...  URL
                    const auto rx_match = rx.match (peek);
                    if (!rx_match.has_match ()) {
                        http_reply_and_close (socket, "404 Not Found", "<html><head><title>404 Not Found</title></head><body><center><h1>404 Not Found</h1></center></body></html>");
                        return;
                    }

                    string code = rx_match.captured (1); // The 'code' is the first capture of the regexp

                    QUrl request_token = Utility.concat_url_path (_account.url ().to_string (), QLatin1String ("/index.php/apps/oauth2/api/v1/token"));
                    QNetworkRequest req;
                    req.set_header (QNetworkRequest.ContentTypeHeader, "application/x-www-form-urlencoded");

                    string basic_auth = string ("%1:%2").arg (
                        Theme.instance ().oauth_client_id (), Theme.instance ().oauth_client_secret ());
                    req.set_raw_header ("Authorization", "Basic " + basic_auth.to_utf8 ().to_base64 ());
                    // We just added the Authorization header, don't let HttpCredentialsAccessManager tamper with it
                    req.set_attribute (HttpCredentials.DontAddCredentialsAttribute, true);

                    auto request_body = new QBuffer;
                    QUrlQuery arguments (string (
                        "grant_type=authorization_code&code=%1&redirect_uri=http://localhost:%2")
                                            .arg (code, string.number (_server.server_port ())));
                    request_body.set_data (arguments.query (QUrl.FullyEncoded).to_latin1 ());

                    auto job = _account.send_request ("POST", request_token, req, request_body);
                    job.on_set_timeout (q_min (30 * 1000ll, job.timeout_msec ()));
                    GLib.Object.connect (job, &SimpleNetworkJob.finished_signal, this, [this, socket] (QNetworkReply *reply) {
                        auto json_data = reply.read_all ();
                        QJsonParseError json_parse_error;
                        QJsonObject json = QJsonDocument.from_json (json_data, &json_parse_error).object ();
                        string access_token = json["access_token"].to_string ();
                        string refresh_token = json["refresh_token"].to_string ();
                        string user = json["user_id"].to_string ();
                        QUrl message_url = json["message_url"].to_string ();

                        if (reply.error () != QNetworkReply.NoError || json_parse_error.error != QJsonParseError.NoError
                            || json_data.is_empty () || json.is_empty () || refresh_token.is_empty () || access_token.is_empty ()
                            || json["token_type"].to_string () != QLatin1String ("Bearer")) {
                            string error_reason;
                            string error_from_json = json["error"].to_string ();
                            if (!error_from_json.is_empty ()) {
                                error_reason = tr ("Error returned from the server : <em>%1</em>")
                                                  .arg (error_from_json.to_html_escaped ());
                            } else if (reply.error () != QNetworkReply.NoError) {
                                error_reason = tr ("There was an error accessing the \"token\" endpoint : <br><em>%1</em>")
                                                  .arg (reply.error_string ().to_html_escaped ());
                            } else if (json_data.is_empty ()) {
                                // Can happen if a funky load balancer strips away POST data, e.g. BigIP APM my.policy
                                error_reason = tr ("Empty JSON from OAuth2 redirect");
                                // We explicitly have this as error case since the json qc_warning output below is misleading,
                                // it will show a fake json will null values that actually never was received like this as
                                // soon as you access json["whatever"] the debug output json will claim to have "whatever":null
                            } else if (json_parse_error.error != QJsonParseError.NoError) {
                                error_reason = tr ("Could not parse the JSON returned from the server : <br><em>%1</em>")
                                                  .arg (json_parse_error.error_string ());
                            } else {
                                error_reason = tr ("The reply from the server did not contain all expected fields");
                            }
                            q_c_warning (lc_oauth) << "Error when getting the access_token" << json << error_reason;
                            http_reply_and_close (socket, "500 Internal Server Error",
                                tr ("<h1>Login Error</h1><p>%1</p>").arg (error_reason).to_utf8 ().const_data ());
                            emit result (Error);
                            return;
                        }
                        if (!_expected_user.is_null () && user != _expected_user) {
                            // Connected with the wrong user
                            string message = tr ("<h1>Wrong user</h1>"
                                                 "<p>You logged-in with user <em>%1</em>, but must login with user <em>%2</em>.<br>"
                                                 "Please log out of %3 in another tab, then <a href='%4'>click here</a> "
                                                 "and log in as user %2</p>")
                                                  .arg (user, _expected_user, Theme.instance ().app_name_gui (),
                                                      authorisation_link ().to_string (QUrl.FullyEncoded));
                            http_reply_and_close (socket, "200 OK", message.to_utf8 ().const_data ());
                            // We are still listening on the socket so we will get the new connection
                            return;
                        }
                        const char *login_successfull_html = "<h1>Login Successful</h1><p>You can close this window.</p>";
                        if (message_url.is_valid ()) {
                            http_reply_and_close (socket, "303 See Other", login_successfull_html,
                                GLib.ByteArray ("Location : " + message_url.to_encoded ()).const_data ());
                        } else {
                            http_reply_and_close (socket, "200 OK", login_successfull_html);
                        }
                        emit result (LoggedIn, user, access_token, refresh_token);
                    });
                });
            }
        });
    }

    QUrl OAuth.authorisation_link () {
        Q_ASSERT (_server.is_listening ());
        QUrlQuery query;
        query.set_query_items ({
            {
                QLatin1String ("response_type"),
                QLatin1String ("code")
            },
            {
                QLatin1String ("client_id"),
                Theme.instance ().oauth_client_id ()
            },
            {
                QLatin1String ("redirect_uri"),
                QLatin1String ("http://localhost:") + string.number (_server.server_port ())
            }
        });
        if (!_expected_user.is_null ())
            query.add_query_item ("user", _expected_user);
        QUrl url = Utility.concat_url_path (_account.url (), QLatin1String ("/index.php/apps/oauth2/authorize"), query);
        return url;
    }

    bool OAuth.open_browser () {
        if (!Utility.open_browser (authorisation_link ())) {
            // We cannot open the browser, then we claim we don't support OAuth.
            emit result (NotSupported, string ());
            return false;
        }
        return true;
    }

    } // namespace Occ
    