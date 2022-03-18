/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestVeryBigFiles : AbstractTestChunkingNg {

    /***********************************************************
    Test uploading large files (2.5GiB)
    ***********************************************************/
    private void TestVeryBigFiles () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ({ "chunking", "1.0" }) } });
        int64 size = 2.5 * 1024 * 1024 * 1024; // 2.5 GiB

        // Partial upload of big files
        partial_upload (fake_folder, "A/a0", size);
        GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
        var chunking_identifier = fake_folder.upload_state ().children.first ().name;

        // Now resume
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size);

        // The same chunk identifier was re-used
        GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
        GLib.assert_true (fake_folder.upload_state ().children.first ().name == chunking_identifier);

        // Upload another file again, this time without interruption
        fake_folder.local_modifier.append_byte ("A/a0");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size + 1);
    }

} // class TestVeryBigFiles

} // namespace Testing
} // namespace Occ
