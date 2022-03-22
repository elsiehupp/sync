/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestParentsGetWarningForError : AbstractTestSyncFileStatusTracker {

    /***********************************************************
    ***********************************************************/
    private TestParentsGetWarningForError () {
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
        status_spy == "";

        fake_folder.exec_until_finished ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusError);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A/a2") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("B/b0") == SyncFileStatus.StatusError);
        status_spy == "";

        // Remove the error and start a second sync, the blocklist should kick in
        fake_folder.server_error_paths () == "";
        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        // A/a1 and B/b0 should be on the block list for the next few seconds
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusError);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("B/b0") == SyncFileStatus.StatusError);
        status_spy == "";
        fake_folder.exec_until_finished ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusError);
        GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A/a2") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusWarning);
        GLib.assert_true (status_spy.status_of ("B/b0") == SyncFileStatus.StatusError);
        status_spy == "";

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
        status_spy == "";
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
        status_spy == "";

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
        status_spy == "";
        fake_folder.exec_until_finished ();
        verify_that_push_matches_pull (fake_folder, status_spy);
        GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusUpToDate);
        GLib.assert_true (status_spy.status_of ("B/b0") == SyncFileStatus.StatusUpToDate);

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }

} // class TestParentsGetWarningForError

} // namespace Testing
} // namespace Occ
