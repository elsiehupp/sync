/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using Occ;

namespace Testing {

public class TestSyncXAttr : GLib.Object {

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

        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        var on_signal_cleanup = () => {
            complete_spy.clear ();
            if (!do_local_discovery) {
                fake_folder.sync_engine ().set_local_discovery_options (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM);
            }
        }
        on_signal_cleanup ();

        // Create a virtual file for a new remote file
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/a1", 64);
        var some_date = GLib.DateTime (QDate (1984, 07, 30), QTime (1,3,2));
        fake_folder.remote_modifier ().set_modification_time ("A/a1", some_date);
        GLib.assert_true (fake_folder.sync_once ());
        xaverify_virtual (fake_folder, "A/a1");
        GLib.assert_true (database_record (fake_folder, "A/a1").file_size == 64);
        GLib.assert_true (new FileInfo (fake_folder.local_path () + "A/a1").last_modified () == some_date);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (item_instruction (complete_spy, "A/a1", SyncInstructions.NEW));
        on_signal_cleanup ();

        // Another sync doesn't actually lead to changes
        GLib.assert_true (fake_folder.sync_once ());
        xaverify_virtual (fake_folder, "A/a1");
        GLib.assert_true (database_record (fake_folder, "A/a1").file_size == 64);
        GLib.assert_true (new FileInfo (fake_folder.local_path () + "A/a1").last_modified () == some_date);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (complete_spy == "");
        on_signal_cleanup ();

        // Not even when the remote is rediscovered
        fake_folder.sync_journal ().force_remote_discovery_next_sync ();
        GLib.assert_true (fake_folder.sync_once ());
        xaverify_virtual (fake_folder, "A/a1");
        GLib.assert_true (database_record (fake_folder, "A/a1").file_size == 64);
        GLib.assert_true (new FileInfo (fake_folder.local_path () + "A/a1").last_modified () == some_date);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (complete_spy == "");
        on_signal_cleanup ();

        // Neither does a remote change
        fake_folder.remote_modifier ().append_byte ("A/a1");
        GLib.assert_true (fake_folder.sync_once ());
        xaverify_virtual (fake_folder, "A/a1");
        GLib.assert_true (database_record (fake_folder, "A/a1").file_size == 65);
        GLib.assert_true (new FileInfo (fake_folder.local_path () + "A/a1").last_modified () == some_date);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (item_instruction (complete_spy, "A/a1", SyncInstructions.UPDATE_METADATA));
        GLib.assert_true (database_record (fake_folder, "A/a1").file_size == 65);
        on_signal_cleanup ();

        // If the local virtual file is removed, this will be propagated remotely
        if (!do_local_discovery)
            fake_folder.sync_engine ().set_local_discovery_options (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A" });
        fake_folder.local_modifier ().remove ("A/a1");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (item_instruction (complete_spy, "A/a1", SyncInstructions.REMOVE));
        GLib.assert_true (!database_record (fake_folder, "A/a1").is_valid ());
        on_signal_cleanup ();

        // Recreate a1 before carrying on with the other tests
        fake_folder.remote_modifier ().insert ("A/a1", 65);
        fake_folder.remote_modifier ().set_modification_time ("A/a1", some_date);
        GLib.assert_true (fake_folder.sync_once ());
        xaverify_virtual (fake_folder, "A/a1");
        GLib.assert_true (database_record (fake_folder, "A/a1").file_size == 65);
        GLib.assert_true (new FileInfo (fake_folder.local_path () + "A/a1").last_modified () == some_date);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (item_instruction (complete_spy, "A/a1", SyncInstructions.NEW));
        on_signal_cleanup ();

        // Remote rename is propagated
        fake_folder.remote_modifier ().rename ("A/a1", "A/a1m");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!new FileInfo (fake_folder.local_path () + "A/a1").exists ());
        xaverify_virtual (fake_folder, "A/a1m");
        GLib.assert_true (database_record (fake_folder, "A/a1m").file_size == 65);
        GLib.assert_true (new FileInfo (fake_folder.local_path () + "A/a1m").last_modified () == some_date);
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1m"));
        GLib.assert_true (
            item_instruction (complete_spy, "A/a1m", SyncInstructions.RENAME)
            || (item_instruction (complete_spy, "A/a1m", SyncInstructions.NEW)
                && item_instruction (complete_spy, "A/a1", SyncInstructions.REMOVE)));
        GLib.assert_true (!database_record (fake_folder, "A/a1").is_valid ());
        on_signal_cleanup ();

