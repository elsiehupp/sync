#ifndef WEBFLOWCREDENTIALS_H
const int WEBFLOWCREDENTIALS_H

// #include <QSslCertificate>
// #include <QSslKey>
// #include <QNetworkRequest>
// #include <QQueue>
// #include <QAuthenticator>
// #include <QNetworkAccessManager>
// #include <QNetworkReply>
// #include <QPointer>
// #include <QTimer>
// #include <Gtk.Dialog>
// #include <QVBoxLayout>
// #include <QLabel>

class QAuthenticator;

#ifdef WITH_WEBENGINE
#endif // WITH_WEBENGINE

using namespace QKeychain;

namespace QKeychain {
    class Job;
}

namespace Occ {

namespace KeychainChunk {
    class ReadJob;
    class WriteJob;
}


class WebFlowCredentials : AbstractCredentials {
    friend class WebFlowCredentialsAccessManager;

    /// Don't add credentials if this is set on a QNetworkRequest
    public static constexpr QNetworkRequest.Attribute DontAddCredentialsAttribute = QNetworkRequest.User;

    /***********************************************************
    ***********************************************************/
    public WebFlowCredentials ();

    /***********************************************************
    ***********************************************************/
    public 
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
    public QNetworkAccessManager create_qNAM () override;

    /***********************************************************
    ***********************************************************/
    public bool ready () override;

    /***********************************************************
    ***********************************************************/
    public void fetch_from_keychain () override;

    /***********************************************************
    ***********************************************************/
    public 
    public bool still_valid (QNetworkReply reply) override;
    public void persist () override;
    public void invalidate_token () override;
    public void forget_sensitive_data () override;

    // To fetch the user name as early as possible
    public void set_account (Account account) override;


    /***********************************************************
    ***********************************************************/
    private void on_authentication (QNetworkReply reply, QAuthenticator authenticator);

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private void on_ask_from_user_cancelled ();

    /***********************************************************
    ***********************************************************/
    private void on_read_client_cert_pem_job_done (KeychainChunk.ReadJob read_job);
    private void on_read_client_key_pem_job_done (KeychainChunk.ReadJob read_job);
    private void on_read_client_ca_certs_pem_job_done (KeychainChunk.ReadJob read_job);
    private void on_read_password_job_done (QKeychain.Job incoming_job);

    /***********************************************************
    ***********************************************************/
    private void on_write_client_cert_pem_job_done (KeychainChunk.WriteJob write_job);
    private void on_write_client_key_pem_job_done (KeychainChunk.WriteJob write_job);
    private void on_write_client_ca_certs_pem_job_done (KeychainChunk.WriteJob write_job);
    private void on_write_job_done (QKeychain.Job *);


    /***********************************************************
    Windows : Workaround for CredWriteW used by QtKeychain

             Saving all client CA's within one credential may result in:
             Error : "Credential size exceeds maximum size of 2560"
    ***********************************************************/
    private void read_single_client_ca_cert_pem ();
    private void write_single_client_ca_cert_pem ();


    /***********************************************************
    Since we're limited by Windows limits, we just create our own
    limit to avoid evil things happening by endless recursion

    Better than storing the count and relying on maybe-hacked values
    ***********************************************************/
    private static constexpr int this.client_ssl_ca_certificates_max_count = 10;
    private QQueue<QSslCertificate> this.client_ssl_ca_certificates_write_queue;


    /***********************************************************
    Reads data from keychain locations

    Goes through
      on_read_client_cert_pem_job_done to
      on_read_client_key_pem_job_done to
      on_read_client_ca_certs_pem_job_done to
      on_read_job_done
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

    protected WebFlowCredentialsDialog this.ask_dialog = nullptr;
};




namespace {
    const char USER_C[] = "user";
    const char client_certificate_pemC[] = "this.client_certificate_pem";
    const char client_key_pemC[] = "this.client_key_pem";
    const char client_ca_certificate_pemC[] = "this.client_ca_certificate_pem";
} // ns

class WebFlowCredentialsAccessManager : AccessManager {

    /***********************************************************
    ***********************************************************/
    public WebFlowCredentialsAccessManager (WebFlowCredentials cred, GLib.Object parent = new GLib.Object ())
        : AccessManager (parent)
        , this.cred (cred) {
    }


