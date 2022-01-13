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

// #include <QByteArray>
// #include <QUrl>
// #include <QNetworkCookie>
// #include <QNetworkRequest>
// #include <QSslSocket>
// #include <QSslCertificate>
// #include <QSslConfiguration>
// #include <QSslCipher>
// #include <QSslError>
// #include <QSharedPointer>

#ifndef TOKEN_AUTH_ONLY
// #include <QPixmap>
#endif

Q_DECLARE_METATYPE (Occ.AccountPtr)
Q_DECLARE_METATYPE (Occ.Account *)

const char app_password[] = "_app-password";

// #include <memory>

class QNetworkAccessManager;

namespace QKeychain {
}


namespace {
    constexpr int pushNotificationsReconnectInterval = 1000 * 60 * 2;
    constexpr int usernamePrefillServerVersinMinSupportedMajor = 24;
}

namespace Occ {

using AccountPtr = QSharedPointer<Account>;
class UserStatusConnector;

/***********************************************************
@brief Reimplement this to handle SSL errors from libsync
@ingroup libsync
***********************************************************/
class AbstractSslErrorHandler {
public:
    virtual ~AbstractSslErrorHandler () = default;
    virtual bool handleErrors (QList<QSslError>, QSslConfiguration &conf, QList<QSslCertificate> *, AccountPtr) = 0;
};

/***********************************************************
@brief The Account class represents an account on an ownCloud Server
@ingroup libsync

The Account has a name and url. It also has information about credentials,
SSL errors and certificates.
***********************************************************/
class Account : GLib.Object {
    Q_PROPERTY (string id MEMBER _id)
    Q_PROPERTY (string davUser MEMBER _davUser)
    Q_PROPERTY (string displayName MEMBER _displayName)
    Q_PROPERTY (QUrl url MEMBER _url)

public:
    static AccountPtr create ();
    ~Account () override;

    AccountPtr sharedFromThis ();

    /***********************************************************
    The user that can be used in dav url.
    
    This can very well be different frome the login user that's
     * stored in credentials ().user ().
    ***********************************************************/
    string davUser ();
    void setDavUser (string &newDavUser);

    string davDisplayName ();
    void setDavDisplayName (string &newDisplayName);

#ifndef TOKEN_AUTH_ONLY
    QImage avatar ();
    void setAvatar (QImage &img);
#endif

    /// The name of the account as shown in the toolbar
    string displayName ();

    /// The internal id of the account.
    string id ();

    /***********************************************************
    Server url of the account */
    void setUrl (QUrl &url);
    QUrl url () { return _url; }

    /// Adjusts _userVisibleUrl once the host to use is discovered.
    void setUserVisibleHost (string &host);

    /***********************************************************
    @brief The possibly themed dav path for the account. It has
           a trailing slash.
    @returns the (themeable) dav path for the account.
    ***********************************************************/
    string davPath ();

    /***********************************************************
    Returns webdav entry URL, based on url () */
    QUrl davUrl ();

    /***********************************************************
    Returns the legacy permalink url for a file.

    This uses the old way of manually building the url. New code should
    use the "privatelink" property accessible via PROPFIND.
    ***********************************************************/
    QUrl deprecatedPrivateLinkUrl (QByteArray &numericFileId) const;

    /***********************************************************
    Holds the accounts credentials */
    AbstractCredentials *credentials ();
    void setCredentials (AbstractCredentials *cred);

    /***********************************************************
    Create a network request on the account's QNAM.

    Network requests in AbstractNetworkJobs are created through
    this function. Other places should prefer to use jobs or
    sendRequest ().
    ***********************************************************/
    QNetworkReply *sendRawRequest (QByteArray &verb,
        const QUrl &url,
        QNetworkRequest req = QNetworkRequest (),
        QIODevice *data = nullptr);

    QNetworkReply *sendRawRequest (QByteArray &verb,
        const QUrl &url, QNetworkRequest req, QByteArray &data);

    QNetworkReply *sendRawRequest (QByteArray &verb,
        const QUrl &url, QNetworkRequest req, QHttpMultiPart *data);

    /***********************************************************
    Create and start network job for a simple one-off request.

    More complicated requests typically create their own job types.
    ***********************************************************/
    SimpleNetworkJob *sendRequest (QByteArray &verb,
        const QUrl &url,
        QNetworkRequest req = QNetworkRequest (),
        QIODevice *data = nullptr);

