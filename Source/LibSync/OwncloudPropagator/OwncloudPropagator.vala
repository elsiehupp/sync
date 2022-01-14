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
// #include <GLib.Object>
// #include <QTimer_event>
// #include <QRegularExpression>
// #include <qmath.h>

// #include <QHash>
// #include <GLib.Object>
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
        const auto modtime = Occ.Utility.q_date_time_from_time_t (item._modtime);
        const int64 ms_since_mod = modtime.msecs_to (QDateTime.current_date_time_utc ());

        return std.chrono.milliseconds (ms_since_mod) < Occ.SyncEngine.minimum_file_age_for_upload
            // if the mtime is too much in the future we *do* upload the file
            && ms_since_mod > -10000;
    }

}

namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lc_propagator)

/***********************************************************
Free disk space threshold below which syncs will abort and not even start.
***********************************************************/
int64 critical_free_space_limit ();

/***********************************************************
The client will not intentionally reduce the available free disk space below
 this limit.

Uploads will still run and downloads that are small enough will continue too.
***********************************************************/
int64 free_space_limit ();

void blacklist_update (SyncJournalDb *journal, SyncFileItem &item);


/***********************************************************
@brief the base class of propagator jobs

This can either be a job, or a container for jobs.
If it is a composite job, it then inherits from Propagate_directory

@ingroup libsync
***********************************************************/
class Propagator_job : GLib.Object {

public:
    Propagator_job (Owncloud_propagator *propagator);

    enum Abort_type {
        Synchronous,
        Asynchronous
    };

    Q_ENUM (Abort_type)

    enum Job_state {
        Not_yet_started,
        Running,
        Finished
    };
    Job_state _state;

    Q_ENUM (Job_state)

    enum Job_parallelism {
        /***********************************************************
        Jobs can be run in parallel to this job
        ***********************************************************/
        Full_parallelism,

        /***********************************************************
        No other job shall be started until this one has finished.
        So this job is guaranteed to finish before any jobs below
        it are executed.
        ***********************************************************/
        Wait_for_finished,
    };

    Q_ENUM (Job_parallelism)

    virtual Job_parallelism parallelism () {
        return Full_parallelism;
    }

    /***********************************************************
    For "small" jobs
    ***********************************************************/
    virtual bool is_likely_finished_quickly () {
        return false;
    }

    /***********************************************************
    The space that the running jobs need to complete but don't actually use yet.

    Note that this does *not* include the disk space that's already
    in use by running jobs for things like a download-in-progress.
    ***********************************************************/
    virtual int64 committed_disk_space () {
        return 0;
    }

    /***********************************************************
    Set the associated composite job

    Used only from Propagator_composite_job itself, when a job is added
    and from Propagate_directory to associate the sub_jobs with the first
    job.
    ***********************************************************/
    void set_associated_composite (Propagator_composite_job *job) {
        _associated_composite = job;
    }

public slots:
    /***********************************************************
    Asynchronous abort requires emit of abort_finished () signal,
    while synchronous is expected to abort immedietaly.
    ***********************************************************/
    virtual void abort (Propagator_job.Abort_type abort_type) {
        if (abort_type == Abort_type.Asynchronous)
            emit abort_finished ();
    }

    /***********************************************************
    Starts this job, or a new subjob
    returns true if a job was started.
    ***********************************************************/
    virtual bool schedule_self_or_child () = 0;
signals:
    /***********************************************************
    Emitted when the job is fully finished
    ***********************************************************/
    void finished (SyncFileItem.Status);

    /***********************************************************
    Emitted when the abort is fully finished
    ***********************************************************/
    void abort_finished (SyncFileItem.Status status = SyncFileItem.Normal_error);
protected:
    Owncloud_propagator *propagator ();

    /***********************************************************
    If this job gets added to a composite job, this will point to the parent.

    For the Propagate_directory._first_job it will point to
    Propagate_directory._sub_jobs.

    That can be useful for jobs that want to spawn follow-up jobs without
    becoming composite jobs themselves.
    ***********************************************************/
    Propagator_composite_job *_associated_composite = nullptr;
};

/***********************************************************
Abstract class to propagate a single item
***********************************************************/
class Propagate_item_job : Propagator_job {
protected:
    virtual void done (SyncFileItem.Status status, string &error_string = string ());

    /***********************************************************
    set a custom restore job message that is used if the restore job succeeded.
    It is displayed in the activity view.
    ***********************************************************/
    string restore_job_msg () {
        return _item._is_restoration ? _item._error_string : string ();
    }
    void set_restore_job_msg (string &msg = string ()) {
        _item._is_restoration = true;
        _item._error_string = msg;
    }

    bool has_encrypted_ancestor ();

protected slots:
    void slot_restore_job_finished (SyncFileItem.Status status);

private:
    QScopedPointer<Propagate_item_job> _restore_job;
    Job_parallelism _parallelism;

public:
    Propagate_item_job (Owncloud_propagator *propagator, SyncFileItemPtr &item)
        : Propagator_job (propagator)
        , _parallelism (Full_parallelism)
        , _item (item) {
        // we should always execute jobs that process the E2EE API calls as sequential jobs
        // TODO : In fact, we must make sure Lock/Unlock are not colliding and always wait for each other to complete. So, we could refactor this "_parallelism" later
        // so every "Propagate_item_job" that will potentially execute Lock job on E2EE folder will get executed sequentially.
        // As an alternative, we could optimize Lock/Unlock calls, so we do a batch-write on one folder and only lock and unlock a folder once per batch.
        _parallelism = (_item._is_encrypted || has_encrypted_ancestor ()) ? Wait_for_finished : Full_parallelism;
    }
    ~Propagate_item_job () override;

    bool schedule_self_or_child () override {
        if (_state != Not_yet_started) {
            return false;
        }
        q_c_info (lc_propagator) << "Starting" << _item._instruction << "propagation of" << _item.destination () << "by" << this;

        _state = Running;
        QMetaObject.invoke_method (this, "start"); // We could be in a different thread (neon jobs)
        return true;
    }

    Job_parallelism parallelism () override {
        return _parallelism;
    }

    SyncFileItemPtr _item;

public slots:
    virtual void start () = 0;
};

/***********************************************************
@brief Job that runs subjobs. It becomes finished only when all subjobs are finished.
@ingroup libsync
***********************************************************/
class Propagator_composite_job : Propagator_job {
public:
    QVector<Propagator_job> _jobs_to_do;
    Sync_file_item_vector _tasks_to_do;
    QVector<Propagator_job> _running_jobs;
    SyncFileItem.Status _has_error; // No_status,  or Normal_error / Soft_error if there was an error
    uint64 _aborts_count;

    Propagator_composite_job (Owncloud_propagator *propagator)
        : Propagator_job (propagator)
        , _has_error (SyncFileItem.No_status), _aborts_count (0) {
    }

