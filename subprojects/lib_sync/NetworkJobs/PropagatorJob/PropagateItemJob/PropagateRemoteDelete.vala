namespace Occ {
namespace LibSync {

/***********************************************************
@class PropagateRemoteDelete

@brief The PropagateRemoteDelete class

@author Olivier Goffart <ogoffart@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PropagateRemoteDelete : AbstractPropagateItemJob {

    KeychainChunkDeleteJob delete_job;
    AbstractPropagateRemoteDeleteEncrypted delete_encrypted_helper = null;

    /***********************************************************
    ***********************************************************/
    public PropagateRemoteDelete (OwncloudPropagator propagator, SyncFileItem item) {
        //  base (propagator, item);
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        //  GLib.info ("Start propagate remote delete job for" + this.item.file);

        //  if (this.propagator.abort_requested)
        //      return;

        //  if (this.item.encrypted_filename != "" || this.item.is_encrypted) {
        //      if (this.item.encrypted_filename != "") {
        //          this.delete_encrypted_helper = new PropagateRemoteDeleteEncrypted (this.propagator, this.item, this);
        //      } else {
        //          this.delete_encrypted_helper = new PropagateRemoteDeleteEncryptedRootFolder (this.propagator, this.item, this);
        //      }
        //      this.delete_encrypted_helper.signal_finished.connect (
        //          this.on_signal_abstract_propagate_remote_delete_encrypted_finished
        //      );
        //      this.delete_encrypted_helper.start ();
        //  } else {
        //      create_delete_job (this.item.file);
        //  }
    }


    private void on_signal_abstract_propagate_remote_delete_encrypted_finished (bool on_signal_success) {
        //  if (!on_signal_success) {
        //      SyncFileItem.Status status = SyncFileItem.Status.NORMAL_ERROR;
        //      if (this.delete_encrypted_helper.network_error != GLib.InputStream.NoError && this.delete_encrypted_helper.network_error != GLib.InputStream.ContentNotFoundError) {
        //          status = this.classify_error (this.delete_encrypted_helper.network_error, this.item.http_error_code, this.propagator.another_sync_needed);
        //      }
        //      on_signal_done (status, this.delete_encrypted_helper.error_string);
        //  } else {
        //      on_signal_done (SyncFileItem.Status.SUCCESS);
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void create_delete_job (string filename) {
        //  GLib.info ("Deleting file, local" + this.item.file + "remote" + filename);

        //  this.delete_job = new KeychainChunkDeleteJob (
        //      this.propagator.account,
        //      this.propagator.full_remote_path (filename),
        //      this
        //  );

        //  this.delete_job.signal_finished.connect (
        //      this.on_signal_delete_job_finished
        //  );
        //  this.propagator.active_job_list.append (this);
        //  this.delete_job.start ();
    }


    /***********************************************************
    ***********************************************************/
    public new void abort (AbstractPropagatorJob.AbortType abort_type) {
        //  if (this.delete_job != null && this.delete_job.input_stream)
        //      this.delete_job.input_stream.abort ();

        //  if (abort_type == AbstractPropagatorJob.AbortType.ASYNCHRONOUS) {
        //      signal_abort_finished ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public new bool is_likely_finished_quickly () {
        //  return !this.item.is_directory;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_delete_job_finished () {
        //  this.propagator.active_job_list.remove_one (this);

        //  //  GLib.assert_true (this.delete_job);

        //  GLib.InputStream.NetworkError err = this.delete_job.input_stream.error;
        //  int http_status = this.delete_job.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        //  this.item.http_error_code = http_status;
        //  this.item.response_time_stamp = this.delete_job.response_timestamp;
        //  this.item.request_id = this.delete_job.request_id ();

        //  if (err != GLib.InputStream.NoError && err != GLib.InputStream.ContentNotFoundError) {
        //      SyncFileItem.Status status = classify_error (err, this.item.http_error_code,
        //          this.propagator.another_sync_needed);
        //      on_signal_done (status, this.delete_job.error_string);
        //      return;
        //  }

        //  // A 404 reply is also considered a on_signal_success here : We want to make sure
        //  // a file is gone from the server. It not being there in the first place
        //  // is ok. This will happen for files that are in the DB but not on
        //  // the server or the local file system.
        //  if (http_status != 204 && http_status != 404) {
        //      // Normally we expect "204 No Content"
        //      // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
        //      // throw an error.
        //      on_signal_done (SyncFileItem.Status.NORMAL_ERROR,
        //          _("Wrong HTTP code returned by server. Expected 204, but received \"%1 %2\".")
        //              .printf (this.item.http_error_code)
        //              .printf (this.delete_job.input_stream.attribute (Soup.Request.HttpReasonPhraseAttribute).to_string ()));
        //      return;
        //  }

        //  this.propagator.journal.delete_file_record (this.item.original_file, this.item.is_directory);
        //  this.propagator.journal.commit ("Remote Remove");

        //  on_signal_done (SyncFileItem.Status.SUCCESS);
    }

} // class PropagateRemoteDelete

} // namespace LibSync
} // namespace Occ
