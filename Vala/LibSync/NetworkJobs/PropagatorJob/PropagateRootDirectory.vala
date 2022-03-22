/***********************************************************
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@class PropagateRootDirectory

@brief Propagate the root directory, and all its sub entries.

@details Primary difference to PropagateDirectory is that it
keeps track of directory deletions that must happen at the
very end.

@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PropagateRootDirectory : PropagateDirectory {

    /***********************************************************
    ***********************************************************/
    public PropagatorCompositeJob dir_deletion_jobs;

    /***********************************************************
    ***********************************************************/
    public PropagateRootDirectory (OwncloudPropagator propagator) {
        base (propagator, new SyncFileItem ());
        this.dir_deletion_jobs = propagator;
        this.dir_deletion_jobs.signal_finished.connect (
            this.on_signal_dir_deletion_jobs_finished
        );
    }


    /***********************************************************
    ***********************************************************/
    public new bool on_signal_schedule_self_or_child () {
        GLib.info ("on_signal_schedule_self_or_child " + this.state + " pending uploads" + this.propagator.delayed_tasks ().size () + " subjobs state " + this.sub_jobs.state);

        if (this.state == Finished) {
            return false;
        }

        if (PropagateDirectory.on_signal_schedule_self_or_child () && this.propagator.delayed_tasks ().empty ()) {
            return true;
        }

        // Important : Finish this.sub_jobs before scheduling any deletes.
        if (this.sub_jobs.state != Finished) {
            return false;
        }

        if (!this.propagator.delayed_tasks ().empty ()) {
            return schedule_delayed_jobs ();
        }

        return this.dir_deletion_jobs.on_signal_schedule_self_or_child ();
    }


    /***********************************************************
    ***********************************************************/
    public new JobParallelism parallelism () {
        // the root directory parallelism isn't important
        return JobParallelism.WAIT_FOR_FINISHED;
    }


    class AbortsFinished {
        public bool sub_jobs_finished = false;
        public bool dir_deletion_finished = false;
    }


    /***********************************************************
    ***********************************************************/
    public new void abort (AbstractPropagatorJob.AbortType abort_type) {
        if (this.first_job != null) {
            // Force first job to abort synchronously
            // even if caller allows async abort (async_abort)
            this.first_job.abort (AbstractPropagatorJob.AbortType.SYNCHRONOUS);
        }

        if (abort_type == AbstractPropagatorJob.AbortType.ASYNCHRONOUS) {
            var abort_status = new AbortsFinished ();

            this.sub_jobs.signal_abort_finished.connect (
                this.on_signal_sub_jobs_abort_finished
            );
            this.dir_deletion_jobs.signal_abort_finished.connect (
                this,
                this.on_signal_ir_deletion_jobs_abort_finished
            );
        }
        this.sub_jobs.abort (abort_type);
        this.dir_deletion_jobs.abort (abort_type);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sub_jobs_abort_finished (AbortsFinished abort_status) {
        abort_status.sub_jobs_finished = true;
        if (abort_status.sub_jobs_finished && abort_status.dir_deletion_finished) {
            /* emit */ signal_abort_finished ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_ir_deletion_jobs_abort_finished (AbortsFinished abort_status) {
        abort_status.dir_deletion_finished = true;
        if (abort_status.sub_jobs_finished && abort_status.dir_deletion_finished) {
            /* emit */ signal_abort_finished ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public new int64 committed_disk_space () {
        return this.sub_jobs.committed_disk_space () + this.dir_deletion_jobs.committed_disk_space ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_dir_deletion_jobs_finished (SyncFileItem.Status status) {
        this.state = Finished;
        GLib.info ("PropagateRootDirectory.on_signal_dir_deletion_jobs_finished " + " emit finished " + status.to_string ());
        /* emit */ signal_finished (status);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sub_jobs_finished (SyncFileItem.Status status) {
        GLib.info (status.to_string () + " on_signal_sub_jobs_finished " + this.state.to_string () + " pending uploads " + this.propagator.delayed_tasks ().size () + " subjobs state " + this.sub_jobs.state);

        if (!this.propagator.delayed_tasks ().empty ()) {
            schedule_delayed_jobs ();
            return;
        }

        if (status != SyncFileItem.Status.SUCCESS
            && status != SyncFileItem.Status.RESTORATION
            && status != SyncFileItem.Status.CONFLICT) {
            if (this.state != Finished) {
                // Synchronously abort
                abort (AbstractPropagatorJob.AbortType.SYNCHRONOUS);
                this.state = Finished;
                GLib.info ("PropagateRootDirectory.on_signal_sub_jobs_finished " + " emit finished " + status.to_string ());
                /* emit */ signal_finished (status);
            }
            return;
        }

        this.propagator.schedule_next_job ();
    }


    /***********************************************************
    ***********************************************************/
    private bool schedule_delayed_jobs () {
        GLib.info ("PropagateRootDirectory.schedule_delayed_jobs");
        this.propagator.schedule_delayed_tasks (true);
        var bulk_propagator_job = std.make_unique<BulkPropagatorJob> (this.propagator, this.propagator.delayed_tasks ());
        this.propagator.clear_delayed_tasks ();
        this.sub_jobs.append_job (bulk_propagator_job.release ());
        this.sub_jobs.state = Running;
        return this.sub_jobs.on_signal_schedule_self_or_child ();
    }

} // class PropagateRootDirectory

} // namespace LibSync
} // namespace Occ
