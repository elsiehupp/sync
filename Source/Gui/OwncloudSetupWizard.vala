/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QAbstractButton>
// #include <QtCore>
// #include <QProcess>
// #include <QMessageBox>
// #include <QDesktopServices>
// #include <QApplication>

// #include <Gtk.Widget>
// #include <QProcess>
// #include <QNetworkReply>
// #include <QPointer>

namespace Occ {



/***********************************************************
@brief The OwncloudSetupWizard class
@ingroup gui
***********************************************************/
class OwncloudSetupWizard : GLib.Object {

    /***********************************************************
    Run the wizard
    ***********************************************************/
    public static void run_wizard (GLib.Object obj, char amember, Gtk.Widget parent = nullptr);


    public static bool bring_wizard_to_front_if_visible ();
signals:
    // overall dialog close signal.
    void own_cloud_wizard_done (int);


    private void on_check_server (string );
    private void on_system_proxy_lookup_done (QNetworkProxy &proxy);

    private void on_find_server ();
    private void on_find_server_behind_redirect ();
    private void on_found_server (GLib.Uri , QJsonObject &);
    private void on_no_server_found (QNetworkReply reply);
    private void on_no_server_found_timeout (GLib.Uri url);

    private void on_determine_auth_type ();

    private void on_connect_to_oCUrl (string );
    private void on_auth_error ();

    private void on_create_local_and_remote_folders (string , string );
    private void on_remote_folder_exists (QNetworkReply *);
    private void on_create_remote_folder_finished (QNetworkReply reply);
    private void on_assistant_finished (int);
    private void on_skip_folder_configuration ();


    private OwncloudSetupWizard (GLib.Object parent = nullptr);
    ~OwncloudSetupWizard () override;
    private void start_wizard ();
    private void test_owncloud_connect ();
    private void create_remote_folder ();
    private void finalize_setup (bool);
    private bool ensure_start_from_scratch (string local_folder);
    private AccountState apply_account_changes ();
    private bool check_downgrade_advised (QNetworkReply reply);

    private OwncloudWizard _oc_wizard;
    private string _init_local_folder;
    private string _remote_folder;
};


    OwncloudSetupWizard.OwncloudSetupWizard (GLib.Object parent)
        : GLib.Object (parent)
        , _oc_wizard (new OwncloudWizard)
        , _remote_folder () {
        connect (_oc_wizard, &OwncloudWizard.determine_auth_type,
            this, &OwncloudSetupWizard.on_check_server);
        connect (_oc_wizard, &OwncloudWizard.connect_to_oc_url,
            this, &OwncloudSetupWizard.on_connect_to_oCUrl);
        connect (_oc_wizard, &OwncloudWizard.create_local_and_remote_folders,
            this, &OwncloudSetupWizard.on_create_local_and_remote_folders);
        /* basic_setup_finished might be called from a reply from the network.
           on_assistant_finished might destroy the temporary QNetworkAccessManager.
           Therefore Qt.QueuedConnection is required */
        connect (_oc_wizard, &OwncloudWizard.basic_setup_finished,
            this, &OwncloudSetupWizard.on_assistant_finished, Qt.QueuedConnection);
        connect (_oc_wizard, &Gtk.Dialog.on_finished, this, &GLib.Object.delete_later);
        connect (_oc_wizard, &OwncloudWizard.skip_folder_configuration, this, &OwncloudSetupWizard.on_skip_folder_configuration);
    }

    OwncloudSetupWizard.~OwncloudSetupWizard () {
        _oc_wizard.delete_later ();
    }

    static QPointer<OwncloudSetupWizard> wiz = nullptr;

    void OwncloudSetupWizard.run_wizard (GLib.Object obj, char amember, Gtk.Widget parent) {
        if (!wiz.is_null ()) {
            bring_wizard_to_front_if_visible ();
            return;
        }

        wiz = new OwncloudSetupWizard (parent);
        connect (wiz, SIGNAL (own_cloud_wizard_done (int)), obj, amember);
        FolderMan.instance ().set_sync_enabled (false);
        wiz.start_wizard ();
    }

