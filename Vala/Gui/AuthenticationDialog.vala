/***********************************************************
Copyright (C) 2014 by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLabel>
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
class AuthenticationDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    public AuthenticationDialog (string realm, string domain, Gtk.Widget parent = null);

    /***********************************************************
    ***********************************************************/
    public string user ();

    /***********************************************************
    ***********************************************************/
    public string password ();


    /***********************************************************
    ***********************************************************/
    private QLineEdit this.user;
    private QLineEdit this.password;
}



    AuthenticationDialog.AuthenticationDialog (string realm, string domain, Gtk.Widget parent)
        : Gtk.Dialog (parent)
        this.user (new QLineEdit)
        this.password (new QLineEdit) {
        window_title (_("Authentication Required"));
        var lay = new QVBoxLayout (this);
        var label = new QLabel (_("Enter username and password for \"%1\" at %2.").arg (realm, domain));
        label.text_format (Qt.PlainText);
        lay.add_widget (label);

        var form = new QFormLayout;
        form.add_row (_("&User:"), this.user);
        form.add_row (_("&Password:"), this.password);
        lay.add_layout (form);
        this.password.echo_mode (QLineEdit.Password);

        var box = new QDialogButtonBox (QDialogButtonBox.Ok | QDialogButtonBox.Cancel, Qt.Horizontal);
        connect (box, &QDialogButtonBox.accepted, this, &Gtk.Dialog.accept);
        connect (box, &QDialogButtonBox.rejected, this, &Gtk.Dialog.reject);
        lay.add_widget (box);
    }

    string AuthenticationDialog.user () {
        return this.user.text ();
    }

    string AuthenticationDialog.password () {
        return this.password.text ();
    }

    } // namespace Occ
    