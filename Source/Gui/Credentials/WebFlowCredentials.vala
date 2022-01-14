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

public:
    /// Don't add credentials if this is set on a QNetworkRequest
    static constexpr QNetworkRequest.Attribute DontAddCredentialsAttribute = QNetworkRequest.User;

    WebFlowCredentials ();
    WebFlowCredentials (
            const string &user,
            const string &password,
            const QSslCertificate &certificate = QSslCertificate (),
            const QSslKey &key = QSslKey (),
            const QList<QSslCertificate> &ca_certificates = QList<QSslCertificate> ());

    string auth_type () const override;
    string user () const override;
    string password () const override;
    QNetworkAccessManager *create_qNAM () const override;

    bool ready () const override;

    void fetch_from_keychain () override;
    void ask_from_user () override;

    bool still_valid (QNetworkReply *reply) override;
    void persist () override;
    void invalidate_token () override;
    void forget_sensitive_data () override;

    // To fetch the user name as early as possible
    void set_account (Account *account) override;

private slots:
    void slot_authentication (QNetworkReply *reply, QAuthenticator *authenticator);
    void slot_finished (QNetworkReply *reply);

    void slot_ask_from_user_credentials_provided (string &user, string &pass, string &host);
    void slot_ask_from_user_cancelled ();

    void slot_read_client_cert_pem_job_done (KeychainChunk.ReadJob *read_job);
    void slot_read_client_key_pem_job_done (KeychainChunk.ReadJob *read_job);
    void slot_read_client_ca_certs_pem_job_done (KeychainChunk.ReadJob *read_job);
    void slot_read_password_job_done (QKeychain.Job *incoming_job);

    void slot_write_client_cert_pem_job_done (KeychainChunk.WriteJob *write_job);
    void slot_write_client_key_pem_job_done (KeychainChunk.WriteJob *write_job);
    void slot_write_client_ca_certs_pem_job_done (KeychainChunk.WriteJob *write_job);
    void slot_write_job_done (QKeychain.Job *);

private:
    /***********************************************************
    Windows : Workaround for CredWriteW used by QtKeychain
    
             Saving all client CA's within one credential may result in:
             Error : "Credential size exceeds maximum size of 2560"
    ***********************************************************/
    void read_single_client_ca_cert_pem ();
    void write_single_client_ca_cert_pem ();

    /***********************************************************
    Since we're limited by Windows limits, we just create our own
    limit to avoid evil things happening by endless recursion
    
    Better than storing the count and relying on maybe-hacked values
    ***********************************************************/
    static constexpr int _client_ssl_ca_certificates_max_count = 10;
    QQueue<QSslCertificate> _client_ssl_ca_certificates_write_queue;

protected:
    /***********************************************************
    Reads data from keychain locations

    Goes through
      slot_read_client_cert_pem_job_done to
      slot_read_client_key_pem_job_done to
      slot_read_client_ca_certs_pem_job_done to
      slot_read_job_done
    ***********************************************************/
    void fetch_from_keychain_helper ();

    /// Wipes legacy keychain locations
    void delete_keychain_entries (bool old_keychain_entries = false);

    string fetch_user ();

    string _user;
    string _password;
    QSslKey _client_ssl_key;
    QSslCertificate _client_ssl_certificate;
    QList<QSslCertificate> _client_ssl_ca_certificates;

    bool _ready = false;
    bool _credentials_valid = false;
    bool _keychain_migration = false;

    WebFlowCredentialsDialog *_ask_dialog = nullptr;
};




namespace {
    const char user_c[] = "user";
    const char client_certificate_pemC[] = "_client_certificate_pem";
    const char client_key_pemC[] = "_client_key_pem";
    const char client_ca_certificate_pemC[] = "_client_ca_certificate_pem";
} // ns

