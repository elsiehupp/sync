/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QLoggingCategory>
// #include <QNetworkReply>

// #include <QStack>
// #include <QFileInfo>
// #include <QDir>
// #include <QLoggingCategory>
// #include <QTimer>
// #include <QTimerEvent>
// #include <QRegularExpression>
// #include <qmath.h>

// #include <QHash>
// #include <QMap>
// #include <QElapsedTimer>
// #include <QTimer>
// #include <QPointer>
// #include <QIODevice>
// #include <QMutex>

// #include <deque>


namespace {

    /***********************************************************
    We do not want to upload files that are currently being modified.
    To avoid that, we don't upload files that have a modification time
    that is too close to the current time.

    This interacts with the ms_between_request_and_sync delay in the fol
    manager. If that delay between file-change notification and sync
    has passed, we should accept the file for upload here.
    ***********************************************************/
    inline bool file_is_still_changing (Occ.SyncFileItem &item) {
        const var modtime = Occ.Utility.q_date_time_from_time_t (item._modtime);
        const int64 ms_since_mod = modtime.msecs_to (QDateTime.current_date_time_utc ());

        return std.chrono.milliseconds (ms_since_mod) < Occ.SyncEngine.minimum_file_age_for_upload
            // if the mtime is too much in the future we do* upload the file
            && ms_since_mod > -10000;
    }

}

namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lc_propagator)

/***********************************************************
Free disk space threshold below which syncs will on_abort and not even on_start.
***********************************************************/
int64 critical_free_space_limit ();

/***********************************************************
The client will not intentionally reduce the available free disk space below
 this limit.

Uploads will still run and downloads that are small enough will continue too.
***********************************************************/
int64 free_space_limit ();

void blacklist_update (SyncJournalDb journal, SyncFileItem &item);


/***********************************************************
@brief the base class of propagator jobs

This can either be a job, or a container for jobs.
If it is a composite job, it then inherits from PropagateDirectory

@ingroup libsync
***********************************************************/
class PropagatorJob : GLib.Object {


    public PropagatorJob (OwncloudPropagator propagator);

    public enum AbortType {
        Synchronous,
        Asynchronous
    };

    public enum JobState {
        NotYetStarted,
        Running,
        Finished
    };

    public JobState _state;

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
        _associated_composite = job;
    }


    /***********************************************************
    Asynchronous on_abort requires emit of abort_finished () signal,
    while synchronous is expected to on_abort immedietaly.
    ***********************************************************/
    public virtual void on_abort (PropagatorJob.AbortType abort_type) {
        if (abort_type == AbortType.Asynchronous)
            emit abort_finished ();
    }


    /***********************************************************
    Starts this job, or a new subjob
    returns true if a job was started.
    ***********************************************************/
    public virtual bool on_schedule_self_or_child () = 0;
signals:
    /***********************************************************
    Emitted when the job is fully on_finished
    ***********************************************************/
    void on_finished (SyncFileItem.Status);


    /***********************************************************
    Emitted when the on_abort is fully on_finished
    ***********************************************************/
    void abort_finished (SyncFileItem.Status status = SyncFileItem.NormalError);

    protected OwncloudPropagator propagator ();


    /***********************************************************
    If this job gets added to a composite job, this will point to the parent.

    For the PropagateDirectory._first_job it will point to
    PropagateDirectory._sub_jobs.

    That can be useful for jobs that want to spawn follow-up jobs without
    becoming composite jobs themselves.
    ***********************************************************/
    protected PropagatorCompositeJob _associated_composite = nullptr;
};

/***********************************************************
Abstract class to propagate a single item
***********************************************************/
class PropagateItemJob : PropagatorJob {

    protected virtual void on_done (SyncFileItem.Status status, string error_string = string ());


    /***********************************************************
    set a custom restore job message that is used if the restore job succeeded.
    It is displayed in the activity view.
    ***********************************************************/
    protected string restore_job_msg () {
        return _item._is_restoration ? _item._error_string : string ();
    }
    protected void set_restore_job_msg (string msg = string ()) {
        _item._is_restoration = true;
        _item._error_string = msg;
    }

    protected bool has_encrypted_ancestor ();

protected slots:
    void on_restore_job_finished (SyncFileItem.Status status);


    private QScopedPointer<PropagateItemJob> _restore_job;
    private JobParallelism _parallelism;


    public PropagateItemJob (OwncloudPropagator propagator, SyncFileItemPtr &item)
        : PropagatorJob (propagator)
        , _parallelism (FullParallelism)
        , _item (item) {
        // we should always execute jobs that process the E2EE API calls as sequential jobs
        // TODO : In fact, we must make sure Lock/Unlock are not colliding and always wait for each other to complete. So, we could refactor this "_parallelism" later
        // so every "PropagateItemJob" that will potentially execute Lock job on E2EE folder will get executed sequentially.
        // As an alternative, we could optimize Lock/Unlock calls, so we do a batch-write on one folder and only lock and unlock a folder once per batch.
        _parallelism = (_item._is_encrypted || has_encrypted_ancestor ()) ? WaitForFinished : FullParallelism;
    }
    ~PropagateItemJob () override;

    public bool on_schedule_self_or_child () override {
        if (_state != NotYetStarted) {
            return false;
        }
        q_c_info (lc_propagator) << "Starting" << _item._instruction << "propagation of" << _item.destination () << "by" << this;

        _state = Running;
        QMetaObject.invoke_method (this, "on_start"); // We could be in a different thread (neon jobs)
        return true;
    }


    public JobParallelism parallelism () override {
        return _parallelism;
    }


    public SyncFileItemPtr _item;


    public virtual void on_start () = 0;
};

/***********************************************************
@brief Job that runs subjobs. It becomes on_finished only when all subjobs are on_finished.
@ingroup libsync
***********************************************************/
class PropagatorCompositeJob : PropagatorJob {

    public QVector<PropagatorJob> _jobs_to_do;
    public SyncFileItemVector _tasks_to_do;
    public QVector<PropagatorJob> _running_jobs;
    public SyncFileItem.Status _has_error; // NoStatus,  or NormalError / SoftError if there was an error
    public uint64 _aborts_count;

    public PropagatorCompositeJob (OwncloudPropagator propagator)
        : PropagatorJob (propagator)
        , _has_error (SyncFileItem.NoStatus), _aborts_count (0) {
    }

    // Don't delete jobs in _jobs_to_do and _running_jobs : they have parents
    // that will be responsible for on_cleanup. Deleting them here would risk
    // deleting something that has already been deleted by a shared parent.
    ~PropagatorCompositeJob () override = default;

    public void append_job (PropagatorJob job);


    public void append_task (SyncFileItemPtr &item) {
        _tasks_to_do.append (item);
    }


    public bool on_schedule_self_or_child () override;
    public JobParallelism parallelism () override;


    /***********************************************************
    Abort synchronously or asynchronously - some jobs
    require to be on_finished without immediete on_abort (on_abort on job might
    cause conflicts/duplicated files - owncloud/client/issues/5949)
    ***********************************************************/
    public void on_abort (PropagatorJob.AbortType abort_type) override {
        if (!_running_jobs.empty ()) {
            _aborts_count = _running_jobs.size ();
            foreach (PropagatorJob j, _running_jobs) {
                if (abort_type == AbortType.Asynchronous) {
                    connect (j, &PropagatorJob.abort_finished,
                            this, &PropagatorCompositeJob.on_sub_job_abort_finished);
                }
                j.on_abort (abort_type);
            }
        } else if (abort_type == AbortType.Asynchronous){
            emit abort_finished ();
        }
    }


    public int64 committed_disk_space () override;


    private void on_sub_job_abort_finished ();
    private on_ bool possibly_run_next_job (PropagatorJob next) {
        if (next._state == NotYetStarted) {
            connect (next, &PropagatorJob.on_finished, this, &PropagatorCompositeJob.on_sub_job_finished);
        }
        return next.on_schedule_self_or_child ();
    }

    private void on_sub_job_finished (SyncFileItem.Status status);
    private on_ void on_finalize ();
};

/***********************************************************
@brief Propagate a directory, and all its sub entries.
@ingroup libsync
***********************************************************/
class PropagateDirectory : PropagatorJob {

    public SyncFileItemPtr _item;
    // e.g : create the directory
    public QScopedPointer<PropagateItemJob> _first_job;

    public PropagatorCompositeJob _sub_jobs;