    /***********************************************************
    The ssl configuration during the first connection */
    QSslConfiguration getOrCreateSslConfig ();
    QSslConfiguration sslConfiguration () { return _sslConfiguration; }
    void setSslConfiguration (QSslConfiguration &config);
    // Because of bugs in Qt, we use this to store info needed for the SSL Button
    QSslCipher _sessionCipher;
    QByteArray _sessionTicket;
    QList<QSslCertificate> _peerCertificateChain;

    /***********************************************************
    The certificates of the account */
    QList<QSslCertificate> approvedCerts () { return _approvedCerts; }
    void setApprovedCerts (QList<QSslCertificate> certs);
    void addApprovedCerts (QList<QSslCertificate> certs);

    // Usually when a user explicitly rejects a certificate we don't
    // ask again. After this call, a dialog will again be shown when
    // the next unknown certificate is encountered.
    void resetRejectedCertificates ();

    // pluggable handler
    void setSslErrorHandler (AbstractSslErrorHandler *handler);

    // To be called by credentials only, for storing username and the like
    QVariant credentialSetting (string &key) const;
    void setCredentialSetting (string &key, QVariant &value);

    /***********************************************************
    Assign a client certificate */
    void setCertificate (QByteArray certficate = QByteArray (), string privateKey = string ());

    /***********************************************************
    Access the server capabilities */
    const Capabilities &capabilities ();
    void setCapabilities (QVariantMap &caps);

    /***********************************************************
    Access the server version

    For servers >= 10.0.0, this can be the empty string until capabilities
    have been received.
    ***********************************************************/
    string serverVersion ();

    /***********************************************************
    Server version for easy comparison.

    Example : serverVersionInt () >= makeServerVersion (11, 2, 3)
    
     * Will be 0 if the version is not available yet.
    ***********************************************************/
    int serverVersionInt ();

    static int makeServerVersion (int majorVersion, int minorVersion, int patchVersion);
    void setServerVersion (string &version);

    /***********************************************************
    Whether the server is too old.

    Not supporting server versions is a gradual process. There's a hard
    compatibility limit (see ConnectionValidator) that forbids connecting
    to extremely old servers. And there's a weak "untested, not
    recommended, potentially dangerous" limit, that users might want
    to go beyond.
    
     * This function returns true if the server is beyond the weak limit.
    ***********************************************************/
    bool serverVersionUnsupported ();

    bool isUsernamePrefillSupported ();

    /***********************************************************
    True when the server connection is using HTTP2  */
    bool isHttp2Supported () { return _http2Supported; }
    void setHttp2Supported (bool value) { _http2Supported = value; }

    void clearCookieJar ();
    void lendCookieJarTo (QNetworkAccessManager *guest);
    string cookieJarPath ();

    void resetNetworkAccessManager ();
    QNetworkAccessManager *networkAccessManager ();
    QSharedPointer<QNetworkAccessManager> sharedNetworkAccessManager ();

    /// Called by network jobs on credential errors, emits invalidCredentials ()
    void handleInvalidCredentials ();

    ClientSideEncryption* e2e ();

    /// Used in RemoteWipe
    void retrieveAppPassword ();
    void writeAppPasswordOnce (string appPassword);
    void deleteAppPassword ();

    void deleteAppToken ();

    /// Direct Editing
    // Check for the directEditing capability
    void fetchDirectEditors (QUrl &directEditingURL, string &directEditingETag);

    void setupUserStatusConnector ();
    void trySetupPushNotifications ();
    PushNotifications *pushNotifications ();
    void setPushNotificationsReconnectInterval (int interval);

    std.shared_ptr<UserStatusConnector> userStatusConnector ();

public slots:
    /// Used when forgetting credentials
    void clearQNAMCache ();
    void slotHandleSslErrors (QNetworkReply *, QList<QSslError>);

signals:
    /// Emitted whenever there's network activity
    void propagatorNetworkActivity ();

    /// Triggered by handleInvalidCredentials ()
    void invalidCredentials ();

    void credentialsFetched (AbstractCredentials *credentials);
    void credentialsAsked (AbstractCredentials *credentials);

    /// Forwards from QNetworkAccessManager.proxyAuthenticationRequired ().
    void proxyAuthenticationRequired (QNetworkProxy &, QAuthenticator *);

    // e.g. when the approved SSL certificates changed
    void wantsAccountSaved (Account *acc);

    void serverVersionChanged (Account *account, string &newVersion, string &oldVersion);

    void accountChangedAvatar ();
    void accountChangedDisplayName ();

    /// Used in RemoteWipe
    void appPasswordRetrieved (string);

    void pushNotificationsReady (Account *account);
    void pushNotificationsDisabled (Account *account);

