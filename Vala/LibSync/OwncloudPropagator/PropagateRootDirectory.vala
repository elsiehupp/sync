/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief Propagate the root directory, and all its sub entries.
@ingroup libsync

Primary difference to PropagateDirectory is that it keeps track of directory
deletions that must happen at the very end.
***********************************************************/
class PropagateRootDirectory : PropagateDirectory {

    /***********************************************************
    ***********************************************************/
    public PropagatorCompositeJob dir_deletion_jobs;

    /***********************************************************
    ***********************************************************/
    public PropagateRootDirectory (OwncloudPropagator propagator) {
        base (propagator, SyncFileItemPtr (new SyncFileItem ()));
        this.dir_deletion_jobs = propagator;
        connect (&this.dir_deletion_jobs, &PropagatorJob.on_signal_finished, this, &PropagateRootDirectory.on_signal_dir_deletion_jobs_finished);
    }


    /***********************************************************
    ***********************************************************/
    public bool on_signal_schedule_self_or_child () {
        GLib.info ()) + "on_signal_schedule_self_or_child" + this.state + "pending uploads" + propagator ().delayed_tasks ().size ("subjobs state" + this.sub_jobs.state;

        if (this.state == Finished) {
            return false;
        }

        if (PropagateDirectory.on_signal_schedule_self_or_child () && propagator ().delayed_tasks ().empty ()) {
            return true;
        }

        // Important : Finish this.sub_jobs before scheduling any deletes.
        if (this.sub_jobs.state != Finished) {
            return false;
        }

        if (!propagator ().delayed_tasks ().empty ()) {
            return schedule_delayed_jobs ();
        }

        return this.dir_deletion_jobs.on_signal_schedule_self_or_child ();
    }


    /***********************************************************
    ***********************************************************/
    public JobParallelism parallelism () {
        // the root directory parallelism isn't important
        return JobParallelism.WAIT_FOR_FINISHED;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_abort (PropagatorJob.AbortType abort_type) {
        if (this.first_job)
            // Force first job to on_signal_abort synchronously
            // even if caller allows async on_signal_abort (async_abort)
            this.first_job.on_signal_abort (AbortType.SYNCHRONOUS);

        if (abort_type == AbortType.ASYNCHRONOUS) {
            struct AbortsFinished {
                bool sub_jobs_finished = false;
                bool dir_deletion_finished = false;
            }
            var abort_status = new unowned AbortsFinished (new AbortsFinished);

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
        this.sub_jobs.on_signal_abort (abort_type);
        this.dir_deletion_jobs.on_signal_abort (abort_type);
    }


    /***********************************************************
    ***********************************************************/
    public int64 committed_disk_space () {
        return this.sub_jobs.committed_disk_space () + this.dir_deletion_jobs.committed_disk_space ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_dir_deletion_jobs_finished (SyncFileItem.Status status) {
        this.state = Finished;
        GLib.info ("PropagateRootDirectory.on_signal_dir_deletion_jobs_finished" + "emit finished" + status;
        /* emit */ finished (status);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sub_jobs_finished (SyncFileItem.Status status) {
        GLib.info ()) + status + "on_signal_sub_jobs_finished" + this.state + "pending uploads" + propagator ().delayed_tasks ().size ("subjobs state" + this.sub_jobs.state;

        if (!propagator ().delayed_tasks ().empty ()) {
            schedule_delayed_jobs ();
            return;
        }

        if (status != SyncFileItem.Status.SUCCESS
            && status != SyncFileItem.Status.RESTORATION
            && status != SyncFileItem.Status.CONFLICT) {
            if (this.state != Finished) {
                // Synchronously on_signal_abort
                on_signal_abort (AbortType.SYNCHRONOUS);
                this.state = Finished;
                GLib.info ("PropagateRootDirectory.on_signal_sub_jobs_finished" + "emit finished" + status;
                /* emit */ finished (status);
            }
            return;
        }

        propagator ().schedule_next_job ();
    }


    /***********************************************************
    ***********************************************************/
    private bool schedule_delayed_jobs () {
        GLib.info ("PropagateRootDirectory.schedule_delayed_jobs";
        propagator ().schedule_delayed_tasks (true);
        var bulk_propagator_job = std.make_unique<BulkPropagatorJob> (propagator (), propagator ().delayed_tasks ());
        propagator ().clear_delayed_tasks ();
        this.sub_jobs.append_job (bulk_propagator_job.release ());
        this.sub_jobs.state = Running;
        return this.sub_jobs.on_signal_schedule_self_or_child ();
    }

} // class PropagateRootDirectory

} // namespace Occ
