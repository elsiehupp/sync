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
    public FakeGetWithDataReply (FileInfo remote_root_file_info, GLib.ByteArray data, Soup.Operation operation, Soup.Request request, GLib.Object parent) {
        base (parent);
        set_request (request);
        set_url (request.url ());
        set_operation (operation);
        open (QIODevice.ReadOnly);

        //  Q_ASSERT (!data.isEmpty ());
        payload = data;
        string filename = get_file_path_from_url (request.url ());
        //  Q_ASSERT (!filename.isEmpty ());
        file_info = remote_root_file_info.find (filename);
        QMetaObject.invoke_method (this, "respond", Qt.QueuedConnection);

        if (request.hasRawHeader ("Range")) {
            const string range = string.fromUtf8 (request.rawHeader ("Range"));
            const QRegularExpression bytesPattern = new QRegularExpression ("bytes= (?<on_signal_start>\\d+)- (?<end>\\d+)");
            const QRegularExpressionMatch match = bytesPattern.match (range);
            if (match.hasMatch ()) {
                const int on_signal_start = match.captured ("on_signal_start").toInt ();
                const int end = match.captured ("end").toInt ();
                payload = payload.mid (on_signal_start, end - on_signal_start + 1);
            }
        }
    }

    public void respond () {
        if (aborted) {
            set_error (OperationCanceledError, "Operation Canceled");
            /* emit */ signal_meta_data_changed ();
            /* emit */ signal_finished ();
            return;
        }
        setHeader (Soup.Request.ContentLengthHeader, payload.size ());
        set_attribute (Soup.Request.HttpStatusCodeAttribute, 200);
        set_raw_header ("OC-ETag", file_info.etag);
        set_raw_header ("ETag", file_info.etag);
        set_raw_header ("OC-FileId", file_info.file_identifier);
        /* emit */ signal_meta_data_changed ();
        if (bytes_available ())
            /* emit */ signal_ready_read ();
        /* emit */ signal_finished ();
    }

    /***********************************************************
    ***********************************************************/
    public override void on_signal_abort () {
        set_error (OperationCanceledError, "Operation Canceled");
        aborted = true;
    }


    /***********************************************************
    ***********************************************************/
    int64 bytes_available () {
        if (aborted) {
            return 0;
        }
        return payload.size () - offset + QIODevice.bytes_available ();
    }


    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char *data, int64 maxlen) {
        int64 len = std.min (payload.size () - offset, uint64 (maxlen));
        std.memcpy (data, payload.constData () + offset, len);
        offset += len;
        return len;
    }

} // class FakeGetWithDataReply
} // namespace Testing
