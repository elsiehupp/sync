namespace Occ {
namespace Testing {

/***********************************************************
@class TestVirtualFileDownload

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestVirtualFileDownload : AbstractTestSyncVirtualFiles {

    /***********************************************************
    ***********************************************************/
    private TestVirtualFileDownload () {
        //  FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        //  set_up_vfs (fake_folder);
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        //  TestSyncVirtualFiles.clean_up_test_virtual_file_download (complete_spy);

        //  // Create a virtual file for remote files
        //  fake_folder.remote_modifier ().mkdir ("A");
        //  fake_folder.remote_modifier ().insert ("A/a1");
        //  fake_folder.remote_modifier ().insert ("A/a2");
        //  fake_folder.remote_modifier ().insert ("A/a3");
        //  fake_folder.remote_modifier ().insert ("A/a4");
        //  fake_folder.remote_modifier ().insert ("A/a5");
        //  fake_folder.remote_modifier ().insert ("A/a6");
        //  fake_folder.remote_modifier ().insert ("A/a7");
        //  fake_folder.remote_modifier ().insert ("A/b1");
        //  fake_folder.remote_modifier ().insert ("A/b2");
        //  fake_folder.remote_modifier ().insert ("A/b3");
        //  fake_folder.remote_modifier ().insert ("A/b4");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a2" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a3" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a4" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a5" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a6" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a7" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/b1" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/b2" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/b3" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/b4" + DVSUFFIX));
        //  TestSyncVirtualFiles.clean_up_test_virtual_file_download (complete_spy);

        //  // Download by changing the database entry
        //  trigger_download (fake_folder, "A/a1");
        //  trigger_download (fake_folder, "A/a2");
        //  trigger_download (fake_folder, "A/a3");
        //  trigger_download (fake_folder, "A/a4");
        //  trigger_download (fake_folder, "A/a5");
        //  trigger_download (fake_folder, "A/a6");
        //  trigger_download (fake_folder, "A/a7");
        //  // Download by renaming locally
        //  fake_folder.local_modifier.rename ("A/b1" + DVSUFFIX, "A/b1");
        //  fake_folder.local_modifier.rename ("A/b2" + DVSUFFIX, "A/b2");
        //  fake_folder.local_modifier.rename ("A/b3" + DVSUFFIX, "A/b3");
        //  fake_folder.local_modifier.rename ("A/b4" + DVSUFFIX, "A/b4");
        //  // Remote complications
        //  fake_folder.remote_modifier ().append_byte ("A/a2");
        //  fake_folder.remote_modifier ().remove ("A/a3");
        //  fake_folder.remote_modifier ().rename ("A/a4", "A/a4m");
        //  fake_folder.remote_modifier ().append_byte ("A/b2");
        //  fake_folder.remote_modifier ().remove ("A/b3");
        //  fake_folder.remote_modifier ().rename ("A/b4", "A/b4m");
        //  // Local complications
        //  fake_folder.local_modifier.insert ("A/a5");
        //  fake_folder.local_modifier.insert ("A/a6");
        //  fake_folder.local_modifier.remove ("A/a6" + DVSUFFIX);
        //  fake_folder.local_modifier.rename ("A/a7" + DVSUFFIX, "A/a7");

        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (item_instruction (complete_spy, "A/a1", CSync.SyncInstructions.SYNC));
        //  GLib.assert_true (complete_spy.find_item ("A/a1").type == ItemType.VIRTUAL_FILE_DOWNLOAD);
        //  GLib.assert_true (item_instruction (complete_spy, "A/a1" + DVSUFFIX, CSync.SyncInstructions.NONE));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a2", CSync.SyncInstructions.SYNC));
        //  GLib.assert_true (complete_spy.find_item ("A/a2").type == ItemType.VIRTUAL_FILE_DOWNLOAD);
        //  GLib.assert_true (item_instruction (complete_spy, "A/a2" + DVSUFFIX, CSync.SyncInstructions.NONE));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a3" + DVSUFFIX, CSync.SyncInstructions.REMOVE));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a4m", CSync.SyncInstructions.NEW));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a4" + DVSUFFIX, CSync.SyncInstructions.REMOVE));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a5", CSync.SyncInstructions.CONFLICT));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a5" + DVSUFFIX, CSync.SyncInstructions.REMOVE));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a6", CSync.SyncInstructions.CONFLICT));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a7", CSync.SyncInstructions.SYNC));
        //  GLib.assert_true (item_instruction (complete_spy, "A/b1", CSync.SyncInstructions.SYNC));
        //  GLib.assert_true (item_instruction (complete_spy, "A/b2", CSync.SyncInstructions.SYNC));
        //  GLib.assert_true (item_instruction (complete_spy, "A/b3", CSync.SyncInstructions.REMOVE));
        //  GLib.assert_true (item_instruction (complete_spy, "A/b4m" + DVSUFFIX, CSync.SyncInstructions.NEW));
        //  GLib.assert_true (item_instruction (complete_spy, "A/b4", CSync.SyncInstructions.REMOVE));
        //  GLib.assert_true (database_record (fake_folder, "A/a1").type == ItemType.FILE);
        //  GLib.assert_true (!database_record (fake_folder, "A/a1" + DVSUFFIX).is_valid);
        //  GLib.assert_true (database_record (fake_folder, "A/a2").type == ItemType.FILE);
        //  GLib.assert_true (!database_record (fake_folder, "A/a3").is_valid);
        //  GLib.assert_true (database_record (fake_folder, "A/a4m").type == ItemType.FILE);
        //  GLib.assert_true (database_record (fake_folder, "A/a5").type == ItemType.FILE);
        //  GLib.assert_true (database_record (fake_folder, "A/a6").type == ItemType.FILE);
        //  GLib.assert_true (database_record (fake_folder, "A/a7").type == ItemType.FILE);
        //  GLib.assert_true (database_record (fake_folder, "A/b1").type == ItemType.FILE);
        //  GLib.assert_true (!database_record (fake_folder, "A/b1" + DVSUFFIX).is_valid);
        //  GLib.assert_true (database_record (fake_folder, "A/b2").type == ItemType.FILE);
        //  GLib.assert_true (!database_record (fake_folder, "A/b3").is_valid);
        //  GLib.assert_true (database_record (fake_folder, "A/b4m" + DVSUFFIX).type == ItemType.VIRTUAL_FILE);
        //  GLib.assert_true (!database_record (fake_folder, "A/a1" + DVSUFFIX).is_valid);
        //  GLib.assert_true (!database_record (fake_folder, "A/a2" + DVSUFFIX).is_valid);
        //  GLib.assert_true (!database_record (fake_folder, "A/a3" + DVSUFFIX).is_valid);
        //  GLib.assert_true (!database_record (fake_folder, "A/a4" + DVSUFFIX).is_valid);
        //  GLib.assert_true (!database_record (fake_folder, "A/a5" + DVSUFFIX).is_valid);
        //  GLib.assert_true (!database_record (fake_folder, "A/a6" + DVSUFFIX).is_valid);
        //  GLib.assert_true (!database_record (fake_folder, "A/a7" + DVSUFFIX).is_valid);
        //  GLib.assert_true (!database_record (fake_folder, "A/b1" + DVSUFFIX).is_valid);
        //  GLib.assert_true (!database_record (fake_folder, "A/b2" + DVSUFFIX).is_valid);
        //  GLib.assert_true (!database_record (fake_folder, "A/b3" + DVSUFFIX).is_valid);
        //  GLib.assert_true (!database_record (fake_folder, "A/b4" + DVSUFFIX).is_valid);

        //  trigger_download (fake_folder, "A/b4m");
        //  GLib.assert_true (fake_folder.sync_once ());

        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private static void clean_up_test_virtual_file_download (ItemCompletedSpy complete_spy) {
        //  complete_spy = "";
    }

} // class TestVirtualFileDownload

} // namespace Testing
} // namespace Occ
