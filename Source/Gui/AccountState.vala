/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QByteArray>
// #include <QElapsedTimer>
// #include <QPointer>

// #include <memory>


namespace Occ {

class RemoteWipe;

using AccountStatePtr = QExplicitlySharedDataPointer<AccountState>;
using AccountAppList = QList<AccountApp>;

/***********************************************************
@brief Extra info about an ownCloud server account.
@ingroup gui
***********************************************************/
class AccountState : GLib.Object, public QSharedData {
    Q_PROPERTY (AccountPtr account MEMBER _account)

public:
    enum State {
        /// Not even attempting to connect, most likely because the
        /// user explicitly signed out or cancelled a credential dialog.
        SignedOut,

        /// Account would like to be connected but hasn't heard back yet.
        Disconnected,

        /// The account is successfully talking to the server.
        Connected,

        /// There's a temporary problem with talking to the server,
        /// don't bother the user too much and try again.
        ServiceUnavailable,

        /// Similar to ServiceUnavailable, but we know the server is down
        /// for maintenance
        MaintenanceMode,

        /// Could not communicate with the server for some reason.
        /// We assume this may resolve itself over time and will try
        /// again automatically.
        NetworkError,

        /// Server configuration error. (For example : unsupported version)
        ConfigurationError,

        /// We are currently asking the user for credentials
        AskingCredentials
    };

    /// The actual current connectivity status.
    using ConnectionStatus = ConnectionValidator.Status;

    /// Use the account as parent
    AccountState (AccountPtr account);
    ~AccountState () override;

    /** Creates an account state from settings and an Account object.
     *
     * Use from AccountManager with a prepared QSettings object only.
     */
    static AccountState *loadFromSettings (AccountPtr account, QSettings &settings);

    /** Writes account state information to settings.
     *
     * It does not write the Account data.
     */
    void writeToSettings (QSettings &settings);

    AccountPtr account ();

    ConnectionStatus connectionStatus ();
    QStringList connectionErrors ();

    State state ();
    static string stateString (State state);

    bool isSignedOut ();

    AccountAppList appList ();
    AccountApp* findApp (string &appId) const;

    /** A user-triggered sign out which disconnects, stops syncs
     * for the account and forgets the password. */
    void signOutByUi ();

    /** Tries to connect from scratch.
     *
     * Does nothing for signed out accounts.
     * Connected accounts will be disconnected and try anew.
     * Disconnected accounts will go to checkConnectivity ().
     *
     * Useful for when network settings (proxy) change.
     */
    void freshConnectionAttempt ();

    /// Move from SignedOut state to Disconnected (attempting to connect)
    void signIn ();

    bool isConnected ();

    /** Returns a new settings object for this account, already in the right groups. */
    std.unique_ptr<QSettings> settings ();

    /** Mark the timestamp when the last successful ETag check happened for
     *  this account.
     *  The checkConnectivity () method uses the timestamp to save a call to
     *  the server to validate the connection if the last successful etag job
     *  was not so long ago.
     */
    void tagLastSuccessfullETagRequest (QDateTime &tp);

    /** Saves the ETag Response header from the last Notifications api
     * request with statusCode 200.
    */
    QByteArray notificationsEtagResponseHeader ();

    /** Returns the ETag Response header from the last Notifications api
     * request with statusCode 200.
    */
    void setNotificationsEtagResponseHeader (QByteArray &value);

    /** Saves the ETag Response header from the last Navigation Apps api
     * request with statusCode 200.
    */
    QByteArray navigationAppsEtagResponseHeader ();

    /** Returns the ETag Response header from the last Navigation Apps api
     * request with statusCode 200.
    */
    void setNavigationAppsEtagResponseHeader (QByteArray &value);

    ///Asks for user credentials
    void handleInvalidCredentials ();

    /** Returns the notifications status retrieved by the notificatons endpoint
     *  https://github.com/nextcloud/desktop/issues/2318#issuecomment-680698429
    */
    bool isDesktopNotificationsAllowed ();

    /** Set desktop notifications status retrieved by the notificatons endpoint
    */
    void setDesktopNotificationsAllowed (bool isAllowed);

public slots:
    /// Triggers a ping to the server to update state and
    /// connection status and errors.
    void checkConnectivity ();

private:
    void setState (State state);
    void fetchNavigationApps ();

signals:
    void stateChanged (State state);
    void isConnectedChanged ();
    void hasFetchedNavigationApps ();
    void statusChanged ();
    void desktopNotificationsAllowedChanged ();

protected slots:
    void slotConnectionValidatorResult (ConnectionValidator.Status status, QStringList &errors);

