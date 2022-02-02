/***********************************************************
Copyright (C) 2015 by Christian Kamm <kamm@incasoftware.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <Gtk.Dialog>

namespace Occ {

namespace Ui {
    class Proxy_auth_dialog;
}

/***********************************************************
@brief Ask for username and password for a given proxy.

Used by ProxyAuthHandler.
***********************************************************/
class Proxy_auth_dialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    public Proxy_auth_dialog (Gtk.Widget parent = nullptr);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public string password ();

    /// Resets the dialog for new credential entry.
    public void on_reset ();


    /***********************************************************
    ***********************************************************/
    private Ui.Proxy_auth_dialog ui;
}

    Proxy_auth_dialog.Proxy_auth_dialog (Gtk.Widget parent)
        : Gtk.Dialog (parent)
        , ui (new Ui.Proxy_auth_dialog) {
        ui.setup_ui (this);
    }

    Proxy_auth_dialog.~Proxy_auth_dialog () {
        delete ui;
    }

    void Proxy_auth_dialog.set_proxy_address (string address) {
        ui.proxy_address.on_set_text (address);
    }

    string Proxy_auth_dialog.username () {
        return ui.username_edit.text ();
    }

    string Proxy_auth_dialog.password () {
        return ui.password_edit.text ();
    }

    void Proxy_auth_dialog.on_reset () {
        ui.username_edit.set_focus ();
        ui.username_edit.clear ();
        ui.password_edit.clear ();
    }

    } // namespace Occ
    