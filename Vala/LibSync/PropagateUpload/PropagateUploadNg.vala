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

GLib.Uri PropagateUploadFileNG.chunk_url (int chunk) {
    string path = QLatin1String ("remote.php/dav/uploads/")
        + propagator ().account ().dav_user ()
        + '/' + string.number (this.transfer_id);
    if (chunk >= 0) {
        // We need to do add leading 0 because the server orders the chunk alphabetically
        path += '/' + string.number (chunk).right_justified (16, '0'); // 1e16 is 10 petabyte
    }
    return Utility.concat_url_path (propagator ().account ().url (), path);
}

/***********************************************************
  State machine:

     *---. do_start_upload ()
            Check the database : is there an entry?
              /
             no                yes
            /
           /                  PROPFIND
       start_new_upload () <-+        +----------------------------
          |               |        |
         MKCOL            + on_propfind_finished_with_error ()     on_propfind_finished ()
          |                                                       Is there stale files to remove?
      on_mk_col_finished ()                                         |                      |
          |                                                       no                    yes
          |                                                       |                      |
          |                                                       |                  DeleteJob
          |                                                       |                      |
    +-----+<------------------------------------------------------+<---  on_delete_job_finished ()
    |
    +---.  on_start_next_chunk ()  ---on_finished?  --+
                  ^               |          |
                  +---------------+          |
                                             |
    +----------------------------------------+
    |
    +. MOVE -----. move_job_finished () --. on_finalize ()

***********************************************************/

void PropagateUploadFileNG.do_start_upload () {
    propagator ()._active_job_list.append (this);

    const SyncJournalDb.UploadInfo progress_info = propagator ()._journal.get_upload_info (this.item._file);
    Q_ASSERT (this.item._modtime > 0);
    if (this.item._modtime <= 0) {
        GLib.warn (lc_propagate_upload ()) << "invalid modified time" << this.item._file << this.item._modtime;
    }
    if (progress_info._valid && progress_info.is_chunked () && progress_info._modtime == this.item._modtime
            && progress_info._size == this.item._size) {
        this.transfer_id = progress_info._transferid;
        var url = chunk_url ();
        var job = new LsColJob (propagator ().account (), url, this);
        this.jobs.append (job);
        job.set_properties (GLib.List<GLib.ByteArray> () << "resourcetype"
                                               << "getcontentlength");
        connect (job, &LsColJob.finished_without_error, this, &PropagateUploadFileNG.on_propfind_finished);
        connect (job, &LsColJob.finished_with_error,
            this, &PropagateUploadFileNG.on_propfind_finished_with_error);
        connect (job, &GLib.Object.destroyed, this, &PropagateUploadFileCommon.on_job_destroyed);
        connect (job, &LsColJob.directory_listing_iterated,
            this, &PropagateUploadFileNG.on_propfind_iterate);
        job.on_start ();
        return;
    } else if (progress_info._valid && progress_info.is_chunked ()) {
        // The upload info is stale. remove the stale chunks on the server
        this.transfer_id = progress_info._transferid;
        // Fire and forget. Any error will be ignored.
        (new DeleteJob (propagator ().account (), chunk_url (), this)).on_start ();
        // start_new_upload will reset the this.transfer_id and the UploadInfo in the database.
    }

    start_new_upload ();
}

void PropagateUploadFileNG.on_propfind_iterate (string name, QMap<string, string> properties) {
    if (name == chunk_url ().path ()) {
        return; // skip the info about the path itself
    }
    bool ok = false;
    string chunk_name = name.mid (name.last_index_of ('/') + 1);
    var chunk_id = chunk_name.to_long_long (&ok);
    if (ok) {
        Server_chunk_info chunkinfo = {
            properties["getcontentlength"].to_long_long (),
            chunk_name
        };
        this.server_chunks[chunk_id] = chunkinfo;
    }
}

