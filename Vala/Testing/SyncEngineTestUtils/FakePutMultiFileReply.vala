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
    public FakePutMultiFileReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, string content_type, GLib.ByteArray put_payload, GLib.Object parent);

    /***********************************************************
    ***********************************************************/
    public static GLib.Vector<FileInfo> performMultiPart (FileInfo remote_root_file_info, Soup.Request request, GLib.ByteArray put_payload, string content_type);

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
    public int64 read_data (char *data, int64 maxlen) override;

}
}







FakePutMultiFileReply.FakePutMultiFileReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, string content_type, GLib.ByteArray put_payload, GLib.Object parent)
    : FakeReply (parent); {
    set_request (request);
    set_url (request.url ());
    set_operation (operation);
    open (QIODevice.ReadOnly);
    this.allFileInfo = performMultiPart (remote_root_file_info, request, put_payload, content_type);
    QMetaObject.invoke_method (this, "respond", Qt.QueuedConnection);
}

GLib.Vector<FileInfo> FakePutMultiFileReply.performMultiPart (FileInfo remote_root_file_info, Soup.Request request, GLib.ByteArray put_payload, string content_type) {
    GLib.Vector<FileInfo> result;

    var string_put_payload = string.fromUtf8 (put_payload);
    const int boundary_position = sizeof ("multipart/related; boundary=");
    const string boundary_value = "--" + content_type.mid (boundary_position, content_type.length () - boundary_position - 1) + "\r\n";
    var string_put_payload_reference = string{string_put_payload}.left (string_put_payload.size () - 2 - boundary_value.size ());
    var all_parts = string_put_payload_reference.split (boundary_value, Qt.SkipEmptyParts);
    for (var one_part : all_parts) {
        var header_end_position = one_part.indexOf ("\r\n\r\n");
        var one_part_header_part = one_part.left (header_end_position);
        var onePartBody = one_part.mid (header_end_position + 4, one_part.size () - header_end_position - 6);
        var one_part_header = one_part_header_part.split ("\r\n");
        GLib.HashMap<string, string> all_headers;
        for (var one_header : one_part_header) {
            var header_parts = one_header.split (":");
            all_headers[header_parts.at (0)] = header_parts.at (1);
        }
        var filename = all_headers["X-File-Path"];
        //  Q_ASSERT (!filename.isEmpty ());
        FileInfo file_info = remote_root_file_info.find (filename);
        if (file_info) {
            file_info.size = onePartBody.size ();
            file_info.content_char = onePartBody.at (0).toLatin1 ();
        } else {
            // Assume that the file is filled with the same character
            file_info = remote_root_file_info.create (filename, onePartBody.size (), onePartBody.at (0).toLatin1 ());
        }
        file_info.last_modified = Occ.Utility.qDateTimeFromTime_t (request.rawHeader ("X-OC-Mtime").toLongLong ());
        remote_root_file_info.find (filename, /*invalidateEtags=*/true);
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
        /* emit */ signal_ready_read ();
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

int64 FakePutMultiFileReply.read_data (char *data, int64 maxlen) {
    int64 len = std.min (int64 { this.payload.size () }, maxlen);
    std.copy (this.payload.cbegin (), this.payload.cbegin () + len, data);
    this.payload.remove (0, static_cast<int> (len));
    return len;
}