namespace Occ {
namespace Testing {

/***********************************************************
@class TestVirtualFileDownload

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestVirtualFileDownload : AbstractTestSyncXAttr {

    /***********************************************************
    ***********************************************************/
    private TestVirtualFileDownload () {
        //  FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        //  set_up_vfs (fake_folder);
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        //  clean_up_test_virtual_file_download ();

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

        //  xaverify_virtual (fake_folder, "A/a1");
        //  xaverify_virtual (fake_folder, "A/a2");
        //  xaverify_virtual (fake_folder, "A/a3");
        //  xaverify_virtual (fake_folder, "A/a4");
        //  xaverify_virtual (fake_folder, "A/a5");
        //  xaverify_virtual (fake_folder, "A/a6");
        //  xaverify_virtual (fake_folder, "A/a7");
        //  xaverify_virtual (fake_folder, "A/b1");
        //  xaverify_virtual (fake_folder, "A/b2");
        //  xaverify_virtual (fake_folder, "A/b3");
        //  xaverify_virtual (fake_folder, "A/b4");

        //  clean_up_test_virtual_file_download ();

        //  // Download by changing the database entry
        //  trigger_download (fake_folder, "A/a1");
        //  trigger_download (fake_folder, "A/a2");
        //  trigger_download (fake_folder, "A/a3");
        //  trigger_download (fake_folder, "A/a4");
        //  trigger_download (fake_folder, "A/a5");
        //  trigger_download (fake_folder, "A/a6");
        //  trigger_download (fake_folder, "A/a7");
        //  trigger_download (fake_folder, "A/b1");
        //  trigger_download (fake_folder, "A/b2");
        //  trigger_download (fake_folder, "A/b3");
        //  trigger_download (fake_folder, "A/b4");

        //  // Remote complications
        //  fake_folder.remote_modifier ().append_byte ("A/a2");
        //  fake_folder.remote_modifier ().remove ("A/a3");
        //  fake_folder.remote_modifier ().rename ("A/a4", "A/a4m");
        //  fake_folder.remote_modifier ().append_byte ("A/b2");
        //  fake_folder.remote_modifier ().remove ("A/b3");
        //  fake_folder.remote_modifier ().rename ("A/b4", "A/b4m");

        //  // Local complications
        //  fake_folder.local_modifier.remove ("A/a5");
        //  fake_folder.local_modifier.insert ("A/a5");
        //  fake_folder.local_modifier.remove ("A/a6");
        //  fake_folder.local_modifier.insert ("A/a6");

        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (item_instruction (complete_spy, "A/a1", CSync.SyncInstructions.SYNC));
        //  GLib.assert_true (complete_spy.find_item ("A/a1").type == ItemType.VIRTUAL_FILE_DOWNLOAD);
        //  GLib.assert_true (item_instruction (complete_spy, "A/a2", CSync.SyncInstructions.SYNC));
        //  GLib.assert_true (complete_spy.find_item ("A/a2").type == ItemType.VIRTUAL_FILE_DOWNLOAD);
        //  GLib.assert_true (item_instruction (complete_spy, "A/a3", CSync.SyncInstructions.REMOVE));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a4m", CSync.SyncInstructions.NEW));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a4", CSync.SyncInstructions.REMOVE));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a5", CSync.SyncInstructions.CONFLICT));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a6", CSync.SyncInstructions.CONFLICT));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a7", CSync.SyncInstructions.SYNC));
        //  GLib.assert_true (item_instruction (complete_spy, "A/b1", CSync.SyncInstructions.SYNC));
        //  GLib.assert_true (item_instruction (complete_spy, "A/b2", CSync.SyncInstructions.SYNC));
        //  GLib.assert_true (item_instruction (complete_spy, "A/b3", CSync.SyncInstructions.REMOVE));
        //  GLib.assert_true (item_instruction (complete_spy, "A/b4m", CSync.SyncInstructions.NEW));
        //  GLib.assert_true (item_instruction (complete_spy, "A/b4", CSync.SyncInstructions.REMOVE));

        //  xaverify_nonvirtual (fake_folder, "A/a1");
        //  xaverify_nonvirtual (fake_folder, "A/a2");
        //  cfverify_gone (fake_folder, "A/a3");
        //  cfverify_gone (fake_folder, "A/a4");
        //  xaverify_nonvirtual (fake_folder, "A/a4m");
        //  xaverify_nonvirtual (fake_folder, "A/a5");
        //  xaverify_nonvirtual (fake_folder, "A/a6");
        //  xaverify_nonvirtual (fake_folder, "A/a7");
        //  xaverify_nonvirtual (fake_folder, "A/b1");
        //  xaverify_nonvirtual (fake_folder, "A/b2");
        //  cfverify_gone (fake_folder, "A/b3");
        //  cfverify_gone (fake_folder, "A/b4");
        //  xaverify_nonvirtual (fake_folder, "A/b4m");

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
