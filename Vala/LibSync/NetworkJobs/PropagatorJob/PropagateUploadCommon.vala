/***********************************************************
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@class PropagateUploadFileCommon

@brief The PropagateUploadFileCommon class is the code
common between all chunking algorithms.

State Machine:

  +--. start ()  -. (delete job) -------+
  |
  +-. on_signal_compute_co
                  |

   on_signal_co
        |
        v
   on_signal_compute_checksum_finished ()  . do_start_up
                                 .
                                 .
                                 v
       on_signal_finalize () or abort_with_error ()  or start_poll_job ()


@author Olivier Goffart <ogoffart@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PropagateUploadFileCommon : AbstractPropagateItemJob {

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
    protected GLib.List<AbstractNetworkJob> jobs;

    /***********************************************************
    Tells that all the jobs have been finished
    ***********************************************************/
    protected bool finished = BITFIELD (1);


    /***********************************************************
    Whether an existing entity with the same name may be deleted before
    the upload.

    delete_existing = BITFIELD (1);

    Default: false.
    ***********************************************************/
    bool delete_existing { public get; protected set; }


    /***********************************************************
    Whether an abort is currently ongoing.

    Important to avoid duplicate aborts since each finishing PUTFileJob might
    trigger an abort on error.
    ***********************************************************/
    protected bool aborting = BITFIELD (1);

    protected UploadFileInfo file_to_upload;
    protected string transmission_checksum_header;


    /***********************************************************
    ***********************************************************/
    private PropagateUploadEncrypted upload_encrypted_helper;
    private bool uploading_encrypted;
    private UploadStatus upload_status;

    /***********************************************************
    ***********************************************************/
    public PropagateUploadFileCommon (OwncloudPropagator propagator, SyncFileItem item) {
        base (propagator, item);
        this.finished = false;
        this.delete_existing = false;
        this.aborting = false;
        this.upload_encrypted_helper = null;
        this.uploading_encrypted = false;
        var path = this.item.file;
        var slash_position = path.last_index_of ("/");
        var parent_path = slash_position >= 0 ? path.left (slash_position): "";

        SyncJournalFileRecord parent_rec;
        bool ok = propagator.journal.get_file_record (parent_path, parent_rec);
        if (!ok) {
            return;
        }
    }


    /***********************************************************
    start should set up the file, path and size that will be send to the server
    ***********************************************************/
    public new void start () {
        var path = this.item.file;
        var slash_position = path.last_index_of ("/");
        var parent_path = slash_position >= 0 ? path.left (slash_position): "";

        if (!this.item.rename_target == "" && this.item.file != this.item.rename_target) {
            // Try to rename the file
            var original_file_path_absolute = this.propagator.full_local_path (this.item.file);
            var new_file_path_absolute = this.propagator.full_local_path (this.item.rename_target);
            var rename_success = GLib.File.rename (original_file_path_absolute, new_file_path_absolute);
            if (!rename_success) {
                on_signal_done (SyncFileItem.Status.NORMAL_ERROR, "File contains trailing spaces and couldn't be renamed");
                return;
            }
            this.item.file = this.item.rename_target;
            this.item.modtime = FileSystem.get_mod_time (new_file_path_absolute);
            GLib.assert (this.item.modtime > 0);
            if (this.item.modtime <= 0) {
                GLib.warning ("Invalid modified time " + this.item.file.to_string () + this.item.modtime.to_string ());
                on_signal_error_start_folder_unlock (SyncFileItem.Status.NORMAL_ERROR, _("File %1 has invalid modified time. Do not upload to the server.").printf (GLib.Dir.to_native_separators (this.item.file)));
                return;
            }
        }

        SyncJournalFileRecord parent_rec;
        bool ok = this.propagator.journal.get_file_record (parent_path, parent_rec);
        if (!ok) {
            on_signal_done (SyncFileItem.Status.NORMAL_ERROR);
            return;
        }

        var account = this.propagator.account;

        if (!account.capabilities.client_side_encryption_available () ||
            !parent_rec.is_valid ||
            !parent_rec.is_e2e_encrypted) {
            up_unencrypted_file ();
            return;
        }

        var remote_parent_path = parent_rec.e2e_mangled_name == "" ? parent_path : parent_rec.e2e_mangled_name;
        this.upload_encrypted_helper = new PropagateUploadEncrypted (this.propagator, remote_parent_path, this.item, this);
        this.upload_encrypted_helper.signal_finalized.connect (
            this.on_signal_upload_encrypted_helper_finalized
        );
        this.upload_encrypted_helper.signal_error.connect (
            this.on_signal_upload_encrypted_helper_error
        );
        this.upload_encrypted_helper.start ();
    }


    private void on_signal_upload_encrypted_helper_error () {
        GLib.debug ("Error setting up encryption.");
        on_signal_done (SyncFileItem.Status.FATAL_ERROR, _("Failed to upload encrypted file."));
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_upload_encrypted_helper_finalized (string path, string filename, uint64 size) {
        GLib.debug ("Starting to upload encrypted file " + path + filename + size.to_string ());
        this.uploading_encrypted = true;
        this.file_to_upload.path = path;
        this.file_to_upload.file = filename;
        this.file_to_upload.size = size;
        start_upload_file ();
    }


    /***********************************************************
    ***********************************************************/
    public void up_unencrypted_file () {
        this.uploading_encrypted = false;
        this.file_to_upload.file = this.item.file;
        this.file_to_upload.size = this.item.size;
        this.file_to_upload.path = this.propagator.full_local_path (this.file_to_upload.file);
        start_upload_file ();
    }

    /***********************************************************
    ***********************************************************/
    public void start_upload_file () {
        if (this.propagator.abort_requested) {
            return;
        }

        // Check if the specific file can be accessed
        if (this.propagator.has_case_clash_accessibility_problem (this.file_to_upload.file)) {
            on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("File %1 cannot be uploaded because another file with the same name, differing only in case, exists").printf (GLib.Dir.to_native_separators (this.item.file)));
            return;
        }

        // Check if we believe that the upload will fail due to remote quota limits
        int64 quota_guess = this.propagator.folder_quota.value (
            GLib.File.new_for_path (this.file_to_upload.file).path, std.numeric_limits<int64>.max ());
        if (this.file_to_upload.size > quota_guess) {
            // Necessary for blocklisting logic
            this.item.http_error_code = 507;
            /* emit */ this.propagator.signal_insufficient_remote_storage ();
            on_signal_done (SyncFileItem.Status.DETAIL_ERROR, _("Upload of %1 exceeds the quota for the folder").printf (Utility.octets_to_string (this.file_to_upload.size)));
            return;
        }

        this.propagator.active_job_list.append (this);

        if (!this.delete_existing) {
            GLib.debug ("Running the compute checksum.");
            return on_signal_delete_job_finished ();
        }

        GLib.debug ("Deleting the current.");
        var delete_job = new KeychainChunkDeleteJob (
            this.propagator.account,
            this.propagator.full_remote_path (this.file_to_upload.file),
            this
        );
        this.jobs.append (delete_job);
        delete_job.signal_finished.connect (
            this.on_signal_delete_job_finished
        );
        delete_job.destroyed.connect (
            this.on_signal_delete_job_destroyed
        );
        delete_job.start ();
    }

    /***********************************************************
    ***********************************************************/
    //  public void call_unlock_folder ();


    /***********************************************************
    ***********************************************************/
    public new bool is_likely_finished_quickly () {
        return this.item.size < this.propagator.small_file_size ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_delete_job_finished () {
        GLib.debug ("Trying to compute the checksum of the file.");
        GLib.debug ("Still trying to understand if this is the local file or the uploaded one.");
        if (this.propagator.abort_requested) {
            return;
        }

        string file_path = this.propagator.full_local_path (this.item.file);

        // remember the modtime before checksumming to be able to detect a file
        // change during the checksum calculation - This goes inside of the this.item.file
        // and not the this.file_to_upload because we are checking the original file, not there
        // probably temporary one.
        this.item.modtime = FileSystem.get_mod_time (file_path);
        if (this.item.modtime <= 0) {
            on_signal_error_start_folder_unlock (SyncFileItem.Status.NORMAL_ERROR, _("File %1 has invalid modified time. Do not upload to the server.").printf (GLib.Dir.to_native_separators (this.item.file)));
            return;
        }

        string checksum_type = this.propagator.account.capabilities.preferred_upload_checksum_type;

        // Maybe the discovery already computed the checksum?
        // Should I compute the checksum of the original (this.item.file)
        // or the maybe-modified? (this.file_to_upload.file) ?

        string existing_checksum_type, existing_checksum;
        parse_checksum_header (this.item.checksum_header, existing_checksum_type, existing_checksum);
        if (existing_checksum_type == checksum_type) {
            on_signal_compute_checksum_finished (checksum_type, existing_checksum);
            return;
        }

        // Compute the content checksum.
        var compute_checksum = new ComputeChecksum (this);
        compute_checksum.checksum_type (checksum_type);
        compute_checksum.signal_finished.connect (
            this.on_signal_compute_checksum_finished
        );
        compute_checksum.signal_finished.connect (
            compute_checksum.delete_later
        );
        compute_checksum.start (this.file_to_upload.path);
    }


    /***********************************************************
    Content checksum computed, compute the transmission checksum
    ***********************************************************/
    private void on_signal_compute_content_checksum_finished (string content_checksum_type, string content_checksum) {
        this.item.checksum_header = make_checksum_header (content_checksum_type, content_checksum);

        // Reuse the content checksum as the transmission checksum if possible
        var supported_transmission_checksums =
            this.propagator.account.capabilities.supported_checksum_types;
        if (supported_transmission_checksums.contains (content_checksum_type)) {
            on_signal_compute_checksum_finished (content_checksum_type, content_checksum);
            return;
        }

        // Compute the transmission checksum.
        var compute_checksum = new ComputeChecksum (this);
        if (upload_checksum_enabled ()) {
            compute_checksum.checksum_type (this.propagator.account.capabilities.upload_checksum_type);
        } else {
            compute_checksum.checksum_type ("");
        }

        compute_checksum.signal_finished.connect (
            this.on_signal_compute_checksum_finished
        );
        compute_checksum.signal_finished.connect (
            compute_checksum.delete_later
        );
        compute_checksum.start (this.file_to_upload.path);
    }


    /***********************************************************
    Transmission checksum computed, prepare the upload
    ***********************************************************/
    private void on_signal_compute_transmission_checksum_finished (string transmission_checksum_type, string transmission_checksum) {
        // Remove ourselfs from the list of active job, before any posible call to on_signal_done ()
        // When we start chunks, we will add it again, once for every chunks.
        this.propagator.active_job_list.remove_one (this);

        this.transmission_checksum_header = make_checksum_header (transmission_checksum_type, transmission_checksum);

        // If no checksum header was not set, reuse the transmission checksum as the content checksum.
        if (this.item.checksum_header == "") {
            this.item.checksum_header = this.transmission_checksum_header;
        }

        string original_file_path = this.propagator.full_local_path (this.item.file);

        if (!FileSystem.file_exists (this.file_to_upload.path)) {
            return on_signal_error_start_folder_unlock (SyncFileItem.Status.SOFT_ERROR, _("File Removed (start upload) %1").printf (this.file_to_upload.path));
        }
        if (this.item.modtime <= 0) {
            on_signal_error_start_folder_unlock (SyncFileItem.Status.NORMAL_ERROR, _("File %1 has invalid modified time. Do not upload to the server.").printf (GLib.Dir.to_native_separators (this.item.file)));
            return;
        }
        GLib.assert (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warning ("Invalid modified time " + this.item.file.to_string () + this.item.modtime.to_string ());
        }
        time_t prev_modtime = this.item.modtime; // the this.item value was set in PropagateUploadFile.start ()
        // but a potential checksum calculation could have taken some time during which the file could
        // have been changed again, so better check again here.

        this.item.modtime = FileSystem.get_mod_time (original_file_path);
        if (this.item.modtime <= 0) {
            on_signal_error_start_folder_unlock (SyncFileItem.Status.NORMAL_ERROR, _("File %1 has invalid modified time. Do not upload to the server.").printf (GLib.Dir.to_native_separators (this.item.file)));
            return;
        }
        GLib.assert (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warning ("Invalid modified time " + this.item.file.to_string () + this.item.modtime.to_string ());
        }
        if (prev_modtime != this.item.modtime) {
            this.propagator.another_sync_needed = true;
            GLib.debug ("Previous modtime: " + prev_modtime.to_string () + " current modtime: " + this.item.modtime.to_string ());
            return on_signal_error_start_folder_unlock (SyncFileItem.Status.SOFT_ERROR, _("Local file changed during syncing. It will be resumed."));
        }

        this.file_to_upload.size = FileSystem.get_size (this.file_to_upload.path);
        this.item.size = FileSystem.get_size (original_file_path);

        // But skip the file if the mtime is too close to 'now'!
        // That usually indicates a file that is still being changed
        // or not yet fully copied to the destination.
        if (file_is_still_changing (*this.item)) {
            this.propagator.another_sync_needed = true;
            return on_signal_error_start_folder_unlock (SyncFileItem.Status.SOFT_ERROR, _("Local file changed during sync."));
        }

        do_start_upload ();
    }


    /***********************************************************
    Invoked when encrypted folder lock has been released
    ***********************************************************/
    private void on_signal_upload_encrypted_helper_folder_unlocked (string folder_identifier, int http_return_code) {
        GLib.debug ("Failed to unlock encrypted folder " + folder_identifier);
        if (this.upload_status.status == SyncFileItem.Status.NO_STATUS && http_return_code != 200) {
            on_signal_done (SyncFileItem.Status.FATAL_ERROR, _("Failed to unlock encrypted folder."));
        } else {
            on_signal_done (this.upload_status.status, this.upload_status.message);
        }
    }


    /***********************************************************
    Invoked on internal error to unlock a folder and faile
    ***********************************************************/
    private void on_signal_error_start_folder_unlock (SyncFileItem.Status status, string error_string) {
        if (this.uploading_encrypted) {
            this.upload_status = new UploadStatus (
                status, error_string
            );
            this.upload_encrypted_helper.signal_folder_unlocked.connect (
                this.on_signal_upload_encrypted_helper_folder_unlocked
            );
            this.upload_encrypted_helper.unlock_folder ();
        } else {
            on_signal_done (status, error_string);
        }
    }


    /***********************************************************
    ***********************************************************/
    public virtual void do_start_upload ();


    /***********************************************************
    ***********************************************************/
    public void start_poll_job (string path) {
        var poll_job = new PollJob (
            this.propagator.account, path, this.item,
            this.propagator.journal, this.propagator.local_path, this
        );
        poll_job.signal_finished.connect (
            this.on_signal_poll_job_finished
        );
        Common.SyncJournalDb.PollInfo info;
        info.file = this.item.file;
        info.url = path;
        info.modtime = this.item.modtime;
        GLib.assert (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warning ("Invalid modified time " + this.item.file.to_string () + this.item.modtime.to_string ());
        }
        info.file_size = this.item.size;
        this.propagator.journal.poll_info (info);
        this.propagator.journal.commit ("add poll info");
        this.propagator.active_job_list.append (this);
        poll_job.start ();
    }


    /***********************************************************
    This function is used whenever there is an error occuring
    and jobs might be in progress
    ***********************************************************/
    public void abort_with_error (SyncFileItem.Status status, string error) {
        if (this.aborting) {
            return;
        }
        abort (AbstractPropagatorJob.AbortType.SYNCHRONOUS);
        on_signal_done (status, error);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_delete_job_destroyed (GLib.Object abstract_job) {
        this.jobs.erase (std.remove (this.jobs.begin (), this.jobs.end (), abstract_job), this.jobs.end ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_poll_job_finished () {
        var poll_job = (PollJob)sender ();
        //  ASSERT (poll_job);

        this.propagator.active_job_list.remove_one (this);

        if (poll_job.item.status != SyncFileItem.Status.SUCCESS) {
            on_signal_done (poll_job.item.status, poll_job.item.error_string);
            return;
        }

        on_signal_finalize ();
    }



    void on_signal_finalize () {
        // Update the quota, if known
        var quota_it = this.propagator.folder_quota.find (GLib.File.new_for_path (this.item.file).path);
        if (quota_it != this.propagator.folder_quota.end ())
            quota_it.value () -= this.file_to_upload.size;

        // Update the database entry
        var result = this.propagator.update_metadata (*this.item);
        if (!result) {
            on_signal_done (SyncFileItem.Status.FATAL_ERROR, _("Error updating metadata : %1").printf (result.error));
            return;
        } else if (*result == AbstractVfs.ConvertToPlaceholderResult.Locked) {
            on_signal_done (SyncFileItem.Status.SOFT_ERROR, _("The file %1 is currently in use").printf (this.item.file));
            return;
        }

        // Files that were new on the remote shouldn't have online-only pin state
        // even if their parent folder is online-only.
        if (this.item.instruction == CSync.SyncInstructions.NEW
            || this.item.instruction == CSync.SyncInstructions.TYPE_CHANGE) {
            var vfs = this.propagator.sync_options.vfs;
            var pin = vfs.pin_state (this.item.file);
            if (pin && *pin == Common.ItemAvailability.ONLINE_ONLY) {
                if (!vfs.pin_state (this.item.file, PinState.PinState.UNSPECIFIED)) {
                    GLib.warning ("Could not set pin state of " + this.item.file + " to unspecified");
                }
            }
        }

        // Remove from the progress database:
        this.propagator.journal.upload_info (this.item.file, Common.SyncJournalDb.UploadInfo ());
        this.propagator.journal.commit ("upload file start");

        if (this.uploading_encrypted) {
            this.upload_status = new UploadStatus (
                SyncFileItem.Status.SUCCESS,
                ""
            );
            this.upload_encrypted_helper.signal_folder_unlocked.connect (
                this.on_signal_upload_encrypted_helper_folder_unlocked
            );
            this.upload_encrypted_helper.unlock_folder ();
        } else {
            on_signal_done (SyncFileItem.Status.SUCCESS);
        }
    }


    /***********************************************************
    ***********************************************************/
    protected new void on_signal_done (SyncFileItem.Status status, string error_string = "") {
        this.finished = true;
        AbstractPropagateItemJob.on_signal_done (status, error_string);
    }


    private delegate bool MayAbortJob (AbstractNetworkJob abstract_job);

    /***********************************************************
    Aborts all running network jobs, except for the ones that may_abort_job
    returns false on and, for async aborts, emits signal_abort_finished when done.
    ***********************************************************/
    protected void abort_network_jobs (
        AbstractPropagatorJob.AbortType abort_type,
        MayAbortJob may_abort_job) {
        if (this.aborting) {
            return;
        }
        this.aborting = true;

        // Count the number of jobs that need aborting, and emit the overall
        // abort signal when they're all done.
        unowned int running_count = 0;

        // Abort all running jobs, except for explicitly excluded ones
        foreach (AbstractNetworkJob abstract_job in this.jobs) {
            var input_stream = abstract_job.input_stream;
            if (!input_stream || !input_stream.is_running ())
                continue;

            (*running_count)++;

            // If a job should not be aborted that means we'll never abort before
            // the hard abort timeout signal comes as running_count will never go to
            // zero.
            // We may however finish before that if the un-abortable job completes
            // normally.
            if (!may_abort_job (abstract_job))
                continue;

            // Abort the job
            if (abort_type == AbstractPropagatorJob.AbortType.ASYNCHRONOUS) {
                // Connect to on_signal_finished signal of job input_stream to asynchonously finish the abort
                input_stream.signal_finished.connect (
                    this.one_abort_finished
                );
            }
            input_stream.abort ();
        }

        if (*running_count == 0 && abort_type == AbstractPropagatorJob.AbortType.ASYNCHRONOUS)
            /* emit */ signal_abort_finished ();
    }


    private int one_abort_finished (int running_count) {
        int count_copy = running_count - 1;
        if (count_copy == 0) {
            /* emit */ this.signal_abort_finished ();
        }
        return count_copy;
    }


    /***********************************************************
    Checks whether the current error is one that should reset the whole
    transfer if it happens too often. If so : Bump UploadInfo.error_count
    and maybe perform the reset.
    ***********************************************************/
    protected void check_resetting_errors () {
        if (this.item.http_error_code == 412
            || this.propagator.account.capabilities.http_error_codes_that_reset_failing_chunked_uploads.contains (this.item.http_error_code)) {
            var upload_info = this.propagator.journal.get_upload_info (this.item.file);
            upload_info.error_count += 1;
            if (upload_info.error_count > 3) {
                GLib.info (
                    "Reset transfer of " + this.item.file.to_string ()
                    + " due to repeated error " + this.item.http_error_code.to_string ());
                upload_info = Common.SyncJournalDb.UploadInfo ();
            } else {
                GLib.info (
                    "Error count for maybe-reset error " + this.item.http_error_code.to_string ()
                    + " on file " + this.item.file.to_string ()
                    + " is " + upload_info.error_count.to_string ()
                );
            }
            this.propagator.journal.upload_info (this.item.file, upload_info);
            this.propagator.journal.commit ("Upload info");
        }
    }


    /***********************************************************
    Error handling functionality that is shared between jobs.
    ***********************************************************/
    protected void common_error_handling (AbstractNetworkJob abstract_job) {
        string reply_content;
        string error_string = abstract_job.error_string_parsing_body (reply_content);
        GLib.debug (reply_content.to_string ()); // display the XML error in the debug

        if (this.item.http_error_code == 412) {
            // Precondition Failed : Either an etag or a checksum mismatch.

            // Maybe the bad etag is in the database, we need to clear the
            // parent folder etag so we won't read from DB next sync.
            this.propagator.journal.schedule_path_for_remote_discovery (this.item.file);
            this.propagator.another_sync_needed = true;
        }

        // Ensure errors that should eventually reset the chunked upload are tracked.
        check_resetting_errors ();

        SyncFileItem.Status status = classify_error (abstract_job.input_stream ().error, this.item.http_error_code,
            this.propagator.another_sync_needed, reply_content);

        // Insufficient remote storage.
        if (this.item.http_error_code == 507) {
            // Update the quota expectation
            // store the quota for the real local file using the information
            // on the file to upload, that could have been modified by
            // filters or something.
            var path = GLib.File.new_for_path (this.item.file).path;
            var quota_it = this.propagator.folder_quota.find (path);
            if (quota_it != this.propagator.folder_quota.end ()) {
                quota_it.value () = q_min (quota_it.value (), this.file_to_upload.size - 1);
            } else {
                this.propagator.folder_quota[path] = this.file_to_upload.size - 1;
            }

            // Set up the error
            status = SyncFileItem.Status.DETAIL_ERROR;
            error_string = _("Upload of %1 exceeds the quota for the folder").printf (Utility.octets_to_string (this.file_to_upload.size));
            /* emit */ this.propagator.signal_insufficient_remote_storage ();
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
    protected static void adjust_last_job_timeout (AbstractNetworkJob abstract_job, int64 file_size) {
        double three_minutes = 3.0 * 60 * 1000;

        abstract_job.on_signal_timeout (
            int64.max (
                abstract_job.timeout_msec (),
                int64.min (
                    // Calculate 3 minutes for each gigabyte of data
                    GLib.Math.llrint (three_minutes * file_size / 1e9),
                    // Maximum of 30 minutes
                    (int64)(30 * 60 * 1000))
                )
            );
    }


    /***********************************************************
    Bases headers that need to be sent on the PUT, or in the MOVE for chunking-ng
    ***********************************************************/
    protected GLib.HashTable<string, string> headers () {
        GLib.HashTable<string, string> headers;
        headers["Content-Type"] = "application/octet-stream";
        GLib.assert (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warning ("Invalid modified time " + this.item.file.to_string () + this.item.modtime.to_string ());
        }
        headers["X-OC-Mtime"] = ((int64) (this.item.modtime)).to_string ();
        if (q_environment_variable_int_value ("OWNCLOUD_LAZYOPS"))
            headers["OC-LazyOps"] = "true";

        if (this.item.file.contains (".sys.admin#recall#")) {
            // This is a file recall triggered by the admin.  Note: the
            // recall list file created by the admin and downloaded by the
            // client (.sys.admin#recall#) also falls into this category
            // (albeit users are not supposed to mess up with it)

            // We use a special tag header so that the server may decide to store this file away in some admin stage area
            // And not directly in the user's area (which would trigger redownloads etc).
            headers["OC-Tag"] = ".sys.admin#recall#";
        }

        if (!this.item.etag == "" && this.item.etag != "empty_etag"
            && this.item.instruction != CSync.SyncInstructions.NEW // On new files never send a If-Match
            && this.item.instruction != CSync.SyncInstructions.TYPE_CHANGE
            && !this.delete_existing) {
            // We add quotes because the owncloud server always adds quotes around the etag, and
            //  csync_owncloud.c's owncloud_file_id always strips the quotes.
            headers["If-Match"] = "\"" + this.item.etag + "\"";
        }

        // Set up a conflict file header pointing to the original file
        var conflict_record = this.propagator.journal.conflict_record (this.item.file.to_utf8 ());
        if (conflict_record.is_valid) {
            headers["OC-Conflict"] = "1";
            if (!conflict_record.initial_base_path == "")
                headers["OC-ConflictInitialBasePath"] = conflict_record.initial_base_path;
            if (!conflict_record.base_file_id == "")
                headers["OC-ConflictBaseFileId"] = conflict_record.base_file_id;
            if (conflict_record.base_modtime != -1)
                headers["OC-ConflictBaseMtime"] = new string.number (conflict_record.base_modtime);
            if (!conflict_record.base_etag == "")
                headers["OC-ConflictBaseEtag"] = conflict_record.base_etag;
        }

        if (this.upload_encrypted_helper && !this.upload_encrypted_helper.folder_token () == "") {
            headers.insert ("e2e-token", this.upload_encrypted_helper.folder_token ());
        }

        return headers;
    }

} // class PropagateUploadFileCommon

} // namespace LibSync
} // namespace Occ
