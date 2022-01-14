/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QMutex>
// #include <QNetworkReply>
// #include <QSettings>
// #include <QSslKey>
// #include <QJsonObject>
// #include <QJsonDocument>
// #include <QBuffer>

// #include <qt5keychain/keychain.h>

// #include <QAuthenticator>

// #include <QMap>
// #include <QSslCertificate>
// #include <QSslKey>
// #include <QNetworkRequest>


namespace QKeychain {
}

namespace Occ {


namespace {
    const char user_c[] = "user";
    const char is_oAuth_c[] = "oauth";
    const char client_cert_bundle_c[] = "client_cert_pkcs12";
    const char client_cert_password_c[] = "_client_cert_password";
    const char client_certificate_pemC[] = "_client_certificate_pem";
    const char client_key_pemC[] = "_client_key_pem";
    const char authentication_failed_c[] = "owncloud-authentication-failed";
    const char need_retry_c[] = "owncloud-need-retry";
} // ns

/***********************************************************
   The authentication system is this way because of Shibboleth.
   There used to be two different ways to authenticate : Shibboleth and HTTP Basic Auth.
   AbstractCredentials can be inherited from both Shibboleth_crendentials and HttpCredentials.

   HttpCredentials is then split in HttpCredentials and HttpCredentialsGui.

   This class handle both HTTP Basic Auth and OAuth. But anything that needs GUI to ask the user
   is in HttpCredentialsGui.

   The authentication mechanism looks like this.

   1) First, AccountState will attempt to load the certificate from the keychain

   ---.  fetch_from_keychain
                |                           }
                v                            }
          slot_read_client_cert_pem_job_done       }     There are first 3 QtKeychain jobs to fetch
                |                             }   the TLS client keys, if any, and the password
                v                            }      (or refresh token
          slot_read_client_key_pem_job_done        }
                |                           }
                v
            slot_read_job_done
                |        |
                |        +------. emit fetched ()   if OAuth is not used
                |
                v
            refresh_access_token ()
                |
                v
            emit fetched ()

   2) If the credentials is still not valid when fetched () is emitted, the ui, will call ask_from_user ()
      which is implemented in HttpCredentialsGui

***********************************************************/
class HttpCredentials : AbstractCredentials {
    friend class HttpCredentialsAccessManager;

public:
    /// Don't add credentials if this is set on a QNetworkRequest
    static constexpr QNetworkRequest.Attribute DontAddCredentialsAttribute = QNetworkRequest.User;

    HttpCredentials ();
    HttpCredentials (string &user, string &password,
            const QByteArray &client_cert_bundle = QByteArray (), QByteArray &client_cert_password = QByteArray ());

    string auth_type () const override;
    QNetworkAccessManager *create_qNAM () const override;
    bool ready () const override;
    void fetch_from_keychain () override;
    bool still_valid (QNetworkReply *reply) override;
    void persist () override;
    string user () const override;
    // the password or token
    string password () const override;
    void invalidate_token () override;
    void forget_sensitive_data () override;
    string fetch_user ();
    virtual bool ssl_is_trusted () {
        return false;
    }

    /* If we still have a valid refresh token, try to refresh it assynchronously and emit fetched ()
    otherwise return false
    ***********************************************************/
    bool refresh_access_token ();

    // To fetch the user name as early as possible
    void set_account (Account *account) override;

    // Whether we are using OAuth
    bool is_using_oAuth () {
        return !_refresh_token.is_null ();
    }

    bool retry_if_needed (AbstractNetworkJob *) override;

private slots:
    void slot_authentication (QNetworkReply *, QAuthenticator *);

    void slot_read_client_cert_password_job_done (QKeychain.Job *);
    void slot_read_client_cert_pem_job_done (QKeychain.Job *);
    void slot_read_client_key_pem_job_done (QKeychain.Job *);

    void slot_read_password_from_keychain ();
    void slot_read_job_done (QKeychain.Job *);

    void slot_write_client_cert_password_job_done (QKeychain.Job *);
    void slot_write_client_cert_pem_job_done (QKeychain.Job *);
    void slot_write_client_key_pem_job_done (QKeychain.Job *);

