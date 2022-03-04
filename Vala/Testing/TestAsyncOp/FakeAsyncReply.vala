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
    public FakeAsyncReply (GLib.ByteArray pollLocation, QNetworkAccessManager.Operation operation, Soup.Request request, GLib.Object parent)
        : FakeReply { parent }
        this.pollLocation (pollLocation) {
        setRequest (request);
        setUrl (request.url ());
        setOperation (operation);
        open (QIODevice.ReadOnly);

        QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
    }

    public void respond () {
        setAttribute (Soup.Request.HttpStatusCodeAttribute, 202);
        setRawHeader ("OC-JobStatus-Location", this.pollLocation);
        /* emit */ metaDataChanged ();
        /* emit */ finished ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override {}
    public int64 read_data (char *, int64) override { return 0; }
}
