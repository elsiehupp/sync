/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>
Copyright (c) by Markus Goetz <guruz@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QMutex>
// #include <QNetworkReply>
// #include <QSettings>
// #include <QNetworkCookieJar>

// #include <QMap>


namespace QKeychain {
}

namespace Occ {

class TokenCredentials : AbstractCredentials {

public:
    friend class TokenCredentialsAccessManager;
    TokenCredentials ();
    TokenCredentials (string &user, string &password, string &token);

    string authType () const override;
    QNetworkAccessManager *createQNAM () const override;
    bool ready () const override;
    void askFromUser () override;
    void fetchFromKeychain () override;
    bool stillValid (QNetworkReply *reply) override;
    void persist () override;
    string user () const override;
    void invalidateToken () override;
    void forgetSensitiveData () override;

    string password ();
private slots:
    void slotAuthentication (QNetworkReply *, QAuthenticator *);

private:
    string _user;
    string _password;
    string _token; // the cookies
    bool _ready;
};


    namespace {
    
        const char authenticationFailedC[] = "owncloud-authentication-failed";
    
    } // ns
    
    class TokenCredentialsAccessManager : AccessManager {
    public:
        friend class TokenCredentials;
        TokenCredentialsAccessManager (TokenCredentials *cred, GLib.Object *parent = nullptr)
            : AccessManager (parent)
            , _cred (cred) {
        }
    
    protected:
        QNetworkReply *createRequest (Operation op, QNetworkRequest &request, QIODevice *outgoingData) {
            if (_cred.user ().isEmpty () || _cred.password ().isEmpty ()) {
                qCWarning (lcTokenCredentials) << "Empty user/password provided!";
            }
    
            QNetworkRequest req (request);
    
            QByteArray credHash = QByteArray (_cred.user ().toUtf8 () + ":" + _cred.password ().toUtf8 ()).toBase64 ();
            req.setRawHeader (QByteArray ("Authorization"), QByteArray ("Basic ") + credHash);
    
            // A pre-authenticated cookie
            QByteArray token = _cred._token.toUtf8 ();
            if (token.length () > 0) {
                setRawCookie (token, request.url ());
            }
    
            return AccessManager.createRequest (op, req, outgoingData);
        }
    
    private:
        const TokenCredentials *_cred;
    };
    
    TokenCredentials.TokenCredentials ()
        : _user ()
        , _password ()
        , _ready (false) {
    }
    
    TokenCredentials.TokenCredentials (string &user, string &password, string &token)
        : _user (user)
        , _password (password)
        , _token (token)
        , _ready (true) {
    }
    
    string TokenCredentials.authType () {
        return string.fromLatin1 ("token");
    }
    
    string TokenCredentials.user () {
        return _user;
    }
    
    string TokenCredentials.password () {
        return _password;
    }
    
    QNetworkAccessManager *TokenCredentials.createQNAM () {
        AccessManager *qnam = new TokenCredentialsAccessManager (this);
    
        connect (qnam, SIGNAL (authenticationRequired (QNetworkReply *, QAuthenticator *)),
            this, SLOT (slotAuthentication (QNetworkReply *, QAuthenticator *)));
    
        return qnam;
    }
    
    bool TokenCredentials.ready () {
        return _ready;
    }
    
    void TokenCredentials.fetchFromKeychain () {
        _wasFetched = true;
        Q_EMIT fetched ();
    }
    
    void TokenCredentials.askFromUser () {
        emit asked ();
    }
    
    bool TokenCredentials.stillValid (QNetworkReply *reply) {
        return ( (reply.error () != QNetworkReply.AuthenticationRequiredError)
            // returned if user/password or token are incorrect
            && (reply.error () != QNetworkReply.OperationCanceledError
                   || !reply.property (authenticationFailedC).toBool ()));
    }
    
    void TokenCredentials.invalidateToken () {
        qCInfo (lcTokenCredentials) << "Invalidating token";
        _ready = false;
        _account.clearCookieJar ();
        _token = string ();
        _user = string ();
        _password = string ();
    }
    
    void TokenCredentials.forgetSensitiveData () {
        invalidateToken ();
    }
    
    void TokenCredentials.persist () {
    }
    
    void TokenCredentials.slotAuthentication (QNetworkReply *reply, QAuthenticator *authenticator) {
        Q_UNUSED (authenticator)
        // we cannot use QAuthenticator, because it sends username and passwords with latin1
        // instead of utf8 encoding. Instead, we send it manually. Thus, if we reach this signal,
        // those credentials were invalid and we terminate.
        qCWarning (lcTokenCredentials) << "Stop request : Authentication failed for " << reply.url ().toString ();
        reply.setProperty (authenticationFailedC, true);
        reply.close ();
    }
    
    } // namespace Occ
    