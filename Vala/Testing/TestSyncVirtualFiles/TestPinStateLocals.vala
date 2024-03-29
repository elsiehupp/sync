namespace Occ {
namespace Testing {

/***********************************************************
@class TestPinStateLocals

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestPinStateLocals : AbstractTestSyncVirtualFiles {

    /***********************************************************
    ***********************************************************/
    private TestPinStateLocals () {
        //  FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        //  Common.AbstractVfs vfs = set_up_vfs (fake_folder);
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        //  fake_folder.remote_modifier ().mkdir ("local");
        //  fake_folder.remote_modifier ().mkdir ("online");
        //  fake_folder.remote_modifier ().mkdir ("unspec");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        //  TestSyncVirtualFiles.set_pin ("local", PinState.ALWAYS_LOCAL);
        //  TestSyncVirtualFiles.set_pin ("online", Common.ItemAvailability.ONLINE_ONLY);
        //  TestSyncVirtualFiles.set_pin ("unspec", PinState.UNSPECIFIED);

        //  fake_folder.local_modifier.insert ("file1");
        //  fake_folder.local_modifier.insert ("online/file1");
        //  fake_folder.local_modifier.insert ("online/file2");
        //  fake_folder.local_modifier.insert ("local/file1");
        //  fake_folder.local_modifier.insert ("unspec/file1");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        //  // root is unspecified
        //  GLib.assert_true (vfs.pin_state ("file1" + DVSUFFIX) == PinState.UNSPECIFIED);
        //  GLib.assert_true (vfs.pin_state ("local/file1") == PinState.ALWAYS_LOCAL);
        //  GLib.assert_true (vfs.pin_state ("online/file1") == PinState.UNSPECIFIED);
        //  GLib.assert_true (vfs.pin_state ("unspec/file1") == PinState.UNSPECIFIED);

        //  // Sync again : bad pin states of new local files usually take effect on second sync
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        //  // When a file in an online-only folder is renamed, it retains its pin
        //  fake_folder.local_modifier.rename ("online/file1", "online/file1rename");
        //  fake_folder.remote_modifier ().rename ("online/file2", "online/file2rename");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (vfs.pin_state ("online/file1rename") == PinState.UNSPECIFIED);
        //  GLib.assert_true (vfs.pin_state ("online/file2rename") == PinState.UNSPECIFIED);

        //  // When a folder is renamed, the pin states inside should be retained
        //  fake_folder.local_modifier.rename ("online", "onlinerenamed1");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (vfs.pin_state ("onlinerenamed1") == Common.ItemAvailability.ONLINE_ONLY);
        //  GLib.assert_true (vfs.pin_state ("onlinerenamed1/file1rename") == PinState.UNSPECIFIED);

        //  fake_folder.remote_modifier ().rename ("onlinerenamed1", "onlinerenamed2");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (vfs.pin_state ("onlinerenamed2") == Common.ItemAvailability.ONLINE_ONLY);
        //  GLib.assert_true (vfs.pin_state ("onlinerenamed2/file1rename") == PinState.UNSPECIFIED);

        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        //  // When a file is deleted and later a new file has the same name, the old pin
        //  // state isn't preserved.
        //  GLib.assert_true (vfs.pin_state ("onlinerenamed2/file1rename") == PinState.UNSPECIFIED);
        //  fake_folder.remote_modifier ().remove ("onlinerenamed2/file1rename");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (vfs.pin_state ("onlinerenamed2/file1rename") == Common.ItemAvailability.ONLINE_ONLY);
        //  fake_folder.remote_modifier ().insert ("onlinerenamed2/file1rename");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (vfs.pin_state ("onlinerenamed2/file1rename") == Common.ItemAvailability.ONLINE_ONLY);
        //  GLib.assert_true (vfs.pin_state ("onlinerenamed2/file1rename" + DVSUFFIX) == Common.ItemAvailability.ONLINE_ONLY);

        //  // When a file is hydrated or dehydrated due to pin state it retains its pin state
        //  GLib.assert_true (vfs.set_pin_state ("onlinerenamed2/file1rename" + DVSUFFIX, PinState.ALWAYS_LOCAL));
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state ().find ("onlinerenamed2/file1rename"));
        //  GLib.assert_true (vfs.pin_state ("onlinerenamed2/file1rename") == PinState.ALWAYS_LOCAL);

        //  GLib.assert_true (vfs.set_pin_state ("onlinerenamed2", PinState.UNSPECIFIED));
        //  GLib.assert_true (vfs.set_pin_state ("onlinerenamed2/file1rename", Common.ItemAvailability.ONLINE_ONLY));
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state ().find ("onlinerenamed2/file1rename" + DVSUFFIX));
        //  GLib.assert_true (vfs.pin_state ("onlinerenamed2/file1rename" + DVSUFFIX) == Common.ItemAvailability.ONLINE_ONLY);
    }

} // class TestPinStateLocals

} // namespace Testing
} // namespace Occ
