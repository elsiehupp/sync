/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestRemoveStale1 : AbstractTestChunkingNg {

    /***********************************************************
    We modify the file locally after it has been partially
    uploaded
    ***********************************************************/
    private TestRemoveStale1 () {

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.account.set_capabilities ({ { "dav", new GLib.VariantMap ({ "chunking", "1.0" }) } });
        int size = 10 * 1000 * 1000; // 10 MB
        set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);

        partial_upload (fake_folder, "A/a0", size);
        GLib.assert_true (fake_folder.upload_state ().children.length == 1);
        var chunking_identifier = fake_folder.upload_state ().children.nth_data (0).name;

        fake_folder.local_modifier.set_contents ("A/a0", 'B');
        fake_folder.local_modifier.append_byte ("A/a0");

        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size + 1);
        // A different chunk identifier was used, and the previous one is removed
        GLib.assert_true (fake_folder.upload_state ().children.length == 1);
        GLib.assert_true (fake_folder.upload_state ().children.nth_data (0).name != chunking_identifier);
    }

} // class TestRemoveStale1

} // namespace Testing
} // namespace Occ