    bool OwncloudSetupWizard.bring_wizard_to_front_if_visible () {
        if (wiz.is_null ()) {
            return false;
        }

        OwncloudGui.raise_dialog (wiz._oc_wizard);
        return true;
    }

    void OwncloudSetupWizard.start_wizard () {
        AccountPointer account = AccountManager.create_account ();
        account.set_credentials (CredentialsFactory.create ("dummy"));
        account.set_url (Theme.instance ().override_server_url ());
        _oc_wizard.set_account (account);
        _oc_wizard.set_oCUrl (account.url ().to_string ());

        _remote_folder = Theme.instance ().default_server_folder ();
        // remote_folder may be empty, which means /
        string local_folder = Theme.instance ().default_client_folder ();

        // if its a relative path, prepend with users home dir, otherwise use as absolute path

        if (!QDir (local_folder).is_absolute ()) {
            local_folder = QDir.home_path () + '/' + local_folder;
        }

        _oc_wizard.set_property ("local_folder", local_folder);

        // remember the local folder to compare later if it changed, but clean first
        string lf = QDir.from_native_separators (local_folder);
        if (!lf.ends_with ('/')) {
            lf.append ('/');
        }

        _init_local_folder = lf;

        _oc_wizard.on_set_remote_folder (_remote_folder);

    #ifdef WITH_PROVIDERS
        const var start_page = WizardCommon.Page_Welcome;
    #else // WITH_PROVIDERS
        const var start_page = WizardCommon.Page_Server_setup;
    #endif // WITH_PROVIDERS
        _oc_wizard.set_start_id (start_page);

        _oc_wizard.restart ();

        _oc_wizard.open ();
        _oc_wizard.raise ();
    }

    // also checks if an installation is valid and determines auth type in a second step
    void OwncloudSetupWizard.on_check_server (string url_string) {
        string fixed_url = url_string;
        GLib.Uri url = GLib.Uri.from_user_input (fixed_url);
        // from_user_input defaults to http, not http if no scheme is specified
        if (!fixed_url.starts_with ("http://") && !fixed_url.starts_with ("https://")) {
            url.set_scheme ("https");
        }
        AccountPointer account = _oc_wizard.account ();
        account.set_url (url);

        // Reset the proxy which might had been determined previously in ConnectionValidator.on_check_server_and_auth ()
        // when there was a previous account.
        account.network_access_manager ().set_proxy (QNetworkProxy (QNetworkProxy.NoProxy));

        // And also reset the QSslConfiguration, for the same reason (#6832)
        // Here the client certificate is added, if any. Later it'll be in HttpCredentials
        account.set_ssl_configuration (QSslConfiguration ());
        var ssl_configuration = account.get_or_create_ssl_config (); // let Account set defaults
        if (!_oc_wizard._client_ssl_certificate.is_null ()) {
            ssl_configuration.set_local_certificate (_oc_wizard._client_ssl_certificate);
            ssl_configuration.set_private_key (_oc_wizard._client_ssl_key);
        }
        // Be sure to merge the CAs
        var ca = ssl_configuration.system_ca_certificates ();
        ca.append (_oc_wizard._client_ssl_ca_certificates);
        ssl_configuration.set_ca_certificates (ca);
        account.set_ssl_configuration (ssl_configuration);

        // Make sure TCP connections get re-established
        account.network_access_manager ().clear_access_cache ();

        // Lookup system proxy in a thread https://github.com/owncloud/client/issues/2993
        if (ClientProxy.is_using_system_default ()) {
            GLib.debug (lc_wizard) << "Trying to look up system proxy";
            ClientProxy.lookup_system_proxy_async (account.url (),
                this, SLOT (on_system_proxy_lookup_done (QNetworkProxy)));
        } else {
            // We want to reset the QNAM proxy so that the global proxy settings are used (via ClientProxy settings)
            account.network_access_manager ().set_proxy (QNetworkProxy (QNetworkProxy.DefaultProxy));
            // use a queued invocation so we're as asynchronous as with the other code path
            QMetaObject.invoke_method (this, "on_find_server", Qt.QueuedConnection);
        }
    }

