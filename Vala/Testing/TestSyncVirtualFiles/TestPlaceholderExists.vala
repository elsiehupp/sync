namespace Occ {
namespace Testing {

/***********************************************************
@class TestPlaceholderExists

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestPlaceholderExists : AbstractTestSyncVirtualFiles {

    /***********************************************************
    ***********************************************************/
    private TestPlaceholderExists () {
        //  FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        //  fake_folder.remote_modifier ().insert ("A/a1" + DVSUFFIX, 111);
        //  fake_folder.remote_modifier ().insert ("A/hello" + DVSUFFIX, 222);
        //  GLib.assert_true (fake_folder.sync_once ());
        //  Common.AbstractVfs vfs = set_up_vfs (fake_folder);

        //  ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        //  TestSyncVirtualFiles.clean_up_test_place_holder_exist ();

        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  GLib.assert_true (item_instruction (complete_spy, "A/a1" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        //  GLib.assert_true (item_instruction (complete_spy, "A/hello" + DVSUFFIX, CSync.SyncInstructions.IGNORE));

        //  fake_folder.remote_modifier ().insert ("A/a2" + DVSUFFIX);
        //  fake_folder.remote_modifier ().insert ("A/hello", 12);
        //  fake_folder.local_modifier.insert ("A/igno" + DVSUFFIX, 123);
        //  TestSyncVirtualFiles.clean_up_test_place_holder_exist ();
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (item_instruction (complete_spy, "A/a1" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        //  GLib.assert_true (item_instruction (complete_spy, "A/igno" + DVSUFFIX, CSync.SyncInstructions.IGNORE));

        //  // verify that the files are still present
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/hello" + DVSUFFIX).size == 222);
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/hello" + DVSUFFIX) ==
        //      fake_folder.current_remote_state ().find ("A/hello" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/igno" + DVSUFFIX).size == 123);

        //  TestSyncVirtualFiles.clean_up_test_place_holder_exist ();
        //  // Dehydrate
        //  GLib.assert_true (vfs.set_pin_state ("", Common.ItemAvailability.ONLINE_ONLY));
        //  GLib.assert_true (!fake_folder.sync_once ());

        //  GLib.assert_true (item_instruction (complete_spy, "A/igno" + DVSUFFIX, CSync.SyncInstructions.IGNORE));
        //  // verify that the files are still present
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX).size == 111);
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/hello" + DVSUFFIX).size == 222);
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/hello" + DVSUFFIX) ==
        //      fake_folder.current_remote_state ().find ("A/hello" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a1") ==
        //      fake_folder.current_remote_state ().find ("A/a1"));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/igno" + DVSUFFIX).size == 123);

        //  // Now disable vfs and check that all files are still there
        //  TestSyncVirtualFiles.clean_up_test_place_holder_exist ();
        //  LibSync.SyncEngine.wipe_virtual_files (fake_folder.local_path, fake_folder.sync_journal (), vfs);
        //  fake_folder.switch_to_vfs ((Common.AbstractVfs)(new VfsOff ()));
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX).size == 111);
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/hello").size == 12);
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/hello" + DVSUFFIX).size == 222);
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/igno" + DVSUFFIX).size == 123);
    }


    /***********************************************************
    ***********************************************************/
    private static void clean_up_test_place_holder_exist (ItemCompletedSpy complete_spy) {
        //  complete_spy = "";
    }

} // class TestPlaceholderExists

} // namespace Testing
} // namespace Occ
