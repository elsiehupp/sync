namespace Occ {
namespace Testing {

/***********************************************************
@class TestExtraFilesWhileLocalHydrated

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestExtraFilesWhileLocalHydrated : AbstractTestSyncVirtualFiles {

    /***********************************************************
    Check what happens if vfs-suffixed files exist on the server
    or in the database.
    ***********************************************************/
    private TestExtraFilesWhileLocalHydrated () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);

        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        TestSyncVirtualFiles.clean_up_test_extra_files_local_dehydrated ();

        // create a bunch of local virtual files, in some instances
        // ignore remote files
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/file1", 30, 'A');
        fake_folder.remote_modifier ().insert ("A/file2", 40, 'A');
        fake_folder.remote_modifier ().insert ("A/file3", 60, 'A');
        fake_folder.remote_modifier ().insert ("A/file3" + DVSUFFIX, 70, 'A');
        fake_folder.remote_modifier ().insert ("A/file4", 80, 'A');
        fake_folder.remote_modifier ().insert ("A/file4" + DVSUFFIX, 90, 'A');
        fake_folder.remote_modifier ().insert ("A/file4" + DVSUFFIX + DVSUFFIX, 100, 'A');
        fake_folder.remote_modifier ().insert ("A/file5", 110, 'A');
        fake_folder.remote_modifier ().insert ("A/file6", 120, 'A');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/file1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/file1" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/file2"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/file2" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/file3"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/file3" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/file4"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/file4" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/file4" + DVSUFFIX + DVSUFFIX));
        GLib.assert_true (item_instruction (complete_spy, "A/file1" + DVSUFFIX, CSync.SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "A/file2" + DVSUFFIX, CSync.SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file4" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file4" + DVSUFFIX + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        TestSyncVirtualFiles.clean_up_test_extra_files_local_dehydrated ();

        // Create odd extra files locally and remotely
        fake_folder.local_modifier.insert ("A/file1", 10, 'A');
        fake_folder.local_modifier.insert ("A/file2" + DVSUFFIX + DVSUFFIX, 10, 'A');
        fake_folder.remote_modifier ().insert ("A/file5" + DVSUFFIX, 10, 'A');
        fake_folder.local_modifier.insert ("A/file6", 10, 'A');
        fake_folder.remote_modifier ().insert ("A/file6" + DVSUFFIX, 10, 'A');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/file1", CSync.SyncInstructions.CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "A/file1" + DVSUFFIX, CSync.SyncInstructions.REMOVE)); // it's now a pointless real virtual file
        GLib.assert_true (item_instruction (complete_spy, "A/file2" + DVSUFFIX + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file5" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file6", CSync.SyncInstructions.CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "A/file6" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        TestSyncVirtualFiles.clean_up_test_extra_files_local_dehydrated ();
    }


    /***********************************************************
    ***********************************************************/
    private static void clean_up_test_extra_files_local_dehydrated (ItemCompletedSpy complete_spy) {
        complete_spy.clear ();
    }

} // class TestExtraFilesWhileLocalHydrated

} // namespace Testing
} // namespace Occ
