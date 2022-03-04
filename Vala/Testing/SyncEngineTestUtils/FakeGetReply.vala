/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakeGetReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public const FileInfo file_info;
    public char payload;
    public int size;
    public bool aborted = false;

    /***********************************************************
    ***********************************************************/
    public FakeGetReply (FileInfo remote_root_file_info, QNetworkAccessManager.Operation operation, Soup.Request request, GLib.Object parent);

    /***********************************************************
    ***********************************************************/
    public void respond ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override;

    /***********************************************************
    ***********************************************************/
    public int64 read_data (char data, int64 maxlen) override;

}
}







FakeGetReply.FakeGetReply (FileInfo remote_root_file_info, QNetworkAccessManager.Operation operation, Soup.Request request, GLib.Object parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (operation);
    open (QIODevice.ReadOnly);

    string fileName = getFilePathFromUrl (request.url ());
    //  Q_ASSERT (!fileName.isEmpty ());
    file_info = remote_root_file_info.find (fileName);
    if (!file_info) {
        GLib.debug ("meh;";
    }
    Q_ASSERT_X (file_info, Q_FUNC_INFO, "Could not find file on the remote");
    QMetaObject.invokeMethod (this, &FakeGetReply.respond, Qt.QueuedConnection);
}

void FakeGetReply.respond () {
    if (aborted) {
        setError (OperationCanceledError, "Operation Canceled");
        /* emit */ metaDataChanged ();
        /* emit */ finished ();
        return;
    }
    payload = file_info.content_char;
    size = file_info.size;
    setHeader (Soup.Request.ContentLengthHeader, size);
    setAttribute (Soup.Request.HttpStatusCodeAttribute, 200);
    setRawHeader ("OC-ETag", file_info.etag);
    setRawHeader ("ETag", file_info.etag);
    setRawHeader ("OC-FileId", file_info.file_identifier);
    /* emit */ metaDataChanged ();
    if (bytes_available ())
        /* emit */ readyRead ();
    /* emit */ finished ();
}

void FakeGetReply.on_signal_abort () {
    setError (OperationCanceledError, "Operation Canceled");
    aborted = true;
}

int64 FakeGetReply.bytes_available () {
    if (aborted)
        return 0;
    return size + QIODevice.bytes_available ();
}

int64 FakeGetReply.read_data (char data, int64 maxlen) {
    int64 len = std.min (int64 { size }, maxlen);
    std.fill_n (data, len, payload);
    size -= len;
    return len;
}