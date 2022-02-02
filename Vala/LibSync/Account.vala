/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <deletejob.h>

// #include <QLoggingCategory>
// #include <QNetworkReply>
// #include <QNetworkAccessManager>
// #include <QSslSocket>
// #include <QNetworkCookieJar>
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
// #include <QHttpMultiPart>

// #include <qsslconfiguration.h>
// #include <qt5keychain/keychain.h>

using namespace QKeychain;

// #include <GLib.Uri>
// #include <QNetworkCookie>
// #include <QNetworkRequest>
// #include <QSslSocket>
// #include <QSslCertificate>
// #include <QSslConfiguration>
// #include <QSslCipher>
// #include <QSslError>


#ifndef TOKEN_AUTH_ONLY
// #include <QPixmap>
#endif

const char app_password[] = "this.app-password";

// #include <memory>

class QNetworkAccessManager;

namespace QKeychain {
}


namespace {
    constexpr int push_notifications_reconnect_interval = 1000 * 60 * 2;
    constexpr int username_prefill_server_versin_min_supported_major = 24;
}

namespace Occ {

using AccountPointer = unowned<Account>;
class UserStatusConnector;

/***********************************************************
@brief Reimplement this to handle SSL errors from libsync
@ingroup libsync
***********************************************************/
class AbstractSslErrorHandler {
    public virtual ~AbstractSslErrorHandler () = default;
    public virtual bool handle_errors (GLib.List<QSslError>, QSslConfiguration conf, GLib.List<QSslCertificate> *, AccountPointer);
};

/***********************************************************
@brief The Account class represents an account on an
ownCloud Server
@ingroup libsync

The Account has a name and url. It also has information
about credentials, SSL errors and certificates.
***********************************************************/
class Account : GLib.Object {
    Q_PROPERTY (string id MEMBER this.id)
    Q_PROPERTY (string dav_user MEMBER this.dav_user)
    Q_PROPERTY (string display_name MEMBER this.display_name)
    Q_PROPERTY (GLib.Uri url MEMBER this.url)

    /***********************************************************
    ***********************************************************/
    public static AccountPointer create ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 
    public AccountPointer shared_from_this ();


    /***********************************************************
    The user that can be used in dav url.

    This can very well be different frome the login user that's
    stored in credentials ().user ().
    ***********************************************************/
    public string dav_user ();


    /***********************************************************
    ***********************************************************/
    public void set_dav_user (string new_dav_user);

    /***********************************************************
    ***********************************************************/
    public string dav_display_name ();

    /***********************************************************
    ***********************************************************/
    public 
    public void set_dav_display_name (string new_display_name);

#ifndef TOKEN_AUTH_ONLY
    public QImage avatar ();


    /***********************************************************
    ***********************************************************/
    public void set_avatar (QImage img);
#endif

    /// The name of the account as shown in the toolbar
    public string display_name ();

    /// The internal id of the account.
    public string id ();


    /***********************************************************
    Server url of the account
    ***********************************************************/
    public void set_url (GLib.Uri url);


    /***********************************************************
    ***********************************************************/
    public GLib.Uri url () {
        return this.url;
    }

    /// Adjusts this.user_visible_url once the host to use is discovered.
    public void set_user_visible_host (string host);


    /***********************************************************
    @brief The possibly themed dav path for the account. It has
           a trailing slash.
    @returns the (themeable) dav path for the account.
    ***********************************************************/
    public string dav_path ();


    /***********************************************************
    Returns webdav entry URL, based on url ()
    ***********************************************************/
    public GLib.Uri dav_url ();


    /***********************************************************
    Returns the legacy permalink url for a file.

    This uses the old way of manually building the url. New
    code should use the "privatelink" property accessible via
    PROPFIND.
    ***********************************************************/
    public GLib.Uri deprecated_private_link_url (GLib.ByteArray numeric_file_id);


    /***********************************************************
    Holds the accounts credentials
    ***********************************************************/
    public AbstractCredentials credentials ();


    /***********************************************************
    ***********************************************************/
    public void set_credentials (AbstractCredentials cred);


    /***********************************************************
    Create a network request on the account's QNAM.

    Network requests in AbstractNetworkJobs are created through
    this function. Other places should prefer to use jobs or
    send_request ().
    ***********************************************************/
    public QNetworkReply send_raw_request (GLib.ByteArray verb,
        const GLib.Uri url,
        QNetworkRequest req = QNetworkRequest (),
        QIODevice data = nullptr);

