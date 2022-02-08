/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

using namespace Occ;

class FakePostReply : Soup.Reply {

    /***********************************************************
    ***********************************************************/
    public std.unique_ptr<QIODevice> payload;
    public bool aborted = false;
    public bool redirectToPolicy = false;
    public bool redirectToToken = false;

    /***********************************************************
    ***********************************************************/
    public FakePostReply (QNetworkAccessManager.Operation op, QNetworkRequest request,
                  std.unique_ptr<QIODevice> payload_, GLib.Object parent)
        : Soup.Reply{parent}, payload{std.move (payload_)} {
        setRequest (request);
        setUrl (request.url ());
        setOperation (op);
        open (QIODevice.ReadOnly);
        payload.open (QIODevice.ReadOnly);
        QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
    }

    public virtual void respond () {
        if (aborted) {
            setError (OperationCanceledError, "Operation Canceled");
            /* emit */ metaDataChanged ();
            /* emit */ finished ();
            return;
        } else if (redirectToPolicy) {
            setHeader (QNetworkRequest.LocationHeader, "/my.policy");
            setAttribute (QNetworkRequest.RedirectionTargetAttribute, "/my.policy");
            setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 302); // 302 might or might not lose POST data in rfc
            setHeader (QNetworkRequest.ContentLengthHeader, 0);
            /* emit */ metaDataChanged ();
            /* emit */ finished ();
            return;
        } else if (redirectToToken) {
            // Redirect to self
            GLib.Variant destination = GLib.Variant (sOAuthTestServer.toString ()+QLatin1String ("/index.php/apps/oauth2/api/v1/token"));
            setHeader (QNetworkRequest.LocationHeader, destination);
            setAttribute (QNetworkRequest.RedirectionTargetAttribute, destination);
            setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 307); // 307 explicitly in rfc says to not lose POST data
            setHeader (QNetworkRequest.ContentLengthHeader, 0);
            /* emit */ metaDataChanged ();
            /* emit */ finished ();
            return;
        }
        setHeader (QNetworkRequest.ContentLengthHeader, payload.size ());
        setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 200);
        /* emit */ metaDataChanged ();
        if (bytesAvailable ())
            /* emit */ readyRead ();
        /* emit */ finished ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override {
        aborted = true;
    }


    /***********************************************************
    ***********************************************************/
    public int64 bytesAvailable () override {
        if (aborted)
            return 0;
        return payload.bytesAvailable ();
    }

    ipublic nt64 readData (char data, int64 maxlen) override {
        return payload.read (data, maxlen);
    }
}
