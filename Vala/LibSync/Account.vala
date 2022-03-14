/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <deletejob.h>
//  #include <QLoggingCategory>
//  #include <QNetworkAccessMana
//  #include <QSslSocket>
//  #include <QNetworkCo
//  #include <QNetw
//  #include <GLib.FileInfo>
//  #include <QDir>
//  #include <QSslKey>
//  #include <QAuthenticat
//  #include <QStandardPa
//  #include <QJsonDocument>
//  #include <QJsonObject>
//  #include <QJsonArray>
//  #include <QLoggingCategory>
//  #include <QHttpMultiPart>
//  #include <qsslconfiguration.h>
//  #include <qt5keychain/keychain.h>

//  using QKeychain;

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

//  #include <memory>

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The Account class represents an account on an
ownCloud Server
@ingroup libsync

The Account has a name and url. It also has information
about credentials, SSL errors and certificates.
***********************************************************/
public class Account : GLib.Object {

    const string app_password = "app-password";

    const int PUSH_NOTIFICATIONS_RECONNECT_INTERVAL = 1000 * 60 * 2;
    const int USERNAME_PREFILL_SERVER_VERSION_MIN_SUPPORTED_MAJOR = 24;

    /***********************************************************
    @brief Reimplement this to handle SSL errors from libsync
    @ingroup libsync
    ***********************************************************/
    class AbstractSslErrorHandler {
        public virtual bool handle_errors (GLib.List<QSslError> error_list, QSslConfiguration conf, GLib.List<QSslCertificate> cert_list, unowned Account account);
    }


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
    QWeakPointer<Account> shared_this {
        private get {
            return this.shared_this;
        }
        public set {
            this.shared_this = value.to_weak_ref ();
            setup_user_status_connector ();
        }
    }

    /***********************************************************
    The internal identifier of the account.
    ***********************************************************/
    string identifier { public get; private set; }

    /***********************************************************
    The user that can be used in dav url.

    This can very well be different frome the login user that's
    stored in credentials ().user ().
    ***********************************************************/
    string dav_user {
        public get {
            return this.dav_user.is_empty () && this.credentials ? this.credentials.user () : this.dav_user;
        }
        public set {
            if (this.dav_user == value) {
                return;
            }
            this.dav_user = value;
            /* emit */ signal_wants_account_saved (this);
        }
    }

    /***********************************************************
    The name of the account as shown in the toolbar
    ***********************************************************/
    string display_name {
        public get {
            string dn = "%1@%2".arg (credentials ().user (), this.url.host ());
            int port = url ().port ();
            if (port > 0 && port != 80 && port != 443) {
                dn.append (':');
                dn.append (string.number (port));
            }
            return dn;
        }
        public set {
            this.display_name = value;
            /* emit */ signal_account_changed_display_name ();
        }
    }

    /***********************************************************
    ***********************************************************/
    private QTimer push_notifications_reconnect_timer;

    /***********************************************************
    ***********************************************************/
//  #ifndef TOKEN_AUTH_ONLY
    Gtk.Image avatar {
        public get {
            return this.avatar;
        }
        public set {
            this.avatar = value;
            /* emit */ signal_account_changed_avatar ();
        }
    }
//  #endif

    /***********************************************************
    ***********************************************************/
    private GLib.HashTable<string, GLib.Variant> settings_map;

    /***********************************************************
    Server url of the account
    ***********************************************************/
    GLib.Uri url {
        public get {
            return this.url;
        }
        public set {
            this.url = value;
            this.user_visible_url = value;
        }
    }

    /***********************************************************
    If url to use for any user-visible urls.

    If the server configures overwritehost this can be different
    from the connection url in this.url. We retrieve the visible
    host through the ocs/v1.php/config endpoint in
    ConnectionValidator.
    ***********************************************************/
    private GLib.Uri user_visible_url;

    /***********************************************************
    The certificates of the account
    ***********************************************************/
    GLib.List<QSslCertificate> approved_certificates {
        public get {
            return this.approved_certificates;
        }
        private set {
            this.approved_certificates = value;
            QSslConfiguration.default_configuration ().add_ca_certificates (value);
        }
    }

