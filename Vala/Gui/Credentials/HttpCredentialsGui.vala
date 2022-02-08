/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QInputDialog>
//  #include <Gtk.Label>
//  #include <QDesktopServices>
//  #include <QTimer>
//  #include <QBuffer>
//  #include <QMessageBox>

using namespace QKeychain;

//  #include <QPointer>
//  #include <QTcpServer>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The HttpCredentialsGui class
@ingroup gui
***********************************************************/
class HttpCredentialsGui : HttpCredentials {

    /***********************************************************
    ***********************************************************/
    public HttpCredentialsGui ()
        : HttpCredentials () {
    }


    /***********************************************************
    ***********************************************************/
    public HttpCredentialsGui (string user, string password,
            const GLib.ByteArray client_cert_bundle, GLib.ByteArray client_cert_password)
        : HttpCredentials (user, password, client_cert_bundle, client_cert_password) {
    }


    /***********************************************************
    ***********************************************************/
    public HttpCredentialsGui (string user, string password, string refresh_token,
            const GLib.ByteArray client_cert_bundle, GLib.ByteArray client_cert_password)
        : HttpCredentials (user, password, client_cert_bundle, client_cert_password) {
        this.refresh_token = refresh_token;
    }


    /***********************************************************
    This will query the server and either uses OAuth via this.async_auth.on_signal_start ()
    or call on_signal_show_dialog to ask the password
    ***********************************************************/
    public void ask_from_user () override;
    /***********************************************************
    In case of oauth, return an URL to the link to open the browser.
    An invalid URL otherwise
    ***********************************************************/
    public GLib.Uri authorisation_link () {
        return this.async_auth ? this.async_auth.authorisation_link () : GLib.Uri ();
    }


    /***********************************************************
    ***********************************************************/
    static string request_app_password_text (Account account);

    /***********************************************************
    ***********************************************************/
    private void on_signal_async_auth_result (OAuth.Result, string user, string access_token, string refresh_token);
    private void on_signal_show_dialog ();
    private void on_signal_ask_from_user_async ();

signals:
    void authorisation_link_changed ();

    /***********************************************************
    ***********************************************************/
    private QScopedPointer<OAuth, QScopedPointerObjectDeleteLater<OAuth>> this.async_auth;
}


void HttpCredentialsGui.ask_from_user () {
    // This function can be called from AccountState.on_signal_invalid_credentials,
    // which (indirectly, through HttpCredentials.invalidate_token) schedules
    // a cache wipe of the qnam. We can only execute a network job again once
    // the cache has been cleared, otherwise we'd interfere with the job.
    QTimer.single_shot (100, this, &HttpCredentialsGui.on_signal_ask_from_user_async);
}

void HttpCredentialsGui.on_signal_ask_from_user_async () {
    // First, we will check what kind of auth we need.
    var job = new DetermineAuthTypeJob (this.account.shared_from_this (), this);
    GLib.Object.connect (job, &DetermineAuthTypeJob.auth_type, this, [this] (DetermineAuthTypeJob.AuthType type) {
        if (type == DetermineAuthTypeJob.AuthType.OAUTH) {
            this.async_auth.on_signal_reset (new OAuth (this.account, this));
            this.async_auth.expected_user = this.account.dav_user ();
            connect (this.async_auth.data (), &OAuth.result,
                this, &HttpCredentialsGui.on_signal_async_auth_result);
            connect (this.async_auth.data (), &OAuth.destroyed,
                this, &HttpCredentialsGui.authorisation_link_changed);
            this.async_auth.on_signal_start ();
            /* emit */ authorisation_link_changed ();
        } else if (type == DetermineAuthTypeJob.AuthType.BASIC) {
            on_signal_show_dialog ();
        } else {
            // Shibboleth?
            GLib.warn ("Bad http auth type:" + type;
            /* emit */ asked ();
        }
    });
    job.on_signal_start ();
}

void HttpCredentialsGui.on_signal_async_auth_result (OAuth.Result r, string user,
    const string token, string refresh_token) {
    switch (r) {
    case OAuth.NotSupported:
        on_signal_show_dialog ();
        this.async_auth.on_signal_reset (null);
        return;
    case OAuth.Error:
        this.async_auth.on_signal_reset (null);
        /* emit */ asked ();
        return;
    case OAuth.LoggedIn:
        break;
    }

    //  ASSERT (this.user == user); // ensured by this.async_auth

    this.password = token;
    this.refresh_token = refresh_token;
    this.ready = true;
    persist ();
    this.async_auth.on_signal_reset (null);
    /* emit */ asked ();
}

void HttpCredentialsGui.on_signal_show_dialog () {
    string message = _("Please enter %1 password:<br>"
                     "<br>"
                     "User : %2<br>"
                     "Account : %3<br>")
                      .arg (Utility.escape (Theme.instance ().app_name_gui ()),
                          Utility.escape (this.user),
                          Utility.escape (this.account.display_name ()));

    string req_txt = request_app_password_text (this.account);
    if (!req_txt.is_empty ()) {
        message += QLatin1String ("<br>") + req_txt + QLatin1String ("<br>");
    }
    if (!this.fetch_error_string.is_empty ()) {
        message += QLatin1String ("<br>")
            + _("Reading from keychain failed with error : \"%1\"")
                  .arg (Utility.escape (this.fetch_error_string))
            + QLatin1String ("<br>");
    }

    var dialog = new QInputDialog ();
    dialog.attribute (Qt.WA_DeleteOnClose, true);
    dialog.window_title (_("Enter Password"));
    dialog.label_text (message);
    dialog.text_value (this.previous_password);
    dialog.text_echo_mode (QLineEdit.Password);
    if (var dialog_label = dialog.find_child<Gtk.Label> ()) {
        dialog_label.open_external_links (true);
        dialog_label.text_format (Qt.RichText);
    }

    dialog.open ();
    connect (dialog, &Gtk.Dialog.on_signal_finished, this, [this, dialog] (int result) {
        if (result == Gtk.Dialog.Accepted) {
            this.password = dialog.text_value ();
            this.refresh_token.clear ();
            this.ready = true;
            persist ();
        }
        /* emit */ asked ();
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
        return "";
    }

    return _("<a href=\"%1\">Click here</a> to request an app password from the web interface.")
        .arg (url);
}
} // namespace Occ