class WebFlowCredentialsAccessManager : AccessManager {
public:
    WebFlowCredentialsAccessManager (WebFlowCredentials *cred, GLib.Object *parent = nullptr)
        : AccessManager (parent)
        , _cred (cred) {
    }

protected:
    QNetworkReply *create_request (Operation op, QNetworkRequest &request, QIODevice *outgoing_data) override {
        QNetworkRequest req (request);
        if (!req.attribute (WebFlowCredentials.DontAddCredentialsAttribute).to_bool ()) {
            if (_cred && !_cred.password ().is_empty ()) {
                QByteArray cred_hash = QByteArray (_cred.user ().to_utf8 () + ":" + _cred.password ().to_utf8 ()).to_base64 ();
                req.set_raw_header ("Authorization", "Basic " + cred_hash);
            }
        }

        if (_cred && !_cred._client_ssl_key.is_null () && !_cred._client_ssl_certificate.is_null ()) {
            // SSL configuration
            QSslConfiguration ssl_configuration = req.ssl_configuration ();
            ssl_configuration.set_local_certificate (_cred._client_ssl_certificate);
            ssl_configuration.set_private_key (_cred._client_ssl_key);

            // Merge client side CA with system CA
            auto ca = ssl_configuration.system_ca_certificates ();
            ca.append (_cred._client_ssl_ca_certificates);
            ssl_configuration.set_ca_certificates (ca);

            req.set_ssl_configuration (ssl_configuration);
        }

        return AccessManager.create_request (op, req, outgoing_data);
    }

private:
    // The credentials object dies along with the account, while the QNAM might
    // outlive both.
    QPointer<const WebFlowCredentials> _cred;
};

#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
static void add_settings_to_job (Account *account, QKeychain.Job *job) {
    Q_UNUSED (account)
    auto settings = ConfigFile.settings_with_group (Theme.instance ().app_name ());
    settings.set_parent (job); // make the job parent to make setting deleted properly
    job.set_settings (settings.release ());
}
#endif

WebFlowCredentials.WebFlowCredentials () = default;

WebFlowCredentials.WebFlowCredentials (string &user, string &password, QSslCertificate &certificate, QSslKey &key, QList<QSslCertificate> &ca_certificates)
    : _user (user)
    , _password (password)
    , _client_ssl_key (key)
    , _client_ssl_certificate (certificate)
    , _client_ssl_ca_certificates (ca_certificates)
    , _ready (true)
    , _credentials_valid (true) {

}

string WebFlowCredentials.auth_type () {
    return string.from_latin1 ("webflow");
}

string WebFlowCredentials.user () {
    return _user;
}

string WebFlowCredentials.password () {
    return _password;
}

QNetworkAccessManager *WebFlowCredentials.create_qNAM () {
    q_c_info (lc_web_flow_credentials ()) << "Get QNAM";
    AccessManager *qnam = new WebFlowCredentialsAccessManager (this);

    connect (qnam, &AccessManager.authentication_required, this, &WebFlowCredentials.slot_authentication);
    connect (qnam, &AccessManager.finished, this, &WebFlowCredentials.slot_finished);

    return qnam;
}

bool WebFlowCredentials.ready () {
    return _ready;
}

void WebFlowCredentials.fetch_from_keychain () {
    _was_fetched = true;

    // Make sure we get the user from the config file
    fetch_user ();

    if (ready ()) {
        emit fetched ();
    } else {
        q_c_info (lc_web_flow_credentials ()) << "Fetch from keychain!";
        fetch_from_keychain_helper ();
    }
}

void WebFlowCredentials.ask_from_user () {
    // Determine if the old flow has to be used (GS for now)
    // Do a DetermineAuthTypeJob to make sure that the server is still using Flow2
    auto job = new DetermineAuthTypeJob (_account.shared_from_this (), this);
    connect (job, &DetermineAuthTypeJob.auth_type, [this] (DetermineAuthTypeJob.AuthType type) {
    // LoginFlowV2 > WebViewFlow > OAuth > Shib > Basic
#ifdef WITH_WEBENGINE
        bool use_flow2 = (type != DetermineAuthTypeJob.WebViewFlow);
#else // WITH_WEBENGINE
        bool use_flow2 = true;
#endif // WITH_WEBENGINE

        _ask_dialog = new WebFlowCredentialsDialog (_account, use_flow2);

        if (!use_flow2) {
            QUrl url = _account.url ();
            string path = url.path () + "/index.php/login/flow";
            url.set_path (path);
            _ask_dialog.set_url (url);
        }

        string msg = tr ("You have been logged out of %1 as user %2. Please login again.")
                          .arg (_account.display_name (), _user);
        _ask_dialog.set_info (msg);

        _ask_dialog.show ();

        connect (_ask_dialog, &WebFlowCredentialsDialog.url_catched, this, &WebFlowCredentials.slot_ask_from_user_credentials_provided);
        connect (_ask_dialog, &WebFlowCredentialsDialog.on_close, this, &WebFlowCredentials.slot_ask_from_user_cancelled);
    });
    job.start ();

    q_c_debug (lc_web_flow_credentials ()) << "User needs to reauth!";
}

