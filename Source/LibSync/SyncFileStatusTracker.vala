/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Jocelyn Turcotte <jturcotte@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>

// // #include <map>
// #include <QSet>

namespace Occ {


/***********************************************************
@brief Takes care of tracking the status of individual files as they
       go through the SyncEngine, to be reported as overlay icons in the shell.
@ingroup libsync
***********************************************************/
class SyncFileStatusTracker : GLib.Object {
public:
    SyncFileStatusTracker (SyncEngine *sync_engine);
    SyncFileStatus file_status (string &relative_path);

public slots:
    void slot_path_touched (string &file_name);
    // path relative to folder
    void slot_add_silently_excluded (string &folder_path);

signals:
    void file_status_changed (string &system_file_name, SyncFileStatus file_status);

private slots:
    void slot_about_to_propagate (Sync_file_item_vector &items);
    void slot_item_completed (SyncFileItemPtr &item);
    void slot_sync_finished ();
    void slot_sync_engine_running_changed ();

private:
    struct Path_comparator {
        bool operator () ( const string& lhs, string& rhs ) const;
    };
    using Problems_map = std.map<string, SyncFileStatus.SyncFileStatusTag, Path_comparator>;
    SyncFileStatus.SyncFileStatusTag lookup_problem (string &path_to_match, Problems_map &problem_map);

    enum Shared_flag { Unknown_shared,
        Not_shared,
        Shared };
    enum Path_known_flag { Path_unknown = 0,
        Path_known };
    SyncFileStatus resolve_sync_and_error_status (string &relative_path, Shared_flag shared_state, Path_known_flag is_path_known = Path_known);

    void invalidate_parent_paths (string &path);
    string get_system_destination (string &relative_path);
    void inc_sync_count_and_emit_status_changed (string &relative_path, Shared_flag shared_state);
    void dec_sync_count_and_emit_status_changed (string &relative_path, Shared_flag shared_state);

    SyncEngine *_sync_engine;

    Problems_map _sync_problems;
    QSet<string> _dirty_paths;
    // Counts the number direct children currently being synced (has unfinished propagation jobs).
    // We'll show a file/directory as SYNC as long as its sync count is > 0.
    // A directory that starts/ends propagation will in turn increase/decrease its own parent by 1.
    QHash<string, int> _sync_count;
};

    static int path_compare ( const string& lhs, string& rhs ) {
        // Should match Utility.fs_case_preserving, we want don't want to pay for the runtime check on every comparison.
        return lhs.compare (rhs, Qt.CaseSensitive);
    }
    
    static bool path_starts_with ( const string& lhs, string& rhs ) {
        return lhs.starts_with (rhs, Qt.CaseSensitive);
    }
    
    bool SyncFileStatusTracker.Path_comparator.operator () ( const string& lhs, string& rhs ) {
        // This will make sure that the std.map is ordered and queried case-insensitively on mac_o_s and Windows.
        return path_compare (lhs, rhs) < 0;
    }
    
    SyncFileStatus.SyncFileStatusTag SyncFileStatusTracker.lookup_problem (string &path_to_match, SyncFileStatusTracker.Problems_map &problem_map) {
        auto lower = problem_map.lower_bound (path_to_match);
        for (auto it = lower; it != problem_map.cend (); ++it) {
            const string &problem_path = it.first;
            SyncFileStatus.SyncFileStatusTag severity = it.second;
    
            if (path_compare (problem_path, path_to_match) == 0) {
                return severity;
            } else if (severity == SyncFileStatus.SyncFileStatusTag.STATUS_ERROR
                && path_starts_with (problem_path, path_to_match)
                && (path_to_match.is_empty () || problem_path.at (path_to_match.size ()) == '/')) {
                return SyncFileStatus.SyncFileStatusTag.STATUS_WARNING;
            } else if (!path_starts_with (problem_path, path_to_match)) {
                // Starting at lower_bound we get the first path that is not smaller,
                // since : "a/" < "a/aa" < "a/aa/aaa" < "a/ab/aba"
                // If problem_map keys are ["a/aa/aaa", "a/ab/aba"] and path_to_match == "a/aa",
                // lower_bound (path_to_match) will point to "a/aa/aaa", and the moment that
                // problem_path.starts_with (path_to_match) == false, we know that we've looked
                // at everything that interest us.
                break;
            }
        }
        return SyncFileStatus.SyncFileStatusTag.STATUS_NONE;
    }
    
