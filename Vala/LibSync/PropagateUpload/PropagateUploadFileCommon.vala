/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

//  Q_DECLARE_LOGGING_CATEGORY (lc_propagate_upload)
/***********************************************************
@brief The PropagateUploadFileCommon class is the code common between all chunking algorithms
@ingroup libsync

State Machine:

  +--. on_start ()  -. (delete job) -------+
  |
  +-. on_compute_co
                  |

   on_co
        |
        v
   on_start_upload ()  . do_start_up
                                 .
                                 .
                                 v
       on_finalize () or abort_with_error ()  or start_poll_job ()
***********************************************************/
class PropagateUploadFileCommon : PropagateItemJob {

    struct UploadStatus {
        SyncFileItem.Status status = SyncFileItem.Status.NO_STATUS;
        string message;
    }


    /***********************************************************
    This is a minified version of the SyncFileItem,
    that holds only the specifics about the file that's
    being uploaded.

    This is needed if we wanna apply changes on the file
    that's being uploaded while keeping the original on disk.
    ***********************************************************/
    protected struct UploadFileInfo {
        /***********************************************************
        I'm still unsure if I should use a SyncFilePtr here.
        ***********************************************************/
        string file; 

        /***********************************************************
        The full path on disk
        ***********************************************************/
        string path;


        int64 size;
    }

    /***********************************************************
    Network jobs that are currently in transit
    ***********************************************************/
    protected GLib.Vector<AbstractNetworkJob> jobs;

    /***********************************************************
    Tells that all the jobs have been finished
    ***********************************************************/
    protected bool finished = BITFIELD (1);


    protected bool delete_existing = BITFIELD (1);


    /***********************************************************
    Whether an on_abort is currently ongoing.

    Important to avoid duplicate aborts since each finishing PUTFile_job might
    trigger an on_abort on error.
    ***********************************************************/
    protected bool aborting = BITFIELD (1);

    protected UploadFileInfo file_to_upload;
    protected GLib.ByteArray transmission_checksum_header;


    /***********************************************************
    ***********************************************************/
    private PropagateUploadEncrypted upload_encrypted_helper;
    private bool uploading_encrypted;
    private UploadStatus upload_status;

    /***********************************************************
    ***********************************************************/
    public PropagateUploadFileCommon (OwncloudPropagator propagator, SyncFileItemPtr item) {
        base (propagator, item);
        this.finished = false;
        this.delete_existing = false;
        this.aborting = false;
        this.upload_encrypted_helper = null;
        this.uploading_encrypted = false;
        const var path = this.item.file;
        const var slash_position = path.last_index_of ('/');
        const var parent_path = slash_position >= 0 ? path.left (slash_position) : "";

        SyncJournalFileRecord parent_rec;
        bool ok = propagator.journal.get_file_record (parent_path, parent_rec);
        if (!ok) {
            return;
        }
    }


    /***********************************************************
    Whether an existing entity with the same name may be deleted before
    the upload.

    Default: false.
    ***********************************************************/
    public void set_delete_existing (bool enabled) {
        this.delete_existing = enabled;
    }


