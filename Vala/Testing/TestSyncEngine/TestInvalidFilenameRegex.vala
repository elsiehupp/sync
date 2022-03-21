/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestInvalidFilenameRegex : AbstractTestSyncEngine {

    /***********************************************************
    Tests the behavior of invalid filename detection
    ***********************************************************/
    private TestInvalidFilenameRegex () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        // For current servers, no characters are forbidden
        fake_folder.sync_engine.account.set_server_version ("10.0.0");
        fake_folder.local_modifier.insert ("A/\\:?*\"<>|.txt");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // For legacy servers, some characters were forbidden by the client
        fake_folder.sync_engine.account.set_server_version ("8.0.0");
        fake_folder.local_modifier.insert ("B/\\:?*\"<>|.txt");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_remote_state ().find ("B/\\:?*\"<>|.txt"));

        // We can override that by setting the capability
        fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ( { "invalid_filename_regex", "" } ) } });
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Check that new servers also accept the capability
        fake_folder.sync_engine.account.set_server_version ("10.0.0");
        fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ( { "invalid_filename_regex", "my[fgh]ile" } ) } });
        fake_folder.local_modifier.insert ("C/myfile.txt");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_remote_state ().find ("C/myfile.txt"));
    }

} // class TestInvalidFilenameRegex

} // namespace Testing
} // namespace Occ