    // Don't delete jobs in _jobs_to_do and _running_jobs : they have parents
    // that will be responsible for cleanup. Deleting them here would risk
    // deleting something that has already been deleted by a shared parent.
    ~Propagator_composite_job () override = default;

    void append_job (Propagator_job *job);
    void append_task (SyncFileItemPtr &item) {
        _tasks_to_do.append (item);
    }

    bool schedule_self_or_child () override;
    Job_parallelism parallelism () override;

    /***********************************************************
    Abort synchronously or asynchronously - some jobs
    require to be finished without immediete abort (abort on job might
    cause conflicts/duplicated files - owncloud/client/issues/5949)
    ***********************************************************/
    void abort (Propagator_job.Abort_type abort_type) override {
        if (!_running_jobs.empty ()) {
            _aborts_count = _running_jobs.size ();
            foreach (Propagator_job *j, _running_jobs) {
                if (abort_type == Abort_type.Asynchronous) {
                    connect (j, &Propagator_job.abort_finished,
                            this, &Propagator_composite_job.slot_sub_job_abort_finished);
                }
                j.abort (abort_type);
            }
        } else if (abort_type == Abort_type.Asynchronous){
            emit abort_finished ();
        }
    }

    int64 committed_disk_space () const override;

private slots:
    void slot_sub_job_abort_finished ();
    bool possibly_run_next_job (Propagator_job *next) {
        if (next._state == Not_yet_started) {
            connect (next, &Propagator_job.finished, this, &Propagator_composite_job.slot_sub_job_finished);
        }
        return next.schedule_self_or_child ();
    }

    void slot_sub_job_finished (SyncFileItem.Status status);
    void finalize ();
};

/***********************************************************
@brief Propagate a directory, and all its sub entries.
@ingroup libsync
***********************************************************/
class Propagate_directory : Propagator_job {
public:
    SyncFileItemPtr _item;
    // e.g : create the directory
    QScopedPointer<Propagate_item_job> _first_job;

    Propagator_composite_job _sub_jobs;

    Propagate_directory (Owncloud_propagator *propagator, SyncFileItemPtr &item);

    void append_job (Propagator_job *job) {
        _sub_jobs.append_job (job);
    }

    void append_task (SyncFileItemPtr &item) {
        _sub_jobs.append_task (item);
    }

    bool schedule_self_or_child () override;
    Job_parallelism parallelism () override;
    void abort (Propagator_job.Abort_type abort_type) override {
        if (_first_job)
            // Force first job to abort synchronously
            // even if caller allows async abort (async_abort)
            _first_job.abort (Abort_type.Synchronous);

        if (abort_type == Abort_type.Asynchronous){
            connect (&_sub_jobs, &Propagator_composite_job.abort_finished, this, &Propagate_directory.abort_finished);
        }
        _sub_jobs.abort (abort_type);
    }

    void increase_affected_count () {
        _first_job._item._affected_items++;
    }

    int64 committed_disk_space () const override {
        return _sub_jobs.committed_disk_space ();
    }

private slots:

    void slot_first_job_finished (SyncFileItem.Status status);
    virtual void slot_sub_jobs_finished (SyncFileItem.Status status);

};

/***********************************************************
@brief Propagate the root directory, and all its sub entries.
@ingroup libsync

Primary difference to Propagate_directory is that it keeps track of directory
deletions that must happen at the very end.
***********************************************************/
class Propagate_root_directory : Propagate_directory {
public:
    Propagator_composite_job _dir_deletion_jobs;

    Propagate_root_directory (Owncloud_propagator *propagator);

    bool schedule_self_or_child () override;
    Job_parallelism parallelism () override;
    void abort (Propagator_job.Abort_type abort_type) override;

    int64 committed_disk_space () const override;

private slots:
    void slot_sub_jobs_finished (SyncFileItem.Status status) override;
    void slot_dir_deletion_jobs_finished (SyncFileItem.Status status);

private:

    bool schedule_delayed_jobs ();
};

/***********************************************************
@brief Dummy job that just mark it as completed and ignored
@ingroup libsync
***********************************************************/
class Propagate_ignore_job : Propagate_item_job {
public:
    Propagate_ignore_job (Owncloud_propagator *propagator, SyncFileItemPtr &item)
        : Propagate_item_job (propagator, item) {
    }
    void start () override {
        SyncFileItem.Status status = _item._status;
        if (status == SyncFileItem.No_status) {
            if (_item._instruction == CSYNC_INSTRUCTION_ERROR) {
                status = SyncFileItem.Normal_error;
            } else {
                status = SyncFileItem.File_ignored;
                ASSERT (_item._instruction == CSYNC_INSTRUCTION_IGNORE);
            }
        }
        done (status, _item._error_string);
    }
};


class Owncloud_propagator : GLib.Object {
public:
    SyncJournalDb *const _journal;
    bool _finished_emited; // used to ensure that finished is only emitted once

public:
    Owncloud_propagator (AccountPtr account, string &local_dir,
                       const string &remote_folder, SyncJournalDb *progress_db,
                       QSet<string> &bulk_upload_black_list)
        : _journal (progress_db)
        , _finished_emited (false)
        , _bandwidth_manager (this)
        , _another_sync_needed (false)
        , _chunk_size (10 * 1000 * 1000) // 10 MB, overridden in set_sync_options
        , _account (account)
        , _local_dir ( (local_dir.ends_with (QChar ('/'))) ? local_dir : local_dir + '/')
        , _remote_folder ( (remote_folder.ends_with (QChar ('/'))) ? remote_folder : remote_folder + '/')
        , _bulk_upload_black_list (bulk_upload_black_list) {
        q_register_meta_type<Propagator_job.Abort_type> ("Propagator_job.Abort_type");
    }

    ~Owncloud_propagator () override;

    void start (Sync_file_item_vector &&_synced_items);

    void start_directory_propagation (SyncFileItemPtr &item,
                                   QStack<QPair<string, Propagate_directory>> &directories,
                                   QVector<Propagator_job> &directories_to_remove,
                                   string &removed_directory,
                                   const Sync_file_item_vector &items);

    void start_file_propagation (SyncFileItemPtr &item,
                              QStack<QPair<string, Propagate_directory>> &directories,
                              QVector<Propagator_job> &directories_to_remove,
                              string &removed_directory,
                              string &maybe_conflict_directory);

    const Sync_options &sync_options ();
    void set_sync_options (Sync_options &sync_options);

    int _download_limit = 0;
    int _upload_limit = 0;
    Bandwidth_manager _bandwidth_manager;

    bool _abort_requested = false;

    /***********************************************************
    The list of currently active jobs.
        This list contains the jobs that are currently using ressources and is used purely to
        know how many jobs there is currently running for the scheduler.
        Jobs add themself to the list when they do an assynchronous operation.
        Jobs can be several time on the list (example, when several chunks are uploaded in parallel)
    ***********************************************************/
    QList<Propagate_item_job> _active_job_list;

