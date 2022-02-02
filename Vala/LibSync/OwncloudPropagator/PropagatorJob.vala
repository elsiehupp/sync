
/***********************************************************
@brief the base class of propagator jobs

This can either be a job, or a container for jobs.
If it is a composite job, it then inherits from PropagateDirectory

@ingroup libsync
***********************************************************/
class PropagatorJob : GLib.Object {


    /***********************************************************
    ***********************************************************/
    public PropagatorJob (OwncloudPropagator propagator);

    /***********************************************************
    ***********************************************************/
    public enum AbortType {
        Synchronous,
        Asynchronous
    };

    /***********************************************************
    ***********************************************************/
    public enum JobState {
        NotYetStarted,
        Running,
        Finished
    };

    /***********************************************************
    ***********************************************************/
    public JobState this.state;

    /***********************************************************
    ***********************************************************/
    public enum JobParallelism {
        /***********************************************************
        Jobs can be run in parallel to this job
        ***********************************************************/
        FullParallelism,

        /***********************************************************
        No other job shall be started until this one has on_finished.
        So this job is guaranteed to finish before any jobs below
        it are executed.
        ***********************************************************/
        WaitForFinished,
    };

    /***********************************************************
    ***********************************************************/
    public virtual JobParallelism parallelism () {
        return FullParallelism;
    }


    /***********************************************************
    For "small" jobs
    ***********************************************************/
    public virtual bool is_likely_finished_quickly () {
        return false;
    }


    /***********************************************************
    The space that the running jobs need to complete but don't actually use yet.

    Note that this does not* include the disk space that's already
    in use by running jobs for things like a download-in-progress.
    ***********************************************************/
    public virtual int64 committed_disk_space () {
        return 0;
    }


    /***********************************************************
    Set the associated composite job

    Used only from PropagatorCompositeJob itself, when a job is added
    and from PropagateDirectory to associate the sub_jobs with the first
    job.
    ***********************************************************/
    public void set_associated_composite (PropagatorCompositeJob job) {
        this.associated_composite = job;
    }


    /***********************************************************
    Asynchronous on_abort requires emit of abort_finished () signal,
    while synchronous is expected to on_abort immedietaly.
    ***********************************************************/
    public virtual void on_abort (PropagatorJob.AbortType abort_type) {
        if (abort_type == AbortType.Asynchronous)
            /* emit */ abort_finished ();
    }


    /***********************************************************
    Starts this job, or a new subjob
    returns true if a job was started.
    ***********************************************************/
    public virtual bool on_schedule_self_or_child ();
signals:
    /***********************************************************
    Emitted when the job is fully on_finished
    ***********************************************************/
    void on_finished (SyncFileItem.Status);


    /***********************************************************
    Emitted when the on_abort is fully on_finished
    ***********************************************************/
    void abort_finished (SyncFileItem.Status status = SyncFileItem.Status.NORMAL_ERROR);

    protected OwncloudPropagator propagator ();


    /***********************************************************
    If this job gets added to a composite job, this will point to the parent.

    For the PropagateDirectory._first_job it will point to
    PropagateDirectory._sub_jobs.

    That can be useful for jobs that want to spawn follow-up jobs without
    becoming composite jobs themselves.
    ***********************************************************/
    protected PropagatorCompositeJob this.associated_composite = nullptr;
}



    PropagatorJob.PropagatorJob (OwncloudPropagator propagator)
        : GLib.Object (propagator)
        , this.state (NotYetStarted) {
    }

    OwncloudPropagator *PropagatorJob.propagator () {
        return qobject_cast<OwncloudPropagator> (parent ());
    }
