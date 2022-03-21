namespace Occ {
namespace Testing {

/***********************************************************
@class TestIncompatiblePins

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestIncompatiblePins : AbstractTestSyncVirtualFiles {

    /***********************************************************
    ***********************************************************/
    private TestIncompatiblePins () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        Vfs vfs = set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("online");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        TestSyncVirtualFiles.set_pin ("local", PinState.PinState.ALWAYS_LOCAL);
        TestSyncVirtualFiles.set_pin ("online", Vfs.ItemAvailability.ONLINE_ONLY);

        fake_folder.local_modifier.insert ("local/file1");
        fake_folder.local_modifier.insert ("online/file1");
        GLib.assert_true (fake_folder.sync_once ());

        mark_for_dehydration (fake_folder, "local/file1");
        trigger_download (fake_folder, "online/file1");

        // the sync sets the changed files pin states to unspecified
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state ().find ("online/file1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("local/file1" + DVSUFFIX));
        GLib.assert_true (vfs.pin_state ("online/file1") == PinState.PinState.UNSPECIFIED);
        GLib.assert_true (vfs.pin_state ("local/file1" + DVSUFFIX) == PinState.PinState.UNSPECIFIED);

        // no change on another sync
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("online/file1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("local/file1" + DVSUFFIX));
    }

} // class TestIncompatiblePins

} // namespace Testing
} // namespace Occ
