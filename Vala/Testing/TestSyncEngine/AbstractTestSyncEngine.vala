/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public abstract class AbstractTestSyncEngine { //: GLib.Object {

//    protected static bool item_did_complete (ItemCompletedSpy spy, string path) {
//        var item = spy.find_item (path);
//        if (item) {
//            return item.instruction != CSync.SyncInstructions.NONE && item.instruction != CSync.SyncInstructions.UPDATE_METADATA;
//        }
//        return false;
//    }


//    protected static bool item_instruction (ItemCompletedSpy spy, string path, CSync.SyncInstructions instr) {
//        var item = spy.find_item (path);
//        return item.instruction == instr;
//    }


//    protected static bool item_did_complete_successfully (ItemCompletedSpy spy, string path) {
//        var item = spy.find_item (path);
//        if (item) {
//            return item.status == LibSync.SyncFileItem.Status.SUCCESS;
//        }
//        return false;
//    }


//    protected static bool item_did_complete_successfully_with_expected_rank (ItemCompletedSpy spy, string path, int rank) {
//        var item = spy.find_item_with_expected_rank (path, rank);
//        if (item) {
//            return item.status == LibSync.SyncFileItem.Status.SUCCESS;
//        }
//        return false;
//    }


//    protected static int item_successfully_completed_get_rank (ItemCompletedSpy spy, string path) {
//        var it_item = std.find_if (spy.begin (), spy.end (), (current_item) => {
//            var item = current_item[0].template_value<LibSync.SyncFileItem> ();
//            return item.destination () == path;
//        });
//        if (it_item != spy.end ()) {
//            return it_item - spy.begin ();
//        }
//        return -1;
//    }

} // class AbstractTestSyncEngine

} // namespace Testing
} // namespace Occ