    /***********************************************************
    ***********************************************************/
    QSslConfiguration ssl_configuration { public get; public set; }

    /***********************************************************
    Access the server capabilities
    ***********************************************************/
    Capabilities capabilities {
        public get {
            return this.capabilities;
        }
        private set {
            this.capabilities = Capabilities (value);

            setup_user_status_connector ();
            try_setup_push_notifications ();
        }
    }

    /***********************************************************
    Access the server version

    For servers >= 10.0.0, this can be the empty string until
    capabilities have been received.
    ***********************************************************/
    string server_version {
        private get {
            return this.server_version;
        }
        public set {
            if (this.server_version == value) {
                return;
            }
    
            var old_server_version = this.server_version;
            this.server_version = value;
            /* emit */ signal_server_version_changed (this, old_server_version, value);
        }
    }

    /***********************************************************
    Pluggable handler
    ***********************************************************/
    QScopedPointer<AbstractSslErrorHandler> ssl_error_handler {
        private get {
            return this.ssl_error_handler;
        }
        public set {
            this.ssl_error_handler.on_signal_reset (value);
        }
    }

    /***********************************************************
    ***********************************************************/
    private unowned QNetworkAccessManager access_manager;

    /***********************************************************
    Holds the accounts credentials
    ***********************************************************/
    QScopedPointer<AbstractCredentials> credentials {
        public get {
            return this.credentials.data ();
        }
        public set {
            // set active credential manager
            QNetworkCookieJar jar = null;
            QNetworkProxy proxy;

            if (this.access_manager) {
                jar = this.access_manager.cookie_jar ();
                jar.parent (null);

                // Remember proxy (issue #2108)
                proxy = this.access_manager.proxy ();

                this.access_manager = new /*unowned*/ QNetworkAccessManager ();
            }

            // The order for these two is important! Reading the credential's
            // settings accesses the account as well as account.credentials,
            this.credentials.on_signal_reset (value);
            value.account (this);

            // Note: This way the QNAM can outlive the Account and Credentials.
            // This is necessary to avoid issues with the QNAM being deleted while
            // processing on_signal_handle_ssl_errors ().
            this.access_manager = new /*unowned*/ QNetworkAccessManager (this.credentials.create_qnam (), GLib.Object.delete_later);

            if (jar) {
                this.access_manager.cookie_jar (jar);
            }
            if (proxy.type () != QNetworkProxy.DefaultProxy) {
                this.access_manager.proxy (proxy);
            }
            this.signal_ssl_errors.connect (
                this.access_manager.data (),
                this.on_signal_handle_ssl_errors);
            QNetworkAccessManager.signal_proxy_authentication_required.connect (
                this.access_manager.data (),
                Account.signal_proxy_authentication_required);
            AbstractCredentials.signal_fetched.connect (
                this.credentials.data (),
                Account.on_signal_credentials_fetched);
            AbstractCredentials.signal_asked.connect (
                this.credentials.data (),
                Account.on_signal_credentials_asked);

            try_setup_push_notifications ();
        }
    }

    /***********************************************************
    True when the server connection is using HTTP2
    ***********************************************************/
    public bool http2Supported;

    /***********************************************************
    Certificates that were explicitly rejected by the user
    ***********************************************************/
    private GLib.List<QSslCertificate> rejected_certificates;

    /***********************************************************
    ***********************************************************/
    private static string config_filename;

    /***********************************************************
    Qt expects everything in the connect to be a pointer, so
    return a pointer.
    ***********************************************************/
    ClientSideEncryption e2e { public get; private set; }

    /***********************************************************
    Used in RemoteWipe
    ***********************************************************/
    private bool wrote_app_password = false;

    /***********************************************************
    ***********************************************************/
    //  private friend class AccountManager;

    /***********************************************************
    Direct Editing
    ***********************************************************/
    private string last_direct_editing_e_tag;

    /***********************************************************
    ***********************************************************/
    PushNotifications push_notifications { public get; private set; }

    /***********************************************************
    ***********************************************************/
    std.shared_ptr<UserStatusConnector> user_status_connector { public get; private set; }

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
    public bool is_remote_wipe_requested_HACK;