    protected QNetworkReply create_request (Operation op, QNetworkRequest request, QIODevice outgoing_data) override {
        QNetworkRequest req (request);
        if (!req.attribute (WebFlowCredentials.DontAddCredentialsAttribute).to_bool ()) {
            if (this.cred && !this.cred.password ().is_empty ()) {
                GLib.ByteArray cred_hash = GLib.ByteArray (this.cred.user ().to_utf8 () + ":" + this.cred.password ().to_utf8 ()).to_base64 ();
                req.set_raw_header ("Authorization", "Basic " + cred_hash);
            }
        }

        if (this.cred && !this.cred._client_ssl_key.is_null () && !this.cred._client_ssl_certificate.is_null ()) {
            // SSL configuration
            QSslConfiguration ssl_configuration = req.ssl_configuration ();
            ssl_configuration.set_local_certificate (this.cred._client_ssl_certificate);
            ssl_configuration.set_private_key (this.cred._client_ssl_key);

            // Merge client side CA with system CA
            var ca = ssl_configuration.system_ca_certificates ();
            ca.append (this.cred._client_ssl_ca_certificates);
            ssl_configuration.set_ca_certificates (ca);

            req.set_ssl_configuration (ssl_configuration);
        }

        return AccessManager.create_request (op, req, outgoing_data);
    }


