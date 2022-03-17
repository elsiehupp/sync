/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QInputDialog>
//  #include <QDesktopServices>
//  #include <QTimer>
//  #include <QBuffer>
//  #include <QMessageBox>

using QKeychain;

//  #include <QPointer>
//  #include <QTcpServer>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The HttpCredentialsGui class
@ingroup gui
***********************************************************/
public class HttpCredentialsGui : HttpCredentials {

    /***********************************************************
    ***********************************************************/
    private QScopedPointer<OAuth, QScopedPointerObjectDeleteLater<OAuth>> async_auth;

    internal signal void signal_authorisation_link_changed ();

    /***********************************************************
    ***********************************************************/
    public HttpCredentialsGui () {
        base ();
    }


    /***********************************************************
    ***********************************************************/
    public HttpCredentialsGui.with_username_and_password (
        string user, string password,
        string refresh_token = "",
        string client_cert_bundle, string client_cert_password) {
        base (user, password, client_cert_bundle, client_cert_password);
        if (refresh_token != "") {
            this.refresh_token = refresh_token;
        }
    }


    /***********************************************************
    This will query the server and either uses OAuth via this.async_auth.on_signal_start ()
    or call on_signal_show_dialog to ask the password
    ***********************************************************/
    public override void ask_from_user () {
        // This function can be called from AccountState.on_signal_invalid_credentials,
        // which (indirectly, through HttpCredentials.invalidate_token) schedules
        // a cache wipe of the qnam. We can only execute a network job again once
        // the cache has been cleared, otherwise we'd interfere with the job.
        QTimer.single_shot (100, this, HttpCredentialsGui.on_signal_ask_from_user_async);
    }


    /***********************************************************
    In case of oauth, return an URL to the link to open the browser.
    An invalid URL otherwise
    ***********************************************************/
    public GLib.Uri authorisation_link () {
        return this.async_auth ? this.async_auth.authorisation_link () : GLib.Uri ();
    }


    /***********************************************************
    ***********************************************************/
    static string request_app_password_text (Account account) {
        int version = account.server_version_int ();
        var url = account.url ().to_string ();
        if (url.ends_with ('/'))
            url.chop (1);

        if (version >= Account.make_server_version (13, 0, 0)) {
            url += "/index.php/settings/user/security";
        } else if (version >= Account.make_server_version (12, 0, 0)) {
            url += "/index.php/settings/personal#security";
        } else if (version >= Account.make_server_version (11, 0, 0)) {
            url += "/index.php/settings/user/security#security";
        } else {
            return "";
        }

        return _("<a href=\"%1\">Click here</a> to request an app password from the web interface.")
            .printf (url);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_async_auth_result (
        OAuth.Result r, string user,
        string token, string refresh_token) {
        switch (r) {
        case OAuth.Result.NOT_SUPPORTED:
            on_signal_show_dialog ();
            this.async_auth.on_signal_reset (null);
            return;
        case OAuth.Error:
            this.async_auth.on_signal_reset (null);
            /* emit */ asked ();
            return;
        case OAuth.Result.LOGGED_IN:
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


    /***********************************************************
    ***********************************************************/
    private void on_signal_show_dialog () {
        string message = _("Please enter %1 password:<br>"
                         + "<br>"
                         + "User: %2<br>"
                         + "Account: %3<br>")
                        .printf (Utility.escape (Theme.instance.app_name_gui ()),
                            Utility.escape (this.user),
                            Utility.escape (this.account.display_name ()));

        string req_txt = request_app_password_text (this.account);
        if (!req_txt == "") {
            message += "<br>" + req_txt + "<br>";
        }
        if (!this.fetch_error_string == "") {
            message += "<br>"
                + _("Reading from keychain failed with error : \"%1\"")
                    .printf (Utility.escape (this.fetch_error_string))
                + "<br>";
        }

        var dialog = new QInputDialog ();
        dialog.attribute (Qt.WA_DeleteOnClose, true);
        dialog.window_title (_("Enter Password"));
        dialog.label_text (message);
        dialog.text_value (this.previous_password);
        dialog.text_echo_mode (QLineEdit.Password);
        var dialog_label = dialog.find_child<Gtk.Label> ();
        if (dialog_label) {
            dialog_label.open_external_links (true);
            dialog_label.text_format (Qt.RichText);
        }

        dialog.open ();
        connect (
            dialog,
            Gtk.Dialog.signal_finished,
            this,
            this.on_signal_finished_with_result
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_finished_with_result (Gtk.Dialog dialog, int result) {
        if (result == Gtk.Dialog.Accepted) {
            this.password = dialog.text_value ();
            this.refresh_token.clear ();
            this.ready = true;
            persist ();
        }
        /* emit */ asked ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_ask_from_user_async () {
        // First, we will check what kind of auth we need.
        var job = new DetermineAuthTypeJob (
            this.account.shared_from_this (), this
        );
        connect (
            job,
            DetermineAuthTypeJob.auth_type,
            this, on_signal_auth_type
        );
        job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_auth_type (DetermineAuthTypeJob.AuthType type) {
        if (type == DetermineAuthTypeJob.AuthType.OAUTH) {

            this.async_auth.on_signal_reset (new OAuth (this.account, this));
            this.async_auth.expected_user = this.account.dav_user ();
            connect (
                this.async_auth,
                OAuth.result,
                this,
                HttpCredentialsGui.on_signal_async_auth_result
            );
            connect (
                this.async_auth,
                OAuth.destroyed,
                this,
                HttpCredentialsGui.signal_authorisation_link_changed
            );
            this.async_auth.on_signal_start ();
            /* emit */ signal_authorisation_link_changed ();
        } else if (type == DetermineAuthTypeJob.AuthType.BASIC) {
            on_signal_show_dialog ();
        } else {
            // Shibboleth?
            GLib.warning ("Bad http auth type: " + type);
            /* emit */ asked ();
        }
    }

} // class HttpCredentialsGui

} // namespace Ui
} // namespace Occ
