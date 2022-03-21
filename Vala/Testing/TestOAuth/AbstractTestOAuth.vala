namespace Occ {
namespace Testing {

/***********************************************************
@class AbstractTestOAuth

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public abstract class AbstractTestOAuth : GLib.Object {

    protected DesktopServiceHook desktop_service_hook;

    protected const GLib.Uri s_oauth_test_server = new GLib.Uri ("oauthtest://someserver/owncloud");

    /***********************************************************
    ***********************************************************/
    protected enum State {
        StartState,
        BrowserOpened,
        TokenAsked,
        CustomState
    }

    protected State state = StartState;

    /***********************************************************
    ***********************************************************/
    protected bool reply_to_browser_ok = false;
    protected bool got_auth_ok = false;

    /***********************************************************
    ***********************************************************/
    protected FakeQNAM fake_soup_context;
    protected Soup.Context real_soup_context;
    protected Soup.Reply browser_reply;

    protected string code = generate_etag ();

    /***********************************************************
    ***********************************************************/
    protected Account account;

    /***********************************************************
    ***********************************************************/
    protected OAuth oauth;

    protected virtual bool finished () {
        return reply_to_browser_ok && got_auth_ok;
    }


    /***********************************************************
    ***********************************************************/
    protected virtual void test () {
        fake_soup_context = new FakeQNAM ({});
        account = Account.create ();
        account.set_url (s_oauth_test_server);
        account.set_credentials (new FakeCredentials (fake_soup_context));
        fake_soup_context.set_parent (this);
        fake_soup_context.set_override (this.oauth_test_case_override);

        desktop_service_hook.signal_hooked.connect (
            this.on_signal_open_browser_hook
        );

        oauth.on_signal_reset (new OAuth (account, null));
        oauth.signal_result.connect (
            this.on_signal_oauth_result
        );
        oauth.on_signal_start ();
        QTRY_VERIFY (signal_finished ());
    }


    protected Soup.Reply oauth_test_case_override (Soup.Operation operation, Soup.Request request, QIODevice device) {
        //  ASSERT (device);
        //  ASSERT (device.bytes_available ()>0); // OAuth2 always sends around POST data.
        return this.token_reply (operation, request);
    }


    /***********************************************************
    ***********************************************************/
    protected virtual void on_signal_open_browser_hook (GLib.Uri url) {
        GLib.assert_true (state == StartState);
        state = BrowserOpened;
        GLib.assert_true (url.path == s_oauth_test_server.path + "/index.php/apps/oauth2/authorize");
        GLib.assert_true (url.to_string ().starts_with (s_oauth_test_server.to_string ()));
        QUrlQuery query = new QUrlQuery (url);
        GLib.assert_true (query.query_item_value ("response_type") == "code");
        GLib.assert_true (query.query_item_value ("client_id") == Theme.oauth_client_id);
        GLib.Uri redirect_uri = new GLib.Uri (query.query_item_value ("redirect_uri"));
        GLib.assert_true (redirect_uri.host () == "localhost");
        redirect_uri.set_query ("code=" + code);
        create_browser_reply (Soup.Request (redirect_uri));
    }


    /***********************************************************
    ***********************************************************/
    protected virtual Soup.Reply create_browser_reply (Soup.Request request) {
        browser_reply = real_soup_context.get (request);
        browser_reply.signal_finished.connect (
            this.on_signal_browser_reply_finished);
        return browser_reply;
    }


    /***********************************************************
    ***********************************************************/
    protected virtual void on_signal_browser_reply_finished () {
        GLib.assert_true (sender () == browser_reply);
        GLib.assert_true (state == TokenAsked);
        browser_reply.delete_later ();
        GLib.assert_true (browser_reply.raw_header ("Location") == "owncloud://on_signal_success");
        reply_to_browser_ok = true;
    }


    /***********************************************************
    ***********************************************************/
    protected virtual Soup.Reply token_reply (Soup.Operation operation, Soup.Request request) {
        //  ASSERT (state == BrowserOpened);
        state = TokenAsked;
        //  ASSERT (operation == Soup.PostOperation);
        //  ASSERT (request.url.to_string ().starts_with (s_oauth_test_server.to_string ()));
        //  ASSERT (request.url.path == s_oauth_test_server.path + "/index.php/apps/oauth2/api/v1/token");
        std.unique_ptr<QBuffer> payload = new std.unique_ptr<QBuffer> (new QBuffer ());
        payload.set_data (token_reply_payload ());
        return new FakePostReply (operation, request, std.move (payload), fake_soup_context);
    }


    /***********************************************************
    ***********************************************************/
    protected virtual string token_reply_payload () {
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
    protected virtual void on_signal_oauth_result (OAuth.Result result, string user, string token , string refresh_token) {
        GLib.assert_true (state == TokenAsked);
        GLib.assert_true (result == OAuth.LoggedIn);
        GLib.assert_true (user == "789");
        GLib.assert_true (token == "123");
        GLib.assert_true (refresh_token == "456");
        got_auth_ok = true;
    }

} // class AbstractTestOAuth
} // namespace Testing
} // namespace Occ
