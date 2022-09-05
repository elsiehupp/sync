/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestNotDeleteMetadataChange : AbstractTestAllFilesDeleted {

    //  /***********************************************************
    //  This test make sure that we don't popup a file deleted
    //  message if all the metadata have been updated (for example
    //  when the server is upgraded or something)
    //  ***********************************************************/
    //  private TestNotDeleteMetadataChange () {

    //      FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
    //      // We never remove all files.
    //      fake_folder.sync_engine.signal_about_to_remove_all_files.connect (
    //          this.on_signal_about_to_remove_all_files_not_delete_metadata_change
    //      );
    //      GLib.assert_true (fake_folder.sync_once ());

    //      foreach (var s in fake_folder.current_remote_state ().children.keys ()) {
    //          fake_folder.sync_journal ().avoid_renames_on_next_sync (s); // clears all the fileid and inodes.
    //      }
    //      fake_folder.local_modifier.remove ("A/a1");
    //      var expected_state = fake_folder.current_local_state ();
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (
    //          fake_folder.current_local_state () ==
    //          expected_state
    //      );
    //      GLib.assert_true (
    //          fake_folder.current_remote_state () ==
    //          expected_state
    //      );

    //      fake_folder.remote_modifier ().remove ("B/b1");
    //      change_all_file_id (fake_folder.remote_modifier ());
    //      expected_state = fake_folder.current_remote_state ();
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (
    //          fake_folder.current_local_state () ==
    //          expected_state
    //      );
    //      GLib.assert_true (
    //          fake_folder.current_remote_state () ==
    //          expected_state
    //      );
    //  }


    //  protected void on_signal_about_to_remove_all_files_not_delete_metadata_change () {
    //      GLib.assert_true (false);
    //  }

}

} // namespace Testing
} // namespace Occ
