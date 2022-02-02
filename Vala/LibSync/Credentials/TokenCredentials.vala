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

    /***********************************************************
    ***********************************************************/
    public friend class TokenCredentialsAccessManager;
    public TokenCredentials ();


    /***********************************************************
    ***********************************************************/
    public TokenCredentials (string user, string password, string token);

    /***********************************************************
    ***********************************************************/
    public string auth_type () override;
    public QNetworkAccessManager create_qNAM () override;
    public bool ready () override;
    public void ask_from_user () override;
    public void fetch_from_keychain () override;
    public bool still_valid (QNetworkReply reply) override;
    public void persist () override;
    public string user () override;
    public void invalidate_token () override;
    public void forget_sensitive_data () override;

    string password ();

    /***********************************************************
    ***********************************************************/
    private void on_authentication (QNetworkReply *, QAuthenticator *);

    /***********************************************************
    ***********************************************************/
    private 
    private string this.user;
    private string this.password;
    private string this.token; // the cookies
    private bool this.ready;
};


    namespace {

        const char authentication_failed_c[] = "owncloud-authentication-failed";

    } // ns

    class TokenCredentialsAccessManager : AccessManager {

        public friend class TokenCredentials;
        public TokenCredentialsAccessManager (TokenCredentials cred, GLib.Object parent = new GLib.Object ())
            : AccessManager (parent)
            , this.cred (cred) {
        }


        protected QNetworkReply create_request (Operation op, Soup.Request request, QIODevice outgoing_data) {
            if (this.cred.user ().is_empty () || this.cred.password ().is_empty ()) {
                GLib.warn (lc_token_credentials) << "Empty user/password provided!";
            }

            Soup.Request req (request);

            GLib.ByteArray cred_hash = GLib.ByteArray (this.cred.user ().to_utf8 () + ":" + this.cred.password ().to_utf8 ()).to_base64 ();
            req.set_raw_header (GLib.ByteArray ("Authorization"), GLib.ByteArray ("Basic ") + cred_hash);

            // A pre-authenticated cookie
            GLib.ByteArray token = this.cred._token.to_utf8 ();
            if (token.length () > 0) {
                set_raw_cookie (token, request.url ());
            }

            return AccessManager.create_request (op, req, outgoing_data);
        }


        private const TokenCredentials this.cred;
    };

    TokenCredentials.TokenCredentials ()
        : this.user ()
        , this.password ()
        , this.ready (false) {
    }

    TokenCredentials.TokenCredentials (string user, string password, string token)
        : this.user (user)
        , this.password (password)
        , this.token (token)
        , this.ready (true) {
    }

    string TokenCredentials.auth_type () {
        return string.from_latin1 ("token");
    }

    string TokenCredentials.user () {
        return this.user;
    }

    string TokenCredentials.password () {
        return this.password;
    }

    QNetworkAccessManager *TokenCredentials.create_qNAM () {
        AccessManager qnam = new TokenCredentialsAccessManager (this);

        connect (qnam, SIGNAL (authentication_required (QNetworkReply *, QAuthenticator *)),
            this, SLOT (on_authentication (QNetworkReply *, QAuthenticator *)));

        return qnam;
    }

    bool TokenCredentials.ready () {
        return this.ready;
    }

    void TokenCredentials.fetch_from_keychain () {
        this.was_fetched = true;
        Q_EMIT fetched ();
    }

    void TokenCredentials.ask_from_user () {
        /* emit */ asked ();
    }

    bool TokenCredentials.still_valid (QNetworkReply reply) {
        return ( (reply.error () != QNetworkReply.AuthenticationRequiredError)
            // returned if user/password or token are incorrect
            && (reply.error () != QNetworkReply.OperationCanceledError
                   || !reply.property (authentication_failed_c).to_bool ()));
    }

    void TokenCredentials.invalidate_token () {
        q_c_info (lc_token_credentials) << "Invalidating token";
        this.ready = false;
        this.account.clear_cookie_jar ();
        this.token = "";
        this.user = "";
        this.password = "";
    }

    void TokenCredentials.forget_sensitive_data () {
        invalidate_token ();
    }

    void TokenCredentials.persist () {
    }

    void TokenCredentials.on_authentication (QNetworkReply reply, QAuthenticator authenticator) {
        Q_UNUSED (authenticator)
        // we cannot use QAuthenticator, because it sends username and passwords with latin1
        // instead of utf8 encoding. Instead, we send it manually. Thus, if we reach this signal,
        // those credentials were invalid and we terminate.
        GLib.warn (lc_token_credentials) << "Stop request : Authentication failed for " << reply.url ().to_string ();
        reply.set_property (authentication_failed_c, true);
        reply.close ();
    }

    } // namespace Occ
    