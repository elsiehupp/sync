/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <QMutex>
//  #include <QSetting
//  #include <QSslKey>
//  #include <QJsonObject>
//  #include <QJsonDocument
//  #include <Soup.Buffer>
//  #include <qt5keychain/keyc
//  #include <QAuthenticator>

//  #include <QSslCertificate>
//  #include <QSslKey>
//  #include <Soup.Request>


namespace QKeychain {
}

namespace Occ {

/***********************************************************
The authentication system is this way because of Shibboleth.
There used to be two different ways to authenticate:
Shibboleth and HTTP Basic Auth. AbstractCredentials can be
inherited from both ShibbolethCrendentials and
HttpCredentials. HttpCredentials is then split in
HttpCredentials and HttpCredentialsGui.

This class handle both HTTP Basic Auth and OAuth. But
anything that needs GUI to ask the user is in
HttpCredentialsGui.

The authentication mechanism looks like this.

1) First, AccountState will attempt to load the certificate
from the keychain

   ---.  fetch_from_keychain
                |                           }
                v                            }
          on_signal_read_client_cert_pem_job_done       }     There are first 3 QtKeychain jobs to fetch
                |                             }   the TLS client keys, if any, and the password
                v                            }      (or refresh token
          on_signal_read_client_key_pem_job_done        }
                |                           }
                v
            on_signal_read_job_done
                |        |
                |        +------. emit fetched ()   if OAuth is not used
                |
                v
            refresh_access_token ()
                |
                v
            emit fetched ()

2) If the credentials is still not valid when fetched () is
emitted, the ui, will call ask_from_user () which is
implemented in HttpCredentialsGui
***********************************************************/
class HttpCredentials : AbstractCredentials {

    const string USER_C = "user";
    const string IS_OAUTH_C = "oauth";
    const string CLIENT_CERT_BUNDLE_C = "client_cert_pkcs12";
    const string CLIENT_CERT_PASSWORD_C = "this.client_cert_password";
    const string CLIENT_CERTIFICATE_PEM_C = "this.client_certificate_pem";
    const string CLIENT_KEY_PEM_C = "this.client_key_pem";
    const string AUTHENTICATION_FAILED_C = "owncloud-authentication-failed";
    const string NEED_RETRY_C = "owncloud-need-retry";

    //  friend class HttpCredentialsAccessManager;

    /***********************************************************
    ***********************************************************/
    string user { public get; protected set; }

    /***********************************************************
    User's password or OAuth access token
    ***********************************************************/
    string password { public get; protected set; }

    /***********************************************************
    OAuth this.refresh_token, set if OAuth is used.
    ***********************************************************/
    protected string refresh_token;

    /***********************************************************
    ***********************************************************/
    protected string previous_password;

    /***********************************************************
    ***********************************************************/
    protected string fetch_error_string;

    /***********************************************************
    ***********************************************************/
    bool ready { public get; protected set; }

    /***********************************************************
    ***********************************************************/
    protected bool is_renewing_oauth_token = false;

    /***********************************************************
    ***********************************************************/
    protected GLib.ByteArray client_cert_bundle;

    /***********************************************************
    ***********************************************************/
    protected GLib.ByteArray client_cert_password;

    /***********************************************************
    ***********************************************************/
    protected QSslKey client_ssl_key;

    /***********************************************************
    ***********************************************************/
    protected QSslCertificate client_ssl_certificate;

    /***********************************************************
    ***********************************************************/
    protected bool keychain_migration = false;

    /***********************************************************
    true if we haven't done yet any reading from keychain
    ***********************************************************/
    protected bool retry_on_signal_key_chain_error = true;

    /***********************************************************
    Jobs we need to retry once the auth token is fetched
    ***********************************************************/
    protected GLib.List<QPointer<AbstractNetworkJob>> retry_queue;

    /***********************************************************
    Don't add credentials if this is set on a Soup.Request
    ***********************************************************/
    public const Soup.Request.Attribute DontAddCredentialsAttribute = Soup.Request.User;

    /***********************************************************
    From wizard
    ***********************************************************/
    public HttpCredentials (string user, string password, GLib.ByteArray client_cert_bundle = new GLib.ByteArray (), GLib.ByteArray client_cert_password = new GLib.ByteArray ()) {
        this.user = user;
        this.password = password;
        this.ready = true;
        this.client_cert_bundle = client_cert_bundle;
        this.client_cert_password = client_cert_password;
        this.retry_on_signal_key_chain_error = false;
        if (!unpack_client_cert_bundle ()) {
            //  ASSERT (false, "pkcs12 client cert bundle passed to HttpCredentials must be valid");
        }
    }


