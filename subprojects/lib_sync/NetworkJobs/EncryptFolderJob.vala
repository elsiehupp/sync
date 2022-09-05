namespace Occ {
namespace LibSync {

/***********************************************************
@class EncryptFolderJob

@author Kevin Ottens <kevin.ottens@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class EncryptFolderJob : AbstractNetworkJob {

    //  /***********************************************************
    //  ***********************************************************/
    //  public enum Status {
    //      SUCCESS = 0,
    //      ERROR,
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  //  private unowned Account account;
    //  private Common.SyncJournalDb journal;
    //  //  private string path;
    //  private string file_identifier;
    //  private string folder_token;
    //  //  string error_string { public get; protected set; }


    //  internal signal void signal_finished (EncryptFolderJob encrypt_folder_job, Status status);


    //  /***********************************************************
    //  ***********************************************************/
    //  public EncryptFolderJob.for_account (Account account, Common.SyncJournalDb journal, string path, string file_identifier, GLib.Object parent = new GLib.Object ()) {
    //      base (parent);
    //      this.account = account;
    //      this.journal = journal;
    //      this.path = path;
    //      this.file_identifier = file_identifier;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public new void start () {
    //      var set_encryption_flag_job = new SetEncryptionFlagApiJob (this.account, this.file_identifier, SetEncryptionFlagApiJob.Set, this);
    //      set_encryption_flag_job.signal_success.connect (
    //          this.on_signal_set_encryption_flag_job_success
    //      );
    //      set_encryption_flag_job.signal_error.connect (
    //          this.on_signal_set_encryption_flag_job_error
    //      );
    //      set_encryption_flag_job.start ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void on_signal_set_encryption_flag_job_success (string file_identifier) {
    //      Common.SyncJournalFileRecord record;
    //      this.journal.get_file_record (this.path, record);
    //      if (record.is_valid) {
    //          record.is_e2e_encrypted = true;
    //          this.journal.file_record (record);
    //      }

    //      var lock_encrypt_folder_api_job = new LockEncryptFolderApiJob (
    //          this.account, file_identifier, this
    //      );
    //      lock_encrypt_folder_api_job.signal_success.connect (
    //          this.on_signal_lock_for_encryption_success
    //      );
    //      lock_encrypt_folder_api_job.signal_error.connect (
    //          this.on_signal_lock_for_encryption_error
    //      );
    //      lock_encrypt_folder_api_job.start ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void on_signal_set_encryption_flag_job_error (string file_identifier, int http_error_code) {
    //      GLib.debug ("Error on the encryption flag of " + file_identifier + " HTTP code: " + http_error_code.to_string ());
    //      signal_finished (this, Status.ERROR);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void on_signal_lock_for_encryption_success (string file_identifier, string token) {
    //      this.folder_token = token;

    //      FolderMetadata empty_metadata = new FolderMetadata (this.account);
    //      var encrypted_metadata = empty_metadata.encrypted_metadata ();
    //      if (encrypted_metadata == "") {
    //          // TODO: Mark the folder as unencrypted as the metadata generation failed.
    //          this.error_string = _("Could not generate the metadata for encryption, Unlocking the folder.\n"
    //                              + "This can be an issue with your OpenSSL libraries.");
    //          signal_finished (this, Status.ERROR);
    //          return;
    //      }

    //      var store_metadata_api_job = new StoreMetadataApiJob (this.account, file_identifier, empty_metadata.encrypted_metadata (), this);
    //      store_metadata_api_job.signal_success.connect (
    //          this.on_signal_upload_metadata_success
    //      );
    //      store_metadata_api_job.signal_error.connect (
    //          this.on_signal_update_metadata_error
    //      );
    //      store_metadata_api_job.start ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void on_signal_lock_for_encryption_error (string file_identifier, int http_error_code) {
    //      GLib.info ("Locking error for " + file_identifier + " HTTP code: " + http_error_code.to_string ());
    //      signal_finished (this, Status.ERROR);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void on_signal_unlock_folder_success (string file_identifier) {
    //      GLib.info ("Unlocking on_signal_success for " + file_identifier);
    //      signal_finished (this, Status.SUCCESS);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void on_signal_unlock_folder_error (string file_identifier, int http_error_code) {
    //      GLib.info ("Unlocking error for " + file_identifier + " HTTP code: " + http_error_code.to_string ());
    //      signal_finished (this, Status.ERROR);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void on_signal_upload_metadata_success (string folder_identifier) {
    //      var unlock_encrypt_folder_api_job = new UnlockEncryptFolderApiJob (this.account, folder_identifier, this.folder_token, this);
    //      unlock_encrypt_folder_api_job.signal_success.connect (
    //          this.on_signal_unlock_folder_success
    //      );
    //      unlock_encrypt_folder_api_job.signal_error.connect (
    //          this.on_signal_unlock_folder_error
    //      );
    //      unlock_encrypt_folder_api_job.start ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void on_signal_update_metadata_error (string folder_identifier, int http_return_code) {
    //      //  Q_UNUSED (http_return_code);

    //      var unlock_encrypt_folder_api_job = new UnlockEncryptFolderApiJob (this.account, folder_identifier, this.folder_token, this);
    //      unlock_encrypt_folder_api_job.signal_success.connect (
    //          this.on_signal_unlock_folder_success
    //      );
    //      unlock_encrypt_folder_api_job.signal_error.connect (
    //          this.on_signal_unlock_folder_error
    //      );
    //      unlock_encrypt_folder_api_job.start ();
    //  }

} // class EncryptFolderJob

} // namespace LibSync
} // namespace Occ
    //  