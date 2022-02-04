/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QSettings>
//  #include <QTimer>
//  #include <qfontmetrics.h>
//  #include
//  #include <QJsonDocumen
//  #include <QJsonObject
//  #include <QJsonArray>
//  #include <QNetworkR
//  #include <QBuffer>
//  #include
//  #include <QElapsedTimer>
//  #include <QPointer>
//  #include
//  #include <memory>


namespace Occ {

using AccountStatePtr = unowned<AccountState>;
using AccountAppList = GLib.List<AccountApp>;

/***********************************************************
@brief Extra info about an own_cloud server account.
@ingroup gui
***********************************************************/
class AccountState : GLib.Object, public QSharedData {
    //  Q_PROPERTY (AccountPointer account MEMBER this.account)

    /***********************************************************
    ***********************************************************/
    public enum State {
        /***********************************************************
        Not even attempting to connect, most likely because the
        user explicitly signed out or cancelled a credential dialog.
        ***********************************************************/
        SignedOut,

        /***********************************************************
        Account would like to be connected but hasn't heard back yet.
        ***********************************************************/
        Disconnected,

        /***********************************************************
        The account is successfully talking to the server.
        ***********************************************************/
        Connected,

        /***********************************************************
        There's a temporary problem with talking to the server,
        don't bother the user too much and try again.
        ***********************************************************/
        ServiceUnavailable,

        /***********************************************************
        Similar to ServiceUnavailable, but we know the server is
        down for maintenance
        ***********************************************************/
        MaintenanceMode,

        /***********************************************************
        Could not communicate with the server for some reason.
        We assume this may resolve itself over time and will try
        again automatically.
        ***********************************************************/
        NetworkError,

        /***********************************************************
        Server configuration error. (For example: unsupported version)
        ***********************************************************/
        ConfigurationError,

        /***********************************************************
        We are currently asking the user for credentials
        ***********************************************************/
        AskingCredentials
    };


    /***********************************************************
    The actual current connectivity status.
    ***********************************************************/
    public using ConnectionStatus = ConnectionValidator.Status;


    /***********************************************************
    Use the account as parent
    ***********************************************************/
    public AccountState (AccountPointer account);
    ~AccountState () override;


    /***********************************************************
    Creates an account state from settings and an Account object.

    Use from AccountManager with a prepared QSettings object only.
    ***********************************************************/
    public static AccountState load_from_settings (AccountPointer account, QSettings settings);


    /***********************************************************
    Writes account state information to settings.

    It does not write the Account data.
    ***********************************************************/
    public void write_to_settings (QSettings settings);

    /***********************************************************
    ***********************************************************/
    public AccountPointer account ();

    /***********************************************************
    ***********************************************************/
    public ConnectionStatus connection_status ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public static string state_st

    /***********************************************************
    ***********************************************************/
    public bool is_signed_out ();

    /***********************************************************
    ***********************************************************/
    public AccountAppList app_list ();


    public AccountApp* find_app (string app_id);


    /***********************************************************
    A user-triggered sign out which disconnects, stops syncs
    for the account and forgets the password.
    ***********************************************************/
    public void sign_out_by_ui ();


    /***********************************************************
    Tries to connect from scratch.

    Does nothing for signed out accounts.
    Connected accounts will be disconnected and try anew.
    Disconnected accounts will go to on_check_connectivity ().

    Useful for when network settings (proxy) change.
    ***********************************************************/
    public void fresh_connection_attempt ();


    /***********************************************************
    Move from SignedOut state to Disconnected (attempting to connect)
    public void sign_in ();

    /***********************************************************
    ***********************************************************/
    public bool is_connected ();


    /***********************************************************
    Returns a new settings object for this account, already in the right groups.
    ***********************************************************/
    public std.unique_ptr<QSettings> settings ();


    /***********************************************************
    Mark the timestamp when the last successful ETag check happened for
    this account.
    The on_check_connectivity () method uses the timestamp to save a call to
    the server to validate the connection if the last successful etag job
    was not so long ago.
    ***********************************************************/
    public void tag_last_successfull_e_tag_request (GLib.DateTime tp);


    /***********************************************************
    Saves the ETag Response header from the last Notifications api
    request with status_code 200.
    ***********************************************************/
    public GLib.ByteArray notifications_etag_response_header ();


    /***********************************************************
    Returns the ETag Response header from the last Notifications api
    request with status_code 200.
    ***********************************************************/
    void set_notifications_etag_response_header (GLib.ByteArray value);


