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
// #include <QSsl_socket>
// #include <QDir>
// #include <QLoggingCategory>
// #include <QMutexLocker>
// #include <QThread>
// #include <QStringList>
// #include <QTextStream>
// #include <QTime>
// #include <QUrl>
// #include <QSslCertificate>
// #include <QProcess>
// #include <QElapsedTimer>
// #include <QFileInfo>
// #include <qtextcodec.h>

// #pragma once

// #include <cstdint>

// #include <QMutex>
// #include <QThread>
// #include <string>
// #include <QSet>
// #include <QMap>
// #include <QStringList>
// #include <QSharedPointer>
// #include <set>


namespace Occ {

class Process_directory_job;

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
public:
    SyncEngine (AccountPtr account, string &local_path,
        const string &remote_path, SyncJournalDb *journal);
    ~SyncEngine () override;

    Q_INVOKABLE void start_sync ();
    void set_network_limits (int upload, int download);

    /***********************************************************
    Abort the sync. Called from the main thread.
    ***********************************************************/
    void abort ();

    bool is_sync_running () {
        return _sync_running;
    }

    Sync_options sync_options () {
        return _sync_options;
    }
    void set_sync_options (Sync_options &options) {
        _sync_options = options;
    }
    bool ignore_hidden_files () {
        return _ignore_hidden_files;
    }
    void set_ignore_hidden_files (bool ignore) {
        _ignore_hidden_files = ignore;
    }

    Excluded_files &excluded_files () {
        return *_excluded_files;
    }
    Utility.StopWatch &stop_watch () {
        return _stop_watch;
    }
    SyncFileStatusTracker &sync_file_status_tracker () {
        return *_sync_file_status_tracker;
    }

    /***********************************************************
    Returns whether another sync is needed to complete the sync
    ***********************************************************/
    Another_sync_needed is_another_sync_needed () {
        return _another_sync_needed;
    }

    bool was_file_touched (string &fn) const;

