/***********************************************************
Copyright (C) 2014 by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <Gtk.Dialog>


namespace Occ {

/***********************************************************
@brief Authenticate a user for a specific credential given his credentials
@ingroup gui
***********************************************************/
class AuthenticationDialog : Gtk.Dialog {
public:
    AuthenticationDialog (string &realm, string &domain, Gtk.Widget *parent = nullptr);

    string user ();
    string password ();

private:
    QLineEdit *_user;
    QLineEdit *_password;
};

} // namespace Occ






/***********************************************************
Copyright (C) 2014 by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QLabel>
// #include <QLineEdit>
// #include <QVBoxLayout>
// #include <QFormLayout>
// #include <QDialogButtonBox>

namespace Occ {

    AuthenticationDialog.AuthenticationDialog (string &realm, string &domain, Gtk.Widget *parent)
        : Gtk.Dialog (parent)
        , _user (new QLineEdit)
        , _password (new QLineEdit) {
        setWindowTitle (tr ("Authentication Required"));
        auto *lay = new QVBoxLayout (this);
        auto *label = new QLabel (tr ("Enter username and password for \"%1\" at %2.").arg (realm, domain));
        label.setTextFormat (Qt.PlainText);
        lay.addWidget (label);
    
        auto *form = new QFormLayout;
        form.addRow (tr ("&User:"), _user);
        form.addRow (tr ("&Password:"), _password);
        lay.addLayout (form);
        _password.setEchoMode (QLineEdit.Password);
    
        auto *box = new QDialogButtonBox (QDialogButtonBox.Ok | QDialogButtonBox.Cancel, Qt.Horizontal);
        connect (box, &QDialogButtonBox.accepted, this, &Gtk.Dialog.accept);
        connect (box, &QDialogButtonBox.rejected, this, &Gtk.Dialog.reject);
        lay.addWidget (box);
    }
    
    string AuthenticationDialog.user () {
        return _user.text ();
    }
    
    string AuthenticationDialog.password () {
        return _password.text ();
    }
    
    } // namespace Occ
    