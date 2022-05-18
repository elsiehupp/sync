namespace Occ {
namespace Testing {

/***********************************************************
@class TestNewVirtuals

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestNewVirtuals : AbstractTestSyncVirtualFiles {

    /***********************************************************
    ***********************************************************/
    private TestNewVirtuals () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("online");
        fake_folder.remote_modifier ().mkdir ("unspec");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        TestSyncVirtualFiles.set_pin ("local", PinState.ALWAYS_LOCAL);
        TestSyncVirtualFiles.set_pin ("online", Common.ItemAvailability.ONLINE_ONLY);
        TestSyncVirtualFiles.set_pin ("unspec", PinState.UNSPECIFIED);

        // Test 1 : root is PinState.UNSPECIFIED
        fake_folder.remote_modifier ().insert ("file1");
        fake_folder.remote_modifier ().insert ("online/file1");
        fake_folder.remote_modifier ().insert ("local/file1");
        fake_folder.remote_modifier ().insert ("unspec/file1");
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state ().find ("file1" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("online/file1" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("local/file1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("unspec/file1" + DVSUFFIX));

        // Test 2 : change root to PinState.ALWAYS_LOCAL
        TestSyncVirtualFiles.set_pin ("", PinState.ALWAYS_LOCAL);

        fake_folder.remote_modifier ().insert ("file2");
        fake_folder.remote_modifier ().insert ("online/file2");
        fake_folder.remote_modifier ().insert ("local/file2");
        fake_folder.remote_modifier ().insert ("unspec/file2");
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state ().find ("file2"));
        GLib.assert_true (fake_folder.current_local_state ().find ("online/file2" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("local/file2"));
        GLib.assert_true (fake_folder.current_local_state ().find ("unspec/file2" + DVSUFFIX));

        // root file1 was hydrated due to its new pin state
        GLib.assert_true (fake_folder.current_local_state ().find ("file1"));

        // file1 is unchanged in the explicitly pinned subfolders
        GLib.assert_true (fake_folder.current_local_state ().find ("online/file1" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("local/file1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("unspec/file1" + DVSUFFIX));

        // Test 3 : change root to Common.ItemAvailability.ONLINE_ONLY
        TestSyncVirtualFiles.set_pin ("", Common.ItemAvailability.ONLINE_ONLY);

        fake_folder.remote_modifier ().insert ("file3");
        fake_folder.remote_modifier ().insert ("online/file3");
        fake_folder.remote_modifier ().insert ("local/file3");
        fake_folder.remote_modifier ().insert ("unspec/file3");
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state ().find ("file3" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("online/file3" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("local/file3"));
        GLib.assert_true (fake_folder.current_local_state ().find ("unspec/file3" + DVSUFFIX));

        // root file1 was dehydrated due to its new pin state
        GLib.assert_true (fake_folder.current_local_state ().find ("file1" + DVSUFFIX));

        // file1 is unchanged in the explicitly pinned subfolders
        GLib.assert_true (fake_folder.current_local_state ().find ("online/file1" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("local/file1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("unspec/file1" + DVSUFFIX));
    }

} // class TestNewVirtuals

} // namespace Testing
} // namespace Occ
