// #include <QSslCertificate>
//  #include <QSslKey>
//  #include <Soup.Request>
//  #include <QQueue>
//  #include <QAuthenticator>
//  #include <QNetworkAccessManager>
//  #include <QPointe
//  #include <QTimer>
//  #include <Gtk.Dialog>
//  #include <QVBoxLayout>
//  #include <Gtk.Label>

#ifdef WITH_WEBENGINE
//  #endif // WITH_WEBENGINE

using QKeychain;

namespace QKeychain {
    class Job;
}


namespace Occ {
namespace Ui {

namespace KeychainChunk {
    class ReadJob;
    class WriteJob;
}


class WebFlowCredentials : AbstractCredentials {
    friend class WebFlowCredentialsAccessManager;

    /// Don't add credentials if this is set on a Soup.Request
    public static constexpr Soup.Request.Attribute DontAddCredentialsAttribute = Soup.Request.User;

    /***********************************************************
    ***********************************************************/
    public WebFlowCredentials ();

    /***********************************************************
    ***********************************************************/
    public WebFlowCredentials (
            const string user,
            const string password,
            const QSslCertificate certificate = QSslCertificate (),
            const QSslKey key = QSslKey (),
            const GLib.List<QSslCertificate> ca_certificates = GLib.List<QSslCertificate> ());

    /***********************************************************
    ***********************************************************/
    public string auth_type () override;
    public string user () override;
    public string password () override;
    public QNetworkAccessManager create_qnam () override;

    /***********************************************************
    ***********************************************************/
    public bool ready () override;

    /***********************************************************
    ***********************************************************/
    public void fetch_from_keychain () override;

    /***********************************************************
    ***********************************************************/
    public bool still_valid (Soup.Reply reply) override;
    public void persist () override;
    public void invalidate_token () override;
    public void forget_sensitive_data () override;

    // To fetch the user name as early as possible
    public void account (Account account) override;


    /***********************************************************
    ***********************************************************/
    private void on_signal_authentication (Soup.Reply reply, QAuthenticator authenticator);

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private void on_signal_ask_from_user_cancelled ();

    /***********************************************************
    ***********************************************************/
    private void on_signal_read_client_cert_pem_job_done (KeychainChunk.ReadJob read_job);
    private void on_signal_read_client_key_pem_job_done (KeychainChunk.ReadJob read_job);
    private void on_signal_read_client_ca_certificates_pem_job_done (KeychainChunk.ReadJob read_job);
    private void on_signal_read_password_job_done (QKeychain.Job incoming_job);

    /***********************************************************
    ***********************************************************/
    private void on_signal_write_client_cert_pem_job_done (KeychainChunk.WriteJob write_job);
    private void on_signal_write_client_key_pem_job_done (KeychainChunk.WriteJob write_job);
    private void on_signal_write_client_ca_certificates_pem_job_done (KeychainChunk.WriteJob write_job);
    private void on_signal_write_job_done (QKeychain.Job *);


    /***********************************************************
    Windows : Workaround for CredWriteW used by QtKeychain

             Saving all client CA's within one credential may result in:
             Error: "Credential size exceeds maximum size of 2560"
    ***********************************************************/
    private void read_single_client_ca_cert_pem ();
    private void write_single_client_ca_cert_pem ();


    /***********************************************************
    Since we're limited by Windows limits, we just create our own
    limit to avoid evil things happening by endless recursion

    Better than storing the count and relying on maybe-hacked values
    ***********************************************************/
    private const int this.client_ssl_ca_certificates_max_count = 10;
    private QQueue<QSslCertificate> this.client_ssl_ca_certificates_write_queue;


    /***********************************************************
    Reads data from keychain locations

    Goes through
      on_signal_read_client_cert_pem_job_done to
      on_signal_read_client_key_pem_job_done to
      on_signal_read_client_ca_certificates_pem_job_done to
      on_signal_read_job_done
    ***********************************************************/
    protected void fetch_from_keychain_helper ();

    /// Wipes legacy keychain locations
    protected void delete_keychain_entries (bool old_keychain_entries = false);

    protected string fetch_user ();

    protected string this.user;
    protected string this.password;
    protected QSslKey this.client_ssl_key;
    protected QSslCertificate this.client_ssl_certificate;
    protected GLib.List<QSslCertificate> this.client_ssl_ca_certificates;

    protected bool this.ready = false;
    protected bool this.credentials_valid = false;
    protected bool this.keychain_migration = false;

