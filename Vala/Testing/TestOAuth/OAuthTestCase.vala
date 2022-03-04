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
    public enum State { StartState, BrowserOpened, TokenAsked, CustomState } state = StartState;

    /***********************************************************
    ***********************************************************/
    public bool replyToBrowserOk = false;
    public bool gotAuthOk = false;
    public virtual bool on_signal_done () { return replyToBrowserOk && gotAuthOk; }


    /***********************************************************
    ***********************************************************/
    public FakeQNAM *fake_qnam = null;
    public QNetworkAccessManager realQNAM;
    public QPointer<Soup.Reply> browserReply = null;
    public string code = generateEtag ();


    /***********************************************************
    ***********************************************************/
    public Occ.AccountPointer account;

    /***********************************************************
    ***********************************************************/
    public QScopedPointer<OAuth> oauth;

    /***********************************************************
    ***********************************************************/
    public virtual void test () {
        fake_qnam = new FakeQNAM ({});
        account = Occ.Account.create ();
        account.setUrl (sOAuthTestServer);
        account.setCredentials (new FakeCredentials{fake_qnam});
        fake_qnam.setParent (this);
        fake_qnam.set_override ([this] (QNetworkAccessManager.Operation operation, Soup.Request req, QIODevice device) {
            //  ASSERT (device);
            //  ASSERT (device.bytes_available ()>0); // OAuth2 always sends around POST data.
            return this.tokenReply (operation, req);
        });

        GLib.Object.connect (&desktopServiceHook, &DesktopServiceHook.hooked,
                         this, &OAuthTestCase.openBrowserHook);

        oauth.on_signal_reset (new OAuth (account.data (), null));
        GLib.Object.connect (oauth.data (), &OAuth.result, this, &OAuthTestCase.oauthResult);
        oauth.on_signal_start ();
        QTRY_VERIFY (on_signal_done ());
    }


    /***********************************************************
    ***********************************************************/
    public virtual void openBrowserHook (GLib.Uri url) {
        QCOMPARE (state, StartState);
        state = BrowserOpened;
        QCOMPARE (url.path (), string (sOAuthTestServer.path () + "/index.php/apps/oauth2/authorize"));
        QVERIFY (url.toString ().startsWith (sOAuthTestServer.toString ()));
        QUrlQuery query (url);
        QCOMPARE (query.queryItemValue (QLatin1String ("response_type")), QLatin1String ("code"));
        QCOMPARE (query.queryItemValue (QLatin1String ("client_id")), Theme.instance ().oauthClientId ());
        GLib.Uri redirectUri (query.queryItemValue (QLatin1String ("redirect_uri")));
        QCOMPARE (redirectUri.host (), QLatin1String ("localhost"));
        redirectUri.setQuery ("code=" + code);
        createBrowserReply (Soup.Request (redirectUri));
    }


    /***********************************************************
    ***********************************************************/
    public virtual Soup.Reply createBrowserReply (Soup.Request request) {
        browserReply = realQNAM.get (request);
        GLib.Object.connect (browserReply, &Soup.Reply.on_signal_finished, this, &OAuthTestCase.browserReplyFinished);
        return browserReply;
    }


    /***********************************************************
    ***********************************************************/
    public virtual void browserReplyFinished () {
        QCOMPARE (sender (), browserReply.data ());
        QCOMPARE (state, TokenAsked);
        browserReply.deleteLater ();
        QCOMPARE (browserReply.rawHeader ("Location"), GLib.ByteArray ("owncloud://on_signal_success"));
        replyToBrowserOk = true;
    }

    /***********************************************************
    ***********************************************************/
    public virtual Soup.Reply tokenReply (QNetworkAccessManager.Operation operation, Soup.Request req) {
        //  ASSERT (state == BrowserOpened);
        state = TokenAsked;
        //  ASSERT (operation == QNetworkAccessManager.PostOperation);
        //  ASSERT (req.url ().toString ().startsWith (sOAuthTestServer.toString ()));
        //  ASSERT (req.url ().path () == sOAuthTestServer.path () + "/index.php/apps/oauth2/api/v1/token");
        std.unique_ptr<QBuffer> payload (new QBuffer ());
        payload.setData (tokenReplyPayload ());
        return new FakePostReply (operation, req, std.move (payload), fake_qnam);
    }


    /***********************************************************
    ***********************************************************/
    public virtual GLib.ByteArray tokenReplyPayload () {
        QJsonDocument jsondata (QJsonObject{ { "access_token", "123" }, { "refresh_token" , "456" }, { "message_url",  "owncloud://on_signal_success"}, { "user_id", "789" }, { "token_type", "Bearer" }
        });
        return jsondata.toJson ();
    }


    /***********************************************************
    ***********************************************************/
    public virtual void oauthResult (OAuth.Result result, string user, string token , string refreshToken) {
        QCOMPARE (state, TokenAsked);
        QCOMPARE (result, OAuth.LoggedIn);
        QCOMPARE (user, string ("789"));
        QCOMPARE (token, string ("123"));
        QCOMPARE (refreshToken, string ("456"));
        gotAuthOk = true;
    }
};