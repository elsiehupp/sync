

namespace Occ {
namespace Ui {

class WebEnginePage : QWebEnginePage {

    /***********************************************************
    ***********************************************************/
    private bool enforce_https = false;

    /***********************************************************
    ***********************************************************/
    public WebEnginePage (QWebEngineProfile profile, GLib.Object parent = new GLib.Object ()) {
        base (profile, parent);
    }


    /***********************************************************
    ***********************************************************/
    public QWebEnginePage create_window (QWebEnginePage.WebWindowType type) {
        //  Q_UNUSED (type);
        var view = new ExternalWebEnginePage (this.profile ());
        return view;
    }


    /***********************************************************
    ***********************************************************/
    public void url (GLib.Uri url) {
        QWebEnginePage.url (url);
        this.enforce_https = url.scheme () == "https";
    }


    /***********************************************************
    ***********************************************************/
    protected bool certificate_error (QWebEngineCertificateError certificate_error) {
        /***********************************************************
        TODO properly improve this.
        The certificate should be displayed.

        Or rather we should do a request with the QNAM and see if it works (then it is in the store).
        This is just a quick fix for now.
        ***********************************************************/
        QMessageBox message_box;
        message_box.on_signal_text (_("Invalid certificate detected"));
        message_box.informative_text (_("The host \"%1\" provided an invalid certificate. Continue?").arg (certificate_error.url ().host ()));
        message_box.icon (QMessageBox.Warning);
        message_box.standard_buttons (QMessageBox.Yes|QMessageBox.No);
        message_box.default_button (QMessageBox.No);

        int ret = message_box.exec ();

        return ret == QMessageBox.Yes;
    }


    /***********************************************************
    ***********************************************************/
    protected bool accept_navigation_request (GLib.Uri url, QWebEnginePage.Navigation_type type, bool is_main_frame) {
        //  Q_UNUSED (type);
        //  Q_UNUSED (is_main_frame);

        if (this.enforce_https && url.scheme () != "https" && url.scheme () != "nc") {
            QMessageBox.warning (null, "Security warning", "Can not follow non https link on a https website. This might be a security issue. Please contact your administrator");
            return false;
        }
        return true;
    }

} // class WebEnginePage

} // namespace Ui
} // namespace Occ
