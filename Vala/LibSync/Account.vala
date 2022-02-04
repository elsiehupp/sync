/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <deletejob.h>
//  #include
//  #include <QLoggingCategory>
//  #include
//  #include <QNetworkAccessMana
//  #include <QSslSocket>
//  #include <QNetworkCo
//  #include <QNetw
//  #include
//  #include <QFileInfo>
//  #include <QDir>
//  #include <QSslKey>
//  #include <QAuthenticat
//  #include <QStandardPa
//  #include <QJsonDocument>
//  #include <QJsonObject>
//  #include <QJsonArray>
//  #include <QLoggingCategory>
//  #include <QHttpMultiPart>
//  #include
//  #include <qsslconfiguration.h>
//  #include <qt5keychain/keychain.h>

//  using namespace QKeychain;

//  #include <QNetworkCookie>
//  #include <Soup.Request>
//  #include <QSslSocket>
//  #include <QSslCertificate>
//  #include <QSslConfiguration>
//  #include <QSslCipher>
//  #include <QSslError>


//  #ifndef TOKEN_AUTH_ONLY
//  #include <QPixmap>
//  #endif

const char app_password[] = "app-password";

//  #include <memory>


namespace {
}

namespace Occ {

class AccountPointer : unowned<Account>;


/***********************************************************
@brief The Account class represents an account on an
ownCloud Server
@ingroup libsync

The Account has a name and url. It also has information
about credentials, SSL errors and certificates.
***********************************************************/
class Account : GLib.Object {

    const int PUSH_NOTIFICATIONS_RECONNECT_INTERVAL = 1000 * 60 * 2;
    const int USERNAME_PREFILL_SERVER_VERSION_MIN_SUPPORTED_MAJOR = 24;

    /***********************************************************
    @brief Reimplement this to handle SSL errors from libsync
    @ingroup libsync
    ***********************************************************/
    class AbstractSslErrorHandler {
        public virtual ~AbstractSslErrorHandler () = default;
        public virtual bool handle_errors (GLib.List<QSslError>, QSslConfiguration conf, GLib.List<QSslCertificate> *, AccountPointer);
    };


    //  Q_PROPERTY (string identifier MEMBER identifier)
    //  Q_PROPERTY (string dav_user MEMBER dav_user)
    //  Q_PROPERTY (string display_name MEMBER display_name)
    //  Q_PROPERTY (GLib.Uri url MEMBER url)


    /***********************************************************
    Because of bugs in Qt, we use this to store info needed for
    the SSL Button
    ***********************************************************/
    public QSslCipher session_cipher;


    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray session_ticket;


    /***********************************************************
    ***********************************************************/
    public GLib.List<QSslCertificate> peer_certificate_chain;

    /***********************************************************
    ***********************************************************/
    private QWeakPointer<Account> shared_this;

    /***********************************************************
    ***********************************************************/
    private string identifier;

    /***********************************************************
    ***********************************************************/
    private string dav_user;

    /***********************************************************
    ***********************************************************/
    private string display_name;

    /***********************************************************
    ***********************************************************/
    private QTimer push_notifications_reconnect_timer;

    /***********************************************************
    ***********************************************************/
#ifndef TOKEN_AUTH_ONLY
    private QImage avatar_img;
#endif

    /***********************************************************
    ***********************************************************/
    private GLib.HashMap<string, GLib.Variant> settings_map;

    /***********************************************************
    ***********************************************************/
    private GLib.Uri url;

    /***********************************************************
    If url to use for any user-visible urls.

    If the server configures overwritehost this can be different
    from the connection url in this.url. We retrieve the visible
    host through the ocs/v1.php/config endpoint in
    ConnectionValidator.
    ***********************************************************/
    private GLib.Uri user_visible_url;

    /***********************************************************
    ***********************************************************/
    private GLib.List<QSslCertificate> approved_certificates;

    /***********************************************************
    ***********************************************************/
    private QSslConfiguration ssl_configuration;

    /***********************************************************
    ***********************************************************/
    private Capabilities capabilities;

    /***********************************************************
    ***********************************************************/
    private string server_version;

    /***********************************************************
    ***********************************************************/
    private QScopedPointer<AbstractSslErrorHandler> ssl_error_handler;

