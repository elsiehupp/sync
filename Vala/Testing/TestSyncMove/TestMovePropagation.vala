/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestMovePropagation : AbstractTestSyncMove {

    /***********************************************************
    ***********************************************************/
    private TestMovePropagation () {
        //  FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        //  var local = fake_folder.local_modifier;
        //  var remote = fake_folder.remote_modifier ();

        //  OperationCounter counter;
        //  fake_folder.set_server_override (counter.functor ());

        //  // Move {
        //      counter.reset ();
        //      local.rename ("A/a1", "A/a1m");
        //      remote.rename ("B/b1", "B/b1m");
        //      ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        //      GLib.assert_true (fake_folder.sync_once ());
        //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //      GLib.assert_true (counter.number_of_get == 0);
        //      GLib.assert_true (counter.number_of_put == 0);
        //      GLib.assert_true (counter.number_of_move == 1);
        //      GLib.assert_true (counter.number_of_delete == 0);
        //      GLib.assert_true (item_successful_move (complete_spy, "A/a1m"));
        //      GLib.assert_true (item_successful_move (complete_spy, "B/b1m"));
        //      GLib.assert_true (complete_spy.find_item ("A/a1m").file == "A/a1");
        //      GLib.assert_true (complete_spy.find_item ("A/a1m").rename_target == "A/a1m");
        //      GLib.assert_true (complete_spy.find_item ("B/b1m").file == "B/b1");
        //      GLib.assert_true (complete_spy.find_item ("B/b1m").rename_target == "B/b1m");
        //  //  }

        //  // Touch+Move on same side
        //  counter.reset ();
        //  local.rename ("A/a2", "A/a2m");
        //  local.set_contents ("A/a2m", 'A');
        //  remote.rename ("B/b2", "B/b2m");
        //  remote.set_contents ("B/b2m", 'A');
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  GLib.assert_true (print_database_data (fake_folder.database_state ()), print_database_data (fake_folder.current_remote_state ()));
        //  GLib.assert_true (counter.number_of_get == 1);
        //  GLib.assert_true (counter.number_of_put == 1);
        //  GLib.assert_true (counter.number_of_move == 0);
        //  GLib.assert_true (counter.number_of_delete == 1);
        //  GLib.assert_true (remote.find ("A/a2m").content_char == 'A');
        //  GLib.assert_true (remote.find ("B/b2m").content_char == 'A');

        //  // Touch+Move on opposite sides
        //  counter.reset ();
        //  local.rename ("A/a1m", "A/a1m2");
        //  remote.set_contents ("A/a1m", 'B');
        //  remote.rename ("B/b1m", "B/b1m2");
        //  local.set_contents ("B/b1m", 'B');
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        //  GLib.assert_true (counter.number_of_get == 2);
        //  GLib.assert_true (counter.number_of_put == 2);
        //  GLib.assert_true (counter.number_of_move == 0);
        //  GLib.assert_true (counter.number_of_delete == 0);
        //  // All these files existing afterwards is debatable. Should we propagate
        //  // the rename in one direction and grab the new contents in the other?
        //  // Currently there's no propagation job that would do that, and this does
        //  // at least not lose data.
        //  GLib.assert_true (remote.find ("A/a1m").content_char == 'B');
        //  GLib.assert_true (remote.find ("B/b1m").content_char == 'B');
        //  GLib.assert_true (remote.find ("A/a1m2").content_char == 'W');
        //  GLib.assert_true (remote.find ("B/b1m2").content_char == 'W');

        //  // Touch+create on one side, move on the other {
        //      counter.reset ();
        //      local.append_byte ("A/a1m");
        //      local.insert ("A/a1mt");
        //      remote.rename ("A/a1m", "A/a1mt");
        //      remote.append_byte ("B/b1m");
        //      remote.insert ("B/b1mt");
        //      local.rename ("B/b1m", "B/b1mt");
        //      complete_spy = new ItemCompletedSpy (fake_folder);
        //      GLib.assert_true (fake_folder.sync_once ());
        //      GLib.assert_true (expect_and_wipe_conflict (local, fake_folder.current_local_state (), "A/a1mt"));
        //      GLib.assert_true (expect_and_wipe_conflict (local, fake_folder.current_local_state (), "B/b1mt"));
        //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //      GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        //      GLib.assert_true (counter.number_of_get == 3);
        //      GLib.assert_true (counter.number_of_put == 1);
        //      GLib.assert_true (counter.number_of_move == 0);
        //      GLib.assert_true (counter.number_of_delete == 0);
        //      GLib.assert_true (item_successful (complete_spy, "A/a1m", CSync.SyncInstructions.NEW));
        //      GLib.assert_true (item_successful (complete_spy, "B/b1m", CSync.SyncInstructions.NEW));
        //      GLib.assert_true (item_conflict (complete_spy, "A/a1mt"));
        //      GLib.assert_true (item_conflict (complete_spy, "B/b1mt"));
        //  //  }

        //  // Create new on one side, move to new on the other {
        //      counter.reset ();
        //      local.insert ("A/a1N", 13);
        //      remote.rename ("A/a1mt", "A/a1N");
        //      remote.insert ("B/b1N", 13);
        //      local.rename ("B/b1mt", "B/b1N");
        //      complete_spy = new ItemCompletedSpy (fake_folder);
        //      GLib.assert_true (fake_folder.sync_once ());
        //      GLib.assert_true (expect_and_wipe_conflict (local, fake_folder.current_local_state (), "A/a1N"));
        //      GLib.assert_true (expect_and_wipe_conflict (local, fake_folder.current_local_state (), "B/b1N"));
        //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //      GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        //      GLib.assert_true (counter.number_of_get == 2);
        //      GLib.assert_true (counter.number_of_put == 0);
        //      GLib.assert_true (counter.number_of_move == 0);
        //      GLib.assert_true (counter.number_of_delete == 1);
        //      GLib.assert_true (item_successful (complete_spy, "A/a1mt", CSync.SyncInstructions.REMOVE));
        //      GLib.assert_true (item_successful (complete_spy, "B/b1mt", CSync.SyncInstructions.REMOVE));
        //      GLib.assert_true (item_conflict (complete_spy, "A/a1N"));
        //      GLib.assert_true (item_conflict (complete_spy, "B/b1N"));
        //  //  }

        //  // Local move, remote move
        //  counter.reset ();
        //  local.rename ("C/c1", "C/c1m_l");
        //  remote.rename ("C/c1", "C/c1m_r");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  // end up with both files
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        //  GLib.assert_true (counter.number_of_get == 1);
        //  GLib.assert_true (counter.number_of_put == 1);
        //  GLib.assert_true (counter.number_of_move == 0);
        //  GLib.assert_true (counter.number_of_delete == 0);

        //  // Rename/rename conflict on a folder
        //  counter.reset ();
        //  remote.rename ("C", "CMR");
        //  local.rename ("C", "CML");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  // End up with both folders
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        //  GLib.assert_true (counter.number_of_get == 3); // 3 files in C
        //  GLib.assert_true (counter.number_of_put == 3);
        //  GLib.assert_true (counter.number_of_move == 0);
        //  GLib.assert_true (counter.number_of_delete == 0);

        //  // FolderConnection move {
        //      counter.reset ();
        //      local.rename ("A", "AM");
        //      remote.rename ("B", "BM");
        //      complete_spy = new ItemCompletedSpy (fake_folder);
        //      GLib.assert_true (fake_folder.sync_once ());
        //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //      GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        //      GLib.assert_true (counter.number_of_get == 0);
        //      GLib.assert_true (counter.number_of_put == 0);
        //      GLib.assert_true (counter.number_of_move == 1);
        //      GLib.assert_true (counter.number_of_delete == 0);
        //      GLib.assert_true (item_successful_move (complete_spy == "AM"));
        //      GLib.assert_true (item_successful_move (complete_spy == "BM"));
        //      GLib.assert_true (complete_spy.find_item ("AM").file == "A");
        //      GLib.assert_true (complete_spy.find_item ("AM").rename_target == "AM");
        //      GLib.assert_true (complete_spy.find_item ("BM").file == "B");
        //      GLib.assert_true (complete_spy.find_item ("BM").rename_target == "BM");
        //  //  }

        //  // FolderConnection move with contents touched on the same side {
        //      counter.reset ();
        //      local.set_contents ("AM/a2m", 'C');
        //      // We must change the modtime for it is likely that it did not change between sync.
        //      // (Previous version of the client (<=2.5) would not need this because it was always doing
        //      // checksum comparison for all renames. But newer version no longer does it if the file is
        //      // renamed because the parent folder is renamed)
        //      local.set_modification_time ("AM/a2m", GLib.DateTime.current_date_time_utc ().add_days (3));
        //      local.rename ("AM", "A2");
        //      remote.set_contents ("BM/b2m", 'C');
        //      remote.rename ("BM", "B2");
        //      complete_spy = new ItemCompletedSpy (fake_folder);
        //      GLib.assert_true (fake_folder.sync_once ());
        //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //      GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        //      GLib.assert_true (counter.number_of_get == 1);
        //      GLib.assert_true (counter.number_of_put == 1);
        //      GLib.assert_true (counter.number_of_move == 1);
        //      GLib.assert_true (counter.number_of_delete == 0);
        //      GLib.assert_true (remote.find ("A2/a2m").content_char == 'C');
        //      GLib.assert_true (remote.find ("B2/b2m").content_char == 'C');
        //      GLib.assert_true (item_successful_move (complete_spy, "A2"));
        //      GLib.assert_true (item_successful_move (complete_spy, "B2"));
        //  //  }

        //  // FolderConnection rename with contents touched on the other tree
        //  counter.reset ();
        //  remote.set_contents ("A2/a2m", 'D');
        //  // set_contents alone may not produce updated mtime if the test is fast
        //  // and since we don't use checksums here, that matters.
        //  remote.append_byte ("A2/a2m");
        //  local.rename ("A2", "A3");
        //  local.set_contents ("B2/b2m", 'D');
        //  local.append_byte ("B2/b2m");
        //  remote.rename ("B2", "B3");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        //  GLib.assert_true (counter.number_of_get == 1);
        //  GLib.assert_true (counter.number_of_put == 1);
        //  GLib.assert_true (counter.number_of_move == 1);
        //  GLib.assert_true (counter.number_of_delete == 0);
        //  GLib.assert_true (remote.find ("A3/a2m").content_char == 'D');
        //  GLib.assert_true (remote.find ("B3/b2m").content_char == 'D');

        //  // FolderConnection rename with contents touched on both ends
        //  counter.reset ();
        //  remote.set_contents ("A3/a2m", 'R');
        //  remote.append_byte ("A3/a2m");
        //  local.set_contents ("A3/a2m", 'L');
        //  local.append_byte ("A3/a2m");
        //  local.append_byte ("A3/a2m");
        //  local.rename ("A3", "A4");
        //  remote.set_contents ("B3/b2m", 'R');
        //  remote.append_byte ("B3/b2m");
        //  local.set_contents ("B3/b2m", 'L');
        //  local.append_byte ("B3/b2m");
        //  local.append_byte ("B3/b2m");
        //  remote.rename ("B3", "B4");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  var current_local = fake_folder.current_local_state ();
        //  var conflicts = find_conflicts (current_local.children["A4"]);
        //  GLib.assert_true (conflicts.size () == 1);
        //  foreach (var c in conflicts) {
        //      GLib.assert_true (current_local.find (c).content_char == 'L');
        //      local.remove (c);
        //  }
        //  conflicts = find_conflicts (current_local.children["B4"]);
        //  GLib.assert_true (conflicts.size () == 1);
        //  foreach (var c in conflicts) {
        //      GLib.assert_true (current_local.find (c).content_char == 'L');
        //      local.remove (c);
        //  }
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        //  GLib.assert_true (counter.number_of_get == 2);
        //  GLib.assert_true (counter.number_of_put == 0);
        //  GLib.assert_true (counter.number_of_move == 1);
        //  GLib.assert_true (counter.number_of_delete == 0);
        //  GLib.assert_true (remote.find ("A4/a2m").content_char == 'R');
        //  GLib.assert_true (remote.find ("B4/b2m").content_char == 'R');

        //  // Rename a folder and rename the contents at the same time
        //  counter.reset ();
        //  local.rename ("A4/a2m", "A4/a2m2");
        //  local.rename ("A4", "A5");
        //  remote.rename ("B4/b2m", "B4/b2m2");
        //  remote.rename ("B4", "B5");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        //  GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
        //  GLib.assert_true (counter.number_of_get == 0);
        //  GLib.assert_true (counter.number_of_put == 0);
        //  GLib.assert_true (counter.number_of_move == 2);
        //  GLib.assert_true (counter.number_of_delete == 0);
    }

} // class TestMovePropagation

} // namespace Testing
} // namespace Occ
