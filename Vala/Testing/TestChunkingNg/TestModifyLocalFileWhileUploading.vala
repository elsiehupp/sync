/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestModifyLocalFileWhileUploading : AbstractTestChunkingNg {

    /***********************************************************
    ***********************************************************/
    private TestModifyLocalFileWhileUploading () {

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.account.set_capabilities ({ { "dav", new GLib.VariantMap ({ "chunking", "1.0" }) } });
        int size = 10 * 1000 * 1000; // 10 MB
        set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);

        fake_folder.local_modifier.insert ("A/a0", size);

        // middle of the sync, modify the file
        GLib.Object.Connection con = connect (
            fake_folder.sync_engine,
            LibSync.SyncEngine.signal_transmission_progress,
            this.on_signal_sync_engine_transmission_progress_modify_local_file_while_uploading
        );

        GLib.assert_true (!fake_folder.sync_once ());

        // There should be a followup sync
        GLib.assert_true (fake_folder.sync_engine.is_another_sync_needed () == ImmediateFollowUp);

        GLib.assert_true (fake_folder.upload_state ().children.length == 1); // We did not clean the chunks at this point
        var chunking_identifier = fake_folder.upload_state ().children.nth_data (0).name;

        // Now we make a new sync which should upload the file for good.
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size + 1);

        // A different chunk identifier was used, and the previous one is removed
        GLib.assert_true (fake_folder.upload_state ().children.length == 1);
        GLib.assert_true (fake_folder.upload_state ().children.nth_data (0).name != chunking_identifier);
    }


    private void on_signal_sync_engine_transmission_progress_modify_local_file_while_uploading (ProgressInfo progress) {
        if (progress.completed_size () > (progress.total_size () / 2 )) {
            fake_folder.local_modifier.set_contents ("A/a0", 'B');
            fake_folder.local_modifier.append_byte ("A/a0");
            disconnect (con);
        }
    }

} // class TestModifyLocalFileWhileUploading

} // namespace Testing
} // namespace Occ
