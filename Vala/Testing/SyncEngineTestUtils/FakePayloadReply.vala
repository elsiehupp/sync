/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakePayloadReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray this.body;

    /***********************************************************
    ***********************************************************/
    public const int defaultDelay = 10;

    /***********************************************************
    ***********************************************************/
    public FakePayloadReply (QNetworkAccessManager.Operation operation, Soup.Request request,

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public st GLib.ByteArra

    /***********************************************************
    ***********************************************************/
    public void respond ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override {}

    /***********************************************************
    ***********************************************************/
    public int64 read_data (char buf, int64 max) override;

    /***********************************************************
    ***********************************************************/
    public int64 bytes_available () override;

}
}







FakePayloadReply.FakePayloadReply (QNetworkAccessManager.Operation operation, Soup.Request request, GLib.ByteArray body, GLib.Object parent)
    : FakePayloadReply (operation, request, body, FakePayloadReply.defaultDelay, parent) {
}

FakePayloadReply.FakePayloadReply (
    QNetworkAccessManager.Operation operation, Soup.Request request, GLib.ByteArray body, int delay, GLib.Object parent)
    : FakeReply{parent}
    this.body (body) {
    setRequest (request);
    setUrl (request.url ());
    setOperation (operation);
    open (QIODevice.ReadOnly);
    QTimer.singleShot (delay, this, &FakePayloadReply.respond);
}

void FakePayloadReply.respond () {
    setAttribute (Soup.Request.HttpStatusCodeAttribute, 200);
    setHeader (Soup.Request.ContentLengthHeader, this.body.size ());
    /* emit */ metaDataChanged ();
    /* emit */ readyRead ();
    setFinished (true);
    /* emit */ finished ();
}

int64 FakePayloadReply.read_data (char buf, int64 max) {
    max = qMin<int64> (max, this.body.size ());
    memcpy (buf, this.body.constData (), max);
    this.body = this.body.mid (max);
    return max;
}

int64 FakePayloadReply.bytes_available () {
    return this.body.size ();
}