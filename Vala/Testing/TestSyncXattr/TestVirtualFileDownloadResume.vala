namespace Occ {
namespace Testing {

/***********************************************************
@class TestVirtualFileDownloadResume

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestVirtualFileDownloadResume : AbstractTestSyncXAttr {

    /***********************************************************
    ***********************************************************/
    private TestVirtualFileDownloadResume () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        clean_up_test_virtual_file_download_resume ();

        // Create a virtual file for remote files
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/a1");
        GLib.assert_true (fake_folder.sync_once ());
        xaverify_virtual (fake_folder, "A/a1");
        clean_up_test_virtual_file_download_resume ();

        // Download by changing the database entry
        trigger_download (fake_folder, "A/a1");
        fake_folder.server_error_paths ().append ("A/a1", 500);
        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/a1", CSync.SyncInstructions.SYNC));
        GLib.assert_true (xattr.has_nextcloud_placeholder_attributes (fake_folder.local_path + "A/a1"));
        GLib.assert_true (new FileInfo (fake_folder.local_path + "A/a1").exists ());
        GLib.assert_true (database_record (fake_folder, "A/a1").type == ItemType.VIRTUAL_FILE_DOWNLOAD);
        clean_up_test_virtual_file_download_resume ();

        fake_folder.server_error_paths () = "";
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/a1", CSync.SyncInstructions.SYNC));
        xaverify_nonvirtual (fake_folder, "A/a1");
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private static void clean_up_test_virtual_file_download_resume (FakeFolder fake_folder, ItemCompletedSpy complete_spy) {
        complete_spy = "";
        fake_folder.sync_journal ().wipe_error_blocklist ();
    }

} // class TestVirtualFileDownloadResume

} // namespace Testing
} // namespace Occ
