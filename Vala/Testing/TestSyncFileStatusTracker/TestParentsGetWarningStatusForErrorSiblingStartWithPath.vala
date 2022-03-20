/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public abstract class TestParentsGetWarningStatusForErrorSiblingStartWithPath : AbstractTestSyncFileStatusTracker {

    /***********************************************************
    ***********************************************************/
    private TestParentsGetWarningStatusForErrorSiblingStartWithPath () {
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

} // class TestParentsGetWarningStatusForErrorSiblingStartWithPath

} // namespace Testing
} // namespace Occ
