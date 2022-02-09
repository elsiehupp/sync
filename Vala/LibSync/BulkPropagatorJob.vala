/***********************************************************
Copyright 2021 (c) Matthieu Gallien <matthieu.gallien@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QFileInfo>
//  #include <QDir>
//  #include <QJsonDocument>
//  #include <QJsonArray>
//  #include <QJsonObject>
//  #include <QJsonValue>


//  #include <QLoggingCategory>
//  #include <deque>

namespace Occ {

class BulkPropagatorJob : PropagatorJob {

    const int BATCH_SIZE = 100;
    const int PARALLEL_JOBS_MAXIMUM_COUNT = 1;

    /***********************************************************
    ***********************************************************/
    private GLib.List<BulkUploadItem> files_to_upload;

    /***********************************************************
    ***********************************************************/
    private SyncFileItem.Status final_status = SyncFileItem.Status.NoStatus;

    /***********************************************************
    This is a minified version of the SyncFileItem, that holds
    only the specifics about the file that's being uploaded.

    This is needed if we want to apply changes on the file
    that's being uploaded while keeping the original on disk.
    ***********************************************************/
    struct UploadFileInfo {
        string file; /// I'm still unsure if I should use a SyncFilePtr here.
        string path; /// the full path on disk.
        int64 size;
    }

    struct BulkUploadItem {
        AccountPointer account;
        SyncFileItemPtr item;
        UploadFileInfo file_to_upload;
        string remote_path;
        string local_path;
        int64 file_size;
        GLib.HashTable<GLib.ByteArray, GLib.ByteArray> headers;
    }


    /***********************************************************
    ***********************************************************/
    public BulkPropagatorJob (
        OwncloudPropagator propagator,
        GLib.Deque<SyncFileItemPtr> items) {
        base (propagator);
        this.items = items;
        this.files_to_upload.reserve (BATCH_SIZE);
        this.pending_checksum_files.reserve (BATCH_SIZE);
    }


    /***********************************************************
    ***********************************************************/
    public bool on_signal_schedule_self_or_child () {
        if (this.items.empty ()) {
            return false;
        }
        if (!this.pending_checksum_files.empty ()) {
            return false;
        }

        this.state = Running;
        for (int i = 0; i < BATCH_SIZE && !this.items.empty (); ++i) {
            var current_item = this.items.front ();
            this.items.pop_front ();
            this.pending_checksum_files.insert (current_item.file);
            QMetaObject.invoke_method (this, /*[this, current_item]*/ () => {
                UploadFileInfo file_to_upload;
                file_to_upload.file = current_item.file;
                file_to_upload.size = current_item.size;
                file_to_upload.path = propagator ().full_local_path (file_to_upload.file);
                on_signal_start_upload_file (current_item, file_to_upload);
            }); // We could be in a different thread (neon jobs)
        }

        return this.items.empty () && this.files_to_upload.empty ();
    }


    /***********************************************************
    ***********************************************************/
    public JobParallelism parallelism () {
        return PropagatorJob.JobParallelism.JobParallelism.FULL_PARALLELISM;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_start_upload_file (SyncFileItemPtr item, UploadFileInfo file_to_upload) {
        if (propagator ().abort_requested) {
            return;
        }

        // Check if the specific file can be accessed
        if (propagator ().has_case_clash_accessibility_problem (file_to_upload.file)) {
            on_signal_done (item, SyncFileItem.Status.NORMAL_ERROR, _("File %1 cannot be uploaded because another file with the same name, differing only in case, exists").arg (QDir.to_native_separators (item.file)));
            return;
        }

        return on_signal_compute_transmission_checksum (item, file_to_upload);
    }



    /***********************************************************
    Content checksum computed, compute the transmission checksum
    ***********************************************************/
    private void on_signal_compute_transmission_checksum (
        SyncFileItemPtr item,
        UploadFileInfo file_to_upload) {
        // Reuse the content checksum as the transmission checksum if possible
        var supported_transmission_checksums =
            propagator ().account ().capabilities ().supported_checksum_types ();

        // Compute the transmission checksum.
        var compute_checksum = std.make_unique<ComputeChecksum> (this);
        if (upload_checksum_enabled ()) {
            compute_checksum.checksum_type ("MD5" /*propagator ().account ().capabilities ().upload_checksum_type ()*/);
        } else {
            compute_checksum.checksum_type (GLib.ByteArray ());
        }

        connect (compute_checksum.get (), &ComputeChecksum.done,
                this, /*[this, item, file_to_upload]*/ (GLib.ByteArray content_checksum_type, GLib.ByteArray content_checksum) => {
            on_signal_start_upload (item, file_to_upload, content_checksum_type, content_checksum);
        });
        connect (compute_checksum.get (), &ComputeChecksum.done,
                compute_checksum.get (), &GLib.Object.delete_later);
        compute_checksum.release ().on_signal_start (file_to_upload.path);
    }



    /***********************************************************
    Transmission checksum computed, prepare the upload
    ***********************************************************/
    private void on_signal_start_upload (
        SyncFileItemPtr item,
        UploadFileInfo file_to_upload,
        GLib.ByteArray transmission_checksum_type,
        GLib.ByteArray transmission_checksum) {
        var transmission_checksum_header = make_checksum_header (transmission_checksum_type, transmission_checksum);

        item.checksum_header = transmission_checksum_header;

        const string full_file_path = file_to_upload.path;
        const string original_file_path = propagator ().full_local_path (item.file);

        if (!FileSystem.file_exists (full_file_path)) {
            this.pending_checksum_files.remove (item.file);
            on_signal_error_start_folder_unlock (item, SyncFileItem.Status.SOFT_ERROR, _("File Removed (on_signal_start upload) %1").arg (full_file_path));
            check_propagation_is_done ();
            return;
        }
        const time_t prev_modtime = item.modtime; // the this.item value was set in PropagateUploadFile.on_signal_start ()
        // but a potential checksum calculation could have taken some time during which the file could
        // have been changed again, so better check again here.

        item.modtime = FileSystem.get_mod_time (original_file_path);
        if (item.modtime <= 0) {
            this.pending_checksum_files.remove (item.file);
            on_signal_error_start_folder_unlock (item, SyncFileItem.Status.NORMAL_ERROR, _("File %1 has invalid modified time. Do not upload to the server.").arg (QDir.to_native_separators (item.file)));
            check_propagation_is_done ();
            return;
        }
        if (prev_modtime != item.modtime) {
            propagator ().another_sync_needed = true;
            this.pending_checksum_files.remove (item.file);
            GLib.debug ("Trigger another sync after checking modified time of item " + item.file + " prev_modtime " + prev_modtime + " Curr " + item.modtime);
            on_signal_error_start_folder_unlock (item, SyncFileItem.Status.SOFT_ERROR, _("Local file changed during syncing. It will be resumed."));
            check_propagation_is_done ();
            return;
        }

        file_to_upload.size = FileSystem.get_size (full_file_path);
        item.size = FileSystem.get_size (original_file_path);

        // But skip the file if the mtime is too close to 'now'!
        // That usually indicates a file that is still being changed
        // or not yet fully copied to the destination.
        if (file_is_still_changing (*item)) {
            propagator ().another_sync_needed = true;
            this.pending_checksum_files.remove (item.file);
            on_signal_error_start_folder_unlock (item, SyncFileItem.Status.SOFT_ERROR, _("Local file changed during sync."));
            check_propagation_is_done ();
            return;
        }

        do_start_upload (item, file_to_upload, transmission_checksum);
    }



    /***********************************************************
    Invoked on internal error to unlock a folder and faile
    ***********************************************************/
    private void on_signal_error_start_folder_unlock (
        SyncFileItemPtr item,
        SyncFileItem.Status status,
        string error_string) {
        GLib.info (status + error_string);
        on_signal_done (item, status, error_string);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_put_finished () {
        var job = qobject_cast<PutMultiFileJob> (sender ());
        //  Q_ASSERT (job);

        on_signal_job_destroyed (job); // remove it from the this.jobs list

        var reply_data = job.reply ().read_all ();
        var reply_json = QJsonDocument.from_json (reply_data);
        var full_reply_object = reply_json.object ();

        foreach (var single_file in this.files_to_upload) {
            if (!full_reply_object.contains (single_file.remote_path)) {
                continue;
            }
            var single_reply_object = full_reply_object[single_file.remote_path].to_object ();
            on_signal_put_finished_one_file (single_file, job, single_reply_object);
        }

        finalize (full_reply_object);
    }


    /***********************************************************
    ***********************************************************/
    private void finalize (QJsonObject full_reply) {
        for (var single_file_it = std.begin (this.files_to_upload); single_file_it != std.end (this.files_to_upload); ) {
            var single_file = *single_file_it;

            if (!full_reply.contains (single_file.remote_path)) {
                ++single_file_it;
                continue;
            }
            if (!single_file.item.has_error_status ()) {
                finalize_one_file (single_file);
            }

            on_signal_done (single_file.item, single_file.item.status, {});

            single_file_it = this.files_to_upload.erase (single_file_it);
        }

        check_propagation_is_done ();
    }


    /***********************************************************
    ***********************************************************/
    private void finalize_one_file (BulkUploadItem one_file) {
        // Update the database entry
        var result = propagator ().update_metadata (*one_file.item);
        if (!result) {
            on_signal_done (one_file.item, SyncFileItem.Status.FATAL_ERROR, _("Error updating metadata : %1").arg (result.error ()));
            return;
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            on_signal_done (one_file.item, SyncFileItem.Status.SOFT_ERROR, _("The file %1 is currently in use").arg (one_file.item.file));
            return;
        }

        // Files that were new on the remote shouldn't have online-only pin state
        // even if their parent folder is online-only.
        if (one_file.item.instruction == CSYNC_INSTRUCTION_NEW
            || one_file.item.instruction == CSYNC_INSTRUCTION_TYPE_CHANGE) {
            var vfs = propagator ().sync_options ().vfs;
            var pin = vfs.pin_state (one_file.item.file);
            if (pin && *pin == PinState.VfsItemAvailability.ONLINE_ONLY && !vfs.pin_state (one_file.item.file, PinState.PinState.UNSPECIFIED)) {
                GLib.warning ("Could not set pin state of " + one_file.item.file + " to unspecified.");
            }
        }

        // Remove from the progress database:
        propagator ().journal.upload_info (one_file.item.file, SyncJournalDb.UploadInfo ());
        propagator ().journal.commit ("upload file on_signal_start");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_upload_progress (SyncFileItemPtr item, int64 sent, int64 total) {
        // Completion is signaled with sent=0, total=0; avoid accidentally
        // resetting progress due to the sent being zero by ignoring it.
        // finished_signal () is bound to be emitted soon anyway.
        // See https://bugreports.qt.io/browse/QTBUG-44782.
        if (sent == 0 && total == 0) {
            return;
        }
        propagator ().report_progress (*item, sent - total);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_job_destroyed (GLib.Object job) {
        this.jobs.erase (std.remove (this.jobs.begin (), this.jobs.end (), job), this.jobs.end ());
    }


    /***********************************************************
    ***********************************************************/
    private void do_start_upload (
        SyncFileItemPtr item,
        UploadFileInfo file_to_upload,
        GLib.ByteArray transmission_checksum_header) {
        if (propagator ().abort_requested) {
            return;
        }

        // write the checksum in the database, so if the POST is sent
        // to the server, but the connection drops before we get the etag, we can check the checksum
        // in reconcile (issue #5106)
        SyncJournalDb.UploadInfo pi;
        pi.valid = true;
        pi.chunk = 0;
        pi.transferid = 0; // We set a null transfer identifier because it is not chunked.
        pi.modtime = item.modtime;
        pi.error_count = 0;
        pi.content_checksum = item.checksum_header;
        pi.size = item.size;
        propagator ().journal.upload_info (item.file, pi);
        propagator ().journal.commit ("Upload info");

        var current_headers = headers (item);
        current_headers[QByteArrayLiteral ("Content-Length")] = new GLib.ByteArray.number (file_to_upload.size);

        if (!item.rename_target.is_empty () && item.file != item.rename_target) {
            // Try to rename the file
            var original_file_path_absolute = propagator ().full_local_path (item.file);
            var new_file_path_absolute = propagator ().full_local_path (item.rename_target);
            var rename_success = GLib.File.rename (original_file_path_absolute, new_file_path_absolute);
            if (!rename_success) {
                on_signal_done (item, SyncFileItem.Status.NORMAL_ERROR, "File contains trailing spaces and couldn't be renamed");
                return;
            }
            GLib.warning (item.file + item.rename_target);
            file_to_upload.file = item.file = item.rename_target;
            file_to_upload.path = propagator ().full_local_path (file_to_upload.file);
            item.modtime = FileSystem.get_mod_time (new_file_path_absolute);
            if (item.modtime <= 0) {
                this.pending_checksum_files.remove (item.file);
                on_signal_error_start_folder_unlock (item, SyncFileItem.Status.NORMAL_ERROR, _("File %1 has invalid modified time. Do not upload to the server.").arg (QDir.to_native_separators (item.file)));
                check_propagation_is_done ();
                return;
            }
        }

        var remote_path = propagator ().full_remote_path (file_to_upload.file);

        current_headers["X-File-MD5"] = transmission_checksum_header;

        BulkUploadItem new_upload_file = new BulkUploadItem (
            propagator ().account (), item, file_to_upload,
            remote_path, file_to_upload.path,
            file_to_upload.size, current_headers);

        GLib.info (remote_path + " transmission checksum " + transmission_checksum_header + file_to_upload.path);
        this.files_to_upload.push_back (std.move (new_upload_file));
        this.pending_checksum_files.remove (item.file);

        if (this.pending_checksum_files.empty ()) {
            trigger_upload ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void trigger_upload () {
        var upload_parameters_data = new GLib.List<SingleUploadFileData> ();
        upload_parameters_data.reserve (this.files_to_upload.size ());

        int timeout = 0;
        foreach (var single_file in this.files_to_upload) {
            // job takes ownership of device via a QScopedPointer. Job deletes itself when finishing
            var device = std.make_unique<UploadDevice> (
                    single_file.local_path, 0, single_file.file_size, propagator ().bandwidth_manager);
            if (!device.open (QIODevice.ReadOnly)) {
                GLib.warning ("Could not prepare upload device: " + device.error_string ());

                // If the file is currently locked, we want to retry the sync
                // when it becomes available again.
                if (FileSystem.is_file_locked (single_file.local_path)) {
                    /* emit */ propagator ().seen_locked_file (single_file.local_path);
                }

                abort_with_error (single_file.item, SyncFileItem.Status.NORMAL_ERROR, device.error_string ());
                /* emit */ finished (SyncFileItem.Status.NORMAL_ERROR);

                return;
            }
            single_file.headers["X-File-Path"] = single_file.remote_path.to_utf8 ();
            upload_parameters_data.push_back ({std.move (device), single_file.headers});
            timeout += single_file.file_size;
        }

        var bulk_upload_url = Utility.concat_url_path (propagator ().account ().url (), "/remote.php/dav/bulk");
        var job = std.make_unique<PutMultiFileJob> (propagator ().account (), bulk_upload_url, std.move (upload_parameters_data), this);
        connect (job.get (), &PutMultiFileJob.finished_signal, this, &BulkPropagatorJob.on_signal_put_finished);

        foreach (var single_file in this.files_to_upload) {
            connect (job.get (), &PutMultiFileJob.upload_progress,
                    this, /*[this, single_file]*/ (int64 sent, int64 total) => {
                on_signal_upload_progress (single_file.item, sent, total);
            });
        }

        adjust_last_job_timeout (job.get (), timeout);
        this.jobs.append (job.get ());
        job.release ().on_signal_start ();
        if (parallelism () == PropagatorJob.JobParallelism.JobParallelism.FULL_PARALLELISM && this.jobs.size () < PARALLEL_JOBS_MAXIMUM_COUNT) {
            on_signal_schedule_self_or_child ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void check_propagation_is_done () {
        if (this.items.empty ()) {
            if (!this.jobs.empty () || !this.pending_checksum_files.empty ()) {
                // just wait for the other job to finish.
                return;
            }

            GLib.info ("final status" + this.final_status);
            /* emit */ finished (this.final_status);
            propagator ().schedule_next_job ();
        } else {
            on_signal_schedule_self_or_child ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void adjust_last_job_timeout (
        AbstractNetworkJob job, int64 file_size) {
        const double three_minutes = 3.0 * 60 * 1000;

        job.on_signal_timeout (q_bound (
            job.timeout_msec (),
            // Calculate 3 minutes for each gigabyte of data
            q_round64 (three_minutes * static_cast<double> (file_size) / 1e9),
            // Maximum of 30 minutes
                            static_cast<int64> (30 * 60 * 1000)));
    }


    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private void on_signal_put_finished_one_file (
        BulkUploadItem single_file,
        PutMultiFileJob job,
        QJsonObject file_reply) {
        bool on_signal_finished = false;

        GLib.info (single_file.item.file + "file headers" + file_reply;

        if (file_reply.contains ("error") && !file_reply[QStringLiteral ("error")].to_bool ()) {
            single_file.item.http_error_code = static_cast<uint16> (200);
        } else {
            single_file.item.http_error_code = static_cast<uint16> (412);
        }

        single_file.item.response_time_stamp = job.response_timestamp ();
        single_file.item.request_id = job.request_id ();
        if (single_file.item.http_error_code != 200) {
            common_error_handling (single_file.item, file_reply[QStringLiteral ("message")].to_string ());
            return;
        }

        single_file.item.status = SyncFileItem.Status.SUCCESS;

        // Check the file again post upload.
        // Two cases must be considered separately : If the upload is on_signal_finished,
        // the file is on the server and has a changed ETag. In that case,
        // the etag has to be properly updated in the client journal, and because
        // of that we can bail out here with an error. But we can reschedule a
        // sync ASAP.
        // But if the upload is ongoing, because not all chunks were uploaded
        // yet, the upload can be stopped and an error can be displayed, because
        // the server hasn't registered the new file yet.
        var etag = get_etag_from_json_reply (file_reply);
        on_signal_finished = etag.length () > 0;

        var full_file_path (propagator ().full_local_path (single_file.item.file));

        // Check if the file still exists
        if (!check_file_still_exists (single_file.item, on_signal_finished, full_file_path)) {
            return;
        }

        // Check whether the file changed since discovery. the file check here is the original and not the temporary.
        if (!check_file_changed (single_file.item, on_signal_finished, full_file_path)) {
            return;
        }

        // the file identifier should only be empty for new files up- or downloaded
        compute_file_id (single_file.item, file_reply);

        single_file.item.etag = etag;

        if (get_header_from_json_reply (file_reply, "X-OC-MTime") != "accepted") {
            // X-OC-MTime is supported since owncloud 5.0.   But not when chunking.
            // Normally Owncloud 6 always puts X-OC-MTime
            GLib.warning ("Server does not support X-OC-MTime" + get_header_from_json_reply (file_reply, "X-OC-MTime");
            // Well, the mtime was not set
        }
    }


    /***********************************************************
    ***********************************************************/
    private static GLib.ByteArray get_etag_from_json_reply (QJsonObject reply) {
        var oc_etag = Occ.parse_etag (reply.value ("OC-ETag").to_string ().to_latin1 ());
        var ETag = Occ.parse_etag (reply.value ("ETag").to_string ().to_latin1 ());
        var  etag = Occ.parse_etag (reply.value ("etag").to_string ().to_latin1 ());
        GLib.ByteArray ret = oc_etag;
        if (ret.is_empty ()) {
            ret = ETag;
        }
        if (ret.is_empty ()) {
            ret = etag;
        }
        if (oc_etag.length () > 0 && oc_etag != etag && oc_etag != ETag) {
            GLib.debug (Occ.lc_bulk_propagator_job) + "Quite peculiar, we have an etag != OC-Etag [no problem!]" + etag + ETag + oc_etag;
        }
        return ret;
    }


    /***********************************************************
    ***********************************************************/
    private static GLib.ByteArray get_header_from_json_reply (QJsonObject reply, GLib.ByteArray header_name) {
        return reply.value (header_name).to_string ().to_latin1 ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_done (
        SyncFileItemPtr item,
        SyncFileItem.Status status,
        string error_string) {
        item.status = status;
        item.error_string = error_string;

        GLib.info ("Item completed " + item.destination () + item.status + item.instruction + item.error_string);

        handle_file_restoration (item, error_string);

        if (propagator ().abort_requested && (item.status == SyncFileItem.Status.NORMAL_ERROR
                                                || item.status == SyncFileItem.Status.FATAL_ERROR)) {
            // an on_signal_abort request is ongoing. Change the status to Soft-Error
            item.status = SyncFileItem.Status.SOFT_ERROR;
        }

        if (item.status != SyncFileItem.Status.SUCCESS) {
            // Blocklist handling
            handle_bulk_upload_block_list (item);
            propagator ().another_sync_needed = true;
        }

        handle_job_done_errors (item, status);

        /* emit */ propagator ().item_completed (item);
    }


    /***********************************************************
    Bases headers that need to be sent on the PUT, or in the MOVE for chunking-ng
    ***********************************************************/
    private GLib.HashTable<GLib.ByteArray, GLib.ByteArray> headers (SyncFileItemPtr item) {
        GLib.HashTable<GLib.ByteArray, GLib.ByteArray> headers;
        headers[QByteArrayLiteral ("Content-Type")] = QByteArrayLiteral ("application/octet-stream");
        headers[QByteArrayLiteral ("X-File-Mtime")] = new GLib.ByteArray.number (int64 (item.modtime));
        if (q_environment_variable_int_value ("OWNCLOUD_LAZYOPS")) {
            headers[QByteArrayLiteral ("OC-LazyOps")] = QByteArrayLiteral ("true");
        }

        if (item.file.contains (QLatin1String (".sys.admin#recall#"))) {
            // This is a file recall triggered by the admin.  Note: the
            // recall list file created by the admin and downloaded by the
            // client (.sys.admin#recall#) also falls into this category
            // (albeit users are not supposed to mess up with it)

            // We use a special tag header so that the server may decide to store this file away in some admin stage area
            // And not directly in the user's area (which would trigger redownloads etc).
            headers["OC-Tag"] = ".sys.admin#recall#";
        }

        if (!item.etag.is_empty () && item.etag != "empty_etag"
            && item.instruction != CSYNC_INSTRUCTION_NEW // On new files never send a If-Match
            && item.instruction != CSYNC_INSTRUCTION_TYPE_CHANGE) {
            // We add quotes because the owncloud server always adds quotes around the etag, and
            //  csync_owncloud.c's owncloud_file_id always strips the quotes.
            headers[QByteArrayLiteral ("If-Match")] = '"' + item.etag + '"';
        }

        // Set up a conflict file header pointing to the original file
        var conflict_record = propagator ().journal.conflict_record (item.file.to_utf8 ());
        if (conflict_record.is_valid ()) {
            headers[QByteArrayLiteral ("OC-Conflict")] = "1";
            if (!conflict_record.initial_base_path.is_empty ()) {
                headers[QByteArrayLiteral ("OC-ConflictInitialBasePath")] = conflict_record.initial_base_path;
            }
            if (!conflict_record.base_file_id.is_empty ()) {
                headers[QByteArrayLiteral ("OC-ConflictBaseFileId")] = conflict_record.base_file_id;
            }
            if (conflict_record.base_modtime != -1) {
                headers[QByteArrayLiteral ("OC-ConflictBaseMtime")] = new GLib.ByteArray.number (conflict_record.base_modtime);
            }
            if (!conflict_record.base_etag.is_empty ()) {
                headers[QByteArrayLiteral ("OC-ConflictBaseEtag")] = conflict_record.base_etag;
            }
        }

        return headers;
    }


    /***********************************************************
    ***********************************************************/
    private void abort_with_error (
        SyncFileItemPtr item,
        SyncFileItem.Status status,
        string error) {
        on_signal_abort (PropagatorJob.AbortType.SYNCHRONOUS);
        on_signal_done (item, status, error);
    }


    /***********************************************************
    Checks whether the current error is one that should reset
    the whole transfer if it happens too often. If so: Bump
    UploadInfo.error_count and maybe perform the reset.
    ***********************************************************/
    private void check_resetting_errors (SyncFileItemPtr item) {
        if (item.http_error_code == 412
            || propagator ().account ().capabilities ().http_error_codes_that_reset_failing_chunked_uploads ().contains (item.http_error_code)) {
            var upload_info = propagator ().journal.get_upload_info (item.file);
            upload_info.error_count += 1;
            if (upload_info.error_count > 3) {
                GLib.info ("Reset transfer of " + item.file
                            + " due to repeated error " + item.http_error_code);
                upload_info = SyncJournalDb.UploadInfo ();
            } else {
                GLib.info ("Error count for maybe-reset error" + item.http_error_code
                        + "on file" + item.file
                        + "is" + upload_info.error_count);
            }
            propagator ().journal.upload_info (item.file, upload_info);
            propagator ().journal.commit ("Upload info");
        }
    }


    /***********************************************************
    Error handling functionality that is shared between jobs.
    ***********************************************************/
    private void common_error_handling (
        SyncFileItemPtr item,
        string error_message) {
        // Ensure errors that should eventually reset the chunked upload are tracked.
        check_resetting_errors (item);

        abort_with_error (item, SyncFileItem.Status.NORMAL_ERROR, error_message);
    }


    /***********************************************************
    ***********************************************************/
    private bool check_file_still_exists (
        SyncFileItemPtr item,
        bool on_signal_finished,
        string full_file_path) {
        if (!FileSystem.file_exists (full_file_path)) {
            if (!on_signal_finished) {
                abort_with_error (item, SyncFileItem.Status.SOFT_ERROR, _("The local file was removed during sync."));
                return false;
            } else {
                propagator ().another_sync_needed = true;
            }
        }

        return true;
    }


    /***********************************************************
    ***********************************************************/
    private bool check_file_changed (
        SyncFileItemPtr item,
        bool on_signal_finished,
        string full_file_path) {
        if (!FileSystem.verify_file_unchanged (full_file_path, item.size, item.modtime)) {
            propagator ().another_sync_needed = true;
            if (!on_signal_finished) {
                abort_with_error (item, SyncFileItem.Status.SOFT_ERROR, _("Local file changed during sync."));
                // FIXME :  the legacy code was retrying for a few seconds.
                //         and also checking that after the last chunk, and removed the file in case of INSTRUCTION_NEW
                return false;
            }
        }

        return true;
    }


    /***********************************************************
    ***********************************************************/
    private void compute_file_id (
        SyncFileItemPtr item,
        QJsonObject file_reply) {
        var fid = get_header_from_json_reply (file_reply, "OC-FileID");
        if (!fid.is_empty ()) {
            if (!item.file_id.is_empty () && item.file_id != fid) {
                GLib.warning ("File ID changed!" + item.file_id + fid);
            }
            item.file_id = fid;
        }
    }


    /***********************************************************
    ***********************************************************/
    private void handle_file_restoration (
        SyncFileItemPtr item,
        string error_string) {
        if (item.is_restoration) {
            if (item.status == SyncFileItem.Status.SUCCESS
                || item.status == SyncFileItem.Status.CONFLICT) {
                item.status = SyncFileItem.Status.RESTORATION;
            } else {
                item.error_string += _("; Restoration Failed : %1").arg (error_string);
            }
        } else {
            if (item.error_string.is_empty ()) {
                item.error_string = error_string;
            }
        }
    }


    /***********************************************************
    ***********************************************************/

    /***********************************************************
    ***********************************************************/
    private void handle_bulk_upload_block_list (SyncFileItemPtr item) {
        propagator ().add_to_bulk_upload_block_list (item.file);
    }


    /***********************************************************
    ***********************************************************/
    private void handle_job_done_errors (
        SyncFileItemPtr item,
        SyncFileItem.Status status) {
        if (item.has_error_status ()) {
            GLib.warning ("Could not complete propagation of " + item.destination () + " by " + this + " with status " + item.status + " and error: " + item.error_string);
        } else {
            GLib.info ("Completed propagation of " + item.destination () + " by " + this +  "with status " + item.status);
        }

        if (item.status == SyncFileItem.Status.FATAL_ERROR) {
            // Abort all remaining jobs.
            propagator ().on_signal_abort ();
        }

        switch (item.status) {
        case SyncFileItem.Status.BLOCKLISTED_ERROR:
        case SyncFileItem.Status.CONFLICT:
        case SyncFileItem.Status.FATAL_ERROR:
        case SyncFileItem.Status.FILE_IGNORED:
        case SyncFileItem.Status.FILE_LOCKED:
        case SyncFileItem.Status.FILENAME_INVALID:
        case SyncFileItem.Status.NO_STATUS:
        case SyncFileItem.Status.NORMAL_ERROR:
        case SyncFileItem.Status.RESTORATION:
        case SyncFileItem.Status.SOFT_ERROR:
            this.final_status = SyncFileItem.Status.NORMAL_ERROR;
            GLib.info ("Modify final status NormalError " + this.final_status + status);
            break;
        case SyncFileItem.Status.DETAIL_ERROR:
            this.final_status = SyncFileItem.Status.DETAIL_ERROR;
            GLib.info ("Modify final status DetailError " + this.final_status + status);
            break;
        case SyncFileItem.Status.SUCCESS:
            break;
        }
    }

} // class BulkPropagatorJob

} // namespace Occ
    