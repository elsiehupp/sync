/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <deletejob.h>

// #include <QLoggingCategory>
// #include <QNetworkReply>
// #include <QNetworkAccessManager>
// #include <QSsl_socket>
// #include <QNetwork_cookie_jar>
// #include <QNetworkProxy>

// #include <QFileInfo>
// #include <QDir>
// #include <QSslKey>
// #include <QAuthenticator>
// #include <QStandardPaths>
// #include <QJsonDocument>
// #include <QJsonObject>
// #include <QJsonArray>
// #include <QLoggingCategory>
// #include <QHttp_multi_part>

// #include <qsslconfiguration.h>
// #include <qt5keychain/keychain.h>

using namespace QKeychain;

// #include <QByteArray>
// #include <QUrl>
// #include <QNetwork_cookie>
// #include <QNetworkRequest>
// #include <QSsl_socket>
// #include <QSslCertificate>
// #include <QSslConfiguration>
// #include <QSsl_cipher>
// #include <QSslError>
// #include <QSharedPointer>

#ifndef TOKEN_AUTH_ONLY
// #include <QPixmap>
#endif

const char app_password[] = "_app-password";

// #include <memory>

class QNetworkAccessManager;

namespace QKeychain {
}


namespace {
    constexpr int push_notifications_reconnect_interval = 1000 * 60 * 2;
    constexpr int username_prefill_server_versin_min_supported_major = 24;
}

namespace Occ {

using AccountPtr = QSharedPointer<Account>;
class User_status_connector;

/***********************************************************
@brief Reimplement this to handle SSL errors from libsync
@ingroup libsync
***********************************************************/
class Abstract_sslErrorHandler {
public:
    virtual ~Abstract_sslErrorHandler () = default;
    virtual bool handle_errors (QList<QSslError>, QSslConfiguration &conf, QList<QSslCertificate> *, AccountPtr) = 0;
};

/***********************************************************
@brief The Account class represents an account on an own_cloud Server
@ingroup libsync

The Account has a name and url. It also has information about credentials,
SSL errors and certificates.
***********************************************************/
class Account : GLib.Object {
    Q_PROPERTY (string id MEMBER _id)
    Q_PROPERTY (string dav_user MEMBER _dav_user)
    Q_PROPERTY (string display_name MEMBER _display_name)
    Q_PROPERTY (QUrl url MEMBER _url)

public:
    static AccountPtr create ();
    ~Account () override;

    AccountPtr shared_from_this ();

    /***********************************************************
    The user that can be used in dav url.
    
    This can very well be different frome the login user that's
    stored in credentials ().user ().
    ***********************************************************/
    string dav_user ();
    void set_dav_user (string &new_dav_user);

    string dav_display_name ();
    void set_dav_display_name (string &new_display_name);

#ifndef TOKEN_AUTH_ONLY
    QImage avatar ();
    void set_avatar (QImage &img);
#endif

    /// The name of the account as shown in the toolbar
    string display_name ();

    /// The internal id of the account.
    string id ();

    /***********************************************************
    Server url of the account */
    void set_url (QUrl &url);
    QUrl url () { return _url; }

    /// Adjusts _user_visible_url once the host to use is discovered.
    void set_user_visible_host (string &host);

    /***********************************************************
    @brief The possibly themed dav path for the account. It has
           a trailing slash.
    @returns the (themeable) dav path for the account.
    ***********************************************************/
    string dav_path ();

    /***********************************************************
    Returns webdav entry URL, based on url () */
    QUrl dav_url ();

    /***********************************************************
    Returns the legacy permalink url for a file.

    This uses the old way of manually building the url. New code should
    use the "privatelink" property accessible via PROPFIND.
    ***********************************************************/
    QUrl deprecated_private_link_url (QByteArray &numeric_file_id) const;

    /***********************************************************
    Holds the accounts credentials */
    AbstractCredentials *credentials ();
    void set_credentials (AbstractCredentials *cred);

    /***********************************************************
    Create a network request on the account's QNAM.

    Network requests in Abstract_network_jobs are created through
    this function. Other places should prefer to use jobs or
    send_request ().
    ***********************************************************/
    QNetworkReply *send_raw_request (QByteArray &verb,
        const QUrl &url,
        QNetworkRequest req = QNetworkRequest (),
        QIODevice *data = nullptr);

    QNetworkReply *send_raw_request (QByteArray &verb,
        const QUrl &url, QNetworkRequest req, QByteArray &data);

