

namespace Occ {

class Web_engine_page : QWeb_engine_page {

    /***********************************************************
    ***********************************************************/
    public Web_engine_page (QWeb_engine_profile profile, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 
    public QWeb_engine_page * create_window (QWeb_engine_page.Web_window_type type) override;
    public void set_url (GLib.Uri url);


    protected bool certificate_error (QWeb_engine_certificate_error certificate_error) override;

    protected bool accept_navigation_request (GLib.Uri url, QWeb_engine_page.Navigation_type type, bool is_main_frame) override;


    /***********************************************************
    ***********************************************************/
    private bool this.enforce_https = false;
}




Web_engine_page.Web_engine_page (QWeb_engine_profile profile, GLib.Object parent) : QWeb_engine_page (profile, parent) {

}

QWeb_engine_page * Web_engine_page.create_window (QWeb_engine_page.Web_window_type type) {
    Q_UNUSED (type);
    var view = new External_web_engine_page (this.profile ());
    return view;
}

void Web_engine_page.set_url (GLib.Uri url) {
    QWeb_engine_page.set_url (url);
    this.enforce_https = url.scheme () == QStringLiteral ("https");
}

bool Web_engine_page.certificate_error (QWeb_engine_certificate_error certificate_error) {
    /***********************************************************
    TODO properly improve this.
    The certificate should be displayed.

    Or rather we should do a request with the QNAM and see if it works (then it is in the store).
    This is just a quick fix for now.
    ***********************************************************/
    QMessageBox message_box;
    message_box.on_set_text (_("Invalid certificate detected"));
    message_box.set_informative_text (_("The host \"%1\" provided an invalid certificate. Continue?").arg (certificate_error.url ().host ()));
    message_box.set_icon (QMessageBox.Warning);
    message_box.set_standard_buttons (QMessageBox.Yes|QMessageBox.No);
    message_box.set_default_button (QMessageBox.No);

    int ret = message_box.exec ();

    return ret == QMessageBox.Yes;
}

bool Web_engine_page.accept_navigation_request (GLib.Uri url, QWeb_engine_page.Navigation_type type, bool is_main_frame) {
    Q_UNUSED (type);
    Q_UNUSED (is_main_frame);

    if (this.enforce_https && url.scheme () != QStringLiteral ("https") && url.scheme () != QStringLiteral ("nc")) {
        QMessageBox.warning (nullptr, "Security warning", "Can not follow non https link on a https website. This might be a security issue. Please contact your administrator");
        return false;
    }
    return true;
}