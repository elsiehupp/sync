namespace Occ {
namespace Testing {

/***********************************************************
@class TestServerBlocklist

@brief Tests the behavior of invalid filename detection

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestServerBlocklist { //: GLib.Object {

    //  private TestServerBlocklist () {
    //      FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

    //      fake_folder.sync_engine.account.set_capabilities (
    //          { { "files", new GLib.HashMap ( { "blocklisted_files", new GLib.VariantList ( ".foo", "bar" ) } ) } });
    //      fake_folder.local_modifier.insert ("C/.foo");
    //      fake_folder.local_modifier.insert ("C/bar");
    //      fake_folder.local_modifier.insert ("C/moo");
    //      fake_folder.local_modifier.insert ("C/.moo");

    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_remote_state ().find ("C/moo"));
    //      GLib.assert_true (fake_folder.current_remote_state ().find ("C/.moo"));
    //      GLib.assert_true (!fake_folder.current_remote_state ().find ("C/.foo"));
    //      GLib.assert_true (!fake_folder.current_remote_state ().find ("C/bar"));
    //  }

} // class TestServerBlocklist

} // namespace Testing
} // namespace Occ
