/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QInputDialog>
// #include <QLabel>
// #include <QDesktopServices>
// #include <QNetworkReply>
// #include <QTimer>
// #include <QBuffer>
// #include <QMessageBox>

using namespace QKeychain;

// #pragma once
// #include <QPointer>
// #include <QTcpServer>

namespace Occ {

/***********************************************************
@brief The HttpCredentialsGui class
@ingroup gui
***********************************************************/
class HttpCredentialsGui : HttpCredentials {

    public HttpCredentialsGui ()
        : HttpCredentials () {
    }
    public HttpCredentialsGui (string user, string password,
            const GLib.ByteArray client_cert_bundle, GLib.ByteArray client_cert_password)
        : HttpCredentials (user, password, client_cert_bundle, client_cert_password) {
    }
    public HttpCredentialsGui (string user, string password, string refresh_token,
            const GLib.ByteArray client_cert_bundle, GLib.ByteArray client_cert_password)
        : HttpCredentials (user, password, client_cert_bundle, client_cert_password) {
        _refresh_token = refresh_token;
    }


    /***********************************************************
    This will query the server and either uses OAuth via _async_auth.on_start ()
    or call on_show_dialog to ask the password
    ***********************************************************/
    public void ask_from_user () override;
    /***********************************************************
    In case of oauth, return an URL to the link to open the browser.
    An invalid URL otherwise
    ***********************************************************/
    public QUrl authorisation_link () {
        return _async_auth ? _async_auth.authorisation_link () : QUrl ();
    }

    static string request_app_password_text (Account account);

    private void on_async_auth_result (OAuth.Result, string user, string access_token, string refresh_token);
    private void on_show_dialog ();
    private void on_ask_from_user_async ();

signals:
    void authorisation_link_changed ();

    private QScopedPointer<OAuth, QScopedPointerObjectDeleteLater<OAuth>> _async_auth;
};


void HttpCredentialsGui.ask_from_user () {
    // This function can be called from AccountState.on_invalid_credentials,
    // which (indirectly, through HttpCredentials.invalidate_token) schedules
    // a cache wipe of the qnam. We can only execute a network job again once
    // the cache has been cleared, otherwise we'd interfere with the job.
    QTimer.single_shot (100, this, &HttpCredentialsGui.on_ask_from_user_async);
}

void HttpCredentialsGui.on_ask_from_user_async () {
    // First, we will check what kind of auth we need.
    var job = new DetermineAuthTypeJob (_account.shared_from_this (), this);
    GLib.Object.connect (job, &DetermineAuthTypeJob.auth_type, this, [this] (DetermineAuthTypeJob.AuthType type) {
        if (type == DetermineAuthTypeJob.OAuth) {
            _async_auth.on_reset (new OAuth (_account, this));
            _async_auth._expected_user = _account.dav_user ();
            connect (_async_auth.data (), &OAuth.result,
                this, &HttpCredentialsGui.on_async_auth_result);
            connect (_async_auth.data (), &OAuth.destroyed,
                this, &HttpCredentialsGui.authorisation_link_changed);
            _async_auth.on_start ();
            emit authorisation_link_changed ();
        } else if (type == DetermineAuthTypeJob.Basic) {
            on_show_dialog ();
        } else {
            // Shibboleth?
            q_c_warning (lc_http_credentials_gui) << "Bad http auth type:" << type;
            emit asked ();
        }
    });
    job.on_start ();
}

void HttpCredentialsGui.on_async_auth_result (OAuth.Result r, string user,
    const string token, string refresh_token) {
    switch (r) {
    case OAuth.NotSupported:
        on_show_dialog ();
        _async_auth.on_reset (nullptr);
        return;
    case OAuth.Error:
        _async_auth.on_reset (nullptr);
        emit asked ();
        return;
    case OAuth.LoggedIn:
        break;
    }

    ASSERT (_user == user); // ensured by _async_auth

    _password = token;
    _refresh_token = refresh_token;
    _ready = true;
    persist ();
    _async_auth.on_reset (nullptr);
    emit asked ();
}

void HttpCredentialsGui.on_show_dialog () {
    string msg = tr ("Please enter %1 password:<br>"
                     "<br>"
                     "User : %2<br>"
                     "Account : %3<br>")
                      .arg (Utility.escape (Theme.instance ().app_name_gui ()),
                          Utility.escape (_user),
                          Utility.escape (_account.display_name ()));

    string req_txt = request_app_password_text (_account);
    if (!req_txt.is_empty ()) {
        msg += QLatin1String ("<br>") + req_txt + QLatin1String ("<br>");
    }
    if (!_fetch_error_string.is_empty ()) {
        msg += QLatin1String ("<br>")
            + tr ("Reading from keychain failed with error : \"%1\"")
                  .arg (Utility.escape (_fetch_error_string))
            + QLatin1String ("<br>");
    }

    var dialog = new QInputDialog ();
    dialog.set_attribute (Qt.WA_DeleteOnClose, true);
    dialog.set_window_title (tr ("Enter Password"));
    dialog.set_label_text (msg);
    dialog.set_text_value (_previous_password);
    dialog.set_text_echo_mode (QLineEdit.Password);
    if (var dialog_label = dialog.find_child<QLabel> ()) {
        dialog_label.set_open_external_links (true);
        dialog_label.set_text_format (Qt.RichText);
    }

    dialog.open ();
    connect (dialog, &Gtk.Dialog.on_finished, this, [this, dialog] (int result) {
        if (result == Gtk.Dialog.Accepted) {
            _password = dialog.text_value ();
            _refresh_token.clear ();
            _ready = true;
            persist ();
        }
        emit asked ();
    });
}

string HttpCredentialsGui.request_app_password_text (Account account) {
    int version = account.server_version_int ();
    var url = account.url ().to_string ();
    if (url.ends_with ('/'))
        url.chop (1);

    if (version >= Account.make_server_version (13, 0, 0)) {
        url += QLatin1String ("/index.php/settings/user/security");
    } else if (version >= Account.make_server_version (12, 0, 0)) {
        url += QLatin1String ("/index.php/settings/personal#security");
    } else if (version >= Account.make_server_version (11, 0, 0)) {
        url += QLatin1String ("/index.php/settings/user/security#security");
    } else {
        return string ();
    }

    return tr ("<a href=\"%1\">Click here</a> to request an app password from the web interface.")
        .arg (url);
}
} // namespace Occ