    /***********************************************************
    We detected that another sync is required after this one
    ***********************************************************/
    bool _another_sync_needed;

    /***********************************************************
    Per-folder quota guesses.

    This starts out empty. When an upload in a folder fails due to insufficent
    remote quota, the quota guess is updated to be attempted_size-1 at maximum.

    Note that it will usually just an upper limit for the actual quota - but
    since the quota on the server might ch
    wrong in the other direction as well.

    This allows skipping of uploads that have a very high likelihood of failure.
    ***********************************************************/
    QHash<string, int64> _folder_quota;

    
    /***********************************************************
    the maximum number of jobs using bandwidth (uploads or downloads, in parallel)
    ***********************************************************/
    int maximum_active_transfer_job ();

    /***********************************************************
    The size to use for upload chunks.

    Will be dynamically adjusted after each chunk upload finishes
    if Capabilities.desired_chunk_upload_duration has a target
    chunk-upload duration set.
    ***********************************************************/
    int64 _chunk_size;
    int64 small_file_size ();

    /***********************************************************
    The maximum number of active jobs in parallel
    ***********************************************************/
    int hard_maximum_active_job ();

    /***********************************************************
    Check whether a download would clash with an existing file
    in filesystems that are only case-preserving.
    ***********************************************************/
    bool local_file_name_clash (string &relfile);

    /***********************************************************
    Check whether a file is properly accessible for upload.

    It is possible to create files with filenames that differ
    only by case in NTFS, but most operations such as stat and
    open only target one of these by default.

    When that happens, we want to avoid uploading incorrect data
    and give up on the file.
    ***********************************************************/
    bool has_case_clash_accessibility_problem (string &relfile);

    Q_REQUIRED_RESULT string full_local_path (string &tmp_file_name) const;
    string local_path ();

    /***********************************************************
    Returns the full remote path including the folder root of a
    folder sync path.
    ***********************************************************/
    Q_REQUIRED_RESULT string full_remote_path (string &tmp_file_name) const;
    string remote_path ();

    /***********************************************************
    Creates the job for an item.
    ***********************************************************/
    Propagate_item_job *create_job (SyncFileItemPtr &item);

    void schedule_next_job ();
    void report_progress (SyncFileItem &, int64 bytes);

    void abort () {
        if (_abort_requested)
            return;
        if (_root_job) {
            // Connect to abort_finished  which signals that abort has been asynchronously finished
            connect (_root_job.data (), &Propagate_directory.abort_finished, this, &Owncloud_propagator.emit_finished);

            // Use Queued Connection because we're possibly already in an item's finished stack
            QMetaObject.invoke_method (_root_job.data (), "abort", Qt.QueuedConnection,
                                      Q_ARG (Propagator_job.Abort_type, Propagator_job.Abort_type.Asynchronous));

            // Give asynchronous abort 5000 msec to finish on its own
            QTimer.single_shot (5000, this, SLOT (abort_timeout ()));
        } else {
            // No root job, call emit_finished
            emit_finished (SyncFileItem.Normal_error);
        }
    }

    AccountPtr account ();

    enum Disk_space_result {
        Disk_space_ok,
        Disk_space_failure,
        Disk_space_critical
    };

    /***********************************************************
    Checks whether there's enough disk space available to complete
     all jobs that are currently running.
    ***********************************************************/
    Disk_space_result disk_space_check ();

    /***********************************************************
    Handles a conflict by renaming the file 'item'.

    Sets up conflict records.

    It also creates a new upload job in composite if the item
    moved away is a file and conflict uploads are requested.

    Returns true on success, false and error on error.
    ***********************************************************/
    bool create_conflict (SyncFileItemPtr &item,
        Propagator_composite_job *composite, string *error);

    // Map original path (as in the DB) to target final path
    QMap<string, string> _renamed_directories;
    string adjust_renamed_path (string &original) const;

    /***********************************************************
    Update the database for an item.

    Typically after a sync operation succeeded. Updates the inode from
    the filesystem.

    Will also trigger a Vfs.convert_to_placeholder.
    ***********************************************************/
    Result<Vfs.ConvertToPlaceholderResult, string> update_metadata (SyncFileItem &item);

    /***********************************************************
    Update the database for an item.

    Typically after a sync operation succeeded. Updates the inode from
    the filesystem.

    Will also trigger a Vfs.convert_to_placeholder.
    ***********************************************************/
    static Result<Vfs.ConvertToPlaceholderResult, string> static_update_metadata (SyncFileItem &item, string local_dir,
                                                                                 Vfs *vfs, SyncJournalDb * const journal);

    Q_REQUIRED_RESULT bool is_delayed_upload_item (SyncFileItemPtr &item) const;

    Q_REQUIRED_RESULT const std.deque<SyncFileItemPtr>& delayed_tasks () {
        return _delayed_tasks;
    }

    void set_schedule_delayed_tasks (bool active);

    void clear_delayed_tasks ();

    void add_to_bulk_upload_black_list (string &file);

    void remove_from_bulk_upload_black_list (string &file);

    bool is_in_bulk_upload_black_list (string &file) const;

private slots:

    void abort_timeout () {
        // Abort synchronously and finish
        _root_job.data ().abort (Propagator_job.Abort_type.Synchronous);
        emit_finished (SyncFileItem.Normal_error);
    }

    /***********************************************************
    Emit the finished signal and make sure it is only emitted once
    ***********************************************************/
    void emit_finished (SyncFileItem.Status status) {
        if (!_finished_emited)
            emit finished (status == SyncFileItem.Success);
        _finished_emited = true;
    }

    void schedule_next_job_impl ();

signals:
    void new_item (SyncFileItemPtr &);
    void item_completed (SyncFileItemPtr &);
    void progress (SyncFileItem &, int64 bytes);
    void finished (bool success);

    /***********************************************************
    Emitted when propagation has problems with a locked file.
    ***********************************************************/
    void seen_locked_file (string &file_name);

    /***********************************************************
    Emitted when propagation touches a file.

    Used to track our own file modifications such that notifications
    from the file watcher about these can be ignored.
    ***********************************************************/
    void touched_file (string &file_name);

    void insufficient_local_storage ();
    void insufficient_remote_storage ();

private:
    std.unique_ptr<Propagate_upload_file_common> create_upload_job (SyncFileItemPtr item,
                                                               bool delete_existing);

    void push_delayed_upload_task (SyncFileItemPtr item);

    void reset_delayed_upload_tasks ();

    AccountPtr _account;
    QScopedPointer<Propagate_root_directory> _root_job;
    Sync_options _sync_options;
    bool _job_scheduled = false;

    const string _local_dir; // absolute path to the local directory. ends with '/'
    const string _remote_folder; // remote folder, ends with '/'

    std.deque<SyncFileItemPtr> _delayed_tasks;
    bool _schedule_delayed_tasks = false;

    QSet<string> &_bulk_upload_black_list;

