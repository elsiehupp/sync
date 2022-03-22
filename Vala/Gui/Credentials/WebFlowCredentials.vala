// #include <QSslCertificate>
//  #include <QSslKey>
//  #include <Soup.Request>
//  #include <QQueue>
//  #include <QAuthenticator>
//  #include <Soup.Context>
//  #include <QPointe
//  #include <GLib.Timeout>
//  #include <Gtk.Dialog>
//  #include <QVBoxLayout>

//  #ifdef WITH_WEBENGINE
//  #endif // WITH_WEBENGINE

using Secret.Collection;

//  namespace Secret.Collection {
//      class Job;
//  }

//  namespace KeychainChunk {
//      class ReadJob;
//      class KeychainChunkWriteJob;
//  }

namespace Occ {
namespace Ui {

public class WebFlowCredentials : AbstractCredentials {

    //  friend class WebFlowCredentialsAccessManager;

    /***********************************************************
    Don't add credentials if this is set on a Soup.Request
    ***********************************************************/
    public const Soup.Request.Attribute DontAddCredentialsAttribute = Soup.Request.User;

    /***********************************************************
    Since we're limited by Windows limits, we just create our own
    limit to avoid evil things happening by endless recursion

    Better than storing the count and relying on maybe-hacked values
    ***********************************************************/
    private const int client_ssl_ca_certificates_max_count = 10;
    private QQueue<QSslCertificate> client_ssl_ca_certificates_write_queue;

    string user { public get; protected set; }
    string password { public get; protected set; }
    bool ready { public get; protected set; }

    protected QSslKey client_ssl_key;
    protected QSslCertificate client_ssl_certificate;
    protected GLib.List<QSslCertificate> client_ssl_ca_certificates;

    protected bool credentials_valid = false;
    protected bool keychain_migration = false;

    protected WebFlowCredentialsDialog ask_dialog = null;

    /***********************************************************
    ***********************************************************/
    public WebFlowCredentials (
        string user,
        string password,
        QSslCertificate certificate = QSslCertificate (),
        QSslKey key = QSslKey (),
        GLib.List<QSslCertificate> ca_certificates = GLib.List<QSslCertificate> ()) {
        this.user = user;
        this.password = password;
        this.client_ssl_key = key;
        this.client_ssl_certificate = certificate;
        this.client_ssl_ca_certificates = ca_certificates;
        this.ready = true;
        this.credentials_valid = true;
    }


    /***********************************************************
    ***********************************************************/
    public override string auth_type () {
        return "webflow";
    }


    /***********************************************************
    ***********************************************************/
    public override Soup.Context create_access_manager () {
        GLib.info ("Getting QNAM");
        AccessManager soup_context = new WebFlowCredentialsAccessManager (this);

        soup_context.signal_authentication_required.connect (
            this.on_signal_authentication
        );
        soup_context.signal_finished.connect (
            this.on_signal_finished
        );

        return soup_context;
    }


