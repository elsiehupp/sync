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

class TestLocalDiscovery : GLib.Object {

    // Check correct behavior when local discovery is partially drawn from the database
    private void testLocalDiscoveryStyle () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        LocalDiscoveryTracker tracker;
        connect (&fake_folder.sync_engine (), &SyncEngine.item_completed, tracker, &LocalDiscoveryTracker.slotItemCompleted);
        connect (&fake_folder.sync_engine (), &SyncEngine.on_signal_finished, tracker, &LocalDiscoveryTracker.slotSyncFinished);

        // More subdirectories are useful for testing
        fake_folder.local_modifier ().mkdir ("A/X");
        fake_folder.local_modifier ().mkdir ("A/Y");
        fake_folder.local_modifier ().insert ("A/X/x1");
        fake_folder.local_modifier ().insert ("A/Y/y1");
        tracker.add_touched_path ("A/X");

        tracker.startSyncFullDiscovery ();
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_true (tracker.localDiscoveryPaths ().empty ());

        // Test begins
        fake_folder.local_modifier ().insert ("A/a3");
        fake_folder.local_modifier ().insert ("A/X/x2");
        fake_folder.local_modifier ().insert ("A/Y/y2");
        fake_folder.local_modifier ().insert ("B/b3");
        fake_folder.remote_modifier ().insert ("C/c3");
        fake_folder.remote_modifier ().append_byte ("C/c1");
        tracker.add_touched_path ("A/X");