    /***********************************************************
    Whether this item should get an ERROR icon through the Socket API.
    
    The Socket API should only present serious, permanent errors to the us
    In particular Soft_errors should just retain their 'needs to be synced'
    icon as the problem is most likely going to resolve itself quickly and
    automatically.
    ***********************************************************/
    static inline bool has_error_status (SyncFileItem &item) {
        const auto status = item._status;
        return item._instruction == CSYNC_INSTRUCTION_ERROR
            || status == SyncFileItem.Normal_error
            || status == SyncFileItem.Fatal_error
            || status == SyncFileItem.Detail_error
            || status == SyncFileItem.Blacklisted_error
            || item._has_blacklist_entry;
    }
    
    static inline bool has_excluded_status (SyncFileItem &item) {
        const auto status = item._status;
        return item._instruction == CSYNC_INSTRUCTION_IGNORE
            || status == SyncFileItem.File_ignored
            || status == SyncFileItem.Conflict
            || status == SyncFileItem.Restoration
            || status == SyncFileItem.File_locked;
    }
    
    SyncFileStatusTracker.SyncFileStatusTracker (SyncEngine *sync_engine)
        : _sync_engine (sync_engine) {
        connect (sync_engine, &SyncEngine.about_to_propagate,
            this, &SyncFileStatusTracker.slot_about_to_propagate);
        connect (sync_engine, &SyncEngine.item_completed,
            this, &SyncFileStatusTracker.slot_item_completed);
        connect (sync_engine, &SyncEngine.finished, this, &SyncFileStatusTracker.slot_sync_finished);
        connect (sync_engine, &SyncEngine.started, this, &SyncFileStatusTracker.slot_sync_engine_running_changed);
        connect (sync_engine, &SyncEngine.finished, this, &SyncFileStatusTracker.slot_sync_engine_running_changed);
    }
    
    SyncFileStatus SyncFileStatusTracker.file_status (string &relative_path) {
        ASSERT (!relative_path.ends_with (QLatin1Char ('/')));
    
        if (relative_path.is_empty ()) {
            // This is the root sync folder, it doesn't have an entry in the database and won't be walked by csync, so resolve manually.
            return resolve_sync_and_error_status (string (), Not_shared);
        }
    
        // The SyncEngine won't notify us at all for CSYNC_FILE_SILENTLY_EXCLUDED
        // and CSYNC_FILE_EXCLUDE_AND_REMOVE excludes. Even though it's possible
        // that the status of CSYNC_FILE_EXCLUDE_LIST excludes will change if the user
        // update the exclude list at runtime and doing it statically here removes
        // our ability to notify changes through the file_status_changed signal,
        // it's an acceptable compromize to treat all exclude types the same.
        // Update : This extra check shouldn't hurt even though silently excluded files
        // are now available via slot_add_silently_excluded ().
        if (_sync_engine.excluded_files ().is_excluded (_sync_engine.local_path () + relative_path,
                _sync_engine.local_path (),
                _sync_engine.ignore_hidden_files ())) {
            return SyncFileStatus.SyncFileStatusTag.STATUS_EXCLUDED;
        }
    
        if (_dirty_paths.contains (relative_path))
            return SyncFileStatus.SyncFileStatusTag.STATUS_SYNC;
    
        // First look it up in the database to know if it's shared
        SyncJournalFileRecord rec;
        if (_sync_engine.journal ().get_file_record (relative_path, &rec) && rec.is_valid ()) {
            return resolve_sync_and_error_status (relative_path, rec._remote_perm.has_permission (RemotePermissions.Is_shared) ? Shared : Not_shared);
        }
    
        // Must be a new file not yet in the database, check if it's syncing or has an error.
        return resolve_sync_and_error_status (relative_path, Not_shared, Path_unknown);
    }
    
    void SyncFileStatusTracker.slot_path_touched (string &file_name) {
        string folder_path = _sync_engine.local_path ();
    
        ASSERT (file_name.starts_with (folder_path));
        string local_path = file_name.mid (folder_path.size ());
        _dirty_paths.insert (local_path);
    
        emit file_status_changed (file_name, SyncFileStatus.SyncFileStatusTag.STATUS_SYNC);
    }
    
    void SyncFileStatusTracker.slot_add_silently_excluded (string &folder_path) {
        _sync_problems[folder_path] = SyncFileStatus.SyncFileStatusTag.STATUS_EXCLUDED;
        emit file_status_changed (get_system_destination (folder_path), resolve_sync_and_error_status (folder_path, Not_shared));
    }
    
