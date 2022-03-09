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
    int n_get = 0;
    int number_of_put = 0;
    int number_of_move = 0;
    int number_of_delete = 0;

    void on_signal_reset () { *this = {}; }

    var functor () {
        return [&] (Soup.Operation operation, Soup.Request request, QIODevice *) {
            if (operation == Soup.GetOperation)
                ++n_get;
            if (operation == Soup.PutOperation)
                ++number_of_put;
            if (operation == Soup.DeleteOperation)
                ++number_of_delete;
            if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE")
                ++number_of_move;
            return null;
        }
    }
}

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

class TestSyncMove : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void on_signal_test_move_custom_remote_root () {
        FileInfo subFolder = new FileInfo ("AS", { { "f1", 4 } });
        FileInfo folder = new FileInfo ("A", { subFolder });
        FileInfo file_info = new FileInfo ({}, { folder });

        FakeFolder fake_folder = new FakeFolder (file_info, folder, "/A");
        var local_modifier = fake_folder.local_modifier ();

        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        // Move file and then move it back again
        counter.on_signal_reset ();
        local_modifier.rename ("AS/f1", "f1");

        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_cmp (counter.n_get, 0);
        GLib.assert_cmp (counter.number_of_put, 0);
        GLib.assert_cmp (counter.number_of_move, 1);
        GLib.assert_cmp (counter.number_of_delete, 0);

