/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestChildOkEmittedBeforeParent : AbstractTestSyncFileStatusTracker {

    /***********************************************************
    Even for status pushes immediately following each other,
    macOS can sometimes have 1s delays between updates, so make
    sure that children are marked as OK before their parents do.
    ***********************************************************/
    private TestChildOkEmittedBeforeParent () {
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

} // class TestChildOkEmittedBeforeParent

} // namespace Testing
} // namespace Occ
