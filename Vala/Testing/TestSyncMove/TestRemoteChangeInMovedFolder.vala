/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestRemoteChangeInMovedFolder : AbstractTestSyncMove {

    /***********************************************************
    ***********************************************************/
    private TestRemoteChangeInMovedFolder () {
        //  // issue #5192
        //  FakeFolder fake_folder = new FakeFolder (
        //      new FileInfo (
        //          "", {
        //              new FileInfo (
        //                  "folder", {
        //                      new FileInfo (
        //                          "folder_a", {
        //                              { "file.txt", 400 }
        //                          }
        //                      ), "folder_b"
        //                  }
        //              )
        //          }
        //      )
        //  );

        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        //  // Edit a file in a moved directory.
        //  fake_folder.remote_modifier ().set_contents ("folder/folder_a/file.txt", 'a');
        //  fake_folder.remote_modifier ().rename ("folder/folder_a", "folder/folder_b/folder_a");
        //  fake_folder.sync_once ();
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  var old_state = fake_folder.current_local_state ();
        //  GLib.assert_true (old_state.find ("folder/folder_b/folder_a/file.txt"));
        //  GLib.assert_true (!old_state.find ("folder/folder_a/file.txt"));

        //  // This sync should not remove the file
        //  fake_folder.sync_once ();
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  GLib.assert_true (fake_folder.current_local_state () == old_state);
    }

} // class TestRemoteChangeInMovedFolder

} // namespace Testing
} // namespace Occ
