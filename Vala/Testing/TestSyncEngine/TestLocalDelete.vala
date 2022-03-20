/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public abstract class TestLocalDelete : AbstractTestSyncEngine {

    /***********************************************************
    ***********************************************************/
    private TestLocalDelete () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        fake_folder.remote_modifier ().remove ("A/a1");
        fake_folder.sync_once ();
        GLib.assert_true (item_did_complete_successfully (complete_spy, "A/a1"));
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }

} // class TestLocalDelete

} // namespace Testing
} // namespace Occ