    /***********************************************************
    on_start should set up the file, path and size that will be send to the server
    ***********************************************************/
    public void on_start () {
        const var path = this.item.file;
        const var slash_position = path.last_index_of ('/');
        const var parent_path = slash_position >= 0 ? path.left (slash_position) : "";

        if (!this.item.rename_target.is_empty () && this.item.file != this.item.rename_target) {
            // Try to rename the file
            const var original_file_path_absolute = propagator ().full_local_path (this.item.file);
            const var new_file_path_absolute = propagator ().full_local_path (this.item.rename_target);
            const var rename_success = GLib.File.rename (original_file_path_absolute, new_file_path_absolute);
            if (!rename_success) {
                on_done (SyncFileItem.Status.NORMAL_ERROR, "File contains trailing spaces and couldn't be renamed");
                return;
            }
            this.item.file = this.item.rename_target;
            this.item.modtime = FileSystem.get_mod_time (new_file_path_absolute);
            //  Q_ASSERT (this.item.modtime > 0);
            if (this.item.modtime <= 0) {
                GLib.warn (lc_propagate_upload ()) << "invalid modified time" << this.item.file << this.item.modtime;
                on_error_start_folder_unlock (SyncFileItem.Status.NORMAL_ERROR, _("File %1 has invalid modified time. Do not upload to the server.").arg (QDir.to_native_separators (this.item.file)));
                return;
            }
        }

        SyncJournalFileRecord parent_rec;
        bool ok = propagator ().journal.get_file_record (parent_path, parent_rec);
        if (!ok) {
            on_done (SyncFileItem.Status.NORMAL_ERROR);
            return;
        }

        const var account = propagator ().account ();

        if (!account.capabilities ().client_side_encryption_available () ||
            !parent_rec.is_valid () ||
            !parent_rec.is_e2e_encrypted) {
            set_up_unencrypted_file ();
            return;
        }

        const var remote_parent_path = parent_rec.e2e_mangled_name.is_empty () ? parent_path : parent_rec.e2e_mangled_name;
        this.upload_encrypted_helper = new PropagateUploadEncrypted (propagator (), remote_parent_path, this.item, this);
        connect (this.upload_encrypted_helper, &PropagateUploadEncrypted.finalized,
                this, &PropagateUploadFileCommon.setup_encrypted_file);
        connect (this.upload_encrypted_helper, &PropagateUploadEncrypted.error, [this] {
            GLib.debug (lc_propagate_upload) << "Error setting up encryption.";
            on_done (SyncFileItem.Status.FATAL_ERROR, _("Failed to upload encrypted file."));
        });
        this.upload_encrypted_helper.on_start ();
    }


    /***********************************************************
    ***********************************************************/
    public void setup_encrypted_file (string path, string filename, uint64 size) {
        GLib.debug (lc_propagate_upload) << "Starting to upload encrypted file" << path << filename << size;
        this.uploading_encrypted = true;
        this.file_to_upload.path = path;
        this.file_to_upload.file = filename;
        this.file_to_upload.size = size;
        start_upload_file ();
    }


    /***********************************************************
    ***********************************************************/
    public void set_up_unencrypted_file () {
        this.uploading_encrypted = false;
        this.file_to_upload.file = this.item.file;
        this.file_to_upload.size = this.item.size;
        this.file_to_upload.path = propagator ().full_local_path (this.file_to_upload.file);
        start_upload_file ();
    }

    /***********************************************************
    ***********************************************************/
    public void start_upload_file () {
        if (propagator ().abort_requested) {
            return;
        }

        // Check if the specific file can be accessed
        if (propagator ().has_case_clash_accessibility_problem (this.file_to_upload.file)) {
            on_done (SyncFileItem.Status.NORMAL_ERROR, _("File %1 cannot be uploaded because another file with the same name, differing only in case, exists").arg (QDir.to_native_separators (this.item.file)));
            return;
        }

        // Check if we believe that the upload will fail due to remote quota limits
        const int64 quota_guess = propagator ().folder_quota.value (
            QFileInfo (this.file_to_upload.file).path (), std.numeric_limits<int64>.max ());
        if (this.file_to_upload.size > quota_guess) {
            // Necessary for blocklisting logic
            this.item.http_error_code = 507;
            /* emit */ propagator ().insufficient_remote_storage ();
            on_done (SyncFileItem.Status.DETAIL_ERROR, _("Upload of %1 exceeds the quota for the folder").arg (Utility.octets_to_string (this.file_to_upload.size)));
            return;
        }

        propagator ().active_job_list.append (this);

        if (!this.delete_existing) {
            GLib.debug () << "Running the compute checksum";
            return on_compute_content_checksum ();
        }

        GLib.debug () << "Deleting the current";
        var job = new DeleteJob (propagator ().account (),
            propagator ().full_remote_path (this.file_to_upload.file),
            this);
        this.jobs.append (job);
        connect (job, &DeleteJob.finished_signal, this, &PropagateUploadFileCommon.on_compute_content_checksum);
        connect (job, &GLib.Object.destroyed, this, &PropagateUploadFileCommon.on_job_destroyed);
        job.on_start ();
    }

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void call_unlock_folder ();


