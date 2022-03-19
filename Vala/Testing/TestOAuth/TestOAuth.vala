/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestOAuth : GLib.Object {

    const GLib.Uri s_oauth_test_server = new GLib.Uri ("oauthtest://someserver/owncloud");

    /***********************************************************
    ***********************************************************/
    private test_basic () {
        OAuthTestCase test;
        test.test ();
    }

    /***********************************************************
    ***********************************************************/
    class TestCloseBrowserDontCrash : OAuthTestCase {

        override Soup.Reply token_reply (Soup.Operation operation, Soup.Request request) {
            //  ASSERT (browser_reply);
            // simulate the fact that the browser is closing the connection
            browser_reply.on_signal_abort ();
            Gtk.Application.process_events ();

            //  ASSERT (state == BrowserOpened);
            state = TokenAsked;

            std.unique_ptr<QBuffer> payload = new std.unique_ptr<QBuffer> (new QBuffer ());
            payload.set_data (token_reply_payload ());
            return new SlowFakePostReply (operation, request, std.move (payload), fake_access_manager);
        }

        override void browser_reply_finished () {
            GLib.assert_true (sender () == browser_reply);
            GLib.assert_true (browser_reply.error == Soup.Reply.OperationCanceledError);
            reply_to_browser_ok = true;
        }
    }

    /***********************************************************
    Test for https://github.com/owncloud/client/pull/6057
    ***********************************************************/
    private test_close_browser_dont_crash () {
        TestCloseBrowserDontCrash test;
        test.test ();
    }


    /***********************************************************
    ***********************************************************/
    class TestRandomConnections : OAuthTestCase {
        override Soup.Reply create_browser_reply (Soup.Request request) {
            GLib.Timeout.single_shot (0, this, () => {
                var port = request.url.port ();
                state = CustomState;
                GLib.List<string> payloads = {
                    "GET FOFOFO HTTP 1/1\n\n",
                    "GET /?code=invalie HTTP 1/1\n\n",
                    "GET /?code=xxxxx&bar=fff",
                    "\0\0\0", // 3 bits!
                    "GET \0\0\0 \n\n\n\n\n\0", // 14 bits!
                    "GET /?code=éléphant\xa5 HTTP\n",
                    "\n\n\n\n",
                };
                foreach (var x in payloads) {
                    var socket = new QTcpSocket (this);
                    socket.connect_to_host ("localhost", port);
                    GLib.assert_true (socket.wait_for_connected ());
                    socket.write (x);
                }

                // Do the actual request a bit later
                GLib.Timeout.single_shot (
                    100,
                    this,
                    () => {
                        GLib.assert_true (state == CustomState);
                        state = BrowserOpened;
                        this.OAuthTestCase.create_browser_reply (request);
                    }
                );
           });
           return null;
        }

        override Soup.Reply token_reply (Soup.Operation operation, Soup.Request request) {
            if (state == CustomState) {
                return new FakeErrorReply (operation, request, this, 500);
            }
            return OAuthTestCase.token_reply (operation, request);
        }

        override void oauth_result (
            OAuth.Result result, string user,
            string token, string refresh_token) {
            if (state != CustomState) {
                return OAuthTestCase.oauth_result (result, user, token, refresh_token);
            }
            GLib.assert_true (result == OAuth.Error);
        }
    }


    /***********************************************************
    ***********************************************************/
    private test_random_connections () {
        // Test that we can send random garbage to the litening socket and it does not prevent the connection
        TestRandomConnections test;
        test.test ();
    }


    /***********************************************************
    ***********************************************************/
    struct TestTokenUrlHasRedirect : OAuthTestCase {

        int redirects_done = 0;

        override Soup.Reply token_reply (Soup.Operation operation, Soup.Request request) {
            //  ASSERT (browser_reply);
            // Kind of reproduces what we had in https://github.com/owncloud/enterprise/issues/2951 (not 1:1)
            if (redirects_done == 0) {
                std.unique_ptr<QBuffer> payload = new std.unique_ptr<QBuffer> (new QBuffer ());
                payload.set_data ("");
                var reply = new SlowFakePostReply (operation, request, std.move (payload), this);
                reply.redirect_to_policy = true;
                redirects_done++;
                return reply;
            } else if  (redirects_done == 1) {
                std.unique_ptr<QBuffer> payload = new std.unique_ptr<QBuffer> (new QBuffer ());
                payload.set_data ("");
                var reply = new SlowFakePostReply (operation, request, std.move (payload), this);
                reply.redirect_to_token = true;
                redirects_done++;
                return reply;
            } else {
                // ^^ This is with a custom reply and not actually HTTP, so we're testing the HTTP redirect code
                // we have in AbstractNetworkJob.on_signal_finished ()
                redirects_done++;
                return OAuthTestCase.token_reply (operation, request);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private test_token_url_has_redirect () {
        TestTokenUrlHasRedirect test;
        test.test ();
    }

}

} // namespace Testing
} // namespace Occ
