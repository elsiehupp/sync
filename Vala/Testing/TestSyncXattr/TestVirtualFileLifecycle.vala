namespace Occ {
namespace Testing {

/***********************************************************
@class TestVirtualFileLifecycle

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestVirtualFileLifecycle : AbstractTestSyncXAttr {

//    /***********************************************************
//    ***********************************************************/
//    private TestVirtualFileLifecycle () {
//        GLib.FETCH (bool, do_local_discovery);

//        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
//        set_up_vfs (fake_folder);
//        GLib.assert_true (fake_folder.current_local_state (), fake_folder.current_remote_state ());
//        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

//        clean_up_test_virtual_file_lifecycle ();

//        // Create a virtual file for a new remote file
//        fake_folder.remote_modifier ().mkdir ("A");
//        fake_folder.remote_modifier ().insert ("A/a1", 64);
//        var some_date = new GLib.DateTime (GLib.Date (1984, 07, 30), GLib.Time (1,3,2));
//        fake_folder.remote_modifier ().set_modification_time ("A/a1", some_date);
//        GLib.assert_true (fake_folder.sync_once ());
//        xaverify_virtual (fake_folder, "A/a1");
//        GLib.assert_true (database_record (fake_folder, "A/a1").file_size == 64);
//        GLib.assert_true (new FileInfo (fake_folder.local_path + "A/a1").last_modified () == some_date);
//        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
//        GLib.assert_true (item_instruction (complete_spy, "A/a1", CSync.SyncInstructions.NEW));
//        clean_up_test_virtual_file_lifecycle ();

//        // Another sync doesn't actually lead to changes
//        GLib.assert_true (fake_folder.sync_once ());
//        xaverify_virtual (fake_folder, "A/a1");
//        GLib.assert_true (database_record (fake_folder, "A/a1").file_size == 64);
//        GLib.assert_true (new FileInfo (fake_folder.local_path + "A/a1").last_modified () == some_date);
//        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
//        GLib.assert_true (complete_spy == "");
//        clean_up_test_virtual_file_lifecycle ();

//        // Not even when the remote is rediscovered
//        fake_folder.sync_journal ().force_remote_discovery_next_sync ();
//        GLib.assert_true (fake_folder.sync_once ());
//        xaverify_virtual (fake_folder, "A/a1");
//        GLib.assert_true (database_record (fake_folder, "A/a1").file_size == 64);
//        GLib.assert_true (new FileInfo (fake_folder.local_path + "A/a1").last_modified () == some_date);
//        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
//        GLib.assert_true (complete_spy == "");
//        clean_up_test_virtual_file_lifecycle ();

//        // Neither does a remote change
//        fake_folder.remote_modifier ().append_byte ("A/a1");
//        GLib.assert_true (fake_folder.sync_once ());
//        xaverify_virtual (fake_folder, "A/a1");
//        GLib.assert_true (database_record (fake_folder, "A/a1").file_size == 65);
//        GLib.assert_true (new FileInfo (fake_folder.local_path + "A/a1").last_modified () == some_date);
//        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
//        GLib.assert_true (item_instruction (complete_spy, "A/a1", CSync.SyncInstructions.UPDATE_METADATA));
//        GLib.assert_true (database_record (fake_folder, "A/a1").file_size == 65);
//        clean_up_test_virtual_file_lifecycle ();

//        // If the local virtual file is removed, this will be propagated remotely
//        if (!do_local_discovery)
//            fake_folder.sync_engine.set_local_discovery_options (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A" });
//        fake_folder.local_modifier.remove ("A/a1");
//        GLib.assert_true (fake_folder.sync_once ());
//        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
//        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a1"));
//        GLib.assert_true (item_instruction (complete_spy, "A/a1", CSync.SyncInstructions.REMOVE));
//        GLib.assert_true (!database_record (fake_folder, "A/a1").is_valid);
//        clean_up_test_virtual_file_lifecycle ();

//        // Recreate a1 before carrying on with the other tests
//        fake_folder.remote_modifier ().insert ("A/a1", 65);
//        fake_folder.remote_modifier ().set_modification_time ("A/a1", some_date);
//        GLib.assert_true (fake_folder.sync_once ());
//        xaverify_virtual (fake_folder, "A/a1");
//        GLib.assert_true (database_record (fake_folder, "A/a1").file_size == 65);
//        GLib.assert_true (new FileInfo (fake_folder.local_path + "A/a1").last_modified () == some_date);
//        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
//        GLib.assert_true (item_instruction (complete_spy, "A/a1", CSync.SyncInstructions.NEW));
//        clean_up_test_virtual_file_lifecycle ();

//        // Remote rename is propagated
//        fake_folder.remote_modifier ().rename ("A/a1", "A/a1m");
//        GLib.assert_true (fake_folder.sync_once ());
//        GLib.assert_true (!new FileInfo (fake_folder.local_path + "A/a1").exists ());
//        xaverify_virtual (fake_folder, "A/a1m");
//        GLib.assert_true (database_record (fake_folder, "A/a1m").file_size == 65);
//        GLib.assert_true (new FileInfo (fake_folder.local_path + "A/a1m").last_modified () == some_date);
//        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a1"));
//        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1m"));
//        GLib.assert_true (
//            item_instruction (complete_spy, "A/a1m", CSync.SyncInstructions.RENAME)
//            || (item_instruction (complete_spy, "A/a1m", CSync.SyncInstructions.NEW)
//                && item_instruction (complete_spy, "A/a1", CSync.SyncInstructions.REMOVE)));
//        GLib.assert_true (!database_record (fake_folder, "A/a1").is_valid);
//        clean_up_test_virtual_file_lifecycle ();

//        // Remote remove is propagated
//        fake_folder.remote_modifier ().remove ("A/a1m");
//        GLib.assert_true (fake_folder.sync_once ());
//        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path + "A/a1m").exists ());
//        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a1m"));
//        GLib.assert_true (item_instruction (complete_spy, "A/a1m", CSync.SyncInstructions.REMOVE));
//        GLib.assert_true (!database_record (fake_folder, "A/a1").is_valid);
//        GLib.assert_true (!database_record (fake_folder, "A/a1m").is_valid);
//        clean_up_test_virtual_file_lifecycle ();

//        // Edge case : Local virtual file but no database entry for some reason
//        fake_folder.remote_modifier ().insert ("A/a2", 32);
//        fake_folder.remote_modifier ().insert ("A/a3", 33);
//        GLib.assert_true (fake_folder.sync_once ());
//        xaverify_virtual (fake_folder, "A/a2");
//        GLib.assert_true (database_record (fake_folder, "A/a2").file_size == 32);
//        xaverify_virtual (fake_folder, "A/a3");
//        GLib.assert_true (database_record (fake_folder, "A/a3").file_size == 33);
//        clean_up_test_virtual_file_lifecycle ();

//        fake_folder.sync_engine.journal.delete_file_record ("A/a2");
//        fake_folder.sync_engine.journal.delete_file_record ("A/a3");
//        fake_folder.remote_modifier ().remove ("A/a3");
//        fake_folder.sync_engine.set_local_discovery_options (LocalDiscoveryStyle.FILESYSTEM_ONLY);
//        GLib.assert_true (fake_folder.sync_once ());
//        xaverify_virtual (fake_folder, "A/a2");
//        GLib.assert_true (database_record (fake_folder, "A/a2").file_size == 32);
//        GLib.assert_true (item_instruction (complete_spy, "A/a2", CSync.SyncInstructions.UPDATE_METADATA));
//        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path + "A/a3").exists ());
//        GLib.assert_true (item_instruction (complete_spy, "A/a3", CSync.SyncInstructions.REMOVE));
//        GLib.assert_true (!database_record (fake_folder, "A/a3").is_valid);
//        clean_up_test_virtual_file_lifecycle ();
//    }

//    /***********************************************************
//    ***********************************************************/
//    private static void clean_up_test_virtual_file_lifecycle () {
//        complete_spy = "";
//        if (!do_local_discovery) {
//            fake_folder.sync_engine.set_local_discovery_options (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM);
//        }
//    }

} // class TestVirtualFileLifecycle

} // namespace Testing
} // namespace Occ
