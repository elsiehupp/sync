/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestResetServer : AbstractTestAllFilesDeleted {

//    /***********************************************************
//    ***********************************************************/
//    private TestResetServer () {
//        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

//        int about_to_remove_all_files_called = 0;
//        fake_folder.sync_engine.signal_about_to_remove_all_files.connect (
//            this.on_signal_about_to_remove_all_files_reset_server
//        );

//        // Some small changes
//        fake_folder.local_modifier.mkdir ("Q");
//        fake_folder.local_modifier.insert ("Q/q1");
//        fake_folder.local_modifier.append_byte ("B/b1");
//        GLib.assert_true (fake_folder.sync_once ());
//        GLib.assert_true (
//            about_to_remove_all_files_called ==
//            0
//        );

//        // Do some change localy
//        fake_folder.local_modifier.append_byte ("A/a1");

//        // reset the server.
//        fake_folder.remote_modifier () = FileInfo.A12_B12_C12_S12 ();

//        // Now, signal_about_to_remove_all_files with down as a direction
//        GLib.assert_true (fake_folder.sync_once ());
//        GLib.assert_true (
//            about_to_remove_all_files_called ==
//            1
//        );
//    }


//    protected void on_signal_about_to_remove_all_files_reset_server (
//        LibSync.SyncFileItem.Direction directory,
//        Callback callback
//    ) {
//        GLib.assert_true (
//            about_to_remove_all_files_called ==
//            0
//        );
//        about_to_remove_all_files_called++;
//        GLib.assert_true (
//            directory ==
//            LibSync.SyncFileItem.Direction.DOWN
//        );
//        callback (false);
//    }

}

} // namespace Testing
} // namespace Occ
