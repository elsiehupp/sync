/***********************************************************
Copyright (C) 2015 by Jeroen Hoek
Copyright (C) 2015 by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
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
    private Ui.OwncloudConnectionMethodDialog ui;


    /***********************************************************
    ***********************************************************/
    public OwncloudConnectionMethodDialog (Gtk.Widget parent = null) {
        base (parent, Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.MSWindowsFixedSizeDialogHint);
        this.ui = new Ui.OwncloudConnectionMethodDialog ();
        ui.up_ui (this);

        connect (
            ui.btn_no_tls,
            QAbstractButton.clicked,
            this,
            OwncloudConnectionMethodDialog.on_signal_return_no_tls
        );
        connect (
            ui.btn_client_side_tLS,
            QAbstractButton.clicked,
            this,
            OwncloudConnectionMethodDialog.on_signal_return_client_side_tls
        );
        connect (
            ui.btn_back,
            QAbstractButton.clicked,
            this,
            OwncloudConnectionMethodDialog.return_back
        );
    }


    /***********************************************************
    ***********************************************************/
    ~OwncloudConnectionMethodDialog () {
        delete ui;
    }


    /***********************************************************
    The URL that was tried
    ***********************************************************/
    public void url (GLib.Uri url) {
        ui.label.on_signal_text (_("<html><head/><body><p>Failed to connect to the secure server address <em>%1</em>. How do you wish to proceed?</p></body></html>").printf (url.to_display_string ().to_html_escaped ()));
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

    