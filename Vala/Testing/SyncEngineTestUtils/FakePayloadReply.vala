/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakePayloadReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray body;

    /***********************************************************
    ***********************************************************/
    public const int DEFAULT_DELAY = 10;

    /***********************************************************
    ***********************************************************/
    public FakePayloadReply (Soup.Operation operation, Soup.Request request, GLib.ByteArray body, GLib.Object parent) {
        FakePayloadReply (operation, request, body, FakePayloadReply.DEFAULT_DELAY, parent);
    }

    /***********************************************************
    ***********************************************************/
    public FakePayloadReply (
        Soup.Operation operation, Soup.Request request, GLib.ByteArray body, int delay, GLib.Object parent) {
        base (parent);
        this.body = body;
        set_request (request);
        set_url (request.url ());
        set_operation (operation);
        open (QIODevice.ReadOnly);
        QTimer.single_shot (delay, this, &FakePayloadReply.respond);
    }


    /***********************************************************
    ***********************************************************/
    public void respond () {
        set_attribute (Soup.Request.HttpStatusCodeAttribute, 200);
        set_header (Soup.Request.ContentLengthHeader, this.body.size ());
        /* emit */ signal_meta_data_changed ();
        /* emit */ signal_ready_read ();
        set_finished (true);
        /* emit */ signal_finished ();
    }

    /***********************************************************
    ***********************************************************/
    public override void on_signal_abort () {
        return;
    }

    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char buf, int64 max) {
        max = q_min<int64> (max, this.body.size ());
        memcpy (buf, this.body.const_data (), max);
        this.body = this.body.mid (max);
        return max;
    }

    /***********************************************************
    ***********************************************************/
    public override int64 bytes_available () {
        return this.body.size ();
    }

} // class FakePayloadReply
} // namespace Testing
