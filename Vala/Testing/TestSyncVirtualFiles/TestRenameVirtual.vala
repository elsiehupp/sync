namespace Occ {
namespace Testing {

/***********************************************************
@class TestRenameVirtual

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestRenameVirtual : AbstractTestSyncVirtualFiles {

    /***********************************************************
    ***********************************************************/
    private TestRenameVirtual () {
        //  FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        //  set_up_vfs (fake_folder);
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        //  TestSyncVirtualFiles.clean_up_test_rename_virtual (complete_spy);

        //  fake_folder.remote_modifier ().insert ("file1", 128, 'C');
        //  fake_folder.remote_modifier ().insert ("file2", 256, 'C');
        //  fake_folder.remote_modifier ().insert ("file3", 256, 'C');
        //  GLib.assert_true (fake_folder.sync_once ());

        //  GLib.assert_true (fake_folder.current_local_state ().find ("file1" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("file2" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("file3" + DVSUFFIX));
        //  TestSyncVirtualFiles.clean_up_test_rename_virtual (complete_spy);

        //  fake_folder.local_modifier.rename ("file1" + DVSUFFIX, "renamed1" + DVSUFFIX);
        //  fake_folder.local_modifier.rename ("file2" + DVSUFFIX, "renamed2" + DVSUFFIX);
        //  trigger_download (fake_folder, "file2");
        //  trigger_download (fake_folder, "file3");
        //  GLib.assert_true (fake_folder.sync_once ());

        //  GLib.assert_true (!fake_folder.current_local_state ().find ("file1" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("renamed1" + DVSUFFIX));
        //  GLib.assert_true (!fake_folder.current_remote_state ().find ("file1"));
        //  GLib.assert_true (fake_folder.current_remote_state ().find ("renamed1"));
        //  GLib.assert_true (item_instruction (complete_spy, "renamed1" + DVSUFFIX, CSync.SyncInstructions.RENAME));
        //  GLib.assert_true (database_record (fake_folder, "renamed1" + DVSUFFIX).is_valid);

        //  // file2 has a conflict between the download request and the rename:
        //  // the rename wins, the download is ignored
        //  GLib.assert_true (!fake_folder.current_local_state ().find ("file2"));
        //  GLib.assert_true (!fake_folder.current_local_state ().find ("file2" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("renamed2" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_remote_state ().find ("renamed2"));
        //  GLib.assert_true (item_instruction (complete_spy, "renamed2" + DVSUFFIX, CSync.SyncInstructions.RENAME));
        //  GLib.assert_true (database_record (fake_folder, "renamed2" + DVSUFFIX).type == ItemType.VIRTUAL_FILE);

        //  GLib.assert_true (item_instruction (complete_spy, "file3", CSync.SyncInstructions.SYNC));
        //  GLib.assert_true (database_record (fake_folder, "file3").type == ItemType.FILE);
        //  TestSyncVirtualFiles.clean_up_test_rename_virtual (complete_spy);

        //  // Test rename while adding/removing vfs suffix
        //  fake_folder.local_modifier.rename ("renamed1" + DVSUFFIX, "R1");
        //  // Contents of file2 could also change at the same time...
        //  fake_folder.local_modifier.rename ("file3", "R3" + DVSUFFIX);
        //  GLib.assert_true (fake_folder.sync_once ());
        //  TestSyncVirtualFiles.clean_up_test_rename_virtual (complete_spy);
    }


    /***********************************************************
    ***********************************************************/
    private static void clean_up_test_rename_virtual (ItemCompletedSpy complete_spy ) {
        //  complete_spy = "";
    }

} // class TestRenameVirtual

} // namespace Testing
} // namespace Occ
