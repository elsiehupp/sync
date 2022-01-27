/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.

***********************************************************/

// #include <QtTest/QtTest>
// #include <QDesktopServices>

using namespace Occ;

class DesktopServiceHook : GLib.Object {
signals:
    void hooked (QUrl );

    public DesktopServiceHook () {
        QDesktopServices.setUrlHandler ("oauthtest", this, "hooked");
    }
};

static const QUrl sOAuthTestServer ("oauthtest://someserver/owncloud");

class FakePostReply : QNetworkReply {

    public std.unique_ptr<QIODevice> payload;
    public bool aborted = false;
    public bool redirectToPolicy = false;
    public bool redirectToToken = false;

    public FakePostReply (QNetworkAccessManager.Operation op, QNetworkRequest &request,
                  std.unique_ptr<QIODevice> payload_, GLib.Object *parent)
        : QNetworkReply{parent}, payload{std.move (payload_)} {
        setRequest (request);
        setUrl (request.url ());
        setOperation (op);
        open (QIODevice.ReadOnly);
        payload.open (QIODevice.ReadOnly);
        QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
    }

    //  Q_INVOKABLE
    public virtual void respond () {
        if (aborted) {
            setError (OperationCanceledError, "Operation Canceled");
            emit metaDataChanged ();
            emit on_finished ();
            return;
        } else if (redirectToPolicy) {
            setHeader (QNetworkRequest.LocationHeader, "/my.policy");
            setAttribute (QNetworkRequest.RedirectionTargetAttribute, "/my.policy");
            setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 302); // 302 might or might not lose POST data in rfc
            setHeader (QNetworkRequest.ContentLengthHeader, 0);
            emit metaDataChanged ();
            emit on_finished ();
            return;
        } else if (redirectToToken) {
            // Redirect to self
            QVariant destination = QVariant (sOAuthTestServer.toString ()+QLatin1String ("/index.php/apps/oauth2/api/v1/token"));
            setHeader (QNetworkRequest.LocationHeader, destination);
            setAttribute (QNetworkRequest.RedirectionTargetAttribute, destination);
            setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 307); // 307 explicitly in rfc says to not lose POST data
            setHeader (QNetworkRequest.ContentLengthHeader, 0);
            emit metaDataChanged ();
            emit on_finished ();
            return;
        }
        setHeader (QNetworkRequest.ContentLengthHeader, payload.size ());
        setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 200);
        emit metaDataChanged ();
        if (bytesAvailable ())
            emit readyRead ();
        emit on_finished ();
    }

    public void on_abort () override {
        aborted = true;
    }
    public int64 bytesAvailable () override {
        if (aborted)
            return 0;
        return payload.bytesAvailable ();
    }

    ipublic nt64 readData (char *data, int64 maxlen) override {
        return payload.read (data, maxlen);
    }
};

// Reply with a small delay
class SlowFakePostReply : FakePostReply {

    public using FakePostReply.FakePostReply;
    public void respond () override {
        // override of FakePostReply.respond, will call the real one with a delay.
        QTimer.singleShot (100, this, [this] { this.FakePostReply.respond (); });
    }
};

class OAuthTestCase : GLib.Object {
    DesktopServiceHook desktopServiceHook;

    public enum State { StartState, BrowserOpened, TokenAsked, CustomState } state = StartState;

    public bool replyToBrowserOk = false;
    public bool gotAuthOk = false;
    public virtual bool on_done () { return replyToBrowserOk && gotAuthOk; }

    public FakeQNAM *fakeQnam = nullptr;
    public QNetworkAccessManager realQNAM;
    public QPointer<QNetworkReply> browserReply = nullptr;
    public string code = generateEtag ();
    public Occ.AccountPtr account;

    public QScopedPointer<OAuth> oauth;