    void OwncloudSetupWizard.on_system_proxy_lookup_done (QNetworkProxy &proxy) {
        if (proxy.type () != QNetworkProxy.NoProxy) {
            q_c_info (lc_wizard) << "Setting QNAM proxy to be system proxy" << ClientProxy.print_q_network_proxy (proxy);
        } else {
            q_c_info (lc_wizard) << "No system proxy set by OS";
        }
        AccountPointer account = _oc_wizard.account ();
        account.network_access_manager ().set_proxy (proxy);

        on_find_server ();
    }

    void OwncloudSetupWizard.on_find_server () {
        AccountPointer account = _oc_wizard.account ();

        // Set fake credentials before we check what credential it actually is.
        account.set_credentials (CredentialsFactory.create ("dummy"));

        // Determining the actual server URL can be a multi-stage process
        // 1. Check url/status.php with CheckServerJob
        //    If that works we're done. In that case we don't check the
        //    url directly for redirects, see #5954.
        // 2. Check the url for permanent redirects (like url shorteners)
        // 3. Check redirected-url/status.php with CheckServerJob

        // Step 1 : Check url/status.php
        var job = new CheckServerJob (account, this);
        job.set_ignore_credential_failure (true);
        connect (job, &CheckServerJob.instance_found, this, &OwncloudSetupWizard.on_found_server);
        connect (job, &CheckServerJob.instance_not_found, this, &OwncloudSetupWizard.on_find_server_behind_redirect);
        connect (job, &CheckServerJob.timeout, this, &OwncloudSetupWizard.on_no_server_found_timeout);
        job.on_set_timeout ( (account.url ().scheme () == "https") ? 30 * 1000 : 10 * 1000);
        job.on_start ();

        // Step 2 and 3 are in on_find_server_behind_redirect ()
    }

    void OwncloudSetupWizard.on_find_server_behind_redirect () {
        AccountPointer account = _oc_wizard.account ();

        // Step 2 : Resolve any permanent redirect chains on the base url
        var redirect_check_job = account.send_request ("GET", account.url ());

        // Use a significantly reduced timeout for this redirect check:
        // the 5-minute default is inappropriate.
        redirect_check_job.on_set_timeout (q_min (2000ll, redirect_check_job.timeout_msec ()));

        // Grab the chain of permanent redirects and adjust the account url
        // accordingly
        var permanent_redirects = std.make_shared<int> (0);
        connect (redirect_check_job, &AbstractNetworkJob.redirected, this,
            [permanent_redirects, account] (QNetworkReply reply, GLib.Uri target_url, int count) {
                int http_code = reply.attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
                if (count == *permanent_redirects && (http_code == 301 || http_code == 308)) {
                    q_c_info (lc_wizard) << account.url () << " was redirected to" << target_url;
                    account.set_url (target_url);
                    *permanent_redirects += 1;
                }
            });

        // Step 3 : When done, on_start checking status.php.
        connect (redirect_check_job, &SimpleNetworkJob.finished_signal, this,
            [this, account] () {
                var job = new CheckServerJob (account, this);
                job.set_ignore_credential_failure (true);
                connect (job, &CheckServerJob.instance_found, this, &OwncloudSetupWizard.on_found_server);
                connect (job, &CheckServerJob.instance_not_found, this, &OwncloudSetupWizard.on_no_server_found);
                connect (job, &CheckServerJob.timeout, this, &OwncloudSetupWizard.on_no_server_found_timeout);
                job.on_set_timeout ( (account.url ().scheme () == "https") ? 30 * 1000 : 10 * 1000);
                job.on_start ();
        });
    }

