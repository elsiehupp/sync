/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestLocalDirectoryRemoteFileConflict : AbstractTestSyncConflict {

    /***********************************************************
    ***********************************************************/
    private TestLocalDirectoryRemoteFileConflict () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.account.set_capabilities ({ { "upload_conflict_files", true } });
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        clean_up ();

        // 1) a NEW/NEW conflict
        fake_folder.local_modifier.mkdir ("Z");
        fake_folder.local_modifier.mkdir ("Z/subdir");
        fake_folder.local_modifier.insert ("Z/foo");
        fake_folder.remote_modifier ().insert ("Z", 63);

        // 2) local file becomes a directory; remote file changes
        fake_folder.local_modifier.remove ("A/a1");
        fake_folder.local_modifier.mkdir ("A/a1");
        fake_folder.local_modifier.insert ("A/a1/bar");
        fake_folder.remote_modifier ().append_byte ("A/a1");

        // 3) local directory gets a new file; remote directory becomes a file
        fake_folder.local_modifier.insert ("B/zzz");
        fake_folder.remote_modifier ().remove ("B");
        fake_folder.remote_modifier ().insert ("B", 31);

        GLib.assert_true (fake_folder.sync_once ());

        var conflicts = find_conflicts (fake_folder.current_local_state ());
        conflicts += find_conflicts (fake_folder.current_local_state ().children["A"]);
        GLib.assert_true (conflicts.size () == 3);
        std.sort (conflicts.begin (), conflicts.end ());

        var conflict_records = fake_folder.sync_journal ().conflict_record_paths ();
        GLib.assert_true (conflict_records.size () == 3);
        std.sort (conflict_records.begin (), conflict_records.end ());

        // 1)
        GLib.assert_true (item_conflict (complete_spy, "Z"));
        GLib.assert_true (fake_folder.current_local_state ().find ("Z").size == 63);
        GLib.assert_true (conflicts[2].contains ("Z"));
        GLib.assert_true (conflicts[2] == conflict_records[2]);
        GLib.assert_true (GLib.FileInfo (fake_folder.local_path + conflicts[2]).is_directory ());
        GLib.assert_true (GLib.File.exists (fake_folder.local_path + conflicts[2] + "/foo"));

        // 2)
        GLib.assert_true (item_conflict (complete_spy, "A/a1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1").size == 5);
        GLib.assert_true (conflicts[0].contains ("A/a1"));
        GLib.assert_true (conflicts[0] == conflict_records[0]);
        GLib.assert_true (GLib.FileInfo (fake_folder.local_path + conflicts[0]).is_directory ());
        GLib.assert_true (GLib.File.exists (fake_folder.local_path + conflicts[0] + "/bar"));

        // 3)
        GLib.assert_true (item_conflict (complete_spy, "B"));
        GLib.assert_true (fake_folder.current_local_state ().find ("B").size == 31);
        GLib.assert_true (conflicts[1].contains ("B"));
        GLib.assert_true (conflicts[1] == conflict_records[1]);
        GLib.assert_true (GLib.FileInfo (fake_folder.local_path + conflicts[1]).is_directory ());
        GLib.assert_true (GLib.File.exists (fake_folder.local_path + conflicts[1] + "/zzz"));

        // The contents of the conflict directories will only be uploaded after
        // another sync.
        GLib.assert_true (fake_folder.sync_engine.is_another_sync_needed () == ImmediateFollowUp);
        clean_up ();
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (item_successful (complete_spy, conflicts[0], CSync.SyncInstructions.NEW));
        GLib.assert_true (item_successful (complete_spy, conflicts[0] + "/bar", CSync.SyncInstructions.NEW));
        GLib.assert_true (item_successful (complete_spy, conflicts[1], CSync.SyncInstructions.NEW));
        GLib.assert_true (item_successful (complete_spy, conflicts[1] + "/zzz", CSync.SyncInstructions.NEW));
        GLib.assert_true (item_successful (complete_spy, conflicts[2], CSync.SyncInstructions.NEW));
        GLib.assert_true (item_successful (complete_spy, conflicts[2] + "/foo", CSync.SyncInstructions.NEW));
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }

} // class TestLocalDirectoryRemoteFileConflict

} // namespace Testing
} // namespace Occ
