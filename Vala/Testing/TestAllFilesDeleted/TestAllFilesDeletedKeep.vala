/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestAllFilesDeletedKeep : AbstractTestAllFilesDeleted {

    /***********************************************************
    In this test, all files are deleted in the client, or the
    server, and we simulate that the users press "keep"
    ***********************************************************/
    private TestAllFilesDeletedKeep () {
        QFETCH (
            bool,
            delete_on_remote
        );
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ConfigFile config;
        config.set_prompt_delete_files (true);

        //Just set a blocklist so we can check it is still there. This directory does not exists but
        // that does not matter for our purposes.
        GLib.List<string> selective_sync_blocklist = { "Q/" };
        fake_folder.sync_engine.journal.set_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST,
                                                                selective_sync_blocklist);

        var initial_state = fake_folder.current_local_state ();
        int about_to_remove_all_files_called = 0;
        fake_folder.sync_engine.signal_about_to_remove_all_files.connect (
            this.on_signal_about_to_remove_all_files_all_files_deleted_keep
        );

        var modifier = delete_on_remote ? fake_folder.remote_modifier () : fake_folder.local_modifier;
        foreach (var state in fake_folder.current_remote_state ().children.keys ()) {
            modifier.remove (state);
        }

        GLib.assert_true (!fake_folder.sync_once ()); // Should fail because we cancel the sync
        GLib.assert_true (about_to_remove_all_files_called == 1);

        // Next sync should recover all files
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (
            fake_folder.current_local_state () ==
            initial_state
        );
        GLib.assert_true (
            fake_folder.current_remote_state () ==
            initial_state
        );

        // The selective sync blocklist should be not have been deleted.
        bool ok = true;
        GLib.assert_true (
            fake_folder.sync_engine.journal.get_gelective_sync_list (
                SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST,
                ok
            ) ==
            selective_sync_blocklist
        );
    }


    protected void on_signal_about_to_remove_all_files_all_files_deleted_keep (LibSync.SyncFileItem.Direction directory, Callback callback) {
        GLib.assert_true (
            about_to_remove_all_files_called ==
            0
        );
        about_to_remove_all_files_called++;
        GLib.assert_true (
            directory ==
            delete_on_remote ? LibSync.SyncFileItem.Direction.DOWN : LibSync.SyncFileItem.Direction.UP
        );
        callback (true);
        fake_folder.sync_engine.journal.clear_file_table (); // That's what FolderConnection is doing
    }

}

}
}
