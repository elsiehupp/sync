
namespace Testing {

class FakeChunkMoveReply : FakeReply {

    FileInfo file_info;

    /***********************************************************
    ***********************************************************/
    public FakeChunkMoveReply (FileInfo uploads_file_info, FileInfo remote_root_file_info,
        Soup.Operation operation, Soup.Request request,
        GLib.Object parent) {
        base (parent);
        set_request (request);
        set_url (request.url ());
        set_operation (operation);
        open (QIODevice.ReadOnly);
        file_info = perform (uploads_file_info, remote_root_file_info, request);
        if (!file_info) {
            QTimer.single_shot (0, this, &FakeChunkMoveReply.respond_precondition_failed);
        } else {
            QTimer.single_shot (0, this, &FakeChunkMoveReply.respond);
        }
    }

    /***********************************************************
    ***********************************************************/
    public static FileInfo perform (FileInfo uploads_file_info, FileInfo remote_root_file_info, Soup.Request request) {
        string source = get_file_path_from_url (request.url ());
        GLib.assert_true (!source.is_empty ());
        GLib.assert_true (source.ends_with ("/.file"));
        source = source.left (source.length () - (int) (qstrlen ("/.file")));

        var source_folder = uploads_file_info.find (source);
        GLib.assert_true (source_folder);
        GLib.assert_true (source_folder.is_directory);
        int count = 0;
        int64 size = 0;
        char payload = '\0';

        string filename = get_file_path_from_url (GLib.Uri.from_encoded (request.raw_header ("Destination")));
        GLib.assert_true (!filename.is_empty ());

        // Compute the size and content from the chunks if possible
        foreach (var chunk_name in source_folder.children.keys ()) {
            var x = source_folder.children[chunk_name];
            GLib.assert_true (!x.is_directory);
            GLib.assert_true (x.size > 0); // There should not be empty chunks
            size += x.size;
            GLib.assert_true (!payload || payload == x.content_char);
            payload = x.content_char;
            ++count;
        }
        GLib.assert_true (source_folder.children.count () == count); // There should not be holes or extra files

        // Note: This does not actually assemble the file data from the chunks!
        FileInfo file_info = remote_root_file_info.find (filename);
        if (file_info) {
            // The client should put this header
            GLib.assert_true (request.has_raw_header ("If"));

            // And it should condition on the destination file
            var on_signal_start = GLib.ByteArray ("<" + request.raw_header ("Destination") + ">");
            GLib.assert_true (request.raw_header ("If").starts_with (on_signal_start));

            if (request.raw_header ("If") != on_signal_start + " ([\"" + file_info.etag + "\"])") {
                return null;
            }
            file_info.size = size;
            file_info.content_char = payload;
        } else {
            GLib.assert_true (!request.has_raw_header ("If"));
            // Assume that the file is filled with the same character
            file_info = remote_root_file_info.create (filename, size, payload);
        }
        file_info.last_modified = Occ.Utility.date_time_from_time_t (request.raw_header ("X-OC-Mtime").to_int64 ());
        remote_root_file_info.find (filename, /*invalidate_etags=*/true);

        return file_info;
    }

    /***********************************************************
    ***********************************************************/
    public virtual void respond () {
        set_attribute (Soup.Request.HttpStatusCodeAttribute, 201);
        set_raw_header ("OC-ETag", file_info.etag);
        set_raw_header ("ETag", file_info.etag);
        set_raw_header ("OC-FileId", file_info.file_identifier);
        /* emit */ signal_meta_data_changed ();
        /* emit */ signal_finished ();
    }

    /***********************************************************
    ***********************************************************/
    public void respond_precondition_failed () {
        set_attribute (Soup.Request.HttpStatusCodeAttribute, 412);
        set_error (InternalServerError, "Precondition Failed");
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
    public override int64 read_data (char *characters, int64 number) {
        return 0;
    }

}
}