    /***********************************************************
    Saves the ETag Response header from the last Navigation Apps api
    request with status_code 200.
    ***********************************************************/
    public GLib.ByteArray navigation_apps_etag_response_header ();


    /***********************************************************
    Returns the ETag Response header from the last Navigation Apps api
    request with status_code 200.
    ***********************************************************/
    public void set_navigation_apps_etag_response_header (GLib.ByteArray value);


    /***********************************************************
    Asks for user credentials
    ***********************************************************/
    public void handle_invalid_credentials ();


    /***********************************************************
    Returns the notifications status retrieved by the notificatons endpoint
    https://github.com/nextcloud/desktop/issues/2318#issuecomment-680698429
    ***********************************************************/
    public bool is_desktop_notifications_allowed ();


    /***********************************************************
    Set desktop notifications status retrieved by the notificatons endpoint
    ***********************************************************/
    public void set_desktop_notifications_allowed (bool is_allowed);


    /***********************************************************
    Triggers a ping to the server to update state and
    connection status and errors.
    ***********************************************************/
    public void on_check_connectivity ();

    /***********************************************************
    ***********************************************************/
    private void set_state (State state);
    private void fetch_navigation_apps ();


    signal void state_changed (State state);
    signal void is_connected_changed ();
    signal void has_fetched_navigation_apps ();
    signal void status_changed ();
    signal void desktop_notifications_allowed_changed ();

    protected void on_connection_validator_result (ConnectionValidator.Status status, string[] errors);


    /***********************************************************
    When client gets a 401 or 403 checks if server requested remote wipe
    before asking for user credentials again
    ***********************************************************/
    protected void on_handle_remote_wipe_check ();

    protected void on_credentials_fetched (AbstractCredentials creds);
    protected void on_credentials_asked (AbstractCredentials creds);

    protected void on_navigation_apps_fetched (QJsonDocument reply, int status_code);
    protected void on_etag_response_header_received (GLib.ByteArray value, int status_code);
    protected void on_ocs_error (int status_code, string message);


    /***********************************************************
    ***********************************************************/
    private AccountPointer this.account;
    private State this.state;
    private ConnectionStatus this.connection_status;
    private string[] this.connection_errors;
    private bool this.waiting_for_new_credentials;
    private GLib.DateTime this.time_of_last_e_tag_check;
    private QPointer<ConnectionValidator> this.connection_validator;
    private GLib.ByteArray this.notifications_etag_response_header;
    private GLib.ByteArray this.navigation_apps_etag_response_header;


    /***********************************************************
    Starts counting when the server starts being back up after 503 or
    maintenance mode. The account will only become connected once this
    timer exceeds the this.maintenance_to_connected_delay value.
    ***********************************************************/
    private QElapsedTimer this.time_since_maintenance_over;


    /***********************************************************
    Milliseconds for which to delay reconnection after 503/maintenance.
    ***********************************************************/
    private int this.maintenance_to_connected_delay;


    /***********************************************************
    Connects remote wipe check with the account
    the log out triggers the check (loads app password . create request)
    ***********************************************************/
    private RemoteWipe this.remote_wipe;


    /***********************************************************
    Holds the App names and URLs available on the server
    ***********************************************************/
    private AccountAppList this.apps;

    /***********************************************************
    ***********************************************************/
    private bool this.is_desktop_notifications_allowed;
}

    AccountState.AccountState (AccountPointer account)
        : GLib.Object ()
        this.account (account)
        this.state (AccountState.Disconnected)
        this.connection_status (ConnectionValidator.Undefined)
        this.waiting_for_new_credentials (false)
        this.maintenance_to_connected_delay (60000 + (qrand () % (4 * 60000))) // 1-5min delay
        this.remote_wipe (new RemoteWipe (this.account))
        this.is_desktop_notifications_allowed (true) {
        q_register_meta_type<AccountState> ("AccountState*");

        connect (account.data (), &Account.invalid_credentials,
            this, &AccountState.on_handle_remote_wipe_check);
        connect (account.data (), &Account.credentials_fetched,
            this, &AccountState.on_credentials_fetched);
        connect (account.data (), &Account.credentials_asked,
            this, &AccountState.on_credentials_asked);

        connect (this, &AccountState.is_connected_changed, [=]{
            // Get the Apps available on the server if we're now connected.
            if (is_connected ()) {
                fetch_navigation_apps ();
            }
        });
    }

    AccountState.~AccountState () = default;

    AccountState *AccountState.load_from_settings (AccountPointer account, QSettings & /*settings*/) {
        var account_state = new AccountState (account);
        return account_state;
    }

