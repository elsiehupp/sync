/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class FakeMkcolReply : FakeReply {

    FileInfo file_info;

    /***********************************************************
    ***********************************************************/
    public FakeMkcolReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request) {
        //  base ();
        //  set_request (request);
        //  set_url (request.url);
        //  set_operation (operation);
        //  open (GLib.IODevice.ReadOnly);

        //  string filename = get_file_path_from_url (request.url);
        //  GLib.assert_true (!filename == "");
        //  file_info = remote_root_file_info.create_directory (filename);

        //  if (!file_info) {
        //      on_signal_abort ();
        //      return;
        //  }
        //  GLib.Object.invoke_method (this, "respond", GLib.QueuedConnection);
    }


    /***********************************************************
    ***********************************************************/
    public void respond () {
        //  set_raw_header ("OC-FileId", file_info.file_identifier);
        //  set_attribute (Soup.Request.HttpStatusCodeAttribute, 201);
        //  signal_meta_data_changed ();
        //  signal_finished ();
    }


    /***********************************************************
    ***********************************************************/
    public override bool on_signal_abort () {
        //  return false; // only run once
    }


    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char * data, int64 length) {
        //  return 0;
    }

} // class FakeMkcolReply
} // namespace Testing
} // namespace Occ