        GLib.assert_true (itemSuccessful (complete_spy, "f1", CSYNC_INSTRUCTION_RENAME));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/f1"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/AS/f1"));
    }


    /***********************************************************
    ***********************************************************/
    private void testRemoteChangeInMovedFolder () {
        // issue #5192
        FakeFolder fake_folder = new FakeFolder (
            new FileInfo ("", {
                new FileInfo ("folder", {
                    new FileInfo ("folderA", {
                        { "file.txt", 400 }
                    } ),
                "folderB" } )
            } )
        );

        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // Edit a file in a moved directory.
        fake_folder.remote_modifier ().set_contents ("folder/folderA/file.txt", 'a');
        fake_folder.remote_modifier ().rename ("folder/folderA", "folder/folderB/folderA");
        fake_folder.sync_once ();
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        var oldState = fake_folder.current_local_state ();
        GLib.assert_true (oldState.find ("folder/folderB/folderA/file.txt"));
        GLib.assert_true (!oldState.find ("folder/folderA/file.txt"));

        // This sync should not remove the file
        fake_folder.sync_once ();
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (fake_folder.current_local_state (), oldState);
    }


    /***********************************************************
    ***********************************************************/
    private void testSelectiveSyncMovedFolder () {
        // issue #5224
        FakeFolder fake_folder = new FakeFolder (
            new FileInfo ("", {
                new FileInfo ("parentFolder", {
                    new FileInfo ("subFolderA", {
                        { "fileA.txt", 400 }
                    } ),
                    new FileInfo ("subFolderB", {
                        { "fileB.txt", 400 }
                    } )
                } )
            } )
        );

        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        var expectedServerState = fake_folder.current_remote_state ();

        // Remove subFolderA with selectiveSync:
        fake_folder.sync_engine ().journal ().set_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, { "parentFolder/subFolderA/" });
        fake_folder.sync_engine ().journal ().schedulePathForRemoteDiscovery (QByteArrayLiteral ("parentFolder/subFolderA/"));

        fake_folder.sync_once ();
 {
            // Nothing changed on the server
            GLib.assert_cmp (fake_folder.current_remote_state (), expectedServerState);
            // The local state should not have subFolderA
            var remoteState = fake_folder.current_remote_state ();
            remoteState.remove ("parentFolder/subFolderA");
            GLib.assert_cmp (fake_folder.current_local_state (), remoteState);
        }

        // Rename parentFolder on the server
        fake_folder.remote_modifier ().rename ("parentFolder", "parentFolderRenamed");
        expectedServerState = fake_folder.current_remote_state ();
        fake_folder.sync_once ();
 {
            GLib.assert_cmp (fake_folder.current_remote_state (), expectedServerState);
            var remoteState = fake_folder.current_remote_state ();
            // The subFolderA should still be there on the server.
            GLib.assert_true (remoteState.find ("parentFolderRenamed/subFolderA/fileA.txt"));
            // But not on the client because of the selective sync
            remoteState.remove ("parentFolderRenamed/subFolderA");
            GLib.assert_cmp (fake_folder.current_local_state (), remoteState);
        }

        // Rename it again, locally this time.
        fake_folder.local_modifier ().rename ("parentFolderRenamed", "parentThirdName");
        fake_folder.sync_once ();
 {
            var remoteState = fake_folder.current_remote_state ();
            // The subFolderA should still be there on the server.
            GLib.assert_true (remoteState.find ("parentThirdName/subFolderA/fileA.txt"));
            // But not on the client because of the selective sync
            remoteState.remove ("parentThirdName/subFolderA");
            GLib.assert_cmp (fake_folder.current_local_state (), remoteState);

            expectedServerState = fake_folder.current_remote_state ();
            ItemCompletedSpy complete_spy (fake_folder);
            fake_folder.sync_once (); // This sync should do nothing
            GLib.assert_cmp (complete_spy.count (), 0);

            GLib.assert_cmp (fake_folder.current_remote_state (), expectedServerState);
            GLib.assert_cmp (fake_folder.current_local_state (), remoteState);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testLocalMoveDetection () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        int number_of_put = 0;
        int number_of_delete = 0;
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request &, QIODevice *) {
            if (operation == Soup.PutOperation)
                ++number_of_put;
            if (operation == Soup.DeleteOperation)
                ++number_of_delete;
            return null;
        });

        // For directly editing the remote checksum
        FileInfo remoteInfo = fake_folder.remote_modifier ();

        // Simple move causing a remote rename
        fake_folder.local_modifier ().rename ("A/a1", "A/a1m");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), remoteInfo);
        GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (remoteInfo));
        GLib.assert_cmp (number_of_put, 0);

        // Move-and-change, causing a upload and delete
        fake_folder.local_modifier ().rename ("A/a2", "A/a2m");
        fake_folder.local_modifier ().append_byte ("A/a2m");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), remoteInfo);
        GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (remoteInfo));
        GLib.assert_cmp (number_of_put, 1);
        GLib.assert_cmp (number_of_delete, 1);

        // Move-and-change, mtime+content only
        fake_folder.local_modifier ().rename ("B/b1", "B/b1m");
        fake_folder.local_modifier ().set_contents ("B/b1m", 'C');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), remoteInfo);
        GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (remoteInfo));
        GLib.assert_cmp (number_of_put, 2);
        GLib.assert_cmp (number_of_delete, 2);

        // Move-and-change, size+content only
        var mtime = fake_folder.remote_modifier ().find ("B/b2").last_modified;
        fake_folder.local_modifier ().rename ("B/b2", "B/b2m");
        fake_folder.local_modifier ().append_byte ("B/b2m");
        fake_folder.local_modifier ().set_modification_time ("B/b2m", mtime);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), remoteInfo);
        GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (remoteInfo));
        GLib.assert_cmp (number_of_put, 3);
        GLib.assert_cmp (number_of_delete, 3);

        // Move-and-change, content only -- c1 has no checksum, so we fail to detect this!
        // Note: This is an expected failure.
        mtime = fake_folder.remote_modifier ().find ("C/c1").last_modified;
        fake_folder.local_modifier ().rename ("C/c1", "C/c1m");
        fake_folder.local_modifier ().set_contents ("C/c1m", 'C');
        fake_folder.local_modifier ().set_modification_time ("C/c1m", mtime);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (number_of_put, 3);
        GLib.assert_cmp (number_of_delete, 3);
        GLib.assert_true (! (fake_folder.current_local_state () == remoteInfo));

        // on_signal_cleanup, and upload a file that will have a checksum in the database
        fake_folder.local_modifier ().remove ("C/c1m");
        fake_folder.local_modifier ().insert ("C/c3");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), remoteInfo);
        GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (remoteInfo));
        GLib.assert_cmp (number_of_put, 4);
        GLib.assert_cmp (number_of_delete, 4);

        // Move-and-change, content only, this time while having a checksum
        mtime = fake_folder.remote_modifier ().find ("C/c3").last_modified;
        fake_folder.local_modifier ().rename ("C/c3", "C/c3m");
        fake_folder.local_modifier ().set_contents ("C/c3m", 'C');
        fake_folder.local_modifier ().set_modification_time ("C/c3m", mtime);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (number_of_put, 5);
        GLib.assert_cmp (number_of_delete, 5);
        GLib.assert_cmp (fake_folder.current_local_state (), remoteInfo);
        GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (remoteInfo));
    }


    /***********************************************************
    ***********************************************************/
    private void testDuplicateFileId_data () {
        QTest.add_column<string> ("prefix");

        // There have been bugs related to how the original
        // folder and the folder with the duplicate tree are
        // ordered. Test both cases here.
        QTest.new_row ("first ordering") + "O"; // "O" > "A"
        QTest.new_row ("second ordering") + "0"; // "0" < "A"
    }

    // If the same folder is shared in two different ways with the same
    // user, the target user will see duplicate file ids. We need to make
    // sure the move detection and sync still do the right thing in that
    // case.
    private void testDuplicateFileId () {
        QFETCH (string, prefix);

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        var remote = fake_folder.remote_modifier ();

        remote.mkdir ("A/W");
        remote.insert ("A/W/w1");
        remote.mkdir ("A/Q");

        // Duplicate every entry in A under O/A
        remote.mkdir (prefix);
        remote.children[prefix].add_child (remote.children["A"]);

        // This already checks that the rename detection doesn't get
        // horribly confused if we add new files that have the same
        // fileid as existing ones
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        // Try a remote file move
        remote.rename ("A/a1", "A/W/a1m");
        remote.rename (prefix + "/A/a1", prefix + "/A/W/a1m");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (counter.n_get, 0);

        // And a remote directory move
        remote.rename ("A/W", "A/Q/W");
        remote.rename (prefix + "/A/W", prefix + "/A/Q/W");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (counter.n_get, 0);

        // Partial file removal (in practice, A/a2 may be moved to O/a2, but we don't care)
        remote.rename (prefix + "/A/a2", prefix + "/a2");
        remote.remove ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (counter.n_get, 0);

        // Local change plus remote move at the same time
        fake_folder.local_modifier ().append_byte (prefix + "/a2");
        remote.rename (prefix + "/a2", prefix + "/a3");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (counter.n_get, 1);
        counter.on_signal_reset ();

        // remove localy, and remote move at the same time
        fake_folder.local_modifier ().remove ("A/Q/W/a1m");
        remote.rename ("A/Q/W/a1m", "A/Q/W/a1p");
        remote.rename (prefix + "/A/Q/W/a1m", prefix + "/A/Q/W/a1p");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (counter.n_get, 1);
        counter.on_signal_reset ();
    }


    /***********************************************************
    ***********************************************************/
    private void testMovePropagation () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        var local = fake_folder.local_modifier ();
        var remote = fake_folder.remote_modifier ();

        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        // Move {
            counter.on_signal_reset ();
            local.rename ("A/a1", "A/a1m");
            remote.rename ("B/b1", "B/b1m");
            ItemCompletedSpy complete_spy (fake_folder);
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
            GLib.assert_cmp (counter.n_get, 0);
            GLib.assert_cmp (counter.number_of_put, 0);
            GLib.assert_cmp (counter.number_of_move, 1);
            GLib.assert_cmp (counter.number_of_delete, 0);
            GLib.assert_true (itemSuccessfulMove (complete_spy, "A/a1m"));
            GLib.assert_true (itemSuccessfulMove (complete_spy, "B/b1m"));
            GLib.assert_cmp (complete_spy.find_item ("A/a1m").file, "A/a1");
            GLib.assert_cmp (complete_spy.find_item ("A/a1m").renameTarget, "A/a1m");
            GLib.assert_cmp (complete_spy.find_item ("B/b1m").file, "B/b1");
            GLib.assert_cmp (complete_spy.find_item ("B/b1m").renameTarget, "B/b1m");
        }

        // Touch+Move on same side
        counter.on_signal_reset ();
        local.rename ("A/a2", "A/a2m");
        local.set_contents ("A/a2m", 'A');
        remote.rename ("B/b2", "B/b2m");
        remote.set_contents ("B/b2m", 'A');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (fake_folder.current_remote_state ()));
        GLib.assert_cmp (counter.n_get, 1);
        GLib.assert_cmp (counter.number_of_put, 1);
        GLib.assert_cmp (counter.number_of_move, 0);
        GLib.assert_cmp (counter.number_of_delete, 1);
        GLib.assert_cmp (remote.find ("A/a2m").content_char, 'A');
        GLib.assert_cmp (remote.find ("B/b2m").content_char, 'A');

        // Touch+Move on opposite sides
        counter.on_signal_reset ();
        local.rename ("A/a1m", "A/a1m2");
        remote.set_contents ("A/a1m", 'B');
        remote.rename ("B/b1m", "B/b1m2");
        local.set_contents ("B/b1m", 'B');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (fake_folder.current_remote_state ()));
        GLib.assert_cmp (counter.n_get, 2);
        GLib.assert_cmp (counter.number_of_put, 2);
        GLib.assert_cmp (counter.number_of_move, 0);
        GLib.assert_cmp (counter.number_of_delete, 0);
        // All these files existing afterwards is debatable. Should we propagate
        // the rename in one direction and grab the new contents in the other?
        // Currently there's no propagation job that would do that, and this does
        // at least not lose data.
        GLib.assert_cmp (remote.find ("A/a1m").content_char, 'B');
        GLib.assert_cmp (remote.find ("B/b1m").content_char, 'B');
        GLib.assert_cmp (remote.find ("A/a1m2").content_char, 'W');
        GLib.assert_cmp (remote.find ("B/b1m2").content_char, 'W');

        // Touch+create on one side, move on the other {
            counter.on_signal_reset ();
            local.append_byte ("A/a1m");
            local.insert ("A/a1mt");
            remote.rename ("A/a1m", "A/a1mt");
            remote.append_byte ("B/b1m");
            remote.insert ("B/b1mt");
            local.rename ("B/b1m", "B/b1mt");
            ItemCompletedSpy complete_spy (fake_folder);
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (expectAndWipeConflict (local, fake_folder.current_local_state (), "A/a1mt"));
            GLib.assert_true (expectAndWipeConflict (local, fake_folder.current_local_state (), "B/b1mt"));
            GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
            GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (fake_folder.current_remote_state ()));
            GLib.assert_cmp (counter.n_get, 3);
            GLib.assert_cmp (counter.number_of_put, 1);
            GLib.assert_cmp (counter.number_of_move, 0);
            GLib.assert_cmp (counter.number_of_delete, 0);
            GLib.assert_true (itemSuccessful (complete_spy, "A/a1m", CSYNC_INSTRUCTION_NEW));
            GLib.assert_true (itemSuccessful (complete_spy, "B/b1m", CSYNC_INSTRUCTION_NEW));
            GLib.assert_true (itemConflict (complete_spy, "A/a1mt"));
            GLib.assert_true (itemConflict (complete_spy, "B/b1mt"));
        }

        // Create new on one side, move to new on the other {
            counter.on_signal_reset ();
            local.insert ("A/a1N", 13);
            remote.rename ("A/a1mt", "A/a1N");
            remote.insert ("B/b1N", 13);
            local.rename ("B/b1mt", "B/b1N");
            ItemCompletedSpy complete_spy (fake_folder);
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (expectAndWipeConflict (local, fake_folder.current_local_state (), "A/a1N"));
            GLib.assert_true (expectAndWipeConflict (local, fake_folder.current_local_state (), "B/b1N"));
            GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
            GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (fake_folder.current_remote_state ()));
            GLib.assert_cmp (counter.n_get, 2);
            GLib.assert_cmp (counter.number_of_put, 0);
            GLib.assert_cmp (counter.number_of_move, 0);
            GLib.assert_cmp (counter.number_of_delete, 1);
            GLib.assert_true (itemSuccessful (complete_spy, "A/a1mt", CSYNC_INSTRUCTION_REMOVE));
            GLib.assert_true (itemSuccessful (complete_spy, "B/b1mt", CSYNC_INSTRUCTION_REMOVE));
            GLib.assert_true (itemConflict (complete_spy, "A/a1N"));
            GLib.assert_true (itemConflict (complete_spy, "B/b1N"));
        }

        // Local move, remote move
        counter.on_signal_reset ();
        local.rename ("C/c1", "C/c1mL");
        remote.rename ("C/c1", "C/c1mR");
        GLib.assert_true (fake_folder.sync_once ());
        // end up with both files
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (fake_folder.current_remote_state ()));
        GLib.assert_cmp (counter.n_get, 1);
        GLib.assert_cmp (counter.number_of_put, 1);
        GLib.assert_cmp (counter.number_of_move, 0);
        GLib.assert_cmp (counter.number_of_delete, 0);

        // Rename/rename conflict on a folder
        counter.on_signal_reset ();
        remote.rename ("C", "CMR");
        local.rename ("C", "CML");
        GLib.assert_true (fake_folder.sync_once ());
        // End up with both folders
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (fake_folder.current_remote_state ()));
        GLib.assert_cmp (counter.n_get, 3); // 3 files in C
        GLib.assert_cmp (counter.number_of_put, 3);
        GLib.assert_cmp (counter.number_of_move, 0);
        GLib.assert_cmp (counter.number_of_delete, 0);

        // Folder move {
            counter.on_signal_reset ();
            local.rename ("A", "AM");
            remote.rename ("B", "BM");
            ItemCompletedSpy complete_spy (fake_folder);
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
            GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (fake_folder.current_remote_state ()));
            GLib.assert_cmp (counter.n_get, 0);
            GLib.assert_cmp (counter.number_of_put, 0);
            GLib.assert_cmp (counter.number_of_move, 1);
            GLib.assert_cmp (counter.number_of_delete, 0);
            GLib.assert_true (itemSuccessfulMove (complete_spy, "AM"));
            GLib.assert_true (itemSuccessfulMove (complete_spy, "BM"));
            GLib.assert_cmp (complete_spy.find_item ("AM").file, "A");
            GLib.assert_cmp (complete_spy.find_item ("AM").renameTarget, "AM");
            GLib.assert_cmp (complete_spy.find_item ("BM").file, "B");
            GLib.assert_cmp (complete_spy.find_item ("BM").renameTarget, "BM");
        }

        // Folder move with contents touched on the same side {
            counter.on_signal_reset ();
            local.set_contents ("AM/a2m", 'C');
            // We must change the modtime for it is likely that it did not change between sync.
            // (Previous version of the client (<=2.5) would not need this because it was always doing
            // checksum comparison for all renames. But newer version no longer does it if the file is
            // renamed because the parent folder is renamed)
            local.set_modification_time ("AM/a2m", GLib.DateTime.current_date_time_utc ().add_days (3));
            local.rename ("AM", "A2");
            remote.set_contents ("BM/b2m", 'C');
            remote.rename ("BM", "B2");
            ItemCompletedSpy complete_spy (fake_folder);
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
            GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (fake_folder.current_remote_state ()));
            GLib.assert_cmp (counter.n_get, 1);
            GLib.assert_cmp (counter.number_of_put, 1);
            GLib.assert_cmp (counter.number_of_move, 1);
            GLib.assert_cmp (counter.number_of_delete, 0);
            GLib.assert_cmp (remote.find ("A2/a2m").content_char, 'C');
            GLib.assert_cmp (remote.find ("B2/b2m").content_char, 'C');
            GLib.assert_true (itemSuccessfulMove (complete_spy, "A2"));
            GLib.assert_true (itemSuccessfulMove (complete_spy, "B2"));
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
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (fake_folder.current_remote_state ()));
        GLib.assert_cmp (counter.n_get, 1);
        GLib.assert_cmp (counter.number_of_put, 1);
        GLib.assert_cmp (counter.number_of_move, 1);
        GLib.assert_cmp (counter.number_of_delete, 0);
        GLib.assert_cmp (remote.find ("A3/a2m").content_char, 'D');
        GLib.assert_cmp (remote.find ("B3/b2m").content_char, 'D');

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
        GLib.assert_true (fake_folder.sync_once ());
        var currentLocal = fake_folder.current_local_state ();
        var conflicts = findConflicts (currentLocal.children["A4"]);
        GLib.assert_cmp (conflicts.size (), 1);
        for (var& c : conflicts) {
            GLib.assert_cmp (currentLocal.find (c).content_char, 'L');
            local.remove (c);
        }
        conflicts = findConflicts (currentLocal.children["B4"]);
        GLib.assert_cmp (conflicts.size (), 1);
        for (var& c : conflicts) {
            GLib.assert_cmp (currentLocal.find (c).content_char, 'L');
            local.remove (c);
        }
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (fake_folder.current_remote_state ()));
        GLib.assert_cmp (counter.n_get, 2);
        GLib.assert_cmp (counter.number_of_put, 0);
        GLib.assert_cmp (counter.number_of_move, 1);
        GLib.assert_cmp (counter.number_of_delete, 0);
        GLib.assert_cmp (remote.find ("A4/a2m").content_char, 'R');
        GLib.assert_cmp (remote.find ("B4/b2m").content_char, 'R');

        // Rename a folder and rename the contents at the same time
        counter.on_signal_reset ();
        local.rename ("A4/a2m", "A4/a2m2");
        local.rename ("A4", "A5");
        remote.rename ("B4/b2m", "B4/b2m2");
        remote.rename ("B4", "B5");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (fake_folder.current_remote_state ()));
        GLib.assert_cmp (counter.n_get, 0);
        GLib.assert_cmp (counter.number_of_put, 0);
        GLib.assert_cmp (counter.number_of_move, 2);
        GLib.assert_cmp (counter.number_of_delete, 0);
    }

    // These renames can be troublesome on windows
    private void testRenameCaseOnly () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        var local = fake_folder.local_modifier ();
        var remote = fake_folder.remote_modifier ();

        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        local.rename ("A/a1", "A/A1");
        remote.rename ("A/a2", "A/A2");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), remote);
        GLib.assert_cmp (print_database_data (fake_folder.database_state ()), print_database_data (fake_folder.current_remote_state ()));
        GLib.assert_cmp (counter.n_get, 0);
        GLib.assert_cmp (counter.number_of_put, 0);
        GLib.assert_cmp (counter.number_of_move, 1);
        GLib.assert_cmp (counter.number_of_delete, 0);
    }

    // Check interaction of moves with file type changes
    private void testMoveAndTypeChange () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        var local = fake_folder.local_modifier ();
        var remote = fake_folder.remote_modifier ();

        // Touch on one side, rename and mkdir on the other {
            local.append_byte ("A/a1");
            remote.rename ("A/a1", "A/a1mq");
            remote.mkdir ("A/a1");
            remote.append_byte ("B/b1");
            local.rename ("B/b1", "B/b1mq");
            local.mkdir ("B/b1");
            ItemCompletedSpy complete_spy (fake_folder);
            GLib.assert_true (fake_folder.sync_once ());
            // BUG : This doesn't behave right
            //GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        }
    }

    // https://github.com/owncloud/client/issues/6629#issuecomment-402450691
    // When a file is moved and the server mtime was not in sync, the local mtime should be kept
    private void testMoveAndMTimeChange () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        // Changing the mtime on the server (without invalidating the etag)
        fake_folder.remote_modifier ().find ("A/a1").last_modified = GLib.DateTime.current_date_time_utc ().add_secs (-50000);
        fake_folder.remote_modifier ().find ("A/a2").last_modified = GLib.DateTime.current_date_time_utc ().add_secs (-40000);

        // Move a few files
        fake_folder.remote_modifier ().rename ("A/a1", "A/a1_server_renamed");
        fake_folder.local_modifier ().rename ("A/a2", "A/a2_local_renamed");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (counter.n_get, 0);
        GLib.assert_cmp (counter.number_of_put, 0);
        GLib.assert_cmp (counter.number_of_move, 1);
        GLib.assert_cmp (counter.number_of_delete, 0);

        // Another sync should do nothing
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (counter.n_get, 0);
        GLib.assert_cmp (counter.number_of_put, 0);
        GLib.assert_cmp (counter.number_of_move, 1);
        GLib.assert_cmp (counter.number_of_delete, 0);

        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }

    // Test for https://github.com/owncloud/client/issues/6694
    private void testInvertFolderHierarchy () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().mkdir ("A/Empty");
        fake_folder.remote_modifier ().mkdir ("A/Empty/Foo");
        fake_folder.remote_modifier ().mkdir ("C/AllEmpty");
        fake_folder.remote_modifier ().mkdir ("C/AllEmpty/Bar");
        fake_folder.remote_modifier ().insert ("A/Empty/f1");
        fake_folder.remote_modifier ().insert ("A/Empty/Foo/f2");
        fake_folder.remote_modifier ().mkdir ("C/AllEmpty/f3");
        fake_folder.remote_modifier ().mkdir ("C/AllEmpty/Bar/f4");
        GLib.assert_true (fake_folder.sync_once ());

        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        // "Empty" is after "A", alphabetically
        fake_folder.local_modifier ().rename ("A/Empty", "Empty");
        fake_folder.local_modifier ().rename ("A", "Empty/A");

        // "AllEmpty" is before "C", alphabetically
        fake_folder.local_modifier ().rename ("C/AllEmpty", "AllEmpty");
        fake_folder.local_modifier ().rename ("C", "AllEmpty/C");

        var expected_state = fake_folder.current_local_state ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), expected_state);
        GLib.assert_cmp (fake_folder.current_remote_state (), expected_state);
        GLib.assert_cmp (counter.number_of_delete, 0);
        GLib.assert_cmp (counter.n_get, 0);
        GLib.assert_cmp (counter.number_of_put, 0);

        // Now, the revert, but "crossed"
        fake_folder.local_modifier ().rename ("Empty/A", "A");
        fake_folder.local_modifier ().rename ("AllEmpty/C", "C");
        fake_folder.local_modifier ().rename ("Empty", "C/Empty");
        fake_folder.local_modifier ().rename ("AllEmpty", "A/AllEmpty");
        expected_state = fake_folder.current_local_state ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), expected_state);
        GLib.assert_cmp (fake_folder.current_remote_state (), expected_state);
        GLib.assert_cmp (counter.number_of_delete, 0);
        GLib.assert_cmp (counter.n_get, 0);
        GLib.assert_cmp (counter.number_of_put, 0);

        // Reverse on remote
        fake_folder.remote_modifier ().rename ("A/AllEmpty", "AllEmpty");
        fake_folder.remote_modifier ().rename ("C/Empty", "Empty");
        fake_folder.remote_modifier ().rename ("C", "AllEmpty/C");
        fake_folder.remote_modifier ().rename ("A", "Empty/A");
        expected_state = fake_folder.current_remote_state ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), expected_state);
        GLib.assert_cmp (fake_folder.current_remote_state (), expected_state);
        GLib.assert_cmp (counter.number_of_delete, 0);
        GLib.assert_cmp (counter.n_get, 0);
        GLib.assert_cmp (counter.number_of_put, 0);
    }


    /***********************************************************
    ***********************************************************/
    private void testDeepHierarchy_data () {
        QTest.add_column<bool> ("local");
        QTest.new_row ("remote") + false;
        QTest.new_row ("local") + true;
    }


    /***********************************************************
    ***********************************************************/
    private void testDeepHierarchy () {
        QFETCH (bool, local);
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        var modifier = local ? fake_folder.local_modifier () : fake_folder.remote_modifier ();

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
        GLib.assert_true (fake_folder.sync_once ());

        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

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
        var expected = local ? fake_folder.current_local_state () : fake_folder.current_remote_state ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), expected);
        GLib.assert_cmp (fake_folder.current_remote_state (), expected);
        GLib.assert_cmp (counter.number_of_delete, local ? 1 : 0); // FolC was is renamed to an existing name, so it is not considered as renamed
        // There was 5 inserts
        GLib.assert_cmp (counter.n_get, local ? 0 : 5);
        GLib.assert_cmp (counter.number_of_put, local ? 5 : 0);
    }


    /***********************************************************
    ***********************************************************/
    private void renameOnBothSides () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        // Test that renaming a file within a directory that was renamed on the other side actually do a rename.

        // 1) move the folder alphabeticaly before
        fake_folder.remote_modifier ().rename ("A/a1", "A/a1m");
        fake_folder.local_modifier ().rename ("A", "this.A");
        fake_folder.local_modifier ().rename ("B/b1", "B/b1m");
        fake_folder.remote_modifier ().rename ("B", "this.B");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_remote_state (), fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("this.A/a1m"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("this.B/b1m"));
        GLib.assert_cmp (counter.number_of_delete, 0);
        GLib.assert_cmp (counter.n_get, 0);
        GLib.assert_cmp (counter.number_of_put, 0);
        GLib.assert_cmp (counter.number_of_move, 2);
        counter.on_signal_reset ();

        // 2) move alphabetically after
        fake_folder.remote_modifier ().rename ("this.A/a2", "this.A/a2m");
        fake_folder.local_modifier ().rename ("this.B/b2", "this.B/b2m");
        fake_folder.local_modifier ().rename ("this.A", "S/A");
        fake_folder.remote_modifier ().rename ("this.B", "S/B");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_remote_state (), fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("S/A/a2m"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("S/B/b2m"));
        GLib.assert_cmp (counter.number_of_delete, 0);
        GLib.assert_cmp (counter.n_get, 0);
        GLib.assert_cmp (counter.number_of_put, 0);
        GLib.assert_cmp (counter.number_of_move, 2);
    }


    /***********************************************************
    ***********************************************************/
    private void moveFileToDifferentFolderOnBothSides () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        // Test that moving a file within to different folder on both side does the right thing.

        fake_folder.remote_modifier ().rename ("B/b1", "A/b1");
        fake_folder.local_modifier ().rename ("B/b1", "C/b1");

        fake_folder.local_modifier ().rename ("B/b2", "A/b2");
        fake_folder.remote_modifier ().rename ("B/b2", "C/b2");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_remote_state (), fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/b1"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("C/b1"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/b2"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("C/b2"));
        GLib.assert_cmp (counter.number_of_move, 0); // Unfortunately, we can't really make a move in this case
        GLib.assert_cmp (counter.n_get, 2);
        GLib.assert_cmp (counter.number_of_put, 2);
        GLib.assert_cmp (counter.number_of_delete, 0);
        counter.on_signal_reset ();

    }

    // Test that deletes don't run before renames
    private void testRenameParallelism () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo{} };
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/file");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        fake_folder.local_modifier ().mkdir ("B");
        fake_folder.local_modifier ().rename ("A/file", "B/file");
        fake_folder.local_modifier ().remove ("A");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void testMovedWithError_data () {
        QTest.add_column<Vfs.Mode> ("vfsMode");

        QTest.new_row ("Vfs.Off") + Vfs.Off;
        QTest.new_row ("Vfs.WithSuffix") + Vfs.WithSuffix;
    }


    /***********************************************************
    ***********************************************************/
    private void testMovedWithError () {
        QFETCH (Vfs.Mode, vfsMode);
        var getName = [vfsMode] (string s) { {f (vfsMode == Vfs.WithSuffix)
            {
                return s + APPLICATION_DOTVIRTUALFILE_SUFFIX;
            }
            return s;
        }
        const string src = "folder/folderA/file.txt";
        const string dest = "folder/folderB/file.txt";
        FakeFolder fake_folder = new FakeFolder (
            new FileInfo ("", {
                new FileInfo ("folder", {
                    new FileInfo ("folderA", {
                        { "file.txt", 400 }
                    } ), "folderB" } )
                } )
            );
        var syncOpts = fake_folder.sync_engine ().sync_options ();
        syncOpts.parallelNetworkJobs = 0;
        fake_folder.sync_engine ().set_sync_options (syncOpts);

        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        if (vfsMode != Vfs.Off) {
            var vfs = unowned<Vfs> (createVfsFromPlugin (vfsMode).release ());
            GLib.assert_true (vfs);
            fake_folder.switch_to_vfs (vfs);
            fake_folder.sync_journal ().internalPinStates ().setForPath ("", PinState.VfsItemAvailability.ONLINE_ONLY);

            // make files virtual
            fake_folder.sync_once ();
        }

        fake_folder.server_error_paths ().append (src, 403);
        fake_folder.local_modifier ().rename (getName (src), getName (dest));
        GLib.assert_true (!fake_folder.current_local_state ().find (getName (src)));
        GLib.assert_true (fake_folder.current_local_state ().find (getName (dest)));
        GLib.assert_true (fake_folder.current_remote_state ().find (src));
        GLib.assert_true (!fake_folder.current_remote_state ().find (dest));

        // sync1 file gets detected as error, instruction is still NEW_FILE
        fake_folder.sync_once ();

        // sync2 file is in error state, checkErrorBlocklisting sets instruction to IGNORED
        fake_folder.sync_once ();

        if (vfsMode != Vfs.Off) {
            fake_folder.sync_journal ().internalPinStates ().setForPath ("", PinState.PinState.ALWAYS_LOCAL);
            fake_folder.sync_once ();
        }

        GLib.assert_true (!fake_folder.current_local_state ().find (src));
        GLib.assert_true (fake_folder.current_local_state ().find (getName (dest)));
        if (vfsMode == Vfs.WithSuffix) {
            // the placeholder was not restored as it is still in error state
            GLib.assert_true (!fake_folder.current_local_state ().find (dest));
        }
        GLib.assert_true (fake_folder.current_remote_state ().find (src));
        GLib.assert_true (!fake_folder.current_remote_state ().find (dest));
    }

}

QTEST_GUILESS_MAIN (TestSyncMove)