    QNetworkReply *send_raw_request (QByteArray &verb,
        const QUrl &url, QNetworkRequest req, QHttp_multi_part *data);

    /***********************************************************
    Create and start network job for a simple one-off request.

    More complicated requests typically create their own job types.
    ***********************************************************/
    SimpleNetworkJob *send_request (QByteArray &verb,
        const QUrl &url,
        QNetworkRequest req = QNetworkRequest (),
        QIODevice *data = nullptr);

    /***********************************************************
    The ssl configuration during the first connection */
    QSslConfiguration get_or_create_ssl_config ();
    QSslConfiguration ssl_configuration () { return _ssl_configuration; }
    void set_ssl_configuration (QSslConfiguration &config);
    // Because of bugs in Qt, we use this to store info needed for the SSL Button
    QSsl_cipher _session_cipher;
    QByteArray _session_ticket;
    QList<QSslCertificate> _peer_certificate_chain;

    /***********************************************************
    The certificates of the account */
    QList<QSslCertificate> approved_certs () { return _approved_certs; }
    void set_approved_certs (QList<QSslCertificate> certs);
    void add_approved_certs (QList<QSslCertificate> certs);

    // Usually when a user explicitly rejects a certificate we don't
    // ask again. After this call, a dialog will again be shown when
    // the next unknown certificate is encountered.
    void reset_rejected_certificates ();

    // pluggable handler
    void set_ssl_error_handler (Abstract_sslErrorHandler *handler);

    // To be called by credentials only, for storing username and the like
    QVariant credential_setting (string &key) const;
    void set_credential_setting (string &key, QVariant &value);

    /***********************************************************
    Assign a client certificate */
    void set_certificate (QByteArray certficate = QByteArray (), string private_key = string ());

    /***********************************************************
    Access the server capabilities */
    const Capabilities &capabilities ();
    void set_capabilities (QVariantMap &caps);

    /***********************************************************
    Access the server version

    For servers >= 10.0.0, this can be the empty string until capabilities
    have been received.
    ***********************************************************/
    string server_version ();

    /***********************************************************
    Server version for easy comparison.

    Example : server_version_int () >= make_server_version (11, 2, 3)
    
    Will be 0 if the version is not available yet.
    ***********************************************************/
    int server_version_int ();

    static int make_server_version (int major_version, int minor_version, int patch_version);
    void set_server_version (string &version);

    /***********************************************************
    Whether the server is too old.

    Not supporting server versions is a gradual process. There's a hard
    compatibility limit (see ConnectionValidator) that forbids connecting
    to extremely old servers. And there's a weak "untested, not
    recommended, potentially dangerous" limit, that users might want
    to go beyond.
    
    This function returns true if the server is beyond the weak limit.
    ***********************************************************/
    bool server_version_unsupported ();

    bool is_username_prefill_supported ();

    /***********************************************************
    True when the server connection is using HTTP2  */
    bool is_http2Supported () { return _http2Supported; }
    void set_http2Supported (bool value) { _http2Supported = value; }

    void clear_cookie_jar ();
    void lend_cookie_jar_to (QNetworkAccessManager *guest);
    string cookie_jar_path ();

    void reset_network_access_manager ();
    QNetworkAccessManager *network_access_manager ();
    QSharedPointer<QNetworkAccessManager> shared_network_access_manager ();

    /// Called by network jobs on credential errors, emits invalid_credentials ()
    void handle_invalid_credentials ();

    ClientSideEncryption* e2e ();

    /// Used in RemoteWipe
    void retrieve_app_password ();
    void write_app_password_once (string app_password);
    void delete_app_password ();

    void delete_app_token ();

    /// Direct Editing
    // Check for the direct_editing capability
    void fetch_direct_editors (QUrl &direct_editing_uRL, string &direct_editing_e_tag);

    void setup_user_status_connector ();
    void try_setup_push_notifications ();
    Push_notifications *push_notifications ();
    void set_push_notifications_reconnect_interval (int interval);

    std.shared_ptr<User_status_connector> user_status_connector ();

public slots:
    /// Used when forgetting credentials
    void clear_qNAMCache ();
    void slot_handle_ssl_errors (QNetworkReply *, QList<QSslError>);

signals:
    /// Emitted whenever there's network activity
    void propagator_network_activity ();

    /// Triggered by handle_invalid_credentials ()
    void invalid_credentials ();

    void credentials_fetched (AbstractCredentials *credentials);
    void credentials_asked (AbstractCredentials *credentials);

    /// Forwards from QNetworkAccessManager.proxy_authentication_required ().
    void proxy_authentication_required (QNetworkProxy &, QAuthenticator *);