    void slot_write_password_to_keychain ();
    void slot_write_job_done (QKeychain.Job *);

protected:
    /***********************************************************
    Reads data from keychain locations

    Goes through
      slot_read_client_cert_pem_job_done to
      slot_read_client_cert_pem_job_done to
      slot_read_job_done
    ***********************************************************/
    void fetch_from_keychain_helper ();

    /// Wipes legacy keychain locations
    void delete_old_keychain_entries ();

    /***********************************************************
    Whether to bow out now because a retry will happen later

    Sometimes the keychain needs a while to become available.
    This function should be called on first keychain-read to check
    whether it errored because the keychain wasn't available yet.
    If that happens, this function will schedule another try and
    return true.
    ***********************************************************/
    bool keychain_unavailable_retry_later (QKeychain.ReadPasswordJob *);

    /***********************************************************
    Takes client cert pkcs12 and unwraps the key/cert.

    Returns false on failure.
    ***********************************************************/
    bool unpack_client_cert_bundle ();

    string _user;
    string _password; // user's password, or access_token for OAuth
    string _refresh_token; // OAuth _refresh_token, set if OAuth is used.
    string _previous_password;

    string _fetch_error_string;
    bool _ready = false;
    bool _is_renewing_oAuth_token = false;
    QByteArray _client_cert_bundle;
    QByteArray _client_cert_password;
    QSslKey _client_ssl_key;
    QSslCertificate _client_ssl_certificate;
    bool _keychain_migration = false;
    bool _retry_on_key_chain_error = true; // true if we haven't done yet any reading from keychain

    QVector<QPointer<AbstractNetworkJob>> _retry_queue; // Jobs we need to retry once the auth token is fetched
};



    class HttpCredentialsAccessManager : AccessManager {
    public:
        HttpCredentialsAccessManager (HttpCredentials *cred, GLib.Object *parent = nullptr)
            : AccessManager (parent)
            , _cred (cred) {
        }

    protected:
        QNetworkReply *create_request (Operation op, QNetworkRequest &request, QIODevice *outgoing_data) override {
            QNetworkRequest req (request);
            if (!req.attribute (HttpCredentials.DontAddCredentialsAttribute).to_bool ()) {
                if (_cred && !_cred.password ().is_empty ()) {
                    if (_cred.is_using_oAuth ()) {
                        req.set_raw_header ("Authorization", "Bearer " + _cred.password ().to_utf8 ());
                    } else {
                        QByteArray cred_hash = QByteArray (_cred.user ().to_utf8 () + ":" + _cred.password ().to_utf8 ()).to_base64 ();
                        req.set_raw_header ("Authorization", "Basic " + cred_hash);
                    }
                } else if (!request.url ().password ().is_empty ()) {
                    // Typically the requests to get or refresh the OAuth access token. The client
                    // credentials are put in the URL from the code making the request.
                    QByteArray cred_hash = request.url ().user_info ().to_utf8 ().to_base64 ();
                    req.set_raw_header ("Authorization", "Basic " + cred_hash);
                }
            }

            if (_cred && !_cred._client_ssl_key.is_null () && !_cred._client_ssl_certificate.is_null ()) {
                // SSL configuration
                QSslConfiguration ssl_configuration = req.ssl_configuration ();
                ssl_configuration.set_local_certificate (_cred._client_ssl_certificate);
                ssl_configuration.set_private_key (_cred._client_ssl_key);
                req.set_ssl_configuration (ssl_configuration);
            }

            auto *reply = AccessManager.create_request (op, req, outgoing_data);

            if (_cred._is_renewing_oAuth_token) {
                // We know this is going to fail, but we have no way to queue it there, so we will
                // simply restart the job after the failure.
                reply.set_property (need_retry_c, true);
            }

            return reply;
        }

    private:
        // The credentials object dies along with the account, while the QNAM might
        // outlive both.
        QPointer<const HttpCredentials> _cred;
    };

    static void add_settings_to_job (Account *account, QKeychain.Job *job) {
        Q_UNUSED (account);
        auto settings = ConfigFile.settings_with_group (Theme.instance ().app_name ());
        settings.set_parent (job); // make the job parent to make setting deleted properly
        job.set_settings (settings.release ());
    }

