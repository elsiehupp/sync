/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestSyncDeleteIssue1329 { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestSyncDeleteIssue1329 () {
        //  FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        //  fake_folder.local_modifier.remove ("B");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        //  // Add a directory that was just removed in the previous sync:
        //  fake_folder.local_modifier.mkdir ("B");
        //  fake_folder.local_modifier.insert ("B/b1");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_remote_state ().find ("B/b1"));
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }

} // class TestSyncDeleteIssue1329

} // namespace Testing
} // namespace Occ
