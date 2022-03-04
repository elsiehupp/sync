/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using Occ;

namespace Testing {

struct OperationCounter {
    int nGET = 0;
    int nPUT = 0;
    int nMOVE = 0;
    int nDELETE = 0;

    void on_signal_reset () { *this = {}; }

    var functor () {
        return [&] (QNetworkAccessManager.Operation operation, Soup.Request req, QIODevice *) {
            if (operation == QNetworkAccessManager.GetOperation)
                ++nGET;
            if (operation == QNetworkAccessManager.PutOperation)
                ++nPUT;
            if (operation == QNetworkAccessManager.DeleteOperation)
                ++nDELETE;
            if (req.attribute (Soup.Request.CustomVerbAttribute) == "MOVE")
                ++nMOVE;
            return null;
        }
    }
}

bool itemSuccessful (ItemCompletedSpy spy, string path, SyncInstructions instr) {
    var item = spy.findItem (path);
    return item.status == SyncFileItem.Status.SUCCESS && item.instruction == instr;
}

bool itemConflict (ItemCompletedSpy spy, string path) {
    var item = spy.findItem (path);
    return item.status == SyncFileItem.Status.CONFLICT && item.instruction == CSYNC_INSTRUCTION_CONFLICT;
}

bool itemSuccessfulMove (ItemCompletedSpy spy, string path) {
    return itemSuccessful (spy, path, CSYNC_INSTRUCTION_RENAME);
}

string[] findConflicts (FileInfo directory) {
    string[] conflicts;
    for (var item : directory.children) {
        if (item.name.contains (" (conflicted copy")) {
            conflicts.append (item.path ());
        }
    }
    return conflicts;
}

bool expectAndWipeConflict (FileModifier local, FileInfo state, string path) {
    PathComponents pathComponents (path);
    var base = state.find (pathComponents.parentDirComponents ());
    if (!base)
        return false;
    for (var item : base.children) {
        if (item.name.startsWith (pathComponents.fileName ()) && item.name.contains (" (conflicted copy")) {
            local.remove (item.path ());
            return true;
        }
    }
    return false;
}

class TestSyncMove : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void on_signal_test_move_custom_remote_root () {
        FileInfo subFolder (QStringLiteral ("AS"), { { QStringLiteral ("f1"), 4 } });
        FileInfo folder (QStringLiteral ("A"), { subFolder });
        FileInfo file_info ({}, { folder });

        FakeFolder fakeFolder (file_info, folder, QStringLiteral ("/A"));
        var local_modifier = fakeFolder.local_modifier ();

        OperationCounter counter;
        fakeFolder.setServerOverride (counter.functor ());

        // Move file and then move it back again {
            counter.on_signal_reset ();
            local_modifier.rename (QStringLiteral ("AS/f1"), QStringLiteral ("f1"));

            ItemCompletedSpy completeSpy (fakeFolder);
            QVERIFY (fakeFolder.sync_once ());

            QCOMPARE (counter.nGET, 0);
            QCOMPARE (counter.nPUT, 0);
            QCOMPARE (counter.nMOVE, 1);
            QCOMPARE (counter.nDELETE, 0);

