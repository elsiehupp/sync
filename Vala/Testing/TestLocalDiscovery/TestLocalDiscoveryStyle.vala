namespace Occ {
namespace Testing {

/***********************************************************
@class TestLocalDiscoveryStyle

@brief Check correct behavior when local discovery is
partially drawn from the database.

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestLocalDiscoveryStyle : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestLocalDiscoveryStyle () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        LocalDiscoveryTracker tracker;
        fake_folder.sync_engine.signal_item_completed.connect (
            tracker.on_signal_item_completed
        );
        fake_folder.sync_engine.signal_finished.connect (
            tracker.on_signal_sync_finished
        );

        // More subdirectories are useful for testing
        fake_folder.local_modifier.mkdir ("A/X");
        fake_folder.local_modifier.mkdir ("A/Y");
        fake_folder.local_modifier.insert ("A/X/x1");
        fake_folder.local_modifier.insert ("A/Y/y1");
        tracker.add_touched_path ("A/X");

        tracker.start_sync_full_discovery ();
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (tracker.local_discovery_paths ().empty ());

        // Test begins
        fake_folder.local_modifier.insert ("A/a3");
        fake_folder.local_modifier.insert ("A/X/x2");
        fake_folder.local_modifier.insert ("A/Y/y2");
        fake_folder.local_modifier.insert ("B/b3");
        fake_folder.remote_modifier ().insert ("C/c3");
        fake_folder.remote_modifier ().append_byte ("C/c1");
        tracker.add_touched_path ("A/X");

        fake_folder.sync_engine.set_local_discovery_options (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.local_discovery_paths ());

        tracker.start_sync_partial_discovery ();
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a3"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/X/x2"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/Y/y2"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("B/b3"));
        GLib.assert_true (fake_folder.current_local_state ().find ("C/c3"));
        GLib.assert_true (fake_folder.sync_engine.last_local_discovery_style () == LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM);
        GLib.assert_true (tracker.local_discovery_paths ().empty ());

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.sync_engine.last_local_discovery_style () == LocalDiscoveryStyle.FILESYSTEM_ONLY);
        GLib.assert_true (tracker.local_discovery_paths ().empty ());
    }

} // class TestLocalDiscoveryStyle

} // namespace Testing
} // namespace Occ
