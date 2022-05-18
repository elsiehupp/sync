namespace Occ {
namespace Testing {

/***********************************************************
@class TestVirtualFileConflict

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestVirtualFileConflict : AbstractTestSyncVirtualFiles {

    /***********************************************************
    ***********************************************************/
    private static TestVirtualFileConflict () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        TestSyncVirtualFiles.clean_up_test_virtual_file_conflict ();

        // Create a virtual file for a new remote file
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/a1", 64);
        fake_folder.remote_modifier ().insert ("A/a2", 64);
        fake_folder.remote_modifier ().mkdir ("B");
        fake_folder.remote_modifier ().insert ("B/b1", 64);
        fake_folder.remote_modifier ().insert ("B/b2", 64);
        fake_folder.remote_modifier ().mkdir ("C");
        fake_folder.remote_modifier ().insert ("C/c1", 64);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("B/b2" + DVSUFFIX));
        TestSyncVirtualFiles.clean_up_test_virtual_file_conflict ();

        // A : the correct file and a conflicting file are added, virtual files stay
        // B : same setup, but the virtual files are deleted by the user
        // C : user adds a directory* locally
        fake_folder.local_modifier.insert ("A/a1", 64);
        fake_folder.local_modifier.insert ("A/a2", 30);
        fake_folder.local_modifier.insert ("B/b1", 64);
        fake_folder.local_modifier.insert ("B/b2", 30);
        fake_folder.local_modifier.remove ("B/b1" + DVSUFFIX);
        fake_folder.local_modifier.remove ("B/b2" + DVSUFFIX);
        fake_folder.local_modifier.mkdir ("C/c1");
        fake_folder.local_modifier.insert ("C/c1/foo");
        GLib.assert_true (fake_folder.sync_once ());

        // Everything is CONFLICT since mtimes are different even for a1/b1
        GLib.assert_true (item_instruction (complete_spy, "A/a1", CSync.SyncInstructions.CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "A/a2", CSync.SyncInstructions.CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "B/b1", CSync.SyncInstructions.CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "B/b2", CSync.SyncInstructions.CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "C/c1", CSync.SyncInstructions.CONFLICT));

        // no virtual file files should remain
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a2" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/b1" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/b2" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("C/c1" + DVSUFFIX));

        // conflict files should exist
        GLib.assert_true (fake_folder.sync_journal ().conflict_record_paths ().size () == 3);

        // nothing should have the virtual file tag
        GLib.assert_true (database_record (fake_folder, "A/a1").type == ItemType.FILE);
        GLib.assert_true (database_record (fake_folder, "A/a2").type == ItemType.FILE);
        GLib.assert_true (database_record (fake_folder, "B/b1").type == ItemType.FILE);
        GLib.assert_true (database_record (fake_folder, "B/b2").type == ItemType.FILE);
        GLib.assert_true (database_record (fake_folder, "C/c1").type == ItemType.FILE);
        GLib.assert_true (!database_record (fake_folder, "A/a1" + DVSUFFIX).is_valid);
        GLib.assert_true (!database_record (fake_folder, "A/a2" + DVSUFFIX).is_valid);
        GLib.assert_true (!database_record (fake_folder, "B/b1" + DVSUFFIX).is_valid);
        GLib.assert_true (!database_record (fake_folder, "B/b2" + DVSUFFIX).is_valid);
        GLib.assert_true (!database_record (fake_folder, "C/c1" + DVSUFFIX).is_valid);

        TestSyncVirtualFiles.clean_up_test_virtual_file_conflict ();
    }


    /***********************************************************
    ***********************************************************/
    private static void clean_up_test_virtual_file_conflict (ItemCompletedSpy complete_spy) {
        complete_spy = "";
    }

} // class TestVirtualFileConflict

} // namespace Testing
} // namespace Occ
