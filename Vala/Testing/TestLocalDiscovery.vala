/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>
//  #include <localdiscoverytracker.h>

using namespace Occ;

class TestLocalDiscovery : GLib.Object {

    // Check correct behavior when local discovery is partially drawn from the database
    private on_ void testLocalDiscoveryStyle () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 () };

        LocalDiscoveryTracker tracker;
        connect (&fakeFolder.syncEngine (), &SyncEngine.itemCompleted, tracker, &LocalDiscoveryTracker.slotItemCompleted);
        connect (&fakeFolder.syncEngine (), &SyncEngine.on_signal_finished, tracker, &LocalDiscoveryTracker.slotSyncFinished);

        // More subdirectories are useful for testing
        fakeFolder.localModifier ().mkdir ("A/X");
        fakeFolder.localModifier ().mkdir ("A/Y");
        fakeFolder.localModifier ().insert ("A/X/x1");
        fakeFolder.localModifier ().insert ("A/Y/y1");
        tracker.addTouchedPath ("A/X");

        tracker.startSyncFullDiscovery ();
        QVERIFY (fakeFolder.syncOnce ());

        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QVERIFY (tracker.localDiscoveryPaths ().empty ());

        // Test begins
        fakeFolder.localModifier ().insert ("A/a3");
        fakeFolder.localModifier ().insert ("A/X/x2");
        fakeFolder.localModifier ().insert ("A/Y/y2");
        fakeFolder.localModifier ().insert ("B/b3");
        fakeFolder.remoteModifier ().insert ("C/c3");
        fakeFolder.remoteModifier ().appendByte ("C/c1");
        tracker.addTouchedPath ("A/X");

        fakeFolder.syncEngine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.localDiscoveryPaths ());

        tracker.startSyncPartialDiscovery ();
        QVERIFY (fakeFolder.syncOnce ());

        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a3"));
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/X/x2"));
        QVERIFY (!fakeFolder.currentRemoteState ().find ("A/Y/y2"));
        QVERIFY (!fakeFolder.currentRemoteState ().find ("B/b3"));
        QVERIFY (fakeFolder.currentLocalState ().find ("C/c3"));
        QCOMPARE (fakeFolder.syncEngine ().lastLocalDiscoveryStyle (), LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM);
        QVERIFY (tracker.localDiscoveryPaths ().empty ());

        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QCOMPARE (fakeFolder.syncEngine ().lastLocalDiscoveryStyle (), LocalDiscoveryStyle.FILESYSTEM_ONLY);
        QVERIFY (tracker.localDiscoveryPaths ().empty ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testLocalDiscoveryDecision () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 () };
        var engine = fakeFolder.syncEngine ();

        QVERIFY (engine.shouldDiscoverLocally (""));
        QVERIFY (engine.shouldDiscoverLocally ("A"));
        QVERIFY (engine.shouldDiscoverLocally ("A/X"));

        fakeFolder.syncEngine ().setLocalDiscoveryOptions (
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

        fakeFolder.syncEngine ().setLocalDiscoveryOptions (
            LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, {});

        QVERIFY (!engine.shouldDiscoverLocally (""));
    }

    // Check whether item on_signal_success and item failure adjusts the
    // tracker correctly.
    private on_ void testTrackerItemCompletion () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 () };

        LocalDiscoveryTracker tracker;
        connect (&fakeFolder.syncEngine (), &SyncEngine.itemCompleted, tracker, &LocalDiscoveryTracker.slotItemCompleted);
        connect (&fakeFolder.syncEngine (), &SyncEngine.on_signal_finished, tracker, &LocalDiscoveryTracker.slotSyncFinished);
        var trackerContains = [&] (char path) {
            return tracker.localDiscoveryPaths ().find (path) != tracker.localDiscoveryPaths ().end ();
        }

        tracker.addTouchedPath ("A/spurious");

        fakeFolder.localModifier ().insert ("A/a3");
        tracker.addTouchedPath ("A/a3");

        fakeFolder.localModifier ().insert ("A/a4");
        fakeFolder.serverErrorPaths ().append ("A/a4");
        // We're not adding a4 as touched, it's in the same folder as a3 and will be seen.
        // And due to the error it should be added to the explicit list while a3 gets removed.

        fakeFolder.syncEngine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.localDiscoveryPaths ());
        tracker.startSyncPartialDiscovery ();
        QVERIFY (!fakeFolder.syncOnce ());

        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a3"));
        QVERIFY (!fakeFolder.currentRemoteState ().find ("A/a4"));
        QVERIFY (!trackerContains ("A/a3"));
        QVERIFY (trackerContains ("A/a4"));
        QVERIFY (trackerContains ("A/spurious")); // not removed since overall sync not successful

        fakeFolder.syncEngine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.FILESYSTEM_ONLY);
        tracker.startSyncFullDiscovery ();
        QVERIFY (!fakeFolder.syncOnce ());

        QVERIFY (!fakeFolder.currentRemoteState ().find ("A/a4"));
        QVERIFY (trackerContains ("A/a4")); // had an error, still here
        QVERIFY (!trackerContains ("A/spurious")); // removed due to full discovery

        fakeFolder.serverErrorPaths ().clear ();
        fakeFolder.syncJournal ().wipeErrorBlocklist ();
        tracker.addTouchedPath ("A/newspurious"); // will be removed due to successful sync

        fakeFolder.syncEngine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, tracker.localDiscoveryPaths ());
        tracker.startSyncPartialDiscovery ();
        QVERIFY (fakeFolder.syncOnce ());

        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a4"));
        QVERIFY (tracker.localDiscoveryPaths ().empty ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testDirectoryAndSubDirectory () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 () };

        fakeFolder.localModifier ().mkdir ("A/newDir");
        fakeFolder.localModifier ().mkdir ("A/newDir/subDir");
        fakeFolder.localModifier ().insert ("A/newDir/subDir/file", 10);

        var expectedState = fakeFolder.currentLocalState ();

        // Only "A" was modified according to the file system tracker
        fakeFolder.syncEngine ().setLocalDiscoveryOptions (
            LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A" });

        QVERIFY (fakeFolder.syncOnce ());

        QCOMPARE (fakeFolder.currentLocalState (), expectedState);
        QCOMPARE (fakeFolder.currentRemoteState (), expectedState);
    }

    // Tests the behavior of invalid filename detection
    private on_ void testServerBlocklist () {
        FakeFolder fakeFolder { FileInfo.A12_B12_C12_S12 () };
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        fakeFolder.syncEngine ().account ().setCapabilities ({ { "files",
            QVariantMap { { "blocklisted_files", QVariantList { ".foo", "bar" } } } } });
        fakeFolder.localModifier ().insert ("C/.foo");
        fakeFolder.localModifier ().insert ("C/bar");
        fakeFolder.localModifier ().insert ("C/moo");
        fakeFolder.localModifier ().insert ("C/.moo");

        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (fakeFolder.currentRemoteState ().find ("C/moo"));
        QVERIFY (fakeFolder.currentRemoteState ().find ("C/.moo"));
        QVERIFY (!fakeFolder.currentRemoteState ().find ("C/.foo"));
        QVERIFY (!fakeFolder.currentRemoteState ().find ("C/bar"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testCreateFileWithTrailingSpaces_localAndRemoteTrimmedDoNotExist_renameAndUploadFile () {
        FakeFolder fakeFolder { FileInfo.A12_B12_C12_S12 () };
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        const string fileWithSpaces1 (" foo");
        const string fileWithSpaces2 (" bar  ");
        const string fileWithSpaces3 ("bla ");
        const string fileWithSpaces4 ("A/ foo");
        const string fileWithSpaces5 ("A/ bar  ");
        const string fileWithSpaces6 ("A/bla ");

        fakeFolder.localModifier ().insert (fileWithSpaces1);
        fakeFolder.localModifier ().insert (fileWithSpaces2);
        fakeFolder.localModifier ().insert (fileWithSpaces3);
        fakeFolder.localModifier ().insert (fileWithSpaces4);
        fakeFolder.localModifier ().insert (fileWithSpaces5);
        fakeFolder.localModifier ().insert (fileWithSpaces6);

        QVERIFY (fakeFolder.syncOnce ());

        QVERIFY (fakeFolder.currentRemoteState ().find (fileWithSpaces1.trimmed ()));
        QVERIFY (!fakeFolder.currentRemoteState ().find (fileWithSpaces1));
        QVERIFY (fakeFolder.currentLocalState ().find (fileWithSpaces1.trimmed ()));
        QVERIFY (!fakeFolder.currentLocalState ().find (fileWithSpaces1));

        QVERIFY (fakeFolder.currentRemoteState ().find (fileWithSpaces2.trimmed ()));
        QVERIFY (!fakeFolder.currentRemoteState ().find (fileWithSpaces2));
        QVERIFY (fakeFolder.currentLocalState ().find (fileWithSpaces2.trimmed ()));
        QVERIFY (!fakeFolder.currentLocalState ().find (fileWithSpaces2));

        QVERIFY (fakeFolder.currentRemoteState ().find (fileWithSpaces3.trimmed ()));
        QVERIFY (!fakeFolder.currentRemoteState ().find (fileWithSpaces3));
        QVERIFY (fakeFolder.currentLocalState ().find (fileWithSpaces3.trimmed ()));
        QVERIFY (!fakeFolder.currentLocalState ().find (fileWithSpaces3));

        QVERIFY (fakeFolder.currentRemoteState ().find ("A/foo"));
        QVERIFY (!fakeFolder.currentRemoteState ().find (fileWithSpaces4));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/foo"));
        QVERIFY (!fakeFolder.currentLocalState ().find (fileWithSpaces4));

        QVERIFY (fakeFolder.currentRemoteState ().find ("A/bar"));
        QVERIFY (!fakeFolder.currentRemoteState ().find (fileWithSpaces5));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/bar"));
        QVERIFY (!fakeFolder.currentLocalState ().find (fileWithSpaces5));

        QVERIFY (fakeFolder.currentRemoteState ().find ("A/bla"));
        QVERIFY (!fakeFolder.currentRemoteState ().find (fileWithSpaces6));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/bla"));
        QVERIFY (!fakeFolder.currentLocalState ().find (fileWithSpaces6));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testCreateFileWithTrailingSpaces_localTrimmedDoesExist_dontRenameAndUploadFile () {
        FakeFolder fakeFolder { FileInfo.A12_B12_C12_S12 () };
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        const string fileWithSpaces (" foo");
        const string fileTrimmed ("foo");

        fakeFolder.localModifier ().insert (fileTrimmed);
        QVERIFY (fakeFolder.syncOnce ());
        fakeFolder.localModifier ().insert (fileWithSpaces);
        QVERIFY (!fakeFolder.syncOnce ());

        QVERIFY (fakeFolder.currentRemoteState ().find (fileTrimmed));
        QVERIFY (!fakeFolder.currentRemoteState ().find (fileWithSpaces));
        QVERIFY (fakeFolder.currentLocalState ().find (fileWithSpaces));
        QVERIFY (fakeFolder.currentLocalState ().find (fileTrimmed));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testCreateFileWithTrailingSpaces_localTrimmedAlsoCreated_dontRenameAndUploadFile () {
        FakeFolder fakeFolder { FileInfo.A12_B12_C12_S12 () };
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        const string fileWithSpaces (" foo");
        const string fileTrimmed ("foo");

        fakeFolder.localModifier ().insert (fileTrimmed);
        fakeFolder.localModifier ().insert (fileWithSpaces);
        QVERIFY (!fakeFolder.syncOnce ());

        QVERIFY (fakeFolder.currentRemoteState ().find (fileTrimmed));
        QVERIFY (!fakeFolder.currentRemoteState ().find (fileWithSpaces));
        QVERIFY (fakeFolder.currentLocalState ().find (fileWithSpaces));
        QVERIFY (fakeFolder.currentLocalState ().find (fileTrimmed));
    }
}

QTEST_GUILESS_MAIN (TestLocalDiscovery)