    // The credentials object dies along with the account, while the QNAM might
    // outlive both.
    private QPointer<const WebFlowCredentials> this.cred;
};

#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
static void add_settings_to_job (Account account, QKeychain.Job job) {
    Q_UNUSED (account)
    var settings = ConfigFile.settings_with_group (Theme.instance ().app_name ());
    settings.set_parent (job); // make the job parent to make setting deleted properly
    job.set_settings (settings.release ());
}
#endif

WebFlowCredentials.WebFlowCredentials () = default;

WebFlowCredentials.WebFlowCredentials (string user, string password, QSslCertificate certificate, QSslKey key, GLib.List<QSslCertificate> ca_certificates)
    : this.user (user)
    , this.password (password)
    , this.client_ssl_key (key)
    , this.client_ssl_certificate (certificate)
    , this.client_ssl_ca_certificates (ca_certificates)
    , this.ready (true)
    , this.credentials_valid (true) {

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

QNetworkAccessManager *WebFlowCredentials.create_qNAM () {
    q_c_info (lc_web_flow_credentials ()) << "Get QNAM";
    AccessManager qnam = new WebFlowCredentialsAccessManager (this);

    connect (qnam, &AccessManager.authentication_required, this, &WebFlowCredentials.on_authentication);
    connect (qnam, &AccessManager.on_finished, this, &WebFlowCredentials.on_finished);

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
        q_c_info (lc_web_flow_credentials ()) << "Fetch from keychain!";
        fetch_from_keychain_helper ();
    }
}

void WebFlowCredentials.ask_from_user () {
    // Determine if the old flow has to be used (GS for now)
    // Do a DetermineAuthTypeJob to make sure that the server is still using Flow2
    var job = new DetermineAuthTypeJob (this.account.shared_from_this (), this);
    connect (job, &DetermineAuthTypeJob.auth_type, [this] (DetermineAuthTypeJob.AuthType type) {
    // LoginFlowV2 > WebViewFlow > OAuth > Shib > Basic
#ifdef WITH_WEBENGINE
        bool use_flow2 = (type != DetermineAuthTypeJob.WebViewFlow);
#else // WITH_WEBENGINE
        bool use_flow2 = true;
#endif // WITH_WEBENGINE

        this.ask_dialog = new WebFlowCredentialsDialog (this.account, use_flow2);

        if (!use_flow2) {
            GLib.Uri url = this.account.url ();
            string path = url.path () + "/index.php/login/flow";
            url.set_path (path);
            this.ask_dialog.set_url (url);
        }

        string msg = _("You have been logged out of %1 as user %2. Please login again.")
                          .arg (this.account.display_name (), this.user);
        this.ask_dialog.set_info (msg);

        this.ask_dialog.show ();

        connect (this.ask_dialog, &WebFlowCredentialsDialog.on_url_catched, this, &WebFlowCredentials.on_ask_from_user_credentials_provided);
        connect (this.ask_dialog, &WebFlowCredentialsDialog.on_close, this, &WebFlowCredentials.on_ask_from_user_cancelled);
    });
    job.on_start ();

    GLib.debug (lc_web_flow_credentials ()) << "User needs to reauth!";
}

void WebFlowCredentials.on_ask_from_user_credentials_provided (string user, string pass, string host) {
    Q_UNUSED (host)

    // Compare the re-entered username case-insensitive and save the new value (avoid breaking the account)
    // See issue : https://github.com/nextcloud/desktop/issues/1741
    if (string.compare (this.user, user, Qt.CaseInsensitive) == 0) {
        this.user = user;
    } else {
        q_c_info (lc_web_flow_credentials ()) << "Authed with the wrong user!";

        string msg = _("Please login with the user : %1")
                .arg (this.user);
        this.ask_dialog.set_error (msg);

        if (!this.ask_dialog.is_using_flow2 ()) {
            GLib.Uri url = this.account.url ();
            string path = url.path () + "/index.php/login/flow";
            url.set_path (path);
            this.ask_dialog.set_url (url);
        }

        return;
    }

    q_c_info (lc_web_flow_credentials ()) << "Obtained a new password";

    this.password = pass;
    this.ready = true;
    this.credentials_valid = true;
    persist ();
    /* emit */ asked ();

    this.ask_dialog.close ();
    this.ask_dialog.delete_later ();
    this.ask_dialog = nullptr;
}

void WebFlowCredentials.on_ask_from_user_cancelled () {
    GLib.debug (lc_web_flow_credentials ()) << "User cancelled reauth!";

    /* emit */ asked ();

    this.ask_dialog.delete_later ();
    this.ask_dialog = nullptr;
}

bool WebFlowCredentials.still_valid (QNetworkReply reply) {
    if (reply.error () != QNetworkReply.NoError) {
        GLib.warn (lc_web_flow_credentials ()) << reply.error ();
        GLib.warn (lc_web_flow_credentials ()) << reply.error_string ();
    }
    return (reply.error () != QNetworkReply.AuthenticationRequiredError);
}

void WebFlowCredentials.persist () {
    if (this.user.is_empty ()) {
        // We don't even have a user nothing to see here move along
        return;
    }

    this.account.set_credential_setting (USER_C, this.user);
    this.account.wants_account_saved (this.account);

    // write cert if there is one
    if (!this.client_ssl_certificate.is_null ()) {
        var job = new KeychainChunk.WriteJob (this.account,
                                               this.user + client_certificate_pemC,
                                               this.client_ssl_certificate.to_pem (),
                                               this);
        connect (job, &KeychainChunk.WriteJob.on_finished, this, &WebFlowCredentials.on_write_client_cert_pem_job_done);
        job.on_start ();
    } else {
        // no cert, just write credentials
        on_write_client_cert_pem_job_done (nullptr);
    }
}

void WebFlowCredentials.on_write_client_cert_pem_job_done (KeychainChunk.WriteJob write_job) {
    Q_UNUSED (write_job)
    // write ssl key if there is one
    if (!this.client_ssl_key.is_null ()) {
        var job = new KeychainChunk.WriteJob (this.account,
                                               this.user + client_key_pemC,
                                               this.client_ssl_key.to_pem (),
                                               this);
        connect (job, &KeychainChunk.WriteJob.on_finished, this, &WebFlowCredentials.on_write_client_key_pem_job_done);
        job.on_start ();
    } else {
        // no key, just write credentials
        on_write_client_key_pem_job_done (nullptr);
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
            GLib.warn (lc_web_flow_credentials) << "Maximum client CA cert count exceeded while writing slot" << string.number (index) << "cutting off after" << string.number (this.client_ssl_ca_certificates_max_count) << "certs";

            this.client_ssl_ca_certificates_write_queue.clear ();

            on_write_client_ca_certs_pem_job_done (nullptr);
            return;
        }

        var job = new KeychainChunk.WriteJob (this.account,
                                               this.user + client_ca_certificate_pemC + string.number (index),
                                               cert.to_pem (),
                                               this);
        connect (job, &KeychainChunk.WriteJob.on_finished, this, &WebFlowCredentials.on_write_client_ca_certs_pem_job_done);
        job.on_start ();
    } else {
        on_write_client_ca_certs_pem_job_done (nullptr);
    }
}

