/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/


//  #include <QLoggingCategory>
using Soup;

//  #include <GLib.List>
//  #include <GLib.FileInfo>
//  #include <QDir>
//  #include <QLoggingCategory>
//  #include <QTimer>
//  #include <QTimerEvent>
//  #include <QRegularExpression>
//  #include <qmath.h>
//  #include <QElapse
//  #include <QTimer>
//  #include <QPointer>
//  #include <QIODevic
//  #include <QMutex>

//  #include <deque>


namespace Occ {
namespace LibSync {

class OwncloudPropagator : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public SyncJournalDb const journal;
    public bool finished_emited; // used to ensure that on_signal_finished is only emitted once


    /***********************************************************
    ***********************************************************/
    public OwncloudPropagator.for_account (unowned Account account, string local_dir,
                       const string remote_folder, SyncJournalDb progress_database,
                       GLib.List<string> bulk_upload_block_list)
        : this.journal (progress_database)
        this.finished_emited (false)
        this.bandwidth_manager (this)
        this.another_sync_needed (false)
        this.chunk_size (10 * 1000 * 1000) // 10 MB, overridden in sync_options
        this.account (account)
        this.local_dir ( (local_dir.has_suffix (char ('/'))) ? local_dir : local_dir + '/')
        this.remote_folder ( (remote_folder.has_suffix (char ('/'))) ? remote_folder : remote_folder + '/')
        this.bulk_upload_block_list (bulk_upload_block_list) {
        q_register_meta_type<PropagatorJob.AbortType> ("PropagatorJob.AbortType");
    }

    ~OwncloudPropagator ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_start (SyncFileItemVector &&this.synced_items);

    /***********************************************************
    ***********************************************************/
    public void start_directory_propagation (SyncFileItemPtr item,
                                   GLib.List<QPair<string, PropagateDirectory>> directories, // should be a LIFO stack
                                   GLib.List<PropagatorJob> directories_to_remove,
                                   string removed_directory,
                                   const SyncFileItemVector items);

    /***********************************************************
    ***********************************************************/
    public void start_file_propagation (SyncFileItemPtr item,
                              GLib.List<QPair<string, PropagateDirectory>> directories, // should be a LIFO stack
                              GLib.List<PropagatorJob> directories_to_remove,
                              string removed_directory,
                              string maybe_conflict_directory);

    /***********************************************************
    ***********************************************************/
    public const SyncOptions sync_options ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public int download_limit = 0;
    public int upload_limit = 0;
    public BandwidthManager bandwidth_manager;

    /***********************************************************
    ***********************************************************/
    public bool abort_requested = false;


    /***********************************************************
    The list of currently active jobs.
        This list contains the jobs that are currently using ressources and is used purely to
        know how many jobs there is currently running for the scheduler.
        Jobs add themself to the list when they do an assynchronous operation.
        Jobs can be several time on the list (example, when several chunks are uploaded in parallel)
    ***********************************************************/
    public GLib.List<PropagateItemJob> active_job_list;


    /***********************************************************
    We detected that another sync is required after this one
    ***********************************************************/
    public bool another_sync_needed;


    /***********************************************************
    Per-folder quota guesses.

    This starts out empty. When an upload in a folder fails due to insufficent
    remote quota, the quota guess is updated to be attempted_size-1 at maximum.

    Note that it will usually just an upper limit for the actual quota - but
    since the quota on the server might ch
    wrong in the other direction as well.

    This allows skipping of uploads that have a very high likelihood of failure.
    ***********************************************************/
    public GLib.HashTable<string, int64> folder_quota;

    
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
    public int64 chunk_size;
    public int64 small_file_size ();


    /***********************************************************
    The maximum number of active jobs in parallel
    ***********************************************************/
    public int hard_maximum_active_job ();


    /***********************************************************
    Check whether a download would clash with an existing file
    in filesystems that are only case-preserving.
    ***********************************************************/
    public bool local_filename_clash (string relfile);


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
    public string full_local_path (string tmp_filename);


    /***********************************************************
    ***********************************************************/
    public string local_path ();


    /***********************************************************
    Returns the full remote path including the folder root of a
    folder sync path.
    ***********************************************************/
    //  Q_REQUIRED_RESULT
    public string full_remote_path (string tmp_filename);


    /***********************************************************
    ***********************************************************/
    public string remote_path ();


    /***********************************************************
    Creates the job for an item.
    ***********************************************************/
    public PropagateItemJob create_job (SyncFileItemPtr item);

