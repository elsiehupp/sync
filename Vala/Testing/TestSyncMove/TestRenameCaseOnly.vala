/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestRenameCaseOnly : AbstractTestSyncMove {

    //  /***********************************************************
    //  These renames can be troublesome on windows
    //  ***********************************************************/
    //  private TestRenameCaseOnly () {
    //      FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
    //      var local = fake_folder.local_modifier;
    //      var remote = fake_folder.remote_modifier ();

    //      OperationCounter counter;
    //      fake_folder.set_server_override (counter.functor ());

    //      local.rename ("A/a1", "A/A1");
    //      remote.rename ("A/a2", "A/A2");

    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state () == remote);
    //      GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (fake_folder.current_remote_state ()));
    //      GLib.assert_true (counter.number_of_get == 0);
    //      GLib.assert_true (counter.number_of_put == 0);
    //      GLib.assert_true (counter.number_of_move == 1);
    //      GLib.assert_true (counter.number_of_delete == 0);
    //  }

} // class TestRenameCaseOnly

} // namespace Testing
} // namespace Occ