    AccountPtr account ();
    SyncJournalDb *journal () {
        return _journal;
    }
    string local_path () {
        return _local_path;
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
    static std.chrono.milliseconds minimum_file_age_for_upload;

    /***********************************************************
    Control whether local discovery should read from filesystem or db.

    If style is Database_and_filesystem, paths a set of file paths relative
    the synced folder. All the parent directories of th
    be read from the db and scanned on the filesystem.

    Note, the style and paths are only retained for the next sync and
    revert afterwards. Use _last_local_discovery_style to discover the last
    sync's style.
    ***********************************************************/
    void set_local_discovery_options (Local_discovery_style style, std.set<string> paths = {});

    /***********************************************************
    Returns whether the given folder-relative path should be locally discovered
    given the local discovery options.

    Example : If path is 'foo/bar' and style is Database_and_filesystem and dirs contains
        'foo/bar/touched_file', then the result will be true.
    ***********************************************************/
    bool should_discover_locally (string &path) const;

    /***********************************************************
    Access the last sync run's local discovery style
    ***********************************************************/
    Local_discovery_style last_local_discovery_style () {
        return _last_local_discovery_style;
    }

    /***********************************************************
    Removes all virtual file db entries and dehydrated local placeholders.

    Particularly useful when switching off vfs mode or switching to a
    different kind of vfs.

    Note that *hydrated* placeholder files might still be left. These will
    get cleaned up by Vfs.unregister_folder ().
    ***********************************************************/
    static void wipe_virtual_files (string &local_path, SyncJournalDb &journal, Vfs &vfs);

    static void switch_to_virtual_files (string &local_path, SyncJournalDb &journal, Vfs &vfs);

    // for the test
    auto get_propagator () {
        return _propagator;
    }

signals:
    // During update, before reconcile
    void root_etag (QByteArray &, QDateTime &);

    // after the above signals. with the items that actually need propagating
    void about_to_propagate (Sync_file_item_vector &);

    // after each item completed by a job (successful or not)
    void item_completed (SyncFileItemPtr &);

    void transmission_progress (ProgressInfo &progress);

    /// We've produced a new sync error of a type.
    void sync_error (string &message, ErrorCategory category = ErrorCategory.Normal);

    void add_error_to_gui (SyncFileItem.Status status, string &error_message, string &subject);

    void finished (bool success);
    void started ();

    /***********************************************************
    Emited when the sync engine detects that all the files have been removed or change.
    This usually happen when the server was reset or something.
    Set *cancel to true in a slot connected from this signal to abort the sync.
    ***********************************************************/
    void about_to_remove_all_files (SyncFileItem.Direction direction, std.function<void (bool)> f);

    // A new folder was discovered and was not synced because of the confirmation feature
    void new_big_folder (string &folder, bool is_external);

    /***********************************************************
    Emitted when propagation has problems with a locked file.

    Forwarded from Owncloud_propagator.seen_locked_file.
    ***********************************************************/
    void seen_locked_file (string &file_name);

private slots:
    void slot_folder_discovered (bool local, string &folder);
    void slot_root_etag_received (QByteArray &, QDateTime &time);

    /***********************************************************
    When the discovery phase discovers an item
    ***********************************************************/
    void slot_item_discovered (SyncFileItemPtr &item);

    /***********************************************************
    Called when a SyncFileItem gets accepted for a sync.

    Mostly done in initial creation inside treewalk_file but
    can also be called via the propagator for items that are
    created during propagation.
    ***********************************************************/
    void slot_new_item (SyncFileItemPtr &item);

    void slot_item_completed (SyncFileItemPtr &item);
    void slot_discovery_finished ();
    void slot_propagation_finished (bool success);
    void slot_progress (SyncFileItem &item, int64 curent);
    void slot_clean_polls_job_aborted (string &error);

    /***********************************************************
    Records that a file was touched by a job.
    ***********************************************************/
    void slot_add_touched_file (string &fn);

    /***********************************************************
    Wipes the _touched_files hash
    ***********************************************************/
    void slot_clear_touched_files ();

    /***********************************************************
    Emit a summary error, unless it was seen before
    ***********************************************************/
    void slot_summary_error (string &message);

    void slot_insufficient_local_storage ();
    void slot_insufficient_remote_storage ();

private:
    bool check_error_blacklisting (SyncFileItem &item);

    // Cleans up unnecessary downloadinfo entries in the journal as well
    // as their temporary files.
    void delete_stale_download_infos (Sync_file_item_vector &sync_items);

    // Removes stale uploadinfos from the journal.
    void delete_stale_upload_infos (Sync_file_item_vector &sync_items);

    // Removes stale error blacklist entries from the journal.
    void delete_stale_error_blacklist_entries (Sync_file_item_vector &sync_items);

    // Removes stale and adds missing conflict records after sync
    void conflict_record_maintenance ();

    // cleanup and emit the finished signal
    void finalize (bool success);

    static bool s_any_sync_running; //true when one sync is running somewhere (for debugging)

    // Must only be acessed during update and reconcile
    QVector<SyncFileItemPtr> _sync_items;

    AccountPtr _account;
    bool _needs_update;
    bool _sync_running;
    string _local_path;
    string _remote_path;
    QByteArray _remote_root_etag;
    SyncJournalDb *_journal;
    QScopedPointer<Discovery_phase> _discovery_phase;
    QSharedPointer<Owncloud_propagator> _propagator;

    QSet<string> _bulk_upload_black_list;

    // List of all files with conflicts
    QSet<string> _seen_conflict_files;

    QScopedPointer<ProgressInfo> _progress_info;

    QScopedPointer<Excluded_files> _excluded_files;
    QScopedPointer<SyncFileStatusTracker> _sync_file_status_tracker;
    Utility.StopWatch _stop_watch;

    /***********************************************************
    check if we are allowed to propagate everything, and if we are not, adjust the instructions
    to recover
    ***********************************************************/
    void check_for_permission (Sync_file_item_vector &sync_items);
    RemotePermissions get_permissions (string &file) const;

    /***********************************************************
    Instead of downloading files from the server, upload the files to the server
    ***********************************************************/
    void restore_old_files (Sync_file_item_vector &sync_items);

    // true if there is at least one file which was not changed on the server
    bool _has_none_files;

    // true if there is at leasr one file with instruction REMOVE
    bool _has_remove_file;

    // If ignored files should be ignored
    bool _ignore_hidden_files = false;

    int _upload_limit;
    int _download_limit;
    Sync_options _sync_options;

    Another_sync_needed _another_sync_needed;

    /***********************************************************
    Stores the time since a job touched a file.
    ***********************************************************/
    QMulti_map<QElapsedTimer, string> _touched_files;

    QElapsedTimer _last_update_progress_callback_call;

    /***********************************************************
    For clearing the _touched_files variable after sync finished
    ***********************************************************/
    QTimer _clear_touched_files_timer;

    /***********************************************************
    List of unique errors that occurred in a sync run.
    ***********************************************************/
    QSet<string> _unique_errors;

    /***********************************************************
    The kind of local discovery the last sync run used
    ***********************************************************/
    Local_discovery_style _last_local_discovery_style = Local_discovery_style.Filesystem_only;
    Local_discovery_style _local_discovery_style = Local_discovery_style.Filesystem_only;
    std.set<string> _local_discovery_paths;
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

    SyncEngine.SyncEngine (AccountPtr account, string &local_path,
        const string &remote_path, Occ.SyncJournalDb *journal)
        : _account (account)
        , _needs_update (false)
        , _sync_running (false)
        , _local_path (local_path)
        , _remote_path (remote_path)
        , _journal (journal)
        , _progress_info (new ProgressInfo)
        , _has_none_files (false)
        , _has_remove_file (false)
        , _upload_limit (0)
        , _download_limit (0)
        , _another_sync_needed (No_follow_up_sync) {
        q_register_meta_type<SyncFileItem> ("SyncFileItem");
        q_register_meta_type<SyncFileItemPtr> ("SyncFileItemPtr");
        q_register_meta_type<SyncFileItem.Status> ("SyncFileItem.Status");
        q_register_meta_type<SyncFileStatus> ("SyncFileStatus");
        q_register_meta_type<Sync_file_item_vector> ("Sync_file_item_vector");
        q_register_meta_type<SyncFileItem.Direction> ("SyncFileItem.Direction");

        // Everything in the SyncEngine expects a trailing slash for the local_path.
        ASSERT (local_path.ends_with (QLatin1Char ('/')));

        _excluded_files.reset (new Excluded_files (local_path));

        _sync_file_status_tracker.reset (new SyncFileStatusTracker (this));

        _clear_touched_files_timer.set_single_shot (true);
        _clear_touched_files_timer.set_interval (30 * 1000);
        connect (&_clear_touched_files_timer, &QTimer.timeout, this, &SyncEngine.slot_clear_touched_files);
        connect (this, &SyncEngine.finished, [this] (bool /* finished */) {
            _journal.key_value_store_set ("last_sync", QDateTime.current_secs_since_epoch ());
        });
    }

    SyncEngine.~SyncEngine () {
        abort ();
        _excluded_files.reset ();
    }

    /***********************************************************
    Check if the item is in the blacklist.
    If it should not be sync'ed because of the blacklist, update the item with the error instruction
    and proper error message, and return true.
    If the item is not in the blacklist, or the blacklist is stale, return false.
    ***********************************************************/
    bool SyncEngine.check_error_blacklisting (SyncFileItem &item) {
        if (!_journal) {
            q_c_critical (lc_engine) << "Journal is undefined!";
            return false;
        }

        SyncJournalErrorBlacklistRecord entry = _journal.error_blacklist_entry (item._file);
        item._has_blacklist_entry = false;

        if (!entry.is_valid ()) {
            return false;
        }

        item._has_blacklist_entry = true;

        // If duration has expired, it's not blacklisted anymore
        time_t now = Utility.q_date_time_to_time_t (QDateTime.current_date_time_utc ());
        if (now >= entry._last_try_time + entry._ignore_duration) {
            q_c_info (lc_engine) << "blacklist entry for " << item._file << " has expired!";
            return false;
        }

        // If the file has changed locally or on the server, the blacklist
        // entry no longer applies
        if (item._direction == SyncFileItem.Up) { // check the modtime
            if (item._modtime == 0 || entry._last_try_modtime == 0) {
                return false;
            } else if (item._modtime != entry._last_try_modtime) {
                q_c_info (lc_engine) << item._file << " is blacklisted, but has changed mtime!";
                return false;
            } else if (item._rename_target != entry._rename_target) {
                q_c_info (lc_engine) << item._file << " is blacklisted, but rename target changed from" << entry._rename_target;
                return false;
            }
        } else if (item._direction == SyncFileItem.Down) {
            // download, check the etag.
            if (item._etag.is_empty () || entry._last_try_etag.is_empty ()) {
                q_c_info (lc_engine) << item._file << "one ETag is empty, no blacklisting";
                return false;
            } else if (item._etag != entry._last_try_etag) {
                q_c_info (lc_engine) << item._file << " is blacklisted, but has changed etag!";
                return false;
            }
        }

        int64 wait_seconds = entry._last_try_time + entry._ignore_duration - now;
        q_c_info (lc_engine) << "Item is on blacklist : " << entry._file
                         << "retries:" << entry._retry_count
                         << "for another" << wait_seconds << "s";

        // We need to indicate that we skip this file due to blacklisting
        // for reporting and for making sure we don't update the blacklist
        // entry yet.
        // Classification is this _instruction and _status
        item._instruction = CSYNC_INSTRUCTION_IGNORE;
        item._status = SyncFileItem.Blacklisted_error;

        auto wait_seconds_str = Utility.duration_to_descriptive_string1 (1000 * wait_seconds);
        item._error_string = tr ("%1 (skipped due to earlier error, trying again in %2)").arg (entry._error_string, wait_seconds_str);

        if (entry._error_category == SyncJournalErrorBlacklistRecord.Insufficient_remote_storage) {
            slot_insufficient_remote_storage ();
        }

        return true;
    }

    static bool is_file_transfer_instruction (Sync_instructions instruction) {
        return instruction == CSYNC_INSTRUCTION_CONFLICT
            || instruction == CSYNC_INSTRUCTION_NEW
            || instruction == CSYNC_INSTRUCTION_SYNC
            || instruction == CSYNC_INSTRUCTION_TYPE_CHANGE;
    }

    void SyncEngine.delete_stale_download_infos (Sync_file_item_vector &sync_items) {
        // Find all downloadinfo paths that we want to preserve.
        QSet<string> download_file_paths;
        foreach (SyncFileItemPtr &it, sync_items) {
            if (it._direction == SyncFileItem.Down
                && it._type == ItemTypeFile
                && is_file_transfer_instruction (it._instruction)) {
                download_file_paths.insert (it._file);
            }
        }

        // Delete from journal and from filesystem.
        const QVector<SyncJournalDb.DownloadInfo> deleted_infos =
            _journal.get_and_delete_stale_download_infos (download_file_paths);
        foreach (SyncJournalDb.DownloadInfo &deleted_info, deleted_infos) {
            const string tmppath = _propagator.full_local_path (deleted_info._tmpfile);
            q_c_info (lc_engine) << "Deleting stale temporary file : " << tmppath;
            FileSystem.remove (tmppath);
        }
    }

    void SyncEngine.delete_stale_upload_infos (Sync_file_item_vector &sync_items) {
        // Find all blacklisted paths that we want to preserve.
        QSet<string> upload_file_paths;
        foreach (SyncFileItemPtr &it, sync_items) {
            if (it._direction == SyncFileItem.Up
                && it._type == ItemTypeFile
                && is_file_transfer_instruction (it._instruction)) {
                upload_file_paths.insert (it._file);
            }
        }

        // Delete from journal.
        auto ids = _journal.delete_stale_upload_infos (upload_file_paths);

        // Delete the stales chunk on the server.
        if (account ().capabilities ().chunking_ng ()) {
            foreach (uint transfer_id, ids) {
                if (!transfer_id)
                    continue; // Was not a chunked upload
                QUrl url = Utility.concat_url_path (account ().url (), QLatin1String ("remote.php/dav/uploads/") + account ().dav_user () + QLatin1Char ('/') + string.number (transfer_id));
                (new DeleteJob (account (), url, this)).start ();
            }
        }
    }

    void SyncEngine.delete_stale_error_blacklist_entries (Sync_file_item_vector &sync_items) {
        // Find all blacklisted paths that we want to preserve.
        QSet<string> blacklist_file_paths;
        foreach (SyncFileItemPtr &it, sync_items) {
            if (it._has_blacklist_entry)
                blacklist_file_paths.insert (it._file);
        }

        // Delete from journal.
        _journal.delete_stale_error_blacklist_entries (blacklist_file_paths);
    }

    #if (QT_VERSION < 0x050600)
    template <typename T>
    constexpr typename std.add_const<T>.type &q_as_const (T &t) noexcept {
        return t;
    }
    #endif

    void SyncEngine.conflict_record_maintenance () {
        // Remove stale conflict entries from the database
        // by checking which files still exist and removing the
        // missing ones.
        const auto conflict_record_paths = _journal.conflict_record_paths ();
        for (auto &path : conflict_record_paths) {
            auto fs_path = _propagator.full_local_path (string.from_utf8 (path));
            if (!QFileInfo (fs_path).exists ()) {
                _journal.delete_conflict_record (path);
            }
        }

        // Did the sync see any conflict files that don't yet have records?
        // If so, add them now.
        //
        // This happens when the conflicts table is new or when conflict files
        // are downlaoded but the server doesn't send conflict headers.
        for (auto &path : q_as_const (_seen_conflict_files)) {
            ASSERT (Utility.is_conflict_file (path));

            auto bapath = path.to_utf8 ();
            if (!conflict_record_paths.contains (bapath)) {
                Conflict_record record;
                record.path = bapath;
                auto base_path = Utility.conflict_file_base_name_from_pattern (bapath);
                record.initial_base_path = base_path;

                // Determine fileid of target file
                SyncJournalFileRecord base_record;
                if (_journal.get_file_record (base_path, &base_record) && base_record.is_valid ()) {
                    record.base_file_id = base_record._file_id;
                }

                _journal.set_conflict_record (record);
            }
        }
    }

    void Occ.SyncEngine.slot_item_discovered (Occ.SyncFileItemPtr &item) {
        if (Utility.is_conflict_file (item._file))
            _seen_conflict_files.insert (item._file);
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

            // This metadata update *could* be a propagation job of its own, but since it's
            // quick to do and we don't want to create a potentially large number of
            // mini-jobs later on, we just update metadata right now.

            if (item._direction == SyncFileItem.Down) {
                string file_path = _local_path + item._file;

                // If the 'W' remote permission changed, update the local filesystem
                SyncJournalFileRecord prev;
                if (_journal.get_file_record (item._file, &prev)
                    && prev.is_valid ()
                    && prev._remote_perm.has_permission (RemotePermissions.Can_write) != item._remote_perm.has_permission (RemotePermissions.Can_write)) {
                    const bool is_read_only = !item._remote_perm.is_null () && !item._remote_perm.has_permission (RemotePermissions.Can_write);
                    FileSystem.set_file_read_only_weak (file_path, is_read_only);
                }
                auto rec = item.to_sync_journal_file_record_with_inode (file_path);
                if (rec._checksum_header.is_empty ())
                    rec._checksum_header = prev._checksum_header;
                rec._server_has_ignored_files |= prev._server_has_ignored_files;

                // Ensure it's a placeholder file on disk
                if (item._type == ItemTypeFile) {
                    const auto result = _sync_options._vfs.convert_to_placeholder (file_path, *item);
                    if (!result) {
                        item._instruction = CSYNC_INSTRUCTION_ERROR;
                        item._error_string = tr ("Could not update file : %1").arg (result.error ());
                        return;
                    }
                }

                // Update on-disk virtual file metadata
                if (item._type == Item_type_virtual_file) {
                    auto r = _sync_options._vfs.update_metadata (file_path, item._modtime, item._size, item._file_id);
                    if (!r) {
                        item._instruction = CSYNC_INSTRUCTION_ERROR;
                        item._error_string = tr ("Could not update virtual file metadata : %1").arg (r.error ());
                        return;
                    }
                }

                // Updating the db happens on success
                _journal.set_file_record (rec);

                // This might have changed the shared flag, so we must notify SyncFileStatusTracker for example
                emit item_completed (item);
            } else {
                // Update only outdated data from the disk.
                _journal.update_local_metadata (item._file, item._modtime, item._size, item._inode);
            }
            _has_none_files = true;
            return;
        } else if (item._instruction == CSYNC_INSTRUCTION_NONE) {
            _has_none_files = true;
            if (_account.capabilities ().upload_conflict_files () && Utility.is_conflict_file (item._file)) {
                // For uploaded conflict files, files with no action performed on them should
                // be displayed : but we mustn't overwrite the instruction if something happens
                // to the file!
                item._error_string = tr ("Unresolved conflict.");
                item._instruction = CSYNC_INSTRUCTION_IGNORE;
                item._status = SyncFileItem.Conflict;
            }
            return;
        } else if (item._instruction == CSYNC_INSTRUCTION_REMOVE && !item._is_selective_sync) {
            _has_remove_file = true;
        } else if (item._instruction == CSYNC_INSTRUCTION_RENAME) {
            _has_none_files = true; // If a file (or every file) has been renamed, it means not al files where deleted
        } else if (item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE
            || item._instruction == CSYNC_INSTRUCTION_SYNC) {
            if (item._direction == SyncFileItem.Up) {
                // An upload of an existing file means that the file was left unchanged on the server
                // This counts as a NONE for detecting if all the files on the server were changed
                _has_none_files = true;
            }
        }

        // check for blacklisting of this item.
        // if the item is on blacklist, the instruction was set to ERROR
        check_error_blacklisting (*item);
        _needs_update = true;

        // Insert sorted
        auto it = std.lower_bound ( _sync_items.begin (), _sync_items.end (), item ); // the _sync_items is sorted
        _sync_items.insert ( it, item );

        slot_new_item (item);

        if (item.is_directory ()) {
            slot_folder_discovered (item._etag.is_empty (), item._file);
        }
    }

