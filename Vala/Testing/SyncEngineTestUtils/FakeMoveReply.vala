/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakeMoveReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public FakeMoveReply (FileInfo remote_root_file_info, QNetworkAccessManager.Operation operation, Soup.Request request, GLib.Object parent);

    /***********************************************************
    ***********************************************************/
    public void respond ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override { }

    /***********************************************************
    ***********************************************************/
    public int64 read_data (char *, int64) override {
        return 0;
    }

}
}







FakeMoveReply.FakeMoveReply (FileInfo remote_root_file_info, QNetworkAccessManager.Operation operation, Soup.Request request, GLib.Object parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (operation);
    open (QIODevice.ReadOnly);

    string fileName = getFilePathFromUrl (request.url ());
    //  Q_ASSERT (!fileName.isEmpty ());
    string dest = getFilePathFromUrl (GLib.Uri.fromEncoded (request.rawHeader ("Destination")));
    //  Q_ASSERT (!dest.isEmpty ());
    remote_root_file_info.rename (fileName, dest);
    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
}

void FakeMoveReply.respond () {
    setAttribute (Soup.Request.HttpStatusCodeAttribute, 201);
    /* emit */ metaDataChanged ();
    /* emit */ finished ();
}