    /***********************************************************
    Emitted whenever there's network activity
    ***********************************************************/
    signal void signal_propagator_network_activity ();

    /***********************************************************
    Triggered by handle_invalid_credentials ()
    ***********************************************************/
    signal void signal_invalid_credentials ();

    /***********************************************************
    ***********************************************************/
    signal void signal_credentials_fetched (AbstractCredentials credentials);

    /***********************************************************
    ***********************************************************/
    signal void signal_credentials_asked (AbstractCredentials credentials);

    /***********************************************************
    Forwards from QNetworkAccessManager.signal_proxy_authentication_required ().
    ***********************************************************/
    signal void signal_proxy_authentication_required (QNetworkProxy proxy, QAuthenticator authenticator);

    /***********************************************************
    e.g. when the approved SSL certificates changed
    ***********************************************************/
    signal void signal_wants_account_saved (Account account);

    /***********************************************************
    ***********************************************************/
    signal void signal_server_version_changed (Account account, string new_version, string old_version);

    /***********************************************************
    ***********************************************************/
    signal void signal_account_changed_avatar ();

    /***********************************************************
    ***********************************************************/
    signal void signal_account_changed_display_name ();

    /***********************************************************
    Used in RemoteWipe
    ***********************************************************/
    signal void signal_app_password_retrieved (string value);

    /***********************************************************
    ***********************************************************/
    signal void signal_push_notifications_ready (Account account);

    /***********************************************************
    ***********************************************************/
    signal void signal_push_notifications_disabled (Account account);

    /***********************************************************
    ***********************************************************/
    signal void signal_user_status_changed ();

    /***********************************************************
    ***********************************************************/
    signal void signal_ssl_errors (Soup.Reply reply, GLib.List<QSslError> error_list);

    /***********************************************************
    ***********************************************************/
    private Account (GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.capabilities = new GLib.HashTable<string, GLib.Variant> ();
        this.http2Supported = false;
        this.push_notifications = null;
        this.is_remote_wipe_requested_HACK = false;
        q_register_meta_type<unowned Account> ("unowned Account");
        q_register_meta_type<Account> ("Account*");

        this.push_notifications_reconnect_timer.interval (PUSH_NOTIFICATIONS_RECONNECT_INTERVAL);
        connect (&this.push_notifications_reconnect_timer, QTimer.timeout, this, Account.try_setup_push_notifications);
    }


    /***********************************************************
    ***********************************************************/
    public static unowned Account create () {
        unowned Account account = new Account ();
        account.shared_this (account);
        return account;
    }


    /***********************************************************
    ***********************************************************/
    public unowned Account shared_from_this () {
        return this.shared_this.to_strong_ref ();
    }


