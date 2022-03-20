/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestTypeChange : AbstractTestSyncConflict {

    /***********************************************************
    ***********************************************************/
    private TestTypeChange () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        // directory becomes file
        fake_folder.remote_modifier ().remove ("A");
        fake_folder.remote_modifier ().insert ("A");
        fake_folder.local_modifier.remove ("B");
        fake_folder.local_modifier.insert ("B");

        // file becomes directory
        fake_folder.remote_modifier ().remove ("C/c1");
        fake_folder.remote_modifier ().mkdir ("C/c1");
        fake_folder.remote_modifier ().insert ("C/c1/foo");
        fake_folder.local_modifier.remove ("C/c2");
        fake_folder.local_modifier.mkdir ("C/c2");
        fake_folder.local_modifier.insert ("C/c2/bar");

        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (item_successful (complete_spy, "A", CSync.SyncInstructions.TYPE_CHANGE));
        GLib.assert_true (item_successful (complete_spy, "B", CSync.SyncInstructions.TYPE_CHANGE));
        GLib.assert_true (item_successful (complete_spy, "C/c1", CSync.SyncInstructions.TYPE_CHANGE));
        GLib.assert_true (item_successful (complete_spy, "C/c2", CSync.SyncInstructions.TYPE_CHANGE));

        // A becomes a conflict because we don't delete folders with files
        // inside of them!
        var conflicts = find_conflicts (fake_folder.current_local_state ());
        GLib.assert_true (conflicts.size () == 1);
        GLib.assert_true (conflicts[0].contains ("A (conflicted copy"));
        foreach (var conflict in conflicts) {
            GLib.Dir (fake_folder.local_path + conflict).remove_recursively ();
        }

        GLib.assert_true (fake_folder.sync_engine.is_another_sync_needed () == ImmediateFollowUp);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }

} // class TestTypeChange

} // namespace Testing
} // namespace Occ
