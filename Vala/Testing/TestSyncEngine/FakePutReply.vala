/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class FakePutReply : FakeReply {

    FileInfo file_info;

    /***********************************************************
    ***********************************************************/
    public FakePutReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, string put_payload, GLib.Object parent) {
        base (parent);
        set_request (request);
        set_url (request.url);
        set_operation (operation);
        open (GLib.IODevice.ReadOnly);
        file_info = perform (remote_root_file_info, request, put_payload);
        GLib.Object.invoke_method (this, "respond", GLib.QueuedConnection);
    }


    /***********************************************************
    ***********************************************************/
    public static FileInfo perform (FileInfo remote_root_file_info, Soup.Request request, string put_payload) {
        string filename = get_file_path_from_url (request.url);
        GLib.assert_true (!filename == "");
        FileInfo file_info = remote_root_file_info.find (filename);
        if (file_info) {
            file_info.size = put_payload.size ();
            file_info.content_char = put_payload.at (0);
        } else {
            // Assume that the file is filled with the same character
            file_info = remote_root_file_info.create (filename, put_payload.size (), put_payload.at (0));
        }
        file_info.last_modified = Utility.date_time_from_time_t (request.raw_header ("X-OC-Mtime").to_int64 ());
        remote_root_file_info.find (filename, /*invalidate_etags=*/true);
        return file_info;
    }


    /***********************************************************
    ***********************************************************/
    public virtual void respond () {
        /* emit */ upload_progress (file_info.size, file_info.size);
        set_raw_header ("OC-ETag", file_info.etag);
        set_raw_header ("ETag", file_info.etag);
        set_raw_header ("OC-FileID", file_info.file_identifier);
        set_raw_header ("X-OC-MTime", "accepted"); // Prevents GLib.assert_true (!this.running_now) since we'll call AbstractPropagateItemJob.done twice in that case.
        set_attribute (Soup.Request.HttpStatusCodeAttribute, 200);
        /* emit */ signal_meta_data_changed ();
        /* emit */ signal_finished ();
    }


    /***********************************************************
    ***********************************************************/
    public override bool on_signal_abort () {
        set_error (OperationCanceledError, "on_signal_abort");
        /* emit */ signal_finished ();
        return false; // only run once
    }


    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char *data, int64 length) {
        return 0;
    }

} // class FakePutReply
} // namespace Testing
} // namespace Occ