    /***********************************************************
    ***********************************************************/
    public override void fetch_from_keychain () {
        this.was_fetched = true;

        // Make sure we get the user from the config file
        fetch_user ();

        if (ready ()) {
            /* emit */ fetched ();
        } else {
            GLib.info ("Fetching from keychain!");
            fetch_from_keychain_helper ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public override bool still_valid (GLib.InputStream reply) {
        if (reply.error != GLib.InputStream.NoError) {
            GLib.warning (reply.error);
            GLib.warning (reply.error_string);
        }
        return (reply.error != GLib.InputStream.AuthenticationRequiredError);
    }


    /***********************************************************
    ***********************************************************/
    public override void persist () {
        if (this.user == "") {
            // We don't even have a user nothing to see here move along
            return;
        }

        this.account.credential_setting (USER_C, this.user);
        this.account.wants_account_saved (this.account);

        // write cert if there is one
        if (!this.client_ssl_certificate == null) {
            var kechain_chunk_write_job = new KeychainChunkWriteJob (
                this.account,
                this.user + CLIENT_CERTIFICATE_PEM_C,
                this.client_ssl_certificate.to_pem (),
                this
            );
            kechain_chunk_write_job.signal_finished.connect (
                this.on_signal_write_client_cert_pem_job_done
            );
            kechain_chunk_write_job.on_signal_start ();
        } else {
            // no cert, just write credentials
            on_signal_write_client_cert_pem_job_done (null);
        }
    }


    /***********************************************************
    ***********************************************************/
    public override void invalidate_token () {
        // clear the session cookie.
        this.account.clear_cookie_jar ();

        // let QNAM forget about the password
        // This needs to be done later in the event loop because we might be called (directly or
        // indirectly) from QNetworkAccessManagerPrivate.signal_authentication_required, which itself
        // is a called from a BlockingQueuedConnection from the Qt HTTP thread. And clearing the
        // cache needs to synchronize again with the HTTP thread.
        GLib.Timeout.single_shot (0, this.account, Account.on_signal_clear_access_manager_cache);
    }


    /***********************************************************
    ***********************************************************/
    public override void forget_sensitive_data () {
        this.password = "";
        this.ready = false;

        fetch_user ();

        this.account.delete_app_password ();

        const string keychain_key = keychain_key (this.account.url.to_string (), this.user, this.account.identifier);
        if (keychain_key == "") {
            GLib.debug ("InvalidateToken: User is empty, bailing out!");
            return;
        }

        var delete_password_job = new DeletePasswordJob (Theme.app_name, this);
        delete_password_job.insecure_fallback (false);
        delete_password_job.key (keychain_key);
        delete_password_job.on_signal_start ();

        invalidate_token ();

        delete_keychain_entries ();
    }


    /***********************************************************
    To fetch the user name as early as possible
    ***********************************************************/
    public override void account (Account account) {
        AbstractCredentials.account (account);
        if (this.user == "") {
            fetch_user ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_authentication (GLib.InputStream reply, QAuthenticator authenticator) {
        //  Q_UNUSED (reply)

        if (!this.ready) {
            return;
        }

        if (this.credentials_valid == false) {
            return;
        }

        GLib.debug ("Requires authentication.");

        authenticator.user (this.user);
        authenticator.password (this.password);
        this.credentials_valid = false;
    }


    /***********************************************************
    ***********************************************************/
    private void ask_from_user () {
        // Determine if the old flow has to be used (GS for now)
        // Do a LibSync.DetermineAuthTypeJob to make sure that the server is still using Flow2
        var determine_auth_type_job = new LibSync.DetermineAuthTypeJob (this.account.shared_from_this (), this);
        determine_auth_type_job.auth_type.connect (
            this.on_signal_determine_auth_type
        );
        determine_auth_type_job.on_signal_start ();

        GLib.debug ("User needs to reauth!");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_determine_auth_type (LibSync.DetermineAuthTypeJob.AuthType type) {
    // LoginFlowV2 > WEB_VIEW_FLOW > OAuth > Shib > Basic
//  #ifdef WITH_WEBENGINE
        bool use_flow2 = (type != LibSync.DetermineAuthTypeJob.WEB_VIEW_FLOW);
//  #else // WITH_WEBENGINE
        bool use_flow2 = true;
//  #endif // WITH_WEBENGINE

        this.ask_dialog = new WebFlowCredentialsDialog (this.account, use_flow2);

        if (!use_flow2) {
            GLib.Uri url = this.account.url;
            string path = url.path + "/index.php/login/flow";
            url.path (path);
            this.ask_dialog.url (url);
        }

        string message = _("You have been logged out of %1 as user %2. Please log in again.")
                        .printf (this.account.display_name, this.user);
        this.ask_dialog.info (message);

        this.ask_dialog.show ();

        this.ask_dialog.signal_url_catched.connect (
            this.on_signal_ask_from_user_credentials_provided
        );
        this.ask_dialog.signal_close.connect (
            this.on_signal_ask_from_user_cancelled
        );
    }



    /***********************************************************
    ***********************************************************/
    private void on_signal_ask_from_user_cancelled () {
        GLib.debug ("User cancelled reauth!");

        /* emit */ asked ();

        this.ask_dialog.delete_later ();
        this.ask_dialog = null;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_read_client_cert_pem_job_done (KeychainChunkReadJob read_job) {
        // Store PEM in memory
        if (read_job.error == NoError && read_job.binary_data ().length > 0) {
            GLib.List<QSslCertificate> ssl_certificate_list = QSslCertificate.from_data (read_job.binary_data (), QSsl.Pem);
            if (ssl_certificate_list.length >= 1) {
                this.client_ssl_certificate = ssl_certificate_list.at (0);
            }
        }

        // Load key too
        var keychain_chunk_read_job = new KeychainChunkReadJob (
            this.account,
            this.user + CLIENT_KEY_PEM_C,
            this.keychain_migration,
            this
        );
        keychain_chunk_read_job.on_signal_finished.connect (
            this.on_signal_read_client_key_pem_job_done
        );
        keychain_chunk_read_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_read_client_key_pem_job_done (KeychainChunkReadJob read_job) {
        // Store key in memory
        if (read_job.error == NoError && read_job.binary_data ().length > 0) {
            string client_key_pem = read_job.binary_data ();
            // FIXME Unfortunately Qt has a bug and we can't just use QSsl.Opaque to let it
            // load whatever we have. So we try until it works.
            this.client_ssl_key = QSslKey (client_key_pem, QSsl.Rsa);
            if (this.client_ssl_key == null) {
                this.client_ssl_key = QSslKey (client_key_pem, QSsl.Dsa);
            }
            if (this.client_ssl_key == null) {
                this.client_ssl_key = QSslKey (client_key_pem, QSsl.Ec);
            }
            if (this.client_ssl_key == null) {
                GLib.warning ("Could not load SSL key into Qt!");
            }
            client_key_pem == "";
        } else {
            GLib.warning ("Unable to read client key " + read_job.error_string);
        }

        // Start fetching client CA certificates
        this.client_ssl_ca_certificates == "";

        read_single_client_ca_cert_pem ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_read_client_ca_certificates_pem_job_done (KeychainChunkReadJob read_job) {
        // Store cert in memory
        if (read_job) {
            if (read_job.error == NoError && read_job.binary_data ().length > 0) {
                GLib.List<QSslCertificate> ssl_certificate_list = QSslCertificate.from_data (read_job.binary_data (), QSsl.Pem);
                if (ssl_certificate_list.length >= 1) {
                    this.client_ssl_ca_certificates.append (ssl_certificate_list.at (0));
                }

                // try next cert
                read_single_client_ca_cert_pem ();
                return;
            } else {
                if (read_job.error != Secret.Collection.Error.EntryNotFound ||
                    ( (read_job.error == Secret.Collection.Error.EntryNotFound) && this.client_ssl_ca_certificates.count () == 0)) {
                    GLib.warning ("Unable to read client CA cert slot " + this.client_ssl_ca_certificates.count ().to_string () + read_job.error_string);
                }
            }
        }

        // Now fetch the actual server password
        const string keychain_key = keychain_key (
            this.account.url.to_string (),
            this.user,
            this.keychain_migration ? "" : this.account.identifier
        );

        var read_password_job = new ReadPasswordJob (Theme.app_name, this);
    //  #if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
        add_settings_to_job (this.account, read_password_job);
    //  #endif
        read_password_job.insecure_fallback (false);
        read_password_job.key (keychain_key);
        read_password_job.signal_finished.connect (
            this.on_signal_read_password_job_finished
        );
        read_password_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_read_password_job_finished (Secret.Collection.Job incoming_job) {
        var read_password_job = qobject_cast<ReadPasswordJob> (incoming_job);
        Secret.Collection.Error error = read_password_job.error;

        // If we could not find the entry try the old entries
        if (!this.keychain_migration && error == Secret.Collection.EntryNotFound) {
            this.keychain_migration = true;
            fetch_from_keychain_helper ();
            return;
        }

        if (this.user == "") {
            GLib.warning ("Strange: User is empty!");
        }

        if (error == Secret.Collection.NoError) {
            this.password = read_password_job.text_data ();
            this.ready = true;
            this.credentials_valid = true;
        } else {
            this.ready = false;
        }
        /* emit */ fetched ();

        // If keychain data was read from legacy location, wipe these entries and store new ones
        if (this.keychain_migration && this.ready) {
            this.keychain_migration = false;
            persist ();
            delete_keychain_entries (true); // true: delete old entries
            GLib.info ("Migrated old keychain entries.");
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_write_client_cert_pem_job_done (KeychainChunkWriteJob write_job) {
        //  Q_UNUSED (write_job)
        // write ssl key if there is one
        if (!this.client_ssl_key == null) {
            var keychain_chunk_write_job = new KeychainChunkWriteJob (
                this.account,
                this.user + CLIENT_KEY_PEM_C,
                this.client_ssl_key.to_pem (),
                this
            );
            keychain_chunk_write_job.signal_finished.connect (
                this.on_signal_write_client_key_pem_job_done
            );
            keychain_chunk_write_job.on_signal_start ();
        } else {
            // no key, just write credentials
            on_signal_write_client_key_pem_job_done (null);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_write_client_key_pem_job_done (KeychainChunkWriteJob write_job) {
        //  Q_UNUSED (write_job)
        this.client_ssl_ca_certificates_write_queue == "";

        // write ca certificates if there are any
        if (!this.client_ssl_ca_certificates == "") {
            // queue the certificates to avoid trouble on Windows (Workaround for CredWriteW used by QtKeychain)
            this.client_ssl_ca_certificates_write_queue.append (this.client_ssl_ca_certificates);

            // first ca cert
            write_single_client_ca_cert_pem ();
        } else {
            on_signal_write_client_ca_certificates_pem_job_done (null);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_write_client_ca_certificates_pem_job_done (KeychainChunkWriteJob write_job) {
        // errors / next ca cert?
        if (write_job && !this.client_ssl_ca_certificates == "") {
            if (write_job.error != NoError) {
                GLib.warning ("Error while writing client CA cert " + write_job.error_string);
            }

            if (!this.client_ssl_ca_certificates_write_queue == "") {
                // next ca cert
                write_single_client_ca_cert_pem ();
                return;
            }
        }

        // done storing ca certificates, time for the password
        var write_password_job = new WritePasswordJob (Theme.app_name, this);
    //  #if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
        add_settings_to_job (this.account, write_password_job);
    //  #endif
        write_password_job.insecure_fallback (false);
        write_password_job.signal_finished.connect (
            this.on_signal_write_job_done
        );
        write_password_job.key (keychain_key (this.account.url.to_string (), this.user, this.account.identifier));
        write_password_job.text_data (this.password);
        write_password_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_write_job_done (Secret.Collection.Job qkeychain_job) {
        delete qkeychain_job.settings ();
        switch (qkeychain_job.error) {
        case NoError:
            break;
        default:
            GLib.warning ("Error while writing password " + qkeychain_job.error_string);
        }
    }


    /***********************************************************
    Windows : Workaround for CredWriteW used by QtKeychain

             Saving all client CA's within one credential may result in:
             Error: "Credential size exceeds maximum size of 2560"
    ***********************************************************/
    private void read_single_client_ca_cert_pem () {
        // try to fetch a client ca cert
        if (this.client_ssl_ca_certificates.count () < this.client_ssl_ca_certificates_max_count) {
            var keychain_chunk_read_job = new KeychainChunkReadJob (
                this.account,
                this.user + client_ca_certificate_pemC + this.client_ssl_ca_certificates.count ().to_string (),
                this.keychain_migration,
                this
            );
            keychain_chunk_read_job.signal_finished.connect (
                this.on_signal_read_client_ca_certificates_pem_job_done
            );
            keychain_chunk_read_job.on_signal_start ();
        } else {
            GLib.warning ("Maximum client CA cert count exceeded while reading, ignoring after " + this.client_ssl_ca_certificates_max_count);

            on_signal_read_client_ca_certificates_pem_job_done (null);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void write_single_client_ca_cert_pem () {
        // write a ca cert if there is any in the queue
        if (!this.client_ssl_ca_certificates_write_queue == "") {
            // grab and remove the first cert from the queue
            var cert = this.client_ssl_ca_certificates_write_queue.dequeue ();

            var index = (this.client_ssl_ca_certificates.count () - this.client_ssl_ca_certificates_write_queue.count ()) - 1;

            // keep the limit
            if (index > (this.client_ssl_ca_certificates_max_count - 1)) {
                GLib.warning ("Maximum client CA cert count exceeded while writing slot " + index.to_string () + " cutting off after " + this.client_ssl_ca_certificates_max_count.to_string () + " certificates.");

                this.client_ssl_ca_certificates_write_queue == "";

                on_signal_write_client_ca_certificates_pem_job_done (null);
                return;
            }

            var keychain_chunk_write_job = new KeychainChunkWriteJob (
                this.account,
                this.user + client_ca_certificate_pemC + string.number (index),
                cert.to_pem (),
                this
            );
            keychain_chunk_write_job.signal_finished.connect (
                this.on_signal_write_client_ca_certificates_pem_job_done
            );
            keychain_chunk_write_job.on_signal_start ();
        } else {
            on_signal_write_client_ca_certificates_pem_job_done (null);
        }
    }


    /***********************************************************
    Reads data from keychain locations

    Goes through
      on_signal_read_client_cert_pem_job_done to
      on_signal_read_client_key_pem_job_done to
      on_signal_read_client_ca_certificates_pem_job_done to
      on_signal_read_job_done
    ***********************************************************/
    protected void fetch_from_keychain_helper () {
        // Read client cert from keychain
        var keychain_chunk_read_job = new KeychainChunkReadJob (
            this.account,
            this.user + CLIENT_CERTIFICATE_PEM_C,
            this.keychain_migration,
            this
        );
        keychain_chunk_read_job.on_signal_finished.connect (
            this.on_signal_read_client_cert_pem_job_done
        );
        keychain_chunk_read_job.on_signal_start ();
    }


    /***********************************************************
    Wipes legacy keychain locations
    ***********************************************************/
    protected void delete_keychain_entries (bool old_keychain_entries = false) {
        start_delete_job (this.user);

        /* IMPORTANT - remove later - FIXME MS@2019-12-07 -.
        TODO: For "Log out" & "Remove account" : Remove client CA certificates and KEY!

            Disabled as long as selecting another cert is not supported by the UI.

            Being able to specify a new certificate is important anyway : expiry etc.

            We introduce this dirty hack here, to allow deleting them upon Remote Wipe.
        ***********************************************************/
        if (this.account.is_remote_wipe_requested_HACK ()) {
        // <-- FIXME MS@2019-12-07

            // Also delete key / cert sub-chunks (KeychainChunk takes care of the Windows workaround)
            // The first chunk (0) has no suffix, to stay compatible with older versions and non-Windows
            start_delete_job (this.user + CLIENT_KEY_PEM_C);
            start_delete_job (this.user + CLIENT_CERTIFICATE_PEM_C);

            // CA cert slots
            for (var i = 0; i < this.client_ssl_ca_certificates.count (); i++) {
                start_delete_job (this.user + client_ca_certificate_pemC + string.number (i));
            }

        // FIXME MS@2019-12-07 -.
        }
        // <-- FIXME MS@2019-12-07
    }


    /***********************************************************
    ***********************************************************/
    private void start_delete_job (bool old_keychain_entries, string key) {
        new KeychainChunkDeleteJob (this.account, key, old_keychain_entries, this).on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    protected string fetch_user () {
        this.user = this.account.credential_setting (USER_C).to_string ();
        return this.user;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_finished (GLib.InputStream reply) {
        GLib.info ("request on_signal_finished");

        if (reply.error == GLib.InputStream.NoError) {
            this.credentials_valid = true;

            /***********************************************************
            ***********************************************************/
            /// Used later for remote wipe
            this.account.write_app_password_once (this.password);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_ask_from_user_credentials_provided (string user, string pass, string host) {
        //  Q_UNUSED (host)

        // Compare the re-entered username case-insensitive and save the new value (avoid breaking the account)
        // See issue : https://github.com/nextcloud/desktop/issues/1741
        if (string.compare (this.user, user, Qt.CaseInsensitive) == 0) {
            this.user = user;
        } else {
            GLib.info ("Authed with the wrong user!");

            string message = _("Please log in with the user: %1")
                    .printf (this.user);
            this.ask_dialog.error (message);

            if (!this.ask_dialog.is_using_flow2 ()) {
                GLib.Uri url = this.account.url;
                string path = url.path + "/index.php/login/flow";
                url.path (path);
                this.ask_dialog.url (url);
            }

            return;
        }

        GLib.info ("Obtained a new password.");

        this.password = pass;
        this.ready = true;
        this.credentials_valid = true;
        persist ();
        /* emit */ asked ();

        this.ask_dialog.close ();
        this.ask_dialog.delete_later ();
        this.ask_dialog = null;
    }

} // class WebFlowCredentials

} // namespace Ui
} // namespace Occ