    static bool _allow_delayed_upload;
};

/***********************************************************
@brief Job that wait for all the poll jobs to be completed
@ingroup libsync
***********************************************************/
class Cleanup_polls_job : GLib.Object {
    QVector<SyncJournalDb.Poll_info> _poll_infos;
    AccountPtr _account;
    SyncJournalDb *_journal;
    string _local_path;
    QSharedPointer<Vfs> _vfs;

public:
    Cleanup_polls_job (QVector<SyncJournalDb.Poll_info> &poll_infos, AccountPtr account, SyncJournalDb *journal, string &local_path,
                             const QSharedPointer<Vfs> &vfs, GLib.Object *parent = nullptr)
        : GLib.Object (parent)
        , _poll_infos (poll_infos)
        , _account (account)
        , _journal (journal)
        , _local_path (local_path)
        , _vfs (vfs) {
    }

    ~Cleanup_polls_job () override;

    /***********************************************************
    Start the job.  After the job is completed, it will emit either finished or aborted, and it
    will destroy itself.
    ***********************************************************/
    void start ();
signals:
    void finished ();
    void aborted (string &error);
private slots:
    void slot_poll_finished ();
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

    Owncloud_propagator.~Owncloud_propagator () = default;

    int Owncloud_propagator.maximum_active_transfer_job () {
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
    int Owncloud_propagator.hard_maximum_active_job () {
        if (!_sync_options._parallel_network_jobs)
            return 1;
        return _sync_options._parallel_network_jobs;
    }

    Propagate_item_job.~Propagate_item_job () {
        if (auto p = propagator ()) {
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

        if (item._status == SyncFileItem.Soft_error) {
            // Track these errors, but don't actively suppress them.
            entry._ignore_duration = 0;
        }

        if (item._http_error_code == 507) {
            entry._error_category = SyncJournalErrorBlacklistRecord.Insufficient_remote_storage;
        }

        return entry;
    }

    /***********************************************************
    Updates, creates or removes a blacklist entry for the given item.

    May adjust the status or item._error_string.
    ***********************************************************/
    void blacklist_update (SyncJournalDb *journal, SyncFileItem &item) {
        SyncJournalErrorBlacklistRecord old_entry = journal.error_blacklist_entry (item._file);

        bool may_blacklist =
            item._error_may_be_blacklisted // explicitly flagged for blacklisting
            || ( (item._status == SyncFileItem.Normal_error
                    || item._status == SyncFileItem.Soft_error
                    || item._status == SyncFileItem.Detail_error)
                   && item._http_error_code != 0 // or non-local error
                   );

        // No new entry? Possibly remove the old one, then done.
        if (!may_blacklist) {
            if (old_entry.is_valid ()) {
                journal.wipe_error_blacklist_entry (item._file);
            }
            return;
        }

        auto new_entry = create_blacklist_entry (old_entry, item);
        journal.set_error_blacklist_entry (new_entry);

        // Suppress the error if it was and continues to be blacklisted.
        // An ignore_duration of 0 mean we're tracking the error, but not actively
        // suppressing it.
        if (item._has_blacklist_entry && new_entry._ignore_duration > 0) {
            item._status = SyncFileItem.Blacklisted_error;

            q_c_info (lc_propagator) << "blacklisting " << item._file
                                 << " for " << new_entry._ignore_duration
                                 << ", retry count " << new_entry._retry_count;

            return;
        }

        // Some soft errors might become louder on repeat occurrence
        if (item._status == SyncFileItem.Soft_error
            && new_entry._retry_count > 1) {
            q_c_warning (lc_propagator) << "escalating soft error on " << item._file
                                    << " to normal error, " << item._http_error_code;
            item._status = SyncFileItem.Normal_error;
            return;
        }
    }

    void Propagate_item_job.done (SyncFileItem.Status status_arg, string &error_string) {
        // Duplicate calls to done () are a logic error
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

        if (propagator ()._abort_requested && (_item._status == SyncFileItem.Normal_error
                                              || _item._status == SyncFileItem.Fatal_error)) {
            // an abort request is ongoing. Change the status to Soft-Error
            _item._status = SyncFileItem.Soft_error;
        }

        // Blacklist handling
        switch (_item._status) {
        case SyncFileItem.Soft_error:
        case SyncFileItem.Fatal_error:
        case SyncFileItem.Normal_error:
        case SyncFileItem.Detail_error:
            // Check the blacklist, possibly adjusting the item (including its status)
            blacklist_update (propagator ()._journal, *_item);
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
        case SyncFileItem.File_ignored:
        case SyncFileItem.No_status:
        case SyncFileItem.Blacklisted_error:
        case SyncFileItem.File_locked:
        case SyncFileItem.File_name_invalid:
            // nothing
            break;
        }

        if (_item.has_error_status ())
            q_c_warning (lc_propagator) << "Could not complete propagation of" << _item.destination () << "by" << this << "with status" << _item._status << "and error:" << _item._error_string;
        else
            q_c_info (lc_propagator) << "Completed propagation of" << _item.destination () << "by" << this << "with status" << _item._status;
        emit propagator ().item_completed (_item);
        emit finished (_item._status);

        if (_item._status == SyncFileItem.Fatal_error) {
            // Abort all remaining jobs.
            propagator ().abort ();
        }
    }

    void Propagate_item_job.slot_restore_job_finished (SyncFileItem.Status status) {
        string msg;
        if (_restore_job) {
            msg = _restore_job.restore_job_msg ();
            _restore_job.set_restore_job_msg ();
        }

        if (status == SyncFileItem.Success || status == SyncFileItem.Conflict
            || status == SyncFileItem.Restoration) {
            done (SyncFileItem.Soft_error, msg);
        } else {
            done (status, tr ("A file or folder was removed from a read only share, but restoring failed : %1").arg (msg));
        }
    }

    bool Propagate_item_job.has_encrypted_ancestor () {
        if (!propagator ().account ().capabilities ().client_side_encryption_available ()) {
            return false;
        }

        const auto path = _item._file;
        const auto slash_position = path.last_index_of ('/');
        const auto parent_path = slash_position >= 0 ? path.left (slash_position) : string ();

        auto path_components = parent_path.split ('/');
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

    Propagate_item_job *Owncloud_propagator.create_job (SyncFileItemPtr &item) {
        bool delete_existing = item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE;
        switch (item._instruction) {
        case CSYNC_INSTRUCTION_REMOVE:
            if (item._direction == SyncFileItem.Down)
                return new Propagate_local_remove (this, item);
            else
                return new Propagate_remote_delete (this, item);
        case CSYNC_INSTRUCTION_NEW:
        case CSYNC_INSTRUCTION_TYPE_CHANGE:
        case CSYNC_INSTRUCTION_CONFLICT:
            if (item.is_directory ()) {
                // CONFLICT has _direction == None
                if (item._direction != SyncFileItem.Up) {
                    auto job = new Propagate_local_mkdir (this, item);
                    job.set_delete_existing_file (delete_existing);
                    return job;
                } else {
                    auto job = new Propagate_remote_mkdir (this, item);
                    job.set_delete_existing (delete_existing);
                    return job;
                }
            } //fall through
        case CSYNC_INSTRUCTION_SYNC:
            if (item._direction != SyncFileItem.Up) {
                auto job = new Propagate_download_file (this, item);
                job.set_delete_existing_folder (delete_existing);
                return job;
            } else {
                if (delete_existing || !is_delayed_upload_item (item)) {
                    auto job = create_upload_job (item, delete_existing);
                    return job.release ();
                } else {
                    push_delayed_upload_task (item);
                    return nullptr;
                }
            }
        case CSYNC_INSTRUCTION_RENAME:
            if (item._direction == SyncFileItem.Up) {
                return new Propagate_remote_move (this, item);
            } else {
                return new Propagate_local_rename (this, item);
            }
        case CSYNC_INSTRUCTION_IGNORE:
        case CSYNC_INSTRUCTION_ERROR:
            return new Propagate_ignore_job (this, item);
        default:
            return nullptr;
        }
        return nullptr;
    }

    std.unique_ptr<Propagate_upload_file_common> Owncloud_propagator.create_upload_job (SyncFileItemPtr item, bool delete_existing) {
        auto job = std.unique_ptr<Propagate_upload_file_common>{};

        if (item._size > sync_options ()._initial_chunk_size && account ().capabilities ().chunking_ng ()) {
            // Item is above _initial_chunk_size, thus will be classified as to be chunked
            job = std.make_unique<Propagate_upload_file_nG> (this, item);
        } else {
            job = std.make_unique<Propagate_upload_file_v1> (this, item);
        }

        job.set_delete_existing (delete_existing);

        remove_from_bulk_upload_black_list (item._file);

        return job;
    }

    void Owncloud_propagator.push_delayed_upload_task (SyncFileItemPtr item) {
        _delayed_tasks.push_back (item);
    }

    void Owncloud_propagator.reset_delayed_upload_tasks () {
        _schedule_delayed_tasks = false;
        _delayed_tasks.clear ();
    }

    int64 Owncloud_propagator.small_file_size () {
        const int64 small_file_size = 100 * 1024; //default to 1 MB. Not dynamic right now.
        return small_file_size;
    }

    void Owncloud_propagator.start (Sync_file_item_vector &&items) {
        Q_ASSERT (std.is_sorted (items.begin (), items.end ()));

        // This builds all the jobs needed for the propagation.
        // Each directory is a Propagate_directory job, which contains the files in it.
        // In order to do that we loop over the items. (which are sorted by destination)
        // When we enter a directory, we can create the directory job and push it on the stack.

        const auto regex = sync_options ().file_regex ();
        if (regex.is_valid ()) {
            QSet<QStringRef> names;
            for (auto &i : items) {
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
            items.erase (std.remove_if (items.begin (), items.end (), [&names] (auto i) {
                return !names.contains (QStringRef {
                    &i._file
                });
            }),
            items.end ());
        }

        reset_delayed_upload_tasks ();
        _root_job.reset (new Propagate_root_directory (this));
        QStack<QPair<string /* directory name */, Propagate_directory * /* job */>> directories;
        directories.push (q_make_pair (string (), _root_job.data ()));
        QVector<Propagator_job> directories_to_remove;
        string removed_directory;
        string maybe_conflict_directory;
        foreach (SyncFileItemPtr &item, items) {
            if (!removed_directory.is_empty () && item._file.starts_with (removed_directory)) {
                // this is an item in a directory which is going to be removed.
                auto *del_dir_job = qobject_cast<Propagate_directory> (directories_to_remove.first ());

                const auto is_new_directory = item.is_directory () &&
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

        foreach (Propagator_job *it, directories_to_remove) {
            _root_job._dir_deletion_jobs.append_job (it);
        }

        connect (_root_job.data (), &Propagator_job.finished, this, &Owncloud_propagator.emit_finished);

        _job_scheduled = false;
        schedule_next_job ();
    }

    void Owncloud_propagator.start_directory_propagation (SyncFileItemPtr &item,
                                                       QStack<QPair<string, Propagate_directory>> &directories,
                                                       QVector<Propagator_job> &directories_to_remove,
                                                       string &removed_directory,
                                                       const Sync_file_item_vector &items) {
        auto directory_propagation_job = std.make_unique<Propagate_directory> (this, item);

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
            // NOTE : Currently this means that we don't update those etag at all in this sync,
            //       but it should not be a problem, they will be updated in the next sync.
            for (int i = 0; i < directories.size (); ++i) {
                if (directories[i].second._item._instruction == CSYNC_INSTRUCTION_UPDATE_METADATA) {
                    directories[i].second._item._instruction = CSYNC_INSTRUCTION_NONE;
                }
            }
        } else {
            const auto current_dir_job = directories.top ().second;
            current_dir_job.append_job (directory_propagation_job.get ());
        }
        directories.push (q_make_pair (item.destination () + "/", directory_propagation_job.release ()));
    }

    void Owncloud_propagator.start_file_propagation (SyncFileItemPtr &item,
                                                  QStack<QPair<string, Propagate_directory> > &directories,
                                                  QVector<Propagator_job> &directories_to_remove,
                                                  string &removed_directory,
                                                  string &maybe_conflict_directory) {
        if (item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE) {
            // will delete directories, so defer execution
            auto job = create_job (item);
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

    const Sync_options &Owncloud_propagator.sync_options () {
        return _sync_options;
    }

    void Owncloud_propagator.set_sync_options (Sync_options &sync_options) {
        _sync_options = sync_options;
        _chunk_size = sync_options._initial_chunk_size;
    }

    bool Owncloud_propagator.local_file_name_clash (string &rel_file) {
        const string file (_local_dir + rel_file);
        Q_ASSERT (!file.is_empty ());

        if (!file.is_empty () && Utility.fs_case_preserving ()) {
            q_c_debug (lc_propagator) << "Case_clash_check for " << file;
            // On Linux, the file system is case sensitive, but this code is useful for testing.
            // Just check that there is no other file with the same name and different casing.
            QFileInfo file_info (file);
            const string fn = file_info.file_name ();
            const QStringList list = file_info.dir ().entry_list ({
                fn
            });
            if (list.count () > 1 || (list.count () == 1 && list[0] != fn)) {
                return true;
            }
        }
        return false;
    }

    bool Owncloud_propagator.has_case_clash_accessibility_problem (string &relfile) {
        Q_UNUSED (relfile);
        return false;
    }

    string Owncloud_propagator.full_local_path (string &tmp_file_name) {
        return _local_dir + tmp_file_name;
    }

    string Owncloud_propagator.local_path () {
        return _local_dir;
    }

    void Owncloud_propagator.schedule_next_job () {
        if (_job_scheduled) return; // don't schedule more than 1
        _job_scheduled = true;
        QTimer.single_shot (3, this, &Owncloud_propagator.schedule_next_job_impl);
    }

    void Owncloud_propagator.schedule_next_job_impl () {
        // TODO : If we see that the automatic up-scaling has a bad impact we
        // need to check how to avoid this.
        // Down-scaling on slow networks? https://github.com/owncloud/client/issues/3382
        // Making sure we do up/down at same time? https://github.com/owncloud/client/issues/1633

        _job_scheduled = false;

        if (_active_job_list.count () < maximum_active_transfer_job ()) {
            if (_root_job.schedule_self_or_child ()) {
                schedule_next_job ();
            }
        } else if (_active_job_list.count () < hard_maximum_active_job ()) {
            int likely_finished_quickly_count = 0;
            // NOTE : Only counts the first 3 jobs! Then for each
            // one that is likely finished quickly, we can launch another one.
            // When a job finishes another one will "move up" to be one of the first 3 and then
            // be counted too.
            for (int i = 0; i < maximum_active_transfer_job () && i < _active_job_list.count (); i++) {
                if (_active_job_list.at (i).is_likely_finished_quickly ()) {
                    likely_finished_quickly_count++;
                }
            }
            if (_active_job_list.count () < maximum_active_transfer_job () + likely_finished_quickly_count) {
                q_c_debug (lc_propagator) << "Can pump in another request! active_jobs =" << _active_job_list.count ();
                if (_root_job.schedule_self_or_child ()) {
                    schedule_next_job ();
                }
            }
        }
    }

    void Owncloud_propagator.report_progress (SyncFileItem &item, int64 bytes) {
        emit progress (item, bytes);
    }

    AccountPtr Owncloud_propagator.account () {
        return _account;
    }

    Owncloud_propagator.Disk_space_result Owncloud_propagator.disk_space_check () {
        const int64 free_bytes = Utility.free_disk_space (_local_dir);
        if (free_bytes < 0) {
            return Disk_space_ok;
        }

        if (free_bytes < critical_free_space_limit ()) {
            return Disk_space_critical;
        }

        if (free_bytes - _root_job.committed_disk_space () < free_space_limit ()) {
            return Disk_space_failure;
        }

        return Disk_space_ok;
    }

    bool Owncloud_propagator.create_conflict (SyncFileItemPtr &item,
        Propagator_composite_job *composite, string *error) {
        string fn = full_local_path (item._file);

        string rename_error;
        auto conflict_mod_time = FileSystem.get_mod_time (fn);
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

        // Create a new conflict record. To get the base etag, we need to read it from the db.
        Conflict_record conflict_record;
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

    string Owncloud_propagator.adjust_renamed_path (string &original) {
        return Occ.adjust_renamed_path (_renamed_directories, original);
    }

    Result<Vfs.ConvertToPlaceholderResult, string> Owncloud_propagator.update_metadata (SyncFileItem &item) {
        return Owncloud_propagator.static_update_metadata (item, _local_dir, sync_options ()._vfs.data (), _journal);
    }

    Result<Vfs.ConvertToPlaceholderResult, string> Owncloud_propagator.static_update_metadata (SyncFileItem &item, string local_dir,
                                                                                              Vfs *vfs, SyncJournalDb *const journal) {
        const string fs_path = local_dir + item.destination ();
        const auto result = vfs.convert_to_placeholder (fs_path, item);
        if (!result) {
            return result.error ();
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            return Vfs.ConvertToPlaceholderResult.Locked;
        }
        auto record = item.to_sync_journal_file_record_with_inode (fs_path);
        const auto d_bresult = journal.set_file_record (record);
        if (!d_bresult) {
            return d_bresult.error ();
        }
        return Vfs.ConvertToPlaceholderResult.Ok;
    }

    bool Owncloud_propagator.is_delayed_upload_item (SyncFileItemPtr &item) {
        return account ().capabilities ().bulk_upload () && !_schedule_delayed_tasks && !item._is_encrypted && _sync_options._min_chunk_size > item._size && !is_in_bulk_upload_black_list (item._file);
    }

    void Owncloud_propagator.set_schedule_delayed_tasks (bool active) {
        _schedule_delayed_tasks = active;
    }

    void Owncloud_propagator.clear_delayed_tasks () {
        _delayed_tasks.clear ();
    }

    void Owncloud_propagator.add_to_bulk_upload_black_list (string &file) {
        q_c_debug (lc_propagator) << "black list for bulk upload" << file;
        _bulk_upload_black_list.insert (file);
    }

    void Owncloud_propagator.remove_from_bulk_upload_black_list (string &file) {
        q_c_debug (lc_propagator) << "black list for bulk upload" << file;
        _bulk_upload_black_list.remove (file);
    }

    bool Owncloud_propagator.is_in_bulk_upload_black_list (string &file) {
        return _bulk_upload_black_list.contains (file);
    }

    // ================================================================================

    Propagator_job.Propagator_job (Owncloud_propagator *propagator)
        : GLib.Object (propagator)
        , _state (Not_yet_started) {
    }

    Owncloud_propagator *Propagator_job.propagator () {
        return qobject_cast<Owncloud_propagator> (parent ());
    }

    // ================================================================================

    Propagator_job.Job_parallelism Propagator_composite_job.parallelism () {
        // If any of the running sub jobs is not parallel, we have to wait
        for (int i = 0; i < _running_jobs.count (); ++i) {
            if (_running_jobs.at (i).parallelism () != Full_parallelism) {
                return _running_jobs.at (i).parallelism ();
            }
        }
        return Full_parallelism;
    }

    void Propagator_composite_job.slot_sub_job_abort_finished () {
        // Count that job has been finished
        _aborts_count--;

        // Emit abort if last job has been aborted
        if (_aborts_count == 0) {
            emit abort_finished ();
        }
    }

    void Propagator_composite_job.append_job (Propagator_job *job) {
        job.set_associated_composite (this);
        _jobs_to_do.append (job);
    }

    bool Propagator_composite_job.schedule_self_or_child () {
        if (_state == Finished) {
            return false;
        }

        // Start the composite job
        if (_state == Not_yet_started) {
            _state = Running;
        }

        // Ask all the running composite jobs if they have something new to schedule.
        for (auto running_job : q_as_const (_running_jobs)) {
            ASSERT (running_job._state == Running);

            if (possibly_run_next_job (running_job)) {
                return true;
            }

            // If any of the running sub jobs is not parallel, we have to cancel the scheduling
            // of the rest of the list and wait for the blocking job to finish and schedule the next one.
            auto paral = running_job.parallelism ();
            if (paral == Wait_for_finished) {
                return false;
            }
        }

        // Now it's our turn, check if we have something left to do.
        // First, convert a task to a job if necessary
        while (_jobs_to_do.is_empty () && !_tasks_to_do.is_empty ()) {
            SyncFileItemPtr next_task = _tasks_to_do.first ();
            _tasks_to_do.remove (0);
            Propagator_job *job = propagator ().create_job (next_task);
            if (!job) {
                q_c_warning (lc_directory) << "Useless task found for file" << next_task.destination () << "instruction" << next_task._instruction;
                continue;
            }
            append_job (job);
            break;
        }
        // Then run the next job
        if (!_jobs_to_do.is_empty ()) {
            Propagator_job *next_job = _jobs_to_do.first ();
            _jobs_to_do.remove (0);
            _running_jobs.append (next_job);
            return possibly_run_next_job (next_job);
        }

        // If neither us or our children had stuff left to do we could hang. Make sure
        // we mark this job as finished so that the propagator can schedule a new one.
        if (_jobs_to_do.is_empty () && _tasks_to_do.is_empty () && _running_jobs.is_empty ()) {
            // Our parent jobs are already iterating over their running jobs, post to the event loop
            // to avoid removing ourself from that list while they iterate.
            QMetaObject.invoke_method (this, "finalize", Qt.QueuedConnection);
        }
        return false;
    }

    void Propagator_composite_job.slot_sub_job_finished (SyncFileItem.Status status) {
        auto *sub_job = static_cast<Propagator_job> (sender ());
        ASSERT (sub_job);

        // Delete the job and remove it from our list of jobs.
        sub_job.delete_later ();
        int i = _running_jobs.index_of (sub_job);
        ENFORCE (i >= 0); // should only happen if this function is called more than once
        _running_jobs.remove (i);

        // Any sub job error will cause the whole composite to fail. This is important
        // for knowing whether to update the etag in Propagate_directory, for example.
        if (status == SyncFileItem.Fatal_error
            || status == SyncFileItem.Normal_error
            || status == SyncFileItem.Soft_error
            || status == SyncFileItem.Detail_error
            || status == SyncFileItem.Blacklisted_error) {
            _has_error = status;
        }

        if (_jobs_to_do.is_empty () && _tasks_to_do.is_empty () && _running_jobs.is_empty ()) {
            finalize ();
        } else {
            propagator ().schedule_next_job ();
        }
    }

    void Propagator_composite_job.finalize () {
        // The propagator will do parallel scheduling and this could be posted
        // multiple times on the event loop, ignore the duplicate calls.
        if (_state == Finished)
            return;

        _state = Finished;
        emit finished (_has_error == SyncFileItem.No_status ? SyncFileItem.Success : _has_error);
    }

    int64 Propagator_composite_job.committed_disk_space () {
        int64 needed = 0;
        foreach (Propagator_job *job, _running_jobs) {
            needed += job.committed_disk_space ();
        }
        return needed;
    }

    // ================================================================================

    Propagate_directory.Propagate_directory (Owncloud_propagator *propagator, SyncFileItemPtr &item)
        : Propagator_job (propagator)
        , _item (item)
        , _first_job (propagator.create_job (item))
        , _sub_jobs (propagator) {
        if (_first_job) {
            connect (_first_job.data (), &Propagator_job.finished, this, &Propagate_directory.slot_first_job_finished);
            _first_job.set_associated_composite (&_sub_jobs);
        }
        connect (&_sub_jobs, &Propagator_job.finished, this, &Propagate_directory.slot_sub_jobs_finished);
    }

    Propagator_job.Job_parallelism Propagate_directory.parallelism () {
        // If any of the non-finished sub jobs is not parallel, we have to wait
        if (_first_job && _first_job.parallelism () != Full_parallelism) {
            return Wait_for_finished;
        }
        if (_sub_jobs.parallelism () != Full_parallelism) {
            return Wait_for_finished;
        }
        return Full_parallelism;
    }

    bool Propagate_directory.schedule_self_or_child () {
        if (_state == Finished) {
            return false;
        }

        if (_state == Not_yet_started) {
            _state = Running;
        }

        if (_first_job && _first_job._state == Not_yet_started) {
            return _first_job.schedule_self_or_child ();
        }

        if (_first_job && _first_job._state == Running) {
            // Don't schedule any more job until this is done.
            return false;
        }

        return _sub_jobs.schedule_self_or_child ();
    }

    void Propagate_directory.slot_first_job_finished (SyncFileItem.Status status) {
        _first_job.take ().delete_later ();

        if (status != SyncFileItem.Success
            && status != SyncFileItem.Restoration
            && status != SyncFileItem.Conflict) {
            if (_state != Finished) {
                // Synchronously abort
                abort (Abort_type.Synchronous);
                _state = Finished;
                q_c_info (lc_propagator) << "Propagate_directory.slot_first_job_finished" << "emit finished" << status;
                emit finished (status);
            }
            return;
        }

        propagator ().schedule_next_job ();
    }

    void Propagate_directory.slot_sub_jobs_finished (SyncFileItem.Status status) {
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
                    status = _item._status = SyncFileItem.Normal_error;
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
                const auto result = propagator ().update_metadata (*_item);
                if (!result) {
                    status = _item._status = SyncFileItem.Fatal_error;
                    _item._error_string = tr ("Error updating metadata : %1").arg (result.error ());
                    q_c_warning (lc_directory) << "Error writing to the database for file" << _item._file << "with" << result.error ();
                } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
                    _item._status = SyncFileItem.Soft_error;
                    _item._error_string = tr ("File is currently in use");
                }
            }
        }
        _state = Finished;
        q_c_info (lc_propagator) << "Propagate_directory.slot_sub_jobs_finished" << "emit finished" << status;
        emit finished (status);
    }

    Propagate_root_directory.Propagate_root_directory (Owncloud_propagator *propagator)
        : Propagate_directory (propagator, SyncFileItemPtr (new SyncFileItem))
        , _dir_deletion_jobs (propagator) {
        connect (&_dir_deletion_jobs, &Propagator_job.finished, this, &Propagate_root_directory.slot_dir_deletion_jobs_finished);
    }

    Propagator_job.Job_parallelism Propagate_root_directory.parallelism () {
        // the root directory parallelism isn't important
        return Wait_for_finished;
    }

    void Propagate_root_directory.abort (Propagator_job.Abort_type abort_type) {
        if (_first_job)
            // Force first job to abort synchronously
            // even if caller allows async abort (async_abort)
            _first_job.abort (Abort_type.Synchronous);

        if (abort_type == Abort_type.Asynchronous) {
            struct Aborts_finished {
                bool sub_jobs_finished = false;
                bool dir_deletion_finished = false;
            };
            auto abort_status = QSharedPointer<Aborts_finished> (new Aborts_finished);

            connect (&_sub_jobs, &Propagator_composite_job.abort_finished, this, [this, abort_status] () {
                abort_status.sub_jobs_finished = true;
                if (abort_status.sub_jobs_finished && abort_status.dir_deletion_finished)
                    emit abort_finished ();
            });
            connect (&_dir_deletion_jobs, &Propagator_composite_job.abort_finished, this, [this, abort_status] () {
                abort_status.dir_deletion_finished = true;
                if (abort_status.sub_jobs_finished && abort_status.dir_deletion_finished)
                    emit abort_finished ();
            });
        }
        _sub_jobs.abort (abort_type);
        _dir_deletion_jobs.abort (abort_type);
    }

    int64 Propagate_root_directory.committed_disk_space () {
        return _sub_jobs.committed_disk_space () + _dir_deletion_jobs.committed_disk_space ();
    }

    bool Propagate_root_directory.schedule_self_or_child () {
        q_c_info (lc_root_directory ()) << "schedule_self_or_child" << _state << "pending uploads" << propagator ().delayed_tasks ().size () << "subjobs state" << _sub_jobs._state;

        if (_state == Finished) {
            return false;
        }

        if (Propagate_directory.schedule_self_or_child () && propagator ().delayed_tasks ().empty ()) {
            return true;
        }

        // Important : Finish _sub_jobs before scheduling any deletes.
        if (_sub_jobs._state != Finished) {
            return false;
        }

        if (!propagator ().delayed_tasks ().empty ()) {
            return schedule_delayed_jobs ();
        }

        return _dir_deletion_jobs.schedule_self_or_child ();
    }

    void Propagate_root_directory.slot_sub_jobs_finished (SyncFileItem.Status status) {
        q_c_info (lc_root_directory ()) << status << "slot_sub_jobs_finished" << _state << "pending uploads" << propagator ().delayed_tasks ().size () << "subjobs state" << _sub_jobs._state;

        if (!propagator ().delayed_tasks ().empty ()) {
            schedule_delayed_jobs ();
            return;
        }

        if (status != SyncFileItem.Success
            && status != SyncFileItem.Restoration
            && status != SyncFileItem.Conflict) {
            if (_state != Finished) {
                // Synchronously abort
                abort (Abort_type.Synchronous);
                _state = Finished;
                q_c_info (lc_propagator) << "Propagate_root_directory.slot_sub_jobs_finished" << "emit finished" << status;
                emit finished (status);
            }
            return;
        }

        propagator ().schedule_next_job ();
    }

    void Propagate_root_directory.slot_dir_deletion_jobs_finished (SyncFileItem.Status status) {
        _state = Finished;
        q_c_info (lc_propagator) << "Propagate_root_directory.slot_dir_deletion_jobs_finished" << "emit finished" << status;
        emit finished (status);
    }

    bool Propagate_root_directory.schedule_delayed_jobs () {
        q_c_info (lc_propagator) << "Propagate_root_directory.schedule_delayed_jobs";
        propagator ().set_schedule_delayed_tasks (true);
        auto bulk_propagator_job = std.make_unique<Bulk_propagator_job> (propagator (), propagator ().delayed_tasks ());
        propagator ().clear_delayed_tasks ();
        _sub_jobs.append_job (bulk_propagator_job.release ());
        _sub_jobs._state = Running;
        return _sub_jobs.schedule_self_or_child ();
    }

    // ================================================================================

    Cleanup_polls_job.~Cleanup_polls_job () = default;

    void Cleanup_polls_job.start () {
        if (_poll_infos.empty ()) {
            emit finished ();
            delete_later ();
            return;
        }

        auto info = _poll_infos.first ();
        _poll_infos.pop_front ();
        SyncFileItemPtr item (new SyncFileItem);
        item._file = info._file;
        item._modtime = info._modtime;
        item._size = info._file_size;
        auto *job = new Poll_job (_account, info._url, item, _journal, _local_path, this);
        connect (job, &Poll_job.finished_signal, this, &Cleanup_polls_job.slot_poll_finished);
        job.start ();
    }

    void Cleanup_polls_job.slot_poll_finished () {
        auto *job = qobject_cast<Poll_job> (sender ());
        ASSERT (job);
        if (job._item._status == SyncFileItem.Fatal_error) {
            emit aborted (job._item._error_string);
            delete_later ();
            return;
        } else if (job._item._status != SyncFileItem.Success) {
            q_c_warning (lc_cleanup_polls) << "There was an error with file " << job._item._file << job._item._error_string;
        } else {
            if (!Owncloud_propagator.static_update_metadata (*job._item, _local_path, _vfs.data (), _journal)) {
                q_c_warning (lc_cleanup_polls) << "database error";
                job._item._status = SyncFileItem.Fatal_error;
                job._item._error_string = tr ("Error writing metadata to the database");
                emit aborted (job._item._error_string);
                delete_later ();
                return;
            }
            _journal.set_upload_info (job._item._file, SyncJournalDb.UploadInfo ());
        }
        // Continue with the next entry, or finish
        start ();
    }

    string Owncloud_propagator.full_remote_path (string &tmp_file_name) {
        // TODO : should this be part of the _item (SyncFileItemPtr)?
        return _remote_folder + tmp_file_name;
    }

    string Owncloud_propagator.remote_path () {
        return _remote_folder;
    }

    inline QByteArray get_etag_from_reply (QNetworkReply *reply) {
        QByteArray oc_etag = parse_etag (reply.raw_header ("OC-ETag"));
        QByteArray etag = parse_etag (reply.raw_header ("ETag"));
        QByteArray ret = oc_etag;
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
        int http_code, bool *another_sync_needed = nullptr, QByteArray &error_body = QByteArray ()) {
        Q_ASSERT (nerror != QNetworkReply.NoError); // we should only be called when there is an error

        if (nerror == QNetworkReply.Remote_host_closed_error) {
            // Sometimes server bugs lead to a connection close on certain files,
            // that shouldn't bring the rest of the syncing to a halt.
            return SyncFileItem.Normal_error;
        }

        if (nerror > QNetworkReply.NoError && nerror <= QNetworkReply.Unknown_proxy_error) {
            // network error or proxy error . fatal
            return SyncFileItem.Fatal_error;
        }

        if (http_code == 503) {
            // When the server is in maintenance mode, we want to exit the sync immediatly
            // so that we do not flood the server with many requests
            // BUG : This relies on a translated string and is thus unreliable.
            //      In the future it should return a Normal_error and trigger a status.php
            //      check that detects maintenance mode reliably and will terminate the sync run.
            auto probably_maintenance =
                    error_body.contains (R" (>Sabre\DAV\Exception\ServiceUnavailable<)")
                    && !error_body.contains ("Storage is temporarily not available");
            return probably_maintenance ? SyncFileItem.Fatal_error : SyncFileItem.Normal_error;
        }

        if (http_code == 412) {
            // "Precondition Failed"
            // Happens when the e-tag has changed
            return SyncFileItem.Soft_error;
        }

        if (http_code == 423) {
            // "Locked"
            // Should be temporary.
            if (another_sync_needed) {
                *another_sync_needed = true;
            }
            return SyncFileItem.File_locked;
        }

        return SyncFileItem.Normal_error;
    }
    }
    