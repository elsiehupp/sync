namespace Occ {
namespace Testing {

/***********************************************************
@class TestWithNormalSync

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestWithNormalSync : AbstractTestSyncXAttr {

    /***********************************************************
    ***********************************************************/
    private TestWithNormalSync () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        clean_up_test_with_normal_sync ();

        // No effect sync
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        clean_up_test_with_normal_sync ();

        // Existing files are propagated just fine in both directions
        fake_folder.local_modifier.append_byte ("A/a1");
        fake_folder.local_modifier.insert ("A/a3");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        clean_up_test_with_normal_sync ();

        // New files on the remote create virtual files
        fake_folder.remote_modifier ().insert ("A/new", 42);
        GLib.assert_true (fake_folder.sync_once ());
        xaverify_virtual (fake_folder, "A/new");
        GLib.assert_true (database_record (fake_folder, "A/new").file_size == 42);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/new"));
        GLib.assert_true (item_instruction (complete_spy, "A/new", CSync.SyncInstructions.NEW));
        clean_up_test_with_normal_sync ();
    }


    /***********************************************************
    ***********************************************************/
    private static clean_up_test_with_normal_sync () {
        complete_spy == "";
    }

} // class TestWithNormalSync

} // namespace Testing
} // namespace Occ
