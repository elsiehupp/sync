

//  #include <QJsonDocument>
//  #include <QTemporary
//  #include <QFile
//  #include <QDir>
//  #include <QTemporary_file>
//  #include <QLoggingCategory>
//  #include <QMimeDatabase>

namespace Occ {
namespace LibSync {

/***********************************************************
This class is used if the server supports end to end
encryption. It will fire for any* folder, encrypted or not,
because when the client starts the upload request we don't
know if the folder is encrypted on the server.

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
    //  private 

    /***********************************************************
    ***********************************************************/
    private bool current_locking_in_progress = false;

    /***********************************************************
    ***********************************************************/
    bool is_unlock_running { public get; private set; }

    /***********************************************************
    ***********************************************************/
    private bool is_folder_locked { public get; private set; }

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
    signal void finalized (string path, string filename, uint64 size);

    /***********************************************************
    ***********************************************************/
    signal void error ();

    /***********************************************************
    ***********************************************************/
    signal void folder_unlocked (string folder_identifier, int http_status);

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

        GLib.debug ("Folder is encrypted; let's get the Id from it.");
        var job = new LsColJob (this.propagator.account (), absolute_remote_parent_path, this);
        job.properties ({"resourcetype", "http://owncloud.org/ns:fileid"});
        connect (job, LsColJob.directory_listing_subfolders, this, PropagateUploadEncrypted.on_signal_folder_encrypted_id_received);
        connect (job, LsColJob.finished_with_error, this, PropagateUploadEncrypted.on_signal_folder_encrypted_id_error);
        job.start ();
    }


    private void root_path () {
        var result = this.propagator.remote_path ();
        if (result.starts_with ("/")) {
            return result.mid (1);
        } else {
            return result;
        }
    }


    private void absolute_remote_parent_path () {
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
        var unlock_job = new UnlockEncryptFolderApiJob (this.propagator.account (),
            this.folder_identifier, this.folder_token, this);

        connect (
            unlock_job,
            UnlockEncryptFolderApiJob.on_signal_success,
            this.on_signal_unlock_encrypt_folder_api_job_success
        );
        connect (
            unlock_job,
            UnlockEncryptFolderApiJob.error,
            this.on_signal_unlock_encrypt_folder_api_job_error
        );
        unlock_job.start ();
    }


    private void on_signal_unlock_encrypt_folder_api_job_success (string folder_identifier) {
        GLib.debug ("Successfully Unlocked");
        this.folder_token = "";
        this.folder_identifier = "";
        this.is_folder_locked = false;

        /* emit */ folder_unlocked (folder_identifier, 200);
        this.is_unlock_running = false;
    }


