/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestNoUpload : AbstractTestSyncConflict {

    /***********************************************************
    ***********************************************************/
    private TestNoUpload () {
        //  FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        //  fake_folder.local_modifier.set_contents ("A/a1", 'L');
        //  fake_folder.remote_modifier ().set_contents ("A/a1", 'R');
        //  fake_folder.local_modifier.append_byte ("A/a2");
        //  fake_folder.remote_modifier ().append_byte ("A/a2");
        //  fake_folder.remote_modifier ().append_byte ("A/a2");
        //  GLib.assert_true (fake_folder.sync_once ());

        //  // Verify that the conflict names don't have the user name
        //  foreach (var name in find_conflicts (fake_folder.current_local_state ().children["A"])) {
        //      GLib.assert_true (!name.contains (fake_folder.sync_engine.account.dav_display_name ()));
        //  }

        //  GLib.assert_true (expect_and_wipe_conflict (fake_folder.local_modifier, fake_folder.current_local_state (), "A/a1"));
        //  GLib.assert_true (expect_and_wipe_conflict (fake_folder.local_modifier, fake_folder.current_local_state (), "A/a2"));
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }

} // class TestNoUpload

} // namespace Testing
} // namespace Occ
