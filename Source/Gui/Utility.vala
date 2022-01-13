/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QClipboard>
// #include <QApplication>
// #include <QDesktopServices>
// #include <QLoggingCategory>
// #include <QMessageBox>
// #include <QUrlQuery>

using namespace Occ;

// #include <string>
// #include <QUrl>
// #include <Gtk.Widget>

namespace Occ {
namespace Utility {

    /***********************************************************
    Open an url in the browser.

    If launching the browser fails, display a message.
    ***********************************************************/
    bool openBrowser (QUrl &url, Gtk.Widget *errorWidgetParent = nullptr);

    /***********************************************************
    Start composing a new email message.

    If launching the email program fails, display a message.
    ***********************************************************/
    bool openEmailComposer (string &subject, string &body,
        Gtk.Widget *errorWidgetParent);

    /***********************************************************
    Returns a translated string indicating the current availability.

    This will be used in context menus to describe the current state.
    ***********************************************************/
    string vfsCurrentAvailabilityText (VfsItemAvailability availability);

    /***********************************************************
    Translated text for "making items always available locally" */
    string vfsPinActionText ();

    /***********************************************************
    Translated text for "free up local space" (and unpinning the item) */
    string vfsFreeSpaceActionText ();

} // namespace Utility
} // namespace Occ

#endif







bool Utility.openBrowser (QUrl &url, Gtk.Widget *errorWidgetParent) {
    const QStringList allowedUrlSchemes = {
        "http",
        "https",
        "oauthtest"
    };

    if (!allowedUrlSchemes.contains (url.scheme ())) {
        qCWarning (lcUtility) << "URL format is not supported, or it has been compromised for:" << url.toString ();
        return false;
    }

    if (!QDesktopServices.openUrl (url)) {
        if (errorWidgetParent) {
            QMessageBox.warning (
                errorWidgetParent,
                QCoreApplication.translate ("utility", "Could not open browser"),
                QCoreApplication.translate ("utility",
                    "There was an error when launching the browser to go to "
                    "URL %1. Maybe no default browser is configured?")
                    .arg (url.toString ()));
        }
        qCWarning (lcUtility) << "QDesktopServices.openUrl failed for" << url;
        return false;
    }
    return true;
}

bool Utility.openEmailComposer (string &subject, string &body, Gtk.Widget *errorWidgetParent) {
    QUrl url (QLatin1String ("mailto:"));
    QUrlQuery query;
    query.setQueryItems ({ { QLatin1String ("subject"), subject }, { QLatin1String ("body"), body } });
    url.setQuery (query);

    if (!QDesktopServices.openUrl (url)) {
        if (errorWidgetParent) {
            QMessageBox.warning (
                errorWidgetParent,
                QCoreApplication.translate ("utility", "Could not open email client"),
                QCoreApplication.translate ("utility",
                    "There was an error when launching the email client to "
                    "create a new message. Maybe no default email client is "
                    "configured?"));
        }
        qCWarning (lcUtility) << "QDesktopServices.openUrl failed for" << url;
        return false;
    }
    return true;
}

string Utility.vfsCurrentAvailabilityText (VfsItemAvailability availability) {
    switch (availability) {
    case VfsItemAvailability.AlwaysLocal:
        return QCoreApplication.translate ("utility", "Always available locally");
    case VfsItemAvailability.AllHydrated:
        return QCoreApplication.translate ("utility", "Currently available locally");
    case VfsItemAvailability.Mixed:
        return QCoreApplication.translate ("utility", "Some available online only");
    case VfsItemAvailability.AllDehydrated:
    case VfsItemAvailability.OnlineOnly:
        return QCoreApplication.translate ("utility", "Available online only");
    }
    Q_UNREACHABLE ();
}

string Utility.vfsPinActionText () {
    return QCoreApplication.translate ("utility", "Make always available locally");
}

string Utility.vfsFreeSpaceActionText () {
    return QCoreApplication.translate ("utility", "Free up local space");
}