    /***********************************************************
    ***********************************************************/
    private unowned<QNetworkAccessManager> access_manager;

    /***********************************************************
    ***********************************************************/
    private QScopedPointer<AbstractCredentials> credentials;

    /***********************************************************
    ***********************************************************/
    private bool http2Supported = false;

    /***********************************************************
    Certificates that were explicitly rejected by the user
    ***********************************************************/
    private GLib.List<QSslCertificate> rejected_certificates;

    /***********************************************************
    ***********************************************************/
    private static string config_filename;

    /***********************************************************
    ***********************************************************/
    private ClientSideEncryption e2e;


    /***********************************************************
    Used in RemoteWipe
    ***********************************************************/
    private bool wrote_app_password = false;

    /***********************************************************
    ***********************************************************/
    private friend class AccountManager;


    /***********************************************************
    Direct Editing
    ***********************************************************/
    private string last_direct_editing_e_tag;

    /***********************************************************
    ***********************************************************/
    private PushNotifications push_notifications = null;

    /***********************************************************
    ***********************************************************/
    private std.shared_ptr<UserStatusConnector> user_status_connector;


    /***********************************************************
    ***********************************************************/
    private bool is_remote_wipe_requested_HACK = false;
    // <-- FIXME MS@2019-12-07


    /***********************************************************
    Emitted whenever there's network activity
    ***********************************************************/
    signal void propagator_network_activity ();



    /***********************************************************
    Triggered by handle_invalid_credentials ()
    ***********************************************************/
    signal void invalid_credentials ();



    /***********************************************************
    ***********************************************************/
    signal void credentials_fetched (AbstractCredentials credentials);


    /***********************************************************
    ***********************************************************/
    signal void credentials_asked (AbstractCredentials credentials);



    /***********************************************************
    Forwards from QNetworkAccessManager.proxy_authentication_required ().
    ***********************************************************/
    signal void proxy_authentication_required (QNetworkProxy &, QAuthenticator *);



    /***********************************************************
    e.g. when the approved SSL certificates changed
    ***********************************************************/
    signal void wants_account_saved (Account acc);



    /***********************************************************
    ***********************************************************/
    signal void server_version_changed (Account account, string new_version, string old_version);



    /***********************************************************
    ***********************************************************/
    signal void account_changed_avatar ();



    /***********************************************************
    ***********************************************************/
    signal void account_changed_display_name ();



    /***********************************************************
    Used in RemoteWipe
    ***********************************************************/
    signal void app_password_retrieved (string);



    /***********************************************************
    ***********************************************************/
    signal void push_notifications_ready (Account account);



    /***********************************************************
    ***********************************************************/
    signal void push_notifications_disabled (Account account);



    /***********************************************************
    ***********************************************************/
    signal void user_status_changed ();


    /***********************************************************
    ***********************************************************/
    private Account (GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.capabilities = new QVariantMap ();
        q_register_meta_type<AccountPointer> ("AccountPointer");
        q_register_meta_type<Account> ("Account*");

        this.push_notifications_reconnect_timer.set_interval (PUSH_NOTIFICATIONS_RECONNECT_INTERVAL);
        connect (&this.push_notifications_reconnect_timer, &QTimer.timeout, this, &Account.try_setup_push_notifications);
    }





    /***********************************************************
    ***********************************************************/
    public static AccountPointer create () {
        AccountPointer acc = AccountPointer (new Account);
        acc.set_shared_this (acc);
        return acc;
    }


    /***********************************************************
    ***********************************************************/
    public void set_shared_this (AccountPointer shared_this) {
        this.shared_this = shared_this.to_weak_ref ();
        setup_user_status_connector ();
    }


    /***********************************************************
    ***********************************************************/
    public AccountPointer shared_from_this () {
        return this.shared_this.to_strong_ref ();
    }


    /***********************************************************
    The user that can be used in dav url.

    This can very well be different frome the login user that's
    stored in credentials ().user ().
    ***********************************************************/
    public string dav_user () {
        return this.dav_user.is_empty () && this.credentials ? this.credentials.user () : this.dav_user;
    }


