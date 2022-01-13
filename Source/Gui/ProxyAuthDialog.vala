/***********************************************************
Copyright (C) 2015 by Christian Kamm <kamm@incasoftware.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <Gtk.Dialog>

namespace Occ {

namespace Ui {
    class ProxyAuthDialog;
}

/***********************************************************
@brief Ask for username and password for a given proxy.

Used by ProxyAuthHandler.
***********************************************************/
class ProxyAuthDialog : Gtk.Dialog {

public:
    ProxyAuthDialog (Gtk.Widget *parent = nullptr);
    ~ProxyAuthDialog () override;

    void setProxyAddress (string &address);

    string username ();
    string password ();

    /// Resets the dialog for new credential entry.
    void reset ();

private:
    Ui.ProxyAuthDialog *ui;
};

    ProxyAuthDialog.ProxyAuthDialog (Gtk.Widget *parent)
        : Gtk.Dialog (parent)
        , ui (new Ui.ProxyAuthDialog) {
        ui.setupUi (this);
    }
    
    ProxyAuthDialog.~ProxyAuthDialog () {
        delete ui;
    }
    
    void ProxyAuthDialog.setProxyAddress (string &address) {
        ui.proxyAddress.setText (address);
    }
    
    string ProxyAuthDialog.username () {
        return ui.usernameEdit.text ();
    }
    
    string ProxyAuthDialog.password () {
        return ui.passwordEdit.text ();
    }
    
    void ProxyAuthDialog.reset () {
        ui.usernameEdit.setFocus ();
        ui.usernameEdit.clear ();
        ui.passwordEdit.clear ();
    }
    
    } // namespace Occ
    