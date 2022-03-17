/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>
//  #include <localdiscoverytracker.h>

using Occ;

namespace Testing {

public class TestLocalDiscovery : GLib.Object {

    // Check correct behavior when local discovery is partially drawn from the database
    private void test_local_discovery_style () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        LocalDiscoveryTracker tracker;
        connect (&fake_folder.sync_engine (), &SyncEngine.item_completed, tracker, &LocalDiscoveryTracker.slot_item_completed);
        connect (&fake_folder.sync_engine (), &SyncEngine.on_signal_finished, tracker, &LocalDiscoveryTracker.slot_sync_finished);

        // More subdirectories are useful for testing
        fake_folder.local_modifier ().mkdir ("A/X");
        fake_folder.local_modifier ().mkdir ("A/Y");
        fake_folder.local_modifier ().insert ("A/X/x1");
        fake_folder.local_modifier ().insert ("A/Y/y1");
        tracker.add_touched_path ("A/X");

        tracker.start_sync_full_discovery ();
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (tracker.local_discovery_paths ().empty ());

        // Test begins
        fake_folder.local_modifier ().insert ("A/a3");
        fake_folder.local_modifier ().insert ("A/X/x2");
        fake_folder.local_modifier ().insert ("A/Y/y2");
        fake_folder.local_modifier ().insert ("B/b3");
        fake_folder.remote_modifier ().insert ("C/c3");
        fake_folder.remote_modifier ().append_byte ("C/c1");
        tracker.add_touched_path ("A/X");

        fake_folder.sync_engine ().set_local_discovery_options (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.local_discovery_paths ());