    void OwncloudSetupWizard.on_found_server (GLib.Uri url, QJsonObject &info) {
        var server_version = CheckServerJob.version (info);

        _oc_wizard.on_append_to_configuration_log (_("<font color=\"green\">Successfully connected to %1 : %2 version %3 (%4)</font><br/><br/>")
                                                .arg (Utility.escape (url.to_string ()),
                                                    Utility.escape (Theme.instance ().app_name_gui ()),
                                                    Utility.escape (CheckServerJob.version_string (info)),
                                                    Utility.escape (server_version)));

        // Note with newer servers we get the version actually only later in capabilities
        // https://github.com/owncloud/core/pull/27473/files
        _oc_wizard.account ().set_server_version (server_version);

        if (url != _oc_wizard.account ().url ()) {
            // We might be redirected, update the account
            _oc_wizard.account ().set_url (url);
            q_c_info (lc_wizard) << " was redirected to" << url.to_string ();
        }

        on_determine_auth_type ();
    }

    void OwncloudSetupWizard.on_no_server_found (QNetworkReply reply) {
        var job = qobject_cast<CheckServerJob> (sender ());

        // Do this early because reply might be deleted in message box event loop
        string msg;
        if (!_oc_wizard.account ().url ().is_valid ()) {
            msg = _("Invalid URL");
        } else {
            msg = _("Failed to connect to %1 at %2:<br/>%3")
                      .arg (Utility.escape (Theme.instance ().app_name_gui ()),
                          Utility.escape (_oc_wizard.account ().url ().to_string ()),
                          Utility.escape (job.error_string ()));
        }
        bool is_downgrade_advised = check_downgrade_advised (reply);

        // Displays message inside wizard and possibly also another message box
        _oc_wizard.on_display_error (msg, is_downgrade_advised);

        // Allow the credentials dialog to pop up again for the same URL.
        // Maybe the user just clicked 'Cancel' by accident or changed his mind.
        _oc_wizard.account ().reset_rejected_certificates ();
    }

    void OwncloudSetupWizard.on_no_server_found_timeout (GLib.Uri url) {
        _oc_wizard.on_display_error (
            _("Timeout while trying to connect to %1 at %2.")
                .arg (Utility.escape (Theme.instance ().app_name_gui ()), Utility.escape (url.to_string ())),
                    false);
    }

    void OwncloudSetupWizard.on_determine_auth_type () {
        var job = new DetermineAuthTypeJob (_oc_wizard.account (), this);
        connect (job, &DetermineAuthTypeJob.auth_type,
            _oc_wizard, &OwncloudWizard.on_set_auth_type);
        job.on_start ();
    }

    void OwncloudSetupWizard.on_connect_to_oCUrl (string url) {
        q_c_info (lc_wizard) << "Connect to url : " << url;
        AbstractCredentials creds = _oc_wizard.get_credentials ();
        _oc_wizard.account ().set_credentials (creds);

        const var fetch_user_name_job = new JsonApiJob (_oc_wizard.account ().shared_from_this (), "/ocs/v1.php/cloud/user");
        connect (fetch_user_name_job, &JsonApiJob.json_received, this, [this, url] (QJsonDocument &json, int status_code) {
            if (status_code != 100) {
                GLib.warn (lc_wizard) << "Could not fetch username.";
            }

            sender ().delete_later ();

            const var obj_data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
            const var user_id = obj_data.value ("id").to_string ("");
            const var display_name = obj_data.value ("display-name").to_string ("");
            _oc_wizard.account ().set_dav_user (user_id);
            _oc_wizard.account ().set_dav_display_name (display_name);

            _oc_wizard.set_field (QLatin1String ("OCUrl"), url);
            _oc_wizard.on_append_to_configuration_log (_("Trying to connect to %1 at %2 …")
                                                    .arg (Theme.instance ().app_name_gui ())
                                                    .arg (url));

            test_owncloud_connect ();
        });
        fetch_user_name_job.on_start ();
    }

