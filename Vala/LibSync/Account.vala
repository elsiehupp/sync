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
//  #include <GLib.Dir>
//  #include <QSslKey>
//  #include <QAuthenticat
//  #include <QStandardPa
//  #include <QJsonDocument>
//  #include <QJsonObject>
//  #include <QJsonArray>
//  #include <QLoggingCategory>
//  #include <QHttpMultiPart>
//  #include <qt5keychain/keychain.h>

//  using QKeychain;

//  #include <QSslSocket>
//  #include <QSslConfiguration>

//  #ifndef TOKEN_AUTH_ONLY
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
    abstract class AbstractSslErrorHandler {
        public abstract bool handle_errors (GLib.List<GnuTLS.ErrorCode> error_list, QSslConfiguration conf, GLib.List<GLib.TlsCertificate> cert_list, Account account);
    }


    /***********************************************************
    Because of bugs in Qt, we use this to store info needed for
    the SSL Button
    ***********************************************************/
    public GnuTLS.CipherAlgorithm session_cipher;


    /***********************************************************
    ***********************************************************/
    public string session_ticket;


    /***********************************************************
    ***********************************************************/
    public GLib.List<GLib.TlsCertificate> peer_certificate_chain;

    /***********************************************************
    ***********************************************************/
    unowned Account shared_this {
        private get {
            return this.shared_this;
        }
        public set {
            this.shared_this = value;
            set_up_user_status_connector ();
        }
    }

    /***********************************************************
    The internal identifier of the account.
    ***********************************************************/
    string identifier { public get; private set; }

    /***********************************************************
    The user that can be used in dav url.

    This can very well be different frome the login user that's
    stored in credentials.user ().
    ***********************************************************/
    string dav_user {
        public get {
            return this.dav_user == "" && this.credentials != null ? this.credentials.user : this.dav_user;
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
            string dn = "%1@%2".printf (this.credentials.user, this.url.host);
            int port = this.url.port ();
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
    GLib.List<GLib.TlsCertificate> approved_certificates {
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
    GLib.HashTable<string, GLib.Variant> capabilities {
        public get {
            return this.capabilities;
        }
        private set {
            this.capabilities = value;

            set_up_user_status_connector ();
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
    AbstractSslErrorHandler ssl_error_handler {
        private get {
            return this.ssl_error_handler;
        }
        public set {
            this.ssl_error_handler = value;
        }
    }

    /***********************************************************
    ***********************************************************/
    private Soup.Session soup_session;

    /***********************************************************
    Holds the accounts credentials
    ***********************************************************/
    AbstractCredentials credentials {
        public get {
            return this.credentials;
        }
        public set {
            // set active credential manager
            Soup.CookieJar jar = null;
            Soup.ProxyResolverDefault proxy;

            if (this.soup_session != null) {
                jar = this.soup_session.add_feature ();
                //  jar.parent (null);

                // Remember proxy (issue #2108)
                proxy = (Soup.ProxyResolverDefault) this.soup_session.get_feature (typeof (Soup.ProxyResolverDefault));

                this.soup_session = new /*unowned*/ Soup.Session ();
            }

            // The order for these two is important! Reading the credential's
            // settings accesses the account as well as account.credentials,
            this.credentials = value;
            value.account = this;

            // Note: This way the QNAM can outlive the Account and Credentials.
            // This is necessary to avoid issues with the QNAM being deleted while
            // processing on_signal_handle_ssl_errors ().
            //  this.soup_session = new Soup.Session (this.credentials.create_qnam (), GLib.Object.delete_later);
            this.soup_session = new Soup.Session ();

            if (jar != null) {
                this.soup_session.add_feature (jar);
            }
            this.soup_session.signal_ssl_errors.connect (
                this.on_signal_handle_ssl_errors
            );
            this.soup_session.signal_proxy_authentication_required.connect (
                this.signal_proxy_authentication_required
            );
            AbstractCredentials.signal_fetched.connect (
                this.on_signal_credentials_fetched
            );
            AbstractCredentials.signal_asked.connect (
                this.on_signal_credentials_asked
            );

            try_setup_push_notifications ();
        }
    }

    /***********************************************************
    True when the server connection is using HTTP2
    ***********************************************************/
    public bool http2_supported;

    /***********************************************************
    Certificates that were explicitly rejected by the user
    ***********************************************************/
    private GLib.List<GLib.TlsCertificate> rejected_certificates;

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
    unowned UserStatusConnector user_status_connector { public get; private set; }

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
    internal signal void signal_propagator_network_activity ();

    /***********************************************************
    Triggered by handle_invalid_credentials ()
    ***********************************************************/
    internal signal void signal_invalid_credentials ();

    /***********************************************************
    ***********************************************************/
    internal signal void signal_credentials_fetched (AbstractCredentials credentials);

    /***********************************************************
    ***********************************************************/
    internal signal void signal_credentials_asked (AbstractCredentials credentials);

    /***********************************************************
    Forwards from Soup.Session.signal_proxy_authentication_required ().
    ***********************************************************/
    internal signal void signal_proxy_authentication_required (Soup.ProxyResolverDefault proxy, QAuthenticator authenticator);

    /***********************************************************
    e.g. when the approved SSL certificates changed
    ***********************************************************/
    internal signal void signal_wants_account_saved (Account account);

    /***********************************************************
    ***********************************************************/
    internal signal void signal_server_version_changed (Account account, string new_version, string old_version);

    /***********************************************************
    ***********************************************************/
    internal signal void signal_account_changed_avatar ();

    /***********************************************************
    ***********************************************************/
    internal signal void signal_account_changed_display_name ();

    /***********************************************************
    Used in RemoteWipe
    ***********************************************************/
    internal signal void signal_app_password_retrieved (string value);

    /***********************************************************
    ***********************************************************/
    internal signal void signal_push_notifications_ready (Account account);

    /***********************************************************
    ***********************************************************/
    internal signal void signal_push_notifications_disabled (Account account);

    /***********************************************************
    ***********************************************************/
    internal signal void signal_user_status_changed ();

    /***********************************************************
    ***********************************************************/
    internal signal void signal_ssl_errors (GLib.InputStream reply, GLib.List<GnuTLS.ErrorCode> error_list);

    /***********************************************************
    ***********************************************************/
    private Account (GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.capabilities = new GLib.HashTable<string, GLib.Variant> (str_hash, str_equal);
        this.http2_supported = false;
        this.push_notifications = null;
        this.is_remote_wipe_requested_HACK = false;
        //  q_register_meta_type<unowned Account> ("unowned Account");
        //  q_register_meta_type<Account> ("Account*");

        this.push_notifications_reconnect_timer.interval (PUSH_NOTIFICATIONS_RECONNECT_INTERVAL);
        this.push_notifications_reconnect_timer.timeout.connect (
            this.try_setup_push_notifications);
    }


    /***********************************************************
    ***********************************************************/
    public static Account create () {
        Account account = new Account ();
        account.shared_this (account);
        return account;
    }


    /***********************************************************
    ***********************************************************/
    public Account shared_from_this () {
        return this.shared_this;
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
        return dav_path_base () + "/" + this.dav_user + "/";
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
    public GLib.Uri deprecated_private_link_url (string numeric_file_id) {
        return Utility.concat_url_path (this.user_visible_url,
            "/index.php/f/" + GLib.Uri.to_percent_encoding (numeric_file_id));
    }


    /***********************************************************
    Create a network request on the account's QNAM.

    Network requests in AbstractNetworkJobs are created through
    this function. Other places should prefer to use jobs or
    send_request ().
    ***********************************************************/
    public GLib.InputStream send_raw_request_for_device (string verb,
        GLib.Uri url, Soup.Request request = Soup.Request (),
        QIODevice data = null) {
        request.url (url);
        request.ssl_configuration (this.get_or_create_ssl_config ());
        if (verb == "HEAD" && !data) {
            return this.soup_session.head (request);
        } else if (verb == "GET" && !data) {
            return this.soup_session.get (request);
        } else if (verb == "POST") {
            return this.soup_session.post (request, data);
        } else if (verb == "PUT") {
            return this.soup_session.put (request, data);
        } else if (verb == "DELETE" && !data) {
            return this.soup_session.delete_resource (request);
        }
        return this.soup_session.send_custom_request (request, verb, data);
    }


    /***********************************************************
    ***********************************************************/
    public GLib.InputStream send_raw_request_for_data (
        string verb,
        GLib.Uri url,
        string data,
        Soup.Request request = Soup.Request ())  {
        request.url (url);
        request.ssl_configuration (this.get_or_create_ssl_config ());
        if (verb == "HEAD" && data == "") {
            return this.soup_session.head (request);
        } else if (verb == "GET" && data == "") {
            return this.soup_session.get (request);
        } else if (verb == "POST") {
            return this.soup_session.post (request, data);
        } else if (verb == "PUT") {
            return this.soup_session.put (request, data);
        } else if (verb == "DELETE" && data == "") {
            return this.soup_session.delete_resource (request);
        }
        return this.soup_session.send_custom_request (request, verb, data);
    }


    /***********************************************************
    ***********************************************************/
    public GLib.InputStream send_raw_request_for_multipart (string verb,
        GLib.Uri url,
        QHttpMultiPart data,
        Soup.Request request = Soup.Request ()) {
        request.url (url);
        request.ssl_configuration (this.get_or_create_ssl_config ());
        if (verb == "PUT") {
            return this.soup_session.put (request, data);
        } else if (verb == "POST") {
            return this.soup_session.post (request, data);
        }
        return this.soup_session.send_custom_request (request, verb, data);
    }


    /***********************************************************
    Create and start network job for a simple one-off request.

    More complicated requests typically create their own job
    types.
    ***********************************************************/
    public SimpleNetworkJob send_request (string verb,
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

        ssl_config.ocsp_stapling_enabled (Theme.enable_stapling_ocsp);

        return ssl_config;
    }


    /***********************************************************
    ***********************************************************/
    public void add_approved_certificates (GLib.List<GLib.TlsCertificate> certificates) {
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
    public void certificate (string certficate = "", string private_key = "");


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
        var jar = (CookieJar) this.soup_session.add_feature ();
        //  ASSERT (jar);
        jar.all_cookies (new GLib.List<Soup.Cookie> ());
        /* emit */ signal_wants_account_saved (this);
    }


    /***********************************************************
    This shares our official cookie jar (containing all the tasty
    authentication cookies) with another QNAM while making sure
    of not losing its ownership.
    ***********************************************************/
    public void lend_cookie_jar_to (Soup.Session guest) {
        var jar = this.soup_session.add_feature ();
        var old_parent = jar.parent ();
        guest.add_feature (jar); // takes ownership of our precious cookie jar
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

                this.push_notifications.signal_ready.connect (
                    this.on_push_notifications_signal_ready
                );
                this.push_notifications.signal_connection_lost.connect (
                    this.on_push_notifications_connection_lost
                );
                this.push_notifications.signal_authentication_failed.connect (
                    this.on_push_notifications_connection_lost
                );
            }
            // If push notifications already running it is no problem to call setup again
            this.push_notifications.up ();
        }
    }

    private void on_push_notifications_signal_ready () {
        this.push_notifications_reconnect_timer.stop ();
        /* emit */ signal_push_notifications_ready (this);
    }

    private void on_push_notifications_connection_lost () {
        GLib.info ("Disable push notifications object because authentication failed or connection lost.");
        if (!this.push_notifications) {
            return;
        }
        if (!this.push_notifications.is_ready ()) {
            /* emit */ signal_push_notifications_disabled (this);
        }
        if (!this.push_notifications_reconnect_timer.is_active ()) {
            this.push_notifications_reconnect_timer.start ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void delete_app_password () {
        string kck = AbstractCredentials.keychain_key (
            this.url.to_string (),
            this.credentials.user + app_password,
            this.identifier
        );

        if (kck == "") {
            GLib.debug ("app_password is empty");
            return;
        }

        var delete_password_job = new DeleteJob (Theme.app_name);
        delete_password_job.insecure_fallback (false);
        delete_password_job.key (kck);
        delete_password_job.signal_finished.connect (
            this.on_signal_delete_password_job_finished
        );
        delete_password_job.start ();
    }


    private void on_signal_delete_password_job_finished (Job incoming) {
        var delete_job = (DeleteJob) incoming;
        if (delete_job.error == NoError) {
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
        return GLib.Environment.get_user_config_dir () + "/cookies" + this.identifier + ".db";
    }


    /***********************************************************
    ***********************************************************/
    public void reset_network_access_manager () {
        if (!this.credentials || !this.soup_session) {
            return;
        }

        GLib.debug ("Resetting QNAM");
        Soup.CookieJar jar = this.soup_session.add_feature ();
        Soup.ProxyResolverDefault proxy = this.soup_session.add_feature ();

        // Use a unowned to allow locking the life of the QNAM on the stack.
        // Make it call delete_later to make sure that we can return to any QNAM stack frames safely.
        this.soup_session = new /*unowned*/ Soup.Session (this.credentials.create_qnam (), GLib.Object.delete_later);

        this.soup_session.add_feature (jar); // takes ownership of the old cookie jar
        this.soup_session.add_feature (proxy);   // Remember proxy (issue #2108)

        this.soup_session.signal_ssl_errors.connect (
            this.on_signal_handle_ssl_errors
        );
        Account.signal_proxy_authentication_required.connect (
            this.soup_session.proxy_authentication_required
        );
    }


    /***********************************************************
    ***********************************************************/
    public Soup.Session network_access_manager () {
        return this.soup_session;
    }


    /***********************************************************
    ***********************************************************/
    public unowned Soup.Session shared_network_access_manager () {
        return this.soup_session;
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
            credentials.user () + app_password,
            this.identifier
        );

        var read_password_job = new ReadPasswordJob (Theme.app_name);
        read_password_job.insecure_fallback (false);
        read_password_job.key (kck);
        read_password_job.signal_finished.connect (
            this.on_signal_read_password_job_finished
        );
        read_password_job.start ();
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
        if (this.identifier == "" || app_password == "")
            return;

        const string kck = AbstractCredentials.keychain_key (
                    url ().to_string (),
                    this.dav_user + app_password,
                    this.identifier
        );

        var write_password_job = new WritePasswordJob (Theme.app_name);
        write_password_job.insecure_fallback (false);
        write_password_job.key (kck);
        write_password_job.binary_data (app_password.to_latin1 ());
        write_password_job.signal_finished.connect (
            this.on_signal_write_password_job_finished
        );
        write_password_job.start ();
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
        delete_app_token_job.signal_finished.connect (
            this.on_signal_delete_job_finished
        );
        delete_app_token_job.start ();
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
        if (direct_editing_url == "" || direct_editing_e_tag == "")
            return;

        // Check for the direct_editing capability
        if (!direct_editing_url == "" &&
            (direct_editing_e_tag == "" || direct_editing_e_tag != this.last_direct_editing_e_tag)) {
                // Fetch the available editors and their mime types
                var json_api_job = new JsonApiJob (shared_from_this (), "ocs/v2.php/apps/files/api/v1/direct_editing");
                json_api_job.signal_json_received.connect (
                    this.on_signal_json_api_job_direct_editing_recieved
                );
                json_api_job.start ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void set_up_user_status_connector () {
        this.user_status_connector = shared_from_this ();
        this.user_status_connector.signal_user_status_fetched.connect (
            this.on_signal_user_status_connector_user_status_fetched
        );
        this.user_status_connector.signal_message_cleared.connect (
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
        this.soup_session.clear_access_cache ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_handle_ssl_errors (GLib.InputStream reply, GLib.List<GnuTLS.ErrorCode> errors) {
        NetworkJobTimeoutPauser pauser = new NetworkJobTimeoutPauser (reply);
        GLib.debug ("SSL-Errors happened for url " + reply.url.to_string ());
        foreach (GnuTLS.ErrorCode error in errors) {
            GLib.debug ("\t_error in " + error.certificate () + ":"
                        + error.error_string () + " (" + error.error () + ")"
                        + "\n");
        }

        //  GLib.info ("ssl errors" + output);
        GLib.info (reply.ssl_configuration ().peer_certificate_chain ());

        bool all_previously_rejected = true;
        foreach (GnuTLS.ErrorCode error in errors) {
            if (!this.rejected_certificates.contains (error.certificate ())) {
                all_previously_rejected = false;
            }
        }

        // If all certificates have previously been rejected by the user, don't ask again.
        if (all_previously_rejected) {
            GLib.info (output + "Certs not trusted by user decision, returning.");
            return;
        }

        GLib.List<GLib.TlsCertificate> approved_certificates;
        if (this.ssl_error_handler.is_null ()) {
            GLib.warning (output + "called without valid SSL error handler for account" + url ());
            return;
        }

        // SslDialogErrorHandler.handle_errors will run an event loop that might execute
        // the delete_later () of the QNAM before we have the chance of unwinding our stack.
        // Keep a ref here on our stackframe to make sure that it doesn't get deleted before
        // handle_errors returns.
        unowned Soup.Session qnam_lock = this.soup_session;
        QPointer<GLib.Object> guard = reply;

        if (this.ssl_error_handler.handle_errors (errors, reply.ssl_configuration (), approved_certificates, shared_from_this ())) {
            if (!guard)
                return;

            if (!approved_certificates == "") {
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
            foreach (GnuTLS.ErrorCode error in errors) {
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
        if (this.dav_user == "") {
            GLib.debug ("User identifier not set. Fetch it.");
            var fetch_user_name_job = new JsonApiJob (shared_from_this (), "/ocs/v1.php/cloud/user");
            fetch_user_name_job.signal_json_received.connect (
                this.on_signal_json_api_job_user_name_fetched
            );
            fetch_user_name_job.start ();
        } else {
            GLib.debug ("User identifier already fetched.");
            /* emit */ signal_credentials_fetched (this.credentials);
        }
    }


    private void on_signal_json_api_job_user_name_fetched (JsonApiJob fetch_user_name_job, QJsonDocument json, int status_code) {
        fetch_user_name_job.delete_later ();
        if (status_code != 100) {
            GLib.warning ("Could not fetch user identifier. Login will probably not work.");
            /* emit */ signal_credentials_fetched (this.credentials);
            return;
        }

        var obj_data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
        var user_id = obj_data.value ("identifier").to_string ();
        this.dav_user = user_id;
        /* emit */ signal_credentials_fetched (this.credentials);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_credentials_asked () {
        /* emit */ signal_credentials_asked (this.credentials);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_json_api_job_direct_editing_recieved (QJsonDocument json) {
        var data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
        var editors = data.value ("editors").to_object ();

        foreach (var editor_key in editors.keys ()) {
            var editor = editors.value (editor_key).to_object ();

            const string identifier = editor.value ("identifier").to_string ();
            const string name = editor.value ("name").to_string ();

            if (!identifier == "" && !name == "") {
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
