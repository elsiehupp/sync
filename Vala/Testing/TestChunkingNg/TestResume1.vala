/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestResume1 : AbstractTestChunkingNg {

//    /***********************************************************
//    Test resuming when there's a confusing chunk added
//    ***********************************************************/
//    private TestResume1 () {
//        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
//        fake_folder.sync_engine.account.set_capabilities ({ { "dav", new GLib.HashMap ({ "chunking", "1.0" }) } });
//        int size = 10 * 1000 * 1000; // 10 MB
//        set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);

//        partial_upload (fake_folder, "A/a0", size);
//        GLib.assert_true (fake_folder.upload_state ().children.length == 1);
//        var chunking_identifier = fake_folder.upload_state ().children.nth_data (0).name;
//        var chunk_map = fake_folder.upload_state ().children.nth_data (0).children;
//        int64 uploaded_size = 0LL;
//        foreach (FileInfo chunk in chunk_map) {
//            uploaded_size += chunk.size;
//        }
//        GLib.assert_true (uploaded_size > 2 * 1000 * 1000); // at least 2 MB

//        // Add a fake chunk to make sure it gets deleted
//        fake_folder.upload_state ().children.nth_data (0).insert ("10000", size);

//        fake_folder.set_server_override (this.override_delegate_resume1);

//        GLib.assert_true (fake_folder.sync_once ());

//        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
//        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size);
//        // The same chunk identifier was re-used
//        GLib.assert_true (fake_folder.upload_state ().children.length == 1);
//        GLib.assert_true (fake_folder.upload_state ().children.nth_data (0).name == chunking_identifier);
//    }


//    private GLib.InputStream override_delegate_resume1 (Soup.Operation operation, Soup.Request request, GLib.OutputStream device) {
//        if (operation == Soup.PutOperation) {
//            // Test that we properly resuming and are not sending past data again.
//            GLib.assert_true (request.raw_header ("OC-Chunk-Offset").to_int64 () >= uploaded_size);
//        } else if (operation == Soup.DeleteOperation) {
//            GLib.assert_true (request.url.path.has_suffix ("/10000"));
//        }
//        return null;
//    }

} // class TestResume1

} // namespace Testing
} // namespace Occ
