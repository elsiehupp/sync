namespace Occ {
namespace LibSync {

/***********************************************************
@class PropagateUploadFileV1

@brief Propagation job impementing the old chunking agorithm

@author Olivier Goffart <ogoffart@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PropagateUploadFileV1 : PropagateUploadFileCommon {

    /***********************************************************
    That's the start chunk that was stored in the database for resuming.
    In the non-resuming case it is 0.
    If we are resuming, this is the first chunk we need to send
    ***********************************************************/
    private int start_chunk = 0;

    /***********************************************************
    This is the next chunk that we need to send. Starting from 0
    even if this.start_chunk != 0.  (In other words,
    this.start_chunk + this.current_chunk is really the number
    of the chunk we need to send next.) (In other words,
    this.current_chunk is the number of the chunk that we
    already sent or started sending.)
    ***********************************************************/
    private int current_chunk = 0;

    /***********************************************************
    Total number of chunks for this file
    ***********************************************************/
    private int chunk_count = 0;

    /***********************************************************
    Transfer identifier (part of the url)
    ***********************************************************/
    private uint32 transfer_identifier = 0;

    /***********************************************************
    Old chunking does not use dynamic chunking algorithm, and
    does not adjusts the chunk size respectively, thus this
    value should be used as the one classifing item to be
    chunked.
    ***********************************************************/
    int64 chunk_size {
        private get {
            return this.propagator.sync_options.initial_chunk_size;
        }
    }


    /***********************************************************
    ***********************************************************/
    public PropagateUploadFileV1 (OwncloudPropagator propagator, SyncFileItem item) {
        base (propagator, item);
    }


    /***********************************************************
    ***********************************************************/
    public new void do_start_upload () {
        this.chunk_count = (int) (std.ceil (this.file_to_upload.size / double (this.chunk_size)));
        this.start_chunk = 0;
        GLib.assert (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warning ("Invalid modified time " + this.item.file.to_string () + this.item.modtime.to_string ());
        }
        this.transfer_identifier = ((int32)Utility.rand ()) ^ ((uint32)this.item.modtime) ^ ((uint32)this.file_to_upload.size) << 16);

        Common.SyncJournalDb.UploadInfo progress_info = this.propagator.journal.get_upload_info (this.item.file);

        GLib.assert (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warning ("Invalid modified time " + this.item.file.to_string () + this.item.modtime.to_string ());
        }
        if (progress_info.valid && progress_info.is_chunked && progress_info.modtime == this.item.modtime && progress_info.size == this.item.size
            && (progress_info.content_checksum == this.item.checksum_header || progress_info.content_checksum == "" || this.item.checksum_header == "")) {
            this.start_chunk = progress_info.chunk;
            this.transfer_identifier = progress_info.transferid;
            GLib.info (this.item.file.to_string () + ": Resuming from chunk " + this.start_chunk.to_string ());
        } else if (this.chunk_count <= 1 && !this.item.checksum_header == "") {
            // If there is only one chunk, write the checksum in the database, so if the PUT is sent
            // to the server, but the connection drops before we get the etag, we can check the checksum
            // in reconcile (issue #5106)
            Common.SyncJournalDb.UploadInfo upload_info;
            upload_info.valid = true;
            upload_info.chunk = 0;
            upload_info.transferid = 0; // We set a null transfer identifier because it is not chunked.
            GLib.assert (this.item.modtime > 0);
            if (this.item.modtime <= 0) {
                GLib.warning ("Invalid modified time " + this.item.file.to_string () + this.item.modtime.to_string ());
            }
            upload_info.modtime = this.item.modtime;
            upload_info.error_count = 0;
            upload_info.content_checksum = this.item.checksum_header;
            upload_info.size = this.item.size;
            this.propagator.journal.upload_info (this.item.file, upload_info);
            this.propagator.journal.commit ("Upload info");
        }

        this.current_chunk = 0;

        this.propagator.report_progress (*this.item, 0);
        on_signal_start_next_chunk ();
    }


    /***********************************************************
    ***********************************************************/
    public new void abort (AbstractPropagatorJob.AbortType abort_type) {
        abort_network_jobs (
            abort_type,
            PropagateUploadFileV1.abort_filter
        );
    }


    private static bool abort_filter (AbstractPropagatorJob.AbortType abort_type, AbstractNetworkJob abstract_job) {
        var put_job = (PUTFileJob) abstract_job;
        if (put_job != null) {
            if (abort_type == AbstractPropagatorJob.AbortType.ASYNCHRONOUS
                && this.chunk_count > 0
                && ( ( (this.current_chunk + this.start_chunk) % this.chunk_count) == 0)
                && put_job.device.at_end ()) {
                return false;
            }
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_start_next_chunk () {
        if (this.propagator.abort_requested)
            return;

        if (!this.jobs == "" && this.current_chunk + this.start_chunk >= this.chunk_count - 1) {
            // Don't do parallel upload of chunk if this might be the last chunk because the server cannot handle that
            // https://github.com/owncloud/core/issues/11106
            // We return now and when the this.jobs are on_signal_finished we will proceed with the last chunk
            // Note: Some other parts of the code such as on_signal_put_file_job_upload_progress also assume that the last chunk
            // is sent last.
            return;
        }
        int64 file_size = this.file_to_upload.size;
        var headers = PropagateUploadFileCommon.headers ();
        headers["OC-Total-Length"] = new string.number (file_size);
        headers["OC-Chunk-Size"] = new string.number (this.chunk_size);

        string path = this.file_to_upload.file;

        int64 chunk_start = 0;
        int64 current_chunk_size = file_size;
        bool is_final_chunk = false;
        if (this.chunk_count > 1) {
            int sending_chunk = (this.current_chunk + this.start_chunk) % this.chunk_count;
            // XOR with chunk size to make sure everything goes well if chunk size changes between runs
            uint32 transid = this.transfer_identifier ^ (uint32)this.chunk_size;
            GLib.info ("Upload chunk" + sending_chunk.to_string () + "of" + this.chunk_count.to_string () + "transferid (remote)=" + transid);
            path += "-chunking-%1-%2-%3".printf (transid).printf (this.chunk_count).printf (sending_chunk);

            headers["OC-Chunked"] = "1";

            chunk_start = this.chunk_size * sending_chunk;
            current_chunk_size = this.chunk_size;
            if (sending_chunk == this.chunk_count - 1) { // last chunk
                current_chunk_size = (file_size % this.chunk_size);
                if (current_chunk_size == 0) { // if the last chunk pretends to be 0, its actually the full chunk size.
                    current_chunk_size = this.chunk_size;
                }
                is_final_chunk = true;
            }
        } else {
            // if there's only one chunk, it's the final one
            is_final_chunk = true;
        }
        GLib.debug (this.chunk_count.to_string () + is_final_chunk.to_string () + chunk_start.to_string () + current_chunk_size.to_string ());

        if (is_final_chunk && !this.transmission_checksum_header == "") {
            GLib.info (this.propagator.full_remote_path (path) + this.transmission_checksum_header);
            headers[CHECK_SUM_HEADER_C] = this.transmission_checksum_header;
        }

        UploadDevice device = new UploadDevice (
            this.file_to_upload.path,
            chunk_start,
            current_chunk_size,
            this.propagator.bandwidth_manager
        );
        if (!device.open (GLib.IODevice.ReadOnly)) {
            GLib.warning ("Could not prepare upload device: " + device.error_string);

            // Soft error because this is likely caused by the user modifying his files while syncing
            abort_with_error (SyncFileItem.Status.SOFT_ERROR, device.error_string);
            return;
        }

        // job takes ownership of device via a GLib.ScopedPointer. Job deletes itself when finishing
        var device_ptr = device; // for connections later
        var put_file_job = new PUTFileJob (this.propagator.account, this.propagator.full_remote_path (path), std.move (device), headers, this.current_chunk, this);
        this.jobs.append (put_file_job);
        put_file_job.signal_finished.connect (
            this.on_signal_put_job_finished
        );
        put_file_job.signal_upload_progress.connect (
            this.on_signal_put_file_job_upload_progress
        );
        put_file_job.signal_upload_progress.connect (
            device_ptr.on_signal_job_upload_progress
        );
        put_file_job.destroyed.connect (
            this.on_signal_job_destroyed
        );
        if (is_final_chunk) {
            adjust_last_job_timeout (put_file_job, file_size);
        }
        put_file_job.start ();
        this.propagator.active_job_list.append (this);
        this.current_chunk++;

        bool parallel_chunk_upload = true;

        if (this.propagator.account.capabilities.chunking_parallel_upload_disabled ()) {
            // Server may also disable parallel chunked upload for any higher version
            parallel_chunk_upload = false;
        } else {
            string env = qgetenv ("OWNCLOUD_PARALLEL_CHUNK");
            if (!env == "") {
                parallel_chunk_upload = env != "false" && env != "0";
            } else {
                int version_num = this.propagator.account.server_version_int;
                if (version_num < Account.make_server_version (8, 0, 3)) {
                    // Disable parallel chunk upload severs older than 8.0.3 to avoid too many
                    // internal sever errors (#2743, #2938)
                    parallel_chunk_upload = false;
                }
            }
        }

        if (this.current_chunk + this.start_chunk >= this.chunk_count - 1) {
            // Don't do parallel upload of chunk if this might be the last chunk because the server cannot handle that
            // https://github.com/owncloud/core/issues/11106
            parallel_chunk_upload = false;
        }

        if (parallel_chunk_upload && (this.propagator.active_job_list.length < this.propagator.maximum_active_transfer_job ())
            && this.current_chunk < this.chunk_count) {
            on_signal_start_next_chunk ();
        }
        if (!parallel_chunk_upload || this.chunk_count - this.current_chunk <= 0) {
            this.propagator.schedule_next_job ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_put_job_finished () {
        var put_file_job = (PUTFileJob)sender ();
        //  ASSERT (put_file_job);

        on_signal_job_destroyed (put_file_job); // remove it from the this.jobs list

        this.propagator.active_job_list.remove_one (this);

        if (this.finished) {
            // We have sent the on_signal_finished signal already. We don't need to handle any remaining jobs
            return;
        }

        this.item.http_error_code = put_file_job.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        this.item.response_time_stamp = put_file_job.response_timestamp;
        this.item.request_id = put_file_job.request_id ();
        GLib.InputStream.NetworkError err = put_file_job.input_stream.error;
        if (err != GLib.InputStream.NoError) {
            common_error_handling (put_file_job);
            return;
        }

        // The server needs some time to process the request and provide us with a poll URL
        if (this.item.http_error_code == 202) {
            string path = string.from_utf8 (put_file_job.input_stream.raw_header ("OC-Job_status-Location"));
            if (path == "") {
                on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("Poll URL missing"));
                return;
            }
            this.finished = true;
            start_poll_job (path);
            return;
        }

        // Check the file again post upload.
        // Two cases must be considered separately : If the upload is on_signal_finished,
        // the file is on the server and has a changed ETag. In that case,
        // the etag has to be properly updated in the client journal, and because
        // of that we can bail out here with an error. But we can reschedule a
        // sync ASAP.
        // But if the upload is ongoing, because not all chunks were uploaded
        // yet, the upload can be stopped and an error can be displayed, because
        // the server hasn't registered the new file yet.
        string etag = get_etag_from_reply (put_file_job.input_stream);
        this.finished = etag.length > 0;

        // Check if the file still exists
        string full_file_path = this.propagator.full_local_path (this.item.file);
        if (!FileSystem.file_exists (full_file_path)) {
            if (!this.finished) {
                abort_with_error (SyncFileItem.Status.SOFT_ERROR, _("The local file was removed during sync."));
                return;
            } else {
                this.propagator.another_sync_needed = true;
            }
        }

        // Check whether the file changed since discovery. the file check here is the original and not the temprary.
        GLib.assert (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warning ("Invalid modified time " + this.item.file.to_string () + this.item.modtime.to_string ());
        }
        if (!FileSystem.verify_file_unchanged (full_file_path, this.item.size, this.item.modtime)) {
            this.propagator.another_sync_needed = true;
            if (!this.finished) {
                abort_with_error (SyncFileItem.Status.SOFT_ERROR, _("Local file changed during sync."));
                // FIXME:  the legacy code was retrying for a few seconds.
                //         and also checking that after the last chunk, and removed the file in case of INSTRUCTION_NEW
                return;
            }
        }

        if (!this.finished) {
            // Proceed to next chunk.
            if (this.current_chunk >= this.chunk_count) {
                if (!this.jobs.empty ()) {
                    // just wait for the other job to finish.
                    return;
                }
                on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("The server did not acknowledge the last chunk. (No e-tag was present)"));
                return;
            }

            // Deletes an existing blocklist entry on successful chunk upload
            if (this.item.has_blocklist_entry) {
                this.propagator.journal.wipe_error_blocklist_entry (this.item.file);
                this.item.has_blocklist_entry = false;
            }

            Common.SyncJournalDb.UploadInfo upload_info;
            upload_info.valid = true;
            var current_chunk = put_file_job.chunk;
            foreach (var job in this.jobs) {
                // Take the minimum on_signal_finished one
                var put_job = (PUTFileJob) job;
                if (put_job != null) {
                    current_chunk = q_min (current_chunk, put_job.chunk - 1);
                }
            }
            upload_info.chunk = (current_chunk + this.start_chunk + 1) % this.chunk_count; // next chunk to start with
            upload_info.transferid = this.transfer_identifier;
            GLib.assert (this.item.modtime > 0);
            if (this.item.modtime <= 0) {
                GLib.warning ("Invalid modified time " + this.item.file.to_string () + this.item.modtime.to_string ());
            }
            upload_info.modtime = this.item.modtime;
            upload_info.error_count = 0; // successful chunk upload resets
            upload_info.content_checksum = this.item.checksum_header;
            upload_info.size = this.item.size;
            this.propagator.journal.upload_info (this.item.file, upload_info);
            this.propagator.journal.commit ("Upload info");
            on_signal_start_next_chunk ();
            return;
        }
        // the following code only happens after all chunks were uploaded.

        // the file identifier should only be empty for new files up- or downloaded
        string fid = put_file_job.input_stream.raw_header ("OC-FileID");
        if (!fid == "") {
            if (!this.item.file_id == "" && this.item.file_id != fid) {
                GLib.warning ("File ID changed! " + this.item.file_id.to_string () + fid.to_string ());
            }
            this.item.file_id = fid;
        }

        this.item.etag = etag;

        if (put_file_job.input_stream.raw_header ("X-OC-MTime") != "accepted") {
            // X-OC-MTime is supported since owncloud 5.0.   But not when chunking.
            // Normally Owncloud 6 always puts X-OC-MTime
            GLib.warning ("Server does not support X-OC-MTime " + put_file_job.input_stream.raw_header ("X-OC-MTime"));
            // Well, the mtime was not set
        }

        on_signal_finalize ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_put_file_job_upload_progress (int64 sent, int64 total) {
        // Completion is signaled with sent=0, total=0; avoid accidentally
        // resetting progress due to the sent being zero by ignoring it.
        // signal_finished () is bound to be emitted soon anyway.
        // See https://bugreports.qt.io/browse/GLib.TBUG-44782.
        if (sent == 0 && total == 0) {
            return;
        }

        int progress_chunk = this.current_chunk + this.start_chunk - 1;
        if (progress_chunk >= this.chunk_count)
            progress_chunk = this.current_chunk - 1;

        // amount is the number of bytes already sent by all the other chunks that were sent
        // not including this one.
        // FIXME: this assumes all chunks have the same size, which is true only if the last chunk
        // has not been on_signal_finished (which should not happen because the last chunk is sent sequentially)
        int64 amount = progress_chunk * this.chunk_size;

        sender ().property ("byte_written", sent);
        if (this.jobs.length > 1) {
            amount -= (this.jobs.length - 1) * this.chunk_size;
            foreach (GLib.Object j in this.jobs) {
                amount += j.property ("byte_written").to_uLong_long ();
            }
        } else {
            // sender () is the only current job, no need to look at the byte_written properties
            amount += sent;
        }
        this.propagator.report_progress (*this.item, amount);
    }

} // class PropagateUploadV1

} // namespace LibSync
} // namespace Occ
