/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest/QtTest>
//  #include <QDesktopServices>

using Occ;

namespace Testing {

class TestOAuth : GLib.Object {

    const GLib.Uri sOAuthTestServer = new GLib.Uri ("oauthtest://someserver/owncloud");

    /***********************************************************
    ***********************************************************/
    private void testBasic () {
        OAuthTestCase test;
        test.test ();
    }

    class TestCloseBrowserDontCrash : OAuthTestCase {

        override Soup.Reply tokenReply (Soup.Operation operation, Soup.Request request) {
            //  ASSERT (browserReply);
            // simulate the fact that the browser is closing the connection
            browserReply.on_signal_abort ();
            QCoreApplication.processEvents ();

            //  ASSERT (state == BrowserOpened);
            state = TokenAsked;

            std.unique_ptr<QBuffer> payload = new std.unique_ptr<QBuffer> (new QBuffer ());
            payload.setData (tokenReplyPayload ());
            return new SlowFakePostReply (operation, request, std.move (payload), fake_qnam);
        }

        override void browserReplyFinished () {
            //  QCOMPARE (sender (), browserReply.data ());
            //  QCOMPARE (browserReply.error (), Soup.Reply.OperationCanceledError);
            replyToBrowserOk = true;
        }
    }

    // Test for https://github.com/owncloud/client/pull/6057
    private void testCloseBrowserDontCrash () {
        TestCloseBrowserDontCrash test;
        test.test ();
    }


    class TestRandomConnections : OAuthTestCase {
        override Soup.Reply createBrowserReply (Soup.Request request) {
            QTimer.singleShot (0, this, [this, request] {
                var port = request.url ().port ();
                state = CustomState;
                GLib.Vector<GLib.ByteArray> payloads = {
                    "GET FOFOFO HTTP 1/1\n\n",
                    "GET /?code=invalie HTTP 1/1\n\n",
                    "GET /?code=xxxxx&bar=fff",
                    GLib.ByteArray ("\0\0\0", 3),
                    GLib.ByteArray ("GET \0\0\0 \n\n\n\n\n\0", 14),
                    GLib.ByteArray ("GET /?code=éléphant\xa5 HTTP\n"),
                    GLib.ByteArray ("\n\n\n\n"),
                }
                foreach (var x in payloads) {
                    var socket = new QTcpSocket (this);
                    socket.connectToHost ("localhost", port);
                    //  QVERIFY (socket.waitForConnected ());
                    socket.write (x);
                }

                // Do the actual request a bit later
                QTimer.singleShot (100, this, [this, request] {
                    //  QCOMPARE (state, CustomState);
                    state = BrowserOpened;
                    this.OAuthTestCase.createBrowserReply (request);
                });
           });
           return null;
        }

        override Soup.Reply tokenReply (Soup.Operation operation, Soup.Request request) {
            if (state == CustomState) {
                return new FakeErrorReply (operation, request, this, 500);
            }
            return OAuthTestCase.tokenReply (operation, request);
        }

        override void oauthResult (OAuth.Result result, string user, string token ,
                        string refreshToken) {
            if (state != CustomState) {
                return OAuthTestCase.oauthResult (result, user, token, refreshToken);
            }
            //  QCOMPARE (result, OAuth.Error);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testRandomConnections () {
        // Test that we can send random garbage to the litening socket and it does not prevent the connection
        TestRandomConnections test;
        test.test ();
    }


    struct TestTokenUrlHasRedirect : OAuthTestCase {

        int redirectsDone = 0;

        override Soup.Reply tokenReply (Soup.Operation operation, Soup.Request request) {
            //  ASSERT (browserReply);
            // Kind of reproduces what we had in https://github.com/owncloud/enterprise/issues/2951 (not 1:1)
            if (redirectsDone == 0) {
                std.unique_ptr<QBuffer> payload = new std.unique_ptr<QBuffer> (new QBuffer ());
                payload.setData ("");
                var reply = new SlowFakePostReply (operation, request, std.move (payload), this);
                reply.redirectToPolicy = true;
                redirectsDone++;
                return reply;
            } else if  (redirectsDone == 1) {
                std.unique_ptr<QBuffer> payload = new std.unique_ptr<QBuffer> (new QBuffer ());
                payload.setData ("");
                var reply = new SlowFakePostReply (operation, request, std.move (payload), this);
                reply.redirectToToken = true;
                redirectsDone++;
                return reply;
            } else {
                // ^^ This is with a custom reply and not actually HTTP, so we're testing the HTTP redirect code
                // we have in AbstractNetworkJob.slotFinished ()
                redirectsDone++;
                return OAuthTestCase.tokenReply (operation, request);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testTokenUrlHasRedirect () {
        TestTokenUrlHasRedirect test;
        test.test ();
    }

}
}