    public virtual void test () {
        fakeQnam = new FakeQNAM ({});
        account = Occ.Account.create ();
        account.setUrl (sOAuthTestServer);
        account.setCredentials (new FakeCredentials{fakeQnam});
        fakeQnam.setParent (this);
        fakeQnam.setOverride ([this] (QNetworkAccessManager.Operation op, QNetworkRequest &req, QIODevice *device) {
            ASSERT (device);
            ASSERT (device.bytesAvailable ()>0); // OAuth2 always sends around POST data.
            return this.tokenReply (op, req);
        });

        GLib.Object.connect (&desktopServiceHook, &DesktopServiceHook.hooked,
                         this, &OAuthTestCase.openBrowserHook);

        oauth.on_reset (new OAuth (account.data (), nullptr));
        GLib.Object.connect (oauth.data (), &OAuth.result, this, &OAuthTestCase.oauthResult);
        oauth.on_start ();
        QTRY_VERIFY (on_done ());
    }

    public virtual void openBrowserHook (QUrl url) {
        QCOMPARE (state, StartState);
        state = BrowserOpened;
        QCOMPARE (url.path (), string (sOAuthTestServer.path () + "/index.php/apps/oauth2/authorize"));
        QVERIFY (url.toString ().startsWith (sOAuthTestServer.toString ()));
        QUrlQuery query (url);
        QCOMPARE (query.queryItemValue (QLatin1String ("response_type")), QLatin1String ("code"));
        QCOMPARE (query.queryItemValue (QLatin1String ("client_id")), Theme.instance ().oauthClientId ());
        QUrl redirectUri (query.queryItemValue (QLatin1String ("redirect_uri")));
        QCOMPARE (redirectUri.host (), QLatin1String ("localhost"));
        redirectUri.setQuery ("code=" + code);
        createBrowserReply (QNetworkRequest (redirectUri));
    }

    public virtual QNetworkReply *createBrowserReply (QNetworkRequest &request) {
        browserReply = realQNAM.get (request);
        GLib.Object.connect (browserReply, &QNetworkReply.on_finished, this, &OAuthTestCase.browserReplyFinished);
        return browserReply;
    }

    public virtual void browserReplyFinished () {
        QCOMPARE (sender (), browserReply.data ());
        QCOMPARE (state, TokenAsked);
        browserReply.deleteLater ();
        QCOMPARE (browserReply.rawHeader ("Location"), GLib.ByteArray ("owncloud://on_success"));
        replyToBrowserOk = true;
    };

    public virtual QNetworkReply *tokenReply (QNetworkAccessManager.Operation op, QNetworkRequest &req) {
        ASSERT (state == BrowserOpened);
        state = TokenAsked;
        ASSERT (op == QNetworkAccessManager.PostOperation);
        ASSERT (req.url ().toString ().startsWith (sOAuthTestServer.toString ()));
        ASSERT (req.url ().path () == sOAuthTestServer.path () + "/index.php/apps/oauth2/api/v1/token");
        std.unique_ptr<QBuffer> payload (new QBuffer ());
        payload.setData (tokenReplyPayload ());
        return new FakePostReply (op, req, std.move (payload), fakeQnam);
    }

    public virtual GLib.ByteArray tokenReplyPayload () {
        QJsonDocument jsondata (QJsonObject{ { "access_token", "123" }, { "refresh_token" , "456" }, { "message_url",  "owncloud://on_success"}, { "user_id", "789" }, { "token_type", "Bearer" }
        });
        return jsondata.toJson ();
    }

    public virtual void oauthResult (OAuth.Result result, string user, string token , string refreshToken) {
        QCOMPARE (state, TokenAsked);
        QCOMPARE (result, OAuth.LoggedIn);
        QCOMPARE (user, string ("789"));
        QCOMPARE (token, string ("123"));
        QCOMPARE (refreshToken, string ("456"));
        gotAuthOk = true;
    }
};

class TestOAuth : public GLib.Object {

    private on_ void testBasic () {
        OAuthTestCase test;
        test.test ();
    }

