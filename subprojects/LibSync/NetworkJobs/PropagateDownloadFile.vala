namespace Occ {
namespace LibSync {

/***********************************************************
@brief The PropagateDownloadFile class
@ingroup libsync

This is the flow:

\code{.unparsed}
  start ()
    |
    | delete_existing_folder () if enabled
    |
    +-. mtime and size identical?
    |    then compute the local checksum
    |                               done?. on_signal_conflict_checksum_computed ()
    |                                              |
    |                         checksum differs?    |
    +. on_signal_start_download () <--------------------------+
          |                                        |
          +. run a GETFileJob                     | checksum identical?
                                                   |
      done?. on_signal_get_file_job_finished ()                    |
                |                                  |
                +. validate checksum header       |
                                                   |
      done?. on_signal_validate_checksum_header_validated ()      |
                |                                  |
                +. compute the content checksum   |
                                                   |
      done?. on_signal_compute_checksum_done ()            |
                |                                  |
                +. on_signal_download_finished ()             |
                       |                           |
    +------------------+                           |
    |                                              |
    +. update_metadata () <-------------------------+

\endcode

@author Olivier Goffart <ogoffart@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PropagateDownloadFile : AbstractPropagateItemJob {

    const string OWNCLOUD_CUSTOM_SOFT_ERROR_STRING_C = "owncloud-custom-soft-error-string";

    /***********************************************************
    ***********************************************************/
    private int64 resume_start;
    private int64 download_progress;
    private GETFileJob get_file_job;
    private GLib.File temporary_file;

    /***********************************************************
    Whether an existing folder with the same name may be deleted before
    the download.

    If it's a non-empty folder, it'll be renamed to a confl
    to preserve any non-synced content that may be inside.

    Default: false.
    ***********************************************************/
    bool delete_existing { private get; public set; }

    private bool is_encrypted = false;
    private EncryptedFile encrypted_info;
    private ConflictRecord conflict_record;

    /***********************************************************
    ***********************************************************/
    private GLib.Timer stopwatch;

    /***********************************************************
    ***********************************************************/
    private PropagateDownloadEncrypted download_encrypted_helper = null;

    /***********************************************************
    ***********************************************************/
    public PropagateDownloadFile (OwncloudPropagator propagator, SyncFileItem item) {
        base (propagator, item);
        this.resume_start = 0;
        this.download_progress = 0;
        this.delete_existing = false;
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        if (this.propagator.abort_requested)
            return;
        this.is_encrypted = false;

        GLib.debug (this.item.file + this.propagator.active_job_list.length);

        var path = this.item.file;
        var slash_position = path.last_index_of ("/");
        var parent_path = slash_position >= 0 ? path.left (slash_position): "";

        SyncJournalFileRecord parent_rec;
        this.propagator.journal.get_file_record (parent_path, parent_rec);

        var account = this.propagator.account;
        if (!account.capabilities.client_side_encryption_available ||
            !parent_rec.is_valid ||
            !parent_rec.is_e2e_encrypted) {
            start_after_is_encrypted_is_checked ();
        } else {
            this.download_encrypted_helper = new PropagateDownloadEncrypted (this.propagator, parent_path, this.item, this);
            this.download_encrypted_helper.signal_file_metadata_found.connect (
                () => {
                    this.is_encrypted = true;
                    start_after_is_encrypted_is_checked ();
                }
            );
            this.download_encrypted_helper.signal_failed.connect (
                () => {
                    on_signal_done (
                        SyncFileItem.Status.NORMAL_ERROR,
                        _("File %1 cannot be downloaded because encryption information is missing.")
                            .printf (GLib.Dir.to_native_separators (this.item.file))
                    );
                }
            );
            this.download_encrypted_helper.start ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public new int64 committed_disk_space () {
        if (this.state == Running) {
            return q_bound (0LL, this.item.size - this.resume_start - this.download_progress, this.item.size);
        }
        return 0;
    }


    /***********************************************************
    We think it might finish quickly because it is a small file.
    ***********************************************************/
    public new bool is_likely_finished_quickly () {
        return this.item.size < this.propagator.small_file_size ();
    }


    /***********************************************************
    ***********************************************************/
    void delete_existing_folder () {
        string existing_dir = this.propagator.full_local_path (this.item.file);
        if (!GLib.File.new_for_path (existing_dir).query_info ().get_file_type () == FileType.DIRECTORY) {
            return;
        }

        // Delete the directory if it is empty!
        GLib.Dir directory = new GLib.Dir (existing_dir);
        if (directory.entry_list (GLib.Dir.NoDotAndDotDot | GLib.Dir.AllEntries).length == 0) {
            if (directory.rmdir (existing_dir)) {
                return;
            }
            // on error, just try to move it away...
        }

        string error;
        if (!this.propagator.create_conflict (this.item, this.associated_composite, error)) {
            on_signal_done (SyncFileItem.Status.NORMAL_ERROR, error);
        }
    }



    /***********************************************************
    Called when ComputeChecksum on the local file finishes,
    maybe the local and remote checksums are identical?
    ***********************************************************/
    private void on_signal_conflict_checksum_computed (string checksum_type, string checksum) {
        this.propagator.active_job_list.remove_one (this);
        if (make_checksum_header (checksum_type, checksum) == this.item.checksum_header) {
            // No download necessary, just update fs and journal metadata
            GLib.debug (this.item.file + "remote and local checksum match");

            // Apply the server mtime locally if necessary, ensuring the journal
            // and local mtimes end up identical
            var filename = this.propagator.full_local_path (this.item.file);
            GLib.assert (this.item.modtime > 0);
            if (this.item.modtime <= 0) {
                GLib.warning ("invalid modified time" + this.item.file.to_string () + this.item.modtime.to_string ());
                return;
            }
            if (this.item.modtime != this.item.previous_modtime) {
                GLib.assert (this.item.modtime > 0);
                FileSystem.mod_time (filename, this.item.modtime);
                this.propagator.signal_touched_file (filename);
            }
            this.item.modtime = FileSystem.get_mod_time (filename);
            GLib.assert (this.item.modtime > 0);
            if (this.item.modtime <= 0) {
                GLib.warning ("Invalid modified time " + this.item.file.to_string () + this.item.modtime.to_string ());
                return;
            }
            update_metadata (/*is_conflict=*/false);
            return;
        }
        on_signal_start_download ();
    }


    /***********************************************************
    Called to start downloading the remote file
    ***********************************************************/
    private void on_signal_start_download () {
        if (this.propagator.abort_requested)
            return;

        // do a klaas' case clash check.
        if (this.propagator.local_filename_clash (this.item.file)) {
            on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("File %1 cannot be downloaded because of a local file name clash!").printf (GLib.Dir.to_native_separators (this.item.file)));
            return;
        }

        this.propagator.report_progress (this.item, 0);

        string temporary_filename;
        string expected_etag_for_resume;
        Common.SyncJournalDb.DownloadInfo progress_info = this.propagator.journal.get_download_info (this.item.file);
        if (progress_info.valid) {
            // if the etag has changed meanwhile, remove the already downloaded part.
            if (progress_info.etag != this.item.etag) {
                FileSystem.remove (this.propagator.full_local_path (progress_info.temporaryfile));
                this.propagator.journal.download_info (this.item.file, Common.SyncJournalDb.DownloadInfo ());
            } else {
                temporary_filename = progress_info.temporaryfile;
                expected_etag_for_resume = progress_info.etag;
            }
        }

        if (temporary_filename == "") {
            temporary_filename = create_download_temporary_filename (this.item.file);
        }
        this.temporary_file.filename (this.propagator.full_local_path (temporary_filename));

        this.resume_start = this.temporary_file.size ();
        if (this.resume_start > 0 && this.resume_start == this.item.size) {
            GLib.info ("File is already complete, no need to download");
            on_signal_download_finished ();
            return;
        }

        // Can't open (Append) read-only files, make sure to make
        // file writable if it exists.
        if (this.temporary_file.exists ())
            FileSystem.file_read_only (this.temporary_file.filename (), false);
        if (!this.temporary_file.open (GLib.IODevice.Append | GLib.IODevice.Unbuffered)) {
            GLib.warning ("could not open temporary file" + this.temporary_file.filename ());
            on_signal_done (SyncFileItem.Status.NORMAL_ERROR, this.temporary_file.error_string);
            return;
        }

        // If there's not enough space to fully download this file, stop.
        var disk_space_result = this.propagator.disk_space_check ();
        if (disk_space_result != OwncloudPropagator.DiskSpaceResult.OK) {
            if (disk_space_result == OwncloudPropagator.DiskSpaceResult.FAILURE) {
                // Using DetailError here will make the error not pop up in the account
                // tab : instead we'll generate a general "disk space low" message and show
                // these detail errors only in the error view.
                on_signal_done (SyncFileItem.Status.DETAIL_ERROR,
                    _("The download would reduce free local disk space below the limit"));
                this.propagator.signal_insufficient_local_storage ();
            } else if (disk_space_result == OwncloudPropagator.DiskSpaceResult.CRITICAL) {
                on_signal_done (SyncFileItem.Status.FATAL_ERROR,
                    _("Free space on disk is less than %1").printf (Utility.octets_to_string (critical_free_space_limit ())));
            }

            // Remove the temporary, if empty.
            if (this.resume_start == 0) {
                this.temporary_file.remove ();
            }

            return;
        }
    {
            Common.SyncJournalDb.DownloadInfo pi;
            pi.etag = this.item.etag;
            pi.temporaryfile = temporary_filename;
            pi.valid = true;
            this.propagator.journal.download_info (this.item.file, pi);
            this.propagator.journal.commit ("download file start");
        }

        GLib.HashTable<string, string> headers;

        if (this.item.direct_download_url == "") {
            // Normal job, download from o_c instance
            this.get_file_job = new GETFileJob (this.propagator.account,
                this.propagator.full_remote_path (this.is_encrypted ? this.item.encrypted_filename : this.item.file),
                this.temporary_file, headers, expected_etag_for_resume, this.resume_start, this);
        } else {
            // We were provided a direct URL, use that one
            GLib.info ("direct_download_url given for " + this.item.file + this.item.direct_download_url);

            if (this.item.direct_download_cookies != "") {
                headers["Cookie"] = this.item.direct_download_cookies.to_utf8 ();
            }

            GLib.Uri url = GLib.Uri.from_user_input (this.item.direct_download_url);
            this.get_file_job = new GETFileJob (this.propagator.account,
                url,
                this.temporary_file, headers, expected_etag_for_resume, this.resume_start, this);
        }
        this.get_file_job.bandwidth_manager = this.propagator.bandwidth_manager;
        this.get_file_job.signal_finished.connect (
            this.on_signal_get_file_job_finished
        );
        this.get_file_job.signal_download_progress.connect (
            this.on_signal_get_file_job_download_progress
        );
        this.propagator.active_job_list.append (this);
        this.get_file_job.start ();
    }


    /***********************************************************
    Called when the GETFileJob finishes
    ***********************************************************/
    private void on_signal_get_file_job_finished () {
        this.propagator.active_job_list.remove_one (this);

        GETFileJob get_file_job = this.get_file_job;
        //  GLib.assert_true (get_file_job);

        this.item.http_error_code = get_file_job.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        this.item.request_id = get_file_job.request_id ();

        GLib.InputStream.NetworkError err = get_file_job.input_stream.error;
        if (err != GLib.InputStream.NoError) {
            // If we sent a 'Range' header and get 416 back, we want to retry
            // without the header.
            bool bad_range_header = get_file_job.resume_start > 0 && this.item.http_error_code == 416;
            if (bad_range_header) {
                GLib.warning ("Server replied 416 to our range request, trying again without.");
                this.propagator.another_sync_needed = true;
            }

            // Getting a 404 probably means that the file was deleted on the server.
            bool file_not_found = this.item.http_error_code == 404;
            if (file_not_found) {
                GLib.warning ("Server replied 404, assuming file was deleted.");
            }

            // Getting a 423 means that the file is locked
            bool file_locked = this.item.http_error_code == 423;
            if (file_locked) {
                GLib.warning ("Server replied 423, file is locked.");
            }

            // Don't keep the temporary file if it is empty or we
            // used a bad range header or the file's not on the server anymore.
            if (this.temporary_file.exists () && (this.temporary_file.size () == 0 || bad_range_header || file_not_found)) {
                this.temporary_file.close ();
                FileSystem.remove (this.temporary_file.filename ());
                this.propagator.journal.download_info (this.item.file, Common.SyncJournalDb.DownloadInfo ());
            }

            if (this.item.direct_download_url != "" && err != GLib.InputStream.OperationCanceledError) {
                // If this was with a direct download, retry without direct download
                GLib.warning ("Direct download of" + this.item.direct_download_url + " failed. Retrying through owncloud.");
                this.item.direct_download_url = "";
                start ();
                return;
            }

            // This gives a custom Soup.Session (by the user of libowncloudsync) to abort () a GLib.InputStream in its meta_data_changed () slot and
            // set a custom error string to make this a soft error. In contrast to the default hard error this won't bring down
            // the whole sync and allows for a custom error message.
            GLib.InputStream reply = get_file_job.input_stream;
            if (err == GLib.InputStream.OperationCanceledError && reply.property (OWNCLOUD_CUSTOM_SOFT_ERROR_STRING_C).is_valid) {
                get_file_job.on_signal_error_string (reply.property (OWNCLOUD_CUSTOM_SOFT_ERROR_STRING_C).to_string ());
                get_file_job.error_status = SyncFileItem.Status.SOFT_ERROR;
            } else if (bad_range_header) {
                // Can't do this in classify_error () because 416 without a
                // Range header should result in NormalError.
                get_file_job.error_status = SyncFileItem.Status.SOFT_ERROR;
            } else if (file_not_found) {
                get_file_job.on_signal_error_string (_("File was deleted from server"));
                get_file_job.error_status = SyncFileItem.Status.SOFT_ERROR;

                // As a precaution against bugs that cause our database and the
                // reality on the server to diverge, rediscover this folder on the
                // next sync run.
                this.propagator.journal.schedule_path_for_remote_discovery (this.item.file);
            }

            string error_body;
            string error_string = this.item.http_error_code >= 400 ? get_file_job.error_string_parsing_body (error_body)
                                                            : get_file_job.error_string;
            SyncFileItem.Status status = get_file_job.error_status;
            if (status == SyncFileItem.Status.NO_STATUS) {
                status = classify_error (err, this.item.http_error_code,
                    this.propagator.another_sync_needed, error_body);
            }

            on_signal_done (status, error_string);
            return;
        }

        this.item.response_time_stamp = get_file_job.response_timestamp;

        if (get_file_job.etag != "") {
            // The etag will be empty if we used a direct download URL.
            // (If it was really empty by the server, the GETFileJob will have errored
            this.item.etag = parse_etag (get_file_job.etag ());
        }
        if (get_file_job.last_modified) {
            // It is possible that the file was modified on the server since we did the discovery phase
            // so make sure we have the up-to-date time
            this.item.modtime = get_file_job.last_modified;
            GLib.assert (this.item.modtime > 0);
            if (this.item.modtime <= 0) {
                GLib.warning ("Invalid modified time: " + this.item.file.to_string () + this.item.modtime.to_string ());
            }
        }

        this.temporary_file.close ();
        this.temporary_file.flush ();

        /* Check that the size of the GET reply matches the file size. There have been cases
        reported that if a server breaks behind a proxy, the GET is still a 200 but is
        truncated, as described here : https://github.com/owncloud/mirall/issues/2528
        ***********************************************************/
        string size_header = "Content-Length";
        int64 body_size = get_file_job.input_stream.raw_header (size_header).to_long_long ();
        bool has_size_header = !get_file_job.input_stream.raw_header (size_header) = "";

        // Qt removes the content-length header for transparently decompressed HTTP1 replies
        // but not for HTTP2 or SPDY replies. For these it remains and contains the size
        // of the compressed data. See GLib.TBUG-73364.
        var content_encoding = get_file_job.input_stream.raw_header ("content-encoding").down ();
        if ( (content_encoding == "gzip" || content_encoding == "deflate")
            && (get_file_job.input_stream.attribute (Soup.Request.HTTP2WasUsedAttribute).to_bool ()
            || get_file_job.input_stream.attribute (Soup.Request.Spdy_was_used_attribute).to_bool ())) {
            body_size = 0;
            has_size_header = false;
        }

        if (has_size_header && this.temporary_file.size () > 0 && body_size == 0) {
            // Strange bug with broken webserver or webfirewall https://github.com/owncloud/client/issues/3373#issuecomment-122672322
            // This happened when trying to resume a file. The Content-Range header was files, Content-Length was == 0
            GLib.debug (body_size + this.item.size + this.temporary_file.size () + get_file_job.resume_start);
            FileSystem.remove (this.temporary_file.filename ());
            on_signal_done (SyncFileItem.Status.SOFT_ERROR, "Broken webserver returning empty content length for non-empty file on resume");
            return;
        }

        if (body_size > 0 && body_size != this.temporary_file.size () - get_file_job.resume_start) {
            GLib.debug (body_size + this.temporary_file.size () + get_file_job.resume_start);
            this.propagator.another_sync_needed = true;
            on_signal_done (SyncFileItem.Status.SOFT_ERROR, _("The file could not be downloaded completely."));
            return;
        }

        if (this.temporary_file.size () == 0 && this.item.size > 0) {
            FileSystem.remove (this.temporary_file.filename ());
            on_signal_done (SyncFileItem.Status.NORMAL_ERROR,
                _("The downloaded file is empty, but the server said it should have been %1.")
                    .printf (Utility.octets_to_string (this.item.size)));
            return;
        }

        // Did the file come with conflict headers? If so, store them now!
        // If we download conflict files but the server doesn't send conflict
        // headers, the record will be established by SyncEngine.conflict_record_maintenance.
        // (we can't reliably determine the file identifier of the base file here,
        // it might still be downloaded in a parallel get_file_job and not exist in
        // the database yet!)
        if (get_file_job.input_stream.raw_header ("OC-Conflict") == "1") {
            this.conflict_record.path = this.item.file.to_utf8 ();
            this.conflict_record.initial_base_path = get_file_job.input_stream.raw_header ("OC-ConflictInitialBasePath");
            this.conflict_record.base_file_id = get_file_job.input_stream.raw_header ("OC-ConflictBaseFileId");
            this.conflict_record.base_etag = get_file_job.input_stream.raw_header ("OC-ConflictBaseEtag");

            var mtime_header = get_file_job.input_stream.raw_header ("OC-ConflictBaseMtime");
            if (!mtime_header == "")
                this.conflict_record.base_modtime = mtime_header.to_long_long ();

            // We don't set it yet. That will only be done when the download on_signal_finished
            // successfully, much further down. Here we just grab the headers because the
            // job will be deleted later.
        }

        // Do checksum validation for the download. If there is no checksum header, the validate_checksum_header
        // will also emit the signal_validated () signal to continue the flow in slot on_signal_validate_checksum_header_validated ()
        // as this is (still) also correct.
        var validate_checksum_header = new ValidateChecksumHeader (this);
        validate_checksum_header.signal_validated.connect (
            this.on_signal_validate_checksum_header_validated
        );
        validate_checksum_header.signal_validation_failed.connect (
            this.on_signal_validate_checksum_header_validation_failed
        );
        var checksum_header = find_best_checksum (get_file_job.input_stream.raw_header (CHECK_SUM_HEADER_C));
        var content_md5Header = get_file_job.input_stream.raw_header (CONTENT_MD5_HEADER_C);
        if (checksum_header == "" && !content_md5Header == "")
            checksum_header = "MD5:" + content_md5Header;
        validate_checksum_header.start (this.temporary_file.filename (), checksum_header);
    }


    /***********************************************************
    Called when the download's checksum header was signal_validated
    ***********************************************************/
    private void on_signal_validate_checksum_header_validated (string checksum_type, string checksum) {
        string the_content_checksum_type = this.propagator.account.capabilities.preferred_upload_checksum_type;

        // Reuse transmission checksum as content checksum.
        //  
        // We could do this more aggressively and accept both MD5 and SHA1
        // instead of insisting on the exactly correct checksum type.
        if (the_content_checksum_type == checksum_type || the_content_checksum_type == "") {
            return on_signal_compute_checksum_done (checksum_type, checksum);
        }

        // Compute the content checksum.
        var compute_checksum = new ComputeChecksum (this);
        compute_checksum.checksum_type (the_content_checksum_type);
        compute_checksum.signal_finished.connect (
            this.on_signal_compute_checksum_done
        );
        compute_checksum.start (this.temporary_file.filename ());
    }


    /***********************************************************
    Called when the download's checksum computation is done
    ***********************************************************/
    private void on_signal_compute_checksum_done (string checksum_type, string checksum) {
        this.item.checksum_header = make_checksum_header (checksum_type, checksum);

        if (this.is_encrypted) {
            if (this.download_encrypted_helper.decrypt_file (this.temporary_file)) {
            on_signal_download_finished ();
            } else {
            on_signal_done (SyncFileItem.Status.NORMAL_ERROR, this.download_encrypted_helper.error_string);
            }

        } else {
            on_signal_download_finished ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_download_finished () {
        //  GLib.assert_true (!this.temporary_file.is_open);
        string filename = this.propagator.full_local_path (this.item.file);

        // In case of file name clash, report an error
        // This can happen if another parallel download saved a clashing file.
        if (this.propagator.local_filename_clash (this.item.file)) {
            on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("File %1 cannot be saved because of a local file name clash!").printf (GLib.Dir.to_native_separators (this.item.file)));
            return;
        }

        if (this.item.modtime <= 0) {
            FileSystem.remove (this.temporary_file.filename ());
            on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("File %1 has invalid modified time reported by server. Do not save it.").printf (GLib.Dir.to_native_separators (this.item.file)));
            return;
        }
        GLib.assert (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warning ("Invalid modified time: " + this.item.file.to_string () + this.item.modtime.to_string ());
        }
        FileSystem.mod_time (this.temporary_file.filename (), this.item.modtime);
        // We need to fetch the time again because some file systems such as FAT have worse than a second
        // Accuracy, and we really need the time from the file system. (#3103)
        this.item.modtime = FileSystem.get_mod_time (this.temporary_file.filename ());
        if (this.item.modtime <= 0) {
            FileSystem.remove (this.temporary_file.filename ());
            on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("File %1 has invalid modified time reported by server. Do not save it.").printf (GLib.Dir.to_native_separators (this.item.file)));
            return;
        }
        GLib.assert (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warning ("Invalid modified time: " + this.item.file.to_string () + this.item.modtime.to_string ());
        }

        bool previous_file_exists = FileSystem.file_exists (filename);
        if (previous_file_exists) {
            // Preserve the existing file permissions.
            GLib.FileInfo existing_file = GLib.File.new_for_path (filename);
            if (existing_file.permissions () != this.temporary_file.permissions ()) {
                this.temporary_file.permissions (existing_file.permissions ());
            }
            preserve_group_ownership (this.temporary_file.filename (), existing_file);

            // Make the file a hydrated placeholder if possible
            var result = this.propagator.sync_options.vfs.convert_to_placeholder (this.temporary_file.filename (), this.item, filename);
            if (!result) {
                on_signal_done (SyncFileItem.Status.NORMAL_ERROR, result.error);
                return;
            }
        }

        // Apply the remote permissions
        FileSystem.file_read_only_weak (this.temporary_file.filename (), !this.item.remote_permissions == null && !this.item.remote_permissions.has_permission (Common.RemotePermissions.Permissions.CAN_WRITE));

        bool is_conflict = this.item.instruction == CSync.SyncInstructions.CONFLICT
            && (GLib.File.new_for_path (filename).query_info ().get_file_type () == FileType.DIRECTORY || !FileSystem.file_equals (filename, this.temporary_file.filename ()));
        if (is_conflict) {
            string error;
            if (!this.propagator.create_conflict (this.item, this.associated_composite, error)) {
                on_signal_done (SyncFileItem.Status.SOFT_ERROR, error);
                return;
            }
            previous_file_exists = false;
        }

        var vfs = this.propagator.sync_options.vfs;

        // In the case of an hydration, this size is likely to change for placeholders
        // (except with the cfapi backend)
        var is_virtual_download = this.item.type == ItemType.VIRTUAL_FILE_DOWNLOAD;
        var is_cf_api_vfs = vfs && vfs.mode () == Common.AbstractVfs.WindowsCfApi;
        if (previous_file_exists && (is_cf_api_vfs || !is_virtual_download)) {
            // Check whether the existing file has changed since the discovery
            // phase by comparing size and mtime to the previous values. This
            // is necessary to avoid overwriting user changes that happened between
            // the discovery phase and now.
            if (!FileSystem.verify_file_unchanged (filename, this.item.previous_size, this.item.previous_modtime)) {
                this.propagator.another_sync_needed = true;
                on_signal_done (SyncFileItem.Status.SOFT_ERROR, _("File has changed since discovery"));
                return;
            }
        }

        string error;
        this.propagator.signal_touched_file (filename);
        // The file_changed () check is done above to generate better error messages.
        if (!FileSystem.unchecked_rename_replace (this.temporary_file.filename (), filename, error)) {
            GLib.warning ("Rename failed: %1 => %2".printf (this.temporary_file.filename ()).printf (filename));
            // If the file is locked, we want to retry this sync when it
            // becomes available again, otherwise try again directly
            if (FileSystem.is_file_locked (filename)) {
                this.propagator.signal_seen_locked_file (filename);
            } else {
                this.propagator.another_sync_needed = true;
            }

            on_signal_done (SyncFileItem.Status.SOFT_ERROR, error);
            return;
        }

        // Maybe we downloaded a newer version of the file than we thought we would...
        // Get up to date information for the journal.
        this.item.size = FileSystem.get_size (filename);

        // Maybe what we downloaded was a conflict file? If so, set a conflict record.
        // (the data was prepared in on_signal_get_file_job_finished above)
        if (this.conflict_record.is_valid)
            this.propagator.journal.conflict_record (this.conflict_record);

        if (vfs && vfs.mode () == Common.AbstractVfs.WithSuffix) {
            // If the virtual file used to have a different name and database
            // entry, remove it transfer its old pin state.
            if (this.item.type == ItemType.VIRTUAL_FILE_DOWNLOAD) {
                string virtual_file = this.item.file + vfs.file_suffix ();
                var filename = this.propagator.full_local_path (virtual_file);
                GLib.debug ("Download of previous virtual file finished: " + filename);
                GLib.File.remove (filename);
                this.propagator.journal.delete_file_record (virtual_file);

                // Move the pin state to the new location
                var pin = this.propagator.journal.internal_pin_states.raw_for_path (virtual_file.to_utf8 ());
                if (pin && *pin != PinState.INHERITED) {
                    if (!vfs.pin_state (this.item.file, pin)) {
                        GLib.warning ("Could not set pin state of " + this.item.file);
                    }
                    if (!vfs.pin_state (virtual_file, PinState.INHERITED)) {
                        GLib.warning ("Could not set pin state of " + virtual_file + " to inherited.");
                    }
                }
            }

            // Ensure the pin state isn't contradictory
            var pin = vfs.pin_state (this.item.file);
            if (pin && *pin == Common.ItemAvailability.ONLINE_ONLY)
                if (!vfs.pin_state (this.item.file, PinState.UNSPECIFIED)) {
                    GLib.warning ("Could not set pin state of " + this.item.file + " to unspecified.");
                }
        }

        update_metadata (is_conflict);
    }


    /***********************************************************
    Called when it's time to update the database metadata
    ***********************************************************/
    private void update_metadata (bool is_conflict) {
        string filename = this.propagator.full_local_path (this.item.file);
        var result = this.propagator.update_metadata (this.item);
        if (!result) {
            on_signal_done (SyncFileItem.Status.FATAL_ERROR, _("Error updating metadata : %1").printf (result.error));
            return;
        } else if (result == Common.AbstractVfs.ConvertToPlaceholderResult.Locked) {
            on_signal_done (SyncFileItem.Status.SOFT_ERROR, _("The file %1 is currently in use").printf (this.item.file));
            return;
        }

        if (this.is_encrypted) {
            this.propagator.journal.download_info (this.item.file, Common.SyncJournalDb.DownloadInfo ());
        } else {
            this.propagator.journal.download_info (this.item.encrypted_filename, Common.SyncJournalDb.DownloadInfo ());
        }

        this.propagator.journal.commit ("download file start2");

        on_signal_done (is_conflict ? SyncFileItem.Status.CONFLICT : SyncFileItem.Status.SUCCESS);

        // handle the special recall file
        if (!this.item.remote_permissions.has_permission (Common.RemotePermissions.Permissions.IS_SHARED)
            && (this.item.file == ".sys.admin#recall#"
                || this.item.file.has_suffix ("/.sys.admin#recall#"))) {
            handle_recall_file (filename, this.propagator.local_path, this.propagator.journal);
        }

        int64 duration = this.stopwatch.elapsed ();
        if (is_likely_finished_quickly () && duration > 5 * 1000) {
            GLib.warning ("WARNING: Unexpectedly slow connection, took" + duration + "msec for " + this.item.size - this.resume_start + " bytes for " + this.item.file);
        }
    }


    /***********************************************************
    ***********************************************************/
    public new void abort (AbstractPropagatorJob.AbortType abort_type)  {
        if (this.get_file_job != null && this.get_file_job.input_stream) {
            this.get_file_job.input_stream.abort ();
        }

        if (abort_type == AbstractPropagatorJob.AbortType.ASYNCHRONOUS) {
            signal_abort_finished ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_get_file_job_download_progress (int64 received, int64 value) {
        if (this.get_file_job == null) {
            return;
        }
        this.download_progress = received;
        this.propagator.report_progress (this.item, this.resume_start + received);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_validate_checksum_header_validation_failed (string error_message) {
        FileSystem.remove (this.temporary_file.filename ());
        this.propagator.another_sync_needed = true;
        on_signal_done (SyncFileItem.Status.SOFT_ERROR, error_message); // _("The file downloaded with a broken checksum, will be redownloaded."));
    }


    /***********************************************************
    ***********************************************************/
    private void start_after_is_encrypted_is_checked () {
        this.stopwatch.start ();

        var sync_options = this.propagator.sync_options;
        var vfs = sync_options.vfs;

        // For virtual files just dehydrate or create the file and be done
        if (this.item.type == ItemType.VIRTUAL_FILE_DEHYDRATION) {
            string fs_path = this.propagator.full_local_path (this.item.file);
            if (!FileSystem.verify_file_unchanged (fs_path, this.item.previous_size, this.item.previous_modtime)) {
                this.propagator.another_sync_needed = true;
                on_signal_done (SyncFileItem.Status.SOFT_ERROR, _("File has changed since discovery"));
                return;
            }

            GLib.debug ("Dehydrating file " + this.item.file);
            var r = vfs.dehydrate_placeholder (this.item);
            if (!r) {
                on_signal_done (SyncFileItem.Status.NORMAL_ERROR, r.error);
                return;
            }
            this.propagator.journal.delete_file_record (this.item.original_file);
            update_metadata (false);

            if (this.item.remote_permissions != null && !this.item.remote_permissions.has_permission (Common.RemotePermissions.Permissions.CAN_WRITE)) {
                // make sure ReadOnly flag is preserved for placeholder, similarly to regular files
                FileSystem.file_read_only (this.propagator.full_local_path (this.item.file), true);
            }

            return;
        }
        if (vfs.mode () == Common.AbstractVfs.Off && this.item.type == ItemType.VIRTUAL_FILE) {
            GLib.warning ("Ignored virtual file type of " + this.item.file);
            this.item.type = ItemType.FILE;
        }
        if (this.item.type == ItemType.VIRTUAL_FILE) {
            if (this.propagator.local_filename_clash (this.item.file)) {
                on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("File %1 cannot be downloaded because of a local file name clash!").printf (GLib.Dir.to_native_separators (this.item.file)));
                return;
            }

            GLib.debug ("Creating virtual file " + this.item.file);
            // do a klaas' case clash check.
            if (this.propagator.local_filename_clash (this.item.file)) {
                on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("File %1 can not be downloaded because of a local file name clash!").printf (GLib.Dir.to_native_separators (this.item.file)));
                return;
            }
            var r = vfs.create_placeholder (this.item);
            if (!r) {
                on_signal_done (SyncFileItem.Status.NORMAL_ERROR, r.error);
                return;
            }
            update_metadata (false);

            if (this.item.remote_permissions != null && !this.item.remote_permissions.has_permission (Common.RemotePermissions.Permissions.CAN_WRITE)) {
                // make sure ReadOnly flag is preserved for placeholder, similarly to regular files
                FileSystem.file_read_only (this.propagator.full_local_path (this.item.file), true);
            }

            return;
        }

        if (this.delete_existing) {
            delete_existing_folder ();

            // check for error with deletion
            if (this.state == Finished) {
                return;
            }
        }

        GLib.assert (this.item.modtime > 0);
        if (this.item.modtime <= 0) {
            GLib.warning ("Invalid modified time " + this.item.file.to_string () + this.item.modtime.to_string ());
        }
        if (this.item.instruction == CSync.SyncInstructions.CONFLICT
            && this.item.size == this.item.previous_size
            && this.item.checksum_header != ""
            && (csync_is_collision_safe_hash (this.item.checksum_header)
                || this.item.modtime == this.item.previous_modtime)) {
            GLib.debug (this.item.file + " may not need download; computing checksum.");
            var compute_checksum = new ComputeChecksum (this);
            compute_checksum.checksum_type (parse_checksum_header_type (this.item.checksum_header));
            compute_checksum.signal_finished.connect (
                this.on_signal_conflict_checksum_computed
            );
            this.propagator.active_job_list.append (this);
            compute_checksum.start (this.propagator.full_local_path (this.item.file));
            return;
        }

        on_signal_start_download ();
    }


    /***********************************************************
    If we have a conflict where size of the file is unchanged,
    compare the remote checksum to the local one. Maybe it's not
    a real conflict and no download is necessary! If the hashes
    are collision safe and identical, we assume the content is
    too. For weak checksums, we only do that if the mtimes are
    also identical.
    ***********************************************************/
    private void csync_is_collision_safe_hash (string checksum_header) {
        return checksum_header.has_prefix ("SHA")
            || checksum_header.has_prefix ("MD5:");
    }


    /***********************************************************
    Always coming in with forward slashes.
    In csync_excluded_no_ctx we ignore all files with longer than 254 chars
    This function also adds a dot at the beginning of the filename to hide the file on OS X and Linux
    ***********************************************************/
    static string create_download_temporary_filename (string previous) {
        string temporary_filename;
        string temporary_path;
        int slash_pos = previous.last_index_of ("/");
        // work with both pathed filenames and only filenames
        if (slash_pos == -1) {
            temporary_filename = previous;
            temporary_path = "";
        } else {
            temporary_filename = previous.mid (slash_pos + 1);
            temporary_path = previous.left (slash_pos);
        }
        int overhead = 1 + 1 + 2 + 8; // slash dot dot-tilde ffffffff"
        int space_for_filename = int.min (254, temporary_filename.length + overhead) - overhead;
        if (temporary_path.length > 0) {
            return temporary_path + "/" + "." + temporary_filename.left (space_for_filename) + ".~" + (string.number (uint32 (Utility.rand () % 0x_f_f_f_f_f_f_f_f), 16));
        } else {
            return "." + temporary_filename.left (space_for_filename) + ".~" + (string.number (uint32 (Utility.rand () % 0x_f_f_f_f_f_f_f_f), 16));
        }
    }


    /***********************************************************
    Anonymous namespace for the recall feature
    ***********************************************************/
    static string make_recall_filename (string filename) {
        string recall_filename = filename;
        // Add this.recall-XXXX  before the extension.
        int dot_location = recall_filename.last_index_of ('.');
        // If no extension, add it at the end  (take care of cases like foo/.hidden or foo.bar/file)
        if (dot_location <= recall_filename.last_index_of ("/") + 1) {
            dot_location = recall_filename.size ();
        }

        string time_string = GLib.DateTime.current_date_time_utc ().to_string () + " yyyy_mMdd-hhmmss";
        recall_filename.insert (dot_location, "this..sys.admin#recall#-" + time_string);

        return recall_filename;
    }


    /***********************************************************
    Anonymous namespace for the recall feature
    ***********************************************************/
    static void handle_recall_file (string file_path, string folder_path, Common.SyncJournalDb journal) {
        GLib.debug ("Handling recall file: " + file_path);

        GLib.File file = GLib.File.new_for_path (file_path);
        if (!file.open (GLib.IODevice.ReadOnly)) {
            GLib.warning ("Could not open recall file: " + file.error_string);
            return;
        }
        GLib.FileInfo existing_file = GLib.File.new_for_path (file_path);
        GLib.Dir base_dir = existing_file.directory ();

        while (!file.at_end ()) {
            string line = file.read_line ();
            line.chop (1); // remove trailing \n

            string recalled_file = GLib.Dir.clean_path (base_dir.file_path (line));
            if (!recalled_file.has_prefix (folder_path) || !recalled_file.has_prefix (base_dir.path)) {
                GLib.warning ("Ignoring recall of " + recalled_file);
                continue;
            }

            // Path of the recalled file in the local folder
            string local_recalled_file = recalled_file.mid (folder_path.size ());

            SyncJournalFileRecord record;
            if (!journal.get_file_record (local_recalled_file, record) || !record.is_valid) {
                GLib.warning ("No database entry for recall of " + local_recalled_file);
                continue;
            }

            GLib.info ("Recalling " + local_recalled_file + " Checksum: " + record.checksum_header);

            string target_path = make_recall_filename (recalled_file);

            GLib.debug ("Copying recall file from " + recalled_file + " to " + target_path);
            // Remove the target first, GLib.File.copy will not overwrite it.
            FileSystem.remove (target_path);
            GLib.File.copy (recalled_file, target_path);
        }
    }


    /***********************************************************
    Anonymous namespace for the recall feature
    ***********************************************************/
    static void preserve_group_ownership (string filename, GLib.FileInfo file_info) {
//  #ifdef Q_OS_UNIX
        int chown_err = chown (filename.to_local8Bit ().const_data (), -1, file_info.group_id ());
        if (chown_err) {
            // TODO: Consider further error handling!
            GLib.warning ("preserve_group_ownership : chown error %1 : setting group %2 failed on file %3".printf (chown_err).printf (file_info.group_id ()).printf (filename));
        }
//  #else
        //  Q_UNUSED (filename);
        //  Q_UNUSED (file_info);
//  #endif
    }

} // class PropagateDownloadFile

} // namespace LibSync
} // namespace Occ
