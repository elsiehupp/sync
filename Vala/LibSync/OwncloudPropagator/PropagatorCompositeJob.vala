/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief Job that runs subjobs. It becomes on_finished only when all subjobs are on_finished.
@ingroup libsync
***********************************************************/
class PropagatorCompositeJob : PropagatorJob {

    public GLib.Vector<PropagatorJob> jobs_to_do;
    public SyncFileItemVector tasks_to_do;
    public GLib.Vector<PropagatorJob> running_jobs;

    /***********************************************************
    NoStatus, or NormalError / SoftError if there was an error
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
    ~PropagatorCompositeJob () override = default;

    /***********************************************************
    ***********************************************************/
    public void append_job (PropagatorJob job) {
        job.set_associated_composite (this);
        this.jobs_to_do.append (job);
    }


    /***********************************************************
    ***********************************************************/
    public void append_task (SyncFileItemPtr item) {
        this.tasks_to_do.append (item);
    }


    /***********************************************************
    ***********************************************************/
    public bool on_schedule_self_or_child () {
        if (this.state == Finished) {
            return false;
        }

        // Start the composite job
        if (this.state == NotYetStarted) {
            this.state = Running;
        }

        // Ask all the running composite jobs if they have something new to schedule.
        for (var running_job : q_as_const (this.running_jobs)) {
            //  ASSERT (running_job.state == Running);

            if (on_possibly_run_next_job (running_job)) {
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
        while (this.jobs_to_do.is_empty () && !this.tasks_to_do.is_empty ()) {
            SyncFileItemPtr next_task = this.tasks_to_do.first ();
            this.tasks_to_do.remove (0);
            PropagatorJob job = propagator ().create_job (next_task);
            if (!job) {
                GLib.warn (lc_directory) << "Useless task found for file" << next_task.destination () << "instruction" << next_task.instruction;
                continue;
            }
            append_job (job);
            break;
        }
        // Then run the next job
        if (!this.jobs_to_do.is_empty ()) {
            PropagatorJob next_job = this.jobs_to_do.first ();
            this.jobs_to_do.remove (0);
            this.running_jobs.append (next_job);
            return on_possibly_run_next_job (next_job);
        }

        // If neither us or our children had stuff left to do we could hang. Make sure
        // we mark this job as on_finished so that the propagator can schedule a new one.
        if (this.jobs_to_do.is_empty () && this.tasks_to_do.is_empty () && this.running_jobs.is_empty ()) {
            // Our parent jobs are already iterating over their running jobs, post to the event loop
            // to avoid removing ourself from that list while they iterate.
            QMetaObject.invoke_method (this, "on_finalize", Qt.QueuedConnection);
        }
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public JobParallelism parallelism () {
        // If any of the running sub jobs is not parallel, we have to wait
        for (int i = 0; i < this.running_jobs.count (); ++i) {
            if (this.running_jobs.at (i).parallelism () != JobParallelism.FULL_PARALLELISM) {
                return this.running_jobs.at (i).parallelism ();
            }
        }
        return JobParallelism.FULL_PARALLELISM;
    }


    /***********************************************************
    Abort synchronously or asynchronously - some jobs
    require to be on_finished without immediete on_abort (on_abort on job might
    cause conflicts/duplicated files - owncloud/client/issues/5949)
    ***********************************************************/
    public void on_abort (PropagatorJob.AbortType abort_type) override {
        if (!this.running_jobs.empty ()) {
            this.aborts_count = this.running_jobs.size ();
            foreach (PropagatorJob j, this.running_jobs) {
                if (abort_type == AbortType.ASYNCHRONOUS) {
                    connect (j, &PropagatorJob.abort_finished,
                            this, &PropagatorCompositeJob.on_sub_job_abort_finished);
                }
                j.on_abort (abort_type);
            }
        } else if (abort_type == AbortType.ASYNCHRONOUS){
            /* emit */ abort_finished ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public int64 committed_disk_space () {
        int64 needed = 0;
        foreach (PropagatorJob job, this.running_jobs) {
            needed += job.committed_disk_space ();
        }
        return needed;
    }


    /***********************************************************
    ***********************************************************/
    private void on_sub_job_abort_finished () {
        // Count that job has been on_finished
        this.aborts_count--;

        // Emit on_abort if last job has been aborted
        if (this.aborts_count == 0) {
            /* emit */ abort_finished ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private bool on_possibly_run_next_job (PropagatorJob next) {
        if (next.state == NotYetStarted) {
            connect (next, &PropagatorJob.on_finished, this, &PropagatorCompositeJob.on_sub_job_finished);
        }
        return next.on_schedule_self_or_child ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_sub_job_finished (SyncFileItem.Status status) {
        var sub_job = static_cast<PropagatorJob> (sender ());
        //  ASSERT (sub_job);

        // Delete the job and remove it from our list of jobs.
        sub_job.delete_later ();
        int i = this.running_jobs.index_of (sub_job);
        ENFORCE (i >= 0); // should only happen if this function is called more than once
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

        if (this.jobs_to_do.is_empty () && this.tasks_to_do.is_empty () && this.running_jobs.is_empty ()) {
            on_finalize ();
        } else {
            propagator ().schedule_next_job ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_finalize () {
        // The propagator will do parallel scheduling and this could be posted
        // multiple times on the event loop, ignore the duplicate calls.
        if (this.state == Finished)
            return;

        this.state = Finished;
        /* emit */ finished (this.has_error == SyncFileItem.Status.NO_STATUS ? SyncFileItem.Status.SUCCESS : this.has_error);
    }

} // class PropagatorCompositeJob

} // namespace Occ
