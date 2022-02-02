
/***********************************************************
@brief Propagate a directory, and all its sub entries.
@ingroup libsync
***********************************************************/
class PropagateDirectory : PropagatorJob {

    /***********************************************************
    ***********************************************************/
    public SyncFileItemPtr this.item;
    // e.g : create the directory
    public QScopedPointer<PropagateItemJob> this.first_job;

    /***********************************************************
    ***********************************************************/
    public PropagatorCompositeJob this.sub_jobs;

    /***********************************************************
    ***********************************************************/
    public PropagateDirectory (OwncloudPropagator propagator, SyncFileItemPtr item);

    /***********************************************************
    ***********************************************************/
    public void append_job (PropagatorJob job) {
        this.sub_jobs.append_job (job);
    }


    /***********************************************************
    ***********************************************************/
    public void append_task (SyncFileItemPtr item) {
        this.sub_jobs.append_task (item);
    }


    /***********************************************************
    ***********************************************************/
    public bool on_schedule_self_or_child () override;
    public JobParallelism parallelism () override;
    public void on_abort (PropagatorJob.AbortType abort_type) override {
        if (this.first_job)
            // Force first job to on_abort synchronously
            // even if caller allows async on_abort (async_abort)
            this.first_job.on_abort (AbortType.Synchronous);

        if (abort_type == AbortType.Asynchronous){
            connect (&this.sub_jobs, &PropagatorCompositeJob.abort_finished, this, &PropagateDirectory.abort_finished);
        }
        this.sub_jobs.on_abort (abort_type);
    }


    /***********************************************************
    ***********************************************************/
    public void increase_affected_count () {
        this.first_job._item._affected_items++;
    }


    /***********************************************************
    ***********************************************************/
    public int64 committed_disk_space () override {
        return this.sub_jobs.committed_disk_space ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_first_job_finished (SyncFileItem.Status status);
    private on_ virtual void on_sub_jobs_finished (SyncFileItem.Status status);

}



    PropagateDirectory.PropagateDirectory (OwncloudPropagator propagator, SyncFileItemPtr item)
        : PropagatorJob (propagator)
        , this.item (item)
        , this.first_job (propagator.create_job (item))
        , this.sub_jobs (propagator) {
        if (this.first_job) {
            connect (this.first_job.data (), &PropagatorJob.on_finished, this, &PropagateDirectory.on_first_job_finished);
            this.first_job.set_associated_composite (&this.sub_jobs);
        }
        connect (&this.sub_jobs, &PropagatorJob.on_finished, this, &PropagateDirectory.on_sub_jobs_finished);
    }

    PropagatorJob.JobParallelism PropagateDirectory.parallelism () {
        // If any of the non-on_finished sub jobs is not parallel, we have to wait
        if (this.first_job && this.first_job.parallelism () != FullParallelism) {
            return WaitForFinished;
        }
        if (this.sub_jobs.parallelism () != FullParallelism) {
            return WaitForFinished;
        }
        return FullParallelism;
    }

    bool PropagateDirectory.on_schedule_self_or_child () {
        if (this.state == Finished) {
            return false;
        }

        if (this.state == NotYetStarted) {
            this.state = Running;
        }

        if (this.first_job && this.first_job._state == NotYetStarted) {
            return this.first_job.on_schedule_self_or_child ();
        }

        if (this.first_job && this.first_job._state == Running) {
            // Don't schedule any more job until this is done.
            return false;
        }

        return this.sub_jobs.on_schedule_self_or_child ();
    }

    void PropagateDirectory.on_first_job_finished (SyncFileItem.Status status) {
        this.first_job.take ().delete_later ();

        if (status != SyncFileItem.Status.SUCCESS
            && status != SyncFileItem.Status.RESTORATION
            && status != SyncFileItem.Status.CONFLICT) {
            if (this.state != Finished) {
                // Synchronously on_abort
                on_abort (AbortType.Synchronous);
                this.state = Finished;
                q_c_info (lc_propagator) << "PropagateDirectory.on_first_job_finished" << "emit finished" << status;
                /* emit */ finished (status);
            }
            return;
        }

        propagator ().schedule_next_job ();
    }

    void PropagateDirectory.on_sub_jobs_finished (SyncFileItem.Status status) {
        if (!this.item.is_empty () && status == SyncFileItem.Status.SUCCESS) {
            // If a directory is renamed, recursively delete any stale items
            // that may still exist below the old path.
            if (this.item._instruction == CSYNC_INSTRUCTION_RENAME
                && this.item._original_file != this.item._rename_target) {
                propagator ()._journal.delete_file_record (this.item._original_file, true);
            }

            if (this.item._instruction == CSYNC_INSTRUCTION_NEW && this.item._direction == SyncFileItem.Direction.DOWN) {
                // special case for local MKDIR, set local directory mtime
                // (it's not synced later at all, but can be nice to have it set initially)

                if (this.item._modtime <= 0) {
                    status = this.item._status = SyncFileItem.Status.NORMAL_ERROR;
                    this.item._error_string = _("Error updating metadata due to invalid modified time");
                    GLib.warn (lc_directory) << "Error writing to the database for file" << this.item._file;
                }

                FileSystem.set_mod_time (propagator ().full_local_path (this.item.destination ()), this.item._modtime);
            }

            // For new directories we always want to update the etag once
            // the directory has been propagated. Otherwise the directory
            // could appear locally without being added to the database.
            if (this.item._instruction == CSYNC_INSTRUCTION_RENAME
                || this.item._instruction == CSYNC_INSTRUCTION_NEW
                || this.item._instruction == CSYNC_INSTRUCTION_UPDATE_METADATA) {
                const var result = propagator ().update_metadata (*this.item);
                if (!result) {
                    status = this.item._status = SyncFileItem.Status.FATAL_ERROR;
                    this.item._error_string = _("Error updating metadata : %1").arg (result.error ());
                    GLib.warn (lc_directory) << "Error writing to the database for file" << this.item._file << "with" << result.error ();
                } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
                    this.item._status = SyncFileItem.Status.SOFT_ERROR;
                    this.item._error_string = _("File is currently in use");
                }
            }
        }
        this.state = Finished;
        q_c_info (lc_propagator) << "PropagateDirectory.on_sub_jobs_finished" << "emit finished" << status;
        /* emit */ finished (status);
    }