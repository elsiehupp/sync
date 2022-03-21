namespace Occ {
namespace Testing {

/***********************************************************
@class TestSyncVirtualFilesAvailability

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestSyncVirtualFilesAvailability : AbstractTestSyncVirtualFiles {

    /***********************************************************
    ***********************************************************/
    private TestSyncVirtualFilesAvailability () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        Vfs vfs = set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("local/sub");
        fake_folder.remote_modifier ().mkdir ("online");
        fake_folder.remote_modifier ().mkdir ("online/sub");
        fake_folder.remote_modifier ().mkdir ("unspec");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        TestSyncVirtualFiles.set_pin ("local", PinState.PinState.ALWAYS_LOCAL);
        TestSyncVirtualFiles.set_pin ("online", Vfs.ItemAvailability.ONLINE_ONLY);
        TestSyncVirtualFiles.set_pin ("unspec", PinState.PinState.UNSPECIFIED);

        fake_folder.remote_modifier ().insert ("file1");
        fake_folder.remote_modifier ().insert ("online/file1");
        fake_folder.remote_modifier ().insert ("online/file2");
        fake_folder.remote_modifier ().insert ("local/file1");
        fake_folder.remote_modifier ().insert ("local/file2");
        fake_folder.remote_modifier ().insert ("unspec/file1");
        GLib.assert_true (fake_folder.sync_once ());

        // root is unspecified
        GLib.assert_true (vfs.availability ("file1" + DVSUFFIX) == Vfs.ItemAvailability.ALL_DEHYDRATED);
        GLib.assert_true (vfs.availability ("local") == Vfs.ItemAvailability.PinState.ALWAYS_LOCAL);
        GLib.assert_true (vfs.availability ("local/file1") == Vfs.ItemAvailability.PinState.ALWAYS_LOCAL);
        GLib.assert_true (vfs.availability ("online") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (vfs.availability ("online/file1" + DVSUFFIX) == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (vfs.availability ("unspec") == Vfs.ItemAvailability.ALL_DEHYDRATED);
        GLib.assert_true (vfs.availability ("unspec/file1" + DVSUFFIX) == Vfs.ItemAvailability.ALL_DEHYDRATED);

        // Subitem pin states can ruin "pure" availabilities
        TestSyncVirtualFiles.set_pin ("local/sub", Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (vfs.availability ("local") == Vfs.ItemAvailability.ALL_HYDRATED);
        TestSyncVirtualFiles.set_pin ("online/sub", PinState.PinState.UNSPECIFIED);
        GLib.assert_true (vfs.availability ("online") == Vfs.ItemAvailability.ALL_DEHYDRATED);

        trigger_download (fake_folder, "unspec/file1");
        TestSyncVirtualFiles.set_pin ("local/file2", Vfs.ItemAvailability.ONLINE_ONLY);
        TestSyncVirtualFiles.set_pin ("online/file2" + DVSUFFIX, PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (vfs.availability ("unspec") == Vfs.ItemAvailability.ALL_HYDRATED);
        GLib.assert_true (vfs.availability ("local") == Vfs.ItemAvailability.MIXED);
        GLib.assert_true (vfs.availability ("online") == Vfs.ItemAvailability.MIXED);

        GLib.assert_true (vfs.set_pin_state ("local", PinState.PinState.ALWAYS_LOCAL));
        GLib.assert_true (vfs.set_pin_state ("online", Vfs.ItemAvailability.ONLINE_ONLY));
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (vfs.availability ("online") == Vfs.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (vfs.availability ("local") == Vfs.ItemAvailability.PinState.ALWAYS_LOCAL);

        var r = vfs.availability ("nonexistant");
        GLib.assert_true (!r);
        GLib.assert_true (r.error == Vfs.AvailabilityError.NO_SUCH_ITEM);
    }

} // class TestSyncVirtualFilesAvailability

} // namespace Testing
} // namespace Occ
