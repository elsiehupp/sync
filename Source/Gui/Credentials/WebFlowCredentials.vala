#ifndef WEBFLOWCREDENTIALS_H
const int WEBFLOWCREDENTIALS_H

// #include <QSslCertificate>
// #include <QSslKey>
// #include <QNetworkRequest>
// #include <QQueue>
// #include <QAuthenticator>
// #include <QNetworkAccessManager>
// #include <QNetworkReply>
// #include <QPointer>
// #include <QTimer>
// #include <Gtk.Dialog>
// #include <QVBoxLayout>
// #include <QLabel>

class QAuthenticator;

#ifdef WITH_WEBENGINE
#endif // WITH_WEBENGINE

using namespace QKeychain;

namespace QKeychain {
    class Job;
}

namespace Occ {

namespace KeychainChunk {
    class ReadJob;
    class WriteJob;
}


class WebFlowCredentials : AbstractCredentials {
    friend class WebFlowCredentialsAccessManager;

public:
    /// Don't add credentials if this is set on a QNetworkRequest
    static constexpr QNetworkRequest.Attribute DontAddCredentialsAttribute = QNetworkRequest.User;

    WebFlowCredentials ();
    WebFlowCredentials (
            const string &user,
            const string &password,
            const QSslCertificate &certificate = QSslCertificate (),
            const QSslKey &key = QSslKey (),
            const QList<QSslCertificate> &caCertificates = QList<QSslCertificate> ());

    string authType () const override;
    string user () const override;
    string password () const override;
    QNetworkAccessManager *createQNAM () const override;

    bool ready () const override;

    void fetchFromKeychain () override;
    void askFromUser () override;

    bool stillValid (QNetworkReply *reply) override;
    void persist () override;
    void invalidateToken () override;
    void forgetSensitiveData () override;

    // To fetch the user name as early as possible
    void setAccount (Account *account) override;

private slots:
    void slotAuthentication (QNetworkReply *reply, QAuthenticator *authenticator);
    void slotFinished (QNetworkReply *reply);

    void slotAskFromUserCredentialsProvided (string &user, string &pass, string &host);
    void slotAskFromUserCancelled ();

    void slotReadClientCertPEMJobDone (KeychainChunk.ReadJob *readJob);
    void slotReadClientKeyPEMJobDone (KeychainChunk.ReadJob *readJob);
    void slotReadClientCaCertsPEMJobDone (KeychainChunk.ReadJob *readJob);
    void slotReadPasswordJobDone (QKeychain.Job *incomingJob);

    void slotWriteClientCertPEMJobDone (KeychainChunk.WriteJob *writeJob);
    void slotWriteClientKeyPEMJobDone (KeychainChunk.WriteJob *writeJob);
    void slotWriteClientCaCertsPEMJobDone (KeychainChunk.WriteJob *writeJob);
    void slotWriteJobDone (QKeychain.Job *);

private:
    /***********************************************************
    Windows : Workaround for CredWriteW used by QtKeychain
    
             Saving all client CA's within one credential may result in:
             Error : "Credential size exceeds maximum size of 2560"
    ***********************************************************/
    void readSingleClientCaCertPEM ();
    void writeSingleClientCaCertPEM ();

    /***********************************************************
    Since we're limited by Windows limits, we just create our own
    limit to avoid evil things happening by endless recursion
    
    Better than storing the count and relying on maybe-hacked values
    ***********************************************************/
    static constexpr int _clientSslCaCertificatesMaxCount = 10;
    QQueue<QSslCertificate> _clientSslCaCertificatesWriteQueue;

protected:
    /***********************************************************
    Reads data from keychain locations

    Goes through
      slotReadClientCertPEMJobDone to
      slotReadClientKeyPEMJobDone to
      slotReadClientCaCertsPEMJobDone to
      slotReadJobDone
    ***********************************************************/
    void fetchFromKeychainHelper ();

    /// Wipes legacy keychain locations
    void deleteKeychainEntries (bool oldKeychainEntries = false);

    string fetchUser ();

    string _user;
    string _password;
    QSslKey _clientSslKey;
    QSslCertificate _clientSslCertificate;
    QList<QSslCertificate> _clientSslCaCertificates;

    bool _ready = false;
    bool _credentialsValid = false;
    bool _keychainMigration = false;

