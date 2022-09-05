/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestRenameError : AbstractTestSyncFileStatusTracker {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestRenameError () {
    //      FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
    //      fake_folder.server_error_paths ().append ("A/a1");
    //      fake_folder.local_modifier.rename ("A/a1", "A/a1m");
    //      fake_folder.local_modifier.rename ("B/b1", "B/b1m");
    //      StatusPushSpy status_spy = new StatusPushSpy (fake_folder.sync_engine);

    //      fake_folder.schedule_sync ();
    //      fake_folder.exec_until_before_propagation ();

    //      verify_that_push_matches_pull (fake_folder, status_spy);

    //      GLib.assert_true (status_spy.status_of ("A/a1m") == SyncFileStatus.StatusSync);
    //      GLib.assert_true (status_spy.status_of ("A/a1") == status_spy.status_of ("A/a1notexist"));
    //      GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusSync);
    //      GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusSync);
    //      GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusSync);
    //      GLib.assert_true (status_spy.status_of ("B/b1m") == SyncFileStatus.StatusSync);

    //      fake_folder.exec_until_finished ();
    //      verify_that_push_matches_pull (fake_folder, status_spy);
    //      GLib.assert_true (status_spy.status_of ("A/a1m") == SyncFileStatus.StatusError);
    //      GLib.assert_true (status_spy.status_of ("A/a1") == status_spy.status_of ("A/a1notexist"));
    //      GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusWarning);
    //      GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusWarning);
    //      GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusUpToDate);
    //      GLib.assert_true (status_spy.status_of ("B/b1m") == SyncFileStatus.StatusUpToDate);
    //      status_spy = "";

    //      GLib.assert_true (!fake_folder.sync_once ());
    //      verify_that_push_matches_pull (fake_folder, status_spy);
    //      status_spy = "";
    //      GLib.assert_true (!fake_folder.sync_once ());
    //      verify_that_push_matches_pull (fake_folder, status_spy);
    //      GLib.assert_true (status_spy.status_of ("A/a1m") == SyncFileStatus.StatusError);
    //      GLib.assert_true (status_spy.status_of ("A/a1") == status_spy.status_of ("A/a1notexist"));
    //      GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusWarning);
    //      GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusWarning);
    //      GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusNone);
    //      GLib.assert_true (status_spy.status_of ("B/b1m") == SyncFileStatus.StatusNone);
    //      status_spy = "";
    //  }

} // class TestRenameError

} // namespace Testing
} // namespace Occ
