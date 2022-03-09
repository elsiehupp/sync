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
    var item = spy.find_item (path);
    return item.status == SyncFileItem.Status.SUCCESS && item.instruction == instr;
}

bool itemConflict (ItemCompletedSpy spy, string path) {
    var item = spy.find_item (path);
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
    PathComponents path_components (path);
    var base = state.find (path_components.parent_directory_components ());
    if (!base)
        return false;
    for (var item : base.children) {
        if (item.name.starts_with (path_components.filename ()) && item.name.contains (" (conflicted copy")) {
            local.remove (item.path ());
            return true;
        }
    }
    return false;
}

SyncJournalFileRecord dbRecord (FakeFolder folder, string path) {
    SyncJournalFileRecord record;
    folder.sync_journal ().get_file_record (path, record);
    return record;
}

class TestSyncConflict : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void testNoUpload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        fake_folder.local_modifier ().set_contents ("A/a1", 'L');
        fake_folder.remote_modifier ().set_contents ("A/a1", 'R');
        fake_folder.local_modifier ().append_byte ("A/a2");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());

        // Verify that the conflict names don't have the user name
        for (var name : findConflicts (fake_folder.current_local_state ().children["A"])) {
            GLib.assert_true (!name.contains (fake_folder.sync_engine ().account ().davDisplayName ()));
        }

        GLib.assert_true (expectAndWipeConflict (fake_folder.local_modifier (), fake_folder.current_local_state (), "A/a1"));
        GLib.assert_true (expectAndWipeConflict (fake_folder.local_modifier (), fake_folder.current_local_state (), "A/a2"));
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void testUploadAfterDownload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account ().set_capabilities ({ { "uploadConflictFiles", true } });
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        GLib.HashMap<GLib.ByteArray, string> conflictMap;
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == Soup.PutOperation) {
                if (request.raw_header ("OC-Conflict") == "1") {
                    var baseFileId = request.raw_header ("OC-ConflictBaseFileId");
                    var components = request.url ().to_string ().split ('/');
                    string conflictFile = components.mid (components.size () - 2).join ('/');
                    conflictMap[baseFileId] = conflictFile;
                    [&] {
                        GLib.assert_true (!baseFileId.is_empty ());
                        GLib.assert_cmp (request.raw_header ("OC-ConflictInitialBasePath"), Utility.conflictFileBaseNameFromPattern (conflictFile));
                    } ();
                }
            }
            return null;
        });

        fake_folder.local_modifier ().set_contents ("A/a1", 'L');
        fake_folder.remote_modifier ().set_contents ("A/a1", 'R');
        fake_folder.local_modifier ().append_byte ("A/a2");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());
        var local = fake_folder.current_local_state ();
        var remote = fake_folder.current_remote_state ();
        GLib.assert_cmp (local, remote);

        var a1FileId = fake_folder.remote_modifier ().find ("A/a1").file_identifier;
        var a2FileId = fake_folder.remote_modifier ().find ("A/a2").file_identifier;
        GLib.assert_true (conflictMap.contains (a1FileId));
        GLib.assert_true (conflictMap.contains (a2FileId));
        GLib.assert_cmp (conflictMap.size (), 2);
        GLib.assert_cmp (Utility.conflictFileBaseNameFromPattern (conflictMap[a1FileId]), GLib.ByteArray ("A/a1"));

        // Check that the conflict file contains the username
        GLib.assert_true (conflictMap[a1FileId].contains (string (" (conflicted copy %1 ").arg (fake_folder.sync_engine ().account ().davDisplayName ())));

        GLib.assert_cmp (remote.find (conflictMap[a1FileId]).content_char, 'L');
        GLib.assert_cmp (remote.find ("A/a1").content_char, 'R');

        GLib.assert_cmp (remote.find (conflictMap[a2FileId]).size, 5);
        GLib.assert_cmp (remote.find ("A/a2").size, 6);
    }


    /***********************************************************
    ***********************************************************/
    private void testSeparateUpload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account ().set_capabilities ({ { "uploadConflictFiles", true } });
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        GLib.HashMap<GLib.ByteArray, string> conflictMap;
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == Soup.PutOperation) {
                if (request.raw_header ("OC-Conflict") == "1") {
                    var baseFileId = request.raw_header ("OC-ConflictBaseFileId");
                    var components = request.url ().to_string ().split ('/');
                    string conflictFile = components.mid (components.size () - 2).join ('/');
                    conflictMap[baseFileId] = conflictFile;
                    [&] {
                        GLib.assert_true (!baseFileId.is_empty ());
                        GLib.assert_cmp (request.raw_header ("OC-ConflictInitialBasePath"), Utility.conflictFileBaseNameFromPattern (conflictFile));
                    } ();
                }
            }
            return null;
        });

        // Explicitly add a conflict file to simulate the case where the upload of the
        // file didn't finish in the same sync run that the conflict was created.
        // To do that we need to create a mock conflict record.
        var a1FileId = fake_folder.remote_modifier ().find ("A/a1").file_identifier;
        string conflictName = "A/a1 (conflicted copy me 1234)";
        fake_folder.local_modifier ().insert (conflictName, 64, 'L');
        ConflictRecord conflictRecord;
        conflictRecord.path = conflictName;
        conflictRecord.baseFileId = a1FileId;
        conflictRecord.initialBasePath = "A/a1";
        fake_folder.sync_journal ().setConflictRecord (conflictRecord);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (conflictMap.size (), 1);
        GLib.assert_cmp (conflictMap[a1FileId], conflictName);
        GLib.assert_cmp (fake_folder.current_remote_state ().find (conflictMap[a1FileId]).content_char, 'L');
        conflictMap.clear ();

        // Now the user can locally alter the conflict file and it will be uploaded
        // as usual.
        fake_folder.local_modifier ().set_contents (conflictName, 'P');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (conflictMap.size (), 1);
        GLib.assert_cmp (conflictMap[a1FileId], conflictName);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        conflictMap.clear ();

        // Similarly, remote modifications of conflict files get propagated downwards
        fake_folder.remote_modifier ().set_contents (conflictName, 'Q');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_true (conflictMap.is_empty ());

        // Conflict files for conflict files!
        var a1ConflictFileId = fake_folder.remote_modifier ().find (conflictName).file_identifier;
        fake_folder.remote_modifier ().append_byte (conflictName);
        fake_folder.remote_modifier ().append_byte (conflictName);
        fake_folder.local_modifier ().append_byte (conflictName);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (conflictMap.size (), 1);
        GLib.assert_true (conflictMap.contains (a1ConflictFileId));
        GLib.assert_cmp (fake_folder.current_remote_state ().find (conflictName).size, 66);
        GLib.assert_cmp (fake_folder.current_remote_state ().find (conflictMap[a1ConflictFileId]).size, 65);
        conflictMap.clear ();
    }

    // What happens if we download a conflict file? Is the metadata set up correctly?
    private void testDownloadingConflictFile () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account ().set_capabilities ({ { "uploadConflictFiles", true } });
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // With no headers from the server
        fake_folder.remote_modifier ().insert ("A/a1 (conflicted copy 1234)");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        var conflictRecord = fake_folder.sync_journal ().conflictRecord ("A/a1 (conflicted copy 1234)");
        GLib.assert_true (conflictRecord.is_valid ());
        GLib.assert_cmp (conflictRecord.baseFileId, fake_folder.remote_modifier ().find ("A/a1").file_identifier);
        GLib.assert_cmp (conflictRecord.initialBasePath, GLib.ByteArray ("A/a1"));

        // Now with server headers
        GLib.Object parent;
        var a2FileId = fake_folder.remote_modifier ().find ("A/a2").file_identifier;
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == Soup.GetOperation) {
                var reply = new FakeGetReply (fake_folder.remote_modifier (), operation, request, parent);
                reply.set_raw_header ("OC-Conflict", "1");
                reply.set_raw_header ("OC-ConflictBaseFileId", a2FileId);
                reply.set_raw_header ("OC-ConflictBaseMtime", "1234");
                reply.set_raw_header ("OC-ConflictBaseEtag", "etag");
                reply.set_raw_header ("OC-ConflictInitialBasePath", "A/original");
                return reply;
            }
            return null;
        });
        fake_folder.remote_modifier ().insert ("A/really-a-conflict"); // doesn't look like a conflict, but headers say it is
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        conflictRecord = fake_folder.sync_journal ().conflictRecord ("A/really-a-conflict");
        GLib.assert_true (conflictRecord.is_valid ());
        GLib.assert_cmp (conflictRecord.baseFileId, a2FileId);
        GLib.assert_cmp (conflictRecord.baseModtime, 1234);
        GLib.assert_cmp (conflictRecord.baseEtag, GLib.ByteArray ("etag"));
        GLib.assert_cmp (conflictRecord.initialBasePath, GLib.ByteArray ("A/original"));
    }

    // Check that conflict records are removed when the file is gone
    private void testConflictRecordRemoval1 () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account ().set_capabilities ({ { "uploadConflictFiles", true } });
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // Make conflict records
        ConflictRecord conflictRecord;
        conflictRecord.path = "A/a1";
        fake_folder.sync_journal ().setConflictRecord (conflictRecord);
        conflictRecord.path = "A/a2";
        fake_folder.sync_journal ().setConflictRecord (conflictRecord);

        // A nothing-to-sync keeps them alive
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.sync_journal ().conflictRecord ("A/a1").is_valid ());
        GLib.assert_true (fake_folder.sync_journal ().conflictRecord ("A/a2").is_valid ());

        // When the file is removed, the record is removed too
        fake_folder.local_modifier ().remove ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.sync_journal ().conflictRecord ("A/a1").is_valid ());
        GLib.assert_true (!fake_folder.sync_journal ().conflictRecord ("A/a2").is_valid ());
    }

    // Same test, but with uploadConflictFiles == false
    private void testConflictRecordRemoval2 () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account ().set_capabilities ({ { "uploadConflictFiles", false } });
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // Create two conflicts
        fake_folder.local_modifier ().append_byte ("A/a1");
        fake_folder.local_modifier ().append_byte ("A/a1");
        fake_folder.remote_modifier ().append_byte ("A/a1");
        fake_folder.local_modifier ().append_byte ("A/a2");
        fake_folder.local_modifier ().append_byte ("A/a2");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());

        var conflicts = findConflicts (fake_folder.current_local_state ().children["A"]);
        GLib.ByteArray a1conflict;
        GLib.ByteArray a2conflict;
        for (var & conflict : conflicts) {
            if (conflict.contains ("a1"))
                a1conflict = conflict;
            if (conflict.contains ("a2"))
                a2conflict = conflict;
        }

        // A nothing-to-sync keeps them alive
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.sync_journal ().conflictRecord (a1conflict).is_valid ());
        GLib.assert_true (fake_folder.sync_journal ().conflictRecord (a2conflict).is_valid ());

        // When the file is removed, the record is removed too
        fake_folder.local_modifier ().remove (a2conflict);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.sync_journal ().conflictRecord (a1conflict).is_valid ());
        GLib.assert_true (!fake_folder.sync_journal ().conflictRecord (a2conflict).is_valid ());
    }


    /***********************************************************
    ***********************************************************/
    private void testConflictFileBaseName_data () {
        QTest.add_column<string> ("input");
        QTest.add_column<string> ("output");

        QTest.new_row ("nomatch1")
            + "a/b/foo"
            + "";
        QTest.new_row ("nomatch2")
            + "a/b/foo.txt"
            + "";
        QTest.new_row ("nomatch3")
            + "a/b/foo_conflict"
            + "";
        QTest.new_row ("nomatch4")
            + "a/b/foo_conflict.txt"
            + "";

        QTest.new_row ("match1")
            + "a/b/foo_conflict-123.txt"
            + "a/b/foo.txt";
        QTest.new_row ("match2")
            + "a/b/foo_conflict-foo-123.txt"
            + "a/b/foo.txt";

        QTest.new_row ("match3")
            + "a/b/foo_conflict-123"
            + "a/b/foo";
        QTest.new_row ("match4")
            + "a/b/foo_conflict-foo-123"
            + "a/b/foo";

        // new style
        QTest.new_row ("newmatch1")
            + "a/b/foo (conflicted copy 123).txt"
            + "a/b/foo.txt";
        QTest.new_row ("newmatch2")
            + "a/b/foo (conflicted copy foo 123).txt"
            + "a/b/foo.txt";

        QTest.new_row ("newmatch3")
            + "a/b/foo (conflicted copy 123)"
            + "a/b/foo";
        QTest.new_row ("newmatch4")
            + "a/b/foo (conflicted copy foo 123)"
            + "a/b/foo";

        QTest.new_row ("newmatch5")
            + "a/b/foo (conflicted copy foo 123) bla"
            + "a/b/foo bla";

        QTest.new_row ("newmatch6")
            + "a/b/foo (conflicted copy foo.bar 123)"
            + "a/b/foo";

        // double conflict files
        QTest.new_row ("double1")
            + "a/b/foo_conflict-123_conflict-456.txt"
            + "a/b/foo_conflict-123.txt";
        QTest.new_row ("double2")
            + "a/b/foo_conflict-foo-123_conflict-bar-456.txt"
            + "a/b/foo_conflict-foo-123.txt";
        QTest.new_row ("double3")
            + "a/b/foo (conflicted copy 123) (conflicted copy 456).txt"
            + "a/b/foo (conflicted copy 123).txt";
        QTest.new_row ("double4")
            + "a/b/foo (conflicted copy 123)this.conflict-456.txt"
            + "a/b/foo (conflicted copy 123).txt";
        QTest.new_row ("double5")
            + "a/b/foo_conflict-123 (conflicted copy 456).txt"
            + "a/b/foo_conflict-123.txt";
    }


    /***********************************************************
    ***********************************************************/
    private void testConflictFileBaseName () {
        QFETCH (string, input);
        QFETCH (string, output);
        GLib.assert_cmp (Utility.conflictFileBaseNameFromPattern (input), output);
    }


    /***********************************************************
    ***********************************************************/
    private void testLocalDirRemoteFileConflict () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account ().set_capabilities ({ { "uploadConflictFiles", true } });
        ItemCompletedSpy complete_spy (fake_folder);

        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        // 1) a NEW/NEW conflict
        fake_folder.local_modifier ().mkdir ("Z");
        fake_folder.local_modifier ().mkdir ("Z/subdir");
        fake_folder.local_modifier ().insert ("Z/foo");
        fake_folder.remote_modifier ().insert ("Z", 63);

        // 2) local file becomes a directory; remote file changes
        fake_folder.local_modifier ().remove ("A/a1");
        fake_folder.local_modifier ().mkdir ("A/a1");
        fake_folder.local_modifier ().insert ("A/a1/bar");
        fake_folder.remote_modifier ().append_byte ("A/a1");

        // 3) local directory gets a new file; remote directory becomes a file
        fake_folder.local_modifier ().insert ("B/zzz");
        fake_folder.remote_modifier ().remove ("B");
        fake_folder.remote_modifier ().insert ("B", 31);

        GLib.assert_true (fake_folder.sync_once ());

        var conflicts = findConflicts (fake_folder.current_local_state ());
        conflicts += findConflicts (fake_folder.current_local_state ().children["A"]);
        GLib.assert_cmp (conflicts.size (), 3);
        std.sort (conflicts.begin (), conflicts.end ());

        var conflictRecords = fake_folder.sync_journal ().conflictRecordPaths ();
        GLib.assert_cmp (conflictRecords.size (), 3);
        std.sort (conflictRecords.begin (), conflictRecords.end ());

        // 1)
        GLib.assert_true (itemConflict (complete_spy, "Z"));
        GLib.assert_cmp (fake_folder.current_local_state ().find ("Z").size, 63);
        GLib.assert_true (conflicts[2].contains ("Z"));
        GLib.assert_cmp (conflicts[2], conflictRecords[2]);
        GLib.assert_true (GLib.FileInfo (fake_folder.local_path () + conflicts[2]).is_directory ());
        GLib.assert_true (GLib.File.exists (fake_folder.local_path () + conflicts[2] + "/foo"));

        // 2)
        GLib.assert_true (itemConflict (complete_spy, "A/a1"));
        GLib.assert_cmp (fake_folder.current_local_state ().find ("A/a1").size, 5);
        GLib.assert_true (conflicts[0].contains ("A/a1"));
        GLib.assert_cmp (conflicts[0], conflictRecords[0]);
        GLib.assert_true (GLib.FileInfo (fake_folder.local_path () + conflicts[0]).is_directory ());
        GLib.assert_true (GLib.File.exists (fake_folder.local_path () + conflicts[0] + "/bar"));

        // 3)
        GLib.assert_true (itemConflict (complete_spy, "B"));
        GLib.assert_cmp (fake_folder.current_local_state ().find ("B").size, 31);
        GLib.assert_true (conflicts[1].contains ("B"));
        GLib.assert_cmp (conflicts[1], conflictRecords[1]);
        GLib.assert_true (GLib.FileInfo (fake_folder.local_path () + conflicts[1]).is_directory ());
        GLib.assert_true (GLib.File.exists (fake_folder.local_path () + conflicts[1] + "/zzz"));

        // The contents of the conflict directories will only be uploaded after
        // another sync.
        GLib.assert_true (fake_folder.sync_engine ().is_another_sync_needed () == ImmediateFollowUp);
        on_signal_cleanup ();
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (itemSuccessful (complete_spy, conflicts[0], CSYNC_INSTRUCTION_NEW));
        GLib.assert_true (itemSuccessful (complete_spy, conflicts[0] + "/bar", CSYNC_INSTRUCTION_NEW));
        GLib.assert_true (itemSuccessful (complete_spy, conflicts[1], CSYNC_INSTRUCTION_NEW));
        GLib.assert_true (itemSuccessful (complete_spy, conflicts[1] + "/zzz", CSYNC_INSTRUCTION_NEW));
        GLib.assert_true (itemSuccessful (complete_spy, conflicts[2], CSYNC_INSTRUCTION_NEW));
        GLib.assert_true (itemSuccessful (complete_spy, conflicts[2] + "/foo", CSYNC_INSTRUCTION_NEW));
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void testLocalFileRemoteDirConflict () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account ().set_capabilities ({ { "uploadConflictFiles", true } });
        ItemCompletedSpy complete_spy (fake_folder);

        // 1) a NEW/NEW conflict
        fake_folder.remote_modifier ().mkdir ("Z");
        fake_folder.remote_modifier ().mkdir ("Z/subdir");
        fake_folder.remote_modifier ().insert ("Z/foo");
        fake_folder.local_modifier ().insert ("Z");

        // 2) local directory becomes file : remote directory adds file
        fake_folder.local_modifier ().remove ("A");
        fake_folder.local_modifier ().insert ("A", 63);
        fake_folder.remote_modifier ().insert ("A/bar");

        // 3) local file changes; remote file becomes directory
        fake_folder.local_modifier ().append_byte ("B/b1");
        fake_folder.remote_modifier ().remove ("B/b1");
        fake_folder.remote_modifier ().mkdir ("B/b1");
        fake_folder.remote_modifier ().insert ("B/b1/zzz");

        GLib.assert_true (fake_folder.sync_once ());
        var conflicts = findConflicts (fake_folder.current_local_state ());
        conflicts += findConflicts (fake_folder.current_local_state ().children["B"]);
        GLib.assert_cmp (conflicts.size (), 3);
        std.sort (conflicts.begin (), conflicts.end ());

        var conflictRecords = fake_folder.sync_journal ().conflictRecordPaths ();
        GLib.assert_cmp (conflictRecords.size (), 3);
        std.sort (conflictRecords.begin (), conflictRecords.end ());

        // 1)
        GLib.assert_true (itemConflict (complete_spy, "Z"));
        GLib.assert_true (conflicts[2].contains ("Z"));
        GLib.assert_cmp (conflicts[2], conflictRecords[2]);

        // 2)
        GLib.assert_true (itemConflict (complete_spy, "A"));
        GLib.assert_true (conflicts[0].contains ("A"));
        GLib.assert_cmp (conflicts[0], conflictRecords[0]);

        // 3)
        GLib.assert_true (itemConflict (complete_spy, "B/b1"));
        GLib.assert_true (conflicts[1].contains ("B/b1"));
        GLib.assert_cmp (conflicts[1], conflictRecords[1]);

        // Also verifies that conflicts were uploaded
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void testTypeConflictWithMove () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy (fake_folder);

        // the remote becomes a file, but a file inside the directory has moved away!
        fake_folder.remote_modifier ().remove ("A");
        fake_folder.remote_modifier ().insert ("A");
        fake_folder.local_modifier ().rename ("A/a1", "a1");

        // same, but with a new file inside the directory locally
        fake_folder.remote_modifier ().remove ("B");
        fake_folder.remote_modifier ().insert ("B");
        fake_folder.local_modifier ().rename ("B/b1", "b1");
        fake_folder.local_modifier ().insert ("B/new");

        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (itemSuccessful (complete_spy, "A", CSYNC_INSTRUCTION_TYPE_CHANGE));
        GLib.assert_true (itemConflict (complete_spy, "B"));

        var conflicts = findConflicts (fake_folder.current_local_state ());
        std.sort (conflicts.begin (), conflicts.end ());
        GLib.assert_true (conflicts.size () == 2);
        GLib.assert_true (conflicts[0].contains ("A (conflicted copy"));
        GLib.assert_true (conflicts[1].contains ("B (conflicted copy"));
        for (var& conflict : conflicts)
            QDir (fake_folder.local_path () + conflict).remove_recursively ();
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // Currently a1 and b1 don't get moved, but redownloaded
    }


    /***********************************************************
    ***********************************************************/
    private void testTypeChange () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy (fake_folder);

        // directory becomes file
        fake_folder.remote_modifier ().remove ("A");
        fake_folder.remote_modifier ().insert ("A");
        fake_folder.local_modifier ().remove ("B");
        fake_folder.local_modifier ().insert ("B");

        // file becomes directory
        fake_folder.remote_modifier ().remove ("C/c1");
        fake_folder.remote_modifier ().mkdir ("C/c1");
        fake_folder.remote_modifier ().insert ("C/c1/foo");
        fake_folder.local_modifier ().remove ("C/c2");
        fake_folder.local_modifier ().mkdir ("C/c2");
        fake_folder.local_modifier ().insert ("C/c2/bar");

        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (itemSuccessful (complete_spy, "A", CSYNC_INSTRUCTION_TYPE_CHANGE));
        GLib.assert_true (itemSuccessful (complete_spy, "B", CSYNC_INSTRUCTION_TYPE_CHANGE));
        GLib.assert_true (itemSuccessful (complete_spy, "C/c1", CSYNC_INSTRUCTION_TYPE_CHANGE));
        GLib.assert_true (itemSuccessful (complete_spy, "C/c2", CSYNC_INSTRUCTION_TYPE_CHANGE));

        // A becomes a conflict because we don't delete folders with files
        // inside of them!
        var conflicts = findConflicts (fake_folder.current_local_state ());
        GLib.assert_true (conflicts.size () == 1);
        GLib.assert_true (conflicts[0].contains ("A (conflicted copy"));
        for (var& conflict : conflicts)
            QDir (fake_folder.local_path () + conflict).remove_recursively ();

        GLib.assert_true (fake_folder.sync_engine ().is_another_sync_needed () == ImmediateFollowUp);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }

    // Test what happens if we remove entries both on the server, and locally
    private void testRemoveRemove () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().remove ("A");
        fake_folder.local_modifier ().remove ("A");
        fake_folder.remote_modifier ().remove ("B/b1");
        fake_folder.local_modifier ().remove ("B/b1");

        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        var expected_state = fake_folder.current_local_state ();

        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_cmp (fake_folder.current_local_state (), expected_state);
        GLib.assert_cmp (fake_folder.current_remote_state (), expected_state);

        GLib.assert_true (dbRecord (fake_folder, "B/b2").is_valid ());

        GLib.assert_true (!dbRecord (fake_folder, "B/b1").is_valid ());
        GLib.assert_true (!dbRecord (fake_folder, "A/a1").is_valid ());
        GLib.assert_true (!dbRecord (fake_folder, "A").is_valid ());
    }
}

QTEST_GUILESS_MAIN (TestSyncConflict)
