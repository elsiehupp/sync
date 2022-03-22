namespace Occ {
namespace Testing {

/***********************************************************
@class TestTokenUrlHasRedirect

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
class TestTokenUrlHasRedirect : AbstractTestOAuth {

    int redirects_done = 0;

    /***********************************************************
    ***********************************************************/
    private TestTokenUrlHasRedirect () {
        this.test ();
    }


    /***********************************************************
    ***********************************************************/
    private override GLib.InputStream token_reply (Soup.Operation operation, Soup.Request request) {
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
            return AbstractTestOAuth.token_reply (operation, request);
        }
    }

} // class TestTokenUrlHasRedirect

} // namespace Testing
} // namespace Occ
