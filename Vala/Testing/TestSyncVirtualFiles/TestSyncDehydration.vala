namespace Occ {
namespace Testing {

/***********************************************************
@class TestSyncDehydration

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestSyncDehydration : AbstractTestSyncVirtualFiles {

    //  /***********************************************************
    //  Dehydration via sync works
    //  ***********************************************************/
    //  private TestSyncDehydration () {
    //      FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
    //      set_up_vfs (fake_folder);

    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

    //      ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

    //      TestSyncVirtualFiles.clean_up_test_sync_dehydration (complete_spy);

    //      //  
    //      // Mark for dehydration and check
    //      //  

    //      mark_for_dehydration (fake_folder, "A/a1");

    //      mark_for_dehydration (fake_folder, "A/a2");
    //      fake_folder.remote_modifier ().append_byte ("A/a2");
    //      // expect : normal dehydration

    //      mark_for_dehydration (fake_folder, "B/b1");
    //      fake_folder.remote_modifier ().remove ("B/b1");
    //      // expect : local removal

    //      mark_for_dehydration (fake_folder, "B/b2");
    //      fake_folder.remote_modifier ().rename ("B/b2", "B/b3");
    //      // expect : B/b2 is gone, B/b3 is NEW placeholder

    //      mark_for_dehydration (fake_folder, "C/c1");
    //      fake_folder.local_modifier.append_byte ("C/c1");
    //      // expect : no dehydration, upload of c1

    //      mark_for_dehydration (fake_folder, "C/c2");
    //      fake_folder.local_modifier.append_byte ("C/c2");
    //      fake_folder.remote_modifier ().append_byte ("C/c2");
    //      fake_folder.remote_modifier ().append_byte ("C/c2");
    //      // expect : no dehydration, conflict

    //      GLib.assert_true (fake_folder.sync_once ());

    //      GLib.assert_true (is_dehydrated ("A/a1"));
    //      GLib.assert_true (has_dehydrated_database_entries ("A/a1"));
    //      GLib.assert_true (item_instruction (complete_spy, "A/a1" + DVSUFFIX, CSync.SyncInstructions.SYNC));
    //      GLib.assert_true (complete_spy.find_item ("A/a1" + DVSUFFIX).type == ItemType.VIRTUAL_FILE_DEHYDRATION);
    //      GLib.assert_true (complete_spy.find_item ("A/a1" + DVSUFFIX).file == "A/a1");
    //      GLib.assert_true (complete_spy.find_item ("A/a1" + DVSUFFIX).rename_target == "A/a1" + DVSUFFIX);
    //      GLib.assert_true (is_dehydrated ("A/a2"));
    //      GLib.assert_true (has_dehydrated_database_entries ("A/a2"));
    //      GLib.assert_true (item_instruction (complete_spy, "A/a2" + DVSUFFIX, CSync.SyncInstructions.SYNC));
    //      GLib.assert_true (complete_spy.find_item ("A/a2" + DVSUFFIX).type == ItemType.VIRTUAL_FILE_DEHYDRATION);

    //      GLib.assert_true (!fake_folder.current_local_state ().find ("B/b1"));
    //      GLib.assert_true (!fake_folder.current_remote_state ().find ("B/b1"));
    //      GLib.assert_true (item_instruction (complete_spy, "B/b1", CSync.SyncInstructions.REMOVE));

    //      GLib.assert_true (!fake_folder.current_local_state ().find ("B/b2"));
    //      GLib.assert_true (!fake_folder.current_remote_state ().find ("B/b2"));
    //      GLib.assert_true (is_dehydrated ("B/b3"));
    //      GLib.assert_true (has_dehydrated_database_entries ("B/b3"));
    //      GLib.assert_true (item_instruction (complete_spy, "B/b2", CSync.SyncInstructions.REMOVE));
    //      GLib.assert_true (item_instruction (complete_spy, "B/b3" + DVSUFFIX, CSync.SyncInstructions.NEW));

    //      GLib.assert_true (fake_folder.current_remote_state ().find ("C/c1").size == 25);
    //      GLib.assert_true (item_instruction (complete_spy, "C/c1", CSync.SyncInstructions.SYNC));

    //      GLib.assert_true (fake_folder.current_remote_state ().find ("C/c2").size == 26);
    //      GLib.assert_true (item_instruction (complete_spy, "C/c2", CSync.SyncInstructions.CONFLICT));
    //      TestSyncVirtualFiles.clean_up_test_sync_dehydration (complete_spy);

    //      var expected_local_state = fake_folder.current_local_state ();
    //      var expected_remote_state = fake_folder.current_remote_state ();
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state () == expected_local_state);
    //      GLib.assert_true (fake_folder.current_remote_state () == expected_remote_state);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private static void clean_up_test_sync_dehydration (ItemCompletedSpy complete_spy) {
    //      complete_spy = "";
    //  }

} // class TestSyncDehydration

} // namespace Testing
} // namespace Occ