void WebFlowCredentials.slot_ask_from_user_credentials_provided (string &user, string &pass, string &host) {
    Q_UNUSED (host)

    // Compare the re-entered username case-insensitive and save the new value (avoid breaking the account)
    // See issue : https://github.com/nextcloud/desktop/issues/1741
    if (string.compare (_user, user, Qt.CaseInsensitive) == 0) {
        _user = user;
    } else {
        q_c_info (lc_web_flow_credentials ()) << "Authed with the wrong user!";

        string msg = tr ("Please login with the user : %1")
                .arg (_user);
        _ask_dialog.set_error (msg);

        if (!_ask_dialog.is_using_flow2 ()) {
            QUrl url = _account.url ();
            string path = url.path () + "/index.php/login/flow";
            url.set_path (path);
            _ask_dialog.set_url (url);
        }

        return;
    }

    q_c_info (lc_web_flow_credentials ()) << "Obtained a new password";

    _password = pass;
    _ready = true;
    _credentials_valid = true;
    persist ();
    emit asked ();

    _ask_dialog.close ();
    _ask_dialog.delete_later ();
    _ask_dialog = nullptr;
}

void WebFlowCredentials.slot_ask_from_user_cancelled () {
    q_c_debug (lc_web_flow_credentials ()) << "User cancelled reauth!";

    emit asked ();

    _ask_dialog.delete_later ();
    _ask_dialog = nullptr;
}

bool WebFlowCredentials.still_valid (QNetworkReply *reply) {
    if (reply.error () != QNetworkReply.NoError) {
        q_c_warning (lc_web_flow_credentials ()) << reply.error ();
        q_c_warning (lc_web_flow_credentials ()) << reply.error_string ();
    }
    return (reply.error () != QNetworkReply.AuthenticationRequiredError);
}

void WebFlowCredentials.persist () {
    if (_user.is_empty ()) {
        // We don't even have a user nothing to see here move along
        return;
    }

    _account.set_credential_setting (user_c, _user);
    _account.wants_account_saved (_account);

    // write cert if there is one
    if (!_client_ssl_certificate.is_null ()) {
        auto job = new KeychainChunk.WriteJob (_account,
                                               _user + client_certificate_pemC,
                                               _client_ssl_certificate.to_pem (),
                                               this);
        connect (job, &KeychainChunk.WriteJob.finished, this, &WebFlowCredentials.slot_write_client_cert_pem_job_done);
        job.start ();
    } else {
        // no cert, just write credentials
        slot_write_client_cert_pem_job_done (nullptr);
    }
}

void WebFlowCredentials.slot_write_client_cert_pem_job_done (KeychainChunk.WriteJob *write_job) {
    Q_UNUSED (write_job)
    // write ssl key if there is one
    if (!_client_ssl_key.is_null ()) {
        auto job = new KeychainChunk.WriteJob (_account,
                                               _user + client_key_pemC,
                                               _client_ssl_key.to_pem (),
                                               this);
        connect (job, &KeychainChunk.WriteJob.finished, this, &WebFlowCredentials.slot_write_client_key_pem_job_done);
        job.start ();
    } else {
        // no key, just write credentials
        slot_write_client_key_pem_job_done (nullptr);
    }
}

