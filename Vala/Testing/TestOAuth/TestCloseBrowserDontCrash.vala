namespace Occ {
namespace Testing {

/***********************************************************
@class TestCloseBrowserDontCrash

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
class TestCloseBrowserDontCrash : AbstractTestOAuth {

    /***********************************************************
    Test for https://github.com/owncloud/client/pull/6057
    ***********************************************************/
    private TestCloseBrowserDontCrash () {
        this.test ();
    }


    override GLib.InputStream token_reply (Soup.Operation operation, Soup.Request request) {
        //  ASSERT (browser_reply);
        // simulate the fact that the browser is closing the connection
        browser_reply.on_signal_abort ();
        Gtk.Application.process_events ();

        //  ASSERT (state == AbstractTestOAuth.State.BROWSER_OPENED);
        state = AbstractTestOAuth.State.TOKEN_ASKED;

        GLib.OutputStream payload = new new GLib.OutputStream ();
        payload.set_data (token_reply_payload ());
        return new SlowFakePostReply (operation, request, std.move (payload), fake_access_manager);
    }

    override void browser_reply_finished () {
        GLib.assert_true (sender () == browser_reply);
        GLib.assert_true (browser_reply.error == GLib.InputStream.OperationCanceledError);
        reply_to_browser_ok = true;
    }

} // class TestCloseBrowserDontCrash

} // namespace Testing
} // namespace Occ
