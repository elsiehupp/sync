
namespace Testing {

class FakeDeleteReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public FakeDeleteReply (FileInfo remote_root_file_info, QNetworkAccessManager.Operation operation, Soup.Request request, GLib.Object parent);

    /***********************************************************
    ***********************************************************/
    public void respond ();

    /***********************************************************
    ***********************************************************/
    public override void on_signal_abort () { }

    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char char_value, int64 int64_value) {
        return 0;
    }

}
}




FakeDeleteReply.FakeDeleteReply (FileInfo remote_root_file_info, QNetworkAccessManager.Operation operation, Soup.Request request, GLib.Object parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (operation);
    open (QIODevice.ReadOnly);

    string fileName = getFilePathFromUrl (request.url ());
    //  Q_ASSERT (!fileName.isEmpty ());
    remote_root_file_info.remove (fileName);
    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
}

void FakeDeleteReply.respond () {
    setAttribute (Soup.Request.HttpStatusCodeAttribute, 204);
    /* emit */ metaDataChanged ();
    /* emit */ finished ();
}