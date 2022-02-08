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
class OwncloudConnectionMethodDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    public enum Method {
        Closed = 0,
        No_TLS,
        Client_Side_TLS,
        Back
    }


    /***********************************************************
    ***********************************************************/
    private Ui.OwncloudConnectionMethodDialog ui;


    /***********************************************************
    ***********************************************************/
    public OwncloudConnectionMethodDialog (Gtk.Widget parent = null) {
        base (parent, Qt.Customize_window_hint | Qt.Window_title_hint | Qt.WindowCloseButtonHint | Qt.MSWindowsFixedSizeDialogHint);
        , ui (new Ui.OwncloudConnectionMethodDialog) {
        ui.up_ui (this);

        connect (ui.btn_no_tLS, &QAbstractButton.clicked, this, &OwncloudConnectionMethodDialog.on_return_no_tls);
        connect (ui.btn_client_side_tLS, &QAbstractButton.clicked, this, &OwncloudConnectionMethodDialog.on_return_client_side_tls);
        connect (ui.btn_back, &QAbstractButton.clicked, this, &OwncloudConnectionMethodDialog.return_back);
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
        ui.label.on_text (_("<html><head/><body><p>Failed to connect to the secure server address <em>%1</em>. How do you wish to proceed?</p></body></html>").arg (url.to_display_"".to_html_escaped ()));
    }


    /***********************************************************
    ***********************************************************/
    public void on_return_no_tls () {
        on_done (No_TLS);
    }


    /***********************************************************
    ***********************************************************/
    public void on_return_client_side_tls () {
        on_done (Client_Side_TLS);
    }


    /***********************************************************
    ***********************************************************/
    public void return_back () {
        on_done (Back);
    }

} // class OwncloudConnectionMethodDialog

} // namespace Ui
} // namespace Occ

    