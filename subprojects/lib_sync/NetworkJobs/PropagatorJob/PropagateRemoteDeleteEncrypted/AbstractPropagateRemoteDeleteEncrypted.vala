    //  using Soup;

namespace Occ {
namespace LibSync {

/***********************************************************
@class AbstractPropagateRemoteDeleteEncrypted

@brief The AbstractPropagateRemoteDeleteEncrypted class is
the base class for Propagate Remote Delete Encrypted jobs

@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/
public abstract class AbstractPropagateRemoteDeleteEncrypted : AbstractNetworkJob {

    //  /***********************************************************
    //  ***********************************************************/
    //  protected OwncloudPropagator propagator = null;

    //  /***********************************************************
    //  ***********************************************************/
    //  protected unowned SyncFileItem item;

    //  /***********************************************************
    //  ***********************************************************/
    //  protected string folder_token;

    //  /***********************************************************
    //  ***********************************************************/
    //  protected string folder_identifier;

    //  /***********************************************************
    //  ***********************************************************/
    //  protected bool folder_locked = false;

    //  /***********************************************************
    //  ***********************************************************/
    //  protected bool is_task_failed = false;

    //  /***********************************************************
    //  ***********************************************************/
    //  public GLib.InputStream.NetworkError network_error { public get; protected set; }

    //  /***********************************************************
    //  ***********************************************************/
    //  public string error_string { public get; protected set; }

    //  /***********************************************************
    //  ***********************************************************/
    //  internal signal void signal_finished (bool success);

    //  /***********************************************************
    //  ***********************************************************/
    //  protected AbstractPropagateRemoteDeleteEncrypted (OwncloudPropagator propagator, SyncFileItem item, GLib.Object parent) {
    //      base (parent);
    //      this.network_error = GLib.InputStream.NoError;
    //      this.propagator = propagator;
    //      this.item = item;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public abstract void start ();


