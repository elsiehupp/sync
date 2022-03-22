/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestRemoveStale2 : AbstractTestChunkingNg {

    /***********************************************************
    We remove the file locally after it has been partially
    uploaded
    ***********************************************************/
    private TestRemoveStale2 () {

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.account.set_capabilities ({ { "dav", new GLib.VariantMap ({"chunking", "1.0"}) } });
        int size = 10 * 1000 * 1000; // 10 MB
        set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);

        partial_upload (fake_folder, "A/a0", size);
        GLib.assert_true (fake_folder.upload_state ().children.count () == 1);

        fake_folder.local_modifier.remove ("A/a0");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.upload_state ().children.count () == 0);
    }

} // class TestRemoveStale2

} // namespace Testing
} // namespace Occ
