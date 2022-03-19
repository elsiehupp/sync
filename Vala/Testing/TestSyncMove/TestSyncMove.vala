/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class OperationCounter {
    public int number_of_get = 0;
    public int number_of_put = 0;
    public int number_of_move = 0;
    public int number_of_delete = 0;

    public void on_signal_reset () {
        this.number_of_get = 0;
        this.number_of_put = 0;
        this.number_of_move = 0;
        this.number_of_delete = 0;
    }

    public void functor (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.GetOperation)
            ++number_of_get;
        if (operation == Soup.PutOperation)
            ++number_of_put;
        if (operation == Soup.DeleteOperation)
            ++number_of_delete;
        if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE")
            ++number_of_move;
        return null;
    }
}

bool item_successful (ItemCompletedSpy spy, string path, CSync.SyncInstructions instr) {
    var item = spy.find_item (path);
    return item.status == SyncFileItem.Status.SUCCESS && item.instruction == instr;
}

bool item_conflict (ItemCompletedSpy spy, string path) {
    var item = spy.find_item (path);
    return item.status == SyncFileItem.Status.CONFLICT && item.instruction == CSync.SyncInstructions.CONFLICT;
}

bool item_successful_move (ItemCompletedSpy spy, string path) {
    return item_successful (spy, path, CSync.SyncInstructions.RENAME);
}

string[] find_conflicts (FileInfo directory) {
    string[] conflicts;
    foreach (var item in directory.children) {
        if (item.name.contains (" (conflicted copy")) {
            conflicts.append (item.path);
        }
    }
    return conflicts;
}

bool expect_and_wipe_conflict (FileModifier local, FileInfo state, string path) {
    PathComponents path_components = new PathComponents (path);
    var base_path = state.find (path_components.parent_directory_components ());
    if (!base_path)
        return false;
    foreach (var item in base_path.children) {
        if (item.name.starts_with (path_components.filename ()) && item.name.contains (" (conflicted copy")) {
            local.remove (item.path);
            return true;
        }
    }
    return false;
}

public class TestSyncMove : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private test_move_custom_remote_root () {
        FileInfo sub_folder = new FileInfo (
            "AS", {
                {
                    "f1", 4
                }
            }
        );
        FileInfo folder = new FileInfo (
            "A", {
                sub_folder
            }
        );
        FileInfo file_info = new FileInfo (
            {

            },
            {
                folder
            }
        );

        FakeFolder fake_folder = new FakeFolder (file_info, folder, "/A");
        var local_modifier = fake_folder.local_modifier;

        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        // Move file and then move it back again
        counter.on_signal_reset ();
        local_modifier.rename ("AS/f1", "f1");

        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (counter.number_of_get == 0);
        GLib.assert_true (counter.number_of_put == 0);
        GLib.assert_true (counter.number_of_move == 1);
        GLib.assert_true (counter.number_of_delete == 0);

