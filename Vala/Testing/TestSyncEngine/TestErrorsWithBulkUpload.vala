/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestErrorsWithBulkUpload : AbstractTestSyncEngine {

    /***********************************************************
    Checks whether subsequent large uploads are skipped after a
    507 error
    ***********************************************************/
    private TestErrorsWithBulkUpload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.account.set_capabilities ({ { "dav", new GLib.VariantMap ( { "bulkupload", "1.0" } ) } });

        // Disable parallel uploads
        LibSync.SyncOptions sync_options;
        sync_options.parallel_network_jobs = 0;
        fake_folder.sync_engine.set_sync_options (sync_options);

        int number_of_put = 0;
        int number_of_post = 0;
        fake_folder.set_server_override (this.override_delegate_with_bulk_upload);

        fake_folder.local_modifier.insert ("A/big", 1);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (number_of_put == 0);
        GLib.assert_true (number_of_post == 1);
        number_of_put = 0;
        number_of_post = 0;

        fake_folder.local_modifier.insert ("A/big1", 1); // ok
        fake_folder.local_modifier.insert ("A/big2", 1); // ko
        fake_folder.local_modifier.insert ("A/big3", 1); // ko
        fake_folder.local_modifier.insert ("A/big4", 1); // ko
        fake_folder.local_modifier.insert ("A/big5", 1); // ko
        fake_folder.local_modifier.insert ("A/big6", 1); // ok
        fake_folder.local_modifier.insert ("A/big7", 1); // ko
        fake_folder.local_modifier.insert ("A/big8", 1); // ok
        fake_folder.local_modifier.insert ("B/big8", 1); // ko

        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_true (number_of_put == 0);
        GLib.assert_true (number_of_post == 1);
        number_of_put = 0;
        number_of_post = 0;

        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_true (number_of_put == 6);
        GLib.assert_true (number_of_post == 0);
    }


    private GLib.InputStream override_delegate_with_bulk_upload (Soup.Operation operation, Soup.Request request, GLib.OutputStream outgoing_data) {
        var content_type = request.header (Soup.Request.ContentTypeHeader).to_string ();
        if (operation == Soup.PostOperation) {
            ++number_of_post;
            if (content_type.has_prefix ("multipart/related; boundary=")) {
                var json_reply_object = fake_folder.for_each_reply_part (outgoing_data, content_type, fake_folder_for_each_reply_part_delegate
                );
                if (json_reply_object.size ()) {
                    var json_reply = new GLib.JsonDocument ();
                    json_reply.set_object (json_reply_object);
                    return new FakeJsonErrorReply (operation, request, this, 200, json_reply);
                }
                return  null;
            }
        } else if (operation == Soup.PutOperation) {
            ++number_of_put;
            var filename = get_file_path_from_url (request.url);
            if (filename.has_suffix ("A/big2") ||
                    filename.has_suffix ("A/big3") ||
                    filename.has_suffix ("A/big4") ||
                    filename.has_suffix ("A/big5") ||
                    filename.has_suffix ("A/big7") ||
                    filename.has_suffix ("B/big8")) {
                return new FakeErrorReply (operation, request, this, 412);
            }
            return null;
        }
        return null;
    }


    private Json.Object fake_folder_for_each_reply_part_delegate (GLib.HashTable<string, string> all_headers) {
        var reply = new Json.Object ();
        var filename = all_headers["X-File-Path"];
        if (filename.has_suffix ("A/big2") ||
                filename.has_suffix ("A/big3") ||
                filename.has_suffix ("A/big4") ||
                filename.has_suffix ("A/big5") ||
                filename.has_suffix ("A/big7") ||
                filename.has_suffix ("B/big8")) {
            reply.insert ("error", true);
            reply.insert ("etag", {});
            return reply;
        } else {
            reply.insert ("error", false);
            reply.insert ("etag", {});
        }
        return reply;
    }

} // class TestErrorsWithBulkUpload

} // namespace Testing
} // namespace Occ