    // e.g. when the approved SSL certificates changed
    void wants_account_saved (Account *acc);

    void server_version_changed (Account *account, string &new_version, string &old_version);

    void account_changed_avatar ();
    void account_changed_display_name ();

    /// Used in RemoteWipe
    void app_password_retrieved (string);

    void push_notifications_ready (Account *account);
    void push_notifications_disabled (Account *account);

    void user_status_changed ();

protected slots:
    void slot_credentials_fetched ();
    void slot_credentials_asked ();
    void slot_direct_editing_recieved (QJsonDocument &json);

private:
    Account (GLib.Object *parent = nullptr);
    void set_shared_this (AccountPtr shared_this);

    static string dav_path_base ();

    QWeak_pointer<Account> _shared_this;
    string _id;
    string _dav_user;
    string _display_name;
    QTimer _push_notifications_reconnect_timer;
#ifndef TOKEN_AUTH_ONLY
    QImage _avatar_img;
#endif
    QMap<string, QVariant> _settings_map;
    QUrl _url;

    /***********************************************************
    If url to use for any user-visible urls.

    If the server configures overwritehost this can be different from
    the connection url in _url. We retrieve the visible host through
    the ocs/v1.php/config endpoint in ConnectionValidator.
    ***********************************************************/
    QUrl _user_visible_url;

    QList<QSslCertificate> _approved_certs;
    QSslConfiguration _ssl_configuration;
    Capabilities _capabilities;
    string _server_version;
    QScopedPointer<Abstract_sslErrorHandler> _ssl_error_handler;
    QSharedPointer<QNetworkAccessManager> _am;
    QScopedPointer<AbstractCredentials> _credentials;
    bool _http2Supported = false;

    /// Certificates that were explicitly rejected by the user
    QList<QSslCertificate> _rejected_certificates;

    static string _config_file_name;

    ClientSideEncryption _e2e;

    /// Used in RemoteWipe
    bool _wrote_app_password = false;

    friend class AccountManager;

    // Direct Editing
    string _last_direct_editing_e_tag;

    Push_notifications *_push_notifications = nullptr;

    std.shared_ptr<User_status_connector> _user_status_connector;

