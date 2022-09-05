/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class FakeGetReply : FakeReply {

    //  /***********************************************************
    //  ***********************************************************/
    //  public const FileInfo file_info;
    //  public char payload;
    //  public int size;
    //  public bool aborted = false;

    //  /***********************************************************
    //  ***********************************************************/
    //  public FakeGetReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, GLib.Object parent) {
    //      base (parent);
    //      set_request (request);
    //      set_url (request.url);
    //      set_operation (operation);
    //      open (GLib.IODevice.ReadOnly);

    //      string filename = get_file_path_from_url (request.url);
    //      GLib.assert_true (!filename == "");
    //      file_info = remote_root_file_info.find (filename);
    //      if (!file_info) {
    //          GLib.debug ("meh;");
    //      }
    //      Q_ASSERT_X (file_info, Q_FUNC_INFO, "Could not find file on the remote");
    //      GLib.Object.invoke_method (this, FakeGetReply.respond, GLib.QueuedConnection);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void respond () {
    //      if (aborted) {
    //          set_error (OperationCanceledError, "Operation Canceled");
    //          signal_meta_data_changed ();
    //          signal_finished ();
    //          return;
    //      }
    //      payload = file_info.content_char;
    //      size = file_info.size;
    //      set_header (Soup.Request.ContentLengthHeader, size);
    //      set_attribute (Soup.Request.HttpStatusCodeAttribute, 200);
    //      set_raw_header ("OC-ETag", file_info.etag);
    //      set_raw_header ("ETag", file_info.etag);
    //      set_raw_header ("OC-FileId", file_info.file_identifier);
    //      signal_meta_data_changed ();
    //      if (bytes_available ()) {
    //          signal_ready_read ();
    //      }
    //      signal_finished ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public bool on_signal_abort () {
    //      set_error (OperationCanceledError, "Operation Canceled");
    //      aborted = true;
    //      return false; // only run once
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  int64 bytes_available () {
    //      if (aborted) {
    //          return 0;
    //      }
    //      return size + GLib.IODevice.bytes_available ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public override int64 read_data (char *data, int64 maxlen) {
    //      int64 len = std.min ((int64) size, maxlen);
    //      std.fill_n (data, len, payload);
    //      size -= len;
    //      return len;
    //  }

} // class FakeGetReply
} // namespace Testing
} // namespace Occ