    void OwncloudSetupWizard.test_owncloud_connect () {
        AccountPointer account = _oc_wizard.account ();

        var job = new PropfindJob (account, "/", this);
        job.set_ignore_credential_failure (true);
        // There is custom redirect handling in the error handler,
        // so don't automatically follow redirects.
        job.set_follow_redirects (false);
        job.set_properties (GLib.List<GLib.ByteArray> () << "getlastmodified");
        connect (job, &PropfindJob.result, _oc_wizard, &OwncloudWizard.on_successful_step);
        connect (job, &PropfindJob.finished_with_error, this, &OwncloudSetupWizard.on_auth_error);
        job.on_start ();
    }

    void OwncloudSetupWizard.on_auth_error () {
        string error_msg;

        var job = qobject_cast<PropfindJob> (sender ());
        if (!job) {
            GLib.warn (lc_wizard) << "Cannot check for authed redirects. This slot should be invoked from PropfindJob!";
            return;
        }
        QNetworkReply reply = job.reply ();

        // If there were redirects on the authed* requests, also store
        // the updated server URL, similar to redirects on status.php.
        GLib.Uri redirect_url = reply.attribute (QNetworkRequest.RedirectionTargetAttribute).to_url ();
        if (!redirect_url.is_empty ()) {
            q_c_info (lc_wizard) << "Authed request was redirected to" << redirect_url.to_string ();

            // strip the expected path
            string path = redirect_url.path ();
            static string expected_path = "/" + _oc_wizard.account ().dav_path ();
            if (path.ends_with (expected_path)) {
                path.chop (expected_path.size ());
                redirect_url.set_path (path);

                q_c_info (lc_wizard) << "Setting account url to" << redirect_url.to_string ();
                _oc_wizard.account ().set_url (redirect_url);
                test_owncloud_connect ();
                return;
            }
            error_msg = _("The authenticated request to the server was redirected to "
                          "\"%1\". The URL is bad, the server is misconfigured.")
                           .arg (Utility.escape (redirect_url.to_string ()));

            // A 404 is actually a on_success : we were authorized to know that the folder does
            // not exist. It will be created later...
        } else if (reply.error () == QNetworkReply.ContentNotFoundError) {
            _oc_wizard.on_successful_step ();
            return;

            // Provide messages for other errors, such as invalid credentials.
        } else if (reply.error () != QNetworkReply.NoError) {
            if (!_oc_wizard.account ().credentials ().still_valid (reply)) {
                error_msg = _("Access forbidden by server. To verify that you have proper access, "
                              "<a href=\"%1\">click here</a> to access the service with your browser.")
                               .arg (Utility.escape (_oc_wizard.account ().url ().to_string ()));
            } else {
                error_msg = job.error_string_parsing_body ();
            }

            // Something else went wrong, maybe the response was 200 but with invalid data.
        } else {
            error_msg = _("There was an invalid response to an authenticated WebDAV request");
        }

        // bring wizard to top
        _oc_wizard.bring_to_top ();
        if (_oc_wizard.current_id () == WizardCommon.Page_OAuth_creds || _oc_wizard.current_id () == WizardCommon.Page_Flow2Auth_creds) {
            _oc_wizard.back ();
        }
        _oc_wizard.on_display_error (error_msg, _oc_wizard.current_id () == WizardCommon.Page_Server_setup && check_downgrade_advised (reply));
    }

    bool OwncloudSetupWizard.check_downgrade_advised (QNetworkReply reply) {
        if (reply.url ().scheme () != QLatin1String ("https")) {
            return false;
        }

        switch (reply.error ()) {
        case QNetworkReply.NoError:
        case QNetworkReply.ContentNotFoundError:
        case QNetworkReply.AuthenticationRequiredError:
        case QNetworkReply.Host_not_found_error:
            return false;
        default:
            break;
        }

        // Adhere to HSTS, even though we do not parse it properly
        if (reply.has_raw_header ("Strict-Transport-Security")) {
            return false;
        }
        return true;
    }

