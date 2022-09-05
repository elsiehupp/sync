namespace Occ {
namespace Testing {

/***********************************************************
@class TestNewVirtuals

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestNewVirtuals : AbstractTestSyncXAttr {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestNewVirtuals () {
    //      FakeFolder fake_folder = new FakeFolder (new FileInfo ());
    //      set_up_vfs (fake_folder);
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

    //      fake_folder.remote_modifier ().mkdir ("local");
    //      fake_folder.remote_modifier ().mkdir ("online");
    //      fake_folder.remote_modifier ().mkdir ("unspec");
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

    //      set_pin ("local", PinState.ALWAYS_LOCAL);
    //      set_pin ("online", Common.ItemAvailability.ONLINE_ONLY);
    //      set_pin ("unspec", PinState.UNSPECIFIED);

    //      // Test 1 : root is PinState.UNSPECIFIED
    //      fake_folder.remote_modifier ().insert ("file1");
    //      fake_folder.remote_modifier ().insert ("online/file1");
    //      fake_folder.remote_modifier ().insert ("local/file1");
    //      fake_folder.remote_modifier ().insert ("unspec/file1");
    //      GLib.assert_true (fake_folder.sync_once ());

    //      xaverify_virtual (fake_folder, "file1");
    //      xaverify_virtual (fake_folder, "online/file1");
    //      xaverify_nonvirtual (fake_folder, "local/file1");
    //      xaverify_virtual (fake_folder, "unspec/file1");

    //      // Test 2 : change root to PinState.ALWAYS_LOCAL
    //      set_pin ("", PinState.ALWAYS_LOCAL);

    //      fake_folder.remote_modifier ().insert ("file2");
    //      fake_folder.remote_modifier ().insert ("online/file2");
    //      fake_folder.remote_modifier ().insert ("local/file2");
    //      fake_folder.remote_modifier ().insert ("unspec/file2");
    //      GLib.assert_true (fake_folder.sync_once ());

    //      xaverify_nonvirtual (fake_folder, "file2");
    //      xaverify_virtual (fake_folder, "online/file2");
    //      xaverify_nonvirtual (fake_folder, "local/file2");
    //      xaverify_virtual (fake_folder, "unspec/file2");

    //      // root file1 was hydrated due to its new pin state
    //      xaverify_nonvirtual (fake_folder, "file1");

    //      // file1 is unchanged in the explicitly pinned subfolders
    //      xaverify_virtual (fake_folder, "online/file1");
    //      xaverify_nonvirtual (fake_folder, "local/file1");
    //      xaverify_virtual (fake_folder, "unspec/file1");

    //      // Test 3 : change root to Common.ItemAvailability.ONLINE_ONLY
    //      set_pin ("", Common.ItemAvailability.ONLINE_ONLY);

    //      fake_folder.remote_modifier ().insert ("file3");
    //      fake_folder.remote_modifier ().insert ("online/file3");
    //      fake_folder.remote_modifier ().insert ("local/file3");
    //      fake_folder.remote_modifier ().insert ("unspec/file3");
    //      GLib.assert_true (fake_folder.sync_once ());

    //      xaverify_virtual (fake_folder, "file3");
    //      xaverify_virtual (fake_folder, "online/file3");
    //      xaverify_nonvirtual (fake_folder, "local/file3");
    //      xaverify_virtual (fake_folder, "unspec/file3");

    //      // root file1 was dehydrated due to its new pin state
    //      xaverify_virtual (fake_folder, "file1");

    //      // file1 is unchanged in the explicitly pinned subfolders
    //      xaverify_virtual (fake_folder, "online/file1");
    //      xaverify_nonvirtual (fake_folder, "local/file1");
    //      xaverify_virtual (fake_folder, "unspec/file1");
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private static void set_pin (FakeFolder fake_folder, string path, PinState state) {
    //      fake_folder.sync_journal ().internal_pin_states.set_for_path (path, state);
    //  }

} // class TestNewVirtuals

} // namespace Testing
} // namespace Occ