    void AccountState.write_to_settings (QSettings & /*settings*/) {
    }

    AccountPointer AccountState.account () {
        return this.account;
    }

    AccountState.ConnectionStatus AccountState.connection_status () {
        return this.connection_status;
    }

    string[] AccountState.connection_errors () {
        return this.connection_errors;
    }

    AccountState.State AccountState.state () {
        return this.state;
    }

    void AccountState.set_state (State state) {
        if (this.state != state) {
            GLib.Info (lc_account_state) << "AccountState state change : "
                                   << state_string (this.state) << "." << state_string (state);
            State old_state = this.state;
            this.state = state;

            if (this.state == SignedOut) {
                this.connection_status = ConnectionValidator.Undefined;
                this.connection_errors.clear ();
            } else if (old_state == SignedOut && this.state == Disconnected) {
                // If we stop being voluntarily signed-out, try to connect and
                // auth right now!
                on_check_connectivity ();
            } else if (this.state == ServiceUnavailable) {
                // Check if we are actually down for maintenance.
                // To do this we must clear the connection validator that just
                // produced the 503. It's on_finished anyway and will delete itself.
                this.connection_validator.clear ();
                on_check_connectivity ();
            }
            if (old_state == Connected || this.state == Connected) {
                /* emit */ is_connected_changed ();
            }
        }

        // might not have changed but the underlying this.connection_errors might have
        /* emit */ state_changed (this.state);
    }

    string AccountState.state_string (State state) {
        switch (state) {
        case SignedOut:
            return _("Signed out");
        case Disconnected:
            return _("Disconnected");
        case Connected:
            return _("Connected");
        case ServiceUnavailable:
            return _("Service unavailable");
        case MaintenanceMode:
            return _("Maintenance mode");
        case NetworkError:
            return _("Network error");
        case ConfigurationError:
            return _("Configuration error");
        case AskingCredentials:
            return _("Asking Credentials");
        }
        return _("Unknown account state");
    }

    bool AccountState.is_signed_out () {
        return this.state == SignedOut;
    }

    void AccountState.sign_out_by_ui () {
        account ().credentials ().forget_sensitive_data ();
        account ().clear_cookie_jar ();
        set_state (SignedOut);
    }

    void AccountState.fresh_connection_attempt () {
        if (is_connected ())
            set_state (Disconnected);
        on_check_connectivity ();
    }

    void AccountState.sign_in () {
        if (this.state == SignedOut) {
            this.waiting_for_new_credentials = false;
            set_state (Disconnected);
        }
    }

    bool AccountState.is_connected () {
        return this.state == Connected;
    }

    void AccountState.tag_last_successfull_e_tag_request (GLib.DateTime tp) {
        this.time_of_last_e_tag_check = tp;
    }

    GLib.ByteArray AccountState.notifications_etag_response_header () {
        return this.notifications_etag_response_header;
    }

    void AccountState.set_notifications_etag_response_header (GLib.ByteArray value) {
        this.notifications_etag_response_header = value;
    }

    GLib.ByteArray AccountState.navigation_apps_etag_response_header () {
        return this.navigation_apps_etag_response_header;
    }

    void AccountState.set_navigation_apps_etag_response_header (GLib.ByteArray value) {
        this.navigation_apps_etag_response_header = value;
    }

    bool AccountState.is_desktop_notifications_allowed () {
        return this.is_desktop_notifications_allowed;
    }

    void AccountState.set_desktop_notifications_allowed (bool is_allowed) {
        if (this.is_desktop_notifications_allowed == is_allowed) {
            return;
        }

        this.is_desktop_notifications_allowed = is_allowed;
        /* emit */ desktop_notifications_allowed_changed ();
    }