    void OwncloudSetupWizard.on_create_local_and_remote_folders (string local_folder, string remote_folder) {
        q_c_info (lc_wizard) << "Setup local sync folder for new o_c connection " << local_folder;
        const QDir fi (local_folder);

        bool next_step = true;
        if (fi.exists ()) {
            FileSystem.set_folder_minimum_permissions (local_folder);
            Utility.setup_fav_link (local_folder);
            // there is an existing local folder. If its non empty, it can only be synced if the
            // own_cloud is newly created.
            _oc_wizard.on_append_to_configuration_log (
                _("Local sync folder %1 already exists, setting it up for sync.<br/><br/>")
                    .arg (Utility.escape (local_folder)));
        } else {
            string res = _("Creating local sync folder %1 …").arg (local_folder);
            if (fi.mkpath (local_folder)) {
                FileSystem.set_folder_minimum_permissions (local_folder);
                Utility.setup_fav_link (local_folder);
                res += _("OK");
            } else {
                res += _("failed.");
                GLib.warn (lc_wizard) << "Failed to create " << fi.path ();
                _oc_wizard.on_display_error (_("Could not create local folder %1").arg (Utility.escape (local_folder)), false);
                next_step = false;
            }
            _oc_wizard.on_append_to_configuration_log (res);
        }
        if (next_step) {
            /***********************************************************
            BEGIN - Sanitize URL paths to eliminate double-slashes

                    Purpose : Don't rely on unsafe paths, be extra careful.

                    Example: https://cloud.example.com/remote.php/dav//

            ***********************************************************/
            q_c_info (lc_wizard) << "Sanitize got URL path:" << string (_oc_wizard.account ().url ().to_string () + '/' + _oc_wizard.account ().dav_path () + remote_folder);

            string new_dav_path = _oc_wizard.account ().dav_path (),
                    new_remote_folder = remote_folder;

            while (new_dav_path.starts_with ('/')) {
                new_dav_path.remove (0, 1);
            }
            while (new_dav_path.ends_with ('/')) {
                new_dav_path.chop (1);
            }

            while (new_remote_folder.starts_with ('/')) {
                new_remote_folder.remove (0, 1);
            }
            while (new_remote_folder.ends_with ('/')) {
                new_remote_folder.chop (1);
            }

            string new_url_path = new_dav_path + '/' + new_remote_folder;

            q_c_info (lc_wizard) << "Sanitized to URL path:" << _oc_wizard.account ().url ().to_string () + '/' + new_url_path;
            /***********************************************************
            END - Sanitize URL paths to eliminate double-slashes
            ***********************************************************/

            var job = new EntityExistsJob (_oc_wizard.account (), new_url_path, this);
            connect (job, &EntityExistsJob.exists, this, &OwncloudSetupWizard.on_remote_folder_exists);
            job.on_start ();
        } else {
            finalize_setup (false);
        }
    }

    // ### TODO move into EntityExistsJob once we decide if/how to return gui strings from jobs
    void OwncloudSetupWizard.on_remote_folder_exists (QNetworkReply reply) {
        var job = qobject_cast<EntityExistsJob> (sender ());
        bool ok = true;
        string error;
        QNetworkReply.NetworkError err_id = reply.error ();

        if (err_id == QNetworkReply.NoError) {
            q_c_info (lc_wizard) << "Remote folder found, all cool!";
        } else if (err_id == QNetworkReply.ContentNotFoundError) {
            if (_remote_folder.is_empty ()) {
                error = _("No remote folder specified!");
                ok = false;
            } else {
                create_remote_folder ();
            }
        } else {
            error = _("Error : %1").arg (job.error_string ());
            ok = false;
        }

        if (!ok) {
            _oc_wizard.on_display_error (Utility.escape (error), false);
        }

        finalize_setup (ok);
    }