    /***********************************************************
    Adjusts this.user_visible_url once the host to use is discovered.
    ***********************************************************/
    public void user_visible_host (string host) {
        this.user_visible_url.host (host);
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
    Create a network request on the account's QNAM.

    Network requests in AbstractNetworkJobs are created through
    this function. Other places should prefer to use jobs or
    send_request ().
    ***********************************************************/
    public Soup.Reply send_raw_request_for_device (GLib.ByteArray verb,
        GLib.Uri url, Soup.Request request = Soup.Request (),
        QIODevice data = null) {
        request.url (url);
        request.ssl_configuration (this.get_or_create_ssl_config ());
        if (verb == "HEAD" && !data) {
            return this.access_manager.head (request);
        } else if (verb == "GET" && !data) {
            return this.access_manager.get (request);
        } else if (verb == "POST") {
            return this.access_manager.post (request, data);
        } else if (verb == "PUT") {
            return this.access_manager.put (request, data);
        } else if (verb == "DELETE" && !data) {
            return this.access_manager.delete_resource (request);
        }
        return this.access_manager.send_custom_request (request, verb, data);
    }


    /***********************************************************
    ***********************************************************/
    public Soup.Reply send_raw_request_for_data (GLib.ByteArray verb,
        GLib.Uri url, Soup.Request request = Soup.Request (),
        GLib.ByteArray data)  {
        request.url (url);
        request.ssl_configuration (this.get_or_create_ssl_config ());
        if (verb == "HEAD" && data.is_empty ()) {
            return this.access_manager.head (request);
        } else if (verb == "GET" && data.is_empty ()) {
            return this.access_manager.get (request);
        } else if (verb == "POST") {
            return this.access_manager.post (request, data);
        } else if (verb == "PUT") {
            return this.access_manager.put (request, data);
        } else if (verb == "DELETE" && data.is_empty ()) {
            return this.access_manager.delete_resource (request);
        }
        return this.access_manager.send_custom_request (request, verb, data);
    }


    /***********************************************************
    ***********************************************************/
    public Soup.Reply send_raw_request_for_multipart (GLib.ByteArray verb,
        GLib.Uri url, Soup.Request request = Soup.Request (),
        QHttpMultiPart data) {
        request.url (url);
        request.ssl_configuration (this.get_or_create_ssl_config ());
        if (verb == "PUT") {
            return this.access_manager.put (request, data);
        } else if (verb == "POST") {
            return this.access_manager.post (request, data);
        }
        return this.access_manager.send_custom_request (request, verb, data);
    }


    /***********************************************************
    Create and start network job for a simple one-off request.

    More complicated requests typically create their own job
    types.
    ***********************************************************/
    public SimpleNetworkJob send_request (GLib.ByteArray verb,
        GLib.Uri url, Soup.Request request = Soup.Request (),
        QIODevice data = null) {
        var simple_network_job = new SimpleNetworkJob (shared_from_this ());
        simple_network_job.start_request (verb, url, request, data);
        return simple_network_job;
    }


    /***********************************************************
    The ssl configuration during the first connection
    ***********************************************************/
    public QSslConfiguration get_or_create_ssl_config () {
        if (!this.ssl_configuration.is_null ()) {
            // Will be set by CheckServerJob.on_signal_finished ()
            // We need to use a central shared config to get SSL session tickets
            return this.ssl_configuration;
        }

        // if setting the client certificate fails, you will probably get an error similar to this:
        //  "An internal error number 1060 happened. SSL handshake failed, client certificate was requested : SSL error : sslv3 alert handshake failure"
        QSslConfiguration ssl_config = QSslConfiguration.default_configuration ();

        // Try hard to re-use session for different requests
        ssl_config.ssl_option (QSsl.SslOptionDisableSessionTickets, false);
        ssl_config.ssl_option (QSsl.SslOptionDisableSessionSharing, false);
        ssl_config.ssl_option (QSsl.SslOptionDisableSessionPersistence, false);

        ssl_config.ocsp_stapling_enabled (Theme.instance ().enable_stapling_ocsp ());

        return ssl_config;
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
    To be called by credentials only, for storing username and the like
    ***********************************************************/
    public GLib.Variant credential_setting_key (string key) {
        if (this.credentials) {
            string prefix = this.credentials.signal_auth_type ();
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
    public void credential_setting_key_value (string key, GLib.Variant value) {
        if (this.credentials) {
            string prefix = this.credentials.signal_auth_type ();
            this.settings_map.insert (prefix + "this." + key, value);
        }
    }


    /***********************************************************
    Assign a client certificate
    ***********************************************************/
    public void certificate (GLib.ByteArray certficate = new GLib.ByteArray (), string private_key = "");


    /***********************************************************
    Server version for easy comparison.

    Example: server_version_int () >= make_server_version (11, 2, 3)

    Will be 0 if the version is not available yet.
    ***********************************************************/
    public int server_version_int () {
        // FIXME: Use Qt 5.5 QVersionNumber
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
    clear all cookies. (Session cookies or not)
    ***********************************************************/
    public void clear_cookie_jar () {
        var jar = (CookieJar) this.access_manager.cookie_jar ();
        //  ASSERT (jar);
        jar.all_cookies (new GLib.List<QNetworkCookie> ());
        /* emit */ signal_wants_account_saved (this);
    }


    /***********************************************************
    This shares our official cookie jar (containing all the tasty
    authentication cookies) with another QNAM while making sure
    of not losing its ownership.
    ***********************************************************/
    public void lend_cookie_jar_to (QNetworkAccessManager guest) {
        var jar = this.access_manager.cookie_jar ();
        var old_parent = jar.parent ();
        guest.cookie_jar (jar); // takes ownership of our precious cookie jar
        jar.parent (old_parent); // takes it back
    }


    /***********************************************************
    ***********************************************************/
    public void try_setup_push_notifications () {
        // Stop the timer to prevent parallel setup attempts
        this.push_notifications_reconnect_timer.stop ();

        if (this.capabilities.available_push_notifications () != PushNotificationType.NONE) {
            GLib.info ("Try to setup push notifications");

            if (this.push_notifications == null) {
                this.push_notifications = new PushNotifications (this, this);

                PushNotifications.signal_ready.connect (this.push_notifications, on_signal_ready);
                PushNotifications.signal_connection_lost.connect (this.push_notifications, on_signal_connection_lost);
                PushNotifications.signal_authentication_failed.connect (this.push_notifications, on_signal_connection_lost);
            }
            // If push notifications already running it is no problem to call setup again
            this.push_notifications.up ();
        }
    }

    private void on_signal_ready () {
        this.push_notifications_reconnect_timer.stop ();
        /* emit */ signal_push_notifications_ready (this);
    }

    private void on_signal_connection_lost () {
        GLib.info ("Disable push notifications object because authentication failed or connection lost.");
        if (!this.push_notifications) {
            return;
        }
        if (!this.push_notifications.is_ready ()) {
            /* emit */ signal_push_notifications_disabled (this);
        }
        if (!this.push_notifications_reconnect_timer.is_active ()) {
            this.push_notifications_reconnect_timer.on_signal_start ();
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
            GLib.debug ("app_password is empty");
            return;
        }

        var delete_password_job = new DeletePasswordJob (Theme.instance ().app_name ());
        delete_password_job.insecure_fallback (false);
        delete_password_job.key (kck);
        connect (
            delete_password_job,
            DeletePasswordJob.signal_finished,
            this.on_signal_delete_password_job_finished
        );
        delete_password_job.on_signal_start ();
    }


    private void on_signal_delete_password_job_finished (Job incoming) {
        var delete_job = static_cast<DeletePasswordJob> (incoming);
        if (delete_job.error () == NoError) {
            GLib.info ("app_password deleted from keychain.");
        } else {
            GLib.warning ("Unable to delete app_password from keychain " + delete_job.error_string ());
        }

        // Allow storing a new app password on re-login
        this.wrote_app_password = false;
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

        GLib.debug ("Resetting QNAM");
        QNetworkCookieJar jar = this.access_manager.cookie_jar ();
        QNetworkProxy proxy = this.access_manager.proxy ();

        // Use a unowned to allow locking the life of the QNAM on the stack.
        // Make it call delete_later to make sure that we can return to any QNAM stack frames safely.
        this.access_manager = new /*unowned*/ QNetworkAccessManager (this.credentials.create_qnam (), GLib.Object.delete_later);

        this.access_manager.cookie_jar (jar); // takes ownership of the old cookie jar
        this.access_manager.proxy (proxy);   // Remember proxy (issue #2108)

        connect (
            this.access_manager.data (),
            signal_ssl_errors (reply, error_list),
            on_signal_handle_ssl_errors (reply, error_list)
        );
        Account.signal_proxy_authentication_required.connect (this.access_manager.data (), QNetworkAccessManager.signal_proxy_authentication_required);
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
    signal_invalid_credentials ()
    ***********************************************************/
    public void handle_invalid_credentials () {
        // Retrieving password will trigger remote wipe check job
        retrieve_app_password ();

        /* emit */ signal_invalid_credentials ();
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

        var read_password_job = new ReadPasswordJob (Theme.instance ().app_name ());
        read_password_job.insecure_fallback (false);
        read_password_job.key (kck);
        connect (
            read_password_job,
            ReadPasswordJob.signal_finished,
            this.on_signal_read_password_job_finished);
        read_password_job.on_signal_start ();
    }


    private void on_signal_read_password_job_finished (Job incoming) {
        var read_job = (ReadPasswordJob) incoming;
        string password = "";
        // Error or no valid public key error out
        if (read_job.error () == NoError &&
                read_job.binary_data ().length () > 0) {
            password = read_job.binary_data ();
        }

        /* emit */ signal_app_password_retrieved (password);
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

        var write_password_job = new WritePasswordJob (Theme.instance ().app_name ());
        write_password_job.insecure_fallback (false);
        write_password_job.key (kck);
        write_password_job.binary_data (app_password.to_latin1 ());
        connect (
            write_password_job,
            WritePasswordJob.signal_finished,
            this.on_signal_write_password_job_finished
        );
        write_password_job.on_signal_start ();
    }


    private void on_signal_write_password_job_finished (Job incoming) {
        var write_job = (WritePasswordJob) (incoming);
        if (write_job.error () == NoError) {
            GLib.info ("app_password stored in keychain.");
        } else {
            GLib.warning ("Unable to store app_password in keychain " + write_job.error_string ());
        }

        // We don't try this again on error, to not raise CPU consumption
        this.wrote_app_password = true;
    }


    /***********************************************************
    ***********************************************************/
    public void delete_app_token () {
        var delete_app_token_job = new DeleteJob (shared_from_this (), "/ocs/v2.php/core/apppassword");
        connect (
            delete_app_token_job,
            DeleteJob.signal_finished,
            this,
            this.on_signal_delete_job_finished
        );
        delete_app_token_job.on_signal_start ();
    }


    private void on_signal_delete_job_finished () {
        var delete_job = (DeleteJob)GLib.Object.sender ();
        if (delete_job) {
            var http_code = delete_job.reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
            if (http_code != 200) {
                GLib.warning ("AppToken remove failed for user: " + display_name () + " with code: " + http_code);
            } else {
                GLib.info ("AppToken for user: " + display_name () + " has been removed.");
            }
        } else {
            GLib.assert (false);
            GLib.warning ("The sender is not a DeleteJob instance.");
        }
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
                var json_api_job = new JsonApiJob (shared_from_this (), QLatin1String ("ocs/v2.php/apps/files/api/v1/direct_editing"));
                GLib.Object.JsonApiJob.signal_json_received.connect (json_api_job, this, Account.on_signal_direct_editing_recieved);
                json_api_job.on_signal_start ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void setup_user_status_connector () {
        this.user_status_connector = std.make_shared<OcsUserStatusConnector> (shared_from_this ());
        connect (
            this.user_status_connector,
            UserStatusConnector.user_status_fetched,
            this,
            this.on_signal_user_status_connector_user_status_fetched
        );
        connect (
            this.user_status_connector,
            UserStatusConnector.signal_message_cleared,
            this,
            this.on_signal_user_status_connector_message_cleared
        );
    }


    private void on_signal_user_status_connector_user_status_fetched (UserStatus status) {
        /* emit */ signal_user_status_changed ();
    }


    private void on_signal_user_status_connector_message_cleared () {
        /* emit */ signal_user_status_changed ();
    }


    /***********************************************************
    ***********************************************************/
    public void push_notifications_reconnect_interval (int interval) {
        this.push_notifications_reconnect_timer.interval (interval);
    }





    /***********************************************************
    Used when forgetting credentials
    ***********************************************************/
    public void on_signal_clear_qnam_cache () {
        this.access_manager.clear_access_cache ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_handle_ssl_errors (Soup.Reply reply, GLib.List<QSslError> errors) {
        NetworkJobTimeoutPauser pauser = new NetworkJobTimeoutPauser (reply);
        GLib.debug ("SSL-Errors happened for url " + reply.url ().to_string ());
        foreach (QSslError error in errors) {
            GLib.debug ("\t_error in " + error.certificate () + ":"
                        + error.error_string () + " (" + error.error () + ")"
                        + "\n");
        }

        //  GLib.info ("ssl errors" + output);
        GLib.info (reply.ssl_configuration ().peer_certificate_chain ());

        bool all_previously_rejected = true;
        foreach (QSslError error in errors) {
            if (!this.rejected_certificates.contains (error.certificate ())) {
                all_previously_rejected = false;
            }
        }

        // If all certificates have previously been rejected by the user, don't ask again.
        if (all_previously_rejected) {
            GLib.info (output + "Certs not trusted by user decision, returning.");
            return;
        }

        GLib.List<QSslCertificate> approved_certificates;
        if (this.ssl_error_handler.is_null ()) {
            GLib.warning (output + "called without valid SSL error handler for account" + url ());
            return;
        }

        // SslDialogErrorHandler.handle_errors will run an event loop that might execute
        // the delete_later () of the QNAM before we have the chance of unwinding our stack.
        // Keep a ref here on our stackframe to make sure that it doesn't get deleted before
        // handle_errors returns.
        unowned QNetworkAccessManager qnam_lock = this.access_manager;
        QPointer<GLib.Object> guard = reply;

        if (this.ssl_error_handler.handle_errors (errors, reply.ssl_configuration (), approved_certificates, shared_from_this ())) {
            if (!guard)
                return;

            if (!approved_certificates.is_empty ()) {
                QSslConfiguration.default_configuration ().add_ca_certificates (approved_certificates);
                add_approved_certificates (approved_certificates);
                /* emit */ signal_wants_account_saved (this);

                // all ssl certificates are known and accepted. We can ignore the problems right away.
                GLib.info (output + " Certs are known and trusted! This is not an actual error.");
            }

            // Warning : Do not* use ignore_ssl_errors () (without args) here:
            // it permanently ignores all SSL errors for this host, even
            // certificate changes.
            reply.ignore_ssl_errors (errors);
        } else {
            if (!guard)
                return;

            // Mark all involved certificates as rejected, so we don't ask the user again.
            foreach (QSslError error in errors) {
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
    protected void on_signal_credentials_fetched () {
        if (this.dav_user.is_empty ()) {
            GLib.debug ("User identifier not set. Fetch it.");
            var fetch_user_name_job = new JsonApiJob (shared_from_this (), "/ocs/v1.php/cloud/user");
            connect (
                fetch_user_name_job,
                JsonApiJob.signal_json_received,
                this,
                this.on_signal_json_api_job_user_name_fetched
            );
            fetch_user_name_job.on_signal_start ();
        } else {
            GLib.debug ("User identifier already fetched.");
            /* emit */ signal_credentials_fetched (this.credentials.data ());
        }
    }


    private void on_signal_json_api_job_user_name_fetched (JsonApiJob fetch_user_name_job, QJsonDocument json, int status_code) {
        fetch_user_name_job.delete_later ();
        if (status_code != 100) {
            GLib.warning ("Could not fetch user identifier. Login will probably not work.");
            /* emit */ signal_credentials_fetched (this.credentials.data ());
            return;
        }

        var obj_data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
        var user_id = obj_data.value ("identifier").to_string ();
        dav_user (user_id);
        /* emit */ signal_credentials_fetched (this.credentials.data ());
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_credentials_asked () {
        /* emit */ signal_credentials_asked (this.credentials.data ());
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_direct_editing_recieved (QJsonDocument json) {
        var data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
        var editors = data.value ("editors").to_object ();

        foreach (var editor_key in editors.keys ()) {
            var editor = editors.value (editor_key).to_object ();

            const string identifier = editor.value ("identifier").to_string ();
            const string name = editor.value ("name").to_string ();

            if (!identifier.is_empty () && !name.is_empty ()) {
                var mime_types = editor.value ("mimetypes").to_array ();
                var optional_mime_types = editor.value ("optional_mimetypes").to_array ();

                var direct_editor = new DirectEditor (identifier, name);

                foreach (var mime_type in mime_types) {
                    direct_editor.add_mimetype (mime_type.to_string ().to_latin1 ());
                }

                foreach (var optional_mime_type in optional_mime_types) {
                    direct_editor.add_optional_mimetype (optional_mime_type.to_string ().to_latin1 ());
                }

                this.capabilities.add_direct_editor (direct_editor);
            }
        }
    }

} // class Account

} // namespace LibSync
} // namespace Occ