void PropagateUploadFileNG.on_propfind_finished () {
    var job = qobject_cast<LsColJob> (sender ());
    on_job_destroyed (job); // remove it from the this.jobs list
    propagator ()._active_job_list.remove_one (this);

    this.current_chunk = 0;
    this.sent = 0;
    while (this.server_chunks.contains (this.current_chunk)) {
        this.sent += this.server_chunks[this.current_chunk].size;
        this.server_chunks.remove (this.current_chunk);
        ++this.current_chunk;
    }

    if (this.sent > this.file_to_upload._size) {
        // Normally this can't happen because the size is xor'ed with the transfer id, and it is
        // therefore impossible that there is more data on the server than on the file.
        q_c_critical (lc_propagate_upload_nG) << "Inconsistency while resuming " << this.item._file
                                      << " : the size on the server (" << this.sent << ") is bigger than the size of the file ("
                                      << this.file_to_upload._size << ")";

        // Wipe the old chunking data.
        // Fire and forget. Any error will be ignored.
        (new DeleteJob (propagator ().account (), chunk_url (), this)).on_start ();

        propagator ()._active_job_list.append (this);
        start_new_upload ();
        return;
    }

    q_c_info (lc_propagate_upload_nG) << "Resuming " << this.item._file << " from chunk " << this.current_chunk << "; sent =" << this.sent;

    if (!this.server_chunks.is_empty ()) {
        q_c_info (lc_propagate_upload_nG) << "To Delete" << this.server_chunks.keys ();
        propagator ()._active_job_list.append (this);
        this.remove_job_error = false;

        // Make sure that if there is a "hole" and then a few more chunks, on the server
        // we should remove the later chunks. Otherwise when we do dynamic chunk sizing, we may end up
        // with corruptions if there are too many chunks, or if we on_abort and there are still stale chunks.
        for (var server_chunk : q_as_const (this.server_chunks)) {
            var job = new DeleteJob (propagator ().account (), Utility.concat_url_path (chunk_url (), server_chunk.original_name), this);
            GLib.Object.connect (job, &DeleteJob.finished_signal, this, &PropagateUploadFileNG.on_delete_job_finished);
            this.jobs.append (job);
            job.on_start ();
        }
        this.server_chunks.clear ();
        return;
    }

    on_start_next_chunk ();
}

void PropagateUploadFileNG.on_propfind_finished_with_error () {
    var job = qobject_cast<LsColJob> (sender ());
    on_job_destroyed (job); // remove it from the this.jobs list
    QNetworkReply.NetworkError err = job.reply ().error ();
    var http_error_code = job.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    var status = classify_error (err, http_error_code, propagator ()._another_sync_needed);
    if (status == SyncFileItem.Status.FATAL_ERROR) {
        this.item._request_id = job.request_id ();
        propagator ()._active_job_list.remove_one (this);
        abort_with_error (status, job.error_string_parsing_body ());
        return;
    }
    start_new_upload ();
}

void PropagateUploadFileNG.on_delete_job_finished () {
    var job = qobject_cast<DeleteJob> (sender ());
    ASSERT (job);
    this.jobs.remove (this.jobs.index_of (job));

    QNetworkReply.NetworkError err = job.reply ().error ();
    if (err != QNetworkReply.NoError && err != QNetworkReply.ContentNotFoundError) {
        const int http_status = job.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
        SyncFileItem.Status status = classify_error (err, http_status);
        if (status == SyncFileItem.Status.FATAL_ERROR) {
            this.item._request_id = job.request_id ();
            abort_with_error (status, job.error_string ());
            return;
        } else {
            GLib.warn (lc_propagate_upload_nG) << "DeleteJob errored out" << job.error_string () << job.reply ().url ();
            this.remove_job_error = true;
            // Let the other jobs finish
        }
    }

    if (this.jobs.is_empty ()) {
        propagator ()._active_job_list.remove_one (this);
        if (this.remove_job_error) {
            // There was an error removing some files, just on_start over
            start_new_upload ();
        } else {
            on_start_next_chunk ();
        }
    }
}