void WebFlowCredentials.write_single_client_ca_cert_pem () {
    // write a ca cert if there is any in the queue
    if (!_client_ssl_ca_certificates_write_queue.is_empty ()) {
        // grab and remove the first cert from the queue
        auto cert = _client_ssl_ca_certificates_write_queue.dequeue ();

        auto index = (_client_ssl_ca_certificates.count () - _client_ssl_ca_certificates_write_queue.count ()) - 1;

        // keep the limit
        if (index > (_client_ssl_ca_certificates_max_count - 1)) {
            q_c_warning (lc_web_flow_credentials) << "Maximum client CA cert count exceeded while writing slot" << string.number (index) << "cutting off after" << string.number (_client_ssl_ca_certificates_max_count) << "certs";

            _client_ssl_ca_certificates_write_queue.clear ();

            slot_write_client_ca_certs_pem_job_done (nullptr);
            return;
        }

        auto job = new KeychainChunk.WriteJob (_account,
                                               _user + client_ca_certificate_pemC + string.number (index),
                                               cert.to_pem (),
                                               this);
        connect (job, &KeychainChunk.WriteJob.finished, this, &WebFlowCredentials.slot_write_client_ca_certs_pem_job_done);
        job.start ();
    } else {
        slot_write_client_ca_certs_pem_job_done (nullptr);
    }
}

void WebFlowCredentials.slot_write_client_key_pem_job_done (KeychainChunk.WriteJob *write_job) {
    Q_UNUSED (write_job)
    _client_ssl_ca_certificates_write_queue.clear ();

    // write ca certs if there are any
    if (!_client_ssl_ca_certificates.is_empty ()) {
        // queue the certs to avoid trouble on Windows (Workaround for CredWriteW used by QtKeychain)
        _client_ssl_ca_certificates_write_queue.append (_client_ssl_ca_certificates);

        // first ca cert
        write_single_client_ca_cert_pem ();
    } else {
        slot_write_client_ca_certs_pem_job_done (nullptr);
    }
}

void WebFlowCredentials.slot_write_client_ca_certs_pem_job_done (KeychainChunk.WriteJob *write_job) {
    // errors / next ca cert?
    if (write_job && !_client_ssl_ca_certificates.is_empty ()) {
        if (write_job.error () != NoError) {
            q_c_warning (lc_web_flow_credentials) << "Error while writing client CA cert" << write_job.error_string ();
        }

        if (!_client_ssl_ca_certificates_write_queue.is_empty ()) {
            // next ca cert
            write_single_client_ca_cert_pem ();
            return;
        }
    }

    // done storing ca certs, time for the password
    auto job = new WritePasswordJob (Theme.instance ().app_name (), this);
#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
    add_settings_to_job (_account, job);
#endif
    job.set_insecure_fallback (false);
    connect (job, &Job.finished, this, &WebFlowCredentials.slot_write_job_done);
    job.set_key (keychain_key (_account.url ().to_string (), _user, _account.id ()));
    job.set_text_data (_password);
    job.start ();
}

void WebFlowCredentials.slot_write_job_done (QKeychain.Job *job) {
    delete job.settings ();
    switch (job.error ()) {
    case NoError:
        break;
    default:
        q_c_warning (lc_web_flow_credentials) << "Error while writing password" << job.error_string ();
    }
}

void WebFlowCredentials.invalidate_token () {
    // clear the session cookie.
    _account.clear_cookie_jar ();

    // let QNAM forget about the password
    // This needs to be done later in the event loop because we might be called (directly or
    // indirectly) from QNetworkAccessManagerPrivate.authentication_required, which itself
    // is a called from a BlockingQueuedConnection from the Qt HTTP thread. And clearing the
    // cache needs to synchronize again with the HTTP thread.
    QTimer.single_shot (0, _account, &Account.clear_qNAMCache);
}

void WebFlowCredentials.forget_sensitive_data () {
    _password = string ();
    _ready = false;

    fetch_user ();

    _account.delete_app_password ();

    const string kck = keychain_key (_account.url ().to_string (), _user, _account.id ());
    if (kck.is_empty ()) {
        q_c_debug (lc_web_flow_credentials ()) << "InvalidateToken : User is empty, bailing out!";
        return;
    }

    auto job = new DeletePasswordJob (Theme.instance ().app_name (), this);
    job.set_insecure_fallback (false);
    job.set_key (kck);
    job.start ();

    invalidate_token ();

    delete_keychain_entries ();
}

