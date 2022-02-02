

namespace Occ {

class Web_view_page_url_scheme_handler : QWeb_engine_url_scheme_handler {

    /***********************************************************
    ***********************************************************/
    public Web_view_page_url_scheme_handler (GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 
    public void request_started (QWeb_engine_url_request_job request) override;

signals:
    void on_url_catched (string user, string pass, string host);
}



Web_view_page_url_scheme_handler.Web_view_page_url_scheme_handler (GLib.Object parent)
    : QWeb_engine_url_scheme_handler (parent) {

}

void Web_view_page_url_scheme_handler.request_started (QWeb_engine_url_request_job request) {
    GLib.Uri url = request.request_url ();

    string path = url.path ().mid (1); // get undecoded path
    const string[] parts = path.split ("&");

    string server;
    string user;
    string password;

    for (string part : parts) {
        if (part.starts_with ("server:")) {
            server = part.mid (7);
        } else if (part.starts_with ("user:")) {
            user = part.mid (5);
        } else if (part.starts_with ("password:")) {
            password = part.mid (9);
        }
    }

    GLib.debug (lc_wizard_webiew ()) << "Got raw user from request path : " << user;

    user = user.replace (char ('+'), char (' '));
    password = password.replace (char ('+'), char (' '));

    user = GLib.Uri.from_percent_encoding (user.to_utf8 ());
    password = GLib.Uri.from_percent_encoding (password.to_utf8 ());

    if (!server.starts_with ("http://") && !server.starts_with ("https://")) {
        server = "https://" + server;
    }
    q_c_info (lc_wizard_webiew ()) << "Got user : " << user << ", server : " << server;

    /* emit */ url_catched (user, password, server);
}