    public PropagateDirectory (OwncloudPropagator propagator, SyncFileItemPtr &item);

    public void append_job (PropagatorJob job) {
        _sub_jobs.append_job (job);
    }


    public void append_task (SyncFileItemPtr &item) {
        _sub_jobs.append_task (item);
    }


    public bool on_schedule_self_or_child () override;
    public JobParallelism parallelism () override;
    public void on_abort (PropagatorJob.AbortType abort_type) override {
        if (_first_job)
            // Force first job to on_abort synchronously
            // even if caller allows async on_abort (async_abort)
            _first_job.on_abort (AbortType.Synchronous);

        if (abort_type == AbortType.Asynchronous){
            connect (&_sub_jobs, &PropagatorCompositeJob.abort_finished, this, &PropagateDirectory.abort_finished);
        }
        _sub_jobs.on_abort (abort_type);
    }


    public void increase_affected_count () {
        _first_job._item._affected_items++;
    }


    public int64 committed_disk_space () override {
        return _sub_jobs.committed_disk_space ();
    }


    private void on_first_job_finished (SyncFileItem.Status status);
    private on_ virtual void on_sub_jobs_finished (SyncFileItem.Status status);

};

/***********************************************************
@brief Propagate the root directory, and all its sub entries.
@ingroup libsync

Primary difference to PropagateDirectory is that it keeps track of directory
deletions that must happen at the very end.
***********************************************************/
class PropagateRootDirectory : PropagateDirectory {

    public PropagatorCompositeJob _dir_deletion_jobs;

    public PropagateRootDirectory (OwncloudPropagator propagator);

    public bool on_schedule_self_or_child () override;
    public JobParallelism parallelism () override;
    public void on_abort (PropagatorJob.AbortType abort_type) override;

    public int64 committed_disk_space () override;


    private void on_sub_jobs_finished (SyncFileItem.Status status) override;
    private void on_dir_deletion_jobs_finished (SyncFileItem.Status status);

    private bool schedule_delayed_jobs ();
};

/***********************************************************
@brief Dummy job that just mark it as completed and ignored
@ingroup libsync
***********************************************************/
class PropagateIgnoreJob : PropagateItemJob {

    public PropagateIgnoreJob (OwncloudPropagator propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item) {
    }
    public void on_start () override {
        SyncFileItem.Status status = _item._status;
        if (status == SyncFileItem.NoStatus) {
            if (_item._instruction == CSYNC_INSTRUCTION_ERROR) {
                status = SyncFileItem.NormalError;
            } else {
                status = SyncFileItem.FileIgnored;
                ASSERT (_item._instruction == CSYNC_INSTRUCTION_IGNORE);
            }
        }
        on_done (status, _item._error_string);
    }
};


class OwncloudPropagator : GLib.Object {

    public SyncJournalDb const _journal;
    public bool _finished_emited; // used to ensure that on_finished is only emitted once


    public OwncloudPropagator (AccountPtr account, string local_dir,
                       const string remote_folder, SyncJournalDb progress_database,
                       QSet<string> &bulk_upload_black_list)
        : _journal (progress_database)
        , _finished_emited (false)
        , _bandwidth_manager (this)
        , _another_sync_needed (false)
        , _chunk_size (10 * 1000 * 1000) // 10 MB, overridden in set_sync_options
        , _account (account)
        , _local_dir ( (local_dir.ends_with (QChar ('/'))) ? local_dir : local_dir + '/')
        , _remote_folder ( (remote_folder.ends_with (QChar ('/'))) ? remote_folder : remote_folder + '/')
        , _bulk_upload_black_list (bulk_upload_black_list) {
        q_register_meta_type<PropagatorJob.AbortType> ("PropagatorJob.AbortType");
    }

    ~OwncloudPropagator () override;

    public void on_start (SyncFileItemVector &&_synced_items);

    public void start_directory_propagation (SyncFileItemPtr &item,
                                   QStack<QPair<string, PropagateDirectory>> &directories,
                                   QVector<PropagatorJob> &directories_to_remove,
                                   string removed_directory,
                                   const SyncFileItemVector &items);

    public void start_file_propagation (SyncFileItemPtr &item,
                              QStack<QPair<string, PropagateDirectory>> &directories,
                              QVector<PropagatorJob> &directories_to_remove,
                              string removed_directory,
                              string maybe_conflict_directory);

    public const SyncOptions &sync_options ();


    public void set_sync_options (SyncOptions &sync_options);

    public int _download_limit = 0;
    public int _upload_limit = 0;
    public BandwidthManager _bandwidth_manager;

    public bool _abort_requested = false;


    /***********************************************************
    The list of currently active jobs.
        This list contains the jobs that are currently using ressources and is used purely to
        know how many jobs there is currently running for the scheduler.
        Jobs add themself to the list when they do an assynchronous operation.
        Jobs can be several time on the list (example, when several chunks are uploaded in parallel)
    ***********************************************************/
    public GLib.List<PropagateItemJob> _active_job_list;


    /***********************************************************
    We detected that another sync is required after this one
    ***********************************************************/
    public bool _another_sync_needed;


    /***********************************************************
    Per-folder quota guesses.

    This starts out empty. When an upload in a folder fails due to insufficent
    remote quota, the quota guess is updated to be attempted_size-1 at maximum.

    Note that it will usually just an upper limit for the actual quota - but
    since the quota on the server might ch
    wrong in the other direction as well.

    This allows skipping of uploads that have a very high likelihood of failure.
    ***********************************************************/
    public QHash<string, int64> _folder_quota;

    
    /***********************************************************
    the maximum number of jobs using bandwidth (uploads or downloads, in parallel)
    ***********************************************************/
    public int maximum_active_transfer_job ();


    /***********************************************************
    The size to use for upload chunks.

    Will be dynamically adjusted after each chunk upload finishes
    if Capabilities.desired_chunk_upload_duration has a target
    chunk-upload duration set.
    ***********************************************************/
    public int64 _chunk_size;
    public int64 small_file_size ();


    /***********************************************************
    The maximum number of active jobs in parallel
    ***********************************************************/
    public int hard_maximum_active_job ();


    /***********************************************************
    Check whether a download would clash with an existing file
    in filesystems that are only case-preserving.
    ***********************************************************/
    public bool local_file_name_clash (string relfile);


    /***********************************************************
    Check whether a file is properly accessible for upload.

    It is possible to create files with filenames that differ
    only by case in NTFS, but most operations such as stat and
    open only target one of these by default.

    When that happens, we want to avoid uploading incorrect data
    and give up on the file.
    ***********************************************************/
    public bool has_case_clash_accessibility_problem (string relfile);

    //  Q_REQUIRED_RESULT
    public string full_local_path (string tmp_file_name);


    public string local_path ();


    /***********************************************************
    Returns the full remote path including the folder root of a
    folder sync path.
    ***********************************************************/
    //  Q_REQUIRED_RESULT
    public string full_remote_path (string tmp_file_name);


    public string remote_path ();


    /***********************************************************
    Creates the job for an item.
    ***********************************************************/
    public PropagateItemJob create_job (SyncFileItemPtr &item);

    public void schedule_next_job ();


    public void report_progress (SyncFileItem &, int64 bytes);

    public void on_abort () {
        if (_abort_requested)
            return;
        if (_root_job) {
            // Connect to abort_finished  which signals that on_abort has been asynchronously on_finished
            connect (_root_job.data (), &PropagateDirectory.abort_finished, this, &OwncloudPropagator.emit_finished);

            // Use Queued Connection because we're possibly already in an item's on_finished stack
            QMetaObject.invoke_method (_root_job.data (), "on_abort", Qt.QueuedConnection,
                                      Q_ARG (PropagatorJob.AbortType, PropagatorJob.AbortType.Asynchronous));

            // Give asynchronous on_abort 5000 msec to finish on its own
            QTimer.single_shot (5000, this, SLOT (abort_timeout ()));
        } else {
            // No root job, call emit_finished
            emit_finished (SyncFileItem.NormalError);
        }
    }


    public AccountPtr account ();

    public enum DiskSpaceResult {
        DiskSpaceOk,
        DiskSpaceFailure,
        DiskSpaceCritical
    };


    /***********************************************************
    Checks whether there's enough disk space available to complete
    all jobs that are currently running.
    ***********************************************************/
    public DiskSpaceResult disk_space_check ();


