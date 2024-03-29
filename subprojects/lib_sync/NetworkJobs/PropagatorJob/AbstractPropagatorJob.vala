/***********************************************************
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@class AbstractPropagatorJob

@brief the base class of propagator jobs

@details This can either be a job or a container for jobs.
If it is a composite job, it then inherits from
PropagateDirectory.


@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public abstract class AbstractPropagatorJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public enum AbortType {
        SYNCHRONOUS,
        ASYNCHRONOUS
    }


    /***********************************************************
    ***********************************************************/
    public enum JobState {
        NOT_YET_STARTED,
        RUNNING,
        FINISHED
    }


    /***********************************************************
    ***********************************************************/
    public enum JobParallelism {
        /***********************************************************
        Jobs can be run in parallel to this job
        ***********************************************************/
        FULL_PARALLELISM,

        /***********************************************************
        No other job shall be started until this one has on_signal_finished.
        So this job is guaranteed to finish before any jobs below
        it are executed.
        ***********************************************************/
        WAIT_FOR_FINISHED,
    }


    /***********************************************************
    ***********************************************************/
    public JobState state;

    /***********************************************************
    If this job gets added to a composite job, this will point to the parent.

    For the PropagateDirectory.first_job it will point to
    PropagateDirectory.sub_jobs.

    That can be useful for jobs that want to spawn follow-up jobs without
    becoming composite jobs themselves.

    Set should be used only from PropagatorCompositeJob itself,
    when a job is added and from PropagateDirectory to
    associate the sub_jobs with the first job.
    ***********************************************************/
    public PropagatorCompositeJob associated_composite { public set; protected get; }

    /***********************************************************
    Emitted when the job is fully on_signal_finished
    ***********************************************************/
    internal signal void signal_finished (SyncFileItem.Status status);

    /***********************************************************
    Emitted when the abort is fully on_signal_finished
    ***********************************************************/
    internal signal void signal_abort_finished (SyncFileItem.Status status = SyncFileItem.Status.NORMAL_ERROR);

    /***********************************************************
    ***********************************************************/
    protected AbstractPropagatorJob (
        OwncloudPropagator propagator
    ) {
        //  base (propagator);
        //  this.state = JobState.NOT_YET_STARTED;
        //  this.associated_composite = null;
    }


    /***********************************************************
    ***********************************************************/
    public virtual JobParallelism parallelism () {
        //  return JobParallelism.FULL_PARALLELISM;
    }


    /***********************************************************
    For "small" jobs
    ***********************************************************/
    public virtual bool is_likely_finished_quickly () {
        //  return false;
    }


    /***********************************************************
    The space that the running jobs need to complete but don't actually use yet.

    Note that this does not* include the disk space that's already
    in use by running jobs for things like a download-in-progress.
    ***********************************************************/
    public virtual int64 committed_disk_space () {
        //  return 0;
    }




    /***********************************************************
    Asynchronous abort requires emit of signal_abort_finished () signal,
    while synchronous is expected to abort immedietaly.
    ***********************************************************/
    public new void abort (AbstractPropagatorJob.AbortType abort_type) {
        //  if (abort_type == AbstractPropagatorJob.AbortType.ASYNCHRONOUS)
        //      signal_abort_finished ();
    }


    /***********************************************************
    Starts this job, or a new subjob
    returns true if a job was started.
    ***********************************************************/
    public abstract bool on_signal_schedule_self_or_child ();


    //  protected OwncloudPropagator propagator {
    //      //  return (OwncloudPropagator)parent ();
    //  }

} // class AbstractPropagatorJob

} // namespace LibSync
} // namespace Occ
