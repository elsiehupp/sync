/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QNetworkAccessManager>
// #include <QFileInfo>
// #include <QDir>
// #include <cmath>
// #include <cstring>

namespace Occ {

void PropagateUploadFileV1.do_start_upload () {
    _chunk_count = int (std.ceil (_file_to_upload._size / double (chunk_size ())));
    _start_chunk = 0;
    Q_ASSERT (_item._modtime > 0);
    if (_item._modtime <= 0) {
        GLib.warn (lc_propagate_upload ()) << "invalid modified time" << _item._file << _item._modtime;
    }
    _transfer_id = uint32 (Utility.rand ()) ^ uint32 (_item._modtime) ^ (uint32 (_file_to_upload._size) << 16);

    const SyncJournalDb.UploadInfo progress_info = propagator ()._journal.get_upload_info (_item._file);

    Q_ASSERT (_item._modtime > 0);
    if (_item._modtime <= 0) {
        GLib.warn (lc_propagate_upload ()) << "invalid modified time" << _item._file << _item._modtime;
    }
    if (progress_info._valid && progress_info.is_chunked () && progress_info._modtime == _item._modtime && progress_info._size == _item._size
        && (progress_info._content_checksum == _item._checksum_header || progress_info._content_checksum.is_empty () || _item._checksum_header.is_empty ())) {
        _start_chunk = progress_info._chunk;
        _transfer_id = progress_info._transferid;
        q_c_info (lc_propagate_upload_v1) << _item._file << " : Resuming from chunk " << _start_chunk;
    } else if (_chunk_count <= 1 && !_item._checksum_header.is_empty ()) {
        // If there is only one chunk, write the checksum in the database, so if the PUT is sent
        // to the server, but the connection drops before we get the etag, we can check the checksum
        // in reconcile (issue #5106)
        SyncJournalDb.UploadInfo pi;
        pi._valid = true;
        pi._chunk = 0;
        pi._transferid = 0; // We set a null transfer id because it is not chunked.
        Q_ASSERT (_item._modtime > 0);
        if (_item._modtime <= 0) {
            GLib.warn (lc_propagate_upload ()) << "invalid modified time" << _item._file << _item._modtime;
        }
        pi._modtime = _item._modtime;
        pi._error_count = 0;
        pi._content_checksum = _item._checksum_header;
        pi._size = _item._size;
        propagator ()._journal.set_upload_info (_item._file, pi);
        propagator ()._journal.commit ("Upload info");
    }

    _current_chunk = 0;

    propagator ().report_progress (*_item, 0);
    on_start_next_chunk ();
}

void PropagateUploadFileV1.on_start_next_chunk () {
    if (propagator ()._abort_requested)
        return;

    if (!_jobs.is_empty () && _current_chunk + _start_chunk >= _chunk_count - 1) {
        // Don't do parallel upload of chunk if this might be the last chunk because the server cannot handle that
        // https://github.com/owncloud/core/issues/11106
        // We return now and when the _jobs are on_finished we will proceed with the last chunk
        // Note: Some other parts of the code such as on_upload_progress also assume that the last chunk
        // is sent last.
        return;
    }
    int64 file_size = _file_to_upload._size;
    var headers = PropagateUploadFileCommon.headers ();
    headers[QByteArrayLiteral ("OC-Total-Length")] = GLib.ByteArray.number (file_size);
    headers[QByteArrayLiteral ("OC-Chunk-Size")] = GLib.ByteArray.number (chunk_size ());

    string path = _file_to_upload._file;

    int64 chunk_start = 0;
    int64 current_chunk_size = file_size;
    bool is_final_chunk = false;
    if (_chunk_count > 1) {
        int sending_chunk = (_current_chunk + _start_chunk) % _chunk_count;
        // XOR with chunk size to make sure everything goes well if chunk size changes between runs
        uint32 transid = _transfer_id ^ uint32 (chunk_size ());
        q_c_info (lc_propagate_upload_v1) << "Upload chunk" << sending_chunk << "of" << _chunk_count << "transferid (remote)=" << transid;
        path += string ("-chunking-%1-%2-%3").arg (transid).arg (_chunk_count).arg (sending_chunk);

        headers[QByteArrayLiteral ("OC-Chunked")] = QByteArrayLiteral ("1");

        chunk_start = chunk_size () * sending_chunk;
        current_chunk_size = chunk_size ();
        if (sending_chunk == _chunk_count - 1) { // last chunk
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
    GLib.debug (lc_propagate_upload_v1) << _chunk_count << is_final_chunk << chunk_start << current_chunk_size;

    if (is_final_chunk && !_transmission_checksum_header.is_empty ()) {
        q_c_info (lc_propagate_upload_v1) << propagator ().full_remote_path (path) << _transmission_checksum_header;
        headers[check_sum_header_c] = _transmission_checksum_header;
    }

    const string file_name = _file_to_upload._path;
    var device = std.make_unique<UploadDevice> (
            file_name, chunk_start, current_chunk_size, &propagator ()._bandwidth_manager);
    if (!device.open (QIODevice.ReadOnly)) {
        GLib.warn (lc_propagate_upload_v1) << "Could not prepare upload device : " << device.error_string ();

        // If the file is currently locked, we want to retry the sync
        // when it becomes available again.
        if (FileSystem.is_file_locked (file_name)) {
            emit propagator ().seen_locked_file (file_name);
        }
        // Soft error because this is likely caused by the user modifying his files while syncing
        abort_with_error (SyncFileItem.SoftError, device.error_string ());
        return;
    }

    // job takes ownership of device via a QScopedPointer. Job deletes itself when finishing
    var device_ptr = device.get (); // for connections later
    var job = new PUTFile_job (propagator ().account (), propagator ().full_remote_path (path), std.move (device), headers, _current_chunk, this);
    _jobs.append (job);
    connect (job, &PUTFile_job.finished_signal, this, &PropagateUploadFileV1.on_put_finished);
    connect (job, &PUTFile_job.upload_progress, this, &PropagateUploadFileV1.on_upload_progress);
    connect (job, &PUTFile_job.upload_progress, device_ptr, &UploadDevice.on_job_upload_progress);
    connect (job, &GLib.Object.destroyed, this, &PropagateUploadFileCommon.on_job_destroyed);
    if (is_final_chunk)
        adjust_last_job_timeout (job, file_size);
    job.on_start ();
    propagator ()._active_job_list.append (this);
    _current_chunk++;

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

    if (_current_chunk + _start_chunk >= _chunk_count - 1) {
        // Don't do parallel upload of chunk if this might be the last chunk because the server cannot handle that
        // https://github.com/owncloud/core/issues/11106
        parallel_chunk_upload = false;
    }

    if (parallel_chunk_upload && (propagator ()._active_job_list.count () < propagator ().maximum_active_transfer_job ())
        && _current_chunk < _chunk_count) {
        on_start_next_chunk ();
    }
    if (!parallel_chunk_upload || _chunk_count - _current_chunk <= 0) {
        propagator ().schedule_next_job ();
    }
}

void PropagateUploadFileV1.on_put_finished () {
    var job = qobject_cast<PUTFile_job> (sender ());
    ASSERT (job);

    on_job_destroyed (job); // remove it from the _jobs list

    propagator ()._active_job_list.remove_one (this);

    if (_finished) {
        // We have sent the on_finished signal already. We don't need to handle any remaining jobs
        return;
    }

    _item._http_error_code = job.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    _item._response_time_stamp = job.response_timestamp ();
    _item._request_id = job.request_id ();
    QNetworkReply.NetworkError err = job.reply ().error ();
    if (err != QNetworkReply.NoError) {
        common_error_handling (job);
        return;
    }

    // The server needs some time to process the request and provide us with a poll URL
    if (_item._http_error_code == 202) {
        string path = string.from_utf8 (job.reply ().raw_header ("OC-Job_status-Location"));
        if (path.is_empty ()) {
            on_done (SyncFileItem.NormalError, _("Poll URL missing"));
            return;
        }
        _finished = true;
        start_poll_job (path);
        return;
    }

    // Check the file again post upload.
    // Two cases must be considered separately : If the upload is on_finished,
    // the file is on the server and has a changed ETag. In that case,
    // the etag has to be properly updated in the client journal, and because
    // of that we can bail out here with an error. But we can reschedule a
    // sync ASAP.
    // But if the upload is ongoing, because not all chunks were uploaded
    // yet, the upload can be stopped and an error can be displayed, because
    // the server hasn't registered the new file yet.
    GLib.ByteArray etag = get_etag_from_reply (job.reply ());
    _finished = etag.length () > 0;

    // Check if the file still exists
    const string full_file_path (propagator ().full_local_path (_item._file));
    if (!FileSystem.file_exists (full_file_path)) {
        if (!_finished) {
            abort_with_error (SyncFileItem.SoftError, _("The local file was removed during sync."));
            return;
        } else {
            propagator ()._another_sync_needed = true;
        }
    }

    // Check whether the file changed since discovery. the file check here is the original and not the temprary.
    Q_ASSERT (_item._modtime > 0);
    if (_item._modtime <= 0) {
        GLib.warn (lc_propagate_upload ()) << "invalid modified time" << _item._file << _item._modtime;
    }
    if (!FileSystem.verify_file_unchanged (full_file_path, _item._size, _item._modtime)) {
        propagator ()._another_sync_needed = true;
        if (!_finished) {
            abort_with_error (SyncFileItem.SoftError, _("Local file changed during sync."));
            // FIXME :  the legacy code was retrying for a few seconds.
            //         and also checking that after the last chunk, and removed the file in case of INSTRUCTION_NEW
            return;
        }
    }

    if (!_finished) {
        // Proceed to next chunk.
        if (_current_chunk >= _chunk_count) {
            if (!_jobs.empty ()) {
                // just wait for the other job to finish.
                return;
            }
            on_done (SyncFileItem.NormalError, _("The server did not acknowledge the last chunk. (No e-tag was present)"));
            return;
        }

        // Deletes an existing blocklist entry on successful chunk upload
        if (_item._has_blocklist_entry) {
            propagator ()._journal.wipe_error_blocklist_entry (_item._file);
            _item._has_blocklist_entry = false;
        }

        SyncJournalDb.UploadInfo pi;
        pi._valid = true;
        var current_chunk = job._chunk;
        foreach (var job, _jobs) {
            // Take the minimum on_finished one
            if (var put_job = qobject_cast<PUTFile_job> (job)) {
                current_chunk = q_min (current_chunk, put_job._chunk - 1);
            }
        }
        pi._chunk = (current_chunk + _start_chunk + 1) % _chunk_count; // next chunk to on_start with
        pi._transferid = _transfer_id;
        Q_ASSERT (_item._modtime > 0);
        if (_item._modtime <= 0) {
            GLib.warn (lc_propagate_upload ()) << "invalid modified time" << _item._file << _item._modtime;
        }
        pi._modtime = _item._modtime;
        pi._error_count = 0; // successful chunk upload resets
        pi._content_checksum = _item._checksum_header;
        pi._size = _item._size;
        propagator ()._journal.set_upload_info (_item._file, pi);
        propagator ()._journal.commit ("Upload info");
        on_start_next_chunk ();
        return;
    }
    // the following code only happens after all chunks were uploaded.

    // the file id should only be empty for new files up- or downloaded
    GLib.ByteArray fid = job.reply ().raw_header ("OC-FileID");
    if (!fid.is_empty ()) {
        if (!_item._file_id.is_empty () && _item._file_id != fid) {
            GLib.warn (lc_propagate_upload_v1) << "File ID changed!" << _item._file_id << fid;
        }
        _item._file_id = fid;
    }

    _item._etag = etag;

    if (job.reply ().raw_header ("X-OC-MTime") != "accepted") {
        // X-OC-MTime is supported since owncloud 5.0.   But not when chunking.
        // Normally Owncloud 6 always puts X-OC-MTime
        GLib.warn (lc_propagate_upload_v1) << "Server does not support X-OC-MTime" << job.reply ().raw_header ("X-OC-MTime");
        // Well, the mtime was not set
    }

    on_finalize ();
}

void PropagateUploadFileV1.on_upload_progress (int64 sent, int64 total) {
    // Completion is signaled with sent=0, total=0; avoid accidentally
    // resetting progress due to the sent being zero by ignoring it.
    // finished_signal () is bound to be emitted soon anyway.
    // See https://bugreports.qt.io/browse/QTBUG-44782.
    if (sent == 0 && total == 0) {
        return;
    }

    int progress_chunk = _current_chunk + _start_chunk - 1;
    if (progress_chunk >= _chunk_count)
        progress_chunk = _current_chunk - 1;

    // amount is the number of bytes already sent by all the other chunks that were sent
    // not including this one.
    // FIXME : this assumes all chunks have the same size, which is true only if the last chunk
    // has not been on_finished (which should not happen because the last chunk is sent sequentially)
    int64 amount = progress_chunk * chunk_size ();

    sender ().set_property ("byte_written", sent);
    if (_jobs.count () > 1) {
        amount -= (_jobs.count () - 1) * chunk_size ();
        foreach (GLib.Object j, _jobs) {
            amount += j.property ("byte_written").to_uLong_long ();
        }
    } else {
        // sender () is the only current job, no need to look at the byte_written properties
        amount += sent;
    }
    propagator ().report_progress (*_item, amount);
}

void PropagateUploadFileV1.on_abort (PropagatorJob.AbortType abort_type) {
    abort_network_jobs (
        abort_type,
        [this, abort_type] (AbstractNetworkJob job) {
            if (var put_job = qobject_cast<PUTFile_job> (job)){
                if (abort_type == AbortType.Asynchronous
                    && _chunk_count > 0
                    && ( ( (_current_chunk + _start_chunk) % _chunk_count) == 0)
                    && put_job.device ().at_end ()) {
                    return false;
                }
            }
            return true;
        });
}

}
