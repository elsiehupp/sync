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
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());

        LocalDiscoveryTracker tracker;
        connect (&fakeFolder.sync_engine (), &SyncEngine.itemCompleted, tracker, &LocalDiscoveryTracker.slotItemCompleted);
        connect (&fakeFolder.sync_engine (), &SyncEngine.on_signal_finished, tracker, &LocalDiscoveryTracker.slotSyncFinished);

        // More subdirectories are useful for testing
        fakeFolder.local_modifier ().mkdir ("A/X");
        fakeFolder.local_modifier ().mkdir ("A/Y");
        fakeFolder.local_modifier ().insert ("A/X/x1");
        fakeFolder.local_modifier ().insert ("A/Y/y1");
        tracker.addTouchedPath ("A/X");

        tracker.startSyncFullDiscovery ();
        QVERIFY (fakeFolder.sync_once ());

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QVERIFY (tracker.localDiscoveryPaths ().empty ());

        // Test begins
        fakeFolder.local_modifier ().insert ("A/a3");
        fakeFolder.local_modifier ().insert ("A/X/x2");
        fakeFolder.local_modifier ().insert ("A/Y/y2");
        fakeFolder.local_modifier ().insert ("B/b3");
        fakeFolder.remote_modifier ().insert ("C/c3");
        fakeFolder.remote_modifier ().append_byte ("C/c1");
        tracker.addTouchedPath ("A/X");

        fakeFolder.sync_engine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.localDiscoveryPaths ());

        tracker.startSyncPartialDiscovery ();
        QVERIFY (fakeFolder.sync_once ());

        QVERIFY (fakeFolder.current_remote_state ().find ("A/a3"));
        QVERIFY (fakeFolder.current_remote_state ().find ("A/X/x2"));
        QVERIFY (!fakeFolder.current_remote_state ().find ("A/Y/y2"));
        QVERIFY (!fakeFolder.current_remote_state ().find ("B/b3"));
        QVERIFY (fakeFolder.current_local_state ().find ("C/c3"));
        QCOMPARE (fakeFolder.sync_engine ().lastLocalDiscoveryStyle (), LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM);
        QVERIFY (tracker.localDiscoveryPaths ().empty ());

        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (fakeFolder.sync_engine ().lastLocalDiscoveryStyle (), LocalDiscoveryStyle.FILESYSTEM_ONLY);
        QVERIFY (tracker.localDiscoveryPaths ().empty ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testLocalDiscoveryDecision () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        var engine = fakeFolder.sync_engine ();

        QVERIFY (engine.shouldDiscoverLocally (""));
        QVERIFY (engine.shouldDiscoverLocally ("A"));
        QVERIFY (engine.shouldDiscoverLocally ("A/X"));

        fakeFolder.sync_engine ().setLocalDiscoveryOptions (
            LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A/X", "A/X space", "A/X/beta", "foo bar space/touch", "foo/", "zzz", "zzzz" });

        QVERIFY (engine.shouldDiscoverLocally (""));
        QVERIFY (engine.shouldDiscoverLocally ("A"));
        QVERIFY (engine.shouldDiscoverLocally ("A/X"));
        QVERIFY (!engine.shouldDiscoverLocally ("B"));
        QVERIFY (!engine.shouldDiscoverLocally ("A B"));
        QVERIFY (!engine.shouldDiscoverLocally ("B/X"));
        QVERIFY (engine.shouldDiscoverLocally ("foo bar space"));
        QVERIFY (engine.shouldDiscoverLocally ("foo"));
        QVERIFY (!engine.shouldDiscoverLocally ("foo bar"));
        QVERIFY (!engine.shouldDiscoverLocally ("foo bar/touch"));
        // These are within "A/X" so they should be discovered
        QVERIFY (engine.shouldDiscoverLocally ("A/X/alpha"));
        QVERIFY (engine.shouldDiscoverLocally ("A/X beta"));
        QVERIFY (engine.shouldDiscoverLocally ("A/X/Y"));
        QVERIFY (engine.shouldDiscoverLocally ("A/X space"));
        QVERIFY (engine.shouldDiscoverLocally ("A/X space/alpha"));
        QVERIFY (!engine.shouldDiscoverLocally ("A/Xylo/foo"));
        QVERIFY (engine.shouldDiscoverLocally ("zzzz/hello"));
        QVERIFY (!engine.shouldDiscoverLocally ("zzza/hello"));

        QEXPECT_FAIL ("", "There is a possibility of false positives if the set contains a path "
            "which is a prefix, and that prefix is followed by a character less than '/'", Continue);
        QVERIFY (!engine.shouldDiscoverLocally ("A/X o"));

        fakeFolder.sync_engine ().setLocalDiscoveryOptions (
            LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, {});

        QVERIFY (!engine.shouldDiscoverLocally (""));
    }

    // Check whether item on_signal_success and item failure adjusts the
    // tracker correctly.
    private on_ void testTrackerItemCompletion () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());

        LocalDiscoveryTracker tracker;
        connect (&fakeFolder.sync_engine (), &SyncEngine.itemCompleted, tracker, &LocalDiscoveryTracker.slotItemCompleted);
        connect (&fakeFolder.sync_engine (), &SyncEngine.on_signal_finished, tracker, &LocalDiscoveryTracker.slotSyncFinished);
        var trackerContains = [&] (char path) {
            return tracker.localDiscoveryPaths ().find (path) != tracker.localDiscoveryPaths ().end ();
        }

        tracker.addTouchedPath ("A/spurious");

        fakeFolder.local_modifier ().insert ("A/a3");
        tracker.addTouchedPath ("A/a3");

        fakeFolder.local_modifier ().insert ("A/a4");
        fakeFolder.server_error_paths ().append ("A/a4");
        // We're not adding a4 as touched, it's in the same folder as a3 and will be seen.
        // And due to the error it should be added to the explicit list while a3 gets removed.

        fakeFolder.sync_engine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.localDiscoveryPaths ());
        tracker.startSyncPartialDiscovery ();
        QVERIFY (!fakeFolder.sync_once ());

        QVERIFY (fakeFolder.current_remote_state ().find ("A/a3"));
        QVERIFY (!fakeFolder.current_remote_state ().find ("A/a4"));
        QVERIFY (!trackerContains ("A/a3"));
        QVERIFY (trackerContains ("A/a4"));
        QVERIFY (trackerContains ("A/spurious")); // not removed since overall sync not successful

        fakeFolder.sync_engine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.FILESYSTEM_ONLY);
        tracker.startSyncFullDiscovery ();
        QVERIFY (!fakeFolder.sync_once ());

        QVERIFY (!fakeFolder.current_remote_state ().find ("A/a4"));
        QVERIFY (trackerContains ("A/a4")); // had an error, still here
        QVERIFY (!trackerContains ("A/spurious")); // removed due to full discovery

        fakeFolder.server_error_paths ().clear ();
        fakeFolder.sync_journal ().wipeErrorBlocklist ();
        tracker.addTouchedPath ("A/newspurious"); // will be removed due to successful sync

        fakeFolder.sync_engine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.localDiscoveryPaths ());
        tracker.startSyncPartialDiscovery ();
        QVERIFY (fakeFolder.sync_once ());

        QVERIFY (fakeFolder.current_remote_state ().find ("A/a4"));
        QVERIFY (tracker.localDiscoveryPaths ().empty ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testDirectoryAndSubDirectory () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());

        fakeFolder.local_modifier ().mkdir ("A/newDir");
        fakeFolder.local_modifier ().mkdir ("A/newDir/subDir");
        fakeFolder.local_modifier ().insert ("A/newDir/subDir/file", 10);

        var expectedState = fakeFolder.current_local_state ();

        // Only "A" was modified according to the file system tracker
        fakeFolder.sync_engine ().setLocalDiscoveryOptions (
            LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A" });

        QVERIFY (fakeFolder.sync_once ());

        QCOMPARE (fakeFolder.current_local_state (), expectedState);
        QCOMPARE (fakeFolder.current_remote_state (), expectedState);
    }

    // Tests the behavior of invalid filename detection
    private on_ void testServerBlocklist () {
        FakeFolder fakeFolder { FileInfo.A12_B12_C12_S12 ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        fakeFolder.sync_engine ().account ().setCapabilities ({ { "files",
            QVariantMap { { "blocklisted_files", QVariantList { ".foo", "bar" } } } } });
        fakeFolder.local_modifier ().insert ("C/.foo");
        fakeFolder.local_modifier ().insert ("C/bar");
        fakeFolder.local_modifier ().insert ("C/moo");
        fakeFolder.local_modifier ().insert ("C/.moo");

        QVERIFY (fakeFolder.sync_once ());
        QVERIFY (fakeFolder.current_remote_state ().find ("C/moo"));
        QVERIFY (fakeFolder.current_remote_state ().find ("C/.moo"));
        QVERIFY (!fakeFolder.current_remote_state ().find ("C/.foo"));
        QVERIFY (!fakeFolder.current_remote_state ().find ("C/bar"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testCreateFileWithTrailingSpaces_localAndRemoteTrimmedDoNotExist_renameAndUploadFile () {
        FakeFolder fakeFolder { FileInfo.A12_B12_C12_S12 ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        const string fileWithSpaces1 (" foo");
        const string fileWithSpaces2 (" bar  ");
        const string fileWithSpaces3 ("bla ");
        const string fileWithSpaces4 ("A/ foo");
        const string fileWithSpaces5 ("A/ bar  ");
        const string fileWithSpaces6 ("A/bla ");

        fakeFolder.local_modifier ().insert (fileWithSpaces1);
        fakeFolder.local_modifier ().insert (fileWithSpaces2);
        fakeFolder.local_modifier ().insert (fileWithSpaces3);
        fakeFolder.local_modifier ().insert (fileWithSpaces4);
        fakeFolder.local_modifier ().insert (fileWithSpaces5);
        fakeFolder.local_modifier ().insert (fileWithSpaces6);

        QVERIFY (fakeFolder.sync_once ());

        QVERIFY (fakeFolder.current_remote_state ().find (fileWithSpaces1.trimmed ()));
        QVERIFY (!fakeFolder.current_remote_state ().find (fileWithSpaces1));
        QVERIFY (fakeFolder.current_local_state ().find (fileWithSpaces1.trimmed ()));
        QVERIFY (!fakeFolder.current_local_state ().find (fileWithSpaces1));

        QVERIFY (fakeFolder.current_remote_state ().find (fileWithSpaces2.trimmed ()));
        QVERIFY (!fakeFolder.current_remote_state ().find (fileWithSpaces2));
        QVERIFY (fakeFolder.current_local_state ().find (fileWithSpaces2.trimmed ()));
        QVERIFY (!fakeFolder.current_local_state ().find (fileWithSpaces2));

        QVERIFY (fakeFolder.current_remote_state ().find (fileWithSpaces3.trimmed ()));
        QVERIFY (!fakeFolder.current_remote_state ().find (fileWithSpaces3));
        QVERIFY (fakeFolder.current_local_state ().find (fileWithSpaces3.trimmed ()));
        QVERIFY (!fakeFolder.current_local_state ().find (fileWithSpaces3));

        QVERIFY (fakeFolder.current_remote_state ().find ("A/foo"));
        QVERIFY (!fakeFolder.current_remote_state ().find (fileWithSpaces4));
        QVERIFY (fakeFolder.current_local_state ().find ("A/foo"));
        QVERIFY (!fakeFolder.current_local_state ().find (fileWithSpaces4));

        QVERIFY (fakeFolder.current_remote_state ().find ("A/bar"));
        QVERIFY (!fakeFolder.current_remote_state ().find (fileWithSpaces5));
        QVERIFY (fakeFolder.current_local_state ().find ("A/bar"));
        QVERIFY (!fakeFolder.current_local_state ().find (fileWithSpaces5));

        QVERIFY (fakeFolder.current_remote_state ().find ("A/bla"));
        QVERIFY (!fakeFolder.current_remote_state ().find (fileWithSpaces6));
        QVERIFY (fakeFolder.current_local_state ().find ("A/bla"));
        QVERIFY (!fakeFolder.current_local_state ().find (fileWithSpaces6));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testCreateFileWithTrailingSpaces_localTrimmedDoesExist_dontRenameAndUploadFile () {
        FakeFolder fakeFolder { FileInfo.A12_B12_C12_S12 ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        const string fileWithSpaces (" foo");
        const string fileTrimmed ("foo");

        fakeFolder.local_modifier ().insert (fileTrimmed);
        QVERIFY (fakeFolder.sync_once ());
        fakeFolder.local_modifier ().insert (fileWithSpaces);
        QVERIFY (!fakeFolder.sync_once ());

        QVERIFY (fakeFolder.current_remote_state ().find (fileTrimmed));
        QVERIFY (!fakeFolder.current_remote_state ().find (fileWithSpaces));
        QVERIFY (fakeFolder.current_local_state ().find (fileWithSpaces));
        QVERIFY (fakeFolder.current_local_state ().find (fileTrimmed));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testCreateFileWithTrailingSpaces_localTrimmedAlsoCreated_dontRenameAndUploadFile () {
        FakeFolder fakeFolder { FileInfo.A12_B12_C12_S12 ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        const string fileWithSpaces (" foo");
        const string fileTrimmed ("foo");

        fakeFolder.local_modifier ().insert (fileTrimmed);
        fakeFolder.local_modifier ().insert (fileWithSpaces);
        QVERIFY (!fakeFolder.sync_once ());

        QVERIFY (fakeFolder.current_remote_state ().find (fileTrimmed));
        QVERIFY (!fakeFolder.current_remote_state ().find (fileWithSpaces));
        QVERIFY (fakeFolder.current_local_state ().find (fileWithSpaces));
        QVERIFY (fakeFolder.current_local_state ().find (fileTrimmed));
    }
}

QTEST_GUILESS_MAIN (TestLocalDiscovery)
