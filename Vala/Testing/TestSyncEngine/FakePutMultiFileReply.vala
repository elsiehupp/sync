/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class FakePutMultiFileReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    private GLib.List<FileInfo> all_file_info;

    /***********************************************************
    ***********************************************************/
    private string payload;

    /***********************************************************
    ***********************************************************/
    public FakePutMultiFileReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, string content_type, string put_payload, GLib.Object parent) {
        base (parent);
        set_request (request);
        set_url (request.url);
        set_operation (operation);
        open (QIODevice.ReadOnly);
        this.all_file_info = perform_multi_part (remote_root_file_info, request, put_payload, content_type);
        GLib.Object.invoke_method (this, "respond", Qt.QueuedConnection);
    }


    /***********************************************************
    ***********************************************************/
    public static GLib.List<FileInfo> perform_multi_part (FileInfo remote_root_file_info, Soup.Request request, string put_payload, string content_type);
    GLib.List<FileInfo> FakePutMultiFileReply.perform_multi_part (FileInfo remote_root_file_info, Soup.Request request, string put_payload, string content_type) {
        GLib.List<FileInfo> result;

        var string_put_payload = put_payload;
        const int boundary_position = "multipart/related; boundary=".size ();
        const string boundary_value = "--" + content_type.mid (boundary_position, content_type.length - boundary_position - 1) + "\r\n";
        var string_put_payload_reference = string_put_payload.left (string_put_payload.size () - 2 - boundary_value.size ());
        var all_parts = string_put_payload_reference.split (boundary_value, Qt.SkipEmptyParts);
        foreach (var one_part in all_parts) {
            var header_end_position = one_part.index_of ("\r\n\r\n");
            var one_part_header_part = one_part.left (header_end_position);
            var one_part_body = one_part.mid (header_end_position + 4, one_part.size () - header_end_position - 6);
            var one_part_header = one_part_header_part.split ("\r\n");
            GLib.HashTable<string, string> all_headers;
            foreach (var one_header in one_part_header) {
                var header_parts = one_header.split (":");
                all_headers[header_parts.at (0)] = header_parts.at (1);
            }
            var filename = all_headers["X-File-Path"];
            GLib.assert_true (!filename == "");
            FileInfo file_info = remote_root_file_info.find (filename);
            if (file_info) {
                file_info.size = one_part_body.size ();
                file_info.content_char = one_part_body.at (0);
            } else {
                // Assume that the file is filled with the same character
                file_info = remote_root_file_info.create (filename, one_part_body.size (), one_part_body.at (0));
            }
            file_info.last_modified = Utility.date_time_from_time_t (request.raw_header ("X-OC-Mtime").to_int64 ());
            remote_root_file_info.find (filename, /*invalidate_etags=*/true);
            result.push_back (file_info);
        }
        return result;
    }


    /***********************************************************
    ***********************************************************/
    public virtual void respond ();
    void FakePutMultiFileReply.respond () {
        QJsonDocument reply;
        QJsonObject all_file_info_reply;

        int64 total_size = 0;

        foreach (var file_info in this.all_file_info) {
            total_size += file_info.size;
        }

        foreach (var file_info in this.all_file_info) {
            QJsonObject file_info_reply;
            file_info_reply.insert ("error", "false");
            file_info_reply.insert ("OC-OperationStatus", file_info.operation_status);
            file_info_reply.insert ("X-File-Path", file_info.path);
            file_info_reply.insert ("OC-ETag", file_info.etag);
            file_info_reply.insert ("ETag", file_info.etag);
            file_info_reply.insert ("etag", file_info.etag);
            file_info_reply.insert ("OC-FileID", file_info.file_identifier);
            file_info_reply.insert ("X-OC-MTime", "accepted"); // Prevents GLib.assert_true (!this.running_now) since we'll call AbstractPropagateItemJob.done twice in that case.
            /* emit */ upload_progress (file_info.size, total_size);
            all_file_info_reply.insert (char ('/') + file_info.path, file_info_reply);
        }
        reply.set_object (all_file_info_reply);
        this.payload = reply.to_json ();

        set_attribute (Soup.Request.HttpStatusCodeAttribute, 200);

        set_finished (true);
        if (bytes_available ()) {
            /* emit */ signal_ready_read ();
        }

        /* emit */ signal_meta_data_changed ();
        /* emit */ signal_finished ();
    }


    /***********************************************************
    ***********************************************************/
    public override void on_signal_abort () {
        set_error (OperationCanceledError, "on_signal_abort");
        /* emit */ signal_finished ();
    }


    /***********************************************************
    ***********************************************************/
    public override int64 bytes_available () {
        return this.payload.size () + QIODevice.bytes_available ();
    }


    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char *data, int64 maxlen) {
        int64 len = std.min ((int64)this.payload.size (), maxlen);
        std.copy (this.payload.cbegin (), this.payload.cbegin () + len, data);
        this.payload.remove (0, (int) (len));
        return len;
    }

}

} // namespace Testing
} // namespace Occ











