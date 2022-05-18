namespace Occ {
namespace LibSync {

/***********************************************************
@class PropagatorCompositeJob

@brief Job that runs subjobs. It becomes finished only when
all subjobs are finished.

@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PropagatorCompositeJob : AbstractPropagatorJob {

    public GLib.List<AbstractPropagatorJob> jobs_to_do;
    public GLib.List<unowned SyncFileItem> tasks_to_do;
    public GLib.List<AbstractPropagatorJob> running_jobs;

    /***********************************************************
    NO_STATUS, or NormalError / SoftError if there was an error
    ***********************************************************/
    public SyncFileItem.Status has_error;

    public uint64 aborts_count;

    /***********************************************************
    ***********************************************************/
    public PropagatorCompositeJob (OwncloudPropagator propagator) {
        base (propagator);
        this.has_error = SyncFileItem.Status.NO_STATUS;
        this.aborts_count = 0;
    }


    /***********************************************************
    Don't delete jobs in this.jobs_to_do and this.running_jobs:
    they have parents that will be responsible for cleanup.
    Deleting them here would risk deleting something that has
    already been deleted by a shared parent.
    ***********************************************************/
    //  ~PropagatorCompositeJob () override = default;

    /***********************************************************
    ***********************************************************/
    public void append_job (AbstractPropagatorJob propagator_job) {
        propagator_job.associated_composite = this;
        this.jobs_to_do.append (propagator_job);
    }


    /***********************************************************
    ***********************************************************/
    public void append_task (SyncFileItem item) {
        this.tasks_to_do.append (item);
    }


    /***********************************************************
    ***********************************************************/
    public new bool on_signal_schedule_self_or_child () {
        if (this.state == Finished) {
            return false;
        }

        // Start the composite job
        if (this.state == NotYetStarted) {
            this.state = Running;
        }

        // Ask all the running composite jobs if they have something new to schedule.
        foreach (var running_job in q_as_const (this.running_jobs)) {
            //  GLib.assert_true (running_job.state == Running);

            if (on_signal_possibly_run_next_job (running_job)) {
                return true;
            }

            // If any of the running sub jobs is not parallel, we have to cancel the scheduling
            // of the rest of the list and wait for the blocking job to finish and schedule the next one.
            var paral = running_job.parallelism ();
            if (paral == JobParallelism.WAIT_FOR_FINISHED) {
                return false;
            }
        }

        // Now it's our turn, check if we have something left to do.
        // First, convert a task to a job if necessary
        while (this.jobs_to_do == null && this.tasks_to_!= null) {
            unowned SyncFileItem next_task = this.tasks_to_do.nth_data (0);
            this.tasks_to_do.remove (0);
            AbstractPropagatorJob propagator_job = this.propagator.create_job (next_task);
            if (!propagator_job) {
                GLib.warning ("Useless task found for file " + next_task.destination () + " instruction " + next_task.instruction);
                continue;
            }
            append_job (propagator_job);
            break;
        }
        // Then run the next job
        if (this.jobs_to_do != null) {
            AbstractPropagatorJob next_job = this.jobs_to_do.nth_data (0);
            this.jobs_to_do.remove (0);
            this.running_jobs.append (next_job);
            return on_signal_possibly_run_next_job (next_job);
        }

        // If neither us or our children had stuff left to do we could hang. Make sure
        // we mark this job as on_signal_finished so that the propagator can schedule a new one.
        if (this.jobs_to_do.length () == 0 && this.tasks_to_do.length () == 0 && this.running_jobs.length () == 0) {
            // Our parent jobs are already iterating over their running jobs, post to the event loop
            // to avoid removing ourself from that list while they iterate.
            GLib.Object.invoke_method (this, "on_signal_finalize", GLib.QueuedConnection);
        }
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public new JobParallelism parallelism () {
        // If any of the running sub jobs is not parallel, we have to wait
        for (int i = 0; i < this.running_jobs.length; ++i) {
            if (this.running_jobs.at (i).parallelism () != JobParallelism.FULL_PARALLELISM) {
                return this.running_jobs.at (i).parallelism ();
            }
        }
        return JobParallelism.FULL_PARALLELISM;
    }


    /***********************************************************
    Abort synchronously or asynchronously - some jobs
    require to be on_signal_finished without immediete abort (abort on job might
    cause conflicts/duplicated files - owncloud/client/issues/5949)
    ***********************************************************/
    public new void abort (AbstractPropagatorJob.AbortType abort_type) {
        if (!this.running_jobs.empty ()) {
            this.aborts_count = this.running_jobs.size ();
            foreach (AbstractPropagatorJob propagator_job in this.running_jobs) {
                if (abort_type == AbstractPropagatorJob.AbortType.ASYNCHRONOUS) {
                    propagator_job.signal_abort_finished.connect (
                        this.on_signal_sub_job_abort_finished
                    );
                }
                propagator_job.abort (abort_type);
            }
        } else if (abort_type == AbstractPropagatorJob.AbortType.ASYNCHRONOUS) {
            signal_abort_finished ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public new int64 committed_disk_space () {
        int64 needed = 0;
        foreach (AbstractPropagatorJob propagator_job in this.running_jobs) {
            needed += propagator_job.committed_disk_space ();
        }
        return needed;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sub_job_abort_finished () {
        // Count that job has been on_signal_finished
        this.aborts_count--;

        // Emit abort if last job has been aborted
        if (this.aborts_count == 0) {
            signal_abort_finished ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_possibly_run_next_job (AbstractPropagatorJob next_propagator_job) {
        if (next_propagator_job.state == NotYetStarted) {
            next_propagator_job.signal_finished.connect (
                this.on_signal_next_propagator_job_finished
            );
        }
        return next_propagator_job.on_signal_schedule_self_or_child ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_next_propagator_job_finished (SyncFileItem.Status status) {
        var sub_job = (AbstractPropagatorJob)sender ();
        //  GLib.assert_true (sub_job);

        // Delete the job and remove it from our list of jobs.
        sub_job.delete_later ();
        int i = this.running_jobs.index_of (sub_job);
        //  ENFORCE (i >= 0); // should only happen if this function is called more than once
        this.running_jobs.remove (i);

        // Any sub job error will cause the whole composite to fail. This is important
        // for knowing whether to update the etag in PropagateDirectory, for example.
        if (status == SyncFileItem.Status.FATAL_ERROR
            || status == SyncFileItem.Status.NORMAL_ERROR
            || status == SyncFileItem.Status.SOFT_ERROR
            || status == SyncFileItem.Status.DETAIL_ERROR
            || status == SyncFileItem.Status.BLOCKLISTED_ERROR) {
            this.has_error = status;
        }

        if (this.jobs_to_do.length () == 0 && this.tasks_to_do.length () == 0 && this.running_jobs.length () == 0) {
            on_signal_finalize ();
        } else {
            this.propagator.schedule_next_job ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_finalize () {
        // The propagator will do parallel scheduling and this could be posted
        // multiple times on the event loop, ignore the duplicate calls.
        if (this.state == Finished)
            return;

        this.state = Finished;
        signal_finished (this.has_error == SyncFileItem.Status.NO_STATUS ? SyncFileItem.Status.SUCCESS : this.has_error);
    }

} // class PropagatorCompositeJob

} // namespace LibSync
} // namespace Occ
