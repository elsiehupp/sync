/***********************************************************
Copyright (C) by Camila Ayres <hello@camila.codes>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QJsonDocument>
// #include <QJsonObject>
// #include <QNetworkRequest>
// #include <QBuffer>

// #include <QNetworkAccessManager>


namespace Occ {

class RemoteWipe : GLib.Object {

    public RemoteWipe (AccountPtr account, GLib.Object parent = nullptr);

signals:
    /***********************************************************
    Notify if wipe was requested
    ***********************************************************/
    void authorized (AccountState*);


    /***********************************************************
    Notify if user only needs to login again
    ***********************************************************/
    void ask_user_credentials ();


    /***********************************************************
    Once receives a 401 or 403 status response it will do a fetch to
    <server>/index.php/core/wipe/check
    ***********************************************************/
    public void on_start_check_job_with_app_password (string);


    /***********************************************************
    If wipe is requested, delete account and data, if not continue by asking
    the user to login again
    ***********************************************************/
    private void on_check_job_slot ();


    /***********************************************************
    Once the client has wiped all the required data a POST to
    <server>/index.php/core/wipe/on_success
    ***********************************************************/
    private void on_notify_server_success_job (AccountState account_state, bool);
    private void on_notify_server_success_job_slot ();


    private AccountPtr _account;
    private string _app_password;
    private bool _account_removed;
    private QNetworkAccessManager _network_manager;
    private QNetworkReply _network_reply_check;
    private QNetworkReply _network_reply_success;

    private friend class .Test_remote_wipe;
};

    RemoteWipe.RemoteWipe (AccountPtr account, GLib.Object parent)
        : GLib.Object (parent),
          _account (account),
          _app_password (string ()),
          _account_removed (false),
          _network_manager (nullptr),
          _network_reply_check (nullptr),
          _network_reply_success (nullptr) {
        GLib.Object.connect (AccountManager.instance (), &AccountManager.on_account_removed,
                         this, [=] (AccountState *) {
            _account_removed = true;
        });
        GLib.Object.connect (this, &RemoteWipe.authorized, FolderMan.instance (),
                         &FolderMan.on_wipe_folder_for_account);
        GLib.Object.connect (FolderMan.instance (), &FolderMan.wipe_done, this,
                         &RemoteWipe.on_notify_server_success_job);
        GLib.Object.connect (_account.data (), &Account.app_password_retrieved, this,
                         &RemoteWipe.on_start_check_job_with_app_password);
    }

    void RemoteWipe.on_start_check_job_with_app_password (string pwd){
        if (pwd.is_empty ())
            return;

        _app_password = pwd;
        QUrl request_url = Utility.concat_url_path (_account.url ().to_string (),
                                                 QLatin1String ("/index.php/core/wipe/check"));
        QNetworkRequest request;
        request.set_header (QNetworkRequest.ContentTypeHeader,
                          "application/x-www-form-urlencoded");
        request.set_url (request_url);
        request.set_ssl_configuration (_account.get_or_create_ssl_config ());
        var request_body = new QBuffer;
        QUrlQuery arguments (string ("token=%1").arg (_app_password));
        request_body.set_data (arguments.query (QUrl.FullyEncoded).to_latin1 ());
        _network_reply_check = _network_manager.post (request, request_body);
        GLib.Object.connect (&_network_manager, SIGNAL (ssl_errors (QNetworkReply *, GLib.List<QSslError>)),
            _account.data (), SLOT (on_handle_ssl_errors (QNetworkReply *, GLib.List<QSslError>)));
        GLib.Object.connect (_network_reply_check, &QNetworkReply.on_finished, this,
                         &RemoteWipe.on_check_job_slot);
    }

    void RemoteWipe.on_check_job_slot () {
        var json_data = _network_reply_check.read_all ();
        QJsonParseError json_parse_error;
        QJsonObject json = QJsonDocument.from_json (json_data, &json_parse_error).object ();
        bool wipe = false;

        //check for errors
        if (_network_reply_check.error () != QNetworkReply.NoError ||
                json_parse_error.error != QJsonParseError.NoError) {
            string error_reason;
            string error_from_json = json["error"].to_string ();
            if (!error_from_json.is_empty ()) {
                q_c_warning (lc_remote_wipe) << string ("Error returned from the server : <em>%1<em>")
                                           .arg (error_from_json.to_html_escaped ());
            } else if (_network_reply_check.error () != QNetworkReply.NoError) {
                q_c_warning (lc_remote_wipe) << string ("There was an error accessing the 'token' endpoint : <br><em>%1</em>")
                                  .arg (_network_reply_check.error_string ().to_html_escaped ());
            } else if (json_parse_error.error != QJsonParseError.NoError) {
                q_c_warning (lc_remote_wipe) << string ("Could not parse the JSON returned from the server : <br><em>%1</em>")
                                  .arg (json_parse_error.error_string ());
            } else {
                q_c_warning (lc_remote_wipe) <<  string ("The reply from the server did not contain all expected fields");
            }

        // check for wipe request
        } else if (!json.value ("wipe").is_undefined ()){
            wipe = json["wipe"].to_bool ();
        }

        var manager = AccountManager.instance ();
        var account_state = manager.account (_account.display_name ()).data ();

        if (wipe){
            /* IMPORTANT - remove later - FIXME MS@2019-12-07 -.
            TODO : For "Log out" & "Remove account" : Remove client CA certs and KEY!

                  Disabled as long as selecting another cert is not supported by the UI.

                  Being able to specify a new certificate is important anyway : expiry etc.

                  We introduce this dirty hack here, to allow deleting them upon Remote Wipe.
             */
            _account.set_remote_wipe_requested_HACK ();
            // <-- FIXME MS@2019-12-07

            // delete account
            manager.delete_account (account_state);
            manager.save ();

            // delete data
            emit authorized (account_state);

        } else {
            // ask user for his credentials again
            account_state.handle_invalid_credentials ();
        }

        _network_reply_check.delete_later ();
    }

    void RemoteWipe.on_notify_server_success_job (AccountState account_state, bool data_wiped){
        if (_account_removed && data_wiped && _account == account_state.account ()){
            QUrl request_url = Utility.concat_url_path (_account.url ().to_string (),
                                                     QLatin1String ("/index.php/core/wipe/on_success"));
            QNetworkRequest request;
            request.set_header (QNetworkRequest.ContentTypeHeader,
                              "application/x-www-form-urlencoded");
            request.set_url (request_url);
            request.set_ssl_configuration (_account.get_or_create_ssl_config ());
            var request_body = new QBuffer;
            QUrlQuery arguments (string ("token=%1").arg (_app_password));
            request_body.set_data (arguments.query (QUrl.FullyEncoded).to_latin1 ());
            _network_reply_success = _network_manager.post (request, request_body);
            GLib.Object.connect (_network_reply_success, &QNetworkReply.on_finished, this,
                             &RemoteWipe.on_notify_server_success_job_slot);
        }
    }

    void RemoteWipe.on_notify_server_success_job_slot () {
        var json_data = _network_reply_success.read_all ();
        QJsonParseError json_parse_error;
        QJsonObject json = QJsonDocument.from_json (json_data, &json_parse_error).object ();
        if (_network_reply_success.error () != QNetworkReply.NoError ||
                json_parse_error.error != QJsonParseError.NoError) {
            string error_reason;
            string error_from_json = json["error"].to_string ();
            if (!error_from_json.is_empty ()) {
                q_c_warning (lc_remote_wipe) << string ("Error returned from the server : <em>%1</em>")
                                  .arg (error_from_json.to_html_escaped ());
            } else if (_network_reply_success.error () != QNetworkReply.NoError) {
                q_c_warning (lc_remote_wipe) << string ("There was an error accessing the 'on_success' endpoint : <br><em>%1</em>")
                                  .arg (_network_reply_success.error_string ().to_html_escaped ());
            } else if (json_parse_error.error != QJsonParseError.NoError) {
                q_c_warning (lc_remote_wipe) << string ("Could not parse the JSON returned from the server : <br><em>%1</em>")
                                  .arg (json_parse_error.error_string ());
            } else {
                q_c_warning (lc_remote_wipe) << string ("The reply from the server did not contain all expected fields.");
            }
        }

        _network_reply_success.delete_later ();
    }
    }
    