namespace Occ {
namespace LibSync {

/***********************************************************
@class TokenCredentials

@author Klaas Freitag <freitag@kde.org>
@author by Markus Goetz <guruz@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class TokenCredentials : AbstractCredentials {

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
    public string auth_type_string () {
        return "token";
    }


    /***********************************************************
    ***********************************************************/
    public new Soup.Session create_access_manager () {
        Soup.ClientContext soup_context = new TokenCredentialsAccessManager (this);

        soup_context.authentication_required.connect (
            this.on_signal_authentication
        );

        return soup_context;
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
    public new bool still_valid (GLib.InputStream reply) {
        return ( (reply.error != GLib.InputStream.AuthenticationRequiredError)
            // returned if user/password or token are incorrect
            && (reply.error != GLib.InputStream.OperationCanceledError
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
    private void on_signal_authentication (GLib.InputStream reply, GLib.Authenticator authenticator) {
        //  Q_UNUSED (authenticator)
        // we cannot use GLib.Authenticator, because it sends username and passwords with latin1
        // instead of utf8 encoding. Instead, we send it manually. Thus, if we reach this signal,
        // those credentials were invalid and we terminate.
        GLib.warning ("Stop request: Authentication failed for " + reply.url.to_string ());
        reply.property (AUTHENTICATION_FAILED_C, true);
        reply.close ();
    }

} // class TokenCredentials

} // namespace LibSync
} // namespace Occ
    