void PropagateUploadFileNG.start_new_upload () {
    ASSERT (propagator ()._active_job_list.count (this) == 1);
    Q_ASSERT (this.item._modtime > 0);
    if (this.item._modtime <= 0) {
        GLib.warn (lc_propagate_upload ()) << "invalid modified time" << this.item._file << this.item._modtime;
    }
    this.transfer_id = uint32 (Utility.rand () ^ uint32 (this.item._modtime) ^ (uint32 (this.file_to_upload._size) << 16) ^ q_hash (this.file_to_upload._file));
    this.sent = 0;
    this.current_chunk = 0;

    propagator ().report_progress (*this.item, 0);

    SyncJournalDb.UploadInfo pi;
    pi._valid = true;
    pi._transferid = this.transfer_id;
    Q_ASSERT (this.item._modtime > 0);
    if (this.item._modtime <= 0) {
        GLib.warn (lc_propagate_upload ()) << "invalid modified time" << this.item._file << this.item._modtime;
    }
    pi._modtime = this.item._modtime;
    pi._content_checksum = this.item._checksum_header;
    pi._size = this.item._size;
    propagator ()._journal.set_upload_info (this.item._file, pi);
    propagator ()._journal.commit ("Upload info");
    QMap<GLib.ByteArray, GLib.ByteArray> headers;

    // But we should send the temporary (or something) one.
    headers["OC-Total-Length"] = GLib.ByteArray.number (this.file_to_upload._size);
    var job = new MkColJob (propagator ().account (), chunk_url (), headers, this);

    connect (job, &MkColJob.finished_with_error,
        this, &PropagateUploadFileNG.on_mk_col_finished);
    connect (job, &MkColJob.finished_without_error,
        this, &PropagateUploadFileNG.on_mk_col_finished);
    connect (job, &GLib.Object.destroyed, this, &PropagateUploadFileCommon.on_job_destroyed);
    job.on_start ();
}

void PropagateUploadFileNG.on_mk_col_finished () {
    propagator ()._active_job_list.remove_one (this);
    var job = qobject_cast<MkColJob> (sender ());
    on_job_destroyed (job); // remove it from the this.jobs list
    QNetworkReply.NetworkError err = job.reply ().error ();
    this.item._http_error_code = job.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();

    if (err != QNetworkReply.NoError || this.item._http_error_code != 201) {
        this.item._request_id = job.request_id ();
        SyncFileItem.Status status = classify_error (err, this.item._http_error_code,
            propagator ()._another_sync_needed);
        abort_with_error (status, job.error_string_parsing_body ());
        return;
    }
    on_start_next_chunk ();
}

void PropagateUploadFileNG.on_start_next_chunk () {
    if (propagator ()._abort_requested)
        return;

    int64 file_size = this.file_to_upload._size;
    ENFORCE (file_size >= this.sent, "Sent data exceeds file size");

    // prevent situation that chunk size is bigger then required one to send
    this.current_chunk_size = q_min (propagator ()._chunk_size, file_size - this.sent);

    if (this.current_chunk_size == 0) {
        Q_ASSERT (this.jobs.is_empty ()); // There should be no running job anymore
        this.finished = true;

        // Finish with a MOVE
        // If we changed the file name, we must store the changed filename in the remote folder, not the original one.
        string destination = QDir.clean_path (propagator ().account ().dav_url ().path ()
            + propagator ().full_remote_path (this.file_to_upload._file));
        var headers = PropagateUploadFileCommon.headers ();

        // "If-Match applies to the source, but we are interested in comparing the etag of the destination
        var if_match = headers.take (QByteArrayLiteral ("If-Match"));
        if (!if_match.is_empty ()) {
            headers[QByteArrayLiteral ("If")] = "<" + GLib.Uri.to_percent_encoding (destination, "/") + "> ([" + if_match + "])";
        }
        if (!this.transmission_checksum_header.is_empty ()) {
            q_c_info (lc_propagate_upload) << destination << this.transmission_checksum_header;
            headers[check_sum_header_c] = this.transmission_checksum_header;
        }
        headers[QByteArrayLiteral ("OC-Total-Length")] = GLib.ByteArray.number (file_size);

        var job = new Move_job (propagator ().account (), Utility.concat_url_path (chunk_url (), "/.file"),
            destination, headers, this);
        this.jobs.append (job);
        connect (job, &Move_job.finished_signal, this, &PropagateUploadFileNG.on_move_job_finished);
        connect (job, &GLib.Object.destroyed, this, &PropagateUploadFileCommon.on_job_destroyed);
        propagator ()._active_job_list.append (this);
        adjust_last_job_timeout (job, file_size);
        job.on_start ();
        return;
    }

    const string filename = this.file_to_upload._path;
    var device = std.make_unique<UploadDevice> (
            filename, this.sent, this.current_chunk_size, propagator ()._bandwidth_manager);
    if (!device.open (QIODevice.ReadOnly)) {
        GLib.warn (lc_propagate_upload_nG) << "Could not prepare upload device : " << device.error_string ();

        // If the file is currently locked, we want to retry the sync
        // when it becomes available again.
        if (FileSystem.is_file_locked (filename)) {
            /* emit */ propagator ().seen_locked_file (filename);
        }
        // Soft error because this is likely caused by the user modifying his files while syncing
        abort_with_error (SyncFileItem.Status.SOFT_ERROR, device.error_string ());
        return;
    }

    QMap<GLib.ByteArray, GLib.ByteArray> headers;
    headers["OC-Chunk-Offset"] = GLib.ByteArray.number (this.sent);

    this.sent += this.current_chunk_size;
    GLib.Uri url = chunk_url (this.current_chunk);

    // job takes ownership of device via a QScopedPointer. Job deletes itself when finishing
    var device_ptr = device.get (); // for connections later
    var job = new PUTFile_job (propagator ().account (), url, std.move (device), headers, this.current_chunk, this);
    this.jobs.append (job);
    connect (job, &PUTFile_job.finished_signal, this, &PropagateUploadFileNG.on_put_finished);
    connect (job, &PUTFile_job.upload_progress,
        this, &PropagateUploadFileNG.on_upload_progress);
    connect (job, &PUTFile_job.upload_progress,
        device_ptr, &UploadDevice.on_job_upload_progress);
    connect (job, &GLib.Object.destroyed, this, &PropagateUploadFileCommon.on_job_destroyed);
    job.on_start ();
    propagator ()._active_job_list.append (this);
    this.current_chunk++;
}