    protected WebFlowCredentialsDialog this.ask_dialog = null;
}





WebFlowCredentials.WebFlowCredentials () = default;

WebFlowCredentials.WebFlowCredentials (string user, string password, QSslCertificate certificate, QSslKey key, GLib.List<QSslCertificate> ca_certificates)
    : this.user (user)
    this.password (password)
    this.client_ssl_key (key)
    this.client_ssl_certificate (certificate)
    this.client_ssl_ca_certificates (ca_certificates)
    this.ready (true)
    this.credentials_valid (true) {

}

string WebFlowCredentials.auth_type () {
    return string.from_latin1 ("webflow");
}

string WebFlowCredentials.user () {
    return this.user;
}

string WebFlowCredentials.password () {
    return this.password;
}

QNetworkAccessManager *WebFlowCredentials.create_qnam () {
    GLib.info ()) + "Get QNAM";
    AccessManager qnam = new WebFlowCredentialsAccessManager (this);

    connect (qnam, &AccessManager.authentication_required, this, &WebFlowCredentials.on_signal_authentication);
    connect (qnam, &AccessManager.on_signal_finished, this, &WebFlowCredentials.on_signal_finished);

    return qnam;
}

bool WebFlowCredentials.ready () {
    return this.ready;
}

void WebFlowCredentials.fetch_from_keychain () {
    this.was_fetched = true;

    // Make sure we get the user from the config file
    fetch_user ();

    if (ready ()) {
        /* emit */ fetched ();
    } else {
        GLib.info ()) + "Fetch from keychain!";
        fetch_from_keychain_helper ();
    }
}

void WebFlowCredentials.ask_from_user () {
    // Determine if the old flow has to be used (GS for now)
    // Do a DetermineAuthTypeJob to make sure that the server is still using Flow2
    var job = new DetermineAuthTypeJob (this.account.shared_from_this (), this);
    connect (job, &DetermineAuthTypeJob.auth_type, [this] (DetermineAuthTypeJob.AuthType type) {
    // LoginFlowV2 > WEB_VIEW_FLOW > OAuth > Shib > Basic
#ifdef WITH_WEBENGINE
        bool use_flow2 = (type != DetermineAuthTypeJob.WEB_VIEW_FLOW);
#else // WITH_WEBENGINE
        bool use_flow2 = true;
//  #endif // WITH_WEBENGINE

        this.ask_dialog = new WebFlowCredentialsDialog (this.account, use_flow2);

        if (!use_flow2) {
            GLib.Uri url = this.account.url ();
            string path = url.path () + "/index.php/login/flow";
            url.path (path);
            this.ask_dialog.url (url);
        }

        string message = _("You have been logged out of %1 as user %2. Please log in again.")
                          .arg (this.account.display_name (), this.user);
        this.ask_dialog.info (message);

        this.ask_dialog.show ();

        connect (this.ask_dialog, &WebFlowCredentialsDialog.on_signal_url_catched, this, &WebFlowCredentials.on_signal_ask_from_user_credentials_provided);
        connect (this.ask_dialog, &WebFlowCredentialsDialog.on_signal_close, this, &WebFlowCredentials.on_signal_ask_from_user_cancelled);
    });
    job.on_signal_start ();

    GLib.debug ()) + "User needs to reauth!";
}

void WebFlowCredentials.on_signal_ask_from_user_credentials_provided (string user, string pass, string host) {
    //  Q_UNUSED (host)

    // Compare the re-entered username case-insensitive and save the new value (avoid breaking the account)
    // See issue : https://github.com/nextcloud/desktop/issues/1741
    if (string.compare (this.user, user, Qt.CaseInsensitive) == 0) {
        this.user = user;
    } else {
        GLib.info ()) + "Authed with the wrong user!";

        string message = _("Please log in with the user: %1")
                .arg (this.user);
        this.ask_dialog.error (message);

        if (!this.ask_dialog.is_using_flow2 ()) {
            GLib.Uri url = this.account.url ();
            string path = url.path () + "/index.php/login/flow";
            url.path (path);
            this.ask_dialog.url (url);
        }

        return;
    }

    GLib.info ()) + "Obtained a new password";

    this.password = pass;
    this.ready = true;
    this.credentials_valid = true;
    persist ();
    /* emit */ asked ();

    this.ask_dialog.close ();
    this.ask_dialog.delete_later ();
    this.ask_dialog = null;
}

void WebFlowCredentials.on_signal_ask_from_user_cancelled () {
    GLib.debug ()) + "User cancelled reauth!";

    /* emit */ asked ();

    this.ask_dialog.delete_later ();
    this.ask_dialog = null;
}

