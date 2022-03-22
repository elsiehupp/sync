namespace Occ {
namespace Testing {

/***********************************************************
@class TestWithNormalSync

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestWithNormalSync : AbstractTestSyncVirtualFiles {

    /***********************************************************
    ***********************************************************/
    private TestWithNormalSync () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        TestSyncVirtualFiles.clean_up_test_with_normal_sync (complete_spy);

        // No effect sync
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        TestSyncVirtualFiles.clean_up_test_with_normal_sync (complete_spy);

        // Existing files are propagated just fine in both directions
        fake_folder.local_modifier.append_byte ("A/a1");
        fake_folder.local_modifier.insert ("A/a3");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        TestSyncVirtualFiles.clean_up_test_with_normal_sync (complete_spy);

        // New files on the remote create virtual files
        fake_folder.remote_modifier ().insert ("A/new");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/new"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/new" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/new"));
        GLib.assert_true (item_instruction (complete_spy, "A/new" + DVSUFFIX, CSync.SyncInstructions.NEW));
        GLib.assert_true (database_record (fake_folder, "A/new" + DVSUFFIX).type == ItemType.VIRTUAL_FILE);
        TestSyncVirtualFiles.clean_up_test_with_normal_sync (complete_spy);
    }


    private static void clean_up_test_with_normal_sync (ItemCompletedSpy complete_spy) {
        complete_spy == "";
    }

} // class TestWithNormalSync

} // namespace Testing
} // namespace Occ
