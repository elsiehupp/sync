/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestSelectiveSyncPopup : AbstractTestAllFilesDeleted {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestSelectiveSyncPopup () {
    //      /***********************************************************
    //      Unselecting all folder should not cause the popup to be shown
    //      ***********************************************************/
    //      FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

    //      int about_to_remove_all_files_called = 0;
    //      fake_folder.sync_engine.signal_about_to_remove_all_files.connect (
    //          this.on_signal_about_to_remove_all_files_selective_sync_o_popup
    //      );

    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (about_to_remove_all_files_called == 0);
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

    //      fake_folder.sync_engine.journal.set_selective_sync_list (
    //          Common.SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST,
    //          {
    //              "A/", "B/", "C/", "S/"
    //          }
    //      );

    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state () == new FileInfo ()); // all files should be one localy
    //      GLib.assert_true (fake_folder.current_remote_state () == FileInfo.A12_B12_C12_S12 ()); // Server not changed
    //      GLib.assert_true (about_to_remove_all_files_called == 0); // But we did not show the popup
    //  }


    //  protected void on_signal_about_to_remove_all_files_selective_sync_o_popup (
    //      LibSync.SyncFileItem.Direction direction,
    //      Callback callback
    //  ) {
    //      about_to_remove_all_files_called++;
    //      GLib.assert_not_reached ("should not be called");
    //  }

}

} // namespace Testing
} // namespace Occ
