/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <Soup.Session>
//  #include <GLib.FileInfo>
//  #include <GLib.Dir>
//  #include <cmath>
//  #include <cstring>

namespace Occ {
namespace LibSync {

/***********************************************************
@ingroup libsync

Propagation job, impementing the new chunking agorithm

State machine:

    *---. do_start_upload ()
            Check the database : is there an entry?
            /
            no                yes
            /
        /                  PROPFIND
    start_new_upload () <-+        +----------------------------
        |               |        |
        MKCOL            + on_signal_propfind_finished_with_error ()     on_signal_propfind_finished ()
        |                                                       Is there stale files to remove?
    on_signal_mkcol_finished ()                                         |                      |
        |                                                       no                    yes
        |                                                       |                      |
        |                                                       |                  DeleteJob
        |                                                       |                      |
    +-----+<------------------------------------------------------+<---  on_signal_delete_job_finished ()
    |
    +---.  on_signal_start_next_chunk ()  ---on_signal_finished?  --+
                ^               |          |
                +---------------+          |
                                            |
    +----------------------------------------+
    |
    +. MOVE -----. move_job_finished () --. on_signal_finalize ()

***********************************************************/
public class PropagateUploadFileNG : PropagateUploadFileCommon {

    /***********************************************************
    Map chunk number with its size  from the PROPFIND on resume.
    (Only used from on_signal_propfind_iterate or 
    on_signal_propfind_finished because the LsColJob use
    signals to report data.)
    ***********************************************************/
    private struct ServerChunkInfo {
        int64 size;
        string original_name;
    }

    /***********************************************************
    Amount of data (bytes) that was already sent
    ***********************************************************/
    private int64 sent = 0;

    /***********************************************************
    Transfer identifier (part of the url)
    ***********************************************************/
    private uint32 transfer_identifier = 0;

    /***********************************************************
    Identifier of the next chunk that will be sent
    ***********************************************************/
    private int current_chunk = 0;

    /***********************************************************
    Current chunk size
    ***********************************************************/
    private int64 current_chunk_size = 0;

    /***********************************************************
    If not null, there was an error removing the job
    ***********************************************************/
    private bool remove_job_error = false;

    private GLib.HashTable<int64, ServerChunkInfo> server_chunks;


    /***********************************************************
    Return the URL of a chunk.
    If chunk == -1, returns the URL of the parent folder containing the chunks
    ***********************************************************/
    private GLib.Uri chunk_url (int chunk = -1) {
        string path = "remote.php/dav/uploads/"
            + propagator ().account.dav_user ()
            + "/" + this.transfer_identifier.to_string ();
        if (chunk >= 0) {
            // We need to do add leading 0 because the server orders the chunk alphabetically
            path += "/" + string.number (chunk).right_justified (16, '0'); // 1e16 is 10 petabyte
        }
        return Utility.concat_url_path (propagator ().account.url, path);
    }


    /***********************************************************
    ***********************************************************/
    public PropagateUploadFileNG (OwncloudPropagator propagator, SyncFileItem item) {
        base (propagator, item);
    }


    /***********************************************************
    ***********************************************************/
    public new void do_start_upload () {
        propagator ().active_job_list.append (this);

        const SyncJournalDb.UploadInfo progress_info = propagator ().journal.get_upload_info (this.item.file);
        GLib.assert (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warning ("Invalid modified time " + this.item.file + this.item.modtime);
        }
        if (progress_info.valid && progress_info.is_chunked () && progress_info.modtime == this.item.modtime
                && progress_info.size == this.item.size) {
            this.transfer_identifier = progress_info.transferid;
            var url = chunk_url ();
            var job = new LsColJob (propagator ().account, url, this);
            this.jobs.append (job);
            job.properties (GLib.List<string> ("resourcetype"
                                                + "getcontentlength"));
            connect (
                job,
                LsColJob.finished_without_error,
                this,
                PropagateUploadFileNG.on_signal_propfind_finished
            );
            connect (
                job,
                LsColJob.signal_finished_with_error,
                this,
                PropagateUploadFileNG.on_signal_propfind_finished_with_error
            );
            connect (
                job,
                GLib.Object.destroyed,
                this,
                PropagateUploadFileCommon.on_signal_job_destroyed
            );
            connect (
                job,
                LsColJob.signal_directory_listing_iterated,
                this,
                PropagateUploadFileNG.on_signal_propfind_iterate
            );
            job.start ();
            return;
        } else if (progress_info.valid && progress_info.is_chunked ()) {
            // The upload info is stale. remove the stale chunks on the server
            this.transfer_identifier = progress_info.transferid;
            // Fire and forget. Any error will be ignored.
            (new DeleteJob (propagator ().account, chunk_url (), this)).start ();
            // start_new_upload will reset the this.transfer_identifier and the UploadInfo in the database.
        }

        start_new_upload ();
    }