    void SyncFileStatusTracker.inc_sync_count_and_emit_status_changed (string &relative_path, Shared_flag shared_flag) {
        // Will return 0 (and increase to 1) if the path wasn't in the map yet
        int count = _sync_count[relative_path]++;
        if (!count) {
            SyncFileStatus status = shared_flag == Unknown_shared
                ? file_status (relative_path)
                : resolve_sync_and_error_status (relative_path, shared_flag);
            emit file_status_changed (get_system_destination (relative_path), status);
    
            // We passed from OK to SYNC, increment the parent to keep it marked as
            // SYNC while we propagate ourselves and our own children.
            ASSERT (!relative_path.ends_with ('/'));
            int last_slash_index = relative_path.last_index_of ('/');
            if (last_slash_index != -1)
                inc_sync_count_and_emit_status_changed (relative_path.left (last_slash_index), Unknown_shared);
            else if (!relative_path.is_empty ())
                inc_sync_count_and_emit_status_changed (string (), Unknown_shared);
        }
    }
    
    void SyncFileStatusTracker.dec_sync_count_and_emit_status_changed (string &relative_path, Shared_flag shared_flag) {
        int count = --_sync_count[relative_path];
        if (!count) {
            // Remove from the map, same as 0
            _sync_count.remove (relative_path);
    
            SyncFileStatus status = shared_flag == Unknown_shared
                ? file_status (relative_path)
                : resolve_sync_and_error_status (relative_path, shared_flag);
            emit file_status_changed (get_system_destination (relative_path), status);
    
            // We passed from SYNC to OK, decrement our parent.
            ASSERT (!relative_path.ends_with ('/'));
            int last_slash_index = relative_path.last_index_of ('/');
            if (last_slash_index != -1)
                dec_sync_count_and_emit_status_changed (relative_path.left (last_slash_index), Unknown_shared);
            else if (!relative_path.is_empty ())
                dec_sync_count_and_emit_status_changed (string (), Unknown_shared);
        }
    }
    
    void SyncFileStatusTracker.slot_about_to_propagate (Sync_file_item_vector &items) {
        ASSERT (_sync_count.is_empty ());
    
        Problems_map old_problems;
        std.swap (_sync_problems, old_problems);
    
        foreach (SyncFileItemPtr &item, items) {
            q_c_debug (lc_status_tracker) << "Investigating" << item.destination () << item._status << item._instruction;
            _dirty_paths.remove (item.destination ());
    
            if (has_error_status (*item)) {
                _sync_problems[item.destination ()] = SyncFileStatus.SyncFileStatusTag.STATUS_ERROR;
                invalidate_parent_paths (item.destination ());
            } else if (has_excluded_status (*item)) {
                _sync_problems[item.destination ()] = SyncFileStatus.SyncFileStatusTag.STATUS_EXCLUDED;
            }
    
            Shared_flag shared_flag = item._remote_perm.has_permission (RemotePermissions.Is_shared) ? Shared : Not_shared;
            if (item._instruction != CSYNC_INSTRUCTION_NONE
                && item._instruction != CSYNC_INSTRUCTION_UPDATE_METADATA
                && item._instruction != CSYNC_INSTRUCTION_IGNORE
                && item._instruction != CSYNC_INSTRUCTION_ERROR) {
                // Mark this path as syncing for instructions that will result in propagation.
                inc_sync_count_and_emit_status_changed (item.destination (), shared_flag);
            } else {
                emit file_status_changed (get_system_destination (item.destination ()), resolve_sync_and_error_status (item.destination (), shared_flag));
            }
        }
    
        // Some metadata status won't trigger files to be synced, make sure that we
        // push the OK status for dirty files that don't need to be propagated.
        // Swap into a copy since file_status () reads _dirty_paths to determine the status
        QSet<string> old_dirty_paths;
        std.swap (_dirty_paths, old_dirty_paths);
        for (auto &old_dirty_path : q_as_const (old_dirty_paths))
            emit file_status_changed (get_system_destination (old_dirty_path), file_status (old_dirty_path));
    
        // Make sure to push any status that might have been resolved indirectly since the last sync
        // (like an error file being deleted from disk)
        for (auto &sync_problem : _sync_problems)
            old_problems.erase (sync_problem.first);
        for (auto &old_problem : old_problems) {
            const string &path = old_problem.first;
            SyncFileStatus.SyncFileStatusTag severity = old_problem.second;
            if (severity == SyncFileStatus.SyncFileStatusTag.STATUS_ERROR)
                invalidate_parent_paths (path);
            emit file_status_changed (get_system_destination (path), file_status (path));
        }
    }
    
