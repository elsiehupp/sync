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
    protected override GLib.InputStream create_browser_reply (Soup.Request request) {
        GLib.Timeout.add (0, this.on_signal_timeout);
        return null;
    }

    private bool on_signal_timeout () {
        var port = request.url.port ();
        state = AbstractTestOAuth.State.CUSTOM_STATE;
        GLib.List<string> payloads = new GLib.List<string> ();
        payloads.append ("GET FOFOFO HTTP 1/1\n\n");
        payloads.append ("GET /?code=invalie HTTP 1/1\n\n");
        payloads.append ("GET /?code=xxxxx&bar=fff");
        payloads.append ("\0\0\0"); // 3 bits!
        payloads.append ("GET \0\0\0 \n\n\n\n\n\0"); // 14 bits!
        payloads.append ("GET /?code=éléphant\xa5 HTTP\n");
        payloads.append ("\n\n\n\n");
        foreach (var x in payloads) {
            var socket = new GLib.TcpSocket (this);
            socket.connect_to_host ("localhost", port);
            GLib.assert_true (socket.wait_for_connected ());
            socket.write (x);
        }

        // Do the actual request a bit later
        GLib.Timeout.add (100, this.on_signal_request);
        return false; // only run once
    }


    private bool on_signal_request () {
        GLib.assert_true (state == AbstractTestOAuth.State.CUSTOM_STATE);
        state = AbstractTestOAuth.State.BROWSER_OPENED;
        base.create_browser_reply (request);
        return false; // only run once
    }


    /***********************************************************
    ***********************************************************/
    internal override GLib.InputStream token_reply (Soup.Operation operation, Soup.Request request) {
        if (state == AbstractTestOAuth.State.CUSTOM_STATE) {
            return new FakeErrorReply (operation, request, this, 500);
        }
        return base.token_reply (operation, request);
    }


    /***********************************************************
    ***********************************************************/
    private override void oauth_result (
        Gui.OAuth.Result result, string user,
        string token, string refresh_token) {
        if (state != AbstractTestOAuth.State.CUSTOM_STATE) {
            return base.oauth_result (result, user, token, refresh_token);
        }
        GLib.assert_true (result == Gui.OAuth.Error);
    }

} // class TestRandomConnections

} // namespace Testing
} // namespace Occ