    void OwncloudSetupWizard.create_remote_folder () {
        _oc_wizard.on_append_to_configuration_log (_("creating folder on Nextcloud : %1").arg (_remote_folder));

        var job = new MkColJob (_oc_wizard.account (), _remote_folder, this);
        connect (job, &MkColJob.finished_with_error, this, &OwncloudSetupWizard.on_create_remote_folder_finished);
        connect (job, &MkColJob.finished_without_error, this, [this] {
            _oc_wizard.on_append_to_configuration_log (_("Remote folder %1 created successfully.").arg (_remote_folder));
            finalize_setup (true);
        });
        job.on_start ();
    }

    void OwncloudSetupWizard.on_create_remote_folder_finished (QNetworkReply reply) {
        var error = reply.error ();
        GLib.debug (lc_wizard) << "** webdav mkdir request on_finished " << error;
        //    disconnect (own_cloud_info.instance (), SIGNAL (webdav_col_created (QNetworkReply.NetworkError)),
        //               this, SLOT (on_create_remote_folder_finished (QNetworkReply.NetworkError)));

        bool on_success = true;
        if (error == 202) {
            _oc_wizard.on_append_to_configuration_log (_("The remote folder %1 already exists. Connecting it for syncing.").arg (_remote_folder));
        } else if (error > 202 && error < 300) {
            _oc_wizard.on_display_error (_("The folder creation resulted in HTTP error code %1").arg (static_cast<int> (error)), false);

            _oc_wizard.on_append_to_configuration_log (_("The folder creation resulted in HTTP error code %1").arg (static_cast<int> (error)));
        } else if (error == QNetworkReply.OperationCanceledError) {
            _oc_wizard.on_display_error (_("The remote folder creation failed because the provided credentials "
                                       "are wrong!"
                                       "<br/>Please go back and check your credentials.</p>"),
                false);
            _oc_wizard.on_append_to_configuration_log (_("<p><font color=\"red\">Remote folder creation failed probably because the provided credentials are wrong.</font>"
                                                   "<br/>Please go back and check your credentials.</p>"));
            _remote_folder.clear ();
            on_success = false;
        } else {
            _oc_wizard.on_append_to_configuration_log (_("Remote folder %1 creation failed with error <tt>%2</tt>.").arg (Utility.escape (_remote_folder)).arg (error));
            _oc_wizard.on_display_error (_("Remote folder %1 creation failed with error <tt>%2</tt>.").arg (Utility.escape (_remote_folder)).arg (error), false);
            _remote_folder.clear ();
            on_success = false;
        }

        finalize_setup (on_success);
    }

    void OwncloudSetupWizard.finalize_setup (bool on_success) {
        const string local_folder = _oc_wizard.property ("local_folder").to_string ();
        if (on_success) {
            if (! (local_folder.is_empty () || _remote_folder.is_empty ())) {
                _oc_wizard.on_append_to_configuration_log (
                    _("A sync connection from %1 to remote directory %2 was set up.")
                        .arg (local_folder, _remote_folder));
            }
            _oc_wizard.on_append_to_configuration_log (QLatin1String (" "));
            _oc_wizard.on_append_to_configuration_log (QLatin1String ("<p><font color=\"green\"><b>")
                + _("Successfully connected to %1!")
                      .arg (Theme.instance ().app_name_gui ())
                + QLatin1String ("</b></font></p>"));
            _oc_wizard.on_successful_step ();
        } else {
            // ### this is not quite true, pass in the real problem as optional parameter
            _oc_wizard.on_append_to_configuration_log (QLatin1String ("<p><font color=\"red\">")
                + _("Connection to %1 could not be established. Please check again.")
                      .arg (Theme.instance ().app_name_gui ())
                + QLatin1String ("</font></p>"));
        }
    }

