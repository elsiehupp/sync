/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

using Occ;

namespace Testing {

class OAuthTestCase : GLib.Object {

    DesktopServiceHook desktopServiceHook;

    /***********************************************************
    ***********************************************************/
    public enum State {
        StartState,
        BrowserOpened,
        TokenAsked,
        CustomState
    }
    
    public State state = StartState;

    /***********************************************************
    ***********************************************************/
    public bool reply_to_browser_ok = false;
    public bool got_auth_ok = false;

    /***********************************************************
    ***********************************************************/
    public FakeQNAM fake_qnam;
    public Soup real_qnam;
    public Soup.Reply browser_reply;


    public string code = generate_etag ();

    /***********************************************************
    ***********************************************************/
    public Occ.AccountPointer account;

    /***********************************************************
    ***********************************************************/
    public OAuth oauth;


    public virtual bool signal_done () {
        return reply_to_browser_ok && got_auth_ok;
    }


    /***********************************************************
    ***********************************************************/
    public virtual void test () {
        fake_qnam = new FakeQNAM ({});
        account = Occ.Account.create ();
        account.set_url (sOAuthTestServer);
        account.set_credentials (new FakeCredentials (fake_qnam));
        fake_qnam.setParent (this);
        fake_qnam.set_override ([this] (Soup.Operation operation, Soup.Request request, QIODevice device) {
            //  ASSERT (device);
            //  ASSERT (device.bytes_available ()>0); // OAuth2 always sends around POST data.
            return this.tokenReply (operation, request);
        });

        GLib.Object.connect (&desktopServiceHook, &DesktopServiceHook.signal_hooked,
                         this, &OAuthTestCase.openBrowserHook);

        oauth.on_signal_reset (new OAuth (account.data (), null));
        GLib.Object.connect (oauth.data (), &OAuth.result, this, &OAuthTestCase.oauthResult);
        oauth.on_signal_start ();
        QTRY_VERIFY (signal_done ());
    }


    /***********************************************************
    ***********************************************************/
    public virtual void openBrowserHook (GLib.Uri url) {
        GLib.assert_cmp (state, StartState);
        state = BrowserOpened;
        GLib.assert_cmp (url.path (), string (sOAuthTestServer.path () + "/index.php/apps/oauth2/authorize"));
        GLib.assert_true (url.to_string ().starts_with (sOAuthTestServer.to_string ()));
        QUrlQuery query = new QUrlQuery (url);
        GLib.assert_cmp (query.query_item_value ("response_type"), "code");
        GLib.assert_cmp (query.query_item_value ("client_id"), Theme.instance ().oauthClientId ());
        GLib.Uri redirectUri = new GLib.Uri (query.query_item_value ("redirect_uri"));
        GLib.assert_cmp (redirectUri.host (), "localhost");
        redirectUri.setQuery ("code=" + code);
        createBrowserReply (Soup.Request (redirectUri));
    }


    /***********************************************************
    ***********************************************************/
    public virtual Soup.Reply createBrowserReply (Soup.Request request) {
        browser_reply = real_qnam.get (request);
        GLib.Object.connect (browser_reply, &Soup.Reply.on_signal_finished, this, &OAuthTestCase.browserReplyFinished);
        return browser_reply;
    }


    /***********************************************************
    ***********************************************************/
    public virtual void browserReplyFinished () {
        GLib.assert_cmp (sender (), browser_reply.data ());
        GLib.assert_cmp (state, TokenAsked);
        browser_reply.delete_later ();
        GLib.assert_cmp (browser_reply.raw_header ("Location"), GLib.ByteArray ("owncloud://on_signal_success"));
        reply_to_browser_ok = true;
    }

    /***********************************************************
    ***********************************************************/
    public virtual Soup.Reply tokenReply (Soup.Operation operation, Soup.Request request) {
        //  ASSERT (state == BrowserOpened);
        state = TokenAsked;
        //  ASSERT (operation == Soup.PostOperation);
        //  ASSERT (request.url ().to_string ().starts_with (sOAuthTestServer.to_string ()));
        //  ASSERT (request.url ().path () == sOAuthTestServer.path () + "/index.php/apps/oauth2/api/v1/token");
        std.unique_ptr<QBuffer> payload = new std.unique_ptr<QBuffer> (new QBuffer ());
        payload.setData (tokenReplyPayload ());
        return new FakePostReply (operation, request, std.move (payload), fake_qnam);
    }


    /***********************************************************
    ***********************************************************/
    public virtual GLib.ByteArray tokenReplyPayload () {
        QJsonDocument jsondata = new QJsonObject (
            { "access_token", "123" },
            { "refresh_token" , "456" },
            { "message_url",  "owncloud://on_signal_success"},
            { "user_id", "789" },
            { "token_type", "Bearer" }
        );
        return jsondata.to_json ();
    }


    /***********************************************************
    ***********************************************************/
    public virtual void oauthResult (OAuth.Result result, string user, string token , string refreshToken) {
        GLib.assert_cmp (state, TokenAsked);
        GLib.assert_cmp (result, OAuth.LoggedIn);
        GLib.assert_cmp (user, string ("789"));
        GLib.assert_cmp (token, string ("123"));
        GLib.assert_cmp (refreshToken, string ("456"));
        got_auth_ok = true;
    }

} // class OAuthTestCase
} // namespace Testing