void WebFlowCredentials.on_write_client_key_pem_job_done (KeychainChunk.WriteJob write_job) {
    Q_UNUSED (write_job)
    this.client_ssl_ca_certificates_write_queue.clear ();

    // write ca certs if there are any
    if (!this.client_ssl_ca_certificates.is_empty ()) {
        // queue the certs to avoid trouble on Windows (Workaround for CredWriteW used by QtKeychain)
        this.client_ssl_ca_certificates_write_queue.append (this.client_ssl_ca_certificates);

        // first ca cert
        write_single_client_ca_cert_pem ();
    } else {
        on_write_client_ca_certs_pem_job_done (nullptr);
    }
}

void WebFlowCredentials.on_write_client_ca_certs_pem_job_done (KeychainChunk.WriteJob write_job) {
    // errors / next ca cert?
    if (write_job && !this.client_ssl_ca_certificates.is_empty ()) {
        if (write_job.error () != NoError) {
            GLib.warn (lc_web_flow_credentials) << "Error while writing client CA cert" << write_job.error_string ();
        }

        if (!this.client_ssl_ca_certificates_write_queue.is_empty ()) {
            // next ca cert
            write_single_client_ca_cert_pem ();
            return;
        }
    }

    // done storing ca certs, time for the password
    var job = new WritePasswordJob (Theme.instance ().app_name (), this);
#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
    add_settings_to_job (this.account, job);
#endif
    job.set_insecure_fallback (false);
    connect (job, &Job.on_finished, this, &WebFlowCredentials.on_write_job_done);
    job.set_key (keychain_key (this.account.url ().to_"", this.user, this.account.id ()));
    job.set_text_data (this.password);
    job.on_start ();
}

void WebFlowCredentials.on_write_job_done (QKeychain.Job job) {
    delete job.settings ();
    switch (job.error ()) {
    case NoError:
        break;
    default:
        GLib.warn (lc_web_flow_credentials) << "Error while writing password" << job.error_string ();
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
    QTimer.single_shot (0, this.account, &Account.on_clear_qnam_cache);
}

void WebFlowCredentials.forget_sensitive_data () {
    this.password = "";
    this.ready = false;

    fetch_user ();

    this.account.delete_app_password ();

    const string kck = keychain_key (this.account.url ().to_"", this.user, this.account.id ());
    if (kck.is_empty ()) {
        GLib.debug (lc_web_flow_credentials ()) << "InvalidateToken : User is empty, bailing out!";
        return;
    }

    var job = new DeletePasswordJob (Theme.instance ().app_name (), this);
    job.set_insecure_fallback (false);
    job.set_key (kck);
    job.on_start ();

    invalidate_token ();

    delete_keychain_entries ();
}

void WebFlowCredentials.set_account (Account account) {
    AbstractCredentials.set_account (account);
    if (this.user.is_empty ()) {
        fetch_user ();
    }
}

string WebFlowCredentials.fetch_user () {
    this.user = this.account.credential_setting (USER_C).to_"";
    return this.user;
}

void WebFlowCredentials.on_authentication (QNetworkReply reply, QAuthenticator authenticator) {
    Q_UNUSED (reply)

    if (!this.ready) {
        return;
    }

    if (this.credentials_valid == false) {
        return;
    }

    GLib.debug (lc_web_flow_credentials ()) << "Requires authentication";

    authenticator.set_user (this.user);
    authenticator.set_password (this.password);
    this.credentials_valid = false;
}

void WebFlowCredentials.on_finished (QNetworkReply reply) {
    q_c_info (lc_web_flow_credentials ()) << "request on_finished";

    if (reply.error () == QNetworkReply.NoError) {
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
                                          this.user + client_certificate_pemC,
                                          this.keychain_migration,
                                          this);
    connect (job, &KeychainChunk.ReadJob.on_finished, this, &WebFlowCredentials.on_read_client_cert_pem_job_done);
    job.on_start ();
}

void WebFlowCredentials.on_read_client_cert_pem_job_done (KeychainChunk.ReadJob read_job) {
    // Store PEM in memory
    if (read_job.error () == NoError && read_job.binary_data ().length () > 0) {
        GLib.List<QSslCertificate> ssl_certificate_list = QSslCertificate.from_data (read_job.binary_data (), QSsl.Pem);
        if (ssl_certificate_list.length () >= 1) {
            this.client_ssl_certificate = ssl_certificate_list.at (0);
        }
    }

    // Load key too
    var job = new KeychainChunk.ReadJob (this.account,
                                          this.user + client_key_pemC,
                                          this.keychain_migration,
                                          this);
    connect (job, &KeychainChunk.ReadJob.on_finished, this, &WebFlowCredentials.on_read_client_key_pem_job_done);
    job.on_start ();
}

void WebFlowCredentials.on_read_client_key_pem_job_done (KeychainChunk.ReadJob read_job) {
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
            GLib.warn (lc_web_flow_credentials) << "Could not load SSL key into Qt!";
        }
        client_key_pem.clear ();
    } else {
        GLib.warn (lc_web_flow_credentials) << "Unable to read client key" << read_job.error_string ();
    }

    // Start fetching client CA certs
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
        connect (job, &KeychainChunk.ReadJob.on_finished, this, &WebFlowCredentials.on_read_client_ca_certs_pem_job_done);
        job.on_start ();
    } else {
        GLib.warn (lc_web_flow_credentials) << "Maximum client CA cert count exceeded while reading, ignoring after" << this.client_ssl_ca_certificates_max_count;

        on_read_client_ca_certs_pem_job_done (nullptr);
    }
}

