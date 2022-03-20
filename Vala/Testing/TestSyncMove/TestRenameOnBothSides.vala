/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestRenameOnBothSides : AbstractTestSyncMove {

    /***********************************************************
    ***********************************************************/
    private TestRenameOnBothSides () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        // Test that renaming a file within a directory that was renamed on the other side actually do a rename.

        // 1) move the folder alphabeticaly before
        fake_folder.remote_modifier ().rename ("A/a1", "A/a1m");
        fake_folder.local_modifier.rename ("A", "this.A");
        fake_folder.local_modifier.rename ("B/b1", "B/b1m");
        fake_folder.remote_modifier ().rename ("B", "this.B");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_remote_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("this.A/a1m"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("this.B/b1m"));
        GLib.assert_true (counter.number_of_delete == 0);
        GLib.assert_true (counter.number_of_get == 0);
        GLib.assert_true (counter.number_of_put == 0);
        GLib.assert_true (counter.number_of_move == 2);
        counter.on_signal_reset ();

        // 2) move alphabetically after
        fake_folder.remote_modifier ().rename ("this.A/a2", "this.A/a2m");
        fake_folder.local_modifier.rename ("this.B/b2", "this.B/b2m");
        fake_folder.local_modifier.rename ("this.A", "S/A");
        fake_folder.remote_modifier ().rename ("this.B", "S/B");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_remote_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("S/A/a2m"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("S/B/b2m"));
        GLib.assert_true (counter.number_of_delete == 0);
        GLib.assert_true (counter.number_of_get == 0);
        GLib.assert_true (counter.number_of_put == 0);
        GLib.assert_true (counter.number_of_move == 2);
    }

} // class TestRenameOnBothSides

} // namespace Testing
} // namespace Occ
