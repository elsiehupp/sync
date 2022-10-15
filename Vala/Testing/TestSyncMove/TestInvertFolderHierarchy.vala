/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestInvertFolderHierarchy : AbstractTestSyncMove {

    /***********************************************************
    Test for https://github.com/owncloud/client/issues/6694
    ***********************************************************/
    private TestInvertFolderHierarchy () {
        //  FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        //  fake_folder.remote_modifier ().mkdir ("A/Empty");
        //  fake_folder.remote_modifier ().mkdir ("A/Empty/Foo");
        //  fake_folder.remote_modifier ().mkdir ("C/AllEmpty");
        //  fake_folder.remote_modifier ().mkdir ("C/AllEmpty/Bar");
        //  fake_folder.remote_modifier ().insert ("A/Empty/f1");
        //  fake_folder.remote_modifier ().insert ("A/Empty/Foo/f2");
        //  fake_folder.remote_modifier ().mkdir ("C/AllEmpty/f3");
        //  fake_folder.remote_modifier ().mkdir ("C/AllEmpty/Bar/f4");
        //  GLib.assert_true (fake_folder.sync_once ());

        //  OperationCounter counter;
        //  fake_folder.set_server_override (counter.functor ());

        //  // "Empty" is after "A", alphabetically
        //  fake_folder.local_modifier.rename ("A/Empty", "Empty");
        //  fake_folder.local_modifier.rename ("A", "Empty/A");

        //  // "AllEmpty" is before "C", alphabetically
        //  fake_folder.local_modifier.rename ("C/AllEmpty", "AllEmpty");
        //  fake_folder.local_modifier.rename ("C", "AllEmpty/C");

        //  var expected_state = fake_folder.current_local_state ();
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == expected_state);
        //  GLib.assert_true (fake_folder.current_remote_state () == expected_state);
        //  GLib.assert_true (counter.number_of_delete == 0);
        //  GLib.assert_true (counter.number_of_get == 0);
        //  GLib.assert_true (counter.number_of_put == 0);

        //  // Now, the revert, but "crossed"
        //  fake_folder.local_modifier.rename ("Empty/A", "A");
        //  fake_folder.local_modifier.rename ("AllEmpty/C", "C");
        //  fake_folder.local_modifier.rename ("Empty", "C/Empty");
        //  fake_folder.local_modifier.rename ("AllEmpty", "A/AllEmpty");
        //  expected_state = fake_folder.current_local_state ();
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == expected_state);
        //  GLib.assert_true (fake_folder.current_remote_state () == expected_state);
        //  GLib.assert_true (counter.number_of_delete == 0);
        //  GLib.assert_true (counter.number_of_get == 0);
        //  GLib.assert_true (counter.number_of_put == 0);

        //  // Reverse on remote
        //  fake_folder.remote_modifier ().rename ("A/AllEmpty", "AllEmpty");
        //  fake_folder.remote_modifier ().rename ("C/Empty", "Empty");
        //  fake_folder.remote_modifier ().rename ("C", "AllEmpty/C");
        //  fake_folder.remote_modifier ().rename ("A", "Empty/A");
        //  expected_state = fake_folder.current_remote_state ();
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == expected_state);
        //  GLib.assert_true (fake_folder.current_remote_state () == expected_state);
        //  GLib.assert_true (counter.number_of_delete == 0);
        //  GLib.assert_true (counter.number_of_get == 0);
        //  GLib.assert_true (counter.number_of_put == 0);
    }

} // class TestInvertFolderHierarchy

} // namespace Testing
} // namespace Occ
