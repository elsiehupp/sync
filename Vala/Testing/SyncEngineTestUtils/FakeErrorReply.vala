

// make public to give tests easy interface
using Soup.Reply.setError;
using Soup.Reply.setAttribute;

namespace Testing {

class FakeErrorReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray body;

    /***********************************************************
    ***********************************************************/
    public FakeErrorReply (QNetworkAccessManager.Operation operation, Soup.Request request,
        GLib.Object parent, int http_error_code, GLib.ByteArray body = GLib.ByteArray ());

    /***********************************************************
    ***********************************************************/
    public virtual void respond ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_finished ();

    /***********************************************************
    ***********************************************************/
    public override void on_signal_abort () { }

    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char buf, int64 max);

    /***********************************************************
    ***********************************************************/
    public override int64 bytes_available ();
};






FakeErrorReply.FakeErrorReply (QNetworkAccessManager.Operation operation, Soup.Request request, GLib.Object parent, int http_error_code, GLib.ByteArray body)
    : FakeReply { parent }
    this.body (body) {
    setRequest (request);
    setUrl (request.url ());
    setOperation (operation);
    open (QIODevice.ReadOnly);
    setAttribute (Soup.Request.HttpStatusCodeAttribute, http_error_code);
    setError (InternalServerError, "Internal Server Fake Error");
    QMetaObject.invokeMethod (this, &FakeErrorReply.respond, Qt.QueuedConnection);
}

void FakeErrorReply.respond () {
    /* emit */ metaDataChanged ();
    /* emit */ readyRead ();
    // finishing can come strictly after readyRead was called
    QTimer.singleShot (5, this, &FakeErrorReply.on_signal_finished);
}

void FakeErrorReply.on_signal_finished () {
    setFinished (true);
    /* emit */ finished ();
}

int64 FakeErrorReply.read_data (char buf, int64 max) {
    max = qMin<int64> (max, this.body.size ());
    memcpy (buf, this.body.constData (), max);
    this.body = this.body.mid (max);
    return max;
}

int64 FakeErrorReply.bytes_available () {
    return this.body.size ();
}