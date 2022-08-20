/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestDiscoveryHiddenFile : AbstractTestSyncEngine {

//    /***********************************************************
//    ***********************************************************/
//    private TestDiscoveryHiddenFile () {
//        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
//        GLib.assert_true (fake_folder.sync_once ());
//        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

//        fake_folder.sync_engine.set_ignore_hidden_files (true);
//        fake_folder.remote_modifier ().insert ("A/.hidden");
//        fake_folder.local_modifier.insert ("B/.hidden");
//        GLib.assert_true (fake_folder.sync_once ());
//        GLib.assert_true (!local_file_exists ("A/.hidden"));
//        GLib.assert_true (!fake_folder.current_remote_state ().find ("B/.hidden"));

//        fake_folder.sync_engine.set_ignore_hidden_files (false);
//        fake_folder.sync_journal ().force_remote_discovery_next_sync ();
//        GLib.assert_true (fake_folder.sync_once ());
//        GLib.assert_true (local_file_exists ("A/.hidden"));
//        GLib.assert_true (fake_folder.current_remote_state ().find ("B/.hidden"));
//    }


//    /***********************************************************
//    We can't depend on current_local_state for hidden files since
//    it should rightfully skip things like download temporaries
//    ***********************************************************/
//    private static FileInfo local_file_exists (FakeFolder fake_folder, string name) {
//        return new FileInfo (fake_folder.local_path + name).exists ();
//    }

} // class TestDiscoveryHiddenFile

} // namespace Testing
} // namespace Occ
