/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestParentsGetSyncStatusNewFileUploadDownload : AbstractTestSyncFileStatusTracker {

    /***********************************************************
    ***********************************************************/
    private TestParentsGetSyncStatusNewFileUploadDownload () {
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

} // class TestParentsGetSyncStatusNewFileUploadDownload

} // namespace Testing
} // namespace Occ
