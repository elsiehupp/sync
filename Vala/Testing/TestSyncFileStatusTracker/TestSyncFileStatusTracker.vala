/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>

using Occ;

namespace Testing {

public class TestSyncFileStatusTracker : GLib.Object {

    void verify_that_push_matches_pull (FakeFolder fake_folder, StatusPushSpy status_spy) {
        string root = fake_folder.local_path;
        QDirIterator it = new QDirIterator (root, GLib.Dir.AllEntries | GLib.Dir.NoDotAndDotDot, QDirIterator.Subdirectories);
        while (it.has_next ()) {
            string file_path = it.next ().mid (root.size ());
            SyncFileStatus pushed_status = status_spy.status_of (file_path);
            if (pushed_status != new SyncFileStatus ()) {
                GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status (file_path) == pushed_status);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void parents_get_sync_status_upload_download () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.local_modifier.append_byte ("B/b1");
        fake_folder.remote_modifier ().append_byte ("C/c1");
        StatusPushSpy status_spy = new StatusPushSpy (fake_folder.sync_engine);

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("B/b1") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("C") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("C/c1") == SyncFileStatus.StatusSync);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A/a1") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("B/b2") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("C/c2") == SyncFileStatus.StatusUpToDate);
        status_spy.clear ();

        fake_folder.exec_until_finished ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B/b1") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("C") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("C/c1") == SyncFileStatus.StatusUpToDate);

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void parents_get_sync_status_new_file_upload_download () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.local_modifier.insert ("B/b0");
        fake_folder.remote_modifier ().insert ("C/c0");
        StatusPushSpy status_spy = new StatusPushSpy (fake_folder.sync_engine);

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("B/b0") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("C") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("C/c0") == SyncFileStatus.StatusSync);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A/a1") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("B/b1") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("C/c1") == SyncFileStatus.StatusUpToDate);
        status_spy.clear ();

        fake_folder.exec_until_finished ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B/b0") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("C") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("C/c0") == SyncFileStatus.StatusUpToDate);

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void parents_get_sync_status_new_dir_download () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().mkdir ("D");
        fake_folder.remote_modifier ().insert ("D/d0");
        StatusPushSpy status_spy = new StatusPushSpy (fake_folder.sync_engine);

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("D") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("D/d0") == SyncFileStatus.StatusSync);

