namespace Occ {
namespace Testing {

/***********************************************************
@class TestRandomConnections

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
class TestRandomConnections : AbstractTestOAuth {

    /***********************************************************
    Test that we can send random garbage to the litening socket
    and it does not prevent the connection
    ***********************************************************/
    private TestRandomConnections () {
        this.test ();
    }

    /***********************************************************
    ***********************************************************/
    private override Soup.Reply create_browser_reply (Soup.Request request) {
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
                    this.AbstractTestOAuth.create_browser_reply (request);
                }
            );
        });
        return null;
    }


    /***********************************************************
    ***********************************************************/
    private override Soup.Reply token_reply (Soup.Operation operation, Soup.Request request) {
        if (state == CustomState) {
            return new FakeErrorReply (operation, request, this, 500);
        }
        return AbstractTestOAuth.token_reply (operation, request);
    }


    /***********************************************************
    ***********************************************************/
    private override void oauth_result (
        OAuth.Result result, string user,
        string token, string refresh_token) {
        if (state != CustomState) {
            return AbstractTestOAuth.oauth_result (result, user, token, refresh_token);
        }
        GLib.assert_true (result == OAuth.Error);
    }

} // class TestRandomConnections

} // namespace Testing
} // namespace Occ
