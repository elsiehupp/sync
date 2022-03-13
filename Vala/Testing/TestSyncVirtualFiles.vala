/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using Occ;

namespace Testing {

const int DVSUFFIX APPLICATION_DOTVIRTUALFILE_SUFFIX

bool item_instruction (ItemCompletedSpy spy, string path, SyncInstructions instr) {
    var item = spy.find_item (path);
    return item.instruction == instr;
}

SyncJournalFileRecord database_record (FakeFolder folder, string path) {
    SyncJournalFileRecord record;
    folder.sync_journal ().get_file_record (path, record);
    return record;
}

void trigger_download (FakeFolder folder, GLib.ByteArray path) {
    var journal = folder.sync_journal ();
    SyncJournalFileRecord record;
    journal.get_file_record (path + DVSUFFIX, record);
    if (!record.is_valid ())
        return;
    record.type = ItemTypeVirtualFileDownload;
    journal.set_file_record (record);
    journal.schedule_path_for_remote_discovery (record.path);
}

void mark_for_dehydration (FakeFolder folder, GLib.ByteArray path) {
    var journal = folder.sync_journal ();
    SyncJournalFileRecord record;
    journal.get_file_record (path, record);
    if (!record.is_valid ())
        return;
    record.type = ItemTypeVirtualFileDehydration;
    journal.set_file_record (record);
    journal.schedule_path_for_remote_discovery (record.path);
}

unowned<Vfs> set_up_vfs (FakeFolder folder) {
    var suffix_vfs = unowned<Vfs> (create_vfs_from_plugin (Vfs.WithSuffix).release ());
    folder.switch_to_vfs (suffix_vfs);

    // Using this directly doesn't recursively unpin everything and instead leaves
    // the files in the hydration that that they on_signal_start with
    folder.sync_journal ().internal_pin_states ().set_for_path ("", PinState.PinState.UNSPECIFIED);

    return suffix_vfs;
}

public class TestSyncVirtualFiles : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_lifecycle_data () {
        QTest.add_column<bool> ("do_local_discovery");

        QTest.new_row ("full local discovery") + true;
        QTest.new_row ("skip local discovery") + false;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_lifecycle () {
        QFETCH (bool, do_local_discovery);

        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
            if (!do_local_discovery)
                fake_folder.sync_engine ().set_local_discovery_options (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM);
        }
        on_signal_cleanup ();

        // Create a virtual file for a new remote file
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/a1", 64);
        var some_date = GLib.DateTime (QDate (1984, 07, 30), QTime (1,3,2));
        fake_folder.remote_modifier ().set_modification_time ("A/a1", some_date);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        GLib.assert_cmp (GLib.FileInfo (fake_folder.local_path () + "A/a1" DVSUFFIX).last_modified (), some_date);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (item_instruction (complete_spy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_NEW));
        GLib.assert_cmp (database_record (fake_folder, "A/a1" DVSUFFIX).type, ItemTypeVirtualFile);
        on_signal_cleanup ();

        // Another sync doesn't actually lead to changes
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        GLib.assert_cmp (GLib.FileInfo (fake_folder.local_path () + "A/a1" DVSUFFIX).last_modified (), some_date);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_cmp (database_record (fake_folder, "A/a1" DVSUFFIX).type, ItemTypeVirtualFile);
        GLib.assert_true (complete_spy.is_empty ());
        on_signal_cleanup ();

        // Not even when the remote is rediscovered
        fake_folder.sync_journal ().force_remote_discovery_next_sync ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        GLib.assert_cmp (GLib.FileInfo (fake_folder.local_path () + "A/a1" DVSUFFIX).last_modified (), some_date);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_cmp (database_record (fake_folder, "A/a1" DVSUFFIX).type, ItemTypeVirtualFile);
        GLib.assert_true (complete_spy.is_empty ());
        on_signal_cleanup ();

        // Neither does a remote change
        fake_folder.remote_modifier ().append_byte ("A/a1");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (item_instruction (complete_spy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_UPDATE_METADATA));
        GLib.assert_cmp (database_record (fake_folder, "A/a1" DVSUFFIX).type, ItemTypeVirtualFile);
        GLib.assert_cmp (database_record (fake_folder, "A/a1" DVSUFFIX).file_size, 65);
        on_signal_cleanup ();

        // If the local virtual file file is removed, it'll just be recreated
        if (!do_local_discovery)
            fake_folder.sync_engine ().set_local_discovery_options (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A" });
        fake_folder.local_modifier ().remove ("A/a1" DVSUFFIX);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (item_instruction (complete_spy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_NEW));
        GLib.assert_cmp (database_record (fake_folder, "A/a1" DVSUFFIX).type, ItemTypeVirtualFile);
        GLib.assert_cmp (database_record (fake_folder, "A/a1" DVSUFFIX).file_size, 65);
        on_signal_cleanup ();

        // Remote rename is propagated
        fake_folder.remote_modifier ().rename ("A/a1", "A/a1m");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1m"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1m" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1m"));
        GLib.assert_true (
            item_instruction (complete_spy, "A/a1m" DVSUFFIX, CSYNC_INSTRUCTION_RENAME)
            || (item_instruction (complete_spy, "A/a1m" DVSUFFIX, CSYNC_INSTRUCTION_NEW)
                && item_instruction (complete_spy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_REMOVE)));
        GLib.assert_cmp (database_record (fake_folder, "A/a1m" DVSUFFIX).type, ItemTypeVirtualFile);
        on_signal_cleanup ();

        // Remote remove is propagated
        fake_folder.remote_modifier ().remove ("A/a1m");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1m" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a1m"));
        GLib.assert_true (item_instruction (complete_spy, "A/a1m" DVSUFFIX, CSYNC_INSTRUCTION_REMOVE));
        GLib.assert_true (!database_record (fake_folder, "A/a1" DVSUFFIX).is_valid ());
        GLib.assert_true (!database_record (fake_folder, "A/a1m" DVSUFFIX).is_valid ());
        on_signal_cleanup ();