    /* IMPORTANT - remove later - FIXME MS@2019-12-07 -.
    TODO : For "Log out" & "Remove account" : Remove client CA certs and KEY!
    
          Disabled as long as selecting another cert is not supported by the UI.
    
          Being able to specify a new certificate is important anyway : expiry etc.
    
     *       We introduce this dirty hack here, to allow deleting them upon Remote Wipe.
    ***********************************************************/
    public:
        void set_remote_wipe_requested_HACK () { _is_remote_wipe_requested_HACK = true; }
        bool is_remote_wipe_requested_HACK () { return _is_remote_wipe_requested_HACK; }
    private:
        bool _is_remote_wipe_requested_HACK = false;
    // <-- FIXME MS@2019-12-07
};

Account.Account (GLib.Object *parent)
    : GLib.Object (parent)
    , _capabilities (QVariantMap ()) {
    q_register_meta_type<AccountPtr> ("AccountPtr");
    q_register_meta_type<Account> ("Account*");

    _push_notifications_reconnect_timer.set_interval (push_notifications_reconnect_interval);
    connect (&_push_notifications_reconnect_timer, &QTimer.timeout, this, &Account.try_setup_push_notifications);
}

AccountPtr Account.create () {
    AccountPtr acc = AccountPtr (new Account);
    acc.set_shared_this (acc);
    return acc;
}

ClientSideEncryption* Account.e2e () {
    // Qt expects everything in the connect to be a pointer, so return a pointer.
    return &_e2e;
}

Account.~Account () = default;

string Account.dav_path () {
    return dav_path_base () + QLatin1Char ('/') + dav_user () + QLatin1Char ('/');
}

void Account.set_shared_this (AccountPtr shared_this) {
    _shared_this = shared_this.to_weak_ref ();
    setup_user_status_connector ();
}

string Account.dav_path_base () {
    return QStringLiteral ("/remote.php/dav/files");
}

AccountPtr Account.shared_from_this () {
    return _shared_this.to_strong_ref ();
}

string Account.dav_user () {
    return _dav_user.is_empty () && _credentials ? _credentials.user () : _dav_user;
}

void Account.set_dav_user (string &new_dav_user) {
    if (_dav_user == new_dav_user)
        return;
    _dav_user = new_dav_user;
    emit wants_account_saved (this);
}

#ifndef TOKEN_AUTH_ONLY
QImage Account.avatar () {
    return _avatar_img;
}
void Account.set_avatar (QImage &img) {
    _avatar_img = img;
    emit account_changed_avatar ();
}
#endif

string Account.display_name () {
    string dn = string ("%1@%2").arg (credentials ().user (), _url.host ());
    int port = url ().port ();
    if (port > 0 && port != 80 && port != 443) {
        dn.append (QLatin1Char (':'));
        dn.append (string.number (port));
    }
    return dn;
}

string Account.dav_display_name () {
    return _display_name;
}

void Account.set_dav_display_name (string &new_display_name) {
    _display_name = new_display_name;
    emit account_changed_display_name ();
}

string Account.id () {
    return _id;
}

AbstractCredentials *Account.credentials () {
    return _credentials.data ();
}

void Account.set_credentials (AbstractCredentials *cred) {
    // set active credential manager
    QNetwork_cookie_jar *jar = nullptr;
    QNetworkProxy proxy;

    if (_am) {
        jar = _am.cookie_jar ();
        jar.set_parent (nullptr);

        // Remember proxy (issue #2108)
        proxy = _am.proxy ();

        _am = QSharedPointer<QNetworkAccessManager> ();
    }

    // The order for these two is important! Reading the credential's
    // settings accesses the account as well as account._credentials,
    _credentials.reset (cred);
    cred.set_account (this);

    // Note : This way the QNAM can outlive the Account and Credentials.
    // This is necessary to avoid issues with the QNAM being deleted while
    // processing slot_handle_ssl_errors ().
    _am = QSharedPointer<QNetworkAccessManager> (_credentials.create_qNAM (), &GLib.Object.delete_later);

    if (jar) {
        _am.set_cookie_jar (jar);
    }
    if (proxy.type () != QNetworkProxy.DefaultProxy) {
        _am.set_proxy (proxy);
    }
    connect (_am.data (), SIGNAL (ssl_errors (QNetworkReply *, QList<QSslError>)),
        SLOT (slot_handle_ssl_errors (QNetworkReply *, QList<QSslError>)));
    connect (_am.data (), &QNetworkAccessManager.proxy_authentication_required,
        this, &Account.proxy_authentication_required);
    connect (_credentials.data (), &AbstractCredentials.fetched,
        this, &Account.slot_credentials_fetched);
    connect (_credentials.data (), &AbstractCredentials.asked,
        this, &Account.slot_credentials_asked);

    try_setup_push_notifications ();
}

void Account.set_push_notifications_reconnect_interval (int interval) {
    _push_notifications_reconnect_timer.set_interval (interval);
}

void Account.try_setup_push_notifications () {
    // Stop the timer to prevent parallel setup attempts
    _push_notifications_reconnect_timer.stop ();

    if (_capabilities.available_push_notifications () != PushNotificationType.None) {
        q_c_info (lc_account) << "Try to setup push notifications";

        if (!_push_notifications) {
            _push_notifications = new Push_notifications (this, this);

            connect (_push_notifications, &Push_notifications.ready, this, [this] () {
                _push_notifications_reconnect_timer.stop ();
                emit push_notifications_ready (this);
            });

            const auto disable_push_notifications = [this] () {
                q_c_info (lc_account) << "Disable push notifications object because authentication failed or connection lost";
                if (!_push_notifications) {
                    return;
                }
                if (!_push_notifications.is_ready ()) {
                    emit push_notifications_disabled (this);
                }
                if (!_push_notifications_reconnect_timer.is_active ()) {
                    _push_notifications_reconnect_timer.start ();
                }
            };

            connect (_push_notifications, &Push_notifications.connection_lost, this, disable_push_notifications);
            connect (_push_notifications, &Push_notifications.authentication_failed, this, disable_push_notifications);
        }
        // If push notifications already running it is no problem to call setup again
        _push_notifications.setup ();
    }
}

QUrl Account.dav_url () {
    return Utility.concat_url_path (url (), dav_path ());
}

QUrl Account.deprecated_private_link_url (QByteArray &numeric_file_id) {
    return Utility.concat_url_path (_user_visible_url,
        QLatin1String ("/index.php/f/") + QUrl.to_percent_encoding (string.from_latin1 (numeric_file_id)));
}

/***********************************************************
clear all cookies. (Session cookies or not)
***********************************************************/
void Account.clear_cookie_jar () {
    auto jar = qobject_cast<CookieJar> (_am.cookie_jar ());
    ASSERT (jar);
    jar.set_all_cookies (QList<QNetwork_cookie> ());
    emit wants_account_saved (this);
}

/*********************************************************** This shares our official cookie jar (containing all the tasty
    authentication cookies) with another QNAM while making sure
    of not losing its ownership. */
void Account.lend_cookie_jar_to (QNetworkAccessManager *guest) {
    auto jar = _am.cookie_jar ();
    auto old_parent = jar.parent ();
    guest.set_cookie_jar (jar); // takes ownership of our precious cookie jar
    jar.set_parent (old_parent); // takes it back
}

string Account.cookie_jar_path () {
    return QStandardPaths.writable_location (QStandardPaths.App_config_location) + "/cookies" + id () + ".db";
}

void Account.reset_network_access_manager () {
    if (!_credentials || !_am) {
        return;
    }

    q_c_debug (lc_account) << "Resetting QNAM";
    QNetwork_cookie_jar *jar = _am.cookie_jar ();
    QNetworkProxy proxy = _am.proxy ();

    // Use a QSharedPointer to allow locking the life of the QNAM on the stack.
    // Make it call delete_later to make sure that we can return to any QNAM stack frames safely.
    _am = QSharedPointer<QNetworkAccessManager> (_credentials.create_qNAM (), &GLib.Object.delete_later);

    _am.set_cookie_jar (jar); // takes ownership of the old cookie jar
    _am.set_proxy (proxy);   // Remember proxy (issue #2108)

    connect (_am.data (), SIGNAL (ssl_errors (QNetworkReply *, QList<QSslError>)),
        SLOT (slot_handle_ssl_errors (QNetworkReply *, QList<QSslError>)));
    connect (_am.data (), &QNetworkAccessManager.proxy_authentication_required,
        this, &Account.proxy_authentication_required);
}

QNetworkAccessManager *Account.network_access_manager () {
    return _am.data ();
}

QSharedPointer<QNetworkAccessManager> Account.shared_network_access_manager () {
    return _am;
}

QNetworkReply *Account.send_raw_request (QByteArray &verb, QUrl &url, QNetworkRequest req, QIODevice *data) {
    req.set_url (url);
    req.set_ssl_configuration (this.get_or_create_ssl_config ());
    if (verb == "HEAD" && !data) {
        return _am.head (req);
    } else if (verb == "GET" && !data) {
        return _am.get (req);
    } else if (verb == "POST") {
        return _am.post (req, data);
    } else if (verb == "PUT") {
        return _am.put (req, data);
    } else if (verb == "DELETE" && !data) {
        return _am.delete_resource (req);
    }
    return _am.send_custom_request (req, verb, data);
}

QNetworkReply *Account.send_raw_request (QByteArray &verb, QUrl &url, QNetworkRequest req, QByteArray &data) {
    req.set_url (url);
    req.set_ssl_configuration (this.get_or_create_ssl_config ());
    if (verb == "HEAD" && data.is_empty ()) {
        return _am.head (req);
    } else if (verb == "GET" && data.is_empty ()) {
        return _am.get (req);
    } else if (verb == "POST") {
        return _am.post (req, data);
    } else if (verb == "PUT") {
        return _am.put (req, data);
    } else if (verb == "DELETE" && data.is_empty ()) {
        return _am.delete_resource (req);
    }
    return _am.send_custom_request (req, verb, data);
}

QNetworkReply *Account.send_raw_request (QByteArray &verb, QUrl &url, QNetworkRequest req, QHttp_multi_part *data) {
    req.set_url (url);
    req.set_ssl_configuration (this.get_or_create_ssl_config ());
    if (verb == "PUT") {
        return _am.put (req, data);
    } else if (verb == "POST") {
        return _am.post (req, data);
    }
    return _am.send_custom_request (req, verb, data);
}

SimpleNetworkJob *Account.send_request (QByteArray &verb, QUrl &url, QNetworkRequest req, QIODevice *data) {
    auto job = new SimpleNetworkJob (shared_from_this ());
    job.start_request (verb, url, req, data);
    return job;
}

void Account.set_ssl_configuration (QSslConfiguration &config) {
    _ssl_configuration = config;
}

QSslConfiguration Account.get_or_create_ssl_config () {
    if (!_ssl_configuration.is_null ()) {
        // Will be set by CheckServerJob.finished ()
        // We need to use a central shared config to get SSL session tickets
        return _ssl_configuration;
    }

    // if setting the client certificate fails, you will probably get an error similar to this:
    //  "An internal error number 1060 happened. SSL handshake failed, client certificate was requested : SSL error : sslv3 alert handshake failure"
    QSslConfiguration ssl_config = QSslConfiguration.default_configuration ();

    // Try hard to re-use session for different requests
    ssl_config.set_ssl_option (QSsl.Ssl_option_disable_session_tickets, false);
    ssl_config.set_ssl_option (QSsl.Ssl_option_disable_session_sharing, false);
    ssl_config.set_ssl_option (QSsl.Ssl_option_disable_session_persistence, false);

    ssl_config.set_ocsp_stapling_enabled (Theme.instance ().enable_stapling_oCSP ());

    return ssl_config;
}

void Account.set_approved_certs (QList<QSslCertificate> certs) {
    _approved_certs = certs;
    QSslConfiguration.default_configuration ().add_ca_certificates (certs);
}

void Account.add_approved_certs (QList<QSslCertificate> certs) {
    _approved_certs += certs;
}

void Account.reset_rejected_certificates () {
    _rejected_certificates.clear ();
}

void Account.set_ssl_error_handler (Abstract_sslErrorHandler *handler) {
    _ssl_error_handler.reset (handler);
}

void Account.set_url (QUrl &url) {
    _url = url;
    _user_visible_url = url;
}

void Account.set_user_visible_host (string &host) {
    _user_visible_url.set_host (host);
}

QVariant Account.credential_setting (string &key) {
    if (_credentials) {
        string prefix = _credentials.auth_type ();
        QVariant value = _settings_map.value (prefix + "_" + key);
        if (value.is_null ()) {
            value = _settings_map.value (key);
        }
        return value;
    }
    return QVariant ();
}

void Account.set_credential_setting (string &key, QVariant &value) {
    if (_credentials) {
        string prefix = _credentials.auth_type ();
        _settings_map.insert (prefix + "_" + key, value);
    }
}

void Account.slot_handle_ssl_errors (QNetworkReply *reply, QList<QSslError> errors) {
    Network_job_timeout_pauser pauser (reply);
    string out;
    QDebug (&out) << "SSL-Errors happened for url " << reply.url ().to_string ();
    foreach (QSslError &error, errors) {
        QDebug (&out) << "\t_error in " << error.certificate () << ":"
                     << error.error_string () << " (" << error.error () << ")"
                     << "\n";
    }

    q_c_info (lc_account ()) << "ssl errors" << out;
    q_c_info (lc_account ()) << reply.ssl_configuration ().peer_certificate_chain ();

    bool all_previously_rejected = true;
    foreach (QSslError &error, errors) {
        if (!_rejected_certificates.contains (error.certificate ())) {
            all_previously_rejected = false;
        }
    }

    // If all certs have previously been rejected by the user, don't ask again.
    if (all_previously_rejected) {
        q_c_info (lc_account) << out << "Certs not trusted by user decision, returning.";
        return;
    }

    QList<QSslCertificate> approved_certs;
    if (_ssl_error_handler.is_null ()) {
        q_c_warning (lc_account) << out << "called without valid SSL error handler for account" << url ();
        return;
    }

    // SslDialogErrorHandler.handle_errors will run an event loop that might execute
    // the delete_later () of the QNAM before we have the chance of unwinding our stack.
    // Keep a ref here on our stackframe to make sure that it doesn't get deleted before
    // handle_errors returns.
    QSharedPointer<QNetworkAccessManager> qnam_lock = _am;
    QPointer<GLib.Object> guard = reply;

    if (_ssl_error_handler.handle_errors (errors, reply.ssl_configuration (), &approved_certs, shared_from_this ())) {
        if (!guard)
            return;

        if (!approved_certs.is_empty ()) {
            QSslConfiguration.default_configuration ().add_ca_certificates (approved_certs);
            add_approved_certs (approved_certs);
            emit wants_account_saved (this);

            // all ssl certs are known and accepted. We can ignore the problems right away.
            q_c_info (lc_account) << out << "Certs are known and trusted! This is not an actual error.";
        }

        // Warning : Do *not* use ignore_ssl_errors () (without args) here:
        // it permanently ignores all SSL errors for this host, even
        // certificate changes.
        reply.ignore_ssl_errors (errors);
    } else {
        if (!guard)
            return;

        // Mark all involved certificates as rejected, so we don't ask the user again.
        foreach (QSslError &error, errors) {
            if (!_rejected_certificates.contains (error.certificate ())) {
                _rejected_certificates.append (error.certificate ());
            }
        }

        // Not calling ignore_ssl_errors will make the SSL handshake fail.
        return;
    }
}

void Account.slot_credentials_fetched () {
    if (_dav_user.is_empty ()) {
        q_c_debug (lc_account) << "User id not set. Fetch it.";
        const auto fetch_user_name_job = new JsonApiJob (shared_from_this (), QStringLiteral ("/ocs/v1.php/cloud/user"));
        connect (fetch_user_name_job, &JsonApiJob.json_received, this, [this, fetch_user_name_job] (QJsonDocument &json, int status_code) {
            fetch_user_name_job.delete_later ();
            if (status_code != 100) {
                q_c_warning (lc_account) << "Could not fetch user id. Login will probably not work.";
                emit credentials_fetched (_credentials.data ());
                return;
            }

            const auto obj_data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
            const auto user_id = obj_data.value ("id").to_string ("");
            set_dav_user (user_id);
            emit credentials_fetched (_credentials.data ());
        });
        fetch_user_name_job.start ();
    } else {
        q_c_debug (lc_account) << "User id already fetched.";
        emit credentials_fetched (_credentials.data ());
    }
}

void Account.slot_credentials_asked () {
    emit credentials_asked (_credentials.data ());
}

void Account.handle_invalid_credentials () {
    // Retrieving password will trigger remote wipe check job
    retrieve_app_password ();

    emit invalid_credentials ();
}

void Account.clear_qNAMCache () {
    _am.clear_access_cache ();
}

const Capabilities &Account.capabilities () {
    return _capabilities;
}

void Account.set_capabilities (QVariantMap &caps) {
    _capabilities = Capabilities (caps);

    setup_user_status_connector ();
    try_setup_push_notifications ();
}

void Account.setup_user_status_connector () {
    _user_status_connector = std.make_shared<Ocs_user_status_connector> (shared_from_this ());
    connect (_user_status_connector.get (), &User_status_connector.user_status_fetched, this, [this] (User_status &) {
        emit user_status_changed ();
    });
    connect (_user_status_connector.get (), &User_status_connector.message_cleared, this, [this] {
        emit user_status_changed ();
    });
}

string Account.server_version () {
    return _server_version;
}

int Account.server_version_int () {
    // FIXME : Use Qt 5.5 QVersion_number
    auto components = server_version ().split ('.');
    return make_server_version (components.value (0).to_int (),
        components.value (1).to_int (),
        components.value (2).to_int ());
}

int Account.make_server_version (int major_version, int minor_version, int patch_version) {
    return (major_version << 16) + (minor_version << 8) + patch_version;
}

bool Account.server_version_unsupported () {
    if (server_version_int () == 0) {
        // not detected yet, assume it is fine.
        return false;
    }
    return server_version_int () < make_server_version (NEXTCLOUD_SERVER_VERSION_MIN_SUPPORTED_MAJOR,
               NEXTCLOUD_SERVER_VERSION_MIN_SUPPORTED_MINOR, NEXTCLOUD_SERVER_VERSION_MIN_SUPPORTED_PATCH);
}

bool Account.is_username_prefill_supported () {
    return server_version_int () >= make_server_version (username_prefill_server_versin_min_supported_major, 0, 0);
}

void Account.set_server_version (string &version) {
    if (version == _server_version) {
        return;
    }

    auto old_server_version = _server_version;
    _server_version = version;
    emit server_version_changed (this, old_server_version, version);
}

void Account.write_app_password_once (string app_password){
    if (_wrote_app_password)
        return;

    // Fix : Password got written from Account Wizard, before finish.
    // Only write the app password for a connected account, else
    // there'll be a zombie keychain slot forever, never used again ;p
    //
    // Also don't write empty passwords (Log out . Relaunch)
    if (id ().is_empty () || app_password.is_empty ())
        return;

    const string kck = AbstractCredentials.keychain_key (
                url ().to_string (),
                dav_user () + app_password,
                id ()
    );

    auto *job = new WritePasswordJob (Theme.instance ().app_name ());
    job.set_insecure_fallback (false);
    job.set_key (kck);
    job.set_binary_data (app_password.to_latin1 ());
    connect (job, &WritePasswordJob.finished, [this] (Job *incoming) {
        auto *write_job = static_cast<WritePasswordJob> (incoming);
        if (write_job.error () == NoError)
            q_c_info (lc_account) << "app_password stored in keychain";
        else
            q_c_warning (lc_account) << "Unable to store app_password in keychain" << write_job.error_string ();

        // We don't try this again on error, to not raise CPU consumption
        _wrote_app_password = true;
    });
    job.start ();
}

void Account.retrieve_app_password (){
    const string kck = AbstractCredentials.keychain_key (
                url ().to_string (),
                credentials ().user () + app_password,
                id ()
    );

    auto *job = new ReadPasswordJob (Theme.instance ().app_name ());
    job.set_insecure_fallback (false);
    job.set_key (kck);
    connect (job, &ReadPasswordJob.finished, [this] (Job *incoming) {
        auto *read_job = static_cast<ReadPasswordJob> (incoming);
        string pwd ("");
        // Error or no valid public key error out
        if (read_job.error () == NoError &&
                read_job.binary_data ().length () > 0) {
            pwd = read_job.binary_data ();
        }

        emit app_password_retrieved (pwd);
    });
    job.start ();
}

void Account.delete_app_password () {
    const string kck = AbstractCredentials.keychain_key (
                url ().to_string (),
                credentials ().user () + app_password,
                id ()
    );

    if (kck.is_empty ()) {
        q_c_debug (lc_account) << "app_password is empty";
        return;
    }

    auto *job = new DeletePasswordJob (Theme.instance ().app_name ());
    job.set_insecure_fallback (false);
    job.set_key (kck);
    connect (job, &DeletePasswordJob.finished, [this] (Job *incoming) {
        auto *delete_job = static_cast<DeletePasswordJob> (incoming);
        if (delete_job.error () == NoError)
            q_c_info (lc_account) << "app_password deleted from keychain";
        else
            q_c_warning (lc_account) << "Unable to delete app_password from keychain" << delete_job.error_string ();

        // Allow storing a new app password on re-login
        _wrote_app_password = false;
    });
    job.start ();
}

void Account.delete_app_token () {
    const auto delete_app_token_job = new DeleteJob (shared_from_this (), QStringLiteral ("/ocs/v2.php/core/apppassword"));
    connect (delete_app_token_job, &DeleteJob.finished_signal, this, [this] () {
        if (auto delete_job = qobject_cast<DeleteJob> (GLib.Object.sender ())) {
            const auto http_code = delete_job.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
            if (http_code != 200) {
                q_c_warning (lc_account) << "App_token remove failed for user : " << display_name () << " with code : " << http_code;
            } else {
                q_c_info (lc_account) << "App_token for user : " << display_name () << " has been removed.";
            }
        } else {
            Q_ASSERT (false);
            q_c_warning (lc_account) << "The sender is not a DeleteJob instance.";
        }
    });
    delete_app_token_job.start ();
}

void Account.fetch_direct_editors (QUrl &direct_editing_uRL, string &direct_editing_e_tag) {
    if (direct_editing_uRL.is_empty () || direct_editing_e_tag.is_empty ())
        return;

    // Check for the direct_editing capability
    if (!direct_editing_uRL.is_empty () &&
        (direct_editing_e_tag.is_empty () || direct_editing_e_tag != _last_direct_editing_e_tag)) {
            // Fetch the available editors and their mime types
            auto *job = new JsonApiJob (shared_from_this (), QLatin1String ("ocs/v2.php/apps/files/api/v1/direct_editing"));
            GLib.Object.connect (job, &JsonApiJob.json_received, this, &Account.slot_direct_editing_recieved);
            job.start ();
    }
}

void Account.slot_direct_editing_recieved (QJsonDocument &json) {
    auto data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
    auto editors = data.value ("editors").to_object ();

    foreach (auto editor_key, editors.keys ()) {
        auto editor = editors.value (editor_key).to_object ();

        const string id = editor.value ("id").to_string ();
        const string name = editor.value ("name").to_string ();

        if (!id.is_empty () && !name.is_empty ()) {
            auto mime_types = editor.value ("mimetypes").to_array ();
            auto optional_mime_types = editor.value ("optional_mimetypes").to_array ();

            auto *direct_editor = new Direct_editor (id, name);

            foreach (auto mime_type, mime_types) {
                direct_editor.add_mimetype (mime_type.to_string ().to_latin1 ());
            }

            foreach (auto optional_mime_type, optional_mime_types) {
                direct_editor.add_optional_mimetype (optional_mime_type.to_string ().to_latin1 ());
            }

            _capabilities.add_direct_editor (direct_editor);
        }
    }
}

Push_notifications *Account.push_notifications () {
    return _push_notifications;
}

std.shared_ptr<User_status_connector> Account.user_status_connector () {
    return _user_status_connector;
}

} // namespace Occ
