/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>
Copyright (c) by Markus Goetz <guruz@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <QMutex>
//  #include <GLib.Settings>
//  #include <QNetworkCookieJar>

namespace Occ {
namespace LibSync {

class TokenCredentials : AbstractCredentials {

    const string AUTHENTICATION_FAILED_C = "owncloud-authentication-failed";

    /***********************************************************
    ***********************************************************/
    //  public friend class TokenCredentialsAccessManager;


    /***********************************************************
    ***********************************************************/
    string user { public get; private set; }


    /***********************************************************
    ***********************************************************/
    new string password { public get; private set; }

    /***********************************************************
    The cookies
    ***********************************************************/
    private string token;

    /***********************************************************
    ***********************************************************/
    new bool ready { private set; public get; }

    /***********************************************************
    ***********************************************************/
    public TokenCredentials (string user = "", string password = "", string token = "") {
        this.user = user;
        this.password = password;
        this.token = token;
        if (token == "") {
            this.ready = false;
        } else {
            this.ready = true;
        }
    }


    /***********************************************************
    ***********************************************************/
    public string auth_type () {
        return "token";
    }


    /***********************************************************
    ***********************************************************/
    public new QNetworkAccessManager create_qnam () {
        AccessManager qnam = new TokenCredentialsAccessManager (this);

        connect (qnam, SIGNAL (authentication_required (Soup.Reply reply, QAuthenticator auth)),
            this, SLOT (on_signal_authentication (Soup.Reply reply, QAuthenticator auth)));

        return qnam;
    }


    /***********************************************************
    ***********************************************************/
    public new void ask_from_user () {
        /* emit */ asked ();
    }


    /***********************************************************
    ***********************************************************/
    public new void fetch_from_keychain () {
        this.was_fetched = true;
        /* Q_EMIT */ fetched ();
    }


    /***********************************************************
    ***********************************************************/
    public new bool still_valid (Soup.Reply reply) {
        return ( (reply.error () != Soup.Reply.AuthenticationRequiredError)
            // returned if user/password or token are incorrect
            && (reply.error () != Soup.Reply.OperationCanceledError
                   || !reply.property (AUTHENTICATION_FAILED_C).to_bool ()));
    }


    /***********************************************************
    ***********************************************************/
    public new void persist () { }


    /***********************************************************
    ***********************************************************/
    public void invalidate_token () {
        GLib.info ("Invalidating token");
        this.ready = false;
        this.account.clear_cookie_jar ();
        this.token = "";
        this.user = "";
        this.password = "";
    }


    /***********************************************************
    ***********************************************************/
    public new void forget_sensitive_data () {
        invalidate_token ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_authentication (Soup.Reply reply, QAuthenticator authenticator) {
        //  Q_UNUSED (authenticator)
        // we cannot use QAuthenticator, because it sends username and passwords with latin1
        // instead of utf8 encoding. Instead, we send it manually. Thus, if we reach this signal,
        // those credentials were invalid and we terminate.
        GLib.warning ("Stop request: Authentication failed for " + reply.url ().to_string ());
        reply.property (AUTHENTICATION_FAILED_C, true);
        reply.close ();
    }

} // class TokenCredentials

} // namespace LibSync
} // namespace Occ
    