    /// When client gets a 401 or 403 checks if server requested remote wipe
    /// before asking for user credentials again
    void slotHandleRemoteWipeCheck ();

    void slotCredentialsFetched (AbstractCredentials *creds);
    void slotCredentialsAsked (AbstractCredentials *creds);

    void slotNavigationAppsFetched (QJsonDocument &reply, int statusCode);
    void slotEtagResponseHeaderReceived (QByteArray &value, int statusCode);
    void slotOcsError (int statusCode, string &message);

private:
    AccountPtr _account;
    State _state;
    ConnectionStatus _connectionStatus;
    QStringList _connectionErrors;
    bool _waitingForNewCredentials;
    QDateTime _timeOfLastETagCheck;
    QPointer<ConnectionValidator> _connectionValidator;
    QByteArray _notificationsEtagResponseHeader;
    QByteArray _navigationAppsEtagResponseHeader;

    /***********************************************************
     * Starts counting when the server starts being back up after 503 or
     * maintenance mode. The account will only become connected once this
     * timer exceeds the _maintenanceToConnectedDelay value.
     */
    QElapsedTimer _timeSinceMaintenanceOver;

    /***********************************************************
     * Milliseconds for which to delay reconnection after 503/maintenance.
     */
    int _maintenanceToConnectedDelay;

    /***********************************************************
     * Connects remote wipe check with the account
     * the log out triggers the check (loads app password . create request)
     */
    RemoteWipe *_remoteWipe;

    /***********************************************************
     * Holds the App names and URLs available on the server
     */
    AccountAppList _apps;

    bool _isDesktopNotificationsAllowed;
};

class AccountApp : GLib.Object {
public:
    AccountApp (string &name, QUrl &url,
        const string &id, QUrl &iconUrl,
        GLib.Object* parent = nullptr);

    string name ();
    QUrl url ();
    string id ();
    QUrl iconUrl ();

private:
    string _name;
    QUrl _url;

    string _id;
    QUrl _iconUrl;
};

}

Q_DECLARE_METATYPE (Occ.AccountState *)
Q_DECLARE_METATYPE (Occ.AccountStatePtr)

#endif //ACCOUNTINFO_H







/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QSettings>
// #include <QTimer>
// #include <qfontmetrics.h>

// #include <QJsonDocument>
// #include <QJsonObject>
// #include <QJsonArray>
// #include <QNetworkRequest>
// #include <QBuffer>

namespace Occ {

    Q_LOGGING_CATEGORY (lcAccountState, "nextcloud.gui.account.state", QtInfoMsg)
    
    AccountState.AccountState (AccountPtr account)
        : GLib.Object ()
        , _account (account)
        , _state (AccountState.Disconnected)
        , _connectionStatus (ConnectionValidator.Undefined)
        , _waitingForNewCredentials (false)
        , _maintenanceToConnectedDelay (60000 + (qrand () % (4 * 60000))) // 1-5min delay
        , _remoteWipe (new RemoteWipe (_account))
        , _isDesktopNotificationsAllowed (true) {
        qRegisterMetaType<AccountState> ("AccountState*");
    
        connect (account.data (), &Account.invalidCredentials,
            this, &AccountState.slotHandleRemoteWipeCheck);
        connect (account.data (), &Account.credentialsFetched,
            this, &AccountState.slotCredentialsFetched);
        connect (account.data (), &Account.credentialsAsked,
            this, &AccountState.slotCredentialsAsked);
    
        connect (this, &AccountState.isConnectedChanged, [=]{
            // Get the Apps available on the server if we're now connected.
            if (isConnected ()) {
                fetchNavigationApps ();
            }
        });
    }
    
    AccountState.~AccountState () = default;
    
    AccountState *AccountState.loadFromSettings (AccountPtr account, QSettings & /*settings*/) {
        auto accountState = new AccountState (account);
        return accountState;
    }
    
    void AccountState.writeToSettings (QSettings & /*settings*/) {
    }
    
    AccountPtr AccountState.account () {
        return _account;
    }
    
    AccountState.ConnectionStatus AccountState.connectionStatus () {
        return _connectionStatus;
    }
    
    QStringList AccountState.connectionErrors () {
        return _connectionErrors;
    }
    
    AccountState.State AccountState.state () {
        return _state;
    }
    
