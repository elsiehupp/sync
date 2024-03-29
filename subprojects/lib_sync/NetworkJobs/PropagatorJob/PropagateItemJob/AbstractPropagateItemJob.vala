/***********************************************************
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@class AbstractPropagateItemJob

@brief Abstract class to propagate a single item

@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public abstract class AbstractPropagateItemJob : AbstractPropagatorJob {

    /***********************************************************
    ***********************************************************/
    private AbstractPropagateItemJob restore_job;
    public new JobParallelism parallelism { public get; private set; }

    /***********************************************************
    ***********************************************************/
    public unowned SyncFileItem item;

    /***********************************************************
    set a custom restore job message that is used if the restore job succeeded.
    It is displayed in the activity view.
    ***********************************************************/
    string restore_job_message {
        protected get {
            return this.item.is_restoration ? this.item.error_string: "";
        }
        protected set {
            this.item.is_restoration = true;
            this.item.error_string = value;
        }
    }


    /***********************************************************
    We should always execute jobs that process the E2EE API
    calls as sequential jobs

    TODO: In fact, we must make sure Lock/Unlock are not
    colliding and always wait for each other to complete, so we
    could refactor this "this.parallelism" later so every
    "AbstractPropagateItemJob" that will potentially execute Lock job on
    E2EE folder will get executed sequentially. As an
    alternative, we could optimize Lock/Unlock calls, so we do a
    batch-write on one folder and only lock and unlock a folder
    once per batch.
    ***********************************************************/
    protected AbstractPropagateItemJob (OwncloudPropagator propagator, SyncFileItem item) {
        //  base (propagator);
        //  this.parallelism = JobParallelism.FULL_PARALLELISM;
        //  this.item = item;
        //  this.parallelism = (this.item.is_encrypted || has_encrypted_ancestor ()) ? JobParallelism.WAIT_FOR_FINISHED : JobParallelism.FULL_PARALLELISM;

        //  this.restore_job_message = "";
    }


    ~AbstractPropagateItemJob () {
        //  var p = this.propagator;
        //  if (p) {
        //      // Normally, every job should clean itself from the this.active_job_list. So this should not be
        //      // needed. But if a job has a bug or is deleted before the network jobs signal get received,
        //      // we might risk end up with dangling pointer in the list which may cause crashes.
        //      p.active_job_list.remove_all (this);
        //  }
    }


    /***********************************************************
    ***********************************************************/
    protected bool has_encrypted_ancestor () {
        //  if (!this.propagator.account.capabilities.client_side_encryption_available) {
        //      return false;
        //  }

        //  var path = this.item.file;
        //  var slash_position = path.last_index_of ("/");
        //  var parent_path = slash_position >= 0 ? path.left (slash_position): "";

        //  var path_components = parent_path.split ("/");
        //  while (!path_components == "") {
        //      Common.SyncJournalFileRecord record;
        //      this.propagator.journal.get_file_record (path_components.join ("/"), record);
        //      if (record.is_valid && record.is_e2e_encrypted) {
        //          return true;
        //      }
        //      path_components.remove_last ();
        //  }

        //  return false;
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_restore_job_finished (SyncFileItem.Status status) {
        //  string message;
        //  if (this.restore_job != null) {
        //      message = this.restore_job.restore_job_message;
        //      this.restore_job.restore_job_message;
        //  }

        //  if (status == SyncFileItem.Status.SUCCESS || status == SyncFileItem.Status.CONFLICT
        //      || status == SyncFileItem.Status.RESTORATION) {
        //      on_signal_done (SyncFileItem.Status.SOFT_ERROR, message);
        //  } else {
        //      on_signal_done (status, _("A file or folder was removed from a read only share, but restoring failed : %1").printf (message));
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public new bool on_signal_schedule_self_or_child () {
        //  if (this.state != NotYetStarted) {
        //      return false;
        //  }
        //  GLib.info ("Starting " + this.item.instruction + " propagation of " + this.item.destination () + " by " + this);

        //  this.state = Running;
        //  GLib.Object.invoke_method (this, "start"); // We could be in a different thread (neon jobs)
        //  return true;
    }





    /***********************************************************
    ***********************************************************/
    //  public virtual void start ();



    /***********************************************************
    ***********************************************************/
    protected void on_signal_done (SyncFileItem.Status status, string error_string = "") {
        //  // Duplicate calls to on_signal_done () are a logic error
        //  //  ENFORCE (this.state != Finished);
        //  this.state = Finished;

        //  this.item.status = status_arg;

        //  if (this.item.is_restoration) {
        //      if (this.item.status == SyncFileItem.Status.SUCCESS
        //          || this.item.status == SyncFileItem.Status.CONFLICT) {
        //          this.item.status = SyncFileItem.Status.RESTORATION;
        //      } else {
        //          this.item.error_string += _("; Restoration Failed : %1").printf (error_string);
        //      }
        //  } else {
        //      if (this.item.error_string == "") {
        //          this.item.error_string = error_string;
        //      }
        //  }

        //  if (this.propagator.abort_requested && (this.item.status == SyncFileItem.Status.NORMAL_ERROR
        //                                      || this.item.status == SyncFileItem.Status.FATAL_ERROR)) {
        //      // an abort request is ongoing. Change the status to Soft-Error
        //      this.item.status = SyncFileItem.Status.SOFT_ERROR;
        //  }

        //  // Blocklist handling
        //  switch (this.item.status) {
        //  case SyncFileItem.Status.SOFT_ERROR:
        //  case SyncFileItem.Status.FATAL_ERROR:
        //  case SyncFileItem.Status.NORMAL_ERROR:
        //  case SyncFileItem.Status.DETAIL_ERROR:
        //      // Check the blocklist, possibly adjusting the item (including its status)
        //      blocklist_update (this.propagator.journal, this.item);
        //      break;
        //  case SyncFileItem.Status.SUCCESS:
        //  case SyncFileItem.Status.RESTORATION:
        //      if (this.item.has_blocklist_entry) {
        //          // wipe blocklist entry.
        //          this.propagator.journal.wipe_error_blocklist_entry (this.item.file);
        //          // remove a blocklist entry in case the file was moved.
        //          if (this.item.original_file != this.item.file) {
        //              this.propagator.journal.wipe_error_blocklist_entry (this.item.original_file);
        //          }
        //      }
        //      break;
        //  case SyncFileItem.Status.CONFLICT:
        //  case SyncFileItem.Status.FILE_IGNORED:
        //  case SyncFileItem.Status.NO_STATUS:
        //  case SyncFileItem.Status.BLOCKLISTED_ERROR:
        //  case SyncFileItem.Status.FILE_LOCKED:
        //  case SyncFileItem.Status.FILENAME_INVALID:
        //      // nothing
        //      break;
        //  }

        //  if (this.item.has_error_status ())
        //      GLib.warning ("Could not complete propagation of " + this.item.destination ().to_string () + " by " + this.to_string () + " with status " + this.item.status.to_string () + " and error: " + this.item.error_string);
        //  else
        //      GLib.info ("Completed propagation of " + this.item.destination ().to_string () + " by " + this.to_string () + " with status " + this.item.status.to_string ());
        //  this.propagator.signal_item_completed (this.item);
        //  signal_finished (this.item.status);

        //  if (this.item.status == SyncFileItem.Status.FATAL_ERROR) {
        //      // Abort all remaining jobs.
        //      this.propagator.abort ();
        //  }
    }

} // class AbstractPropagateItemJob

} // namespace LibSync
} // namespace Occ
