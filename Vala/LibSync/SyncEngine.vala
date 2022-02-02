/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <unistd.h>

// #include <climits>
// #include <cassert>
// #include <chrono>

// #include <QCoreApplication>
// #include <QSslSocket>
// #include <QDir>
// #include <QLoggingCategory>
// #include <QMutexLocker>
// #include <QThread>
// #include <string[]>
// #include <QTextStream>
// #include <QTime>
// #include <GLib.Uri>
// #include <QSslCertificate>
// #include <QProcess>
// #include <QElapsedTimer>
// #include <QFileInfo>
// #include <qtextcodec.h>

// #pragma once

// #include <cstdint>

// #include <QMutex>
// #include <QThread>
// #include <QMap>
// #include <string[]>

// #include <set>


namespace Occ {

class ProcessDirectoryJob;

enum Another_sync_needed {
    No_follow_up_sync,
    Immediate_follow_up, // schedule this again immediately (limited amount of times)
    DelayedFollowUp // regularly schedule this folder again (around 1/minute, unlimited)
};

/***********************************************************
@brief The SyncEngine class
@ingroup libsync
***********************************************************/
class SyncEngine : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public SyncEngine (AccountPointer account, string local_path,
        const string remote_path, SyncJournalDb journal);
    ~SyncEngine () override;

    /***********************************************************
    ***********************************************************/
    public void on_start_sync ();

    /***********************************************************
    ***********************************************************/
    public 
    public void set_network_limits (int upload, int download);


    /***********************************************************
    Abort the sync. Called from the main thread.
    ***********************************************************/
    public void on_abort ();

    /***********************************************************
    ***********************************************************/
    public bool is_sync_running () {
        return this.sync_running;
    }


    /***********************************************************
    ***********************************************************/
    public SyncOptions sync_options () {
        return this.sync_options;
    }


    /***********************************************************
    ***********************************************************/
    public void set_sync_options (SyncOptions options) {
    }


    /***********************************************************
    ***********************************************************/
    public 
    }


    /***********************************************************
    ***********************************************************/
    public urn this.ignore_hidden_files;
    }
    public void set_ignore_hidden_files (bool ignore) {
        this.ignore_hidden_files = ignore;
    }


    /***********************************************************
    ***********************************************************/
    public ExcludedFiles excluded_files () {
        return this.excluded_files;
    }


    /***********************************************************
    ***********************************************************/
    public Utility.StopWatch stop_watch () {
    }


    /***********************************************************
    ***********************************************************/
    public 
    public SyncFileStatusTracker sync_file_status_tracker () {
        return this.sync_file_status_tracker;
    }


    /***********************************************************
    Returns whether another sync is needed to complete the sync
    ***********************************************************/
    public Another_sync_needed is_another_sync_needed () {
        return this.another_sync_needed;
    }


    /***********************************************************
    ***********************************************************/
    public bool was_file_touched (string fn);

    /***********************************************************
    ***********************************************************/
    public AccountPointer account ();

    /***********************************************************
    ***********************************************************/
    public 
    public SyncJournalDb journal () {
        return this.journal;
    }


    /***********************************************************
    ***********************************************************/
    public string local_path () {
        return this.local_path;
    }


    /***********************************************************
    Duration in ms that uploads should be delayed after a file change

    In certain situations a file can be written to very regularly over a large
    amount of time. Copying a large file could take a while. A logfile could be
    updated every second.

    In these cases it isn't desirable to attempt to upload the "unfinished" file
    To avoid that, uploads of files where the distance between the mtime and the
    current time is less than this duration are skipped.
    ***********************************************************/
    public static std.chrono.milliseconds minimum_file_age_for_upload;


    /***********************************************************
    Control whether local discovery should read from filesystem or database.

    If style is DatabaseAndFilesystem, paths a set of file paths relative
    the synced folder. All the parent directories of th
    be read from the database and scanned on the filesystem.

    Note, the style and paths are only retained for the next sync and
    revert afterwards. Use this.last_local_discovery_style to discover the last
    sync's style.
    ***********************************************************/
    public void set_local_discovery_options (LocalDiscoveryStyle style, std.set<string> paths = {});


    /***********************************************************
    Returns whether the given folder-relative path should be locally discovered
    given the local discovery options.

    Example: If path is 'foo/bar' and style is DatabaseAndFilesystem and dirs contains
        'foo/bar/touched_file', then the result will be true.
    ***********************************************************/
    public bool should_discover_locally (string path);


    /***********************************************************
    Access the last sync run's local discovery style
    ***********************************************************/
    public LocalDiscoveryStyle last_local_discovery_style () {
        return this.last_local_discovery_style;
    }


    /***********************************************************
    Removes all virtual file database entries and dehydrated local placeholders.

    Particularly useful when switching off vfs mode or switching to a
    different kind of vfs.

    Note that hydrated* placeholder files might still be left. These will
    get cleaned up by Vfs.unregister_folder ().
    ***********************************************************/
    public static void wipe_virtual_files (string local_path, SyncJournalDb journal, Vfs vfs);

    /***********************************************************
    ***********************************************************/
    public static void switch_to_virtual_files (string local_path, SyncJournalDb journal, Vfs vfs);

    // for the test
    public var get_propagator () {
        return this.propagator;
    }

