namespace Occ {
namespace Testing {

/***********************************************************
@class TestNewFilesNotVirtual

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestNewFilesNotVirtual : AbstractTestSyncVirtualFiles {

    /***********************************************************
    ***********************************************************/
    private TestNewFilesNotVirtual () {
        //  FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        //  set_up_vfs (fake_folder);
        //  GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        //  fake_folder.remote_modifier ().mkdir ("A");
        //  fake_folder.remote_modifier ().insert ("A/a1");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX));

        //  fake_folder.sync_journal ().internal_pin_states.set_for_path ("", PinState.ALWAYS_LOCAL);

        //  // Create a new remote file, it'll not be virtual
        //  fake_folder.remote_modifier ().insert ("A/a2");
        //  GLib.assert_true (fake_folder.sync_once ());
        //  GLib.assert_true (fake_folder.current_local_state ().find ("A/a2"));
        //  GLib.assert_true (!fake_folder.current_local_state ().find ("A/a2" + DVSUFFIX));
    }

} // class TestNewFilesNotVirtual

} // namespace Testing
} // namespace Occ
