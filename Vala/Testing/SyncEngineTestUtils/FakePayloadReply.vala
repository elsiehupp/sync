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
    public FakePayloadReply (Soup.Operation operation, Soup.Request request,

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







FakePayloadReply.FakePayloadReply (Soup.Operation operation, Soup.Request request, GLib.ByteArray body, GLib.Object parent)
    : FakePayloadReply (operation, request, body, FakePayloadReply.defaultDelay, parent) {
}

FakePayloadReply.FakePayloadReply (
    Soup.Operation operation, Soup.Request request, GLib.ByteArray body, int delay, GLib.Object parent)
    : FakeReply{parent}
    this.body (body) {
    set_request (request);
    set_url (request.url ());
    set_operation (operation);
    open (QIODevice.ReadOnly);
    QTimer.singleShot (delay, this, &FakePayloadReply.respond);
}

void FakePayloadReply.respond () {
    set_attribute (Soup.Request.HttpStatusCodeAttribute, 200);
    setHeader (Soup.Request.ContentLengthHeader, this.body.size ());
    /* emit */ signal_meta_data_changed ();
    /* emit */ readyRead ();
    setFinished (true);
    /* emit */ signal_finished ();
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