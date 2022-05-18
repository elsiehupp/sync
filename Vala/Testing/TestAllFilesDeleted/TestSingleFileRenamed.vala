/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestSingleFileRenamed : AbstractTestAllFilesDeleted {

    /***********************************************************
    ***********************************************************/
    private TestSingleFileRenamed () {
        FakeFolder fake_folder = new FakeFolder (
            new FileInfo ()
        );

        int about_to_remove_all_files_called = 0;
        fake_folder.sync_engine.signal_about_to_remove_all_files.connect (
            this.on_signal_about_to_remove_all_files_single_file_renamed
        );

        // add a single file
        fake_folder.local_modifier.insert ("hello.txt");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (about_to_remove_all_files_called == 0);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // rename it
        fake_folder.local_modifier.rename ("hello.txt", "goodbye.txt");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (about_to_remove_all_files_called == 0);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    protected void on_signal_about_to_remove_all_files_single_file_renamed (
        LibSync.SyncFileItem.Direction direction,
        Callback callback
    ) {
        about_to_remove_all_files_called++;
        GLib.assert_not_reached ("should not be called");
    }

}

} // namespace Testing
} // namespace Occ