bool WebFlowCredentials.still_valid (Soup.Reply reply) {
    if (reply.error () != Soup.Reply.NoError) {
        GLib.warning ()) + reply.error ();
        GLib.warning ()) + reply.error_string ();
    }
    return (reply.error () != Soup.Reply.AuthenticationRequiredError);
}

void WebFlowCredentials.persist () {
    if (this.user.is_empty ()) {
        // We don't even have a user nothing to see here move along
        return;
    }

    this.account.credential_setting (USER_C, this.user);
    this.account.wants_account_saved (this.account);

    // write cert if there is one
    if (!this.client_ssl_certificate.is_null ()) {
        var job = new KeychainChunk.WriteJob (this.account,
                                               this.user + CLIENT_CERTIFICATE_PEM_C,
                                               this.client_ssl_certificate.to_pem (),
                                               this);
        connect (job, &KeychainChunk.WriteJob.on_signal_finished, this, &WebFlowCredentials.on_signal_write_client_cert_pem_job_done);
        job.on_signal_start ();
    } else {
        // no cert, just write credentials
        on_signal_write_client_cert_pem_job_done (null);
    }
}

void WebFlowCredentials.on_signal_write_client_cert_pem_job_done (KeychainChunk.WriteJob write_job) {
    //  Q_UNUSED (write_job)
    // write ssl key if there is one
    if (!this.client_ssl_key.is_null ()) {
        var job = new KeychainChunk.WriteJob (this.account,
                                               this.user + CLIENT_KEY_PEM_C,
                                               this.client_ssl_key.to_pem (),
                                               this);
        connect (job, &KeychainChunk.WriteJob.on_signal_finished, this, &WebFlowCredentials.on_signal_write_client_key_pem_job_done);
        job.on_signal_start ();
    } else {
        // no key, just write credentials
        on_signal_write_client_key_pem_job_done (null);
    }
}

