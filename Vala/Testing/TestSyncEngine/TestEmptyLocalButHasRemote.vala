/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public abstract class TestEmptyLocalButHasRemote : AbstractTestSyncEngine {

    /***********************************************************
    ***********************************************************/
    private TestEmptyLocalButHasRemote () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        fake_folder.remote_modifier ().mkdir ("foo");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        GLib.assert_true (fake_folder.current_local_state ().find ("foo"));

    }

} // class TestEmptyLocalButHasRemote

} // namespace Testing
} // namespace Occ
