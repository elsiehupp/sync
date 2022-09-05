/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestTypeConflictWithMove : AbstractTestSyncConflict {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestTypeConflictWithMove () {
    //      FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
    //      ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

    //      // the remote becomes a file, but a file inside the directory has moved away!
    //      fake_folder.remote_modifier ().remove ("A");
    //      fake_folder.remote_modifier ().insert ("A");
    //      fake_folder.local_modifier.rename ("A/a1", "a1");

    //      // same, but with a new file inside the directory locally
    //      fake_folder.remote_modifier ().remove ("B");
    //      fake_folder.remote_modifier ().insert ("B");
    //      fake_folder.local_modifier.rename ("B/b1", "b1");
    //      fake_folder.local_modifier.insert ("B/new");

    //      GLib.assert_true (fake_folder.sync_once ());

    //      GLib.assert_true (item_successful (complete_spy, "A", CSync.SyncInstructions.TYPE_CHANGE));
    //      GLib.assert_true (item_conflict (complete_spy, "B"));

    //      var conflicts = find_conflicts (fake_folder.current_local_state ());
    //      std.sort (conflicts.begin (), conflicts.end ());
    //      GLib.assert_true (conflicts.size () == 2);
    //      GLib.assert_true (conflicts[0].contains ("A (conflicted copy"));
    //      GLib.assert_true (conflicts[1].contains ("B (conflicted copy"));
    //      foreach (var conflict in conflicts) {
    //          GLib.Dir (fake_folder.local_path + conflict).remove_recursively ();
    //      }
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

    //      // Currently a1 and b1 don't get moved, but redownloaded
    //  }

} // class TestTypeConflictWithMove

} // namespace Testing
} // namespace Occ