    void userStatusChanged ();

protected slots:
    void slotCredentialsFetched ();
    void slotCredentialsAsked ();
    void slotDirectEditingRecieved (QJsonDocument &json);

private:
    Account (GLib.Object *parent = nullptr);
    void setSharedThis (AccountPtr sharedThis);

    static string davPathBase ();

    QWeakPointer<Account> _sharedThis;
    string _id;
    string _davUser;
    string _displayName;
    QTimer _pushNotificationsReconnectTimer;
#ifndef TOKEN_AUTH_ONLY
    QImage _avatarImg;
#endif
    QMap<string, QVariant> _settingsMap;
    QUrl _url;

    /***********************************************************
    If url to use for any user-visible urls.

    If the server configures overwritehost this can be different from
    the connection url in _url. We retrieve the visible host through
    the ocs/v1.php/config endpoint in ConnectionValidator.
    ***********************************************************/
    QUrl _userVisibleUrl;

    QList<QSslCertificate> _approvedCerts;
    QSslConfiguration _sslConfiguration;
    Capabilities _capabilities;
    string _serverVersion;
    QScopedPointer<AbstractSslErrorHandler> _sslErrorHandler;
    QSharedPointer<QNetworkAccessManager> _am;
    QScopedPointer<AbstractCredentials> _credentials;
    bool _http2Supported = false;

    /// Certificates that were explicitly rejected by the user
    QList<QSslCertificate> _rejectedCertificates;

    static string _configFileName;

    ClientSideEncryption _e2e;

    /// Used in RemoteWipe
    bool _wroteAppPassword = false;

    friend class AccountManager;

    // Direct Editing
    string _lastDirectEditingETag;

    PushNotifications *_pushNotifications = nullptr;

    std.shared_ptr<UserStatusConnector> _userStatusConnector;

