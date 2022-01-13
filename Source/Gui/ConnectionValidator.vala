/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QJsonDocument>
// #include <QJsonObject>
// #include <QJsonArray>
// #include <QLoggingCategory>
// #include <QNetworkReply>
// #include <QNetworkProxyFactory>
// #include <QXmlStreamReader>

// #include <creds/abstractcredentials.h>

// #include <GLib.Object>
// #include <QStringList>
// #include <QVariantMap>
// #include <QNetworkReply>

namespace Occ {

/***********************************************************
This is a job-like class to check that the server is up and that we are connected.
There are two entry points : checkServerAndAuth and checkAuthentication
checkAuthentication is the quick version that only does the propfind
while checkServerAndAuth is doing the 4 calls.

We cannot use the capabilites call to test the l
https://github.com/owncloud/core/issues/12930

Here follows the state machine

\code{.unparsed}
*--. checkServerAndAuth  (check status.php)
        Will asynchronously check for system proxy (if using system proxy)
        And then invoke slotCheckServerAndAuth
        CheckServerJob
        |
        +. slotNoStatusFound -. X
        |
        +. slotJobTimeout -. X
        |
        +. slotStatusFound --+-. X (if credentials are still missing)
                              |
  +---------------------------+
  |
*-+. checkAuthentication (PROPFIND on root)
        PropfindJob
        |
        +. slotAuthFailed -. X
        |
        +. slotAuthSuccess --+-. X (depending if coming from checkServerAndAuth or not)
                              |
  +---------------------------+
  |
  +. checkServerCapabilities --------------v (in parallel)
        JsonApiJob (cloud/capabilities)
        +. slotCapabilitiesRecieved -+
                                      |
    +---------------------------------+
    |
  fetchUser
        Utilizes the UserInfo class to fetch the user and avatar image
  +-----------------------------------+
  |
  +. Client Side Encryption Checks --+ --reportResult ()
    \endcode
***********************************************************/


class ConnectionValidator : GLib.Object {
public:
    ConnectionValidator (AccountStatePtr accountState, GLib.Object *parent = nullptr);

    enum Status {
        Undefined,
        Connected,
        NotConfigured,
        ServerVersionMismatch, // The server version is too old
        CredentialsNotReady, // Credentials aren't ready
        CredentialsWrong, // AuthenticationRequiredError
        SslError, // SSL handshake error, certificate rejected by user?
        StatusNotFound, // Error retrieving status.php
        ServiceUnavailable, // 503 on authed request
        MaintenanceMode, // maintenance enabled in status.php
        Timeout // actually also used for other errors on the authed request
    };
    Q_ENUM (Status);

    // How often should the Application ask this object to check for the connection?
    enum { DefaultCallingIntervalMsec = 62 * 1000 };

public slots:
    /// Checks the server and the authentication.
    void checkServerAndAuth ();
    void systemProxyLookupDone (QNetworkProxy &proxy);

    /// Checks authentication only.
    void checkAuthentication ();

signals:
    void connectionResult (ConnectionValidator.Status status, QStringList &errors);

protected slots:
    void slotCheckServerAndAuth ();

    void slotStatusFound (QUrl &url, QJsonObject &info);
    void slotNoStatusFound (QNetworkReply *reply);
    void slotJobTimeout (QUrl &url);

    void slotAuthFailed (QNetworkReply *reply);
    void slotAuthSuccess ();

    void slotCapabilitiesRecieved (QJsonDocument &);
    void slotUserFetched (UserInfo *userInfo);

private:
#ifndef TOKEN_AUTH_ONLY
    void reportConnected ();
#endif
    void reportResult (Status status);
    void checkServerCapabilities ();
    void fetchUser ();

    /***********************************************************
    Sets the account's server version

    Returns false and reports ServerVersionMismatch for very old servers.
    ***********************************************************/
    bool setAndCheckServerVersion (string &version);

    QStringList _errors;
    AccountStatePtr _accountState;
    AccountPtr _account;
    bool _isCheckingServerAndAuth;
};

    // Make sure the timeout for this job is less than how often we get called
    // This makes sure we get tried often enough without "ConnectionValidator already running"
    static int64 timeoutToUseMsec = qMax (1000, ConnectionValidator.DefaultCallingIntervalMsec - 5 * 1000);
    
    ConnectionValidator.ConnectionValidator (AccountStatePtr accountState, GLib.Object *parent)
        : GLib.Object (parent)
        , _accountState (accountState)
        , _account (accountState.account ())
        , _isCheckingServerAndAuth (false) {
    }
    
