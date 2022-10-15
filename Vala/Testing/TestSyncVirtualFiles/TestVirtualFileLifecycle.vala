namespace Occ {
namespace Testing {

/***********************************************************
@class TestVirtualFileLifecycle

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestVirtualFileLifecycle : AbstractTestSyncVirtualFiles {

    /***********************************************************
    ***********************************************************/
    private TestVirtualFileLifecycle () {
        //  GLib.FETCH (bool, do_local_discovery);

        //  FakeFolder fake_folder = new FakeFolder (FileInfo ());
        //  set_up_vfs (fake_folder);
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        //  TestSyncVirtualFiles.clean_up_test_virtual_file_lifecycle (complete_spy, do_local_discovery, fake_folder);

        //  // Create a virtual file for a new remote file
        //  fake_folder.remote_modifier ().mkdir ("A");
        //  fake_folder.remote_modifier ().insert ("A/a1", 64);
        //  var some_date = new GLib.DateTime (new GLib.Date (1984, 07, 30), new GLib.Time (1,3,2));
        //  fake_folder.remote_modifier ().set_modification_time ("A/a1", some_date);
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX));
        //  GLib.assert_true (new FileInfo (fake_folder.local_path + "A/a1" + DVSUFFIX).last_modified () == some_date);
        //  GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a1" + DVSUFFIX, CSync.SyncInstructions.NEW));
        //  GLib.assert_true (database_record (fake_folder, "A/a1" + DVSUFFIX).type == ItemType.VIRTUAL_FILE);
        //  TestSyncVirtualFiles.clean_up_test_virtual_file_lifecycle (complete_spy, do_local_discovery, fake_folder);

        //  // Another sync doesn't actually lead to changes
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX));
        //  GLib.assert_true (new FileInfo (fake_folder.local_path + "A/a1" + DVSUFFIX).last_modified () == some_date);
        //  GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        //  GLib.assert_true (database_record (fake_folder, "A/a1" + DVSUFFIX).type == ItemType.VIRTUAL_FILE);
        //  GLib.assert_true (complete_spy == "");
        //  TestSyncVirtualFiles.clean_up_test_virtual_file_lifecycle (complete_spy, do_local_discovery, fake_folder);

        //  // Not even when the remote is rediscovered
        //  fake_folder.sync_journal ().force_remote_discovery_next_sync ();
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX));
        //  GLib.assert_true (new FileInfo (fake_folder.local_path + "A/a1" + DVSUFFIX).last_modified () == some_date);
        //  GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        //  GLib.assert_true (database_record (fake_folder, "A/a1" + DVSUFFIX).type == ItemType.VIRTUAL_FILE);
        //  GLib.assert_true (complete_spy == "");
        //  TestSyncVirtualFiles.clean_up_test_virtual_file_lifecycle (complete_spy, do_local_discovery, fake_folder);

        //  // Neither does a remote change
        //  fake_folder.remote_modifier ().append_byte ("A/a1");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a1" + DVSUFFIX, CSync.SyncInstructions.UPDATE_METADATA));
        //  GLib.assert_true (database_record (fake_folder, "A/a1" + DVSUFFIX).type == ItemType.VIRTUAL_FILE);
        //  GLib.assert_true (database_record (fake_folder, "A/a1" + DVSUFFIX).file_size == 65);
        //  TestSyncVirtualFiles.clean_up_test_virtual_file_lifecycle (complete_spy, do_local_discovery, fake_folder);

        //  // If the local virtual file file is removed, it'll just be recreated
        //  if (!do_local_discovery) {
        //      fake_folder.sync_engine.set_local_discovery_options (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A" });
        //  }
        //  fake_folder.local_modifier.remove ("A/a1" + DVSUFFIX);
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a1" + DVSUFFIX, CSync.SyncInstructions.NEW));
        //  GLib.assert_true (database_record (fake_folder, "A/a1" + DVSUFFIX).type == ItemType.VIRTUAL_FILE);
        //  GLib.assert_true (database_record (fake_folder, "A/a1" + DVSUFFIX).file_size == 65);
        //  TestSyncVirtualFiles.clean_up_test_virtual_file_lifecycle (complete_spy, do_local_discovery, fake_folder);

        //  // Remote rename is propagated
        //  fake_folder.remote_modifier ().rename ("A/a1", "A/a1m");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        //  GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1m"));
        //  GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a1m" + DVSUFFIX));
        //  GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a1"));
        //  GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1m"));
        //  GLib.assert_true (
        //      item_instruction (complete_spy, "A/a1m" + DVSUFFIX, CSync.SyncInstructions.RENAME)
        //      || (item_instruction (complete_spy, "A/a1m" + DVSUFFIX, CSync.SyncInstructions.NEW)
        //          && item_instruction (complete_spy, "A/a1" + DVSUFFIX, CSync.SyncInstructions.REMOVE)));
        //  GLib.assert_true (database_record (fake_folder, "A/a1m" + DVSUFFIX).type == ItemType.VIRTUAL_FILE);
        //  TestSyncVirtualFiles.clean_up_test_virtual_file_lifecycle (complete_spy, do_local_discovery, fake_folder);

        //  // Remote remove is propagated
        //  fake_folder.remote_modifier ().remove ("A/a1m");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1m" + DVSUFFIX));
        //  GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a1m"));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a1m" + DVSUFFIX, CSync.SyncInstructions.REMOVE));
        //  GLib.assert_true (!database_record (fake_folder, "A/a1" + DVSUFFIX).is_valid);
        //  GLib.assert_true (!database_record (fake_folder, "A/a1m" + DVSUFFIX).is_valid);
        //  TestSyncVirtualFiles.clean_up_test_virtual_file_lifecycle (complete_spy, do_local_discovery, fake_folder);

        //  // Edge case : Local virtual file but no database entry for some reason
        //  fake_folder.remote_modifier ().insert ("A/a2", 64);
        //  fake_folder.remote_modifier ().insert ("A/a3", 64);
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a2" + DVSUFFIX));
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a3" + DVSUFFIX));
        //  TestSyncVirtualFiles.clean_up_test_virtual_file_lifecycle (complete_spy, do_local_discovery, fake_folder);

        //  fake_folder.sync_engine.journal.delete_file_record ("A/a2" + DVSUFFIX);
        //  fake_folder.sync_engine.journal.delete_file_record ("A/a3" + DVSUFFIX);
        //  fake_folder.remote_modifier ().remove ("A/a3");
        //  fake_folder.sync_engine.set_local_discovery_options (LocalDiscoveryStyle.FILESYSTEM_ONLY);
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a2" + DVSUFFIX));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a2" + DVSUFFIX, CSync.SyncInstructions.UPDATE_METADATA));
        //  GLib.assert_true (database_record (fake_folder, "A/a2" + DVSUFFIX).is_valid);
        //  GLib.assert_true (!fake_folder.current_local_state ().find ("A/a3" + DVSUFFIX));
        //  GLib.assert_true (item_instruction (complete_spy, "A/a3" + DVSUFFIX, CSync.SyncInstructions.REMOVE));
        //  GLib.assert_true (!database_record (fake_folder, "A/a3" + DVSUFFIX).is_valid);
        //  TestSyncVirtualFiles.clean_up_test_virtual_file_lifecycle (complete_spy, do_local_discovery, fake_folder);
    }


    /***********************************************************
    ***********************************************************/
    private static void clean_up_test_virtual_file_lifecycle (ItemCompletedSpy complete_spy, bool do_local_discovery, FakeFolder fake_folder) {
        //  complete_spy = "";
        //  if (!do_local_discovery) {
        //      fake_folder.sync_engine.set_local_discovery_options (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM);
        //  }
    }

} // class TestVirtualFileLifecycle

} // namespace Testing
} // namespace Occ