        fake_folder.sync_engine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.localDiscoveryPaths ());

        tracker.startSyncPartialDiscovery ();
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a3"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/X/x2"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/Y/y2"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("B/b3"));
        GLib.assert_true (fake_folder.current_local_state ().find ("C/c3"));
        GLib.assert_cmp (fake_folder.sync_engine ().lastLocalDiscoveryStyle (), LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM);
        GLib.assert_true (tracker.localDiscoveryPaths ().empty ());

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (fake_folder.sync_engine ().lastLocalDiscoveryStyle (), LocalDiscoveryStyle.FILESYSTEM_ONLY);
        GLib.assert_true (tracker.localDiscoveryPaths ().empty ());
    }


    /***********************************************************
    ***********************************************************/
    private void testLocalDiscoveryDecision () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        var engine = fake_folder.sync_engine ();

        GLib.assert_true (engine.shouldDiscoverLocally (""));
        GLib.assert_true (engine.shouldDiscoverLocally ("A"));
        GLib.assert_true (engine.shouldDiscoverLocally ("A/X"));

        fake_folder.sync_engine ().setLocalDiscoveryOptions (
            LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A/X", "A/X space", "A/X/beta", "foo bar space/touch", "foo/", "zzz", "zzzz" });

        GLib.assert_true (engine.shouldDiscoverLocally (""));
        GLib.assert_true (engine.shouldDiscoverLocally ("A"));
        GLib.assert_true (engine.shouldDiscoverLocally ("A/X"));
        GLib.assert_true (!engine.shouldDiscoverLocally ("B"));
        GLib.assert_true (!engine.shouldDiscoverLocally ("A B"));
        GLib.assert_true (!engine.shouldDiscoverLocally ("B/X"));
        GLib.assert_true (engine.shouldDiscoverLocally ("foo bar space"));
        GLib.assert_true (engine.shouldDiscoverLocally ("foo"));
        GLib.assert_true (!engine.shouldDiscoverLocally ("foo bar"));
        GLib.assert_true (!engine.shouldDiscoverLocally ("foo bar/touch"));
        // These are within "A/X" so they should be discovered
        GLib.assert_true (engine.shouldDiscoverLocally ("A/X/alpha"));
        GLib.assert_true (engine.shouldDiscoverLocally ("A/X beta"));
        GLib.assert_true (engine.shouldDiscoverLocally ("A/X/Y"));
        GLib.assert_true (engine.shouldDiscoverLocally ("A/X space"));
        GLib.assert_true (engine.shouldDiscoverLocally ("A/X space/alpha"));
        GLib.assert_true (!engine.shouldDiscoverLocally ("A/Xylo/foo"));
        GLib.assert_true (engine.shouldDiscoverLocally ("zzzz/hello"));
        GLib.assert_true (!engine.shouldDiscoverLocally ("zzza/hello"));

        QEXPECT_FAIL ("", "There is a possibility of false positives if the set contains a path "
        //      "which is a prefix, and that prefix is followed by a character less than '/'", Continue);
        GLib.assert_true (!engine.shouldDiscoverLocally ("A/X o"));

        fake_folder.sync_engine ().setLocalDiscoveryOptions (
            LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, {});

        GLib.assert_true (!engine.shouldDiscoverLocally (""));
    }

    // Check whether item on_signal_success and item failure adjusts the
    // tracker correctly.
    private void testTrackerItemCompletion () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        LocalDiscoveryTracker tracker;
        connect (&fake_folder.sync_engine (), &SyncEngine.item_completed, tracker, &LocalDiscoveryTracker.slotItemCompleted);
        connect (&fake_folder.sync_engine (), &SyncEngine.on_signal_finished, tracker, &LocalDiscoveryTracker.slotSyncFinished);
        var trackerContains = (char path) => {
            return tracker.localDiscoveryPaths ().find (path) != tracker.localDiscoveryPaths ().end ();
        }

        tracker.add_touched_path ("A/spurious");

        fake_folder.local_modifier ().insert ("A/a3");
        tracker.add_touched_path ("A/a3");

        fake_folder.local_modifier ().insert ("A/a4");
        fake_folder.server_error_paths ().append ("A/a4");
        // We're not adding a4 as touched, it's in the same folder as a3 and will be seen.
        // And due to the error it should be added to the explicit list while a3 gets removed.

        fake_folder.sync_engine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.localDiscoveryPaths ());
        tracker.startSyncPartialDiscovery ();
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a3"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a4"));
        GLib.assert_true (!trackerContains ("A/a3"));
        GLib.assert_true (trackerContains ("A/a4"));
        GLib.assert_true (trackerContains ("A/spurious")); // not removed since overall sync not successful

        fake_folder.sync_engine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.FILESYSTEM_ONLY);
        tracker.startSyncFullDiscovery ();
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a4"));
        GLib.assert_true (trackerContains ("A/a4")); // had an error, still here
        GLib.assert_true (!trackerContains ("A/spurious")); // removed due to full discovery

        fake_folder.server_error_paths ().clear ();
        fake_folder.sync_journal ().wipe_error_blocklist ();
        tracker.add_touched_path ("A/newspurious"); // will be removed due to successful sync

        fake_folder.sync_engine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.localDiscoveryPaths ());
        tracker.startSyncPartialDiscovery ();
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a4"));
        GLib.assert_true (tracker.localDiscoveryPaths ().empty ());
    }


    /***********************************************************
    ***********************************************************/
    private void testDirectoryAndSubDirectory () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        fake_folder.local_modifier ().mkdir ("A/new_directory");
        fake_folder.local_modifier ().mkdir ("A/new_directory/sub_directory");
        fake_folder.local_modifier ().insert ("A/new_directory/sub_directory/file", 10);

        var expected_state = fake_folder.current_local_state ();

        // Only "A" was modified according to the file system tracker
        fake_folder.sync_engine ().setLocalDiscoveryOptions (
            LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A" });

        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_cmp (fake_folder.current_local_state (), expected_state);
        GLib.assert_cmp (fake_folder.current_remote_state (), expected_state);
    }

    // Tests the behavior of invalid filename detection
    private void testServerBlocklist () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        fake_folder.sync_engine ().account ().set_capabilities ({ { "files",
            QVariantMap { { "blocklisted_files", QVariantList { ".foo", "bar" } } } } });
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
    private void testCreateFileWithTrailingSpaces_localAndRemoteTrimmedDoNotExist_renameAndUploadFile () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        const string fileWithSpaces1 (" foo");
        const string fileWithSpaces2 (" bar  ");
        const string fileWithSpaces3 ("bla ");
        const string fileWithSpaces4 ("A/ foo");
        const string fileWithSpaces5 ("A/ bar  ");
        const string fileWithSpaces6 ("A/bla ");

        fake_folder.local_modifier ().insert (fileWithSpaces1);
        fake_folder.local_modifier ().insert (fileWithSpaces2);
        fake_folder.local_modifier ().insert (fileWithSpaces3);
        fake_folder.local_modifier ().insert (fileWithSpaces4);
        fake_folder.local_modifier ().insert (fileWithSpaces5);
        fake_folder.local_modifier ().insert (fileWithSpaces6);

        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find (fileWithSpaces1.trimmed ()));
        GLib.assert_true (!fake_folder.current_remote_state ().find (fileWithSpaces1));
        GLib.assert_true (fake_folder.current_local_state ().find (fileWithSpaces1.trimmed ()));
        GLib.assert_true (!fake_folder.current_local_state ().find (fileWithSpaces1));

        GLib.assert_true (fake_folder.current_remote_state ().find (fileWithSpaces2.trimmed ()));
        GLib.assert_true (!fake_folder.current_remote_state ().find (fileWithSpaces2));
        GLib.assert_true (fake_folder.current_local_state ().find (fileWithSpaces2.trimmed ()));
        GLib.assert_true (!fake_folder.current_local_state ().find (fileWithSpaces2));

        GLib.assert_true (fake_folder.current_remote_state ().find (fileWithSpaces3.trimmed ()));
        GLib.assert_true (!fake_folder.current_remote_state ().find (fileWithSpaces3));
        GLib.assert_true (fake_folder.current_local_state ().find (fileWithSpaces3.trimmed ()));
        GLib.assert_true (!fake_folder.current_local_state ().find (fileWithSpaces3));

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/foo"));
        GLib.assert_true (!fake_folder.current_remote_state ().find (fileWithSpaces4));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/foo"));
        GLib.assert_true (!fake_folder.current_local_state ().find (fileWithSpaces4));

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/bar"));
        GLib.assert_true (!fake_folder.current_remote_state ().find (fileWithSpaces5));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/bar"));
        GLib.assert_true (!fake_folder.current_local_state ().find (fileWithSpaces5));

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/bla"));
        GLib.assert_true (!fake_folder.current_remote_state ().find (fileWithSpaces6));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/bla"));
        GLib.assert_true (!fake_folder.current_local_state ().find (fileWithSpaces6));
    }


    /***********************************************************
    ***********************************************************/
    private void testCreateFileWithTrailingSpaces_localTrimmedDoesExist_dontRenameAndUploadFile () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        const string fileWithSpaces (" foo");
        const string fileTrimmed ("foo");

        fake_folder.local_modifier ().insert (fileTrimmed);
        GLib.assert_true (fake_folder.sync_once ());
        fake_folder.local_modifier ().insert (fileWithSpaces);
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find (fileTrimmed));
        GLib.assert_true (!fake_folder.current_remote_state ().find (fileWithSpaces));
        GLib.assert_true (fake_folder.current_local_state ().find (fileWithSpaces));
        GLib.assert_true (fake_folder.current_local_state ().find (fileTrimmed));
    }


    /***********************************************************
    ***********************************************************/
    private void testCreateFileWithTrailingSpaces_localTrimmedAlsoCreated_dontRenameAndUploadFile () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        const string fileWithSpaces (" foo");
        const string fileTrimmed ("foo");

        fake_folder.local_modifier ().insert (fileTrimmed);
        fake_folder.local_modifier ().insert (fileWithSpaces);
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find (fileTrimmed));
        GLib.assert_true (!fake_folder.current_remote_state ().find (fileWithSpaces));
        GLib.assert_true (fake_folder.current_local_state ().find (fileWithSpaces));
        GLib.assert_true (fake_folder.current_local_state ().find (fileTrimmed));
    }
}

QTEST_GUILESS_MAIN (TestLocalDiscovery)