    void AccountState.setState (State state) {
        if (_state != state) {
            qCInfo (lcAccountState) << "AccountState state change : "
                                   << stateString (_state) << "." << stateString (state);
            State oldState = _state;
            _state = state;
    
            if (_state == SignedOut) {
                _connectionStatus = ConnectionValidator.Undefined;
                _connectionErrors.clear ();
            } else if (oldState == SignedOut && _state == Disconnected) {
                // If we stop being voluntarily signed-out, try to connect and
                // auth right now!
                checkConnectivity ();
            } else if (_state == ServiceUnavailable) {
                // Check if we are actually down for maintenance.
                // To do this we must clear the connection validator that just
                // produced the 503. It's finished anyway and will delete itself.
                _connectionValidator.clear ();
                checkConnectivity ();
            }
            if (oldState == Connected || _state == Connected) {
                emit isConnectedChanged ();
            }
        }
    
        // might not have changed but the underlying _connectionErrors might have
        emit stateChanged (_state);
    }
    
    string AccountState.stateString (State state) {
        switch (state) {
        case SignedOut:
            return tr ("Signed out");
        case Disconnected:
            return tr ("Disconnected");
        case Connected:
            return tr ("Connected");
        case ServiceUnavailable:
            return tr ("Service unavailable");
        case MaintenanceMode:
            return tr ("Maintenance mode");
        case NetworkError:
            return tr ("Network error");
        case ConfigurationError:
            return tr ("Configuration error");
        case AskingCredentials:
            return tr ("Asking Credentials");
        }
        return tr ("Unknown account state");
    }
    
    bool AccountState.isSignedOut () {
        return _state == SignedOut;
    }
    
    void AccountState.signOutByUi () {
        account ().credentials ().forgetSensitiveData ();
        account ().clearCookieJar ();
        setState (SignedOut);
    }
    
    void AccountState.freshConnectionAttempt () {
        if (isConnected ())
            setState (Disconnected);
        checkConnectivity ();
    }
    
    void AccountState.signIn () {
        if (_state == SignedOut) {
            _waitingForNewCredentials = false;
            setState (Disconnected);
        }
    }
    
    bool AccountState.isConnected () {
        return _state == Connected;
    }
    
    void AccountState.tagLastSuccessfullETagRequest (QDateTime &tp) {
        _timeOfLastETagCheck = tp;
    }
    
    QByteArray AccountState.notificationsEtagResponseHeader () {
        return _notificationsEtagResponseHeader;
    }
    
    void AccountState.setNotificationsEtagResponseHeader (QByteArray &value) {
        _notificationsEtagResponseHeader = value;
    }
    
    QByteArray AccountState.navigationAppsEtagResponseHeader () {
        return _navigationAppsEtagResponseHeader;
    }
    
    void AccountState.setNavigationAppsEtagResponseHeader (QByteArray &value) {
        _navigationAppsEtagResponseHeader = value;
    }
    
    bool AccountState.isDesktopNotificationsAllowed () {
        return _isDesktopNotificationsAllowed;
    }
    
    void AccountState.setDesktopNotificationsAllowed (bool isAllowed) {
        if (_isDesktopNotificationsAllowed == isAllowed) {
            return;
        }
    
        _isDesktopNotificationsAllowed = isAllowed;
        emit desktopNotificationsAllowedChanged ();
    }
    
    void AccountState.checkConnectivity () {
        if (isSignedOut () || _waitingForNewCredentials) {
            return;
        }
    
        if (_connectionValidator) {
            qCWarning (lcAccountState) << "ConnectionValidator already running, ignoring" << account ().displayName ();
            return;
        }
    
        // If we never fetched credentials, do that now - otherwise connection attempts
        // make little sense, we might be missing client certs.
        if (!account ().credentials ().wasFetched ()) {
            _waitingForNewCredentials = true;
            account ().credentials ().fetchFromKeychain ();
            return;
        }
    
        // IF the account is connected the connection check can be skipped
        // if the last successful etag check job is not so long ago.
        const auto polltime = std.chrono.duration_cast<std.chrono.seconds> (ConfigFile ().remotePollInterval ());
        const auto elapsed = _timeOfLastETagCheck.secsTo (QDateTime.currentDateTimeUtc ());
        if (isConnected () && _timeOfLastETagCheck.isValid ()
            && elapsed <= polltime.count ()) {
            qCDebug (lcAccountState) << account ().displayName () << "The last ETag check succeeded within the last " << polltime.count () << "s (" << elapsed << "s). No connection check needed!";
            return;
        }
    
        auto *conValidator = new ConnectionValidator (AccountStatePtr (this));
        _connectionValidator = conValidator;
        connect (conValidator, &ConnectionValidator.connectionResult,
            this, &AccountState.slotConnectionValidatorResult);
        if (isConnected ()) {
            // Use a small authed propfind as a minimal ping when we're
            // already connected.
            conValidator.checkAuthentication ();
        } else {
            // Check the server and then the auth.
    
            // Let's try this for all OS and see if it fixes the Qt issues we have on Linux  #4720 #3888 #4051
            //#ifdef Q_OS_WIN
            // There seems to be a bug in Qt on Windows where QNAM sometimes stops
            // working correctly after the computer woke up from sleep. See #2895 #2899
            // and #2973.
            // As an attempted workaround, reset the QNAM regularly if the account is
            // disconnected.
            account ().resetNetworkAccessManager ();
    
            // If we don't reset the ssl config a second CheckServerJob can produce a
            // ssl config that does not have a sensible certificate chain.
            account ().setSslConfiguration (QSslConfiguration ());
            //#endif
            conValidator.checkServerAndAuth ();
        }
    }
    
