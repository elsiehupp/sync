/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class FakeAsyncReply : FakeReply {

    string poll_location;

    /***********************************************************
    ***********************************************************/
    public FakeAsyncReply (string poll_location, Soup.Operation operation, Soup.Request request, GLib.Object parent) {
        base (parent);
        this.poll_location = poll_location;
        set_request (request);
        set_url (request.url);
        set_operation (operation);
        open (GLib.IODevice.ReadOnly);

        GLib.Object.invoke_method (this, "respond", GLib.QueuedConnection);
    }


    /***********************************************************
    ***********************************************************/
    public void respond () {
        set_attribute (Soup.Request.HttpStatusCodeAttribute, 202);
        set_raw_header ("OC-JobStatus-Location", this.poll_location);
        /* emit */ signal_meta_data_changed ();
        /* emit */ signal_finished ();
    }


    /***********************************************************
    ***********************************************************/
    public override bool on_signal_abort () {
        return false; // only run once
    }


    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char *data, int64 length) {
        return 0;
    }

} // class FakeAsyncReply
} // namespace Testing
} // namespace Occ
