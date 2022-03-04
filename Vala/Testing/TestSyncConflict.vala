/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using Occ;

namespace Testing {

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

SyncJournalFileRecord dbRecord (FakeFolder folder, string path) {
    SyncJournalFileRecord record;
    folder.sync_journal ().getFileRecord (path, record);
    return record;
}

class TestSyncConflict : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testNoUpload () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        fakeFolder.local_modifier ().set_contents ("A/a1", 'L');
        fakeFolder.remote_modifier ().set_contents ("A/a1", 'R');
        fakeFolder.local_modifier ().append_byte ("A/a2");
        fakeFolder.remote_modifier ().append_byte ("A/a2");
        fakeFolder.remote_modifier ().append_byte ("A/a2");
        QVERIFY (fakeFolder.sync_once ());

        // Verify that the conflict names don't have the user name
        for (var name : findConflicts (fakeFolder.current_local_state ().children["A"])) {
            QVERIFY (!name.contains (fakeFolder.sync_engine ().account ().davDisplayName ()));
        }

        QVERIFY (expectAndWipeConflict (fakeFolder.local_modifier (), fakeFolder.current_local_state (), "A/a1"));
        QVERIFY (expectAndWipeConflict (fakeFolder.local_modifier (), fakeFolder.current_local_state (), "A/a2"));
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testUploadAfterDownload () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "uploadConflictFiles", true } });
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        GLib.HashMap<GLib.ByteArray, string> conflictMap;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == QNetworkAccessManager.PutOperation) {
                if (request.rawHeader ("OC-Conflict") == "1") {
                    var baseFileId = request.rawHeader ("OC-ConflictBaseFileId");
                    var components = request.url ().toString ().split ('/');
                    string conflictFile = components.mid (components.size () - 2).join ('/');
                    conflictMap[baseFileId] = conflictFile;
                    [&] {
                        QVERIFY (!baseFileId.isEmpty ());
                        QCOMPARE (request.rawHeader ("OC-ConflictInitialBasePath"), Utility.conflictFileBaseNameFromPattern (conflictFile.toUtf8 ()));
                    } ();
                }
            }
            return null;
        });

        fakeFolder.local_modifier ().set_contents ("A/a1", 'L');
        fakeFolder.remote_modifier ().set_contents ("A/a1", 'R');
        fakeFolder.local_modifier ().append_byte ("A/a2");
        fakeFolder.remote_modifier ().append_byte ("A/a2");
        fakeFolder.remote_modifier ().append_byte ("A/a2");
        QVERIFY (fakeFolder.sync_once ());
        var local = fakeFolder.current_local_state ();
        var remote = fakeFolder.current_remote_state ();
        QCOMPARE (local, remote);

        var a1FileId = fakeFolder.remote_modifier ().find ("A/a1").file_identifier;
        var a2FileId = fakeFolder.remote_modifier ().find ("A/a2").file_identifier;
        QVERIFY (conflictMap.contains (a1FileId));
        QVERIFY (conflictMap.contains (a2FileId));
        QCOMPARE (conflictMap.size (), 2);
        QCOMPARE (Utility.conflictFileBaseNameFromPattern (conflictMap[a1FileId].toUtf8 ()), GLib.ByteArray ("A/a1"));

        // Check that the conflict file contains the username
        QVERIFY (conflictMap[a1FileId].contains (string (" (conflicted copy %1 ").arg (fakeFolder.sync_engine ().account ().davDisplayName ())));

        QCOMPARE (remote.find (conflictMap[a1FileId]).content_char, 'L');
        QCOMPARE (remote.find ("A/a1").content_char, 'R');

        QCOMPARE (remote.find (conflictMap[a2FileId]).size, 5);
        QCOMPARE (remote.find ("A/a2").size, 6);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSeparateUpload () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "uploadConflictFiles", true } });
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        GLib.HashMap<GLib.ByteArray, string> conflictMap;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == QNetworkAccessManager.PutOperation) {
                if (request.rawHeader ("OC-Conflict") == "1") {
                    var baseFileId = request.rawHeader ("OC-ConflictBaseFileId");
                    var components = request.url ().toString ().split ('/');
                    string conflictFile = components.mid (components.size () - 2).join ('/');
                    conflictMap[baseFileId] = conflictFile;
                    [&] {
                        QVERIFY (!baseFileId.isEmpty ());
                        QCOMPARE (request.rawHeader ("OC-ConflictInitialBasePath"), Utility.conflictFileBaseNameFromPattern (conflictFile.toUtf8 ()));
                    } ();
                }
            }
            return null;
        });

        // Explicitly add a conflict file to simulate the case where the upload of the
        // file didn't finish in the same sync run that the conflict was created.
        // To do that we need to create a mock conflict record.
        var a1FileId = fakeFolder.remote_modifier ().find ("A/a1").file_identifier;
        string conflictName = QLatin1String ("A/a1 (conflicted copy me 1234)");
        fakeFolder.local_modifier ().insert (conflictName, 64, 'L');
        ConflictRecord conflictRecord;
        conflictRecord.path = conflictName.toUtf8 ();
        conflictRecord.baseFileId = a1FileId;
        conflictRecord.initialBasePath = "A/a1";
        fakeFolder.sync_journal ().setConflictRecord (conflictRecord);
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (conflictMap.size (), 1);
        QCOMPARE (conflictMap[a1FileId], conflictName);
        QCOMPARE (fakeFolder.current_remote_state ().find (conflictMap[a1FileId]).content_char, 'L');
        conflictMap.clear ();

        // Now the user can locally alter the conflict file and it will be uploaded
        // as usual.
        fakeFolder.local_modifier ().set_contents (conflictName, 'P');
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (conflictMap.size (), 1);
        QCOMPARE (conflictMap[a1FileId], conflictName);
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        conflictMap.clear ();

        // Similarly, remote modifications of conflict files get propagated downwards
        fakeFolder.remote_modifier ().set_contents (conflictName, 'Q');
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QVERIFY (conflictMap.isEmpty ());

        // Conflict files for conflict files!
        var a1ConflictFileId = fakeFolder.remote_modifier ().find (conflictName).file_identifier;
        fakeFolder.remote_modifier ().append_byte (conflictName);
        fakeFolder.remote_modifier ().append_byte (conflictName);
        fakeFolder.local_modifier ().append_byte (conflictName);
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (conflictMap.size (), 1);
        QVERIFY (conflictMap.contains (a1ConflictFileId));
        QCOMPARE (fakeFolder.current_remote_state ().find (conflictName).size, 66);
        QCOMPARE (fakeFolder.current_remote_state ().find (conflictMap[a1ConflictFileId]).size, 65);
        conflictMap.clear ();
    }

    // What happens if we download a conflict file? Is the metadata set up correctly?
    private on_ void testDownloadingConflictFile () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "uploadConflictFiles", true } });
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // With no headers from the server
        fakeFolder.remote_modifier ().insert ("A/a1 (conflicted copy 1234)");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        var conflictRecord = fakeFolder.sync_journal ().conflictRecord ("A/a1 (conflicted copy 1234)");
        QVERIFY (conflictRecord.isValid ());
        QCOMPARE (conflictRecord.baseFileId, fakeFolder.remote_modifier ().find ("A/a1").file_identifier);
        QCOMPARE (conflictRecord.initialBasePath, GLib.ByteArray ("A/a1"));

        // Now with server headers
        GLib.Object parent;
        var a2FileId = fakeFolder.remote_modifier ().find ("A/a2").file_identifier;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == QNetworkAccessManager.GetOperation) {
                var reply = new FakeGetReply (fakeFolder.remote_modifier (), operation, request, parent);
                reply.setRawHeader ("OC-Conflict", "1");
                reply.setRawHeader ("OC-ConflictBaseFileId", a2FileId);
                reply.setRawHeader ("OC-ConflictBaseMtime", "1234");
                reply.setRawHeader ("OC-ConflictBaseEtag", "etag");
                reply.setRawHeader ("OC-ConflictInitialBasePath", "A/original");
                return reply;
            }
            return null;
        });
        fakeFolder.remote_modifier ().insert ("A/really-a-conflict"); // doesn't look like a conflict, but headers say it is
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        conflictRecord = fakeFolder.sync_journal ().conflictRecord ("A/really-a-conflict");
        QVERIFY (conflictRecord.isValid ());
        QCOMPARE (conflictRecord.baseFileId, a2FileId);
        QCOMPARE (conflictRecord.baseModtime, 1234);
        QCOMPARE (conflictRecord.baseEtag, GLib.ByteArray ("etag"));
        QCOMPARE (conflictRecord.initialBasePath, GLib.ByteArray ("A/original"));
    }

    // Check that conflict records are removed when the file is gone
    private on_ void testConflictRecordRemoval1 () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "uploadConflictFiles", true } });
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // Make conflict records
        ConflictRecord conflictRecord;
        conflictRecord.path = "A/a1";
        fakeFolder.sync_journal ().setConflictRecord (conflictRecord);
        conflictRecord.path = "A/a2";
        fakeFolder.sync_journal ().setConflictRecord (conflictRecord);

        // A nothing-to-sync keeps them alive
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QVERIFY (fakeFolder.sync_journal ().conflictRecord ("A/a1").isValid ());
        QVERIFY (fakeFolder.sync_journal ().conflictRecord ("A/a2").isValid ());

        // When the file is removed, the record is removed too
        fakeFolder.local_modifier ().remove ("A/a2");
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QVERIFY (fakeFolder.sync_journal ().conflictRecord ("A/a1").isValid ());
        QVERIFY (!fakeFolder.sync_journal ().conflictRecord ("A/a2").isValid ());
    }

    // Same test, but with uploadConflictFiles == false
    private on_ void testConflictRecordRemoval2 () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "uploadConflictFiles", false } });
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // Create two conflicts
        fakeFolder.local_modifier ().append_byte ("A/a1");
        fakeFolder.local_modifier ().append_byte ("A/a1");
        fakeFolder.remote_modifier ().append_byte ("A/a1");
        fakeFolder.local_modifier ().append_byte ("A/a2");
        fakeFolder.local_modifier ().append_byte ("A/a2");
        fakeFolder.remote_modifier ().append_byte ("A/a2");
        QVERIFY (fakeFolder.sync_once ());

        var conflicts = findConflicts (fakeFolder.current_local_state ().children["A"]);
        GLib.ByteArray a1conflict;
        GLib.ByteArray a2conflict;
        for (var & conflict : conflicts) {
            if (conflict.contains ("a1"))
                a1conflict = conflict.toUtf8 ();
            if (conflict.contains ("a2"))
                a2conflict = conflict.toUtf8 ();
        }

        // A nothing-to-sync keeps them alive
        QVERIFY (fakeFolder.sync_once ());
        QVERIFY (fakeFolder.sync_journal ().conflictRecord (a1conflict).isValid ());
        QVERIFY (fakeFolder.sync_journal ().conflictRecord (a2conflict).isValid ());

        // When the file is removed, the record is removed too
        fakeFolder.local_modifier ().remove (a2conflict);
        QVERIFY (fakeFolder.sync_once ());
        QVERIFY (fakeFolder.sync_journal ().conflictRecord (a1conflict).isValid ());
        QVERIFY (!fakeFolder.sync_journal ().conflictRecord (a2conflict).isValid ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testConflictFileBaseName_data () {
        QTest.addColumn<string> ("input");
        QTest.addColumn<string> ("output");

        QTest.newRow ("nomatch1")
            + "a/b/foo"
            + "";
        QTest.newRow ("nomatch2")
            + "a/b/foo.txt"
            + "";
        QTest.newRow ("nomatch3")
            + "a/b/foo_conflict"
            + "";
        QTest.newRow ("nomatch4")
            + "a/b/foo_conflict.txt"
            + "";

        QTest.newRow ("match1")
            + "a/b/foo_conflict-123.txt"
            + "a/b/foo.txt";
        QTest.newRow ("match2")
            + "a/b/foo_conflict-foo-123.txt"
            + "a/b/foo.txt";

        QTest.newRow ("match3")
            + "a/b/foo_conflict-123"
            + "a/b/foo";
        QTest.newRow ("match4")
            + "a/b/foo_conflict-foo-123"
            + "a/b/foo";

        // new style
        QTest.newRow ("newmatch1")
            + "a/b/foo (conflicted copy 123).txt"
            + "a/b/foo.txt";
        QTest.newRow ("newmatch2")
            + "a/b/foo (conflicted copy foo 123).txt"
            + "a/b/foo.txt";

        QTest.newRow ("newmatch3")
            + "a/b/foo (conflicted copy 123)"
            + "a/b/foo";
        QTest.newRow ("newmatch4")
            + "a/b/foo (conflicted copy foo 123)"
            + "a/b/foo";

        QTest.newRow ("newmatch5")
            + "a/b/foo (conflicted copy foo 123) bla"
            + "a/b/foo bla";

        QTest.newRow ("newmatch6")
            + "a/b/foo (conflicted copy foo.bar 123)"
            + "a/b/foo";

        // double conflict files
        QTest.newRow ("double1")
            + "a/b/foo_conflict-123_conflict-456.txt"
            + "a/b/foo_conflict-123.txt";
        QTest.newRow ("double2")
            + "a/b/foo_conflict-foo-123_conflict-bar-456.txt"
            + "a/b/foo_conflict-foo-123.txt";
        QTest.newRow ("double3")
            + "a/b/foo (conflicted copy 123) (conflicted copy 456).txt"
            + "a/b/foo (conflicted copy 123).txt";
        QTest.newRow ("double4")
            + "a/b/foo (conflicted copy 123)this.conflict-456.txt"
            + "a/b/foo (conflicted copy 123).txt";
        QTest.newRow ("double5")
            + "a/b/foo_conflict-123 (conflicted copy 456).txt"
            + "a/b/foo_conflict-123.txt";
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testConflictFileBaseName () {
        QFETCH (string, input);
        QFETCH (string, output);
        QCOMPARE (Utility.conflictFileBaseNameFromPattern (input.toUtf8 ()), output.toUtf8 ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testLocalDirRemoteFileConflict () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "uploadConflictFiles", true } });
        ItemCompletedSpy completeSpy (fakeFolder);

        var on_signal_cleanup = [&] () {
            completeSpy.clear ();
        }
        on_signal_cleanup ();

        // 1) a NEW/NEW conflict
        fakeFolder.local_modifier ().mkdir ("Z");
        fakeFolder.local_modifier ().mkdir ("Z/subdir");
        fakeFolder.local_modifier ().insert ("Z/foo");
        fakeFolder.remote_modifier ().insert ("Z", 63);

        // 2) local file becomes a directory; remote file changes
        fakeFolder.local_modifier ().remove ("A/a1");
        fakeFolder.local_modifier ().mkdir ("A/a1");
        fakeFolder.local_modifier ().insert ("A/a1/bar");
        fakeFolder.remote_modifier ().append_byte ("A/a1");

        // 3) local directory gets a new file; remote directory becomes a file
        fakeFolder.local_modifier ().insert ("B/zzz");
        fakeFolder.remote_modifier ().remove ("B");
        fakeFolder.remote_modifier ().insert ("B", 31);

        QVERIFY (fakeFolder.sync_once ());

        var conflicts = findConflicts (fakeFolder.current_local_state ());
        conflicts += findConflicts (fakeFolder.current_local_state ().children["A"]);
        QCOMPARE (conflicts.size (), 3);
        std.sort (conflicts.begin (), conflicts.end ());

        var conflictRecords = fakeFolder.sync_journal ().conflictRecordPaths ();
        QCOMPARE (conflictRecords.size (), 3);
        std.sort (conflictRecords.begin (), conflictRecords.end ());

        // 1)
        QVERIFY (itemConflict (completeSpy, "Z"));
        QCOMPARE (fakeFolder.current_local_state ().find ("Z").size, 63);
        QVERIFY (conflicts[2].contains ("Z"));
        QCOMPARE (conflicts[2].toUtf8 (), conflictRecords[2]);
        QVERIFY (GLib.FileInfo (fakeFolder.local_path () + conflicts[2]).isDir ());
        QVERIFY (GLib.File.exists (fakeFolder.local_path () + conflicts[2] + "/foo"));

        // 2)
        QVERIFY (itemConflict (completeSpy, "A/a1"));
        QCOMPARE (fakeFolder.current_local_state ().find ("A/a1").size, 5);
        QVERIFY (conflicts[0].contains ("A/a1"));
        QCOMPARE (conflicts[0].toUtf8 (), conflictRecords[0]);
        QVERIFY (GLib.FileInfo (fakeFolder.local_path () + conflicts[0]).isDir ());
        QVERIFY (GLib.File.exists (fakeFolder.local_path () + conflicts[0] + "/bar"));

        // 3)
        QVERIFY (itemConflict (completeSpy, "B"));
        QCOMPARE (fakeFolder.current_local_state ().find ("B").size, 31);
        QVERIFY (conflicts[1].contains ("B"));
        QCOMPARE (conflicts[1].toUtf8 (), conflictRecords[1]);
        QVERIFY (GLib.FileInfo (fakeFolder.local_path () + conflicts[1]).isDir ());
        QVERIFY (GLib.File.exists (fakeFolder.local_path () + conflicts[1] + "/zzz"));

        // The contents of the conflict directories will only be uploaded after
        // another sync.
        QVERIFY (fakeFolder.sync_engine ().isAnotherSyncNeeded () == ImmediateFollowUp);
        on_signal_cleanup ();
        QVERIFY (fakeFolder.sync_once ());

        QVERIFY (itemSuccessful (completeSpy, conflicts[0], CSYNC_INSTRUCTION_NEW));
        QVERIFY (itemSuccessful (completeSpy, conflicts[0] + "/bar", CSYNC_INSTRUCTION_NEW));
        QVERIFY (itemSuccessful (completeSpy, conflicts[1], CSYNC_INSTRUCTION_NEW));
        QVERIFY (itemSuccessful (completeSpy, conflicts[1] + "/zzz", CSYNC_INSTRUCTION_NEW));
        QVERIFY (itemSuccessful (completeSpy, conflicts[2], CSYNC_INSTRUCTION_NEW));
        QVERIFY (itemSuccessful (completeSpy, conflicts[2] + "/foo", CSYNC_INSTRUCTION_NEW));
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testLocalFileRemoteDirConflict () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        fakeFolder.sync_engine ().account ().setCapabilities ({ { "uploadConflictFiles", true } });
        ItemCompletedSpy completeSpy (fakeFolder);

        // 1) a NEW/NEW conflict
        fakeFolder.remote_modifier ().mkdir ("Z");
        fakeFolder.remote_modifier ().mkdir ("Z/subdir");
        fakeFolder.remote_modifier ().insert ("Z/foo");
        fakeFolder.local_modifier ().insert ("Z");

        // 2) local directory becomes file : remote directory adds file
        fakeFolder.local_modifier ().remove ("A");
        fakeFolder.local_modifier ().insert ("A", 63);
        fakeFolder.remote_modifier ().insert ("A/bar");

        // 3) local file changes; remote file becomes directory
        fakeFolder.local_modifier ().append_byte ("B/b1");
        fakeFolder.remote_modifier ().remove ("B/b1");
        fakeFolder.remote_modifier ().mkdir ("B/b1");
        fakeFolder.remote_modifier ().insert ("B/b1/zzz");

        QVERIFY (fakeFolder.sync_once ());
        var conflicts = findConflicts (fakeFolder.current_local_state ());
        conflicts += findConflicts (fakeFolder.current_local_state ().children["B"]);
        QCOMPARE (conflicts.size (), 3);
        std.sort (conflicts.begin (), conflicts.end ());

        var conflictRecords = fakeFolder.sync_journal ().conflictRecordPaths ();
        QCOMPARE (conflictRecords.size (), 3);
        std.sort (conflictRecords.begin (), conflictRecords.end ());

        // 1)
        QVERIFY (itemConflict (completeSpy, "Z"));
        QVERIFY (conflicts[2].contains ("Z"));
        QCOMPARE (conflicts[2].toUtf8 (), conflictRecords[2]);

        // 2)
        QVERIFY (itemConflict (completeSpy, "A"));
        QVERIFY (conflicts[0].contains ("A"));
        QCOMPARE (conflicts[0].toUtf8 (), conflictRecords[0]);

        // 3)
        QVERIFY (itemConflict (completeSpy, "B/b1"));
        QVERIFY (conflicts[1].contains ("B/b1"));
        QCOMPARE (conflicts[1].toUtf8 (), conflictRecords[1]);

        // Also verifies that conflicts were uploaded
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testTypeConflictWithMove () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy completeSpy (fakeFolder);

        // the remote becomes a file, but a file inside the directory has moved away!
        fakeFolder.remote_modifier ().remove ("A");
        fakeFolder.remote_modifier ().insert ("A");
        fakeFolder.local_modifier ().rename ("A/a1", "a1");

        // same, but with a new file inside the directory locally
        fakeFolder.remote_modifier ().remove ("B");
        fakeFolder.remote_modifier ().insert ("B");
        fakeFolder.local_modifier ().rename ("B/b1", "b1");
        fakeFolder.local_modifier ().insert ("B/new");

        QVERIFY (fakeFolder.sync_once ());

        QVERIFY (itemSuccessful (completeSpy, "A", CSYNC_INSTRUCTION_TYPE_CHANGE));
        QVERIFY (itemConflict (completeSpy, "B"));

        var conflicts = findConflicts (fakeFolder.current_local_state ());
        std.sort (conflicts.begin (), conflicts.end ());
        QVERIFY (conflicts.size () == 2);
        QVERIFY (conflicts[0].contains ("A (conflicted copy"));
        QVERIFY (conflicts[1].contains ("B (conflicted copy"));
        for (var& conflict : conflicts)
            QDir (fakeFolder.local_path () + conflict).removeRecursively ();
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());

        // Currently a1 and b1 don't get moved, but redownloaded
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testTypeChange () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy completeSpy (fakeFolder);

        // directory becomes file
        fakeFolder.remote_modifier ().remove ("A");
        fakeFolder.remote_modifier ().insert ("A");
        fakeFolder.local_modifier ().remove ("B");
        fakeFolder.local_modifier ().insert ("B");

        // file becomes directory
        fakeFolder.remote_modifier ().remove ("C/c1");
        fakeFolder.remote_modifier ().mkdir ("C/c1");
        fakeFolder.remote_modifier ().insert ("C/c1/foo");
        fakeFolder.local_modifier ().remove ("C/c2");
        fakeFolder.local_modifier ().mkdir ("C/c2");
        fakeFolder.local_modifier ().insert ("C/c2/bar");

        QVERIFY (fakeFolder.sync_once ());

        QVERIFY (itemSuccessful (completeSpy, "A", CSYNC_INSTRUCTION_TYPE_CHANGE));
        QVERIFY (itemSuccessful (completeSpy, "B", CSYNC_INSTRUCTION_TYPE_CHANGE));
        QVERIFY (itemSuccessful (completeSpy, "C/c1", CSYNC_INSTRUCTION_TYPE_CHANGE));
        QVERIFY (itemSuccessful (completeSpy, "C/c2", CSYNC_INSTRUCTION_TYPE_CHANGE));

        // A becomes a conflict because we don't delete folders with files
        // inside of them!
        var conflicts = findConflicts (fakeFolder.current_local_state ());
        QVERIFY (conflicts.size () == 1);
        QVERIFY (conflicts[0].contains ("A (conflicted copy"));
        for (var& conflict : conflicts)
            QDir (fakeFolder.local_path () + conflict).removeRecursively ();

        QVERIFY (fakeFolder.sync_engine ().isAnotherSyncNeeded () == ImmediateFollowUp);
        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }

    // Test what happens if we remove entries both on the server, and locally
    private on_ void testRemoveRemove () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        fakeFolder.remote_modifier ().remove ("A");
        fakeFolder.local_modifier ().remove ("A");
        fakeFolder.remote_modifier ().remove ("B/b1");
        fakeFolder.local_modifier ().remove ("B/b1");

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        var expectedState = fakeFolder.current_local_state ();

        QVERIFY (fakeFolder.sync_once ());

        QCOMPARE (fakeFolder.current_local_state (), expectedState);
        QCOMPARE (fakeFolder.current_remote_state (), expectedState);

        QVERIFY (dbRecord (fakeFolder, "B/b2").isValid ());

        QVERIFY (!dbRecord (fakeFolder, "B/b1").isValid ());
        QVERIFY (!dbRecord (fakeFolder, "A/a1").isValid ());
        QVERIFY (!dbRecord (fakeFolder, "A").isValid ());
    }
}

QTEST_GUILESS_MAIN (TestSyncConflict)