    void AccountState.slotConnectionValidatorResult (ConnectionValidator.Status status, QStringList &errors) {
        if (isSignedOut ()) {
            qCWarning (lcAccountState) << "Signed out, ignoring" << status << _account.url ().toString ();
            return;
        }
    
        // Come online gradually from 503 or maintenance mode
        if (status == ConnectionValidator.Connected
            && (_connectionStatus == ConnectionValidator.ServiceUnavailable
                || _connectionStatus == ConnectionValidator.MaintenanceMode)) {
            if (!_timeSinceMaintenanceOver.isValid ()) {
                qCInfo (lcAccountState) << "AccountState reconnection : delaying for"
                                       << _maintenanceToConnectedDelay << "ms";
                _timeSinceMaintenanceOver.start ();
                QTimer.singleShot (_maintenanceToConnectedDelay + 100, this, &AccountState.checkConnectivity);
                return;
            } else if (_timeSinceMaintenanceOver.elapsed () < _maintenanceToConnectedDelay) {
                qCInfo (lcAccountState) << "AccountState reconnection : only"
                                       << _timeSinceMaintenanceOver.elapsed () << "ms have passed";
                return;
            }
        }
    
        if (_connectionStatus != status) {
            qCInfo (lcAccountState) << "AccountState connection status change : "
                                   << _connectionStatus << "."
                                   << status;
            _connectionStatus = status;
        }
        _connectionErrors = errors;
    
        switch (status) {
        case ConnectionValidator.Connected:
            if (_state != Connected) {
                setState (Connected);
    
                // Get the Apps available on the server.
                fetchNavigationApps ();
    
                // Setup push notifications after a successful connection
                account ().trySetupPushNotifications ();
            }
            break;
        case ConnectionValidator.Undefined:
        case ConnectionValidator.NotConfigured:
            setState (Disconnected);
            break;
        case ConnectionValidator.ServerVersionMismatch:
            setState (ConfigurationError);
            break;
        case ConnectionValidator.StatusNotFound:
            // This can happen either because the server does not exist
            // or because we are having network issues. The latter one is
            // much more likely, so keep trying to connect.
            setState (NetworkError);
            break;
        case ConnectionValidator.CredentialsWrong:
        case ConnectionValidator.CredentialsNotReady:
            handleInvalidCredentials ();
            break;
        case ConnectionValidator.SslError:
            setState (SignedOut);
            break;
        case ConnectionValidator.ServiceUnavailable:
            _timeSinceMaintenanceOver.invalidate ();
            setState (ServiceUnavailable);
            break;
        case ConnectionValidator.MaintenanceMode:
            _timeSinceMaintenanceOver.invalidate ();
            setState (MaintenanceMode);
            break;
        case ConnectionValidator.Timeout:
            setState (NetworkError);
            break;
        }
    }
    
    void AccountState.slotHandleRemoteWipeCheck () {
        // make sure it changes account state and icons
        signOutByUi ();
    
        qCInfo (lcAccountState) << "Invalid credentials for" << _account.url ().toString ()
                               << "checking for remote wipe request";
    
        _waitingForNewCredentials = false;
        setState (SignedOut);
    }
    
    void AccountState.handleInvalidCredentials () {
        if (isSignedOut () || _waitingForNewCredentials)
            return;
    
        qCInfo (lcAccountState) << "Invalid credentials for" << _account.url ().toString ()
                               << "asking user";
    
        _waitingForNewCredentials = true;
        setState (AskingCredentials);
    
        if (account ().credentials ().ready ()) {
            account ().credentials ().invalidateToken ();
        }
        if (auto creds = qobject_cast<HttpCredentials> (account ().credentials ())) {
            if (creds.refreshAccessToken ())
                return;
        }
        account ().credentials ().askFromUser ();
    }
    