    /***********************************************************
    ***********************************************************/
    public bool is_likely_finished_quickly () {
        return this.item.size < propagator ().small_file_size ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_compute_content_checksum () {
        GLib.debug () << "Trying to compute the checksum of the file";
        GLib.debug () << "Still trying to understand if this is the local file or the uploaded one";
        if (propagator ().abort_requested) {
            return;
        }

        const string file_path = propagator ().full_local_path (this.item.file);

        // remember the modtime before checksumming to be able to detect a file
        // change during the checksum calculation - This goes inside of the this.item.file
        // and not the this.file_to_upload because we are checking the original file, not there
        // probably temporary one.
        this.item.modtime = FileSystem.get_mod_time (file_path);
        if (this.item.modtime <= 0) {
            on_error_start_folder_unlock (SyncFileItem.Status.NORMAL_ERROR, _("File %1 has invalid modified time. Do not upload to the server.").arg (QDir.to_native_separators (this.item.file)));
            return;
        }

        const GLib.ByteArray checksum_type = propagator ().account ().capabilities ().preferred_upload_checksum_type ();

        // Maybe the discovery already computed the checksum?
        // Should I compute the checksum of the original (this.item.file)
        // or the maybe-modified? (this.file_to_upload.file) ?

        GLib.ByteArray existing_checksum_type, existing_checksum;
        parse_checksum_header (this.item.checksum_header, existing_checksum_type, existing_checksum);
        if (existing_checksum_type == checksum_type) {
            on_compute_transmission_checksum (checksum_type, existing_checksum);
            return;
        }

        // Compute the content checksum.
        var compute_checksum = new ComputeChecksum (this);
        compute_checksum.set_checksum_type (checksum_type);

        connect (compute_checksum, &ComputeChecksum.done,
            this, &PropagateUploadFileCommon.on_compute_transmission_checksum);
        connect (compute_checksum, &ComputeChecksum.done,
            compute_checksum, &GLib.Object.delete_later);
        compute_checksum.on_start (this.file_to_upload.path);
    }


    /***********************************************************
    Content checksum computed, compute the transmission checksum
    ***********************************************************/
    private void on_compute_transmission_checksum (GLib.ByteArray content_checksum_type, GLib.ByteArray content_checksum) {
        this.item.checksum_header = make_checksum_header (content_checksum_type, content_checksum);

        // Reuse the content checksum as the transmission checksum if possible
        const var supported_transmission_checksums =
            propagator ().account ().capabilities ().supported_checksum_types ();
        if (supported_transmission_checksums.contains (content_checksum_type)) {
            on_start_upload (content_checksum_type, content_checksum);
            return;
        }

        // Compute the transmission checksum.
        var compute_checksum = new ComputeChecksum (this);
        if (upload_checksum_enabled ()) {
            compute_checksum.set_checksum_type (propagator ().account ().capabilities ().upload_checksum_type ());
        } else {
            compute_checksum.set_checksum_type (GLib.ByteArray ());
        }

        connect (compute_checksum, &ComputeChecksum.done,
            this, &PropagateUploadFileCommon.on_start_upload);
        connect (compute_checksum, &ComputeChecksum.done,
            compute_checksum, &GLib.Object.delete_later);
        compute_checksum.on_start (this.file_to_upload.path);
    }


    /***********************************************************
    Transmission checksum computed, prepare the upload
    ***********************************************************/
    private void on_start_upload (GLib.ByteArray transmission_checksum_type, GLib.ByteArray transmission_checksum) {
        // Remove ourselfs from the list of active job, before any posible call to on_done ()
        // When we on_start chunks, we will add it again, once for every chunks.
        propagator ().active_job_list.remove_one (this);

        this.transmission_checksum_header = make_checksum_header (transmission_checksum_type, transmission_checksum);

        // If no checksum header was not set, reuse the transmission checksum as the content checksum.
        if (this.item.checksum_header.is_empty ()) {
            this.item.checksum_header = this.transmission_checksum_header;
        }

        const string full_file_path = this.file_to_upload.path;
        const string original_file_path = propagator ().full_local_path (this.item.file);

        if (!FileSystem.file_exists (full_file_path)) {
            return on_error_start_folder_unlock (SyncFileItem.Status.SOFT_ERROR, _("File Removed (on_start upload) %1").arg (full_file_path));
        }
        if (this.item.modtime <= 0) {
            on_error_start_folder_unlock (SyncFileItem.Status.NORMAL_ERROR, _("File %1 has invalid modified time. Do not upload to the server.").arg (QDir.to_native_separators (this.item.file)));
            return;
        }
        //  Q_ASSERT (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warn (lc_propagate_upload ()) << "invalid modified time" << this.item.file << this.item.modtime;
        }
        time_t prev_modtime = this.item.modtime; // the this.item value was set in PropagateUploadFile.on_start ()
        // but a potential checksum calculation could have taken some time during which the file could
        // have been changed again, so better check again here.

        this.item.modtime = FileSystem.get_mod_time (original_file_path);
        if (this.item.modtime <= 0) {
            on_error_start_folder_unlock (SyncFileItem.Status.NORMAL_ERROR, _("File %1 has invalid modified time. Do not upload to the server.").arg (QDir.to_native_separators (this.item.file)));
            return;
        }
        //  Q_ASSERT (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warn (lc_propagate_upload ()) << "invalid modified time" << this.item.file << this.item.modtime;
        }
        if (prev_modtime != this.item.modtime) {
            propagator ().another_sync_needed = true;
            GLib.debug () << "prev_modtime" << prev_modtime << "Curr" << this.item.modtime;
            return on_error_start_folder_unlock (SyncFileItem.Status.SOFT_ERROR, _("Local file changed during syncing. It will be resumed."));
        }

