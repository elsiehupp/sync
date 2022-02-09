/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using namespace Occ;

class TestSelectiveSync : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testSelectiveSyncBigFolders () {
        FakeFolder fakeFolder { FileInfo.A12_B12_C12_S12 () };
        SyncOptions options;
        options.newBigFolderSizeLimit = 20000; // 20 K
        fakeFolder.syncEngine ().setSyncOptions (options);

        string[] sizeRequests;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation, QNetworkRequest req, QIODevice device)
                                         . Soup.Reply * {
            // Record what path we are querying for the size
            if (req.attribute (QNetworkRequest.CustomVerbAttribute) == "PROPFIND") {
                if (device.readAll ().contains ("<size "))
                    sizeRequests + req.url ().path ();
            }
            return null;
        });

        QSignalSpy newBigFolder (&fakeFolder.syncEngine (), &SyncEngine.newBigFolder);

        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        fakeFolder.remoteModifier ().createDir ("A/newBigDir");
        fakeFolder.remoteModifier ().createDir ("A/newBigDir/subDir");
        fakeFolder.remoteModifier ().insert ("A/newBigDir/subDir/bigFile", options.newBigFolderSizeLimit + 10);
        fakeFolder.remoteModifier ().insert ("A/newBigDir/subDir/smallFile", 10);

        fakeFolder.remoteModifier ().createDir ("B/newSmallDir");
        fakeFolder.remoteModifier ().createDir ("B/newSmallDir/subDir");
        fakeFolder.remoteModifier ().insert ("B/newSmallDir/subDir/smallFile", 10);

        // Because the test system don't do that automatically
        fakeFolder.remoteModifier ().find ("A/newBigDir").extraDavProperties = "<oc:size>20020</oc:size>";
        fakeFolder.remoteModifier ().find ("A/newBigDir/subDir").extraDavProperties = "<oc:size>20020</oc:size>";
        fakeFolder.remoteModifier ().find ("B/newSmallDir").extraDavProperties = "<oc:size>10</oc:size>";
        fakeFolder.remoteModifier ().find ("B/newSmallDir/subDir").extraDavProperties = "<oc:size>10</oc:size>";

        QVERIFY (fakeFolder.syncOnce ());

        QCOMPARE (newBigFolder.count (), 1);
        QCOMPARE (newBigFolder.first ()[0].toString (), string ("A/newBigDir"));
        QCOMPARE (newBigFolder.first ()[1].toBool (), false);
        newBigFolder.clear ();

        QCOMPARE (sizeRequests.count (), 2); // "A/newBigDir" and "B/newSmallDir";
        QCOMPARE (sizeRequests.filter ("/subDir").count (), 0); // at no point we should request the size of the subdirs
        sizeRequests.clear ();

        var oldSync = fakeFolder.currentLocalState ();
        // syncing again should do the same
        fakeFolder.syncEngine ().journal ().schedulePathForRemoteDiscovery (string ("A/newBigDir"));
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), oldSync);
        QCOMPARE (newBigFolder.count (), 1); // (since we don't have a real Folder, the files were not added to any list)
        newBigFolder.clear ();
        QCOMPARE (sizeRequests.count (), 1); // "A/newBigDir";
        sizeRequests.clear ();

        // Simulate that we accept all files by seting a wildcard allow list
        fakeFolder.syncEngine ().journal ().setSelectiveSyncList (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST,
            string[] () + QLatin1String ("/"));
        fakeFolder.syncEngine ().journal ().schedulePathForRemoteDiscovery (string ("A/newBigDir"));
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (newBigFolder.count (), 0);
        QCOMPARE (sizeRequests.count (), 0);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
    }
}

QTEST_GUILESS_MAIN (TestSelectiveSync)