        // Edge case : Local virtual file but no database entry for some reason
        fake_folder.remote_modifier ().insert ("A/a2", 64);
        fake_folder.remote_modifier ().insert ("A/a3", 64);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a2" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a3" DVSUFFIX));
        on_signal_cleanup ();

        fake_folder.sync_engine ().journal ().delete_file_record ("A/a2" DVSUFFIX);
        fake_folder.sync_engine ().journal ().delete_file_record ("A/a3" DVSUFFIX);
        fake_folder.remote_modifier ().remove ("A/a3");
        fake_folder.sync_engine ().set_local_discovery_options (LocalDiscoveryStyle.FILESYSTEM_ONLY);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a2" DVSUFFIX));
        GLib.assert_true (item_instruction (complete_spy, "A/a2" DVSUFFIX, CSYNC_INSTRUCTION_UPDATE_METADATA));
        GLib.assert_true (database_record (fake_folder, "A/a2" DVSUFFIX).is_valid ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a3" DVSUFFIX));
        GLib.assert_true (item_instruction (complete_spy, "A/a3" DVSUFFIX, CSYNC_INSTRUCTION_REMOVE));
        GLib.assert_true (!database_record (fake_folder, "A/a3" DVSUFFIX).is_valid ());
        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_conflict () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        // Create a virtual file for a new remote file
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/a1", 64);
        fake_folder.remote_modifier ().insert ("A/a2", 64);
        fake_folder.remote_modifier ().mkdir ("B");
        fake_folder.remote_modifier ().insert ("B/b1", 64);
        fake_folder.remote_modifier ().insert ("B/b2", 64);
        fake_folder.remote_modifier ().mkdir ("C");
        fake_folder.remote_modifier ().insert ("C/c1", 64);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("B/b2" DVSUFFIX));
        on_signal_cleanup ();

        // A : the correct file and a conflicting file are added, virtual files stay
        // B : same setup, but the virtual files are deleted by the user
        // C : user adds a directory* locally
        fake_folder.local_modifier ().insert ("A/a1", 64);
        fake_folder.local_modifier ().insert ("A/a2", 30);
        fake_folder.local_modifier ().insert ("B/b1", 64);
        fake_folder.local_modifier ().insert ("B/b2", 30);
        fake_folder.local_modifier ().remove ("B/b1" DVSUFFIX);
        fake_folder.local_modifier ().remove ("B/b2" DVSUFFIX);
        fake_folder.local_modifier ().mkdir ("C/c1");
        fake_folder.local_modifier ().insert ("C/c1/foo");
        GLib.assert_true (fake_folder.sync_once ());

        // Everything is CONFLICT since mtimes are different even for a1/b1
        GLib.assert_true (item_instruction (complete_spy, "A/a1", CSYNC_INSTRUCTION_CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "A/a2", CSYNC_INSTRUCTION_CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "B/b1", CSYNC_INSTRUCTION_CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "B/b2", CSYNC_INSTRUCTION_CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "C/c1", CSYNC_INSTRUCTION_CONFLICT));

        // no virtual file files should remain
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a2" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/b1" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/b2" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("C/c1" DVSUFFIX));

        // conflict files should exist
        GLib.assert_cmp (fake_folder.sync_journal ().conflict_record_paths ().size (), 3);

        // nothing should have the virtual file tag
        GLib.assert_cmp (database_record (fake_folder, "A/a1").type, ItemTypeFile);
        GLib.assert_cmp (database_record (fake_folder, "A/a2").type, ItemTypeFile);
        GLib.assert_cmp (database_record (fake_folder, "B/b1").type, ItemTypeFile);
        GLib.assert_cmp (database_record (fake_folder, "B/b2").type, ItemTypeFile);
        GLib.assert_cmp (database_record (fake_folder, "C/c1").type, ItemTypeFile);
        GLib.assert_true (!database_record (fake_folder, "A/a1" DVSUFFIX).is_valid ());
        GLib.assert_true (!database_record (fake_folder, "A/a2" DVSUFFIX).is_valid ());
        GLib.assert_true (!database_record (fake_folder, "B/b1" DVSUFFIX).is_valid ());
        GLib.assert_true (!database_record (fake_folder, "B/b2" DVSUFFIX).is_valid ());
        GLib.assert_true (!database_record (fake_folder, "C/c1" DVSUFFIX).is_valid ());

        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_with_normal_sync () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        set_up_vfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        // No effect sync
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        on_signal_cleanup ();

        // Existing files are propagated just fine in both directions
        fake_folder.local_modifier ().append_byte ("A/a1");
        fake_folder.local_modifier ().insert ("A/a3");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        on_signal_cleanup ();

        // New files on the remote create virtual files
        fake_folder.remote_modifier ().insert ("A/new");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/new"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/new" DVSUFFIX));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/new"));
        GLib.assert_true (item_instruction (complete_spy, "A/new" DVSUFFIX, CSYNC_INSTRUCTION_NEW));
        GLib.assert_cmp (database_record (fake_folder, "A/new" DVSUFFIX).type, ItemTypeVirtualFile);
        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_download () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        // Create a virtual file for remote files
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/a1");
        fake_folder.remote_modifier ().insert ("A/a2");
        fake_folder.remote_modifier ().insert ("A/a3");
        fake_folder.remote_modifier ().insert ("A/a4");
        fake_folder.remote_modifier ().insert ("A/a5");
        fake_folder.remote_modifier ().insert ("A/a6");
        fake_folder.remote_modifier ().insert ("A/a7");
        fake_folder.remote_modifier ().insert ("A/b1");
        fake_folder.remote_modifier ().insert ("A/b2");
        fake_folder.remote_modifier ().insert ("A/b3");
        fake_folder.remote_modifier ().insert ("A/b4");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a2" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a3" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a4" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a5" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a6" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a7" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/b1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/b2" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/b3" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/b4" DVSUFFIX));
        on_signal_cleanup ();

        // Download by changing the database entry
        trigger_download (fake_folder, "A/a1");
        trigger_download (fake_folder, "A/a2");
        trigger_download (fake_folder, "A/a3");
        trigger_download (fake_folder, "A/a4");
        trigger_download (fake_folder, "A/a5");
        trigger_download (fake_folder, "A/a6");
        trigger_download (fake_folder, "A/a7");
        // Download by renaming locally
        fake_folder.local_modifier ().rename ("A/b1" DVSUFFIX, "A/b1");
        fake_folder.local_modifier ().rename ("A/b2" DVSUFFIX, "A/b2");
        fake_folder.local_modifier ().rename ("A/b3" DVSUFFIX, "A/b3");
        fake_folder.local_modifier ().rename ("A/b4" DVSUFFIX, "A/b4");
        // Remote complications
        fake_folder.remote_modifier ().append_byte ("A/a2");
        fake_folder.remote_modifier ().remove ("A/a3");
        fake_folder.remote_modifier ().rename ("A/a4", "A/a4m");
        fake_folder.remote_modifier ().append_byte ("A/b2");
        fake_folder.remote_modifier ().remove ("A/b3");
        fake_folder.remote_modifier ().rename ("A/b4", "A/b4m");
        // Local complications
        fake_folder.local_modifier ().insert ("A/a5");
        fake_folder.local_modifier ().insert ("A/a6");
        fake_folder.local_modifier ().remove ("A/a6" DVSUFFIX);
        fake_folder.local_modifier ().rename ("A/a7" DVSUFFIX, "A/a7");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/a1", CSYNC_INSTRUCTION_SYNC));
        GLib.assert_cmp (complete_spy.find_item ("A/a1").type, ItemTypeVirtualFileDownload);
        GLib.assert_true (item_instruction (complete_spy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_NONE));
        GLib.assert_true (item_instruction (complete_spy, "A/a2", CSYNC_INSTRUCTION_SYNC));
        GLib.assert_cmp (complete_spy.find_item ("A/a2").type, ItemTypeVirtualFileDownload);
        GLib.assert_true (item_instruction (complete_spy, "A/a2" DVSUFFIX, CSYNC_INSTRUCTION_NONE));
        GLib.assert_true (item_instruction (complete_spy, "A/a3" DVSUFFIX, CSYNC_INSTRUCTION_REMOVE));
        GLib.assert_true (item_instruction (complete_spy, "A/a4m", CSYNC_INSTRUCTION_NEW));
        GLib.assert_true (item_instruction (complete_spy, "A/a4" DVSUFFIX, CSYNC_INSTRUCTION_REMOVE));
        GLib.assert_true (item_instruction (complete_spy, "A/a5", CSYNC_INSTRUCTION_CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "A/a5" DVSUFFIX, CSYNC_INSTRUCTION_REMOVE));
        GLib.assert_true (item_instruction (complete_spy, "A/a6", CSYNC_INSTRUCTION_CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "A/a7", CSYNC_INSTRUCTION_SYNC));
        GLib.assert_true (item_instruction (complete_spy, "A/b1", CSYNC_INSTRUCTION_SYNC));
        GLib.assert_true (item_instruction (complete_spy, "A/b2", CSYNC_INSTRUCTION_SYNC));
        GLib.assert_true (item_instruction (complete_spy, "A/b3", CSYNC_INSTRUCTION_REMOVE));
        GLib.assert_true (item_instruction (complete_spy, "A/b4m" DVSUFFIX, CSYNC_INSTRUCTION_NEW));
        GLib.assert_true (item_instruction (complete_spy, "A/b4", CSYNC_INSTRUCTION_REMOVE));
        GLib.assert_cmp (database_record (fake_folder, "A/a1").type, ItemTypeFile);
        GLib.assert_true (!database_record (fake_folder, "A/a1" DVSUFFIX).is_valid ());
        GLib.assert_cmp (database_record (fake_folder, "A/a2").type, ItemTypeFile);
        GLib.assert_true (!database_record (fake_folder, "A/a3").is_valid ());
        GLib.assert_cmp (database_record (fake_folder, "A/a4m").type, ItemTypeFile);
        GLib.assert_cmp (database_record (fake_folder, "A/a5").type, ItemTypeFile);
        GLib.assert_cmp (database_record (fake_folder, "A/a6").type, ItemTypeFile);
        GLib.assert_cmp (database_record (fake_folder, "A/a7").type, ItemTypeFile);
        GLib.assert_cmp (database_record (fake_folder, "A/b1").type, ItemTypeFile);
        GLib.assert_true (!database_record (fake_folder, "A/b1" DVSUFFIX).is_valid ());
        GLib.assert_cmp (database_record (fake_folder, "A/b2").type, ItemTypeFile);
        GLib.assert_true (!database_record (fake_folder, "A/b3").is_valid ());
        GLib.assert_cmp (database_record (fake_folder, "A/b4m" DVSUFFIX).type, ItemTypeVirtualFile);
        GLib.assert_true (!database_record (fake_folder, "A/a1" DVSUFFIX).is_valid ());
        GLib.assert_true (!database_record (fake_folder, "A/a2" DVSUFFIX).is_valid ());
        GLib.assert_true (!database_record (fake_folder, "A/a3" DVSUFFIX).is_valid ());
        GLib.assert_true (!database_record (fake_folder, "A/a4" DVSUFFIX).is_valid ());
        GLib.assert_true (!database_record (fake_folder, "A/a5" DVSUFFIX).is_valid ());
        GLib.assert_true (!database_record (fake_folder, "A/a6" DVSUFFIX).is_valid ());
        GLib.assert_true (!database_record (fake_folder, "A/a7" DVSUFFIX).is_valid ());
        GLib.assert_true (!database_record (fake_folder, "A/b1" DVSUFFIX).is_valid ());
        GLib.assert_true (!database_record (fake_folder, "A/b2" DVSUFFIX).is_valid ());
        GLib.assert_true (!database_record (fake_folder, "A/b3" DVSUFFIX).is_valid ());
        GLib.assert_true (!database_record (fake_folder, "A/b4" DVSUFFIX).is_valid ());

        trigger_download (fake_folder, "A/b4m");
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_download_resume () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
            fake_folder.sync_journal ().wipe_error_blocklist ();
        }
        on_signal_cleanup ();

        // Create a virtual file for remote files
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/a1");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        on_signal_cleanup ();

        // Download by changing the database entry
        trigger_download (fake_folder, "A/a1");
        fake_folder.server_error_paths ().append ("A/a1", 500);
        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/a1", CSYNC_INSTRUCTION_SYNC));
        GLib.assert_true (item_instruction (complete_spy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_NONE));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_cmp (database_record (fake_folder, "A/a1" DVSUFFIX).type, ItemTypeVirtualFileDownload);
        GLib.assert_true (!database_record (fake_folder, "A/a1").is_valid ());
        on_signal_cleanup ();

        fake_folder.server_error_paths ().clear ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/a1", CSYNC_INSTRUCTION_SYNC));
        GLib.assert_true (item_instruction (complete_spy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_NONE));
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (database_record (fake_folder, "A/a1").type, ItemTypeFile);
        GLib.assert_true (!database_record (fake_folder, "A/a1" DVSUFFIX).is_valid ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_new_files_not_virtual () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/a1");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));

        fake_folder.sync_journal ().internal_pin_states ().set_for_path ("", PinState.PinState.ALWAYS_LOCAL);

        // Create a new remote file, it'll not be virtual
        fake_folder.remote_modifier ().insert ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a2"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a2" DVSUFFIX));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_download_recursive () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // Create a virtual file for remote files
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().mkdir ("A/Sub");
        fake_folder.remote_modifier ().mkdir ("A/Sub/SubSub");
        fake_folder.remote_modifier ().mkdir ("A/Sub2");
        fake_folder.remote_modifier ().mkdir ("B");
        fake_folder.remote_modifier ().mkdir ("B/Sub");
        fake_folder.remote_modifier ().insert ("A/a1");
        fake_folder.remote_modifier ().insert ("A/a2");
        fake_folder.remote_modifier ().insert ("A/Sub/a3");
        fake_folder.remote_modifier ().insert ("A/Sub/a4");
        fake_folder.remote_modifier ().insert ("A/Sub/SubSub/a5");
        fake_folder.remote_modifier ().insert ("A/Sub2/a6");
        fake_folder.remote_modifier ().insert ("B/b1");
        fake_folder.remote_modifier ().insert ("B/Sub/b2");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a2" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/a3" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/a4" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/SubSub/a5" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub2/a6" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("B/b1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("B/Sub/b2" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a2"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/a3"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/a4"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/SubSub/a5"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub2/a6"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/b1"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/Sub/b2"));

        // Download All file in the directory A/Sub
        // (as in Folder.download_virtual_file)
        fake_folder.sync_journal ().mark_virtual_file_for_download_recursively ("A/Sub");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a2" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/a3" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/a4" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/SubSub/a5" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub2/a6" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("B/b1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("B/Sub/b2" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a2"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/a3"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/a4"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/SubSub/a5"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub2/a6"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/b1"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/Sub/b2"));

        // Add a file in a subfolder that was downloaded
        // Currently, this continue to add it as a virtual file.
        fake_folder.remote_modifier ().insert ("A/Sub/SubSub/a7");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/SubSub/a7" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/SubSub/a7"));

        // Now download all files in "A"
        fake_folder.sync_journal ().mark_virtual_file_for_download_recursively ("A");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a2" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/a3" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/a4" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/SubSub/a5" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub2/a6" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/SubSub/a7" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("B/b1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("B/Sub/b2" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a2"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/a3"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/a4"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/SubSub/a5"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub2/a6"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/SubSub/a7"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/b1"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/Sub/b2"));

        // Now download remaining files in "B"
        fake_folder.sync_journal ().mark_virtual_file_for_download_recursively ("B");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_rename_to_virtual () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        set_up_vfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        // If a file is renamed to <name>.owncloud, it becomes virtual
        fake_folder.local_modifier ().rename ("A/a1", "A/a1" DVSUFFIX);
        // If a file is renamed to <random>.owncloud, the rename propagates but the
        // file isn't made virtual the first sync run.
        fake_folder.local_modifier ().rename ("A/a2", "A/rand" DVSUFFIX);
        // dangling virtual files are removed
        fake_folder.local_modifier ().insert ("A/dangling" DVSUFFIX, 1, ' ');
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX).size <= 1);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (item_instruction (complete_spy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_SYNC));
        GLib.assert_cmp (database_record (fake_folder, "A/a1" DVSUFFIX).type, ItemTypeVirtualFile);
        GLib.assert_true (!database_record (fake_folder, "A/a1").is_valid ());

        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a2"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a2" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/rand"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a2"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/rand"));
        GLib.assert_true (item_instruction (complete_spy, "A/rand", CSYNC_INSTRUCTION_RENAME));
        GLib.assert_true (database_record (fake_folder, "A/rand").type == ItemTypeFile);

        GLib.assert_true (!fake_folder.current_local_state ().find ("A/dangling" DVSUFFIX));
        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_rename_virtual () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        fake_folder.remote_modifier ().insert ("file1", 128, 'C');
        fake_folder.remote_modifier ().insert ("file2", 256, 'C');
        fake_folder.remote_modifier ().insert ("file3", 256, 'C');
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state ().find ("file1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("file2" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("file3" DVSUFFIX));
        on_signal_cleanup ();

        fake_folder.local_modifier ().rename ("file1" DVSUFFIX, "renamed1" DVSUFFIX);
        fake_folder.local_modifier ().rename ("file2" DVSUFFIX, "renamed2" DVSUFFIX);
        trigger_download (fake_folder, "file2");
        trigger_download (fake_folder, "file3");
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (!fake_folder.current_local_state ().find ("file1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("renamed1" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("file1"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("renamed1"));
        GLib.assert_true (item_instruction (complete_spy, "renamed1" DVSUFFIX, CSYNC_INSTRUCTION_RENAME));
        GLib.assert_true (database_record (fake_folder, "renamed1" DVSUFFIX).is_valid ());

        // file2 has a conflict between the download request and the rename:
        // the rename wins, the download is ignored
        GLib.assert_true (!fake_folder.current_local_state ().find ("file2"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("file2" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("renamed2" DVSUFFIX));
        GLib.assert_true (fake_folder.current_remote_state ().find ("renamed2"));
        GLib.assert_true (item_instruction (complete_spy, "renamed2" DVSUFFIX, CSYNC_INSTRUCTION_RENAME));
        GLib.assert_true (database_record (fake_folder, "renamed2" DVSUFFIX).type == ItemTypeVirtualFile);

        GLib.assert_true (item_instruction (complete_spy, "file3", CSYNC_INSTRUCTION_SYNC));
        GLib.assert_true (database_record (fake_folder, "file3").type == ItemTypeFile);
        on_signal_cleanup ();

        // Test rename while adding/removing vfs suffix
        fake_folder.local_modifier ().rename ("renamed1" DVSUFFIX, "R1");
        // Contents of file2 could also change at the same time...
        fake_folder.local_modifier ().rename ("file3", "R3" DVSUFFIX);
        GLib.assert_true (fake_folder.sync_once ());
        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_rename_virtual2 () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        set_up_vfs (fake_folder);
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        fake_folder.remote_modifier ().insert ("case3", 128, 'C');
        fake_folder.remote_modifier ().insert ("case4", 256, 'C');
        fake_folder.remote_modifier ().insert ("case5", 256, 'C');
        fake_folder.remote_modifier ().insert ("case6", 256, 'C');
        GLib.assert_true (fake_folder.sync_once ());

        trigger_download (fake_folder, "case4");
        trigger_download (fake_folder, "case6");
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state ().find ("case3" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("case4"));
        GLib.assert_true (fake_folder.current_local_state ().find ("case5" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("case6"));
        on_signal_cleanup ();

        // Case 1 : foo . bar (tested elsewhere)
        // Case 2 : foo.oc . bar.oc (tested elsewhere)

        // Case 3 : foo.oc . bar (database unchanged)
        fake_folder.local_modifier ().rename ("case3" DVSUFFIX, "case3-rename");

        // Case 4 : foo . bar.oc (database unchanged)
        fake_folder.local_modifier ().rename ("case4", "case4-rename" DVSUFFIX);

        // Case 5 : foo.oc . bar.oc (database hydrate)
        fake_folder.local_modifier ().rename ("case5" DVSUFFIX, "case5-rename" DVSUFFIX);
        trigger_download (fake_folder, "case5");

        // Case 6 : foo . bar (database dehydrate)
        fake_folder.local_modifier ().rename ("case6", "case6-rename");
        mark_for_dehydration (fake_folder, "case6");

        GLib.assert_true (fake_folder.sync_once ());

        // Case 3 : the rename went though, hydration is forgotten
        GLib.assert_true (!fake_folder.current_local_state ().find ("case3"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("case3" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("case3-rename"));
        GLib.assert_true (fake_folder.current_local_state ().find ("case3-rename" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("case3"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("case3-rename"));
        GLib.assert_true (item_instruction (complete_spy, "case3-rename" DVSUFFIX, CSYNC_INSTRUCTION_RENAME));
        GLib.assert_true (database_record (fake_folder, "case3-rename" DVSUFFIX).type == ItemTypeVirtualFile);

        // Case 4 : the rename went though, dehydration is forgotten
        GLib.assert_true (!fake_folder.current_local_state ().find ("case4"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("case4" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("case4-rename"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("case4-rename" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("case4"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("case4-rename"));
        GLib.assert_true (item_instruction (complete_spy, "case4-rename", CSYNC_INSTRUCTION_RENAME));
        GLib.assert_true (database_record (fake_folder, "case4-rename").type == ItemTypeFile);

        // Case 5 : the rename went though, hydration is forgotten
        GLib.assert_true (!fake_folder.current_local_state ().find ("case5"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("case5" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("case5-rename"));
        GLib.assert_true (fake_folder.current_local_state ().find ("case5-rename" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("case5"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("case5-rename"));
        GLib.assert_true (item_instruction (complete_spy, "case5-rename" DVSUFFIX, CSYNC_INSTRUCTION_RENAME));
        GLib.assert_true (database_record (fake_folder, "case5-rename" DVSUFFIX).type == ItemTypeVirtualFile);

        // Case 6 : the rename went though, dehydration is forgotten
        GLib.assert_true (!fake_folder.current_local_state ().find ("case6"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("case6" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("case6-rename"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("case6-rename" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("case6"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("case6-rename"));
        GLib.assert_true (item_instruction (complete_spy, "case6-rename", CSYNC_INSTRUCTION_RENAME));
        GLib.assert_true (database_record (fake_folder, "case6-rename").type == ItemTypeFile);
    }

    // Dehydration via sync works
    private void on_signal_test_sync_dehydration () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        set_up_vfs (fake_folder);

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        //
        // Mark for dehydration and check
        //

        mark_for_dehydration (fake_folder, "A/a1");

        mark_for_dehydration (fake_folder, "A/a2");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        // expect : normal dehydration

        mark_for_dehydration (fake_folder, "B/b1");
        fake_folder.remote_modifier ().remove ("B/b1");
        // expect : local removal

        mark_for_dehydration (fake_folder, "B/b2");
        fake_folder.remote_modifier ().rename ("B/b2", "B/b3");
        // expect : B/b2 is gone, B/b3 is NEW placeholder

        mark_for_dehydration (fake_folder, "C/c1");
        fake_folder.local_modifier ().append_byte ("C/c1");
        // expect : no dehydration, upload of c1

        mark_for_dehydration (fake_folder, "C/c2");
        fake_folder.local_modifier ().append_byte ("C/c2");
        fake_folder.remote_modifier ().append_byte ("C/c2");
        fake_folder.remote_modifier ().append_byte ("C/c2");
        // expect : no dehydration, conflict

        GLib.assert_true (fake_folder.sync_once ());

        var is_dehydrated = [&] (string path) {
            string placeholder = path + DVSUFFIX;
            return !fake_folder.current_local_state ().find (path)
                && fake_folder.current_local_state ().find (placeholder);
        }
        var has_dehydrated_database_entries = [&] (string path) {
            SyncJournalFileRecord normal, suffix;
            fake_folder.sync_journal ().get_file_record (path, normal);
            fake_folder.sync_journal ().get_file_record (path + DVSUFFIX, suffix);
            return !normal.is_valid () && suffix.is_valid () && suffix.type == ItemTypeVirtualFile;
        }

        GLib.assert_true (is_dehydrated ("A/a1"));
        GLib.assert_true (has_dehydrated_database_entries ("A/a1"));
        GLib.assert_true (item_instruction (complete_spy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_SYNC));
        GLib.assert_cmp (complete_spy.find_item ("A/a1" DVSUFFIX).type, ItemTypeVirtualFileDehydration);
        GLib.assert_cmp (complete_spy.find_item ("A/a1" DVSUFFIX).file, "A/a1");
        GLib.assert_cmp (complete_spy.find_item ("A/a1" DVSUFFIX).rename_target, "A/a1" + DVSUFFIX);
        GLib.assert_true (is_dehydrated ("A/a2"));
        GLib.assert_true (has_dehydrated_database_entries ("A/a2"));
        GLib.assert_true (item_instruction (complete_spy, "A/a2" DVSUFFIX, CSYNC_INSTRUCTION_SYNC));
        GLib.assert_cmp (complete_spy.find_item ("A/a2" DVSUFFIX).type, ItemTypeVirtualFileDehydration);

        GLib.assert_true (!fake_folder.current_local_state ().find ("B/b1"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("B/b1"));
        GLib.assert_true (item_instruction (complete_spy, "B/b1", CSYNC_INSTRUCTION_REMOVE));

        GLib.assert_true (!fake_folder.current_local_state ().find ("B/b2"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("B/b2"));
        GLib.assert_true (is_dehydrated ("B/b3"));
        GLib.assert_true (has_dehydrated_database_entries ("B/b3"));
        GLib.assert_true (item_instruction (complete_spy, "B/b2", CSYNC_INSTRUCTION_REMOVE));
        GLib.assert_true (item_instruction (complete_spy, "B/b3" DVSUFFIX, CSYNC_INSTRUCTION_NEW));

        GLib.assert_cmp (fake_folder.current_remote_state ().find ("C/c1").size, 25);
        GLib.assert_true (item_instruction (complete_spy, "C/c1", CSYNC_INSTRUCTION_SYNC));

        GLib.assert_cmp (fake_folder.current_remote_state ().find ("C/c2").size, 26);
        GLib.assert_true (item_instruction (complete_spy, "C/c2", CSYNC_INSTRUCTION_CONFLICT));
        on_signal_cleanup ();

        var expected_local_state = fake_folder.current_local_state ();
        var expected_remote_state = fake_folder.current_remote_state ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), expected_local_state);
        GLib.assert_cmp (fake_folder.current_remote_state (), expected_remote_state);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_wipe_virtual_suffix_files () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);

        // Create a suffix-vfs baseline

        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().mkdir ("A/B");
        fake_folder.remote_modifier ().insert ("f1");
        fake_folder.remote_modifier ().insert ("A/a1");
        fake_folder.remote_modifier ().insert ("A/a3");
        fake_folder.remote_modifier ().insert ("A/B/b1");
        fake_folder.local_modifier ().mkdir ("A");
        fake_folder.local_modifier ().mkdir ("A/B");
        fake_folder.local_modifier ().insert ("f2");
        fake_folder.local_modifier ().insert ("A/a2");
        fake_folder.local_modifier ().insert ("A/B/b2");

        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state ().find ("f1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a3" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/B/b1" DVSUFFIX));

        // Make local changes to a3
        fake_folder.local_modifier ().remove ("A/a3" DVSUFFIX);
        fake_folder.local_modifier ().insert ("A/a3" DVSUFFIX, 100);

        // Now wipe the virtuals

        SyncEngine.wipe_virtual_files (fake_folder.local_path (), fake_folder.sync_journal (), *fake_folder.sync_engine ().sync_options ().vfs);

        GLib.assert_true (!fake_folder.current_local_state ().find ("f1" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a3" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/B/b1" DVSUFFIX));

        fake_folder.switch_to_vfs (unowned<Vfs> (new VfsOff));
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a3" DVSUFFIX)); // regular upload
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_new_virtuals () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        var set_pin = [&] (GLib.ByteArray path, PinState state) {
            fake_folder.sync_journal ().internal_pin_states ().set_for_path (path, state);
        }

        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("online");
        fake_folder.remote_modifier ().mkdir ("unspec");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        set_pin ("local", PinState.PinState.ALWAYS_LOCAL);
        set_pin ("online", PinState.VfsItemAvailability.ONLINE_ONLY);
        set_pin ("unspec", PinState.PinState.UNSPECIFIED);

        // Test 1 : root is PinState.UNSPECIFIED
        fake_folder.remote_modifier ().insert ("file1");
        fake_folder.remote_modifier ().insert ("online/file1");
        fake_folder.remote_modifier ().insert ("local/file1");
        fake_folder.remote_modifier ().insert ("unspec/file1");
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state ().find ("file1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("online/file1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("local/file1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("unspec/file1" DVSUFFIX));

        // Test 2 : change root to PinState.ALWAYS_LOCAL
        set_pin ("", PinState.PinState.ALWAYS_LOCAL);

        fake_folder.remote_modifier ().insert ("file2");
        fake_folder.remote_modifier ().insert ("online/file2");
        fake_folder.remote_modifier ().insert ("local/file2");
        fake_folder.remote_modifier ().insert ("unspec/file2");
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state ().find ("file2"));
        GLib.assert_true (fake_folder.current_local_state ().find ("online/file2" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("local/file2"));
        GLib.assert_true (fake_folder.current_local_state ().find ("unspec/file2" DVSUFFIX));

        // root file1 was hydrated due to its new pin state
        GLib.assert_true (fake_folder.current_local_state ().find ("file1"));

        // file1 is unchanged in the explicitly pinned subfolders
        GLib.assert_true (fake_folder.current_local_state ().find ("online/file1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("local/file1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("unspec/file1" DVSUFFIX));

        // Test 3 : change root to VfsItemAvailability.ONLINE_ONLY
        set_pin ("", PinState.VfsItemAvailability.ONLINE_ONLY);

        fake_folder.remote_modifier ().insert ("file3");
        fake_folder.remote_modifier ().insert ("online/file3");
        fake_folder.remote_modifier ().insert ("local/file3");
        fake_folder.remote_modifier ().insert ("unspec/file3");
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state ().find ("file3" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("online/file3" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("local/file3"));
        GLib.assert_true (fake_folder.current_local_state ().find ("unspec/file3" DVSUFFIX));

        // root file1 was dehydrated due to its new pin state
        GLib.assert_true (fake_folder.current_local_state ().find ("file1" DVSUFFIX));

        // file1 is unchanged in the explicitly pinned subfolders
        GLib.assert_true (fake_folder.current_local_state ().find ("online/file1" DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("local/file1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("unspec/file1" DVSUFFIX));
    }

    // Check what happens if vfs-suffixed files exist on the server or locally
    // while the file is hydrated
    private void on_signal_test_suffix_files_while_local_hydrated () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());

        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        // suffixed files are happily synced with Vfs.Off
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/test1" DVSUFFIX, 10, 'A');
        fake_folder.remote_modifier ().insert ("A/test2" DVSUFFIX, 20, 'A');
        fake_folder.remote_modifier ().insert ("A/file1" DVSUFFIX, 30, 'A');
        fake_folder.remote_modifier ().insert ("A/file2", 40, 'A');
        fake_folder.remote_modifier ().insert ("A/file2" DVSUFFIX, 50, 'A');
        fake_folder.remote_modifier ().insert ("A/file3", 60, 'A');
        fake_folder.remote_modifier ().insert ("A/file3" DVSUFFIX, 70, 'A');
        fake_folder.remote_modifier ().insert ("A/file3" DVSUFFIX DVSUFFIX, 80, 'A');
        fake_folder.remote_modifier ().insert ("A/remote1" DVSUFFIX, 30, 'A');
        fake_folder.remote_modifier ().insert ("A/remote2", 40, 'A');
        fake_folder.remote_modifier ().insert ("A/remote2" DVSUFFIX, 50, 'A');
        fake_folder.remote_modifier ().insert ("A/remote3", 60, 'A');
        fake_folder.remote_modifier ().insert ("A/remote3" DVSUFFIX, 70, 'A');
        fake_folder.remote_modifier ().insert ("A/remote3" DVSUFFIX DVSUFFIX, 80, 'A');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        on_signal_cleanup ();

        // Enable suffix vfs
        set_up_vfs (fake_folder);

        // A simple sync removes the files that are now ignored (?)
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/file1" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file2" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" DVSUFFIX DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        on_signal_cleanup ();

        // Add a real file where the suffixed file exists
        fake_folder.local_modifier ().insert ("A/test1", 11, 'A');
        fake_folder.remote_modifier ().insert ("A/test2", 21, 'A');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/test1", CSYNC_INSTRUCTION_NEW));
        // this isn't fully good since some code requires size == 1 for placeholders
        // (when renaming placeholder to real file). But the alternative would mean
        // special casing this to allow CONFLICT at virtual file creation level. Ew.
        GLib.assert_true (item_instruction (complete_spy, "A/test2" DVSUFFIX, CSYNC_INSTRUCTION_UPDATE_METADATA));
        on_signal_cleanup ();

        // Local changes of suffixed file do nothing
        fake_folder.local_modifier ().set_contents ("A/file1" DVSUFFIX, 'B');
        fake_folder.local_modifier ().set_contents ("A/file2" DVSUFFIX, 'B');
        fake_folder.local_modifier ().set_contents ("A/file3" DVSUFFIX, 'B');
        fake_folder.local_modifier ().set_contents ("A/file3" DVSUFFIX DVSUFFIX, 'B');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/file1" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file2" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" DVSUFFIX DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        on_signal_cleanup ();

        // Remote changes don't do anything either
        fake_folder.remote_modifier ().set_contents ("A/file1" DVSUFFIX, 'C');
        fake_folder.remote_modifier ().set_contents ("A/file2" DVSUFFIX, 'C');
        fake_folder.remote_modifier ().set_contents ("A/file3" DVSUFFIX, 'C');
        fake_folder.remote_modifier ().set_contents ("A/file3" DVSUFFIX DVSUFFIX, 'C');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/file1" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file2" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" DVSUFFIX DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        on_signal_cleanup ();

        // Local removal : when not querying server
        fake_folder.local_modifier ().remove ("A/file1" DVSUFFIX);
        fake_folder.local_modifier ().remove ("A/file2" DVSUFFIX);
        fake_folder.local_modifier ().remove ("A/file3" DVSUFFIX);
        fake_folder.local_modifier ().remove ("A/file3" DVSUFFIX DVSUFFIX);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (complete_spy.find_item ("A/file1" DVSUFFIX).is_empty ());
        GLib.assert_true (complete_spy.find_item ("A/file2" DVSUFFIX).is_empty ());
        GLib.assert_true (complete_spy.find_item ("A/file3" DVSUFFIX).is_empty ());
        GLib.assert_true (complete_spy.find_item ("A/file3" DVSUFFIX DVSUFFIX).is_empty ());
        on_signal_cleanup ();

        // Local removal : when querying server
        fake_folder.remote_modifier ().set_contents ("A/file1" DVSUFFIX, 'D');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/file1" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file2" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" DVSUFFIX DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        on_signal_cleanup ();

        // Remote removal
        fake_folder.remote_modifier ().remove ("A/remote1" DVSUFFIX);
        fake_folder.remote_modifier ().remove ("A/remote2" DVSUFFIX);
        fake_folder.remote_modifier ().remove ("A/remote3" DVSUFFIX);
        fake_folder.remote_modifier ().remove ("A/remote3" DVSUFFIX DVSUFFIX);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/remote1" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/remote2" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/remote3" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/remote3" DVSUFFIX DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        on_signal_cleanup ();

        // New files with a suffix aren't propagated downwards in the first place
        fake_folder.remote_modifier ().insert ("A/new1" DVSUFFIX);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/new1" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/new1" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/new1"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/new1" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/new1" DVSUFFIX DVSUFFIX));
        on_signal_cleanup ();
    }

    // Check what happens if vfs-suffixed files exist on the server or in the database
    private void on_signal_test_extra_files_local_dehydrated () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        set_up_vfs (fake_folder);

        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        // create a bunch of local virtual files, in some instances
        // ignore remote files
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/file1", 30, 'A');
        fake_folder.remote_modifier ().insert ("A/file2", 40, 'A');
        fake_folder.remote_modifier ().insert ("A/file3", 60, 'A');
        fake_folder.remote_modifier ().insert ("A/file3" DVSUFFIX, 70, 'A');
        fake_folder.remote_modifier ().insert ("A/file4", 80, 'A');
        fake_folder.remote_modifier ().insert ("A/file4" DVSUFFIX, 90, 'A');
        fake_folder.remote_modifier ().insert ("A/file4" DVSUFFIX DVSUFFIX, 100, 'A');
        fake_folder.remote_modifier ().insert ("A/file5", 110, 'A');
        fake_folder.remote_modifier ().insert ("A/file6", 120, 'A');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/file1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/file1" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/file2"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/file2" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/file3"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/file3" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/file4"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/file4" DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/file4" DVSUFFIX DVSUFFIX));
        GLib.assert_true (item_instruction (complete_spy, "A/file1" DVSUFFIX, CSYNC_INSTRUCTION_NEW));
        GLib.assert_true (item_instruction (complete_spy, "A/file2" DVSUFFIX, CSYNC_INSTRUCTION_NEW));
        GLib.assert_true (item_instruction (complete_spy, "A/file3" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file4" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file4" DVSUFFIX DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        on_signal_cleanup ();

        // Create odd extra files locally and remotely
        fake_folder.local_modifier ().insert ("A/file1", 10, 'A');
        fake_folder.local_modifier ().insert ("A/file2" DVSUFFIX DVSUFFIX, 10, 'A');
        fake_folder.remote_modifier ().insert ("A/file5" DVSUFFIX, 10, 'A');
        fake_folder.local_modifier ().insert ("A/file6", 10, 'A');
        fake_folder.remote_modifier ().insert ("A/file6" DVSUFFIX, 10, 'A');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/file1", CSYNC_INSTRUCTION_CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "A/file1" DVSUFFIX, CSYNC_INSTRUCTION_REMOVE)); // it's now a pointless real virtual file
        GLib.assert_true (item_instruction (complete_spy, "A/file2" DVSUFFIX DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file5" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/file6", CSYNC_INSTRUCTION_CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "A/file6" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_availability () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        var vfs = set_up_vfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        var set_pin = [&] (GLib.ByteArray path, PinState state) {
            fake_folder.sync_journal ().internal_pin_states ().set_for_path (path, state);
        }

        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("local/sub");
        fake_folder.remote_modifier ().mkdir ("online");
        fake_folder.remote_modifier ().mkdir ("online/sub");
        fake_folder.remote_modifier ().mkdir ("unspec");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        set_pin ("local", PinState.PinState.ALWAYS_LOCAL);
        set_pin ("online", PinState.VfsItemAvailability.ONLINE_ONLY);
        set_pin ("unspec", PinState.PinState.UNSPECIFIED);

        fake_folder.remote_modifier ().insert ("file1");
        fake_folder.remote_modifier ().insert ("online/file1");
        fake_folder.remote_modifier ().insert ("online/file2");
        fake_folder.remote_modifier ().insert ("local/file1");
        fake_folder.remote_modifier ().insert ("local/file2");
        fake_folder.remote_modifier ().insert ("unspec/file1");
        GLib.assert_true (fake_folder.sync_once ());

        // root is unspecified
        GLib.assert_cmp (*vfs.availability ("file1" DVSUFFIX), VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);
        GLib.assert_cmp (*vfs.availability ("local"), VfsItemAvailability.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (*vfs.availability ("local/file1"), VfsItemAvailability.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (*vfs.availability ("online"), VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (*vfs.availability ("online/file1" DVSUFFIX), VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (*vfs.availability ("unspec"), VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);
        GLib.assert_cmp (*vfs.availability ("unspec/file1" DVSUFFIX), VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);

        // Subitem pin states can ruin "pure" availabilities
        set_pin ("local/sub", PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (*vfs.availability ("local"), VfsItemAvailability.VfsItemAvailability.ALL_HYDRATED);
        set_pin ("online/sub", PinState.PinState.UNSPECIFIED);
        GLib.assert_cmp (*vfs.availability ("online"), VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);

        trigger_download (fake_folder, "unspec/file1");
        set_pin ("local/file2", PinState.VfsItemAvailability.ONLINE_ONLY);
        set_pin ("online/file2" DVSUFFIX, PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_cmp (*vfs.availability ("unspec"), VfsItemAvailability.VfsItemAvailability.ALL_HYDRATED);
        GLib.assert_cmp (*vfs.availability ("local"), VfsItemAvailability.VfsItemAvailability.MIXED);
        GLib.assert_cmp (*vfs.availability ("online"), VfsItemAvailability.VfsItemAvailability.MIXED);

        GLib.assert_true (vfs.set_pin_state ("local", PinState.PinState.ALWAYS_LOCAL));
        GLib.assert_true (vfs.set_pin_state ("online", PinState.VfsItemAvailability.ONLINE_ONLY));
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_cmp (*vfs.availability ("online"), VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (*vfs.availability ("local"), VfsItemAvailability.PinState.ALWAYS_LOCAL);

        var r = vfs.availability ("nonexistant");
        GLib.assert_true (!r);
        GLib.assert_cmp (r.error (), Vfs.AvailabilityError.NO_SUCH_ITEM);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_pin_state_locals () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        var vfs = set_up_vfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        var set_pin = [&] (GLib.ByteArray path, PinState state) {
            fake_folder.sync_journal ().internal_pin_states ().set_for_path (path, state);
        }

        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("online");
        fake_folder.remote_modifier ().mkdir ("unspec");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        set_pin ("local", PinState.PinState.ALWAYS_LOCAL);
        set_pin ("online", PinState.VfsItemAvailability.ONLINE_ONLY);
        set_pin ("unspec", PinState.PinState.UNSPECIFIED);

        fake_folder.local_modifier ().insert ("file1");
        fake_folder.local_modifier ().insert ("online/file1");
        fake_folder.local_modifier ().insert ("online/file2");
        fake_folder.local_modifier ().insert ("local/file1");
        fake_folder.local_modifier ().insert ("unspec/file1");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // root is unspecified
        GLib.assert_cmp (*vfs.pin_state ("file1" DVSUFFIX), PinState.PinState.UNSPECIFIED);
        GLib.assert_cmp (*vfs.pin_state ("local/file1"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (*vfs.pin_state ("online/file1"), PinState.PinState.UNSPECIFIED);
        GLib.assert_cmp (*vfs.pin_state ("unspec/file1"), PinState.PinState.UNSPECIFIED);

        // Sync again : bad pin states of new local files usually take effect on second sync
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // When a file in an online-only folder is renamed, it retains its pin
        fake_folder.local_modifier ().rename ("online/file1", "online/file1rename");
        fake_folder.remote_modifier ().rename ("online/file2", "online/file2rename");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (*vfs.pin_state ("online/file1rename"), PinState.PinState.UNSPECIFIED);
        GLib.assert_cmp (*vfs.pin_state ("online/file2rename"), PinState.PinState.UNSPECIFIED);

        // When a folder is renamed, the pin states inside should be retained
        fake_folder.local_modifier ().rename ("online", "onlinerenamed1");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (*vfs.pin_state ("onlinerenamed1"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (*vfs.pin_state ("onlinerenamed1/file1rename"), PinState.PinState.UNSPECIFIED);

        fake_folder.remote_modifier ().rename ("onlinerenamed1", "onlinerenamed2");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (*vfs.pin_state ("onlinerenamed2"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (*vfs.pin_state ("onlinerenamed2/file1rename"), PinState.PinState.UNSPECIFIED);

        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // When a file is deleted and later a new file has the same name, the old pin
        // state isn't preserved.
        GLib.assert_cmp (*vfs.pin_state ("onlinerenamed2/file1rename"), PinState.PinState.UNSPECIFIED);
        fake_folder.remote_modifier ().remove ("onlinerenamed2/file1rename");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (*vfs.pin_state ("onlinerenamed2/file1rename"), PinState.VfsItemAvailability.ONLINE_ONLY);
        fake_folder.remote_modifier ().insert ("onlinerenamed2/file1rename");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (*vfs.pin_state ("onlinerenamed2/file1rename"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (*vfs.pin_state ("onlinerenamed2/file1rename" DVSUFFIX), PinState.VfsItemAvailability.ONLINE_ONLY);

        // When a file is hydrated or dehydrated due to pin state it retains its pin state
        GLib.assert_true (vfs.set_pin_state ("onlinerenamed2/file1rename" DVSUFFIX, PinState.PinState.ALWAYS_LOCAL));
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("onlinerenamed2/file1rename"));
        GLib.assert_cmp (*vfs.pin_state ("onlinerenamed2/file1rename"), PinState.PinState.ALWAYS_LOCAL);

        GLib.assert_true (vfs.set_pin_state ("onlinerenamed2", PinState.PinState.UNSPECIFIED));
        GLib.assert_true (vfs.set_pin_state ("onlinerenamed2/file1rename", PinState.VfsItemAvailability.ONLINE_ONLY));
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("onlinerenamed2/file1rename" DVSUFFIX));
        GLib.assert_cmp (*vfs.pin_state ("onlinerenamed2/file1rename" DVSUFFIX), PinState.VfsItemAvailability.ONLINE_ONLY);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_incompatible_pins () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        var vfs = set_up_vfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        var set_pin = [&] (GLib.ByteArray path, PinState state) {
            fake_folder.sync_journal ().internal_pin_states ().set_for_path (path, state);
        }

        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("online");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        set_pin ("local", PinState.PinState.ALWAYS_LOCAL);
        set_pin ("online", PinState.VfsItemAvailability.ONLINE_ONLY);

        fake_folder.local_modifier ().insert ("local/file1");
        fake_folder.local_modifier ().insert ("online/file1");
        GLib.assert_true (fake_folder.sync_once ());

        mark_for_dehydration (fake_folder, "local/file1");
        trigger_download (fake_folder, "online/file1");

        // the sync sets the changed files pin states to unspecified
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state ().find ("online/file1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("local/file1" DVSUFFIX));
        GLib.assert_cmp (*vfs.pin_state ("online/file1"), PinState.PinState.UNSPECIFIED);
        GLib.assert_cmp (*vfs.pin_state ("local/file1" DVSUFFIX), PinState.PinState.UNSPECIFIED);

        // no change on another sync
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("online/file1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("local/file1" DVSUFFIX));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_place_holder_exist () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().insert ("A/a1" DVSUFFIX, 111);
        fake_folder.remote_modifier ().insert ("A/hello" DVSUFFIX, 222);
        GLib.assert_true (fake_folder.sync_once ());
        var vfs = set_up_vfs (fake_folder);

        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        var on_signal_cleanup = [&] () { complete_spy.clear (); };
        on_signal_cleanup ();

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_true (item_instruction (complete_spy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/hello" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));

        fake_folder.remote_modifier ().insert ("A/a2" DVSUFFIX);
        fake_folder.remote_modifier ().insert ("A/hello", 12);
        fake_folder.local_modifier ().insert ("A/igno" DVSUFFIX, 123);
        on_signal_cleanup ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        GLib.assert_true (item_instruction (complete_spy, "A/igno" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));

        // verify that the files are still present
        GLib.assert_cmp (fake_folder.current_local_state ().find ("A/hello" DVSUFFIX).size, 222);
        GLib.assert_cmp (*fake_folder.current_local_state ().find ("A/hello" DVSUFFIX),
                 *fake_folder.current_remote_state ().find ("A/hello" DVSUFFIX));
        GLib.assert_cmp (fake_folder.current_local_state ().find ("A/igno" DVSUFFIX).size, 123);

        on_signal_cleanup ();
        // Dehydrate
        GLib.assert_true (vfs.set_pin_state ("", PinState.VfsItemAvailability.ONLINE_ONLY));
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (item_instruction (complete_spy, "A/igno" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        // verify that the files are still present
        GLib.assert_cmp (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX).size, 111);
        GLib.assert_cmp (fake_folder.current_local_state ().find ("A/hello" DVSUFFIX).size, 222);
        GLib.assert_cmp (*fake_folder.current_local_state ().find ("A/hello" DVSUFFIX),
                 *fake_folder.current_remote_state ().find ("A/hello" DVSUFFIX));
        GLib.assert_cmp (*fake_folder.current_local_state ().find ("A/a1"),
                 *fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_cmp (fake_folder.current_local_state ().find ("A/igno" DVSUFFIX).size, 123);

        // Now disable vfs and check that all files are still there
        on_signal_cleanup ();
        SyncEngine.wipe_virtual_files (fake_folder.local_path (), fake_folder.sync_journal (), *vfs);
        fake_folder.switch_to_vfs (unowned<Vfs> (new VfsOff));
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (fake_folder.current_local_state ().find ("A/a1" DVSUFFIX).size, 111);
        GLib.assert_cmp (fake_folder.current_local_state ().find ("A/hello").size, 12);
        GLib.assert_cmp (fake_folder.current_local_state ().find ("A/hello" DVSUFFIX).size, 222);
        GLib.assert_cmp (fake_folder.current_local_state ().find ("A/igno" DVSUFFIX).size, 123);
    }
}

QTEST_GUILESS_MAIN (TestSyncVirtualFiles)