    void ConnectionValidator.checkServerAndAuth () {
        if (!_account) {
            _errors << tr ("No Nextcloud account configured");
            reportResult (NotConfigured);
            return;
        }
        qCDebug (lcConnectionValidator) << "Checking server and authentication";
    
        _isCheckingServerAndAuth = true;
    
        // Lookup system proxy in a thread https://github.com/owncloud/client/issues/2993
        if (ClientProxy.isUsingSystemDefault ()) {
            qCDebug (lcConnectionValidator) << "Trying to look up system proxy";
            ClientProxy.lookupSystemProxyAsync (_account.url (),
                this, SLOT (systemProxyLookupDone (QNetworkProxy)));
        } else {
            // We want to reset the QNAM proxy so that the global proxy settings are used (via ClientProxy settings)
            _account.networkAccessManager ().setProxy (QNetworkProxy (QNetworkProxy.DefaultProxy));
            // use a queued invocation so we're as asynchronous as with the other code path
            QMetaObject.invokeMethod (this, "slotCheckServerAndAuth", Qt.QueuedConnection);
        }
    }
    
    void ConnectionValidator.systemProxyLookupDone (QNetworkProxy &proxy) {
        if (!_account) {
            qCWarning (lcConnectionValidator) << "Bailing out, Account had been deleted";
            return;
        }
    
        if (proxy.type () != QNetworkProxy.NoProxy) {
            qCInfo (lcConnectionValidator) << "Setting QNAM proxy to be system proxy" << ClientProxy.printQNetworkProxy (proxy);
        } else {
            qCInfo (lcConnectionValidator) << "No system proxy set by OS";
        }
        _account.networkAccessManager ().setProxy (proxy);
    
        slotCheckServerAndAuth ();
    }
    
    // The actual check
    void ConnectionValidator.slotCheckServerAndAuth () {
        auto *checkJob = new CheckServerJob (_account, this);
        checkJob.setTimeout (timeoutToUseMsec);
        checkJob.setIgnoreCredentialFailure (true);
        connect (checkJob, &CheckServerJob.instanceFound, this, &ConnectionValidator.slotStatusFound);
        connect (checkJob, &CheckServerJob.instanceNotFound, this, &ConnectionValidator.slotNoStatusFound);
        connect (checkJob, &CheckServerJob.timeout, this, &ConnectionValidator.slotJobTimeout);
        checkJob.start ();
    }
    
    void ConnectionValidator.slotStatusFound (QUrl &url, QJsonObject &info) {
        // Newer servers don't disclose any version in status.php anymore
        // https://github.com/owncloud/core/pull/27473/files
        // so this string can be empty.
        string serverVersion = CheckServerJob.version (info);
    
        // status.php was found.
        qCInfo (lcConnectionValidator) << "** Application : ownCloud found : "
                                      << url << " with version "
                                      << CheckServerJob.versionString (info)
                                      << " (" << serverVersion << ")";
    
        // Update server url in case of redirection
        if (_account.url () != url) {
            qCInfo (lcConnectionValidator ()) << "status.php was redirected to" << url.toString ();
            _account.setUrl (url);
            _account.wantsAccountSaved (_account.data ());
        }
    
        if (!serverVersion.isEmpty () && !setAndCheckServerVersion (serverVersion)) {
            return;
        }
    
        // Check for maintenance mode : Servers send "true", so go through QVariant
        // to parse it correctly.
        if (info["maintenance"].toVariant ().toBool ()) {
            reportResult (MaintenanceMode);
            return;
        }
    
        // now check the authentication
        QTimer.singleShot (0, this, &ConnectionValidator.checkAuthentication);
    }
    
    // status.php could not be loaded (network or server issue!).
    void ConnectionValidator.slotNoStatusFound (QNetworkReply *reply) {
        auto job = qobject_cast<CheckServerJob> (sender ());
        qCWarning (lcConnectionValidator) << reply.error () << job.errorString () << reply.peek (1024);
        if (reply.error () == QNetworkReply.SslHandshakeFailedError) {
            reportResult (SslError);
            return;
        }
    
        if (!_account.credentials ().stillValid (reply)) {
            // Note : Why would this happen on a status.php request?
            _errors.append (tr ("Authentication error : Either username or password are wrong."));
        } else {
            //_errors.append (tr ("Unable to connect to %1").arg (_account.url ().toString ()));
            _errors.append (job.errorString ());
        }
        reportResult (StatusNotFound);
    }
    
    void ConnectionValidator.slotJobTimeout (QUrl &url) {
        Q_UNUSED (url);
        //_errors.append (tr ("Unable to connect to %1").arg (url.toString ()));
        _errors.append (tr ("Timeout"));
        reportResult (Timeout);
    }
    
    void ConnectionValidator.checkAuthentication () {
        AbstractCredentials *creds = _account.credentials ();
    
        if (!creds.ready ()) {
            reportResult (CredentialsNotReady);
            return;
        }
    
        // simply GET the webdav root, will fail if credentials are wrong.
        // continue in slotAuthCheck here :-)
        qCDebug (lcConnectionValidator) << "# Check whether authenticated propfind works.";
        auto *job = new PropfindJob (_account, "/", this);
        job.setTimeout (timeoutToUseMsec);
        job.setProperties (QList<QByteArray> () << "getlastmodified");
        connect (job, &PropfindJob.result, this, &ConnectionValidator.slotAuthSuccess);
        connect (job, &PropfindJob.finishedWithError, this, &ConnectionValidator.slotAuthFailed);
        job.start ();
    }
    