    /***********************************************************
    ***********************************************************/
    public QNetworkReply send_raw_request (GLib.ByteArray verb,

    /***********************************************************
    ***********************************************************/
    public 
    public QNetworkReply send_raw_request (GLib.ByteArray verb,
        const GLib.Uri url, QNetworkRequest req, QHttpMultiPart data);


    /***********************************************************
    Create and start network job for a simple one-off request.

    More complicated requests typically create their own job
    types.
    ***********************************************************/
    public SimpleNetworkJob send_request (GLib.ByteArray verb,
        const GLib.Uri url,
        QNetworkRequest req = QNetworkRequest (),
        QIODevice data = nullptr);


    /***********************************************************
    The ssl configuration during the first connection
    ***********************************************************/
    public QSslConfiguration get_or_create_ssl_config ();


    /***********************************************************
    ***********************************************************/
    public QSslConfiguration ssl_configuration () {
        return this.ssl_configuration;
    }


    /***********************************************************
    ***********************************************************/
    public void set_ssl_configuration (QSslConfiguration config);
    // Because of bugs in Qt, we use this to store info needed for the SSL Button
    public QSslCipher this.session_cipher;
    public GLib.ByteArray this.session_ticket;
    public GLib.List<QSslCertificate> this.peer_certificate_chain;


    /***********************************************************
    The certificates of the account
    ***********************************************************/
    public GLib.List<QSslCertificate> approved_certs () {
        return this.approved_certs;
    }


    /***********************************************************
    ***********************************************************/
    public void set_approved_certs (GLib.List<QSslCertificate> certs);

    /***********************************************************
    ***********************************************************/
    public 
    public void add_approved_certs (GLib.List<QSslCertificate> certs);

    // Usually when a user explicitly rejects a certificate we don't
    // ask again. After this call, a dialog will again be shown when
    // the next unknown certificate is encountered.
    public void reset_rejected_certificates ();

    // pluggable handler
    public void set_ssl_error_handler (AbstractSslErrorHandler handler);

    // To be called by credentials only, for storing username and the like
    public GLib.Variant credential_setting (string key);


    /***********************************************************
    ***********************************************************/
    public void set_credential_setting (string key, GLib.Variant value);


    /***********************************************************
    Assign a client certificate
    ***********************************************************/
    public void set_certificate (GLib.ByteArray certficate = GLib.ByteArray (), string private_key = "");


    /***********************************************************
    Access the server capabilities
    ***********************************************************/
    public const Capabilities capabilities ();


    /***********************************************************
    ***********************************************************/
    public void set_capabilities (QVariantMap caps);


    /***********************************************************
    Access the server version

    For servers >= 10.0.0, this can be the empty string until
    capabilities have been received.
    ***********************************************************/
    public string server_version ();


    /***********************************************************
    Server version for easy comparison.

    Example: server_version_int () >= make_server_version (11, 2, 3)

    Will be 0 if the version is not available yet.
    ***********************************************************/
    public int server_version_int ();

    /***********************************************************
    ***********************************************************/
    public static int make_server_version (int major_version, int minor_version, int patch_version);

    /***********************************************************
    ***********************************************************/
    public 
    public void set_server_version (string version);


    /***********************************************************
    Whether the server is too old.

    Not supporting server versions is a gradual process. There's
    a hard compatibility limit (see ConnectionValidator) that
    forbids connecting to extremely old servers. And there's a
    weak "untested, not recommended, potentially dangerous"
    limit, that users might want to go beyond.

    This function returns true if the server is beyond the weak
    limit.
    ***********************************************************/
    public bool server_version_unsupported ();

    /***********************************************************
    ***********************************************************/
    public bool is_username_prefill_supported ();


    /***********************************************************
    True when the server connection is using HTTP2
    ***********************************************************/
    public bool is_http2Supported () {
        return this.http2Supported;
    }


    /***********************************************************
    ***********************************************************/
    public void set_http2Supported (bool value) {
        this.http2Supported = value;
    }


    /***********************************************************
    ***********************************************************/
    public void clear_cookie_jar ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public string cookie_jar_path ();

    /***********************************************************
    ***********************************************************/
    public void reset_network_access_manager ();

    /***********************************************************
    ***********************************************************/
    public 
    public QNetworkAccessManager network_access_manager ();


    public unowned<QNetworkAccessManager> shared_network_access_manager ();

    /// Called by network jobs on credential errors, emits invalid_credentials ()
    public void handle_invalid_credentials ();

    ClientSideEncryption* e2e ();

    /// Used in RemoteWipe
    public void retrieve_app_password ();


    /***********************************************************
    ***********************************************************/
    public void write_app_password_once (string app_password);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 
    public void delete_app_token ();

    /// Direct Editing
    // Check for the direct_editing capability
    public void fetch_direct_editors (GLib.Uri direct_editing_uRL, string direct_editing_e_tag);

    /***********************************************************
    ***********************************************************/
    public void setup_user_status_connector ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public PushNotifications push_notifications ();

    /***********************************************************
    ***********************************************************/
    public 
    public void set_push_notifications_reconnect_interval (int interval);

    public std.shared_ptr<UserStatusConnector> user_status_connector ();


    /// Used when forgetting credentials
    public void on_clear_qnam_cache ();


    /***********************************************************
    ***********************************************************/
    public void on_handle_ssl_errors (QNetworkReply *, GLib.List<QSslError>);

signals:
    /// Emitted whenever there's network activity
    void propagator_network_activity ();

    /// Triggered by handle_invalid_credentials ()
    void invalid_credentials ();

    void credentials_fetched (AbstractCredentials credentials);
    void credentials_asked (AbstractCredentials credentials);

    /// Forwards from QNetworkAccessManager.proxy_authentication_required ().
    void proxy_authentication_required (QNetworkProxy &, QAuthenticator *);

    // e.g. when the approved SSL certificates changed
    void wants_account_saved (Account acc);

    void server_version_changed (Account account, string new_version, string old_version);

    void account_changed_avatar ();
    void account_changed_display_name ();

    /// Used in RemoteWipe
    void app_password_retrieved (string);

    void push_notifications_ready (Account account);
    void push_notifications_disabled (Account account);

    void user_status_changed ();

protected slots:
    void on_credentials_fetched ();
    void on_credentials_asked ();
    void on_direct_editing_recieved (QJsonDocument json);


    /***********************************************************
    ***********************************************************/
    private Account (GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 
    private QWeakPointer<Account> this.shared_this;
    private string this.id;
    private string this.dav_user;
    private string this.display_name;
    private QTimer this.push_notifications_reconnect_timer;
#ifndef TOKEN_AUTH_ONLY
    private QImage this.avatar_img;
#endif
    private QMap<string, GLib.Variant> this.settings_map;
    private GLib.Uri this.url;


    /***********************************************************
    If url to use for any user-visible urls.

    If the server configures overwritehost this can be different
    from the connection url in this.url. We retrieve the visible
    host through the ocs/v1.php/config endpoint in
    ConnectionValidator.
    ***********************************************************/
    private GLib.Uri this.user_visible_url;

    /***********************************************************
    ***********************************************************/
    private GLib.List<QSslCertificate> this.approved_certs;
    private QSslConfiguration this.ssl_configuration;
    private Capabilities this.capabilities;
    private string this.server_version;
    private QScopedPointer<AbstractSslErrorHandler> this.ssl_error_handler;
    private unowned<QNetworkAccessManager> this.am;
    private QScopedPointer<AbstractCredentials> this.credentials;
    private bool this.http2Supported = false;

    /// Certificates that were explicitly rejected by the user
    private GLib.List<QSslCertificate> this.rejected_certificates;

    /***********************************************************
    ***********************************************************/
    private static string this.config_filename;

    /***********************************************************
    ***********************************************************/
    private ClientSideEncryption this.e2e;

    /// Used in RemoteWipe
    private bool this.wrote_app_password = false;

    /***********************************************************
    ***********************************************************/
    private friend class AccountManager;

    // Direct Editing
    private string this.last_direct_editing_e_tag;

    /***********************************************************
    ***********************************************************/
    private PushNotifications this.push_notifications = nullptr;

    /***********************************************************
    ***********************************************************/
    private std.shared_ptr<UserStatusConnector> this.user_status_connector;


    /***********************************************************
    IMPORTANT - remove later - FIXME MS@2019-12-07 -.
    TODO: For "Log out" & "Remove account":
        Remove client CA certs and KEY!

    Disabled as long as selecting another cert is not supported
    by the UI.

    Being able to specify a new certificate is important anyway:
    expiry etc.

    We introduce this dirty hack here, to allow deleting them
    upon Remote Wipe.
    ***********************************************************/
    public void set_remote_wipe_requested_HACK () {
        this.is_remote_wipe_requested_HACK = true;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_remote_wipe_requested_HACK () {
        return this.is_remote_wipe_requested_HACK;
    }


    /***********************************************************
    ***********************************************************/
    private bool this.is_remote_wipe_requested_HACK = false;
    // <-- FIXME MS@2019-12-07
};

Account.Account (GLib.Object parent)
    : GLib.Object (parent)
    , this.capabilities (QVariantMap ()) {
    q_register_meta_type<AccountPointer> ("AccountPointer");
    q_register_meta_type<Account> ("Account*");

    this.push_notifications_reconnect_timer.set_interval (push_notifications_reconnect_interval);
    connect (&this.push_notifications_reconnect_timer, &QTimer.timeout, this, &Account.try_setup_push_notifications);
}

AccountPointer Account.create () {
    AccountPointer acc = AccountPointer (new Account);
    acc.set_shared_this (acc);
    return acc;
}

ClientSideEncryption* Account.e2e () {
    // Qt expects everything in the connect to be a pointer, so return a pointer.
    return this.e2e;
}

Account.~Account () = default;

string Account.dav_path () {
    return dav_path_base () + '/' + dav_user () + '/';
}

void Account.set_shared_this (AccountPointer shared_this) {
    this.shared_this = shared_this.to_weak_ref ();
    setup_user_status_connector ();
}

string Account.dav_path_base () {
    return QStringLiteral ("/remote.php/dav/files");
}

AccountPointer Account.shared_from_this () {
    return this.shared_this.to_strong_ref ();
}

string Account.dav_user () {
    return this.dav_user.is_empty () && this.credentials ? this.credentials.user () : this.dav_user;
}

void Account.set_dav_user (string new_dav_user) {
    if (this.dav_user == new_dav_user)
        return;
    this.dav_user = new_dav_user;
    /* emit */ wants_account_saved (this);
}

#ifndef TOKEN_AUTH_ONLY
QImage Account.avatar () {
    return this.avatar_img;
}
void Account.set_avatar (QImage img) {
    this.avatar_img = img;
    /* emit */ account_changed_avatar ();
}
#endif

string Account.display_name () {
    string dn = string ("%1@%2").arg (credentials ().user (), this.url.host ());
    int port = url ().port ();
    if (port > 0 && port != 80 && port != 443) {
        dn.append (':');
        dn.append (string.number (port));
    }
    return dn;
}

string Account.dav_display_name () {
    return this.display_name;
}

void Account.set_dav_display_name (string new_display_name) {
    this.display_name = new_display_name;
    /* emit */ account_changed_display_name ();
}

string Account.id () {
    return this.id;
}

AbstractCredentials *Account.credentials () {
    return this.credentials.data ();
}

void Account.set_credentials (AbstractCredentials cred) {
    // set active credential manager
    QNetworkCookieJar jar = nullptr;
    QNetworkProxy proxy;

    if (this.am) {
        jar = this.am.cookie_jar ();
        jar.set_parent (nullptr);

        // Remember proxy (issue #2108)
        proxy = this.am.proxy ();

        this.am = unowned<QNetworkAccessManager> ();
    }

    // The order for these two is important! Reading the credential's
    // settings accesses the account as well as account._credentials,
    this.credentials.on_reset (cred);
    cred.set_account (this);

    // Note: This way the QNAM can outlive the Account and Credentials.
    // This is necessary to avoid issues with the QNAM being deleted while
    // processing on_handle_ssl_errors ().
    this.am = unowned<QNetworkAccessManager> (this.credentials.create_qNAM (), &GLib.Object.delete_later);

    if (jar) {
        this.am.set_cookie_jar (jar);
    }
    if (proxy.type () != QNetworkProxy.DefaultProxy) {
        this.am.set_proxy (proxy);
    }
    connect (this.am.data (), SIGNAL (ssl_errors (QNetworkReply *, GLib.List<QSslError>)),
        SLOT (on_handle_ssl_errors (QNetworkReply *, GLib.List<QSslError>)));
    connect (this.am.data (), &QNetworkAccessManager.proxy_authentication_required,
        this, &Account.proxy_authentication_required);
    connect (this.credentials.data (), &AbstractCredentials.fetched,
        this, &Account.on_credentials_fetched);
    connect (this.credentials.data (), &AbstractCredentials.asked,
        this, &Account.on_credentials_asked);

    try_setup_push_notifications ();
}

void Account.set_push_notifications_reconnect_interval (int interval) {
    this.push_notifications_reconnect_timer.set_interval (interval);
}

void Account.try_setup_push_notifications () {
    // Stop the timer to prevent parallel setup attempts
    this.push_notifications_reconnect_timer.stop ();

    if (this.capabilities.available_push_notifications () != PushNotificationType.None) {
        q_c_info (lc_account) << "Try to setup push notifications";

        if (!this.push_notifications) {
            this.push_notifications = new PushNotifications (this, this);

            connect (this.push_notifications, &PushNotifications.ready, this, [this] () {
                this.push_notifications_reconnect_timer.stop ();
                /* emit */ push_notifications_ready (this);
            });

            const var disable_push_notifications = [this] () {
                q_c_info (lc_account) << "Disable push notifications object because authentication failed or connection lost";
                if (!this.push_notifications) {
                    return;
                }
                if (!this.push_notifications.is_ready ()) {
                    /* emit */ push_notifications_disabled (this);
                }
                if (!this.push_notifications_reconnect_timer.is_active ()) {
                    this.push_notifications_reconnect_timer.on_start ();
                }
            };

            connect (this.push_notifications, &PushNotifications.connection_lost, this, disable_push_notifications);
            connect (this.push_notifications, &PushNotifications.authentication_failed, this, disable_push_notifications);
        }
        // If push notifications already running it is no problem to call setup again
        this.push_notifications.setup ();
    }
}

GLib.Uri Account.dav_url () {
    return Utility.concat_url_path (url (), dav_path ());
}

GLib.Uri Account.deprecated_private_link_url (GLib.ByteArray numeric_file_id) {
    return Utility.concat_url_path (this.user_visible_url,
        QLatin1String ("/index.php/f/") + GLib.Uri.to_percent_encoding (string.from_latin1 (numeric_file_id)));
}

/***********************************************************
clear all cookies. (Session cookies or not)
***********************************************************/
void Account.clear_cookie_jar () {
    var jar = qobject_cast<CookieJar> (this.am.cookie_jar ());
    ASSERT (jar);
    jar.set_all_cookies (GLib.List<QNetworkCookie> ());
    /* emit */ wants_account_saved (this);
}

/***********************************************************
This shares our official cookie jar (containing all the tasty
authentication cookies) with another QNAM while making sure
of not losing its ownership.
***********************************************************/
void Account.lend_cookie_jar_to (QNetworkAccessManager guest) {
    var jar = this.am.cookie_jar ();
    var old_parent = jar.parent ();
    guest.set_cookie_jar (jar); // takes ownership of our precious cookie jar
    jar.set_parent (old_parent); // takes it back
}

string Account.cookie_jar_path () {
    return QStandardPaths.writable_location (QStandardPaths.AppConfigLocation) + "/cookies" + id () + ".db";
}

void Account.reset_network_access_manager () {
    if (!this.credentials || !this.am) {
        return;
    }

    GLib.debug (lc_account) << "Resetting QNAM";
    QNetworkCookieJar jar = this.am.cookie_jar ();
    QNetworkProxy proxy = this.am.proxy ();

    // Use a unowned to allow locking the life of the QNAM on the stack.
    // Make it call delete_later to make sure that we can return to any QNAM stack frames safely.
    this.am = unowned<QNetworkAccessManager> (this.credentials.create_qNAM (), &GLib.Object.delete_later);

    this.am.set_cookie_jar (jar); // takes ownership of the old cookie jar
    this.am.set_proxy (proxy);   // Remember proxy (issue #2108)

    connect (this.am.data (), SIGNAL (ssl_errors (QNetworkReply *, GLib.List<QSslError>)),
        SLOT (on_handle_ssl_errors (QNetworkReply *, GLib.List<QSslError>)));
    connect (this.am.data (), &QNetworkAccessManager.proxy_authentication_required,
        this, &Account.proxy_authentication_required);
}

QNetworkAccessManager *Account.network_access_manager () {
    return this.am.data ();
}

unowned<QNetworkAccessManager> Account.shared_network_access_manager () {
    return this.am;
}

QNetworkReply *Account.send_raw_request (GLib.ByteArray verb, GLib.Uri url, QNetworkRequest req, QIODevice data) {
    req.set_url (url);
    req.set_ssl_configuration (this.get_or_create_ssl_config ());
    if (verb == "HEAD" && !data) {
        return this.am.head (req);
    } else if (verb == "GET" && !data) {
        return this.am.get (req);
    } else if (verb == "POST") {
        return this.am.post (req, data);
    } else if (verb == "PUT") {
        return this.am.put (req, data);
    } else if (verb == "DELETE" && !data) {
        return this.am.delete_resource (req);
    }
    return this.am.send_custom_request (req, verb, data);
}

QNetworkReply *Account.send_raw_request (GLib.ByteArray verb, GLib.Uri url, QNetworkRequest req, GLib.ByteArray data) {
    req.set_url (url);
    req.set_ssl_configuration (this.get_or_create_ssl_config ());
    if (verb == "HEAD" && data.is_empty ()) {
        return this.am.head (req);
    } else if (verb == "GET" && data.is_empty ()) {
        return this.am.get (req);
    } else if (verb == "POST") {
        return this.am.post (req, data);
    } else if (verb == "PUT") {
        return this.am.put (req, data);
    } else if (verb == "DELETE" && data.is_empty ()) {
        return this.am.delete_resource (req);
    }
    return this.am.send_custom_request (req, verb, data);
}

QNetworkReply *Account.send_raw_request (GLib.ByteArray verb, GLib.Uri url, QNetworkRequest req, QHttpMultiPart data) {
    req.set_url (url);
    req.set_ssl_configuration (this.get_or_create_ssl_config ());
    if (verb == "PUT") {
        return this.am.put (req, data);
    } else if (verb == "POST") {
        return this.am.post (req, data);
    }
    return this.am.send_custom_request (req, verb, data);
}

SimpleNetworkJob *Account.send_request (GLib.ByteArray verb, GLib.Uri url, QNetworkRequest req, QIODevice data) {
    var job = new SimpleNetworkJob (shared_from_this ());
    job.start_request (verb, url, req, data);
    return job;
}

void Account.set_ssl_configuration (QSslConfiguration config) {
    this.ssl_configuration = config;
}

QSslConfiguration Account.get_or_create_ssl_config () {
    if (!this.ssl_configuration.is_null ()) {
        // Will be set by CheckServerJob.on_finished ()
        // We need to use a central shared config to get SSL session tickets
        return this.ssl_configuration;
    }

    // if setting the client certificate fails, you will probably get an error similar to this:
    //  "An internal error number 1060 happened. SSL handshake failed, client certificate was requested : SSL error : sslv3 alert handshake failure"
    QSslConfiguration ssl_config = QSslConfiguration.default_configuration ();

    // Try hard to re-use session for different requests
    ssl_config.set_ssl_option (QSsl.SslOptionDisableSessionTickets, false);
    ssl_config.set_ssl_option (QSsl.SslOptionDisableSessionSharing, false);
    ssl_config.set_ssl_option (QSsl.SslOptionDisableSessionPersistence, false);

    ssl_config.set_ocsp_stapling_enabled (Theme.instance ().enable_stapling_ocsp ());

    return ssl_config;
}

void Account.set_approved_certs (GLib.List<QSslCertificate> certs) {
    this.approved_certs = certs;
    QSslConfiguration.default_configuration ().add_ca_certificates (certs);
}

void Account.add_approved_certs (GLib.List<QSslCertificate> certs) {
    this.approved_certs += certs;
}

void Account.reset_rejected_certificates () {
    this.rejected_certificates.clear ();
}

void Account.set_ssl_error_handler (AbstractSslErrorHandler handler) {
    this.ssl_error_handler.on_reset (handler);
}

void Account.set_url (GLib.Uri url) {
    this.url = url;
    this.user_visible_url = url;
}

void Account.set_user_visible_host (string host) {
    this.user_visible_url.set_host (host);
}

GLib.Variant Account.credential_setting (string key) {
    if (this.credentials) {
        string prefix = this.credentials.auth_type ();
        GLib.Variant value = this.settings_map.value (prefix + "this." + key);
        if (value.is_null ()) {
            value = this.settings_map.value (key);
        }
        return value;
    }
    return GLib.Variant ();
}

void Account.set_credential_setting (string key, GLib.Variant value) {
    if (this.credentials) {
        string prefix = this.credentials.auth_type ();
        this.settings_map.insert (prefix + "this." + key, value);
    }
}

void Account.on_handle_ssl_errors (QNetworkReply reply, GLib.List<QSslError> errors) {
    NetworkJobTimeoutPauser pauser (reply);
    string out;
    QDebug (&out) << "SSL-Errors happened for url " << reply.url ().to_"";
    foreach (QSslError error, errors) {
        QDebug (&out) << "\t_error in " << error.certificate () << ":"
                     << error.error_string () << " (" << error.error () << ")"
                     << "\n";
    }

    q_c_info (lc_account ()) << "ssl errors" << out;
    q_c_info (lc_account ()) << reply.ssl_configuration ().peer_certificate_chain ();

    bool all_previously_rejected = true;
    foreach (QSslError error, errors) {
        if (!this.rejected_certificates.contains (error.certificate ())) {
            all_previously_rejected = false;
        }
    }

    // If all certs have previously been rejected by the user, don't ask again.
    if (all_previously_rejected) {
        q_c_info (lc_account) << out << "Certs not trusted by user decision, returning.";
        return;
    }

    GLib.List<QSslCertificate> approved_certs;
    if (this.ssl_error_handler.is_null ()) {
        GLib.warn (lc_account) << out << "called without valid SSL error handler for account" << url ();
        return;
    }

    // SslDialogErrorHandler.handle_errors will run an event loop that might execute
    // the delete_later () of the QNAM before we have the chance of unwinding our stack.
    // Keep a ref here on our stackframe to make sure that it doesn't get deleted before
    // handle_errors returns.
    unowned<QNetworkAccessManager> qnam_lock = this.am;
    QPointer<GLib.Object> guard = reply;

    if (this.ssl_error_handler.handle_errors (errors, reply.ssl_configuration (), approved_certs, shared_from_this ())) {
        if (!guard)
            return;

        if (!approved_certs.is_empty ()) {
            QSslConfiguration.default_configuration ().add_ca_certificates (approved_certs);
            add_approved_certs (approved_certs);
            /* emit */ wants_account_saved (this);

            // all ssl certs are known and accepted. We can ignore the problems right away.
            q_c_info (lc_account) << out << "Certs are known and trusted! This is not an actual error.";
        }

        // Warning : Do not* use ignore_ssl_errors () (without args) here:
        // it permanently ignores all SSL errors for this host, even
        // certificate changes.
        reply.ignore_ssl_errors (errors);
    } else {
        if (!guard)
            return;

        // Mark all involved certificates as rejected, so we don't ask the user again.
        foreach (QSslError error, errors) {
            if (!this.rejected_certificates.contains (error.certificate ())) {
                this.rejected_certificates.append (error.certificate ());
            }
        }

        // Not calling ignore_ssl_errors will make the SSL handshake fail.
        return;
    }
}

void Account.on_credentials_fetched () {
    if (this.dav_user.is_empty ()) {
        GLib.debug (lc_account) << "User id not set. Fetch it.";
        const var fetch_user_name_job = new JsonApiJob (shared_from_this (), QStringLiteral ("/ocs/v1.php/cloud/user"));
        connect (fetch_user_name_job, &JsonApiJob.json_received, this, [this, fetch_user_name_job] (QJsonDocument json, int status_code) {
            fetch_user_name_job.delete_later ();
            if (status_code != 100) {
                GLib.warn (lc_account) << "Could not fetch user id. Login will probably not work.";
                /* emit */ credentials_fetched (this.credentials.data ());
                return;
            }

            const var obj_data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
            const var user_id = obj_data.value ("id").to_string ("");
            set_dav_user (user_id);
            /* emit */ credentials_fetched (this.credentials.data ());
        });
        fetch_user_name_job.on_start ();
    } else {
        GLib.debug (lc_account) << "User id already fetched.";
        /* emit */ credentials_fetched (this.credentials.data ());
    }
}

void Account.on_credentials_asked () {
    /* emit */ credentials_asked (this.credentials.data ());
}

void Account.handle_invalid_credentials () {
    // Retrieving password will trigger remote wipe check job
    retrieve_app_password ();

    /* emit */ invalid_credentials ();
}

void Account.on_clear_qnam_cache () {
    this.am.clear_access_cache ();
}

const Capabilities &Account.capabilities () {
    return this.capabilities;
}

void Account.set_capabilities (QVariantMap caps) {
    this.capabilities = Capabilities (caps);

    setup_user_status_connector ();
    try_setup_push_notifications ();
}

void Account.setup_user_status_connector () {
    this.user_status_connector = std.make_shared<OcsUserStatusConnector> (shared_from_this ());
    connect (this.user_status_connector.get (), &UserStatusConnector.user_status_fetched, this, [this] (UserStatus &) {
        /* emit */ user_status_changed ();
    });
    connect (this.user_status_connector.get (), &UserStatusConnector.message_cleared, this, [this] {
        /* emit */ user_status_changed ();
    });
}

string Account.server_version () {
    return this.server_version;
}

int Account.server_version_int () {
    // FIXME : Use Qt 5.5 QVersionNumber
    var components = server_version ().split ('.');
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

void Account.set_server_version (string version) {
    if (version == this.server_version) {
        return;
    }

    var old_server_version = this.server_version;
    this.server_version = version;
    /* emit */ server_version_changed (this, old_server_version, version);
}

void Account.write_app_password_once (string app_password){
    if (this.wrote_app_password)
        return;

    // Fix : Password got written from Account Wizard, before finish.
    // Only write the app password for a connected account, else
    // there'll be a zombie keychain slot forever, never used again ;p
    //
    // Also don't write empty passwords (Log out . Relaunch)
    if (id ().is_empty () || app_password.is_empty ())
        return;

    const string kck = AbstractCredentials.keychain_key (
                url ().to_"",
                dav_user () + app_password,
                id ()
    );

    var job = new WritePasswordJob (Theme.instance ().app_name ());
    job.set_insecure_fallback (false);
    job.set_key (kck);
    job.set_binary_data (app_password.to_latin1 ());
    connect (job, &WritePasswordJob.on_finished, [this] (Job incoming) {
        var write_job = static_cast<WritePasswordJob> (incoming);
        if (write_job.error () == NoError)
            q_c_info (lc_account) << "app_password stored in keychain";
        else
            GLib.warn (lc_account) << "Unable to store app_password in keychain" << write_job.error_string ();

        // We don't try this again on error, to not raise CPU consumption
        this.wrote_app_password = true;
    });
    job.on_start ();
}

void Account.retrieve_app_password (){
    const string kck = AbstractCredentials.keychain_key (
                url ().to_"",
                credentials ().user () + app_password,
                id ()
    );

    var job = new ReadPasswordJob (Theme.instance ().app_name ());
    job.set_insecure_fallback (false);
    job.set_key (kck);
    connect (job, &ReadPasswordJob.on_finished, [this] (Job incoming) {
        var read_job = static_cast<ReadPasswordJob> (incoming);
        string pwd ("");
        // Error or no valid public key error out
        if (read_job.error () == NoError &&
                read_job.binary_data ().length () > 0) {
            pwd = read_job.binary_data ();
        }

        /* emit */ app_password_retrieved (pwd);
    });
    job.on_start ();
}

void Account.delete_app_password () {
    const string kck = AbstractCredentials.keychain_key (
                url ().to_"",
                credentials ().user () + app_password,
                id ()
    );

    if (kck.is_empty ()) {
        GLib.debug (lc_account) << "app_password is empty";
        return;
    }

    var job = new DeletePasswordJob (Theme.instance ().app_name ());
    job.set_insecure_fallback (false);
    job.set_key (kck);
    connect (job, &DeletePasswordJob.on_finished, [this] (Job incoming) {
        var delete_job = static_cast<DeletePasswordJob> (incoming);
        if (delete_job.error () == NoError)
            q_c_info (lc_account) << "app_password deleted from keychain";
        else
            GLib.warn (lc_account) << "Unable to delete app_password from keychain" << delete_job.error_string ();

        // Allow storing a new app password on re-login
        this.wrote_app_password = false;
    });
    job.on_start ();
}

void Account.delete_app_token () {
    const var delete_app_token_job = new DeleteJob (shared_from_this (), QStringLiteral ("/ocs/v2.php/core/apppassword"));
    connect (delete_app_token_job, &DeleteJob.finished_signal, this, [this] () {
        if (var delete_job = qobject_cast<DeleteJob> (GLib.Object.sender ())) {
            const var http_code = delete_job.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
            if (http_code != 200) {
                GLib.warn (lc_account) << "AppToken remove failed for user : " << display_name () << " with code : " << http_code;
            } else {
                q_c_info (lc_account) << "AppToken for user : " << display_name () << " has been removed.";
            }
        } else {
            Q_ASSERT (false);
            GLib.warn (lc_account) << "The sender is not a DeleteJob instance.";
        }
    });
    delete_app_token_job.on_start ();
}

void Account.fetch_direct_editors (GLib.Uri direct_editing_uRL, string direct_editing_e_tag) {
    if (direct_editing_uRL.is_empty () || direct_editing_e_tag.is_empty ())
        return;

    // Check for the direct_editing capability
    if (!direct_editing_uRL.is_empty () &&
        (direct_editing_e_tag.is_empty () || direct_editing_e_tag != this.last_direct_editing_e_tag)) {
            // Fetch the available editors and their mime types
            var job = new JsonApiJob (shared_from_this (), QLatin1String ("ocs/v2.php/apps/files/api/v1/direct_editing"));
            GLib.Object.connect (job, &JsonApiJob.json_received, this, &Account.on_direct_editing_recieved);
            job.on_start ();
    }
}

void Account.on_direct_editing_recieved (QJsonDocument json) {
    var data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
    var editors = data.value ("editors").to_object ();

    foreach (var editor_key, editors.keys ()) {
        var editor = editors.value (editor_key).to_object ();

        const string id = editor.value ("id").to_"";
        const string name = editor.value ("name").to_"";

        if (!id.is_empty () && !name.is_empty ()) {
            var mime_types = editor.value ("mimetypes").to_array ();
            var optional_mime_types = editor.value ("optional_mimetypes").to_array ();

            var direct_editor = new DirectEditor (id, name);

            foreach (var mime_type, mime_types) {
                direct_editor.add_mimetype (mime_type.to_"".to_latin1 ());
            }

            foreach (var optional_mime_type, optional_mime_types) {
                direct_editor.add_optional_mimetype (optional_mime_type.to_"".to_latin1 ());
            }

            this.capabilities.add_direct_editor (direct_editor);
        }
    }
}

PushNotifications *Account.push_notifications () {
    return this.push_notifications;
}

std.shared_ptr<UserStatusConnector> Account.user_status_connector () {
    return this.user_status_connector;
}

} // namespace Occ