    // Test for https://github.com/owncloud/client/pull/6057
    private on_ void testCloseBrowserDontCrash () {
        struct Test : OAuthTestCase {
            QNetworkReply *tokenReply (QNetworkAccessManager.Operation op, QNetworkRequest & req) override {
                ASSERT (browserReply);
                // simulate the fact that the browser is closing the connection
                browserReply.on_abort ();
                QCoreApplication.processEvents ();

                ASSERT (state == BrowserOpened);
                state = TokenAsked;

                std.unique_ptr<QBuffer> payload (new QBuffer);
                payload.setData (tokenReplyPayload ());
                return new SlowFakePostReply (op, req, std.move (payload), fakeQnam);
            }

            void browserReplyFinished () override {
                QCOMPARE (sender (), browserReply.data ());
                QCOMPARE (browserReply.error (), QNetworkReply.OperationCanceledError);
                replyToBrowserOk = true;
            }
        } test;
        test.test ();
    }

    private on_ void testRandomConnections () {
        // Test that we can send random garbage to the litening socket and it does not prevent the connection
        struct Test : OAuthTestCase {
            QNetworkReply *createBrowserReply (QNetworkRequest &request) override {
                QTimer.singleShot (0, this, [this, request] {
                    auto port = request.url ().port ();
                    state = CustomState;
                    QVector<GLib.ByteArray> payloads = {
                        "GET FOFOFO HTTP 1/1\n\n",
                        "GET /?code=invalie HTTP 1/1\n\n",
                        "GET /?code=xxxxx&bar=fff",
                        GLib.ByteArray ("\0\0\0", 3),
                        GLib.ByteArray ("GET \0\0\0 \n\n\n\n\n\0", 14),
                        GLib.ByteArray ("GET /?code=éléphant\xa5 HTTP\n"),
                        GLib.ByteArray ("\n\n\n\n"),
                    };
                    foreach (auto &x, payloads) {
                        auto socket = new QTcpSocket (this);
                        socket.connectToHost ("localhost", port);
                        QVERIFY (socket.waitForConnected ());
                        socket.write (x);
                    }

                    // Do the actual request a bit later
                    QTimer.singleShot (100, this, [this, request] {
                        QCOMPARE (state, CustomState);
                        state = BrowserOpened;
                        this.OAuthTestCase.createBrowserReply (request);
                    });
               });
               return nullptr;
            }

            QNetworkReply *tokenReply (QNetworkAccessManager.Operation op, QNetworkRequest &req) override {
                if (state == CustomState)
                    return new FakeErrorReply{op, req, this, 500};
                return OAuthTestCase.tokenReply (op, req);
            }

            void oauthResult (OAuth.Result result, string user, string token ,
                             const string refreshToken) override {
                if (state != CustomState)
                    return OAuthTestCase.oauthResult (result, user, token, refreshToken);
                QCOMPARE (result, OAuth.Error);
            }
        } test;
        test.test ();
    }

    private on_ void testTokenUrlHasRedirect () {
        struct Test : OAuthTestCase {
            int redirectsDone = 0;
            QNetworkReply *tokenReply (QNetworkAccessManager.Operation op, QNetworkRequest & request) override {
                ASSERT (browserReply);
                // Kind of reproduces what we had in https://github.com/owncloud/enterprise/issues/2951 (not 1:1)
                if (redirectsDone == 0) {
                    std.unique_ptr<QBuffer> payload (new QBuffer ());
                    payload.setData ("");
                    auto *reply = new SlowFakePostReply (op, request, std.move (payload), this);
                    reply.redirectToPolicy = true;
                    redirectsDone++;
                    return reply;
                } else if  (redirectsDone == 1) {
                    std.unique_ptr<QBuffer> payload (new QBuffer ());
                    payload.setData ("");
                    auto *reply = new SlowFakePostReply (op, request, std.move (payload), this);
                    reply.redirectToToken = true;
                    redirectsDone++;
                    return reply;
                } else {
                    // ^^ This is with a custom reply and not actually HTTP, so we're testing the HTTP redirect code
                    // we have in AbstractNetworkJob.slotFinished ()
                    redirectsDone++;
                    return OAuthTestCase.tokenReply (op, request);
                }
            }
        } test;
        test.test ();
    }
};

QTEST_GUILESS_MAIN (TestOAuth)