        tracker.start_sync_partial_discovery ();
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a3"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/X/x2"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/Y/y2"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("B/b3"));
        GLib.assert_true (fake_folder.current_local_state ().find ("C/c3"));
        GLib.assert_true (fake_folder.sync_engine ().last_local_discovery_style () == LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM);
        GLib.assert_true (tracker.local_discovery_paths ().empty ());

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.sync_engine ().last_local_discovery_style () == LocalDiscoveryStyle.FILESYSTEM_ONLY);
        GLib.assert_true (tracker.local_discovery_paths ().empty ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_local_discovery_decision () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        var engine = fake_folder.sync_engine ();

        GLib.assert_true (engine.should_discover_locally (""));
        GLib.assert_true (engine.should_discover_locally ("A"));
        GLib.assert_true (engine.should_discover_locally ("A/X"));

        fake_folder.sync_engine ().set_local_discovery_options (
            LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A/X", "A/X space", "A/X/beta", "foo bar space/touch", "foo/", "zzz", "zzzz" });

        GLib.assert_true (engine.should_discover_locally (""));
        GLib.assert_true (engine.should_discover_locally ("A"));
        GLib.assert_true (engine.should_discover_locally ("A/X"));
        GLib.assert_true (!engine.should_discover_locally ("B"));
        GLib.assert_true (!engine.should_discover_locally ("A B"));
        GLib.assert_true (!engine.should_discover_locally ("B/X"));
        GLib.assert_true (engine.should_discover_locally ("foo bar space"));
        GLib.assert_true (engine.should_discover_locally ("foo"));
        GLib.assert_true (!engine.should_discover_locally ("foo bar"));
        GLib.assert_true (!engine.should_discover_locally ("foo bar/touch"));
        // These are within "A/X" so they should be discovered
        GLib.assert_true (engine.should_discover_locally ("A/X/alpha"));
        GLib.assert_true (engine.should_discover_locally ("A/X beta"));
        GLib.assert_true (engine.should_discover_locally ("A/X/Y"));
        GLib.assert_true (engine.should_discover_locally ("A/X space"));
        GLib.assert_true (engine.should_discover_locally ("A/X space/alpha"));
        GLib.assert_true (!engine.should_discover_locally ("A/Xylo/foo"));
        GLib.assert_true (engine.should_discover_locally ("zzzz/hello"));
        GLib.assert_true (!engine.should_discover_locally ("zzza/hello"));

        GLib.assert_fail ("", "There is a possibility of false positives if the set contains a path " +
            "which is a prefix, and that prefix is followed by a character less than '/'", Continue);
        GLib.assert_true (!engine.should_discover_locally ("A/X o"));

        fake_folder.sync_engine ().set_local_discovery_options (
            LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, {});

        GLib.assert_true (!engine.should_discover_locally (""));
    }


    /***********************************************************
    Check whether item on_signal_success and item failure
    adjusts the tracker correctly.
    ***********************************************************/
    private void test_tracker_item_completion () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        LocalDiscoveryTracker tracker;
        connect (
            fake_folder.sync_engine (),
            SyncEngine.item_completed,
            tracker,
            LocalDiscoveryTracker.slot_item_completed
        );
        connect (
            fake_folder.sync_engine (),
            SyncEngine.on_signal_finished,
            tracker,
            LocalDiscoveryTracker.slot_sync_finished
        );

        tracker.add_touched_path ("A/spurious");

        fake_folder.local_modifier ().insert ("A/a3");
        tracker.add_touched_path ("A/a3");

        fake_folder.local_modifier ().insert ("A/a4");
        fake_folder.server_error_paths ().append ("A/a4");
        // We're not adding a4 as touched, it's in the same folder as a3 and will be seen.
        // And due to the error it should be added to the explicit list while a3 gets removed.

        fake_folder.sync_engine ().set_local_discovery_options (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.local_discovery_paths ());
        tracker.start_sync_partial_discovery ();
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a3"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a4"));
        GLib.assert_true (!tracker_contains ("A/a3"));
        GLib.assert_true (tracker_contains ("A/a4"));
        GLib.assert_true (tracker_contains ("A/spurious")); // not removed since overall sync not successful

        fake_folder.sync_engine ().set_local_discovery_options (LocalDiscoveryStyle.FILESYSTEM_ONLY);
        tracker.start_sync_full_discovery ();
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a4"));
        GLib.assert_true (tracker_contains ("A/a4")); // had an error, still here
        GLib.assert_true (!tracker_contains ("A/spurious")); // removed due to full discovery

        fake_folder.server_error_paths ().clear ();
        fake_folder.sync_journal ().wipe_error_blocklist ();
        tracker.add_touched_path ("A/newspurious"); // will be removed due to successful sync

        fake_folder.sync_engine ().set_local_discovery_options (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.local_discovery_paths ());
        tracker.start_sync_partial_discovery ();
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a4"));
        GLib.assert_true (tracker.local_discovery_paths ().empty ());
    }


    private bool tracker_contains (char path) {
        return tracker.local_discovery_paths ().find (path) != tracker.local_discovery_paths ().end ();
    }


    /***********************************************************
    ***********************************************************/
    private void test_directory_and_sub_directory () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        fake_folder.local_modifier ().mkdir ("A/new_directory");
        fake_folder.local_modifier ().mkdir ("A/new_directory/sub_directory");
        fake_folder.local_modifier ().insert ("A/new_directory/sub_directory/file", 10);

        var expected_state = fake_folder.current_local_state ();

        // Only "A" was modified according to the file system tracker
        fake_folder.sync_engine ().set_local_discovery_options (
            LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A" });

        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state () == expected_state);
        GLib.assert_true (fake_folder.current_remote_state () == expected_state);
    }


    /***********************************************************
    Tests the behavior of invalid filename detection
    ***********************************************************/
    private void test_server_blocklist () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        fake_folder.sync_engine ().account.set_capabilities (
            { { "files", new QVariantMap ( { "blocklisted_files", new QVariantList ( ".foo", "bar" ) } ) } });
        fake_folder.local_modifier ().insert ("C/.foo");
        fake_folder.local_modifier ().insert ("C/bar");
        fake_folder.local_modifier ().insert ("C/moo");
        fake_folder.local_modifier ().insert ("C/.moo");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("C/moo"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("C/.moo"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("C/.foo"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("C/bar"));
    }


    /***********************************************************
    ***********************************************************/
    private void test_create_file_with_trailing_spaces_local_and_remote_trimmed_do_not_exist_rename_and_upload_file () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        const string file_with_spaces_1 = " foo";
        const string file_with_spaces_2 = " bar  ";
        const string file_with_spaces_3 = "bla ";
        const string file_with_spaces_4 = "A/ foo";
        const string file_with_spaces_5 = "A/ bar  ";
        const string file_with_spaces_6 = "A/bla ";

        fake_folder.local_modifier ().insert (file_with_spaces_1);
        fake_folder.local_modifier ().insert (file_with_spaces_2);
        fake_folder.local_modifier ().insert (file_with_spaces_3);
        fake_folder.local_modifier ().insert (file_with_spaces_4);
        fake_folder.local_modifier ().insert (file_with_spaces_5);
        fake_folder.local_modifier ().insert (file_with_spaces_6);

        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find (file_with_spaces_1.trimmed ()));
        GLib.assert_true (!fake_folder.current_remote_state ().find (file_with_spaces_1));
        GLib.assert_true (fake_folder.current_local_state ().find (file_with_spaces_1.trimmed ()));
        GLib.assert_true (!fake_folder.current_local_state ().find (file_with_spaces_1));

        GLib.assert_true (fake_folder.current_remote_state ().find (file_with_spaces_2.trimmed ()));
        GLib.assert_true (!fake_folder.current_remote_state ().find (file_with_spaces_2));
        GLib.assert_true (fake_folder.current_local_state ().find (file_with_spaces_2.trimmed ()));
        GLib.assert_true (!fake_folder.current_local_state ().find (file_with_spaces_2));

        GLib.assert_true (fake_folder.current_remote_state ().find (file_with_spaces_3.trimmed ()));
        GLib.assert_true (!fake_folder.current_remote_state ().find (file_with_spaces_3));
        GLib.assert_true (fake_folder.current_local_state ().find (file_with_spaces_3.trimmed ()));
        GLib.assert_true (!fake_folder.current_local_state ().find (file_with_spaces_3));

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/foo"));
        GLib.assert_true (!fake_folder.current_remote_state ().find (file_with_spaces_4));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/foo"));
        GLib.assert_true (!fake_folder.current_local_state ().find (file_with_spaces_4));

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/bar"));
        GLib.assert_true (!fake_folder.current_remote_state ().find (file_with_spaces_5));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/bar"));
        GLib.assert_true (!fake_folder.current_local_state ().find (file_with_spaces_5));

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/bla"));
        GLib.assert_true (!fake_folder.current_remote_state ().find (file_with_spaces_6));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/bla"));
        GLib.assert_true (!fake_folder.current_local_state ().find (file_with_spaces_6));
    }


    /***********************************************************
    ***********************************************************/
    private void test_create_file_with_trailing_spaces_local_trimmed_does_exist_dont_rename_and_upload_file () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        const string file_with_spaces = " foo";
        const string file_trimmed = "foo";

        fake_folder.local_modifier ().insert (file_trimmed);
        GLib.assert_true (fake_folder.sync_once ());
        fake_folder.local_modifier ().insert (file_with_spaces);
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find (file_trimmed));
        GLib.assert_true (!fake_folder.current_remote_state ().find (file_with_spaces));
        GLib.assert_true (fake_folder.current_local_state ().find (file_with_spaces));
        GLib.assert_true (fake_folder.current_local_state ().find (file_trimmed));
    }


    /***********************************************************
    ***********************************************************/
    private void test_create_file_with_trailing_spaces_local_trimmed_also_created_dont_rename_and_upload_file () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        const string file_with_spaces = " foo";
        const string file_trimmed = "foo";

        fake_folder.local_modifier ().insert (file_trimmed);
        fake_folder.local_modifier ().insert (file_with_spaces);
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find (file_trimmed));
        GLib.assert_true (!fake_folder.current_remote_state ().find (file_with_spaces));
        GLib.assert_true (fake_folder.current_local_state ().find (file_with_spaces));
        GLib.assert_true (fake_folder.current_local_state ().find (file_trimmed));
    }

}
}