    /***********************************************************
    ***********************************************************/
    public void schedule_next_job ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () {
        if (this.abort_requested)
            return;
        if (this.root_job) {
            // Connect to abort_finished  which signals that on_signal_abort has been asynchronously on_signal_finished
            connect (this.root_job.data (), PropagateDirectory.abort_finished, this, OwncloudPropagator.emit_finished);

            // Use Queued Connection because we're possibly already in an item's on_signal_finished stack
            QMetaObject.invoke_method (this.root_job.data (), "on_signal_abort", Qt.QueuedConnection,
                                      Q_ARG (PropagatorJob.AbortType, PropagatorJob.AbortType.ASYNCHRONOUS));

            // Give asynchronous on_signal_abort 5000 msec to finish on its own
            QTimer.single_shot (5000, this, SLOT (abort_timeout ()));
        } else {
            // No root job, call emit_finished
            emit_finished (SyncFileItem.Status.NORMAL_ERROR);
        }
    }


    /***********************************************************
    ***********************************************************/
    //  private unowned Account account;
    /***********************************************************
    ***********************************************************/
    public unowned Account account ();

    /***********************************************************
    ***********************************************************/
    public enum DiskSpaceResult {
        DiskSpaceOk,
        DiskSpaceFailure,
        DiskSpaceCritical
    }


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

    Returns true on on_signal_success, false and error on error.
    ***********************************************************/
    public bool create_conflict (SyncFileItemPtr item,
        PropagatorCompositeJob composite, string error);

    // Map original path (as in the DB) to target final path
    public GLib.HashTable<string, string> renamed_directories;
    public string adjust_renamed_path (string original);


    /***********************************************************
    Update the database for an item.

    Typically after a sync operation succeeded. Updates the inode from
    the filesystem.

    Will also trigger a Vfs.convert_to_placeholder.
    ***********************************************************/
    public Result<Vfs.ConvertToPlaceholderResult, string> update_metadata (SyncFileItem item);


    /***********************************************************
    Update the database for an item.

    Typically after a sync operation succeeded. Updates the inode from
    the filesystem.

    Will also trigger a Vfs.convert_to_placeholder.
    ***********************************************************/
    public static Result<Vfs.ConvertToPlaceholderResult, string> static_update_metadata (SyncFileItem item, string local_dir,
                                                                                 Vfs vfs, SyncJournalDb * const journal);

    //  Q_REQUIRED_RESULT
    public bool is_delayed_upload_item (SyncFileItemPtr item);

    //  Q_REQUIRED_RESULT
    public const GLib.Deque<SyncFileItemPtr>& delayed_tasks () {
        return this.delayed_tasks;
    }


    /***********************************************************
    ***********************************************************/
    public void schedule_delayed_tasks (bool active);

    /***********************************************************
    ***********************************************************/
    public void clear_delayed_tasks ();

    /***********************************************************
    ***********************************************************/
    public void add_to_bulk_upload_block_list (string file);

    /***********************************************************
    ***********************************************************/
    public void remove_from_bulk_upload_block_list (string file);

    /***********************************************************
    ***********************************************************/
    public bool is_in_bulk_upload_block_list (string file);


    /***********************************************************
    ***********************************************************/
    private on_ void abort_timeout () {
        // Abort synchronously and finish
        this.root_job.data ().on_signal_abort (PropagatorJob.AbortType.SYNCHRONOUS);
        emit_finished (SyncFileItem.Status.NORMAL_ERROR);
    }


    /***********************************************************
    Emit the on_signal_finished signal and make sure it is only emitted once
    ***********************************************************/
    private on_ void emit_finished (SyncFileItem.Status status) {
        if (!this.finished_emited)
            /* emit */ finished (status == SyncFileItem.Status.SUCCESS);
        this.finished_emited = true;
    }


    /***********************************************************
    ***********************************************************/
    private on_ void schedule_next_job_impl ();

    signal void new_item (SyncFileItemPtr &);
    signal void item_completed (SyncFileItemPtr &);
    signal void progress (SyncFileItem &, int64 bytes);
    signal void on_signal_finished (bool on_signal_success);


    /***********************************************************
    Emitted when propagation touches a file.

    Used to track our own file modifications such that notifications
    from the file watcher about these can be ignored.
    ***********************************************************/
    void touched_file (string filename);

    void insufficient_local_storage ();
    void insufficient_remote_storage ();


