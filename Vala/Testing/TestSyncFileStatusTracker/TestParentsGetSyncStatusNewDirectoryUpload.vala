/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestParentsGetSyncStatusNewDirectoryUpload : AbstractTestSyncFileStatusTracker {

    /***********************************************************
    ***********************************************************/
    private TestParentsGetSyncStatusNewDirectoryUpload () {
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

} // class TestParentsGetSyncStatusNewDirectoryUpload

} // namespace Testing
} // namespace Occ
