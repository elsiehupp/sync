namespace Occ {
namespace Testing {

/***********************************************************
@class TestDirectoryAndSubDirectory

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestDirectoryAndSubDirectory : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestDirectoryAndSubDirectory () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        fake_folder.local_modifier.mkdir ("A/new_directory");
        fake_folder.local_modifier.mkdir ("A/new_directory/sub_directory");
        fake_folder.local_modifier.insert ("A/new_directory/sub_directory/file", 10);

        var expected_state = fake_folder.current_local_state ();

        // Only "A" was modified according to the file system tracker
        fake_folder.sync_engine.set_local_discovery_options (
            LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A" });

        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state () == expected_state);
        GLib.assert_true (fake_folder.current_remote_state () == expected_state);
    }

} // class TestDirectoryAndSubDirectory

} // namespace Testing
} // namespace Occ