    /***********************************************************
    ***********************************************************/
    public string auth_type () {
        return string.from_latin1 ("http");
    }


    /***********************************************************
    ***********************************************************/
    public QNetworkAccessManager create_qnam () {
        AccessManager qnam = new HttpCredentialsAccessManager (this);

        connect (qnam, &QNetworkAccessManager.authentication_required,
            this, &HttpCredentials.on_signal_authentication);

        return qnam;
    }




    /***********************************************************
    ***********************************************************/
    public void fetch_from_keychain () {
        this.was_fetched = true;

        // User must be fetched from config file
        fetch_user ();

        if (!this.ready && !this.refresh_token.is_empty ()) {
            // This happens if the credentials are still loaded from the keychain, but we are called
            // here because the auth is invalid, so this means we simply need to refresh the credentials
            refresh_access_token ();
            return;
        }

        if (this.ready) {
            /* Q_EMIT */ fetched ();
        } else {
            this.keychain_migration = false;
            fetch_from_keychain_helper ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool still_valid (Soup.Reply reply) {
        return ( (reply.error () != Soup.Reply.AuthenticationRequiredError)
            // returned if user or password is incorrect
            && (reply.error () != Soup.Reply.OperationCanceledError
                   || !reply.property (AUTHENTICATION_FAILED_C).to_bool ()));
    }


    /***********************************************************
    ***********************************************************/
    public void persist () {
        if (this.user.is_empty ()) {
            // We never connected or fetched the user, there is nothing to save.
            return;
        }

        this.account.credential_setting (QLatin1String (USER_C), this.user);
        this.account.credential_setting (QLatin1String (IS_OAUTH_C), is_using_oauth ());
        if (!this.client_cert_bundle.is_empty ()) {
            // Note that the this.client_cert_bundle will often be cleared after usage,
            // it's just written if it gets passed into the constructor.
            this.account.credential_setting (QLatin1String (CLIENT_CERT_BUNDLE_C), this.client_cert_bundle);
        }
        this.account.wants_account_saved (this.account);

        // write secrets to the keychain
        if (!this.client_cert_bundle.is_empty ()) {
            // Option 1 : If we have a pkcs12 bundle, that'll be written to the config file
            // and we'll just store the bundle password in the keychain. That's prefered
            // since the keychain on older Windows platforms can only store a limited number
            // of bytes per entry and key/cert may exceed that.
            var job = new QKeychain.WritePasswordJob (Theme.instance ().app_name ());
            add_settings_to_job (this.account, job);
            job.insecure_fallback (false);
            connect (job, &QKeychain.Job.on_signal_finished, this, &HttpCredentials.on_signal_write_client_cert_password_job_done);
            job.key (keychain_key (this.account.url ().to_string (), this.user + CLIENT_CERT_PASSWORD_C, this.account.identifier ()));
            job.binary_data (this.client_cert_password);
            job.on_signal_start ();
            this.client_cert_bundle.clear ();
            this.client_cert_password.clear ();
        } else if (this.account.credential_setting (QLatin1String (CLIENT_CERT_BUNDLE_C)).is_null () && !this.client_ssl_certificate.is_null ()) {
            // Option 2, pre 2.6 configs : We used to store the raw cert/key in the keychain and
            // still do so if no bundle is available. We can't currently migrate to Option 1
            // because we have no functions for creating an encrypted pkcs12 bundle.
            var job = new QKeychain.WritePasswordJob (Theme.instance ().app_name ());
            add_settings_to_job (this.account, job);
            job.insecure_fallback (false);
            connect (job, &QKeychain.Job.on_signal_finished, this, &HttpCredentials.on_signal_write_client_cert_pem_job_done);
            job.key (keychain_key (this.account.url ().to_string (), this.user + CLIENT_CERTIFICATE_PEM_C, this.account.identifier ()));
            job.binary_data (this.client_ssl_certificate.to_pem ());
            job.on_signal_start ();
        } else {
            // Option 3 : no client certificate at all (or doesn't need to be written)
            on_signal_write_password_to_keychain ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void invalidate_token () {
        if (!this.password.is_empty ()) {
            this.previous_password = this.password;
        }
        this.password = "";
        this.ready = false;

        // User must be fetched from config file to generate a valid key
        fetch_user ();

        const string kck = keychain_key (this.account.url ().to_string (), this.user, this.account.identifier ());
        if (kck.is_empty ()) {
            GLib.warning ("InvalidateToken : User is empty, bailing out!";
            return;
        }

        // clear the session cookie.
        this.account.clear_cookie_jar ();

        if (!this.refresh_token.is_empty ()) {
            // Only invalidate the access_token (this.password) but keep the this.refresh_token in the keychain
            // (when coming from forget_sensitive_data, the this.refresh_token is cleared)
            return;
        }

        var job = new QKeychain.DeletePasswordJob (Theme.instance ().app_name ());
        add_settings_to_job (this.account, job);
        job.insecure_fallback (true);
        job.key (kck);
        job.on_signal_start ();

        // let QNAM forget about the password
        // This needs to be done later in the event loop because we might be called (directly or
        // indirectly) from QNetworkAccessManagerPrivate.authentication_required, which itself
        // is a called from a BlockingQueuedConnection from the Qt HTTP thread. And clearing the
        // cache needs to synchronize again with the HTTP thread.
        QTimer.single_shot (0, this.account, &Account.on_signal_clear_qnam_cache);
    }


    /***********************************************************
    ***********************************************************/
    public void forget_sensitive_data () {
        // need to be done before invalidate_token, so it actually deletes the refresh_token from the keychain
        this.refresh_token.clear ();

        invalidate_token ();
        this.previous_password.clear ();
    }


    /***********************************************************
    ***********************************************************/
    public string fetch_user () {
        this.user = this.account.credential_setting (QLatin1String (USER_C)).to_string ();
        return this.user;
    }


    /***********************************************************
    ***********************************************************/
    public virtual bool ssl_is_trusted () {
        return false;
    }


    /***********************************************************
    If we still have a valid refresh token, try to refresh it
    asynchronously and emit fetched () otherwise return false
    ***********************************************************/
    public bool refresh_access_token () {
        if (this.refresh_token.is_empty ())
            return false;

        GLib.Uri request_token = Utility.concat_url_path (this.account.url (), QLatin1String ("/index.php/apps/oauth2/api/v1/token"));
        Soup.Request request;
        request.header (Soup.Request.ContentTypeHeader, "application/x-www-form-urlencoded");

        string basic_auth = string ("%1:%2").arg (
            Theme.instance ().oauth_client_id (), Theme.instance ().oauth_client_secret ());
        request.raw_header ("Authorization", "Basic " + basic_auth.to_utf8 ().to_base64 ());
        request.attribute (HttpCredentials.DontAddCredentialsAttribute, true);

        var request_body = new Soup.Buffer;
        QUrlQuery arguments (string ("grant_type=refresh_token&refresh_token=%1").arg (this.refresh_token));
        request_body.data (arguments.query (GLib.Uri.FullyEncoded).to_latin1 ());

        var job = this.account.send_request ("POST", request_token, request, request_body);
        job.on_signal_timeout (q_min (30 * 1000ll, job.timeout_msec ()));
        GLib.Object.connect (job, &SimpleNetworkJob.finished_signal, this, (Soup.Reply reply) {
            var json_data = reply.read_all ();
            QJsonParseError json_parse_error;
            QJsonObject json = QJsonDocument.from_json (json_data, json_parse_error).object ();
            string access_token = json["access_token"].to_string ();
            if (json_parse_error.error != QJsonParseError.NoError || json.is_empty ()) {
                // Invalid or empty JSON : Network error maybe?
                GLib.warning ("Error while refreshing the token" + reply.error_string () + json_data + json_parse_error.error_string ();
            } else if (access_token.is_empty ()) {
                // If the json was valid, but the reply did not contain an access token, the token
                // is considered expired. (Usually the HTTP reply code is 400)
                GLib.debug ("Expired refresh token. Logging out";
                this.refresh_token.clear ();
            } else {
                this.ready = true;
                this.password = access_token;
                this.refresh_token = json["refresh_token"].to_string ();
                persist ();
            }
            this.is_renewing_oauth_token = false;
            foreach (var job in this.retry_queue) {
                if (job)
                    job.retry ();
            }
            this.retry_queue.clear ();
            /* emit */ fetched ();
        });
        this.is_renewing_oauth_token = true;
        return true;
    }


    /***********************************************************
    To fetch the user name as early as possible
    ***********************************************************/
    public void account (Account account) {
        AbstractCredentials.account (account);
        if (this.user.is_empty ()) {
            fetch_user ();
        }
    }


    /***********************************************************
    Whether we are using OAuth
    ***********************************************************/
    public bool is_using_oauth () {
        return !this.refresh_token.is_null ();
    }


    /***********************************************************
    ***********************************************************/
    public bool retry_if_needed (AbstractNetworkJob job) {
        var reply = job.reply ();
        if (!reply || !reply.property (NEED_RETRY_C).to_bool ())
            return false;
        if (this.is_renewing_oauth_token) {
            this.retry_queue.append (job);
        } else {
            job.retry ();
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_authentication (Soup.Reply reply, QAuthenticator authenticator) {
        if (!this.ready)
            return;
        //  Q_UNUSED (authenticator)
        // Because of issue #4326, we need to set the login and password manually at every requests
        // Thus, if we reach this signal, those credentials were invalid and we terminate.
        GLib.warning ("Stop request : Authentication failed for " + reply.url ().to_string ();
        reply.property (AUTHENTICATION_FAILED_C, true);

        if (this.is_renewing_oauth_token) {
            reply.property (NEED_RETRY_C, true);
        } else if (is_using_oauth () && !reply.property (NEED_RETRY_C).to_bool ()) {
            reply.property (NEED_RETRY_C, true);
            GLib.info ("Refreshing token";
            refresh_access_token ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_read_client_cert_password_job_done (QKeychain.Job job) {
        var read_job = qobject_cast<QKeychain.ReadPasswordJob> (job);
        if (keychain_unavailable_retry_later (read_job))
            return;

        if (read_job.error () == QKeychain.NoError) {
            this.client_cert_password = read_job.binary_data ();
        } else {
            GLib.warning ("Could not retrieve client cert password from keychain" + read_job.error_string ();
        }

        if (!unpack_client_cert_bundle ()) {
            GLib.warning ("Could not unpack client cert bundle";
        }
        this.client_cert_bundle.clear ();
        this.client_cert_password.clear ();

        on_signal_read_password_from_keychain ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_read_client_cert_pem_job_done (QKeychain.Job incoming) {
        var read_job = qobject_cast<QKeychain.ReadPasswordJob> (incoming);
        if (keychain_unavailable_retry_later (read_job))
            return;

        // Store PEM in memory
        if (read_job.error () == QKeychain.NoError && read_job.binary_data ().length () > 0) {
            GLib.List<QSslCertificate> ssl_certificate_list = QSslCertificate.from_data (read_job.binary_data (), QSsl.Pem);
            if (ssl_certificate_list.length () >= 1) {
                this.client_ssl_certificate = ssl_certificate_list.at (0);
            }
        }

        // Load key too
        const string kck = keychain_key (
            this.account.url ().to_string (),
            this.user + CLIENT_KEY_PEM_C,
            this.keychain_migration ? "" : this.account.identifier ());

        var job = new QKeychain.ReadPasswordJob (Theme.instance ().app_name ());
        add_settings_to_job (this.account, job);
        job.insecure_fallback (false);
        job.key (kck);
        connect (job, &QKeychain.ReadPasswordJob.on_signal_finished, this, &HttpCredentials.on_signal_read_client_key_pem_job_done);
        job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_read_client_key_pem_job_done (QKeychain.Job incoming) {
        var read_job = qobject_cast<QKeychain.ReadPasswordJob> (incoming);
        // Store key in memory

        if (read_job.error () == QKeychain.NoError && read_job.binary_data ().length () > 0) {
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
        }

        on_signal_read_password_from_keychain ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_read_password_from_keychain () {
        const string kck = keychain_key (
            this.account.url ().to_string (),
            this.user,
            this.keychain_migration ? "" : this.account.identifier ());

        var job = new QKeychain.ReadPasswordJob (Theme.instance ().app_name ());
        add_settings_to_job (this.account, job);
        job.insecure_fallback (false);
        job.key (kck);
        connect (job, &QKeychain.ReadPasswordJob.on_signal_finished, this, &HttpCredentials.on_signal_read_job_done);
        job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_write_client_cert_password_job_done (QKeychain.Job finished_job) {
        if (finished_job && finished_job.error () != QKeychain.NoError) {
            GLib.warning ("Could not write client cert password to credentials"
                                         + finished_job.error () + finished_job.error_string ();
        }

        on_signal_write_password_to_keychain ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_write_client_cert_pem_job_done (QKeychain.Job finished_job) {
        if (finished_job && finished_job.error () != QKeychain.NoError) {
            GLib.warning ("Could not write client cert to credentials"
                                         + finished_job.error () + finished_job.error_string ();
        }

        // write ssl key if there is one
        if (!this.client_ssl_key.is_null ()) {
            var job = new QKeychain.WritePasswordJob (Theme.instance ().app_name ());
            add_settings_to_job (this.account, job);
            job.insecure_fallback (false);
            connect (job, &QKeychain.Job.on_signal_finished, this, &HttpCredentials.on_signal_write_client_key_pem_job_done);
            job.key (keychain_key (this.account.url ().to_string (), this.user + CLIENT_KEY_PEM_C, this.account.identifier ()));
            job.binary_data (this.client_ssl_key.to_pem ());
            job.on_signal_start ();
        } else {
            on_signal_write_client_key_pem_job_done (null);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_write_client_key_pem_job_done (QKeychain.Job finished_job) {
        if (finished_job && finished_job.error () != QKeychain.NoError) {
            GLib.warning ("Could not write client key to credentials"
                                         + finished_job.error () + finished_job.error_string ();
        }

        on_signal_write_password_to_keychain ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_read_job_done (QKeychain.Job incoming) {
        var job = static_cast<QKeychain.ReadPasswordJob> (incoming);
        QKeychain.Error error = job.error ();

        // If we can't find the credentials at the keys that include the account identifier,
        // try to read them from the legacy locations that don't have a account identifier.
        if (!this.keychain_migration && error == QKeychain.EntryNotFound) {
            GLib.warning ()
                + "Could not find keychain entries, attempting to read from legacy locations";
            this.keychain_migration = true;
            fetch_from_keychain_helper ();
            return;
        }

        bool is_oauth = this.account.credential_setting (QLatin1String (IS_OAUTH_C)).to_bool ();
        if (is_oauth) {
            this.refresh_token = job.text_data ();
        } else {
            this.password = job.text_data ();
        }

        if (this.user.is_empty ()) {
            GLib.warning ("Strange : User is empty!";
        }

        if (!this.refresh_token.is_empty () && error == QKeychain.NoError) {
            refresh_access_token ();
        } else if (!this.password.is_empty () && error == QKeychain.NoError) {
            // All cool, the keychain did not come back with error.
            // Still, the password can be empty which indicates a problem and
            // the password dialog has to be opened.
            this.ready = true;
            /* emit */ fetched ();
        } else {
            // we come here if the password is empty or any other keychain
            // error happend.

            this.fetch_error_string = job.error () != QKeychain.EntryNotFound ? job.error_string () : "";

            this.password = "";
            this.ready = false;
            /* emit */ fetched ();
        }

        // If keychain data was read from legacy location, wipe these entries and store new ones
        if (this.keychain_migration && this.ready) {
            persist ();
            delete_old_keychain_entries ();
            GLib.warning ("Migrated old keychain entries";
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_write_password_to_keychain () {
        var job = new QKeychain.WritePasswordJob (Theme.instance ().app_name ());
        add_settings_to_job (this.account, job);
        job.insecure_fallback (false);
        connect (job, &QKeychain.Job.on_signal_finished, this, &HttpCredentials.on_signal_write_job_done);
        job.key (keychain_key (this.account.url ().to_string (), this.user, this.account.identifier ()));
        job.text_data (is_using_oauth () ? this.refresh_token : this.password);
        job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_write_job_done (QKeychain.Job job) {
        if (job && job.error () != QKeychain.NoError) {
            GLib.warning ("Error while writing password"
                                         + job.error () + job.error_string ();
        }
    }


    /***********************************************************
    Reads data from keychain locations

    Goes through
      on_signal_read_client_cert_pem_job_done to
      on_signal_read_client_cert_pem_job_done to
      on_signal_read_job_done
    ***********************************************************/
    protected void fetch_from_keychain_helper () {
        this.client_cert_bundle = this.account.credential_setting (QLatin1String (CLIENT_CERT_BUNDLE_C)).to_byte_array ();
        if (!this.client_cert_bundle.is_empty ()) {
            // New case (>=2.6) : We have a bundle in the settings and read the password from
            // the keychain
            var job = new QKeychain.ReadPasswordJob (Theme.instance ().app_name ());
            add_settings_to_job (this.account, job);
            job.insecure_fallback (false);
            job.key (keychain_key (this.account.url ().to_string (), this.user + CLIENT_CERT_PASSWORD_C, this.account.identifier ()));
            connect (job, &QKeychain.Job.on_signal_finished, this, &HttpCredentials.on_signal_read_client_cert_password_job_done);
            job.on_signal_start ();
            return;
        }

        // Old case (pre 2.6) : Read client cert and then key from keychain
        const string kck = keychain_key (
            this.account.url ().to_string (),
            this.user + CLIENT_CERTIFICATE_PEM_C,
            this.keychain_migration ? "" : this.account.identifier ());

        var job = new QKeychain.ReadPasswordJob (Theme.instance ().app_name ());
        add_settings_to_job (this.account, job);
        job.insecure_fallback (false);
        job.key (kck);
        connect (job, &QKeychain.Job.on_signal_finished, this, &HttpCredentials.on_signal_read_client_cert_pem_job_done);
        job.on_signal_start ();
    }



    /***********************************************************
    Wipes legacy keychain locations
    ***********************************************************/
    protected void delete_old_keychain_entries () {
        var start_delete_job = [this] (string user) {
            var job = new QKeychain.DeletePasswordJob (Theme.instance ().app_name ());
            add_settings_to_job (this.account, job);
            job.insecure_fallback (true);
            job.key (keychain_key (this.account.url ().to_string (), user, ""));
            job.on_signal_start ();
        }

        start_delete_job (this.user);
        start_delete_job (this.user + CLIENT_KEY_PEM_C);
        start_delete_job (this.user + CLIENT_CERTIFICATE_PEM_C);
    }


    /***********************************************************
    Whether to bow out now because a retry will happen later

    Sometimes the keychain needs a while to become available.
    This function should be called on first keychain-read to
    check whether it errored because the keychain wasn't
    available yet. If that happens, this function will schedule
    another try and return true.
    ***********************************************************/
    protected bool keychain_unavailable_retry_later (QKeychain.ReadPasswordJob incoming) {
        //  Q_ASSERT (!incoming.insecure_fallback ()); // If insecure_fallback is set, the next test would be pointless
        if (this.retry_on_signal_key_chain_error && (incoming.error () == QKeychain.NoBackendAvailable
                || incoming.error () == QKeychain.OtherError)) {
            // Could be that the backend was not yet available. Wait some extra seconds.
            // (Issues #4274 and #6522)
            // (For kwallet, the error is OtherError instead of NoBackendAvailable, maybe a bug in QtKeychain)
            GLib.info ("Backend unavailable (yet?) Retrying in a few seconds." + incoming.error_string ();
            QTimer.single_shot (10000, this, &HttpCredentials.fetch_from_keychain_helper);
            this.retry_on_signal_key_chain_error = false;
            return true;
        }
        this.retry_on_signal_key_chain_error = false;
        return false;
    }


    /***********************************************************
    Takes client cert pkcs12 and unwraps the key/cert.

    Returns false on failure.
    ***********************************************************/
    protected bool unpack_client_cert_bundle () {
        if (this.client_cert_bundle.is_empty ())
            return true;

        Soup.Buffer cert_buffer (&this.client_cert_bundle);
        cert_buffer.open (QIODevice.ReadOnly);
        GLib.List<QSslCertificate> client_ca_certificates;
        return QSslCertificate.import_pkcs12 (
                cert_buffer, this.client_ssl_key, this.client_ssl_certificate, client_ca_certificates, this.client_cert_password);
    }


    /***********************************************************
    ***********************************************************/
    private static void add_settings_to_job (Account account, QKeychain.Job job) {
        //  Q_UNUSED (account);
        var settings = ConfigFile.settings_with_group (Theme.instance ().app_name ());
        settings.parent (job); // make the job parent to make setting deleted properly
        job.settings (settings.release ());
    }

} // class HttpCredentials

} // namespace Occ
    