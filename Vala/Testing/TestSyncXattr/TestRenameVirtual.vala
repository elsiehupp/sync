namespace Occ {
namespace Testing {

/***********************************************************
@class TestRenameVirtual

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public abstract class TestRenameVirtual : AbstractTestSyncXAttr {

    /***********************************************************
    ***********************************************************/
    private TestRenameVirtual () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        clean_up_test_rename_virtual ();

        fake_folder.remote_modifier ().insert ("file1", 128, 'C');
        fake_folder.remote_modifier ().insert ("file2", 256, 'C');
        fake_folder.remote_modifier ().insert ("file3", 256, 'C');
        GLib.assert_true (fake_folder.sync_once ());

        xaverify_virtual (fake_folder, "file1");
        xaverify_virtual (fake_folder, "file2");
        xaverify_virtual (fake_folder, "file3");

        clean_up_test_rename_virtual ();

        fake_folder.local_modifier.rename ("file1", "renamed1");
        fake_folder.local_modifier.rename ("file2", "renamed2");
        trigger_download (fake_folder, "file2");
        trigger_download (fake_folder, "file3");
        GLib.assert_true (fake_folder.sync_once ());

        cfverify_gone (fake_folder, "file1");
        xaverify_virtual (fake_folder, "renamed1");

        GLib.assert_true (fake_folder.current_remote_state ().find ("renamed1"));
        GLib.assert_true (item_instruction (complete_spy, "renamed1", CSync.SyncInstructions.RENAME));

        // file2 has a conflict between the download request and the rename:
        // the rename wins, the download is ignored

        cfverify_gone (fake_folder, "file2");
        xaverify_virtual (fake_folder, "renamed2");

        GLib.assert_true (fake_folder.current_remote_state ().find ("renamed2"));
        GLib.assert_true (item_instruction (complete_spy, "renamed2", CSync.SyncInstructions.RENAME));

        GLib.assert_true (item_instruction (complete_spy, "file3", CSync.SyncInstructions.SYNC));
        xaverify_nonvirtual (fake_folder, "file3");
        clean_up_test_rename_virtual ();
    }


    /***********************************************************
    ***********************************************************/
    private static void clean_up_test_rename_virtual (ItemCompletedSpy complete_spy) {
        complete_spy.clear ();
    }

} // class TestRenameVirtual

} // namespace Testing
} // namespace Occ
