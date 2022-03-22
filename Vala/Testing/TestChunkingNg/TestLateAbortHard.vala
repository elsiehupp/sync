/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestLateAbortHard : AbstractTestChunkingNg {

    /***********************************************************
    Check what happens when we abort during the final MOVE and
    the final MOVE takes longer than the abort-delay.
    ***********************************************************/
    private TestLateAbortHard () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine.account.set_capabilities ({ { "dav", new GLib.VariantMap ( { "chunking", "1.0" } ) }, { "checksums", new GLib.VariantMap ( { "supportedTypes", { "SHA1" } } ) } });
        int size = 15 * 1000 * 1000; // 15 MB
        set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);

        // Make the MOVE never reply, but trigger a client-on_signal_abort and apply the change remotely
        GLib.Object parent;
        string move_checksum_header;
        int n_get = 0;
        int response_delay = 100000; // bigger than on_signal_abort-wait timeout
        fake_folder.set_server_override (this.override_delegate_abort_hard);

        // Test 1 : NEW file aborted
        fake_folder.local_modifier.insert ("A/a0", size);
        GLib.assert_true (!fake_folder.sync_once ()); // error : on_signal_abort!

        var connection = connect (
            fake_folder.sync_engine,
            SyncEngine.signal_about_to_propagate,
            check_etag_updated
        );
        GLib.assert_true (fake_folder.sync_once ());
        disconnect (connection);
        GLib.assert_true (n_get == 0);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Test 2 : modified file upload aborted
        fake_folder.local_modifier.append_byte ("A/a0");
        GLib.assert_true (!fake_folder.sync_once ()); // error : on_signal_abort!

        // An EVAL/EVAL conflict is also UPDATE_METADATA when there's no checksums
        connection = connect (
            fake_folder.sync_engine, SyncEngine.signal_about_to_propagate,
            check_etag_updated
        );
        GLib.assert_true (fake_folder.sync_once ());
        disconnect (connection);
        GLib.assert_true (n_get == 0);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Test 3 : modified file upload aborted, with good checksums
        fake_folder.local_modifier.append_byte ("A/a0");
        GLib.assert_true (!fake_folder.sync_once ()); // error : on_signal_abort!

        // Set the remote checksum -- the test setup doesn't do it automatically
        GLib.assert_true (move_checksum_header != "");
        fake_folder.remote_modifier ().find ("A/a0").checksums = move_checksum_header;

        GLib.assert_true (fake_folder.sync_once ());
        disconnect (connection);
        GLib.assert_true (n_get == 0); // no new download, just a metadata update!
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Test 4 : New file, that gets deleted locally before the next sync
        fake_folder.local_modifier.insert ("A/a3", size);
        GLib.assert_true (!fake_folder.sync_once ()); // error : on_signal_abort!
        fake_folder.local_modifier.remove ("A/a3");

        // bug : in this case we must expect a re-download of A/A3
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (n_get == 1);
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a3"));
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    /***********************************************************
    Now the next sync gets a NEW/NEW conflict and since there's
    no checksum it just becomes a UPDATE_METADATA.
    ***********************************************************/
    private static void check_etag_updated (SyncFileItemVector items) {
        GLib.assert_true (items.size () == 1);
        GLib.assert_true (items[0].file == "A");
        SyncJournalFileRecord record;
        GLib.assert_true (fake_folder.sync_journal ().get_file_record ("A/a0", record));
        GLib.assert_true (record.etag == fake_folder.remote_modifier ().find ("A/a0").etag);
    }


    private GLib.InputStream override_delegate_abort_hard (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
            GLib.Timeout.single_shot (50, parent, () => { fake_folder.sync_engine.on_signal_abort (); });
            move_checksum_header = request.raw_header ("OC-Checksum");
            return new DelayedReply<FakeChunkMoveReply> (response_delay, fake_folder.upload_state (), fake_folder.remote_modifier (), operation, request, parent);
        } else if (operation == Soup.GetOperation) {
            n_get++;
        }
        return null;
    }

} // class TestLateAbortHard

} // namespace Testing
} // namespace Occ
