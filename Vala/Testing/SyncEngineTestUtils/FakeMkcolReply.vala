/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakeMkcolReply : FakeReply {

    FileInfo file_info;

    /***********************************************************
    ***********************************************************/
    public FakeMkcolReply (FileInfo remote_root_file_info, QNetworkAccessManager.Operation operation, Soup.Request request, GLib.Object parent);

    public void respond ();

    /***********************************************************
    ***********************************************************/
    public override void on_signal_abort () { }

    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char *, int64) {
        return 0;
    }

}
}




FakeMkcolReply.FakeMkcolReply (FileInfo remote_root_file_info, QNetworkAccessManager.Operation operation, Soup.Request request, GLib.Object parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (operation);
    open (QIODevice.ReadOnly);

    string fileName = getFilePathFromUrl (request.url ());
    //  Q_ASSERT (!fileName.isEmpty ());
    file_info = remote_root_file_info.createDir (fileName);

    if (!file_info) {
        on_signal_abort ();
        return;
    }
    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
}

void FakeMkcolReply.respond () {
    setRawHeader ("OC-FileId", file_info.file_identifier);
    setAttribute (Soup.Request.HttpStatusCodeAttribute, 201);
    /* emit */ metaDataChanged ();
    /* emit */ finished ();
}