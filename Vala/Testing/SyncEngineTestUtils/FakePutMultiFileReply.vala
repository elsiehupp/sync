/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakePutMultiFileReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    private GLib.Vector<FileInfo> allFileInfo;

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray payload;

    /***********************************************************
    ***********************************************************/
    public FakePutMultiFileReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, string content_type, GLib.ByteArray putPayload, GLib.Object parent);

    /***********************************************************
    ***********************************************************/
    public static GLib.Vector<FileInfo> performMultiPart (FileInfo remote_root_file_info, Soup.Request request, GLib.ByteArray putPayload, string content_type);

    /***********************************************************
    ***********************************************************/
    public virtual void respond ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override;

    /***********************************************************
    ***********************************************************/
    public int64 bytes_available () override;

    /***********************************************************
    ***********************************************************/
    public int64 read_data (char data, int64 maxlen) override;

}
}







FakePutMultiFileReply.FakePutMultiFileReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, string content_type, GLib.ByteArray putPayload, GLib.Object parent)
    : FakeReply (parent); {
    set_request (request);
    set_url (request.url ());
    set_operation (operation);
    open (QIODevice.ReadOnly);
    this.allFileInfo = performMultiPart (remote_root_file_info, request, putPayload, content_type);
    QMetaObject.invoke_method (this, "respond", Qt.QueuedConnection);
}

GLib.Vector<FileInfo> FakePutMultiFileReply.performMultiPart (FileInfo remote_root_file_info, Soup.Request request, GLib.ByteArray putPayload, string content_type) {
    GLib.Vector<FileInfo> result;

    var stringPutPayload = string.fromUtf8 (putPayload);
    const int boundaryPosition = sizeof ("multipart/related; boundary=");
    const string boundaryValue = "--" + content_type.mid (boundaryPosition, content_type.length () - boundaryPosition - 1) + "\r\n";
    var stringPutPayloadRef = string{stringPutPayload}.left (stringPutPayload.size () - 2 - boundaryValue.size ());
    var allParts = stringPutPayloadRef.split (boundaryValue, Qt.SkipEmptyParts);
    for (var onePart : allParts) {
        var headerEndPosition = onePart.indexOf ("\r\n\r\n");
        var onePartHeaderPart = onePart.left (headerEndPosition);
        var onePartBody = onePart.mid (headerEndPosition + 4, onePart.size () - headerEndPosition - 6);
        var onePartHeaders = onePartHeaderPart.split ("\r\n");
        GLib.HashMap<string, string> allHeaders;
        for (var oneHeader : onePartHeaders) {
            var headerParts = oneHeader.split (":");
            allHeaders[headerParts.at (0)] = headerParts.at (1);
        }
        var fileName = allHeaders["X-File-Path"];
        //  Q_ASSERT (!fileName.isEmpty ());
        FileInfo file_info = remote_root_file_info.find (fileName);
        if (file_info) {
            file_info.size = onePartBody.size ();
            file_info.content_char = onePartBody.at (0).toLatin1 ();
        } else {
            // Assume that the file is filled with the same character
            file_info = remote_root_file_info.create (fileName, onePartBody.size (), onePartBody.at (0).toLatin1 ());
        }
        file_info.lastModified = Occ.Utility.qDateTimeFromTime_t (request.rawHeader ("X-OC-Mtime").toLongLong ());
        remote_root_file_info.find (fileName, /*invalidateEtags=*/true);
        result.push_back (file_info);
    }
    return result;
}

void FakePutMultiFileReply.respond () {
    QJsonDocument reply;
    QJsonObject allFileInfoReply;

    int64 totalSize = 0;
    std.for_each (this.allFileInfo.begin (), this.allFileInfo.end (), [&totalSize] (var file_info) {
        totalSize += file_info.size;
    });

    foreach (var file_info in qAsConst (this.allFileInfo)) {
        QJsonObject file_info_reply;
        file_info_reply.insert ("error", "false");
        file_info_reply.insert ("OC-OperationStatus", file_info.operation_status);
        file_info_reply.insert ("X-File-Path", file_info.path ());
        file_info_reply.insert ("OC-ETag", file_info.etag);
        file_info_reply.insert ("ETag", file_info.etag);
        file_info_reply.insert ("etag", file_info.etag);
        file_info_reply.insert ("OC-FileID", file_info.file_identifier);
        file_info_reply.insert ("X-OC-MTime", "accepted"); // Prevents Q_ASSERT (!this.runningNow) since we'll call PropagateItemJob.done twice in that case.
        /* emit */ uploadProgress (file_info.size, totalSize);
        allFileInfoReply.insert (char ('/') + file_info.path (), file_info_reply);
    }
    reply.setObject (allFileInfoReply);
    this.payload = reply.toJson ();

    set_attribute (Soup.Request.HttpStatusCodeAttribute, 200);

    setFinished (true);
    if (bytes_available ()) {
        /* emit */ readyRead ();
    }

    /* emit */ signal_meta_data_changed ();
    /* emit */ signal_finished ();
}

void FakePutMultiFileReply.on_signal_abort () {
    set_error (OperationCanceledError, "on_signal_abort");
    /* emit */ signal_finished ();
}

int64 FakePutMultiFileReply.bytes_available () {
    return this.payload.size () + QIODevice.bytes_available ();
}

int64 FakePutMultiFileReply.read_data (char data, int64 maxlen) {
    int64 len = std.min (int64 { this.payload.size () }, maxlen);
    std.copy (this.payload.cbegin (), this.payload.cbegin () + len, data);
    this.payload.remove (0, static_cast<int> (len));
    return len;
}