namespace Occ {
namespace Testing {

/***********************************************************
@class TestSuffixFilesWhileLocalHydrated

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestSuffixFilesWhileLocalHydrated : AbstractTestSyncVirtualFiles {

    /***********************************************************
    Check what happens if vfs-suffixed files exist on the server
    or locally while the file is hydrated.
    ***********************************************************/
    private TestSuffixFilesWhileLocalHydrated () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());

        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        TestSyncVirtualFiles.clean_up_test_suffix_files_while_local_hydrated ();

        // suffixed files are happily synced with Vfs.Off
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/test1" + DVSUFFIX, 10, 'A');
        fake_folder.remote_modifier ().insert ("A/test2" + DVSUFFIX, 20, 'A');
        fake_folder.remote_modifier ().insert ("A/file1" + DVSUFFIX, 30, 'A');
        fake_folder.remote_modifier ().insert ("A/file2", 40, 'A');
        fake_folder.remote_modifier ().insert ("A/file2" + DVSUFFIX, 50, 'A');
        fake_folder.remote_modifier ().insert ("A/file3", 60, 'A');
        fake_folder.remote_modifier ().insert ("A/file3" + DVSUFFIX, 70, 'A');
        fake_folder.remote_modifier ().insert ("A/file3" + DVSUFFIX + DVSUFFIX, 80, 'A');
        fake_folder.remote_modifier ().insert ("A/remote1" + DVSUFFIX, 30, 'A');
        fake_folder.remote_modifier ().insert ("A/remote2", 40, 'A');
        fake_folder.remote_modifier ().insert ("A/remote2" + DVSUFFIX, 50, 'A');
        fake_folder.remote_modifier ().insert ("A/remote3", 60, 'A');
        fake_folder.remote_modifier ().insert ("A/remote3" + DVSUFFIX, 70, 'A');
        fake_folder.remote_modifier ().insert ("A/remote3" + DVSUFFIX + DVSUFFIX, 80, 'A');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        TestSyncVirtualFiles.clean_up_test_suffix_files_while_local_hydrated ();

        // Enable suffix vfs
        set_up_vfs (fake_folder);

        // A simple sync removes the files that are now ignored (?)
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/file1" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file2" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" + DVSUFFIX + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        TestSyncVirtualFiles.clean_up_test_suffix_files_while_local_hydrated ();

        // Add a real file where the suffixed file exists
        fake_folder.local_modifier.insert ("A/test1", 11, 'A');
        fake_folder.remote_modifier ().insert ("A/test2", 21, 'A');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/test1", CSync.SyncInstructions.NEW));
        // this isn't fully good since some code requires size == 1 for placeholders
        // (when renaming placeholder to real file). But the alternative would mean
        // special casing this to allow CONFLICT at virtual file creation level. Ew.
        GLib.assert_true (item_instruction (complete_spy, "A/test2" + DVSUFFIX, CSync.SyncInstructions.UPDATE_METADATA));
        TestSyncVirtualFiles.clean_up_test_suffix_files_while_local_hydrated ();

        // Local changes of suffixed file do nothing
        fake_folder.local_modifier.set_contents ("A/file1" + DVSUFFIX, 'B');
        fake_folder.local_modifier.set_contents ("A/file2" + DVSUFFIX, 'B');
        fake_folder.local_modifier.set_contents ("A/file3" + DVSUFFIX, 'B');
        fake_folder.local_modifier.set_contents ("A/file3" + DVSUFFIX + DVSUFFIX, 'B');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/file1" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file2" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" + DVSUFFIX + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        TestSyncVirtualFiles.clean_up_test_suffix_files_while_local_hydrated ();

        // Remote changes don't do anything either
        fake_folder.remote_modifier ().set_contents ("A/file1" + DVSUFFIX, 'C');
        fake_folder.remote_modifier ().set_contents ("A/file2" + DVSUFFIX, 'C');
        fake_folder.remote_modifier ().set_contents ("A/file3" + DVSUFFIX, 'C');
        fake_folder.remote_modifier ().set_contents ("A/file3" + DVSUFFIX + DVSUFFIX, 'C');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/file1" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file2" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" + DVSUFFIX + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        TestSyncVirtualFiles.clean_up_test_suffix_files_while_local_hydrated ();

        // Local removal : when not querying server
        fake_folder.local_modifier.remove ("A/file1" + DVSUFFIX);
        fake_folder.local_modifier.remove ("A/file2" + DVSUFFIX);
        fake_folder.local_modifier.remove ("A/file3" + DVSUFFIX);
        fake_folder.local_modifier.remove ("A/file3" + DVSUFFIX + DVSUFFIX);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (complete_spy.find_item ("A/file1" + DVSUFFIX) == "");
        GLib.assert_true (complete_spy.find_item ("A/file2" + DVSUFFIX) == "");
        GLib.assert_true (complete_spy.find_item ("A/file3" + DVSUFFIX) == "");
        GLib.assert_true (complete_spy.find_item ("A/file3" + DVSUFFIX + DVSUFFIX) == "");
        TestSyncVirtualFiles.clean_up_test_suffix_files_while_local_hydrated ();

        // Local removal : when querying server
        fake_folder.remote_modifier ().set_contents ("A/file1" + DVSUFFIX, 'D');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/file1" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file2" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" + DVSUFFIX + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        TestSyncVirtualFiles.clean_up_test_suffix_files_while_local_hydrated ();

        // Remote removal
        fake_folder.remote_modifier ().remove ("A/remote1" + DVSUFFIX);
        fake_folder.remote_modifier ().remove ("A/remote2" + DVSUFFIX);
        fake_folder.remote_modifier ().remove ("A/remote3" + DVSUFFIX);
        fake_folder.remote_modifier ().remove ("A/remote3" + DVSUFFIX + DVSUFFIX);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/remote1" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/remote2" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/remote3" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/remote3" + DVSUFFIX + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        TestSyncVirtualFiles.clean_up_test_suffix_files_while_local_hydrated ();

        // New files with a suffix aren't propagated downwards in the first place
        fake_folder.remote_modifier ().insert ("A/new1" + DVSUFFIX);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/new1" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/new1" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/new1"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/new1" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/new1" + DVSUFFIX + DVSUFFIX));
        TestSyncVirtualFiles.clean_up_test_suffix_files_while_local_hydrated ();
    }


    /***********************************************************
    ***********************************************************/
    private static void clean_up_test_suffix_files_while_local_hydrated (ItemCompletedSpy complete_spy) {
        complete_spy.clear ();
    }

} // class TestSuffixFilesWhileLocalHydrated

} // namespace Testing
} // namespace Occ
