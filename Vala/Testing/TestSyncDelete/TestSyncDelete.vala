/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <syncengine.h>

namespace Occ {
namespace Testing {

public class TestSyncDelete : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private test_delete_directory_with_new_file () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        // Remove a directory on the server with new files on the client
        fake_folder.remote_modifier ().remove ("A");
        fake_folder.local_modifier.insert ("A/hello.txt");

        // Symetry
        fake_folder.local_modifier.remove ("B");
        fake_folder.remote_modifier ().insert ("B/hello.txt");

        GLib.assert_true (fake_folder.sync_once ());

        // A/a1 must be gone because the directory was removed on the server, but hello.txt must be there
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/hello.txt"));

        // Symetry
        GLib.assert_true (!fake_folder.current_remote_state ().find ("B/b1"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("B/hello.txt"));

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void issue1329 () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        fake_folder.local_modifier.remove ("B");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Add a directory that was just removed in the previous sync:
        fake_folder.local_modifier.mkdir ("B");
        fake_folder.local_modifier.insert ("B/b1");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("B/b1"));
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }

}

} // namespace Testing
} // namespace Occ