        // Remote remove is propagated
        fake_folder.remote_modifier ().remove ("A/a1m");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path () + "A/a1m").exists ());
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a1m"));
        GLib.assert_true (item_instruction (complete_spy, "A/a1m", SyncInstructions.REMOVE));
        GLib.assert_true (!database_record (fake_folder, "A/a1").is_valid ());
        GLib.assert_true (!database_record (fake_folder, "A/a1m").is_valid ());
        on_signal_cleanup ();

        // Edge case : Local virtual file but no database entry for some reason
        fake_folder.remote_modifier ().insert ("A/a2", 32);
        fake_folder.remote_modifier ().insert ("A/a3", 33);
        GLib.assert_true (fake_folder.sync_once ());
        xaverify_virtual (fake_folder, "A/a2");
        GLib.assert_true (database_record (fake_folder, "A/a2").file_size == 32);
        xaverify_virtual (fake_folder, "A/a3");
        GLib.assert_true (database_record (fake_folder, "A/a3").file_size == 33);
        on_signal_cleanup ();

        fake_folder.sync_engine ().journal ().delete_file_record ("A/a2");
        fake_folder.sync_engine ().journal ().delete_file_record ("A/a3");
        fake_folder.remote_modifier ().remove ("A/a3");
        fake_folder.sync_engine ().set_local_discovery_options (LocalDiscoveryStyle.FILESYSTEM_ONLY);
        GLib.assert_true (fake_folder.sync_once ());
        xaverify_virtual (fake_folder, "A/a2");
        GLib.assert_true (database_record (fake_folder, "A/a2").file_size == 32);
        GLib.assert_true (item_instruction (complete_spy, "A/a2", SyncInstructions.UPDATE_METADATA));
        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path () + "A/a3").exists ());
        GLib.assert_true (item_instruction (complete_spy, "A/a3", SyncInstructions.REMOVE));
        GLib.assert_true (!database_record (fake_folder, "A/a3").is_valid ());
        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_conflict () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        var on_signal_cleanup = () => {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        // Create a virtual file for a new remote file
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/a1", 11);
        fake_folder.remote_modifier ().insert ("A/a2", 12);
        fake_folder.remote_modifier ().mkdir ("B");
        fake_folder.remote_modifier ().insert ("B/b1", 21);
        GLib.assert_true (fake_folder.sync_once ());
        xaverify_virtual (fake_folder, "A/a1");
        xaverify_virtual (fake_folder, "A/a2");
        xaverify_virtual (fake_folder, "B/b1");
        GLib.assert_true (database_record (fake_folder, "A/a1").file_size == 11);
        GLib.assert_true (database_record (fake_folder, "A/a2").file_size == 12);
        GLib.assert_true (database_record (fake_folder, "B/b1").file_size == 21);
        on_signal_cleanup ();

        // All the files are touched on the server
        fake_folder.remote_modifier ().append_byte ("A/a1");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        fake_folder.remote_modifier ().append_byte ("B/b1");

        // A : the correct file and a conflicting file are added
        // B : user adds a directory* locally
        fake_folder.local_modifier ().remove ("A/a1");
        fake_folder.local_modifier ().insert ("A/a1", 12);
        fake_folder.local_modifier ().remove ("A/a2");
        fake_folder.local_modifier ().insert ("A/a2", 10);
        fake_folder.local_modifier ().remove ("B/b1");
        fake_folder.local_modifier ().mkdir ("B/b1");
        fake_folder.local_modifier ().insert ("B/b1/foo");
        GLib.assert_true (fake_folder.sync_once ());

        // Everything is CONFLICT
        GLib.assert_true (item_instruction (complete_spy, "A/a1", SyncInstructions.CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "A/a2", SyncInstructions.CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "B/b1", SyncInstructions.CONFLICT));

        // conflict files should exist
        GLib.assert_true (fake_folder.sync_journal ().conflict_record_paths ().size () == 2);

        // nothing should have the virtual file tag
        xaverify_nonvirtual (fake_folder, "A/a1");
        xaverify_nonvirtual (fake_folder, "A/a2");
        xaverify_nonvirtual (fake_folder, "B/b1");

        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_with_normal_sync () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        var on_signal_cleanup = () => {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        // No effect sync
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        on_signal_cleanup ();

        // Existing files are propagated just fine in both directions
        fake_folder.local_modifier ().append_byte ("A/a1");
        fake_folder.local_modifier ().insert ("A/a3");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        on_signal_cleanup ();

        // New files on the remote create virtual files
        fake_folder.remote_modifier ().insert ("A/new", 42);
        GLib.assert_true (fake_folder.sync_once ());
        xaverify_virtual (fake_folder, "A/new");
        GLib.assert_true (database_record (fake_folder, "A/new").file_size == 42);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/new"));
        GLib.assert_true (item_instruction (complete_spy, "A/new", SyncInstructions.NEW));
        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_download () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        var on_signal_cleanup = () => {
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

        xaverify_virtual (fake_folder, "A/a1");
        xaverify_virtual (fake_folder, "A/a2");
        xaverify_virtual (fake_folder, "A/a3");
        xaverify_virtual (fake_folder, "A/a4");
        xaverify_virtual (fake_folder, "A/a5");
        xaverify_virtual (fake_folder, "A/a6");
        xaverify_virtual (fake_folder, "A/a7");
        xaverify_virtual (fake_folder, "A/b1");
        xaverify_virtual (fake_folder, "A/b2");
        xaverify_virtual (fake_folder, "A/b3");
        xaverify_virtual (fake_folder, "A/b4");

        on_signal_cleanup ();

        // Download by changing the database entry
        trigger_download (fake_folder, "A/a1");
        trigger_download (fake_folder, "A/a2");
        trigger_download (fake_folder, "A/a3");
        trigger_download (fake_folder, "A/a4");
        trigger_download (fake_folder, "A/a5");
        trigger_download (fake_folder, "A/a6");
        trigger_download (fake_folder, "A/a7");
        trigger_download (fake_folder, "A/b1");
        trigger_download (fake_folder, "A/b2");
        trigger_download (fake_folder, "A/b3");
        trigger_download (fake_folder, "A/b4");

        // Remote complications
        fake_folder.remote_modifier ().append_byte ("A/a2");
        fake_folder.remote_modifier ().remove ("A/a3");
        fake_folder.remote_modifier ().rename ("A/a4", "A/a4m");
        fake_folder.remote_modifier ().append_byte ("A/b2");
        fake_folder.remote_modifier ().remove ("A/b3");
        fake_folder.remote_modifier ().rename ("A/b4", "A/b4m");

        // Local complications
        fake_folder.local_modifier ().remove ("A/a5");
        fake_folder.local_modifier ().insert ("A/a5");
        fake_folder.local_modifier ().remove ("A/a6");
        fake_folder.local_modifier ().insert ("A/a6");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/a1", SyncInstructions.SYNC));
        GLib.assert_true (complete_spy.find_item ("A/a1").type == ItemType.VIRTUAL_FILE_DOWNLOAD);
        GLib.assert_true (item_instruction (complete_spy, "A/a2", SyncInstructions.SYNC));
        GLib.assert_true (complete_spy.find_item ("A/a2").type == ItemType.VIRTUAL_FILE_DOWNLOAD);
        GLib.assert_true (item_instruction (complete_spy, "A/a3", SyncInstructions.REMOVE));
        GLib.assert_true (item_instruction (complete_spy, "A/a4m", SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "A/a4", SyncInstructions.REMOVE));
        GLib.assert_true (item_instruction (complete_spy, "A/a5", SyncInstructions.CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "A/a6", SyncInstructions.CONFLICT));
        GLib.assert_true (item_instruction (complete_spy, "A/a7", SyncInstructions.SYNC));
        GLib.assert_true (item_instruction (complete_spy, "A/b1", SyncInstructions.SYNC));
        GLib.assert_true (item_instruction (complete_spy, "A/b2", SyncInstructions.SYNC));
        GLib.assert_true (item_instruction (complete_spy, "A/b3", SyncInstructions.REMOVE));
        GLib.assert_true (item_instruction (complete_spy, "A/b4m", SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "A/b4", SyncInstructions.REMOVE));

        xaverify_nonvirtual (fake_folder, "A/a1");
        xaverify_nonvirtual (fake_folder, "A/a2");
        cfverify_gone (fake_folder, "A/a3");
        cfverify_gone (fake_folder, "A/a4");
        xaverify_nonvirtual (fake_folder, "A/a4m");
        xaverify_nonvirtual (fake_folder, "A/a5");
        xaverify_nonvirtual (fake_folder, "A/a6");
        xaverify_nonvirtual (fake_folder, "A/a7");
        xaverify_nonvirtual (fake_folder, "A/b1");
        xaverify_nonvirtual (fake_folder, "A/b2");
        cfverify_gone (fake_folder, "A/b3");
        cfverify_gone (fake_folder, "A/b4");
        xaverify_nonvirtual (fake_folder, "A/b4m");

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_download_resume () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        var on_signal_cleanup = () => {
            complete_spy.clear ();
            fake_folder.sync_journal ().wipe_error_blocklist ();
        }
        on_signal_cleanup ();

        // Create a virtual file for remote files
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/a1");
        GLib.assert_true (fake_folder.sync_once ());
        xaverify_virtual (fake_folder, "A/a1");
        on_signal_cleanup ();

        // Download by changing the database entry
        trigger_download (fake_folder, "A/a1");
        fake_folder.server_error_paths ().append ("A/a1", 500);
        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/a1", SyncInstructions.SYNC));
        GLib.assert_true (xattr.has_nextcloud_placeholder_attributes (fake_folder.local_path () + "A/a1"));
        GLib.assert_true (new FileInfo (fake_folder.local_path () + "A/a1").exists ());
        GLib.assert_true (database_record (fake_folder, "A/a1").type == ItemType.VIRTUAL_FILE_DOWNLOAD);
        on_signal_cleanup ();

        fake_folder.server_error_paths ().clear ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (item_instruction (complete_spy, "A/a1", SyncInstructions.SYNC));
        xaverify_nonvirtual (fake_folder, "A/a1");
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_new_files_not_virtual () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/a1");
        GLib.assert_true (fake_folder.sync_once ());
        xaverify_virtual (fake_folder, "A/a1");

        fake_folder.sync_journal ().internal_pin_states ().set_for_path ("", PinState.PinState.ALWAYS_LOCAL);

        // Create a new remote file, it'll not be virtual
        fake_folder.remote_modifier ().insert ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());

        xaverify_nonvirtual (fake_folder, "A/a2");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_download_recursive () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

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

        xaverify_virtual (fake_folder, "A/a1");
        xaverify_virtual (fake_folder, "A/a2");
        xaverify_virtual (fake_folder, "A/Sub/a3");
        xaverify_virtual (fake_folder, "A/Sub/a4");
        xaverify_virtual (fake_folder, "A/Sub/SubSub/a5");
        xaverify_virtual (fake_folder, "A/Sub2/a6");
        xaverify_virtual (fake_folder, "B/b1");
        xaverify_virtual (fake_folder, "B/Sub/b2");

        // Download All file in the directory A/Sub
        // (as in Folder.download_virtual_file)
        fake_folder.sync_journal ().mark_virtual_file_for_download_recursively ("A/Sub");

        GLib.assert_true (fake_folder.sync_once ());

        xaverify_virtual (fake_folder, "A/a1");
        xaverify_virtual (fake_folder, "A/a2");
        xaverify_nonvirtual (fake_folder, "A/Sub/a3");
        xaverify_nonvirtual (fake_folder, "A/Sub/a4");
        xaverify_nonvirtual (fake_folder, "A/Sub/SubSub/a5");
        xaverify_virtual (fake_folder, "A/Sub2/a6");
        xaverify_virtual (fake_folder, "B/b1");
        xaverify_virtual (fake_folder, "B/Sub/b2");

        // Add a file in a subfolder that was downloaded
        // Currently, this continue to add it as a virtual file.
        fake_folder.remote_modifier ().insert ("A/Sub/SubSub/a7");
        GLib.assert_true (fake_folder.sync_once ());

        xaverify_virtual (fake_folder, "A/Sub/SubSub/a7");

        // Now download all files in "A"
        fake_folder.sync_journal ().mark_virtual_file_for_download_recursively ("A");
        GLib.assert_true (fake_folder.sync_once ());

        xaverify_nonvirtual (fake_folder, "A/a1");
        xaverify_nonvirtual (fake_folder, "A/a2");
        xaverify_nonvirtual (fake_folder, "A/Sub/a3");
        xaverify_nonvirtual (fake_folder, "A/Sub/a4");
        xaverify_nonvirtual (fake_folder, "A/Sub/SubSub/a5");
        xaverify_nonvirtual (fake_folder, "A/Sub/SubSub/a7");
        xaverify_nonvirtual (fake_folder, "A/Sub2/a6");
        xaverify_virtual (fake_folder, "B/b1");
        xaverify_virtual (fake_folder, "B/Sub/b2");

        // Now download remaining files in "B"
        fake_folder.sync_journal ().mark_virtual_file_for_download_recursively ("B");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_rename_virtual () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        var on_signal_cleanup = () => {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        fake_folder.remote_modifier ().insert ("file1", 128, 'C');
        fake_folder.remote_modifier ().insert ("file2", 256, 'C');
        fake_folder.remote_modifier ().insert ("file3", 256, 'C');
        GLib.assert_true (fake_folder.sync_once ());

        xaverify_virtual (fake_folder, "file1");
        xaverify_virtual (fake_folder, "file2");
        xaverify_virtual (fake_folder, "file3");

        on_signal_cleanup ();

        fake_folder.local_modifier ().rename ("file1", "renamed1");
        fake_folder.local_modifier ().rename ("file2", "renamed2");
        trigger_download (fake_folder, "file2");
        trigger_download (fake_folder, "file3");
        GLib.assert_true (fake_folder.sync_once ());

        cfverify_gone (fake_folder, "file1");
        xaverify_virtual (fake_folder, "renamed1");

        GLib.assert_true (fake_folder.current_remote_state ().find ("renamed1"));
        GLib.assert_true (item_instruction (complete_spy, "renamed1", SyncInstructions.RENAME));

        // file2 has a conflict between the download request and the rename:
        // the rename wins, the download is ignored

        cfverify_gone (fake_folder, "file2");
        xaverify_virtual (fake_folder, "renamed2");

        GLib.assert_true (fake_folder.current_remote_state ().find ("renamed2"));
        GLib.assert_true (item_instruction (complete_spy, "renamed2", SyncInstructions.RENAME));

        GLib.assert_true (item_instruction (complete_spy, "file3", SyncInstructions.SYNC));
        xaverify_nonvirtual (fake_folder, "file3");
        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_rename_virtual2 () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        var on_signal_cleanup = () => {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        fake_folder.remote_modifier ().insert ("case3", 128, 'C');
        fake_folder.remote_modifier ().insert ("case4", 256, 'C');
        GLib.assert_true (fake_folder.sync_once ());

        trigger_download (fake_folder, "case4");
        GLib.assert_true (fake_folder.sync_once ());

        xaverify_virtual (fake_folder, "case3");
        xaverify_nonvirtual (fake_folder, "case4");

        on_signal_cleanup ();

        // Case 1 : non-virtual, foo . bar (tested elsewhere)
        // Case 2 : virtual, foo . bar (tested elsewhere)

        // Case 3 : virtual, foo.oc . bar.oc (database hydrate)
        fake_folder.local_modifier ().rename ("case3", "case3-rename");
        trigger_download (fake_folder, "case3");

        // Case 4 : non-virtual foo . bar (database dehydrate)
        fake_folder.local_modifier ().rename ("case4", "case4-rename");
        mark_for_dehydration (fake_folder, "case4");

        GLib.assert_true (fake_folder.sync_once ());

        // Case 3 : the rename went though, hydration is forgotten
        cfverify_gone (fake_folder, "case3");
        xaverify_virtual (fake_folder, "case3-rename");
        GLib.assert_true (!fake_folder.current_remote_state ().find ("case3"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("case3-rename"));
        GLib.assert_true (item_instruction (complete_spy, "case3-rename", SyncInstructions.RENAME));

        // Case 4 : the rename went though, dehydration is forgotten
        cfverify_gone (fake_folder, "case4");
        xaverify_nonvirtual (fake_folder, "case4-rename");
        GLib.assert_true (!fake_folder.current_remote_state ().find ("case4"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("case4-rename"));
        GLib.assert_true (item_instruction (complete_spy, "case4-rename", SyncInstructions.RENAME));
    }

    // Dehydration via sync works
    private void on_signal_test_sync_dehydration () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        set_up_vfs (fake_folder);

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        var on_signal_cleanup = () => {
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
            return xattr.has_nextcloud_placeholder_attributes (fake_folder.local_path () + path)
                && GLib.FileInfo (fake_folder.local_path () + path).exists ();
        }
        var has_dehydrated_database_entries = [&] (string path) {
            SyncJournalFileRecord record;
            fake_folder.sync_journal ().get_file_record (path, record);
            return record.is_valid () && record.type == ItemType.VIRTUAL_FILE;
        }

        GLib.assert_true (is_dehydrated ("A/a1"));
        GLib.assert_true (has_dehydrated_database_entries ("A/a1"));
        GLib.assert_true (item_instruction (complete_spy, "A/a1", SyncInstructions.SYNC));
        GLib.assert_true (complete_spy.find_item ("A/a1").type == ItemType.VIRTUAL_FILE_DEHYDRATION);
        GLib.assert_true (complete_spy.find_item ("A/a1").file == "A/a1");
        GLib.assert_true (is_dehydrated ("A/a2"));
        GLib.assert_true (has_dehydrated_database_entries ("A/a2"));
        GLib.assert_true (item_instruction (complete_spy, "A/a2", SyncInstructions.SYNC));
        GLib.assert_true (complete_spy.find_item ("A/a2").type == ItemType.VIRTUAL_FILE_DEHYDRATION);

        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path () + "B/b1").exists ());
        GLib.assert_true (!fake_folder.current_remote_state ().find ("B/b1"));
        GLib.assert_true (item_instruction (complete_spy, "B/b1", SyncInstructions.REMOVE));

        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path () + "B/b2").exists ());
        GLib.assert_true (!fake_folder.current_remote_state ().find ("B/b2"));
        GLib.assert_true (is_dehydrated ("B/b3"));
        GLib.assert_true (has_dehydrated_database_entries ("B/b3"));
        GLib.assert_true (item_instruction (complete_spy, "B/b2", SyncInstructions.REMOVE));
        GLib.assert_true (item_instruction (complete_spy, "B/b3", SyncInstructions.NEW));

        GLib.assert_true (fake_folder.current_remote_state ().find ("C/c1").size == 25);
        GLib.assert_true (item_instruction (complete_spy, "C/c1", SyncInstructions.SYNC));

        GLib.assert_true (fake_folder.current_remote_state ().find ("C/c2").size == 26);
        GLib.assert_true (item_instruction (complete_spy, "C/c2", SyncInstructions.CONFLICT));
        on_signal_cleanup ();

        var expected_remote_state = fake_folder.current_remote_state ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_remote_state () == expected_remote_state);

        GLib.assert_true (is_dehydrated ("A/a1"));
        GLib.assert_true (has_dehydrated_database_entries ("A/a1"));
        GLib.assert_true (is_dehydrated ("A/a2"));
        GLib.assert_true (has_dehydrated_database_entries ("A/a2"));

        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path () + "B/b1").exists ());
        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path () + "B/b2").exists ());
        GLib.assert_true (is_dehydrated ("B/b3"));
        GLib.assert_true (has_dehydrated_database_entries ("B/b3"));

        GLib.assert_true (new FileInfo (fake_folder.local_path () + "C/c1").exists ());
        GLib.assert_true (database_record (fake_folder, "C/c1").is_valid ());
        GLib.assert_true (!is_dehydrated ("C/c1"));
        GLib.assert_true (!has_dehydrated_database_entries ("C/c1"));

        GLib.assert_true (new FileInfo (fake_folder.local_path () + "C/c2").exists ());
        GLib.assert_true (database_record (fake_folder, "C/c2").is_valid ());
        GLib.assert_true (!is_dehydrated ("C/c2"));
        GLib.assert_true (!has_dehydrated_database_entries ("C/c2"));
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

        xaverify_virtual (fake_folder, "f1");
        xaverify_virtual (fake_folder, "A/a1");
        xaverify_virtual (fake_folder, "A/a3");
        xaverify_virtual (fake_folder, "A/B/b1");

        // Make local changes to a3
        fake_folder.local_modifier ().remove ("A/a3");
        fake_folder.local_modifier ().insert ("A/a3", 100);

        // Now wipe the virtuals
        SyncEngine.wipe_virtual_files (fake_folder.local_path (), fake_folder.sync_journal (), *fake_folder.sync_engine ().sync_options ().vfs);

        cfverify_gone (fake_folder, "f1");
        cfverify_gone (fake_folder, "A/a1");
        GLib.assert_true (new FileInfo (fake_folder.local_path () + "A/a3").exists ());
        GLib.assert_true (!database_record (fake_folder, "A/a3").is_valid ());
        cfverify_gone (fake_folder, "A/B/b1");

        fake_folder.switch_to_vfs (unowned<Vfs> (new VfsOff));
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state ().find ("A"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/B"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/B/b1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/B/b2"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a2"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a3"));
        GLib.assert_true (fake_folder.current_local_state ().find ("f1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("f2"));

        // a3 has a conflict
        GLib.assert_true (item_instruction (complete_spy, "A/a3", SyncInstructions.CONFLICT));

        // conflict files should exist
        GLib.assert_true (fake_folder.sync_journal ().conflict_record_paths ().size () == 1);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_new_virtuals () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        var set_pin = (string path, PinState state) => {
            fake_folder.sync_journal ().internal_pin_states ().set_for_path (path, state);
        }

        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("online");
        fake_folder.remote_modifier ().mkdir ("unspec");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        set_pin ("local", PinState.PinState.ALWAYS_LOCAL);
        set_pin ("online", PinState.VfsItemAvailability.ONLINE_ONLY);
        set_pin ("unspec", PinState.PinState.UNSPECIFIED);

        // Test 1 : root is PinState.UNSPECIFIED
        fake_folder.remote_modifier ().insert ("file1");
        fake_folder.remote_modifier ().insert ("online/file1");
        fake_folder.remote_modifier ().insert ("local/file1");
        fake_folder.remote_modifier ().insert ("unspec/file1");
        GLib.assert_true (fake_folder.sync_once ());

        xaverify_virtual (fake_folder, "file1");
        xaverify_virtual (fake_folder, "online/file1");
        xaverify_nonvirtual (fake_folder, "local/file1");
        xaverify_virtual (fake_folder, "unspec/file1");

        // Test 2 : change root to PinState.ALWAYS_LOCAL
        set_pin ("", PinState.PinState.ALWAYS_LOCAL);

        fake_folder.remote_modifier ().insert ("file2");
        fake_folder.remote_modifier ().insert ("online/file2");
        fake_folder.remote_modifier ().insert ("local/file2");
        fake_folder.remote_modifier ().insert ("unspec/file2");
        GLib.assert_true (fake_folder.sync_once ());

        xaverify_nonvirtual (fake_folder, "file2");
        xaverify_virtual (fake_folder, "online/file2");
        xaverify_nonvirtual (fake_folder, "local/file2");
        xaverify_virtual (fake_folder, "unspec/file2");

        // root file1 was hydrated due to its new pin state
        xaverify_nonvirtual (fake_folder, "file1");

        // file1 is unchanged in the explicitly pinned subfolders
        xaverify_virtual (fake_folder, "online/file1");
        xaverify_nonvirtual (fake_folder, "local/file1");
        xaverify_virtual (fake_folder, "unspec/file1");

        // Test 3 : change root to VfsItemAvailability.ONLINE_ONLY
        set_pin ("", PinState.VfsItemAvailability.ONLINE_ONLY);

        fake_folder.remote_modifier ().insert ("file3");
        fake_folder.remote_modifier ().insert ("online/file3");
        fake_folder.remote_modifier ().insert ("local/file3");
        fake_folder.remote_modifier ().insert ("unspec/file3");
        GLib.assert_true (fake_folder.sync_once ());

        xaverify_virtual (fake_folder, "file3");
        xaverify_virtual (fake_folder, "online/file3");
        xaverify_nonvirtual (fake_folder, "local/file3");
        xaverify_virtual (fake_folder, "unspec/file3");

        // root file1 was dehydrated due to its new pin state
        xaverify_virtual (fake_folder, "file1");

        // file1 is unchanged in the explicitly pinned subfolders
        xaverify_virtual (fake_folder, "online/file1");
        xaverify_nonvirtual (fake_folder, "local/file1");
        xaverify_virtual (fake_folder, "unspec/file1");
    }


    private static void set_pin (string path, PinState state) {
        fake_folder.sync_journal ().internal_pin_states ().set_for_path (path, state);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_availability () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        var vfs = set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());


        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("local/sub");
        fake_folder.remote_modifier ().mkdir ("online");
        fake_folder.remote_modifier ().mkdir ("online/sub");
        fake_folder.remote_modifier ().mkdir ("unspec");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

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
        GLib.assert_true (vfs.availability ("file1") == VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);
        GLib.assert_true (vfs.availability ("local") == VfsItemAvailability.PinState.ALWAYS_LOCAL);
        GLib.assert_true (vfs.availability ("local/file1") == VfsItemAvailability.PinState.ALWAYS_LOCAL);
        GLib.assert_true (vfs.availability ("online") == VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_true (vfs.availability ("online/file1") == VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_true (vfs.availability ("unspec") ==  VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);
        GLib.assert_true (vfs.availability ("unspec/file1") == VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);

        // Subitem pin states can ruin "pure" availabilities
        set_pin ("local/sub", PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_true (vfs.availability ("local") == VfsItemAvailability.VfsItemAvailability.ALL_HYDRATED);
        set_pin ("online/sub", PinState.PinState.UNSPECIFIED);
        GLib.assert_true (vfs.availability ("online") == VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);

        trigger_download (fake_folder, "unspec/file1");
        set_pin ("local/file2", PinState.VfsItemAvailability.ONLINE_ONLY);
        set_pin ("online/file2", PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (vfs.availability ("unspec") == VfsItemAvailability.VfsItemAvailability.ALL_HYDRATED);
        GLib.assert_true (vfs.availability ("local") == VfsItemAvailability.VfsItemAvailability.MIXED);
        GLib.assert_true (vfs.availability ("online") == VfsItemAvailability.VfsItemAvailability.MIXED);

        GLib.assert_true (vfs.set_pin_state ("local", PinState.PinState.ALWAYS_LOCAL));
        GLib.assert_true (vfs.set_pin_state ("online", PinState.VfsItemAvailability.ONLINE_ONLY));
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (vfs.availability ("online") == VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_true (vfs.availability ("local") == VfsItemAvailability.PinState.ALWAYS_LOCAL);

        var r = vfs.availability ("nonexistant");
        GLib.assert_true (!r);
        GLib.assert_true (r.error () == Vfs.AvailabilityError.NO_SUCH_ITEM);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_pin_state_locals () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        var vfs = set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("online");
        fake_folder.remote_modifier ().mkdir ("unspec");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        set_pin ("local", PinState.PinState.ALWAYS_LOCAL);
        set_pin ("online", PinState.VfsItemAvailability.ONLINE_ONLY);
        set_pin ("unspec", PinState.PinState.UNSPECIFIED);

        fake_folder.local_modifier ().insert ("file1");
        fake_folder.local_modifier ().insert ("online/file1");
        fake_folder.local_modifier ().insert ("online/file2");
        fake_folder.local_modifier ().insert ("local/file1");
        fake_folder.local_modifier ().insert ("unspec/file1");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // root is unspecified
        GLib.assert_true (vfs.pin_state ("file1") == PinState.PinState.UNSPECIFIED);
        GLib.assert_true (vfs.pin_state ("local/file1") == PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (vfs.pin_state ("online/file1") == PinState.PinState.UNSPECIFIED);
        GLib.assert_true (vfs.pin_state ("unspec/file1") == PinState.PinState.UNSPECIFIED);

        // Sync again : bad pin states of new local files usually take effect on second sync
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // When a file in an online-only folder is renamed, it retains its pin
        fake_folder.local_modifier ().rename ("online/file1", "online/file1rename");
        fake_folder.remote_modifier ().rename ("online/file2", "online/file2rename");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (vfs.pin_state ("online/file1rename") == PinState.PinState.UNSPECIFIED);
        GLib.assert_true (vfs.pin_state ("online/file2rename") == PinState.PinState.UNSPECIFIED);

        // When a folder is renamed, the pin states inside should be retained
        fake_folder.local_modifier ().rename ("online", "onlinerenamed1");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (vfs.pin_state ("onlinerenamed1") == PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_true (vfs.pin_state ("onlinerenamed1/file1rename") == PinState.PinState.UNSPECIFIED);

        fake_folder.remote_modifier ().rename ("onlinerenamed1", "onlinerenamed2");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (vfs.pin_state ("onlinerenamed2") == PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_true (vfs.pin_state ("onlinerenamed2/file1rename") == PinState.PinState.UNSPECIFIED);

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // When a file is deleted and later a new file has the same name, the old pin
        // state isn't preserved.
        GLib.assert_true (vfs.pin_state ("onlinerenamed2/file1rename") == PinState.PinState.UNSPECIFIED);
        fake_folder.remote_modifier ().remove ("onlinerenamed2/file1rename");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (vfs.pin_state ("onlinerenamed2/file1rename") == PinState.VfsItemAvailability.ONLINE_ONLY);
        fake_folder.remote_modifier ().insert ("onlinerenamed2/file1rename");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (vfs.pin_state ("onlinerenamed2/file1rename") == PinState.VfsItemAvailability.ONLINE_ONLY);

        // When a file is hydrated or dehydrated due to pin state it retains its pin state
        GLib.assert_true (vfs.set_pin_state ("onlinerenamed2/file1rename", PinState.PinState.ALWAYS_LOCAL));
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("onlinerenamed2/file1rename"));
        GLib.assert_true (vfs.pin_state ("onlinerenamed2/file1rename") == PinState.PinState.ALWAYS_LOCAL);

        GLib.assert_true (vfs.set_pin_state ("onlinerenamed2", PinState.PinState.UNSPECIFIED));
        GLib.assert_true (vfs.set_pin_state ("onlinerenamed2/file1rename", PinState.VfsItemAvailability.ONLINE_ONLY));
        GLib.assert_true (fake_folder.sync_once ());

        xaverify_virtual (fake_folder, "onlinerenamed2/file1rename");

        GLib.assert_true (vfs.pin_state ("onlinerenamed2/file1rename") == PinState.VfsItemAvailability.ONLINE_ONLY);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_incompatible_pins () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        var vfs = set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("online");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        set_pin ("local", PinState.PinState.ALWAYS_LOCAL);
        set_pin ("online", PinState.VfsItemAvailability.ONLINE_ONLY);

        fake_folder.local_modifier ().insert ("local/file1");
        fake_folder.local_modifier ().insert ("online/file1");
        GLib.assert_true (fake_folder.sync_once ());

        mark_for_dehydration (fake_folder, "local/file1");
        trigger_download (fake_folder, "online/file1");

        // the sync sets the changed files pin states to unspecified
        GLib.assert_true (fake_folder.sync_once ());

        xaverify_nonvirtual (fake_folder, "online/file1");
        xaverify_virtual (fake_folder, "local/file1");
        GLib.assert_true (vfs.pin_state ("online/file1") == PinState.PinState.UNSPECIFIED);
        GLib.assert_true (vfs.pin_state ("local/file1") == PinState.PinState.UNSPECIFIED);

        // no change on another sync
        GLib.assert_true (fake_folder.sync_once ());
        xaverify_nonvirtual (fake_folder, "online/file1");
        xaverify_virtual (fake_folder, "local/file1");
    }


    private static void xaverify_virtual (FakeFolder folder, string path) {
        GLib.assert_true (new FileInfo (folder.local_path () + (path)).exists ());
        GLib.assert_true (new FileInfo (folder.local_path () + (path)).size () == 1);
        GLib.assert_true (xattr.has_nextcloud_placeholder_attributes ( folder.local_path () + (path)));
        GLib.assert_true (database_record (folder, path).is_valid ());
        GLib.assert_true (database_record (folder, path).type == ItemType.VIRTUAL_FILE);
    }


    private static void xaverify_nonvirtual (FakeFolder folder, string path) {
        GLib.assert_true (new FileInfo (folder.local_path () + (path)).exists ());
        GLib.assert_true (!xattr.has_nextcloud_placeholder_attributes ( folder.local_path () + (path)));
        GLib.assert_true (database_record (folder, path).is_valid ());
        GLib.assert_true (database_record (folder, path).type == ItemType.FILE);
    }


    private static void cfverify_gone (FakeFolder folder, string path) {
        GLib.assert_true (!GLib.FileInfo (folder.local_path () + (path)).exists ());
        GLib.assert_true (!database_record (folder, path).is_valid ());
    }


    private static bool item_instruction (ItemCompletedSpy spy, string path, SyncInstructions instr) {
        var item = spy.find_item (path);
        return item.instruction == instr;
    }


    private static SyncJournalFileRecord database_record (FakeFolder folder, string path) {
        SyncJournalFileRecord record;
        folder.sync_journal ().get_file_record (path, record);
        return record;
    }


    private static void trigger_download (FakeFolder folder, string path) {
        var journal = folder.sync_journal ();
        SyncJournalFileRecord record;
        journal.get_file_record (path, record);
        if (!record.is_valid ())
            return;
        record.type = ItemType.VIRTUAL_FILE_DOWNLOAD;
        journal.set_file_record (record);
        journal.schedule_path_for_remote_discovery (record.path);
    }


    private static void mark_for_dehydration (FakeFolder folder, string path) {
        var journal = folder.sync_journal ();
        SyncJournalFileRecord record;
        journal.get_file_record (path, record);
        if (!record.is_valid ())
            return;
        record.type = ItemType.VIRTUAL_FILE_DEHYDRATION;
        journal.set_file_record (record);
        journal.schedule_path_for_remote_discovery (record.path);
    }


    private static Vfs set_up_vfs (FakeFolder folder) {
        var xattr_vfs = unowned<Vfs> (create_vfs_from_plugin (Vfs.XAttr).release ());
        connect (
            folder.sync_engine ().sync_file_status_tracker (),
            SyncFileStatusTracker.file_status_changed,
            xattr_vfs.data (),
            Vfs.file_status_changed
        );
        folder.switch_to_vfs (xattr_vfs);

        // Using this directly doesn't recursively unpin everything and instead leaves
        // the files in the hydration that that they on_signal_start with
        folder.sync_journal ().internal_pin_states ().set_for_path ("", PinState.PinState.UNSPECIFIED);

        return xattr_vfs;
    }

}
}