            QVERIFY (itemSuccessful (completeSpy, "f1", CSYNC_INSTRUCTION_RENAME));
            QVERIFY (fakeFolder.current_remote_state ().find ("A/f1"));
            QVERIFY (!fakeFolder.current_remote_state ().find ("A/AS/f1"));
        }
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testRemoteChangeInMovedFolder () {
        // issue #5192
        FakeFolder fakeFolder{ FileInfo{ "", { FileInfo{ QStringLiteral ("folder"), { FileInfo{ QStringLiteral ("folderA"), { { QStringLiteral ("file.txt"), 400 } } }, QStringLiteral ("folderB") } } } } };

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // Edit a file in a moved directory.
        fakeFolder.remote_modifier ().set_contents ("folder/folderA/file.txt", 'a');
        fakeFolder.remote_modifier ().rename ("folder/folderA", "folder/folderB/folderA");
        fakeFolder.sync_once ();
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        var oldState = fakeFolder.current_local_state ();
        QVERIFY (oldState.find ("folder/folderB/folderA/file.txt"));
        QVERIFY (!oldState.find ("folder/folderA/file.txt"));

        // This sync should not remove the file
        fakeFolder.sync_once ();
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (fakeFolder.current_local_state (), oldState);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSelectiveSyncMovedFolder () {
        // issue #5224
        FakeFolder fakeFolder{ FileInfo{ "", { FileInfo{ QStringLiteral ("parentFolder"), { FileInfo{ QStringLiteral ("subFolderA"), { { QStringLiteral ("fileA.txt"), 400 } } }, FileInfo{ QStringLiteral ("subFolderB"), { { QStringLiteral ("fileB.txt"), 400 } } } } } } } };

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        var expectedServerState = fakeFolder.current_remote_state ();

        // Remove subFolderA with selectiveSync:
        fakeFolder.sync_engine ().journal ().setSelectiveSyncList (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, { "parentFolder/subFolderA/" });
        fakeFolder.sync_engine ().journal ().schedulePathForRemoteDiscovery (QByteArrayLiteral ("parentFolder/subFolderA/"));

        fakeFolder.sync_once ();
 {
            // Nothing changed on the server
            QCOMPARE (fakeFolder.current_remote_state (), expectedServerState);
            // The local state should not have subFolderA
            var remoteState = fakeFolder.current_remote_state ();
            remoteState.remove ("parentFolder/subFolderA");
            QCOMPARE (fakeFolder.current_local_state (), remoteState);
        }

        // Rename parentFolder on the server
        fakeFolder.remote_modifier ().rename ("parentFolder", "parentFolderRenamed");
        expectedServerState = fakeFolder.current_remote_state ();
        fakeFolder.sync_once ();
 {
            QCOMPARE (fakeFolder.current_remote_state (), expectedServerState);
            var remoteState = fakeFolder.current_remote_state ();
            // The subFolderA should still be there on the server.
            QVERIFY (remoteState.find ("parentFolderRenamed/subFolderA/fileA.txt"));
            // But not on the client because of the selective sync
            remoteState.remove ("parentFolderRenamed/subFolderA");
            QCOMPARE (fakeFolder.current_local_state (), remoteState);
        }

        // Rename it again, locally this time.
        fakeFolder.local_modifier ().rename ("parentFolderRenamed", "parentThirdName");
        fakeFolder.sync_once ();
 {
            var remoteState = fakeFolder.current_remote_state ();
            // The subFolderA should still be there on the server.
            QVERIFY (remoteState.find ("parentThirdName/subFolderA/fileA.txt"));
            // But not on the client because of the selective sync
            remoteState.remove ("parentThirdName/subFolderA");
            QCOMPARE (fakeFolder.current_local_state (), remoteState);

            expectedServerState = fakeFolder.current_remote_state ();
            ItemCompletedSpy completeSpy (fakeFolder);
            fakeFolder.sync_once (); // This sync should do nothing
            QCOMPARE (completeSpy.count (), 0);

            QCOMPARE (fakeFolder.current_remote_state (), expectedServerState);
            QCOMPARE (fakeFolder.current_local_state (), remoteState);
        }
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testLocalMoveDetection () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());

        int nPUT = 0;
        int nDELETE = 0;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request &, QIODevice *) {
            if (operation == QNetworkAccessManager.PutOperation)
                ++nPUT;
            if (operation == QNetworkAccessManager.DeleteOperation)
                ++nDELETE;
            return null;
        });

        // For directly editing the remote checksum
        FileInfo remoteInfo = fakeFolder.remote_modifier ();

        // Simple move causing a remote rename
        fakeFolder.local_modifier ().rename ("A/a1", "A/a1m");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), remoteInfo);
        QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (remoteInfo));
        QCOMPARE (nPUT, 0);

        // Move-and-change, causing a upload and delete
        fakeFolder.local_modifier ().rename ("A/a2", "A/a2m");
        fakeFolder.local_modifier ().append_byte ("A/a2m");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), remoteInfo);
        QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (remoteInfo));
        QCOMPARE (nPUT, 1);
        QCOMPARE (nDELETE, 1);

        // Move-and-change, mtime+content only
        fakeFolder.local_modifier ().rename ("B/b1", "B/b1m");
        fakeFolder.local_modifier ().set_contents ("B/b1m", 'C');
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), remoteInfo);
        QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (remoteInfo));
        QCOMPARE (nPUT, 2);
        QCOMPARE (nDELETE, 2);

        // Move-and-change, size+content only
        var mtime = fakeFolder.remote_modifier ().find ("B/b2").lastModified;
        fakeFolder.local_modifier ().rename ("B/b2", "B/b2m");
        fakeFolder.local_modifier ().append_byte ("B/b2m");
        fakeFolder.local_modifier ().set_modification_time ("B/b2m", mtime);
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), remoteInfo);
        QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (remoteInfo));
        QCOMPARE (nPUT, 3);
        QCOMPARE (nDELETE, 3);

        // Move-and-change, content only -- c1 has no checksum, so we fail to detect this!
        // Note: This is an expected failure.
        mtime = fakeFolder.remote_modifier ().find ("C/c1").lastModified;
        fakeFolder.local_modifier ().rename ("C/c1", "C/c1m");
        fakeFolder.local_modifier ().set_contents ("C/c1m", 'C');
        fakeFolder.local_modifier ().set_modification_time ("C/c1m", mtime);
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (nPUT, 3);
        QCOMPARE (nDELETE, 3);
        QVERIFY (! (fakeFolder.current_local_state () == remoteInfo));

        // on_signal_cleanup, and upload a file that will have a checksum in the database
        fakeFolder.local_modifier ().remove ("C/c1m");
        fakeFolder.local_modifier ().insert ("C/c3");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), remoteInfo);
        QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (remoteInfo));
        QCOMPARE (nPUT, 4);
        QCOMPARE (nDELETE, 4);

        // Move-and-change, content only, this time while having a checksum
        mtime = fakeFolder.remote_modifier ().find ("C/c3").lastModified;
        fakeFolder.local_modifier ().rename ("C/c3", "C/c3m");
        fakeFolder.local_modifier ().set_contents ("C/c3m", 'C');
        fakeFolder.local_modifier ().set_modification_time ("C/c3m", mtime);
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (nPUT, 5);
        QCOMPARE (nDELETE, 5);
        QCOMPARE (fakeFolder.current_local_state (), remoteInfo);
        QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (remoteInfo));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testDuplicateFileId_data () {
        QTest.addColumn<string> ("prefix");

        // There have been bugs related to how the original
        // folder and the folder with the duplicate tree are
        // ordered. Test both cases here.
        QTest.newRow ("first ordering") + "O"; // "O" > "A"
        QTest.newRow ("second ordering") + "0"; // "0" < "A"
    }

    // If the same folder is shared in two different ways with the same
    // user, the target user will see duplicate file ids. We need to make
    // sure the move detection and sync still do the right thing in that
    // case.
    private on_ void testDuplicateFileId () {
        QFETCH (string, prefix);

        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        var remote = fakeFolder.remote_modifier ();

        remote.mkdir ("A/W");
        remote.insert ("A/W/w1");
        remote.mkdir ("A/Q");

        // Duplicate every entry in A under O/A
        remote.mkdir (prefix);
        remote.children[prefix].addChild (remote.children["A"]);

        // This already checks that the rename detection doesn't get
        // horribly confused if we add new files that have the same
        // fileid as existing ones
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        OperationCounter counter;
        fakeFolder.setServerOverride (counter.functor ());

        // Try a remote file move
        remote.rename ("A/a1", "A/W/a1m");
        remote.rename (prefix + "/A/a1", prefix + "/A/W/a1m");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (counter.nGET, 0);

        // And a remote directory move
        remote.rename ("A/W", "A/Q/W");
        remote.rename (prefix + "/A/W", prefix + "/A/Q/W");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (counter.nGET, 0);

        // Partial file removal (in practice, A/a2 may be moved to O/a2, but we don't care)
        remote.rename (prefix + "/A/a2", prefix + "/a2");
        remote.remove ("A/a2");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (counter.nGET, 0);

        // Local change plus remote move at the same time
        fakeFolder.local_modifier ().append_byte (prefix + "/a2");
        remote.rename (prefix + "/a2", prefix + "/a3");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (counter.nGET, 1);
        counter.on_signal_reset ();

        // remove localy, and remote move at the same time
        fakeFolder.local_modifier ().remove ("A/Q/W/a1m");
        remote.rename ("A/Q/W/a1m", "A/Q/W/a1p");
        remote.rename (prefix + "/A/Q/W/a1m", prefix + "/A/Q/W/a1p");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (counter.nGET, 1);
        counter.on_signal_reset ();
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testMovePropagation () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        var local = fakeFolder.local_modifier ();
        var remote = fakeFolder.remote_modifier ();

        OperationCounter counter;
        fakeFolder.setServerOverride (counter.functor ());

        // Move {
            counter.on_signal_reset ();
            local.rename ("A/a1", "A/a1m");
            remote.rename ("B/b1", "B/b1m");
            ItemCompletedSpy completeSpy (fakeFolder);
            QVERIFY (fakeFolder.sync_once ());
            QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
            QCOMPARE (counter.nGET, 0);
            QCOMPARE (counter.nPUT, 0);
            QCOMPARE (counter.nMOVE, 1);
            QCOMPARE (counter.nDELETE, 0);
            QVERIFY (itemSuccessfulMove (completeSpy, "A/a1m"));
            QVERIFY (itemSuccessfulMove (completeSpy, "B/b1m"));
            QCOMPARE (completeSpy.findItem ("A/a1m").file, QStringLiteral ("A/a1"));
            QCOMPARE (completeSpy.findItem ("A/a1m").renameTarget, QStringLiteral ("A/a1m"));
            QCOMPARE (completeSpy.findItem ("B/b1m").file, QStringLiteral ("B/b1"));
            QCOMPARE (completeSpy.findItem ("B/b1m").renameTarget, QStringLiteral ("B/b1m"));
        }

        // Touch+Move on same side
        counter.on_signal_reset ();
        local.rename ("A/a2", "A/a2m");
        local.set_contents ("A/a2m", 'A');
        remote.rename ("B/b2", "B/b2m");
        remote.set_contents ("B/b2m", 'A');
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (fakeFolder.current_remote_state ()));
        QCOMPARE (counter.nGET, 1);
        QCOMPARE (counter.nPUT, 1);
        QCOMPARE (counter.nMOVE, 0);
        QCOMPARE (counter.nDELETE, 1);
        QCOMPARE (remote.find ("A/a2m").content_char, 'A');
        QCOMPARE (remote.find ("B/b2m").content_char, 'A');

        // Touch+Move on opposite sides
        counter.on_signal_reset ();
        local.rename ("A/a1m", "A/a1m2");
        remote.set_contents ("A/a1m", 'B');
        remote.rename ("B/b1m", "B/b1m2");
        local.set_contents ("B/b1m", 'B');
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (fakeFolder.current_remote_state ()));
        QCOMPARE (counter.nGET, 2);
        QCOMPARE (counter.nPUT, 2);
        QCOMPARE (counter.nMOVE, 0);
        QCOMPARE (counter.nDELETE, 0);
        // All these files existing afterwards is debatable. Should we propagate
        // the rename in one direction and grab the new contents in the other?
        // Currently there's no propagation job that would do that, and this does
        // at least not lose data.
        QCOMPARE (remote.find ("A/a1m").content_char, 'B');
        QCOMPARE (remote.find ("B/b1m").content_char, 'B');
        QCOMPARE (remote.find ("A/a1m2").content_char, 'W');
        QCOMPARE (remote.find ("B/b1m2").content_char, 'W');

        // Touch+create on one side, move on the other {
            counter.on_signal_reset ();
            local.append_byte ("A/a1m");
            local.insert ("A/a1mt");
            remote.rename ("A/a1m", "A/a1mt");
            remote.append_byte ("B/b1m");
            remote.insert ("B/b1mt");
            local.rename ("B/b1m", "B/b1mt");
            ItemCompletedSpy completeSpy (fakeFolder);
            QVERIFY (fakeFolder.sync_once ());
            QVERIFY (expectAndWipeConflict (local, fakeFolder.current_local_state (), "A/a1mt"));
            QVERIFY (expectAndWipeConflict (local, fakeFolder.current_local_state (), "B/b1mt"));
            QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
            QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (fakeFolder.current_remote_state ()));
            QCOMPARE (counter.nGET, 3);
            QCOMPARE (counter.nPUT, 1);
            QCOMPARE (counter.nMOVE, 0);
            QCOMPARE (counter.nDELETE, 0);
            QVERIFY (itemSuccessful (completeSpy, "A/a1m", CSYNC_INSTRUCTION_NEW));
            QVERIFY (itemSuccessful (completeSpy, "B/b1m", CSYNC_INSTRUCTION_NEW));
            QVERIFY (itemConflict (completeSpy, "A/a1mt"));
            QVERIFY (itemConflict (completeSpy, "B/b1mt"));
        }

        // Create new on one side, move to new on the other {
            counter.on_signal_reset ();
            local.insert ("A/a1N", 13);
            remote.rename ("A/a1mt", "A/a1N");
            remote.insert ("B/b1N", 13);
            local.rename ("B/b1mt", "B/b1N");
            ItemCompletedSpy completeSpy (fakeFolder);
            QVERIFY (fakeFolder.sync_once ());
            QVERIFY (expectAndWipeConflict (local, fakeFolder.current_local_state (), "A/a1N"));
            QVERIFY (expectAndWipeConflict (local, fakeFolder.current_local_state (), "B/b1N"));
            QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
            QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (fakeFolder.current_remote_state ()));
            QCOMPARE (counter.nGET, 2);
            QCOMPARE (counter.nPUT, 0);
            QCOMPARE (counter.nMOVE, 0);
            QCOMPARE (counter.nDELETE, 1);
            QVERIFY (itemSuccessful (completeSpy, "A/a1mt", CSYNC_INSTRUCTION_REMOVE));
            QVERIFY (itemSuccessful (completeSpy, "B/b1mt", CSYNC_INSTRUCTION_REMOVE));
            QVERIFY (itemConflict (completeSpy, "A/a1N"));
            QVERIFY (itemConflict (completeSpy, "B/b1N"));
        }

        // Local move, remote move
        counter.on_signal_reset ();
        local.rename ("C/c1", "C/c1mL");
        remote.rename ("C/c1", "C/c1mR");
        QVERIFY (fakeFolder.sync_once ());
        // end up with both files
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (fakeFolder.current_remote_state ()));
        QCOMPARE (counter.nGET, 1);
        QCOMPARE (counter.nPUT, 1);
        QCOMPARE (counter.nMOVE, 0);
        QCOMPARE (counter.nDELETE, 0);

        // Rename/rename conflict on a folder
        counter.on_signal_reset ();
        remote.rename ("C", "CMR");
        local.rename ("C", "CML");
        QVERIFY (fakeFolder.sync_once ());
        // End up with both folders
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (fakeFolder.current_remote_state ()));
        QCOMPARE (counter.nGET, 3); // 3 files in C
        QCOMPARE (counter.nPUT, 3);
        QCOMPARE (counter.nMOVE, 0);
        QCOMPARE (counter.nDELETE, 0);

        // Folder move {
            counter.on_signal_reset ();
            local.rename ("A", "AM");
            remote.rename ("B", "BM");
            ItemCompletedSpy completeSpy (fakeFolder);
            QVERIFY (fakeFolder.sync_once ());
            QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
            QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (fakeFolder.current_remote_state ()));
            QCOMPARE (counter.nGET, 0);
            QCOMPARE (counter.nPUT, 0);
            QCOMPARE (counter.nMOVE, 1);
            QCOMPARE (counter.nDELETE, 0);
            QVERIFY (itemSuccessfulMove (completeSpy, "AM"));
            QVERIFY (itemSuccessfulMove (completeSpy, "BM"));
            QCOMPARE (completeSpy.findItem ("AM").file, QStringLiteral ("A"));
            QCOMPARE (completeSpy.findItem ("AM").renameTarget, QStringLiteral ("AM"));
            QCOMPARE (completeSpy.findItem ("BM").file, QStringLiteral ("B"));
            QCOMPARE (completeSpy.findItem ("BM").renameTarget, QStringLiteral ("BM"));
        }

        // Folder move with contents touched on the same side {
            counter.on_signal_reset ();
            local.set_contents ("AM/a2m", 'C');
            // We must change the modtime for it is likely that it did not change between sync.
            // (Previous version of the client (<=2.5) would not need this because it was always doing
            // checksum comparison for all renames. But newer version no longer does it if the file is
            // renamed because the parent folder is renamed)
            local.set_modification_time ("AM/a2m", GLib.DateTime.currentDateTimeUtc ().addDays (3));
            local.rename ("AM", "A2");
            remote.set_contents ("BM/b2m", 'C');
            remote.rename ("BM", "B2");
            ItemCompletedSpy completeSpy (fakeFolder);
            QVERIFY (fakeFolder.sync_once ());
            QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
            QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (fakeFolder.current_remote_state ()));
            QCOMPARE (counter.nGET, 1);
            QCOMPARE (counter.nPUT, 1);
            QCOMPARE (counter.nMOVE, 1);
            QCOMPARE (counter.nDELETE, 0);
            QCOMPARE (remote.find ("A2/a2m").content_char, 'C');
            QCOMPARE (remote.find ("B2/b2m").content_char, 'C');
            QVERIFY (itemSuccessfulMove (completeSpy, "A2"));
            QVERIFY (itemSuccessfulMove (completeSpy, "B2"));
        }

        // Folder rename with contents touched on the other tree
        counter.on_signal_reset ();
        remote.set_contents ("A2/a2m", 'D');
        // set_contents alone may not produce updated mtime if the test is fast
        // and since we don't use checksums here, that matters.
        remote.append_byte ("A2/a2m");
        local.rename ("A2", "A3");
        local.set_contents ("B2/b2m", 'D');
        local.append_byte ("B2/b2m");
        remote.rename ("B2", "B3");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (fakeFolder.current_remote_state ()));
        QCOMPARE (counter.nGET, 1);
        QCOMPARE (counter.nPUT, 1);
        QCOMPARE (counter.nMOVE, 1);
        QCOMPARE (counter.nDELETE, 0);
        QCOMPARE (remote.find ("A3/a2m").content_char, 'D');
        QCOMPARE (remote.find ("B3/b2m").content_char, 'D');

        // Folder rename with contents touched on both ends
        counter.on_signal_reset ();
        remote.set_contents ("A3/a2m", 'R');
        remote.append_byte ("A3/a2m");
        local.set_contents ("A3/a2m", 'L');
        local.append_byte ("A3/a2m");
        local.append_byte ("A3/a2m");
        local.rename ("A3", "A4");
        remote.set_contents ("B3/b2m", 'R');
        remote.append_byte ("B3/b2m");
        local.set_contents ("B3/b2m", 'L');
        local.append_byte ("B3/b2m");
        local.append_byte ("B3/b2m");
        remote.rename ("B3", "B4");
        QVERIFY (fakeFolder.sync_once ());
        var currentLocal = fakeFolder.current_local_state ();
        var conflicts = findConflicts (currentLocal.children["A4"]);
        QCOMPARE (conflicts.size (), 1);
        for (var& c : conflicts) {
            QCOMPARE (currentLocal.find (c).content_char, 'L');
            local.remove (c);
        }
        conflicts = findConflicts (currentLocal.children["B4"]);
        QCOMPARE (conflicts.size (), 1);
        for (var& c : conflicts) {
            QCOMPARE (currentLocal.find (c).content_char, 'L');
            local.remove (c);
        }
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (fakeFolder.current_remote_state ()));
        QCOMPARE (counter.nGET, 2);
        QCOMPARE (counter.nPUT, 0);
        QCOMPARE (counter.nMOVE, 1);
        QCOMPARE (counter.nDELETE, 0);
        QCOMPARE (remote.find ("A4/a2m").content_char, 'R');
        QCOMPARE (remote.find ("B4/b2m").content_char, 'R');

        // Rename a folder and rename the contents at the same time
        counter.on_signal_reset ();
        local.rename ("A4/a2m", "A4/a2m2");
        local.rename ("A4", "A5");
        remote.rename ("B4/b2m", "B4/b2m2");
        remote.rename ("B4", "B5");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (fakeFolder.current_remote_state ()));
        QCOMPARE (counter.nGET, 0);
        QCOMPARE (counter.nPUT, 0);
        QCOMPARE (counter.nMOVE, 2);
        QCOMPARE (counter.nDELETE, 0);
    }

    // These renames can be troublesome on windows
    private on_ void testRenameCaseOnly () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        var local = fakeFolder.local_modifier ();
        var remote = fakeFolder.remote_modifier ();

        OperationCounter counter;
        fakeFolder.setServerOverride (counter.functor ());

        local.rename ("A/a1", "A/A1");
        remote.rename ("A/a2", "A/A2");

        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), remote);
        QCOMPARE (printDbData (fakeFolder.database_state ()), printDbData (fakeFolder.current_remote_state ()));
        QCOMPARE (counter.nGET, 0);
        QCOMPARE (counter.nPUT, 0);
        QCOMPARE (counter.nMOVE, 1);
        QCOMPARE (counter.nDELETE, 0);
    }

    // Check interaction of moves with file type changes
    private on_ void testMoveAndTypeChange () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        var local = fakeFolder.local_modifier ();
        var remote = fakeFolder.remote_modifier ();

        // Touch on one side, rename and mkdir on the other {
            local.append_byte ("A/a1");
            remote.rename ("A/a1", "A/a1mq");
            remote.mkdir ("A/a1");
            remote.append_byte ("B/b1");
            local.rename ("B/b1", "B/b1mq");
            local.mkdir ("B/b1");
            ItemCompletedSpy completeSpy (fakeFolder);
            QVERIFY (fakeFolder.sync_once ());
            // BUG : This doesn't behave right
            //QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        }
    }

    // https://github.com/owncloud/client/issues/6629#issuecomment-402450691
    // When a file is moved and the server mtime was not in sync, the local mtime should be kept
    private on_ void testMoveAndMTimeChange () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        OperationCounter counter;
        fakeFolder.setServerOverride (counter.functor ());

        // Changing the mtime on the server (without invalidating the etag)
        fakeFolder.remote_modifier ().find ("A/a1").lastModified = GLib.DateTime.currentDateTimeUtc ().addSecs (-50000);
        fakeFolder.remote_modifier ().find ("A/a2").lastModified = GLib.DateTime.currentDateTimeUtc ().addSecs (-40000);

        // Move a few files
        fakeFolder.remote_modifier ().rename ("A/a1", "A/a1_server_renamed");
        fakeFolder.local_modifier ().rename ("A/a2", "A/a2_local_renamed");

        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (counter.nGET, 0);
        QCOMPARE (counter.nPUT, 0);
        QCOMPARE (counter.nMOVE, 1);
        QCOMPARE (counter.nDELETE, 0);

        // Another sync should do nothing
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (counter.nGET, 0);
        QCOMPARE (counter.nPUT, 0);
        QCOMPARE (counter.nMOVE, 1);
        QCOMPARE (counter.nDELETE, 0);

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }

    // Test for https://github.com/owncloud/client/issues/6694
    private on_ void testInvertFolderHierarchy () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        fakeFolder.remote_modifier ().mkdir ("A/Empty");
        fakeFolder.remote_modifier ().mkdir ("A/Empty/Foo");
        fakeFolder.remote_modifier ().mkdir ("C/AllEmpty");
        fakeFolder.remote_modifier ().mkdir ("C/AllEmpty/Bar");
        fakeFolder.remote_modifier ().insert ("A/Empty/f1");
        fakeFolder.remote_modifier ().insert ("A/Empty/Foo/f2");
        fakeFolder.remote_modifier ().mkdir ("C/AllEmpty/f3");
        fakeFolder.remote_modifier ().mkdir ("C/AllEmpty/Bar/f4");
        QVERIFY (fakeFolder.sync_once ());

        OperationCounter counter;
        fakeFolder.setServerOverride (counter.functor ());

        // "Empty" is after "A", alphabetically
        fakeFolder.local_modifier ().rename ("A/Empty", "Empty");
        fakeFolder.local_modifier ().rename ("A", "Empty/A");

        // "AllEmpty" is before "C", alphabetically
        fakeFolder.local_modifier ().rename ("C/AllEmpty", "AllEmpty");
        fakeFolder.local_modifier ().rename ("C", "AllEmpty/C");

        var expectedState = fakeFolder.current_local_state ();
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), expectedState);
        QCOMPARE (fakeFolder.current_remote_state (), expectedState);
        QCOMPARE (counter.nDELETE, 0);
        QCOMPARE (counter.nGET, 0);
        QCOMPARE (counter.nPUT, 0);

        // Now, the revert, but "crossed"
        fakeFolder.local_modifier ().rename ("Empty/A", "A");
        fakeFolder.local_modifier ().rename ("AllEmpty/C", "C");
        fakeFolder.local_modifier ().rename ("Empty", "C/Empty");
        fakeFolder.local_modifier ().rename ("AllEmpty", "A/AllEmpty");
        expectedState = fakeFolder.current_local_state ();
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), expectedState);
        QCOMPARE (fakeFolder.current_remote_state (), expectedState);
        QCOMPARE (counter.nDELETE, 0);
        QCOMPARE (counter.nGET, 0);
        QCOMPARE (counter.nPUT, 0);

        // Reverse on remote
        fakeFolder.remote_modifier ().rename ("A/AllEmpty", "AllEmpty");
        fakeFolder.remote_modifier ().rename ("C/Empty", "Empty");
        fakeFolder.remote_modifier ().rename ("C", "AllEmpty/C");
        fakeFolder.remote_modifier ().rename ("A", "Empty/A");
        expectedState = fakeFolder.current_remote_state ();
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), expectedState);
        QCOMPARE (fakeFolder.current_remote_state (), expectedState);
        QCOMPARE (counter.nDELETE, 0);
        QCOMPARE (counter.nGET, 0);
        QCOMPARE (counter.nPUT, 0);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testDeepHierarchy_data () {
        QTest.addColumn<bool> ("local");
        QTest.newRow ("remote") + false;
        QTest.newRow ("local") + true;
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testDeepHierarchy () {
        QFETCH (bool, local);
        FakeFolder fakeFolder { FileInfo.A12_B12_C12_S12 ());
        var modifier = local ? fakeFolder.local_modifier () : fakeFolder.remote_modifier ();

        modifier.mkdir ("FolA");
        modifier.mkdir ("FolA/FolB");
        modifier.mkdir ("FolA/FolB/FolC");
        modifier.mkdir ("FolA/FolB/FolC/FolD");
        modifier.mkdir ("FolA/FolB/FolC/FolD/FolE");
        modifier.insert ("FolA/FileA.txt");
        modifier.insert ("FolA/FolB/FileB.txt");
        modifier.insert ("FolA/FolB/FolC/FileC.txt");
        modifier.insert ("FolA/FolB/FolC/FolD/FileD.txt");
        modifier.insert ("FolA/FolB/FolC/FolD/FolE/FileE.txt");
        QVERIFY (fakeFolder.sync_once ());

        OperationCounter counter;
        fakeFolder.setServerOverride (counter.functor ());

        modifier.insert ("FolA/FileA2.txt");
        modifier.insert ("FolA/FolB/FileB2.txt");
        modifier.insert ("FolA/FolB/FolC/FileC2.txt");
        modifier.insert ("FolA/FolB/FolC/FolD/FileD2.txt");
        modifier.insert ("FolA/FolB/FolC/FolD/FolE/FileE2.txt");
        modifier.rename ("FolA", "FolA_Renamed");
        modifier.rename ("FolA_Renamed/FolB", "FolB_Renamed");
        modifier.rename ("FolB_Renamed/FolC", "FolA");
        modifier.rename ("FolA/FolD", "FolA/FolD_Renamed");
        modifier.mkdir ("FolB_Renamed/New");
        modifier.rename ("FolA/FolD_Renamed/FolE", "FolB_Renamed/New/FolE");
        var expected = local ? fakeFolder.current_local_state () : fakeFolder.current_remote_state ();
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), expected);
        QCOMPARE (fakeFolder.current_remote_state (), expected);
        QCOMPARE (counter.nDELETE, local ? 1 : 0); // FolC was is renamed to an existing name, so it is not considered as renamed
        // There was 5 inserts
        QCOMPARE (counter.nGET, local ? 0 : 5);
        QCOMPARE (counter.nPUT, local ? 5 : 0);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void renameOnBothSides () {
        FakeFolder fakeFolder { FileInfo.A12_B12_C12_S12 ());
        OperationCounter counter;
        fakeFolder.setServerOverride (counter.functor ());

        // Test that renaming a file within a directory that was renamed on the other side actually do a rename.

        // 1) move the folder alphabeticaly before
        fakeFolder.remote_modifier ().rename ("A/a1", "A/a1m");
        fakeFolder.local_modifier ().rename ("A", "this.A");
        fakeFolder.local_modifier ().rename ("B/b1", "B/b1m");
        fakeFolder.remote_modifier ().rename ("B", "this.B");

        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_remote_state (), fakeFolder.current_remote_state ());
        QVERIFY (fakeFolder.current_remote_state ().find ("this.A/a1m"));
        QVERIFY (fakeFolder.current_remote_state ().find ("this.B/b1m"));
        QCOMPARE (counter.nDELETE, 0);
        QCOMPARE (counter.nGET, 0);
        QCOMPARE (counter.nPUT, 0);
        QCOMPARE (counter.nMOVE, 2);
        counter.on_signal_reset ();

        // 2) move alphabetically after
        fakeFolder.remote_modifier ().rename ("this.A/a2", "this.A/a2m");
        fakeFolder.local_modifier ().rename ("this.B/b2", "this.B/b2m");
        fakeFolder.local_modifier ().rename ("this.A", "S/A");
        fakeFolder.remote_modifier ().rename ("this.B", "S/B");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_remote_state (), fakeFolder.current_remote_state ());
        QVERIFY (fakeFolder.current_remote_state ().find ("S/A/a2m"));
        QVERIFY (fakeFolder.current_remote_state ().find ("S/B/b2m"));
        QCOMPARE (counter.nDELETE, 0);
        QCOMPARE (counter.nGET, 0);
        QCOMPARE (counter.nPUT, 0);
        QCOMPARE (counter.nMOVE, 2);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void moveFileToDifferentFolderOnBothSides () {
        FakeFolder fakeFolder { FileInfo.A12_B12_C12_S12 ());
        OperationCounter counter;
        fakeFolder.setServerOverride (counter.functor ());

        // Test that moving a file within to different folder on both side does the right thing.

        fakeFolder.remote_modifier ().rename ("B/b1", "A/b1");
        fakeFolder.local_modifier ().rename ("B/b1", "C/b1");

        fakeFolder.local_modifier ().rename ("B/b2", "A/b2");
        fakeFolder.remote_modifier ().rename ("B/b2", "C/b2");

        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_remote_state (), fakeFolder.current_remote_state ());
        QVERIFY (fakeFolder.current_remote_state ().find ("A/b1"));
        QVERIFY (fakeFolder.current_remote_state ().find ("C/b1"));
        QVERIFY (fakeFolder.current_remote_state ().find ("A/b2"));
        QVERIFY (fakeFolder.current_remote_state ().find ("C/b2"));
        QCOMPARE (counter.nMOVE, 0); // Unfortunately, we can't really make a move in this case
        QCOMPARE (counter.nGET, 2);
        QCOMPARE (counter.nPUT, 2);
        QCOMPARE (counter.nDELETE, 0);
        counter.on_signal_reset ();

    }

    // Test that deletes don't run before renames
    private on_ void testRenameParallelism () {
        FakeFolder fakeFolder{ FileInfo{} };
        fakeFolder.remote_modifier ().mkdir ("A");
        fakeFolder.remote_modifier ().insert ("A/file");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        fakeFolder.local_modifier ().mkdir ("B");
        fakeFolder.local_modifier ().rename ("A/file", "B/file");
        fakeFolder.local_modifier ().remove ("A");

        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testMovedWithError_data () {
        QTest.addColumn<Vfs.Mode> ("vfsMode");

        QTest.newRow ("Vfs.Off") + Vfs.Off;
        QTest.newRow ("Vfs.WithSuffix") + Vfs.WithSuffix;
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testMovedWithError () {
        QFETCH (Vfs.Mode, vfsMode);
        const var getName = [vfsMode] (string s) { {f (vfsMode == Vfs.WithSuffix)
            {
                return QStringLiteral ("%1" APPLICATION_DOTVIRTUALFILE_SUFFIX).arg (s);
            }
            return s;
        }
        const string src = "folder/folderA/file.txt";
        const string dest = "folder/folderB/file.txt";
        FakeFolder fakeFolder{ FileInfo{ "", { FileInfo{ QStringLiteral ("folder"), { FileInfo{ QStringLiteral ("folderA"), { { QStringLiteral ("file.txt"), 400 } } }, QStringLiteral ("folderB") } } } } };
        var syncOpts = fakeFolder.sync_engine ().syncOptions ();
        syncOpts.parallelNetworkJobs = 0;
        fakeFolder.sync_engine ().setSyncOptions (syncOpts);

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        if (vfsMode != Vfs.Off) {
            var vfs = unowned<Vfs> (createVfsFromPlugin (vfsMode).release ());
            QVERIFY (vfs);
            fakeFolder.switch_to_vfs (vfs);
            fakeFolder.sync_journal ().internalPinStates ().setForPath ("", PinState.VfsItemAvailability.ONLINE_ONLY);

            // make files virtual
            fakeFolder.sync_once ();
        }

        fakeFolder.server_error_paths ().append (src, 403);
        fakeFolder.local_modifier ().rename (getName (src), getName (dest));
        QVERIFY (!fakeFolder.current_local_state ().find (getName (src)));
        QVERIFY (fakeFolder.current_local_state ().find (getName (dest)));
        QVERIFY (fakeFolder.current_remote_state ().find (src));
        QVERIFY (!fakeFolder.current_remote_state ().find (dest));

        // sync1 file gets detected as error, instruction is still NEW_FILE
        fakeFolder.sync_once ();

        // sync2 file is in error state, checkErrorBlocklisting sets instruction to IGNORED
        fakeFolder.sync_once ();

        if (vfsMode != Vfs.Off) {
            fakeFolder.sync_journal ().internalPinStates ().setForPath ("", PinState.PinState.ALWAYS_LOCAL);
            fakeFolder.sync_once ();
        }

        QVERIFY (!fakeFolder.current_local_state ().find (src));
        QVERIFY (fakeFolder.current_local_state ().find (getName (dest)));
        if (vfsMode == Vfs.WithSuffix) {
            // the placeholder was not restored as it is still in error state
            QVERIFY (!fakeFolder.current_local_state ().find (dest));
        }
        QVERIFY (fakeFolder.current_remote_state ().find (src));
        QVERIFY (!fakeFolder.current_remote_state ().find (dest));
    }

}

QTEST_GUILESS_MAIN (TestSyncMove)
