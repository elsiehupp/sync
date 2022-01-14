/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>
Copyright (c) by Markus Goetz <guruz@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QMutex>
// #include <QNetworkReply>
// #include <QSettings>
// #include <QNetwork_cookie_jar>

// #include <QMap>


namespace QKeychain {
}

namespace Occ {

class Token_credentials : AbstractCredentials {

public:
    friend class Token_credentials_access_manager;
    Token_credentials ();
    Token_credentials (string &user, string &password, string &token);

    string auth_type () const override;
    QNetworkAccessManager *create_qNAM () const override;
    bool ready () const override;
    void ask_from_user () override;
    void fetch_from_keychain () override;
    bool still_valid (QNetworkReply *reply) override;
    void persist () override;
    string user () const override;
    void invalidate_token () override;
    void forget_sensitive_data () override;

    string password ();
private slots:
    void slot_authentication (QNetworkReply *, QAuthenticator *);

private:
    string _user;
    string _password;
    string _token; // the cookies
    bool _ready;
};


    namespace {
    
        const char authentication_failed_c[] = "owncloud-authentication-failed";
    
    } // ns
    
    class Token_credentials_access_manager : AccessManager {
    public:
        friend class Token_credentials;
        Token_credentials_access_manager (Token_credentials *cred, GLib.Object *parent = nullptr)
            : AccessManager (parent)
            , _cred (cred) {
        }
    
    protected:
        QNetworkReply *create_request (Operation op, QNetworkRequest &request, QIODevice *outgoing_data) {
            if (_cred.user ().is_empty () || _cred.password ().is_empty ()) {
                q_c_warning (lc_token_credentials) << "Empty user/password provided!";
            }
    
            QNetworkRequest req (request);
    
            QByteArray cred_hash = QByteArray (_cred.user ().to_utf8 () + ":" + _cred.password ().to_utf8 ()).to_base64 ();
            req.set_raw_header (QByteArray ("Authorization"), QByteArray ("Basic ") + cred_hash);
    
            // A pre-authenticated cookie
            QByteArray token = _cred._token.to_utf8 ();
            if (token.length () > 0) {
                set_raw_cookie (token, request.url ());
            }
    
            return AccessManager.create_request (op, req, outgoing_data);
        }
    
    private:
        const Token_credentials *_cred;
    };
    
    Token_credentials.Token_credentials ()
        : _user ()
        , _password ()
        , _ready (false) {
    }
    
    Token_credentials.Token_credentials (string &user, string &password, string &token)
        : _user (user)
        , _password (password)
        , _token (token)
        , _ready (true) {
    }
    
    string Token_credentials.auth_type () {
        return string.from_latin1 ("token");
    }
    
    string Token_credentials.user () {
        return _user;
    }
    
    string Token_credentials.password () {
        return _password;
    }
    
    QNetworkAccessManager *Token_credentials.create_qNAM () {
        AccessManager *qnam = new Token_credentials_access_manager (this);
    
        connect (qnam, SIGNAL (authentication_required (QNetworkReply *, QAuthenticator *)),
            this, SLOT (slot_authentication (QNetworkReply *, QAuthenticator *)));
    
        return qnam;
    }
    
    bool Token_credentials.ready () {
        return _ready;
    }
    
    void Token_credentials.fetch_from_keychain () {
        _was_fetched = true;
        Q_EMIT fetched ();
    }
    
    void Token_credentials.ask_from_user () {
        emit asked ();
    }
    
    bool Token_credentials.still_valid (QNetworkReply *reply) {
        return ( (reply.error () != QNetworkReply.AuthenticationRequiredError)
            // returned if user/password or token are incorrect
            && (reply.error () != QNetworkReply.Operation_canceled_error
                   || !reply.property (authentication_failed_c).to_bool ()));
    }
    
    void Token_credentials.invalidate_token () {
        q_c_info (lc_token_credentials) << "Invalidating token";
        _ready = false;
        _account.clear_cookie_jar ();
        _token = string ();
        _user = string ();
        _password = string ();
    }
    
    void Token_credentials.forget_sensitive_data () {
        invalidate_token ();
    }
    
    void Token_credentials.persist () {
    }
    
    void Token_credentials.slot_authentication (QNetworkReply *reply, QAuthenticator *authenticator) {
        Q_UNUSED (authenticator)
        // we cannot use QAuthenticator, because it sends username and passwords with latin1
        // instead of utf8 encoding. Instead, we send it manually. Thus, if we reach this signal,
        // those credentials were invalid and we terminate.
        q_c_warning (lc_token_credentials) << "Stop request : Authentication failed for " << reply.url ().to_string ();
        reply.set_property (authentication_failed_c, true);
        reply.close ();
    }
    
    } // namespace Occ
    