    /* IMPORTANT - remove later - FIXME MS@2019-12-07 -.
    TODO : For "Log out" & "Remove account" : Remove client CA certs and KEY!
    
          Disabled as long as selecting another cert is not supported by the UI.
    
     *       Being able to specify a new certificate is important anyway : expiry etc.

     *       We introduce this dirty hack here, to allow deleting them upon Remote Wipe.
    */
    public:
        void setRemoteWipeRequested_HACK () { _isRemoteWipeRequested_HACK = true; }
        bool isRemoteWipeRequested_HACK () { return _isRemoteWipeRequested_HACK; }
    private:
        bool _isRemoteWipeRequested_HACK = false;
    // <-- FIXME MS@2019-12-07
};

Account.Account (GLib.Object *parent)
    : GLib.Object (parent)
    , _capabilities (QVariantMap ()) {
    qRegisterMetaType<AccountPtr> ("AccountPtr");
    qRegisterMetaType<Account> ("Account*");

    _pushNotificationsReconnectTimer.setInterval (pushNotificationsReconnectInterval);
    connect (&_pushNotificationsReconnectTimer, &QTimer.timeout, this, &Account.trySetupPushNotifications);
}

AccountPtr Account.create () {
    AccountPtr acc = AccountPtr (new Account);
    acc.setSharedThis (acc);
    return acc;
}

ClientSideEncryption* Account.e2e () {
    // Qt expects everything in the connect to be a pointer, so return a pointer.
    return &_e2e;
}

Account.~Account () = default;

string Account.davPath () {
    return davPathBase () + QLatin1Char ('/') + davUser () + QLatin1Char ('/');
}

void Account.setSharedThis (AccountPtr sharedThis) {
    _sharedThis = sharedThis.toWeakRef ();
    setupUserStatusConnector ();
}

string Account.davPathBase () {
    return QStringLiteral ("/remote.php/dav/files");
}

AccountPtr Account.sharedFromThis () {
    return _sharedThis.toStrongRef ();
}

string Account.davUser () {
    return _davUser.isEmpty () && _credentials ? _credentials.user () : _davUser;
}

void Account.setDavUser (string &newDavUser) {
    if (_davUser == newDavUser)
        return;
    _davUser = newDavUser;
    emit wantsAccountSaved (this);
}

#ifndef TOKEN_AUTH_ONLY
QImage Account.avatar () {
    return _avatarImg;
}
void Account.setAvatar (QImage &img) {
    _avatarImg = img;
    emit accountChangedAvatar ();
}
#endif

string Account.displayName () {
    string dn = string ("%1@%2").arg (credentials ().user (), _url.host ());
    int port = url ().port ();
    if (port > 0 && port != 80 && port != 443) {
        dn.append (QLatin1Char (':'));
        dn.append (string.number (port));
    }
    return dn;
}

string Account.davDisplayName () {
    return _displayName;
}

void Account.setDavDisplayName (string &newDisplayName) {
    _displayName = newDisplayName;
    emit accountChangedDisplayName ();
}

string Account.id () {
    return _id;
}

AbstractCredentials *Account.credentials () {
    return _credentials.data ();
}

void Account.setCredentials (AbstractCredentials *cred) {
    // set active credential manager
    QNetworkCookieJar *jar = nullptr;
    QNetworkProxy proxy;

    if (_am) {
        jar = _am.cookieJar ();
        jar.setParent (nullptr);

        // Remember proxy (issue #2108)
        proxy = _am.proxy ();

        _am = QSharedPointer<QNetworkAccessManager> ();
    }

    // The order for these two is important! Reading the credential's
    // settings accesses the account as well as account._credentials,
    _credentials.reset (cred);
    cred.setAccount (this);

    // Note : This way the QNAM can outlive the Account and Credentials.
    // This is necessary to avoid issues with the QNAM being deleted while
    // processing slotHandleSslErrors ().
    _am = QSharedPointer<QNetworkAccessManager> (_credentials.createQNAM (), &GLib.Object.deleteLater);

    if (jar) {
        _am.setCookieJar (jar);
    }
    if (proxy.type () != QNetworkProxy.DefaultProxy) {
        _am.setProxy (proxy);
    }
    connect (_am.data (), SIGNAL (sslErrors (QNetworkReply *, QList<QSslError>)),
        SLOT (slotHandleSslErrors (QNetworkReply *, QList<QSslError>)));
    connect (_am.data (), &QNetworkAccessManager.proxyAuthenticationRequired,
        this, &Account.proxyAuthenticationRequired);
    connect (_credentials.data (), &AbstractCredentials.fetched,
        this, &Account.slotCredentialsFetched);
    connect (_credentials.data (), &AbstractCredentials.asked,
        this, &Account.slotCredentialsAsked);

    trySetupPushNotifications ();
}

void Account.setPushNotificationsReconnectInterval (int interval) {
    _pushNotificationsReconnectTimer.setInterval (interval);
}

void Account.trySetupPushNotifications () {
    // Stop the timer to prevent parallel setup attempts
    _pushNotificationsReconnectTimer.stop ();

    if (_capabilities.availablePushNotifications () != PushNotificationType.None) {
        qCInfo (lcAccount) << "Try to setup push notifications";

        if (!_pushNotifications) {
            _pushNotifications = new PushNotifications (this, this);

            connect (_pushNotifications, &PushNotifications.ready, this, [this] () {
                _pushNotificationsReconnectTimer.stop ();
                emit pushNotificationsReady (this);
            });

            const auto disablePushNotifications = [this] () {
                qCInfo (lcAccount) << "Disable push notifications object because authentication failed or connection lost";
                if (!_pushNotifications) {
                    return;
                }
                if (!_pushNotifications.isReady ()) {
                    emit pushNotificationsDisabled (this);
                }
                if (!_pushNotificationsReconnectTimer.isActive ()) {
                    _pushNotificationsReconnectTimer.start ();
                }
            };

            connect (_pushNotifications, &PushNotifications.connectionLost, this, disablePushNotifications);
            connect (_pushNotifications, &PushNotifications.authenticationFailed, this, disablePushNotifications);
        }
        // If push notifications already running it is no problem to call setup again
        _pushNotifications.setup ();
    }
}

QUrl Account.davUrl () {
    return Utility.concatUrlPath (url (), davPath ());
}

QUrl Account.deprecatedPrivateLinkUrl (QByteArray &numericFileId) {
    return Utility.concatUrlPath (_userVisibleUrl,
        QLatin1String ("/index.php/f/") + QUrl.toPercentEncoding (string.fromLatin1 (numericFileId)));
}

/***********************************************************
clear all cookies. (Session cookies or not)
***********************************************************/
void Account.clearCookieJar () {
    auto jar = qobject_cast<CookieJar> (_am.cookieJar ());
    ASSERT (jar);
    jar.setAllCookies (QList<QNetworkCookie> ());
    emit wantsAccountSaved (this);
}

/*********************************************************** This shares our official cookie jar (containing all the tasty
    authentication cookies) with another QNAM while making sure
    of not losing its ownership. */
void Account.lendCookieJarTo (QNetworkAccessManager *guest) {
    auto jar = _am.cookieJar ();
    auto oldParent = jar.parent ();
    guest.setCookieJar (jar); // takes ownership of our precious cookie jar
    jar.setParent (oldParent); // takes it back
}

string Account.cookieJarPath () {
    return QStandardPaths.writableLocation (QStandardPaths.AppConfigLocation) + "/cookies" + id () + ".db";
}

void Account.resetNetworkAccessManager () {
    if (!_credentials || !_am) {
        return;
    }

    qCDebug (lcAccount) << "Resetting QNAM";
    QNetworkCookieJar *jar = _am.cookieJar ();
    QNetworkProxy proxy = _am.proxy ();

    // Use a QSharedPointer to allow locking the life of the QNAM on the stack.
    // Make it call deleteLater to make sure that we can return to any QNAM stack frames safely.
    _am = QSharedPointer<QNetworkAccessManager> (_credentials.createQNAM (), &GLib.Object.deleteLater);

    _am.setCookieJar (jar); // takes ownership of the old cookie jar
    _am.setProxy (proxy);   // Remember proxy (issue #2108)

    connect (_am.data (), SIGNAL (sslErrors (QNetworkReply *, QList<QSslError>)),
        SLOT (slotHandleSslErrors (QNetworkReply *, QList<QSslError>)));
    connect (_am.data (), &QNetworkAccessManager.proxyAuthenticationRequired,
        this, &Account.proxyAuthenticationRequired);
}

QNetworkAccessManager *Account.networkAccessManager () {
    return _am.data ();
}

QSharedPointer<QNetworkAccessManager> Account.sharedNetworkAccessManager () {
    return _am;
}

QNetworkReply *Account.sendRawRequest (QByteArray &verb, QUrl &url, QNetworkRequest req, QIODevice *data) {
    req.setUrl (url);
    req.setSslConfiguration (this.getOrCreateSslConfig ());
    if (verb == "HEAD" && !data) {
        return _am.head (req);
    } else if (verb == "GET" && !data) {
        return _am.get (req);
    } else if (verb == "POST") {
        return _am.post (req, data);
    } else if (verb == "PUT") {
        return _am.put (req, data);
    } else if (verb == "DELETE" && !data) {
        return _am.deleteResource (req);
    }
    return _am.sendCustomRequest (req, verb, data);
}

QNetworkReply *Account.sendRawRequest (QByteArray &verb, QUrl &url, QNetworkRequest req, QByteArray &data) {
    req.setUrl (url);
    req.setSslConfiguration (this.getOrCreateSslConfig ());
    if (verb == "HEAD" && data.isEmpty ()) {
        return _am.head (req);
    } else if (verb == "GET" && data.isEmpty ()) {
        return _am.get (req);
    } else if (verb == "POST") {
        return _am.post (req, data);
    } else if (verb == "PUT") {
        return _am.put (req, data);
    } else if (verb == "DELETE" && data.isEmpty ()) {
        return _am.deleteResource (req);
    }
    return _am.sendCustomRequest (req, verb, data);
}

QNetworkReply *Account.sendRawRequest (QByteArray &verb, QUrl &url, QNetworkRequest req, QHttpMultiPart *data) {
    req.setUrl (url);
    req.setSslConfiguration (this.getOrCreateSslConfig ());
    if (verb == "PUT") {
        return _am.put (req, data);
    } else if (verb == "POST") {
        return _am.post (req, data);
    }
    return _am.sendCustomRequest (req, verb, data);
}

SimpleNetworkJob *Account.sendRequest (QByteArray &verb, QUrl &url, QNetworkRequest req, QIODevice *data) {
    auto job = new SimpleNetworkJob (sharedFromThis ());
    job.startRequest (verb, url, req, data);
    return job;
}

void Account.setSslConfiguration (QSslConfiguration &config) {
    _sslConfiguration = config;
}

QSslConfiguration Account.getOrCreateSslConfig () {
    if (!_sslConfiguration.isNull ()) {
        // Will be set by CheckServerJob.finished ()
        // We need to use a central shared config to get SSL session tickets
        return _sslConfiguration;
    }

    // if setting the client certificate fails, you will probably get an error similar to this:
    //  "An internal error number 1060 happened. SSL handshake failed, client certificate was requested : SSL error : sslv3 alert handshake failure"
    QSslConfiguration sslConfig = QSslConfiguration.defaultConfiguration ();

    // Try hard to re-use session for different requests
    sslConfig.setSslOption (QSsl.SslOptionDisableSessionTickets, false);
    sslConfig.setSslOption (QSsl.SslOptionDisableSessionSharing, false);
    sslConfig.setSslOption (QSsl.SslOptionDisableSessionPersistence, false);

    sslConfig.setOcspStaplingEnabled (Theme.instance ().enableStaplingOCSP ());

    return sslConfig;
}

void Account.setApprovedCerts (QList<QSslCertificate> certs) {
    _approvedCerts = certs;
    QSslConfiguration.defaultConfiguration ().addCaCertificates (certs);
}

void Account.addApprovedCerts (QList<QSslCertificate> certs) {
    _approvedCerts += certs;
}

void Account.resetRejectedCertificates () {
    _rejectedCertificates.clear ();
}

void Account.setSslErrorHandler (AbstractSslErrorHandler *handler) {
    _sslErrorHandler.reset (handler);
}

void Account.setUrl (QUrl &url) {
    _url = url;
    _userVisibleUrl = url;
}

void Account.setUserVisibleHost (string &host) {
    _userVisibleUrl.setHost (host);
}

QVariant Account.credentialSetting (string &key) {
    if (_credentials) {
        string prefix = _credentials.authType ();
        QVariant value = _settingsMap.value (prefix + "_" + key);
        if (value.isNull ()) {
            value = _settingsMap.value (key);
        }
        return value;
    }
    return QVariant ();
}

void Account.setCredentialSetting (string &key, QVariant &value) {
    if (_credentials) {
        string prefix = _credentials.authType ();
        _settingsMap.insert (prefix + "_" + key, value);
    }
}

void Account.slotHandleSslErrors (QNetworkReply *reply, QList<QSslError> errors) {
    NetworkJobTimeoutPauser pauser (reply);
    string out;
    QDebug (&out) << "SSL-Errors happened for url " << reply.url ().toString ();
    foreach (QSslError &error, errors) {
        QDebug (&out) << "\tError in " << error.certificate () << ":"
                     << error.errorString () << " (" << error.error () << ")"
                     << "\n";
    }

    qCInfo (lcAccount ()) << "ssl errors" << out;
    qCInfo (lcAccount ()) << reply.sslConfiguration ().peerCertificateChain ();

    bool allPreviouslyRejected = true;
    foreach (QSslError &error, errors) {
        if (!_rejectedCertificates.contains (error.certificate ())) {
            allPreviouslyRejected = false;
        }
    }

    // If all certs have previously been rejected by the user, don't ask again.
    if (allPreviouslyRejected) {
        qCInfo (lcAccount) << out << "Certs not trusted by user decision, returning.";
        return;
    }

    QList<QSslCertificate> approvedCerts;
    if (_sslErrorHandler.isNull ()) {
        qCWarning (lcAccount) << out << "called without valid SSL error handler for account" << url ();
        return;
    }

    // SslDialogErrorHandler.handleErrors will run an event loop that might execute
    // the deleteLater () of the QNAM before we have the chance of unwinding our stack.
    // Keep a ref here on our stackframe to make sure that it doesn't get deleted before
    // handleErrors returns.
    QSharedPointer<QNetworkAccessManager> qnamLock = _am;
    QPointer<GLib.Object> guard = reply;

    if (_sslErrorHandler.handleErrors (errors, reply.sslConfiguration (), &approvedCerts, sharedFromThis ())) {
        if (!guard)
            return;

        if (!approvedCerts.isEmpty ()) {
            QSslConfiguration.defaultConfiguration ().addCaCertificates (approvedCerts);
            addApprovedCerts (approvedCerts);
            emit wantsAccountSaved (this);

            // all ssl certs are known and accepted. We can ignore the problems right away.
            qCInfo (lcAccount) << out << "Certs are known and trusted! This is not an actual error.";
        }

        // Warning : Do *not* use ignoreSslErrors () (without args) here:
        // it permanently ignores all SSL errors for this host, even
        // certificate changes.
        reply.ignoreSslErrors (errors);
    } else {
        if (!guard)
            return;

        // Mark all involved certificates as rejected, so we don't ask the user again.
        foreach (QSslError &error, errors) {
            if (!_rejectedCertificates.contains (error.certificate ())) {
                _rejectedCertificates.append (error.certificate ());
            }
        }

        // Not calling ignoreSslErrors will make the SSL handshake fail.
        return;
    }
}

void Account.slotCredentialsFetched () {
    if (_davUser.isEmpty ()) {
        qCDebug (lcAccount) << "User id not set. Fetch it.";
        const auto fetchUserNameJob = new JsonApiJob (sharedFromThis (), QStringLiteral ("/ocs/v1.php/cloud/user"));
        connect (fetchUserNameJob, &JsonApiJob.jsonReceived, this, [this, fetchUserNameJob] (QJsonDocument &json, int statusCode) {
            fetchUserNameJob.deleteLater ();
            if (statusCode != 100) {
                qCWarning (lcAccount) << "Could not fetch user id. Login will probably not work.";
                emit credentialsFetched (_credentials.data ());
                return;
            }

            const auto objData = json.object ().value ("ocs").toObject ().value ("data").toObject ();
            const auto userId = objData.value ("id").toString ("");
            setDavUser (userId);
            emit credentialsFetched (_credentials.data ());
        });
        fetchUserNameJob.start ();
    } else {
        qCDebug (lcAccount) << "User id already fetched.";
        emit credentialsFetched (_credentials.data ());
    }
}

void Account.slotCredentialsAsked () {
    emit credentialsAsked (_credentials.data ());
}

void Account.handleInvalidCredentials () {
    // Retrieving password will trigger remote wipe check job
    retrieveAppPassword ();

    emit invalidCredentials ();
}

void Account.clearQNAMCache () {
    _am.clearAccessCache ();
}

const Capabilities &Account.capabilities () {
    return _capabilities;
}

void Account.setCapabilities (QVariantMap &caps) {
    _capabilities = Capabilities (caps);

    setupUserStatusConnector ();
    trySetupPushNotifications ();
}

void Account.setupUserStatusConnector () {
    _userStatusConnector = std.make_shared<OcsUserStatusConnector> (sharedFromThis ());
    connect (_userStatusConnector.get (), &UserStatusConnector.userStatusFetched, this, [this] (UserStatus &) {
        emit userStatusChanged ();
    });
    connect (_userStatusConnector.get (), &UserStatusConnector.messageCleared, this, [this] {
        emit userStatusChanged ();
    });
}

string Account.serverVersion () {
    return _serverVersion;
}

int Account.serverVersionInt () {
    // FIXME : Use Qt 5.5 QVersionNumber
    auto components = serverVersion ().split ('.');
    return makeServerVersion (components.value (0).toInt (),
        components.value (1).toInt (),
        components.value (2).toInt ());
}

int Account.makeServerVersion (int majorVersion, int minorVersion, int patchVersion) {
    return (majorVersion << 16) + (minorVersion << 8) + patchVersion;
}

bool Account.serverVersionUnsupported () {
    if (serverVersionInt () == 0) {
        // not detected yet, assume it is fine.
        return false;
    }
    return serverVersionInt () < makeServerVersion (NEXTCLOUD_SERVER_VERSION_MIN_SUPPORTED_MAJOR,
               NEXTCLOUD_SERVER_VERSION_MIN_SUPPORTED_MINOR, NEXTCLOUD_SERVER_VERSION_MIN_SUPPORTED_PATCH);
}

bool Account.isUsernamePrefillSupported () {
    return serverVersionInt () >= makeServerVersion (usernamePrefillServerVersinMinSupportedMajor, 0, 0);
}

void Account.setServerVersion (string &version) {
    if (version == _serverVersion) {
        return;
    }

    auto oldServerVersion = _serverVersion;
    _serverVersion = version;
    emit serverVersionChanged (this, oldServerVersion, version);
}

void Account.writeAppPasswordOnce (string appPassword){
    if (_wroteAppPassword)
        return;

    // Fix : Password got written from Account Wizard, before finish.
    // Only write the app password for a connected account, else
    // there'll be a zombie keychain slot forever, never used again ;p
    //
    // Also don't write empty passwords (Log out . Relaunch)
    if (id ().isEmpty () || appPassword.isEmpty ())
        return;

    const string kck = AbstractCredentials.keychainKey (
                url ().toString (),
                davUser () + app_password,
                id ()
    );

    auto *job = new WritePasswordJob (Theme.instance ().appName ());
    job.setInsecureFallback (false);
    job.setKey (kck);
    job.setBinaryData (appPassword.toLatin1 ());
    connect (job, &WritePasswordJob.finished, [this] (Job *incoming) {
        auto *writeJob = static_cast<WritePasswordJob> (incoming);
        if (writeJob.error () == NoError)
            qCInfo (lcAccount) << "appPassword stored in keychain";
        else
            qCWarning (lcAccount) << "Unable to store appPassword in keychain" << writeJob.errorString ();

        // We don't try this again on error, to not raise CPU consumption
        _wroteAppPassword = true;
    });
    job.start ();
}

void Account.retrieveAppPassword (){
    const string kck = AbstractCredentials.keychainKey (
                url ().toString (),
                credentials ().user () + app_password,
                id ()
    );

    auto *job = new ReadPasswordJob (Theme.instance ().appName ());
    job.setInsecureFallback (false);
    job.setKey (kck);
    connect (job, &ReadPasswordJob.finished, [this] (Job *incoming) {
        auto *readJob = static_cast<ReadPasswordJob> (incoming);
        string pwd ("");
        // Error or no valid public key error out
        if (readJob.error () == NoError &&
                readJob.binaryData ().length () > 0) {
            pwd = readJob.binaryData ();
        }

        emit appPasswordRetrieved (pwd);
    });
    job.start ();
}

void Account.deleteAppPassword () {
    const string kck = AbstractCredentials.keychainKey (
                url ().toString (),
                credentials ().user () + app_password,
                id ()
    );

    if (kck.isEmpty ()) {
        qCDebug (lcAccount) << "appPassword is empty";
        return;
    }

    auto *job = new DeletePasswordJob (Theme.instance ().appName ());
    job.setInsecureFallback (false);
    job.setKey (kck);
    connect (job, &DeletePasswordJob.finished, [this] (Job *incoming) {
        auto *deleteJob = static_cast<DeletePasswordJob> (incoming);
        if (deleteJob.error () == NoError)
            qCInfo (lcAccount) << "appPassword deleted from keychain";
        else
            qCWarning (lcAccount) << "Unable to delete appPassword from keychain" << deleteJob.errorString ();

        // Allow storing a new app password on re-login
        _wroteAppPassword = false;
    });
    job.start ();
}

void Account.deleteAppToken () {
    const auto deleteAppTokenJob = new DeleteJob (sharedFromThis (), QStringLiteral ("/ocs/v2.php/core/apppassword"));
    connect (deleteAppTokenJob, &DeleteJob.finishedSignal, this, [this] () {
        if (auto deleteJob = qobject_cast<DeleteJob> (GLib.Object.sender ())) {
            const auto httpCode = deleteJob.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
            if (httpCode != 200) {
                qCWarning (lcAccount) << "AppToken remove failed for user : " << displayName () << " with code : " << httpCode;
            } else {
                qCInfo (lcAccount) << "AppToken for user : " << displayName () << " has been removed.";
            }
        } else {
            Q_ASSERT (false);
            qCWarning (lcAccount) << "The sender is not a DeleteJob instance.";
        }
    });
    deleteAppTokenJob.start ();
}

void Account.fetchDirectEditors (QUrl &directEditingURL, string &directEditingETag) {
    if (directEditingURL.isEmpty () || directEditingETag.isEmpty ())
        return;

    // Check for the directEditing capability
    if (!directEditingURL.isEmpty () &&
        (directEditingETag.isEmpty () || directEditingETag != _lastDirectEditingETag)) {
            // Fetch the available editors and their mime types
            auto *job = new JsonApiJob (sharedFromThis (), QLatin1String ("ocs/v2.php/apps/files/api/v1/directEditing"));
            GLib.Object.connect (job, &JsonApiJob.jsonReceived, this, &Account.slotDirectEditingRecieved);
            job.start ();
    }
}

void Account.slotDirectEditingRecieved (QJsonDocument &json) {
    auto data = json.object ().value ("ocs").toObject ().value ("data").toObject ();
    auto editors = data.value ("editors").toObject ();

    foreach (auto editorKey, editors.keys ()) {
        auto editor = editors.value (editorKey).toObject ();

        const string id = editor.value ("id").toString ();
        const string name = editor.value ("name").toString ();

        if (!id.isEmpty () && !name.isEmpty ()) {
            auto mimeTypes = editor.value ("mimetypes").toArray ();
            auto optionalMimeTypes = editor.value ("optionalMimetypes").toArray ();

            auto *directEditor = new DirectEditor (id, name);

            foreach (auto mimeType, mimeTypes) {
                directEditor.addMimetype (mimeType.toString ().toLatin1 ());
            }

            foreach (auto optionalMimeType, optionalMimeTypes) {
                directEditor.addOptionalMimetype (optionalMimeType.toString ().toLatin1 ());
            }

            _capabilities.addDirectEditor (directEditor);
        }
    }
}

PushNotifications *Account.pushNotifications () {
    return _pushNotifications;
}

std.shared_ptr<UserStatusConnector> Account.userStatusConnector () {
    return _userStatusConnector;
}

} // namespace Occ