    /***********************************************************
    ***********************************************************/
    public void set_dav_user (string new_dav_user) {
        if (this.dav_user == new_dav_user) {
            return;
        }
        this.dav_user = new_dav_user;
        /* emit */ wants_account_saved (this);
    }


    /***********************************************************
    ***********************************************************/
    public string dav_display_name () {
        return this.display_name;
    }


    /***********************************************************
    ***********************************************************/
    public void set_dav_display_name (string new_display_name) {
        this.display_name = new_display_name;
        /* emit */ account_changed_display_name ();
    }


    /***********************************************************
    ***********************************************************/
#ifndef TOKEN_AUTH_ONLY
    public QImage avatar () {
        return this.avatar_img;
    }


    /***********************************************************
    ***********************************************************/
    public void set_avatar (QImage img) {
        this.avatar_img = img;
        /* emit */ account_changed_avatar ();
    }
#endif


    /***********************************************************
    The name of the account as shown in the toolbar
    ***********************************************************/
    public string display_name () {
        string dn = string ("%1@%2").arg (credentials ().user (), this.url.host ());
        int port = url ().port ();
        if (port > 0 && port != 80 && port != 443) {
            dn.append (':');
            dn.append (string.number (port));
        }
        return dn;
    }



    /***********************************************************
    The internal identifier of the account.
    ***********************************************************/
    public string identifier () {
        return this.identifier;
    }


