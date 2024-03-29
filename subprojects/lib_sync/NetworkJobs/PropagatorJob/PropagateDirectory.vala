namespace Occ {
namespace LibSync {

/***********************************************************
@class PropagateDirectory

@brief Propagate a directory, and all its sub entries.

@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PropagateDirectory : AbstractPropagatorJob {

    /***********************************************************
    ***********************************************************/
    public unowned SyncFileItem item;

    /***********************************************************
    e.g : create the directory
    ***********************************************************/
    public AbstractPropagateItemJob first_job;

    /***********************************************************
    ***********************************************************/
    public PropagatorCompositeJob sub_jobs;

    /***********************************************************
    ***********************************************************/
    public PropagateDirectory (OwncloudPropagator propagator, SyncFileItem item) {
        //  base (propagator);
        //  this.item = item;
        //  this.first_job = propagator.create_job (item);
        //  this.sub_jobs = propagator;
        //  if (this.first_job != null) {
        //      this.first_job.signal_finished.connect (
        //          this.on_signal_first_job_finished
        //      );
        //      this.first_job.associated_composite = this.sub_jobs;
        //  }
        //  this.sub_jobs.signal_finished.connect (
        //      this.on_signal_sub_jobs_finished
        //  );
    }


    /***********************************************************
    ***********************************************************/
    public void append_job (AbstractPropagatorJob propagator_job) {
        //  this.sub_jobs.append_job (propagator_job);
    }


    /***********************************************************
    ***********************************************************/
    public void append_task (SyncFileItem item) {
        //  this.sub_jobs.append_task (item);
    }


    /***********************************************************
    ***********************************************************/
    public new bool on_signal_schedule_self_or_child () {
        //  if (this.state == Finished) {
        //      return false;
        //  }

        //  if (this.state == NotYetStarted) {
        //      this.state = Running;
        //  }

        //  if (this.first_job != null && this.first_job.state == NotYetStarted) {
        //      return this.first_job.on_signal_schedule_self_or_child ();
        //  }

        //  if (this.first_job != null && this.first_job.state == Running) {
        //      // Don't schedule any more job until this is done.
        //      return false;
        //  }

        //  return this.sub_jobs.on_signal_schedule_self_or_child ();
    }


    /***********************************************************
    ***********************************************************/
    public new JobParallelism parallelism () {
        //  // If any of the non-on_signal_finished sub jobs is not parallel, we have to wait
        //  if (this.first_job != null && this.first_job.parallelism != JobParallelism.FULL_PARALLELISM) {
        //      return JobParallelism.WAIT_FOR_FINISHED;
        //  }
        //  if (this.sub_jobs.parallelism () != JobParallelism.FULL_PARALLELISM) {
        //      return JobParallelism.WAIT_FOR_FINISHED;
        //  }
        //  return JobParallelism.FULL_PARALLELISM;
    }


    /***********************************************************
    ***********************************************************/
    public new void abort (AbstractPropagatorJob.AbortType abort_type) {
        //  if (this.first_job != null)
        //      // Force first job to abort synchronously
        //      // even if caller allows async abort (async_abort)
        //      this.first_job.abort (AbstractPropagatorJob.AbortType.SYNCHRONOUS);

        //  if (abort_type == AbstractPropagatorJob.AbortType.ASYNCHRONOUS) {
        //      this.sub_jobs.signal_abort_finished.connect (
        //          this.on_signal_abort_finished
        //      );
        //  }
        //  this.sub_jobs.abort (abort_type);
    }


    /***********************************************************
    ***********************************************************/
    public void increase_affected_count () {
        //  this.first_job.item.affected_items++;
    }


    /***********************************************************
    ***********************************************************/
    public new int64 committed_disk_space () {
        //  return this.sub_jobs.committed_disk_space ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_first_job_finished (SyncFileItem.Status status) {
        //  this.first_job.take ().delete_later ();

        //  if (status != SyncFileItem.Status.SUCCESS
        //      && status != SyncFileItem.Status.RESTORATION
        //      && status != SyncFileItem.Status.CONFLICT) {
        //      if (this.state != Finished) {
        //          // Synchronously abort
        //          abort (AbstractPropagatorJob.AbortType.SYNCHRONOUS);
        //          this.state = Finished;
        //          GLib.info ("PropagateDirectory.on_signal_first_job_finished " + " emit finished " + status.to_string ());
        //          signal_finished (status);
        //      }
        //      return;
        //  }

        //  this.propagator.schedule_next_job ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sub_jobs_finished (SyncFileItem.Status status) {
        //  if (this.item != null && status == SyncFileItem.Status.SUCCESS) {
        //      // If a directory is renamed, recursively delete any stale items
        //      // that may still exist below the old path.
        //      if (this.item.instruction == CSync.SyncInstructions.RENAME
        //          && this.item.original_file != this.item.rename_target) {
        //          this.propagator.journal.delete_file_record (this.item.original_file, true);
        //      }

        //      if (this.item.instruction == CSync.SyncInstructions.NEW && this.item.direction == SyncFileItem.Direction.DOWN) {
        //          // special case for local MKDIR, set local directory mtime
        //          // (it's not synced later at all, but can be nice to have it set initially)

        //          if (this.item.modtime <= 0) {
        //              status = this.item.status = SyncFileItem.Status.NORMAL_ERROR;
        //              this.item.error_string = _("Error updating metadata due to invalid modified time");
        //              GLib.warning ("Error writing to the database for file " + this.item.file);
        //          }

        //          FileSystem.mod_time (this.propagator.full_local_path (this.item.destination ()), this.item.modtime);
        //      }

        //      // For new directories we always want to update the etag once
        //      // the directory has been propagated. Otherwise the directory
        //      // could appear locally without being added to the database.
        //      if (this.item.instruction == CSync.SyncInstructions.RENAME
        //          || this.item.instruction == CSync.SyncInstructions.NEW
        //          || this.item.instruction == CSync.SyncInstructions.UPDATE_METADATA) {
        //          var result = this.propagator.update_metadata (this.item);
        //          if (!result) {
        //              status = this.item.status = SyncFileItem.Status.FATAL_ERROR;
        //              this.item.error_string = _("Error updating metadata : %1").printf (result.error);
        //              GLib.warning ("Error writing to the database for file " + this.item.file + " with " + result.error);
        //          } else if (result == Common.AbstractVfs.ConvertToPlaceholderResult.Locked) {
        //              this.item.status = SyncFileItem.Status.SOFT_ERROR;
        //              this.item.error_string = _("File is currently in use");
        //          }
        //      }
        //  }
        //  this.state = Finished;
        //  GLib.info ("PropagateDirectory.on_signal_sub_jobs_finished " + " emit finished " + status.to_string ());
        //  signal_finished (status);
    }

} // class PropagateDirectory

} // namespace LibSync
} // namespace Occ
