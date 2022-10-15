/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class FakeGetWithDataReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public const FileInfo file_info;
    public string payload;
    public uint64 offset = 0;
    public bool aborted = false;

    /***********************************************************
    ***********************************************************/
    public FakeGetWithDataReply (FileInfo remote_root_file_info, string data, Soup.Operation operation, Soup.Request request, GLib.Object parent) {
        //  base (parent);
        //  set_request (request);
        //  set_url (request.url);
        //  set_operation (operation);
        //  open (GLib.IODevice.ReadOnly);

        //  GLib.assert_true (!data == "");
        //  payload = data;
        //  string filename = get_file_path_from_url (request.url);
        //  GLib.assert_true (!filename == "");
        //  file_info = remote_root_file_info.find (filename);
        //  GLib.Object.invoke_method (this, "respond", GLib.QueuedConnection);

        //  if (request.has_raw_header ("Range")) {
        //      string range = request.raw_header ("Range").to_string ();
        //      GLib.Regex bytes_pattern = new GLib.Regex ("bytes= (?<start>\\d+)- (?<end>\\d+)");
        //      GLib.RegularExpressionMatch match = bytes_pattern.match (range);
        //      if (match.has_match ()) {
        //          int on_signal_start = match.captured ("on_signal_start").to_int ();
        //          int end = match.captured ("end").to_int ();
        //          payload = payload.mid (on_signal_start, end - on_signal_start + 1);
        //      }
        //  }
    }

    public void respond () {
        //  if (aborted) {
        //      set_error (OperationCanceledError, "Operation Canceled");
        //      signal_meta_data_changed ();
        //      signal_finished ();
        //      return;
        //  }
        //  set_header (Soup.Request.ContentLengthHeader, payload.size ());
        //  set_attribute (Soup.Request.HttpStatusCodeAttribute, 200);
        //  set_raw_header ("OC-ETag", file_info.etag);
        //  set_raw_header ("ETag", file_info.etag);
        //  set_raw_header ("OC-FileId", file_info.file_identifier);
        //  signal_meta_data_changed ();
        //  if (bytes_available ())
        //      signal_ready_read ();
        //  signal_finished ();
    }


    /***********************************************************
    ***********************************************************/
    public override bool on_signal_abort () {
        //  set_error (OperationCanceledError, "Operation Canceled");
        //  aborted = true;
        //  return false; // only run once
    }


    /***********************************************************
    ***********************************************************/
    int64 bytes_available () {
        //  if (aborted) {
        //      return 0;
        //  }
        //  return payload.size () - offset + GLib.IODevice.bytes_available ();
    }


    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char *data, int64 maxlen) {
        //  int64 len = std.min (payload.size () - offset, uint64 (maxlen));
        //  std.memcpy (data, payload.const_data () + offset, len);
        //  offset += len;
        //  return len;
    }

} // class FakeGetWithDataReply
} // namespace Testing
} // namespace Occ
