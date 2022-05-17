/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class FakePayloadReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public string body;

    /***********************************************************
    ***********************************************************/
    public const int DEFAULT_DELAY = 10;

    /***********************************************************
    ***********************************************************/
    public FakePayloadReply (
        Soup.Operation operation,
        Soup.Request request,
        string body,
        int delay = 0,
        GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.body = body;
        set_request (request);
        set_url (request.url);
        set_operation (operation);
        open (GLib.IODevice.ReadOnly);
        GLib.Timeout.add (delay, this.respond);
    }


    /***********************************************************
    ***********************************************************/
    public bool respond () {
        set_attribute (Soup.Request.HttpStatusCodeAttribute, 200);
        set_header (Soup.Request.ContentLengthHeader, this.body.size ());
        /* emit */ signal_meta_data_changed ();
        /* emit */ signal_ready_read ();
        set_finished (true);
        /* emit */ signal_finished ();
        return false; // only run once
    }


    /***********************************************************
    ***********************************************************/
    public override bool on_signal_abort () {
        return false; // only run once
    }


    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char buf, int64 max) {
        max = int64.min (max, this.body.size ());
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
} // namespace Occ
