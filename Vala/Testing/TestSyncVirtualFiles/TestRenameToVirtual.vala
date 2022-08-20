namespace Occ {
namespace Testing {

/***********************************************************
@class TestRenameToVirtual

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestRenameToVirtual : AbstractTestSyncVirtualFiles {

//    /***********************************************************
//    ***********************************************************/
//    private TestRenameToVirtual () {
//        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
//        set_up_vfs (fake_folder);
//        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
//        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

//        TestSyncVirtualFiles.clean_up_test_rename_to_virtual ();

//        // If a file is renamed to <name>.owncloud, it becomes virtual
//        fake_folder.local_modifier.rename ("A/a1", "A/a1" + DVSUFFIX);
//        // If a file is renamed to <random>.owncloud, the rename propagates but the
//        // file isn't made virtual the first sync run.
//        fake_folder.local_modifier.rename ("A/a2", "A/rand" + DVSUFFIX);
//        // dangling virtual files are removed
//        fake_folder.local_modifier.insert ("A/dangling" + DVSUFFIX, 1, ' ');
//        GLib.assert_true (fake_folder.sync_once ());

//        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
//        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX));
//        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX).size <= 1);
//        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
//        GLib.assert_true (item_instruction (complete_spy, "A/a1" + DVSUFFIX, CSync.SyncInstructions.SYNC));
//        GLib.assert_true (database_record (fake_folder, "A/a1" + DVSUFFIX).type == ItemType.VIRTUAL_FILE);
//        GLib.assert_true (!database_record (fake_folder, "A/a1").is_valid);

//        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a2"));
//        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a2" + DVSUFFIX));
//        GLib.assert_true (fake_folder.current_local_state ().find ("A/rand"));
//        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a2"));
//        GLib.assert_true (fake_folder.current_remote_state ().find ("A/rand"));
//        GLib.assert_true (item_instruction (complete_spy, "A/rand", CSync.SyncInstructions.RENAME));
//        GLib.assert_true (database_record (fake_folder, "A/rand").type == ItemType.FILE);

//        GLib.assert_true (!fake_folder.current_local_state ().find ("A/dangling" + DVSUFFIX));
//        TestSyncVirtualFiles.clean_up_test_rename_to_virtual ();
//    }


//    /***********************************************************
//    ***********************************************************/
//    private static void clean_up_test_rename_to_virtual (ItemCompletedSpy complete_spy) {
//        complete_spy = "";
//    }

} // class TestRenameToVirtual

} // namespace Testing
} // namespace Occ