    WebFlowCredentialsDialog *_askDialog = nullptr;
};




namespace {
    const char userC[] = "user";
    const char clientCertificatePEMC[] = "_clientCertificatePEM";
    const char clientKeyPEMC[] = "_clientKeyPEM";
    const char clientCaCertificatePEMC[] = "_clientCaCertificatePEM";
} // ns

class WebFlowCredentialsAccessManager : AccessManager {
public:
    WebFlowCredentialsAccessManager (WebFlowCredentials *cred, GLib.Object *parent = nullptr)
        : AccessManager (parent)
        , _cred (cred) {
    }

protected:
    QNetworkReply *createRequest (Operation op, QNetworkRequest &request, QIODevice *outgoingData) override {
        QNetworkRequest req (request);
        if (!req.attribute (WebFlowCredentials.DontAddCredentialsAttribute).toBool ()) {
            if (_cred && !_cred.password ().isEmpty ()) {
                QByteArray credHash = QByteArray (_cred.user ().toUtf8 () + ":" + _cred.password ().toUtf8 ()).toBase64 ();
                req.setRawHeader ("Authorization", "Basic " + credHash);
            }
        }

        if (_cred && !_cred._clientSslKey.isNull () && !_cred._clientSslCertificate.isNull ()) {
            // SSL configuration
            QSslConfiguration sslConfiguration = req.sslConfiguration ();
            sslConfiguration.setLocalCertificate (_cred._clientSslCertificate);
            sslConfiguration.setPrivateKey (_cred._clientSslKey);

            // Merge client side CA with system CA
            auto ca = sslConfiguration.systemCaCertificates ();
            ca.append (_cred._clientSslCaCertificates);
            sslConfiguration.setCaCertificates (ca);

            req.setSslConfiguration (sslConfiguration);
        }

        return AccessManager.createRequest (op, req, outgoingData);
    }

private:
    // The credentials object dies along with the account, while the QNAM might
    // outlive both.
    QPointer<const WebFlowCredentials> _cred;
};

#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
static void addSettingsToJob (Account *account, QKeychain.Job *job) {
    Q_UNUSED (account)
    auto settings = ConfigFile.settingsWithGroup (Theme.instance ().appName ());
    settings.setParent (job); // make the job parent to make setting deleted properly
    job.setSettings (settings.release ());
}
#endif

WebFlowCredentials.WebFlowCredentials () = default;

WebFlowCredentials.WebFlowCredentials (string &user, string &password, QSslCertificate &certificate, QSslKey &key, QList<QSslCertificate> &caCertificates)
    : _user (user)
    , _password (password)
    , _clientSslKey (key)
    , _clientSslCertificate (certificate)
    , _clientSslCaCertificates (caCertificates)
    , _ready (true)
    , _credentialsValid (true) {

}

string WebFlowCredentials.authType () {
    return string.fromLatin1 ("webflow");
}

string WebFlowCredentials.user () {
    return _user;
}

string WebFlowCredentials.password () {
    return _password;
}

QNetworkAccessManager *WebFlowCredentials.createQNAM () {
    qCInfo (lcWebFlowCredentials ()) << "Get QNAM";
    AccessManager *qnam = new WebFlowCredentialsAccessManager (this);

    connect (qnam, &AccessManager.authenticationRequired, this, &WebFlowCredentials.slotAuthentication);
    connect (qnam, &AccessManager.finished, this, &WebFlowCredentials.slotFinished);

    return qnam;
}

bool WebFlowCredentials.ready () {
    return _ready;
}

void WebFlowCredentials.fetchFromKeychain () {
    _wasFetched = true;

    // Make sure we get the user from the config file
    fetchUser ();

    if (ready ()) {
        emit fetched ();
    } else {
        qCInfo (lcWebFlowCredentials ()) << "Fetch from keychain!";
        fetchFromKeychainHelper ();
    }
}

void WebFlowCredentials.askFromUser () {
    // Determine if the old flow has to be used (GS for now)
    // Do a DetermineAuthTypeJob to make sure that the server is still using Flow2
    auto job = new DetermineAuthTypeJob (_account.sharedFromThis (), this);
    connect (job, &DetermineAuthTypeJob.authType, [this] (DetermineAuthTypeJob.AuthType type) {
    // LoginFlowV2 > WebViewFlow > OAuth > Shib > Basic
#ifdef WITH_WEBENGINE
        bool useFlow2 = (type != DetermineAuthTypeJob.WebViewFlow);
#else // WITH_WEBENGINE
        bool useFlow2 = true;
#endif // WITH_WEBENGINE

        _askDialog = new WebFlowCredentialsDialog (_account, useFlow2);

        if (!useFlow2) {
            QUrl url = _account.url ();
            string path = url.path () + "/index.php/login/flow";
            url.setPath (path);
            _askDialog.setUrl (url);
        }

        string msg = tr ("You have been logged out of %1 as user %2. Please login again.")
                          .arg (_account.displayName (), _user);
        _askDialog.setInfo (msg);

        _askDialog.show ();

        connect (_askDialog, &WebFlowCredentialsDialog.urlCatched, this, &WebFlowCredentials.slotAskFromUserCredentialsProvided);
        connect (_askDialog, &WebFlowCredentialsDialog.onClose, this, &WebFlowCredentials.slotAskFromUserCancelled);
    });
    job.start ();

    qCDebug (lcWebFlowCredentials ()) << "User needs to reauth!";
}

void WebFlowCredentials.slotAskFromUserCredentialsProvided (string &user, string &pass, string &host) {
    Q_UNUSED (host)

    // Compare the re-entered username case-insensitive and save the new value (avoid breaking the account)
    // See issue : https://github.com/nextcloud/desktop/issues/1741
    if (string.compare (_user, user, Qt.CaseInsensitive) == 0) {
        _user = user;
    } else {
        qCInfo (lcWebFlowCredentials ()) << "Authed with the wrong user!";

        string msg = tr ("Please login with the user : %1")
                .arg (_user);
        _askDialog.setError (msg);

        if (!_askDialog.isUsingFlow2 ()) {
            QUrl url = _account.url ();
            string path = url.path () + "/index.php/login/flow";
            url.setPath (path);
            _askDialog.setUrl (url);
        }

        return;
    }

    qCInfo (lcWebFlowCredentials ()) << "Obtained a new password";

    _password = pass;
    _ready = true;
    _credentialsValid = true;
    persist ();
    emit asked ();

    _askDialog.close ();
    _askDialog.deleteLater ();
    _askDialog = nullptr;
}

void WebFlowCredentials.slotAskFromUserCancelled () {
    qCDebug (lcWebFlowCredentials ()) << "User cancelled reauth!";

    emit asked ();

    _askDialog.deleteLater ();
    _askDialog = nullptr;
}

bool WebFlowCredentials.stillValid (QNetworkReply *reply) {
    if (reply.error () != QNetworkReply.NoError) {
        qCWarning (lcWebFlowCredentials ()) << reply.error ();
        qCWarning (lcWebFlowCredentials ()) << reply.errorString ();
    }
    return (reply.error () != QNetworkReply.AuthenticationRequiredError);
}

void WebFlowCredentials.persist () {
    if (_user.isEmpty ()) {
        // We don't even have a user nothing to see here move along
        return;
    }

    _account.setCredentialSetting (userC, _user);
    _account.wantsAccountSaved (_account);

    // write cert if there is one
    if (!_clientSslCertificate.isNull ()) {
        auto job = new KeychainChunk.WriteJob (_account,
                                               _user + clientCertificatePEMC,
                                               _clientSslCertificate.toPem (),
                                               this);
        connect (job, &KeychainChunk.WriteJob.finished, this, &WebFlowCredentials.slotWriteClientCertPEMJobDone);
        job.start ();
    } else {
        // no cert, just write credentials
        slotWriteClientCertPEMJobDone (nullptr);
    }
}

void WebFlowCredentials.slotWriteClientCertPEMJobDone (KeychainChunk.WriteJob *writeJob) {
    Q_UNUSED (writeJob)
    // write ssl key if there is one
    if (!_clientSslKey.isNull ()) {
        auto job = new KeychainChunk.WriteJob (_account,
                                               _user + clientKeyPEMC,
                                               _clientSslKey.toPem (),
                                               this);
        connect (job, &KeychainChunk.WriteJob.finished, this, &WebFlowCredentials.slotWriteClientKeyPEMJobDone);
        job.start ();
    } else {
        // no key, just write credentials
        slotWriteClientKeyPEMJobDone (nullptr);
    }
}

void WebFlowCredentials.writeSingleClientCaCertPEM () {
    // write a ca cert if there is any in the queue
    if (!_clientSslCaCertificatesWriteQueue.isEmpty ()) {
        // grab and remove the first cert from the queue
        auto cert = _clientSslCaCertificatesWriteQueue.dequeue ();

        auto index = (_clientSslCaCertificates.count () - _clientSslCaCertificatesWriteQueue.count ()) - 1;

        // keep the limit
        if (index > (_clientSslCaCertificatesMaxCount - 1)) {
            qCWarning (lcWebFlowCredentials) << "Maximum client CA cert count exceeded while writing slot" << string.number (index) << "cutting off after" << string.number (_clientSslCaCertificatesMaxCount) << "certs";

            _clientSslCaCertificatesWriteQueue.clear ();

            slotWriteClientCaCertsPEMJobDone (nullptr);
            return;
        }

        auto job = new KeychainChunk.WriteJob (_account,
                                               _user + clientCaCertificatePEMC + string.number (index),
                                               cert.toPem (),
                                               this);
        connect (job, &KeychainChunk.WriteJob.finished, this, &WebFlowCredentials.slotWriteClientCaCertsPEMJobDone);
        job.start ();
    } else {
        slotWriteClientCaCertsPEMJobDone (nullptr);
    }
}

void WebFlowCredentials.slotWriteClientKeyPEMJobDone (KeychainChunk.WriteJob *writeJob) {
    Q_UNUSED (writeJob)
    _clientSslCaCertificatesWriteQueue.clear ();

    // write ca certs if there are any
    if (!_clientSslCaCertificates.isEmpty ()) {
        // queue the certs to avoid trouble on Windows (Workaround for CredWriteW used by QtKeychain)
        _clientSslCaCertificatesWriteQueue.append (_clientSslCaCertificates);

        // first ca cert
        writeSingleClientCaCertPEM ();
    } else {
        slotWriteClientCaCertsPEMJobDone (nullptr);
    }
}

void WebFlowCredentials.slotWriteClientCaCertsPEMJobDone (KeychainChunk.WriteJob *writeJob) {
    // errors / next ca cert?
    if (writeJob && !_clientSslCaCertificates.isEmpty ()) {
        if (writeJob.error () != NoError) {
            qCWarning (lcWebFlowCredentials) << "Error while writing client CA cert" << writeJob.errorString ();
        }

        if (!_clientSslCaCertificatesWriteQueue.isEmpty ()) {
            // next ca cert
            writeSingleClientCaCertPEM ();
            return;
        }
    }

    // done storing ca certs, time for the password
    auto job = new WritePasswordJob (Theme.instance ().appName (), this);
#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
    addSettingsToJob (_account, job);
#endif
    job.setInsecureFallback (false);
    connect (job, &Job.finished, this, &WebFlowCredentials.slotWriteJobDone);
    job.setKey (keychainKey (_account.url ().toString (), _user, _account.id ()));
    job.setTextData (_password);
    job.start ();
}

void WebFlowCredentials.slotWriteJobDone (QKeychain.Job *job) {
    delete job.settings ();
    switch (job.error ()) {
    case NoError:
        break;
    default:
        qCWarning (lcWebFlowCredentials) << "Error while writing password" << job.errorString ();
    }
}

void WebFlowCredentials.invalidateToken () {
    // clear the session cookie.
    _account.clearCookieJar ();

    // let QNAM forget about the password
    // This needs to be done later in the event loop because we might be called (directly or
    // indirectly) from QNetworkAccessManagerPrivate.authenticationRequired, which itself
    // is a called from a BlockingQueuedConnection from the Qt HTTP thread. And clearing the
    // cache needs to synchronize again with the HTTP thread.
    QTimer.singleShot (0, _account, &Account.clearQNAMCache);
}

void WebFlowCredentials.forgetSensitiveData () {
    _password = string ();
    _ready = false;

    fetchUser ();

    _account.deleteAppPassword ();

    const string kck = keychainKey (_account.url ().toString (), _user, _account.id ());
    if (kck.isEmpty ()) {
        qCDebug (lcWebFlowCredentials ()) << "InvalidateToken : User is empty, bailing out!";
        return;
    }

    auto job = new DeletePasswordJob (Theme.instance ().appName (), this);
    job.setInsecureFallback (false);
    job.setKey (kck);
    job.start ();

    invalidateToken ();

    deleteKeychainEntries ();
}

void WebFlowCredentials.setAccount (Account *account) {
    AbstractCredentials.setAccount (account);
    if (_user.isEmpty ()) {
        fetchUser ();
    }
}

string WebFlowCredentials.fetchUser () {
    _user = _account.credentialSetting (userC).toString ();
    return _user;
}

void WebFlowCredentials.slotAuthentication (QNetworkReply *reply, QAuthenticator *authenticator) {
    Q_UNUSED (reply)

    if (!_ready) {
        return;
    }

    if (_credentialsValid == false) {
        return;
    }

    qCDebug (lcWebFlowCredentials ()) << "Requires authentication";

    authenticator.setUser (_user);
    authenticator.setPassword (_password);
    _credentialsValid = false;
}

void WebFlowCredentials.slotFinished (QNetworkReply *reply) {
    qCInfo (lcWebFlowCredentials ()) << "request finished";

    if (reply.error () == QNetworkReply.NoError) {
        _credentialsValid = true;

        /// Used later for remote wipe
        _account.writeAppPasswordOnce (_password);
    }
}

void WebFlowCredentials.fetchFromKeychainHelper () {
    // Read client cert from keychain
    auto job = new KeychainChunk.ReadJob (_account,
                                          _user + clientCertificatePEMC,
                                          _keychainMigration,
                                          this);
    connect (job, &KeychainChunk.ReadJob.finished, this, &WebFlowCredentials.slotReadClientCertPEMJobDone);
    job.start ();
}

void WebFlowCredentials.slotReadClientCertPEMJobDone (KeychainChunk.ReadJob *readJob) {
    // Store PEM in memory
    if (readJob.error () == NoError && readJob.binaryData ().length () > 0) {
        QList<QSslCertificate> sslCertificateList = QSslCertificate.fromData (readJob.binaryData (), QSsl.Pem);
        if (sslCertificateList.length () >= 1) {
            _clientSslCertificate = sslCertificateList.at (0);
        }
    }

    // Load key too
    auto job = new KeychainChunk.ReadJob (_account,
                                          _user + clientKeyPEMC,
                                          _keychainMigration,
                                          this);
    connect (job, &KeychainChunk.ReadJob.finished, this, &WebFlowCredentials.slotReadClientKeyPEMJobDone);
    job.start ();
}

void WebFlowCredentials.slotReadClientKeyPEMJobDone (KeychainChunk.ReadJob *readJob) {
    // Store key in memory
    if (readJob.error () == NoError && readJob.binaryData ().length () > 0) {
        QByteArray clientKeyPEM = readJob.binaryData ();
        // FIXME Unfortunately Qt has a bug and we can't just use QSsl.Opaque to let it
        // load whatever we have. So we try until it works.
        _clientSslKey = QSslKey (clientKeyPEM, QSsl.Rsa);
        if (_clientSslKey.isNull ()) {
            _clientSslKey = QSslKey (clientKeyPEM, QSsl.Dsa);
        }
        if (_clientSslKey.isNull ()) {
            _clientSslKey = QSslKey (clientKeyPEM, QSsl.Ec);
        }
        if (_clientSslKey.isNull ()) {
            qCWarning (lcWebFlowCredentials) << "Could not load SSL key into Qt!";
        }
        clientKeyPEM.clear ();
    } else {
        qCWarning (lcWebFlowCredentials) << "Unable to read client key" << readJob.errorString ();
    }

    // Start fetching client CA certs
    _clientSslCaCertificates.clear ();

    readSingleClientCaCertPEM ();
}

void WebFlowCredentials.readSingleClientCaCertPEM () {
    // try to fetch a client ca cert
    if (_clientSslCaCertificates.count () < _clientSslCaCertificatesMaxCount) {
        auto job = new KeychainChunk.ReadJob (_account,
                                              _user + clientCaCertificatePEMC + string.number (_clientSslCaCertificates.count ()),
                                              _keychainMigration,
                                              this);
        connect (job, &KeychainChunk.ReadJob.finished, this, &WebFlowCredentials.slotReadClientCaCertsPEMJobDone);
        job.start ();
    } else {
        qCWarning (lcWebFlowCredentials) << "Maximum client CA cert count exceeded while reading, ignoring after" << _clientSslCaCertificatesMaxCount;

        slotReadClientCaCertsPEMJobDone (nullptr);
    }
}

void WebFlowCredentials.slotReadClientCaCertsPEMJobDone (KeychainChunk.ReadJob *readJob) {
    // Store cert in memory
    if (readJob) {
        if (readJob.error () == NoError && readJob.binaryData ().length () > 0) {
            QList<QSslCertificate> sslCertificateList = QSslCertificate.fromData (readJob.binaryData (), QSsl.Pem);
            if (sslCertificateList.length () >= 1) {
                _clientSslCaCertificates.append (sslCertificateList.at (0));
            }

            // try next cert
            readSingleClientCaCertPEM ();
            return;
        } else {
            if (readJob.error () != QKeychain.Error.EntryNotFound ||
                ( (readJob.error () == QKeychain.Error.EntryNotFound) && _clientSslCaCertificates.count () == 0)) {
                qCWarning (lcWebFlowCredentials) << "Unable to read client CA cert slot" << string.number (_clientSslCaCertificates.count ()) << readJob.errorString ();
            }
        }
    }

    // Now fetch the actual server password
    const string kck = keychainKey (
        _account.url ().toString (),
        _user,
        _keychainMigration ? string () : _account.id ());

    auto job = new ReadPasswordJob (Theme.instance ().appName (), this);
#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
    addSettingsToJob (_account, job);
#endif
    job.setInsecureFallback (false);
    job.setKey (kck);
    connect (job, &Job.finished, this, &WebFlowCredentials.slotReadPasswordJobDone);
    job.start ();
}

void WebFlowCredentials.slotReadPasswordJobDone (Job *incomingJob) {
    auto job = qobject_cast<ReadPasswordJob> (incomingJob);
    QKeychain.Error error = job.error ();

    // If we could not find the entry try the old entries
    if (!_keychainMigration && error == QKeychain.EntryNotFound) {
        _keychainMigration = true;
        fetchFromKeychainHelper ();
        return;
    }

    if (_user.isEmpty ()) {
        qCWarning (lcWebFlowCredentials) << "Strange : User is empty!";
    }

    if (error == QKeychain.NoError) {
        _password = job.textData ();
        _ready = true;
        _credentialsValid = true;
    } else {
        _ready = false;
    }
    emit fetched ();

    // If keychain data was read from legacy location, wipe these entries and store new ones
    if (_keychainMigration && _ready) {
        _keychainMigration = false;
        persist ();
        deleteKeychainEntries (true); // true : delete old entries
        qCInfo (lcWebFlowCredentials) << "Migrated old keychain entries";
    }
}

void WebFlowCredentials.deleteKeychainEntries (bool oldKeychainEntries) {
    auto startDeleteJob = [this, oldKeychainEntries] (string key) {
        auto job = new KeychainChunk.DeleteJob (_account, key, oldKeychainEntries, this);
        job.start ();
    };

    startDeleteJob (_user);

    /* IMPORTANT - remove later - FIXME MS@2019-12-07 -.
      * TODO : For "Log out" & "Remove account" : Remove client CA certs and KEY!
      *
      *       Disabled as long as selecting another cert is not supported by the UI.
      *
      *       Being able to specify a new certificate is important anyway : expiry etc.
      *
      *       We introduce this dirty hack here, to allow deleting them upon Remote Wipe.
    ***********************************************************/
    if (_account.isRemoteWipeRequested_HACK ()) {
    // <-- FIXME MS@2019-12-07

        // Also delete key / cert sub-chunks (KeychainChunk takes care of the Windows workaround)
        // The first chunk (0) has no suffix, to stay compatible with older versions and non-Windows
        startDeleteJob (_user + clientKeyPEMC);
        startDeleteJob (_user + clientCertificatePEMC);

        // CA cert slots
        for (auto i = 0; i < _clientSslCaCertificates.count (); i++) {
            startDeleteJob (_user + clientCaCertificatePEMC + string.number (i));
        }

    // FIXME MS@2019-12-07 -.
    }
    // <-- FIXME MS@2019-12-07
}

} // namespace Occ
