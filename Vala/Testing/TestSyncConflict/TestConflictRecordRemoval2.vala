/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestConflictRecordRemoval2 : AbstractTestSyncConflict {

    /***********************************************************
    Same test, but with upload_conflict_files == false
    ***********************************************************/
    private TestConflictRecordRemoval2 () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.account.set_capabilities ({ { "upload_conflict_files", false } });
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Create two conflicts
        fake_folder.local_modifier.append_byte ("A/a1");
        fake_folder.local_modifier.append_byte ("A/a1");
        fake_folder.remote_modifier ().append_byte ("A/a1");
        fake_folder.local_modifier.append_byte ("A/a2");
        fake_folder.local_modifier.append_byte ("A/a2");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());

        var conflicts = find_conflicts (fake_folder.current_local_state ().children["A"]);
        string a1conflict;
        string a2conflict;
        foreach (var conflict in conflicts) {
            if (conflict.contains ("a1")) {
                a1conflict = conflict;
            }
            if (conflict.contains ("a2")) {
                a2conflict = conflict;
            }
        }

        // A nothing-to-sync keeps them alive
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.sync_journal ().conflict_record (a1conflict).is_valid);
        GLib.assert_true (fake_folder.sync_journal ().conflict_record (a2conflict).is_valid);

        // When the file is removed, the record is removed too
        fake_folder.local_modifier.remove (a2conflict);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.sync_journal ().conflict_record (a1conflict).is_valid);
        GLib.assert_true (!fake_folder.sync_journal ().conflict_record (a2conflict).is_valid);
    }

} // class TestConflictRecordRemoval2

} // namespace Testing
} // namespace Occ
