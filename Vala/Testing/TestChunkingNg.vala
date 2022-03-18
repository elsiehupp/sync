/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using Occ;

namespace Testing {

public class TestChunkingNg : GLib.Object {

    /***********************************************************
    Upload a 1/3 of a file of given size.
    fake_folder needs to be synchronized
    ***********************************************************/
    static void partial_upload (FakeFolder fake_folder, string name, int64 size) {
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


    // need to make sure size_when_abort gets passed back to caller
    private void on_signal_progress_delegate (ProgressInfo progress, int64 *size_when_abort) {
        if (progress.completed_size () > (progress.total_size () /3 )) {
            size_when_abort = progress.completed_size ();
            fake_folder.sync_engine.on_signal_abort ();
        }
    }

    // Reduce max chunk size a bit so we get more chunks
    static void set_chunk_size (SyncEngine engine, int64 size) {
        SyncOptions options;
        options.max_chunk_size = size;
        options.initial_chunk_size = size;
        options.min_chunk_size = size;
        engine.set_sync_options (options);
    }

    public class TestChunkingNG : GLib.Object {

        /***********************************************************
        ***********************************************************/
        private void test_file_upload () {
            FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
            fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ({ "chunking", "1.0" }) } });
            set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);
            int size = 10 * 1000 * 1000; // 10 MB