    /***********************************************************
    ***********************************************************/
    private std.unique_ptr<PropagateUploadFileCommon> create_upload_job (SyncFileItemPtr item,

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 

    private QScopedPointer<PropagateRootDirectory> root_job;
    private SyncOptions sync_options;
    private bool job_scheduled = false;

    /***********************************************************
    ***********************************************************/
    private const string local_dir; // absolute path to the local directory. ends with '/'

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private bool schedule_delayed_tasks = false;

    /***********************************************************
    ***********************************************************/
    private GLib.List<string> bulk_upload_block_list;

    /***********************************************************
    ***********************************************************/
    private static bool allow_delayed_upload;
}


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
        if (this.download_limit != 0
            || this.upload_limit != 0
            || !this.sync_options.parallel_network_jobs) {
            // disable parallelism when there is a network limit.
            return 1;
        }
        return q_min (3, q_ceil (this.sync_options.parallel_network_jobs / 2.));
    }


    /***********************************************************
    The maximum number of active jobs in parallel
    ***********************************************************/
    int OwncloudPropagator.hard_maximum_active_job () {
        if (!this.sync_options.parallel_network_jobs)
            return 1;
        return this.sync_options.parallel_network_jobs;
    }


    /***********************************************************
    ***********************************************************/
    static int64 get_min_blocklist_time () {
        return q_max (q_environment_variable_int_value ("OWNCLOUD_BLOCKLIST_TIME_MIN"),
            25); // 25 seconds
    }


    /***********************************************************
    ***********************************************************/
    static int64 get_max_blocklist_time () {
        int v = q_environment_variable_int_value ("OWNCLOUD_BLOCKLIST_TIME_MAX");
        if (v > 0)
            return v;
        return 24 * 60 * 60; // 1 day
    }


