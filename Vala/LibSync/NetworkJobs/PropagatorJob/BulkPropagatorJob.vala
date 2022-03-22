namespace Occ {
namespace LibSync {

/***********************************************************
@class BulkPropagatorJob

@author Matthieu Gallien <matthieu.gallien@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class BulkPropagatorJob : AbstractPropagatorJob {

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
        unowned Account account;
        unowned SyncFileItem item;
        UploadFileInfo file_to_upload;
        string remote_path;
        string local_path;
        int64 file_size;
        GLib.HashTable<string, string> headers;
    }

    const int BATCH_SIZE = 100;
    const int PARALLEL_JOBS_MAXIMUM_COUNT = 1;

    /***********************************************************
    ***********************************************************/
    private GLib.List<BulkUploadItem?> files_to_upload;

    /***********************************************************
    ***********************************************************/
    private SyncFileItem.Status final_status = SyncFileItem.Status.NO_STATUS;

    /***********************************************************
    ***********************************************************/
    public BulkPropagatorJob (
        OwncloudPropagator propagator,
        GLib.Deque<unowned SyncFileItem> items) {
        base (propagator);
        this.items = items;
        this.files_to_upload.reserve (BATCH_SIZE);
        this.pending_checksum_files.reserve (BATCH_SIZE);
    }


    /***********************************************************
    ***********************************************************/
    public new bool on_signal_schedule_self_or_child () {
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
            GLib.Object.invoke_method (this, /*[this, current_item]*/ () => {
                UploadFileInfo file_to_upload;
                file_to_upload.file = current_item.file;
                file_to_upload.size = current_item.size;
                file_to_upload.path = this.propagator.full_local_path (file_to_upload.file);
                on_signal_start_upload_file (current_item, file_to_upload);
            }); // We could be in a different thread (neon jobs)
        }

        return this.items.empty () && this.files_to_upload.empty ();
    }


    /***********************************************************
    ***********************************************************/
    public new AbstractPropagatorJob.JobParallelism parallelism () {
        return AbstractPropagatorJob.JobParallelism.FULL_PARALLELISM;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_start_upload_file (SyncFileItem item, UploadFileInfo file_to_upload) {
        if (this.propagator.abort_requested) {
            return;
        }

        // Check if the specific file can be accessed
        if (this.propagator.has_case_clash_accessibility_problem (file_to_upload.file)) {
            on_signal_done (item, SyncFileItem.Status.NORMAL_ERROR, _("File %1 cannot be uploaded because another file with the same name, differing only in case, exists").printf (GLib.Dir.to_native_separators (item.file)));
            return;
        }

        on_signal_compute_transmission_checksum (item, file_to_upload);

        return;
    }



    /***********************************************************
    Content checksum computed, compute the transmission checksum
    ***********************************************************/
    private void on_signal_compute_transmission_checksum (
        SyncFileItem item,
        UploadFileInfo file_to_upload) {
        // Reuse the content checksum as the transmission checksum if possible
        var supported_transmission_checksums =
            this.propagator.account.capabilities.supported_checksum_types ();

        // Compute the transmission checksum.
        var compute_checksum = std.make_unique<ComputeChecksum> (this);
        if (upload_checksum_enabled ()) {
            compute_checksum.checksum_type ("MD5" /*this.propagator.account.capabilities.upload_checksum_type ()*/);
        } else {
            compute_checksum.checksum_type ("");
        }

        ComputeChecksum.signal_finished.connect (
            (compute_checksum, content_checksum_type, content_checksum) => {
                on_signal_start_upload (item, file_to_upload, content_checksum_type, content_checksum);
            }
        );
        ComputeChecksum.signal_finished.connect (
            compute_checksum,
            GLib.Object.delete_later
        );
        compute_checksum.release ().start (file_to_upload.path);
    }


    /***********************************************************
    Transmission checksum computed, prepare the upload
    ***********************************************************/
    private void on_signal_start_upload (
        SyncFileItem item,
        UploadFileInfo file_to_upload,
        string transmission_checksum_type,
        string transmission_checksum) {
        var transmission_checksum_header = make_checksum_header (transmission_checksum_type, transmission_checksum);

        item.checksum_header = transmission_checksum_header;

        const string full_file_path = file_to_upload.path;
        const string original_file_path = this.propagator.full_local_path (item.file);

        if (!FileSystem.file_exists (full_file_path)) {
            this.pending_checksum_files.remove (item.file);
            on_signal_error_start_folder_unlock (item, SyncFileItem.Status.SOFT_ERROR, _("File Removed (start upload) %1").printf (full_file_path));
            check_propagation_is_done ();
            return;
        }
        const time_t prev_modtime = item.modtime; // the this.item value was set in PropagateUploadFile.start ()
        // but a potential checksum calculation could have taken some time during which the file could
        // have been changed again, so better check again here.

        item.modtime = FileSystem.get_mod_time (original_file_path);
        if (item.modtime <= 0) {
            this.pending_checksum_files.remove (item.file);
            on_signal_error_start_folder_unlock (item, SyncFileItem.Status.NORMAL_ERROR, _("File %1 has invalid modified time. Do not upload to the server.").printf (GLib.Dir.to_native_separators (item.file)));
            check_propagation_is_done ();
            return;
        }
        if (prev_modtime != item.modtime) {
            this.propagator.another_sync_needed = true;
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
            this.propagator.another_sync_needed = true;
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
        SyncFileItem item,
        SyncFileItem.Status status,
        string error_string) {
        GLib.info (status + error_string);
        on_signal_done (item, status, error_string);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_put_finished () {
        var put_multi_file_job = qobject_cast<PutMultiFileJob> (sender ());
        GLib.assert (put_multi_file_job);

        on_signal_job_destroyed (put_multi_file_job); // remove it from the this.jobs list

        var reply_data = put_multi_file_job.input_stream.read_all ();
        var reply_json = QJsonDocument.from_json (reply_data);
        var full_reply_object = reply_json.object ();

        foreach (var single_file in this.files_to_upload) {
            if (!full_reply_object.contains (single_file.remote_path)) {
                continue;
            }
            var single_reply_object = full_reply_object[single_file.remote_path].to_object ();
            on_signal_put_finished_one_file (single_file, put_multi_file_job, single_reply_object);
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
        var result = this.propagator.update_metadata (*one_file.item);
        if (!result) {
            on_signal_done (one_file.item, SyncFileItem.Status.FATAL_ERROR, _("Error updating metadata : %1").printf (result.error));
            return;
        } else if (*result == AbstractVfs.ConvertToPlaceholderResult.Locked) {
            on_signal_done (one_file.item, SyncFileItem.Status.SOFT_ERROR, _("The file %1 is currently in use").printf (one_file.item.file));
            return;
        }

        // Files that were new on the remote shouldn't have online-only pin state
        // even if their parent folder is online-only.
        if (one_file.item.instruction == CSync.SyncInstructions.NEW
            || one_file.item.instruction == CSync.SyncInstructions.TYPE_CHANGE) {
            var vfs = this.propagator.sync_options.vfs;
            var pin = vfs.pin_state (one_file.item.file);
            if (pin && *pin == Common.ItemAvailability.ONLINE_ONLY && !vfs.pin_state (one_file.item.file, PinState.PinState.UNSPECIFIED)) {
                GLib.warning ("Could not set pin state of " + one_file.item.file + " to unspecified.");
            }
        }

        // Remove from the progress database:
        this.propagator.journal.upload_info (one_file.item.file, Common.SyncJournalDb.UploadInfo ());
        this.propagator.journal.commit ("upload file start");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_upload_progress (SyncFileItem item, int64 sent, int64 total) {
        // Completion is signaled with sent=0, total=0; avoid accidentally
        // resetting progress due to the sent being zero by ignoring it.
        // signal_finished () is bound to be emitted soon anyway.
        // See https://bugreports.qt.io/browse/QTBUG-44782.
        if (sent == 0 && total == 0) {
            return;
        }
        this.propagator.report_progress (item, sent - total);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_job_destroyed (GLib.Object any_job) {
        this.jobs.erase (std.remove (this.jobs.begin (), this.jobs.end (), any_job), this.jobs.end ());
    }


    /***********************************************************
    ***********************************************************/
    private void do_start_upload (
        SyncFileItem item,
        UploadFileInfo file_to_upload,
        string transmission_checksum_header) {
        if (this.propagator.abort_requested) {
            return;
        }

        // write the checksum in the database, so if the POST is sent
        // to the server, but the connection drops before we get the etag, we can check the checksum
        // in reconcile (issue #5106)
        Common.SyncJournalDb.UploadInfo pi;
        pi.valid = true;
        pi.chunk = 0;
        pi.transferid = 0; // We set a null transfer identifier because it is not chunked.
        pi.modtime = item.modtime;
        pi.error_count = 0;
        pi.content_checksum = item.checksum_header;
        pi.size = item.size;
        this.propagator.journal.upload_info (item.file, pi);
        this.propagator.journal.commit ("Upload info");

        var current_headers = headers (item);
        current_headers["Content-Length"] = new string.number (file_to_upload.size);

        if (!item.rename_target == "" && item.file != item.rename_target) {
            // Try to rename the file
            var original_file_path_absolute = this.propagator.full_local_path (item.file);
            var new_file_path_absolute = this.propagator.full_local_path (item.rename_target);
            var rename_success = GLib.File.rename (original_file_path_absolute, new_file_path_absolute);
            if (!rename_success) {
                on_signal_done (item, SyncFileItem.Status.NORMAL_ERROR, "File contains trailing spaces and couldn't be renamed");
                return;
            }
            GLib.warning (item.file + item.rename_target);
            file_to_upload.file = item.file = item.rename_target;
            file_to_upload.path = this.propagator.full_local_path (file_to_upload.file);
            item.modtime = FileSystem.get_mod_time (new_file_path_absolute);
            if (item.modtime <= 0) {
                this.pending_checksum_files.remove (item.file);
                on_signal_error_start_folder_unlock (item, SyncFileItem.Status.NORMAL_ERROR, _("File %1 has invalid modified time. Do not upload to the server.").printf (GLib.Dir.to_native_separators (item.file)));
                check_propagation_is_done ();
                return;
            }
        }

        var remote_path = this.propagator.full_remote_path (file_to_upload.file);

        current_headers["X-File-MD5"] = transmission_checksum_header;

        BulkUploadItem new_upload_file = BulkUploadItem (
            this.propagator.account,
            item,
            file_to_upload,
            remote_path, file_to_upload.path,
            file_to_upload.size, current_headers
        );

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
                    single_file.local_path, 0, single_file.file_size, this.propagator.bandwidth_manager);
            if (!device.open (QIODevice.ReadOnly)) {
                GLib.warning ("Could not prepare upload device: " + device.error_string);

                // If the file is currently locked, we want to retry the sync
                // when it becomes available again.
                if (FileSystem.is_file_locked (single_file.local_path)) {
                    /* emit */ this.propagator.seen_locked_file (single_file.local_path);
                }

                abort_with_error (single_file.item, SyncFileItem.Status.NORMAL_ERROR, device.error_string);
                /* emit */ signal_finished (SyncFileItem.Status.NORMAL_ERROR);

                return;
            }
            single_file.headers["X-File-Path"] = single_file.remote_path.to_utf8 ();
            upload_parameters_data.push_back ({std.move (device), single_file.headers});
            timeout += single_file.file_size;
        }

        var bulk_upload_url = Utility.concat_url_path (this.propagator.account.url, "/remote.php/dav/bulk");
        var put_multi_file_job = std.make_unique<PutMultiFileJob> (this.propagator.account, bulk_upload_url, std.move (upload_parameters_data), this);
        put_multi_file_job.signal_finished.connect (
            this.on_signal_put_finished
        );

        foreach (var single_file in this.files_to_upload) {
            put_multi_file_job.signal_upload_progress.connect (
                (single_file, sent, total) => {
                    on_signal_upload_progress (single_file.item, sent, total);
                }
            );
        }

        adjust_last_job_timeout (put_multi_file_job, timeout);
        this.jobs.append (put_multi_file_job);
        put_multi_file_job.release ().start ();
        if (parallelism () == AbstractPropagatorJob.JobParallelism.FULL_PARALLELISM && this.jobs.size () < PARALLEL_JOBS_MAXIMUM_COUNT) {
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
            /* emit */ signal_finished (this.final_status);
            this.propagator.schedule_next_job ();
        } else {
            on_signal_schedule_self_or_child ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void adjust_last_job_timeout (
        AbstractNetworkJob abstract_netowrk_job, int64 file_size) {
        const double three_minutes = 3.0 * 60 * 1000;

        abstract_netowrk_job.on_signal_timeout (q_bound (
            abstract_netowrk_job.timeout_msec (),
            // Calculate 3 minutes for each gigabyte of data
            q_round64 (three_minutes * static_cast<double> (file_size) / 1e9),
            // Maximum of 30 minutes
                            static_cast<int64> (30 * 60 * 1000)));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_put_finished_one_file (
        BulkUploadItem single_file,
        PutMultiFileJob put_multi_file_job,
        QJsonObject file_reply) {
        bool finished = false;

        GLib.info (single_file.item.file + " file headers " + file_reply);

        if (file_reply.contains ("error") && !file_reply["error"].to_bool ()) {
            single_file.item.http_error_code = (uint16) 200;
        } else {
            single_file.item.http_error_code = (uint16) 412;
        }

        single_file.item.response_time_stamp = put_multi_file_job.response_timestamp;
        single_file.item.request_id = put_multi_file_job.request_id ();
        if (single_file.item.http_error_code != 200) {
            common_error_handling (single_file.item, file_reply["message"].to_string ());
            return;
        }

        single_file.item.status = SyncFileItem.Status.SUCCESS;

        // Check the file again post upload.
        // Two cases must be considered separately : If the upload is finished,
        // the file is on the server and has a changed ETag. In that case,
        // the etag has to be properly updated in the client journal, and because
        // of that we can bail out here with an error. But we can reschedule a
        // sync ASAP.
        // But if the upload is ongoing, because not all chunks were uploaded
        // yet, the upload can be stopped and an error can be displayed, because
        // the server hasn't registered the new file yet.
        var etag = get_etag_from_json_reply (file_reply);
        finished = etag.length > 0;

        var full_file_path = this.propagator.full_local_path (single_file.item.file);

        // Check if the file still exists
        if (!check_file_still_exists (single_file.item, finished, full_file_path)) {
            return;
        }

        // Check whether the file changed since discovery. the file check here is the original and not the temporary.
        if (!check_file_changed (single_file.item, finished, full_file_path)) {
            return;
        }

        // the file identifier should only be empty for new files up- or downloaded
        compute_file_id (single_file.item, file_reply);

        single_file.item.etag = etag;

        if (get_header_from_json_reply (file_reply, "X-OC-MTime") != "accepted") {
            // X-OC-MTime is supported since owncloud 5.0.   But not when chunking.
            // Normally Owncloud 6 always puts X-OC-MTime
            GLib.warning ("Server does not support X-OC-MTime " + get_header_from_json_reply (file_reply, "X-OC-MTime"));
            // Well, the mtime was not set
        }
    }


    /***********************************************************
    ***********************************************************/
    private static string get_etag_from_json_reply (QJsonObject reply) {
        var oc_etag = parse_etag (reply.value ("OC-ETag").to_string ().to_latin1 ());
        var ETag = parse_etag (reply.value ("ETag").to_string ().to_latin1 ());
        var  etag = parse_etag (reply.value ("etag").to_string ().to_latin1 ());
        string ret = oc_etag;
        if (ret == "") {
            ret = ETag;
        }
        if (ret == "") {
            ret = etag;
        }
        if (oc_etag.length > 0 && oc_etag != etag && oc_etag != ETag) {
            GLib.debug ("Quite peculiar, we have an etag != OC-Etag [no problem!] " + etag + ETag + oc_etag);
        }
        return ret;
    }


    /***********************************************************
    ***********************************************************/
    private static string get_header_from_json_reply (QJsonObject reply, string header_name) {
        return reply.value (header_name).to_string ().to_latin1 ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_done (
        SyncFileItem item,
        SyncFileItem.Status status,
        string error_string) {
        item.status = status;
        item.error_string = error_string;

        GLib.info ("Item completed " + item.destination () + item.status + item.instruction + item.error_string);

        handle_file_restoration (item, error_string);

        if (this.propagator.abort_requested && (item.status == SyncFileItem.Status.NORMAL_ERROR
                                                || item.status == SyncFileItem.Status.FATAL_ERROR)) {
            // an abort request is ongoing. Change the status to Soft-Error
            item.status = SyncFileItem.Status.SOFT_ERROR;
        }

        if (item.status != SyncFileItem.Status.SUCCESS) {
            // Blocklist handling
            handle_bulk_upload_block_list (item);
            this.propagator.another_sync_needed = true;
        }

        handle_job_done_errors (item, status);

        /* emit */ this.propagator.signal_item_completed (item);
    }


    /***********************************************************
    Bases headers that need to be sent on the PUT, or in the MOVE for chunking-ng
    ***********************************************************/
    private GLib.HashTable<string, string> headers (SyncFileItem item) {
        GLib.HashTable<string, string> headers;
        headers["Content-Type"] = "application/octet-stream";
        headers["X-File-Mtime"] = new string.number (int64 (item.modtime));
        if (q_environment_variable_int_value ("OWNCLOUD_LAZYOPS")) {
            headers["OC-LazyOps"] = "true";
        }

        if (item.file.contains (".sys.admin#recall#")) {
            // This is a file recall triggered by the admin.  Note: the
            // recall list file created by the admin and downloaded by the
            // client (.sys.admin#recall#) also falls into this category
            // (albeit users are not supposed to mess up with it)

            // We use a special tag header so that the server may decide to store this file away in some admin stage area
            // And not directly in the user's area (which would trigger redownloads etc).
            headers["OC-Tag"] = ".sys.admin#recall#";
        }

        if (!item.etag == "" && item.etag != "empty_etag"
            && item.instruction != CSync.SyncInstructions.NEW // On new files never send a If-Match
            && item.instruction != CSync.SyncInstructions.TYPE_CHANGE) {
            // We add quotes because the owncloud server always adds quotes around the etag, and
            //  csync_owncloud.c's owncloud_file_id always strips the quotes.
            headers["If-Match"] = '"' + item.etag + '"';
        }

        // Set up a conflict file header pointing to the original file
        var conflict_record = this.propagator.journal.conflict_record (item.file.to_utf8 ());
        if (conflict_record.is_valid ()) {
            headers["OC-Conflict"] = "1";
            if (!conflict_record.initial_base_path == "") {
                headers["OC-ConflictInitialBasePath"] = conflict_record.initial_base_path;
            }
            if (!conflict_record.base_file_id == "") {
                headers["OC-ConflictBaseFileId"] = conflict_record.base_file_id;
            }
            if (conflict_record.base_modtime != -1) {
                headers["OC-ConflictBaseMtime"] = new string.number (conflict_record.base_modtime);
            }
            if (!conflict_record.base_etag == "") {
                headers["OC-ConflictBaseEtag"] = conflict_record.base_etag;
            }
        }

        return headers;
    }


    /***********************************************************
    ***********************************************************/
    private void abort_with_error (
        SyncFileItem item,
        SyncFileItem.Status status,
        string error) {
        abort (AbstractPropagatorJob.AbortType.SYNCHRONOUS);
        on_signal_done (item, status, error);
    }


    /***********************************************************
    Checks whether the current error is one that should reset
    the whole transfer if it happens too often. If so: Bump
    UploadInfo.error_count and maybe perform the reset.
    ***********************************************************/
    private void check_resetting_errors (SyncFileItem item) {
        if (item.http_error_code == 412
            || this.propagator.account.capabilities.http_error_codes_that_reset_failing_chunked_uploads ().contains (item.http_error_code)) {
            var upload_info = this.propagator.journal.get_upload_info (item.file);
            upload_info.error_count += 1;
            if (upload_info.error_count > 3) {
                GLib.info ("Reset transfer of " + item.file
                            + " due to repeated error " + item.http_error_code.to_string ());
                upload_info = Common.SyncJournalDb.UploadInfo ();
            } else {
                GLib.info ("Error count for maybe-reset error" + item.http_error_code
                        + "on file" + item.file
                        + "is" + upload_info.error_count);
            }
            this.propagator.journal.upload_info (item.file, upload_info);
            this.propagator.journal.commit ("Upload info");
        }
    }


    /***********************************************************
    Error handling functionality that is shared between jobs.
    ***********************************************************/
    private void common_error_handling (
        SyncFileItem item,
        string error_message) {
        // Ensure errors that should eventually reset the chunked upload are tracked.
        check_resetting_errors (item);

        abort_with_error (item, SyncFileItem.Status.NORMAL_ERROR, error_message);
    }


    /***********************************************************
    ***********************************************************/
    private bool check_file_still_exists (
        SyncFileItem item,
        bool finished,
        string full_file_path) {
        if (!FileSystem.file_exists (full_file_path)) {
            if (!finished) {
                abort_with_error (item, SyncFileItem.Status.SOFT_ERROR, _("The local file was removed during sync."));
                return false;
            } else {
                this.propagator.another_sync_needed = true;
            }
        }

        return true;
    }


    /***********************************************************
    ***********************************************************/
    private bool check_file_changed (
        SyncFileItem item,
        bool finished,
        string full_file_path) {
        if (!FileSystem.verify_file_unchanged (full_file_path, item.size, item.modtime)) {
            this.propagator.another_sync_needed = true;
            if (!finished) {
                abort_with_error (item, SyncFileItem.Status.SOFT_ERROR, _("Local file changed during sync."));
                // FIXME:  the legacy code was retrying for a few seconds.
                //         and also checking that after the last chunk, and removed the file in case of INSTRUCTION_NEW
                return false;
            }
        }

        return true;
    }


    /***********************************************************
    ***********************************************************/
    private void compute_file_id (
        SyncFileItem item,
        QJsonObject file_reply) {
        var fid = get_header_from_json_reply (file_reply, "OC-FileID");
        if (!fid == "") {
            if (!item.file_id == "" && item.file_id != fid) {
                GLib.warning ("File ID changed!" + item.file_id + fid);
            }
            item.file_id = fid;
        }
    }


    /***********************************************************
    ***********************************************************/
    private void handle_file_restoration (
        SyncFileItem item,
        string error_string) {
        if (item.is_restoration) {
            if (item.status == SyncFileItem.Status.SUCCESS
                || item.status == SyncFileItem.Status.CONFLICT) {
                item.status = SyncFileItem.Status.RESTORATION;
            } else {
                item.error_string += _("; Restoration Failed : %1").printf (error_string);
            }
        } else {
            if (item.error_string == "") {
                item.error_string = error_string;
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void handle_bulk_upload_block_list (SyncFileItem item) {
        this.propagator.add_to_bulk_upload_block_list (item.file);
    }


    /***********************************************************
    ***********************************************************/
    private void handle_job_done_errors (
        SyncFileItem item,
        SyncFileItem.Status status) {
        if (item.has_error_status ()) {
            GLib.warning ("Could not complete propagation of " + item.destination () + " by " + this.to_string () + " with status " + item.status + " and error: " + item.error_string);
        } else {
            GLib.info ("Completed propagation of " + item.destination () + " by " + this.to_string () + "with status " + item.status);
        }

        if (item.status == SyncFileItem.Status.FATAL_ERROR) {
            // Abort all remaining jobs.
            this.propagator.abort ();
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

} // namespace LibSync
} // namespace Occ
    