    void SyncEngine.start_sync () {
        if (_journal.exists ()) {
            QVector<SyncJournalDb.Poll_info> poll_infos = _journal.get_poll_infos ();
            if (!poll_infos.is_empty ()) {
                q_c_info (lc_engine) << "Finish Poll jobs before starting a sync";
                auto *job = new Cleanup_polls_job (poll_infos, _account,
                    _journal, _local_path, _sync_options._vfs, this);
                connect (job, &Cleanup_polls_job.finished, this, &SyncEngine.start_sync);
                connect (job, &Cleanup_polls_job.aborted, this, &SyncEngine.slot_clean_polls_job_aborted);
                job.start ();
                return;
            }
        }

        if (s_any_sync_running || _sync_running) {
            ASSERT (false)
            return;
        }

        s_any_sync_running = true;
        _sync_running = true;
        _another_sync_needed = No_follow_up_sync;
        _clear_touched_files_timer.stop ();

        _has_none_files = false;
        _has_remove_file = false;
        _seen_conflict_files.clear ();

        _progress_info.reset ();

        if (!QDir (_local_path).exists ()) {
            _another_sync_needed = DelayedFollowUp;
            // No _tr, it should only occur in non-mirall
            Q_EMIT sync_error (QStringLiteral ("Unable to find local sync folder."));
            finalize (false);
            return;
        }

        // Check free size on disk first.
        const int64 min_free = critical_free_space_limit ();
        const int64 free_bytes = Utility.free_disk_space (_local_path);
        if (free_bytes >= 0) {
            if (free_bytes < min_free) {
                q_c_warning (lc_engine ()) << "Too little space available at" << _local_path << ". Have"
                                      << free_bytes << "bytes and require at least" << min_free << "bytes";
                _another_sync_needed = DelayedFollowUp;
                Q_EMIT sync_error (tr ("Only %1 are available, need at least %2 to start",
                    "Placeholders are postfixed with file sizes using Utility.octets_to_string ()")
                                     .arg (
                                         Utility.octets_to_string (free_bytes),
                                         Utility.octets_to_string (min_free)));
                finalize (false);
                return;
            } else {
                q_c_info (lc_engine) << "There are" << free_bytes << "bytes available at" << _local_path;
            }
        } else {
            q_c_warning (lc_engine) << "Could not determine free space available at" << _local_path;
        }

        _sync_items.clear ();
        _needs_update = false;

        if (!_journal.exists ()) {
            q_c_info (lc_engine) << "New sync (no sync journal exists)";
        } else {
            q_c_info (lc_engine) << "Sync with existing sync journal";
        }

        string ver_str ("Using Qt ");
        ver_str.append (q_version ());

        ver_str.append (" SSL library ").append (QSsl_socket.ssl_library_version_string ().to_utf8 ().data ());
        ver_str.append (" on ").append (Utility.platform_name ());
        q_c_info (lc_engine) << ver_str;

        // This creates the DB if it does not exist yet.
        if (!_journal.open ()) {
            q_c_warning (lc_engine) << "No way to create a sync journal!";
            Q_EMIT sync_error (tr ("Unable to open or create the local sync database. Make sure you have write access in the sync folder."));
            finalize (false);
            return;
            // database creation error!
        }

        // Functionality like selective sync might have set up etag storage
        // filtering via schedule_path_for_remote_discovery (). This *is* the next sync, so
        // undo the filter to allow this sync to retrieve and store the correct etags.
        _journal.clear_etag_storage_filter ();

        _excluded_files.set_exclude_conflict_files (!_account.capabilities ().upload_conflict_files ());

        _last_local_discovery_style = _local_discovery_style;

        if (_sync_options._vfs.mode () == Vfs.WithSuffix && _sync_options._vfs.file_suffix ().is_empty ()) {
            Q_EMIT sync_error (tr ("Using virtual files with suffix, but suffix is not set"));
            finalize (false);
            return;
        }

        bool ok = false;
        auto selective_sync_black_list = _journal.get_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, &ok);
        if (ok) {
            bool using_selective_sync = (!selective_sync_black_list.is_empty ());
            q_c_info (lc_engine) << (using_selective_sync ? "Using Selective Sync" : "NOT Using Selective Sync");
        } else {
            q_c_warning (lc_engine) << "Could not retrieve selective sync list from DB";
            Q_EMIT sync_error (tr ("Unable to read the blacklist from the local database"));
            finalize (false);
            return;
        }

