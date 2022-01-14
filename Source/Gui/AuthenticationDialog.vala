/***********************************************************
Copyright (C) 2014 by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLabel>
// #include <QLineEdit>
// #include <QVBoxLayout>
// #include <QFormLayout>
// #include <QDialogButtonBox>

// #include <Gtk.Dialog>


namespace Occ {

/***********************************************************
@brief Authenticate a user for a specific credential given his credentials
@ingroup gui
***********************************************************/
class AuthenticationDialog : Gtk.Dialog {

    public AuthenticationDialog (string &realm, string &domain, Gtk.Widget *parent = nullptr);

    public string user ();
    public string password ();

private:
    QLineEdit *_user;
    QLineEdit *_password;
};



    AuthenticationDialog.AuthenticationDialog (string &realm, string &domain, Gtk.Widget *parent)
        : Gtk.Dialog (parent)
        , _user (new QLineEdit)
        , _password (new QLineEdit) {
        set_window_title (tr ("Authentication Required"));
        auto *lay = new QVBoxLayout (this);
        auto *label = new QLabel (tr ("Enter username and password for \"%1\" at %2.").arg (realm, domain));
        label.set_text_format (Qt.PlainText);
        lay.add_widget (label);

        auto *form = new QFormLayout;
        form.add_row (tr ("&User:"), _user);
        form.add_row (tr ("&Password:"), _password);
        lay.add_layout (form);
        _password.set_echo_mode (QLineEdit.Password);

        auto *box = new QDialogButtonBox (QDialogButtonBox.Ok | QDialogButtonBox.Cancel, Qt.Horizontal);
        connect (box, &QDialogButtonBox.accepted, this, &Gtk.Dialog.accept);
        connect (box, &QDialogButtonBox.rejected, this, &Gtk.Dialog.reject);
        lay.add_widget (box);
    }

    string AuthenticationDialog.user () {
        return _user.text ();
    }

    string AuthenticationDialog.password () {
        return _password.text ();
    }

    } // namespace Occ
    