    HttpCredentials.HttpCredentials () = default;

    // From wizard
    HttpCredentials.HttpCredentials (string &user, string &password, QByteArray &client_cert_bundle, QByteArray &client_cert_password)
        : _user (user)
        , _password (password)
        , _ready (true)
        , _client_cert_bundle (client_cert_bundle)
        , _client_cert_password (client_cert_password)
        , _retry_on_key_chain_error (false) {
        if (!unpack_client_cert_bundle ()) {
            ASSERT (false, "pkcs12 client cert bundle passed to HttpCredentials must be valid");
        }
    }

    string HttpCredentials.auth_type () {
        return string.from_latin1 ("http");
    }

    string HttpCredentials.user () {
        return _user;
    }

    string HttpCredentials.password () {
        return _password;
    }

    void HttpCredentials.set_account (Account *account) {
        AbstractCredentials.set_account (account);
        if (_user.is_empty ()) {
            fetch_user ();
        }
    }

    QNetworkAccessManager *HttpCredentials.create_qNAM () {
        AccessManager *qnam = new HttpCredentialsAccessManager (this);

        connect (qnam, &QNetworkAccessManager.authentication_required,
            this, &HttpCredentials.slot_authentication);

        return qnam;
    }

    bool HttpCredentials.ready () {
        return _ready;
    }

    string HttpCredentials.fetch_user () {
        _user = _account.credential_setting (QLatin1String (user_c)).to_string ();
        return _user;
    }

    void HttpCredentials.fetch_from_keychain () {
        _was_fetched = true;

        // User must be fetched from config file
        fetch_user ();

        if (!_ready && !_refresh_token.is_empty ()) {
            // This happens if the credentials are still loaded from the keychain, but we are called
            // here because the auth is invalid, so this means we simply need to refresh the credentials
            refresh_access_token ();
            return;
        }

        if (_ready) {
            Q_EMIT fetched ();
        } else {
            _keychain_migration = false;
            fetch_from_keychain_helper ();
        }
    }

    void HttpCredentials.fetch_from_keychain_helper () {
        _client_cert_bundle = _account.credential_setting (QLatin1String (client_cert_bundle_c)).to_byte_array ();
        if (!_client_cert_bundle.is_empty ()) {
            // New case (>=2.6) : We have a bundle in the settings and read the password from
            // the keychain
            auto job = new QKeychain.ReadPasswordJob (Theme.instance ().app_name ());
            add_settings_to_job (_account, job);
            job.set_insecure_fallback (false);
            job.set_key (keychain_key (_account.url ().to_string (), _user + client_cert_password_c, _account.id ()));
            connect (job, &QKeychain.Job.finished, this, &HttpCredentials.slot_read_client_cert_password_job_done);
            job.start ();
            return;
        }

        // Old case (pre 2.6) : Read client cert and then key from keychain
        const string kck = keychain_key (
            _account.url ().to_string (),
            _user + client_certificate_pemC,
            _keychain_migration ? string () : _account.id ());

        auto *job = new QKeychain.ReadPasswordJob (Theme.instance ().app_name ());
        add_settings_to_job (_account, job);
        job.set_insecure_fallback (false);
        job.set_key (kck);
        connect (job, &QKeychain.Job.finished, this, &HttpCredentials.slot_read_client_cert_pem_job_done);
        job.start ();
    }

    void HttpCredentials.delete_old_keychain_entries () {
        auto start_delete_job = [this] (string user) {
            auto *job = new QKeychain.DeletePasswordJob (Theme.instance ().app_name ());
            add_settings_to_job (_account, job);
            job.set_insecure_fallback (true);
            job.set_key (keychain_key (_account.url ().to_string (), user, string ()));
            job.start ();
        };

        start_delete_job (_user);
        start_delete_job (_user + client_key_pemC);
        start_delete_job (_user + client_certificate_pemC);
    }

