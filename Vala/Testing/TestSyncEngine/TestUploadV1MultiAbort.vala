/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestUploadV1MultiAbort : AbstractTestSyncEngine {

    /***********************************************************
    Aborting has had bugs when there are parallel upload jobs
    ***********************************************************/
    private TestUploadV1MultiAbort () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        SyncOptions options;
        options.initial_chunk_size = 10;
        options.max_chunk_size = 10;
        options.min_chunk_size = 10;
        fake_folder.sync_engine.set_sync_options (options);

        GLib.Object parent;
        int number_of_put = 0;
        fake_folder.set_server_override (this.override_delegate);

        fake_folder.local_modifier.insert ("file", 100, 'W');
        GLib.Timeout.single_shot (100, fake_folder.sync_engine, () => { fake_folder.sync_engine.on_signal_abort (); });
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (number_of_put == 3);
    }


    private Soup.Reply override_delegate (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.PutOperation) {
            ++number_of_put;
            return new FakeHangingReply (operation, request, parent);
        }
        return null;
    }

} // class TestUploadV1MultiAbort

} // namespace Testing
} // namespace Occ
