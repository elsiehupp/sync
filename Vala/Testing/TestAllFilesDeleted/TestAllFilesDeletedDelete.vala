/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {   

public class TestAllFilesDeletedDelete : AbstractTestAllFilesDeleted {

    /***********************************************************
    This test is like the previous one but we simulate that the user presses "delete"
    ***********************************************************/
    private TestAllFilesDeletedDelete () {
        QFETCH (
            bool,
            delete_on_remote
        );
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        int about_to_remove_all_files_called = 0;
        fake_folder.sync_engine.signal_about_to_remove_all_files.connect (
            this.on_signal_about_to_remove_all_files_all_files_deleted_delete
        );

        var modifier = delete_on_remote ? fake_folder.remote_modifier () : fake_folder.local_modifier;
        foreach (var s in fake_folder.current_remote_state ().children.keys ())
            modifier.remove (s);

        GLib.assert_true (
            fake_folder.sync_once ()
        ); // Should succeed and all files must then be deleted

        GLib.assert_true (
            fake_folder.current_local_state () ==
            fake_folder.current_remote_state ()
        );
        GLib.assert_true (
            fake_folder.current_local_state ().children.count () ==
            0
        );

        // Try another sync to be sure.

        GLib.assert_true (fake_folder.sync_once ()); // Should succeed (doing nothing)
        GLib.assert_true (
            about_to_remove_all_files_called ==
            1
        ); // should not have been called.

        GLib.assert_true (
            fake_folder.current_local_state () ==
            fake_folder.current_remote_state ()
        );
        GLib.assert_true (
            fake_folder.current_local_state ().children.count () ==
            0
        );
    }


    protected void on_signal_about_to_remove_all_files_all_files_deleted_delete (
        SyncFileItem.Direction directory,
        Callback callback
    ) {
        GLib.assert_true (
            about_to_remove_all_files_called ==
            0
        );
        about_to_remove_all_files_called++;
        GLib.assert_true (
            directory ==
            delete_on_remote ? SyncFileItem.Direction.DOWN : SyncFileItem.Direction.UP
        );
        callback (false);
    }

}

}
}