void PropagateUploadFileNG.on_put_finished () {
    var job = qobject_cast<PUTFile_job> (sender ());
    ASSERT (job);

    on_job_destroyed (job); // remove it from the this.jobs list

    propagator ()._active_job_list.remove_one (this);

    if (this.finished) {
        // We have sent the on_finished signal already. We don't need to handle any remaining jobs
        return;
    }

    QNetworkReply.NetworkError err = job.reply ().error ();

    if (err != QNetworkReply.NoError) {
        this.item._http_error_code = job.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
        this.item._request_id = job.request_id ();
        common_error_handling (job);
        return;
    }

    ENFORCE (this.sent <= this.file_to_upload._size, "can't send more than size");

    // Adjust the chunk size for the time taken.
    //
    // Dynamic chunk sizing is enabled if the server configured a
    // target duration for each chunk upload.
    var target_duration = propagator ().sync_options ()._target_chunk_upload_duration;
    if (target_duration.count () > 0) {
        var upload_time = ++job.ms_since_start (); // add one to avoid div-by-zero
        int64 predicted_good_size = (this.current_chunk_size * target_duration) / upload_time;

        // The whole targeting is heuristic. The predicted_good_size will fluctuate
        // quite a bit because of external factors (like available bandwidth)
        // and internal factors (like number of parallel uploads).
        //
        // We use an exponential moving average here as a cheap way of smoothing
        // the chunk sizes a bit.
        int64 target_size = propagator ()._chunk_size / 2 + predicted_good_size / 2;

        // Adjust the dynamic chunk size this.chunk_size used for sizing of the item's chunks to be send
        propagator ()._chunk_size = q_bound (
            propagator ().sync_options ()._min_chunk_size,
            target_size,
            propagator ().sync_options ()._max_chunk_size);

        q_c_info (lc_propagate_upload_nG) << "Chunked upload of" << this.current_chunk_size << "bytes took" << upload_time.count ()
                                  << "ms, desired is" << target_duration.count () << "ms, expected good chunk size is"
                                  << predicted_good_size << "bytes and nudged next chunk size to "
                                  << propagator ()._chunk_size << "bytes";
    }

    this.finished = this.sent == this.item._size;

    // Check if the file still exists
    const string full_file_path (propagator ().full_local_path (this.item._file));
    if (!FileSystem.file_exists (full_file_path)) {
        if (!this.finished) {
            abort_with_error (SyncFileItem.Status.SOFT_ERROR, _("The local file was removed during sync."));
            return;
        } else {
            propagator ()._another_sync_needed = true;
        }
    }

    // Check whether the file changed since discovery - this acts on the original file.
    Q_ASSERT (this.item._modtime > 0);
    if (this.item._modtime <= 0) {
        GLib.warn (lc_propagate_upload ()) << "invalid modified time" << this.item._file << this.item._modtime;
    }
    if (!FileSystem.verify_file_unchanged (full_file_path, this.item._size, this.item._modtime)) {
        propagator ()._another_sync_needed = true;
        if (!this.finished) {
            abort_with_error (SyncFileItem.Status.SOFT_ERROR, _("Local file changed during sync."));
            return;
        }
    }

    if (!this.finished) {
        // Deletes an existing blocklist entry on successful chunk upload
        if (this.item._has_blocklist_entry) {
            propagator ()._journal.wipe_error_blocklist_entry (this.item._file);
            this.item._has_blocklist_entry = false;
        }

        // Reset the error count on successful chunk upload
        var upload_info = propagator ()._journal.get_upload_info (this.item._file);
        upload_info._error_count = 0;
        propagator ()._journal.set_upload_info (this.item._file, upload_info);
        propagator ()._journal.commit ("Upload info");
    }
    on_start_next_chunk ();
}