    bool HttpCredentials.keychain_unavailable_retry_later (QKeychain.ReadPasswordJob *incoming) {
        Q_ASSERT (!incoming.insecure_fallback ()); // If insecure_fallback is set, the next test would be pointless
        if (_retry_on_key_chain_error && (incoming.error () == QKeychain.No_backend_available
                || incoming.error () == QKeychain.Other_error)) {
            // Could be that the backend was not yet available. Wait some extra seconds.
            // (Issues #4274 and #6522)
            // (For kwallet, the error is Other_error instead of No_backend_available, maybe a bug in QtKeychain)
            q_c_info (lc_http_credentials) << "Backend unavailable (yet?) Retrying in a few seconds." << incoming.error_string ();
            QTimer.single_shot (10000, this, &HttpCredentials.fetch_from_keychain_helper);
            _retry_on_key_chain_error = false;
            return true;
        }
        _retry_on_key_chain_error = false;
        return false;
    }

    void HttpCredentials.slot_read_client_cert_password_job_done (QKeychain.Job *job) {
        auto read_job = qobject_cast<QKeychain.ReadPasswordJob> (job);
        if (keychain_unavailable_retry_later (read_job))
            return;

        if (read_job.error () == QKeychain.NoError) {
            _client_cert_password = read_job.binary_data ();
        } else {
            q_c_warning (lc_http_credentials) << "Could not retrieve client cert password from keychain" << read_job.error_string ();
        }

        if (!unpack_client_cert_bundle ()) {
            q_c_warning (lc_http_credentials) << "Could not unpack client cert bundle";
        }
        _client_cert_bundle.clear ();
        _client_cert_password.clear ();

        slot_read_password_from_keychain ();
    }

    void HttpCredentials.slot_read_client_cert_pem_job_done (QKeychain.Job *incoming) {
        auto read_job = qobject_cast<QKeychain.ReadPasswordJob> (incoming);
        if (keychain_unavailable_retry_later (read_job))
            return;

        // Store PEM in memory
        if (read_job.error () == QKeychain.NoError && read_job.binary_data ().length () > 0) {
            QList<QSslCertificate> ssl_certificate_list = QSslCertificate.from_data (read_job.binary_data (), QSsl.Pem);
            if (ssl_certificate_list.length () >= 1) {
                _client_ssl_certificate = ssl_certificate_list.at (0);
            }
        }

        // Load key too
        const string kck = keychain_key (
            _account.url ().to_string (),
            _user + client_key_pemC,
            _keychain_migration ? string () : _account.id ());

        auto *job = new QKeychain.ReadPasswordJob (Theme.instance ().app_name ());
        add_settings_to_job (_account, job);
        job.set_insecure_fallback (false);
        job.set_key (kck);
        connect (job, &QKeychain.ReadPasswordJob.finished, this, &HttpCredentials.slot_read_client_key_pem_job_done);
        job.start ();
    }

    void HttpCredentials.slot_read_client_key_pem_job_done (QKeychain.Job *incoming) {
        auto read_job = qobject_cast<QKeychain.ReadPasswordJob> (incoming);
        // Store key in memory

        if (read_job.error () == QKeychain.NoError && read_job.binary_data ().length () > 0) {
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
                q_c_warning (lc_http_credentials) << "Could not load SSL key into Qt!";
            }
        }

