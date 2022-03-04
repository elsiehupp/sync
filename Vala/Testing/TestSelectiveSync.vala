/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using Occ;

namespace Testing {

class TestSelectiveSync : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testSelectiveSyncBigFolders () {
        FakeFolder fakeFolder { FileInfo.A12_B12_C12_S12 ());
        SyncOptions options;
        options.newBigFolderSizeLimit = 20000; // 20 K
        fakeFolder.sync_engine ().setSyncOptions (options);

        string[] sizeRequests;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation, Soup.Request req, QIODevice device)
                                         . Soup.Reply * {
            // Record what path we are querying for the size
            if (req.attribute (Soup.Request.CustomVerbAttribute) == "PROPFIND") {
                if (device.readAll ().contains ("<size "))
                    sizeRequests + req.url ().path ();
            }
            return null;
        });

        QSignalSpy newBigFolder (&fakeFolder.sync_engine (), &SyncEngine.newBigFolder);

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        fakeFolder.remote_modifier ().createDir ("A/newBigDir");
        fakeFolder.remote_modifier ().createDir ("A/newBigDir/subDir");
        fakeFolder.remote_modifier ().insert ("A/newBigDir/subDir/bigFile", options.newBigFolderSizeLimit + 10);
        fakeFolder.remote_modifier ().insert ("A/newBigDir/subDir/smallFile", 10);

        fakeFolder.remote_modifier ().createDir ("B/newSmallDir");
        fakeFolder.remote_modifier ().createDir ("B/newSmallDir/subDir");
        fakeFolder.remote_modifier ().insert ("B/newSmallDir/subDir/smallFile", 10);

        // Because the test system don't do that automatically
        fakeFolder.remote_modifier ().find ("A/newBigDir").extraDavProperties = "<oc:size>20020</oc:size>";
        fakeFolder.remote_modifier ().find ("A/newBigDir/subDir").extraDavProperties = "<oc:size>20020</oc:size>";
        fakeFolder.remote_modifier ().find ("B/newSmallDir").extraDavProperties = "<oc:size>10</oc:size>";
        fakeFolder.remote_modifier ().find ("B/newSmallDir/subDir").extraDavProperties = "<oc:size>10</oc:size>";

        QVERIFY (fakeFolder.sync_once ());

        QCOMPARE (newBigFolder.count (), 1);
        QCOMPARE (newBigFolder.first ()[0].toString (), string ("A/newBigDir"));
        QCOMPARE (newBigFolder.first ()[1].to_bool (), false);
        newBigFolder.clear ();

        QCOMPARE (sizeRequests.count (), 2); // "A/newBigDir" and "B/newSmallDir";
        QCOMPARE (sizeRequests.filter ("/subDir").count (), 0); // at no point we should request the size of the subdirectories
        sizeRequests.clear ();

        var oldSync = fakeFolder.current_local_state ();
        // syncing again should do the same
        fakeFolder.sync_engine ().journal ().schedulePathForRemoteDiscovery (string ("A/newBigDir"));
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), oldSync);
        QCOMPARE (newBigFolder.count (), 1); // (since we don't have a real Folder, the files were not added to any list)
        newBigFolder.clear ();
        QCOMPARE (sizeRequests.count (), 1); // "A/newBigDir";
        sizeRequests.clear ();

        // Simulate that we accept all files by seting a wildcard allow list
        fakeFolder.sync_engine ().journal ().setSelectiveSyncList (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST,
            string[] () + QLatin1String ("/"));
        fakeFolder.sync_engine ().journal ().schedulePathForRemoteDiscovery (string ("A/newBigDir"));
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (newBigFolder.count (), 0);
        QCOMPARE (sizeRequests.count (), 0);
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }
}

QTEST_GUILESS_MAIN (TestSelectiveSync)
