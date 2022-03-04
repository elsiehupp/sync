/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

using Occ;

namespace Testing {

class FakePostReply : Soup.Reply {

    /***********************************************************
    ***********************************************************/
    public std.unique_ptr<QIODevice> payload;
    public bool aborted = false;
    public bool redirectToPolicy = false;
    public bool redirectToToken = false;

    /***********************************************************
    ***********************************************************/
    public FakePostReply (QNetworkAccessManager.Operation operation, Soup.Request request,
                  std.unique_ptr<QIODevice> payload_, GLib.Object parent)
        : Soup.Reply{parent}, payload{std.move (payload_)} {
        setRequest (request);
        setUrl (request.url ());
        setOperation (operation);
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
            setHeader (Soup.Request.LocationHeader, "/my.policy");
            setAttribute (Soup.Request.RedirectionTargetAttribute, "/my.policy");
            setAttribute (Soup.Request.HttpStatusCodeAttribute, 302); // 302 might or might not lose POST data in rfc
            setHeader (Soup.Request.ContentLengthHeader, 0);
            /* emit */ metaDataChanged ();
            /* emit */ finished ();
            return;
        } else if (redirectToToken) {
            // Redirect to self
            GLib.Variant destination = GLib.Variant (sOAuthTestServer.toString ()+QLatin1String ("/index.php/apps/oauth2/api/v1/token"));
            setHeader (Soup.Request.LocationHeader, destination);
            setAttribute (Soup.Request.RedirectionTargetAttribute, destination);
            setAttribute (Soup.Request.HttpStatusCodeAttribute, 307); // 307 explicitly in rfc says to not lose POST data
            setHeader (Soup.Request.ContentLengthHeader, 0);
            /* emit */ metaDataChanged ();
            /* emit */ finished ();
            return;
        }
        setHeader (Soup.Request.ContentLengthHeader, payload.size ());
        setAttribute (Soup.Request.HttpStatusCodeAttribute, 200);
        /* emit */ metaDataChanged ();
        if (bytes_available ())
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
    public int64 bytes_available () override {
        if (aborted)
            return 0;
        return payload.bytes_available ();
    }

    ipublic nt64 read_data (char data, int64 maxlen) override {
        return payload.read (data, maxlen);
    }
}
