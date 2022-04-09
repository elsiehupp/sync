/***********************************************************
@author Christian Kamm <mail@ckamm.de>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.Clipboard>
//  #include <GLib.Application>
//  #include <GLib.DesktopServices>
//  #include <Gtk.MessageBox>
//  #include <GLib.UrlQuery>

//  #include <Gtk.Widget>

namespace Occ {
namespace Ui {

public errordomain OpenExternalError {
    INVALID_URL_SCHEME,
    OPEN_EXTERNAL_FAILED,
}

public class OpenExternal : GLib.Object {

    /***********************************************************
    Open an url in the browser.

    If launching the browser fails, display a message.
    ***********************************************************/
    public static void open_browser (GLib.Uri url, Gtk.Widget error_widget_parent = new Gtk.Widget ()) throws OpenExternalError {
        GLib.List<string> allowed_url_schemes = {
            "http",
            "https",
            "oauthtest"
        };

        if (!allowed_url_schemes.contains (url.scheme ())) {
            GLib.warning ("URL format is not supported, or it has been compromised for: " + url.to_string ());
            throw new OpenExternalError.INVALID_URL_SCHEME ("URL format is not supported, or it has been compromised for: " + url.to_string ());
        }

        if (!GLib.DesktopServices.open_url (url)) {
            if (error_widget_parent != null) {
                Gtk.MessageBox.warning (
                    error_widget_parent,
                    _("Could not open browser"),
                    _("utility",
                    + "There was an error when launching the browser to go to "
                    + "URL %1. Maybe no default browser is configured?")
                        .printf (url.to_string ()));
            }
            GLib.warning ("GLib.DesktopServices.open_url failed for " + url.to_string ());
            throw new OpenExternalError.OPEN_EXTERNAL_FAILED ("GLib.DesktopServices.open_url failed for " + url.to_string ());
        }
        return;
    }


    /***********************************************************
    Start composing a new email message.

    If launching the email program fails, display a message.
    ***********************************************************/
    public static void open_email_composer (
        string subject, string body,
        Gtk.Widget error_widget_parent) throws OpenExternalError {
        GLib.Uri url = new GLib.Uri ("mailto:");
        GLib.UrlQuery query;
        query.query_items (
            {
                {
                    "subject",
                    subject
                },
                {
                    "body",
                    body
                }
            }
        );
        url.query (query);

        if (!GLib.DesktopServices.open_url (url)) {
            if (error_widget_parent != null) {
                Gtk.MessageBox.warning (
                    error_widget_parent,
                    _("Could not open email client"),
                    _("utility",
                    + "There was an error when launching the email client to "
                    + "create a new message. Maybe no default email client is "
                    + "configured?"));
            }
            GLib.warning ("GLib.DesktopServices.open_url failed for " + url);
            throw new OpenExternalError.INVALID_URL_SCHEME ("GLib.DesktopServices.open_url failed for " + url.to_string ());
        }
    }

} // class OpenExternal

} // namespace Ui
} // namespace Occ