    void AccountState.on_check_connectivity () {
        if (is_signed_out () || this.waiting_for_new_credentials) {
            return;
        }

        if (this.connection_validator) {
            GLib.warn (lc_account_state) << "ConnectionValidator already running, ignoring" << account ().display_name ();
            return;
        }

        // If we never fetched credentials, do that now - otherwise connection attempts
        // make little sense, we might be missing client certificates.
        if (!account ().credentials ().was_fetched ()) {
            this.waiting_for_new_credentials = true;
            account ().credentials ().fetch_from_keychain ();
            return;
        }

        // IF the account is connected the connection check can be skipped
        // if the last successful etag check job is not so long ago.
        const var polltime = std.chrono.duration_cast<std.chrono.seconds> (ConfigFile ().remote_poll_interval ());
        const var elapsed = this.time_of_last_e_tag_check.secs_to (GLib.DateTime.current_date_time_utc ());
        if (is_connected () && this.time_of_last_e_tag_check.is_valid ()
            && elapsed <= polltime.count ()) {
            GLib.debug (lc_account_state) << account ().display_name () << "The last ETag check succeeded within the last " << polltime.count () << "s (" << elapsed << "s). No connection check needed!";
            return;
        }

        var con_validator = new ConnectionValidator (AccountStatePtr (this));
        this.connection_validator = con_validator;
        connect (con_validator, &ConnectionValidator.connection_result,
            this, &AccountState.on_connection_validator_result);
        if (is_connected ()) {
            // Use a small authed propfind as a minimal ping when we're
            // already connected.
            con_validator.on_check_authentication ();
        } else {
            // Check the server and then the auth.

            // Let's try this for all OS and see if it fixes the Qt issues we have on Linux  #4720 #3888 #4051
            //#ifdef Q_OS_WIN
            // There seems to be a bug in Qt on Windows where QNAM sometimes stops
            // working correctly after the computer woke up from sleep. See #2895 #2899
            // and #2973.
            // As an attempted workaround, reset the QNAM regularly if the account is
            // disconnected.
            account ().reset_network_access_manager ();

            // If we don't reset the ssl config a second CheckServerJob can produce a
            // ssl config that does not have a sensible certificate chain.
            account ().set_ssl_configuration (QSslConfiguration ());
            //#endif
            con_validator.on_check_server_and_auth ();
        }
    }

    void AccountState.on_connection_validator_result (ConnectionValidator.Status status, string[] errors) {
        if (is_signed_out ()) {
            GLib.warn (lc_account_state) << "Signed out, ignoring" << status << this.account.url ().to_string ();
            return;
        }

        // Come online gradually from 503 or maintenance mode
        if (status == ConnectionValidator.Connected
            && (this.connection_status == ConnectionValidator.ServiceUnavailable
                || this.connection_status == ConnectionValidator.MaintenanceMode)) {
            if (!this.time_since_maintenance_over.is_valid ()) {
                GLib.Info (lc_account_state) << "AccountState reconnection : delaying for"
                                       << this.maintenance_to_connected_delay << "ms";
                this.time_since_maintenance_over.on_start ();
                QTimer.single_shot (this.maintenance_to_connected_delay + 100, this, &AccountState.on_check_connectivity);
                return;
            } else if (this.time_since_maintenance_over.elapsed () < this.maintenance_to_connected_delay) {
                GLib.Info (lc_account_state) << "AccountState reconnection : only"
                                       << this.time_since_maintenance_over.elapsed () << "ms have passed";
                return;
            }
        }

        if (this.connection_status != status) {
            GLib.Info (lc_account_state) << "AccountState connection status change : "
                                   << this.connection_status << "."
                                   << status;
            this.connection_status = status;
        }
        this.connection_errors = errors;

        switch (status) {
        case ConnectionValidator.Connected:
            if (this.state != Connected) {
                set_state (Connected);

                // Get the Apps available on the server.
                fetch_navigation_apps ();

                // Setup push notifications after a successful connection
                account ().try_setup_push_notifications ();
            }
            break;
        case ConnectionValidator.Undefined:
        case ConnectionValidator.NotConfigured:
            set_state (Disconnected);
            break;
        case ConnectionValidator.ServerVersionMismatch:
            set_state (ConfigurationError);
            break;
        case ConnectionValidator.StatusNotFound:
            // This can happen either because the server does not exist
            // or because we are having network issues. The latter one is
            // much more likely, so keep trying to connect.
            set_state (NetworkError);
            break;
        case ConnectionValidator.CredentialsWrong:
        case ConnectionValidator.CredentialsNotReady:
            handle_invalid_credentials ();
            break;
        case ConnectionValidator.SslError:
            set_state (SignedOut);
            break;
        case ConnectionValidator.ServiceUnavailable:
            this.time_since_maintenance_over.invalidate ();
            set_state (ServiceUnavailable);
            break;
        case ConnectionValidator.MaintenanceMode:
            this.time_since_maintenance_over.invalidate ();
            set_state (MaintenanceMode);
            break;
        case ConnectionValidator.Timeout:
            set_state (NetworkError);
            break;
        }
    }

    void AccountState.on_handle_remote_wipe_check () {
        // make sure it changes account state and icons
        sign_out_by_ui ();

        GLib.Info (lc_account_state) << "Invalid credentials for" << this.account.url ().to_string ()
                               << "checking for remote wipe request";

        this.waiting_for_new_credentials = false;
        set_state (SignedOut);
    }

