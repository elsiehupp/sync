/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public abstract class TestSharedStatus : AbstractTestSyncFileStatusTracker {

    /***********************************************************
    ***********************************************************/
    private TestSharedStatus () {
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

} // class TestSharedStatus

} // namespace Testing
} // namespace Occ
