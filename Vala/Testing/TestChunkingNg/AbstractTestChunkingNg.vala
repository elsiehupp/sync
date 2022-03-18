/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public abstract class AbstractTestChunkingNg : GLib.Object {

    /***********************************************************
    Upload a 1/3 of a file of given size.
    fake_folder needs to be synchronized
    ***********************************************************/
    protected static void partial_upload (FakeFolder fake_folder, string name, int64 size) {
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.upload_state ().children.count () == 0); // The state should be clean

        fake_folder.local_modifier.insert (name, size);
        // Abort when the upload is at 1/3
        int64 size_when_abort = -1;
        fake_folder.sync_engine.signal_transmission_progress.connect (
            this.on_signal_progress_delegate
        );

        GLib.assert_true (!fake_folder.sync_once ()); // there should have been an error
        fake_folder.sync_engine.signal_transmission_progress.disconnect (
            this.on_signal_progress_delegate
        );
        GLib.assert_true (size_when_abort > 0);
        GLib.assert_true (size_when_abort < size);

        GLib.assert_true (fake_folder.upload_state ().children.count () == 1); // the transfer was done with chunking
        var up_state_children = fake_folder.upload_state ().children.first ().children;

        int64 cumulative_size = 0;
        foreach (FileInfo child in up_state_children) {
            cumulative_size += child.size;
        }

        GLib.assert_true (size_when_abort == cumulative_size);
    }


    /***********************************************************
    Need to make sure size_when_abort gets passed back to caller!
    ***********************************************************/
    protected void on_signal_progress_delegate (ProgressInfo progress, int64 *size_when_abort) {
        if (progress.completed_size () > (progress.total_size () /3 )) {
            size_when_abort = progress.completed_size ();
            fake_folder.sync_engine.on_signal_abort ();
        }
    }


    /***********************************************************
    Reduce max chunk size a bit so we get more chunks
    ***********************************************************/
    protected static void set_chunk_size (SyncEngine engine, int64 size) {
        SyncOptions options;
        options.max_chunk_size = size;
        options.initial_chunk_size = size;
        options.min_chunk_size = size;
        engine.set_sync_options (options);
    }

} // class AbstractTestChunkingNg

} // namespace Testing
} // namespace Occ
