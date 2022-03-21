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

} // class TestCloseBrowserDontCrash

} // namespace Testing
} // namespace Occ