    bool OwncloudSetupWizard.ensure_start_from_scratch (string local_folder) {
        // first try to rename (backup) the current local dir.
        bool rename_ok = false;
        while (!rename_ok) {
            rename_ok = FolderMan.instance ().start_from_scratch (local_folder);
            if (!rename_ok) {
                QMessageBox.StandardButton but = QMessageBox.question (nullptr, _("Folder rename failed"),
                    _("Cannot remove and back up the folder because the folder or a file in it is open in another program."
                       " Please close the folder or file and hit retry or cancel the setup."),
                    QMessageBox.Retry | QMessageBox.Abort, QMessageBox.Retry);
                if (but == QMessageBox.Abort) {
                    break;
                }
            }
        }
        return rename_ok;
    }

    // Method executed when the user end has on_finished the basic setup.
    void OwncloudSetupWizard.on_assistant_finished (int result) {
        FolderMan folder_man = FolderMan.instance ();

        if (result == Gtk.Dialog.Rejected) {
            q_c_info (lc_wizard) << "Rejected the new config, use the old!";

        } else if (result == Gtk.Dialog.Accepted) {
            // This may or may not wipe all folder definitions, depending
            // on whether a new account is activated or the existing one
            // is changed.
            var account = apply_account_changes ();

            string local_folder = FolderDefinition.prepare_local_path (_oc_wizard.local_folder ());

            bool start_from_scratch = _oc_wizard.field ("OCSync_from_scratch").to_bool ();
            if (!start_from_scratch || ensure_start_from_scratch (local_folder)) {
                q_c_info (lc_wizard) << "Adding folder definition for" << local_folder << _remote_folder;
                FolderDefinition folder_definition;
                folder_definition.local_path = local_folder;
                folder_definition.target_path = FolderDefinition.prepare_target_path (_remote_folder);
                folder_definition.ignore_hidden_files = folder_man.ignore_hidden_files ();
                if (_oc_wizard.use_virtual_file_sync ()) {
                    folder_definition.virtual_files_mode = best_available_vfs_mode ();
                }
                if (folder_man.navigation_pane_helper ().show_in_explorer_navigation_pane ())
                    folder_definition.navigation_pane_clsid = QUuid.create_uuid ();

                var f = folder_man.add_folder (account, folder_definition);
                if (f) {
                    if (folder_definition.virtual_files_mode != Vfs.Off && _oc_wizard.use_virtual_file_sync ())
                        f.set_root_pin_state (PinState.VfsItemAvailability.ONLINE_ONLY);

                    f.journal_database ().set_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST,
                        _oc_wizard.selective_sync_blocklist ());
                    if (!_oc_wizard.is_confirm_big_folder_checked ()) {
                        // The user already accepted the selective sync dialog. everything is in the allow list
                        f.journal_database ().set_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST,
                            string[] () << QLatin1String ("/"));
                    }
                }
                _oc_wizard.on_append_to_configuration_log (_("<font color=\"green\"><b>Local sync folder %1 successfully created!</b></font>").arg (local_folder));
            }
        }

        // notify others.
        _oc_wizard.on_done (QWizard.Accepted);
        emit own_cloud_wizard_done (result);
    }

    void OwncloudSetupWizard.on_skip_folder_configuration () {
        apply_account_changes ();

        disconnect (_oc_wizard, &OwncloudWizard.basic_setup_finished,
            this, &OwncloudSetupWizard.on_assistant_finished);
        _oc_wizard.close ();
        emit own_cloud_wizard_done (Gtk.Dialog.Accepted);
    }

    AccountState *OwncloudSetupWizard.apply_account_changes () {
        AccountPointer new_account = _oc_wizard.account ();

        // Detach the account that is going to be saved from the
        // wizard to ensure it doesn't accidentally get modified
        // later (such as from running on_cleanup such as
        // Abstract_credentials_wizard_page.cleanup_page ())
        _oc_wizard.set_account (AccountManager.create_account ());

        var manager = AccountManager.instance ();

        var new_state = manager.add_account (new_account);
        manager.save ();
        return new_state;
    }

    } // namespace Occ
    