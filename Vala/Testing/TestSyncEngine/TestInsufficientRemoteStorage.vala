/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public abstract class TestInsufficientRemoteStorage : AbstractTestSyncEngine {

    /***********************************************************
    Checks whether subsequent large uploads are skipped after a
    507 error
    ***********************************************************/
    private TestInsufficientRemoteStorage () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        // Disable parallel uploads
        SyncOptions sync_options;
        sync_options.parallel_network_jobs = 0;
        fake_folder.sync_engine.set_sync_options (sync_options);

        // Produce an error based on upload size
        int remote_quota = 1000;
        int n507 = 0, number_of_put = 0;
        GLib.Object parent;
        fake_folder.set_server_override (this.override_delegate_insufficient_remote_storage);

        fake_folder.local_modifier.insert ("A/big", 800);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (number_of_put == 1);
        GLib.assert_true (n507 == 0);

        number_of_put = 0;
        fake_folder.local_modifier.insert ("A/big1", 500); // ok
        fake_folder.local_modifier.insert ("A/big2", 1200); // 507 (quota guess now 1199)
        fake_folder.local_modifier.insert ("A/big3", 1200); // skipped
        fake_folder.local_modifier.insert ("A/big4", 1500); // skipped
        fake_folder.local_modifier.insert ("A/big5", 1100); // 507 (quota guess now 1099)
        fake_folder.local_modifier.insert ("A/big6", 900); // ok (quota guess now 199)
        fake_folder.local_modifier.insert ("A/big7", 200); // skipped
        fake_folder.local_modifier.insert ("A/big8", 199); // ok (quota guess now 0)

        fake_folder.local_modifier.insert ("B/big8", 1150); // 507
        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_true (number_of_put == 6);
        GLib.assert_true (n507 == 3);
    }


    private Soup.Reply override_delegate_insufficient_remote_storage (Soup.Operation operation, Soup.Request request, QIODevice outgoing_data) {

        if (operation == Soup.PutOperation) {
            number_of_put++;
            if (request.raw_header ("OC-Total-Length").to_int () > remote_quota) {
                n507++;
                return new FakeErrorReply (operation, request, parent, 507);
            }
        }
        return null;
    }

} // class TestInsufficientRemoteStorage

} // namespace Testing
} // namespace Occ