    /***********************************************************
    Creates a blocklist entry, possibly taking into account an old one.

    The old entry may be invalid, then a fresh entry is created.
    ***********************************************************/
    static SyncJournalErrorBlocklistRecord create_blocklist_entry (
        const SyncJournalErrorBlocklistRecord old, SyncFileItem item) {
        SyncJournalErrorBlocklistRecord entry;
        entry.file = item.file;
        entry.error_string = item.error_string;
        entry.last_try_modtime = item.modtime;
        entry.last_try_etag = item.etag;
        entry.last_try_time = Utility.q_date_time_to_time_t (GLib.DateTime.current_date_time_utc ());
        entry.rename_target = item.rename_target;
        entry.retry_count = old.retry_count + 1;
        entry.request_id = item.request_id;

        static int64 min_blocklist_time (get_min_blocklist_time ());
        static int64 max_blocklist_time (q_max (get_max_blocklist_time (), min_blocklist_time));

        // The factor of 5 feels natural : 25s, 2 min, 10 min, ~1h, ~5h, ~24h
        entry.ignore_duration = old.ignore_duration * 5;

        if (item.http_error_code == 403) {
            GLib.warning ("Probably firewall error: " + item.http_error_code + ", blocklisting up to 1h only";
            entry.ignore_duration = q_min (entry.ignore_duration, int64 (60 * 60));

        } else if (item.http_error_code == 413 || item.http_error_code == 415) {
            GLib.warning ("Fatal Error condition" + item.http_error_code + ", maximum blocklist ignore time!";
            entry.ignore_duration = max_blocklist_time;
        }

        entry.ignore_duration = q_bound (min_blocklist_time, entry.ignore_duration, max_blocklist_time);

        if (item.status == SyncFileItem.Status.SOFT_ERROR) {
            // Track these errors, but don't actively suppress them.
            entry.ignore_duration = 0;
        }

        if (item.http_error_code == 507) {
            entry.error_category = SyncJournalErrorBlocklistRecord.INSUFFICIENT_REMOTE_STORAGE;
        }

        return entry;
    }


    /***********************************************************
    Updates, creates or removes a blocklist entry for the given item.

    May adjust the status or item.error_string.
    ***********************************************************/
    void blocklist_update (SyncJournalDb journal, SyncFileItem item) {
        SyncJournalErrorBlocklistRecord old_entry = journal.error_blocklist_entry (item.file);

        bool may_blocklist =
            item.error_may_be_blocklisted // explicitly flagged for blocklisting
            || ( (item.status == SyncFileItem.Status.NORMAL_ERROR
                    || item.status == SyncFileItem.Status.SOFT_ERROR
                    || item.status == SyncFileItem.Status.DETAIL_ERROR)
                   && item.http_error_code != 0 // or non-local error
                   );

        // No new entry? Possibly remove the old one, then done.
        if (!may_blocklist) {
            if (old_entry.is_valid ()) {
                journal.wipe_error_blocklist_entry (item.file);
            }
            return;
        }

        var new_entry = create_blocklist_entry (old_entry, item);
        journal.error_blocklist_entry (new_entry);

        // Suppress the error if it was and continues to be blocklisted.
        // An ignore_duration of 0 mean we're tracking the error, but not actively
        // suppressing it.
        if (item.has_blocklist_entry && new_entry.ignore_duration > 0) {
            item.status = SyncFileItem.Status.BLOCKLISTED_ERROR;

            GLib.info ("blocklisting " + item.file
                                 + " for " + new_entry.ignore_duration
                                 + ", retry count " + new_entry.retry_count;

            return;
        }

        // Some soft errors might become louder on repeat occurrence
        if (item.status == SyncFileItem.Status.SOFT_ERROR
            && new_entry.retry_count > 1) {
            GLib.warning ("escalating soft error on " + item.file
                                    + " to normal error, " + item.http_error_code;
            item.status = SyncFileItem.Status.NORMAL_ERROR;
            return;
        }
    }

    // ================================================================================

    PropagateItemJob *OwncloudPropagator.create_job (SyncFileItemPtr item) {
        bool delete_existing = item.instruction == CSYNC_INSTRUCTION_TYPE_CHANGE;
        switch (item.instruction) {
        case CSYNC_INSTRUCTION_REMOVE:
            if (item.direction == SyncFileItem.Direction.DOWN)
                return new PropagateLocalRemove (this, item);
            else
                return new PropagateRemoteDelete (this, item);
        case CSYNC_INSTRUCTION_NEW:
        case CSYNC_INSTRUCTION_TYPE_CHANGE:
        case CSYNC_INSTRUCTION_CONFLICT:
            if (item.is_directory ()) {
                // CONFLICT has this.direction == None
                if (item.direction != SyncFileItem.Direction.UP) {
                    var job = new PropagateLocalMkdir (this, item);
                    job.delete_existing_file (delete_existing);
                    return job;
                } else {
                    var job = new PropagateRemoteMkdir (this, item);
                    job.delete_existing (delete_existing);
                    return job;
                }
            } //fall through
        case CSYNC_INSTRUCTION_SYNC:
            if (item.direction != SyncFileItem.Direction.UP) {
                var job = new PropagateDownloadFile (this, item);
                job.delete_existing_folder (delete_existing);
                return job;
            } else {
                if (delete_existing || !is_delayed_upload_item (item)) {
                    var job = create_upload_job (item, delete_existing);
                    return job.release ();
                } else {
                    push_delayed_upload_task (item);
                    return null;
                }
            }
        case CSYNC_INSTRUCTION_RENAME:
            if (item.direction == SyncFileItem.Direction.UP) {
                return new PropagateRemoteMove (this, item);
            } else {
                return new PropagateLocalRename (this, item);
            }
        case CSYNC_INSTRUCTION_IGNORE:
        case CSYNC_INSTRUCTION_ERROR:
            return new PropagateIgnoreJob (this, item);
        default:
            return null;
        }
        return null;
    }

    std.unique_ptr<PropagateUploadFileCommon> OwncloudPropagator.create_upload_job (SyncFileItemPtr item, bool delete_existing) {
        var job = std.unique_ptr<PropagateUploadFileCommon>{};

        if (item.size > sync_options ().initial_chunk_size && account ().capabilities ().chunking_ng ()) {
            // Item is above this.initial_chunk_size, thus will be classified as to be chunked
            job = std.make_unique<PropagateUploadFileNG> (this, item);
        } else {
            job = std.make_unique<PropagateUploadFileV1> (this, item);
        }

        job.delete_existing (delete_existing);

        remove_from_bulk_upload_block_list (item.file);

        return job;
    }

    void OwncloudPropagator.push_delayed_upload_task (SyncFileItemPtr item) {
        this.delayed_tasks.push_back (item);
    }

    void OwncloudPropagator.reset_delayed_upload_tasks () {
        this.schedule_delayed_tasks = false;
        this.delayed_tasks.clear ();
    }

    int64 OwncloudPropagator.small_file_size () {
        const int64 small_file_size = 100 * 1024; //default to 1 MB. Not dynamic right now.
        return small_file_size;
    }

    void OwncloudPropagator.on_signal_start (SyncFileItemVector &&items) {
        //  Q_ASSERT (std.is_sorted (items.begin (), items.end ()));

        // This builds all the jobs needed for the propagation.
        // Each directory is a PropagateDirectory job, which contains the files in it.
        // In order to do that we loop over the items. (which are sorted by destination)
        // When we enter a directory, we can create the directory job and push it on the stack.

        var regex = sync_options ().file_regex ();
        if (regex.is_valid ()) {
            GLib.List<QStringRef> names;
            foreach (var i in items) {
                if (regex.match (i.file).has_match ()) {
                    int index = -1;
                    QStringRef ref;
                    do {
                        ref = i.file.mid_ref (0, index);
                        names.insert (ref);
                        index = ref.last_index_of ('/');
                    } while (index > 0);
                }
            }
            items.erase (std.remove_if (items.begin (), items.end (), [&names] (var i) {
                return !names.contains (QStringRef {
                    i.file
                });
            }),
            items.end ());
        }

        reset_delayed_upload_tasks ();
        this.root_job.on_signal_reset (new PropagateRootDirectory (this));
        GLib.List<QPair<string /* directory name */, PropagateDirectory /* job */>> directories; // should be a LIFO stack
        directories.push (q_make_pair ("", this.root_job.data ()));
        GLib.List<PropagatorJob> directories_to_remove;
        string removed_directory;
        string maybe_conflict_directory;
        foreach (SyncFileItemPtr item in items) {
            if (!removed_directory.is_empty () && item.file.starts_with (removed_directory)) {
                // this is an item in a directory which is going to be removed.
                var del_dir_job = qobject_cast<PropagateDirectory> (directories_to_remove.first ());

                var is_new_directory = item.is_directory () &&
                        (item.instruction == CSYNC_INSTRUCTION_NEW || item.instruction == CSYNC_INSTRUCTION_TYPE_CHANGE);

                if (item.instruction == CSYNC_INSTRUCTION_REMOVE || is_new_directory) {
                    // If it is a remove it is already taken care of by the removal of the parent directory

                    // If it is a new directory then it is inside a deleted directory... That can happen if
                    // the directory etag was not fetched properly on the previous sync because the sync was
                    // aborted while uploading this directory (which is now removed).  We can ignore it.

                    // increase the number of subjobs that would be there.
                    if (del_dir_job) {
                        del_dir_job.increase_affected_count ();
                    }
                    continue;
                } else if (item.instruction == CSYNC_INSTRUCTION_IGNORE) {
                    continue;
                } else if (item.instruction == CSYNC_INSTRUCTION_RENAME) {
                    // all is good, the rename will be executed before the directory deletion
                } else {
                    GLib.warning ("WARNING :  Job within a removed directory?  This should not happen!"
                                            + item.file + item.instruction;
                }
            }

            // If a CONFLICT item contains files these can't be processed because
            // the conflict handling is likely to rename the directory. This can happen
            // when there's a new local directory at the same time as a remote file.
            if (!maybe_conflict_directory.is_empty ()) {
                if (item.destination ().starts_with (maybe_conflict_directory)) {
                    GLib.info ("Skipping job inside CONFLICT directory"
                                         + item.file + item.instruction;
                    item.instruction = CSYNC_INSTRUCTION_NONE;
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

        foreach (PropagatorJob it in directories_to_remove) {
            this.root_job.dir_deletion_jobs.append_job (it);
        }

        connect (this.root_job.data (), PropagatorJob.on_signal_finished, this, OwncloudPropagator.emit_finished);

        this.job_scheduled = false;
        schedule_next_job ();
    }

    void OwncloudPropagator.start_directory_propagation (SyncFileItemPtr item,
                                                       GLib.List<QPair<string, PropagateDirectory>> directories, // should be a LIFO stack
                                                       GLib.List<PropagatorJob> directories_to_remove,
                                                       string removed_directory,
                                                       const SyncFileItemVector items) {
        var directory_propagation_job = std.make_unique<PropagateDirectory> (this, item);

        if (item.instruction == CSYNC_INSTRUCTION_TYPE_CHANGE
            && item.direction == SyncFileItem.Direction.UP) {
            // Skip all potential uploads to the new folder.
            // Processing them now leads to problems with permissions:
            // check_for_permissions () has already run and used the permissions
            // of the file we're about to delete to decide whether uploading
            // to the new directory is ok...
            foreach (SyncFileItemPtr dir_item in items) {
                if (dir_item.destination ().starts_with (item.destination () + "/")) {
                    dir_item.instruction = CSYNC_INSTRUCTION_NONE;
                    this.another_sync_needed = true;
                }
            }
        }

        if (item.instruction == CSYNC_INSTRUCTION_REMOVE) {
            // We do the removal of directories at the end, because there might be moves from
            // these directories that will happen later.
            directories_to_remove.prepend (directory_propagation_job);
            removed_directory = item.file + "/";

            // We should not update the etag of parent directories of the removed directory
            // since it would be done before the actual remove (issue #1845)
            // Note: Currently this means that we don't update those etag at all in this sync,
            //       but it should not be a problem, they will be updated in the next sync.
            for (int i = 0; i < directories.size (); ++i) {
                if (directories[i].second.item.instruction == CSYNC_INSTRUCTION_UPDATE_METADATA) {
                    directories[i].second.item.instruction = CSYNC_INSTRUCTION_NONE;
                }
            }
        } else {
            var current_dir_job = directories.top ().second;
            current_dir_job.append_job (directory_propagation_job);
        }
        directories.push (q_make_pair (item.destination () + "/", directory_propagation_job.release ()));
    }

    void OwncloudPropagator.start_file_propagation (SyncFileItemPtr item,
                                                  GLib.List<QPair<string, PropagateDirectory> > directories, // should be a LIFO stack
                                                  GLib.List<PropagatorJob> directories_to_remove,
                                                  string removed_directory,
                                                  string maybe_conflict_directory) {
        if (item.instruction == CSYNC_INSTRUCTION_TYPE_CHANGE) {
            // will delete directories, so defer execution
            var job = create_job (item);
            if (job) {
                directories_to_remove.prepend (job);
            }
            removed_directory = item.file + "/";
        } else {
            directories.top ().second.append_task (item);
        }

        if (item.instruction == CSYNC_INSTRUCTION_CONFLICT) {
            // This might be a file or a directory on the local side. If it's a
            // directory we want to skip processing items inside it.
            maybe_conflict_directory = item.file + "/";
        }
    }

    const SyncOptions &OwncloudPropagator.sync_options () {
        return this.sync_options;
    }

    void OwncloudPropagator.sync_options (SyncOptions sync_options) {
        this.sync_options = sync_options;
        this.chunk_size = sync_options.initial_chunk_size;
    }

    bool OwncloudPropagator.local_filename_clash (string rel_file) {
        const string file (this.local_dir + rel_file);
        //  Q_ASSERT (!file.is_empty ());

        if (!file.is_empty () && Utility.fs_case_preserving ()) {
            GLib.debug ("CaseClashCheck for " + file;
            // On Linux, the file system is case sensitive, but this code is useful for testing.
            // Just check that there is no other file with the same name and different casing.
            GLib.FileInfo file_info = new GLib.FileInfo (file);
            const string fn = file_info.filename ();
            const string[] list = file_info.directory ().entry_list ({
                fn
            });
            if (list.count () > 1 || (list.count () == 1 && list[0] != fn)) {
                return true;
            }
        }
        return false;
    }

    bool OwncloudPropagator.has_case_clash_accessibility_problem (string relfile) {
        //  Q_UNUSED (relfile);
        return false;
    }

    string OwncloudPropagator.full_local_path (string tmp_filename) {
        return this.local_dir + tmp_filename;
    }

    string OwncloudPropagator.local_path () {
        return this.local_dir;
    }

    void OwncloudPropagator.schedule_next_job () {
        if (this.job_scheduled) return; // don't schedule more than 1
        this.job_scheduled = true;
        QTimer.single_shot (3, this, OwncloudPropagator.schedule_next_job_impl);
    }

    void OwncloudPropagator.schedule_next_job_impl () {
        // TODO : If we see that the automatic up-scaling has a bad impact we
        // need to check how to avoid this.
        // Down-scaling on slow networks? https://github.com/owncloud/client/issues/3382
        // Making sure we do up/down at same time? https://github.com/owncloud/client/issues/1633

        this.job_scheduled = false;

        if (this.active_job_list.count () < maximum_active_transfer_job ()) {
            if (this.root_job.on_signal_schedule_self_or_child ()) {
                schedule_next_job ();
            }
        } else if (this.active_job_list.count () < hard_maximum_active_job ()) {
            int likely_finished_quickly_count = 0;
            // Note: Only counts the first 3 jobs! Then for each
            // one that is likely on_signal_finished quickly, we can launch another one.
            // When a job finishes another one will "move up" to be one of the first 3 and then
            // be counted too.
            for (int i = 0; i < maximum_active_transfer_job () && i < this.active_job_list.count (); i++) {
                if (this.active_job_list.at (i).is_likely_finished_quickly ()) {
                    likely_finished_quickly_count++;
                }
            }
            if (this.active_job_list.count () < maximum_active_transfer_job () + likely_finished_quickly_count) {
                GLib.debug ("Can pump in another request! active_jobs =" + this.active_job_list.count ();
                if (this.root_job.on_signal_schedule_self_or_child ()) {
                    schedule_next_job ();
                }
            }
        }
    }

    void OwncloudPropagator.report_progress (SyncFileItem item, int64 bytes) {
        /* emit */ progress (item, bytes);
    }

    unowned Account OwncloudPropagator.account () {
        return this.account;
    }

    OwncloudPropagator.DiskSpaceResult OwncloudPropagator.disk_space_check () {
        const int64 free_bytes = Utility.free_disk_space (this.local_dir);
        if (free_bytes < 0) {
            return DiskSpaceOk;
        }

        if (free_bytes < critical_free_space_limit ()) {
            return DiskSpaceCritical;
        }

        if (free_bytes - this.root_job.committed_disk_space () < free_space_limit ()) {
            return DiskSpaceFailure;
        }

        return DiskSpaceOk;
    }

    bool OwncloudPropagator.create_conflict (SyncFileItemPtr item,
        PropagatorCompositeJob composite, string error) {
        string fn = full_local_path (item.file);

        string rename_error;
        var conflict_mod_time = FileSystem.get_mod_time (fn);
        if (conflict_mod_time <= 0) {
            *error = _("Impossible to get modification time for file in conflict %1").arg (fn);
            return false;
        }
        string conflict_user_name;
        if (account ().capabilities ().upload_conflict_files ())
            conflict_user_name = account ().display_name;
        string conflict_filename = Utility.make_conflict_filename (
            item.file, Utility.q_date_time_from_time_t (conflict_mod_time), conflict_user_name);
        string conflict_file_path = full_local_path (conflict_filename);

        /* emit */ touched_file (fn);
        /* emit */ touched_file (conflict_file_path);

        if (!FileSystem.rename (fn, conflict_file_path, rename_error)) {
            // If the rename fails, don't replace it.
            if (error)
                *error = rename_error;
            return false;
        }
        GLib.info ("Created conflict file" + fn + "." + conflict_filename;

        // Create a new conflict record. To get the base etag, we need to read it from the database.
        ConflictRecord conflict_record;
        conflict_record.path = conflict_filename.to_utf8 ();
        conflict_record.base_modtime = item.previous_modtime;
        conflict_record.initial_base_path = item.file.to_utf8 ();

        SyncJournalFileRecord base_record;
        if (this.journal.get_file_record (item.original_file, base_record) && base_record.is_valid ()) {
            conflict_record.base_etag = base_record.etag;
            conflict_record.base_file_id = base_record.file_id;
        } else {
            // We might very well end up with no fileid/etag for new/new conflicts
        }

        this.journal.conflict_record (conflict_record);

        // Create a new upload job if the new conflict file should be uploaded
        if (account ().capabilities ().upload_conflict_files ()) {
            if (composite && !GLib.FileInfo (conflict_file_path).is_dir ()) {
                SyncFileItemPtr conflict_item = SyncFileItemPtr (new SyncFileItem);
                conflict_item.file = conflict_filename;
                conflict_item.type = ItemTypeFile;
                conflict_item.direction = SyncFileItem.Direction.UP;
                conflict_item.instruction = CSYNC_INSTRUCTION_NEW;
                conflict_item.modtime = conflict_mod_time;
                conflict_item.size = item.previous_size;
                /* emit */ new_item (conflict_item);
                composite.append_task (conflict_item);
            }
        }

        // Need a new sync to detect the created copy of the conflicting file
        this.another_sync_needed = true;

        return true;
    }

    string OwncloudPropagator.adjust_renamed_path (string original) {
        return Occ.adjust_renamed_path (this.renamed_directories, original);
    }

    Result<Vfs.ConvertToPlaceholderResult, string> OwncloudPropagator.update_metadata (SyncFileItem item) {
        return OwncloudPropagator.static_update_metadata (item, this.local_dir, sync_options ().vfs.data (), this.journal);
    }

    Result<Vfs.ConvertToPlaceholderResult, string> OwncloudPropagator.static_update_metadata (SyncFileItem item, string local_dir,
                                                                                              Vfs vfs, SyncJournalDb const journal) {
        const string fs_path = local_dir + item.destination ();
        var result = vfs.convert_to_placeholder (fs_path, item);
        if (!result) {
            return result.error ();
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            return Vfs.ConvertToPlaceholderResult.Locked;
        }
        var record = item.to_sync_journal_file_record_with_inode (fs_path);
        var d_bresult = journal.file_record (record);
        if (!d_bresult) {
            return d_bresult.error ();
        }
        return Vfs.ConvertToPlaceholderResult.Ok;
    }

    bool OwncloudPropagator.is_delayed_upload_item (SyncFileItemPtr item) {
        return account ().capabilities ().bulk_upload () && !this.schedule_delayed_tasks && !item.is_encrypted && this.sync_options.min_chunk_size > item.size && !is_in_bulk_upload_block_list (item.file);
    }

    void OwncloudPropagator.schedule_delayed_tasks (bool active) {
        this.schedule_delayed_tasks = active;
    }

    void OwncloudPropagator.clear_delayed_tasks () {
        this.delayed_tasks.clear ();
    }

    void OwncloudPropagator.add_to_bulk_upload_block_list (string file) {
        GLib.debug ("block list for bulk upload" + file;
        this.bulk_upload_block_list.insert (file);
    }

    void OwncloudPropagator.remove_from_bulk_upload_block_list (string file) {
        GLib.debug ("block list for bulk upload" + file;
        this.bulk_upload_block_list.remove (file);
    }

    bool OwncloudPropagator.is_in_bulk_upload_block_list (string file) {
        return this.bulk_upload_block_list.contains (file);
    }


    string OwncloudPropagator.full_remote_path (string tmp_filename) {
        // TODO : should this be part of the this.item (SyncFileItemPtr)?
        return this.remote_folder + tmp_filename;
    }

    string OwncloudPropagator.remote_path () {
        return this.remote_folder;
    }

    inline GLib.ByteArray get_etag_from_reply (Soup.Reply reply) {
        GLib.ByteArray oc_etag = parse_etag (reply.raw_header ("OC-ETag"));
        GLib.ByteArray etag = parse_etag (reply.raw_header ("ETag"));
        GLib.ByteArray ret = oc_etag;
        if (ret.is_empty ()) {
            ret = etag;
        }
        if (oc_etag.length () > 0 && oc_etag != etag) {
            GLib.debug ("Quite peculiar, we have an etag != OC-Etag [no problem!]" + etag + oc_etag;
        }
        return ret;
    }


    /***********************************************************
    Given an error from the network, map to a SyncFileItem.Status error
    ***********************************************************/
    inline SyncFileItem.Status classify_error (Soup.Reply.NetworkError nerror,
        int http_code, bool another_sync_needed = null, GLib.ByteArray error_body = new GLib.ByteArray ()) {
        //  Q_ASSERT (nerror != Soup.Reply.NoError); // we should only be called when there is an error

        if (nerror == Soup.Reply.RemoteHostClosedError) {
            // Sometimes server bugs lead to a connection close on certain files,
            // that shouldn't bring the rest of the syncing to a halt.
            return SyncFileItem.Status.NORMAL_ERROR;
        }

        if (nerror > Soup.Reply.NoError && nerror <= Soup.Reply.UnknownProxyError) {
            // network error or proxy error . fatal
            return SyncFileItem.Status.FATAL_ERROR;
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
            return probably_maintenance ? SyncFileItem.Status.FATAL_ERROR : SyncFileItem.Status.NORMAL_ERROR;
        }

        if (http_code == 412) {
            // "Precondition Failed"
            // Happens when the e-tag has changed
            return SyncFileItem.Status.SOFT_ERROR;
        }

        if (http_code == 423) {
            // "Locked"
            // Should be temporary.
            if (another_sync_needed) {
                *another_sync_needed = true;
            }
            return SyncFileItem.Status.FILE_LOCKED;
        }

        return SyncFileItem.Status.NORMAL_ERROR;
    }
    }
    
















/***********************************************************
We do not want to upload files that are currently being modified.
To avoid that, we don't upload files that have a modification time
that is too close to the current time.

This interacts with the ms_between_request_and_sync delay in the fol
manager. If that delay between file-change notification and sync
has passed, we should accept the file for upload here.
***********************************************************/
inline bool file_is_still_changing (Occ.SyncFileItem item) {
    var modtime = Occ.Utility.q_date_time_from_time_t (item.modtime);
    const int64 ms_since_mod = modtime.msecs_to (GLib.DateTime.current_date_time_utc ());

    return std.chrono.milliseconds (ms_since_mod) < Occ.SyncEngine.minimum_file_age_for_upload
        // if the mtime is too much in the future we do* upload the file
        && ms_since_mod > -10000;
}

/***********************************************************
Free disk space threshold below which syncs will on_signal_abort and not even on_signal_start.
***********************************************************/
int64 critical_free_space_limit ();

/***********************************************************
The client will not intentionally reduce the available free disk space below
 this limit.

Uploads will still run and downloads that are small enough will continue too.
***********************************************************/
int64 free_space_limit ();

void blocklist_update (SyncJournalDb journal, SyncFileItem item);