    /***********************************************************
    ***********************************************************/
    private void start_new_upload () {
        //  ASSERT (propagator ().active_job_list.count (this) == 1);
        GLib.assert (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warning ("Invalid modified time" + this.item.file + this.item.modtime);
        }
        this.transfer_identifier = uint32 (Utility.rand () ^ uint32 (this.item.modtime) ^ (uint32 (this.file_to_upload.size) << 16) ^ q_hash (this.file_to_upload.file));
        this.sent = 0;
        this.current_chunk = 0;

        propagator ().report_progress (*this.item, 0);

        SyncJournalDb.UploadInfo pi;
        pi.valid = true;
        pi.transferid = this.transfer_identifier;
        GLib.assert (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warning ("Invalid modified time " + this.item.file + this.item.modtime);
        }
        pi.modtime = this.item.modtime;
        pi.content_checksum = this.item.checksum_header;
        pi.size = this.item.size;
        propagator ().journal.upload_info (this.item.file, pi);
        propagator ().journal.commit ("Upload info");
        GLib.HashTable<string, string> headers;

        // But we should send the temporary (or something) one.
        headers["OC-Total-Length"] = new string.number (this.file_to_upload.size);
        var job = new MkColJob (propagator ().account, chunk_url (), headers, this);

        connect (job, MkColJob.signal_finished_with_error,
            this, PropagateUploadFileNG.on_signal_mkcol_finished);
        connect (job, MkColJob.finished_without_error,
            this, PropagateUploadFileNG.on_signal_mkcol_finished);
        connect (job, GLib.Object.destroyed, this, PropagateUploadFileCommon.on_signal_job_destroyed);
        job.start ();
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_start_next_chunk () {
        if (propagator ().abort_requested)
            return;

        int64 file_size = this.file_to_upload.size;
        //  ENFORCE (file_size >= this.sent, "Sent data exceeds file size");

        // prevent situation that chunk size is bigger then required one to send
        this.current_chunk_size = q_min (propagator ().chunk_size, file_size - this.sent);

        if (this.current_chunk_size == 0) {
            GLib.assert (this.jobs == ""); // There should be no running job anymore
            this.finished = true;

            // Finish with a MOVE
            // If we changed the file name, we must store the changed filename in the remote folder, not the original one.
            string destination = GLib.Dir.clean_path (propagator ().account.dav_url ().path ()
                + propagator ().full_remote_path (this.file_to_upload.file));
            var headers = PropagateUploadFileCommon.headers ();

            // "If-Match applies to the source, but we are interested in comparing the etag of the destination
            var if_match = headers.take ("If-Match");
            if (!if_match == "") {
                headers["If"] = "<" + GLib.Uri.to_percent_encoding (destination, "/") + "> ([" + if_match + "])";
            }
            if (!this.transmission_checksum_header == "") {
                GLib.info (destination + this.transmission_checksum_header);
                headers[CHECK_SUM_HEADER_C] = this.transmission_checksum_header;
            }
            headers["OC-Total-Length"] = new string.number (file_size);

            var job = new MoveJob (propagator ().account, Utility.concat_url_path (chunk_url (), "/.file"),
                destination, headers, this);
            this.jobs.append (job);
            connect (job, MoveJob.signal_finished, this, PropagateUploadFileNG.on_signal_move_job_finished);
            connect (job, GLib.Object.destroyed, this, PropagateUploadFileCommon.on_signal_job_destroyed);
            propagator ().active_job_list.append (this);
            adjust_last_job_timeout (job, file_size);
            job.start ();
            return;
        }

        const string filename = this.file_to_upload.path;
        var device = std.make_unique<UploadDevice> (
                filename, this.sent, this.current_chunk_size, propagator ().bandwidth_manager);
        if (!device.open (QIODevice.ReadOnly)) {
            GLib.warning ("Could not prepare upload device: " + device.error_string ());

            // Soft error because this is likely caused by the user modifying his files while syncing
            abort_with_error (SyncFileItem.Status.SOFT_ERROR, device.error_string ());
            return;
        }

        GLib.HashTable<string, string> headers;
        headers["OC-Chunk-Offset"] = new string.number (this.sent);

        this.sent += this.current_chunk_size;
        GLib.Uri url = chunk_url (this.current_chunk);

        // job takes ownership of device via a QScopedPointer. Job deletes itself when finishing
        var device_ptr = device; // for connections later
        var job = new PUTFileJob (propagator ().account, url, std.move (device), headers, this.current_chunk, this);
        this.jobs.append (job);
        connect (job, PUTFileJob.signal_finished, this, PropagateUploadFileNG.on_signal_put_finished);
        connect (job, PUTFileJob.signal_upload_progress,
            this, PropagateUploadFileNG.on_signal_upload_progress);
        connect (job, PUTFileJob.signal_upload_progress,
            device_ptr, UploadDevice.on_signal_job_upload_progress);
        connect (job, GLib.Object.destroyed, this, PropagateUploadFileCommon.on_signal_job_destroyed);
        job.start ();
        propagator ().active_job_list.append (this);
        this.current_chunk++;
    }

    /***********************************************************
    ***********************************************************/
    public new void abort (PropagatorJob.AbortType abort_type) {
        abort_network_jobs (
            abort_type,
            PropagateUploadNg.abort_filter
        );
    }


    /***********************************************************
    ***********************************************************/
    private static bool abort_filter (PropagatorJob.AbortType abort_type, AbstractNetworkJob job) {
        return abort_type != PropagatorJob.AbortType.ASYNCHRONOUS || !(MoveJob) job;
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_propfind_finished () {
        var job = qobject_cast<LsColJob> (sender ());
        on_signal_job_destroyed (job); // remove it from the this.jobs list
        propagator ().active_job_list.remove_one (this);

        this.current_chunk = 0;
        this.sent = 0;
        while (this.server_chunks.contains (this.current_chunk)) {
            this.sent += this.server_chunks[this.current_chunk].size;
            this.server_chunks.remove (this.current_chunk);
            ++this.current_chunk;
        }

        if (this.sent > this.file_to_upload.size) {
            // Normally this can't happen because the size is xor'ed with the transfer identifier, and it is
            // therefore impossible that there is more data on the server than on the file.
            GLib.critical (
                "Inconsistency while resuming " + this.item.file
                + " : the size on the server (" + this.sent + ") is bigger than the size of the file ("
                + this.file_to_upload.size + ")"
            );

            // Wipe the old chunking data.
            // Fire and forget. Any error will be ignored.
            new DeleteJob (propagator ().account, chunk_url (), this).start ();

            propagator ().active_job_list.append (this);
            start_new_upload ();
            return;
        }

        GLib.info ("Resuming " + this.item.file + " from chunk " + this.current_chunk + "; sent =" + this.sent);

        if (!this.server_chunks == "") {
            GLib.info ("To Delete " + this.server_chunks.keys ());
            propagator ().active_job_list.append (this);
            this.remove_job_error = false;

            // Make sure that if there is a "hole" and then a few more chunks, on the server
            // we should remove the later chunks. Otherwise when we do dynamic chunk sizing, we may end up
            // with corruptions if there are too many chunks, or if we abort and there are still stale chunks.
            foreach (var server_chunk in q_as_const (this.server_chunks)) {
                var job = new DeleteJob (propagator ().account, Utility.concat_url_path (chunk_url (), server_chunk.original_name), this);
                GLib.Object.connect (job, DeleteJob.signal_finished, this, PropagateUploadFileNG.on_signal_delete_job_finished);
                this.jobs.append (job);
                job.start ();
            }
            this.server_chunks.clear ();
            return;
        }

        on_signal_start_next_chunk ();
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_propfind_finished_with_error () {
        var job = qobject_cast<LsColJob> (sender ());
        on_signal_job_destroyed (job); // remove it from the this.jobs list
        Soup.Reply.NetworkError err = job.reply ().error ();
        var http_error_code = job.reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        var status = classify_error (err, http_error_code, propagator ().another_sync_needed);
        if (status == SyncFileItem.Status.FATAL_ERROR) {
            this.item.request_id = job.request_id ();
            propagator ().active_job_list.remove_one (this);
            abort_with_error (status, job.error_string_parsing_body ());
            return;
        }
        start_new_upload ();
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_propfind_iterate (string name, GLib.HashTable<string, string> properties) {
        if (name == chunk_url ().path ()) {
            return; // skip the info about the path itself
        }
        bool ok = false;
        string chunk_name = name.mid (name.last_index_of ("/") + 1);
        var chunk_id = chunk_name.to_long_long (&ok);
        if (ok) {
            this.server_chunks[chunk_id] = ServerChunkInfo (
                properties["getcontentlength"].to_long_long (),
                chunk_name
            );
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_delete_job_finished () {
        var job = qobject_cast<DeleteJob> (sender ());
        //  ASSERT (job);
        this.jobs.remove (this.jobs.index_of (job));

        Soup.Reply.NetworkError err = job.reply ().error ();
        if (err != Soup.Reply.NoError && err != Soup.Reply.ContentNotFoundError) {
            const int http_status = job.reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
            SyncFileItem.Status status = classify_error (err, http_status);
            if (status == SyncFileItem.Status.FATAL_ERROR) {
                this.item.request_id = job.request_id ();
                abort_with_error (status, job.error_string ());
                return;
            } else {
                GLib.warning ("DeleteJob errored out " + job.error_string () + job.reply ().url);
                this.remove_job_error = true;
                // Let the other jobs finish
            }
        }

        if (this.jobs == "") {
            propagator ().active_job_list.remove_one (this);
            if (this.remove_job_error) {
                // There was an error removing some files, just start over
                start_new_upload ();
            } else {
                on_signal_start_next_chunk ();
            }
        }
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_mkcol_finished () {
        propagator ().active_job_list.remove_one (this);
        var job = qobject_cast<MkColJob> (sender ());
        on_signal_job_destroyed (job); // remove it from the this.jobs list
        Soup.Reply.NetworkError err = job.reply ().error ();
        this.item.http_error_code = job.reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();

        if (err != Soup.Reply.NoError || this.item.http_error_code != 201) {
            this.item.request_id = job.request_id ();
            SyncFileItem.Status status = classify_error (err, this.item.http_error_code,
                propagator ().another_sync_needed);
            abort_with_error (status, job.error_string_parsing_body ());
            return;
        }
        on_signal_start_next_chunk ();
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_put_finished () {
        var job = qobject_cast<PUTFileJob> (sender ());
        //  ASSERT (job);

        on_signal_job_destroyed (job); // remove it from the this.jobs list

        propagator ().active_job_list.remove_one (this);

        if (this.finished) {
            // We have sent the on_signal_finished signal already. We don't need to handle any remaining jobs
            return;
        }

        Soup.Reply.NetworkError err = job.reply ().error ();

        if (err != Soup.Reply.NoError) {
            this.item.http_error_code = job.reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
            this.item.request_id = job.request_id ();
            common_error_handling (job);
            return;
        }

        //  ENFORCE (this.sent <= this.file_to_upload.size, "can't send more than size");

        // Adjust the chunk size for the time taken.
        //
        // Dynamic chunk sizing is enabled if the server configured a
        // target duration for each chunk upload.
        var target_duration = propagator ().sync_options.target_chunk_upload_duration;
        if (target_duration.count () > 0) {
            var upload_time = ++job.ms_since_start (); // add one to avoid div-by-zero
            int64 predicted_good_size = (this.current_chunk_size * target_duration) / upload_time;

            // The whole targeting is heuristic. The predicted_good_size will fluctuate
            // quite a bit because of external factors (like available bandwidth)
            // and internal factors (like number of parallel uploads).
            //
            // We use an exponential moving average here as a cheap way of smoothing
            // the chunk sizes a bit.
            int64 target_size = propagator ().chunk_size / 2 + predicted_good_size / 2;

            // Adjust the dynamic chunk size this.chunk_size used for sizing of the item's chunks to be send
            propagator ().chunk_size = q_bound (
                propagator ().sync_options.min_chunk_size,
                target_size,
                propagator ().sync_options.max_chunk_size);

            GLib.info (
                "Chunked upload of " + this.current_chunk_size.to_string () + " bytes took " + upload_time.count ()
                + "ms, desired is " + target_duration.count () + "ms, expected good chunk size is "
                + predicted_good_size + " bytes and nudged next chunk size to "
                + propagator ().chunk_size + " bytes."
            );
        }

        this.finished = this.sent == this.item.size;

        // Check if the file still exists
        const string full_file_path = propagator ().full_local_path (this.item.file);
        if (!FileSystem.file_exists (full_file_path)) {
            if (!this.finished) {
                abort_with_error (SyncFileItem.Status.SOFT_ERROR, _("The local file was removed during sync."));
                return;
            } else {
                propagator ().another_sync_needed = true;
            }
        }

        // Check whether the file changed since discovery - this acts on the original file.
        GLib.assert (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warning ("Invalid modified time " + this.item.file + this.item.modtime);
        }
        if (!FileSystem.verify_file_unchanged (full_file_path, this.item.size, this.item.modtime)) {
            propagator ().another_sync_needed = true;
            if (!this.finished) {
                abort_with_error (SyncFileItem.Status.SOFT_ERROR, _("Local file changed during sync."));
                return;
            }
        }

        if (!this.finished) {
            // Deletes an existing blocklist entry on successful chunk upload
            if (this.item.has_blocklist_entry) {
                propagator ().journal.wipe_error_blocklist_entry (this.item.file);
                this.item.has_blocklist_entry = false;
            }

            // Reset the error count on successful chunk upload
            var upload_info = propagator ().journal.get_upload_info (this.item.file);
            upload_info.error_count = 0;
            propagator ().journal.upload_info (this.item.file, upload_info);
            propagator ().journal.commit ("Upload info");
        }
        on_signal_start_next_chunk ();
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_move_job_finished () {
        propagator ().active_job_list.remove_one (this);
        var job = qobject_cast<MoveJob> (sender ());
        on_signal_job_destroyed (job); // remove it from the this.jobs list
        Soup.Reply.NetworkError err = job.reply ().error ();
        this.item.http_error_code = job.reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        this.item.response_time_stamp = job.response_timestamp ();
        this.item.request_id = job.request_id ();

        if (err != Soup.Reply.NoError) {
            common_error_handling (job);
            return;
        }

        if (this.item.http_error_code == 202) {
            string path = string.from_utf8 (job.reply ().raw_header ("OC-Job_status-Location"));
            if (path == "") {
                on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("Poll URL missing"));
                return;
            }
            this.finished = true;
            start_poll_job (path);
            return;
        }

        if (this.item.http_error_code != 201 && this.item.http_error_code != 204) {
            abort_with_error (SyncFileItem.Status.NORMAL_ERROR, _("Unexpected return code from server (%1)").printf (this.item.http_error_code));
            return;
        }

        string fid = job.reply ().raw_header ("OC-FileID");
        if (fid == "") {
            GLib.warning ("Server did not return a OC-FileID " + this.item.file);
            abort_with_error (SyncFileItem.Status.NORMAL_ERROR, _("Missing File ID from server"));
            return;
        } else {
            // the old file identifier should only be empty for new files uploaded
            if (!this.item.file_id == "" && this.item.file_id != fid) {
                GLib.warning ("File ID changed! " + this.item.file_id.to_string () + fid);
            }
            this.item.file_id = fid;
        }

        this.item.etag = get_etag_from_reply (job.reply ());
        ;
        if (this.item.etag == "") {
            GLib.warning ("Server did not return an ETAG " + this.item.file);
            abort_with_error (SyncFileItem.Status.NORMAL_ERROR, _("Missing ETag from server"));
            return;
        }
        on_signal_finalize ();
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_upload_progress (int64 sent, int64 total) {
        // Completion is signaled with sent=0, total=0; avoid accidentally
        // resetting progress due to the sent being zero by ignoring it.
        // signal_finished () is bound to be emitted soon anyway.
        // See https://bugreports.qt.io/browse/QTBUG-44782.
        if (sent == 0 && total == 0) {
            return;
        }
        propagator ().report_progress (*this.item, this.sent + sent - total);
    }

} // class PropagateUploadFileNG

} // namespace LibSync
} // namespace Occ
