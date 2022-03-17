/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

public class FakeQNAM : Soup {

    /***********************************************************
    ***********************************************************/
    private FileInfo remote_root_file_info;

    /***********************************************************
    ***********************************************************/
    private FileInfo upload_file_info;

    /***********************************************************
    Maps a path to an HTTP error
    ***********************************************************/
    private GLib.HashTable<string, int> error_paths;

    /***********************************************************
    Monitor requests and optionally provide custom replies
    ***********************************************************/
    private OverrideDelegate override_value;

    /***********************************************************
    ***********************************************************/
    public delegate Soup.Reply OverrideDelegate (Operation value1, Soup.Request value2, QIODevice value3);

    /***********************************************************
    ***********************************************************/
    public FakeQNAM (FileInfo initial_root_file_info) {
        this.remote_root_file_info = std.move (initial_root_file_info);
        set_cookie_jar (new Occ.CookieJar ());
    }


    /***********************************************************
    ***********************************************************/
    public FileInfo current_remote_state () {
        return this.remote_root_file_info;
    }


    /***********************************************************
    ***********************************************************/
    public FileInfo upload_state () {
        return this.upload_file_info;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.HashTable<string, int> error_paths () {
        return this.error_paths;
    }

    delegate QJsonObject ReplyFunction (GLib.HashTable<string, string> map);

    /***********************************************************
    ***********************************************************/
    public QJsonObject for_each_reply_part (
        QIODevice outgoing_data,
        string content_type,
        ReplyFunction reply_function) {
        var full_reply = new QJsonObject ();
        var put_payload = outgoing_data.peek (outgoing_data.bytes_available ());
        outgoing_data.on_signal_reset ();
        string string_put_payload = put_payload;
        const int boundary_position = "multipart/related; boundary=".size ();
        const string boundary_value = "--" + content_type.mid (boundary_position, content_type.length () - boundary_position - 1) + "\r\n";
        var string_put_payload_reference = string_put_payload.left (string_put_payload.size () - 2 - boundary_value.size ());
        var all_parts = string_put_payload_reference.split (boundary_value, Qt.SkipEmptyParts);
        foreach (var one_part in all_parts) {
            var header_end_position = one_part.index_of ("\r\n\r\n");
            var one_part_header_part = one_part.left (header_end_position);
            var one_part_header = one_part_header_part.split ("\r\n");
            GLib.HashTable<string, string> all_headers;
            foreach (var one_header in one_part_header) {
                var header_parts = one_header.split (":");
                all_headers[header_parts.at (0)] = header_parts.at (1);
            }
            var reply = reply_function (all_headers);
            if (reply.contains ("error") && reply.contains ("etag")) {
                full_reply.insert (all_headers["X-File-Path"], reply);
            }
        }

        return full_reply;
    }


    /***********************************************************
    ***********************************************************/
    public Soup.Reply override_reply_with_error (string filename, Operation operation, Soup.Request new_request) {
        Soup.Reply reply = null;

        GLib.assert_true (!filename.is_null ());
        if (this.error_paths.contains (filename)) {
            reply = new FakeErrorReply (operation, new_request, this, this.error_paths[filename]);
        }

        return reply;
    }


    /***********************************************************
    ***********************************************************/
    protected override Soup.Reply create_request (
        Operation operation,
        Soup.Request request,
        QIODevice outgoing_data = null) {
        Soup.Reply reply = null;
        var new_request = request;
        new_request.set_raw_header ("X-Request-ID", Occ.AccessManager.generate_request_identifier ());
        var content_type = request.header (Soup.Request.ContentTypeHeader).to_string ();
        if (this.override_value) {
            var reply_override = this.override_value (operation, new_request, outgoing_data);
            if (reply_override) {
                reply = reply_override;
            }
        }
        if (!reply) {
            reply = override_reply_with_error (get_file_path_from_url (new_request.url ()), operation, new_request);
        }
        if (!reply) {
            const bool is_upload = new_request.url ().path ().starts_with (s_upload_url.path ());
            FileInfo info = is_upload ? this.upload_file_info : this.remote_root_file_info;

            var verb = new_request.attribute (Soup.Request.CustomVerbAttribute);
            if (verb == "PROPFIND") {
                // Ignore outgoing_data always returning somethign good enough, works for now.
                reply = new FakePropfindReply (info, operation, new_request, this);
            } else if (verb == "GET" || operation == Soup.GetOperation) {
                reply = new FakeGetReply (info, operation, new_request, this);
            } else if (verb == "PUT" || operation == Soup.PutOperation) {
                reply = new FakePutReply (info, operation, new_request, outgoing_data.read_all (), this);
            } else if (verb == "MKCOL") {
                reply = new FakeMkcolReply (info, operation, new_request, this);
            } else if (verb == "DELETE" || operation == Soup.DeleteOperation) {
                reply = new FakeDeleteReply (info, operation, new_request, this);
            } else if (verb == "MOVE" && !is_upload) {
                reply = new FakeMoveReply (info, operation, new_request, this);
            } else if (verb == "MOVE" && is_upload) {
                reply = new FakeChunkMoveReply ( info, this.remote_root_file_info, operation, new_request, this);
            } else if (verb == "POST" || operation == Soup.PostOperation) {
                if (content_type.starts_with ("multipart/related; boundary=")) {
                    reply = new FakePutMultiFileReply (info, operation, new_request, content_type, outgoing_data.read_all (), this);
                }
            } else {
                GLib.debug (verb + outgoing_data);
                Q_UNREACHABLE ();
            }
        }
        Occ.HttpLogger.log_request (reply, operation, outgoing_data);
        return reply;
    }

} // class FakeQNAM 
} // namespace Testing