void PropagateUploadFileNG.on_move_job_finished () {
    propagator ()._active_job_list.remove_one (this);
    var job = qobject_cast<Move_job> (sender ());
    on_job_destroyed (job); // remove it from the this.jobs list
    QNetworkReply.NetworkError err = job.reply ().error ();
    this.item._http_error_code = job.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    this.item._response_time_stamp = job.response_timestamp ();
    this.item._request_id = job.request_id ();

    if (err != QNetworkReply.NoError) {
        common_error_handling (job);
        return;
    }

    if (this.item._http_error_code == 202) {
        string path = string.from_utf8 (job.reply ().raw_header ("OC-Job_status-Location"));
        if (path.is_empty ()) {
            on_done (SyncFileItem.Status.NORMAL_ERROR, _("Poll URL missing"));
            return;
        }
        this.finished = true;
        start_poll_job (path);
        return;
    }

    if (this.item._http_error_code != 201 && this.item._http_error_code != 204) {
        abort_with_error (SyncFileItem.Status.NORMAL_ERROR, _("Unexpected return code from server (%1)").arg (this.item._http_error_code));
        return;
    }

    GLib.ByteArray fid = job.reply ().raw_header ("OC-FileID");
    if (fid.is_empty ()) {
        GLib.warn (lc_propagate_upload_nG) << "Server did not return a OC-FileID" << this.item._file;
        abort_with_error (SyncFileItem.Status.NORMAL_ERROR, _("Missing File ID from server"));
        return;
    } else {
        // the old file id should only be empty for new files uploaded
        if (!this.item._file_id.is_empty () && this.item._file_id != fid) {
            GLib.warn (lc_propagate_upload_nG) << "File ID changed!" << this.item._file_id << fid;
        }
        this.item._file_id = fid;
    }

    this.item._etag = get_etag_from_reply (job.reply ());
    ;
    if (this.item._etag.is_empty ()) {
        GLib.warn (lc_propagate_upload_nG) << "Server did not return an ETAG" << this.item._file;
        abort_with_error (SyncFileItem.Status.NORMAL_ERROR, _("Missing ETag from server"));
        return;
    }
    on_finalize ();
}

void PropagateUploadFileNG.on_upload_progress (int64 sent, int64 total) {
    // Completion is signaled with sent=0, total=0; avoid accidentally
    // resetting progress due to the sent being zero by ignoring it.
    // finished_signal () is bound to be emitted soon anyway.
    // See https://bugreports.qt.io/browse/QTBUG-44782.
    if (sent == 0 && total == 0) {
        return;
    }
    propagator ().report_progress (*this.item, this.sent + sent - total);
}

void PropagateUploadFileNG.on_abort (PropagatorJob.AbortType abort_type) {
    abort_network_jobs (
        abort_type,
        [abort_type] (AbstractNetworkJob job) {
            return abort_type != AbortType.Asynchronous || !qobject_cast<Move_job> (job);
        });
}

}