        fake_folder.exec_until_item_completed ("D");
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("D") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("D/d0") == SyncFileStatus.StatusSync);

        fake_folder.exec_until_finished ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("D") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("D/d0") == SyncFileStatus.StatusUpToDate);

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void parents_get_sync_status_new_dir_upload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.local_modifier.mkdir ("D");
        fake_folder.local_modifier.insert ("D/d0");
        StatusPushSpy status_spy = new StatusPushSpy (fake_folder.sync_engine);

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("D") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("D/d0") == SyncFileStatus.StatusSync);

        fake_folder.exec_until_item_completed ("D");
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("D") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("D/d0") == SyncFileStatus.StatusSync);

        fake_folder.exec_until_finished ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("D") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("D/d0") == SyncFileStatus.StatusUpToDate);

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void parents_get_sync_status_delete_up_down () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().remove ("B/b1");
        fake_folder.local_modifier.remove ("C/c1");
        StatusPushSpy status_spy = new StatusPushSpy (fake_folder.sync_engine);

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusSync);
        // Discovered as remotely removed, pending for local removal.
        GLib.assert_true (status_spy.status_of ("B/b1") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("C") == SyncFileStatus.StatusSync);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("B/b2") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("C/c2") == SyncFileStatus.StatusUpToDate);
        status_spy.clear ();

        fake_folder.exec_until_finished ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("C") == SyncFileStatus.StatusUpToDate);

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void warning_status_for_excluded_file () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.excluded_files ().add_manual_exclude ("A/a1");
        fake_folder.sync_engine.excluded_files ().add_manual_exclude ("B");
        fake_folder.local_modifier.append_byte ("A/a1");
        fake_folder.local_modifier.append_byte ("B/b1");
        StatusPushSpy status_spy = new StatusPushSpy (fake_folder.sync_engine);

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusExcluded);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusExcluded);
        GLib.assert_fail ("", "csync will stop at ignored directories without traversing children, so we don't currently push the status for newly ignored children of an ignored directory.", Continue);
        GLib.assert_true (status_spy.status_of ("B/b1") == SyncFileStatus.StatusExcluded);

        fake_folder.exec_until_finished ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusExcluded);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusExcluded);
        GLib.assert_fail ("", "csync will stop at ignored directories without traversing children, so we don't currently push the status for newly ignored children of an ignored directory.", Continue);
        GLib.assert_true (status_spy.status_of ("B/b1") == SyncFileStatus.StatusExcluded);
        GLib.assert_fail ("" == "csync will stop at ignored directories without traversing children, so we don't currently push the status for newly ignored children of an ignored directory.", Continue);
        GLib.assert_true (status_spy.status_of ("B/b2") == SyncFileStatus.StatusExcluded);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status (""), SyncFileStatus.StatusUpToDate);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A"), SyncFileStatus.StatusUpToDate);
        status_spy.clear ();

        // Clears the exclude expr above
        fake_folder.sync_engine.excluded_files ().clear_manual_excludes ();
        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("B/b1") == SyncFileStatus.StatusSync);
        status_spy.clear ();

        fake_folder.exec_until_finished ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B/b1") == SyncFileStatus.StatusUpToDate);

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void warning_status_for_excluded_file_case_preserving () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.excluded_files ().add_manual_exclude ("B");
        fake_folder.server_error_paths ().append ("A/a1");
        fake_folder.local_modifier.append_byte ("A/a1");

        fake_folder.sync_once ();
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("") == SyncFileStatus.StatusWarning);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A") == SyncFileStatus.StatusWarning);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A/a1") == SyncFileStatus.StatusError);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("B") == SyncFileStatus.StatusExcluded);

        // Should still get the status for different casing on macOS and Windows.
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("a") == Utility.filesystem_case_preserving () ? SyncFileStatus.StatusWarning : SyncFileStatus.StatusNone);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A/A1") == Utility.filesystem_case_preserving () ? SyncFileStatus.StatusError : SyncFileStatus.StatusNone);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("b") == Utility.filesystem_case_preserving () ? SyncFileStatus.StatusExcluded : SyncFileStatus.StatusNone);
    }


    /***********************************************************
    ***********************************************************/
    private void parents_get_warning_status_for_error () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.server_error_paths ().append ("A/a1");
        fake_folder.server_error_paths ().append ("B/b0");
        fake_folder.local_modifier.append_byte ("A/a1");
        fake_folder.local_modifier.insert ("B/b0");
        StatusPushSpy status_spy = new StatusPushSpy (fake_folder.sync_engine);

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("B/b0") == SyncFileStatus.StatusSync);
        status_spy.clear ();

        fake_folder.exec_until_finished ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusError);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A/a2") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("B/b0") == SyncFileStatus.StatusError);
        status_spy.clear ();

        // Remove the error and start a second sync, the blocklist should kick in
        fake_folder.server_error_paths ().clear ();
        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        // A/a1 and B/b0 should be on the block list for the next few seconds
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusError);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("B/b0") == SyncFileStatus.StatusError);
        status_spy.clear ();
        fake_folder.exec_until_finished ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusError);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A/a2") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("B/b0") == SyncFileStatus.StatusError);
        status_spy.clear ();

        // Start a third sync, this time together with a real file to sync
        fake_folder.local_modifier.append_byte ("C/c1");
        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        // The root should show SYNC even though there is an error underneath,
        // since C/c1 is syncing and the SYNC status has priority.
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusError);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("B/b0") == SyncFileStatus.StatusError);
        GLib.assert_true (status_spy.status_of ("C") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("C/c1") == SyncFileStatus.StatusSync);
        status_spy.clear ();
        fake_folder.exec_until_finished ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusError);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A/a2") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("B/b0") == SyncFileStatus.StatusError);
        GLib.assert_true (status_spy.status_of ("C") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("C/c1") == SyncFileStatus.StatusUpToDate);
        status_spy.clear ();

        // Another sync after clearing the blocklist entry, everything should return to order.
        fake_folder.sync_engine.journal.wipe_error_blocklist_entry ("A/a1");
        fake_folder.sync_engine.journal.wipe_error_blocklist_entry ("B/b0");
        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("B/b0") == SyncFileStatus.StatusSync);
        status_spy.clear ();
        fake_folder.exec_until_finished ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B/b0") == SyncFileStatus.StatusUpToDate);

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void parents_get_warning_status_for_error__sibling_starts_with_path {
        // A is a parent of A/a1, but A/a is not even if it's a substring of A/a1
        FakeFolder fake_folder = new FakeFolder (
            {
                "", {
                    {
                        "A", {
                            {
                                "a", 4
                            },
                            {
                                "a1", 4
                            }
                        }
                    }
                }
            }
        );
        fake_folder.server_error_paths ().append ("A/a1");
        fake_folder.local_modifier.append_byte ("A/a1");

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        // The SyncFileStatusTraker won't push any status for all of them, test with a pull.
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("") == SyncFileStatus.StatusSync);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A") == SyncFileStatus.StatusSync);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A/a1") == SyncFileStatus.StatusSync);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A/a") == SyncFileStatus.StatusUpToDate);

        fake_folder.exec_until_finished ();
        // We use string matching for paths in the implementation,
        // an error should affect only parents and not every path that starts with the problem path.
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("") == SyncFileStatus.StatusWarning);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A") == SyncFileStatus.StatusWarning);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A/a1") == SyncFileStatus.StatusError);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A/a") == SyncFileStatus.StatusUpToDate);
    }


    /***********************************************************
    Even for status pushes immediately following each other,
    macOS can sometimes have 1s delays between updates, so make
    sure that children are marked as OK before their parents do.
    ***********************************************************/
    private void child_ok_emitted_before_parent () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.local_modifier.append_byte ("B/b1");
        fake_folder.remote_modifier ().append_byte ("C/c1");
        StatusPushSpy status_spy = new StatusPushSpy (fake_folder.sync_engine);

        fake_folder.sync_once ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_emitted_before ("B/b1", "B"));
        GLib.assert_true (status_spy.status_emitted_before ("C/c1", "C"));
        GLib.assert_true (status_spy.status_emitted_before ("B", ""));
        GLib.assert_true (status_spy.status_emitted_before ("C", ""));
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B/b1") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("C") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("C/c1") == SyncFileStatus.StatusUpToDate);
    }


    /***********************************************************
    ***********************************************************/
    private void shared_status () {
        SyncFileStatus shared_up_to_date_status = SyncFileStatus.StatusUpToDate;
        shared_up_to_date_status.set_shared (true);

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().insert ("S/s0");
        fake_folder.remote_modifier ().append_byte ("S/s1");
        fake_folder.remote_modifier ().insert ("B/b3");
        fake_folder.remote_modifier ().find ("B/b3").extra_dav_properties = "<oc:share-types><oc:share-type>0</oc:share-type></oc:share-types>";
        fake_folder.remote_modifier ().find ("A/a1").is_shared = true; // becomes shared
        fake_folder.remote_modifier ().find ("A", true); // change the etags of the parent

        StatusPushSpy status_spy = new StatusPushSpy (fake_folder.sync_engine);

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusSync);
        // We don't care about the shared flag for the sync status,
        // Mac and Windows won't show it and we can't know it for new files.
        GLib.assert_true (status_spy.status_of ("S").tag () == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("S/s0").tag () == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("S/s1").tag () == SyncFileStatus.StatusSync);

        fake_folder.exec_until_finished ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("S") == shared_up_to_date_status);
        GLib.assert_fail ("", "We currently only know if a new file is shared on the second sync, after a PROPFIND.", Continue);
        GLib.assert_true (status_spy.status_of ("S/s0") == shared_up_to_date_status);
        GLib.assert_true (status_spy.status_of ("S/s1") == shared_up_to_date_status);
        GLib.assert_true (status_spy.status_of ("B/b1").shared () == false);
        GLib.assert_true (status_spy.status_of ("B/b3") == shared_up_to_date_status);
        GLib.assert_true (status_spy.status_of ("A/a1") == shared_up_to_date_status);

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void rename_error () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.server_error_paths ().append ("A/a1");
        fake_folder.local_modifier.rename ("A/a1", "A/a1m");
        fake_folder.local_modifier.rename ("B/b1", "B/b1m");
        StatusPushSpy status_spy = new StatusPushSpy (fake_folder.sync_engine);

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();

        verify_that_push_matches_pull (fake_folder, status_spy);

        GLib.assert_true (status_spy.status_of ("A/a1m") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("A/a1") == status_spy.status_of ("A/a1notexist"));
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusSync);
        GLib.assert_true (status_spy.status_of ("B/b1m") == SyncFileStatus.StatusSync);

        fake_folder.exec_until_finished ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("A/a1m") == SyncFileStatus.StatusError);
        GLib.assert_true (status_spy.status_of ("A/a1") == status_spy.status_of ("A/a1notexist"));
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B/b1m") == SyncFileStatus.StatusUpToDate);
        status_spy.clear ();

        GLib.assert_true (!fake_folder.sync_once ());
        verify_that_push_matches_pull (fake_folder, status_spy);
        status_spy.clear ();
        GLib.assert_true (!fake_folder.sync_once ());
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("A/a1m") == SyncFileStatus.StatusError);
        GLib.assert_true (status_spy.status_of ("A/a1") == status_spy.status_of ("A/a1notexist"));
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusNone);
        GLib.assert_true (status_spy.status_of ("B/b1m") == SyncFileStatus.StatusNone);
        status_spy.clear ();
    }

}
}