    void AccountState.slotCredentialsFetched (AbstractCredentials *) {
        // Make a connection attempt, no matter whether the credentials are
        // ready or not - we want to check whether we can get an SSL connection
        // going before bothering the user for a password.
        qCInfo (lcAccountState) << "Fetched credentials for" << _account.url ().toString ()
                               << "attempting to connect";
        _waitingForNewCredentials = false;
        checkConnectivity ();
    }
    
    void AccountState.slotCredentialsAsked (AbstractCredentials *credentials) {
        qCInfo (lcAccountState) << "Credentials asked for" << _account.url ().toString ()
                               << "are they ready?" << credentials.ready ();
    
        _waitingForNewCredentials = false;
    
        if (!credentials.ready ()) {
            // User canceled the connection or did not give a password
            setState (SignedOut);
            return;
        }
    
        if (_connectionValidator) {
            // When new credentials become available we always want to restart the
            // connection validation, even if it's currently running.
            _connectionValidator.deleteLater ();
            _connectionValidator = nullptr;
        }
    
        checkConnectivity ();
    }
    
    std.unique_ptr<QSettings> AccountState.settings () {
        auto s = ConfigFile.settingsWithGroup (QLatin1String ("Accounts"));
        s.beginGroup (_account.id ());
        return s;
    }
    
    void AccountState.fetchNavigationApps (){
        auto *job = new OcsNavigationAppsJob (_account);
        job.addRawHeader ("If-None-Match", navigationAppsEtagResponseHeader ());
        connect (job, &OcsNavigationAppsJob.appsJobFinished, this, &AccountState.slotNavigationAppsFetched);
        connect (job, &OcsNavigationAppsJob.etagResponseHeaderReceived, this, &AccountState.slotEtagResponseHeaderReceived);
        connect (job, &OcsNavigationAppsJob.ocsError, this, &AccountState.slotOcsError);
        job.getNavigationApps ();
    }
    
    void AccountState.slotEtagResponseHeaderReceived (QByteArray &value, int statusCode){
        if (statusCode == 200){
            qCDebug (lcAccountState) << "New navigation apps ETag Response Header received " << value;
            setNavigationAppsEtagResponseHeader (value);
        }
    }
    
    void AccountState.slotOcsError (int statusCode, string &message) {
        qCDebug (lcAccountState) << "Error " << statusCode << " while fetching new navigation apps : " << message;
    }
    
    void AccountState.slotNavigationAppsFetched (QJsonDocument &reply, int statusCode) {
        if (_account){
            if (statusCode == 304) {
                qCWarning (lcAccountState) << "Status code " << statusCode << " Not Modified - No new navigation apps.";
            } else {
                _apps.clear ();
    
                if (!reply.isEmpty ()){
                    auto element = reply.object ().value ("ocs").toObject ().value ("data");
                    const auto navLinks = element.toArray ();
    
                    if (navLinks.size () > 0){
                        for (QJsonValue &value : navLinks) {
                            auto navLink = value.toObject ();
    
                            auto *app = new AccountApp (navLink.value ("name").toString (), QUrl (navLink.value ("href").toString ()),
                                navLink.value ("id").toString (), QUrl (navLink.value ("icon").toString ()));
    
                            _apps << app;
                        }
                    }
                }
    
                emit hasFetchedNavigationApps ();
            }
        }
    }
    
    AccountAppList AccountState.appList () {
        return _apps;
    }
    
    AccountApp* AccountState.findApp (string &appId) {
        if (!appId.isEmpty ()) {
            const auto apps = appList ();
            const auto it = std.find_if (apps.cbegin (), apps.cend (), [appId] (auto &app) {
                return app.id () == appId;
            });
            if (it != apps.cend ()) {
                return *it;
            }
        }
    
        return nullptr;
    }
    
    /*-------------------------------------------------------------------------------------*/
    
    AccountApp.AccountApp (string &name, QUrl &url,
        const string &id, QUrl &iconUrl,
        GLib.Object *parent)
        : GLib.Object (parent)
        , _name (name)
        , _url (url)
        , _id (id)
        , _iconUrl (iconUrl) {
    }
    
    string AccountApp.name () {
        return _name;
    }
    
    QUrl AccountApp.url () {
        return _url;
    }
    
    string AccountApp.id () {
        return _id;
    }
    
    QUrl AccountApp.iconUrl () {
        return _iconUrl;
    }
    
    /*-------------------------------------------------------------------------------------*/
    
    } // namespace Occ
    