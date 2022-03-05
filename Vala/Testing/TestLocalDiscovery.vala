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
    private on_ void testLocalDiscoveryStyle () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        LocalDiscoveryTracker tracker;
        connect (&fake_folder.sync_engine (), &SyncEngine.itemCompleted, tracker, &LocalDiscoveryTracker.slotItemCompleted);
        connect (&fake_folder.sync_engine (), &SyncEngine.on_signal_finished, tracker, &LocalDiscoveryTracker.slotSyncFinished);

        // More subdirectories are useful for testing
        fake_folder.local_modifier ().mkdir ("A/X");
        fake_folder.local_modifier ().mkdir ("A/Y");
        fake_folder.local_modifier ().insert ("A/X/x1");
        fake_folder.local_modifier ().insert ("A/Y/y1");
        tracker.addTouchedPath ("A/X");

        tracker.startSyncFullDiscovery ();
        //  QVERIFY (fake_folder.sync_once ());

        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        //  QVERIFY (tracker.localDiscoveryPaths ().empty ());

        // Test begins
        fake_folder.local_modifier ().insert ("A/a3");
        fake_folder.local_modifier ().insert ("A/X/x2");
        fake_folder.local_modifier ().insert ("A/Y/y2");
        fake_folder.local_modifier ().insert ("B/b3");
        fake_folder.remote_modifier ().insert ("C/c3");
        fake_folder.remote_modifier ().append_byte ("C/c1");
        tracker.addTouchedPath ("A/X");

        fake_folder.sync_engine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.localDiscoveryPaths ());

        tracker.startSyncPartialDiscovery ();
        //  QVERIFY (fake_folder.sync_once ());

        //  QVERIFY (fake_folder.current_remote_state ().find ("A/a3"));
        //  QVERIFY (fake_folder.current_remote_state ().find ("A/X/x2"));
        //  QVERIFY (!fake_folder.current_remote_state ().find ("A/Y/y2"));
        //  QVERIFY (!fake_folder.current_remote_state ().find ("B/b3"));
        //  QVERIFY (fake_folder.current_local_state ().find ("C/c3"));
        //  QCOMPARE (fake_folder.sync_engine ().lastLocalDiscoveryStyle (), LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM);
        //  QVERIFY (tracker.localDiscoveryPaths ().empty ());

        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        //  QCOMPARE (fake_folder.sync_engine ().lastLocalDiscoveryStyle (), LocalDiscoveryStyle.FILESYSTEM_ONLY);
        //  QVERIFY (tracker.localDiscoveryPaths ().empty ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testLocalDiscoveryDecision () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        var engine = fake_folder.sync_engine ();

        //  QVERIFY (engine.shouldDiscoverLocally (""));
        //  QVERIFY (engine.shouldDiscoverLocally ("A"));
        //  QVERIFY (engine.shouldDiscoverLocally ("A/X"));

        fake_folder.sync_engine ().setLocalDiscoveryOptions (
            LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A/X", "A/X space", "A/X/beta", "foo bar space/touch", "foo/", "zzz", "zzzz" });

        //  QVERIFY (engine.shouldDiscoverLocally (""));
        //  QVERIFY (engine.shouldDiscoverLocally ("A"));
        //  QVERIFY (engine.shouldDiscoverLocally ("A/X"));
        //  QVERIFY (!engine.shouldDiscoverLocally ("B"));
        //  QVERIFY (!engine.shouldDiscoverLocally ("A B"));
        //  QVERIFY (!engine.shouldDiscoverLocally ("B/X"));
        //  QVERIFY (engine.shouldDiscoverLocally ("foo bar space"));
        //  QVERIFY (engine.shouldDiscoverLocally ("foo"));
        //  QVERIFY (!engine.shouldDiscoverLocally ("foo bar"));
        //  QVERIFY (!engine.shouldDiscoverLocally ("foo bar/touch"));
        // These are within "A/X" so they should be discovered
        //  QVERIFY (engine.shouldDiscoverLocally ("A/X/alpha"));
        //  QVERIFY (engine.shouldDiscoverLocally ("A/X beta"));
        //  QVERIFY (engine.shouldDiscoverLocally ("A/X/Y"));
        //  QVERIFY (engine.shouldDiscoverLocally ("A/X space"));
        //  QVERIFY (engine.shouldDiscoverLocally ("A/X space/alpha"));
        //  QVERIFY (!engine.shouldDiscoverLocally ("A/Xylo/foo"));
        //  QVERIFY (engine.shouldDiscoverLocally ("zzzz/hello"));
        //  QVERIFY (!engine.shouldDiscoverLocally ("zzza/hello"));

        QEXPECT_FAIL ("", "There is a possibility of false positives if the set contains a path "
            "which is a prefix, and that prefix is followed by a character less than '/'", Continue);
        //  QVERIFY (!engine.shouldDiscoverLocally ("A/X o"));

        fake_folder.sync_engine ().setLocalDiscoveryOptions (
            LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, {});

        //  QVERIFY (!engine.shouldDiscoverLocally (""));
    }

    // Check whether item on_signal_success and item failure adjusts the
    // tracker correctly.
    private on_ void testTrackerItemCompletion () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        LocalDiscoveryTracker tracker;
        connect (&fake_folder.sync_engine (), &SyncEngine.itemCompleted, tracker, &LocalDiscoveryTracker.slotItemCompleted);
        connect (&fake_folder.sync_engine (), &SyncEngine.on_signal_finished, tracker, &LocalDiscoveryTracker.slotSyncFinished);
        var trackerContains = [&] (char path) {
            return tracker.localDiscoveryPaths ().find (path) != tracker.localDiscoveryPaths ().end ();
        }

        tracker.addTouchedPath ("A/spurious");

        fake_folder.local_modifier ().insert ("A/a3");
        tracker.addTouchedPath ("A/a3");

        fake_folder.local_modifier ().insert ("A/a4");
        fake_folder.server_error_paths ().append ("A/a4");
        // We're not adding a4 as touched, it's in the same folder as a3 and will be seen.
        // And due to the error it should be added to the explicit list while a3 gets removed.

        fake_folder.sync_engine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.localDiscoveryPaths ());
        tracker.startSyncPartialDiscovery ();
        //  QVERIFY (!fake_folder.sync_once ());

        //  QVERIFY (fake_folder.current_remote_state ().find ("A/a3"));
        //  QVERIFY (!fake_folder.current_remote_state ().find ("A/a4"));
        //  QVERIFY (!trackerContains ("A/a3"));
        //  QVERIFY (trackerContains ("A/a4"));
        //  QVERIFY (trackerContains ("A/spurious")); // not removed since overall sync not successful

        fake_folder.sync_engine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.FILESYSTEM_ONLY);
        tracker.startSyncFullDiscovery ();
        //  QVERIFY (!fake_folder.sync_once ());

        //  QVERIFY (!fake_folder.current_remote_state ().find ("A/a4"));
        //  QVERIFY (trackerContains ("A/a4")); // had an error, still here
        //  QVERIFY (!trackerContains ("A/spurious")); // removed due to full discovery

        fake_folder.server_error_paths ().clear ();
        fake_folder.sync_journal ().wipeErrorBlocklist ();
        tracker.addTouchedPath ("A/newspurious"); // will be removed due to successful sync

        fake_folder.sync_engine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.localDiscoveryPaths ());
        tracker.startSyncPartialDiscovery ();
        //  QVERIFY (fake_folder.sync_once ());

        //  QVERIFY (fake_folder.current_remote_state ().find ("A/a4"));
        //  QVERIFY (tracker.localDiscoveryPaths ().empty ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testDirectoryAndSubDirectory () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        fake_folder.local_modifier ().mkdir ("A/newDir");
        fake_folder.local_modifier ().mkdir ("A/newDir/subDir");
        fake_folder.local_modifier ().insert ("A/newDir/subDir/file", 10);

        var expectedState = fake_folder.current_local_state ();

        // Only "A" was modified according to the file system tracker
        fake_folder.sync_engine ().setLocalDiscoveryOptions (
            LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A" });

        //  QVERIFY (fake_folder.sync_once ());

        //  QCOMPARE (fake_folder.current_local_state (), expectedState);
        //  QCOMPARE (fake_folder.current_remote_state (), expectedState);
    }

    // Tests the behavior of invalid filename detection
    private on_ void testServerBlocklist () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        fake_folder.sync_engine ().account ().setCapabilities ({ { "files",
            QVariantMap { { "blocklisted_files", QVariantList { ".foo", "bar" } } } } });
        fake_folder.local_modifier ().insert ("C/.foo");
        fake_folder.local_modifier ().insert ("C/bar");
        fake_folder.local_modifier ().insert ("C/moo");
        fake_folder.local_modifier ().insert ("C/.moo");

        //  QVERIFY (fake_folder.sync_once ());
        //  QVERIFY (fake_folder.current_remote_state ().find ("C/moo"));
        //  QVERIFY (fake_folder.current_remote_state ().find ("C/.moo"));
        //  QVERIFY (!fake_folder.current_remote_state ().find ("C/.foo"));
        //  QVERIFY (!fake_folder.current_remote_state ().find ("C/bar"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testCreateFileWithTrailingSpaces_localAndRemoteTrimmedDoNotExist_renameAndUploadFile () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
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

        //  QVERIFY (fake_folder.sync_once ());

        //  QVERIFY (fake_folder.current_remote_state ().find (fileWithSpaces1.trimmed ()));
        //  QVERIFY (!fake_folder.current_remote_state ().find (fileWithSpaces1));
        //  QVERIFY (fake_folder.current_local_state ().find (fileWithSpaces1.trimmed ()));
        //  QVERIFY (!fake_folder.current_local_state ().find (fileWithSpaces1));

        //  QVERIFY (fake_folder.current_remote_state ().find (fileWithSpaces2.trimmed ()));
        //  QVERIFY (!fake_folder.current_remote_state ().find (fileWithSpaces2));
        //  QVERIFY (fake_folder.current_local_state ().find (fileWithSpaces2.trimmed ()));
        //  QVERIFY (!fake_folder.current_local_state ().find (fileWithSpaces2));

        //  QVERIFY (fake_folder.current_remote_state ().find (fileWithSpaces3.trimmed ()));
        //  QVERIFY (!fake_folder.current_remote_state ().find (fileWithSpaces3));
        //  QVERIFY (fake_folder.current_local_state ().find (fileWithSpaces3.trimmed ()));
        //  QVERIFY (!fake_folder.current_local_state ().find (fileWithSpaces3));

        //  QVERIFY (fake_folder.current_remote_state ().find ("A/foo"));
        //  QVERIFY (!fake_folder.current_remote_state ().find (fileWithSpaces4));
        //  QVERIFY (fake_folder.current_local_state ().find ("A/foo"));
        //  QVERIFY (!fake_folder.current_local_state ().find (fileWithSpaces4));

        //  QVERIFY (fake_folder.current_remote_state ().find ("A/bar"));
        //  QVERIFY (!fake_folder.current_remote_state ().find (fileWithSpaces5));
        //  QVERIFY (fake_folder.current_local_state ().find ("A/bar"));
        //  QVERIFY (!fake_folder.current_local_state ().find (fileWithSpaces5));

        //  QVERIFY (fake_folder.current_remote_state ().find ("A/bla"));
        //  QVERIFY (!fake_folder.current_remote_state ().find (fileWithSpaces6));
        //  QVERIFY (fake_folder.current_local_state ().find ("A/bla"));
        //  QVERIFY (!fake_folder.current_local_state ().find (fileWithSpaces6));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testCreateFileWithTrailingSpaces_localTrimmedDoesExist_dontRenameAndUploadFile () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        const string fileWithSpaces (" foo");
        const string fileTrimmed ("foo");

        fake_folder.local_modifier ().insert (fileTrimmed);
        //  QVERIFY (fake_folder.sync_once ());
        fake_folder.local_modifier ().insert (fileWithSpaces);
        //  QVERIFY (!fake_folder.sync_once ());

        //  QVERIFY (fake_folder.current_remote_state ().find (fileTrimmed));
        //  QVERIFY (!fake_folder.current_remote_state ().find (fileWithSpaces));
        //  QVERIFY (fake_folder.current_local_state ().find (fileWithSpaces));
        //  QVERIFY (fake_folder.current_local_state ().find (fileTrimmed));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testCreateFileWithTrailingSpaces_localTrimmedAlsoCreated_dontRenameAndUploadFile () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        const string fileWithSpaces (" foo");
        const string fileTrimmed ("foo");

        fake_folder.local_modifier ().insert (fileTrimmed);
        fake_folder.local_modifier ().insert (fileWithSpaces);
        //  QVERIFY (!fake_folder.sync_once ());

        //  QVERIFY (fake_folder.current_remote_state ().find (fileTrimmed));
        //  QVERIFY (!fake_folder.current_remote_state ().find (fileWithSpaces));
        //  QVERIFY (fake_folder.current_local_state ().find (fileWithSpaces));
        //  QVERIFY (fake_folder.current_local_state ().find (fileTrimmed));
    }
}

QTEST_GUILESS_MAIN (TestLocalDiscovery)
