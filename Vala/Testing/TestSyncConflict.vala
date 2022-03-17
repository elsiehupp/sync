/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using Occ;

namespace Testing {

public class TestSyncConflict : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void test_no_upload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        fake_folder.local_modifier ().set_contents ("A/a1", 'L');
        fake_folder.remote_modifier ().set_contents ("A/a1", 'R');
        fake_folder.local_modifier ().append_byte ("A/a2");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());

        // Verify that the conflict names don't have the user name
        foreach (var name in find_conflicts (fake_folder.current_local_state ().children["A"])) {
            GLib.assert_true (!name.contains (fake_folder.sync_engine ().account.dav_display_name ()));
        }

        GLib.assert_true (expect_and_wipe_conflict (fake_folder.local_modifier (), fake_folder.current_local_state (), "A/a1"));
        GLib.assert_true (expect_and_wipe_conflict (fake_folder.local_modifier (), fake_folder.current_local_state (), "A/a2"));
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_upload_after_download () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account.set_capabilities ({ { "upload_conflict_files", true } });
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        GLib.HashTable<string, string> conflict_map;
        fake_folder.set_server_override (this.override_delegate_upload_after_download);

        fake_folder.local_modifier ().set_contents ("A/a1", 'L');
        fake_folder.remote_modifier ().set_contents ("A/a1", 'R');
        fake_folder.local_modifier ().append_byte ("A/a2");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());
        var local = fake_folder.current_local_state ();
        var remote = fake_folder.current_remote_state ();
        GLib.assert_true (local == remote);

        var a1FileId = fake_folder.remote_modifier ().find ("A/a1").file_identifier;
        var a2FileId = fake_folder.remote_modifier ().find ("A/a2").file_identifier;
        GLib.assert_true (conflict_map.contains (a1FileId));
        GLib.assert_true (conflict_map.contains (a2FileId));
        GLib.assert_true (conflict_map.size () == 2);
        GLib.assert_true (Utility.conflict_file_base_name_from_pattern (conflict_map[a1FileId]) == "A/a1");

        // Check that the conflict file contains the username
        GLib.assert_true (conflict_map[a1FileId].contains (" (conflicted copy %1 ".printf (fake_folder.sync_engine ().account.dav_display_name ())));

        GLib.assert_true (remote.find (conflict_map[a1FileId]).content_char == 'L');
        GLib.assert_true (remote.find ("A/a1").content_char == 'R');

        GLib.assert_true (remote.find (conflict_map[a2FileId]).size == 5);
        GLib.assert_true (remote.find ("A/a2").size == 6);
    }


    private Soup.Reply override_delegate_upload_after_download (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.PutOperation) {
            if (request.raw_header ("OC-Conflict") == "1") {
                var base_file_id = request.raw_header ("OC-ConflictBaseFileId");
                var components = request.url ().to_string ().split ('/');
                string conflict_file = components.mid (components.size () - 2).join ('/');
                conflict_map[base_file_id] = conflict_file;
                GLib.assert_true (!base_file_id == "");
                GLib.assert_true (request.raw_header ("OC-ConflictInitialBasePath") == Utility.conflict_file_base_name_from_pattern (conflict_file));
            }
        }
        return null;
    }


    /***********************************************************
    ***********************************************************/
    private void test_separate_upload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account.set_capabilities ({ { "upload_conflict_files", true } });
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        GLib.HashTable<string, string> conflict_map;
        fake_folder.set_server_override (this.override_delegate_separate_upload);

        // Explicitly add a conflict file to simulate the case where the upload of the
        // file didn't finish in the same sync run that the conflict was created.
        // To do that we need to create a mock conflict record.
        var a1FileId = fake_folder.remote_modifier ().find ("A/a1").file_identifier;
        string conflict_name = "A/a1 (conflicted copy me 1234)";
        fake_folder.local_modifier ().insert (conflict_name, 64, 'L');
        ConflictRecord conflict_record;
        conflict_record.path = conflict_name;
        conflict_record.base_file_id = a1FileId;
        conflict_record.initial_base_path = "A/a1";
        fake_folder.sync_journal ().set_conflict_record (conflict_record);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (conflict_map.size () == 1);
        GLib.assert_true (conflict_map[a1FileId] == conflict_name);
        GLib.assert_true (fake_folder.current_remote_state ().find (conflict_map[a1FileId]).content_char == 'L');
        conflict_map.clear ();

        // Now the user can locally alter the conflict file and it will be uploaded
        // as usual.
        fake_folder.local_modifier ().set_contents (conflict_name, 'P');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (conflict_map.size () == 1);
        GLib.assert_true (conflict_map[a1FileId] == conflict_name);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        conflict_map.clear ();

        // Similarly, remote modifications of conflict files get propagated downwards
        fake_folder.remote_modifier ().set_contents (conflict_name, 'Q');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (conflict_map == "");

        // Conflict files for conflict files!
        var a1ConflictFileId = fake_folder.remote_modifier ().find (conflict_name).file_identifier;
        fake_folder.remote_modifier ().append_byte (conflict_name);
        fake_folder.remote_modifier ().append_byte (conflict_name);
        fake_folder.local_modifier ().append_byte (conflict_name);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (conflict_map.size () == 1);
        GLib.assert_true (conflict_map.contains (a1ConflictFileId));
        GLib.assert_true (fake_folder.current_remote_state ().find (conflict_name).size == 66);
        GLib.assert_true (fake_folder.current_remote_state ().find (conflict_map[a1ConflictFileId]).size == 65);
        conflict_map.clear ();
    }


    private Soup.Reply override_delegate_separate_upload (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.PutOperation) {
            if (request.raw_header ("OC-Conflict") == "1") {
                var base_file_id = request.raw_header ("OC-ConflictBaseFileId");
                var components = request.url ().to_string ().split ('/');
                string conflict_file = components.mid (components.size () - 2).join ('/');
                conflict_map[base_file_id] = conflict_file;
                GLib.assert_true (!base_file_id == "");
                GLib.assert_true (request.raw_header ("OC-ConflictInitialBasePath") == Utility.conflict_file_base_name_from_pattern (conflict_file));
            }
        }
        return null;
    }


    /***********************************************************
    What happens if we download a conflict file? Is the metadata
    set up correctly?
    ***********************************************************/
    private void test_downloading_conflict_file () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account.set_capabilities ({ { "upload_conflict_files", true } });
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // With no headers from the server
        fake_folder.remote_modifier ().insert ("A/a1 (conflicted copy 1234)");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        var conflict_record = fake_folder.sync_journal ().conflict_record ("A/a1 (conflicted copy 1234)");
        GLib.assert_true (conflict_record.is_valid ());
        GLib.assert_true (conflict_record.base_file_id == fake_folder.remote_modifier ().find ("A/a1").file_identifier);
        GLib.assert_true (conflict_record.initial_base_path == "A/a1");

        // Now with server headers
        GLib.Object parent;
        var a2FileId = fake_folder.remote_modifier ().find ("A/a2").file_identifier;
        fake_folder.set_server_override (this.override_delegate_downloading_conflict_file);

        fake_folder.remote_modifier ().insert ("A/really-a-conflict"); // doesn't look like a conflict, but headers say it is
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        conflict_record = fake_folder.sync_journal ().conflict_record ("A/really-a-conflict");
        GLib.assert_true (conflict_record.is_valid ());
        GLib.assert_true (conflict_record.base_file_id == a2FileId);
        GLib.assert_true (conflict_record.base_modtime == 1234);
        GLib.assert_true (conflict_record.base_etag == "etag");
        GLib.assert_true (conflict_record.initial_base_path == "A/original");
    }


    private Soup.Reply override_delegate_downloading_conflict_file (Soup.Operation operation, Soup.Request request, QIODevice device) {
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
    }


    /***********************************************************
    Check that conflict records are removed when the file is gone
    ***********************************************************/
    private void test_conflict_record_removal1 () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account.set_capabilities ({ { "upload_donflict_files", true } });
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Make conflict records
        ConflictRecord conflict_record;
        conflict_record.path = "A/a1";
        fake_folder.sync_journal ().set_conflict_record (conflict_record);
        conflict_record.path = "A/a2";
        fake_folder.sync_journal ().set_conflict_record (conflict_record);

        // A nothing-to-sync keeps them alive
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.sync_journal ().conflict_record ("A/a1").is_valid ());
        GLib.assert_true (fake_folder.sync_journal ().conflict_record ("A/a2").is_valid ());

        // When the file is removed, the record is removed too
        fake_folder.local_modifier ().remove ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.sync_journal ().conflict_record ("A/a1").is_valid ());
        GLib.assert_true (!fake_folder.sync_journal ().conflict_record ("A/a2").is_valid ());
    }


    /***********************************************************
    Same test, but with upload_conflict_files == false
    ***********************************************************/
    private void test_conflict_record_removal2 () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account.set_capabilities ({ { "upload_conflict_files", false } });
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Create two conflicts
        fake_folder.local_modifier ().append_byte ("A/a1");
        fake_folder.local_modifier ().append_byte ("A/a1");
        fake_folder.remote_modifier ().append_byte ("A/a1");
        fake_folder.local_modifier ().append_byte ("A/a2");
        fake_folder.local_modifier ().append_byte ("A/a2");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());

        var conflicts = find_conflicts (fake_folder.current_local_state ().children["A"]);
        string a1conflict;
        string a2conflict;
        foreach (var conflict in conflicts) {
            if (conflict.contains ("a1")) {
                a1conflict = conflict;
            }
            if (conflict.contains ("a2")) {
                a2conflict = conflict;
            }
        }

        // A nothing-to-sync keeps them alive
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.sync_journal ().conflict_record (a1conflict).is_valid ());
        GLib.assert_true (fake_folder.sync_journal ().conflict_record (a2conflict).is_valid ());

        // When the file is removed, the record is removed too
        fake_folder.local_modifier ().remove (a2conflict);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.sync_journal ().conflict_record (a1conflict).is_valid ());
        GLib.assert_true (!fake_folder.sync_journal ().conflict_record (a2conflict).is_valid ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_conflict_file_base_name_data () {
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
    private void test_conflict_file_base_name () {
        QFETCH (string, input);
        QFETCH (string, output);
        GLib.assert_true (Utility.conflict_file_base_name_from_pattern (input) == output);
    }


    /***********************************************************
    ***********************************************************/
    private void test_local_dir_remote_file_conflict () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account.set_capabilities ({ { "upload_conflict_files", true } });
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

        clean_up ();

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

        var conflicts = find_conflicts (fake_folder.current_local_state ());
        conflicts += find_conflicts (fake_folder.current_local_state ().children["A"]);
        GLib.assert_true (conflicts.size () == 3);
        std.sort (conflicts.begin (), conflicts.end ());

        var conflict_records = fake_folder.sync_journal ().conflict_record_paths ();
        GLib.assert_true (conflict_records.size () == 3);
        std.sort (conflict_records.begin (), conflict_records.end ());

        // 1)
        GLib.assert_true (item_conflict (complete_spy, "Z"));
        GLib.assert_true (fake_folder.current_local_state ().find ("Z").size == 63);
        GLib.assert_true (conflicts[2].contains ("Z"));
        GLib.assert_true (conflicts[2] == conflict_records[2]);
        GLib.assert_true (GLib.FileInfo (fake_folder.local_path () + conflicts[2]).is_directory ());
        GLib.assert_true (GLib.File.exists (fake_folder.local_path () + conflicts[2] + "/foo"));

        // 2)
        GLib.assert_true (item_conflict (complete_spy, "A/a1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1").size == 5);
        GLib.assert_true (conflicts[0].contains ("A/a1"));
        GLib.assert_true (conflicts[0] == conflict_records[0]);
        GLib.assert_true (GLib.FileInfo (fake_folder.local_path () + conflicts[0]).is_directory ());
        GLib.assert_true (GLib.File.exists (fake_folder.local_path () + conflicts[0] + "/bar"));

        // 3)
        GLib.assert_true (item_conflict (complete_spy, "B"));
        GLib.assert_true (fake_folder.current_local_state ().find ("B").size == 31);
        GLib.assert_true (conflicts[1].contains ("B"));
        GLib.assert_true (conflicts[1] == conflict_records[1]);
        GLib.assert_true (GLib.FileInfo (fake_folder.local_path () + conflicts[1]).is_directory ());
        GLib.assert_true (GLib.File.exists (fake_folder.local_path () + conflicts[1] + "/zzz"));

        // The contents of the conflict directories will only be uploaded after
        // another sync.
        GLib.assert_true (fake_folder.sync_engine ().is_another_sync_needed () == ImmediateFollowUp);
        clean_up ();
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (item_successful (complete_spy, conflicts[0], SyncInstructions.NEW));
        GLib.assert_true (item_successful (complete_spy, conflicts[0] + "/bar", SyncInstructions.NEW));
        GLib.assert_true (item_successful (complete_spy, conflicts[1], SyncInstructions.NEW));
        GLib.assert_true (item_successful (complete_spy, conflicts[1] + "/zzz", SyncInstructions.NEW));
        GLib.assert_true (item_successful (complete_spy, conflicts[2], SyncInstructions.NEW));
        GLib.assert_true (item_successful (complete_spy, conflicts[2] + "/foo", SyncInstructions.NEW));
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    private static void clean_up (ItemCompletedSpy complete_spy) {
        complete_spy.clear ();
    }


    /***********************************************************
    ***********************************************************/
    private void test_local_file_remote_dir_conflict () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().account.set_capabilities ({ { "upload_conflict_files", true } });
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

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
        var conflicts = find_conflicts (fake_folder.current_local_state ());
        conflicts += find_conflicts (fake_folder.current_local_state ().children["B"]);
        GLib.assert_true (conflicts.size () == 3);
        std.sort (conflicts.begin (), conflicts.end ());

        var conflict_records = fake_folder.sync_journal ().conflict_record_paths ();
        GLib.assert_true (conflict_records.size () == 3);
        std.sort (conflict_records.begin (), conflict_records.end ());

        // 1)
        GLib.assert_true (item_conflict (complete_spy, "Z"));
        GLib.assert_true (conflicts[2].contains ("Z"));
        GLib.assert_true (conflicts[2] == conflict_records[2]);

        // 2)
        GLib.assert_true (item_conflict (complete_spy, "A"));
        GLib.assert_true (conflicts[0].contains ("A"));
        GLib.assert_true (conflicts[0] == conflict_records[0]);

        // 3)
        GLib.assert_true (item_conflict (complete_spy, "B/b1"));
        GLib.assert_true (conflicts[1].contains ("B/b1"));
        GLib.assert_true (conflicts[1] == conflict_records[1]);

        // Also verifies that conflicts were uploaded
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_type_conflict_with_move () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

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

        GLib.assert_true (item_successful (complete_spy, "A", SyncInstructions.TYPE_CHANGE));
        GLib.assert_true (item_conflict (complete_spy, "B"));

        var conflicts = find_conflicts (fake_folder.current_local_state ());
        std.sort (conflicts.begin (), conflicts.end ());
        GLib.assert_true (conflicts.size () == 2);
        GLib.assert_true (conflicts[0].contains ("A (conflicted copy"));
        GLib.assert_true (conflicts[1].contains ("B (conflicted copy"));
        foreach (var conflict in conflicts) {
            QDir (fake_folder.local_path () + conflict).remove_recursively ();
        }
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Currently a1 and b1 don't get moved, but redownloaded
    }


    /***********************************************************
    ***********************************************************/
    private void test_type_change () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);

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

        GLib.assert_true (item_successful (complete_spy, "A", SyncInstructions.TYPE_CHANGE));
        GLib.assert_true (item_successful (complete_spy, "B", SyncInstructions.TYPE_CHANGE));
        GLib.assert_true (item_successful (complete_spy, "C/c1", SyncInstructions.TYPE_CHANGE));
        GLib.assert_true (item_successful (complete_spy, "C/c2", SyncInstructions.TYPE_CHANGE));

        // A becomes a conflict because we don't delete folders with files
        // inside of them!
        var conflicts = find_conflicts (fake_folder.current_local_state ());
        GLib.assert_true (conflicts.size () == 1);
        GLib.assert_true (conflicts[0].contains ("A (conflicted copy"));
        foreach (var conflict in conflicts) {
            QDir (fake_folder.local_path () + conflict).remove_recursively ();
        }

        GLib.assert_true (fake_folder.sync_engine ().is_another_sync_needed () == ImmediateFollowUp);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    Test what happens if we remove entries both on the server,
    and locally
    ***********************************************************/
    private void test_remove_remove () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().remove ("A");
        fake_folder.local_modifier ().remove ("A");
        fake_folder.remote_modifier ().remove ("B/b1");
        fake_folder.local_modifier ().remove ("B/b1");

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        var expected_state = fake_folder.current_local_state ();

        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state () == expected_state);
        GLib.assert_true (fake_folder.current_remote_state () == expected_state);

        GLib.assert_true (database_record (fake_folder, "B/b2").is_valid ());

        GLib.assert_true (!database_record (fake_folder, "B/b1").is_valid ());
        GLib.assert_true (!database_record (fake_folder, "A/a1").is_valid ());
        GLib.assert_true (!database_record (fake_folder, "A").is_valid ());
    }


    private static bool item_successful (ItemCompletedSpy spy, string path, SyncInstructions instr) {
        var item = spy.find_item (path);
        return item.status == SyncFileItem.Status.SUCCESS && item.instruction == instr;
    }


    private static bool item_conflict (ItemCompletedSpy spy, string path) {
        var item = spy.find_item (path);
        return item.status == SyncFileItem.Status.CONFLICT && item.instruction == SyncInstructions.CONFLICT;
    }


    private static bool item_successful_move (ItemCompletedSpy spy, string path) {
        return item_successful (spy, path, SyncInstructions.RENAME);
    }


    private static string[] find_conflicts (FileInfo directory) {
        string[] conflicts;
        foreach (var item in directory.children) {
            if (item.name.contains (" (conflicted copy")) {
                conflicts.append (item.path ());
            }
        }
        return conflicts;
    }


    private static bool expect_and_wipe_conflict (FileModifier local, FileInfo state, string path) {
        PathComponents path_components = new PathComponents (path);
        var base_path = state.find (path_components.parent_directory_components ());
        if (!base_path) {
            return false;
        }
        foreach (var item in base_path.children) {
            if (item.name.starts_with (path_components.filename ()) && item.name.contains (" (conflicted copy")) {
                local.remove (item.path ());
                return true;
            }
        }
        return false;
    }


    private static SyncJournalFileRecord database_record (FakeFolder folder, string path) {
        SyncJournalFileRecord record;
        folder.sync_journal ().get_file_record (path, record);
        return record;
    }

}
}
