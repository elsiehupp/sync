/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestRemoveRemove : AbstractTestSyncConflict {

//    /***********************************************************
//    Test what happens if we remove entries both on the server,
//    and locally
//    ***********************************************************/
//    private TestRemoveRemove () {
//        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
//        fake_folder.remote_modifier ().remove ("A");
//        fake_folder.local_modifier.remove ("A");
//        fake_folder.remote_modifier ().remove ("B/b1");
//        fake_folder.local_modifier.remove ("B/b1");

//        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
//        var expected_state = fake_folder.current_local_state ();

//        GLib.assert_true (fake_folder.sync_once ());

//        GLib.assert_true (fake_folder.current_local_state () == expected_state);
//        GLib.assert_true (fake_folder.current_remote_state () == expected_state);

//        GLib.assert_true (database_record (fake_folder, "B/b2").is_valid);

//        GLib.assert_true (!database_record (fake_folder, "B/b1").is_valid);
//        GLib.assert_true (!database_record (fake_folder, "A/a1").is_valid);
//        GLib.assert_true (!database_record (fake_folder, "A").is_valid);
//    }

} // class TestRemoveRemove

} // namespace Testing
} // namespace Occ
