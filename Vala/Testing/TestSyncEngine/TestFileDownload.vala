/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestFileDownload : AbstractTestSyncEngine {

    /***********************************************************
    ***********************************************************/
    private TestFileDownload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        fake_folder.remote_modifier ().insert ("A/a0");
        fake_folder.sync_once ();
        GLib.assert_true (item_did_complete_successfully (complete_spy, "A/a0"));
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }

} // class TestFileDownload

} // namespace Testing
} // namespace Occ
