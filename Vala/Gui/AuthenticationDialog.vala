/***********************************************************
Copyright (C) 2014 by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLineEdit>
//  #include <QVBoxLayout>
//  #include <QFormLayout>
//  #include <QDialogButtonBox>
//  #include <Gtk.Dialog>

namespace Occ {
namespace Ui {

/***********************************************************
@brief Authenticate a user for a specific credential given
their credentials
@ingroup gui
***********************************************************/
public class AuthenticationDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    private QLineEdit user;
    private QLineEdit password;

    /***********************************************************
    ***********************************************************/
    public AuthenticationDialog (string realm, string domain, Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.user = new QLineEdit ();
        this.password = new QLineEdit ();
        window_title (_("Authentication Required"));
        var lay = new QVBoxLayout (this);
        var label = new Gtk.Label (_("Enter username and password for \"%1\" at %2.").printf (realm, domain));
        label.text_format (Qt.UpdateStatusStringFormat.PLAIN_TEXT);
        lay.add_widget (label);

        var form = new QFormLayout ();
        form.add_row (_("&User:"), this.user);
        form.add_row (_("&Password:"), this.password);
        lay.add_layout (form);
        this.password.echo_mode (QLineEdit.Password);

        var box = new QDialogButtonBox (QDialogButtonBox.Ok | QDialogButtonBox.Cancel, Qt.Horizontal);
        connect (box, QDialogButtonBox.accepted, this, Gtk.Dialog.accept);
        connect (box, QDialogButtonBox.rejected, this, Gtk.Dialog.reject);
        lay.add_widget (box);
    }


    /***********************************************************
    ***********************************************************/
    public string user_text () {
        return this.user.text ();
    }


    /***********************************************************
    ***********************************************************/
    public string password_text () {
        return this.password.text ();
    }

} // class AuthenticationDialog

} // namespace Ui
} // namespace Occ
