/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestMovedWithError : AbstractTestSyncMove {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestMovedWithError () {
    //      GLib.FETCH (VfsMode, vfs_mode);
    //      string src = "folder/folder_a/file.txt";
    //      string dest = "folder/folder_b/file.txt";
    //      FakeFolder fake_folder = new FakeFolder (
    //          new FileInfo (
    //              "", {
    //                  new FileInfo (
    //                      "folder", {
    //                          new FileInfo (
    //                              "folder_a", {
    //                                  {
    //                                      "file.txt", 400
    //                                  }
    //                              }
    //                          ), "folder_b"
    //                      }
    //                  )
    //              }
    //          )
    //      );
    //      var sync_opts = fake_folder.sync_engine.sync_options ();
    //      sync_opts.parallel_network_jobs = 0;
    //      fake_folder.sync_engine.set_sync_options (sync_opts);

    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

    //      if (vfs_mode != Common.AbstractVfs.Off) {
    //          var vfs = unowned<Common.AbstractVfs> (create_vfs_from_plugin (vfs_mode).release ());
    //          GLib.assert_true (vfs);
    //          fake_folder.switch_to_vfs (vfs);
    //          fake_folder.sync_journal ().internal_pin_states.set_for_path ("", Common.ItemAvailability.ONLINE_ONLY);

    //          // make files virtual
    //          fake_folder.sync_once ();
    //      }

    //      fake_folder.server_error_paths ().append (src, 403);
    //      fake_folder.local_modifier.rename (get_name (src), get_name (dest));
    //      GLib.assert_true (!fake_folder.current_local_state ().find (get_name (src)));
    //      GLib.assert_true (fake_folder.current_local_state ().find (get_name (dest)));
    //      GLib.assert_true (fake_folder.current_remote_state ().find (src));
    //      GLib.assert_true (!fake_folder.current_remote_state ().find (dest));

    //      // sync1 file gets detected as error, instruction is still NEW_FILE
    //      fake_folder.sync_once ();

    //      // sync2 file is in error state, check_error_blocklisting sets instruction to IGNORED
    //      fake_folder.sync_once ();

    //      if (vfs_mode != Common.AbstractVfs.Off) {
    //          fake_folder.sync_journal ().internal_pin_states.set_for_path ("", PinState.ALWAYS_LOCAL);
    //          fake_folder.sync_once ();
    //      }

    //      GLib.assert_true (!fake_folder.current_local_state ().find (src));
    //      GLib.assert_true (fake_folder.current_local_state ().find (get_name (dest)));
    //      if (vfs_mode == Common.AbstractVfs.WithSuffix) {
    //          // the placeholder was not restored as it is still in error state
    //          GLib.assert_true (!fake_folder.current_local_state ().find (dest));
    //      }
    //      GLib.assert_true (fake_folder.current_remote_state ().find (src));
    //      GLib.assert_true (!fake_folder.current_remote_state ().find (dest));
    //  }

} // class TestMovedWithError

} // namespace Testing
} // namespace Occ