void WebFlowCredentials.write_single_client_ca_cert_pem () {
    // write a ca cert if there is any in the queue
    if (!this.client_ssl_ca_certificates_write_queue.is_empty ()) {
        // grab and remove the first cert from the queue
        var cert = this.client_ssl_ca_certificates_write_queue.dequeue ();

        var index = (this.client_ssl_ca_certificates.count () - this.client_ssl_ca_certificates_write_queue.count ()) - 1;

        // keep the limit
        if (index > (this.client_ssl_ca_certificates_max_count - 1)) {
            GLib.warning ("Maximum client CA cert count exceeded while writing slot" + string.number (index) + "cutting off after" + string.number (this.client_ssl_ca_certificates_max_count) + "certificates";

            this.client_ssl_ca_certificates_write_queue.clear ();

            on_signal_write_client_ca_certificates_pem_job_done (null);
            return;
        }

        var job = new KeychainChunk.WriteJob (this.account,
                                               this.user + client_ca_certificate_pemC + string.number (index),
                                               cert.to_pem (),
                                               this);
        connect (job, &KeychainChunk.WriteJob.on_signal_finished, this, &WebFlowCredentials.on_signal_write_client_ca_certificates_pem_job_done);
        job.on_signal_start ();
    } else {
        on_signal_write_client_ca_certificates_pem_job_done (null);
    }
}

void WebFlowCredentials.on_signal_write_client_key_pem_job_done (KeychainChunk.WriteJob write_job) {
    //  Q_UNUSED (write_job)
    this.client_ssl_ca_certificates_write_queue.clear ();

    // write ca certificates if there are any
    if (!this.client_ssl_ca_certificates.is_empty ()) {
        // queue the certificates to avoid trouble on Windows (Workaround for CredWriteW used by QtKeychain)
        this.client_ssl_ca_certificates_write_queue.append (this.client_ssl_ca_certificates);

        // first ca cert
        write_single_client_ca_cert_pem ();
    } else {
        on_signal_write_client_ca_certificates_pem_job_done (null);
    }
}

void WebFlowCredentials.on_signal_write_client_ca_certificates_pem_job_done (KeychainChunk.WriteJob write_job) {
    // errors / next ca cert?
    if (write_job && !this.client_ssl_ca_certificates.is_empty ()) {
        if (write_job.error () != NoError) {
            GLib.warning ("Error while writing client CA cert" + write_job.error_string ();
        }

        if (!this.client_ssl_ca_certificates_write_queue.is_empty ()) {
            // next ca cert
            write_single_client_ca_cert_pem ();
            return;
        }
    }

    // done storing ca certificates, time for the password
    var job = new WritePasswordJob (Theme.instance ().app_name (), this);
#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
    add_settings_to_job (this.account, job);
//  #endif
    job.insecure_fallback (false);
    connect (job, &Job.on_signal_finished, this, &WebFlowCredentials.on_signal_write_job_done);
    job.key (keychain_key (this.account.url ().to_string (), this.user, this.account.identifier ()));
    job.text_data (this.password);
    job.on_signal_start ();
}

void WebFlowCredentials.on_signal_write_job_done (QKeychain.Job job) {
    delete job.settings ();
    switch (job.error ()) {
    case NoError:
        break;
    default:
        GLib.warning ("Error while writing password" + job.error_string ();
    }
}

void WebFlowCredentials.invalidate_token () {
    // clear the session cookie.
    this.account.clear_cookie_jar ();

    // let QNAM forget about the password
    // This needs to be done later in the event loop because we might be called (directly or
    // indirectly) from QNetworkAccessManagerPrivate.authentication_required, which itself
    // is a called from a BlockingQueuedConnection from the Qt HTTP thread. And clearing the
    // cache needs to synchronize again with the HTTP thread.
    QTimer.single_shot (0, this.account, &Account.on_signal_clear_qnam_cache);
}

void WebFlowCredentials.forget_sensitive_data () {
    this.password = "";
    this.ready = false;

    fetch_user ();

    this.account.delete_app_password ();

    const string kck = keychain_key (this.account.url ().to_string (), this.user, this.account.identifier ());
    if (kck.is_empty ()) {
        GLib.debug ()) + "InvalidateToken : User is empty, bailing out!";
        return;
    }

    var job = new DeletePasswordJob (Theme.instance ().app_name (), this);
    job.insecure_fallback (false);
    job.key (kck);
    job.on_signal_start ();

    invalidate_token ();

    delete_keychain_entries ();
}

void WebFlowCredentials.account (Account account) {
    AbstractCredentials.account (account);
    if (this.user.is_empty ()) {
        fetch_user ();
    }
}

string WebFlowCredentials.fetch_user () {
    this.user = this.account.credential_setting (USER_C).to_string ();
    return this.user;
}

void WebFlowCredentials.on_signal_authentication (Soup.Reply reply, QAuthenticator authenticator) {
    //  Q_UNUSED (reply)

    if (!this.ready) {
        return;
    }

    if (this.credentials_valid == false) {
        return;
    }

    GLib.debug ()) + "Requires authentication";

    authenticator.user (this.user);
    authenticator.password (this.password);
    this.credentials_valid = false;
}

void WebFlowCredentials.on_signal_finished (Soup.Reply reply) {
    GLib.info ()) + "request on_signal_finished";

    if (reply.error () == Soup.Reply.NoError) {
        this.credentials_valid = true;

        /***********************************************************
        ***********************************************************/
        /// Used later for remote wipe
        this.account.write_app_password_once (this.password);
    }
}

void WebFlowCredentials.fetch_from_keychain_helper () {
    // Read client cert from keychain
    var job = new KeychainChunk.ReadJob (this.account,
                                          this.user + CLIENT_CERTIFICATE_PEM_C,
                                          this.keychain_migration,
                                          this);
    connect (job, &KeychainChunk.ReadJob.on_signal_finished, this, &WebFlowCredentials.on_signal_read_client_cert_pem_job_done);
    job.on_signal_start ();
}

void WebFlowCredentials.on_signal_read_client_cert_pem_job_done (KeychainChunk.ReadJob read_job) {
    // Store PEM in memory
    if (read_job.error () == NoError && read_job.binary_data ().length () > 0) {
        GLib.List<QSslCertificate> ssl_certificate_list = QSslCertificate.from_data (read_job.binary_data (), QSsl.Pem);
        if (ssl_certificate_list.length () >= 1) {
            this.client_ssl_certificate = ssl_certificate_list.at (0);
        }
    }

    // Load key too
    var job = new KeychainChunk.ReadJob (this.account,
                                          this.user + CLIENT_KEY_PEM_C,
                                          this.keychain_migration,
                                          this);
    connect (job, &KeychainChunk.ReadJob.on_signal_finished, this, &WebFlowCredentials.on_signal_read_client_key_pem_job_done);
    job.on_signal_start ();
}

