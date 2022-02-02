/***********************************************************
Copyright 2021 (c) Matthieu Gallien <matthieu.gallien@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFileInfo>
// #include <QDir>
// #include <QJsonDocument>
// #include <QJsonArray>
// #include <QJsonObject>
// #include <QJsonValue>

// #pragma once

// #include <QLoggingCategory>
// #include <deque>

namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lc_bulk_propagator_job)


class BulkPropagatorJob : PropagatorJob {

    /***********************************************************
    This is a minified version of the SyncFileItem, that holds
    only the specifics about the file that's being uploaded.

    This is needed if we want to apply changes on the file
    that's being uploaded while keeping the original on disk.
    ***********************************************************/
    struct UploadFileInfo {
        string this.file; /// I'm still unsure if I should use a SyncFilePtr here.
        string this.path; /// the full path on disk.
        int64 this.size;
    };

    struct BulkUploadItem {
        AccountPointer this.account;
        SyncFileItemPtr this.item;
        UploadFileInfo this.file_to_upload;
        string this.remote_path;
        string this.local_path;
        int64 this.file_size;
        GLib.HashMap<GLib.ByteArray, GLib.ByteArray> this.headers;
    };


    /***********************************************************
    ***********************************************************/
    public BulkPropagatorJob (OwncloudPropagator propagator,

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 
    public JobParallelism parallelism () override;


    /***********************************************************
    ***********************************************************/
    private void on_start_upload_file (SyncFileItemPtr item, UploadFileInfo file_to_upload);

    // Content checksum computed, compute the transmission checksum
    private void on_compute_transmission_checksum (SyncFileItemPtr item,
                                         UploadFileInfo file_to_upload);

    // transmission checksum computed, prepare the upload
    private void on_start_upload (SyncFileItemPtr item,
                         UploadFileInfo file_to_upload,
                         const GLib.ByteArray transmission_checksum_type,
                         const GLib.ByteArray transmission_checksum);

    // invoked on internal error to unlock a folder and faile
    private void on_on_error_start_folder_unlock (SyncFileItemPtr item,
                                      SyncFileItem.Status status,
                                      const string error_string);

    /***********************************************************
    ***********************************************************/
    private void on_put_finished ();

    /***********************************************************
    ***********************************************************/
    private void on_upload_progress (SyncFileItemPtr item, int64 sent, int64 total);

    /***********************************************************
    ***********************************************************/
    private void on_job_destroyed (GLib.Object job);

    /***********************************************************
    ***********************************************************/
    private 
    private void do_start_upload (SyncFileItemPtr item,
                       UploadFileInfo file_to_upload,
                       GLib.ByteArray transmission_checksum_header);

    /***********************************************************
    ***********************************************************/
    private void adjust_last_job_timeout (AbstractNetworkJob job,

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 
    private void on_put_finished_one_file (BulkUploadItem single_file,
                                Occ.PutMultiFileJob job,
                                const QJsonObject full_reply_object);

    /***********************************************************
    ***********************************************************/
    private void on_done (SyncFileItemPtr item,
              SyncFileItem.Status status,
              const string error_string);


    /***********************************************************
    Bases headers that need to be sent on the PUT, or in the MOVE for chunking-ng
    ***********************************************************/
    private GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers (SyncFileItemPtr item);

    /***********************************************************
    ***********************************************************/
    private void abort_with_error (SyncFileItemPtr item,
                        SyncFileItem.Status status,
                        const string error);


    /***********************************************************
    Checks whether the current error is one that should reset the whole
    transfer if it happens too often. If so : Bump UploadInfo.error_count
    and maybe perform the reset.
    ***********************************************************/
    private void check_resetting_errors (SyncFileItemPtr item);


    /***********************************************************
    Error handling functionality that is shared between jobs.
    ***********************************************************/
    private void common_error_handling (SyncFileItemPtr item,
                             const string error_message);

    /***********************************************************
    ***********************************************************/
    private bool check_file_still_exists (SyncFileItemPtr item,
                              const bool on_finished,
                              const string full_file_path);

    /***********************************************************
    ***********************************************************/
    private bool check_file_changed (SyncFileItemPtr item,
                          const bool on_finished,
                          const string full_file_path);

    /***********************************************************
    ***********************************************************/
    private void compute_file_id (SyncFileItemPtr item,

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private                    const string error_string);

    /***********************************************************
    ***********************************************************/
    private void handle_bulk_upload_block_list (SyncFileItemPtr item);

    /***********************************************************
    ***********************************************************/
    private void handle_job_done_er

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 
    private std.vector<BulkUploadItem> this.files_to_upload;

    /***********************************************************
    ***********************************************************/
    private SyncFileItem.Status this.final_status = SyncFileItem.Status.NoStatus;
}



    GLib.ByteArray get_etag_from_json_reply (QJsonObject reply) {
        const var oc_etag = Occ.parse_etag (reply.value ("OC-ETag").to_string ().to_latin1 ());
        const var ETag = Occ.parse_etag (reply.value ("ETag").to_string ().to_latin1 ());
        const var  etag = Occ.parse_etag (reply.value ("etag").to_string ().to_latin1 ());
        GLib.ByteArray ret = oc_etag;
        if (ret.is_empty ()) {
            ret = ETag;
        }
        if (ret.is_empty ()) {
            ret = etag;
        }
        if (oc_etag.length () > 0 && oc_etag != etag && oc_etag != ETag) {
            GLib.debug (Occ.lc_bulk_propagator_job) << "Quite peculiar, we have an etag != OC-Etag [no problem!]" << etag << ETag << oc_etag;
        }
        return ret;
    }

    GLib.ByteArray get_header_from_json_reply (QJsonObject reply, GLib.ByteArray header_name) {
        return reply.value (header_name).to_string ().to_latin1 ();
    }

    constexpr var batch_size = 100;

    constexpr var parallel_jobs_maximum_count = 1;


    BulkPropagatorJob.BulkPropagatorJob (OwncloudPropagator propagator,
                                         const std.deque<SyncFileItemPtr> items)
        : PropagatorJob (propagator)
        , this.items (items) {
        this.files_to_upload.reserve (batch_size);
        this.pending_checksum_files.reserve (batch_size);
    }

    bool BulkPropagatorJob.on_schedule_self_or_child () {
        if (this.items.empty ()) {
            return false;
        }
        if (!this.pending_checksum_files.empty ()) {
            return false;
        }

        this.state = Running;
        for (int i = 0; i < batch_size && !this.items.empty (); ++i) {
            var current_item = this.items.front ();
            this.items.pop_front ();
            this.pending_checksum_files.insert (current_item._file);
            QMetaObject.invoke_method (this, [this, current_item] () {
                UploadFileInfo file_to_upload;
                file_to_upload._file = current_item._file;
                file_to_upload._size = current_item._size;
                file_to_upload._path = propagator ().full_local_path (file_to_upload._file);
                on_start_upload_file (current_item, file_to_upload);
            }); // We could be in a different thread (neon jobs)
        }

        return this.items.empty () && this.files_to_upload.empty ();
    }

    PropagatorJob.JobParallelism BulkPropagatorJob.parallelism () {
        return PropagatorJob.JobParallelism.FullParallelism;
    }

    void BulkPropagatorJob.on_start_upload_file (SyncFileItemPtr item, UploadFileInfo file_to_upload) {
        if (propagator ()._abort_requested) {
            return;
        }

        // Check if the specific file can be accessed
        if (propagator ().has_case_clash_accessibility_problem (file_to_upload._file)) {
            on_done (item, SyncFileItem.Status.NORMAL_ERROR, _("File %1 cannot be uploaded because another file with the same name, differing only in case, exists").arg (QDir.to_native_separators (item._file)));
            return;
        }

        return on_compute_transmission_checksum (item, file_to_upload);
    }

    void BulkPropagatorJob.do_start_upload (SyncFileItemPtr item,
                                          UploadFileInfo file_to_upload,
                                          GLib.ByteArray transmission_checksum_header) {
        if (propagator ()._abort_requested) {
            return;
        }

        // write the checksum in the database, so if the POST is sent
        // to the server, but the connection drops before we get the etag, we can check the checksum
        // in reconcile (issue #5106)
        SyncJournalDb.UploadInfo pi;
        pi._valid = true;
        pi._chunk = 0;
        pi._transferid = 0; // We set a null transfer id because it is not chunked.
        pi._modtime = item._modtime;
        pi._error_count = 0;
        pi._content_checksum = item._checksum_header;
        pi._size = item._size;
        propagator ()._journal.set_upload_info (item._file, pi);
        propagator ()._journal.commit ("Upload info");

        var current_headers = headers (item);
        current_headers[QByteArrayLiteral ("Content-Length")] = GLib.ByteArray.number (file_to_upload._size);

        if (!item._rename_target.is_empty () && item._file != item._rename_target) {
            // Try to rename the file
            const var original_file_path_absolute = propagator ().full_local_path (item._file);
            const var new_file_path_absolute = propagator ().full_local_path (item._rename_target);
            const var rename_success = GLib.File.rename (original_file_path_absolute, new_file_path_absolute);
            if (!rename_success) {
                on_done (item, SyncFileItem.Status.NORMAL_ERROR, "File contains trailing spaces and couldn't be renamed");
                return;
            }
            GLib.warn (lc_bulk_propagator_job ()) << item._file << item._rename_target;
            file_to_upload._file = item._file = item._rename_target;
            file_to_upload._path = propagator ().full_local_path (file_to_upload._file);
            item._modtime = FileSystem.get_mod_time (new_file_path_absolute);
            if (item._modtime <= 0) {
                this.pending_checksum_files.remove (item._file);
                on_on_error_start_folder_unlock (item, SyncFileItem.Status.NORMAL_ERROR, _("File %1 has invalid modified time. Do not upload to the server.").arg (QDir.to_native_separators (item._file)));
                check_propagation_is_done ();
                return;
            }
        }

        const var remote_path = propagator ().full_remote_path (file_to_upload._file);

        current_headers["X-File-MD5"] = transmission_checksum_header;

        BulkUploadItem new_upload_file{propagator ().account (), item, file_to_upload,
                    remote_path, file_to_upload._path,
                    file_to_upload._size, current_headers};

        q_c_info (lc_bulk_propagator_job) << remote_path << "transmission checksum" << transmission_checksum_header << file_to_upload._path;
        this.files_to_upload.push_back (std.move (new_upload_file));
        this.pending_checksum_files.remove (item._file);

        if (this.pending_checksum_files.empty ()) {
            trigger_upload ();
        }
    }

    void BulkPropagatorJob.trigger_upload () {
        var upload_parameters_data = std.vector<SingleUploadFileData>{};
        upload_parameters_data.reserve (this.files_to_upload.size ());

        int timeout = 0;
        for (var single_file : this.files_to_upload) {
            // job takes ownership of device via a QScopedPointer. Job deletes itself when finishing
            var device = std.make_unique<UploadDevice> (
                    single_file._local_path, 0, single_file._file_size, propagator ()._bandwidth_manager);
            if (!device.open (QIODevice.ReadOnly)) {
                GLib.warn (lc_bulk_propagator_job) << "Could not prepare upload device : " << device.error_string ();

                // If the file is currently locked, we want to retry the sync
                // when it becomes available again.
                if (FileSystem.is_file_locked (single_file._local_path)) {
                    /* emit */ propagator ().seen_locked_file (single_file._local_path);
                }

                abort_with_error (single_file._item, SyncFileItem.Status.NORMAL_ERROR, device.error_string ());
                /* emit */ finished (SyncFileItem.Status.NORMAL_ERROR);

                return;
            }
            single_file._headers["X-File-Path"] = single_file._remote_path.to_utf8 ();
            upload_parameters_data.push_back ({std.move (device), single_file._headers});
            timeout += single_file._file_size;
        }

        const var bulk_upload_url = Utility.concat_url_path (propagator ().account ().url (), QStringLiteral ("/remote.php/dav/bulk"));
        var job = std.make_unique<PutMultiFileJob> (propagator ().account (), bulk_upload_url, std.move (upload_parameters_data), this);
        connect (job.get (), &PutMultiFileJob.finished_signal, this, &BulkPropagatorJob.on_put_finished);

        for (var single_file : this.files_to_upload) {
            connect (job.get (), &PutMultiFileJob.upload_progress,
                    this, [this, single_file] (int64 sent, int64 total) {
                on_upload_progress (single_file._item, sent, total);
            });
        }

        adjust_last_job_timeout (job.get (), timeout);
        this.jobs.append (job.get ());
        job.release ().on_start ();
        if (parallelism () == PropagatorJob.JobParallelism.FullParallelism && this.jobs.size () < parallel_jobs_maximum_count) {
            on_schedule_self_or_child ();
        }
    }

    void BulkPropagatorJob.check_propagation_is_done () {
        if (this.items.empty ()) {
            if (!this.jobs.empty () || !this.pending_checksum_files.empty ()) {
                // just wait for the other job to finish.
                return;
            }

            q_c_info (lc_bulk_propagator_job) << "final status" << this.final_status;
            /* emit */ finished (this.final_status);
            propagator ().schedule_next_job ();
        } else {
            on_schedule_self_or_child ();
        }
    }

    void BulkPropagatorJob.on_compute_transmission_checksum (SyncFileItemPtr item,
                                                            UploadFileInfo file_to_upload) {
        // Reuse the content checksum as the transmission checksum if possible
        const var supported_transmission_checksums =
            propagator ().account ().capabilities ().supported_checksum_types ();

        // Compute the transmission checksum.
        var compute_checksum = std.make_unique<ComputeChecksum> (this);
        if (upload_checksum_enabled ()) {
            compute_checksum.set_checksum_type ("MD5" /*propagator ().account ().capabilities ().upload_checksum_type ()*/);
        } else {
            compute_checksum.set_checksum_type (GLib.ByteArray ());
        }

        connect (compute_checksum.get (), &ComputeChecksum.done,
                this, [this, item, file_to_upload] (GLib.ByteArray content_checksum_type, GLib.ByteArray content_checksum) {
            on_start_upload (item, file_to_upload, content_checksum_type, content_checksum);
        });
        connect (compute_checksum.get (), &ComputeChecksum.done,
                compute_checksum.get (), &GLib.Object.delete_later);
        compute_checksum.release ().on_start (file_to_upload._path);
    }

    void BulkPropagatorJob.on_start_upload (SyncFileItemPtr item,
                                            UploadFileInfo file_to_upload,
                                            const GLib.ByteArray transmission_checksum_type,
                                            const GLib.ByteArray transmission_checksum) {
        const var transmission_checksum_header = make_checksum_header (transmission_checksum_type, transmission_checksum);

        item._checksum_header = transmission_checksum_header;

        const string full_file_path = file_to_upload._path;
        const string original_file_path = propagator ().full_local_path (item._file);

        if (!FileSystem.file_exists (full_file_path)) {
            this.pending_checksum_files.remove (item._file);
            on_on_error_start_folder_unlock (item, SyncFileItem.Status.SOFT_ERROR, _("File Removed (on_start upload) %1").arg (full_file_path));
            check_propagation_is_done ();
            return;
        }
        const time_t prev_modtime = item._modtime; // the this.item value was set in PropagateUploadFile.on_start ()
        // but a potential checksum calculation could have taken some time during which the file could
        // have been changed again, so better check again here.

        item._modtime = FileSystem.get_mod_time (original_file_path);
        if (item._modtime <= 0) {
            this.pending_checksum_files.remove (item._file);
            on_on_error_start_folder_unlock (item, SyncFileItem.Status.NORMAL_ERROR, _("File %1 has invalid modified time. Do not upload to the server.").arg (QDir.to_native_separators (item._file)));
            check_propagation_is_done ();
            return;
        }
        if (prev_modtime != item._modtime) {
            propagator ()._another_sync_needed = true;
            this.pending_checksum_files.remove (item._file);
            q_debug () << "trigger another sync after checking modified time of item" << item._file << "prev_modtime" << prev_modtime << "Curr" << item._modtime;
            on_on_error_start_folder_unlock (item, SyncFileItem.Status.SOFT_ERROR, _("Local file changed during syncing. It will be resumed."));
            check_propagation_is_done ();
            return;
        }

        file_to_upload._size = FileSystem.get_size (full_file_path);
        item._size = FileSystem.get_size (original_file_path);

        // But skip the file if the mtime is too close to 'now'!
        // That usually indicates a file that is still being changed
        // or not yet fully copied to the destination.
        if (file_is_still_changing (*item)) {
            propagator ()._another_sync_needed = true;
            this.pending_checksum_files.remove (item._file);
            on_on_error_start_folder_unlock (item, SyncFileItem.Status.SOFT_ERROR, _("Local file changed during sync."));
            check_propagation_is_done ();
            return;
        }

        do_start_upload (item, file_to_upload, transmission_checksum);
    }

    void BulkPropagatorJob.on_on_error_start_folder_unlock (SyncFileItemPtr item,
                                                         SyncFileItem.Status status,
                                                         const string error_string) {
        q_c_info (lc_bulk_propagator_job ()) << status << error_string;
        on_done (item, status, error_string);
    }

    void BulkPropagatorJob.on_put_finished_one_file (BulkUploadItem single_file,
                                                   PutMultiFileJob job,
                                                   const QJsonObject file_reply) {
        bool on_finished = false;

        q_c_info (lc_bulk_propagator_job ()) << single_file._item._file << "file headers" << file_reply;

        if (file_reply.contains ("error") && !file_reply[QStringLiteral ("error")].to_bool ()) {
            single_file._item._http_error_code = static_cast<uint16> (200);
        } else {
            single_file._item._http_error_code = static_cast<uint16> (412);
        }

        single_file._item._response_time_stamp = job.response_timestamp ();
        single_file._item._request_id = job.request_id ();
        if (single_file._item._http_error_code != 200) {
            common_error_handling (single_file._item, file_reply[QStringLiteral ("message")].to_string ());
            return;
        }

        single_file._item._status = SyncFileItem.Status.SUCCESS;

        // Check the file again post upload.
        // Two cases must be considered separately : If the upload is on_finished,
        // the file is on the server and has a changed ETag. In that case,
        // the etag has to be properly updated in the client journal, and because
        // of that we can bail out here with an error. But we can reschedule a
        // sync ASAP.
        // But if the upload is ongoing, because not all chunks were uploaded
        // yet, the upload can be stopped and an error can be displayed, because
        // the server hasn't registered the new file yet.
        const var etag = get_etag_from_json_reply (file_reply);
        on_finished = etag.length () > 0;

        const var full_file_path (propagator ().full_local_path (single_file._item._file));

        // Check if the file still exists
        if (!check_file_still_exists (single_file._item, on_finished, full_file_path)) {
            return;
        }

        // Check whether the file changed since discovery. the file check here is the original and not the temporary.
        if (!check_file_changed (single_file._item, on_finished, full_file_path)) {
            return;
        }

        // the file id should only be empty for new files up- or downloaded
        compute_file_id (single_file._item, file_reply);

        single_file._item._etag = etag;

        if (get_header_from_json_reply (file_reply, "X-OC-MTime") != "accepted") {
            // X-OC-MTime is supported since owncloud 5.0.   But not when chunking.
            // Normally Owncloud 6 always puts X-OC-MTime
            GLib.warn (lc_bulk_propagator_job) << "Server does not support X-OC-MTime" << get_header_from_json_reply (file_reply, "X-OC-MTime");
            // Well, the mtime was not set
        }
    }

    void BulkPropagatorJob.on_put_finished () {
        var job = qobject_cast<PutMultiFileJob> (sender ());
        Q_ASSERT (job);

        on_job_destroyed (job); // remove it from the this.jobs list

        const var reply_data = job.reply ().read_all ();
        const var reply_json = QJsonDocument.from_json (reply_data);
        const var full_reply_object = reply_json.object ();

        for (var single_file : this.files_to_upload) {
            if (!full_reply_object.contains (single_file._remote_path)) {
                continue;
            }
            const var single_reply_object = full_reply_object[single_file._remote_path].to_object ();
            on_put_finished_one_file (single_file, job, single_reply_object);
        }

        on_finalize (full_reply_object);
    }

    void BulkPropagatorJob.on_upload_progress (SyncFileItemPtr item, int64 sent, int64 total) {
        // Completion is signaled with sent=0, total=0; avoid accidentally
        // resetting progress due to the sent being zero by ignoring it.
        // finished_signal () is bound to be emitted soon anyway.
        // See https://bugreports.qt.io/browse/QTBUG-44782.
        if (sent == 0 && total == 0) {
            return;
        }
        propagator ().report_progress (*item, sent - total);
    }

    void BulkPropagatorJob.on_job_destroyed (GLib.Object job) {
        this.jobs.erase (std.remove (this.jobs.begin (), this.jobs.end (), job), this.jobs.end ());
    }

    void BulkPropagatorJob.adjust_last_job_timeout (AbstractNetworkJob job, int64 file_size) {
        constexpr double three_minutes = 3.0 * 60 * 1000;

        job.on_set_timeout (q_bound (
            job.timeout_msec (),
            // Calculate 3 minutes for each gigabyte of data
            q_round64 (three_minutes * static_cast<double> (file_size) / 1e9),
            // Maximum of 30 minutes
                            static_cast<int64> (30 * 60 * 1000)));
    }

    void BulkPropagatorJob.finalize_one_file (BulkUploadItem one_file) {
        // Update the database entry
        const var result = propagator ().update_metadata (*one_file._item);
        if (!result) {
            on_done (one_file._item, SyncFileItem.Status.FATAL_ERROR, _("Error updating metadata : %1").arg (result.error ()));
            return;
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            on_done (one_file._item, SyncFileItem.Status.SOFT_ERROR, _("The file %1 is currently in use").arg (one_file._item._file));
            return;
        }

        // Files that were new on the remote shouldn't have online-only pin state
        // even if their parent folder is online-only.
        if (one_file._item._instruction == CSYNC_INSTRUCTION_NEW
            || one_file._item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE) {
            var vfs = propagator ().sync_options ()._vfs;
            const var pin = vfs.pin_state (one_file._item._file);
            if (pin && *pin == PinState.VfsItemAvailability.ONLINE_ONLY && !vfs.set_pin_state (one_file._item._file, PinState.PinState.UNSPECIFIED)) {
                GLib.warn (lc_bulk_propagator_job) << "Could not set pin state of" << one_file._item._file << "to unspecified";
            }
        }

        // Remove from the progress database:
        propagator ()._journal.set_upload_info (one_file._item._file, SyncJournalDb.UploadInfo ());
        propagator ()._journal.commit ("upload file on_start");
    }

    void BulkPropagatorJob.on_finalize (QJsonObject full_reply) {
        for (var single_file_it = std.begin (this.files_to_upload); single_file_it != std.end (this.files_to_upload); ) {
            const var single_file = *single_file_it;

            if (!full_reply.contains (single_file._remote_path)) {
                ++single_file_it;
                continue;
            }
            if (!single_file._item.has_error_status ()) {
                finalize_one_file (single_file);
            }

            on_done (single_file._item, single_file._item._status, {});

            single_file_it = this.files_to_upload.erase (single_file_it);
        }

        check_propagation_is_done ();
    }

    void BulkPropagatorJob.on_done (SyncFileItemPtr item,
                                 SyncFileItem.Status status,
                                 const string error_string) {
        item._status = status;
        item._error_string = error_string;

        q_c_info (lc_bulk_propagator_job) << "Item completed" << item.destination () << item._status << item._instruction << item._error_string;

        handle_file_restoration (item, error_string);

        if (propagator ()._abort_requested && (item._status == SyncFileItem.Status.NORMAL_ERROR
                                              || item._status == SyncFileItem.Status.FATAL_ERROR)) {
            // an on_abort request is ongoing. Change the status to Soft-Error
            item._status = SyncFileItem.Status.SOFT_ERROR;
        }

        if (item._status != SyncFileItem.Status.SUCCESS) {
            // Blocklist handling
            handle_bulk_upload_block_list (item);
            propagator ()._another_sync_needed = true;
        }

        handle_job_done_errors (item, status);

        /* emit */ propagator ().item_completed (item);
    }

    GLib.HashMap<GLib.ByteArray, GLib.ByteArray> BulkPropagatorJob.headers (SyncFileItemPtr item) {
        GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers;
        headers[QByteArrayLiteral ("Content-Type")] = QByteArrayLiteral ("application/octet-stream");
        headers[QByteArrayLiteral ("X-File-Mtime")] = GLib.ByteArray.number (int64 (item._modtime));
        if (q_environment_variable_int_value ("OWNCLOUD_LAZYOPS")) {
            headers[QByteArrayLiteral ("OC-LazyOps")] = QByteArrayLiteral ("true");
        }

        if (item._file.contains (QLatin1String (".sys.admin#recall#"))) {
            // This is a file recall triggered by the admin.  Note: the
            // recall list file created by the admin and downloaded by the
            // client (.sys.admin#recall#) also falls into this category
            // (albeit users are not supposed to mess up with it)

            // We use a special tag header so that the server may decide to store this file away in some admin stage area
            // And not directly in the user's area (which would trigger redownloads etc).
            headers["OC-Tag"] = ".sys.admin#recall#";
        }

        if (!item._etag.is_empty () && item._etag != "empty_etag"
            && item._instruction != CSYNC_INSTRUCTION_NEW // On new files never send a If-Match
            && item._instruction != CSYNC_INSTRUCTION_TYPE_CHANGE) {
            // We add quotes because the owncloud server always adds quotes around the etag, and
            //  csync_owncloud.c's owncloud_file_id always strips the quotes.
            headers[QByteArrayLiteral ("If-Match")] = '"' + item._etag + '"';
        }

        // Set up a conflict file header pointing to the original file
        var conflict_record = propagator ()._journal.conflict_record (item._file.to_utf8 ());
        if (conflict_record.is_valid ()) {
            headers[QByteArrayLiteral ("OC-Conflict")] = "1";
            if (!conflict_record.initial_base_path.is_empty ()) {
                headers[QByteArrayLiteral ("OC-ConflictInitialBasePath")] = conflict_record.initial_base_path;
            }
            if (!conflict_record.base_file_id.is_empty ()) {
                headers[QByteArrayLiteral ("OC-ConflictBaseFileId")] = conflict_record.base_file_id;
            }
            if (conflict_record.base_modtime != -1) {
                headers[QByteArrayLiteral ("OC-ConflictBaseMtime")] = GLib.ByteArray.number (conflict_record.base_modtime);
            }
            if (!conflict_record.base_etag.is_empty ()) {
                headers[QByteArrayLiteral ("OC-ConflictBaseEtag")] = conflict_record.base_etag;
            }
        }

        return headers;
    }

    void BulkPropagatorJob.abort_with_error (SyncFileItemPtr item,
                                           SyncFileItem.Status status,
                                           const string error) {
        on_abort (AbortType.Synchronous);
        on_done (item, status, error);
    }

    void BulkPropagatorJob.check_resetting_errors (SyncFileItemPtr item) {
        if (item._http_error_code == 412
            || propagator ().account ().capabilities ().http_error_codes_that_reset_failing_chunked_uploads ().contains (item._http_error_code)) {
            var upload_info = propagator ()._journal.get_upload_info (item._file);
            upload_info._error_count += 1;
            if (upload_info._error_count > 3) {
                q_c_info (lc_bulk_propagator_job) << "Reset transfer of" << item._file
                                          << "due to repeated error" << item._http_error_code;
                upload_info = SyncJournalDb.UploadInfo ();
            } else {
                q_c_info (lc_bulk_propagator_job) << "Error count for maybe-reset error" << item._http_error_code
                                          << "on file" << item._file
                                          << "is" << upload_info._error_count;
            }
            propagator ()._journal.set_upload_info (item._file, upload_info);
            propagator ()._journal.commit ("Upload info");
        }
    }

    void BulkPropagatorJob.common_error_handling (SyncFileItemPtr item,
                                                const string error_message) {
        // Ensure errors that should eventually reset the chunked upload are tracked.
        check_resetting_errors (item);

        abort_with_error (item, SyncFileItem.Status.NORMAL_ERROR, error_message);
    }

    bool BulkPropagatorJob.check_file_still_exists (SyncFileItemPtr item,
                                                 const bool on_finished,
                                                 const string full_file_path) {
        if (!FileSystem.file_exists (full_file_path)) {
            if (!on_finished) {
                abort_with_error (item, SyncFileItem.Status.SOFT_ERROR, _("The local file was removed during sync."));
                return false;
            } else {
                propagator ()._another_sync_needed = true;
            }
        }

        return true;
    }

    bool BulkPropagatorJob.check_file_changed (SyncFileItemPtr item,
                                             const bool on_finished,
                                             const string full_file_path) {
        if (!FileSystem.verify_file_unchanged (full_file_path, item._size, item._modtime)) {
            propagator ()._another_sync_needed = true;
            if (!on_finished) {
                abort_with_error (item, SyncFileItem.Status.SOFT_ERROR, _("Local file changed during sync."));
                // FIXME :  the legacy code was retrying for a few seconds.
                //         and also checking that after the last chunk, and removed the file in case of INSTRUCTION_NEW
                return false;
            }
        }

        return true;
    }

    void BulkPropagatorJob.compute_file_id (SyncFileItemPtr item,
                                          const QJsonObject file_reply) {
        const var fid = get_header_from_json_reply (file_reply, "OC-FileID");
        if (!fid.is_empty ()) {
            if (!item._file_id.is_empty () && item._file_id != fid) {
                GLib.warn (lc_bulk_propagator_job) << "File ID changed!" << item._file_id << fid;
            }
            item._file_id = fid;
        }
    }

    void BulkPropagatorJob.handle_file_restoration (SyncFileItemPtr item,
                                                  const string error_string) {
        if (item._is_restoration) {
            if (item._status == SyncFileItem.Status.SUCCESS
                || item._status == SyncFileItem.Status.CONFLICT) {
                item._status = SyncFileItem.Status.RESTORATION;
            } else {
                item._error_string += _("; Restoration Failed : %1").arg (error_string);
            }
        } else {
            if (item._error_string.is_empty ()) {
                item._error_string = error_string;
            }
        }
    }

    void BulkPropagatorJob.handle_bulk_upload_block_list (SyncFileItemPtr item) {
        propagator ().add_to_bulk_upload_block_list (item._file);
    }

    void BulkPropagatorJob.handle_job_done_errors (SyncFileItemPtr item,
                                                SyncFileItem.Status status) {
        if (item.has_error_status ()) {
            GLib.warn (lc_propagator) << "Could not complete propagation of" << item.destination () << "by" << this << "with status" << item._status << "and error:" << item._error_string;
        } else {
            q_c_info (lc_propagator) << "Completed propagation of" << item.destination () << "by" << this << "with status" << item._status;
        }

        if (item._status == SyncFileItem.Status.FATAL_ERROR) {
            // Abort all remaining jobs.
            propagator ().on_abort ();
        }

        switch (item._status) {
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
            q_c_info (lc_bulk_propagator_job) << "modify final status NormalError" << this.final_status << status;
            break;
        case SyncFileItem.Status.DETAIL_ERROR:
            this.final_status = SyncFileItem.Status.DETAIL_ERROR;
            q_c_info (lc_bulk_propagator_job) << "modify final status DetailError" << this.final_status << status;
            break;
        case SyncFileItem.Status.SUCCESS:
            break;
        }
    }

    }
    