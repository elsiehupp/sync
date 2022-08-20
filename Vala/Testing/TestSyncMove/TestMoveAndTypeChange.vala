/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestMoveAndTypeChange : AbstractTestSyncMove {

//    /***********************************************************
//    Check interaction of moves with file type changes
//    ***********************************************************/
//    private TestMoveAndTypeChange () {
//        FakeFolder fake_folder = new FakeFolder (new FileInfo.A12_B12_C12_S12 ());
//        var local = fake_folder.local_modifier;
//        var remote = fake_folder.remote_modifier ();

//        // Touch on one side, rename and mkdir on the other {
//            local.append_byte ("A/a1");
//            remote.rename ("A/a1", "A/a1mq");
//            remote.mkdir ("A/a1");
//            remote.append_byte ("B/b1");
//            local.rename ("B/b1", "B/b1mq");
//            local.mkdir ("B/b1");
//            ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
//            GLib.assert_true (fake_folder.sync_once ());
//            // BUG : This doesn't behave right
//            //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
//        }
//    }

} // class TestMoveAndTypeChange

} // namespace Testing
} // namespace Occ
