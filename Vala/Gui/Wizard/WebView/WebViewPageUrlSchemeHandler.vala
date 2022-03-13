

namespace Occ {
namespace Ui {

public class WebViewPageUrlSchemeHandler : QWebEngineUrlSchemeHandler {

    signal void on_signal_url_catched (string user, string pass, string host);

    /***********************************************************
    ***********************************************************/
    public WebViewPageUrlSchemeHandler (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public void request_started (QWebEngineUrlRequestJob request) {
        GLib.Uri url = request.request_url ();

        string path = url.path ().mid (1); // get undecoded path
        const string[] parts = path.split ("&");

        string server;
        string user;
        string password;

        foreach (string part in parts) {
            if (part.starts_with ("server:")) {
                server = part.mid (7);
            } else if (part.starts_with ("user:")) {
                user = part.mid (5);
            } else if (part.starts_with ("password:")) {
                password = part.mid (9);
            }
        }

        GLib.debug ("Got raw user from request path: " + user);

        user = user.replace (char ('+'), char (' '));
        password = password.replace (char ('+'), char (' '));

        user = GLib.Uri.from_percent_encoding (user.to_utf8 ());
        password = GLib.Uri.from_percent_encoding (password.to_utf8 ());

        if (!server.starts_with ("http://") && !server.starts_with ("https://")) {
            server = "https://" + server;
        }
        GLib.info ("Got user: " + user + ", server: " + server);

        /* emit */ url_catched (user, password, server);
    }

} // class WebViewPageUrlSchemeHandler

} // namespace Ui
} // namespace Occ
