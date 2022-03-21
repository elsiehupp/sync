namespace Occ {
namespace Testing {

/***********************************************************
@class TestIncompatiblePins

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestIncompatiblePins : AbstractTestSyncXAttr {

    /***********************************************************
    ***********************************************************/
    private TestIncompatiblePins () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        var vfs = set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("online");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        set_pin ("local", PinState.PinState.ALWAYS_LOCAL);
        set_pin ("online", Vfs.ItemAvailability.ONLINE_ONLY);

        fake_folder.local_modifier.insert ("local/file1");
        fake_folder.local_modifier.insert ("online/file1");
        GLib.assert_true (fake_folder.sync_once ());

        mark_for_dehydration (fake_folder, "local/file1");
        trigger_download (fake_folder, "online/file1");

        // the sync sets the changed files pin states to unspecified
        GLib.assert_true (fake_folder.sync_once ());

        xaverify_nonvirtual (fake_folder, "online/file1");
        xaverify_virtual (fake_folder, "local/file1");
        GLib.assert_true (vfs.pin_state ("online/file1") == PinState.PinState.UNSPECIFIED);
        GLib.assert_true (vfs.pin_state ("local/file1") == PinState.PinState.UNSPECIFIED);

        // no change on another sync
        GLib.assert_true (fake_folder.sync_once ());
        xaverify_nonvirtual (fake_folder, "online/file1");
        xaverify_virtual (fake_folder, "local/file1");
    }


    /***********************************************************
    ***********************************************************/
    private static void xaverify_virtual (FakeFolder folder, string path) {
        GLib.assert_true (new FileInfo (folder.local_path + (path)).exists ());
        GLib.assert_true (new FileInfo (folder.local_path + (path)).size () == 1);
        GLib.assert_true (xattr.has_nextcloud_placeholder_attributes ( folder.local_path + (path)));
        GLib.assert_true (database_record (folder, path).is_valid ());
        GLib.assert_true (database_record (folder, path).type == ItemType.VIRTUAL_FILE);
    }


    /***********************************************************
    ***********************************************************/
    private static void xaverify_nonvirtual (FakeFolder folder, string path) {
        GLib.assert_true (new FileInfo (folder.local_path + (path)).exists ());
        GLib.assert_true (!xattr.has_nextcloud_placeholder_attributes ( folder.local_path + (path)));
        GLib.assert_true (database_record (folder, path).is_valid ());
        GLib.assert_true (database_record (folder, path).type == ItemType.FILE);
    }


    /***********************************************************
    ***********************************************************/
    private static void cfverify_gone (FakeFolder folder, string path) {
        GLib.assert_true (!GLib.FileInfo (folder.local_path + (path)).exists ());
        GLib.assert_true (!database_record (folder, path).is_valid ());
    }

} // class TestIncompatiblePins

} // namespace Testing
} // namespace Occ
