/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public abstract class AbstractTestSyncFileStatusTracker { //: GLib.Object {

//    protected static void verify_that_push_matches_pull (FakeFolder fake_folder, StatusPushSpy status_spy) {
//        string root = fake_folder.local_path;
//        GLib.DirIterator it = new GLib.DirIterator (root, GLib.Dir.AllEntries | GLib.Dir.NoDotAndDotDot, GLib.DirIterator.Subdirectories);
//        while (it.has_next ()) {
//            string file_path = it.next ().mid (root.size ());
//            SyncFileStatus pushed_status = status_spy.status_of (file_path);
//            if (pushed_status != new SyncFileStatus ()) {
//                GLib.assert_true (fake_folder.sync_engine.sync_file_status_tracker.file_status (file_path) == pushed_status);
//            }
//        }
//    }

} // class AbstractTestSyncFileStatusTracker

} // namespace Testing
} // namespace Occ
