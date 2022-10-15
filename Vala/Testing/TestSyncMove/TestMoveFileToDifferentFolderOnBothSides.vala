/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestMoveFileToDifferentFolderOnBothSides : AbstractTestSyncMove {

    /***********************************************************
    ***********************************************************/
    private TestMoveFileToDifferentFolderOnBothSides () {
        //  FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        //  OperationCounter counter;
        //  fake_folder.set_server_override (counter.functor ());

        //  // Test that moving a file within to different folder on both side does the right thing.

        //  fake_folder.remote_modifier ().rename ("B/b1", "A/b1");
        //  fake_folder.local_modifier.rename ("B/b1", "C/b1");

        //  fake_folder.local_modifier.rename ("B/b2", "A/b2");
        //  fake_folder.remote_modifier ().rename ("B/b2", "C/b2");

        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_remote_state () == fake_folder.current_remote_state ());
        //  GLib.assert_true (fake_folder.current_remote_state ().find ("A/b1"));
        //  GLib.assert_true (fake_folder.current_remote_state ().find ("C/b1"));
        //  GLib.assert_true (fake_folder.current_remote_state ().find ("A/b2"));
        //  GLib.assert_true (fake_folder.current_remote_state ().find ("C/b2"));
        //  GLib.assert_true (counter.number_of_move == 0); // Unfortunately, we can't really make a move in this case
        //  GLib.assert_true (counter.number_of_get == 2);
        //  GLib.assert_true (counter.number_of_put == 2);
        //  GLib.assert_true (counter.number_of_delete == 0);
        //  counter.reset ();

    }

} // class TestMoveFileToDifferentFolderOnBothSides

} // namespace Testing
} // namespace Occ