        _stop_watch.start ();
        _progress_info._status = ProgressInfo.Starting;
        emit transmission_progress (*_progress_info);

        q_c_info (lc_engine) << "#### Discovery start ####################################################";
        q_c_info (lc_engine) << "Server" << account ().server_version ()
                         << (account ().is_http2Supported () ? "Using HTTP/2" : "");
        _progress_info._status = ProgressInfo.Discovery;
        emit transmission_progress (*_progress_info);

        _discovery_phase.reset (new Discovery_phase);
        _discovery_phase._account = _account;
        _discovery_phase._excludes = _excluded_files.data ();
        const string exclude_file_path = _local_path + QStringLiteral (".sync-exclude.lst");
        if (QFile.exists (exclude_file_path)) {
            _discovery_phase._excludes.add_exclude_file_path (exclude_file_path);
            _discovery_phase._excludes.reload_exclude_files ();
        }
        _discovery_phase._statedb = _journal;
        _discovery_phase._local_dir = _local_path;
        if (!_discovery_phase._local_dir.ends_with ('/'))
            _discovery_phase._local_dir+='/';
        _discovery_phase._remote_folder = _remote_path;
        if (!_discovery_phase._remote_folder.ends_with ('/'))
            _discovery_phase._remote_folder+='/';
        _discovery_phase._sync_options = _sync_options;
        _discovery_phase._should_discover_localy = [this] (string &s) {
            return should_discover_locally (s);
        };
        _discovery_phase.set_selective_sync_black_list (selective_sync_black_list);
        _discovery_phase.set_selective_sync_white_list (_journal.get_selective_sync_list (SyncJournalDb.SelectiveSyncWhiteList, &ok));
        if (!ok) {
            q_c_warning (lc_engine) << "Unable to read selective sync list, aborting.";
            Q_EMIT sync_error (tr ("Unable to read from the sync journal."));
            finalize (false);
            return;
        }

