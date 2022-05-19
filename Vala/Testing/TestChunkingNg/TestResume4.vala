/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestResume4 : AbstractTestChunkingNg {

    /***********************************************************
    Test resuming (or rather not resuming!) for the error case
    of the sum of chunk sizes being larger than the file size.
    ***********************************************************/
    private TestResume4 () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.account.set_capabilities ({ { "dav", new GLib.HashMap ({ "chunking", "1.0" }) } });
        int size = 30 * 1000 * 1000; // 30 MB
        set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);

        partial_upload (fake_folder, "A/a0", size);
        GLib.assert_true (fake_folder.upload_state ().children.length == 1);
        var chunking_identifier = fake_folder.upload_state ().children.nth_data (0).name;
        var chunk_map = fake_folder.upload_state ().children.nth_data (0).children;
        int64 uploaded_size = 0LL;
        foreach (FileInfo chunk in chunk_map) {
            uploaded_size += chunk.size;
        }
        GLib.assert_true (uploaded_size > 5 * 1000 * 1000); // at least 5 MB

        // Add a chunk that makes the file more than completely uploaded
        fake_folder.upload_state ().children.nth_data (0).insert (
            string.number (chunk_map.size ()).right_justified (16, '0'), size - uploaded_size + 100);

        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size);
        // Used a new transfer identifier but wiped the old one
        GLib.assert_true (fake_folder.upload_state ().children.length == 1);
        GLib.assert_true (fake_folder.upload_state ().children.nth_data (0).name != chunking_identifier);
    }


    private GLib.InputStream override_delegate_resume3 (Soup.Operation operation, Soup.Request request, GLib.OutputStream device) {
        if (operation == Soup.PutOperation) {
            saw_put = true;
        } else if (operation == Soup.DeleteOperation) {
            saw_delete = true;
        } else if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
            saw_move = true;
        }
        return null;
    }

} // class TestResume4

} // namespace Testing
} // namespace Occ
