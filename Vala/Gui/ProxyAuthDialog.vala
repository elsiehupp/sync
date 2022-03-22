/***********************************************************
@author 2015 by Christian Kamm <kamm@incasoftware.de>

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
    private ProxyAuthDialog instance;

    /***********************************************************
    ***********************************************************/
    public ProxyAuthDialog (Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.instance = new ProxyAuthDialog ();
        instance.up_ui (this);
    }


    ~ProxyAuthDialog () {
        //  delete this.instance;
    }


    /***********************************************************
    ***********************************************************/
    public void proxy_address (string address) {
        instance.proxy_address.on_signal_text (address);
    }


    /***********************************************************
    ***********************************************************/
    public string username () {
        return instance.username_edit.text ();
    }


    /***********************************************************
    ***********************************************************/
    public string password () {
        return instance.password_edit.text ();
    }


    /***********************************************************
    Resets the dialog for new credential entry.
    ***********************************************************/
    public void on_signal_reset () {
        instance.username_edit.focus ();
        instance.username_edit == "";
        instance.password_edit == "";
    }

} // class ProxyAuthDialog

} // namespace Ui
} // namespace Occ
    