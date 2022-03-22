namespace Occ {
namespace Testing {

/***********************************************************
@class TestTrackerItemCompletion

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestTrackerItemCompletion : GLib.Object {

    /***********************************************************
    Check whether item on_signal_success and item failure
    adjusts the tracker correctly.
    ***********************************************************/
    private TestTrackerItemCompletion () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        LocalDiscoveryTracker tracker;
        fake_folder.sync_engine.signal_item_completed.connect (
            tracker.on_signal_item_completed
        );
        fake_folder.sync_engine.signal_finished.connect (
            tracker.on_signal_sync_finished
        );

        tracker.add_touched_path ("A/spurious");

        fake_folder.local_modifier.insert ("A/a3");
        tracker.add_touched_path ("A/a3");

        fake_folder.local_modifier.insert ("A/a4");
        fake_folder.server_error_paths ().append ("A/a4");
        // We're not adding a4 as touched, it's in the same folder as a3 and will be seen.
        // And due to the error it should be added to the explicit list while a3 gets removed.

        fake_folder.sync_engine.set_local_discovery_options (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.local_discovery_paths ());
        tracker.start_sync_partial_discovery ();
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a3"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a4"));
        GLib.assert_true (!tracker_contains ("A/a3"));
        GLib.assert_true (tracker_contains ("A/a4"));
        GLib.assert_true (tracker_contains ("A/spurious")); // not removed since overall sync not successful

        fake_folder.sync_engine.set_local_discovery_options (LocalDiscoveryStyle.FILESYSTEM_ONLY);
        tracker.start_sync_full_discovery ();
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a4"));
        GLib.assert_true (tracker_contains ("A/a4")); // had an error, still here
        GLib.assert_true (!tracker_contains ("A/spurious")); // removed due to full discovery

        fake_folder.server_error_paths () == "";
        fake_folder.sync_journal ().wipe_error_blocklist ();
        tracker.add_touched_path ("A/newspurious"); // will be removed due to successful sync

        fake_folder.sync_engine.set_local_discovery_options (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.local_discovery_paths ());
        tracker.start_sync_partial_discovery ();
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a4"));
        GLib.assert_true (tracker.local_discovery_paths ().empty ());
    }


    /***********************************************************
    ***********************************************************/
    private static bool tracker_contains (char path) {
        return tracker.local_discovery_paths ().find (path) != tracker.local_discovery_paths ().end ();
    }

} // class TestTrackerItemCompletion

} // namespace Testing
} // namespace Occ