signals:
    // During update, before reconcile
    void root_etag (GLib.ByteArray , GLib.DateTime &);

    // after the above signals. with the items that actually need propagating
    void about_to_propagate (SyncFileItemVector &);

    // after each item completed by a job (successful or not)
    void item_completed (SyncFileItemPtr &);

    void transmission_progress (ProgressInfo progress);

    /// We've produced a new sync error of a type.
    void sync_error (string message, ErrorCategory category = ErrorCategory.Normal);

    void add_error_to_gui (SyncFileItem.Status status, string error_message, string subject);

    void on_finished (bool on_success);
    void started ();


    /***********************************************************
    Emited when the sync engine detects that all the files have been removed or change.
    This usually happen when the server was reset or something.
    Set cancel to true in a slot connected from this signal to on_abort the sync.
    ***********************************************************/
    void about_to_remove_all_files (SyncFileItem.Direction direction, std.function<void (bool)> f);

    // A new folder was discovered and was not synced because of the confirmation feature
    void new_big_folder (string folder, bool is_external);


    /***********************************************************
    Emitted when propagation has problems with a locked file.

    Forwarded from OwncloudPropagator.seen_locked_file.
    ***********************************************************/
    void seen_locked_file (string filename);


    /***********************************************************
    ***********************************************************/
    private void on_folder_discovered (bool local, string folder);
    private void on_root_etag_received (GLib.ByteArray , GLib.DateTime time);


    /***********************************************************
    When the discovery phase discovers an item
    ***********************************************************/
    private void on_item_discovered (SyncFileItemPtr item);


    /***********************************************************
    Called when a SyncFileItem gets accepted for a sync.

    Mostly done in initial creation inside treewalk_file but
    can also be called via the propagator for items that are
    created during propagation.
    ***********************************************************/
    private void on_new_item (SyncFileItemPtr item);

    /***********************************************************
    ***********************************************************/
    private void on_item_completed (SyncFileItemPtr item);
    private void on_discovery_finished ();
    private void on_propagation_finished (bool on_success);
    private void on_progress (SyncFileItem item, int64 curent);
    private void on_clean_polls_job_aborted (string error);


    /***********************************************************
    Records that a file was touched by a job.
    ***********************************************************/
    private void on_add_touched_file (string fn);


    /***********************************************************
    Wipes the this.touched_files hash
    ***********************************************************/
    private void on_clear_touched_files ();


    /***********************************************************
    Emit a summary error, unless it was seen before
    ***********************************************************/
    private void on_summary_error (string message);

    /***********************************************************
    ***********************************************************/
    private void on_insufficient_local_storage ();
    private void on_insufficient_remote_storage ();


    /***********************************************************
    ***********************************************************/
    private bool check_error_blocklisting (SyncFileItem item);

    // Cleans up unnecessary downloadinfo entries in the journal as well
    // as their temporary files.
    private void delete_stale_download_infos (SyncFileItemVector sync_items);

    // Removes stale uploadinfos from the journal.
    private void delete_stale_upload_infos (SyncFileItemVector sync_items);

    // Removes stale error blocklist entries from the journal.
    private void delete_stale_error_blocklist_entries (SyncFileItemVector sync_items);

    // Removes stale and adds missing conflict records after sync
    private void conflict_record_maintenance ();

    // on_cleanup and emit the on_finished signal
    private void on_finalize (bool on_success);

    /***********************************************************
    ***********************************************************/
    private static bool s_any_sync_running; //true when one sync is running somewhere (for debugging)

    // Must only be acessed during update and reconcile
    private GLib.Vector<SyncFileItemPtr> this.sync_items;

    /***********************************************************
    ***********************************************************/
    private AccountPointer this.account;
    private bool this.needs_update;
    private bool this.sync_running;
    private string this.local_path;
    private string this.remote_path;
    private GLib.ByteArray this.remote_root_etag;
    private SyncJournalDb this.journal;
    private QScopedPointer<DiscoveryPhase> this.discovery_phase;
    private unowned<OwncloudPropagator> this.propagator;

    /***********************************************************
    ***********************************************************/
    private GLib.Set<string> this.bulk_upload_block_list;

    // List of all files with conflicts
    private GLib.Set<string> this.seen_conflict_files;

    /***********************************************************
    ***********************************************************/
    private QScopedPointer<ProgressInfo> this.progress_info;

    /***********************************************************
    ***********************************************************/
    private QScopedPointer<ExcludedFiles> this.excluded_files;
    private QScopedPointer<SyncFileStatusTracker> this.sync_file_status_tracker;
    private Utility.StopWatch this.stop_watch;


    /***********************************************************
    check if we are allowed to propagate everything, and if we are not, adjust the instructions
    to recover
    ***********************************************************/
    private void check_for_permission (SyncFileItemVector sync_items);
    private RemotePermissions get_permissions (string file);


    /***********************************************************
    Instead of downloading files from the server, upload the files to the server
    ***********************************************************/
    private void restore_old_files (SyncFileItemVector sync_items);

    // true if there is at least one file which was not changed on the server
    private bool this.has_none_files;

    // true if there is at leasr one file with instruction REMOVE
    private bool this.has_remove_file;

    // If ignored files should be ignored
    private bool this.ignore_hidden_files = false;

    /***********************************************************
    ***********************************************************/
    private int this.upload_limit;
    private int this.download_limit;
    private SyncOptions this.sync_options;

    /***********************************************************
    ***********************************************************/
    private Another_sync_needed this.another_sync_needed;


    /***********************************************************
    Stores the time since a job touched a file.
    ***********************************************************/
    private QMulti_map<QElapsedTimer, string> this.touched_files;

    /***********************************************************
    ***********************************************************/
    private QElapsedTimer this.last_update_progress_callback_call;


    /***********************************************************
    For clearing the this.touched_files variable after sync on_finished
    ***********************************************************/
    private QTimer this.clear_touched_files_timer;


    /***********************************************************
    List of unique errors that occurred in a sync run.
    ***********************************************************/
    private GLib.Set<string> this.unique_errors;


    /***********************************************************
    The kind of local discovery the last sync run used
    ***********************************************************/
    private LocalDiscoveryStyle this.last_local_discovery_style = LocalDiscoveryStyle.FilesystemOnly;
    private LocalDiscoveryStyle this.local_discovery_style = LocalDiscoveryStyle.FilesystemOnly;
    private std.set<string> this.local_discovery_paths;
};

    bool SyncEngine.s_any_sync_running = false;


    /***********************************************************
    When the client touches a file, block change notifications for this duration (ms)

    On Linux and Windows the file watcher can't distinguish a change that originates
    from the client (like a download during a sync operation) and an external change.
    To work around that, all files the client touches are recorded and file change
    notifications for these are blocked for some time. This value controls for how
    long.

    Reasons this delay can't be very small:
    - it takes time for the change notification to arrive and to be processed by th
    - some time could pass between the client recording that a file will be touched
      and its filesystem operation finishing, triggering the notification
    ***********************************************************/
    static const std.chrono.milliseconds s_touched_files_max_age_ms (3 * 1000);

    // doc in header
    std.chrono.milliseconds SyncEngine.minimum_file_age_for_upload (2000);

    SyncEngine.SyncEngine (AccountPointer account, string local_path,
        const string remote_path, Occ.SyncJournalDb journal)
        : this.account (account)
        , this.needs_update (false)
        , this.sync_running (false)
        , this.local_path (local_path)
        , this.remote_path (remote_path)
        , this.journal (journal)
        , this.progress_info (new ProgressInfo)
        , this.has_none_files (false)
        , this.has_remove_file (false)
        , this.upload_limit (0)
        , this.download_limit (0)
        , this.another_sync_needed (No_follow_up_sync) {
        q_register_meta_type<SyncFileItem> ("SyncFileItem");
        q_register_meta_type<SyncFileItemPtr> ("SyncFileItemPtr");
        q_register_meta_type<SyncFileItem.Status> ("SyncFileItem.Status");
        q_register_meta_type<SyncFileStatus> ("SyncFileStatus");
        q_register_meta_type<SyncFileItemVector> ("SyncFileItemVector");
        q_register_meta_type<SyncFileItem.Direction> ("SyncFileItem.Direction");

        // Everything in the SyncEngine expects a trailing slash for the local_path.
        ASSERT (local_path.ends_with ('/'));

        this.excluded_files.on_reset (new ExcludedFiles (local_path));

        this.sync_file_status_tracker.on_reset (new SyncFileStatusTracker (this));

        this.clear_touched_files_timer.set_single_shot (true);
        this.clear_touched_files_timer.set_interval (30 * 1000);
        connect (&this.clear_touched_files_timer, &QTimer.timeout, this, &SyncEngine.on_clear_touched_files);
        connect (this, &SyncEngine.on_finished, [this] (bool /* on_finished */) {
            this.journal.key_value_store_set ("last_sync", GLib.DateTime.current_secs_since_epoch ());
        });
    }

    SyncEngine.~SyncEngine () {
        on_abort ();
        this.excluded_files.on_reset ();
    }


    /***********************************************************
    Check if the item is in the blocklist.
    If it should not be sync'ed because of the blocklist, update the item with the error instruction
    and proper error message, and return true.
    If the item is not in the blocklist, or the blocklist is stale, return false.
    ***********************************************************/
    bool SyncEngine.check_error_blocklisting (SyncFileItem item) {
        if (!this.journal) {
            q_c_critical (lc_engine) << "Journal is undefined!";
            return false;
        }

        SyncJournalErrorBlocklistRecord entry = this.journal.error_blocklist_entry (item._file);
        item._has_blocklist_entry = false;

        if (!entry.is_valid ()) {
            return false;
        }

        item._has_blocklist_entry = true;

        // If duration has expired, it's not blocklisted anymore
        time_t now = Utility.q_date_time_to_time_t (GLib.DateTime.current_date_time_utc ());
        if (now >= entry._last_try_time + entry._ignore_duration) {
            q_c_info (lc_engine) << "blocklist entry for " << item._file << " has expired!";
            return false;
        }

        // If the file has changed locally or on the server, the blocklist
        // entry no longer applies
        if (item._direction == SyncFileItem.Direction.UP) { // check the modtime
            if (item._modtime == 0 || entry._last_try_modtime == 0) {
                return false;
            } else if (item._modtime != entry._last_try_modtime) {
                q_c_info (lc_engine) << item._file << " is blocklisted, but has changed mtime!";
                return false;
            } else if (item._rename_target != entry._rename_target) {
                q_c_info (lc_engine) << item._file << " is blocklisted, but rename target changed from" << entry._rename_target;
                return false;
            }
        } else if (item._direction == SyncFileItem.Direction.DOWN) {
            // download, check the etag.
            if (item._etag.is_empty () || entry._last_try_etag.is_empty ()) {
                q_c_info (lc_engine) << item._file << "one ETag is empty, no blocklisting";
                return false;
            } else if (item._etag != entry._last_try_etag) {
                q_c_info (lc_engine) << item._file << " is blocklisted, but has changed etag!";
                return false;
            }
        }

        int64 wait_seconds = entry._last_try_time + entry._ignore_duration - now;
        q_c_info (lc_engine) << "Item is on blocklist : " << entry._file
                         << "retries:" << entry._retry_count
                         << "for another" << wait_seconds << "s";

        // We need to indicate that we skip this file due to blocklisting
        // for reporting and for making sure we don't update the blocklist
        // entry yet.
        // Classification is this this.instruction and this.status
        item._instruction = CSYNC_INSTRUCTION_IGNORE;
        item._status = SyncFileItem.Status.BLOCKLISTED_ERROR;

        var wait_seconds_str = Utility.duration_to_descriptive_string1 (1000 * wait_seconds);
        item._error_string = _("%1 (skipped due to earlier error, trying again in %2)").arg (entry._error_string, wait_seconds_str);

        if (entry._error_category == SyncJournalErrorBlocklistRecord.InsufficientRemoteStorage) {
            on_insufficient_remote_storage ();
        }

        return true;
    }

    /***********************************************************
    ***********************************************************/
    static bool is_file_transfer_instruction (SyncInstructions instruction) {
        return instruction == CSYNC_INSTRUCTION_CONFLICT
            || instruction == CSYNC_INSTRUCTION_NEW
            || instruction == CSYNC_INSTRUCTION_SYNC
            || instruction == CSYNC_INSTRUCTION_TYPE_CHANGE;
    }

    void SyncEngine.delete_stale_download_infos (SyncFileItemVector sync_items) {
        // Find all downloadinfo paths that we want to preserve.
        GLib.Set<string> download_file_paths;
        foreach (SyncFileItemPtr it, sync_items) {
            if (it._direction == SyncFileItem.Direction.DOWN
                && it._type == ItemTypeFile
                && is_file_transfer_instruction (it._instruction)) {
                download_file_paths.insert (it._file);
            }
        }

        // Delete from journal and from filesystem.
        const GLib.Vector<SyncJournalDb.DownloadInfo> deleted_infos =
            this.journal.get_and_delete_stale_download_infos (download_file_paths);
        foreach (SyncJournalDb.DownloadInfo deleted_info, deleted_infos) {
            const string tmppath = this.propagator.full_local_path (deleted_info._tmpfile);
            q_c_info (lc_engine) << "Deleting stale temporary file : " << tmppath;
            FileSystem.remove (tmppath);
        }
    }

    void SyncEngine.delete_stale_upload_infos (SyncFileItemVector sync_items) {
        // Find all blocklisted paths that we want to preserve.
        GLib.Set<string> upload_file_paths;
        foreach (SyncFileItemPtr it, sync_items) {
            if (it._direction == SyncFileItem.Direction.UP
                && it._type == ItemTypeFile
                && is_file_transfer_instruction (it._instruction)) {
                upload_file_paths.insert (it._file);
            }
        }

        // Delete from journal.
        var ids = this.journal.delete_stale_upload_infos (upload_file_paths);

        // Delete the stales chunk on the server.
        if (account ().capabilities ().chunking_ng ()) {
            foreach (uint32 transfer_id, ids) {
                if (!transfer_id)
                    continue; // Was not a chunked upload
                GLib.Uri url = Utility.concat_url_path (account ().url (), QLatin1String ("remote.php/dav/uploads/") + account ().dav_user () + '/' + string.number (transfer_id));
                (new DeleteJob (account (), url, this)).on_start ();
            }
        }
    }

    void SyncEngine.delete_stale_error_blocklist_entries (SyncFileItemVector sync_items) {
        // Find all blocklisted paths that we want to preserve.
        GLib.Set<string> blocklist_file_paths;
        foreach (SyncFileItemPtr it, sync_items) {
            if (it._has_blocklist_entry)
                blocklist_file_paths.insert (it._file);
        }

        // Delete from journal.
        this.journal.delete_stale_error_blocklist_entries (blocklist_file_paths);
    }

    #if (QT_VERSION < 0x050600)
    template <typename T>
    constexpr typename std.add_const<T>.type q_as_const (T t) noexcept {
        return t;
    }
    #endif

    void SyncEngine.conflict_record_maintenance () {
        // Remove stale conflict entries from the database
        // by checking which files still exist and removing the
        // missing ones.
        const var conflict_record_paths = this.journal.conflict_record_paths ();
        for (var path : conflict_record_paths) {
            var fs_path = this.propagator.full_local_path (string.from_utf8 (path));
            if (!QFileInfo (fs_path).exists ()) {
                this.journal.delete_conflict_record (path);
            }
        }

        // Did the sync see any conflict files that don't yet have records?
        // If so, add them now.
        //
        // This happens when the conflicts table is new or when conflict files
        // are downlaoded but the server doesn't send conflict headers.
        for (var path : q_as_const (this.seen_conflict_files)) {
            ASSERT (Utility.is_conflict_file (path));

            var bapath = path.to_utf8 ();
            if (!conflict_record_paths.contains (bapath)) {
                ConflictRecord record;
                record.path = bapath;
                var base_path = Utility.conflict_file_base_name_from_pattern (bapath);
                record.initial_base_path = base_path;

                // Determine fileid of target file
                SyncJournalFileRecord base_record;
                if (this.journal.get_file_record (base_path, base_record) && base_record.is_valid ()) {
                    record.base_file_id = base_record._file_id;
                }

                this.journal.set_conflict_record (record);
            }
        }
    }

    void Occ.SyncEngine.on_item_discovered (Occ.SyncFileItemPtr item) {
        if (Utility.is_conflict_file (item._file))
            this.seen_conflict_files.insert (item._file);
        if (item._instruction == CSYNC_INSTRUCTION_UPDATE_METADATA && !item.is_directory ()) {
            // For directories, metadata-only updates will be done after all their files are propagated.

            // Update the database now already :  New remote fileid or Etag or Remote_perm
            // Or for files that were detected as "resolved conflict".
            // Or a local inode/mtime change

            // In case of "resolved conflict" : there should have been a conflict because they
            // both were new, or both had their local mtime or remote etag modified, but the
            // size and mtime is the same on the server.  This typically happens when the
            // database is removed. Nothing will be done for those files, but we still need
            // to update the database.

            // This metadata update could* be a propagation job of its own, but since it's
            // quick to do and we don't want to create a potentially large number of
            // mini-jobs later on, we just update metadata right now.

            if (item._direction == SyncFileItem.Direction.DOWN) {
                string file_path = this.local_path + item._file;

                // If the 'W' remote permission changed, update the local filesystem
                SyncJournalFileRecord prev;
                if (this.journal.get_file_record (item._file, prev)
                    && prev.is_valid ()
                    && prev._remote_perm.has_permission (RemotePermissions.Can_write) != item._remote_perm.has_permission (RemotePermissions.Can_write)) {
                    const bool is_read_only = !item._remote_perm.is_null () && !item._remote_perm.has_permission (RemotePermissions.Can_write);
                    FileSystem.set_file_read_only_weak (file_path, is_read_only);
                }
                var record = item.to_sync_journal_file_record_with_inode (file_path);
                if (record._checksum_header.is_empty ())
                    record._checksum_header = prev._checksum_header;
                record._server_has_ignored_files |= prev._server_has_ignored_files;

                // Ensure it's a placeholder file on disk
                if (item._type == ItemTypeFile) {
                    const var result = this.sync_options._vfs.convert_to_placeholder (file_path, *item);
                    if (!result) {
                        item._instruction = CSYNC_INSTRUCTION_ERROR;
                        item._error_string = _("Could not update file : %1").arg (result.error ());
                        return;
                    }
                }

                // Update on-disk virtual file metadata
                if (item._type == ItemTypeVirtualFile) {
                    var r = this.sync_options._vfs.update_metadata (file_path, item._modtime, item._size, item._file_id);
                    if (!r) {
                        item._instruction = CSYNC_INSTRUCTION_ERROR;
                        item._error_string = _("Could not update virtual file metadata : %1").arg (r.error ());
                        return;
                    }
                }

                // Updating the database happens on on_success
                this.journal.set_file_record (record);

                // This might have changed the shared flag, so we must notify SyncFileStatusTracker for example
                /* emit */ item_completed (item);
            } else {
                // Update only outdated data from the disk.
                this.journal.update_local_metadata (item._file, item._modtime, item._size, item._inode);
            }
            this.has_none_files = true;
            return;
        } else if (item._instruction == CSYNC_INSTRUCTION_NONE) {
            this.has_none_files = true;
            if (this.account.capabilities ().upload_conflict_files () && Utility.is_conflict_file (item._file)) {
                // For uploaded conflict files, files with no action performed on them should
                // be displayed : but we mustn't overwrite the instruction if something happens
                // to the file!
                item._error_string = _("Unresolved conflict.");
                item._instruction = CSYNC_INSTRUCTION_IGNORE;
                item._status = SyncFileItem.Status.CONFLICT;
            }
            return;
        } else if (item._instruction == CSYNC_INSTRUCTION_REMOVE && !item._is_selective_sync) {
            this.has_remove_file = true;
        } else if (item._instruction == CSYNC_INSTRUCTION_RENAME) {
            this.has_none_files = true; // If a file (or every file) has been renamed, it means not al files where deleted
        } else if (item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE
            || item._instruction == CSYNC_INSTRUCTION_SYNC) {
            if (item._direction == SyncFileItem.Direction.UP) {
                // An upload of an existing file means that the file was left unchanged on the server
                // This counts as a NONE for detecting if all the files on the server were changed
                this.has_none_files = true;
            }
        }

        // check for blocklisting of this item.
        // if the item is on blocklist, the instruction was set to ERROR
        check_error_blocklisting (*item);
        this.needs_update = true;

        // Insert sorted
        var it = std.lower_bound ( this.sync_items.begin (), this.sync_items.end (), item ); // the this.sync_items is sorted
        this.sync_items.insert ( it, item );

        on_new_item (item);

        if (item.is_directory ()) {
            on_folder_discovered (item._etag.is_empty (), item._file);
        }
    }

    void SyncEngine.on_start_sync () {
        if (this.journal.exists ()) {
            GLib.Vector<SyncJournalDb.PollInfo> poll_infos = this.journal.get_poll_infos ();
            if (!poll_infos.is_empty ()) {
                q_c_info (lc_engine) << "Finish Poll jobs before starting a sync";
                var job = new CleanupPollsJob (poll_infos, this.account,
                    this.journal, this.local_path, this.sync_options._vfs, this);
                connect (job, &CleanupPollsJob.on_finished, this, &SyncEngine.on_start_sync);
                connect (job, &CleanupPollsJob.aborted, this, &SyncEngine.on_clean_polls_job_aborted);
                job.on_start ();
                return;
            }
        }

        if (s_any_sync_running || this.sync_running) {
            ASSERT (false)
            return;
        }

        s_any_sync_running = true;
        this.sync_running = true;
        this.another_sync_needed = No_follow_up_sync;
        this.clear_touched_files_timer.stop ();

        this.has_none_files = false;
        this.has_remove_file = false;
        this.seen_conflict_files.clear ();

        this.progress_info.on_reset ();

        if (!QDir (this.local_path).exists ()) {
            this.another_sync_needed = DelayedFollowUp;
            // No this.tr, it should only occur in non-mirall
            Q_EMIT sync_error (QStringLiteral ("Unable to find local sync folder."));
            on_finalize (false);
            return;
        }

        // Check free size on disk first.
        const int64 min_free = critical_free_space_limit ();
        const int64 free_bytes = Utility.free_disk_space (this.local_path);
        if (free_bytes >= 0) {
            if (free_bytes < min_free) {
                GLib.warn (lc_engine ()) << "Too little space available at" << this.local_path << ". Have"
                                      << free_bytes << "bytes and require at least" << min_free << "bytes";
                this.another_sync_needed = DelayedFollowUp;
                Q_EMIT sync_error (_("Only %1 are available, need at least %2 to on_start",
                    "Placeholders are postfixed with file sizes using Utility.octets_to_""")
                                     .arg (
                                         Utility.octets_to_string (free_bytes),
                                         Utility.octets_to_string (min_free)));
                on_finalize (false);
                return;
            } else {
                q_c_info (lc_engine) << "There are" << free_bytes << "bytes available at" << this.local_path;
            }
        } else {
            GLib.warn (lc_engine) << "Could not determine free space available at" << this.local_path;
        }

        this.sync_items.clear ();
        this.needs_update = false;

        if (!this.journal.exists ()) {
            q_c_info (lc_engine) << "New sync (no sync journal exists)";
        } else {
            q_c_info (lc_engine) << "Sync with existing sync journal";
        }

        string ver_str ("Using Qt ");
        ver_str.append (q_version ());

        ver_str.append (" SSL library ").append (QSslSocket.ssl_library_version_"".to_utf8 ().data ());
        ver_str.append (" on ").append (Utility.platform_name ());
        q_c_info (lc_engine) << ver_str;

        // This creates the DB if it does not exist yet.
        if (!this.journal.open ()) {
            GLib.warn (lc_engine) << "No way to create a sync journal!";
            Q_EMIT sync_error (_("Unable to open or create the local sync database. Make sure you have write access in the sync folder."));
            on_finalize (false);
            return;
            // database creation error!
        }

        // Functionality like selective sync might have set up etag storage
        // filtering via schedule_path_for_remote_discovery (). This is* the next sync, so
        // undo the filter to allow this sync to retrieve and store the correct etags.
        this.journal.clear_etag_storage_filter ();

        this.excluded_files.set_exclude_conflict_files (!this.account.capabilities ().upload_conflict_files ());

        this.last_local_discovery_style = this.local_discovery_style;

        if (this.sync_options._vfs.mode () == Vfs.WithSuffix && this.sync_options._vfs.file_suffix ().is_empty ()) {
            Q_EMIT sync_error (_("Using virtual files with suffix, but suffix is not set"));
            on_finalize (false);
            return;
        }

        bool ok = false;
        var selective_sync_block_list = this.journal.get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok);
        if (ok) {
            bool using_selective_sync = (!selective_sync_block_list.is_empty ());
            q_c_info (lc_engine) << (using_selective_sync ? "Using Selective Sync" : "NOT Using Selective Sync");
        } else {
            GLib.warn (lc_engine) << "Could not retrieve selective sync list from DB";
            Q_EMIT sync_error (_("Unable to read the blocklist from the local database"));
            on_finalize (false);
            return;
        }

        this.stop_watch.on_start ();
        this.progress_info._status = ProgressInfo.Starting;
        /* emit */ transmission_progress (*this.progress_info);

        q_c_info (lc_engine) << "#### Discovery on_start ####################################################";
        q_c_info (lc_engine) << "Server" << account ().server_version ()
                         << (account ().is_http2Supported () ? "Using HTTP/2" : "");
        this.progress_info._status = ProgressInfo.Discovery;
        /* emit */ transmission_progress (*this.progress_info);

        this.discovery_phase.on_reset (new DiscoveryPhase);
        this.discovery_phase._account = this.account;
        this.discovery_phase._excludes = this.excluded_files.data ();
        const string exclude_file_path = this.local_path + QStringLiteral (".sync-exclude.lst");
        if (GLib.File.exists (exclude_file_path)) {
            this.discovery_phase._excludes.add_exclude_file_path (exclude_file_path);
            this.discovery_phase._excludes.on_reload_exclude_files ();
        }
        this.discovery_phase._statedatabase = this.journal;
        this.discovery_phase._local_dir = this.local_path;
        if (!this.discovery_phase._local_dir.ends_with ('/'))
            this.discovery_phase._local_dir+='/';
        this.discovery_phase._remote_folder = this.remote_path;
        if (!this.discovery_phase._remote_folder.ends_with ('/'))
            this.discovery_phase._remote_folder+='/';
        this.discovery_phase._sync_options = this.sync_options;
        this.discovery_phase._should_discover_localy = [this] (string s) {
            return should_discover_locally (s);
        };
        this.discovery_phase.set_selective_sync_block_list (selective_sync_block_list);
        this.discovery_phase.set_selective_sync_allow_list (this.journal.get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST, ok));
        if (!ok) {
            GLib.warn (lc_engine) << "Unable to read selective sync list, aborting.";
            Q_EMIT sync_error (_("Unable to read from the sync journal."));
            on_finalize (false);
            return;
        }

        // Check for invalid character in old server version
        string invalid_filename_pattern = this.account.capabilities ().invalid_filename_regex ();
        if (invalid_filename_pattern.is_null ()
            && this.account.server_version_int () < Account.make_server_version (8, 1, 0)) {
            // Server versions older than 8.1 don't support some characters in filenames.
            // If the capability is not set, default to a pattern that avoids uploading
            // files with names that contain these.
            // It's important to respect the capability also for older servers -- the
            // version check doesn't make sense for custom servers.
            invalid_filename_pattern = R" ([\\:?*\"<>|])";
        }
        if (!invalid_filename_pattern.is_empty ())
            this.discovery_phase._invalid_filename_rx = QRegularExpression (invalid_filename_pattern);
        this.discovery_phase._server_blocklisted_files = this.account.capabilities ().blocklisted_files ();
        this.discovery_phase._ignore_hidden_files = ignore_hidden_files ();

        connect (this.discovery_phase.data (), &DiscoveryPhase.item_discovered, this, &SyncEngine.on_item_discovered);
        connect (this.discovery_phase.data (), &DiscoveryPhase.new_big_folder, this, &SyncEngine.new_big_folder);
        connect (this.discovery_phase.data (), &DiscoveryPhase.fatal_error, this, [this] (string error_string) {
            Q_EMIT sync_error (error_string);
            on_finalize (false);
        });
        connect (this.discovery_phase.data (), &DiscoveryPhase.on_finished, this, &SyncEngine.on_discovery_finished);
        connect (this.discovery_phase.data (), &DiscoveryPhase.silently_excluded,
            this.sync_file_status_tracker.data (), &SyncFileStatusTracker.on_add_silently_excluded);

        var discovery_job = new ProcessDirectoryJob (
            this.discovery_phase.data (), PinState.PinState.ALWAYS_LOCAL, this.journal.key_value_store_get_int ("last_sync", 0), this.discovery_phase.data ());
        this.discovery_phase.start_job (discovery_job);
        connect (discovery_job, &ProcessDirectoryJob.etag, this, &SyncEngine.on_root_etag_received);
        connect (this.discovery_phase.data (), &DiscoveryPhase.add_error_to_gui, this, &SyncEngine.add_error_to_gui);
    }

    void SyncEngine.on_folder_discovered (bool local, string folder) {
        // Don't wanna overload the UI
        if (!this.last_update_progress_callback_call.is_valid () || this.last_update_progress_callback_call.elapsed () >= 200) {
            this.last_update_progress_callback_call.on_start (); // first call or enough elapsed time
        } else {
            return;
        }

        if (local) {
            this.progress_info._current_discovered_local_folder = folder;
            this.progress_info._current_discovered_remote_folder.clear ();
        } else {
            this.progress_info._current_discovered_remote_folder = folder;
            this.progress_info._current_discovered_local_folder.clear ();
        }
        /* emit */ transmission_progress (*this.progress_info);
    }

    void SyncEngine.on_root_etag_received (GLib.ByteArray e, GLib.DateTime time) {
        if (this.remote_root_etag.is_empty ()) {
            GLib.debug (lc_engine) << "Root etag:" << e;
            this.remote_root_etag = e;
            /* emit */ root_etag (this.remote_root_etag, time);
        }
    }

    void SyncEngine.on_new_item (SyncFileItemPtr item) {
        this.progress_info.adjust_totals_for_file (*item);
    }

    void SyncEngine.on_discovery_finished () {
        if (!this.discovery_phase) {
            // There was an error that was already taken care of
            return;
        }

        q_c_info (lc_engine) << "#### Discovery end #################################################### " << this.stop_watch.add_lap_time (QLatin1String ("Discovery Finished")) << "ms";

        // Sanity check
        if (!this.journal.open ()) {
            GLib.warn (lc_engine) << "Bailing out, DB failure";
            Q_EMIT sync_error (_("Cannot open the sync journal"));
            on_finalize (false);
            return;
        } else {
            // Commits a possibly existing (should not though) transaction and starts a new one for the propagate phase
            this.journal.commit_if_needed_and_start_new_transaction ("Post discovery");
        }

        this.progress_info._current_discovered_remote_folder.clear ();
        this.progress_info._current_discovered_local_folder.clear ();
        this.progress_info._status = ProgressInfo.Reconcile;
        /* emit */ transmission_progress (*this.progress_info);

        //    q_c_info (lc_engine) << "Permissions of the root folder : " << this.csync_ctx.remote.root_perms.to_"";
        var finish = [this]{
            var database_fingerprint = this.journal.data_fingerprint ();
            // If database_fingerprint is empty, this means that there was no information in the database
            // (for example, upgrading from a previous version, or first sync, or server not supporting fingerprint)
            if (!database_fingerprint.is_empty () && this.discovery_phase
                && this.discovery_phase._data_fingerprint != database_fingerprint) {
                q_c_info (lc_engine) << "data fingerprint changed, assume restore from backup" << database_fingerprint << this.discovery_phase._data_fingerprint;
                restore_old_files (this.sync_items);
            }

            if (this.discovery_phase._another_sync_needed && this.another_sync_needed == No_follow_up_sync) {
                this.another_sync_needed = Immediate_follow_up;
            }

            Q_ASSERT (std.is_sorted (this.sync_items.begin (), this.sync_items.end ()));

            q_c_info (lc_engine) << "#### Reconcile (about_to_propagate) #################################################### " << this.stop_watch.add_lap_time (QStringLiteral ("Reconcile (about_to_propagate)")) << "ms";

            this.local_discovery_paths.clear ();

            // To announce the beginning of the sync
            /* emit */ about_to_propagate (this.sync_items);

            q_c_info (lc_engine) << "#### Reconcile (about_to_propagate OK) #################################################### "<< this.stop_watch.add_lap_time (QStringLiteral ("Reconcile (about_to_propagate OK)")) << "ms";

            // it's important to do this before ProgressInfo.on_start (), to announce on_start of new sync
            this.progress_info._status = ProgressInfo.Propagation;
            /* emit */ transmission_progress (*this.progress_info);
            this.progress_info.start_estimate_updates ();

            // post update phase script : allow to tweak stuff by a custom script in debug mode.
            if (!q_environment_variable_is_empty ("OWNCLOUD_POST_UPDATE_SCRIPT")) {
        #ifndef NDEBUG
                const string script = q_environment_variable ("OWNCLOUD_POST_UPDATE_SCRIPT");

                GLib.debug (lc_engine) << "Post Update Script : " << script;
                var script_args = script.split (QRegularExpression ("\\s+"), Qt.Skip_empty_parts);
                if (script_args.size () > 0) {
                    const var script_executable = script_args.take_first ();
                    QProcess.execute (script_executable, script_args);
                }
    #else
                GLib.warn (lc_engine) << "**** Attention : POST_UPDATE_SCRIPT installed, but not executed because compiled with NDEBUG";
        #endif
            }

            // do a database commit
            this.journal.commit (QStringLiteral ("post treewalk"));

            this.propagator = unowned<OwncloudPropagator> (
                new OwncloudPropagator (this.account, this.local_path, this.remote_path, this.journal, this.bulk_upload_block_list));
            this.propagator.set_sync_options (this.sync_options);
            connect (this.propagator.data (), &OwncloudPropagator.item_completed,
                this, &SyncEngine.on_item_completed);
            connect (this.propagator.data (), &OwncloudPropagator.progress,
                this, &SyncEngine.on_progress);
            connect (this.propagator.data (), &OwncloudPropagator.on_finished, this, &SyncEngine.on_propagation_finished, Qt.QueuedConnection);
            connect (this.propagator.data (), &OwncloudPropagator.seen_locked_file, this, &SyncEngine.seen_locked_file);
            connect (this.propagator.data (), &OwncloudPropagator.touched_file, this, &SyncEngine.on_add_touched_file);
            connect (this.propagator.data (), &OwncloudPropagator.insufficient_local_storage, this, &SyncEngine.on_insufficient_local_storage);
            connect (this.propagator.data (), &OwncloudPropagator.insufficient_remote_storage, this, &SyncEngine.on_insufficient_remote_storage);
            connect (this.propagator.data (), &OwncloudPropagator.new_item, this, &SyncEngine.on_new_item);

            // apply the network limits to the propagator
            set_network_limits (this.upload_limit, this.download_limit);

            delete_stale_download_infos (this.sync_items);
            delete_stale_upload_infos (this.sync_items);
            delete_stale_error_blocklist_entries (this.sync_items);
            this.journal.commit (QStringLiteral ("post stale entry removal"));

            // Emit the started signal only after the propagator has been set up.
            if (this.needs_update)
                Q_EMIT started ();

            this.propagator.on_start (std.move (this.sync_items));

            q_c_info (lc_engine) << "#### Post-Reconcile end #################################################### " << this.stop_watch.add_lap_time (QStringLiteral ("Post-Reconcile Finished")) << "ms";
        };

        if (!this.has_none_files && this.has_remove_file) {
            q_c_info (lc_engine) << "All the files are going to be changed, asking the user";
            int side = 0; // > 0 means more deleted on the server.  < 0 means more deleted on the client
            foreach (var it, this.sync_items) {
                if (it._instruction == CSYNC_INSTRUCTION_REMOVE) {
                    side += it._direction == SyncFileItem.Direction.DOWN ? 1 : -1;
                }
            }

            QPointer<GLib.Object> guard = new GLib.Object ();
            QPointer<GLib.Object> self = this;
            var callback = [this, self, finish, guard] (bool cancel) . void {
                // use a guard to ensure its only called once...
                // qpointer to self to ensure we still exist
                if (!guard || !self) {
                    return;
                }
                guard.delete_later ();
                if (cancel) {
                    q_c_info (lc_engine) << "User aborted sync";
                    on_finalize (false);
                    return;
                } else {
                    finish ();
                }
            };
            /* emit */ about_to_remove_all_files (side >= 0 ? SyncFileItem.Direction.DOWN : SyncFileItem.Direction.UP, callback);
            return;
        }
        finish ();
    }

    void SyncEngine.on_clean_polls_job_aborted (string error) {
        sync_error (error);
        on_finalize (false);
    }

    void SyncEngine.set_network_limits (int upload, int download) {
        this.upload_limit = upload;
        this.download_limit = download;

        if (!this.propagator)
            return;

        this.propagator._upload_limit = upload;
        this.propagator._download_limit = download;

        if (upload != 0 || download != 0) {
            q_c_info (lc_engine) << "Network Limits (down/up) " << upload << download;
        }
    }

    void SyncEngine.on_item_completed (SyncFileItemPtr item) {
        this.progress_info.set_progress_complete (*item);

        /* emit */ transmission_progress (*this.progress_info);
        /* emit */ item_completed (item);
    }

    void SyncEngine.on_propagation_finished (bool on_success) {
        if (this.propagator._another_sync_needed && this.another_sync_needed == No_follow_up_sync) {
            this.another_sync_needed = Immediate_follow_up;
        }

        if (on_success && this.discovery_phase) {
            this.journal.set_data_fingerprint (this.discovery_phase._data_fingerprint);
        }

        conflict_record_maintenance ();

        this.journal.delete_stale_flags_entries ();
        this.journal.commit ("All Finished.", false);

        // Send final progress information even if no
        // files needed propagation, but clear the last_completed_item
        // so we don't count this twice (like Recent Files)
        this.progress_info._last_completed_item = SyncFileItem ();
        this.progress_info._status = ProgressInfo.Done;
        /* emit */ transmission_progress (*this.progress_info);

        on_finalize (on_success);
    }

    void SyncEngine.on_finalize (bool on_success) {
        q_c_info (lc_engine) << "Sync run took " << this.stop_watch.add_lap_time (QLatin1String ("Sync Finished")) << "ms";
        this.stop_watch.stop ();

        if (this.discovery_phase) {
            this.discovery_phase.take ().delete_later ();
        }
        s_any_sync_running = false;
        this.sync_running = false;
        /* emit */ finished (on_success);

        // Delete the propagator only after emitting the signal.
        this.propagator.clear ();
        this.seen_conflict_files.clear ();
        this.unique_errors.clear ();
        this.local_discovery_paths.clear ();
        this.local_discovery_style = LocalDiscoveryStyle.FilesystemOnly;

        this.clear_touched_files_timer.on_start ();
    }

    void SyncEngine.on_progress (SyncFileItem item, int64 current) {
        this.progress_info.set_progress_item (item, current);
        /* emit */ transmission_progress (*this.progress_info);
    }


    /***********************************************************
    When the server is trying to send us lots of file in the
    past, this means that a backup was restored in the server.
    In that case, we should not simply overwrite the newer file
    on the file system with the older file from the backup on
    the server. Instead, we will upload the client file. But
    we still downloaded the old file in a conflict file just
    in case.
    ***********************************************************/
    void SyncEngine.restore_old_files (SyncFileItemVector sync_items) {

        for (var sync_item : q_as_const (sync_items)) {
            if (sync_item._direction != SyncFileItem.Direction.DOWN)
                continue;

            switch (sync_item._instruction) {
            case CSYNC_INSTRUCTION_SYNC:
                GLib.warn (lc_engine) << "restore_old_files : RESTORING" << sync_item._file;
                sync_item._instruction = CSYNC_INSTRUCTION_CONFLICT;
                break;
            case CSYNC_INSTRUCTION_REMOVE:
                GLib.warn (lc_engine) << "restore_old_files : RESTORING" << sync_item._file;
                sync_item._instruction = CSYNC_INSTRUCTION_NEW;
                sync_item._direction = SyncFileItem.Direction.UP;
                break;
            case CSYNC_INSTRUCTION_RENAME:
            case CSYNC_INSTRUCTION_NEW:
                // Ideally we should try to revert the rename or remove, but this would be dangerous
                // without re-doing the reconcile phase.  So just let it happen.
            default:
                break;
            }
        }
    }

    void SyncEngine.on_add_touched_file (string fn) {
        QElapsedTimer now;
        now.on_start ();
        string file = QDir.clean_path (fn);

        // Iterate from the oldest and remove anything older than 15 seconds.
        while (true) {
            var first = this.touched_files.begin ();
            if (first == this.touched_files.end ())
                break;
            // Compare to our new QElapsedTimer instead of using elapsed ().
            // This avoids querying the current time from the OS for every loop.
            var elapsed = std.chrono.milliseconds (now.msecs_since_reference () - first.key ().msecs_since_reference ());
            if (elapsed <= s_touched_files_max_age_ms) {
                // We found the first path younger than the maximum age, keep the rest.
                break;
            }

            this.touched_files.erase (first);
        }

        // This should be the largest QElapsedTimer yet, use const_end () as hint.
        this.touched_files.insert (this.touched_files.const_end (), now, file);
    }

    void SyncEngine.on_clear_touched_files () {
        this.touched_files.clear ();
    }

    bool SyncEngine.was_file_touched (string fn) {
        // Start from the end (most recent) and look for our path. Check the time just in case.
        var begin = this.touched_files.const_begin ();
        for (var it = this.touched_files.const_end (); it != begin; --it) {
            if ( (it-1).value () == fn)
                return std.chrono.milliseconds ( (it-1).key ().elapsed ()) <= s_touched_files_max_age_ms;
        }
        return false;
    }

    AccountPointer SyncEngine.account () {
        return this.account;
    }

    void SyncEngine.set_local_discovery_options (LocalDiscoveryStyle style, std.set<string> paths) {
        this.local_discovery_style = style;
        this.local_discovery_paths = std.move (paths);

        // Normalize to make sure that no path is a contained in another.
        // Note: for simplicity, this code consider anything less than '/' as a path separator, so for
        // example, this will remove "foo.bar" if "foo" is in the list. This will mean we might have
        // some false positive, but that's Ok.
        // This invariant is used in SyncEngine.should_discover_locally
        string prev;
        var it = this.local_discovery_paths.begin ();
        while (it != this.local_discovery_paths.end ()) {
            if (!prev.is_null () && it.starts_with (prev) && (prev.ends_with ('/') || *it == prev || it.at (prev.size ()) <= '/')) {
                it = this.local_discovery_paths.erase (it);
            } else {
                prev = *it;
                ++it;
            }
        }
    }

    bool SyncEngine.should_discover_locally (string path) {
        if (this.local_discovery_style == LocalDiscoveryStyle.FilesystemOnly)
            return true;

        // The intention is that if "A/X" is in this.local_discovery_paths:
        // - parent folders like "/", "A" will be discovered (to make sure the discovery reaches the
        //   point where something new happened)
        // - the folder itself "A/X" will be discovered
        // - subfolders like "A/X/Y" will be discovered (so data inside a new or renamed folder will be
        //   discovered in full)
        // Check out Test_local_discovery.test_local_discovery_decision ()

        var it = this.local_discovery_paths.lower_bound (path);
        if (it == this.local_discovery_paths.end () || !it.starts_with (path)) {
            // Maybe a subfolder of something in the list?
            if (it != this.local_discovery_paths.begin () && path.starts_with (* (--it))) {
                return it.ends_with ('/') || (path.size () > it.size () && path.at (it.size ()) <= '/');
            }
            return false;
        }

        // maybe an exact match or an empty path?
        if (it.size () == path.size () || path.is_empty ())
            return true;

        // Maybe a parent folder of something in the list?
        // check for a prefix + / match
        forever {
            if (it.size () > path.size () && it.at (path.size ()) == '/')
                return true;
            ++it;
            if (it == this.local_discovery_paths.end () || !it.starts_with (path))
                return false;
        }
        return false;
    }

    void SyncEngine.wipe_virtual_files (string local_path, SyncJournalDb journal, Vfs vfs) {
        q_c_info (lc_engine) << "Wiping virtual files inside" << local_path;
        journal.get_files_below_path (GLib.ByteArray (), [&] (SyncJournalFileRecord record) {
            if (record._type != ItemTypeVirtualFile && record._type != ItemTypeVirtualFileDownload)
                return;

            GLib.debug (lc_engine) << "Removing database record for" << record.path ();
            journal.delete_file_record (record._path);

            // If the local file is a dehydrated placeholder, wipe it too.
            // Otherwise leave it to allow the next sync to have a new-new conflict.
            string local_file = local_path + record._path;
            if (GLib.File.exists (local_file) && vfs.is_dehydrated_placeholder (local_file)) {
                GLib.debug (lc_engine) << "Removing local dehydrated placeholder" << record.path ();
                GLib.File.remove (local_file);
            }
        });

        journal.force_remote_discovery_next_sync ();

        // Postcondition : No ItemTypeVirtualFile / ItemTypeVirtualFileDownload left in the database.
        // But hydrated placeholders may still be around.
    }

    void SyncEngine.switch_to_virtual_files (string local_path, SyncJournalDb journal, Vfs vfs) {
        q_c_info (lc_engine) << "Convert to virtual files inside" << local_path;
        journal.get_files_below_path ({}, [&] (SyncJournalFileRecord record) {
            const var path = record.path ();
            const var filename = QFileInfo (path).filename ();
            if (FileSystem.is_exclude_file (filename)) {
                return;
            }
            SyncFileItem item;
            string local_file = local_path + path;
            const var result = vfs.convert_to_placeholder (local_file, item, local_file);
            if (!result.is_valid ()) {
                GLib.warn (lc_engine) << "Could not convert file to placeholder" << result.error ();
            }
        });
    }

    void SyncEngine.on_abort () {
        if (this.propagator)
            q_c_info (lc_engine) << "Aborting sync";

        if (this.propagator) {
            // If we're already in the propagation phase, aborting that is sufficient
            this.propagator.on_abort ();
        } else if (this.discovery_phase) {
            // Delete the discovery and all child jobs after ensuring
            // it can't finish and on_start the propagator
            disconnect (this.discovery_phase.data (), nullptr, this, nullptr);
            this.discovery_phase.take ().delete_later ();

            Q_EMIT sync_error (_("Synchronization will resume shortly."));
            on_finalize (false);
        }
    }

    void SyncEngine.on_summary_error (string message) {
        if (this.unique_errors.contains (message))
            return;

        this.unique_errors.insert (message);
        /* emit */ sync_error (message, ErrorCategory.Normal);
    }

    void SyncEngine.on_insufficient_local_storage () {
        on_summary_error (
            _("Disk space is low : Downloads that would reduce free space "
               "below %1 were skipped.")
                .arg (Utility.octets_to_string (free_space_limit ())));
    }

    void SyncEngine.on_insufficient_remote_storage () {
        var msg = _("There is insufficient space available on the server for some uploads.");
        if (this.unique_errors.contains (msg))
            return;

        this.unique_errors.insert (msg);
        /* emit */ sync_error (msg, ErrorCategory.InsufficientRemoteStorage);
    }

    } // namespace Occ
    