/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public abstract class TestParentsGetSyncStatusUploadDownload : AbstractTestSyncFileStatusTracker {

    /***********************************************************
    ***********************************************************/
    private TestParentsGetSyncStatusUploadDownload () {
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

} // class TestParentsGetSyncStatusUploadDownload

} // namespace Testing
} // namespace Occ