        this.file_to_upload.size = FileSystem.get_size (full_file_path);
        this.item.size = FileSystem.get_size (original_file_path);

        // But skip the file if the mtime is too close to 'now'!
        // That usually indicates a file that is still being changed
        // or not yet fully copied to the destination.
        if (file_is_still_changing (*this.item)) {
            propagator ().another_sync_needed = true;
            return on_error_start_folder_unlock (SyncFileItem.Status.SOFT_ERROR, _("Local file changed during sync."));
        }

        do_start_upload ();
    }


    /***********************************************************
    Invoked when encrypted folder lock has been released
    ***********************************************************/
    private void on_folder_unlocked (GLib.ByteArray folder_identifier, int http_return_code) {
        GLib.debug () << "Failed to unlock encrypted folder" << folder_identifier;
        if (this.upload_status.status == SyncFileItem.Status.NO_STATUS && http_return_code != 200) {
            on_done (SyncFileItem.Status.FATAL_ERROR, _("Failed to unlock encrypted folder."));
        } else {
            on_done (this.upload_status.status, this.upload_status.message);
        }
    }


    /***********************************************************
    Invoked on internal error to unlock a folder and faile
    ***********************************************************/
    private void on_error_start_folder_unlock (SyncFileItem.Status status, string error_string) {
        if (this.uploading_encrypted) {
            this.upload_status = {
                status, error_string
            };
            connect (this.upload_encrypted_helper, &PropagateUploadEncrypted.folder_unlocked, this, &PropagateUploadFileCommon.on_folder_unlocked);
            this.upload_encrypted_helper.unlock_folder ();
        } else {
            on_done (status, error_string);
        }
    }


    /***********************************************************
    ***********************************************************/
    public virtual void do_start_upload ();


    /***********************************************************
    ***********************************************************/
    public void start_poll_job (string path) {
        var job = new PollJob (propagator ().account (), path, this.item,
            propagator ().journal, propagator ().local_path (), this);
        connect (job, &PollJob.finished_signal, this, &PropagateUploadFileCommon.on_poll_finished);
        SyncJournalDb.PollInfo info;
        info.file = this.item.file;
        info.url = path;
        info.modtime = this.item.modtime;
        //  Q_ASSERT (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warn (lc_propagate_upload ()) << "invalid modified time" << this.item.file << this.item.modtime;
        }
        info.file_size = this.item.size;
        propagator ().journal.set_poll_info (info);
        propagator ().journal.commit ("add poll info");
        propagator ().active_job_list.append (this);
        job.on_start ();
    }

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void abort_with_error (SyncFileItem.Status status, string error);
    // This function is used whenever there is an error occuring and jobs might be in progress
    void PropagateUploadFileCommon.abort_with_error (SyncFileItem.Status status, string error) {
        if (this.aborting)
            return;
        on_abort (AbortType.SYNCHRONOUS);
        on_done (status, error);
    }


    /***********************************************************
    ***********************************************************/
    public void on_job_destroyed (GLib.Object job) {
        this.jobs.erase (std.remove (this.jobs.begin (), this.jobs.end (), job), this.jobs.end ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_poll_finished () {
        var job = qobject_cast<PollJob> (sender ());
        ASSERT (job);

        propagator ().active_job_list.remove_one (this);

        if (job.item.status != SyncFileItem.Status.SUCCESS) {
            on_done (job.item.status, job.item.error_string);
            return;
        }

        on_finalize ();
    }



    void on_finalize () {
        // Update the quota, if known
        var quota_it = propagator ().folder_quota.find (QFileInfo (this.item.file).path ());
        if (quota_it != propagator ().folder_quota.end ())
            quota_it.value () -= this.file_to_upload.size;

        // Update the database entry
        const var result = propagator ().update_metadata (*this.item);
        if (!result) {
            on_done (SyncFileItem.Status.FATAL_ERROR, _("Error updating metadata : %1").arg (result.error ()));
            return;
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            on_done (SyncFileItem.Status.SOFT_ERROR, _("The file %1 is currently in use").arg (this.item.file));
            return;
        }

        // Files that were new on the remote shouldn't have online-only pin state
        // even if their parent folder is online-only.
        if (this.item.instruction == CSYNC_INSTRUCTION_NEW
            || this.item.instruction == CSYNC_INSTRUCTION_TYPE_CHANGE) {
            var vfs = propagator ().sync_options ().vfs;
            const var pin = vfs.pin_state (this.item.file);
            if (pin && *pin == PinState.VfsItemAvailability.ONLINE_ONLY) {
                if (!vfs.set_pin_state (this.item.file, PinState.PinState.UNSPECIFIED)) {
                    GLib.warn (lc_propagate_upload) << "Could not set pin state of" << this.item.file << "to unspecified";
                }
            }
        }

        // Remove from the progress database:
        propagator ().journal.set_upload_info (this.item.file, SyncJournalDb.UploadInfo ());
        propagator ().journal.commit ("upload file on_start");

        if (this.uploading_encrypted) {
            this.upload_status = {
                SyncFileItem.Status.SUCCESS, ""
            };
            connect (this.upload_encrypted_helper, &PropagateUploadEncrypted.folder_unlocked, this, &PropagateUploadFileCommon.on_folder_unlocked);
            this.upload_encrypted_helper.unlock_folder ();
        } else {
            on_done (SyncFileItem.Status.SUCCESS);
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_done (SyncFileItem.Status status, string error_string = "") {
        this.finished = true;
        PropagateItemJob.on_done (status, error_string);
    }


    /***********************************************************
    Aborts all running network jobs, except for the ones that may_abort_job
    returns false on and, for async aborts, emits abort_finished when done.
    ***********************************************************/
    protected void abort_network_jobs (
        AbortType abort_type,
        std.function<bool (AbstractNetworkJob job)> may_abort_job) {
        if (this.aborting)
            return;
        this.aborting = true;

        // Count the number of jobs that need aborting, and emit the overall
        // on_abort signal when they're all done.
        unowned<int> running_count (new int (0));
        var one_abort_finished = [this, running_count] () {
            (*running_count)--;
            if (*running_count == 0) {
                /* emit */ this.abort_finished ();
            }
        };

        // Abort all running jobs, except for explicitly excluded ones
        foreach (AbstractNetworkJob job, this.jobs) {
            var reply = job.reply ();
            if (!reply || !reply.is_running ())
                continue;

            (*running_count)++;

            // If a job should not be aborted that means we'll never on_abort before
            // the hard on_abort timeout signal comes as running_count will never go to
            // zero.
            // We may however finish before that if the un-abortable job completes
            // normally.
            if (!may_abort_job (job))
                continue;

            // Abort the job
            if (abort_type == AbortType.ASYNCHRONOUS) {
                // Connect to on_finished signal of job reply to asynchonously finish the on_abort
                connect (reply, &Soup.Reply.on_finished, this, one_abort_finished);
            }
            reply.on_abort ();
        }

        if (*running_count == 0 && abort_type == AbortType.ASYNCHRONOUS)
            /* emit */ abort_finished ();
    }


    /***********************************************************
    Checks whether the current error is one that should reset the whole
    transfer if it happens too often. If so : Bump UploadInfo.error_count
    and maybe perform the reset.
    ***********************************************************/
    protected void check_resetting_errors () {
        if (this.item.http_error_code == 412
            || propagator ().account ().capabilities ().http_error_codes_that_reset_failing_chunked_uploads ().contains (this.item.http_error_code)) {
            var upload_info = propagator ().journal.get_upload_info (this.item.file);
            upload_info.error_count += 1;
            if (upload_info.error_count > 3) {
                GLib.Info (lc_propagate_upload) << "Reset transfer of" << this.item.file
                                          << "due to repeated error" << this.item.http_error_code;
                upload_info = SyncJournalDb.UploadInfo ();
            } else {
                GLib.Info (lc_propagate_upload) << "Error count for maybe-reset error" << this.item.http_error_code
                                          << "on file" << this.item.file
                                          << "is" << upload_info.error_count;
            }
            propagator ().journal.set_upload_info (this.item.file, upload_info);
            propagator ().journal.commit ("Upload info");
        }
    }


    /***********************************************************
    Error handling functionality that is shared between jobs.
    ***********************************************************/
    protected void common_error_handling (AbstractNetworkJob job) {
        GLib.ByteArray reply_content;
        string error_string = job.error_string_parsing_body (&reply_content);
        GLib.debug (lc_propagate_upload) << reply_content; // display the XML error in the debug

        if (this.item.http_error_code == 412) {
            // Precondition Failed : Either an etag or a checksum mismatch.

            // Maybe the bad etag is in the database, we need to clear the
            // parent folder etag so we won't read from DB next sync.
            propagator ().journal.schedule_path_for_remote_discovery (this.item.file);
            propagator ().another_sync_needed = true;
        }

        // Ensure errors that should eventually reset the chunked upload are tracked.
        check_resetting_errors ();

        SyncFileItem.Status status = classify_error (job.reply ().error (), this.item.http_error_code,
            propagator ().another_sync_needed, reply_content);

        // Insufficient remote storage.
        if (this.item.http_error_code == 507) {
            // Update the quota expectation
            // store the quota for the real local file using the information
            // on the file to upload, that could have been modified by
            // filters or something.
            const var path = QFileInfo (this.item.file).path ();
            var quota_it = propagator ().folder_quota.find (path);
            if (quota_it != propagator ().folder_quota.end ()) {
                quota_it.value () = q_min (quota_it.value (), this.file_to_upload.size - 1);
            } else {
                propagator ().folder_quota[path] = this.file_to_upload.size - 1;
            }

            // Set up the error
            status = SyncFileItem.Status.DETAIL_ERROR;
            error_string = _("Upload of %1 exceeds the quota for the folder").arg (Utility.octets_to_string (this.file_to_upload.size));
            /* emit */ propagator ().insufficient_remote_storage ();
        }

        abort_with_error (status, error_string);
    }


    /***********************************************************
    Increases the timeout for the final MOVE/PUT for large files.

    This is an unfortunate workaround since the drawback is not being able to
    detect real disconnects in a timely manner. Shall go away when the s
    response starts coming quicker, or there is some sort of async api.

    See #6527, enterprise#2480
    ***********************************************************/
    protected static void adjust_last_job_timeout (AbstractNetworkJob job, int64 file_size) {
        const double three_minutes = 3.0 * 60 * 1000;

        job.on_set_timeout (q_bound (
            job.timeout_msec (),
            // Calculate 3 minutes for each gigabyte of data
            q_round64 (three_minutes * file_size / 1e9),
            // Maximum of 30 minutes
            static_cast<int64> (30 * 60 * 1000)));
    }


    /***********************************************************
    Bases headers that need to be sent on the PUT, or in the MOVE for chunking-ng
    ***********************************************************/
    protected GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers () {
        GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers;
        headers[QByteArrayLiteral ("Content-Type")] = QByteArrayLiteral ("application/octet-stream");
        //  Q_ASSERT (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warn (lc_propagate_upload ()) << "invalid modified time" << this.item.file << this.item.modtime;
        }
        headers[QByteArrayLiteral ("X-OC-Mtime")] = GLib.ByteArray.number (int64 (this.item.modtime));
        if (q_environment_variable_int_value ("OWNCLOUD_LAZYOPS"))
            headers[QByteArrayLiteral ("OC-LazyOps")] = QByteArrayLiteral ("true");

        if (this.item.file.contains (QLatin1String (".sys.admin#recall#"))) {
            // This is a file recall triggered by the admin.  Note: the
            // recall list file created by the admin and downloaded by the
            // client (.sys.admin#recall#) also falls into this category
            // (albeit users are not supposed to mess up with it)

            // We use a special tag header so that the server may decide to store this file away in some admin stage area
            // And not directly in the user's area (which would trigger redownloads etc).
            headers["OC-Tag"] = ".sys.admin#recall#";
        }

        if (!this.item.etag.is_empty () && this.item.etag != "empty_etag"
            && this.item.instruction != CSYNC_INSTRUCTION_NEW // On new files never send a If-Match
            && this.item.instruction != CSYNC_INSTRUCTION_TYPE_CHANGE
            && !this.delete_existing) {
            // We add quotes because the owncloud server always adds quotes around the etag, and
            //  csync_owncloud.c's owncloud_file_id always strips the quotes.
            headers[QByteArrayLiteral ("If-Match")] = '"' + this.item.etag + '"';
        }

        // Set up a conflict file header pointing to the original file
        var conflict_record = propagator ().journal.conflict_record (this.item.file.to_utf8 ());
        if (conflict_record.is_valid ()) {
            headers[QByteArrayLiteral ("OC-Conflict")] = "1";
            if (!conflict_record.initial_base_path.is_empty ())
                headers[QByteArrayLiteral ("OC-ConflictInitialBasePath")] = conflict_record.initial_base_path;
            if (!conflict_record.base_file_id.is_empty ())
                headers[QByteArrayLiteral ("OC-ConflictBaseFileId")] = conflict_record.base_file_id;
            if (conflict_record.base_modtime != -1)
                headers[QByteArrayLiteral ("OC-ConflictBaseMtime")] = GLib.ByteArray.number (conflict_record.base_modtime);
            if (!conflict_record.base_etag.is_empty ())
                headers[QByteArrayLiteral ("OC-ConflictBaseEtag")] = conflict_record.base_etag;
        }

        if (this.upload_encrypted_helper && !this.upload_encrypted_helper.folder_token ().is_empty ()) {
            headers.insert ("e2e-token", this.upload_encrypted_helper.folder_token ());
        }

        return headers;
    }

} // class PropagateUploadFileCommon

} // namespace Occ