void WebFlowCredentials.on_signal_read_client_key_pem_job_done (KeychainChunk.ReadJob read_job) {
    // Store key in memory
    if (read_job.error () == NoError && read_job.binary_data ().length () > 0) {
        GLib.ByteArray client_key_pem = read_job.binary_data ();
        // FIXME Unfortunately Qt has a bug and we can't just use QSsl.Opaque to let it
        // load whatever we have. So we try until it works.
        this.client_ssl_key = QSslKey (client_key_pem, QSsl.Rsa);
        if (this.client_ssl_key.is_null ()) {
            this.client_ssl_key = QSslKey (client_key_pem, QSsl.Dsa);
        }
        if (this.client_ssl_key.is_null ()) {
            this.client_ssl_key = QSslKey (client_key_pem, QSsl.Ec);
        }
        if (this.client_ssl_key.is_null ()) {
            GLib.warning ("Could not load SSL key into Qt!";
        }
        client_key_pem.clear ();
    } else {
        GLib.warning ("Unable to read client key" + read_job.error_string ();
    }

    // Start fetching client CA certificates
    this.client_ssl_ca_certificates.clear ();

    read_single_client_ca_cert_pem ();
}

void WebFlowCredentials.read_single_client_ca_cert_pem () {
    // try to fetch a client ca cert
    if (this.client_ssl_ca_certificates.count () < this.client_ssl_ca_certificates_max_count) {
        var job = new KeychainChunk.ReadJob (this.account,
                                              this.user + client_ca_certificate_pemC + string.number (this.client_ssl_ca_certificates.count ()),
                                              this.keychain_migration,
                                              this);
        connect (job, &KeychainChunk.ReadJob.on_signal_finished, this, &WebFlowCredentials.on_signal_read_client_ca_certificates_pem_job_done);
        job.on_signal_start ();
    } else {
        GLib.warning ("Maximum client CA cert count exceeded while reading, ignoring after" + this.client_ssl_ca_certificates_max_count;

        on_signal_read_client_ca_certificates_pem_job_done (null);
    }
}

void WebFlowCredentials.on_signal_read_client_ca_certificates_pem_job_done (KeychainChunk.ReadJob read_job) {
    // Store cert in memory
    if (read_job) {
        if (read_job.error () == NoError && read_job.binary_data ().length () > 0) {
            GLib.List<QSslCertificate> ssl_certificate_list = QSslCertificate.from_data (read_job.binary_data (), QSsl.Pem);
            if (ssl_certificate_list.length () >= 1) {
                this.client_ssl_ca_certificates.append (ssl_certificate_list.at (0));
            }

            // try next cert
            read_single_client_ca_cert_pem ();
            return;
        } else {
            if (read_job.error () != QKeychain.Error.EntryNotFound ||
                ( (read_job.error () == QKeychain.Error.EntryNotFound) && this.client_ssl_ca_certificates.count () == 0)) {
                GLib.warning ("Unable to read client CA cert slot" + string.number (this.client_ssl_ca_certificates.count ()) + read_job.error_string ();
            }
        }
    }

    // Now fetch the actual server password
    const string kck = keychain_key (
        this.account.url ().to_string (),
        this.user,
        this.keychain_migration ? "" : this.account.identifier ());

    var job = new ReadPasswordJob (Theme.instance ().app_name (), this);
#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
    add_settings_to_job (this.account, job);
//  #endif
    job.insecure_fallback (false);
    job.key (kck);
    connect (job, &Job.on_signal_finished, this, &WebFlowCredentials.on_signal_read_password_job_done);
    job.on_signal_start ();
}

void WebFlowCredentials.on_signal_read_password_job_done (Job incoming_job) {
    var job = qobject_cast<ReadPasswordJob> (incoming_job);
    QKeychain.Error error = job.error ();

    // If we could not find the entry try the old entries
    if (!this.keychain_migration && error == QKeychain.EntryNotFound) {
        this.keychain_migration = true;
        fetch_from_keychain_helper ();
        return;
    }

    if (this.user.is_empty ()) {
        GLib.warning ("Strange : User is empty!";
    }

    if (error == QKeychain.NoError) {
        this.password = job.text_data ();
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
        delete_keychain_entries (true); // true : delete old entries
        GLib.info ("Migrated old keychain entries";
    }
}

void WebFlowCredentials.delete_keychain_entries (bool old_keychain_entries) {
    var start_delete_job = [this, old_keychain_entries] (string key) {
        var job = new KeychainChunk.DeleteJob (this.account, key, old_keychain_entries, this);
        job.on_signal_start ();
    }

    start_delete_job (this.user);

    /* IMPORTANT - remove later - FIXME MS@2019-12-07 -.
    TODO : For "Log out" & "Remove account" : Remove client CA certificates and KEY!

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

} // namespace Occ
