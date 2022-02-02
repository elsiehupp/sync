
/***********************************************************
@brief Propagate the root directory, and all its sub entries.
@ingroup libsync

Primary difference to PropagateDirectory is that it keeps track of directory
deletions that must happen at the very end.
***********************************************************/
class PropagateRootDirectory : PropagateDirectory {

    /***********************************************************
    ***********************************************************/
    public PropagatorCompositeJob this.dir_deletion_jobs;

    /***********************************************************
    ***********************************************************/
    public PropagateRootDirectory (OwncloudPropagator propagator);

    /***********************************************************
    ***********************************************************/
    public bool on_schedule_self_or_child () override;
    public JobParallelism parallelism () override;
    public void on_abort (PropagatorJob.AbortType abort_type) override;

    /***********************************************************
    ***********************************************************/
    public int64 committed_disk_space () override;


    /***********************************************************
    ***********************************************************/
    private void on_sub_jobs_finished (SyncFileItem.Status status) override;

    /***********************************************************
    ***********************************************************/
    private 
    private bool schedule_delayed_jobs ();
}




    PropagateRootDirectory.PropagateRootDirectory (OwncloudPropagator propagator)
        : PropagateDirectory (propagator, SyncFileItemPtr (new SyncFileItem))
        , this.dir_deletion_jobs (propagator) {
        connect (&this.dir_deletion_jobs, &PropagatorJob.on_finished, this, &PropagateRootDirectory.on_dir_deletion_jobs_finished);
    }

    PropagatorJob.JobParallelism PropagateRootDirectory.parallelism () {
        // the root directory parallelism isn't important
        return WaitForFinished;
    }

    void PropagateRootDirectory.on_abort (PropagatorJob.AbortType abort_type) {
        if (this.first_job)
            // Force first job to on_abort synchronously
            // even if caller allows async on_abort (async_abort)
            this.first_job.on_abort (AbortType.Synchronous);

        if (abort_type == AbortType.Asynchronous) {
            struct AbortsFinished {
                bool sub_jobs_finished = false;
                bool dir_deletion_finished = false;
            };
            var abort_status = unowned<AbortsFinished> (new AbortsFinished);

            connect (&this.sub_jobs, &PropagatorCompositeJob.abort_finished, this, [this, abort_status] () {
                abort_status.sub_jobs_finished = true;
                if (abort_status.sub_jobs_finished && abort_status.dir_deletion_finished)
                    /* emit */ abort_finished ();
            });
            connect (&this.dir_deletion_jobs, &PropagatorCompositeJob.abort_finished, this, [this, abort_status] () {
                abort_status.dir_deletion_finished = true;
                if (abort_status.sub_jobs_finished && abort_status.dir_deletion_finished)
                    /* emit */ abort_finished ();
            });
        }
        this.sub_jobs.on_abort (abort_type);
        this.dir_deletion_jobs.on_abort (abort_type);
    }

    int64 PropagateRootDirectory.committed_disk_space () {
        return this.sub_jobs.committed_disk_space () + this.dir_deletion_jobs.committed_disk_space ();
    }

    bool PropagateRootDirectory.on_schedule_self_or_child () {
        q_c_info (lc_root_directory ()) << "on_schedule_self_or_child" << this.state << "pending uploads" << propagator ().delayed_tasks ().size () << "subjobs state" << this.sub_jobs._state;

        if (this.state == Finished) {
            return false;
        }

        if (PropagateDirectory.on_schedule_self_or_child () && propagator ().delayed_tasks ().empty ()) {
            return true;
        }

        // Important : Finish this.sub_jobs before scheduling any deletes.
        if (this.sub_jobs._state != Finished) {
            return false;
        }

        if (!propagator ().delayed_tasks ().empty ()) {
            return schedule_delayed_jobs ();
        }

        return this.dir_deletion_jobs.on_schedule_self_or_child ();
    }

    void PropagateRootDirectory.on_sub_jobs_finished (SyncFileItem.Status status) {
        q_c_info (lc_root_directory ()) << status << "on_sub_jobs_finished" << this.state << "pending uploads" << propagator ().delayed_tasks ().size () << "subjobs state" << this.sub_jobs._state;

        if (!propagator ().delayed_tasks ().empty ()) {
            schedule_delayed_jobs ();
            return;
        }

        if (status != SyncFileItem.Status.SUCCESS
            && status != SyncFileItem.Status.RESTORATION
            && status != SyncFileItem.Status.CONFLICT) {
            if (this.state != Finished) {
                // Synchronously on_abort
                on_abort (AbortType.Synchronous);
                this.state = Finished;
                q_c_info (lc_propagator) << "PropagateRootDirectory.on_sub_jobs_finished" << "emit finished" << status;
                /* emit */ finished (status);
            }
            return;
        }

        propagator ().schedule_next_job ();
    }

    void PropagateRootDirectory.on_dir_deletion_jobs_finished (SyncFileItem.Status status) {
        this.state = Finished;
        q_c_info (lc_propagator) << "PropagateRootDirectory.on_dir_deletion_jobs_finished" << "emit finished" << status;
        /* emit */ finished (status);
    }

    bool PropagateRootDirectory.schedule_delayed_jobs () {
        q_c_info (lc_propagator) << "PropagateRootDirectory.schedule_delayed_jobs";
        propagator ().set_schedule_delayed_tasks (true);
        var bulk_propagator_job = std.make_unique<BulkPropagatorJob> (propagator (), propagator ().delayed_tasks ());
        propagator ().clear_delayed_tasks ();
        this.sub_jobs.append_job (bulk_propagator_job.release ());
        this.sub_jobs._state = Running;
        return this.sub_jobs.on_schedule_self_or_child ();
    }
