/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

/***********************************************************
This test ensure that the SyncEngine.signal_about_to_remove_all_files
is correctly called and that when we the user choose to
remove all files SyncJournalDb.clear_file_table makes works
as expected
***********************************************************/
public abstract class AbstractTestAllFilesDeleted : GLib.Object {

    protected delegate void Callback (bool value);

    protected GLib.InputStream override_delegate (
        Soup.Operation operation,
        Soup.Request request,
        GLib.OutputStream stream
    ) {
        var verb = request.attribute (Soup.Request.CustomVerbAttribute);
        if (verb == "PROPFIND") {
            var data = stream.read_all ();
            if (data.contains ("data-fingerprint")) {
                if (request.url.path.has_suffix ("dav/files/admin/")) {
                    ++fingerprint_requests;
                } else {
                    fingerprint_requests = -10000; // fingerprint queried on incorrect path
                }
            }
        }
        return null;
    }


    protected static void change_all_file_id (FileInfo info) {
        info.file_identifier = generate_file_id ();
        if (!info.is_directory) {
            return;
        }
        info.etag = generate_etag ();
        foreach (var child in info.children) {
            change_all_file_id (child);
        }
    }

} // class TestAllFilesDeleted
} // namespace Testing
} // namespace Occ