        // Check for invalid character in old server version
        string invalid_filename_pattern = _account.capabilities ().invalid_filename_regex ();
        if (invalid_filename_pattern.is_null ()
            && _account.server_version_int () < Account.make_server_version (8, 1, 0)) {
            // Server versions older than 8.1 don't support some characters in filenames.
            // If the capability is not set, default to a pattern that avoids uploading
            // files with names that contain these.
            // It's important to respect the capability also for older servers -- the
            // version check doesn't make sense for custom servers.
            invalid_filename_pattern = R" ([\\:?*\"<>|])";
        }
        if (!invalid_filename_pattern.is_empty ())
            _discovery_phase._invalid_filename_rx = QRegularExpression (invalid_filename_pattern);
        _discovery_phase._server_blacklisted_files = _account.capabilities ().blacklisted_files ();
        _discovery_phase._ignore_hidden_files = ignore_hidden_files ();

        connect (_discovery_phase.data (), &Discovery_phase.item_discovered, this, &SyncEngine.slot_item_discovered);
        connect (_discovery_phase.data (), &Discovery_phase.new_big_folder, this, &SyncEngine.new_big_folder);
        connect (_discovery_phase.data (), &Discovery_phase.fatal_error, this, [this] (string &error_string) {
            Q_EMIT sync_error (error_string);
            finalize (false);
        });
        connect (_discovery_phase.data (), &Discovery_phase.finished, this, &SyncEngine.slot_discovery_finished);
        connect (_discovery_phase.data (), &Discovery_phase.silently_excluded,
            _sync_file_status_tracker.data (), &SyncFileStatusTracker.slot_add_silently_excluded);