        GLib.assert_true (item_successful (complete_spy, "f1", CSync.SyncInstructions.RENAME));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/f1"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/AS/f1"));
    }


    /***********************************************************
    ***********************************************************/
    private test_remote_change_in_moved_folder () {
        // issue #5192
        FakeFolder fake_folder = new FakeFolder (
            new FileInfo (
                "", {
                    new FileInfo (
                        "folder", {
                            new FileInfo (
                                "folder_a", {
                                    { "file.txt", 400 }
                                }
                            ), "folder_b"
                        }
                    )
                }
            )
        );

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Edit a file in a moved directory.
        fake_folder.remote_modifier ().set_contents ("folder/folder_a/file.txt", 'a');
        fake_folder.remote_modifier ().rename ("folder/folder_a", "folder/folder_b/folder_a");
        fake_folder.sync_once ();
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        var old_state = fake_folder.current_local_state ();
        GLib.assert_true (old_state.find ("folder/folder_b/folder_a/file.txt"));
        GLib.assert_true (!old_state.find ("folder/folder_a/file.txt"));

        // This sync should not remove the file
        fake_folder.sync_once ();
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.current_local_state () == old_state);
    }


    /***********************************************************
    ***********************************************************/
    private test_selective_sync_moved_folder () {
        // issue #5224
        FakeFolder fake_folder = new FakeFolder (
            new FileInfo (
                "", {
                    new FileInfo (
                        "parent_folder", {
                            new FileInfo (
                                "sub_folder_a", {
                                    {
                                        "file_a.txt", 400
                                    }
                                }
                            ), new FileInfo (
                                "sub_folder_b", {
                                    {
                                        "file_b.txt", 400
                                    }
                                }
                            )
                        }
                    )
                }
            )
        );

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        var expected_server_state = fake_folder.current_remote_state ();

        // Remove sub_folder_a with selective_sync:
        fake_folder.sync_engine.journal.set_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, { "parent_folder/sub_folder_a/" });
        fake_folder.sync_engine.journal.schedule_path_for_remote_discovery ("parent_folder/sub_folder_a/");

        fake_folder.sync_once ();

        // Nothing changed on the server
        GLib.assert_true (fake_folder.current_remote_state () == expected_server_state);
        // The local state should not have sub_folder_a
        var remote_state = fake_folder.current_remote_state ();
        remote_state.remove ("parent_folder/sub_folder_a");
        GLib.assert_true (fake_folder.current_local_state () == remote_state);

        // Rename parent_folder on the server
        fake_folder.remote_modifier ().rename ("parent_folder", "parent_folder_renamed");
        expected_server_state = fake_folder.current_remote_state ();
        fake_folder.sync_once ();

        GLib.assert_true (fake_folder.current_remote_state () == expected_server_state);
        var remote_state = fake_folder.current_remote_state ();
        // The sub_folder_a should still be there on the server.
        GLib.assert_true (remote_state.find ("parent_folder_renamed/sub_folder_a/file_a.txt"));
        // But not on the client because of the selective sync
        remote_state.remove ("parent_folder_renamed/sub_folder_a");
        GLib.assert_true (fake_folder.current_local_state () == remote_state);

        // Rename it again, locally this time.
        fake_folder.local_modifier.rename ("parent_folder_renamed", "parent_third_name");
        fake_folder.sync_once ();

        var remote_state = fake_folder.current_remote_state ();
        // The sub_folder_a should still be there on the server.
        GLib.assert_true (remote_state.find ("parent_third_name/sub_folder_a/file_a.txt"));
        // But not on the client because of the selective sync
        remote_state.remove ("parent_third_name/sub_folder_a");
        GLib.assert_true (fake_folder.current_local_state () == remote_state);

        expected_server_state = fake_folder.current_remote_state ();
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        fake_folder.sync_once (); // This sync should do nothing
        GLib.assert_true (complete_spy.count () == 0);

        GLib.assert_true (fake_folder.current_remote_state () == expected_server_state);
        GLib.assert_true (fake_folder.current_local_state () == remote_state);
    }


    /***********************************************************
    ***********************************************************/
    private test_local_move_detection () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        int number_of_put = 0;
        int number_of_delete = 0;
        fake_folder.set_server_override (this.override_delegate_local_move_detection);

        // For directly editing the remote checksum
        FileInfo remote_info = fake_folder.remote_modifier ();

        // Simple move causing a remote rename
        fake_folder.local_modifier.rename ("A/a1", "A/a1m");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == remote_info);
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (remote_info));
        GLib.assert_true (number_of_put == 0);

        // Move-and-change, causing a upload and delete
        fake_folder.local_modifier.rename ("A/a2", "A/a2m");
        fake_folder.local_modifier.append_byte ("A/a2m");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == remote_info);
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (remote_info));
        GLib.assert_true (number_of_put == 1);
        GLib.assert_true (number_of_delete == 1);

        // Move-and-change, mtime+content only
        fake_folder.local_modifier.rename ("B/b1", "B/b1m");
        fake_folder.local_modifier.set_contents ("B/b1m", 'C');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == remote_info);
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (remote_info));
        GLib.assert_true (number_of_put == 2);
        GLib.assert_true (number_of_delete == 2);

        // Move-and-change, size+content only
        var mtime = fake_folder.remote_modifier ().find ("B/b2").last_modified;
        fake_folder.local_modifier.rename ("B/b2", "B/b2m");
        fake_folder.local_modifier.append_byte ("B/b2m");
        fake_folder.local_modifier.set_modification_time ("B/b2m", mtime);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == remote_info);
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (remote_info));
        GLib.assert_true (number_of_put == 3);
        GLib.assert_true (number_of_delete == 3);

        // Move-and-change, content only -- c1 has no checksum, so we fail to detect this!
        // Note: This is an expected failure.
        mtime = fake_folder.remote_modifier ().find ("C/c1").last_modified;
        fake_folder.local_modifier.rename ("C/c1", "C/c1m");
        fake_folder.local_modifier.set_contents ("C/c1m", 'C');
        fake_folder.local_modifier.set_modification_time ("C/c1m", mtime);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (number_of_put == 3);
        GLib.assert_true (number_of_delete == 3);
        GLib.assert_true (! (fake_folder.current_local_state () == remote_info));

        // on_signal_cleanup, and upload a file that will have a checksum in the database
        fake_folder.local_modifier.remove ("C/c1m");
        fake_folder.local_modifier.insert ("C/c3");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == remote_info);
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (remote_info));
        GLib.assert_true (number_of_put == 4);
        GLib.assert_true (number_of_delete == 4);

        // Move-and-change, content only, this time while having a checksum
        mtime = fake_folder.remote_modifier ().find ("C/c3").last_modified;
        fake_folder.local_modifier.rename ("C/c3", "C/c3m");
        fake_folder.local_modifier.set_contents ("C/c3m", 'C');
        fake_folder.local_modifier.set_modification_time ("C/c3m", mtime);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (number_of_put == 5);
        GLib.assert_true (number_of_delete == 5);
        GLib.assert_true (fake_folder.current_local_state () == remote_info);
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (remote_info));
    }


    /***********************************************************
    ***********************************************************/
    private Soup.Reply override_delegate_local_move_detection (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.PutOperation)
            ++number_of_put;
        if (operation == Soup.DeleteOperation)
            ++number_of_delete;
        return null;
    }


    /***********************************************************
    ***********************************************************/
    private test_duplicate_file_id_data () {
        QTest.add_column<string> ("prefix");

        // There have been bugs related to how the original
        // folder and the folder with the duplicate tree are
        // ordered. Test both cases here.
        QTest.new_row ("first ordering") + "O"; // "O" > "A"
        QTest.new_row ("second ordering") + "0"; // "0" < "A"
    }

    /***********************************************************
    ***********************************************************/
    // If the same folder is shared in two different ways with the same
    // user, the target user will see duplicate file ids. We need to make
    // sure the move detection and sync still do the right thing in that
    // case.
    private test_duplicate_file_id () {
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
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        // Try a remote file move
        remote.rename ("A/a1", "A/W/a1m");
        remote.rename (prefix + "/A/a1", prefix + "/A/W/a1m");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (counter.number_of_get == 0);

        // And a remote directory move
        remote.rename ("A/W", "A/Q/W");
        remote.rename (prefix + "/A/W", prefix + "/A/Q/W");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (counter.number_of_get == 0);

        // Partial file removal (in practice, A/a2 may be moved to O/a2, but we don't care)
        remote.rename (prefix + "/A/a2", prefix + "/a2");
        remote.remove ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (counter.number_of_get == 0);

        // Local change plus remote move at the same time
        fake_folder.local_modifier.append_byte (prefix + "/a2");
        remote.rename (prefix + "/a2", prefix + "/a3");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (counter.number_of_get == 1);
        counter.on_signal_reset ();

        // remove localy, and remote move at the same time
        fake_folder.local_modifier.remove ("A/Q/W/a1m");
        remote.rename ("A/Q/W/a1m", "A/Q/W/a1p");
        remote.rename (prefix + "/A/Q/W/a1m", prefix + "/A/Q/W/a1p");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (counter.number_of_get == 1);
        counter.on_signal_reset ();
    }


    /***********************************************************
    ***********************************************************/
    private test_move_propagation () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        var local = fake_folder.local_modifier;
        var remote = fake_folder.remote_modifier ();

        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        // Move {
            counter.on_signal_reset ();
            local.rename ("A/a1", "A/a1m");
            remote.rename ("B/b1", "B/b1m");
            ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            GLib.assert_true (counter.number_of_get == 0);
            GLib.assert_true (counter.number_of_put == 0);
            GLib.assert_true (counter.number_of_move == 1);
            GLib.assert_true (counter.number_of_delete == 0);
            GLib.assert_true (item_successful_move (complete_spy, "A/a1m"));
            GLib.assert_true (item_successful_move (complete_spy, "B/b1m"));
            GLib.assert_true (complete_spy.find_item ("A/a1m").file == "A/a1");
            GLib.assert_true (complete_spy.find_item ("A/a1m").rename_target == "A/a1m");
            GLib.assert_true (complete_spy.find_item ("B/b1m").file == "B/b1");
            GLib.assert_true (complete_spy.find_item ("B/b1m").rename_target == "B/b1m");
        //  }

        // Touch+Move on same side
        counter.on_signal_reset ();
        local.rename ("A/a2", "A/a2m");
        local.set_contents ("A/a2m", 'A');
        remote.rename ("B/b2", "B/b2m");
        remote.set_contents ("B/b2m", 'A');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (print_database_data (fake_folder.database_state ()), print_database_data (fake_folder.current_remote_state ()));
        GLib.assert_true (counter.number_of_get == 1);
        GLib.assert_true (counter.number_of_put == 1);
        GLib.assert_true (counter.number_of_move == 0);
        GLib.assert_true (counter.number_of_delete == 1);
        GLib.assert_true (remote.find ("A/a2m").content_char == 'A');
        GLib.assert_true (remote.find ("B/b2m").content_char == 'A');

        // Touch+Move on opposite sides
        counter.on_signal_reset ();
        local.rename ("A/a1m", "A/a1m2");
        remote.set_contents ("A/a1m", 'B');
        remote.rename ("B/b1m", "B/b1m2");
        local.set_contents ("B/b1m", 'B');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        GLib.assert_true (counter.number_of_get == 2);
        GLib.assert_true (counter.number_of_put == 2);
        GLib.assert_true (counter.number_of_move == 0);
        GLib.assert_true (counter.number_of_delete == 0);
        // All these files existing afterwards is debatable. Should we propagate
        // the rename in one direction and grab the new contents in the other?
        // Currently there's no propagation job that would do that, and this does
        // at least not lose data.
        GLib.assert_true (remote.find ("A/a1m").content_char == 'B');
        GLib.assert_true (remote.find ("B/b1m").content_char == 'B');
        GLib.assert_true (remote.find ("A/a1m2").content_char == 'W');
        GLib.assert_true (remote.find ("B/b1m2").content_char == 'W');

        // Touch+create on one side, move on the other {
            counter.on_signal_reset ();
            local.append_byte ("A/a1m");
            local.insert ("A/a1mt");
            remote.rename ("A/a1m", "A/a1mt");
            remote.append_byte ("B/b1m");
            remote.insert ("B/b1mt");
            local.rename ("B/b1m", "B/b1mt");
            ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (expect_and_wipe_conflict (local, fake_folder.current_local_state (), "A/a1mt"));
            GLib.assert_true (expect_and_wipe_conflict (local, fake_folder.current_local_state (), "B/b1mt"));
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
            GLib.assert_true (counter.number_of_get == 3);
            GLib.assert_true (counter.number_of_put == 1);
            GLib.assert_true (counter.number_of_move == 0);
            GLib.assert_true (counter.number_of_delete == 0);
            GLib.assert_true (item_successful (complete_spy, "A/a1m", CSync.SyncInstructions.NEW));
            GLib.assert_true (item_successful (complete_spy, "B/b1m", CSync.SyncInstructions.NEW));
            GLib.assert_true (item_conflict (complete_spy, "A/a1mt"));
            GLib.assert_true (item_conflict (complete_spy, "B/b1mt"));
        //  }

        // Create new on one side, move to new on the other {
            counter.on_signal_reset ();
            local.insert ("A/a1N", 13);
            remote.rename ("A/a1mt", "A/a1N");
            remote.insert ("B/b1N", 13);
            local.rename ("B/b1mt", "B/b1N");
            ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (expect_and_wipe_conflict (local, fake_folder.current_local_state (), "A/a1N"));
            GLib.assert_true (expect_and_wipe_conflict (local, fake_folder.current_local_state (), "B/b1N"));
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
            GLib.assert_true (counter.number_of_get == 2);
            GLib.assert_true (counter.number_of_put == 0);
            GLib.assert_true (counter.number_of_move == 0);
            GLib.assert_true (counter.number_of_delete == 1);
            GLib.assert_true (item_successful (complete_spy, "A/a1mt", CSync.SyncInstructions.REMOVE));
            GLib.assert_true (item_successful (complete_spy, "B/b1mt", CSync.SyncInstructions.REMOVE));
            GLib.assert_true (item_conflict (complete_spy, "A/a1N"));
            GLib.assert_true (item_conflict (complete_spy, "B/b1N"));
        //  }

        // Local move, remote move
        counter.on_signal_reset ();
        local.rename ("C/c1", "C/c1m_l");
        remote.rename ("C/c1", "C/c1m_r");
        GLib.assert_true (fake_folder.sync_once ());
        // end up with both files
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        GLib.assert_true (counter.number_of_get == 1);
        GLib.assert_true (counter.number_of_put == 1);
        GLib.assert_true (counter.number_of_move == 0);
        GLib.assert_true (counter.number_of_delete == 0);

        // Rename/rename conflict on a folder
        counter.on_signal_reset ();
        remote.rename ("C", "CMR");
        local.rename ("C", "CML");
        GLib.assert_true (fake_folder.sync_once ());
        // End up with both folders
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        GLib.assert_true (counter.number_of_get == 3); // 3 files in C
        GLib.assert_true (counter.number_of_put == 3);
        GLib.assert_true (counter.number_of_move == 0);
        GLib.assert_true (counter.number_of_delete == 0);

        // Folder move {
            counter.on_signal_reset ();
            local.rename ("A", "AM");
            remote.rename ("B", "BM");
            ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
            GLib.assert_true (counter.number_of_get == 0);
            GLib.assert_true (counter.number_of_put == 0);
            GLib.assert_true (counter.number_of_move == 1);
            GLib.assert_true (counter.number_of_delete == 0);
            GLib.assert_true (item_successful_move (complete_spy == "AM"));
            GLib.assert_true (item_successful_move (complete_spy == "BM"));
            GLib.assert_true (complete_spy.find_item ("AM").file == "A");
            GLib.assert_true (complete_spy.find_item ("AM").rename_target == "AM");
            GLib.assert_true (complete_spy.find_item ("BM").file == "B");
            GLib.assert_true (complete_spy.find_item ("BM").rename_target == "BM");
        //  }

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
            ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
            GLib.assert_true (counter.number_of_get == 1);
            GLib.assert_true (counter.number_of_put == 1);
            GLib.assert_true (counter.number_of_move == 1);
            GLib.assert_true (counter.number_of_delete == 0);
            GLib.assert_true (remote.find ("A2/a2m").content_char == 'C');
            GLib.assert_true (remote.find ("B2/b2m").content_char == 'C');
            GLib.assert_true (item_successful_move (complete_spy, "A2"));
            GLib.assert_true (item_successful_move (complete_spy, "B2"));
        //  }

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
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        GLib.assert_true (counter.number_of_get == 1);
        GLib.assert_true (counter.number_of_put == 1);
        GLib.assert_true (counter.number_of_move == 1);
        GLib.assert_true (counter.number_of_delete == 0);
        GLib.assert_true (remote.find ("A3/a2m").content_char == 'D');
        GLib.assert_true (remote.find ("B3/b2m").content_char == 'D');

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
        var current_local = fake_folder.current_local_state ();
        var conflicts = find_conflicts (current_local.children["A4"]);
        GLib.assert_true (conflicts.size () == 1);
        foreach (var c in conflicts) {
            GLib.assert_true (current_local.find (c).content_char == 'L');
            local.remove (c);
        }
        conflicts = find_conflicts (current_local.children["B4"]);
        GLib.assert_true (conflicts.size () == 1);
        foreach (var c in conflicts) {
            GLib.assert_true (current_local.find (c).content_char == 'L');
            local.remove (c);
        }
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        GLib.assert_true (counter.number_of_get == 2);
        GLib.assert_true (counter.number_of_put == 0);
        GLib.assert_true (counter.number_of_move == 1);
        GLib.assert_true (counter.number_of_delete == 0);
        GLib.assert_true (remote.find ("A4/a2m").content_char == 'R');
        GLib.assert_true (remote.find ("B4/b2m").content_char == 'R');

        // Rename a folder and rename the contents at the same time
        counter.on_signal_reset ();
        local.rename ("A4/a2m", "A4/a2m2");
        local.rename ("A4", "A5");
        remote.rename ("B4/b2m", "B4/b2m2");
        remote.rename ("B4", "B5");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        GLib.assert_true (counter.number_of_get == 0);
        GLib.assert_true (counter.number_of_put == 0);
        GLib.assert_true (counter.number_of_move == 2);
        GLib.assert_true (counter.number_of_delete == 0);
    }

    /***********************************************************
    ***********************************************************/
    // These renames can be troublesome on windows
    private test_rename_case_only () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        var local = fake_folder.local_modifier;
        var remote = fake_folder.remote_modifier ();

        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        local.rename ("A/a1", "A/A1");
        remote.rename ("A/a2", "A/A2");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == remote);
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        GLib.assert_true (counter.number_of_get == 0);
        GLib.assert_true (counter.number_of_put == 0);
        GLib.assert_true (counter.number_of_move == 1);
        GLib.assert_true (counter.number_of_delete == 0);
    }

    /***********************************************************
    ***********************************************************/
    // Check interaction of moves with file type changes
    private test_move_and_type_change () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        var local = fake_folder.local_modifier;
        var remote = fake_folder.remote_modifier ();

        // Touch on one side, rename and mkdir on the other {
            local.append_byte ("A/a1");
            remote.rename ("A/a1", "A/a1mq");
            remote.mkdir ("A/a1");
            remote.append_byte ("B/b1");
            local.rename ("B/b1", "B/b1mq");
            local.mkdir ("B/b1");
            ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
            GLib.assert_true (fake_folder.sync_once ());
            // BUG : This doesn't behave right
            //GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        }
    }

    /***********************************************************
    ***********************************************************/
    // https://github.com/owncloud/client/issues/6629#issuecomment-402450691
    // When a file is moved and the server mtime was not in sync, the local mtime should be kept
    private test_move_and_m_time_change () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        // Changing the mtime on the server (without invalidating the etag)
        fake_folder.remote_modifier ().find ("A/a1").last_modified = GLib.DateTime.current_date_time_utc ().add_secs (-50000);
        fake_folder.remote_modifier ().find ("A/a2").last_modified = GLib.DateTime.current_date_time_utc ().add_secs (-40000);

        // Move a few files
        fake_folder.remote_modifier ().rename ("A/a1", "A/a1_server_renamed");
        fake_folder.local_modifier.rename ("A/a2", "A/a2_local_renamed");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (counter.number_of_get == 0);
        GLib.assert_true (counter.number_of_put == 0);
        GLib.assert_true (counter.number_of_move == 1);
        GLib.assert_true (counter.number_of_delete == 0);

        // Another sync should do nothing
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (counter.number_of_get == 0);
        GLib.assert_true (counter.number_of_put == 0);
        GLib.assert_true (counter.number_of_move == 1);
        GLib.assert_true (counter.number_of_delete == 0);

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }

    /***********************************************************
    ***********************************************************/
    // Test for https://github.com/owncloud/client/issues/6694
    private test_invert_folder_hierarchy () {
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
        fake_folder.local_modifier.rename ("A/Empty", "Empty");
        fake_folder.local_modifier.rename ("A", "Empty/A");

        // "AllEmpty" is before "C", alphabetically
        fake_folder.local_modifier.rename ("C/AllEmpty", "AllEmpty");
        fake_folder.local_modifier.rename ("C", "AllEmpty/C");

        var expected_state = fake_folder.current_local_state ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == expected_state);
        GLib.assert_true (fake_folder.current_remote_state () == expected_state);
        GLib.assert_true (counter.number_of_delete == 0);
        GLib.assert_true (counter.number_of_get == 0);
        GLib.assert_true (counter.number_of_put == 0);

        // Now, the revert, but "crossed"
        fake_folder.local_modifier.rename ("Empty/A", "A");
        fake_folder.local_modifier.rename ("AllEmpty/C", "C");
        fake_folder.local_modifier.rename ("Empty", "C/Empty");
        fake_folder.local_modifier.rename ("AllEmpty", "A/AllEmpty");
        expected_state = fake_folder.current_local_state ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == expected_state);
        GLib.assert_true (fake_folder.current_remote_state () == expected_state);
        GLib.assert_true (counter.number_of_delete == 0);
        GLib.assert_true (counter.number_of_get == 0);
        GLib.assert_true (counter.number_of_put == 0);

        // Reverse on remote
        fake_folder.remote_modifier ().rename ("A/AllEmpty", "AllEmpty");
        fake_folder.remote_modifier ().rename ("C/Empty", "Empty");
        fake_folder.remote_modifier ().rename ("C", "AllEmpty/C");
        fake_folder.remote_modifier ().rename ("A", "Empty/A");
        expected_state = fake_folder.current_remote_state ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == expected_state);
        GLib.assert_true (fake_folder.current_remote_state () == expected_state);
        GLib.assert_true (counter.number_of_delete == 0);
        GLib.assert_true (counter.number_of_get == 0);
        GLib.assert_true (counter.number_of_put == 0);
    }


    /***********************************************************
    ***********************************************************/
    private test_deep_hierarchy_data () {
        QTest.add_column<bool> ("local");
        QTest.new_row ("remote") + false;
        QTest.new_row ("local") + true;
    }


    /***********************************************************
    ***********************************************************/
    private test_deep_hierarchy () {
        QFETCH (bool, local);
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        var modifier = local ? fake_folder.local_modifier : fake_folder.remote_modifier ();

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
        GLib.assert_true (fake_folder.current_local_state () == expected);
        GLib.assert_true (fake_folder.current_remote_state () == expected);
        GLib.assert_true (counter.number_of_delete == local ? 1 : 0); // FolC was is renamed to an existing name, so it is not considered as renamed
        // There was 5 inserts
        GLib.assert_true (counter.number_of_get == local ? 0 : 5);
        GLib.assert_true (counter.number_of_put == local ? 5 : 0);
    }


    /***********************************************************
    ***********************************************************/
    private void rename_on_both_sides () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        // Test that renaming a file within a directory that was renamed on the other side actually do a rename.

        // 1) move the folder alphabeticaly before
        fake_folder.remote_modifier ().rename ("A/a1", "A/a1m");
        fake_folder.local_modifier.rename ("A", "this.A");
        fake_folder.local_modifier.rename ("B/b1", "B/b1m");
        fake_folder.remote_modifier ().rename ("B", "this.B");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_remote_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("this.A/a1m"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("this.B/b1m"));
        GLib.assert_true (counter.number_of_delete == 0);
        GLib.assert_true (counter.number_of_get == 0);
        GLib.assert_true (counter.number_of_put == 0);
        GLib.assert_true (counter.number_of_move == 2);
        counter.on_signal_reset ();

        // 2) move alphabetically after
        fake_folder.remote_modifier ().rename ("this.A/a2", "this.A/a2m");
        fake_folder.local_modifier.rename ("this.B/b2", "this.B/b2m");
        fake_folder.local_modifier.rename ("this.A", "S/A");
        fake_folder.remote_modifier ().rename ("this.B", "S/B");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_remote_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("S/A/a2m"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("S/B/b2m"));
        GLib.assert_true (counter.number_of_delete == 0);
        GLib.assert_true (counter.number_of_get == 0);
        GLib.assert_true (counter.number_of_put == 0);
        GLib.assert_true (counter.number_of_move == 2);
    }


    /***********************************************************
    ***********************************************************/
    private void move_file_to_different_folder_on_both_sides () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        OperationCounter counter;
        fake_folder.set_server_override (counter.functor ());

        // Test that moving a file within to different folder on both side does the right thing.

        fake_folder.remote_modifier ().rename ("B/b1", "A/b1");
        fake_folder.local_modifier.rename ("B/b1", "C/b1");

        fake_folder.local_modifier.rename ("B/b2", "A/b2");
        fake_folder.remote_modifier ().rename ("B/b2", "C/b2");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_remote_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/b1"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("C/b1"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/b2"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("C/b2"));
        GLib.assert_true (counter.number_of_move == 0); // Unfortunately, we can't really make a move in this case
        GLib.assert_true (counter.number_of_get == 2);
        GLib.assert_true (counter.number_of_put == 2);
        GLib.assert_true (counter.number_of_delete == 0);
        counter.on_signal_reset ();

    }


    /***********************************************************
    Test that deletes don't run before renames
    ***********************************************************/
    private test_rename_parallelism () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/file");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        fake_folder.local_modifier.mkdir ("B");
        fake_folder.local_modifier.rename ("A/file", "B/file");
        fake_folder.local_modifier.remove ("A");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private test_moved_with_error_data () {
        QTest.add_column<AbstractVfs.Mode> ("vfs_mode");

        QTest.new_row ("Vfs.Off") + Vfs.Off;
        QTest.new_row ("Vfs.WithSuffix") + Vfs.WithSuffix;
    }


    /***********************************************************
    ***********************************************************/
    private test_moved_with_error () {
        QFETCH (AbstractVfs.Mode, vfs_mode);
        const string src = "folder/folder_a/file.txt";
        const string dest = "folder/folder_b/file.txt";
        FakeFolder fake_folder = new FakeFolder (
            new FileInfo (
                "", {
                    new FileInfo (
                        "folder", {
                            new FileInfo (
                                "folder_a", {
                                    {
                                        "file.txt", 400
                                    }
                                }
                            ), "folder_b"
                        }
                    )
                }
            )
        );
        var sync_opts = fake_folder.sync_engine.sync_options ();
        sync_opts.parallel_network_jobs = 0;
        fake_folder.sync_engine.set_sync_options (sync_opts);

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        if (vfs_mode != Vfs.Off) {
            var vfs = unowned<Vfs> (create_vfs_from_plugin (vfs_mode).release ());
            GLib.assert_true (vfs);
            fake_folder.switch_to_vfs (vfs);
            fake_folder.sync_journal ().internal_pin_states.set_for_path ("", Vfs.ItemAvailability.ONLINE_ONLY);

            // make files virtual
            fake_folder.sync_once ();
        }

        fake_folder.server_error_paths ().append (src, 403);
        fake_folder.local_modifier.rename (get_name (src), get_name (dest));
        GLib.assert_true (!fake_folder.current_local_state ().find (get_name (src)));
        GLib.assert_true (fake_folder.current_local_state ().find (get_name (dest)));
        GLib.assert_true (fake_folder.current_remote_state ().find (src));
        GLib.assert_true (!fake_folder.current_remote_state ().find (dest));

        // sync1 file gets detected as error, instruction is still NEW_FILE
        fake_folder.sync_once ();

        // sync2 file is in error state, check_error_blocklisting sets instruction to IGNORED
        fake_folder.sync_once ();

        if (vfs_mode != Vfs.Off) {
            fake_folder.sync_journal ().internal_pin_states.set_for_path ("", PinState.PinState.ALWAYS_LOCAL);
            fake_folder.sync_once ();
        }

        GLib.assert_true (!fake_folder.current_local_state ().find (src));
        GLib.assert_true (fake_folder.current_local_state ().find (get_name (dest)));
        if (vfs_mode == Vfs.WithSuffix) {
            // the placeholder was not restored as it is still in error state
            GLib.assert_true (!fake_folder.current_local_state ().find (dest));
        }
        GLib.assert_true (fake_folder.current_remote_state ().find (src));
        GLib.assert_true (!fake_folder.current_remote_state ().find (dest));
    }


    /***********************************************************
    ***********************************************************/
    private static string get_name (AbstractVfs.Mode vfs_mode, string s) {
        if (vfs_mode == Vfs.WithSuffix) {
            return s + APPLICATION_DOTVIRTUALFILE_SUFFIX;
        }
        return s;
    }

}

} // namespace Testing
} // namespace Occ
