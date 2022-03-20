/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestLocalFileRemoteDirectoryConflict : AbstractTestSyncConflict {

    /***********************************************************
    ***********************************************************/
    private TestLocalFileRemoteDirectoryConflict () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.account.set_capabilities ({ { "upload_conflict_files", true } });
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        // 1) a NEW/NEW conflict
        fake_folder.remote_modifier ().mkdir ("Z");
        fake_folder.remote_modifier ().mkdir ("Z/subdir");
        fake_folder.remote_modifier ().insert ("Z/foo");
        fake_folder.local_modifier.insert ("Z");

        // 2) local directory becomes file : remote directory adds file
        fake_folder.local_modifier.remove ("A");
        fake_folder.local_modifier.insert ("A", 63);
        fake_folder.remote_modifier ().insert ("A/bar");

        // 3) local file changes; remote file becomes directory
        fake_folder.local_modifier.append_byte ("B/b1");
        fake_folder.remote_modifier ().remove ("B/b1");
        fake_folder.remote_modifier ().mkdir ("B/b1");
        fake_folder.remote_modifier ().insert ("B/b1/zzz");

        GLib.assert_true (fake_folder.sync_once ());
        var conflicts = find_conflicts (fake_folder.current_local_state ());
        conflicts += find_conflicts (fake_folder.current_local_state ().children["B"]);
        GLib.assert_true (conflicts.size () == 3);
        std.sort (conflicts.begin (), conflicts.end ());

        var conflict_records = fake_folder.sync_journal ().conflict_record_paths ();
        GLib.assert_true (conflict_records.size () == 3);
        std.sort (conflict_records.begin (), conflict_records.end ());

        // 1)
        GLib.assert_true (item_conflict (complete_spy, "Z"));
        GLib.assert_true (conflicts[2].contains ("Z"));
        GLib.assert_true (conflicts[2] == conflict_records[2]);

        // 2)
        GLib.assert_true (item_conflict (complete_spy, "A"));
        GLib.assert_true (conflicts[0].contains ("A"));
        GLib.assert_true (conflicts[0] == conflict_records[0]);

        // 3)
        GLib.assert_true (item_conflict (complete_spy, "B/b1"));
        GLib.assert_true (conflicts[1].contains ("B/b1"));
        GLib.assert_true (conflicts[1] == conflict_records[1]);

        // Also verifies that conflicts were uploaded
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }

} // class TestLocalFileRemoteDirectoryConflict

} // namespace Testing
} // namespace Occ
