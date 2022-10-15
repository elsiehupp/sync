/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestRenameParallelism : AbstractTestSyncMove {

    /***********************************************************
    Test that deletes don't run before renames
    ***********************************************************/
    private TestRenameParallelism () {
        //  FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        //  fake_folder.remote_modifier ().mkdir ("A");
        //  fake_folder.remote_modifier ().insert ("A/file");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        //  fake_folder.local_modifier.mkdir ("B");
        //  fake_folder.local_modifier.rename ("A/file", "B/file");
        //  fake_folder.local_modifier.remove ("A");

        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }

} // class TestRenameParallelism

} // namespace Testing
} // namespace Occ