    /***********************************************************
    Server url of the account
    ***********************************************************/
    public void set_url (GLib.Uri url) {
        this.url = url;
        this.user_visible_url = url;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Uri url () {
        return this.url;
    }


    /***********************************************************
    Adjusts this.user_visible_url once the host to use is discovered.
    ***********************************************************/
    public void set_user_visible_host (string host) {
        this.user_visible_url.set_host (host);
    }


    /***********************************************************
    @brief The possibly themed dav path for the account. It has
           a trailing slash.
    @returns the (themeable) dav path for the account.
    ***********************************************************/
    public string dav_path () {
        return dav_path_base () + '/' + dav_user () + '/';
    }


    private static string dav_path_base () {
        return "/remote.php/dav/files";
    }


    /***********************************************************
    Returns webdav entry URL, based on url ()
    ***********************************************************/
    public GLib.Uri dav_url () {
        return Utility.concat_url_path (url (), dav_path ());
    }


    /***********************************************************
    Returns the legacy permalink url for a file.

    This uses the old way of manually building the url. New
    code should use the "privatelink" property accessible via
    PROPFIND.
    ***********************************************************/
    public GLib.Uri deprecated_private_link_url (GLib.ByteArray numeric_file_id) {
        return Utility.concat_url_path (this.user_visible_url,
            QLatin1String ("/index.php/f/") + GLib.Uri.to_percent_encoding (string.from_latin1 (numeric_file_id)));
    }


    /***********************************************************
    Holds the accounts credentials
    ***********************************************************/
    public AbstractCredentials credentials () {
        return this.credentials.data ();
    }


    /***********************************************************
    ***********************************************************/
    public void set_credentials (AbstractCredentials credentials) {
        // set active credential manager
        QNetworkCookieJar jar = null;
        QNetworkProxy proxy;

        if (this.access_manager) {
            jar = this.access_manager.cookie_jar ();
            jar.set_parent (null);

            // Remember proxy (issue #2108)
            proxy = this.access_manager.proxy ();

            this.access_manager = unowned<QNetworkAccessManager> ();
        }

        // The order for these two is important! Reading the credential's
        // settings accesses the account as well as account.credentials,
        this.credentials.on_reset (credentials);
        credentials.set_account (this);

        // Note: This way the QNAM can outlive the Account and Credentials.
        // This is necessary to avoid issues with the QNAM being deleted while
        // processing on_handle_ssl_errors ().
        this.access_manager = unowned<QNetworkAccessManager> (this.credentials.create_qnam (), &GLib.Object.delete_later);

        if (jar) {
            this.access_manager.set_cookie_jar (jar);
        }
        if (proxy.type () != QNetworkProxy.DefaultProxy) {
            this.access_manager.set_proxy (proxy);
        }
        connect (this.access_manager.data (), SIGNAL (ssl_errors (Soup.Reply *, GLib.List<QSslError>)),
            SLOT (on_handle_ssl_errors (Soup.Reply *, GLib.List<QSslError>)));
        connect (this.access_manager.data (), &QNetworkAccessManager.proxy_authentication_required,
            this, &Account.proxy_authentication_required);
        connect (this.credentials.data (), &AbstractCredentials.fetched,
            this, &Account.on_credentials_fetched);
        connect (this.credentials.data (), &AbstractCredentials.asked,
            this, &Account.on_credentials_asked);

        try_setup_push_notifications ();
    }


    /***********************************************************
    Create a network request on the account's QNAM.

    Network requests in AbstractNetworkJobs are created through
    this function. Other places should prefer to use jobs or
    send_request ().
    ***********************************************************/
    public Soup.Reply send_raw_request (GLib.ByteArray verb,
        const GLib.Uri url,
        Soup.Request req = Soup.Request (),
        QIODevice data = null) {
        req.set_url (url);
        req.set_ssl_configuration (this.get_or_create_ssl_config ());
        if (verb == "HEAD" && !data) {
            return this.access_manager.head (req);
        } else if (verb == "GET" && !data) {
            return this.access_manager.get (req);
        } else if (verb == "POST") {
            return this.access_manager.post (req, data);
        } else if (verb == "PUT") {
            return this.access_manager.put (req, data);
        } else if (verb == "DELETE" && !data) {
            return this.access_manager.delete_resource (req);
        }
        return this.access_manager.send_custom_request (req, verb, data);
    }


    /***********************************************************
    ***********************************************************/
    public Soup.Reply send_raw_request (GLib.ByteArray verb,
        GLib.Uri url, Soup.Request req, GLib.ByteArray data)  {
        req.set_url (url);
        req.set_ssl_configuration (this.get_or_create_ssl_config ());
        if (verb == "HEAD" && data.is_empty ()) {
            return this.access_manager.head (req);
        } else if (verb == "GET" && data.is_empty ()) {
            return this.access_manager.get (req);
        } else if (verb == "POST") {
            return this.access_manager.post (req, data);
        } else if (verb == "PUT") {
            return this.access_manager.put (req, data);
        } else if (verb == "DELETE" && data.is_empty ()) {
            return this.access_manager.delete_resource (req);
        }
        return this.access_manager.send_custom_request (req, verb, data);
    }


    /***********************************************************
    ***********************************************************/
    public Soup.Reply send_raw_request (GLib.ByteArray verb,
        GLib.Uri url, Soup.Request req, QHttpMultiPart data) {
        req.set_url (url);
        req.set_ssl_configuration (this.get_or_create_ssl_config ());
        if (verb == "PUT") {
            return this.access_manager.put (req, data);
        } else if (verb == "POST") {
            return this.access_manager.post (req, data);
        }
        return this.access_manager.send_custom_request (req, verb, data);
    }


    /***********************************************************
    Create and start network job for a simple one-off request.

    More complicated requests typically create their own job
    types.
    ***********************************************************/
    public SimpleNetworkJob send_request (GLib.ByteArray verb,
        GLib.Uri url,
        Soup.Request req = Soup.Request (),
        QIODevice data = null) {
        var job = new SimpleNetworkJob (shared_from_this ());
        job.start_request (verb, url, req, data);
        return job;
    }


    /***********************************************************
    The ssl configuration during the first connection
    ***********************************************************/
    public QSslConfiguration get_or_create_ssl_config ()s {
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


    /***********************************************************
    ***********************************************************/
    public QSslConfiguration ssl_configuration () {
        return ssl_configuration;
    }


    /***********************************************************
    ***********************************************************/
    public void set_ssl_configuration (QSslConfiguration config) {
        this.ssl_configuration = config;
    }


    /***********************************************************
    The certificates of the account
    ***********************************************************/
    public GLib.List<QSslCertificate> approved_certificates () {
        return approved_certificates;
    }


    /***********************************************************
    ***********************************************************/
    public void set_approved_certificates (GLib.List<QSslCertificate> certificates) {
        this.approved_certificates = certificates;
        QSslConfiguration.default_configuration ().add_ca_certificates (certificates);
    }


    /***********************************************************
    ***********************************************************/
    public void add_approved_certificates (GLib.List<QSslCertificate> certificates) {
        this.approved_certificates += certificates;
    }


    /***********************************************************
    Usually when a user explicitly rejects a certificate we
    don't ask again. After this call, a dialog will again be
    shown when the next unknown certificate is encountered.
    ***********************************************************/
    public void reset_rejected_certificates () {
        this.rejected_certificates.clear ();
    }



    /***********************************************************
    Pluggable handler
    ***********************************************************/
    public void set_ssl_error_handler (AbstractSslErrorHandler handler) {
        this.ssl_error_handler.on_reset (handler);
    }



    /***********************************************************
    To be called by credentials only, for storing username and the like
    ***********************************************************/
    public GLib.Variant credential_setting (string key) {
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


    /***********************************************************
    ***********************************************************/
    public void set_credential_setting (string key, GLib.Variant value) {
        if (this.credentials) {
            string prefix = this.credentials.auth_type ();
            this.settings_map.insert (prefix + "this." + key, value);
        }
    }


    /***********************************************************
    Assign a client certificate
    ***********************************************************/
    public void set_certificate (GLib.ByteArray certficate = GLib.ByteArray (), string private_key = "");


    /***********************************************************
    Access the server capabilities
    ***********************************************************/
    public const Capabilities capabilities () {
        return this.capabilities;
    }


    /***********************************************************
    ***********************************************************/
    public void set_capabilities (QVariantMap capabilities) {
        this.capabilities = Capabilities (capabilities);

        setup_user_status_connector ();
        try_setup_push_notifications ();
    }


    /***********************************************************
    Access the server version

    For servers >= 10.0.0, this can be the empty string until
    capabilities have been received.
    ***********************************************************/
    public string server_version () {
        return this.server_version;
    }


    /***********************************************************
    Server version for easy comparison.

    Example: server_version_int () >= make_server_version (11, 2, 3)

    Will be 0 if the version is not available yet.
    ***********************************************************/
    public int server_version_int (){
        // FIXME : Use Qt 5.5 QVersionNumber
        var components = server_version ().split ('.');
        return make_server_version (components.value (0).to_int (),
            components.value (1).to_int (),
            components.value (2).to_int ());
    }


    /***********************************************************
    ***********************************************************/
    public static int make_server_version (int major_version, int minor_version, int patch_version) {
        return (major_version << 16) + (minor_version << 8) + patch_version;
    }


    /***********************************************************
    ***********************************************************/
    public void set_server_version (string version) {
        if (version == this.server_version) {
            return;
        }

        var old_server_version = this.server_version;
        this.server_version = version;
        /* emit */ server_version_changed (this, old_server_version, version);
    }


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
    public bool server_version_unsupported () {
        if (server_version_int () == 0) {
            // not detected yet, assume it is fine.
            return false;
        }
        return server_version_int () < make_server_version (NEXTCLOUD_SERVER_VERSION_MIN_SUPPORTED_MAJOR,
                NEXTCLOUD_SERVER_VERSION_MIN_SUPPORTED_MINOR, NEXTCLOUD_SERVER_VERSION_MIN_SUPPORTED_PATCH);
    }


    /***********************************************************
    ***********************************************************/
    public bool is_username_prefill_supported () {
        return server_version_int () >= make_server_version (USERNAME_PREFILL_SERVER_VERSION_MIN_SUPPORTED_MAJOR, 0, 0);
    }


    /***********************************************************
    True when the server connection is using HTTP2
    ***********************************************************/
    public bool is_http2Supported () {
        return http2Supported;
    }


    /***********************************************************
    ***********************************************************/
    public void set_http2Supported (bool value) {
        http2Supported = value;
    }


    /***********************************************************
    clear all cookies. (Session cookies or not)
    ***********************************************************/
    public void clear_cookie_jar () {
        var jar = qobject_cast<CookieJar> (this.access_manager.cookie_jar ());
        ASSERT (jar);
        jar.set_all_cookies (GLib.List<QNetworkCookie> ());
        /* emit */ wants_account_saved (this);
    }


    /***********************************************************
    This shares our official cookie jar (containing all the tasty
    authentication cookies) with another QNAM while making sure
    of not losing its ownership.
    ***********************************************************/
    public void lend_cookie_jar_to (QNetworkAccessManager guest) {
        var jar = this.access_manager.cookie_jar ();
        var old_parent = jar.parent ();
        guest.set_cookie_jar (jar); // takes ownership of our precious cookie jar
        jar.set_parent (old_parent); // takes it back
    }


    /***********************************************************
    ***********************************************************/
    public void try_setup_push_notifications () {
        // Stop the timer to prevent parallel setup attempts
        this.push_notifications_reconnect_timer.stop ();

        if (this.capabilities.available_push_notifications () != PushNotificationType.NONE) {
            GLib.Info (lc_account) << "Try to setup push notifications";

            if (!this.push_notifications) {
                this.push_notifications = new PushNotifications (this, this);

                connect (this.push_notifications, &PushNotifications.ready, this, [this] () {
                    this.push_notifications_reconnect_timer.stop ();
                    /* emit */ push_notifications_ready (this);
                });

                const var disable_push_notifications = [this] () {
                    GLib.Info (lc_account) << "Disable push notifications object because authentication failed or connection lost";
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


    /***********************************************************
    ***********************************************************/
    public void delete_app_password () {
        const string kck = AbstractCredentials.keychain_key (
                    url ().to_string (),
                    credentials ().user () + app_password,
                    identifier ()
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
                GLib.Info (lc_account) << "app_password deleted from keychain";
            else
                GLib.warn (lc_account) << "Unable to delete app_password from keychain" << delete_job.error_string ();

            // Allow storing a new app password on re-login
            this.wrote_app_password = false;
        });
        job.on_start ();
    }


    /***********************************************************
    ***********************************************************/
    public string cookie_jar_path () {
        return QStandardPaths.writable_location (QStandardPaths.AppConfigLocation) + "/cookies" + identifier () + ".db";
    }


    /***********************************************************
    ***********************************************************/
    public void reset_network_access_manager () {
        if (!this.credentials || !this.access_manager) {
            return;
        }

        GLib.debug (lc_account) << "Resetting QNAM";
        QNetworkCookieJar jar = this.access_manager.cookie_jar ();
        QNetworkProxy proxy = this.access_manager.proxy ();

        // Use a unowned to allow locking the life of the QNAM on the stack.
        // Make it call delete_later to make sure that we can return to any QNAM stack frames safely.
        this.access_manager = unowned<QNetworkAccessManager> (this.credentials.create_qnam (), &GLib.Object.delete_later);

        this.access_manager.set_cookie_jar (jar); // takes ownership of the old cookie jar
        this.access_manager.set_proxy (proxy);   // Remember proxy (issue #2108)

        connect (this.access_manager.data (), SIGNAL (ssl_errors (Soup.Reply *, GLib.List<QSslError>)),
            SLOT (on_handle_ssl_errors (Soup.Reply *, GLib.List<QSslError>)));
        connect (this.access_manager.data (), &QNetworkAccessManager.proxy_authentication_required,
            this, &Account.proxy_authentication_required);
    }


    /***********************************************************
    ***********************************************************/
    public QNetworkAccessManager network_access_manager () {
        return this.access_manager.data ();
    }


    /***********************************************************
    ***********************************************************/
    public unowned QNetworkAccessManager shared_network_access_manager () {
        return this.access_manager;
    }


    /***********************************************************
    Called by network jobs on credential errors, emits
    invalid_credentials ()
    ***********************************************************/
    public void handle_invalid_credentials () {
        // Retrieving password will trigger remote wipe check job
        retrieve_app_password ();

        /* emit */ invalid_credentials ();
    }


    /***********************************************************
    ***********************************************************/
    public ClientSideEncryption e2e () {
        // Qt expects everything in the connect to be a pointer, so return a pointer.
        return this.e2e;
    }


    /***********************************************************
    Used in RemoteWipe
    ***********************************************************/
    public void retrieve_app_password () {
        const string kck = AbstractCredentials.keychain_key (
                    url ().to_string (),
                    credentials ().user () + app_password,
                    identifier ()
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


    /***********************************************************
    ***********************************************************/
    public void write_app_password_once (string app_password) {
        if (this.wrote_app_password)
            return;

        // Fix : Password got written from Account Wizard, before finish.
        // Only write the app password for a connected account, else
        // there'll be a zombie keychain slot forever, never used again ;p
        //
        // Also don't write empty passwords (Log out . Relaunch)
        if (identifier ().is_empty () || app_password.is_empty ())
            return;

        const string kck = AbstractCredentials.keychain_key (
                    url ().to_string (),
                    dav_user () + app_password,
                    identifier ()
        );

        var job = new WritePasswordJob (Theme.instance ().app_name ());
        job.set_insecure_fallback (false);
        job.set_key (kck);
        job.set_binary_data (app_password.to_latin1 ());
        connect (job, &WritePasswordJob.on_finished, [this] (Job incoming) {
            var write_job = static_cast<WritePasswordJob> (incoming);
            if (write_job.error () == NoError)
                GLib.Info (lc_account) << "app_password stored in keychain";
            else
                GLib.warn (lc_account) << "Unable to store app_password in keychain" << write_job.error_string ();

            // We don't try this again on error, to not raise CPU consumption
            this.wrote_app_password = true;
        });
        job.on_start ();
    }


    /***********************************************************
    ***********************************************************/
    public void delete_app_token () {
        const var delete_app_token_job = new DeleteJob (shared_from_this (), QStringLiteral ("/ocs/v2.php/core/apppassword"));
        connect (delete_app_token_job, &DeleteJob.finished_signal, this, [this] () {
            if (var delete_job = qobject_cast<DeleteJob> (GLib.Object.sender ())) {
                const var http_code = delete_job.reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
                if (http_code != 200) {
                    GLib.warn (lc_account) << "AppToken remove failed for user : " << display_name () << " with code : " << http_code;
                } else {
                    GLib.Info (lc_account) << "AppToken for user : " << display_name () << " has been removed.";
                }
            } else {
                //  Q_ASSERT (false);
                GLib.warn (lc_account) << "The sender is not a DeleteJob instance.";
            }
        });
        delete_app_token_job.on_start ();
    }



    /***********************************************************
    Direct Editing
    Check for the direct_editing capability
    ***********************************************************/
    public void fetch_direct_editors (GLib.Uri direct_editing_url, string direct_editing_e_tag) {
        if (direct_editing_url.is_empty () || direct_editing_e_tag.is_empty ())
            return;

        // Check for the direct_editing capability
        if (!direct_editing_url.is_empty () &&
            (direct_editing_e_tag.is_empty () || direct_editing_e_tag != this.last_direct_editing_e_tag)) {
                // Fetch the available editors and their mime types
                var job = new JsonApiJob (shared_from_this (), QLatin1String ("ocs/v2.php/apps/files/api/v1/direct_editing"));
                GLib.Object.connect (job, &JsonApiJob.json_received, this, &Account.on_direct_editing_recieved);
                job.on_start ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void setup_user_status_connector () {
        this.user_status_connector = std.make_shared<OcsUserStatusConnector> (shared_from_this ());
        connect (this.user_status_connector.get (), &UserStatusConnector.user_status_fetched, this, [this] (UserStatus &) {
            /* emit */ user_status_changed ();
        });
        connect (this.user_status_connector.get (), &UserStatusConnector.message_cleared, this, [this] {
            /* emit */ user_status_changed ();
        });
    }


    /***********************************************************
    ***********************************************************/
    public PushNotifications push_notifications () {
        return this.push_notifications;
    }


    /***********************************************************
    ***********************************************************/
    public void set_push_notifications_reconnect_interval (int interval) {
        this.push_notifications_reconnect_timer.set_interval (interval);
    }



    /***********************************************************
    ***********************************************************/
    public std.shared_ptr<UserStatusConnector> user_status_connector () {
        return this.user_status_connector;
    }


    /***********************************************************
    Used when forgetting credentials
    ***********************************************************/
    public void on_clear_qnam_cache () {
        this.access_manager.clear_access_cache ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_handle_ssl_errors (Soup.Reply reply, GLib.List<QSslError> errors) {
        NetworkJobTimeoutPauser pauser (reply);
        string out;
        QDebug (&out) << "SSL-Errors happened for url " << reply.url ().to_string ();
        foreach (QSslError error, errors) {
            QDebug (&out) << "\t_error in " << error.certificate () << ":"
                        << error.error_string () << " (" << error.error () << ")"
                        << "\n";
        }

        GLib.Info (lc_account ()) << "ssl errors" << out;
        GLib.Info (lc_account ()) << reply.ssl_configuration ().peer_certificate_chain ();

        bool all_previously_rejected = true;
        foreach (QSslError error, errors) {
            if (!this.rejected_certificates.contains (error.certificate ())) {
                all_previously_rejected = false;
            }
        }

        // If all certificates have previously been rejected by the user, don't ask again.
        if (all_previously_rejected) {
            GLib.Info (lc_account) << out << "Certs not trusted by user decision, returning.";
            return;
        }

        GLib.List<QSslCertificate> approved_certificates;
        if (this.ssl_error_handler.is_null ()) {
            GLib.warn (lc_account) << out << "called without valid SSL error handler for account" << url ();
            return;
        }

        // SslDialogErrorHandler.handle_errors will run an event loop that might execute
        // the delete_later () of the QNAM before we have the chance of unwinding our stack.
        // Keep a ref here on our stackframe to make sure that it doesn't get deleted before
        // handle_errors returns.
        unowned<QNetworkAccessManager> qnam_lock = this.access_manager;
        QPointer<GLib.Object> guard = reply;

        if (this.ssl_error_handler.handle_errors (errors, reply.ssl_configuration (), approved_certificates, shared_from_this ())) {
            if (!guard)
                return;

            if (!approved_certificates.is_empty ()) {
                QSslConfiguration.default_configuration ().add_ca_certificates (approved_certificates);
                add_approved_certificates (approved_certificates);
                /* emit */ wants_account_saved (this);

                // all ssl certificates are known and accepted. We can ignore the problems right away.
                GLib.Info (lc_account) << out << "Certs are known and trusted! This is not an actual error.";
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


    /***********************************************************
    ***********************************************************/
    protected void on_credentials_fetched () {
        if (this.dav_user.is_empty ()) {
            GLib.debug (lc_account) << "User identifier not set. Fetch it.";
            const var fetch_user_name_job = new JsonApiJob (shared_from_this (), QStringLiteral ("/ocs/v1.php/cloud/user"));
            connect (fetch_user_name_job, &JsonApiJob.json_received, this, [this, fetch_user_name_job] (QJsonDocument json, int status_code) {
                fetch_user_name_job.delete_later ();
                if (status_code != 100) {
                    GLib.warn (lc_account) << "Could not fetch user identifier. Login will probably not work.";
                    /* emit */ credentials_fetched (this.credentials.data ());
                    return;
                }

                const var obj_data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
                const var user_id = obj_data.value ("identifier").to_string ("");
                set_dav_user (user_id);
                /* emit */ credentials_fetched (this.credentials.data ());
            });
            fetch_user_name_job.on_start ();
        } else {
            GLib.debug (lc_account) << "User identifier already fetched.";
            /* emit */ credentials_fetched (this.credentials.data ());
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_credentials_asked () {
        /* emit */ credentials_asked (this.credentials.data ());
    }


    /***********************************************************
    ***********************************************************/
    protected void on_direct_editing_recieved (QJsonDocument json) {
        var data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
        var editors = data.value ("editors").to_object ();

        foreach (var editor_key, editors.keys ()) {
            var editor = editors.value (editor_key).to_object ();

            const string identifier = editor.value ("identifier").to_string ();
            const string name = editor.value ("name").to_string ();

            if (!identifier.is_empty () && !name.is_empty ()) {
                var mime_types = editor.value ("mimetypes").to_array ();
                var optional_mime_types = editor.value ("optional_mimetypes").to_array ();

                var direct_editor = new DirectEditor (identifier, name);

                foreach (var mime_type, mime_types) {
                    direct_editor.add_mimetype (mime_type.to_string ().to_latin1 ());
                }

                foreach (var optional_mime_type, optional_mime_types) {
                    direct_editor.add_optional_mimetype (optional_mime_type.to_string ().to_latin1 ());
                }

                this.capabilities.add_direct_editor (direct_editor);
            }
        }
    }


    /***********************************************************
    IMPORTANT - remove later - FIXME MS@2019-12-07 -.
    TODO: For "Log out" & "Remove account":
        Remove client CA certificates and KEY!

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
}

} // namespace Occ
