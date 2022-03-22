/***********************************************************
@author 2015 by Jeroen Hoek
@author 2015 by Olivier Goffart <ogoffart@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <Gtk.Dialog>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The OwncloudConnectionMethodDialog class
@ingroup gui
***********************************************************/
public class OwncloudConnectionMethodDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    public enum Method {
        CLOSED = 0,
        NO_TLS,
        CLIENT_SIDE_TLS,
        BACK
    }


    /***********************************************************
    ***********************************************************/
    private OwncloudConnectionMethodDialog instance;


    /***********************************************************
    ***********************************************************/
    public OwncloudConnectionMethodDialog (Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent, Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.MSWindowsFixedSizeDialogHint);
        this.instance = new OwncloudConnectionMethodDialog ();
        instance.up_ui (this);

        instance.no_tls_button.clicked.connect (
            this.on_signal_return_no_tls
        );
        instance.client_side_tls_button.clicked.connect (
            this.on_signal_return_client_side_tls
        );
        instance.back_button.clicked.connect (
            this.return_back
        );
    }


    /***********************************************************
    ***********************************************************/
    ~OwncloudConnectionMethodDialog () {
        delete instance;
    }


    /***********************************************************
    The URL that was tried
    ***********************************************************/
    public void url (GLib.Uri url) {
        instance.label.on_signal_text (_("<html><head/><body><p>Failed to connect to the secure server address <em>%1</em>. How do you wish to proceed?</p></body></html>").printf (url.to_display_string ().to_html_escaped ()));
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_return_no_tls () {
        on_signal_done (Method.NO_TLS);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_return_client_side_tls () {
        on_signal_done (Method.CLIENT_SIDE_TLS);
    }


    /***********************************************************
    ***********************************************************/
    public void return_back () {
        on_signal_done (Method.BACK);
    }

} // class OwncloudConnectionMethodDialog

} // namespace Ui
} // namespace Occ

    