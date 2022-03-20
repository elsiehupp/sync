/***********************************************************
@author Olivier Goffart <ogoffart@woboq.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <QDesktopServices>
//  #include <QBuffer>
//  #include <QJsonObject>
//  #include <QJsonDocument>

//  #include <QPointer>
//  #include <QTcpServer>

namespace Occ {
namespace Ui {

/***********************************************************
Job that do the authorization grant and fetch the access token

Normal workfl

  -. on_signal_start ()
      |
      +---. open_browser () open the browser to the login page, redirects to http://localhost
      |
      +---. this.ser
               |
               v
            requ
               |
               v
              emit signal_result (...)

***********************************************************/
public class OAuth : GLib.Object {

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

    /***********************************************************
    ***********************************************************/
    public string expected_user;


    /***********************************************************
    The state has changed.
    when logged in, token has the value of the token.
    ***********************************************************/
    internal signal void signal_result (OAuth.Result result, string user = "", string token = "", string refresh_token = "");

    /***********************************************************
    ***********************************************************/
    public OAuth (Account account, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.account = account;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        // Listen on the socket to get a port which will be used in the redirect_uri
        if (!this.server.listen (QHostAddress.LocalLost)) {
            /* emit */ signal_result (Result.NOT_SUPPORTED, "");
            return;
        }

        if (!open_browser ()) {
            return;
        }

        this.server.new_connection.connect (
            this.on_signal_new_connection
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_new_connection () {
        QTcpSocket socket = this.server.next_pending_connection ();
        while (socket) {
            socket.disconnected.connect (
                socket.delete_later
            );
            socket.ready_read.connect (
                this.on_signal_ready_read
            );
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_ready_read (QTcpSocket socket) {
        string peek = socket.peek (q_min (socket.bytes_available (), 4000LL)); //The code should always be within the first 4K
        if (peek.index_of ('\n') < 0)
            return; // wait until we find a \n
        const QRegularExpression regular_expression = new QRegularExpression ("^GET /\\?code= ([a-z_a-Z0-9]+)[& ]"); // Match a  /?code=...  URL
        const var regular_expression_match = regular_expression.match (peek);
        if (!regular_expression_match.has_match ()) {
            http_reply_and_close (socket, "404 Not Found", "<html><head><title>404 Not Found</title></head><body><center><h1>404 Not Found</h1></center></body></html>");
            return;
        }

        string code = regular_expression_match.captured (1); // The 'code' is the first capture of the regexp

        GLib.Uri request_token = Utility.concat_url_path (this.account.url.to_string (), "/index.php/apps/oauth2/api/v1/token");
        Soup.Request req;
        req.header (Soup.Request.ContentTypeHeader, "application/x-www-form-urlencoded");

        string basic_auth = "%1:%2".printf (
            Theme.oauth_client_id,
            Theme.oauth_client_secret
        );
        req.raw_header ("Authorization", "Basic " + basic_auth.to_utf8 ().to_base64 ());
        // We just added the Authorization header, don't let HttpCredentialsAccessManager tamper with it
        req.attribute (HttpCredentials.DontAddCredentialsAttribute, true);

        var request_body = new QBuffer ();
        QUrlQuery arguments = new QUrlQuery (
            "grant_type=authorization_code&code=%1&redirect_uri=http://localhost:%2"
                .printf (code, string.number (this.server.server_port ())));
        request_body.data (arguments.query (GLib.Uri.FullyEncoded).to_latin1 ());

        var simple_network_job = this.account.send_request ("POST", request_token, req, request_body);
        simple_network_job.on_signal_timeout (q_min (30 * 1000ll, simple_network_job.timeout_msec ()));
        simple_network_job.signal_finished.connect (
            this.on_signal_simple_network_job_finished
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_simple_network_job_finished (QTcpSocket socket, Soup.Reply reply) {
        var json_data = reply.read_all ();
        QJsonParseError json_parse_error;
        QJsonObject json = QJsonDocument.from_json (json_data, json_parse_error).object ();
        string access_token = json["access_token"].to_string ();
        string refresh_token = json["refresh_token"].to_string ();
        string user = json["user_id"].to_string ();
        GLib.Uri message_url = json["message_url"].to_string ();

        if (reply.error != Soup.Reply.NoError || json_parse_error.error != QJsonParseError.NoError
            || json_data == "" || json == "" || refresh_token == "" || access_token == ""
            || json["token_type"].to_string () != "Bearer") {
            string error_reason;
            string error_from_json = json["error"].to_string ();
            if (!error_from_json == "") {
                error_reason = _("Error returned from the server : <em>%1</em>")
                                  .printf (error_from_json.to_html_escaped ());
            } else if (reply.error != Soup.Reply.NoError) {
                error_reason = _("There was an error accessing the \"token\" endpoint : <br><em>%1</em>")
                                  .printf (reply.error_string.to_html_escaped ());
            } else if (json_data == "") {
                // Can happen if a funky load balancer strips away POST data, e.g. BigIP APM my.policy
                error_reason = _("Empty JSON from OAuth2 redirect");
                // We explicitly have this as error case since the json qc_warning output below is misleading,
                // it will show a fake json will null values that actually never was received like this as
                // soon as you access json["whatever"] the debug output json will claim to have "whatever":null
            } else if (json_parse_error.error != QJsonParseError.NoError) {
                error_reason = _("Could not parse the JSON returned from the server : <br><em>%1</em>")
                                  .printf (json_parse_error.error_string);
            } else {
                error_reason = _("The reply from the server did not contain all expected fields");
            }
            GLib.warning ("Error when getting the access_token " + json + error_reason);
            http_reply_and_close (socket, "500 Internal Server Error",
                _("<h1>Login Error</h1><p>%1</p>").printf (error_reason).to_utf8 ().const_data ());
            /* emit */ signal_result (Error);
            return;
        }
        if (!this.expected_user == null && user != this.expected_user) {
            // Connected with the wrong user
            string message = _("<h1>Wrong user</h1>"
                             + "<p>You logged-in with user <em>%1</em>, but must log in with user <em>%2</em>.<br>"
                             + "Please log out of %3 in another tab, then <a href='%4'>click here</a> "
                             + "and log in as user %2</p>")
                                  .printf (user, this.expected_user, Theme.app_name_gui,
                                      authorisation_link ().to_string (GLib.Uri.FullyEncoded));
            http_reply_and_close (socket, "200 OK", message.to_utf8 ().const_data ());
            // We are still listening on the socket so we will get the new connection
            return;
        }
        const string login_successfull_html = "<h1>Login Successful</h1><p>You can close this window.</p>";
        if (message_url.is_valid ()) {
            http_reply_and_close (socket, "303 See Other", login_successfull_html,
                ("Location: " + message_url.to_encoded ()).const_data ());
        } else {
            http_reply_and_close (socket, "200 OK", login_successfull_html);
        }
        /* emit */ signal_result (Result.LOGGED_IN, user, access_token, refresh_token);
    }


    /***********************************************************
    ***********************************************************/
    public bool open_browser () {
        try {
            OpenExternal.open_browser (authorisation_link ());
        } catch {
            // We cannot open the browser, then we claim we don't support OAuth.
            /* emit */ signal_result (Result.NOT_SUPPORTED, "");
            return false;
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    private static void http_reply_and_close (QTcpSocket socket, string code, string html,
        string more_headers = null) {
        if (!socket)
            return; // socket can have been deleted if the browser was closed
        socket.write ("HTTP/1.1 ");
        socket.write (code);
        socket.write ("\r\n_content-Type : text/html\r\n_connection : close\r\n_content-Length: ");
        socket.write (string.number (qstrlen (html)));
        if (more_headers) {
            socket.write ("\r\n");
            socket.write (more_headers);
        }
        socket.write ("\r\n\r\n");
        socket.write (html);
        socket.disconnect_from_host ();
        // We don't want that deleting the server too early prevent queued data to be sent on this socket.
        // The socket will be deleted after disconnection because disconnected is connected to delete_later
        socket.parent (null);
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Uri authorisation_link () {
        //  Q_ASSERT (this.server.is_listening ());
        QUrlQuery query;
        query.query_items ({
            {
                "response_type",
                "code"
            },
            {
                "client_id",
                Theme.oauth_client_id
            },
            {
                "redirect_uri",
                "http://localhost:" + this.server.server_port ().to_string ()
            }
        });
        if (!this.expected_user == null)
            query.add_query_item ("user", this.expected_user);
        GLib.Uri url = Utility.concat_url_path (this.account.url, "/index.php/apps/oauth2/authorize", query);
        return url;
    }

} // class OAuth

} // namespace Ui
} // namespace Occ
    