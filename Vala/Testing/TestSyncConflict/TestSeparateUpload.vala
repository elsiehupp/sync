/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestSeparateUpload : AbstractTestSyncConflict {

    /***********************************************************
    ***********************************************************/
    private TestSeparateUpload () {
        //  FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        //  fake_folder.sync_engine.account.set_capabilities ({ { "upload_conflict_files", true } });
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        //  GLib.HashTable<string, string> conflict_map;
        //  fake_folder.set_server_override (this.override_delegate_separate_upload);

        //  // Explicitly add a conflict file to simulate the case where the upload of the
        //  // file didn't finish in the same sync run that the conflict was created.
        //  // To do that we need to create a mock conflict record.
        //  var a1FileId = fake_folder.remote_modifier ().find ("A/a1").file_identifier;
        //  string conflict_name = "A/a1 (conflicted copy me 1234)";
        //  fake_folder.local_modifier.insert (conflict_name, 64, 'L');
        //  ConflictRecord conflict_record;
        //  conflict_record.path = conflict_name;
        //  conflict_record.base_file_id = a1FileId;
        //  conflict_record.initial_base_path = "A/a1";
        //  fake_folder.sync_journal ().set_conflict_record (conflict_record);
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  GLib.assert_true (conflict_map.size () == 1);
        //  GLib.assert_true (conflict_map[a1FileId] == conflict_name);
        //  GLib.assert_true (fake_folder.current_remote_state ().find (conflict_map[a1FileId]).content_char == 'L');
        //  conflict_map = "";

        //  // Now the user can locally alter the conflict file and it will be uploaded
        //  // as usual.
        //  fake_folder.local_modifier.set_contents (conflict_name, 'P');
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (conflict_map.size () == 1);
        //  GLib.assert_true (conflict_map[a1FileId] == conflict_name);
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  conflict_map = "";

        //  // Similarly, remote modifications of conflict files get propagated downwards
        //  fake_folder.remote_modifier ().set_contents (conflict_name, 'Q');
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  GLib.assert_true (conflict_map == "");

        //  // Conflict files for conflict files!
        //  var a1ConflictFileId = fake_folder.remote_modifier ().find (conflict_name).file_identifier;
        //  fake_folder.remote_modifier ().append_byte (conflict_name);
        //  fake_folder.remote_modifier ().append_byte (conflict_name);
        //  fake_folder.local_modifier.append_byte (conflict_name);
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  GLib.assert_true (conflict_map.size () == 1);
        //  GLib.assert_true (conflict_map.contains (a1ConflictFileId));
        //  GLib.assert_true (fake_folder.current_remote_state ().find (conflict_name).size == 66);
        //  GLib.assert_true (fake_folder.current_remote_state ().find (conflict_map[a1ConflictFileId]).size == 65);
        //  conflict_map = "";
    }


    private GLib.InputStream override_delegate_separate_upload (Soup.Operation operation, Soup.Request request, GLib.OutputStream device) {
        //  if (operation == Soup.PutOperation) {
        //      if (request.raw_header ("OC-Conflict") == "1") {
        //          var base_file_id = request.raw_header ("OC-ConflictBaseFileId");
        //          var components = request.url.to_string ().split ("/");
        //          string conflict_file = components.mid (components.size () - 2).join ("/");
        //          conflict_map[base_file_id] = conflict_file;
        //          GLib.assert_true (!base_file_id == "");
        //          GLib.assert_true (request.raw_header ("OC-ConflictInitialBasePath") == Utility.conflict_file_base_name_from_pattern (conflict_file));
        //      }
        //  }
        //  return null;
    }

} // class TestSeparateUpload

} // namespace Testing
} // namespace Occ