        slot_read_password_from_keychain ();
    }

    void HttpCredentials.slot_read_password_from_keychain () {
        const string kck = keychain_key (
            _account.url ().to_string (),
            _user,
            _keychain_migration ? string () : _account.id ());

        auto *job = new QKeychain.ReadPasswordJob (Theme.instance ().app_name ());
        add_settings_to_job (_account, job);
        job.set_insecure_fallback (false);
        job.set_key (kck);
        connect (job, &QKeychain.ReadPasswordJob.finished, this, &HttpCredentials.slot_read_job_done);
        job.start ();
    }

    bool HttpCredentials.still_valid (QNetworkReply *reply) {
        return ( (reply.error () != QNetworkReply.AuthenticationRequiredError)
            // returned if user or password is incorrect
            && (reply.error () != QNetworkReply.Operation_canceled_error
                   || !reply.property (authentication_failed_c).to_bool ()));
    }

    void HttpCredentials.slot_read_job_done (QKeychain.Job *incoming) {
        auto *job = static_cast<QKeychain.ReadPasswordJob> (incoming);
        QKeychain.Error error = job.error ();

        // If we can't find the credentials at the keys that include the account id,
        // try to read them from the legacy locations that don't have a account id.
        if (!_keychain_migration && error == QKeychain.EntryNotFound) {
            q_c_warning (lc_http_credentials)
                << "Could not find keychain entries, attempting to read from legacy locations";
            _keychain_migration = true;
            fetch_from_keychain_helper ();
            return;
        }

        bool is_oauth = _account.credential_setting (QLatin1String (is_oAuth_c)).to_bool ();
        if (is_oauth) {
            _refresh_token = job.text_data ();
        } else {
            _password = job.text_data ();
        }

        if (_user.is_empty ()) {
            q_c_warning (lc_http_credentials) << "Strange : User is empty!";
        }

        if (!_refresh_token.is_empty () && error == QKeychain.NoError) {
            refresh_access_token ();
        } else if (!_password.is_empty () && error == QKeychain.NoError) {
            // All cool, the keychain did not come back with error.
            // Still, the password can be empty which indicates a problem and
            // the password dialog has to be opened.
            _ready = true;
            emit fetched ();
        } else {
            // we come here if the password is empty or any other keychain
            // error happend.

            _fetch_error_string = job.error () != QKeychain.EntryNotFound ? job.error_string () : string ();

            _password = string ();
            _ready = false;
            emit fetched ();
        }

        // If keychain data was read from legacy location, wipe these entries and store new ones
        if (_keychain_migration && _ready) {
            persist ();
            delete_old_keychain_entries ();
            q_c_warning (lc_http_credentials) << "Migrated old keychain entries";
        }
    }

    bool HttpCredentials.refresh_access_token () {
        if (_refresh_token.is_empty ())
            return false;

        QUrl request_token = Utility.concat_url_path (_account.url (), QLatin1String ("/index.php/apps/oauth2/api/v1/token"));
        QNetworkRequest req;
        req.set_header (QNetworkRequest.ContentTypeHeader, "application/x-www-form-urlencoded");

        string basic_auth = string ("%1:%2").arg (
            Theme.instance ().oauth_client_id (), Theme.instance ().oauth_client_secret ());
        req.set_raw_header ("Authorization", "Basic " + basic_auth.to_utf8 ().to_base64 ());
        req.set_attribute (HttpCredentials.DontAddCredentialsAttribute, true);

        auto request_body = new QBuffer;
        QUrlQuery arguments (string ("grant_type=refresh_token&refresh_token=%1").arg (_refresh_token));
        request_body.set_data (arguments.query (QUrl.FullyEncoded).to_latin1 ());

        auto job = _account.send_request ("POST", request_token, req, request_body);
        job.set_timeout (q_min (30 * 1000ll, job.timeout_msec ()));
        GLib.Object.connect (job, &SimpleNetworkJob.finished_signal, this, [this] (QNetworkReply *reply) {
            auto json_data = reply.read_all ();
            QJsonParseError json_parse_error;
            QJsonObject json = QJsonDocument.from_json (json_data, &json_parse_error).object ();
            string access_token = json["access_token"].to_string ();
            if (json_parse_error.error != QJsonParseError.NoError || json.is_empty ()) {
                // Invalid or empty JSON : Network error maybe?
                q_c_warning (lc_http_credentials) << "Error while refreshing the token" << reply.error_string () << json_data << json_parse_error.error_string ();
            } else if (access_token.is_empty ()) {
                // If the json was valid, but the reply did not contain an access token, the token
                // is considered expired. (Usually the HTTP reply code is 400)
                q_c_debug (lc_http_credentials) << "Expired refresh token. Logging out";
                _refresh_token.clear ();
            } else {
                _ready = true;
                _password = access_token;
                _refresh_token = json["refresh_token"].to_string ();
                persist ();
            }
            _is_renewing_oAuth_token = false;
            for (auto &job : _retry_queue) {
                if (job)
                    job.retry ();
            }
            _retry_queue.clear ();
            emit fetched ();
        });
        _is_renewing_oAuth_token = true;
        return true;
    }

    void HttpCredentials.invalidate_token () {
        if (!_password.is_empty ()) {
            _previous_password = _password;
        }
        _password = string ();
        _ready = false;

        // User must be fetched from config file to generate a valid key
        fetch_user ();

        const string kck = keychain_key (_account.url ().to_string (), _user, _account.id ());
        if (kck.is_empty ()) {
            q_c_warning (lc_http_credentials) << "InvalidateToken : User is empty, bailing out!";
            return;
        }

        // clear the session cookie.
        _account.clear_cookie_jar ();

        if (!_refresh_token.is_empty ()) {
            // Only invalidate the access_token (_password) but keep the _refresh_token in the keychain
            // (when coming from forget_sensitive_data, the _refresh_token is cleared)
            return;
        }

        auto *job = new QKeychain.DeletePasswordJob (Theme.instance ().app_name ());
        add_settings_to_job (_account, job);
        job.set_insecure_fallback (true);
        job.set_key (kck);
        job.start ();

        // let QNAM forget about the password
        // This needs to be done later in the event loop because we might be called (directly or
        // indirectly) from QNetworkAccessManagerPrivate.authentication_required, which itself
        // is a called from a BlockingQueuedConnection from the Qt HTTP thread. And clearing the
        // cache needs to synchronize again with the HTTP thread.
        QTimer.single_shot (0, _account, &Account.clear_qNAMCache);
    }

    void HttpCredentials.forget_sensitive_data () {
        // need to be done before invalidate_token, so it actually deletes the refresh_token from the keychain
        _refresh_token.clear ();

        invalidate_token ();
        _previous_password.clear ();
    }

    void HttpCredentials.persist () {
        if (_user.is_empty ()) {
            // We never connected or fetched the user, there is nothing to save.
            return;
        }

        _account.set_credential_setting (QLatin1String (user_c), _user);
        _account.set_credential_setting (QLatin1String (is_oAuth_c), is_using_oAuth ());
        if (!_client_cert_bundle.is_empty ()) {
            // Note that the _client_cert_bundle will often be cleared after usage,
            // it's just written if it gets passed into the constructor.
            _account.set_credential_setting (QLatin1String (client_cert_bundle_c), _client_cert_bundle);
        }
        _account.wants_account_saved (_account);

        // write secrets to the keychain
        if (!_client_cert_bundle.is_empty ()) {
            // Option 1 : If we have a pkcs12 bundle, that'll be written to the config file
            // and we'll just store the bundle password in the keychain. That's prefered
            // since the keychain on older Windows platforms can only store a limited number
            // of bytes per entry and key/cert may exceed that.
            auto *job = new QKeychain.WritePasswordJob (Theme.instance ().app_name ());
            add_settings_to_job (_account, job);
            job.set_insecure_fallback (false);
            connect (job, &QKeychain.Job.finished, this, &HttpCredentials.slot_write_client_cert_password_job_done);
            job.set_key (keychain_key (_account.url ().to_string (), _user + client_cert_password_c, _account.id ()));
            job.set_binary_data (_client_cert_password);
            job.start ();
            _client_cert_bundle.clear ();
            _client_cert_password.clear ();
        } else if (_account.credential_setting (QLatin1String (client_cert_bundle_c)).is_null () && !_client_ssl_certificate.is_null ()) {
            // Option 2, pre 2.6 configs : We used to store the raw cert/key in the keychain and
            // still do so if no bundle is available. We can't currently migrate to Option 1
            // because we have no functions for creating an encrypted pkcs12 bundle.
            auto *job = new QKeychain.WritePasswordJob (Theme.instance ().app_name ());
            add_settings_to_job (_account, job);
            job.set_insecure_fallback (false);
            connect (job, &QKeychain.Job.finished, this, &HttpCredentials.slot_write_client_cert_pem_job_done);
            job.set_key (keychain_key (_account.url ().to_string (), _user + client_certificate_pemC, _account.id ()));
            job.set_binary_data (_client_ssl_certificate.to_pem ());
            job.start ();
        } else {
            // Option 3 : no client certificate at all (or doesn't need to be written)
            slot_write_password_to_keychain ();
        }
    }

    void HttpCredentials.slot_write_client_cert_password_job_done (QKeychain.Job *finished_job) {
        if (finished_job && finished_job.error () != QKeychain.NoError) {
            q_c_warning (lc_http_credentials) << "Could not write client cert password to credentials"
                                         << finished_job.error () << finished_job.error_string ();
        }

        slot_write_password_to_keychain ();
    }

    void HttpCredentials.slot_write_client_cert_pem_job_done (QKeychain.Job *finished_job) {
        if (finished_job && finished_job.error () != QKeychain.NoError) {
            q_c_warning (lc_http_credentials) << "Could not write client cert to credentials"
                                         << finished_job.error () << finished_job.error_string ();
        }

        // write ssl key if there is one
        if (!_client_ssl_key.is_null ()) {
            auto *job = new QKeychain.WritePasswordJob (Theme.instance ().app_name ());
            add_settings_to_job (_account, job);
            job.set_insecure_fallback (false);
            connect (job, &QKeychain.Job.finished, this, &HttpCredentials.slot_write_client_key_pem_job_done);
            job.set_key (keychain_key (_account.url ().to_string (), _user + client_key_pemC, _account.id ()));
            job.set_binary_data (_client_ssl_key.to_pem ());
            job.start ();
        } else {
            slot_write_client_key_pem_job_done (nullptr);
        }
    }

    void HttpCredentials.slot_write_client_key_pem_job_done (QKeychain.Job *finished_job) {
        if (finished_job && finished_job.error () != QKeychain.NoError) {
            q_c_warning (lc_http_credentials) << "Could not write client key to credentials"
                                         << finished_job.error () << finished_job.error_string ();
        }

        slot_write_password_to_keychain ();
    }

    void HttpCredentials.slot_write_password_to_keychain () {
        auto *job = new QKeychain.WritePasswordJob (Theme.instance ().app_name ());
        add_settings_to_job (_account, job);
        job.set_insecure_fallback (false);
        connect (job, &QKeychain.Job.finished, this, &HttpCredentials.slot_write_job_done);
        job.set_key (keychain_key (_account.url ().to_string (), _user, _account.id ()));
        job.set_text_data (is_using_oAuth () ? _refresh_token : _password);
        job.start ();
    }

    void HttpCredentials.slot_write_job_done (QKeychain.Job *job) {
        if (job && job.error () != QKeychain.NoError) {
            q_c_warning (lc_http_credentials) << "Error while writing password"
                                         << job.error () << job.error_string ();
        }
    }

    void HttpCredentials.slot_authentication (QNetworkReply *reply, QAuthenticator *authenticator) {
        if (!_ready)
            return;
        Q_UNUSED (authenticator)
        // Because of issue #4326, we need to set the login and password manually at every requests
        // Thus, if we reach this signal, those credentials were invalid and we terminate.
        q_c_warning (lc_http_credentials) << "Stop request : Authentication failed for " << reply.url ().to_string ();
        reply.set_property (authentication_failed_c, true);

        if (_is_renewing_oAuth_token) {
            reply.set_property (need_retry_c, true);
        } else if (is_using_oAuth () && !reply.property (need_retry_c).to_bool ()) {
            reply.set_property (need_retry_c, true);
            q_c_info (lc_http_credentials) << "Refreshing token";
            refresh_access_token ();
        }
    }

    bool HttpCredentials.retry_if_needed (AbstractNetworkJob *job) {
        auto *reply = job.reply ();
        if (!reply || !reply.property (need_retry_c).to_bool ())
            return false;
        if (_is_renewing_oAuth_token) {
            _retry_queue.append (job);
        } else {
            job.retry ();
        }
        return true;
    }

    bool HttpCredentials.unpack_client_cert_bundle () {
        if (_client_cert_bundle.is_empty ())
            return true;

        QBuffer cert_buffer (&_client_cert_bundle);
        cert_buffer.open (QIODevice.Read_only);
        QList<QSslCertificate> client_ca_certificates;
        return QSslCertificate.import_pkcs12 (
                &cert_buffer, &_client_ssl_key, &_client_ssl_certificate, &client_ca_certificates, _client_cert_password);
    }

    } // namespace Occ
    