void WebFlowCredentials.set_account (Account *account) {
    AbstractCredentials.set_account (account);
    if (_user.is_empty ()) {
        fetch_user ();
    }
}

string WebFlowCredentials.fetch_user () {
    _user = _account.credential_setting (user_c).to_string ();
    return _user;
}

void WebFlowCredentials.slot_authentication (QNetworkReply *reply, QAuthenticator *authenticator) {
    Q_UNUSED (reply)

    if (!_ready) {
        return;
    }

    if (_credentials_valid == false) {
        return;
    }

    q_c_debug (lc_web_flow_credentials ()) << "Requires authentication";

    authenticator.set_user (_user);
    authenticator.set_password (_password);
    _credentials_valid = false;
}

void WebFlowCredentials.slot_finished (QNetworkReply *reply) {
    q_c_info (lc_web_flow_credentials ()) << "request finished";

    if (reply.error () == QNetworkReply.NoError) {
        _credentials_valid = true;

        /// Used later for remote wipe
        _account.write_app_password_once (_password);
    }
}

void WebFlowCredentials.fetch_from_keychain_helper () {
    // Read client cert from keychain
    auto job = new KeychainChunk.ReadJob (_account,
                                          _user + client_certificate_pemC,
                                          _keychain_migration,
                                          this);
    connect (job, &KeychainChunk.ReadJob.finished, this, &WebFlowCredentials.slot_read_client_cert_pem_job_done);
    job.start ();
}

void WebFlowCredentials.slot_read_client_cert_pem_job_done (KeychainChunk.ReadJob *read_job) {
    // Store PEM in memory
    if (read_job.error () == NoError && read_job.binary_data ().length () > 0) {
        QList<QSslCertificate> ssl_certificate_list = QSslCertificate.from_data (read_job.binary_data (), QSsl.Pem);
        if (ssl_certificate_list.length () >= 1) {
            _client_ssl_certificate = ssl_certificate_list.at (0);
        }
    }

    // Load key too
    auto job = new KeychainChunk.ReadJob (_account,
                                          _user + client_key_pemC,
                                          _keychain_migration,
                                          this);
    connect (job, &KeychainChunk.ReadJob.finished, this, &WebFlowCredentials.slot_read_client_key_pem_job_done);
    job.start ();
}

void WebFlowCredentials.slot_read_client_key_pem_job_done (KeychainChunk.ReadJob *read_job) {
    // Store key in memory
    if (read_job.error () == NoError && read_job.binary_data ().length () > 0) {
        QByteArray client_key_pem = read_job.binary_data ();
        // FIXME Unfortunately Qt has a bug and we can't just use QSsl.Opaque to let it
        // load whatever we have. So we try until it works.
        _client_ssl_key = QSslKey (client_key_pem, QSsl.Rsa);
        if (_client_ssl_key.is_null ()) {
            _client_ssl_key = QSslKey (client_key_pem, QSsl.Dsa);
        }
        if (_client_ssl_key.is_null ()) {
            _client_ssl_key = QSslKey (client_key_pem, QSsl.Ec);
        }
        if (_client_ssl_key.is_null ()) {
            q_c_warning (lc_web_flow_credentials) << "Could not load SSL key into Qt!";
        }
        client_key_pem.clear ();
    } else {
        q_c_warning (lc_web_flow_credentials) << "Unable to read client key" << read_job.error_string ();
    }

    // Start fetching client CA certs
    _client_ssl_ca_certificates.clear ();

    read_single_client_ca_cert_pem ();
}

void WebFlowCredentials.read_single_client_ca_cert_pem () {
    // try to fetch a client ca cert
    if (_client_ssl_ca_certificates.count () < _client_ssl_ca_certificates_max_count) {
        auto job = new KeychainChunk.ReadJob (_account,
                                              _user + client_ca_certificate_pemC + string.number (_client_ssl_ca_certificates.count ()),
                                              _keychain_migration,
                                              this);
        connect (job, &KeychainChunk.ReadJob.finished, this, &WebFlowCredentials.slot_read_client_ca_certs_pem_job_done);
        job.start ();
    } else {
        q_c_warning (lc_web_flow_credentials) << "Maximum client CA cert count exceeded while reading, ignoring after" << _client_ssl_ca_certificates_max_count;

        slot_read_client_ca_certs_pem_job_done (nullptr);
    }
}

