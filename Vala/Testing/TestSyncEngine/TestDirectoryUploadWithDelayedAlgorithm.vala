/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestDirectoryUploadWithDelayedAlgorithm : AbstractTestSyncEngine {

//    /***********************************************************
//    ***********************************************************/
//    private TestDirectoryUploadWithDelayedAlgorithm () {
//        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
//        fake_folder.sync_engine.account.set_capabilities (
//            {
//                {
//                    "dav", new GLib.HashMap (
//                        {
//                            "bulkupload", "1.0"
//                        }
//                    )
//                }
//            }
//        );

//        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
//        fake_folder.local_modifier.mkdir ("Y");
//        fake_folder.local_modifier.insert ("Y/d0");
//        fake_folder.local_modifier.mkdir ("Z");
//        fake_folder.local_modifier.insert ("Z/d0");
//        fake_folder.local_modifier.insert ("A/a0");
//        fake_folder.local_modifier.insert ("B/b0");
//        fake_folder.local_modifier.insert ("r0");
//        fake_folder.local_modifier.insert ("r1");
//        fake_folder.sync_once ();
//        GLib.assert_true (item_did_complete_successfully_with_expected_rank (complete_spy, "Y", 0));
//        GLib.assert_true (item_did_complete_successfully_with_expected_rank (complete_spy, "Z", 1));
//        GLib.assert_true (item_did_complete_successfully (complete_spy, "Y/d0"));
//        GLib.assert_true (item_successfully_completed_get_rank (complete_spy, "Y/d0") > 1);
//        GLib.assert_true (item_did_complete_successfully (complete_spy, "Z/d0"));
//        GLib.assert_true (item_successfully_completed_get_rank (complete_spy, "Z/d0") > 1);
//        GLib.assert_true (item_did_complete_successfully (complete_spy, "A/a0"));
//        GLib.assert_true (item_successfully_completed_get_rank (complete_spy, "A/a0") > 1);
//        GLib.assert_true (item_did_complete_successfully (complete_spy, "B/b0"));
//        GLib.assert_true (item_successfully_completed_get_rank (complete_spy, "B/b0") > 1);
//        GLib.assert_true (item_did_complete_successfully (complete_spy, "r0"));
//        GLib.assert_true (item_successfully_completed_get_rank (complete_spy, "r0") > 1);
//        GLib.assert_true (item_did_complete_successfully (complete_spy, "r1"));
//        GLib.assert_true (item_successfully_completed_get_rank (complete_spy, "r1") > 1);
//        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
//    }

} // class TestDirectoryUploadWithDelayedAlgorithm

} // namespace Testing
} // namespace Occ
