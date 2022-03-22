/***********************************************************
@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/


using Soup;

//  #include <GLib.List>
//  #include <GLib.FileInfo>
//  #include <GLib.Dir>
//  #include <QTimerEvent>
//  #include <GLib.Regex>
//  #include <qmath.h>
//  #include <QElapse
//  #include <QPointer>
//  #include <QIODevic
//  #include <QMutex>

//  #include <deque>


namespace Occ {
namespace LibSync {

public class OwncloudPropagator : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum DiskSpaceResult {
        DiskSpaceOk,
        DiskSpaceFailure,
        DiskSpaceCritical
    }

    /***********************************************************
    const?
    ***********************************************************/
    public SyncJournalDb journal;

    /***********************************************************
    Used to ensure that on_signal_finished is only emitted once
    ***********************************************************/
    public bool finished_emited;
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
    public GLib.HashTable<string, int64?> folder_quota;


    /***********************************************************
    The size to use for upload chunks.

    Will be dynamically adjusted after each chunk upload finishes
    if Capabilities.desired_chunk_upload_duration has a target
    chunk-upload duration set.
    ***********************************************************/
    public int64 chunk_size;

    /***********************************************************
    Map original path (as in the DB) to target final path
    ***********************************************************/
    public GLib.HashTable<string, string> renamed_directories;


    /***********************************************************
    ***********************************************************/
    private PropagateRootDirectory propagate_root_directory_job;

    public SyncOptions sync_options {
        public get {
            return this.sync_options;
        }
        public set {
            this.sync_options = sync_options;
            this.chunk_size = sync_options.initial_chunk_size;
        }
    }

    private bool job_scheduled = false;

    /***********************************************************
    Absolute path to the local directory. ends with "/"
    ***********************************************************/
    private const string local_dir;

    /***********************************************************
    ***********************************************************/
    bool schedule_delayed_tasks { private get; public set; }

    /***********************************************************
    ***********************************************************/
    private GLib.List<string> bulk_upload_block_list;

    /***********************************************************
    ***********************************************************/
    private static bool allow_delayed_upload;
    private static bool has_env;
    private static int64 env;
    private static int64 min_blocklist_time;
    private static int64 max_blocklist_time;


    internal signal void signal_new_item (SyncFileItem item);
    internal signal void signal_item_completed (SyncFileItem item);
    internal signal void signal_progress (SyncFileItem item, int64 bytes);
    internal signal void signal_finished (bool success);


    /***********************************************************
    Emitted when propagation touches a file.

    Used to track our own file modifications such that notifications
    from the file watcher about these can be ignored.
    ***********************************************************/
    internal signal void signal_touched_file (string filename);

    internal signal void signal_insufficient_local_storage ();
    internal signal void signal_insufficient_remote_storage ();

    /***********************************************************
    ***********************************************************/
    public OwncloudPropagator.for_account (
        Account account,
        string local_dir,
        string remote_folder,
        SyncJournalDb progress_database,
        GLib.List<string> bulk_upload_block_list) {
        this.journal = progress_database;
        this.finished_emited = false;
        this.bandwidth_manager = this;
        this.another_sync_needed = false;
        this.chunk_size = 10 * 1000 * 1000; // 10 MB, overridden in sync_options
        this.account = account;
        this.local_dir = local_dir.has_suffix ("/") ? local_dir : local_dir + "/";
        this.remote_folder = remote_folder.has_suffix ("/") ? remote_folder : remote_folder + "/";
        this.bulk_upload_block_list = bulk_upload_block_list;
        this.schedule_delayed_tasks = false;
        q_register_meta_type<PropagatorJob.AbortType> ("PropagatorJob.AbortType");
    }


    /***********************************************************
    ***********************************************************/
    public void start (SyncFileItemVector synced_items) {
        GLib.assert (std.is_sorted (synced_items.begin (), synced_items.end ()));

        // This builds all the jobs needed for the propagation.
        // Each directory is a PropagateDirectory job, which contains the files in it.
        // In order to do that we loop over the items. (which are sorted by destination)
        // When we enter a directory, we can create the directory job and push it on the stack.

        var regular_expression = sync_options.file_regex;
        if (regular_expression.is_valid ()) {
            GLib.List</* QStringRef */ string> names;
            foreach (var i in synced_items) {
                if (regular_expression.match (i.file).has_match ()) {
                    int index = -1;
                    /* QStringRef */ string string_ref;
                    do {
                        string_ref = i.file.mid_ref (0, index);
                        names.insert (string_ref);
                        index = string_ref.last_index_of ("/");
                    } while (index > 0);
                }
            }
            synced_items.erase (
                std.remove_if (synced_items.begin (),
                synced_items.end (),
                OwncloudPropagator.erase_filter
            ),
            synced_items.end ());
        }

        reset_delayed_upload_tasks ();
        this.propagate_root_directory_job.reset (new PropagateRootDirectory (this));
        GLib.List<QPair<string /* directory name */, PropagateDirectory /* job */>> directories; // should be a LIFO stack
        directories.push (q_make_pair ("", this.propagate_root_directory_job));
        GLib.List<PropagatorJob> directories_to_remove;
        string removed_directory;
        string maybe_conflict_directory;
        foreach (unowned SyncFileItem item in synced_items) {
            if (!removed_directory == "" && item.file.starts_with (removed_directory)) {
                // this is an item in a directory which is going to be removed.
                var del_dir_job = qobject_cast<PropagateDirectory> (directories_to_remove.first ());

                var is_new_directory = item.is_directory () &&
                        (item.instruction == CSync.SyncInstructions.NEW || item.instruction == CSync.SyncInstructions.TYPE_CHANGE);

                if (item.instruction == CSync.SyncInstructions.REMOVE || is_new_directory) {
                    // If it is a remove it is already taken care of by the removal of the parent directory

                    // If it is a new directory then it is inside a deleted directory... That can happen if
                    // the directory etag was not fetched properly on the previous sync because the sync was
                    // aborted while uploading this directory (which is now removed).  We can ignore it.

                    // increase the number of subjobs that would be there.
                    if (del_dir_job) {
                        del_dir_job.increase_affected_count ();
                    }
                    continue;
                } else if (item.instruction == CSync.SyncInstructions.IGNORE) {
                    continue;
                } else if (item.instruction == CSync.SyncInstructions.RENAME) {
                    // all is good, the rename will be executed before the directory deletion
                } else {
                    GLib.warning (
                        "WARNING: Job within a removed directory? This should not happen! "
                        + item.file + item.instruction
                    );
                }
            }

            // If a CONFLICT item contains files these can't be processed because
            // the conflict handling is likely to rename the directory. This can happen
            // when there's a new local directory at the same time as a remote file.
            if (!maybe_conflict_directory == "") {
                if (item.destination ().starts_with (maybe_conflict_directory)) {
                    GLib.info (
                        "Skipping job inside CONFLICT directory "
                        + item.file + item.instruction
                    );
                    item.instruction = CSync.SyncInstructions.NONE;
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
                                          synced_items);
            } else {
                start_file_propagation (item,
                                     directories,
                                     directories_to_remove,
                                     removed_directory,
                                     maybe_conflict_directory);
            }
        }

        foreach (PropagatorJob it in directories_to_remove) {
            this.propagate_root_directory_job.dir_deletion_jobs.append_job (it);
        }

        this.propagate_root_directory_job.signal_finished.connect (
            this.on_signal_propagate_root_directory_job_finished
        );

        this.job_scheduled = false;
        schedule_next_job ();
    }


    /***********************************************************
    ***********************************************************/
    private static erase_filter (GLib.List</* QStringRef */ string> names, SyncFileItem item) {
        return !names.contains (new /* QStringRef */ string (
            item.file
        ));
    }


    /***********************************************************
    ***********************************************************/
    public void start_directory_propagation (
        SyncFileItem item,
        GLib.List<QPair<string, PropagateDirectory>> directories, // should be a LIFO stack
        GLib.List<PropagatorJob> directories_to_remove,
        string removed_directory,
        SyncFileItemVector synced_items) {
        var directory_propagation_job = std.make_unique<PropagateDirectory> (this, item);

        if (item.instruction == CSync.SyncInstructions.TYPE_CHANGE
            && item.direction == SyncFileItem.Direction.UP) {
            // Skip all potential uploads to the new folder.
            // Processing them now leads to problems with permissions:
            // check_for_permissions () has already run and used the permissions
            // of the file we're about to delete to decide whether uploading
            // to the new directory is ok...
            foreach (unowned SyncFileItem dir_item in synced_items) {
                if (dir_item.destination ().starts_with (item.destination () + "/")) {
                    dir_item.instruction = CSync.SyncInstructions.NONE;
                    this.another_sync_needed = true;
                }
            }
        }

        if (item.instruction == CSync.SyncInstructions.REMOVE) {
            // We do the removal of directories at the end, because there might be moves from
            // these directories that will happen later.
            directories_to_remove.prepend (directory_propagation_job);
            removed_directory = item.file + "/";

            // We should not update the etag of parent directories of the removed directory
            // since it would be done before the actual remove (issue #1845)
            // Note: Currently this means that we don't update those etag at all in this sync,
            //       but it should not be a problem, they will be updated in the next sync.
            for (int i = 0; i < directories.size (); ++i) {
                if (directories[i].second.item.instruction == CSync.SyncInstructions.UPDATE_METADATA) {
                    directories[i].second.item.instruction = CSync.SyncInstructions.NONE;
                }
            }
        } else {
            var current_dir_job = directories.top ().second;
            current_dir_job.append_job (directory_propagation_job);
        }
        directories.push (q_make_pair (item.destination () + "/", directory_propagation_job.release ()));
    }


    /***********************************************************
    ***********************************************************/
    public void start_file_propagation (
        SyncFileItem item,
        GLib.List<QPair<string, PropagateDirectory>> directories, // should be a LIFO stack
        GLib.List<PropagatorJob> directories_to_remove,
        string removed_directory,
        string maybe_conflict_directory) {
        if (item.instruction == CSync.SyncInstructions.TYPE_CHANGE) {
            // will delete directories, so defer execution
            var propagate_item_job = create_job (item);
            if (propagate_item_job) {
                directories_to_remove.prepend (propagate_item_job);
            }
            removed_directory = item.file + "/";
        } else {
            directories.top ().second.append_task (item);
        }

        if (item.instruction == CSync.SyncInstructions.CONFLICT) {
            // This might be a file or a directory on the local side. If it's a
            // directory we want to skip processing items inside it.
            maybe_conflict_directory = item.file + "/";
        }
    }


    /***********************************************************
    the maximum number of jobs using bandwidth (uploads or
    downloads, in parallel)
    ***********************************************************/
    public int maximum_active_transfer_job () {
        if (this.download_limit != 0
            || this.upload_limit != 0
            || !this.sync_options.parallel_network_jobs) {
            // disable parallelism when there is a network limit.
            return 1;
        }
        return q_min (3, q_ceil (this.sync_options.parallel_network_jobs / 2.0));
    }


    /***********************************************************
    The size to use for upload chunks.

    Will be dynamically adjusted after each chunk upload finishes
    if Capabilities.desired_chunk_upload_duration has a target
    chunk-upload duration set.
    ***********************************************************/
    public int64 small_file_size () {
        const int64 small_file_size = 100 * 1024; //default to 1 MB. Not dynamic right now.
        return small_file_size;
    }


    /***********************************************************
    The maximum number of active jobs in parallel
    ***********************************************************/
    public int hard_maximum_active_job () {
        if (!this.sync_options.parallel_network_jobs) {
            return 1;
        }
        return this.sync_options.parallel_network_jobs;
    }


    /***********************************************************
    Check whether a download would clash with an existing file
    in filesystems that are only case-preserving.
    ***********************************************************/
    public bool local_filename_clash (string relfile) {
        const string file = this.local_dir + rel_file;
        GLib.assert (!file == "");

        if (!file == "" && Utility.fs_case_preserving ()) {
            GLib.debug ("CaseClashCheck for " + file);
            // On Linux, the file system is case sensitive, but this code is useful for testing.
            // Just check that there is no other file with the same name and different casing.
            GLib.FileInfo file_info = GLib.File.new_for_path (file);
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


    /***********************************************************
    Check whether a file is properly accessible for upload.

    It is possible to create files with filenames that differ
    only by case in NTFS, but most operations such as stat and
    open only target one of these by default.

    When that happens, we want to avoid uploading incorrect data
    and give up on the file.
    ***********************************************************/
    public bool has_case_clash_accessibility_problem (string relfile) {
        //  Q_UNUSED (relfile);
        return false;
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public string full_local_path (string temporary_filename) {
        return this.local_dir + temporary_filename;
    }


    /***********************************************************
    ***********************************************************/
    public string local_path {
        return this.local_dir;
    }


    /***********************************************************
    Returns the full remote path including the folder root of a
    folder sync path.

    // TODO: should this be part of the this.item (unowned SyncFileItem)?

    Q_REQUIRED_RESULT
    ***********************************************************/
    public string full_remote_path (string temporary_filename) {
        return this.remote_folder + temporary_filename;
    }


    /***********************************************************
    ***********************************************************/
    public string remote_path {
        return this.remote_folder;
    }


    /***********************************************************
    Creates the job for an item.
    ***********************************************************/
    public PropagateItemJob create_job (SyncFileItem item) {
        bool delete_existing = item.instruction == CSync.SyncInstructions.TYPE_CHANGE;
        switch (item.instruction) {
        case CSync.SyncInstructions.REMOVE:
            if (item.direction == SyncFileItem.Direction.DOWN)
                return new PropagateLocalRemove (this, item);
            else
                return new PropagateRemoteDelete (this, item);
        case CSync.SyncInstructions.NEW:
        case CSync.SyncInstructions.TYPE_CHANGE:
        case CSync.SyncInstructions.CONFLICT:
            if (item.is_directory ()) {
                // CONFLICT has this.direction == None
                if (item.direction != SyncFileItem.Direction.UP) {
                    var propagate_local_mkdir_job = new PropagateLocalMkdir (this, item);
                    propagate_local_mkdir_job.delete_existing_file (delete_existing);
                    return propagate_local_mkdir_job;
                } else {
                    var propagate_remote_mkdir_job = new PropagateRemoteMkdir (this, item);
                    propagate_remote_mkdir_job.delete_existing (delete_existing);
                    return propagate_remote_mkdir_job;
                }
            } //fall through
        case CSync.SyncInstructions.SYNC:
            if (item.direction != SyncFileItem.Direction.UP) {
                var propagate_download_file_job = new PropagateDownloadFile (this, item);
                propagate_download_file_job.delete_existing_folder (delete_existing);
                return propagate_download_file_job;
            } else {
                if (delete_existing || !is_delayed_upload_item (item)) {
                    var propagate_upload_file_job = create_upload_job (item, delete_existing);
                    return propagate_upload_file_job.release ();
                } else {
                    push_delayed_upload_task (item);
                    return null;
                }
            }
        case CSync.SyncInstructions.RENAME:
            if (item.direction == SyncFileItem.Direction.UP) {
                return new PropagateRemoteMove (this, item);
            } else {
                return new PropagateLocalRename (this, item);
            }
        case CSync.SyncInstructions.IGNORE:
        case CSync.SyncInstructions.ERROR:
            return new PropagateIgnoreJob (this, item);
        default:
            return null;
        }
        return null;
    }


    /***********************************************************
    ***********************************************************/
    public void schedule_next_job () {
        if (this.job_scheduled) {
            return; // don't schedule more than 1
        }
        this.job_scheduled = true;
        GLib.Timeout.single_shot (3, this, OwncloudPropagator.on_signal_schedule_next_job_impl);
    }


    /***********************************************************
    ***********************************************************/
    public void report_progress (SyncFileItem item, int64 bytes) {
        /* emit */ progress (item, bytes);
    }


    /***********************************************************
    ***********************************************************/
    public new void abort () {
        if (this.abort_requested) {
            return;
        }
        if (this.propagate_root_directory_job) {
            // Connect to signal_abort_finished  which signals that abort has been asynchronously on_signal_finished
            this.propagate_root_directory_job.signal_abort_finished.connect (
                this.on_signal_propagate_root_directory_job_finished
            );

            // Use Queued Connection because we're possibly already in an item's on_signal_finished stack
            QMetaObject.invoke_method (this.propagate_root_directory_job, "abort", Qt.QueuedConnection,
                                      Q_ARG (PropagatorJob.AbortType, PropagatorJob.AbortType.ASYNCHRONOUS));

            // Give asynchronous abort 5000 msec to finish on its own
            GLib.Timeout.single_shot (5000, this, SLOT (on_signal_abort_timeout ()));
        } else {
            // No root job, call on_signal_propagate_root_directory_job_finished
            on_signal_propagate_root_directory_job_finished (SyncFileItem.Status.NORMAL_ERROR);
        }
    }


    /***********************************************************
    ***********************************************************/
    //  private unowned Account account;
    /***********************************************************
    ***********************************************************/
    public unowned Account account;
    unowned Account OwncloudPropagator.account {
        return this.account;
    }


    /***********************************************************
    Checks whether there's enough disk space available to complete
    all jobs that are currently running.
    ***********************************************************/
    public DiskSpaceResult disk_space_check () {
        const int64 free_bytes = Utility.free_disk_space (this.local_dir);
        if (free_bytes < 0) {
            return DiskSpaceOk;
        }

        if (free_bytes < critical_free_space_limit ()) {
            return DiskSpaceCritical;
        }

        if (free_bytes - this.propagate_root_directory_job.committed_disk_space () < free_space_limit ()) {
            return DiskSpaceFailure;
        }

        return DiskSpaceOk;
    }


    /***********************************************************
    Handles a conflict by renaming the file 'item'.

    Sets up conflict records.

    It also creates a new upload job in composite if the item
    moved away is a file and conflict uploads are requested.

    Returns true on on_signal_success, false and error on error.
    ***********************************************************/
    public bool create_conflict (
        SyncFileItem item,
        PropagatorCompositeJob composite,
        string *error) {
        string fn = full_local_path (item.file);

        string rename_error;
        var conflict_mod_time = FileSystem.get_mod_time (fn);
        if (conflict_mod_time <= 0) {
            error = _("Impossible to get modification time for file in conflict %1").printf (fn);
            return false;
        }
        string conflict_user_name;
        if (account.capabilities.upload_conflict_files ()) {
            conflict_user_name = account.display_name;
        }
        string conflict_filename = Utility.make_conflict_filename (
            item.file, Utility.q_date_time_from_time_t (conflict_mod_time), conflict_user_name);
        string conflict_file_path = full_local_path (conflict_filename);

        /* emit */ signal_touched_file (fn);
        /* emit */ signal_touched_file (conflict_file_path);

        if (!FileSystem.rename (fn, conflict_file_path, rename_error)) {
            // If the rename fails, don't replace it.
            if (error)
                *error = rename_error;
            return false;
        }
        GLib.info ("Created conflict file " + fn + " -> " + conflict_filename);

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
        if (account.capabilities.upload_conflict_files ()) {
            if (composite && !GLib.File.new_for_path (conflict_file_path).query_info ().get_file_type () == FileType.DIRECTORY) {
                SyncFileItem conflict_item = new SyncFileItem ();
                conflict_item.file = conflict_filename;
                conflict_item.type = ItemType.FILE;
                conflict_item.direction = SyncFileItem.Direction.UP;
                conflict_item.instruction = CSync.SyncInstructions.NEW;
                conflict_item.modtime = conflict_mod_time;
                conflict_item.size = item.previous_size;
                /* emit */ signal_new_item (conflict_item);
                composite.append_task (conflict_item);
            }
        }

        // Need a new sync to detect the created copy of the conflicting file
        this.another_sync_needed = true;

        return true;
    }


    /***********************************************************
    Map original path (as in the DB) to target final path
    ***********************************************************/
    public string adjust_renamed_path (string original);
    string OwncloudPropagator.adjust_renamed_path (string original) {
        return adjust_renamed_path (this.renamed_directories, original);
    }


    /***********************************************************
    Update the database for an item.

    Typically after a sync operation succeeded. Updates the inode from
    the filesystem.

    Will also trigger a Vfs.convert_to_placeholder.
    ***********************************************************/
    public Result<Vfs.ConvertToPlaceholderResult, string> update_metadata (SyncFileItem item);
    Result<Vfs.ConvertToPlaceholderResult, string> OwncloudPropagator.update_metadata (SyncFileItem item) {
        return OwncloudPropagator.static_update_metadata (item, this.local_dir, sync_options.vfs, this.journal);
    }


    /***********************************************************
    Update the database for an item.

    Typically after a sync operation succeeded. Updates the inode from
    the filesystem.

    Will also trigger a Vfs.convert_to_placeholder.
    ***********************************************************/
    public static Result<Vfs.ConvertToPlaceholderResult, string> static_update_metadata (
        SyncFileItem item, string local_dir,
        Vfs vfs, SyncJournalDb journal) {
        const string fs_path = local_dir + item.destination ();
        var result = vfs.convert_to_placeholder (fs_path, item);
        if (!result) {
            return result.error;
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            return Vfs.ConvertToPlaceholderResult.Locked;
        }
        var record = item.to_sync_journal_file_record_with_inode (fs_path);
        var d_bresult = journal.file_record (record);
        if (!d_bresult) {
            return d_bresult.error;
        }
        return Vfs.ConvertToPlaceholderResult.Ok;
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public bool is_delayed_upload_item (SyncFileItem item) {
        return account.capabilities.bulk_upload () && !this.schedule_delayed_tasks && !item.is_encrypted && this.sync_options.min_chunk_size > item.size && !is_in_bulk_upload_block_list (item.file);
    }


    /***********************************************************
    Q_REQUIRED_RESULT
    ***********************************************************/
    public GLib.Deque<unowned SyncFileItem> delayed_tasks () {
        return this.delayed_tasks;
    }


    /***********************************************************
    ***********************************************************/
    public void clear_delayed_tasks () {
        this.delayed_tasks.clear ();
    }


    /***********************************************************
    ***********************************************************/
    public void add_to_bulk_upload_block_list (string file) {
        GLib.debug ("Block list for bulk upload " + file);
        this.bulk_upload_block_list.insert (file);
    }


    /***********************************************************
    ***********************************************************/
    public void remove_from_bulk_upload_block_list (string file) {
        GLib.debug ("Block list for bulk upload " + file);
        this.bulk_upload_block_list.remove (file);
    }


    /***********************************************************
    ***********************************************************/
    public bool is_in_bulk_upload_block_list (string file) {
        return this.bulk_upload_block_list.contains (file);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_abort_timeout () {
        // Abort synchronously and finish
        this.propagate_root_directory_job.abort (PropagatorJob.AbortType.SYNCHRONOUS);
        on_signal_propagate_root_directory_job_finished (SyncFileItem.Status.NORMAL_ERROR);
    }


    /***********************************************************
    Emit the on_signal_finished signal and make sure it is only emitted once
    ***********************************************************/
    private void on_signal_propagate_root_directory_job_finished (SyncFileItem.Status status) {
        if (!this.finished_emited) {
            /* emit */ signal_finished (status == SyncFileItem.Status.SUCCESS);
        }
        this.finished_emited = true;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_schedule_next_job_impl () {
        // TODO: If we see that the automatic up-scaling has a bad impact we
        // need to check how to avoid this.
        // Down-scaling on slow networks? https://github.com/owncloud/client/issues/3382
        // Making sure we do up/down at same time? https://github.com/owncloud/client/issues/1633

        this.job_scheduled = false;

        if (this.active_job_list.count () < maximum_active_transfer_job ()) {
            if (this.propagate_root_directory_job.on_signal_schedule_self_or_child ()) {
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
                GLib.debug ("Can pump in another request! active_jobs = " + this.active_job_list.count ());
                if (this.propagate_root_directory_job.on_signal_schedule_self_or_child ()) {
                    schedule_next_job ();
                }
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private PropagateUploadFileCommon create_upload_job (SyncFileItem item, bool delete_existing) {
        var propagate_upload_file_job = new PropagateUploadFileCommon ();

        if (item.size > sync_options.initial_chunk_size && account.capabilities.chunking_ng ()) {
            // Item is above this.initial_chunk_size, thus will be classified as to be chunked
            propagate_upload_file_job = std.make_unique<PropagateUploadFileNG> (this, item);
        } else {
            propagate_upload_file_job = std.make_unique<PropagateUploadFileV1> (this, item);
        }

        propagate_upload_file_job.delete_existing (delete_existing);

        remove_from_bulk_upload_block_list (item.file);

        return propagate_upload_file_job;
    }


    /***********************************************************
    ***********************************************************/
    private void push_delayed_upload_task (SyncFileItem item) {
        this.delayed_tasks.push_back (item);
    }


    /***********************************************************
    ***********************************************************/
    private void reset_delayed_upload_tasks () {
        this.schedule_delayed_tasks = false;
        this.delayed_tasks.clear ();
    }


    /***********************************************************
    Free disk space threshold below which syncs will abort and
    not even start.
    ***********************************************************/
    private static int64 critical_free_space_limit () {
        int64 value = 50 * 1000 * 1000LL;

        OwncloudPropagator.has_env = false;
        OwncloudPropagator.env = qgetenv ("OWNCLOUD_CRITICAL_FREE_SPACE_BYTES").to_long_long (&has_env);
        if (has_env) {
            value = env;
        }

        return q_bound (0LL, value, free_space_limit ());
    }


    /***********************************************************
    The client will not intentionally reduce the available free
    disk space below this limit.

    Uploads will still run and downloads that are small enough
    will continue too.
    ***********************************************************/
    private static int64 free_space_limit () {
        int64 value = 250 * 1000 * 1000LL;

        OwncloudPropagator.has_env = false;
        OwncloudPropagator.env = qgetenv ("OWNCLOUD_FREE_SPACE_BYTES").to_long_long (&has_env);
        if (has_env) {
            value = env;
        }

        return value;
    }


    /***********************************************************
    ***********************************************************/
    private static int64 get_min_blocklist_time () {
        return q_max (q_environment_variable_int_value ("OWNCLOUD_BLOCKLIST_TIME_MIN"),
            25); // 25 seconds
    }


    /***********************************************************
    ***********************************************************/
    private static int64 get_max_blocklist_time () {
        int v = q_environment_variable_int_value ("OWNCLOUD_BLOCKLIST_TIME_MAX");
        if (v > 0)
            return v;
        return 24 * 60 * 60; // 1 day
    }


    /***********************************************************
    Creates a blocklist entry, possibly taking into account an old one.

    The old entry may be invalid, then a fresh entry is created.
    ***********************************************************/
    private static SyncJournalErrorBlocklistRecord create_blocklist_entry (
        SyncJournalErrorBlocklistRecord old,
        SyncFileItem item) {
        SyncJournalErrorBlocklistRecord entry;
        entry.file = item.file;
        entry.error_string = item.error_string;
        entry.last_try_modtime = item.modtime;
        entry.last_try_etag = item.etag;
        entry.last_try_time = Utility.q_date_time_to_time_t (GLib.DateTime.current_date_time_utc ());
        entry.rename_target = item.rename_target;
        entry.retry_count = old.retry_count + 1;
        entry.request_id = item.request_id;

        OwncloudPropagator.min_blocklist_time = get_min_blocklist_time ();
        OwncloudPropagator.max_blocklist_time = q_max (get_max_blocklist_time (), min_blocklist_time);

        // The factor of 5 feels natural : 25s, 2 min, 10 min, ~1h, ~5h, ~24h
        entry.ignore_duration = old.ignore_duration * 5;

        if (item.http_error_code == 403) {
            GLib.warning ("Probably firewall error: " + item.http_error_code + ", blocklisting up to 1h only.");
            entry.ignore_duration = q_min (entry.ignore_duration, int64 (60 * 60));

        } else if (item.http_error_code == 413 || item.http_error_code == 415) {
            GLib.warning ("Fatal Error condition " + item.http_error_code + ", maximum blocklist ignore time!");
            entry.ignore_duration = max_blocklist_time;
        }

        entry.ignore_duration = q_bound (OwncloudPropagator.min_blocklist_time, entry.ignore_duration, OwncloudPropagator.max_blocklist_time);

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
    Updates, creates or removes a blocklist entry for the given
    item.

    May adjust the status or item.error_string.
    ***********************************************************/
    private static void blocklist_update (SyncJournalDb journal, SyncFileItem item) {
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

            GLib.info (
                "blocklisting " + item.file
                + " for " + new_entry.ignore_duration
                + ", retry count " + new_entry.retry_count);

            return;
        }

        // Some soft errors might become louder on repeat occurrence
        if (item.status == SyncFileItem.Status.SOFT_ERROR
            && new_entry.retry_count > 1) {
            GLib.warning (
                "escalating soft error on " + item.file
                + " to normal error, " + item.http_error_code);
            item.status = SyncFileItem.Status.NORMAL_ERROR;
            return;
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
    public static bool file_is_still_changing (SyncFileItem item) {
        var modtime = Utility.q_date_time_from_time_t (item.modtime);
        const int64 ms_since_mod = modtime.msecs_to (GLib.DateTime.current_date_time_utc ());

        return new GLib.TimeSpan (ms_since_mod) < SyncEngine.minimum_file_age_for_upload
            // if the mtime is too much in the future we do* upload the file
            && ms_since_mod > -10000;
    }



    private string get_etag_from_reply (GLib.InputStream reply) {
        string oc_etag = parse_etag (reply.raw_header ("OC-ETag"));
        string etag = parse_etag (reply.raw_header ("ETag"));
        string ret = oc_etag;
        if (ret == "") {
            ret = etag;
        }
        if (oc_etag.length > 0 && oc_etag != etag) {
            GLib.debug ("Quite peculiar, we have an etag != OC-Etag [no problem!] " + etag + oc_etag);
        }
        return ret;
    }


    /***********************************************************
    Given an error from the network, map to a SyncFileItem.Status error
    ***********************************************************/
    private SyncFileItem.Status classify_error (GLib.InputStream.NetworkError nerror,
        int http_code, bool another_sync_needed = null, string error_body = "") {
        GLib.assert (nerror != GLib.InputStream.NoError); // we should only be called when there is an error

        if (nerror == GLib.InputStream.RemoteHostClosedError) {
            // Sometimes server bugs lead to a connection close on certain files,
            // that shouldn't bring the rest of the syncing to a halt.
            return SyncFileItem.Status.NORMAL_ERROR;
        }

        if (nerror > GLib.InputStream.NoError && nerror <= GLib.InputStream.UnknownProxyError) {
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
                    error_body.contains (" (>Sabre\DAV\Exception\ServiceUnavailable<)")
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

} // class OwncloudPropagator

} // namespace LibSync
} // namespace Occ
