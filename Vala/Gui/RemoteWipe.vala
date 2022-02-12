/***********************************************************
Copyright (C) by Camila Ayres <hello@camila.codes>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QJsonDocument>
//  #include <QJsonObject>
//  #include <QNetworkRequest>
//  #include <QBuffer>
//  #include <QNetworkAccessManager>

namespace Occ {
namespace Ui {

class RemoteWipe : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public RemoteWipe (AccountPointer account, GLib.Object parent = new GLib.Object ());

signals:
    /***********************************************************
    Notify if wipe was requested
    ***********************************************************/
    void authorized (AccountState*);


    /***********************************************************
    Notify if user only needs to log in again
    ***********************************************************/
    void ask_user_credentials ();


    /***********************************************************
    Once receives a 401 or 403 status response it will do a
    fetch to <server>/index.php/core/wipe/check
    ***********************************************************/
    public void on_signal_start_check_job_with_app_password (string);


    /***********************************************************
    If wipe is requested, delete account and data, if not
    continue by asking the user to log in again
    ***********************************************************/
    private void on_signal_check_job_slot ();


    /***********************************************************
    Once the client has wiped all the required data a POST to
    <server>/index.php/core/wipe/on_signal_success
    ***********************************************************/
    private void on_signal_notify_server_success_job (AccountState account_state, bool);
    private void on_signal_notify_server_success_job_slot ();


    /***********************************************************
    ***********************************************************/
    private AccountPointer this.account;
    private string this.app_password;
    private bool this.account_removed;
    private QNetworkAccessManager this.network_manager;
    private Soup.Reply this.network_reply_check;
    private Soup.Reply this.network_reply_success;

    /***********************************************************
    ***********************************************************/
    private friend class .Test_remote_wipe;
}

    RemoteWipe.RemoteWipe (AccountPointer account, GLib.Object parent)
        : GLib.Object (parent),
          this.account (account),
          this.app_password (""),
          this.account_removed (false),
          this.network_manager (null),
          this.network_reply_check (null),
          this.network_reply_success (null) {
        GLib.Object.connect (AccountManager.instance (), &AccountManager.on_signal_account_removed,
                         this, [=] (AccountState *) {
            this.account_removed = true;
        });
        GLib.Object.connect (this, &RemoteWipe.authorized, FolderMan.instance (),
                         &FolderMan.on_signal_wipe_folder_for_account);
        GLib.Object.connect (FolderMan.instance (), &FolderMan.signal_wipe_done, this,
                         &RemoteWipe.on_signal_notify_server_success_job);
        GLib.Object.connect (this.account.data (), &Account.app_password_retrieved, this,
                         &RemoteWipe.on_signal_start_check_job_with_app_password);
    }

    void RemoteWipe.on_signal_start_check_job_with_app_password (string pwd) {
        if (pwd.is_empty ())
            return;

        this.app_password = pwd;
        GLib.Uri request_url = Utility.concat_url_path (this.account.url ().to_string (),
                                                 QLatin1String ("/index.php/core/wipe/check"));
        QNetworkRequest request;
        request.header (QNetworkRequest.ContentTypeHeader,
                          "application/x-www-form-urlencoded");
        request.url (request_url);
        request.ssl_configuration (this.account.get_or_create_ssl_config ());
        var request_body = new QBuffer;
        QUrlQuery arguments (string ("token=%1").arg (this.app_password));
        request_body.data (arguments.query (GLib.Uri.FullyEncoded).to_latin1 ());
        this.network_reply_check = this.network_manager.post (request, request_body);
        GLib.Object.connect (&this.network_manager, SIGNAL (ssl_errors (Soup.Reply *, GLib.List<QSslError>)),
            this.account.data (), SLOT (on_signal_handle_ssl_errors (Soup.Reply *, GLib.List<QSslError>)));
        GLib.Object.connect (this.network_reply_check, &Soup.Reply.on_signal_finished, this,
                         &RemoteWipe.on_signal_check_job_slot);
    }

    void RemoteWipe.on_signal_check_job_slot () {
        var json_data = this.network_reply_check.read_all ();
        QJsonParseError json_parse_error;
        QJsonObject json = QJsonDocument.from_json (json_data, json_parse_error).object ();
        bool wipe = false;

        //check for errors
        if (this.network_reply_check.error () != Soup.Reply.NoError ||
                json_parse_error.error != QJsonParseError.NoError) {
            string error_reason;
            string error_from_json = json["error"].to_string ();
            if (!error_from_json.is_empty ()) {
                GLib.warning () + string ("Error returned from the server : <em>%1<em>")
                                           .arg (error_from_json.to_html_escaped ());
            } else if (this.network_reply_check.error () != Soup.Reply.NoError) {
                GLib.warning () + string ("There was an error accessing the 'token' endpoint : <br><em>%1</em>")
                                  .arg (this.network_reply_check.error_string ().to_html_escaped ());
            } else if (json_parse_error.error != QJsonParseError.NoError) {
                GLib.warning () + string ("Could not parse the JSON returned from the server : <br><em>%1</em>")
                                  .arg (json_parse_error.error_string ());
            } else {
                GLib.warning () +  string ("The reply from the server did not contain all expected fields");
            }

        // check for wipe request
        } else if (!json.value ("wipe").is_undefined ()) {
            wipe = json["wipe"].to_bool ();
        }

        var manager = AccountManager.instance ();
        var account_state = manager.account (this.account.display_name ()).data ();

        if (wipe) {
            /* IMPORTANT - remove later - FIXME MS@2019-12-07 -.
            TODO : For "Log out" & "Remove account" : Remove client CA certificates and KEY!

                  Disabled as long as selecting another cert is not supported by the UI.

                  Being able to specify a new certificate is important anyway : expiry etc.

                  We introduce this dirty hack here, to allow deleting them upon Remote Wipe.
             */
            this.account.remote_wipe_requested_HACK ();
            // <-- FIXME MS@2019-12-07

            // delete account
            manager.delete_account (account_state);
            manager.save ();

            // delete data
            /* emit */ authorized (account_state);

        } else {
            // ask user for his credentials again
            account_state.handle_invalid_credentials ();
        }

        this.network_reply_check.delete_later ();
    }

    void RemoteWipe.on_signal_notify_server_success_job (AccountState account_state, bool data_wiped) {
        if (this.account_removed && data_wiped && this.account == account_state.account ()) {
            GLib.Uri request_url = Utility.concat_url_path (this.account.url ().to_string (),
                                                     QLatin1String ("/index.php/core/wipe/on_signal_success"));
            QNetworkRequest request;
            request.header (QNetworkRequest.ContentTypeHeader,
                              "application/x-www-form-urlencoded");
            request.url (request_url);
            request.ssl_configuration (this.account.get_or_create_ssl_config ());
            var request_body = new QBuffer;
            QUrlQuery arguments (string ("token=%1").arg (this.app_password));
            request_body.data (arguments.query (GLib.Uri.FullyEncoded).to_latin1 ());
            this.network_reply_success = this.network_manager.post (request, request_body);
            GLib.Object.connect (this.network_reply_success, &Soup.Reply.on_signal_finished, this,
                             &RemoteWipe.on_signal_notify_server_success_job_slot);
        }
    }

    void RemoteWipe.on_signal_notify_server_success_job_slot () {
        var json_data = this.network_reply_success.read_all ();
        QJsonParseError json_parse_error;
        QJsonObject json = QJsonDocument.from_json (json_data, json_parse_error).object ();
        if (this.network_reply_success.error () != Soup.Reply.NoError ||
                json_parse_error.error != QJsonParseError.NoError) {
            string error_reason;
            string error_from_json = json["error"].to_string ();
            if (!error_from_json.is_empty ()) {
                GLib.warning () + string ("Error returned from the server : <em>%1</em>")
                                  .arg (error_from_json.to_html_escaped ());
            } else if (this.network_reply_success.error () != Soup.Reply.NoError) {
                GLib.warning () + string ("There was an error accessing the 'on_signal_success' endpoint : <br><em>%1</em>")
                                  .arg (this.network_reply_success.error_string ().to_html_escaped ());
            } else if (json_parse_error.error != QJsonParseError.NoError) {
                GLib.warning () + string ("Could not parse the JSON returned from the server : <br><em>%1</em>")
                                  .arg (json_parse_error.error_string ());
            } else {
                GLib.warning () + string ("The reply from the server did not contain all expected fields.");
            }
        }

        this.network_reply_success.delete_later ();
    }
    }
    