void WebFlowCredentials.slot_read_client_ca_certs_pem_job_done (KeychainChunk.ReadJob *read_job) {
    // Store cert in memory
    if (read_job) {
        if (read_job.error () == NoError && read_job.binary_data ().length () > 0) {
            QList<QSslCertificate> ssl_certificate_list = QSslCertificate.from_data (read_job.binary_data (), QSsl.Pem);
            if (ssl_certificate_list.length () >= 1) {
                _client_ssl_ca_certificates.append (ssl_certificate_list.at (0));
            }

            // try next cert
            read_single_client_ca_cert_pem ();
            return;
        } else {
            if (read_job.error () != QKeychain.Error.EntryNotFound ||
                ( (read_job.error () == QKeychain.Error.EntryNotFound) && _client_ssl_ca_certificates.count () == 0)) {
                q_c_warning (lc_web_flow_credentials) << "Unable to read client CA cert slot" << string.number (_client_ssl_ca_certificates.count ()) << read_job.error_string ();
            }
        }
    }

    // Now fetch the actual server password
    const string kck = keychain_key (
        _account.url ().to_string (),
        _user,
        _keychain_migration ? string () : _account.id ());

    auto job = new ReadPasswordJob (Theme.instance ().app_name (), this);
#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
    add_settings_to_job (_account, job);
#endif
    job.set_insecure_fallback (false);
    job.set_key (kck);
    connect (job, &Job.finished, this, &WebFlowCredentials.slot_read_password_job_done);
    job.start ();
}

void WebFlowCredentials.slot_read_password_job_done (Job *incoming_job) {
    auto job = qobject_cast<ReadPasswordJob> (incoming_job);
    QKeychain.Error error = job.error ();

    // If we could not find the entry try the old entries
    if (!_keychain_migration && error == QKeychain.EntryNotFound) {
        _keychain_migration = true;
        fetch_from_keychain_helper ();
        return;
    }

    if (_user.is_empty ()) {
        q_c_warning (lc_web_flow_credentials) << "Strange : User is empty!";
    }

    if (error == QKeychain.NoError) {
        _password = job.text_data ();
        _ready = true;
        _credentials_valid = true;
    } else {
        _ready = false;
    }
    emit fetched ();

    // If keychain data was read from legacy location, wipe these entries and store new ones
    if (_keychain_migration && _ready) {
        _keychain_migration = false;
        persist ();
        delete_keychain_entries (true); // true : delete old entries
        q_c_info (lc_web_flow_credentials) << "Migrated old keychain entries";
    }
}

void WebFlowCredentials.delete_keychain_entries (bool old_keychain_entries) {
    auto start_delete_job = [this, old_keychain_entries] (string key) {
        auto job = new KeychainChunk.DeleteJob (_account, key, old_keychain_entries, this);
        job.start ();
    };

    start_delete_job (_user);

    /* IMPORTANT - remove later - FIXME MS@2019-12-07 -.
      * TODO : For "Log out" & "Remove account" : Remove client CA certs and KEY!
      *
      *       Disabled as long as selecting another cert is not supported by the UI.
      *
      *       Being able to specify a new certificate is important anyway : expiry etc.
      *
      *       We introduce this dirty hack here, to allow deleting them upon Remote Wipe.
    ***********************************************************/
    if (_account.is_remote_wipe_requested_HACK ()) {
    // <-- FIXME MS@2019-12-07

        // Also delete key / cert sub-chunks (KeychainChunk takes care of the Windows workaround)
        // The first chunk (0) has no suffix, to stay compatible with older versions and non-Windows
        start_delete_job (_user + client_key_pemC);
        start_delete_job (_user + client_certificate_pemC);

        // CA cert slots
        for (auto i = 0; i < _client_ssl_ca_certificates.count (); i++) {
            start_delete_job (_user + client_ca_certificate_pemC + string.number (i));
        }

    // FIXME MS@2019-12-07 -.
    }
    // <-- FIXME MS@2019-12-07
}

} // namespace Occ
