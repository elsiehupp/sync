/***********************************************************
Copyright (C) 2015 by Christian Kamm <kamm@incasoftware.de>
@copyright GPLv3 or Later
***********************************************************/

//  #include <Gtk.Dialog>

namespace Occ {
namespace Ui {

/***********************************************************
@brief Ask for username and password for a given proxy.

Used by ProxyAuthHandler.
***********************************************************/
public class ProxyAuthDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    private Ui.ProxyAuthDialog ui;

    /***********************************************************
    ***********************************************************/
    public ProxyAuthDialog (Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.ui = new Ui.ProxyAuthDialog ();
        ui.up_ui (this);
    }


    ~ProxyAuthDialog () {
        delete ui;
    }


    /***********************************************************
    ***********************************************************/
    public void proxy_address (string address) {
        ui.proxy_address.on_signal_text (address);
    }


    /***********************************************************
    ***********************************************************/
    public string username () {
        return ui.username_edit.text ();
    }


    /***********************************************************
    ***********************************************************/
    public string password () {
        return ui.password_edit.text ();
    }


    /***********************************************************
    Resets the dialog for new credential entry.
    ***********************************************************/
    public void on_signal_reset () {
        ui.username_edit.focus ();
        ui.username_edit.clear ();
        ui.password_edit.clear ();
    }

} // class ProxyAuthDialog

} // namespace Ui
} // namespace Occ
    