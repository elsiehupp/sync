/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QClipboard>
//  #include <Gtk.Application>
//  #include <QDesktopServices>
//  #include <QLoggingCategory>
//  #include <Gtk.MessageBox>
//  #include <QUrlQuery>

//  #include <Gtk.Widget>

namespace Occ {
namespace Ui {

public class OpenExtrernal {

    /***********************************************************
    Open an url in the browser.

    If launching the browser fails, display a message.
    ***********************************************************/
    public static bool open_browser (GLib.Uri url, Gtk.Widget error_widget_parent = null) {
        const string[] allowed_url_schemes = {
            "http",
            "https",
            "oauthtest"
        };

        if (!allowed_url_schemes.contains (url.scheme ())) {
            GLib.warning ("URL format is not supported, or it has been compromised for: " + url.to_string ());
            return false;
        }

        if (!QDesktopServices.open_url (url)) {
            if (error_widget_parent) {
                Gtk.MessageBox.warning (
                    error_widget_parent,
                    _("Could not open browser"),
                    _("utility",
                    + "There was an error when launching the browser to go to "
                    + "URL %1. Maybe no default browser is configured?")
                        .printf (url.to_string ()));
            }
            GLib.warning ("QDesktopServices.open_url failed for " + url);
            return false;
        }
        return true;
    }


    /***********************************************************
    Start composing a new email message.

    If launching the email program fails, display a message.
    ***********************************************************/
    public static bool open_email_composer (
        string subject, string body,
        Gtk.Widget error_widget_parent) {
        GLib.Uri url = new GLib.Uri ("mailto:");
        QUrlQuery query;
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

        if (!QDesktopServices.open_url (url)) {
            if (error_widget_parent) {
                Gtk.MessageBox.warning (
                    error_widget_parent,
                    _("Could not open email client"),
                    _("utility",
                    + "There was an error when launching the email client to "
                    + "create a new message. Maybe no default email client is "
                    + "configured?"));
            }
            GLib.warning ("QDesktopServices.open_url failed for " + url);
            return false;
        }
        return true;
    }

} // class Utility

} // namespace Ui
} // namespace Occ
