/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QClipboard>
//  #include <QApplication>
//  #include <QDesktopServices>
//  #include <QLoggingCategory>
//  #include <QMessageBox>
//  #include <QUrlQuery>

//  #include <Gtk.Widget>

namespace Occ {
namespace Ui {

public class Utility {

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
                QMessageBox.warning (
                    error_widget_parent,
                    _("utility", "Could not open browser"),
                    _("utility",
                    + "There was an error when launching the browser to go to "
                    + "URL %1. Maybe no default browser is configured?")
                        .arg (url.to_string ()));
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
    public static bool open_email_composer (string subject, string body,
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
                QMessageBox.warning (
                    error_widget_parent,
                    _("utility", "Could not open email client"),
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


    /***********************************************************
    Returns a translated string indicating the current
    availability.

    This will be used in context menus to describe the current
    state.
    ***********************************************************/
    public static string vfs_current_availability_text (VfsItemAvailability availability) {
        switch (availability) {
        case VfsItemAvailability.PinState.ALWAYS_LOCAL:
            return _("utility", "Always available locally");
        case VfsItemAvailability.VfsItemAvailability.ALL_HYDRATED:
            return _("utility", "Currently available locally");
        case VfsItemAvailability.VfsItemAvailability.MIXED:
            return _("utility", "Some available online only");
        case VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED:
        case VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY:
            return _("utility", "Available online only");
        }
        GLib.assert_not_reached ();
    }


    /***********************************************************
    Translated text for "making items always available locally"
    ***********************************************************/
    public static string vfs_pin_action_text () {
        return _("utility", "Make always available locally");
    }


    /***********************************************************
    Translated text for "free up local space" (and unpinning the item)
    ***********************************************************/
    public static string vfs_free_space_action_text () {
        return _("utility", "Free up local space");
    }

} // class Utility

} // namespace Ui
} // namespace Occ
