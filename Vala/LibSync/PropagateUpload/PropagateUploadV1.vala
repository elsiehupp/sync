/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QNetworkAccessManager>
//  #include <QFileInfo>
//  #include <QDir>
//  #include <cmath>
//  #include <cstring>

namespace Occ {

void PropagateUploadFileV1.do_start_upload () {
    this.chunk_count = int (std.ceil (this.file_to_upload.size / double (chunk_size ())));
    this.start_chunk = 0;
    //  Q_ASSERT (this.item.modtime > 0);
    if (this.item.modtime <= 0) {
        GLib.warn ("invalid modified time" + this.item.file + this.item.modtime;
    }
    this.transfer_id = uint32 (Utility.rand ()) ^ uint32 (this.item.modtime) ^ (uint32 (this.file_to_upload.size) << 16);

    const SyncJournalDb.UploadInfo progress_info = propagator ().journal.get_upload_info (this.item.file);

    //  Q_ASSERT (this.item.modtime > 0);
    if (this.item.modtime <= 0) {
        GLib.warn ("invalid modified time" + this.item.file + this.item.modtime;
    }
    if (progress_info.valid && progress_info.is_chunked () && progress_info.modtime == this.item.modtime && progress_info.size == this.item.size
        && (progress_info.content_checksum == this.item.checksum_header || progress_info.content_checksum.is_empty () || this.item.checksum_header.is_empty ())) {
        this.start_chunk = progress_info.chunk;
        this.transfer_id = progress_info.transferid;
        GLib.info () + this.item.file + " : Resuming from chunk " + this.start_chunk;
    } else if (this.chunk_count <= 1 && !this.item.checksum_header.is_empty ()) {
        // If there is only one chunk, write the checksum in the database, so if the PUT is sent
        // to the server, but the connection drops before we get the etag, we can check the checksum
        // in reconcile (issue #5106)
        SyncJournalDb.UploadInfo pi;
        pi.valid = true;
        pi.chunk = 0;
        pi.transferid = 0; // We set a null transfer identifier because it is not chunked.
        //  Q_ASSERT (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warn ("invalid modified time" + this.item.file + this.item.modtime;
        }
        pi.modtime = this.item.modtime;
        pi.error_count = 0;
        pi.content_checksum = this.item.checksum_header;
        pi.size = this.item.size;
        propagator ().journal.upload_info (this.item.file, pi);
        propagator ().journal.commit ("Upload info");
    }

    this.current_chunk = 0;

    propagator ().report_progress (*this.item, 0);
    on_signal_start_next_chunk ();
}

void PropagateUploadFileV1.on_signal_start_next_chunk () {
    if (propagator ().abort_requested)
        return;

    if (!this.jobs.is_empty () && this.current_chunk + this.start_chunk >= this.chunk_count - 1) {
        // Don't do parallel upload of chunk if this might be the last chunk because the server cannot handle that
        // https://github.com/owncloud/core/issues/11106
        // We return now and when the this.jobs are on_signal_finished we will proceed with the last chunk
        // Note: Some other parts of the code such as on_signal_upload_progress also assume that the last chunk
        // is sent last.
        return;
    }
    int64 file_size = this.file_to_upload.size;
    var headers = PropagateUploadFileCommon.headers ();
    headers[QByteArrayLiteral ("OC-Total-Length")] = GLib.ByteArray.number (file_size);
    headers[QByteArrayLiteral ("OC-Chunk-Size")] = GLib.ByteArray.number (chunk_size ());

    string path = this.file_to_upload.file;

    int64 chunk_start = 0;
    int64 current_chunk_size = file_size;
    bool is_final_chunk = false;
    if (this.chunk_count > 1) {
        int sending_chunk = (this.current_chunk + this.start_chunk) % this.chunk_count;
        // XOR with chunk size to make sure everything goes well if chunk size changes between runs
        uint32 transid = this.transfer_id ^ uint32 (chunk_size ());
        GLib.info ("Upload chunk" + sending_chunk + "of" + this.chunk_count + "transferid (remote)=" + transid;
        path += string ("-chunking-%1-%2-%3").arg (transid).arg (this.chunk_count).arg (sending_chunk);

        headers[QByteArrayLiteral ("OC-Chunked")] = QByteArrayLiteral ("1");

        chunk_start = chunk_size () * sending_chunk;
        current_chunk_size = chunk_size ();
        if (sending_chunk == this.chunk_count - 1) { // last chunk
            current_chunk_size = (file_size % chunk_size ());
            if (current_chunk_size == 0) { // if the last chunk pretends to be 0, its actually the full chunk size.
                current_chunk_size = chunk_size ();
            }
            is_final_chunk = true;
        }
    } else {
        // if there's only one chunk, it's the final one
        is_final_chunk = true;
    }
    GLib.debug (this.chunk_count + is_final_chunk + chunk_start + current_chunk_size;

    if (is_final_chunk && !this.transmission_checksum_header.is_empty ()) {
        GLib.info () + propagator ().full_remote_path (path) + this.transmission_checksum_header;
        headers[CHECK_SUM_HEADER_C] = this.transmission_checksum_header;
    }

    const string filename = this.file_to_upload.path;
    var device = std.make_unique<UploadDevice> (
            filename, chunk_start, current_chunk_size, propagator ().bandwidth_manager);
    if (!device.open (QIODevice.ReadOnly)) {
        GLib.warn ("Could not prepare upload device : " + device.error_string ();

        // If the file is currently locked, we want to retry the sync
        // when it becomes available again.
        if (FileSystem.is_file_locked (filename)) {
            /* emit */ propagator ().seen_locked_file (filename);
        }
        // Soft error because this is likely caused by the user modifying his files while syncing
        abort_with_error (SyncFileItem.Status.SOFT_ERROR, device.error_string ());
        return;
    }

    // job takes ownership of device via a QScopedPointer. Job deletes itself when finishing
    var device_ptr = device.get (); // for connections later
    var job = new PUTFile_job (propagator ().account (), propagator ().full_remote_path (path), std.move (device), headers, this.current_chunk, this);
    this.jobs.append (job);
    connect (job, &PUTFile_job.finished_signal, this, &PropagateUploadFileV1.on_signal_put_finished);
    connect (job, &PUTFile_job.upload_progress, this, &PropagateUploadFileV1.on_signal_upload_progress);
    connect (job, &PUTFile_job.upload_progress, device_ptr, &UploadDevice.on_signal_job_upload_progress);
    connect (job, &GLib.Object.destroyed, this, &PropagateUploadFileCommon.on_signal_job_destroyed);
    if (is_final_chunk)
        adjust_last_job_timeout (job, file_size);
    job.on_signal_start ();
    propagator ().active_job_list.append (this);
    this.current_chunk++;

    bool parallel_chunk_upload = true;

    if (propagator ().account ().capabilities ().chunking_parallel_upload_disabled ()) {
        // Server may also disable parallel chunked upload for any higher version
        parallel_chunk_upload = false;
    } else {
        GLib.ByteArray env = qgetenv ("OWNCLOUD_PARALLEL_CHUNK");
        if (!env.is_empty ()) {
            parallel_chunk_upload = env != "false" && env != "0";
        } else {
            int version_num = propagator ().account ().server_version_int ();
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

    if (parallel_chunk_upload && (propagator ().active_job_list.count () < propagator ().maximum_active_transfer_job ())
        && this.current_chunk < this.chunk_count) {
        on_signal_start_next_chunk ();
    }
    if (!parallel_chunk_upload || this.chunk_count - this.current_chunk <= 0) {
        propagator ().schedule_next_job ();
    }
}

void PropagateUploadFileV1.on_signal_put_finished () {
    var job = qobject_cast<PUTFile_job> (sender ());
    //  ASSERT (job);

    on_signal_job_destroyed (job); // remove it from the this.jobs list

    propagator ().active_job_list.remove_one (this);

    if (this.finished) {
        // We have sent the on_signal_finished signal already. We don't need to handle any remaining jobs
        return;
    }

    this.item.http_error_code = job.reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
    this.item.response_time_stamp = job.response_timestamp ();
    this.item.request_id = job.request_id ();
    Soup.Reply.NetworkError err = job.reply ().error ();
    if (err != Soup.Reply.NoError) {
        common_error_handling (job);
        return;
    }

    // The server needs some time to process the request and provide us with a poll URL
    if (this.item.http_error_code == 202) {
        string path = string.from_utf8 (job.reply ().raw_header ("OC-Job_status-Location"));
        if (path.is_empty ()) {
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
    GLib.ByteArray etag = get_etag_from_reply (job.reply ());
    this.finished = etag.length () > 0;

    // Check if the file still exists
    const string full_file_path (propagator ().full_local_path (this.item.file));
    if (!FileSystem.file_exists (full_file_path)) {
        if (!this.finished) {
            abort_with_error (SyncFileItem.Status.SOFT_ERROR, _("The local file was removed during sync."));
            return;
        } else {
            propagator ().another_sync_needed = true;
        }
    }

    // Check whether the file changed since discovery. the file check here is the original and not the temprary.
    //  Q_ASSERT (this.item.modtime > 0);
    if (this.item.modtime <= 0) {
        GLib.warn ("invalid modified time" + this.item.file + this.item.modtime;
    }
    if (!FileSystem.verify_file_unchanged (full_file_path, this.item.size, this.item.modtime)) {
        propagator ().another_sync_needed = true;
        if (!this.finished) {
            abort_with_error (SyncFileItem.Status.SOFT_ERROR, _("Local file changed during sync."));
            // FIXME :  the legacy code was retrying for a few seconds.
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
            propagator ().journal.wipe_error_blocklist_entry (this.item.file);
            this.item.has_blocklist_entry = false;
        }

        SyncJournalDb.UploadInfo pi;
        pi.valid = true;
        var current_chunk = job.chunk;
        foreach (var job in this.jobs) {
            // Take the minimum on_signal_finished one
            if (var put_job = qobject_cast<PUTFile_job> (job)) {
                current_chunk = q_min (current_chunk, put_job.chunk - 1);
            }
        }
        pi.chunk = (current_chunk + this.start_chunk + 1) % this.chunk_count; // next chunk to on_signal_start with
        pi.transferid = this.transfer_id;
        //  Q_ASSERT (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warn ("invalid modified time" + this.item.file + this.item.modtime;
        }
        pi.modtime = this.item.modtime;
        pi.error_count = 0; // successful chunk upload resets
        pi.content_checksum = this.item.checksum_header;
        pi.size = this.item.size;
        propagator ().journal.upload_info (this.item.file, pi);
        propagator ().journal.commit ("Upload info");
        on_signal_start_next_chunk ();
        return;
    }
    // the following code only happens after all chunks were uploaded.

    // the file identifier should only be empty for new files up- or downloaded
    GLib.ByteArray fid = job.reply ().raw_header ("OC-FileID");
    if (!fid.is_empty ()) {
        if (!this.item.file_id.is_empty () && this.item.file_id != fid) {
            GLib.warn ("File ID changed!" + this.item.file_id + fid;
        }
        this.item.file_id = fid;
    }

    this.item.etag = etag;

    if (job.reply ().raw_header ("X-OC-MTime") != "accepted") {
        // X-OC-MTime is supported since owncloud 5.0.   But not when chunking.
        // Normally Owncloud 6 always puts X-OC-MTime
        GLib.warn ("Server does not support X-OC-MTime" + job.reply ().raw_header ("X-OC-MTime");
        // Well, the mtime was not set
    }

    on_signal_finalize ();
}

void PropagateUploadFileV1.on_signal_upload_progress (int64 sent, int64 total) {
    // Completion is signaled with sent=0, total=0; avoid accidentally
    // resetting progress due to the sent being zero by ignoring it.
    // finished_signal () is bound to be emitted soon anyway.
    // See https://bugreports.qt.io/browse/QTBUG-44782.
    if (sent == 0 && total == 0) {
        return;
    }

    int progress_chunk = this.current_chunk + this.start_chunk - 1;
    if (progress_chunk >= this.chunk_count)
        progress_chunk = this.current_chunk - 1;

    // amount is the number of bytes already sent by all the other chunks that were sent
    // not including this one.
    // FIXME : this assumes all chunks have the same size, which is true only if the last chunk
    // has not been on_signal_finished (which should not happen because the last chunk is sent sequentially)
    int64 amount = progress_chunk * chunk_size ();

    sender ().property ("byte_written", sent);
    if (this.jobs.count () > 1) {
        amount -= (this.jobs.count () - 1) * chunk_size ();
        foreach (GLib.Object j in this.jobs) {
            amount += j.property ("byte_written").to_uLong_long ();
        }
    } else {
        // sender () is the only current job, no need to look at the byte_written properties
        amount += sent;
    }
    propagator ().report_progress (*this.item, amount);
}

void PropagateUploadFileV1.on_signal_abort (PropagatorJob.AbortType abort_type) {
    abort_network_jobs (
        abort_type,
        [this, abort_type] (AbstractNetworkJob job) {
            if (var put_job = qobject_cast<PUTFile_job> (job)) {
                if (abort_type == AbortType.ASYNCHRONOUS
                    && this.chunk_count > 0
                    && ( ( (this.current_chunk + this.start_chunk) % this.chunk_count) == 0)
                    && put_job.device ().at_end ()) {
                    return false;
                }
            }
            return true;
        });
}

}
