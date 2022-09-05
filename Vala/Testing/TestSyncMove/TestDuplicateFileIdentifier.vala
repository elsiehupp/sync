/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestDuplicateFileIdentifier : AbstractTestSyncMove {

    //  /***********************************************************
    //  If the same folder is shared in two different ways with the
    //  same user, the target user will see duplicate file ids. We
    //  need to make sure the move detection and sync still do the
    //  right thing in that case.
    //  ***********************************************************/
    //  private TestDuplicateFileIdentifier () {
    //      GLib.FETCH (string, prefix);

    //      FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
    //      var remote = fake_folder.remote_modifier ();

    //      remote.mkdir ("A/W");
    //      remote.insert ("A/W/w1");
    //      remote.mkdir ("A/Q");

    //      // Duplicate every entry in A under O/A
    //      remote.mkdir (prefix);
    //      remote.children[prefix].add_child (remote.children["A"]);

    //      // This already checks that the rename detection doesn't get
    //      // horribly confused if we add new files that have the same
    //      // fileid as existing ones
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

    //      OperationCounter counter;
    //      fake_folder.set_server_override (counter.functor ());

    //      // Try a remote file move
    //      remote.rename ("A/a1", "A/W/a1m");
    //      remote.rename (prefix + "/A/a1", prefix + "/A/W/a1m");
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    //      GLib.assert_true (counter.number_of_get == 0);

    //      // And a remote directory move
    //      remote.rename ("A/W", "A/Q/W");
    //      remote.rename (prefix + "/A/W", prefix + "/A/Q/W");
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    //      GLib.assert_true (counter.number_of_get == 0);

    //      // Partial file removal (in practice, A/a2 may be moved to O/a2, but we don't care)
    //      remote.rename (prefix + "/A/a2", prefix + "/a2");
    //      remote.remove ("A/a2");
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    //      GLib.assert_true (counter.number_of_get == 0);

    //      // Local change plus remote move at the same time
    //      fake_folder.local_modifier.append_byte (prefix + "/a2");
    //      remote.rename (prefix + "/a2", prefix + "/a3");
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    //      GLib.assert_true (counter.number_of_get == 1);
    //      counter.reset ();

    //      // remove localy, and remote move at the same time
    //      fake_folder.local_modifier.remove ("A/Q/W/a1m");
    //      remote.rename ("A/Q/W/a1m", "A/Q/W/a1p");
    //      remote.rename (prefix + "/A/Q/W/a1m", prefix + "/A/Q/W/a1p");
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    //      GLib.assert_true (counter.number_of_get == 1);
    //      counter.reset ();
    //  }

} // class TestDuplicateFileIdentifier

} // namespace Testing
} // namespace Occ
