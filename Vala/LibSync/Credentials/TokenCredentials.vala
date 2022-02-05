/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>
Copyright (c) by Markus Goetz <guruz@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <QMutex>
//  #include <QSettings>
//  #include <QNetworkCookieJar>

namespace Occ {

class TokenCredentials : AbstractCredentials {

    const string AUTHENTICATION_FAILED_C = "owncloud-authentication-failed";

    /***********************************************************
    ***********************************************************/
    //  public friend class TokenCredentialsAccessManager;


    /***********************************************************
    ***********************************************************/
    private string this.user;
    private string this.password;


    /***********************************************************
    The cookies
    ***********************************************************/
    private string this.token;


    /***********************************************************
    ***********************************************************/
    private bool this.ready;


    /***********************************************************
    ***********************************************************/
    public TokenCredentials () {
        this.user = "";
        this.password = "";
        this.ready = false;
    }


    /***********************************************************
    ***********************************************************/
    public TokenCredentials (string user, string password, string token) {
        this.user = user;
        this.password = password;
        this.token = token;
        this.ready = true;
    }


    /***********************************************************
    ***********************************************************/
    public string auth_type () {
        return "token";
    }


    /***********************************************************
    ***********************************************************/
    public QNetworkAccessManager create_qnam () {
        AccessManager qnam = new TokenCredentialsAccessManager (this);

        connect (qnam, SIGNAL (authentication_required (Soup.Reply *, QAuthenticator *)),
            this, SLOT (on_authentication (Soup.Reply *, QAuthenticator *)));

        return qnam;
    }


    /***********************************************************
    ***********************************************************/
    public bool ready () {
        return this.ready;
    }


    /***********************************************************
    ***********************************************************/
    public void ask_from_user () {
        /* emit */ asked ();
    }


    /***********************************************************
    ***********************************************************/
    public void fetch_from_keychain () {
        this.was_fetched = true;
        /* Q_EMIT */ fetched ();
    }


    /***********************************************************
    ***********************************************************/
    public bool still_valid (Soup.Reply reply) {
        return ( (reply.error () != Soup.Reply.AuthenticationRequiredError)
            // returned if user/password or token are incorrect
            && (reply.error () != Soup.Reply.OperationCanceledError
                   || !reply.property (AUTHENTICATION_FAILED_C).to_bool ()));
    }


    /***********************************************************
    ***********************************************************/
    public void persist () {
    }


    /***********************************************************
    ***********************************************************/
    public string user () {
        return this.user;
    }


    /***********************************************************
    ***********************************************************/
    public void invalidate_token () {
        GLib.info (lc_token_credentials) << "Invalidating token";
        this.ready = false;
        this.account.clear_cookie_jar ();
        this.token = "";
        this.user = "";
        this.password = "";
    }


    /***********************************************************
    ***********************************************************/
    public void forget_sensitive_data () {
        invalidate_token ();
    }




    /***********************************************************
    ***********************************************************/
    public string password () {
        return this.password;
    }


    /***********************************************************
    ***********************************************************/
    private void on_authentication (Soup.Reply reply, QAuthenticator authenticator) {
        //  Q_UNUSED (authenticator)
        // we cannot use QAuthenticator, because it sends username and passwords with latin1
        // instead of utf8 encoding. Instead, we send it manually. Thus, if we reach this signal,
        // those credentials were invalid and we terminate.
        GLib.warn (lc_token_credentials) << "Stop request : Authentication failed for " << reply.url ().to_string ();
        reply.property (AUTHENTICATION_FAILED_C, true);
        reply.close ();
    }

} // class TokenCredentials

} // namespace Occ
    