    void ConnectionValidator.slotAuthFailed (QNetworkReply *reply) {
        auto job = qobject_cast<PropfindJob> (sender ());
        Status stat = Timeout;
    
        if (reply.error () == QNetworkReply.SslHandshakeFailedError) {
            _errors << job.errorStringParsingBody ();
            stat = SslError;
    
        } else if (reply.error () == QNetworkReply.AuthenticationRequiredError
            || !_account.credentials ().stillValid (reply)) {
            qCWarning (lcConnectionValidator) << "******** Password is wrong!" << reply.error () << job.errorString ();
            _errors << tr ("The provided credentials are not correct");
            stat = CredentialsWrong;
    
        } else if (reply.error () != QNetworkReply.NoError) {
            _errors << job.errorStringParsingBody ();
    
            const int httpStatus =
                reply.attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
            if (httpStatus == 503) {
                _errors.clear ();
                stat = ServiceUnavailable;
            }
        }
    
        reportResult (stat);
    }
    
    void ConnectionValidator.slotAuthSuccess () {
        _errors.clear ();
        if (!_isCheckingServerAndAuth) {
            reportResult (Connected);
            return;
        }
        checkServerCapabilities ();
    }
    
    void ConnectionValidator.checkServerCapabilities () {
        // The main flow now needs the capabilities
        auto *job = new JsonApiJob (_account, QLatin1String ("ocs/v1.php/cloud/capabilities"), this);
        job.setTimeout (timeoutToUseMsec);
        GLib.Object.connect (job, &JsonApiJob.jsonReceived, this, &ConnectionValidator.slotCapabilitiesRecieved);
        job.start ();
    }
    
    void ConnectionValidator.slotCapabilitiesRecieved (QJsonDocument &json) {
        auto caps = json.object ().value ("ocs").toObject ().value ("data").toObject ().value ("capabilities").toObject ();
        qCInfo (lcConnectionValidator) << "Server capabilities" << caps;
        _account.setCapabilities (caps.toVariantMap ());
    
        // New servers also report the version in the capabilities
        string serverVersion = caps["core"].toObject ()["status"].toObject ()["version"].toString ();
        if (!serverVersion.isEmpty () && !setAndCheckServerVersion (serverVersion)) {
            return;
        }
    
        // Check for the directEditing capability
        QUrl directEditingURL = QUrl (caps["files"].toObject ()["directEditing"].toObject ()["url"].toString ());
        string directEditingETag = caps["files"].toObject ()["directEditing"].toObject ()["etag"].toString ();
        _account.fetchDirectEditors (directEditingURL, directEditingETag);
    
        fetchUser ();
    }
    
    void ConnectionValidator.fetchUser () {
        auto *userInfo = new UserInfo (_accountState.data (), true, true, this);
        GLib.Object.connect (userInfo, &UserInfo.fetchedLastInfo, this, &ConnectionValidator.slotUserFetched);
        userInfo.setActive (true);
    }
    
    bool ConnectionValidator.setAndCheckServerVersion (string &version) {
        qCInfo (lcConnectionValidator) << _account.url () << "has server version" << version;
        _account.setServerVersion (version);
    
        // We cannot deal with servers < 7.0.0
        if (_account.serverVersionInt ()
            && _account.serverVersionInt () < Account.makeServerVersion (7, 0, 0)) {
            _errors.append (tr ("The configured server for this client is too old"));
            _errors.append (tr ("Please update to the latest server and restart the client."));
            reportResult (ServerVersionMismatch);
            return false;
        }
        // We attempt to work with servers >= 7.0.0 but warn users.
        // Check usages of Account.serverVersionUnsupported () for details.
    
    #if QT_VERSION >= QT_VERSION_CHECK (5, 9, 0)
        // Record that the server supports HTTP/2
        // Actual decision if we should use HTTP/2 is done in AccessManager.createRequest
        if (auto job = qobject_cast<AbstractNetworkJob> (sender ())) {
            if (auto reply = job.reply ()) {
                _account.setHttp2Supported (
                    reply.attribute (QNetworkRequest.HTTP2WasUsedAttribute).toBool ());
            }
        }
    #endif
        return true;
    }
    
    void ConnectionValidator.slotUserFetched (UserInfo *userInfo) {
        if (userInfo) {
            userInfo.setActive (false);
            userInfo.deleteLater ();
        }
    
    #ifndef TOKEN_AUTH_ONLY
        connect (_account.e2e (), &ClientSideEncryption.initializationFinished, this, &ConnectionValidator.reportConnected);
        _account.e2e ().initialize (_account);
    #else
        reportResult (Connected);
    #endif
    }
    
    #ifndef TOKEN_AUTH_ONLY
    void ConnectionValidator.reportConnected () {
        reportResult (Connected);
    }
    #endif
    
    void ConnectionValidator.reportResult (Status status) {
        emit connectionResult (status, _errors);
        deleteLater ();
    }
    
    } // namespace Occ
    