    void SyncFileStatusTracker.slot_item_completed (SyncFileItemPtr &item) {
        q_c_debug (lc_status_tracker) << "Item completed" << item.destination () << item._status << item._instruction;
    
        if (has_error_status (*item)) {
            _sync_problems[item.destination ()] = SyncFileStatus.SyncFileStatusTag.STATUS_ERROR;
            invalidate_parent_paths (item.destination ());
        } else if (has_excluded_status (*item)) {
            _sync_problems[item.destination ()] = SyncFileStatus.SyncFileStatusTag.STATUS_EXCLUDED;
        } else {
            _sync_problems.erase (item.destination ());
        }
    
        Shared_flag shared_flag = item._remote_perm.has_permission (RemotePermissions.Is_shared) ? Shared : Not_shared;
        if (item._instruction != CSYNC_INSTRUCTION_NONE
            && item._instruction != CSYNC_INSTRUCTION_UPDATE_METADATA
            && item._instruction != CSYNC_INSTRUCTION_IGNORE
            && item._instruction != CSYNC_INSTRUCTION_ERROR) {
            // dec_sync_count calls *must* be symetric with inc_sync_count calls in slot_about_to_propagate
            dec_sync_count_and_emit_status_changed (item.destination (), shared_flag);
        } else {
            emit file_status_changed (get_system_destination (item.destination ()), resolve_sync_and_error_status (item.destination (), shared_flag));
        }
    }
    
    void SyncFileStatusTracker.slot_sync_finished () {
        // Clear the sync counts to reduce the impact of unsymetrical inc/dec calls (e.g. when directory job abort)
        QHash<string, int> old_sync_count;
        std.swap (_sync_count, old_sync_count);
        for (auto it = old_sync_count.begin (); it != old_sync_count.end (); ++it) {
            // Don't announce folders, file_status expect only paths without '/', otherwise it asserts
            if (it.key ().ends_with ('/')) {
                continue;
            }
    
            emit file_status_changed (get_system_destination (it.key ()), file_status (it.key ()));
        }
    }
    
    void SyncFileStatusTracker.slot_sync_engine_running_changed () {
        emit file_status_changed (get_system_destination (string ()), resolve_sync_and_error_status (string (), Not_shared));
    }
    
    SyncFileStatus SyncFileStatusTracker.resolve_sync_and_error_status (string &relative_path, Shared_flag shared_flag, Path_known_flag is_path_known) {
        // If it's a new file and that we're not syncing it yet,
        // don't show any icon and wait for the filesystem watcher to trigger a sync.
        SyncFileStatus status (is_path_known ? SyncFileStatus.SyncFileStatusTag.STATUS_UP_TO_DATE : SyncFileStatus.SyncFileStatusTag.STATUS_NONE);
        if (_sync_count.value (relative_path)) {
            status.set (SyncFileStatus.SyncFileStatusTag.STATUS_SYNC);
        } else {
            // After a sync finished, we need to show the users issues from that last sync like the activity list does.
            // Also used for parent directories showing a warning for an error child.
            SyncFileStatus.SyncFileStatusTag problem_status = lookup_problem (relative_path, _sync_problems);
            if (problem_status != SyncFileStatus.SyncFileStatusTag.STATUS_NONE)
                status.set (problem_status);
        }
    
        ASSERT (shared_flag != Unknown_shared,
            "The shared status needs to have been fetched from a SyncFileItem or the DB at this point.");
        if (shared_flag == Shared)
            status.set_shared (true);
    
        return status;
    }
    
    void SyncFileStatusTracker.invalidate_parent_paths (string &path) {
        QStringList split_path = path.split ('/', Qt.Skip_empty_parts);
        for (int i = 0; i < split_path.size (); ++i) {
            string parent_path = QStringList (split_path.mid (0, i)).join (QLatin1String ("/"));
            emit file_status_changed (get_system_destination (parent_path), file_status (parent_path));
        }
    }
    
    string SyncFileStatusTracker.get_system_destination (string &relative_path) {
        string system_path = _sync_engine.local_path () + relative_path;
        // SyncEngine.local_path () has a trailing slash, make sure to remove it if the
        // destination is empty.
        if (system_path.ends_with (QLatin1Char ('/'))) {
            system_path.truncate (system_path.length () - 1);
        }
        return system_path;
    }
    }
    