    /***********************************************************
    Handles a conflict by renaming the file 'item'.

    Sets up conflict records.

    It also creates a new upload job in composite if the item
    moved away is a file and conflict uploads are requested.

    Returns true on on_success, false and error on error.
    ***********************************************************/
    public bool create_conflict (SyncFileItemPtr &item,
        PropagatorCompositeJob composite, string error);

    // Map original path (as in the DB) to target final path
    public QMap<string, string> _renamed_directories;
    public string adjust_renamed_path (string original);


    /***********************************************************
    Update the database for an item.

    Typically after a sync operation succeeded. Updates the inode from
    the filesystem.

    Will also trigger a Vfs.convert_to_placeholder.
    ***********************************************************/
    public Result<Vfs.ConvertToPlaceholderResult, string> update_metadata (SyncFileItem &item);


    /***********************************************************
    Update the database for an item.

    Typically after a sync operation succeeded. Updates the inode from
    the filesystem.

    Will also trigger a Vfs.convert_to_placeholder.
    ***********************************************************/
    public static Result<Vfs.ConvertToPlaceholderResult, string> static_update_metadata (SyncFileItem &item, string local_dir,
                                                                                 Vfs vfs, SyncJournalDb * const journal);

    //  Q_REQUIRED_RESULT
    public bool is_delayed_upload_item (SyncFileItemPtr &item);

    //  Q_REQUIRED_RESULT
    public const std.deque<SyncFileItemPtr>& delayed_tasks () {
        return _delayed_tasks;
    }


    public void set_schedule_delayed_tasks (bool active);

    public void clear_delayed_tasks ();

    public void add_to_bulk_upload_black_list (string file);

    public void remove_from_bulk_upload_black_list (string file);

    public bool is_in_bulk_upload_black_list (string file);


    private on_ void abort_timeout () {
        // Abort synchronously and finish
        _root_job.data ().on_abort (PropagatorJob.AbortType.Synchronous);
        emit_finished (SyncFileItem.NormalError);
    }


    /***********************************************************
    Emit the on_finished signal and make sure it is only emitted once
    ***********************************************************/
    private on_ void emit_finished (SyncFileItem.Status status) {
        if (!_finished_emited)
            emit finished (status == SyncFileItem.Success);
        _finished_emited = true;
    }

    private on_ void schedule_next_job_impl ();

signals:
    void new_item (SyncFileItemPtr &);
    void item_completed (SyncFileItemPtr &);
    void progress (SyncFileItem &, int64 bytes);
    void on_finished (bool on_success);


    /***********************************************************
    Emitted when propagation has problems with a locked file.
    ***********************************************************/
    void seen_locked_file (string file_name);


    /***********************************************************
    Emitted when propagation touches a file.

    Used to track our own file modifications such that notifications
    from the file watcher about these can be ignored.
    ***********************************************************/
    void touched_file (string file_name);

    void insufficient_local_storage ();
    void insufficient_remote_storage ();


    private std.unique_ptr<PropagateUploadFileCommon> create_upload_job (SyncFileItemPtr item,
                                                               bool delete_existing);

    private void push_delayed_upload_task (SyncFileItemPtr item);

    private void reset_delayed_upload_tasks ();

    private AccountPtr _account;
    private QScopedPointer<PropagateRootDirectory> _root_job;
    private SyncOptions _sync_options;
    private bool _job_scheduled = false;

    private const string _local_dir; // absolute path to the local directory. ends with '/'
    private const string _remote_folder; // remote folder, ends with '/'

    private std.deque<SyncFileItemPtr> _delayed_tasks;
    private bool _schedule_delayed_tasks = false;

    private QSet<string> &_bulk_upload_black_list;

    private static bool _allow_delayed_upload;
};

/***********************************************************
@brief Job that wait for all the poll jobs to be completed
@ingroup libsync
***********************************************************/
class CleanupPollsJob : GLib.Object {
    QVector<SyncJournalDb.PollInfo> _poll_infos;
    AccountPtr _account;
    SyncJournalDb _journal;
    string _local_path;
    unowned<Vfs> _vfs;

    public CleanupPollsJob (QVector<SyncJournalDb.PollInfo> &poll_infos, AccountPtr account, SyncJournalDb journal, string local_path,
                             const unowned<Vfs> &vfs, GLib.Object parent = nullptr)
        : GLib.Object (parent)
        , _poll_infos (poll_infos)
        , _account (account)
        , _journal (journal)
        , _local_path (local_path)
        , _vfs (vfs) {
    }

    ~CleanupPollsJob () override;


    /***********************************************************
    Start the job.  After the job is completed, it will emit either on_finished or aborted, and it
    will destroy itself.
    ***********************************************************/
    public void on_start ();
signals:
    void on_finished ();
    void aborted (string error);

