namespace Occ {
namespace Testing {

/***********************************************************
@class TestRenameVirtual2

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestRenameVirtual2 : AbstractTestSyncXAttr {

    /***********************************************************
    ***********************************************************/
    private TestRenameVirtual2 () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        clean_up_test_rename_virtual2 ();

        fake_folder.remote_modifier ().insert ("case3", 128, 'C');
        fake_folder.remote_modifier ().insert ("case4", 256, 'C');
        GLib.assert_true (fake_folder.sync_once ());

        trigger_download (fake_folder, "case4");
        GLib.assert_true (fake_folder.sync_once ());

        xaverify_virtual (fake_folder, "case3");
        xaverify_nonvirtual (fake_folder, "case4");

        clean_up_test_rename_virtual2 ();

        // Case 1 : non-virtual, foo . bar (tested elsewhere)
        // Case 2 : virtual, foo . bar (tested elsewhere)

        // Case 3 : virtual, foo.oc . bar.oc (database hydrate)
        fake_folder.local_modifier.rename ("case3", "case3-rename");
        trigger_download (fake_folder, "case3");

        // Case 4 : non-virtual foo . bar (database dehydrate)
        fake_folder.local_modifier.rename ("case4", "case4-rename");
        mark_for_dehydration (fake_folder, "case4");

        GLib.assert_true (fake_folder.sync_once ());

        // Case 3 : the rename went though, hydration is forgotten
        cfverify_gone (fake_folder, "case3");
        xaverify_virtual (fake_folder, "case3-rename");
        GLib.assert_true (!fake_folder.current_remote_state ().find ("case3"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("case3-rename"));
        GLib.assert_true (item_instruction (complete_spy, "case3-rename", CSync.SyncInstructions.RENAME));

        // Case 4 : the rename went though, dehydration is forgotten
        cfverify_gone (fake_folder, "case4");
        xaverify_nonvirtual (fake_folder, "case4-rename");
        GLib.assert_true (!fake_folder.current_remote_state ().find ("case4"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("case4-rename"));
        GLib.assert_true (item_instruction (complete_spy, "case4-rename", CSync.SyncInstructions.RENAME));
    }


    /***********************************************************
    ***********************************************************/
    private static void clean_up_test_rename_virtual2 (ItemCompletedSpy complete_spy) {
        complete_spy.clear ();
    }

} // class TestRenameVirtual2

} // namespace Testing
} // namespace Occ