    private void on_signal_unlock_encrypt_folder_api_job_error (string folder_identifier, int http_status) {
        GLib.debug ("Unlock Error");

        /* emit */ folder_unlocked (folder_identifier, http_status);
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
    private void on_signal_folder_encrypted_id_received (string[] list) {
        GLib.debug ("Received identifier of folder; trying to lock it so we can prepare the metadata.");
        var job = (LsColJob) sender ();
        var folder_info = job.folder_infos.value (list.first ());
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
        GLib.debug ("Folder " + file_identifier.to_string () + " locked successfully for upload; fetching metadata.");
        // Should I use a mutex here?
        this.current_locking_in_progress = true;
        this.folder_token = token;
        this.folder_identifier = file_identifier;
        this.is_folder_locked = true;

        var job = new GetMetadataApiJob (this.propagator.account (), this.folder_identifier);
        connect (
            job,
            GetMetadataApiJob.signal_json_received,
            this,
            PropagateUploadEncrypted.on_signal_folder_encrypted_metadata_received
        );
        connect (
            job,
            GetMetadataApiJob.error,
            this,
            PropagateUploadEncrypted.on_signal_folder_encrypted_metadata_error
        );

        job.start ();
    }


    /***********************************************************
    Try to call the lock from 5 to 5 seconds and fail if it's
    more than 5 minutes.
    ***********************************************************/
    private void on_signal_folder_locked_error (string file_identifier, int http_error_code) {
        //  Q_UNUSED (http_error_code);
        QTimer.single_shot (
            5000,
            this,
            this.on_signal_timer_complete
        );

        GLib.debug ("Folder " + file_identifier + " couldn't be locked.");
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
        var lock_job = new LockEncryptFolderApiJob (this.propagator.account (), file_identifier, this);
        connect (lock_job, LockEncryptFolderApiJob.on_signal_success, this, PropagateUploadEncrypted.on_signal_folder_locked_successfully);
        connect (lock_job, LockEncryptFolderApiJob.error, this, PropagateUploadEncrypted.on_signal_folder_locked_error);
        lock_job.start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_encrypted_metadata_received (QJsonDocument json, int status_code) {
        GLib.debug ("Metadata Received; preparing it for the new file. " + json.to_variant ());

        // Encrypt File!
        this.metadata = new FolderMetadata (this.propagator.account (), json.to_json (QJsonDocument.Compact), status_code);

        GLib.FileInfo info = GLib.File.new_for_path (this.propagator.full_local_path (this.item.file));
        const string filename = info.filename ();

        // Find existing metadata for this file
        bool found = false;
        EncryptedFile encrypted_file;
        const GLib.List<EncryptedFile> files = this.metadata.files ();

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

            QMimeDatabase mdatabase;
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
            GLib.File input = new GLib.File (info.absolute_file_path ());
            GLib.File output = new GLib.File (QDir.temp_path () + QDir.separator () + encrypted_file.encrypted_filename);

            string tag;
            bool encryption_result = EncryptionHelper.file_encryption (
                encrypted_file.encryption_key,
                encrypted_file.initialization_vector,
                input, output, tag);

            if (!encryption_result) {
                GLib.debug ("There was an error encrypting the file; aborting upload.");
                connect (
                    this,
                    PropagateUploadEncrypted.folder_unlocked,
                    this,
                    PropagateUploadEncrypted.error
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
            var job = new StoreMetaDataApiJob (this.propagator.account (),
                                                this.folder_identifier,
                                                this.metadata.encrypted_metadata ());
            connect (job, StoreMetaDataApiJob.on_signal_success, this, PropagateUploadEncrypted.on_signal_update_metadata_success);
            connect (job, StoreMetaDataApiJob.error, this, PropagateUploadEncrypted.on_signal_update_metadata_error);
            job.start ();
        } else {
            var job = new UpdateMetadataApiJob (this.propagator.account (),
                                                this.folder_identifier,
                                                this.metadata.encrypted_metadata (),
                                                this.folder_token);

            connect (job, UpdateMetadataApiJob.on_signal_success, this, PropagateUploadEncrypted.on_signal_update_metadata_success);
            connect (job, UpdateMetadataApiJob.error, this, PropagateUploadEncrypted.on_signal_update_metadata_error);
            job.start ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_encrypted_metadata_error (string file_identifier, int http_return_code) {
        //  Q_UNUSED (file_identifier);
        //  Q_UNUSED (http_return_code);
        GLib.debug ("Error getting the encrypted metadata. Pretend we got empty metadata.");
        FolderMetadata empty_metadata = new FolderMetadata (this.propagator.account ());
        empty_metadata.encrypted_metadata ();
        var json = QJsonDocument.from_json (empty_metadata.encrypted_metadata ());
        on_signal_folder_encrypted_metadata_received (json, http_return_code);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_update_metadata_success (string file_identifier) {
        //  Q_UNUSED (file_identifier);
        GLib.debug ("Uploading of the metadata succeeded; encrypting the file.");
        GLib.FileInfo output_info = GLib.File.new_for_path (this.complete_filename);

        GLib.debug ("Encrypted info: " + output_info.path () + output_info.filename () + output_info.size ());
        GLib.debug ("Finalizing the upload part; now the actual uploader will take over.");
        /* emit */ finalized (output_info.path () + "/" + output_info.filename (),
            this.remote_parent_path + "/" + output_info.filename (),
            output_info.size ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_update_metadata_error (string file_identifier, int http_error_response) {
        GLib.debug ("Update metadata error for folder " + file_identifier + " with error " + http_error_response);
        GLib.debug ("Unlocking the folder.");
        connect (
            this,
            PropagateUploadEncrypted.folder_unlocked,
            this,
            PropagateUploadEncrypted.error
        );
        unlock_folder ();
    }

} // class PropagateUploadEncrypted

} // namespace LibSync
} // namespace Occ
  