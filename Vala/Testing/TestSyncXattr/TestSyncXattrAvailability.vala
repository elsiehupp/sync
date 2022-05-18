namespace Occ {
namespace Testing {

/***********************************************************
@class TestSyncXattrAvailability

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestSyncXattrAvailability : AbstractTestSyncXAttr {

    /***********************************************************
    ***********************************************************/
    private TestSyncXattrAvailability () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        var vfs = set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());


        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("local/sub");
        fake_folder.remote_modifier ().mkdir ("online");
        fake_folder.remote_modifier ().mkdir ("online/sub");
        fake_folder.remote_modifier ().mkdir ("unspec");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        set_pin ("local", PinState.ALWAYS_LOCAL);
        set_pin ("online", Common.ItemAvailability.ONLINE_ONLY);
        set_pin ("unspec", PinState.UNSPECIFIED);

        fake_folder.remote_modifier ().insert ("file1");
        fake_folder.remote_modifier ().insert ("online/file1");
        fake_folder.remote_modifier ().insert ("online/file2");
        fake_folder.remote_modifier ().insert ("local/file1");
        fake_folder.remote_modifier ().insert ("local/file2");
        fake_folder.remote_modifier ().insert ("unspec/file1");
        GLib.assert_true (fake_folder.sync_once ());

        // root is unspecified
        GLib.assert_true (vfs.availability ("file1") == Common.ItemAvailability.ALL_DEHYDRATED);
        GLib.assert_true (vfs.availability ("local") == Common.ItemAvailability.PinState.ALWAYS_LOCAL);
        GLib.assert_true (vfs.availability ("local/file1") == Common.ItemAvailability.PinState.ALWAYS_LOCAL);
        GLib.assert_true (vfs.availability ("online") == Common.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (vfs.availability ("online/file1") == Common.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (vfs.availability ("unspec") ==  Common.ItemAvailability.ALL_DEHYDRATED);
        GLib.assert_true (vfs.availability ("unspec/file1") == Common.ItemAvailability.ALL_DEHYDRATED);

        // Subitem pin states can ruin "pure" availabilities
        set_pin ("local/sub", Common.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (vfs.availability ("local") == Common.ItemAvailability.ALL_HYDRATED);
        set_pin ("online/sub", PinState.UNSPECIFIED);
        GLib.assert_true (vfs.availability ("online") == Common.ItemAvailability.ALL_DEHYDRATED);

        trigger_download (fake_folder, "unspec/file1");
        set_pin ("local/file2", Common.ItemAvailability.ONLINE_ONLY);
        set_pin ("online/file2", PinState.ALWAYS_LOCAL);
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (vfs.availability ("unspec") == Common.ItemAvailability.ALL_HYDRATED);
        GLib.assert_true (vfs.availability ("local") == Common.ItemAvailability.MIXED);
        GLib.assert_true (vfs.availability ("online") == Common.ItemAvailability.MIXED);

        GLib.assert_true (vfs.set_pin_state ("local", PinState.ALWAYS_LOCAL));
        GLib.assert_true (vfs.set_pin_state ("online", Common.ItemAvailability.ONLINE_ONLY));
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (vfs.availability ("online") == Common.ItemAvailability.ONLINE_ONLY);
        GLib.assert_true (vfs.availability ("local") == Common.ItemAvailability.PinState.ALWAYS_LOCAL);

        var r = vfs.availability ("nonexistant");
        GLib.assert_true (!r);
        GLib.assert_true (r.error == Common.AbstractVfs.AvailabilityError.NO_SUCH_ITEM);
    }

} // class TestSyncXattrAvailability

} // namespace Testing
} // namespace Occ
