/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestResume2 : AbstractTestChunkingNg {

    /***********************************************************
    Test resuming when one of the uploaded chunks got removed.
    ***********************************************************/
    private TestResume2 () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.account.set_capabilities ({ { "dav", new GLib.VariantMap ( {"chunking", "1.0"} ) } });
        set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);
        int size = 30 * 1000 * 1000; // 30 MB
        partial_upload (fake_folder, "A/a0", size);
        GLib.assert_true (fake_folder.upload_state ().children.length == 1);
        var chunking_identifier = fake_folder.upload_state ().children.first ().name;
        var chunk_map = fake_folder.upload_state ().children.first ().children;
        int64 uploaded_size = 0LL;
        foreach (FileInfo chunk in chunk_map) {
            uploaded_size += chunk.size;
        }
        GLib.assert_true (uploaded_size > 2 * 1000 * 1000); // at least 50 MB
        GLib.assert_true (chunk_map.size () >= 3); // at least three chunks

        GLib.List<string> chunks_to_delete;

        // Remove the second chunk, so all further chunks will be deleted and resent
        var first_chunk = chunk_map.first ();
        var second_chunk = * (chunk_map.begin () + 1);
        foreach (var name in chunk_map.keys ().mid (2)) {
            chunks_to_delete.append (name);
        }
        fake_folder.upload_state ().children.first ().remove (second_chunk.name);

        GLib.List<string> deleted_paths;
        fake_folder.set_server_override (this.override_delegate_resume2);

        GLib.assert_true (fake_folder.sync_once ());

        foreach (var to_delete in chunks_to_delete) {
            bool was_deleted = false;
            foreach (var deleted in deleted_paths) {
                if (deleted.mid (deleted.last_index_of ("/") + 1) == to_delete) {
                    was_deleted = true;
                    break;
                }
            }
            GLib.assert_true (was_deleted);
        }

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size);
        // The same chunk identifier was re-used
        GLib.assert_true (fake_folder.upload_state ().children.length == 1);
        GLib.assert_true (fake_folder.upload_state ().children.first ().name == chunking_identifier);
    }


    /***********************************************************
    ***********************************************************/
    private GLib.InputStream override_delegate_resume2 (Soup.Operation operation, Soup.Request request, GLib.OutputStream device) {
        if (operation == Soup.PutOperation) {
            // Test that we properly resuming, not resending the first chunk
            GLib.assert_true (request.raw_header ("OC-Chunk-Offset").to_int64 () >= first_chunk.size);
        } else if (operation == Soup.DeleteOperation) {
            deleted_paths.append (request.url.path);
        }
        return null;
    }

} // class TestResume2

} // namespace Testing
} // namespace Occ
