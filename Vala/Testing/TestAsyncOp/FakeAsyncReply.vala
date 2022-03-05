/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakeAsyncReply : FakeReply {

    GLib.ByteArray this.pollLocation;


    /***********************************************************
    ***********************************************************/
    public FakeAsyncReply (GLib.ByteArray pollLocation, Soup.Operation operation, Soup.Request request, GLib.Object parent)
        : FakeReply (parent);
        this.pollLocation (pollLocation) {
        set_request (request);
        set_url (request.url ());
        set_operation (operation);
        open (QIODevice.ReadOnly);

        QMetaObject.invoke_method (this, "respond", Qt.QueuedConnection);
    }

    public void respond () {
        set_attribute (Soup.Request.HttpStatusCodeAttribute, 202);
        setRawHeader ("OC-JobStatus-Location", this.pollLocation);
        /* emit */ signal_meta_data_changed ();
        /* emit */ signal_finished ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override {}
    public int64 read_data (char *, int64) override ( return 0; }
}
