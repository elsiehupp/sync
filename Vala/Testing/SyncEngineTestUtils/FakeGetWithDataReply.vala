/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakeGetWithDataReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public const FileInfo file_info;
    public GLib.ByteArray payload;
    public uint64 offset = 0;
    public bool aborted = false;

    /***********************************************************
    ***********************************************************/
    public FakeGetWithDataReply (FileInfo remote_root_file_info, GLib.ByteArray data, QNetworkAccessManager.Operation operation, Soup.Request request, GLib.Object parent);

    public void respond ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override;

    /***********************************************************
    ***********************************************************/
    public int64 read_data (char data, int64 maxlen) override;

}
}








FakeGetWithDataReply.FakeGetWithDataReply (FileInfo remote_root_file_info, GLib.ByteArray data, QNetworkAccessManager.Operation operation, Soup.Request request, GLib.Object parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (operation);
    open (QIODevice.ReadOnly);

    //  Q_ASSERT (!data.isEmpty ());
    payload = data;
    string fileName = getFilePathFromUrl (request.url ());
    //  Q_ASSERT (!fileName.isEmpty ());
    file_info = remote_root_file_info.find (fileName);
    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);

    if (request.hasRawHeader ("Range")) {
        const string range = string.fromUtf8 (request.rawHeader ("Range"));
        const QRegularExpression bytesPattern ("bytes= (?<on_signal_start>\\d+)- (?<end>\\d+)");
        const QRegularExpressionMatch match = bytesPattern.match (range);
        if (match.hasMatch ()) {
            const int on_signal_start = match.captured ("on_signal_start").toInt ();
            const int end = match.captured ("end").toInt ();
            payload = payload.mid (on_signal_start, end - on_signal_start + 1);
        }
    }
}

void FakeGetWithDataReply.respond () {
    if (aborted) {
        setError (OperationCanceledError, "Operation Canceled");
        /* emit */ metaDataChanged ();
        /* emit */ finished ();
        return;
    }
    setHeader (Soup.Request.ContentLengthHeader, payload.size ());
    setAttribute (Soup.Request.HttpStatusCodeAttribute, 200);
    setRawHeader ("OC-ETag", file_info.etag);
    setRawHeader ("ETag", file_info.etag);
    setRawHeader ("OC-FileId", file_info.file_identifier);
    /* emit */ metaDataChanged ();
    if (bytes_available ())
        /* emit */ readyRead ();
    /* emit */ finished ();
}

void FakeGetWithDataReply.on_signal_abort () {
    setError (OperationCanceledError, "Operation Canceled");
    aborted = true;
}

int64 FakeGetWithDataReply.bytes_available () {
    if (aborted)
        return 0;
    return payload.size () - offset + QIODevice.bytes_available ();
}

int64 FakeGetWithDataReply.read_data (char data, int64 maxlen) {
    int64 len = std.min (payload.size () - offset, uint64 (maxlen));
    std.memcpy (data, payload.constData () + offset, len);
    offset += len;
    return len;
}