            fake_folder.local_modifier.insert ("A/a0", size);
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1); // the transfer was done with chunking
            GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size);

            // Check that another upload of the same file also work.
            fake_folder.local_modifier.append_byte ("A/a0");
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            GLib.assert_true (fake_folder.upload_state ().children.count () == 2); // the transfer was done with chunking
        }

        // Test resuming when there's a confusing chunk added
        private void test_resume1 () {
            FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
            fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ({ "chunking", "1.0" }) } });
            int size = 10 * 1000 * 1000; // 10 MB
            set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);

            partial_upload (fake_folder, "A/a0", size);
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
            var chunking_identifier = fake_folder.upload_state ().children.first ().name;
            var chunk_map = fake_folder.upload_state ().children.first ().children;
            int64 uploaded_size = 0LL;
            foreach (FileInfo chunk in chunk_map) {
                uploaded_size += chunk.size;
            }
            GLib.assert_true (uploaded_size > 2 * 1000 * 1000); // at least 2 MB

            // Add a fake chunk to make sure it gets deleted
            fake_folder.upload_state ().children.first ().insert ("10000", size);

            fake_folder.set_server_override (this.override_delegate_resume1);

            GLib.assert_true (fake_folder.sync_once ());

            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size);
            // The same chunk identifier was re-used
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
            GLib.assert_true (fake_folder.upload_state ().children.first ().name == chunking_identifier);
        }


        private Soup.Reply override_delegate_resume1 (Soup.Operation operation, Soup.Request request, QIODevice device) {
            if (operation == Soup.PutOperation) {
                // Test that we properly resuming and are not sending past data again.
                GLib.assert_true (request.raw_header ("OC-Chunk-Offset").to_int64 () >= uploaded_size);
            } else if (operation == Soup.DeleteOperation) {
                GLib.assert_true (request.url.path.ends_with ("/10000"));
            }
            return null;
        }


        // Test resuming when one of the uploaded chunks got removed
        private void test_resume2 () {
            FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
            fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ( {"chunking", "1.0"} ) } });
            set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);
            int size = 30 * 1000 * 1000; // 30 MB
            partial_upload (fake_folder, "A/a0", size);
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
            var chunking_identifier = fake_folder.upload_state ().children.first ().name;
            var chunk_map = fake_folder.upload_state ().children.first ().children;
            int64 uploaded_size = 0LL;
            foreach (FileInfo chunk in chunk_map) {
                uploaded_size += chunk.size;
            }
            GLib.assert_true (uploaded_size > 2 * 1000 * 1000); // at least 50 MB
            GLib.assert_true (chunk_map.size () >= 3); // at least three chunks

            string[] chunks_to_delete;

            // Remove the second chunk, so all further chunks will be deleted and resent
            var first_chunk = chunk_map.first ();
            var second_chunk = * (chunk_map.begin () + 1);
            foreach (var name in chunk_map.keys ().mid (2)) {
                chunks_to_delete.append (name);
            }
            fake_folder.upload_state ().children.first ().remove (second_chunk.name);

            string[] deleted_paths;
            fake_folder.set_server_override (this.override_delegate_resume2);

            GLib.assert_true (fake_folder.sync_once ());

            foreach (var to_delete in chunks_to_delete) {
                bool was_deleted = false;
                foreach (var deleted in deleted_paths) {
                    if (deleted.mid (deleted.last_index_of ('/') + 1) == to_delete) {
                        was_deleted = true;
                        break;
                    }
                }
                GLib.assert_true (was_deleted);
            }

            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size);
            // The same chunk identifier was re-used
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
            GLib.assert_true (fake_folder.upload_state ().children.first ().name == chunking_identifier);
        }


        private Soup.Reply override_delegate_resume2 (Soup.Operation operation, Soup.Request request, QIODevice device) {
            if (operation == Soup.PutOperation) {
                // Test that we properly resuming, not resending the first chunk
                GLib.assert_true (request.raw_header ("OC-Chunk-Offset").to_int64 () >= first_chunk.size);
            } else if (operation == Soup.DeleteOperation) {
                deleted_paths.append (request.url.path);
            }
            return null;
        }


        // Test resuming when all chunks are already present
        private void test_resume3 () {
            FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
            fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ({ "chunking", "1.0" }) } });
            int size = 30 * 1000 * 1000; // 30 MB
            set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);

            partial_upload (fake_folder, "A/a0", size);
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
            var chunking_identifier = fake_folder.upload_state ().children.first ().name;
            var chunk_map = fake_folder.upload_state ().children.first ().children;
            int64 uploaded_size = 0LL;
            foreach (FileInfo chunk in chunk_map) {
                uploaded_size += chunk.size;
            }
            GLib.assert_true (uploaded_size > 5 * 1000 * 1000); // at least 5 MB

            // Add a chunk that makes the file completely uploaded
            fake_folder.upload_state ().children.first ().insert (
                string.number (chunk_map.size ()).right_justified (16, '0'), size - uploaded_size);

            bool saw_put = false;
            bool saw_delete = false;
            bool saw_move = false;
            fake_folder.set_server_override (this.override_delegate_resume3);

            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (saw_move);
            GLib.assert_true (!saw_put);
            GLib.assert_true (!saw_delete);

            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size);
            // The same chunk identifier was re-used
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
            GLib.assert_true (fake_folder.upload_state ().children.first ().name == chunking_identifier);
        }

        // Test resuming (or rather not resuming!) for the error case of the sum of
        // chunk sizes being larger than the file size
        private void test_resume4 () {
            FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
            fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ({ "chunking", "1.0" }) } });
            int size = 30 * 1000 * 1000; // 30 MB
            set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);

            partial_upload (fake_folder, "A/a0", size);
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
            var chunking_identifier = fake_folder.upload_state ().children.first ().name;
            var chunk_map = fake_folder.upload_state ().children.first ().children;
            int64 uploaded_size = 0LL;
            foreach (FileInfo chunk in chunk_map) {
                uploaded_size += chunk.size;
            }
            GLib.assert_true (uploaded_size > 5 * 1000 * 1000); // at least 5 MB

            // Add a chunk that makes the file more than completely uploaded
            fake_folder.upload_state ().children.first ().insert (
                string.number (chunk_map.size ()).right_justified (16, '0'), size - uploaded_size + 100);

            GLib.assert_true (fake_folder.sync_once ());

            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size);
            // Used a new transfer identifier but wiped the old one
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
            GLib.assert_true (fake_folder.upload_state ().children.first ().name != chunking_identifier);
        }


        private Soup.Reply override_delegate_resume3 (Soup.Operation operation, Soup.Request request, QIODevice device) {
            if (operation == Soup.PutOperation) {
                saw_put = true;
            } else if (operation == Soup.DeleteOperation) {
                saw_delete = true;
            } else if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
                saw_move = true;
            }
            return null;
        }


        // Check what happens when we on_signal_abort during the final MOVE and the
        // the final MOVE takes longer than the on_signal_abort-delay
        private void test_late_abort_hard () {
            FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
            fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ( { "chunking", "1.0" } ) }, { "checksums", new QVariantMap ( { "supportedTypes", { "SHA1" } } ) } });
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
            GLib.assert_true (!move_checksum_header == "");
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


        // Now the next sync gets a NEW/NEW conflict and since there's no checksum
        // it just becomes a UPDATE_METADATA
        private void check_etag_updated (SyncFileItemVector items) {
            GLib.assert_true (items.size () == 1);
            GLib.assert_true (items[0].file == "A");
            SyncJournalFileRecord record;
            GLib.assert_true (fake_folder.sync_journal ().get_file_record ("A/a0", record));
            GLib.assert_true (record.etag == fake_folder.remote_modifier ().find ("A/a0").etag);
        }


        private Soup.Reply override_delegate_abort_hard (Soup.Operation operation, Soup.Request request, QIODevice device) {
            if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
                GLib.Timeout.single_shot (50, parent, () => { fake_folder.sync_engine.on_signal_abort (); });
                move_checksum_header = request.raw_header ("OC-Checksum");
                return new DelayedReply<FakeChunkMoveReply> (response_delay, fake_folder.upload_state (), fake_folder.remote_modifier (), operation, request, parent);
            } else if (operation == Soup.GetOperation) {
                n_get++;
            }
            return null;
        }


        // Check what happens when we on_signal_abort during the final MOVE and the
        // the final MOVE is short enough for the on_signal_abort-delay to help
        private void test_late_abort_recoverable () {
            FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
            fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ( { "chunking", "1.0" } ) }, { "checksums", new QVariantMap ( { "supportedTypes", { "SHA1" } } ) } });
            int size = 15 * 1000 * 1000; // 15 MB
            set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);

            // Make the MOVE never reply, but trigger a client-on_signal_abort and apply the change remotely
            GLib.Object parent;
            int response_delay = 200; // smaller than on_signal_abort-wait timeout
            fake_folder.set_server_override (this.override_delegate_abort_recoverable);

            // Test 1 : NEW file aborted
            fake_folder.local_modifier.insert ("A/a0", size);
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

            // Test 2 : modified file upload aborted
            fake_folder.local_modifier.append_byte ("A/a0");
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        }


        private Soup.Reply override_delegate_abort_recoverable (Soup.Operation operation, Soup.Request request, QIODevice device) {
            if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
                GLib.Timeout.single_shot (50, parent, () => { fake_folder.sync_engine.on_signal_abort (); });
                return new DelayedReply<FakeChunkMoveReply> (response_delay, fake_folder.upload_state (), fake_folder.remote_modifier (), operation, request, parent);
            }
            return null;
        }


        // We modify the file locally after it has been partially uploaded
        private void test_remove_stale1 () {

            FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
            fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ({ "chunking", "1.0" }) } });
            int size = 10 * 1000 * 1000; // 10 MB
            set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);

            partial_upload (fake_folder, "A/a0", size);
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
            var chunking_identifier = fake_folder.upload_state ().children.first ().name;

            fake_folder.local_modifier.set_contents ("A/a0", 'B');
            fake_folder.local_modifier.append_byte ("A/a0");

            GLib.assert_true (fake_folder.sync_once ());

            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size + 1);
            // A different chunk identifier was used, and the previous one is removed
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
            GLib.assert_true (fake_folder.upload_state ().children.first ().name != chunking_identifier);
        }

        // We remove the file locally after it has been partially uploaded
        private void test_remove_stale2 () {

            FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
            fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ({"chunking", "1.0"}) } });
            int size = 10 * 1000 * 1000; // 10 MB
            set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);

            partial_upload (fake_folder, "A/a0", size);
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1);

            fake_folder.local_modifier.remove ("A/a0");

            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (fake_folder.upload_state ().children.count () == 0);
        }


        /***********************************************************
        ***********************************************************/
        private void test_create_conflict_while_syncing () {
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


        /***********************************************************
        ***********************************************************/
        private void test_modify_local_file_while_uploading () {

            FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
            fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ({ "chunking", "1.0" }) } });
            int size = 10 * 1000 * 1000; // 10 MB
            set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);

            fake_folder.local_modifier.insert ("A/a0", size);

            // middle of the sync, modify the file
            QMetaObject.Connection con = connect (
                fake_folder.sync_engine,
                SyncEngine.signal_transmission_progress,
                this.on_signal_sync_engine_transmission_progress_modify_local_file_while_uploading
            );

            GLib.assert_true (!fake_folder.sync_once ());

            // There should be a followup sync
            GLib.assert_true (fake_folder.sync_engine.is_another_sync_needed () == ImmediateFollowUp);

            GLib.assert_true (fake_folder.upload_state ().children.count () == 1); // We did not clean the chunks at this point
            var chunking_identifier = fake_folder.upload_state ().children.first ().name;

            // Now we make a new sync which should upload the file for good.
            GLib.assert_true (fake_folder.sync_once ());

            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size + 1);

            // A different chunk identifier was used, and the previous one is removed
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
            GLib.assert_true (fake_folder.upload_state ().children.first ().name != chunking_identifier);
        }


        private void on_signal_sync_engine_transmission_progress_modify_local_file_while_uploading (ProgressInfo progress) {
            if (progress.completed_size () > (progress.total_size () / 2 )) {
                fake_folder.local_modifier.set_contents ("A/a0", 'B');
                fake_folder.local_modifier.append_byte ("A/a0");
                disconnect (con);
            }
        }


        /***********************************************************
        ***********************************************************/
        private void test_resume_server_deleted_chunks () {

            FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
            fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ({ "chunking", "1.0" }) } });
            int size = 30 * 1000 * 1000; // 30 MB
            set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);
            partial_upload (fake_folder, "A/a0", size);
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
            var chunking_identifier = fake_folder.upload_state ().children.first ().name;

            // Delete the chunks on the server
            fake_folder.upload_state ().children.clear ();
            GLib.assert_true (fake_folder.sync_once ());

            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size);

            // A different chunk identifier was used
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
            GLib.assert_true (fake_folder.upload_state ().children.first ().name != chunking_identifier);
        }

        // Check what happens when the connection is dropped on the PUT (non-chunking) or MOVE (chunking)
        // for on the issue #5106
        private void connection_dropped_before_etag_recieved_data () {
            QTest.add_column<bool> ("chunking");
            QTest.new_row ("big file") + true;
            QTest.new_row ("small file") + false;
        }


        /***********************************************************
        ***********************************************************/
        private void connection_dropped_before_etag_recieved () {
            QFETCH (bool, chunking);
            FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
            fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ( { "chunking", "1.0" } ) }, { "checksums", new QVariantMap ( { "supportedTypes", { "SHA1" } } ) } });
            int size = chunking ? 1 * 1000 * 1000 : 300;
            set_chunk_size (fake_folder.sync_engine, 300 * 1000);

            // Make the MOVE never reply, but trigger a client-on_signal_abort and apply the change remotely
            string checksum_header;
            int n_get = 0;
            QScopedValueRollback<int> set_http_timeout = new QScopedValueRollback<int> (AbstractNetworkJob.http_timeout, 1);
            int response_delay = AbstractNetworkJob.http_timeout * 1000 * 1000; // much bigger than http timeout (so a timeout will occur)
            // This will perform the operation on the server, but the reply will not come to the client
            fake_folder.set_server_override (this.override_delegate_connection_dropped);

            // Test 1 : a NEW file
            fake_folder.local_modifier.insert ("A/a0", size);
            GLib.assert_true (!fake_folder.sync_once ()); // timeout!
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ()); // but the upload succeeded
            GLib.assert_true (!checksum_header == "");
            fake_folder.remote_modifier ().find ("A/a0").checksums = checksum_header; // The test system don't do that automatically
            // Should be resolved properly
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (n_get == 0);
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

            // Test 2 : Modify the file further
            fake_folder.local_modifier.append_byte ("A/a0");
            GLib.assert_true (!fake_folder.sync_once ()); // timeout!
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ()); // but the upload succeeded
            fake_folder.remote_modifier ().find ("A/a0").checksums = checksum_header;
            // modify again, should not cause conflict
            fake_folder.local_modifier.append_byte ("A/a0");
            GLib.assert_true (!fake_folder.sync_once ()); // now it's trying to upload the modified file
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            fake_folder.remote_modifier ().find ("A/a0").checksums = checksum_header;
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (n_get == 0);
        }


        private Soup.Reply override_delegate_connection_dropped (Soup.Operation operation, Soup.Request request, QIODevice outgoing_data) {
            if (!chunking) {
                GLib.assert_true (!request.url.path.contains ("/uploads/")
                    && "Should not touch uploads endpoint when not chunking");
            }
            if (!chunking && operation == Soup.PutOperation) {
                checksum_header = request.raw_header ("OC-Checksum");
                return new DelayedReply<FakePutReply> (response_delay, fake_folder.remote_modifier (), operation, request, outgoing_data.read_all (), fake_folder.sync_engine);
            } else if (chunking && request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE") {
                checksum_header = request.raw_header ("OC-Checksum");
                return new DelayedReply<FakeChunkMoveReply> (response_delay, fake_folder.upload_state (), fake_folder.remote_modifier (), operation, request, fake_folder.sync_engine);
            } else if (operation == Soup.GetOperation) {
                n_get++;
            }
            return null;
        }


        /***********************************************************
        ***********************************************************/
        private void test_percent_encoding () {
            FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
            fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ({ "chunking", "1.0" }) } });
            int size = 5 * 1000 * 1000;
            set_chunk_size (fake_folder.sync_engine, 1 * 1000 * 1000);

            fake_folder.local_modifier.insert ("A/file % \u20ac", size);
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

            // Only the second upload contains an "If" header
            fake_folder.local_modifier.append_byte ("A/file % \u20ac");
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        }

        // Test uploading large files (2.5GiB)
        private void test_very_big_files () {
            FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
            fake_folder.sync_engine.account.set_capabilities ({ { "dav", new QVariantMap ({ "chunking", "1.0" }) } });
            int64 size = 2.5 * 1024 * 1024 * 1024; // 2.5 GiB

            // Partial upload of big files
            partial_upload (fake_folder, "A/a0", size);
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
            var chunking_identifier = fake_folder.upload_state ().children.first ().name;

            // Now resume
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size);

            // The same chunk identifier was re-used
            GLib.assert_true (fake_folder.upload_state ().children.count () == 1);
            GLib.assert_true (fake_folder.upload_state ().children.first ().name == chunking_identifier);

            // Upload another file again, this time without interruption
            fake_folder.local_modifier.append_byte ("A/a0");
            GLib.assert_true (fake_folder.sync_once ());
            GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
            GLib.assert_true (fake_folder.current_remote_state ().find ("A/a0").size == size + 1);
        }

    }

}
}
