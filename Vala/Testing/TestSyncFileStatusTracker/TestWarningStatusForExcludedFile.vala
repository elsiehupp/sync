/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestWarningStatusForExcludedFile : AbstractTestSyncFileStatusTracker {

    /***********************************************************
    ***********************************************************/
    private TestWarningStatusForExcludedFile () {
        //  FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        //  fake_folder.sync_engine.excluded_files ().add_manual_exclude ("A/a1");
        //  fake_folder.sync_engine.excluded_files ().add_manual_exclude ("B");
        //  fake_folder.local_modifier.append_byte ("A/a1");
        //  fake_folder.local_modifier.append_byte ("B/b1");
        //  StatusPushSpy status_spy = new StatusPushSpy (fake_folder.sync_engine);

        //  fake_folder.schedule_sync ();
        //  fake_folder.exec_until_before_propagation ();
        //  verify_that_push_matches_pull (fake_folder, status_spy);
        //  GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusExcluded);
        //  GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusExcluded);
        //  GLib.assert_fail ("", "csync will stop at ignored directories without traversing children, so we don't currently push the status for newly ignored children of an ignored directory.", Continue);
        //  GLib.assert_true (status_spy.status_of ("B/b1") == SyncFileStatus.StatusExcluded);

        //  fake_folder.exec_until_finished ();
        //  verify_that_push_matches_pull (fake_folder, status_spy);
        //  GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusExcluded);
        //  GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusExcluded);
        //  GLib.assert_fail ("", "csync will stop at ignored directories without traversing children, so we don't currently push the status for newly ignored children of an ignored directory.", Continue);
        //  GLib.assert_true (status_spy.status_of ("B/b1") == SyncFileStatus.StatusExcluded);
        //  GLib.assert_fail ("" == "csync will stop at ignored directories without traversing children, so we don't currently push the status for newly ignored children of an ignored directory.", Continue);
        //  GLib.assert_true (status_spy.status_of ("B/b2") == SyncFileStatus.StatusExcluded);
        //  GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status (""), SyncFileStatus.StatusUpToDate);
        //  GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status ("A"), SyncFileStatus.StatusUpToDate);
        //  status_spy = "";

        //  // Clears the exclude expr above
        //  fake_folder.sync_engine.excluded_files ().clear_manual_excludes ();
        //  fake_folder.schedule_sync ();
        //  fake_folder.exec_until_before_propagation ();
        //  GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusSync);
        //  GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusSync);
        //  GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusSync);
        //  GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusSync);
        //  GLib.assert_true (status_spy.status_of ("B/b1") == SyncFileStatus.StatusSync);
        //  status_spy = "";

        //  fake_folder.exec_until_finished ();
        //  verify_that_push_matches_pull (fake_folder, status_spy);
        //  GLib.assert_true (status_spy.status_of ("") == SyncFileStatus.StatusUpToDate);
        //  GLib.assert_true (status_spy.status_of ("A") == SyncFileStatus.StatusUpToDate);
        //  GLib.assert_true (status_spy.status_of ("A/a1") == SyncFileStatus.StatusUpToDate);
        //  GLib.assert_true (status_spy.status_of ("B") == SyncFileStatus.StatusUpToDate);
        //  GLib.assert_true (status_spy.status_of ("B/b1") == SyncFileStatus.StatusUpToDate);

        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }

} // class TestWarningStatusForExcludedFile

} // namespace Testing
} // namespace Occ