void WebFlowCredentials.on_read_client_ca_certs_pem_job_done (KeychainChunk.ReadJob read_job) {
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
                GLib.warn (lc_web_flow_credentials) << "Unable to read client CA cert slot" << string.number (this.client_ssl_ca_certificates.count ()) << read_job.error_string ();
            }
        }
    }

    // Now fetch the actual server password
    const string kck = keychain_key (
        this.account.url ().to_"",
        this.user,
        this.keychain_migration ? "" : this.account.id ());

    var job = new ReadPasswordJob (Theme.instance ().app_name (), this);
#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
    add_settings_to_job (this.account, job);
#endif
    job.set_insecure_fallback (false);
    job.set_key (kck);
    connect (job, &Job.on_finished, this, &WebFlowCredentials.on_read_password_job_done);
    job.on_start ();
}

void WebFlowCredentials.on_read_password_job_done (Job incoming_job) {
    var job = qobject_cast<ReadPasswordJob> (incoming_job);
    QKeychain.Error error = job.error ();

    // If we could not find the entry try the old entries
    if (!this.keychain_migration && error == QKeychain.EntryNotFound) {
        this.keychain_migration = true;
        fetch_from_keychain_helper ();
        return;
    }

    if (this.user.is_empty ()) {
        GLib.warn (lc_web_flow_credentials) << "Strange : User is empty!";
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
        q_c_info (lc_web_flow_credentials) << "Migrated old keychain entries";
    }
}

void WebFlowCredentials.delete_keychain_entries (bool old_keychain_entries) {
    var start_delete_job = [this, old_keychain_entries] (string key) {
        var job = new KeychainChunk.DeleteJob (this.account, key, old_keychain_entries, this);
        job.on_start ();
    };

    start_delete_job (this.user);

    /* IMPORTANT - remove later - FIXME MS@2019-12-07 -.
    TODO : For "Log out" & "Remove account" : Remove client CA certs and KEY!

          Disabled as long as selecting another cert is not supported by the UI.

          Being able to specify a new certificate is important anyway : expiry etc.

           We introduce this dirty hack here, to allow deleting them upon Remote Wipe.
    ***********************************************************/
    if (this.account.is_remote_wipe_requested_HACK ()) {
    // <-- FIXME MS@2019-12-07

        // Also delete key / cert sub-chunks (KeychainChunk takes care of the Windows workaround)
        // The first chunk (0) has no suffix, to stay compatible with older versions and non-Windows
        start_delete_job (this.user + client_key_pemC);
        start_delete_job (this.user + client_certificate_pemC);

        // CA cert slots
        for (var i = 0; i < this.client_ssl_ca_certificates.count (); i++) {
            start_delete_job (this.user + client_ca_certificate_pemC + string.number (i));
        }

    // FIXME MS@2019-12-07 -.
    }
    // <-- FIXME MS@2019-12-07
}

} // namespace Occ