        auto discovery_job = new Process_directory_job (
            _discovery_phase.data (), PinState.AlwaysLocal, _journal.key_value_store_get_int ("last_sync", 0), _discovery_phase.data ());
        _discovery_phase.start_job (discovery_job);
        connect (discovery_job, &Process_directory_job.etag, this, &SyncEngine.slot_root_etag_received);
        connect (_discovery_phase.data (), &Discovery_phase.add_error_to_gui, this, &SyncEngine.add_error_to_gui);
    }

    void SyncEngine.slot_folder_discovered (bool local, string &folder) {
        // Don't wanna overload the UI
        if (!_last_update_progress_callback_call.is_valid () || _last_update_progress_callback_call.elapsed () >= 200) {
            _last_update_progress_callback_call.start (); // first call or enough elapsed time
        } else {
            return;
        }

        if (local) {
            _progress_info._current_discovered_local_folder = folder;
            _progress_info._current_discovered_remote_folder.clear ();
        } else {
            _progress_info._current_discovered_remote_folder = folder;
            _progress_info._current_discovered_local_folder.clear ();
        }
        emit transmission_progress (*_progress_info);
    }

    void SyncEngine.slot_root_etag_received (QByteArray &e, QDateTime &time) {
        if (_remote_root_etag.is_empty ()) {
            q_c_debug (lc_engine) << "Root etag:" << e;
            _remote_root_etag = e;
            emit root_etag (_remote_root_etag, time);
        }
    }

    void SyncEngine.slot_new_item (SyncFileItemPtr &item) {
        _progress_info.adjust_totals_for_file (*item);
    }

    void SyncEngine.slot_discovery_finished () {
        if (!_discovery_phase) {
            // There was an error that was already taken care of
            return;
        }

        q_c_info (lc_engine) << "#### Discovery end #################################################### " << _stop_watch.add_lap_time (QLatin1String ("Discovery Finished")) << "ms";

        // Sanity check
        if (!_journal.open ()) {
            q_c_warning (lc_engine) << "Bailing out, DB failure";
            Q_EMIT sync_error (tr ("Cannot open the sync journal"));
            finalize (false);
            return;
        } else {
            // Commits a possibly existing (should not though) transaction and starts a new one for the propagate phase
            _journal.commit_if_needed_and_start_new_transaction ("Post discovery");
        }

        _progress_info._current_discovered_remote_folder.clear ();
        _progress_info._current_discovered_local_folder.clear ();
        _progress_info._status = ProgressInfo.Reconcile;
        emit transmission_progress (*_progress_info);

        //    q_c_info (lc_engine) << "Permissions of the root folder : " << _csync_ctx.remote.root_perms.to_string ();
        auto finish = [this]{
            auto database_fingerprint = _journal.data_fingerprint ();
            // If database_fingerprint is empty, this means that there was no information in the database
            // (for example, upgrading from a previous version, or first sync, or server not supporting fingerprint)
            if (!database_fingerprint.is_empty () && _discovery_phase
                && _discovery_phase._data_fingerprint != database_fingerprint) {
                q_c_info (lc_engine) << "data fingerprint changed, assume restore from backup" << database_fingerprint << _discovery_phase._data_fingerprint;
                restore_old_files (_sync_items);
            }

            if (_discovery_phase._another_sync_needed && _another_sync_needed == No_follow_up_sync) {
                _another_sync_needed = Immediate_follow_up;
            }

            Q_ASSERT (std.is_sorted (_sync_items.begin (), _sync_items.end ()));

            q_c_info (lc_engine) << "#### Reconcile (about_to_propagate) #################################################### " << _stop_watch.add_lap_time (QStringLiteral ("Reconcile (about_to_propagate)")) << "ms";

            _local_discovery_paths.clear ();

            // To announce the beginning of the sync
            emit about_to_propagate (_sync_items);

            q_c_info (lc_engine) << "#### Reconcile (about_to_propagate OK) #################################################### "<< _stop_watch.add_lap_time (QStringLiteral ("Reconcile (about_to_propagate OK)")) << "ms";

            // it's important to do this before ProgressInfo.start (), to announce start of new sync
            _progress_info._status = ProgressInfo.Propagation;
            emit transmission_progress (*_progress_info);
            _progress_info.start_estimate_updates ();

            // post update phase script : allow to tweak stuff by a custom script in debug mode.
            if (!q_environment_variable_is_empty ("OWNCLOUD_POST_UPDATE_SCRIPT")) {
        #ifndef NDEBUG
                const string script = q_environment_variable ("OWNCLOUD_POST_UPDATE_SCRIPT");

                q_c_debug (lc_engine) << "Post Update Script : " << script;
                auto script_args = script.split (QRegularExpression ("\\s+"), Qt.Skip_empty_parts);
                if (script_args.size () > 0) {
                    const auto script_executable = script_args.take_first ();
                    QProcess.execute (script_executable, script_args);
                }
    #else
                q_c_warning (lc_engine) << "**** Attention : POST_UPDATE_SCRIPT installed, but not executed because compiled with NDEBUG";
        #endif
            }

            // do a database commit
            _journal.commit (QStringLiteral ("post treewalk"));

            _propagator = QSharedPointer<Owncloud_propagator> (
                new Owncloud_propagator (_account, _local_path, _remote_path, _journal, _bulk_upload_black_list));
            _propagator.set_sync_options (_sync_options);
            connect (_propagator.data (), &Owncloud_propagator.item_completed,
                this, &SyncEngine.slot_item_completed);
            connect (_propagator.data (), &Owncloud_propagator.progress,
                this, &SyncEngine.slot_progress);
            connect (_propagator.data (), &Owncloud_propagator.finished, this, &SyncEngine.slot_propagation_finished, Qt.QueuedConnection);
            connect (_propagator.data (), &Owncloud_propagator.seen_locked_file, this, &SyncEngine.seen_locked_file);
            connect (_propagator.data (), &Owncloud_propagator.touched_file, this, &SyncEngine.slot_add_touched_file);
            connect (_propagator.data (), &Owncloud_propagator.insufficient_local_storage, this, &SyncEngine.slot_insufficient_local_storage);
            connect (_propagator.data (), &Owncloud_propagator.insufficient_remote_storage, this, &SyncEngine.slot_insufficient_remote_storage);
            connect (_propagator.data (), &Owncloud_propagator.new_item, this, &SyncEngine.slot_new_item);

            // apply the network limits to the propagator
            set_network_limits (_upload_limit, _download_limit);

            delete_stale_download_infos (_sync_items);
            delete_stale_upload_infos (_sync_items);
            delete_stale_error_blacklist_entries (_sync_items);
            _journal.commit (QStringLiteral ("post stale entry removal"));

            // Emit the started signal only after the propagator has been set up.
            if (_needs_update)
                Q_EMIT started ();

            _propagator.start (std.move (_sync_items));

            q_c_info (lc_engine) << "#### Post-Reconcile end #################################################### " << _stop_watch.add_lap_time (QStringLiteral ("Post-Reconcile Finished")) << "ms";
        };

        if (!_has_none_files && _has_remove_file) {
            q_c_info (lc_engine) << "All the files are going to be changed, asking the user";
            int side = 0; // > 0 means more deleted on the server.  < 0 means more deleted on the client
            foreach (auto &it, _sync_items) {
                if (it._instruction == CSYNC_INSTRUCTION_REMOVE) {
                    side += it._direction == SyncFileItem.Down ? 1 : -1;
                }
            }

            QPointer<GLib.Object> guard = new GLib.Object ();
            QPointer<GLib.Object> self = this;
            auto callback = [this, self, finish, guard] (bool cancel) . void {
                // use a guard to ensure its only called once...
                // qpointer to self to ensure we still exist
                if (!guard || !self) {
                    return;
                }
                guard.delete_later ();
                if (cancel) {
                    q_c_info (lc_engine) << "User aborted sync";
                    finalize (false);
                    return;
                } else {
                    finish ();
                }
            };
            emit about_to_remove_all_files (side >= 0 ? SyncFileItem.Down : SyncFileItem.Up, callback);
            return;
        }
        finish ();
    }

    void SyncEngine.slot_clean_polls_job_aborted (string &error) {
        sync_error (error);
        finalize (false);
    }

    void SyncEngine.set_network_limits (int upload, int download) {
        _upload_limit = upload;
        _download_limit = download;

        if (!_propagator)
            return;

        _propagator._upload_limit = upload;
        _propagator._download_limit = download;

        if (upload != 0 || download != 0) {
            q_c_info (lc_engine) << "Network Limits (down/up) " << upload << download;
        }
    }

    void SyncEngine.slot_item_completed (SyncFileItemPtr &item) {
        _progress_info.set_progress_complete (*item);

        emit transmission_progress (*_progress_info);
        emit item_completed (item);
    }

    void SyncEngine.slot_propagation_finished (bool success) {
        if (_propagator._another_sync_needed && _another_sync_needed == No_follow_up_sync) {
            _another_sync_needed = Immediate_follow_up;
        }

        if (success && _discovery_phase) {
            _journal.set_data_fingerprint (_discovery_phase._data_fingerprint);
        }

        conflict_record_maintenance ();

        _journal.delete_stale_flags_entries ();
        _journal.commit ("All Finished.", false);

        // Send final progress information even if no
        // files needed propagation, but clear the last_completed_item
        // so we don't count this twice (like Recent Files)
        _progress_info._last_completed_item = SyncFileItem ();
        _progress_info._status = ProgressInfo.Done;
        emit transmission_progress (*_progress_info);

        finalize (success);
    }

    void SyncEngine.finalize (bool success) {
        q_c_info (lc_engine) << "Sync run took " << _stop_watch.add_lap_time (QLatin1String ("Sync Finished")) << "ms";
        _stop_watch.stop ();

        if (_discovery_phase) {
            _discovery_phase.take ().delete_later ();
        }
        s_any_sync_running = false;
        _sync_running = false;
        emit finished (success);

        // Delete the propagator only after emitting the signal.
        _propagator.clear ();
        _seen_conflict_files.clear ();
        _unique_errors.clear ();
        _local_discovery_paths.clear ();
        _local_discovery_style = Local_discovery_style.Filesystem_only;

        _clear_touched_files_timer.start ();
    }

    void SyncEngine.slot_progress (SyncFileItem &item, int64 current) {
        _progress_info.set_progress_item (item, current);
        emit transmission_progress (*_progress_info);
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
    void SyncEngine.restore_old_files (Sync_file_item_vector &sync_items) {

        for (auto &sync_item : q_as_const (sync_items)) {
            if (sync_item._direction != SyncFileItem.Down)
                continue;

            switch (sync_item._instruction) {
            case CSYNC_INSTRUCTION_SYNC:
                q_c_warning (lc_engine) << "restore_old_files : RESTORING" << sync_item._file;
                sync_item._instruction = CSYNC_INSTRUCTION_CONFLICT;
                break;
            case CSYNC_INSTRUCTION_REMOVE:
                q_c_warning (lc_engine) << "restore_old_files : RESTORING" << sync_item._file;
                sync_item._instruction = CSYNC_INSTRUCTION_NEW;
                sync_item._direction = SyncFileItem.Up;
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

    void SyncEngine.slot_add_touched_file (string &fn) {
        QElapsedTimer now;
        now.start ();
        string file = QDir.clean_path (fn);

        // Iterate from the oldest and remove anything older than 15 seconds.
        while (true) {
            auto first = _touched_files.begin ();
            if (first == _touched_files.end ())
                break;
            // Compare to our new QElapsedTimer instead of using elapsed ().
            // This avoids querying the current time from the OS for every loop.
            auto elapsed = std.chrono.milliseconds (now.msecs_since_reference () - first.key ().msecs_since_reference ());
            if (elapsed <= s_touched_files_max_age_ms) {
                // We found the first path younger than the maximum age, keep the rest.
                break;
            }

            _touched_files.erase (first);
        }

        // This should be the largest QElapsedTimer yet, use const_end () as hint.
        _touched_files.insert (_touched_files.const_end (), now, file);
    }

    void SyncEngine.slot_clear_touched_files () {
        _touched_files.clear ();
    }

    bool SyncEngine.was_file_touched (string &fn) {
        // Start from the end (most recent) and look for our path. Check the time just in case.
        auto begin = _touched_files.const_begin ();
        for (auto it = _touched_files.const_end (); it != begin; --it) {
            if ( (it-1).value () == fn)
                return std.chrono.milliseconds ( (it-1).key ().elapsed ()) <= s_touched_files_max_age_ms;
        }
        return false;
    }

    AccountPtr SyncEngine.account () {
        return _account;
    }

    void SyncEngine.set_local_discovery_options (Local_discovery_style style, std.set<string> paths) {
        _local_discovery_style = style;
        _local_discovery_paths = std.move (paths);

        // Normalize to make sure that no path is a contained in another.
        // Note : for simplicity, this code consider anything less than '/' as a path separator, so for
        // example, this will remove "foo.bar" if "foo" is in the list. This will mean we might have
        // some false positive, but that's Ok.
        // This invariant is used in SyncEngine.should_discover_locally
        string prev;
        auto it = _local_discovery_paths.begin ();
        while (it != _local_discovery_paths.end ()) {
            if (!prev.is_null () && it.starts_with (prev) && (prev.ends_with ('/') || *it == prev || it.at (prev.size ()) <= '/')) {
                it = _local_discovery_paths.erase (it);
            } else {
                prev = *it;
                ++it;
            }
        }
    }

    bool SyncEngine.should_discover_locally (string &path) {
        if (_local_discovery_style == Local_discovery_style.Filesystem_only)
            return true;

        // The intention is that if "A/X" is in _local_discovery_paths:
        // - parent folders like "/", "A" will be discovered (to make sure the discovery reaches the
        //   point where something new happened)
        // - the folder itself "A/X" will be discovered
        // - subfolders like "A/X/Y" will be discovered (so data inside a new or renamed folder will be
        //   discovered in full)
        // Check out Test_local_discovery.test_local_discovery_decision ()

        auto it = _local_discovery_paths.lower_bound (path);
        if (it == _local_discovery_paths.end () || !it.starts_with (path)) {
            // Maybe a subfolder of something in the list?
            if (it != _local_discovery_paths.begin () && path.starts_with (* (--it))) {
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
            if (it == _local_discovery_paths.end () || !it.starts_with (path))
                return false;
        }
        return false;
    }

    void SyncEngine.wipe_virtual_files (string &local_path, SyncJournalDb &journal, Vfs &vfs) {
        q_c_info (lc_engine) << "Wiping virtual files inside" << local_path;
        journal.get_files_below_path (QByteArray (), [&] (SyncJournalFileRecord &rec) {
            if (rec._type != Item_type_virtual_file && rec._type != Item_type_virtual_file_download)
                return;

            q_c_debug (lc_engine) << "Removing db record for" << rec.path ();
            journal.delete_file_record (rec._path);

            // If the local file is a dehydrated placeholder, wipe it too.
            // Otherwise leave it to allow the next sync to have a new-new conflict.
            string local_file = local_path + rec._path;
            if (QFile.exists (local_file) && vfs.is_dehydrated_placeholder (local_file)) {
                q_c_debug (lc_engine) << "Removing local dehydrated placeholder" << rec.path ();
                QFile.remove (local_file);
            }
        });

        journal.force_remote_discovery_next_sync ();

        // Postcondition : No Item_type_virtual_file / Item_type_virtual_file_download left in the db.
        // But hydrated placeholders may still be around.
    }

    void SyncEngine.switch_to_virtual_files (string &local_path, SyncJournalDb &journal, Vfs &vfs) {
        q_c_info (lc_engine) << "Convert to virtual files inside" << local_path;
        journal.get_files_below_path ({}, [&] (SyncJournalFileRecord &rec) {
            const auto path = rec.path ();
            const auto file_name = QFileInfo (path).file_name ();
            if (FileSystem.is_exclude_file (file_name)) {
                return;
            }
            SyncFileItem item;
            string local_file = local_path + path;
            const auto result = vfs.convert_to_placeholder (local_file, item, local_file);
            if (!result.is_valid ()) {
                q_c_warning (lc_engine) << "Could not convert file to placeholder" << result.error ();
            }
        });
    }

    void SyncEngine.abort () {
        if (_propagator)
            q_c_info (lc_engine) << "Aborting sync";

        if (_propagator) {
            // If we're already in the propagation phase, aborting that is sufficient
            _propagator.abort ();
        } else if (_discovery_phase) {
            // Delete the discovery and all child jobs after ensuring
            // it can't finish and start the propagator
            disconnect (_discovery_phase.data (), nullptr, this, nullptr);
            _discovery_phase.take ().delete_later ();

            Q_EMIT sync_error (tr ("Synchronization will resume shortly."));
            finalize (false);
        }
    }

    void SyncEngine.slot_summary_error (string &message) {
        if (_unique_errors.contains (message))
            return;

        _unique_errors.insert (message);
        emit sync_error (message, ErrorCategory.Normal);
    }

    void SyncEngine.slot_insufficient_local_storage () {
        slot_summary_error (
            tr ("Disk space is low : Downloads that would reduce free space "
               "below %1 were skipped.")
                .arg (Utility.octets_to_string (free_space_limit ())));
    }

    void SyncEngine.slot_insufficient_remote_storage () {
        auto msg = tr ("There is insufficient space available on the server for some uploads.");
        if (_unique_errors.contains (msg))
            return;

        _unique_errors.insert (msg);
        emit sync_error (msg, ErrorCategory.Insufficient_remote_storage);
    }

    } // namespace Occ
    