    void AccountState.handle_invalid_credentials () {
        if (is_signed_out () || this.waiting_for_new_credentials)
            return;

        GLib.Info (lc_account_state) << "Invalid credentials for" << this.account.url ().to_string ()
                               << "asking user";

        this.waiting_for_new_credentials = true;
        set_state (AskingCredentials);

        if (account ().credentials ().ready ()) {
            account ().credentials ().invalidate_token ();
        }
        if (var creds = qobject_cast<HttpCredentials> (account ().credentials ())) {
            if (creds.refresh_access_token ())
                return;
        }
        account ().credentials ().ask_from_user ();
    }

    void AccountState.on_credentials_fetched (AbstractCredentials *) {
        // Make a connection attempt, no matter whether the credentials are
        // ready or not - we want to check whether we can get an SSL connection
        // going before bothering the user for a password.
        GLib.Info (lc_account_state) << "Fetched credentials for" << this.account.url ().to_string ()
                               << "attempting to connect";
        this.waiting_for_new_credentials = false;
        on_check_connectivity ();
    }

    void AccountState.on_credentials_asked (AbstractCredentials credentials) {
        GLib.Info (lc_account_state) << "Credentials asked for" << this.account.url ().to_string ()
                               << "are they ready?" << credentials.ready ();

        this.waiting_for_new_credentials = false;

        if (!credentials.ready ()) {
            // User canceled the connection or did not give a password
            set_state (SignedOut);
            return;
        }

        if (this.connection_validator) {
            // When new credentials become available we always want to restart the
            // connection validation, even if it's currently running.
            this.connection_validator.delete_later ();
            this.connection_validator = null;
        }

        on_check_connectivity ();
    }

    std.unique_ptr<QSettings> AccountState.settings () {
        var s = ConfigFile.settings_with_group (QLatin1String ("Accounts"));
        s.begin_group (this.account.identifier ());
        return s;
    }

    void AccountState.fetch_navigation_apps (){
        var job = new OcsNavigationAppsJob (this.account);
        job.add_raw_header ("If-None-Match", navigation_apps_etag_response_header ());
        connect (job, &OcsNavigationAppsJob.apps_job_finished, this, &AccountState.on_navigation_apps_fetched);
        connect (job, &OcsNavigationAppsJob.etag_response_header_received, this, &AccountState.on_etag_response_header_received);
        connect (job, &OcsNavigationAppsJob.ocs_error, this, &AccountState.on_ocs_error);
        job.get_navigation_apps ();
    }

    void AccountState.on_etag_response_header_received (GLib.ByteArray value, int status_code){
        if (status_code == 200){
            GLib.debug (lc_account_state) << "New navigation apps ETag Response Header received " << value;
            set_navigation_apps_etag_response_header (value);
        }
    }

    void AccountState.on_ocs_error (int status_code, string message) {
        GLib.debug (lc_account_state) << "Error " << status_code << " while fetching new navigation apps : " << message;
    }

    void AccountState.on_navigation_apps_fetched (QJsonDocument reply, int status_code) {
        if (this.account){
            if (status_code == 304) {
                GLib.warn (lc_account_state) << "Status code " << status_code << " Not Modified - No new navigation apps.";
            } else {
                this.apps.clear ();

                if (!reply.is_empty ()){
                    var element = reply.object ().value ("ocs").to_object ().value ("data");
                    const var nav_links = element.to_array ();

                    if (nav_links.size () > 0){
                        for (QJsonValue value : nav_links) {
                            var nav_link = value.to_object ();

                            var app = new AccountApp (nav_link.value ("name").to_string (), GLib.Uri (nav_link.value ("href").to_string ()),
                                nav_link.value ("identifier").to_string (), GLib.Uri (nav_link.value ("icon").to_string ()));

                            this.apps << app;
                        }
                    }
                }

                /* emit */ has_fetched_navigation_apps ();
            }
        }
    }

    AccountAppList AccountState.app_list () {
        return this.apps;
    }

    AccountApp* AccountState.find_app (string app_id) {
        if (!app_id.is_empty ()) {
            const var apps = app_list ();
            const var it = std.find_if (apps.cbegin (), apps.cend (), [app_id] (var app) {
                return app.identifier () == app_id;
            });
            if (it != apps.cend ()) {
                return it;
            }
        }

        return null;
    }



} // namespace Occ
    