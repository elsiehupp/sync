namespace Occ {
namespace LibSync {

/***********************************************************
@class PropagateUploadEncrypted

@details This class is used if the server supports end to
end encryption. It will fire for *any* folder, encrypted or
not, because when the client starts the upload request we
don't know if the folder is encrypted on the server.

emits:
finalized () if the encrypted file is ready to be
error () if there was an error with the encryption
folder_not_encrypted () if the file is within a folder that's not encrypted.
***********************************************************/
public class PropagateUploadEncrypted : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private OwncloudPropagator propagator;
    private string remote_parent_path;
    private unowned SyncFileItem item;

    /***********************************************************
    ***********************************************************/
    string folder_token { public get; private set; }

    /***********************************************************
    ***********************************************************/
    private bool current_locking_in_progress = false;

    /***********************************************************
    ***********************************************************/
    public bool is_unlock_running { public get; private set; }

    /***********************************************************
    ***********************************************************/
    public bool is_folder_locked { public get; private set; }

    /***********************************************************
    ***********************************************************/
    private string generated_key;
    private string generated_initialization_vector;
    private FolderMetadata metadata;
    private EncryptedFile encrypted_file;
    private string complete_filename;

    /***********************************************************
    Emmited after the file is encrypted and everything is set up.
    ***********************************************************/
    internal signal void finalized (string path, string filename, uint64 size);

    /***********************************************************
    ***********************************************************/
    internal signal void signal_error ();

    /***********************************************************
    ***********************************************************/
    internal signal void signal_folder_unlocked (string folder_identifier, int http_status);

    /***********************************************************
    ***********************************************************/
    public PropagateUploadEncrypted (OwncloudPropagator propagator, string remote_parent_path, SyncFileItem item, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.propagator = propagator;
        this.remote_parent_path = remote_parent_path;
        this.item = item;
        this.metadata = null;
        this.is_unlock_running = false;
        this.is_folder_locked = false;
    }


    /***********************************************************
    If the file is in a encrypted folder, which we know, we
    wouldn't be here otherwise, we need to do the long road:

    - find the ID of the folder.
    - lock the folder using its identifier.
    - download the metadata
    - update the metadata
    - upload the file
    - upload the metadata
    - unlock the folder.
    ***********************************************************/
    public new void start () {

        GLib.debug ("FolderConnection is encrypted; let's get the Id from it.");
        var lscol_job = new LscolJob (
            this.propagator.account,
            absolute_remote_parent_path,
            this
        );
        lscol_job.properties (
            {
                "resourcetype",
                "http://owncloud.org/ns:fileid"
            }
        );
        lscol_job.signal_directory_listing_subfolders.connect (
            this.on_signal_folder_encrypted_id_received
        );
        lscol_job.signal_finished_with_error.connect (
            this.on_signal_folder_encrypted_id_error
        );
        lscol_job.start ();
    }


    private void root_path {
        var result = this.propagator.remote_path;
        if (result.has_prefix ("/")) {
            return result.mid (1);
        } else {
            return result;
        }
    }


    private void absolute_remote_parent_path {
        var path = root_path + this.remote_parent_path;
        if (path.has_suffix ("/")) {
            path.chop (1);
        }
        return path;
    }


    /***********************************************************
    ***********************************************************/
    public void unlock_folder () {
        //  ASSERT (!this.is_unlock_running);

        if (this.is_unlock_running) {
            GLib.warning ("Double-call to unlock_folder.");
            return;
        }

        this.is_unlock_running = true;

        GLib.debug ("Calling Unlock");
        var unlock_job = new UnlockEncryptFolderApiJob (
            this.propagator.account,
            this.folder_identifier,
            this.folder_token,
            this
        );

        unlock_job.on_signal_success.connect (
            this.on_signal_unlock_encrypt_folder_api_job_success
        );
        unlock_job.signal_error.connect (
            this.on_signal_unlock_encrypt_folder_api_job_error
        );
        unlock_job.start ();
    }


    private void on_signal_unlock_encrypt_folder_api_job_success (string folder_identifier) {
        GLib.debug ("Successfully Unlocked");
        this.folder_token = "";
        this.folder_identifier = "";
        this.is_folder_locked = false;

        /* emit */ signal_folder_unlocked (folder_identifier, 200);
        this.is_unlock_running = false;
    }


    private void on_signal_unlock_encrypt_folder_api_job_error (string folder_identifier, int http_status) {
        GLib.debug ("Unlock Error");

        /* emit */ signal_folder_unlocked (folder_identifier, http_status);
        this.is_unlock_running = false;
    }






    /***********************************************************
    We try to lock a folder, if it's locked we try again in one second.
    if it's still locked we try again in one second. looping untill one minute.
                                                                        . fail.
    the 'loop' :                                                         /
        on_signal_folder_encrypted_id_received . on_signal_try_lock . lock_error . still_time? . on_signal_try_lock

                                            . on_signal_success.
    ***********************************************************/
    private void on_signal_folder_encrypted_id_received (GLib.List<string> list) {
        GLib.debug ("Received identifier of folder; trying to lock it so we can prepare the metadata.");
        var lscol_job = (LscolJob) sender ();
        var folder_info = lscol_job.folder_infos.value (list.nth_data (0));
        this.folder_lock_first_try.start ();
        on_signal_try_lock (folder_info.file_identifier);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_encrypted_id_error (GLib.InputStream reply) {
        //  Q_UNUSED (reply);
        GLib.debug ("Error retrieving the Id of the encrypted folder.");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_locked_successfully (string file_identifier, string token) {
        GLib.debug ("FolderConnection " + file_identifier.to_string () + " locked successfully for upload; fetching metadata.");
        // Should I use a mutex here?
        this.current_locking_in_progress = true;
        this.folder_token = token;
        this.folder_identifier = file_identifier;
        this.is_folder_locked = true;

        var get_metatdata_api_job = new GetMetadataApiJob (this.propagator.account, this.folder_identifier);
        get_metatdata_api_job.signal_json_received.connect (
            this.on_signal_folder_encrypted_metadata_received
        );
        get_metatdata_api_job.signal_error.connect (
            this.on_signal_folder_encrypted_metadata_error
        );

        get_metatdata_api_job.start ();
    }


    /***********************************************************
    Try to call the lock from 5 to 5 seconds and fail if it's
    more than 5 minutes.
    ***********************************************************/
    private void on_signal_folder_locked_error (string file_identifier, int http_error_code) {
        //  Q_UNUSED (http_error_code);
        GLib.Timeout.single_shot (
            5000,
            this,
            this.on_signal_timer_complete
        );

        GLib.debug ("FolderConnection " + file_identifier + " couldn't be locked.");
    }


    private void on_signal_timer_complete (string file_identifier) {
        if (!this.current_locking_in_progress) {
            GLib.debug ("Error locking the folder while no other update is locking it up.");
            GLib.debug ("Perhaps another client locked it.");
            GLib.debug ("Aborting.");
            return;
        }

        // Perhaps I should remove the elapsed timer if the lock is from this client?
        if (this.folder_lock_first_try.elapsed () > /* five minutes */ 1000 * 60 * 5 ) {
            GLib.debug ("One minute passed, ignoring more attempts to lock the folder.");
            return;
        }
        on_signal_try_lock (file_identifier);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_try_lock (string file_identifier) {
        var lock_encrypt_folder_api_job = new LockEncryptFolderApiJob (this.propagator.account, file_identifier, this);
        lock_encrypt_folder_api_job.signal_success.connect (
            this.on_signal_folder_locked_successfully
        );
        lock_encrypt_folder_api_job.signal_error.connect (
            this.on_signal_folder_locked_error
        );
        lock_encrypt_folder_api_job.start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_encrypted_metadata_received (GLib.JsonDocument json, int status_code) {
        GLib.debug ("Metadata Received; preparing it for the new file. " + json.to_variant ());

        // Encrypt File!
        this.metadata = new FolderMetadata (this.propagator.account, json.to_json (GLib.JsonDocument.Compact), status_code);

        GLib.FileInfo info = GLib.File.new_for_path (this.propagator.full_local_path (this.item.file));
        string filename = info.filename ();

        // Find existing metadata for this file
        bool found = false;
        EncryptedFile encrypted_file;
        GLib.List<EncryptedFile> files = this.metadata.files ();

        foreach (EncryptedFile file in files) {
            if (file.original_filename == filename) {
                encrypted_file = file;
                found = true;
            }
        }

        // New encrypted file so set it all up!
        if (!found) {
            encrypted_file.encryption_key = EncryptionHelper.generate_random (16);
            encrypted_file.encrypted_filename = EncryptionHelper.generate_random_filename ();
            encrypted_file.initialization_vector = EncryptionHelper.generate_random (16);
            encrypted_file.file_version = 1;
            encrypted_file.metadata_key = 1;
            encrypted_file.original_filename = filename;

            GLib.MimeDatabase mdatabase;
            encrypted_file.mimetype = mdatabase.mime_type_for_file (info).name ().to_local8Bit ();

            // Other clients expect "httpd/unix-directory" instead of "inode/directory"
            // Doesn't matter much for us since we don't do much about that mimetype anyway
            if (encrypted_file.mimetype == "inode/directory") {
                encrypted_file.mimetype = "httpd/unix-directory";
            }
        }

        this.item.encrypted_filename = this.remote_parent_path + "/" + encrypted_file.encrypted_filename;
        this.item.is_encrypted = true;

        GLib.debug ("Creating the encrypted file.");

        if (info.query_info ().get_file_type () == FileType.DIRECTORY) {
            this.complete_filename = encrypted_file.encrypted_filename;
        } else {
            GLib.File input = new GLib.File (info.absolute_file_path);
            GLib.File output = new GLib.File (GLib.Dir.temp_path + GLib.Dir.separator () + encrypted_file.encrypted_filename);

            string tag;
            bool encryption_result = EncryptionHelper.file_encryption (
                encrypted_file.encryption_key,
                encrypted_file.initialization_vector,
                input, output, tag);

            if (!encryption_result) {
                GLib.debug ("There was an error encrypting the file; aborting upload.");
                this.signal_folder_unlocked.connect (
                    this.signal_error
                );
                unlock_folder ();
                return;
            }

            encrypted_file.authentication_tag = tag;
            this.complete_filename = output.filename ();
        }

        GLib.debug ("Creating the metadata for the encrypted file.");

        this.metadata.add_encrypted_file (encrypted_file);
        this.encrypted_file = encrypted_file;

        GLib.debug ("Metadata created; sending to the server.");

        if (status_code == 404) {
            var store_metatdata_api_job = new StoreMetadataApiJob (
                this.propagator.account,
                this.folder_identifier,
                this.metadata.encrypted_metadata ()
            );
            store_metatdata_api_job.signal_success.connect (
                this.on_signal_update_metadata_success
            );
            store_metatdata_api_job.signal_error.connect (
                this.on_signal_update_metadata_error
            );
            store_metatdata_api_job.start ();
        } else {
            var store_metatdata_api_job = new UpdateMetadataApiJob (
                this.propagator.account,
                this.folder_identifier,
                this.metadata.encrypted_metadata (),
                this.folder_token
            );

            store_metatdata_api_job.signal_success.connect (
                this.on_signal_update_metadata_success
            );
            store_metatdata_api_job.signal_error.connect (
                this.on_signal_update_metadata_error
            );
            store_metatdata_api_job.start ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_encrypted_metadata_error (string file_identifier, int http_return_code) {
        //  Q_UNUSED (file_identifier);
        //  Q_UNUSED (http_return_code);
        GLib.debug ("Error getting the encrypted metadata. Pretend we got empty metadata.");
        FolderMetadata empty_metadata = new FolderMetadata (this.propagator.account);
        empty_metadata.encrypted_metadata ();
        var json = GLib.JsonDocument.from_json (empty_metadata.encrypted_metadata ());
        on_signal_folder_encrypted_metadata_received (json, http_return_code);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_update_metadata_success (string file_identifier) {
        //  Q_UNUSED (file_identifier);
        GLib.debug ("Uploading of the metadata succeeded; encrypting the file.");
        GLib.FileInfo output_info = GLib.File.new_for_path (this.complete_filename);

        GLib.debug ("Encrypted info: " + output_info.path + output_info.filename () + output_info.size ());
        GLib.debug ("Finalizing the upload part; now the actual uploader will take over.");
        /* emit */ finalized (output_info.path + "/" + output_info.filename (),
            this.remote_parent_path + "/" + output_info.filename (),
            output_info.size ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_update_metadata_error (string file_identifier, int http_error_response) {
        GLib.debug ("Update metadata error for folder " + file_identifier + " with error " + http_error_response.to_string ());
        GLib.debug ("Unlocking the folder.");
        this.signal_folder_unlocked.connect (
            this.on_signal_error
        );
        unlock_folder ();
    }

} // class PropagateUploadEncrypted

} // namespace LibSync
} // namespace Occ
  