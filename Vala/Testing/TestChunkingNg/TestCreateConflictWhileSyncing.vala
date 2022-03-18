/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class AbstractTestChunkingNg {

    /***********************************************************
    ***********************************************************/
    private void TestCreateConflictWhileSyncing () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ({ "chunking", "1.0" }) } });
        int size = 10 * 1000 * 1000; // 10 MB
        set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);

        // Put a file on the server and download it.
        fake_folder.remote_modifier ().insert ("A/a0", size);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Modify the file localy and on_signal_start the upload
        fake_folder.local_modifier.set_contents ("A/a0", 'B');
        fake_folder.local_modifier.append_byte ("A/a0");

        // But in the middle of the sync, modify the file on the server
        QMetaObject.Connection con = connect (
            fake_folder.sync_engine,
            SyncEngine.signal_transmission_progress,
            this.on_signal_sync_engine_transmission_progress_create_conflict_while_syncing
        );

        GLib.assert_true (!fake_folder.sync_once ());
        // There was a precondition failed error, this means wen need to sync again
        GLib.assert_true (fake_folder.sync_engine.is_another_sync_needed () == ImmediateFollowUp);

        GLib.assert_true (fake_folder.upload_state ().children.count () == 1); // We did not clean the chunks at this point

        // Now we will download the server file and create a conflict
        GLib.assert_true (fake_folder.sync_once ());
        var local_state = fake_folder.current_local_state ();

        // A0 is the one from the server
        GLib.assert_true (local_state.find ("A/a0").size == size);
        GLib.assert_true (local_state.find ("A/a0").content_char == 'C');

        // There is a conflict file with our version
        var state_a_children = local_state.find ("A").children;
        FileInfo file_info;
        foreach (FileInfo child in state_a_children) {
            if (child.name.starts_with ("a0 (conflicted copy")) {
                file_info = child;
                break;
            }
        }
        GLib.assert_true (file_info != state_a_children.cend ());
        GLib.assert_true (file_info.content_char == 'B');
        GLib.assert_true (file_info.size == size + 1);

        // Remove the conflict file so the comparison works!
        fake_folder.local_modifier.remove ("A/" + it.name);

        GLib.assert_cassert_truemp (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        GLib.assert_true (fake_folder.upload_state ().children.count () == 0); // The last sync cleaned the chunks
    }


    private void on_signal_sync_engine_transmission_progress_create_conflict_while_syncing (ProgressInfo progress) {
        if (progress.completed_size () > (progress.total_size () / 2 )) {
            fake_folder.remote_modifier ().set_contents ("A/a0", 'C');
            disconnect (con);
        }
    }

} // class AbstractTestChunkingNg

} // namespace Testing
} // namespace Occ