    //  /***********************************************************
    //  ***********************************************************/
    //  protected void store_first_error (GLib.InputStream.NetworkError error_to_store) {
    //      if (this.network_error == GLib.InputStream.NetworkError.NoError) {
    //          this.network_error = error_to_store;
    //      }
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected void store_first_error_string (string error_string) {
    //      if (this.error_string == "") {
    //          this.error_string = error_string;
    //      }
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected void start_lscol_job (string path) {
    //      GLib.debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED + "FolderConnection is encrypted, let's get the Id from it.");
    //      var lscol_job = new LscolJob (this.propagator.account, this.propagator.full_remote_path (path), this);
    //      lscol_job.properties ({"resourcetype", "http://owncloud.org/ns:fileid"});
    //      lscol_job.signal_directory_listing_subfolders.connect (
    //          this.on_signal_folder_encrypted_id_received
    //      );
    //      lscol_job.signal_finished_with_error.connect (
    //          this.on_signal_task_failed
    //      );
    //      lscol_job.start ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected void on_signal_folder_encrypted_id_received (GLib.List<string> list) {
    //      GLib.debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED + "Received identifier of folder, trying to lock it so we can prepare the metadata");
    //      var lscol_job = (LscolJob)sender ();
    //      ExtraFolderInfo folder_info = lscol_job.folder_infos.value (list.nth_data (0));
    //      on_signal_try_lock (folder_info.file_identifier);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected void on_signal_try_lock (string folder_identifier) {
    //      var lock_encrypt_folder_job = new LockEncryptFolderApiJob (this.propagator.account, folder_identifier, this);
    //      lock_encrypt_folder_job.signal_success.connect (
    //          this.on_signal_folder_locked_successfully
    //      );
    //      lock_encrypt_folder_job.signal_error.connect (
    //          this.on_signal_task_failed
    //      );
    //      lock_encrypt_folder_job.start ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected void on_signal_folder_locked_successfully (string folder_identifier, string token) {
    //      GLib.debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED + "FolderConnection identifier" + folder_identifier + "Locked Successfully for Upload, Fetching Metadata");
    //      this.folder_locked = true;
    //      this.folder_token = token;
    //      this.folder_identifier = folder_identifier;

    //      var get_metadata_job = new GetMetadataApiJob (this.propagator.account, this.folder_identifier);
    //      get_metadata_job.signal_json_received.connect (
    //          this.on_signal_folder_encrypted_metadata_received
    //      );
    //      get_metadata_job.signal_error.connect (
    //          this.on_signal_task_failed
    //      );
    //      get_metadata_job.start ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected virtual void on_signal_folder_unlocked_successfully (string folder_identifier) {
    //      //  Q_UNUSED (folder_identifier);
    //      GLib.debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED + "FolderConnection identifier " + folder_identifier + " successfully unlocked.");
    //      this.folder_locked = false;
    //      this.folder_token = "";
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  //  protected virtual void on_signal_folder_encrypted_metadata_received (GLib.JsonDocument json, int status_code);


    //  /***********************************************************
    //  ***********************************************************/
    //  protected void on_signal_delete_remote_item_finished () {
    //      var delete_job = (KeychainChunkDeleteJob)sender ();

    //      GLib.assert (delete_job);

    //      if (!delete_job) {
    //          GLib.critical (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED + "Sender is not a KeychainChunkDeleteJob instance.");
    //          on_signal_task_failed ();
    //          return;
    //      }

    //      this.item.http_error_code = delete_job.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
    //      this.item.response_time_stamp = delete_job.response_timestamp;
    //      this.item.request_id = delete_job.request_id ();

    //      if (delete_job.reply.error != GLib.InputStream.NoError && delete_job.reply.error != GLib.InputStream.ContentNotFoundError) {
    //          store_first_error_string (delete_job.error_string);
    //          store_first_error (delete_job.reply.error);

    //          on_signal_task_failed ();
    //          return;
    //      }

    //      // A 404 reply is also considered a on_signal_success here : We want to make sure
    //      // a file is gone from the server. It not being there in the first place
    //      // is ok. This will happen for files that are in the DB but not on
    //      // the server or the local file system.
    //      if (this.item.http_error_code != 204 && this.item.http_error_code != 404) {
    //          // Normally we expect "204 No Content"
    //          // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
    //          // throw an error.
    //          store_first_error_string (_("Wrong HTTP code returned by server. Expected 204, but received \"%1 %2\".")
    //                      .printf (this.item.http_error_code)
    //                      .printf (delete_job.input_stream.attribute (Soup.Request.HttpReasonPhraseAttribute).to_string ()));

    //          on_signal_task_failed ();
    //          return;
    //      }

    //      this.propagator.journal.delete_file_record (this.item.original_file, this.item.is_directory ());
    //      this.propagator.journal.commit ("Remote Remove");

    //      unlock_folder ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected void delete_remote_item (string filename) {
    //      GLib.info (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED + "Deleting nested encrypted item " + filename);

    //      var delete_job = new KeychainChunkDeleteJob (this.propagator.account, this.propagator.full_remote_path (filename), this);
    //      delete_job.folder_token (this.folder_token);

    //      delete_job.signal_finished.connect (
    //          this.on_signal_delete_remote_item_finished
    //      );

    //      delete_job.start ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected void unlock_folder () {
    //      if (!this.folder_locked) {
    //          signal_finished (true);
    //          return;
    //      }

    //      GLib.debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED + "Unlocking folder " + this.folder_identifier);
    //      var unlock_encrypt_folder_job = new UnlockEncryptFolderApiJob (this.propagator.account, this.folder_identifier, this.folder_token, this);

    //      unlock_encrypt_folder_job.signal_success.connect (
    //          this.on_signal_folder_unlocked_successfully
    //      );
    //      unlock_encrypt_folder_job.signal_error.connect (
    //          (file_identifier, http_return_code) => {
    //          //  Q_UNUSED (file_identifier);
    //          this.folder_locked = false;
    //          this.folder_token = "";
    //          this.item.http_error_code = http_return_code;
    //          this.error_string = _("\"%1 Failed to unlock encrypted folder %2\".")
    //                  .printf (http_return_code)
    //                  .printf (string.from_utf8 (file_identifier));
    //          this.item.error_string =this.error_string;
    //          on_signal_task_failed ();
    //      });
    //      unlock_encrypt_folder_job.start ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected void on_signal_task_failed () {
    //      GLib.debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED + "Task failed for job " + sender ());
    //      this.is_task_failed = true;
    //      if (this.folder_locked) {
    //          unlock_folder ();
    //      } else {
    //          signal_finished (false);
    //      }
    //  }

} // class AbstractPropagateRemoteDeleteEncrypted

} // namespace LibSync
} // namespace Occ