    private void on_poll_finished ();
};

    int64 critical_free_space_limit () {
        int64 value = 50 * 1000 * 1000LL;

        static bool has_env = false;
        static int64 env = qgetenv ("OWNCLOUD_CRITICAL_FREE_SPACE_BYTES").to_long_long (&has_env);
        if (has_env) {
            value = env;
        }

        return q_bound (0LL, value, free_space_limit ());
    }

    int64 free_space_limit () {
        int64 value = 250 * 1000 * 1000LL;

        static bool has_env = false;
        static int64 env = qgetenv ("OWNCLOUD_FREE_SPACE_BYTES").to_long_long (&has_env);
        if (has_env) {
            value = env;
        }

        return value;
    }

    OwncloudPropagator.~OwncloudPropagator () = default;

    int OwncloudPropagator.maximum_active_transfer_job () {
        if (_download_limit != 0
            || _upload_limit != 0
            || !_sync_options._parallel_network_jobs) {
            // disable parallelism when there is a network limit.
            return 1;
        }
        return q_min (3, q_ceil (_sync_options._parallel_network_jobs / 2.));
    }


    /***********************************************************
    The maximum number of active jobs in parallel
    ***********************************************************/
    int OwncloudPropagator.hard_maximum_active_job () {
        if (!_sync_options._parallel_network_jobs)
            return 1;
        return _sync_options._parallel_network_jobs;
    }

    PropagateItemJob.~PropagateItemJob () {
        if (var p = propagator ()) {
            // Normally, every job should clean itself from the _active_job_list. So this should not be
            // needed. But if a job has a bug or is deleted before the network jobs signal get received,
            // we might risk end up with dangling pointer in the list which may cause crashes.
            p._active_job_list.remove_all (this);
        }
    }

    static int64 get_min_blacklist_time () {
        return q_max (q_environment_variable_int_value ("OWNCLOUD_BLACKLIST_TIME_MIN"),
            25); // 25 seconds
    }

    static int64 get_max_blacklist_time () {
        int v = q_environment_variable_int_value ("OWNCLOUD_BLACKLIST_TIME_MAX");
        if (v > 0)
            return v;
        return 24 * 60 * 60; // 1 day
    }


    /***********************************************************
    Creates a blacklist entry, possibly taking into account an old one.

    The old entry may be invalid, then a fresh entry is created.
    ***********************************************************/
    static SyncJournalErrorBlacklistRecord create_blacklist_entry (
        const SyncJournalErrorBlacklistRecord &old, SyncFileItem &item) {
        SyncJournalErrorBlacklistRecord entry;
        entry._file = item._file;
        entry._error_string = item._error_string;
        entry._last_try_modtime = item._modtime;
        entry._last_try_etag = item._etag;
        entry._last_try_time = Utility.q_date_time_to_time_t (QDateTime.current_date_time_utc ());
        entry._rename_target = item._rename_target;
        entry._retry_count = old._retry_count + 1;
        entry._request_id = item._request_id;

        static int64 min_blacklist_time (get_min_blacklist_time ());
        static int64 max_blacklist_time (q_max (get_max_blacklist_time (), min_blacklist_time));

        // The factor of 5 feels natural : 25s, 2 min, 10 min, ~1h, ~5h, ~24h
        entry._ignore_duration = old._ignore_duration * 5;

        if (item._http_error_code == 403) {
            q_c_warning (lc_propagator) << "Probably firewall error : " << item._http_error_code << ", blacklisting up to 1h only";
            entry._ignore_duration = q_min (entry._ignore_duration, int64 (60 * 60));

        } else if (item._http_error_code == 413 || item._http_error_code == 415) {
            q_c_warning (lc_propagator) << "Fatal Error condition" << item._http_error_code << ", maximum blacklist ignore time!";
            entry._ignore_duration = max_blacklist_time;
        }

        entry._ignore_duration = q_bound (min_blacklist_time, entry._ignore_duration, max_blacklist_time);

        if (item._status == SyncFileItem.SoftError) {
            // Track these errors, but don't actively suppress them.
            entry._ignore_duration = 0;
        }

        if (item._http_error_code == 507) {
            entry._error_category = SyncJournalErrorBlacklistRecord.InsufficientRemoteStorage;
        }

        return entry;
    }


    /***********************************************************
    Updates, creates or removes a blacklist entry for the given item.

    May adjust the status or item._error_string.
    ***********************************************************/
    void blacklist_update (SyncJournalDb journal, SyncFileItem &item) {
        SyncJournalErrorBlacklistRecord old_entry = journal.error_blacklist_entry (item._file);

        bool may_blacklist =
            item._error_may_be_blacklisted // explicitly flagged for blacklisting
            || ( (item._status == SyncFileItem.NormalError
                    || item._status == SyncFileItem.SoftError
                    || item._status == SyncFileItem.DetailError)
                   && item._http_error_code != 0 // or non-local error
                   );

        // No new entry? Possibly remove the old one, then done.
        if (!may_blacklist) {
            if (old_entry.is_valid ()) {
                journal.wipe_error_blacklist_entry (item._file);
            }
            return;
        }

        var new_entry = create_blacklist_entry (old_entry, item);
        journal.set_error_blacklist_entry (new_entry);

        // Suppress the error if it was and continues to be blacklisted.
        // An ignore_duration of 0 mean we're tracking the error, but not actively
        // suppressing it.
        if (item._has_blacklist_entry && new_entry._ignore_duration > 0) {
            item._status = SyncFileItem.BlacklistedError;

            q_c_info (lc_propagator) << "blacklisting " << item._file
                                 << " for " << new_entry._ignore_duration
                                 << ", retry count " << new_entry._retry_count;

            return;
        }

        // Some soft errors might become louder on repeat occurrence
        if (item._status == SyncFileItem.SoftError
            && new_entry._retry_count > 1) {
            q_c_warning (lc_propagator) << "escalating soft error on " << item._file
                                    << " to normal error, " << item._http_error_code;
            item._status = SyncFileItem.NormalError;
            return;
        }
    }

    void PropagateItemJob.on_done (SyncFileItem.Status status_arg, string error_string) {
        // Duplicate calls to on_done () are a logic error
        ENFORCE (_state != Finished);
        _state = Finished;

        _item._status = status_arg;

        if (_item._is_restoration) {
            if (_item._status == SyncFileItem.Success
                || _item._status == SyncFileItem.Conflict) {
                _item._status = SyncFileItem.Restoration;
            } else {
                _item._error_string += tr ("; Restoration Failed : %1").arg (error_string);
            }
        } else {
            if (_item._error_string.is_empty ()) {
                _item._error_string = error_string;
            }
        }

        if (propagator ()._abort_requested && (_item._status == SyncFileItem.NormalError
                                              || _item._status == SyncFileItem.FatalError)) {
            // an on_abort request is ongoing. Change the status to Soft-Error
            _item._status = SyncFileItem.SoftError;
        }

        // Blacklist handling
        switch (_item._status) {
        case SyncFileItem.SoftError:
        case SyncFileItem.FatalError:
        case SyncFileItem.NormalError:
        case SyncFileItem.DetailError:
            // Check the blacklist, possibly adjusting the item (including its status)
            blacklist_update (propagator ()._journal, _item);
            break;
        case SyncFileItem.Success:
        case SyncFileItem.Restoration:
            if (_item._has_blacklist_entry) {
                // wipe blacklist entry.
                propagator ()._journal.wipe_error_blacklist_entry (_item._file);
                // remove a blacklist entry in case the file was moved.
                if (_item._original_file != _item._file) {
                    propagator ()._journal.wipe_error_blacklist_entry (_item._original_file);
                }
            }
            break;
        case SyncFileItem.Conflict:
        case SyncFileItem.FileIgnored:
        case SyncFileItem.NoStatus:
        case SyncFileItem.BlacklistedError:
        case SyncFileItem.FileLocked:
        case SyncFileItem.FileNameInvalid:
            // nothing
            break;
        }

        if (_item.has_error_status ())
            q_c_warning (lc_propagator) << "Could not complete propagation of" << _item.destination () << "by" << this << "with status" << _item._status << "and error:" << _item._error_string;
        else
            q_c_info (lc_propagator) << "Completed propagation of" << _item.destination () << "by" << this << "with status" << _item._status;
        emit propagator ().item_completed (_item);
        emit finished (_item._status);

        if (_item._status == SyncFileItem.FatalError) {
            // Abort all remaining jobs.
            propagator ().on_abort ();
        }
    }

    void PropagateItemJob.on_restore_job_finished (SyncFileItem.Status status) {
        string msg;
        if (_restore_job) {
            msg = _restore_job.restore_job_msg ();
            _restore_job.set_restore_job_msg ();
        }

        if (status == SyncFileItem.Success || status == SyncFileItem.Conflict
            || status == SyncFileItem.Restoration) {
            on_done (SyncFileItem.SoftError, msg);
        } else {
            on_done (status, tr ("A file or folder was removed from a read only share, but restoring failed : %1").arg (msg));
        }
    }

    bool PropagateItemJob.has_encrypted_ancestor () {
        if (!propagator ().account ().capabilities ().client_side_encryption_available ()) {
            return false;
        }

        const var path = _item._file;
        const var slash_position = path.last_index_of ('/');
        const var parent_path = slash_position >= 0 ? path.left (slash_position) : string ();

        var path_components = parent_path.split ('/');
        while (!path_components.is_empty ()) {
            SyncJournalFileRecord rec;
            propagator ()._journal.get_file_record (path_components.join ('/'), &rec);
            if (rec.is_valid () && rec._is_e2e_encrypted) {
                return true;
            }
            path_components.remove_last ();
        }

        return false;
    }

    // ================================================================================

    PropagateItemJob *OwncloudPropagator.create_job (SyncFileItemPtr &item) {
        bool delete_existing = item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE;
        switch (item._instruction) {
        case CSYNC_INSTRUCTION_REMOVE:
            if (item._direction == SyncFileItem.Down)
                return new PropagateLocalRemove (this, item);
            else
                return new PropagateRemoteDelete (this, item);
        case CSYNC_INSTRUCTION_NEW:
        case CSYNC_INSTRUCTION_TYPE_CHANGE:
        case CSYNC_INSTRUCTION_CONFLICT:
            if (item.is_directory ()) {
                // CONFLICT has _direction == None
                if (item._direction != SyncFileItem.Up) {
                    var job = new PropagateLocalMkdir (this, item);
                    job.set_delete_existing_file (delete_existing);
                    return job;
                } else {
                    var job = new PropagateRemoteMkdir (this, item);
                    job.set_delete_existing (delete_existing);
                    return job;
                }
            } //fall through
        case CSYNC_INSTRUCTION_SYNC:
            if (item._direction != SyncFileItem.Up) {
                var job = new PropagateDownloadFile (this, item);
                job.set_delete_existing_folder (delete_existing);
                return job;
            } else {
                if (delete_existing || !is_delayed_upload_item (item)) {
                    var job = create_upload_job (item, delete_existing);
                    return job.release ();
                } else {
                    push_delayed_upload_task (item);
                    return nullptr;
                }
            }
        case CSYNC_INSTRUCTION_RENAME:
            if (item._direction == SyncFileItem.Up) {
                return new PropagateRemoteMove (this, item);
            } else {
                return new PropagateLocalRename (this, item);
            }
        case CSYNC_INSTRUCTION_IGNORE:
        case CSYNC_INSTRUCTION_ERROR:
            return new PropagateIgnoreJob (this, item);
        default:
            return nullptr;
        }
        return nullptr;
    }

    std.unique_ptr<PropagateUploadFileCommon> OwncloudPropagator.create_upload_job (SyncFileItemPtr item, bool delete_existing) {
        var job = std.unique_ptr<PropagateUploadFileCommon>{};

        if (item._size > sync_options ()._initial_chunk_size && account ().capabilities ().chunking_ng ()) {
            // Item is above _initial_chunk_size, thus will be classified as to be chunked
            job = std.make_unique<PropagateUploadFileNG> (this, item);
        } else {
            job = std.make_unique<PropagateUploadFileV1> (this, item);
        }

        job.set_delete_existing (delete_existing);

        remove_from_bulk_upload_black_list (item._file);

        return job;
    }

    void OwncloudPropagator.push_delayed_upload_task (SyncFileItemPtr item) {
        _delayed_tasks.push_back (item);
    }

    void OwncloudPropagator.reset_delayed_upload_tasks () {
        _schedule_delayed_tasks = false;
        _delayed_tasks.clear ();
    }

    int64 OwncloudPropagator.small_file_size () {
        const int64 small_file_size = 100 * 1024; //default to 1 MB. Not dynamic right now.
        return small_file_size;
    }

    void OwncloudPropagator.on_start (SyncFileItemVector &&items) {
        Q_ASSERT (std.is_sorted (items.begin (), items.end ()));

        // This builds all the jobs needed for the propagation.
        // Each directory is a PropagateDirectory job, which contains the files in it.
        // In order to do that we loop over the items. (which are sorted by destination)
        // When we enter a directory, we can create the directory job and push it on the stack.

        const var regex = sync_options ().file_regex ();
        if (regex.is_valid ()) {
            QSet<QStringRef> names;
            for (var &i : items) {
                if (regex.match (i._file).has_match ()) {
                    int index = -1;
                    QStringRef ref;
                    do {
                        ref = i._file.mid_ref (0, index);
                        names.insert (ref);
                        index = ref.last_index_of (QLatin1Char ('/'));
                    } while (index > 0);
                }
            }
            items.erase (std.remove_if (items.begin (), items.end (), [&names] (var i) {
                return !names.contains (QStringRef {
                    &i._file
                });
            }),
            items.end ());
        }

        reset_delayed_upload_tasks ();
        _root_job.on_reset (new PropagateRootDirectory (this));
        QStack<QPair<string /* directory name */, PropagateDirectory * /* job */>> directories;
        directories.push (q_make_pair (string (), _root_job.data ()));
        QVector<PropagatorJob> directories_to_remove;
        string removed_directory;
        string maybe_conflict_directory;
        foreach (SyncFileItemPtr &item, items) {
            if (!removed_directory.is_empty () && item._file.starts_with (removed_directory)) {
                // this is an item in a directory which is going to be removed.
                var del_dir_job = qobject_cast<PropagateDirectory> (directories_to_remove.first ());

                const var is_new_directory = item.is_directory () &&
                        (item._instruction == CSYNC_INSTRUCTION_NEW || item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE);

                if (item._instruction == CSYNC_INSTRUCTION_REMOVE || is_new_directory) {
                    // If it is a remove it is already taken care of by the removal of the parent directory

                    // If it is a new directory then it is inside a deleted directory... That can happen if
                    // the directory etag was not fetched properly on the previous sync because the sync was
                    // aborted while uploading this directory (which is now removed).  We can ignore it.

                    // increase the number of subjobs that would be there.
                    if (del_dir_job) {
                        del_dir_job.increase_affected_count ();
                    }
                    continue;
                } else if (item._instruction == CSYNC_INSTRUCTION_IGNORE) {
                    continue;
                } else if (item._instruction == CSYNC_INSTRUCTION_RENAME) {
                    // all is good, the rename will be executed before the directory deletion
                } else {
                    q_c_warning (lc_propagator) << "WARNING :  Job within a removed directory?  This should not happen!"
                                            << item._file << item._instruction;
                }
            }

            // If a CONFLICT item contains files these can't be processed because
            // the conflict handling is likely to rename the directory. This can happen
            // when there's a new local directory at the same time as a remote file.
            if (!maybe_conflict_directory.is_empty ()) {
                if (item.destination ().starts_with (maybe_conflict_directory)) {
                    q_c_info (lc_propagator) << "Skipping job inside CONFLICT directory"
                                         << item._file << item._instruction;
                    item._instruction = CSYNC_INSTRUCTION_NONE;
                    continue;
                } else {
                    maybe_conflict_directory.clear ();
                }
            }

            while (!item.destination ().starts_with (directories.top ().first)) {
                directories.pop ();
            }

            if (item.is_directory ()) {
                start_directory_propagation (item,
                                          directories,
                                          directories_to_remove,
                                          removed_directory,
                                          items);
            } else {
                start_file_propagation (item,
                                     directories,
                                     directories_to_remove,
                                     removed_directory,
                                     maybe_conflict_directory);
            }
        }

        foreach (PropagatorJob it, directories_to_remove) {
            _root_job._dir_deletion_jobs.append_job (it);
        }

        connect (_root_job.data (), &PropagatorJob.on_finished, this, &OwncloudPropagator.emit_finished);

        _job_scheduled = false;
        schedule_next_job ();
    }

    void OwncloudPropagator.start_directory_propagation (SyncFileItemPtr &item,
                                                       QStack<QPair<string, PropagateDirectory>> &directories,
                                                       QVector<PropagatorJob> &directories_to_remove,
                                                       string removed_directory,
                                                       const SyncFileItemVector &items) {
        var directory_propagation_job = std.make_unique<PropagateDirectory> (this, item);

        if (item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE
            && item._direction == SyncFileItem.Up) {
            // Skip all potential uploads to the new folder.
            // Processing them now leads to problems with permissions:
            // check_for_permissions () has already run and used the permissions
            // of the file we're about to delete to decide whether uploading
            // to the new dir is ok...
            foreach (SyncFileItemPtr &dir_item, items) {
                if (dir_item.destination ().starts_with (item.destination () + "/")) {
                    dir_item._instruction = CSYNC_INSTRUCTION_NONE;
                    _another_sync_needed = true;
                }
            }
        }

        if (item._instruction == CSYNC_INSTRUCTION_REMOVE) {
            // We do the removal of directories at the end, because there might be moves from
            // these directories that will happen later.
            directories_to_remove.prepend (directory_propagation_job.get ());
            removed_directory = item._file + "/";

            // We should not update the etag of parent directories of the removed directory
            // since it would be done before the actual remove (issue #1845)
            // Note: Currently this means that we don't update those etag at all in this sync,
            //       but it should not be a problem, they will be updated in the next sync.
            for (int i = 0; i < directories.size (); ++i) {
                if (directories[i].second._item._instruction == CSYNC_INSTRUCTION_UPDATE_METADATA) {
                    directories[i].second._item._instruction = CSYNC_INSTRUCTION_NONE;
                }
            }
        } else {
            const var current_dir_job = directories.top ().second;
            current_dir_job.append_job (directory_propagation_job.get ());
        }
        directories.push (q_make_pair (item.destination () + "/", directory_propagation_job.release ()));
    }

    void OwncloudPropagator.start_file_propagation (SyncFileItemPtr &item,
                                                  QStack<QPair<string, PropagateDirectory> > &directories,
                                                  QVector<PropagatorJob> &directories_to_remove,
                                                  string removed_directory,
                                                  string maybe_conflict_directory) {
        if (item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE) {
            // will delete directories, so defer execution
            var job = create_job (item);
            if (job) {
                directories_to_remove.prepend (job);
            }
            removed_directory = item._file + "/";
        } else {
            directories.top ().second.append_task (item);
        }

        if (item._instruction == CSYNC_INSTRUCTION_CONFLICT) {
            // This might be a file or a directory on the local side. If it's a
            // directory we want to skip processing items inside it.
            maybe_conflict_directory = item._file + "/";
        }
    }

    const SyncOptions &OwncloudPropagator.sync_options () {
        return _sync_options;
    }

    void OwncloudPropagator.set_sync_options (SyncOptions &sync_options) {
        _sync_options = sync_options;
        _chunk_size = sync_options._initial_chunk_size;
    }

    bool OwncloudPropagator.local_file_name_clash (string rel_file) {
        const string file (_local_dir + rel_file);
        Q_ASSERT (!file.is_empty ());

        if (!file.is_empty () && Utility.fs_case_preserving ()) {
            q_c_debug (lc_propagator) << "CaseClashCheck for " << file;
            // On Linux, the file system is case sensitive, but this code is useful for testing.
            // Just check that there is no other file with the same name and different casing.
            QFileInfo file_info (file);
            const string fn = file_info.file_name ();
            const string[] list = file_info.dir ().entry_list ({
                fn
            });
            if (list.count () > 1 || (list.count () == 1 && list[0] != fn)) {
                return true;
            }
        }
        return false;
    }

    bool OwncloudPropagator.has_case_clash_accessibility_problem (string relfile) {
        Q_UNUSED (relfile);
        return false;
    }

    string OwncloudPropagator.full_local_path (string tmp_file_name) {
        return _local_dir + tmp_file_name;
    }

    string OwncloudPropagator.local_path () {
        return _local_dir;
    }

    void OwncloudPropagator.schedule_next_job () {
        if (_job_scheduled) return; // don't schedule more than 1
        _job_scheduled = true;
        QTimer.single_shot (3, this, &OwncloudPropagator.schedule_next_job_impl);
    }

    void OwncloudPropagator.schedule_next_job_impl () {
        // TODO : If we see that the automatic up-scaling has a bad impact we
        // need to check how to avoid this.
        // Down-scaling on slow networks? https://github.com/owncloud/client/issues/3382
        // Making sure we do up/down at same time? https://github.com/owncloud/client/issues/1633

        _job_scheduled = false;

        if (_active_job_list.count () < maximum_active_transfer_job ()) {
            if (_root_job.on_schedule_self_or_child ()) {
                schedule_next_job ();
            }
        } else if (_active_job_list.count () < hard_maximum_active_job ()) {
            int likely_finished_quickly_count = 0;
            // Note: Only counts the first 3 jobs! Then for each
            // one that is likely on_finished quickly, we can launch another one.
            // When a job finishes another one will "move up" to be one of the first 3 and then
            // be counted too.
            for (int i = 0; i < maximum_active_transfer_job () && i < _active_job_list.count (); i++) {
                if (_active_job_list.at (i).is_likely_finished_quickly ()) {
                    likely_finished_quickly_count++;
                }
            }
            if (_active_job_list.count () < maximum_active_transfer_job () + likely_finished_quickly_count) {
                q_c_debug (lc_propagator) << "Can pump in another request! active_jobs =" << _active_job_list.count ();
                if (_root_job.on_schedule_self_or_child ()) {
                    schedule_next_job ();
                }
            }
        }
    }

    void OwncloudPropagator.report_progress (SyncFileItem &item, int64 bytes) {
        emit progress (item, bytes);
    }

    AccountPtr OwncloudPropagator.account () {
        return _account;
    }

    OwncloudPropagator.DiskSpaceResult OwncloudPropagator.disk_space_check () {
        const int64 free_bytes = Utility.free_disk_space (_local_dir);
        if (free_bytes < 0) {
            return DiskSpaceOk;
        }

        if (free_bytes < critical_free_space_limit ()) {
            return DiskSpaceCritical;
        }

        if (free_bytes - _root_job.committed_disk_space () < free_space_limit ()) {
            return DiskSpaceFailure;
        }

        return DiskSpaceOk;
    }

    bool OwncloudPropagator.create_conflict (SyncFileItemPtr &item,
        PropagatorCompositeJob composite, string error) {
        string fn = full_local_path (item._file);

        string rename_error;
        var conflict_mod_time = FileSystem.get_mod_time (fn);
        if (conflict_mod_time <= 0) {
            *error = tr ("Impossible to get modification time for file in conflict %1").arg (fn);
            return false;
        }
        string conflict_user_name;
        if (account ().capabilities ().upload_conflict_files ())
            conflict_user_name = account ().dav_display_name ();
        string conflict_file_name = Utility.make_conflict_file_name (
            item._file, Utility.q_date_time_from_time_t (conflict_mod_time), conflict_user_name);
        string conflict_file_path = full_local_path (conflict_file_name);

        emit touched_file (fn);
        emit touched_file (conflict_file_path);

        if (!FileSystem.rename (fn, conflict_file_path, &rename_error)) {
            // If the rename fails, don't replace it.

            // If the file is locked, we want to retry this sync when it
            // becomes available again.
            if (FileSystem.is_file_locked (fn)) {
                emit seen_locked_file (fn);
            }

            if (error)
                *error = rename_error;
            return false;
        }
        q_c_info (lc_propagator) << "Created conflict file" << fn << "." << conflict_file_name;

        // Create a new conflict record. To get the base etag, we need to read it from the database.
        ConflictRecord conflict_record;
        conflict_record.path = conflict_file_name.to_utf8 ();
        conflict_record.base_modtime = item._previous_modtime;
        conflict_record.initial_base_path = item._file.to_utf8 ();

        SyncJournalFileRecord base_record;
        if (_journal.get_file_record (item._original_file, &base_record) && base_record.is_valid ()) {
            conflict_record.base_etag = base_record._etag;
            conflict_record.base_file_id = base_record._file_id;
        } else {
            // We might very well end up with no fileid/etag for new/new conflicts
        }

        _journal.set_conflict_record (conflict_record);

        // Create a new upload job if the new conflict file should be uploaded
        if (account ().capabilities ().upload_conflict_files ()) {
            if (composite && !QFileInfo (conflict_file_path).is_dir ()) {
                SyncFileItemPtr conflict_item = SyncFileItemPtr (new SyncFileItem);
                conflict_item._file = conflict_file_name;
                conflict_item._type = ItemTypeFile;
                conflict_item._direction = SyncFileItem.Up;
                conflict_item._instruction = CSYNC_INSTRUCTION_NEW;
                conflict_item._modtime = conflict_mod_time;
                conflict_item._size = item._previous_size;
                emit new_item (conflict_item);
                composite.append_task (conflict_item);
            }
        }

        // Need a new sync to detect the created copy of the conflicting file
        _another_sync_needed = true;

        return true;
    }

    string OwncloudPropagator.adjust_renamed_path (string original) {
        return Occ.adjust_renamed_path (_renamed_directories, original);
    }

    Result<Vfs.ConvertToPlaceholderResult, string> OwncloudPropagator.update_metadata (SyncFileItem &item) {
        return OwncloudPropagator.static_update_metadata (item, _local_dir, sync_options ()._vfs.data (), _journal);
    }

    Result<Vfs.ConvertToPlaceholderResult, string> OwncloudPropagator.static_update_metadata (SyncFileItem &item, string local_dir,
                                                                                              Vfs vfs, SyncJournalDb const journal) {
        const string fs_path = local_dir + item.destination ();
        const var result = vfs.convert_to_placeholder (fs_path, item);
        if (!result) {
            return result.error ();
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            return Vfs.ConvertToPlaceholderResult.Locked;
        }
        var record = item.to_sync_journal_file_record_with_inode (fs_path);
        const var d_bresult = journal.set_file_record (record);
        if (!d_bresult) {
            return d_bresult.error ();
        }
        return Vfs.ConvertToPlaceholderResult.Ok;
    }

    bool OwncloudPropagator.is_delayed_upload_item (SyncFileItemPtr &item) {
        return account ().capabilities ().bulk_upload () && !_schedule_delayed_tasks && !item._is_encrypted && _sync_options._min_chunk_size > item._size && !is_in_bulk_upload_black_list (item._file);
    }

    void OwncloudPropagator.set_schedule_delayed_tasks (bool active) {
        _schedule_delayed_tasks = active;
    }

    void OwncloudPropagator.clear_delayed_tasks () {
        _delayed_tasks.clear ();
    }

    void OwncloudPropagator.add_to_bulk_upload_black_list (string file) {
        q_c_debug (lc_propagator) << "black list for bulk upload" << file;
        _bulk_upload_black_list.insert (file);
    }

    void OwncloudPropagator.remove_from_bulk_upload_black_list (string file) {
        q_c_debug (lc_propagator) << "black list for bulk upload" << file;
        _bulk_upload_black_list.remove (file);
    }

    bool OwncloudPropagator.is_in_bulk_upload_black_list (string file) {
        return _bulk_upload_black_list.contains (file);
    }

    // ================================================================================

    PropagatorJob.PropagatorJob (OwncloudPropagator propagator)
        : GLib.Object (propagator)
        , _state (NotYetStarted) {
    }

    OwncloudPropagator *PropagatorJob.propagator () {
        return qobject_cast<OwncloudPropagator> (parent ());
    }

    // ================================================================================

    PropagatorJob.JobParallelism PropagatorCompositeJob.parallelism () {
        // If any of the running sub jobs is not parallel, we have to wait
        for (int i = 0; i < _running_jobs.count (); ++i) {
            if (_running_jobs.at (i).parallelism () != FullParallelism) {
                return _running_jobs.at (i).parallelism ();
            }
        }
        return FullParallelism;
    }

    void PropagatorCompositeJob.on_sub_job_abort_finished () {
        // Count that job has been on_finished
        _aborts_count--;

        // Emit on_abort if last job has been aborted
        if (_aborts_count == 0) {
            emit abort_finished ();
        }
    }

    void PropagatorCompositeJob.append_job (PropagatorJob job) {
        job.set_associated_composite (this);
        _jobs_to_do.append (job);
    }

    bool PropagatorCompositeJob.on_schedule_self_or_child () {
        if (_state == Finished) {
            return false;
        }

        // Start the composite job
        if (_state == NotYetStarted) {
            _state = Running;
        }

        // Ask all the running composite jobs if they have something new to schedule.
        for (var running_job : q_as_const (_running_jobs)) {
            ASSERT (running_job._state == Running);

            if (possibly_run_next_job (running_job)) {
                return true;
            }

            // If any of the running sub jobs is not parallel, we have to cancel the scheduling
            // of the rest of the list and wait for the blocking job to finish and schedule the next one.
            var paral = running_job.parallelism ();
            if (paral == WaitForFinished) {
                return false;
            }
        }

        // Now it's our turn, check if we have something left to do.
        // First, convert a task to a job if necessary
        while (_jobs_to_do.is_empty () && !_tasks_to_do.is_empty ()) {
            SyncFileItemPtr next_task = _tasks_to_do.first ();
            _tasks_to_do.remove (0);
            PropagatorJob job = propagator ().create_job (next_task);
            if (!job) {
                q_c_warning (lc_directory) << "Useless task found for file" << next_task.destination () << "instruction" << next_task._instruction;
                continue;
            }
            append_job (job);
            break;
        }
        // Then run the next job
        if (!_jobs_to_do.is_empty ()) {
            PropagatorJob next_job = _jobs_to_do.first ();
            _jobs_to_do.remove (0);
            _running_jobs.append (next_job);
            return possibly_run_next_job (next_job);
        }

        // If neither us or our children had stuff left to do we could hang. Make sure
        // we mark this job as on_finished so that the propagator can schedule a new one.
        if (_jobs_to_do.is_empty () && _tasks_to_do.is_empty () && _running_jobs.is_empty ()) {
            // Our parent jobs are already iterating over their running jobs, post to the event loop
            // to avoid removing ourself from that list while they iterate.
            QMetaObject.invoke_method (this, "on_finalize", Qt.QueuedConnection);
        }
        return false;
    }

    void PropagatorCompositeJob.on_sub_job_finished (SyncFileItem.Status status) {
        var sub_job = static_cast<PropagatorJob> (sender ());
        ASSERT (sub_job);

        // Delete the job and remove it from our list of jobs.
        sub_job.delete_later ();
        int i = _running_jobs.index_of (sub_job);
        ENFORCE (i >= 0); // should only happen if this function is called more than once
        _running_jobs.remove (i);

        // Any sub job error will cause the whole composite to fail. This is important
        // for knowing whether to update the etag in PropagateDirectory, for example.
        if (status == SyncFileItem.FatalError
            || status == SyncFileItem.NormalError
            || status == SyncFileItem.SoftError
            || status == SyncFileItem.DetailError
            || status == SyncFileItem.BlacklistedError) {
            _has_error = status;
        }

        if (_jobs_to_do.is_empty () && _tasks_to_do.is_empty () && _running_jobs.is_empty ()) {
            on_finalize ();
        } else {
            propagator ().schedule_next_job ();
        }
    }

    void PropagatorCompositeJob.on_finalize () {
        // The propagator will do parallel scheduling and this could be posted
        // multiple times on the event loop, ignore the duplicate calls.
        if (_state == Finished)
            return;

        _state = Finished;
        emit finished (_has_error == SyncFileItem.NoStatus ? SyncFileItem.Success : _has_error);
    }

    int64 PropagatorCompositeJob.committed_disk_space () {
        int64 needed = 0;
        foreach (PropagatorJob job, _running_jobs) {
            needed += job.committed_disk_space ();
        }
        return needed;
    }

    // ================================================================================

    PropagateDirectory.PropagateDirectory (OwncloudPropagator propagator, SyncFileItemPtr &item)
        : PropagatorJob (propagator)
        , _item (item)
        , _first_job (propagator.create_job (item))
        , _sub_jobs (propagator) {
        if (_first_job) {
            connect (_first_job.data (), &PropagatorJob.on_finished, this, &PropagateDirectory.on_first_job_finished);
            _first_job.set_associated_composite (&_sub_jobs);
        }
        connect (&_sub_jobs, &PropagatorJob.on_finished, this, &PropagateDirectory.on_sub_jobs_finished);
    }

    PropagatorJob.JobParallelism PropagateDirectory.parallelism () {
        // If any of the non-on_finished sub jobs is not parallel, we have to wait
        if (_first_job && _first_job.parallelism () != FullParallelism) {
            return WaitForFinished;
        }
        if (_sub_jobs.parallelism () != FullParallelism) {
            return WaitForFinished;
        }
        return FullParallelism;
    }

    bool PropagateDirectory.on_schedule_self_or_child () {
        if (_state == Finished) {
            return false;
        }

        if (_state == NotYetStarted) {
            _state = Running;
        }

        if (_first_job && _first_job._state == NotYetStarted) {
            return _first_job.on_schedule_self_or_child ();
        }

        if (_first_job && _first_job._state == Running) {
            // Don't schedule any more job until this is done.
            return false;
        }

        return _sub_jobs.on_schedule_self_or_child ();
    }

    void PropagateDirectory.on_first_job_finished (SyncFileItem.Status status) {
        _first_job.take ().delete_later ();

        if (status != SyncFileItem.Success
            && status != SyncFileItem.Restoration
            && status != SyncFileItem.Conflict) {
            if (_state != Finished) {
                // Synchronously on_abort
                on_abort (AbortType.Synchronous);
                _state = Finished;
                q_c_info (lc_propagator) << "PropagateDirectory.on_first_job_finished" << "emit finished" << status;
                emit finished (status);
            }
            return;
        }

        propagator ().schedule_next_job ();
    }

    void PropagateDirectory.on_sub_jobs_finished (SyncFileItem.Status status) {
        if (!_item.is_empty () && status == SyncFileItem.Success) {
            // If a directory is renamed, recursively delete any stale items
            // that may still exist below the old path.
            if (_item._instruction == CSYNC_INSTRUCTION_RENAME
                && _item._original_file != _item._rename_target) {
                propagator ()._journal.delete_file_record (_item._original_file, true);
            }

            if (_item._instruction == CSYNC_INSTRUCTION_NEW && _item._direction == SyncFileItem.Down) {
                // special case for local MKDIR, set local directory mtime
                // (it's not synced later at all, but can be nice to have it set initially)

                if (_item._modtime <= 0) {
                    status = _item._status = SyncFileItem.NormalError;
                    _item._error_string = tr ("Error updating metadata due to invalid modified time");
                    q_c_warning (lc_directory) << "Error writing to the database for file" << _item._file;
                }

                FileSystem.set_mod_time (propagator ().full_local_path (_item.destination ()), _item._modtime);
            }

            // For new directories we always want to update the etag once
            // the directory has been propagated. Otherwise the directory
            // could appear locally without being added to the database.
            if (_item._instruction == CSYNC_INSTRUCTION_RENAME
                || _item._instruction == CSYNC_INSTRUCTION_NEW
                || _item._instruction == CSYNC_INSTRUCTION_UPDATE_METADATA) {
                const var result = propagator ().update_metadata (*_item);
                if (!result) {
                    status = _item._status = SyncFileItem.FatalError;
                    _item._error_string = tr ("Error updating metadata : %1").arg (result.error ());
                    q_c_warning (lc_directory) << "Error writing to the database for file" << _item._file << "with" << result.error ();
                } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
                    _item._status = SyncFileItem.SoftError;
                    _item._error_string = tr ("File is currently in use");
                }
            }
        }
        _state = Finished;
        q_c_info (lc_propagator) << "PropagateDirectory.on_sub_jobs_finished" << "emit finished" << status;
        emit finished (status);
    }

    PropagateRootDirectory.PropagateRootDirectory (OwncloudPropagator propagator)
        : PropagateDirectory (propagator, SyncFileItemPtr (new SyncFileItem))
        , _dir_deletion_jobs (propagator) {
        connect (&_dir_deletion_jobs, &PropagatorJob.on_finished, this, &PropagateRootDirectory.on_dir_deletion_jobs_finished);
    }

    PropagatorJob.JobParallelism PropagateRootDirectory.parallelism () {
        // the root directory parallelism isn't important
        return WaitForFinished;
    }

    void PropagateRootDirectory.on_abort (PropagatorJob.AbortType abort_type) {
        if (_first_job)
            // Force first job to on_abort synchronously
            // even if caller allows async on_abort (async_abort)
            _first_job.on_abort (AbortType.Synchronous);

        if (abort_type == AbortType.Asynchronous) {
            struct AbortsFinished {
                bool sub_jobs_finished = false;
                bool dir_deletion_finished = false;
            };
            var abort_status = unowned<AbortsFinished> (new AbortsFinished);

            connect (&_sub_jobs, &PropagatorCompositeJob.abort_finished, this, [this, abort_status] () {
                abort_status.sub_jobs_finished = true;
                if (abort_status.sub_jobs_finished && abort_status.dir_deletion_finished)
                    emit abort_finished ();
            });
            connect (&_dir_deletion_jobs, &PropagatorCompositeJob.abort_finished, this, [this, abort_status] () {
                abort_status.dir_deletion_finished = true;
                if (abort_status.sub_jobs_finished && abort_status.dir_deletion_finished)
                    emit abort_finished ();
            });
        }
        _sub_jobs.on_abort (abort_type);
        _dir_deletion_jobs.on_abort (abort_type);
    }

    int64 PropagateRootDirectory.committed_disk_space () {
        return _sub_jobs.committed_disk_space () + _dir_deletion_jobs.committed_disk_space ();
    }

    bool PropagateRootDirectory.on_schedule_self_or_child () {
        q_c_info (lc_root_directory ()) << "on_schedule_self_or_child" << _state << "pending uploads" << propagator ().delayed_tasks ().size () << "subjobs state" << _sub_jobs._state;

        if (_state == Finished) {
            return false;
        }

        if (PropagateDirectory.on_schedule_self_or_child () && propagator ().delayed_tasks ().empty ()) {
            return true;
        }

        // Important : Finish _sub_jobs before scheduling any deletes.
        if (_sub_jobs._state != Finished) {
            return false;
        }

        if (!propagator ().delayed_tasks ().empty ()) {
            return schedule_delayed_jobs ();
        }

        return _dir_deletion_jobs.on_schedule_self_or_child ();
    }

    void PropagateRootDirectory.on_sub_jobs_finished (SyncFileItem.Status status) {
        q_c_info (lc_root_directory ()) << status << "on_sub_jobs_finished" << _state << "pending uploads" << propagator ().delayed_tasks ().size () << "subjobs state" << _sub_jobs._state;

        if (!propagator ().delayed_tasks ().empty ()) {
            schedule_delayed_jobs ();
            return;
        }

        if (status != SyncFileItem.Success
            && status != SyncFileItem.Restoration
            && status != SyncFileItem.Conflict) {
            if (_state != Finished) {
                // Synchronously on_abort
                on_abort (AbortType.Synchronous);
                _state = Finished;
                q_c_info (lc_propagator) << "PropagateRootDirectory.on_sub_jobs_finished" << "emit finished" << status;
                emit finished (status);
            }
            return;
        }

        propagator ().schedule_next_job ();
    }

    void PropagateRootDirectory.on_dir_deletion_jobs_finished (SyncFileItem.Status status) {
        _state = Finished;
        q_c_info (lc_propagator) << "PropagateRootDirectory.on_dir_deletion_jobs_finished" << "emit finished" << status;
        emit finished (status);
    }

    bool PropagateRootDirectory.schedule_delayed_jobs () {
        q_c_info (lc_propagator) << "PropagateRootDirectory.schedule_delayed_jobs";
        propagator ().set_schedule_delayed_tasks (true);
        var bulk_propagator_job = std.make_unique<BulkPropagatorJob> (propagator (), propagator ().delayed_tasks ());
        propagator ().clear_delayed_tasks ();
        _sub_jobs.append_job (bulk_propagator_job.release ());
        _sub_jobs._state = Running;
        return _sub_jobs.on_schedule_self_or_child ();
    }

    // ================================================================================

    CleanupPollsJob.~CleanupPollsJob () = default;

    void CleanupPollsJob.on_start () {
        if (_poll_infos.empty ()) {
            emit finished ();
            delete_later ();
            return;
        }

        var info = _poll_infos.first ();
        _poll_infos.pop_front ();
        SyncFileItemPtr item (new SyncFileItem);
        item._file = info._file;
        item._modtime = info._modtime;
        item._size = info._file_size;
        var job = new PollJob (_account, info._url, item, _journal, _local_path, this);
        connect (job, &PollJob.finished_signal, this, &CleanupPollsJob.on_poll_finished);
        job.on_start ();
    }

    void CleanupPollsJob.on_poll_finished () {
        var job = qobject_cast<PollJob> (sender ());
        ASSERT (job);
        if (job._item._status == SyncFileItem.FatalError) {
            emit aborted (job._item._error_string);
            delete_later ();
            return;
        } else if (job._item._status != SyncFileItem.Success) {
            q_c_warning (lc_cleanup_polls) << "There was an error with file " << job._item._file << job._item._error_string;
        } else {
            if (!OwncloudPropagator.static_update_metadata (*job._item, _local_path, _vfs.data (), _journal)) {
                q_c_warning (lc_cleanup_polls) << "database error";
                job._item._status = SyncFileItem.FatalError;
                job._item._error_string = tr ("Error writing metadata to the database");
                emit aborted (job._item._error_string);
                delete_later ();
                return;
            }
            _journal.set_upload_info (job._item._file, SyncJournalDb.UploadInfo ());
        }
        // Continue with the next entry, or finish
        on_start ();
    }

    string OwncloudPropagator.full_remote_path (string tmp_file_name) {
        // TODO : should this be part of the _item (SyncFileItemPtr)?
        return _remote_folder + tmp_file_name;
    }

    string OwncloudPropagator.remote_path () {
        return _remote_folder;
    }

    inline GLib.ByteArray get_etag_from_reply (QNetworkReply reply) {
        GLib.ByteArray oc_etag = parse_etag (reply.raw_header ("OC-ETag"));
        GLib.ByteArray etag = parse_etag (reply.raw_header ("ETag"));
        GLib.ByteArray ret = oc_etag;
        if (ret.is_empty ()) {
            ret = etag;
        }
        if (oc_etag.length () > 0 && oc_etag != etag) {
            q_c_debug (lc_propagator) << "Quite peculiar, we have an etag != OC-Etag [no problem!]" << etag << oc_etag;
        }
        return ret;
    }


    /***********************************************************
    Given an error from the network, map to a SyncFileItem.Status error
    ***********************************************************/
    inline SyncFileItem.Status classify_error (QNetworkReply.NetworkError nerror,
        int http_code, bool another_sync_needed = nullptr, GLib.ByteArray error_body = GLib.ByteArray ()) {
        Q_ASSERT (nerror != QNetworkReply.NoError); // we should only be called when there is an error

        if (nerror == QNetworkReply.RemoteHostClosedError) {
            // Sometimes server bugs lead to a connection close on certain files,
            // that shouldn't bring the rest of the syncing to a halt.
            return SyncFileItem.NormalError;
        }

        if (nerror > QNetworkReply.NoError && nerror <= QNetworkReply.UnknownProxyError) {
            // network error or proxy error . fatal
            return SyncFileItem.FatalError;
        }

        if (http_code == 503) {
            // When the server is in maintenance mode, we want to exit the sync immediatly
            // so that we do not flood the server with many requests
            // BUG : This relies on a translated string and is thus unreliable.
            //      In the future it should return a NormalError and trigger a status.php
            //      check that detects maintenance mode reliably and will terminate the sync run.
            var probably_maintenance =
                    error_body.contains (R" (>Sabre\DAV\Exception\ServiceUnavailable<)")
                    && !error_body.contains ("Storage is temporarily not available");
            return probably_maintenance ? SyncFileItem.FatalError : SyncFileItem.NormalError;
        }

        if (http_code == 412) {
            // "Precondition Failed"
            // Happens when the e-tag has changed
            return SyncFileItem.SoftError;
        }

        if (http_code == 423) {
            // "Locked"
            // Should be temporary.
            if (another_sync_needed) {
                *another_sync_needed = true;
            }
            return SyncFileItem.FileLocked;
        }

        return SyncFileItem.NormalError;
    }
    }
    