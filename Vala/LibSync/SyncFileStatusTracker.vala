/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Jocelyn Turcotte <jturcotte@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <map>

namespace Occ {

/***********************************************************
@brief Takes care of tracking the status of individual
files as they go through the SyncEngine, to be reported as
overlay icons in the shell.
@ingroup libsync
***********************************************************/
class SyncFileStatusTracker : GLib.Object {


    /***********************************************************
    ***********************************************************/
    private struct PathComparator {
        //  private bool operator () (string lhs, string rhs) {
        //      // This will make sure that the std.map is ordered and queried case-insensitively on macOS and Windows.
        //      return path_compare (lhs, rhs) < 0;
        //  }
    }


    /***********************************************************
    ***********************************************************/
    private class ProblemsMap : GLib.HashTable<string, SyncFileStatus.SyncFileStatusTag, PathComparator> { }


    /***********************************************************
    ***********************************************************/
    private enum SharedFlag {
        UNKNOWN_SHARED,
        NOT_SHARED,
        SHARED
    }


    /***********************************************************
    ***********************************************************/
    private enum PathKnownFlag {
        PATH_UNKNOWN = 0,
        PATH_KNOWN
    }


    /***********************************************************
    ***********************************************************/
    private SyncEngine sync_engine;


    /***********************************************************
    ***********************************************************/
    private ProblemsMap sync_problems;


    /***********************************************************
    ***********************************************************/
    private GLib.List<string> dirty_paths;


    /***********************************************************
    Counts the number direct children currently being synced
    (has unfinished propagation jobs). We'll show a
    file/directory as SYNC as long as its sync count is > 0.
    A directory that starts/ends propagation will in turn
    increase/decrease its own parent by 1.
    ***********************************************************/
    private GLib.HashTable<string, int> sync_count;


    signal void file_status_changed (string system_filename, SyncFileStatus file_status);


    /***********************************************************
    ***********************************************************/
    public SyncFileStatusTracker (SyncEngine sync_engine) {
        this.sync_engine = sync_engine;
        connect (sync_engine, SyncEngine.about_to_propagate,
            this, SyncFileStatusTracker.on_signal_about_to_propagate);
        connect (sync_engine, SyncEngine.item_completed,
            this, SyncFileStatusTracker.on_signal_item_completed);
        connect (sync_engine, SyncEngine.on_signal_finished, this, SyncFileStatusTracker.on_signal_sync_finished);
        connect (sync_engine, SyncEngine.started, this, SyncFileStatusTracker.on_signal_sync_engine_running_changed);
        connect (sync_engine, SyncEngine.on_signal_finished, this, SyncFileStatusTracker.on_signal_sync_engine_running_changed);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_path_touched (string filename) {
        string folder_path = this.sync_engine.local_path ();

        //  ASSERT (filename.starts_with (folder_path));
        string local_path = filename.mid (folder_path.size ());
        this.dirty_paths.insert (local_path);

        /* emit */ file_status_changed (filename, SyncFileStatus.SyncFileStatusTag.STATUS_SYNC);
    }


    /***********************************************************
    Path relative to folder
    ***********************************************************/
    public void on_signal_add_silently_excluded (string folder_path) {
        this.sync_problems[folder_path] = SyncFileStatus.SyncFileStatusTag.STATUS_EXCLUDED;
        /* emit */ file_status_changed (get_system_destination (folder_path), resolve_sync_and_error_status (folder_path, SharedFlag.NOT_SHARED));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_about_to_propagate (SyncFileItemVector items) {
        //  ASSERT (this.sync_count.is_empty ());

        ProblemsMap old_problems;
        std.swap (this.sync_problems, old_problems);

        foreach (SyncFileItemPtr item in items) {
            GLib.debug ("Investigating " + item.destination () + item.status + item.instruction);
            this.dirty_paths.remove (item.destination ());

            if (has_error_status (*item)) {
                this.sync_problems[item.destination ()] = SyncFileStatus.SyncFileStatusTag.STATUS_ERROR;
                invalidate_parent_paths (item.destination ());
            } else if (has_excluded_status (*item)) {
                this.sync_problems[item.destination ()] = SyncFileStatus.SyncFileStatusTag.STATUS_EXCLUDED;
            }

            SharedFlag shared_flag = item.remote_perm.has_permission (RemotePermissions.Permissions.IS_SHARED) ? SharedFlag.SHARED : SharedFlag.NOT_SHARED;
            if (item.instruction != CSYNC_INSTRUCTION_NONE
                && item.instruction != CSYNC_INSTRUCTION_UPDATE_METADATA
                && item.instruction != CSYNC_INSTRUCTION_IGNORE
                && item.instruction != CSYNC_INSTRUCTION_ERROR) {
                // Mark this path as syncing for instructions that will result in propagation.
                inc_sync_count_and_emit_status_changed (item.destination (), shared_flag);
            } else {
                /* emit */ file_status_changed (get_system_destination (item.destination ()), resolve_sync_and_error_status (item.destination (), shared_flag));
            }
        }

        // Some metadata status won't trigger files to be synced, make sure that we
        // push the OK status for dirty files that don't need to be propagated.
        // Swap into a copy since file_status () reads this.dirty_paths to determine the status
        GLib.List<string> old_dirty_paths;
        std.swap (this.dirty_paths, old_dirty_paths);
        foreach (var old_dirty_path in q_as_const (old_dirty_paths))
            /* emit */ file_status_changed (get_system_destination (old_dirty_path), file_status (old_dirty_path));

        // Make sure to push any status that might have been resolved indirectly since the last sync
        // (like an error file being deleted from disk)
        foreach (var sync_problem in this.sync_problems)
            old_problems.erase (sync_problem.first);
        foreach (var old_problem in old_problems) {
            const string path = old_problem.first;
            SyncFileStatus.SyncFileStatusTag severity = old_problem.second;
            if (severity == SyncFileStatus.SyncFileStatusTag.STATUS_ERROR)
                invalidate_parent_paths (path);
            /* emit */ file_status_changed (get_system_destination (path), file_status (path));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_item_completed (SyncFileItemPtr item) {
        GLib.debug ("Item completed " + item.destination () + item.status + item.instruction);

        if (has_error_status (*item)) {
            this.sync_problems[item.destination ()] = SyncFileStatus.SyncFileStatusTag.STATUS_ERROR;
            invalidate_parent_paths (item.destination ());
        } else if (has_excluded_status (*item)) {
            this.sync_problems[item.destination ()] = SyncFileStatus.SyncFileStatusTag.STATUS_EXCLUDED;
        } else {
            this.sync_problems.erase (item.destination ());
        }

        SharedFlag shared_flag = item.remote_perm.has_permission (RemotePermissions.Permissions.IS_SHARED) ? SharedFlag.SHARED : SharedFlag.NOT_SHARED;
        if (item.instruction != CSYNC_INSTRUCTION_NONE
            && item.instruction != CSYNC_INSTRUCTION_UPDATE_METADATA
            && item.instruction != CSYNC_INSTRUCTION_IGNORE
            && item.instruction != CSYNC_INSTRUCTION_ERROR) {
            // dec_sync_count calls must* be symetric with inc_sync_count calls in on_signal_about_to_propagate
            dec_sync_count_and_emit_status_changed (item.destination (), shared_flag);
        } else {
            /* emit */ file_status_changed (get_system_destination (item.destination ()), resolve_sync_and_error_status (item.destination (), shared_flag));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sync_finished () {
        // Clear the sync counts to reduce the impact of unsymetrical inc/dec calls (e.g. when directory job on_signal_abort)
        GLib.HashTable<string, int> old_sync_count;
        std.swap (this.sync_count, old_sync_count);
        for (var it = old_sync_count.begin (); it != old_sync_count.end (); ++it) {
            // Don't announce folders, file_status expect only paths without '/', otherwise it asserts
            if (it.key ().has_suffix ('/')) {
                continue;
            }

            /* emit */ file_status_changed (get_system_destination (it.key ()), file_status (it.key ()));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sync_engine_running_changed () {
        /* emit */ file_status_changed (get_system_destination (""), resolve_sync_and_error_status ("", SharedFlag.NOT_SHARED));
    }


    /***********************************************************
    ***********************************************************/
    private SyncFileStatus.SyncFileStatusTag lookup_problem (string path_to_match, ProblemsMap problem_map) {
        var lower = problem_map.lower_bound (path_to_match);
        for (var it = lower; it != problem_map.cend (); ++it) {
            const string problem_path = it.first;
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
    ***********************************************************/
    private SyncFileStatus resolve_sync_and_error_status (string relative_path, SharedFlag shared_state, PathKnownFlag is_path_known = PathKnownFlag.PATH_KNOWN) {
        // If it's a new file and that we're not syncing it yet,
        // don't show any icon and wait for the filesystem watcher to trigger a sync.
        SyncFileStatus status = new SyncFileStatus (is_path_known ? SyncFileStatus.SyncFileStatusTag.STATUS_UP_TO_DATE : SyncFileStatus.SyncFileStatusTag.STATUS_NONE);
        if (this.sync_count.value (relative_path)) {
            status.set (SyncFileStatus.SyncFileStatusTag.STATUS_SYNC);
        } else {
            // After a sync on_signal_finished, we need to show the users issues from that last sync like the activity list does.
            // Also used for parent directories showing a warning for an error child.
            SyncFileStatus.SyncFileStatusTag problem_status = lookup_problem (relative_path, this.sync_problems);
            if (problem_status != SyncFileStatus.SyncFileStatusTag.STATUS_NONE)
                status.set (problem_status);
        }

        //  ASSERT (shared_flag != SharedFlag.UNKNOWN_SHARED,
        //      "The shared status needs to have been fetched from a SyncFileItem or the DB at this point.");
        if (shared_flag == SharedFlag.SHARED)
            status.shared (true);

        return status;
    }


    /***********************************************************
    ***********************************************************/
    private void invalidate_parent_paths (string path) {
        string[] split_path = path.split ("/", Qt.SkipEmptyParts);
        for (int i = 0; i < split_path.size (); ++i) {
            string parent_path = split_path.mid (0, i).join ("/");
            /* emit */ file_status_changed (get_system_destination (parent_path), file_status (parent_path));
        }
    }


    /***********************************************************
    ***********************************************************/
    private string get_system_destination (string relative_path) {
        string system_path = this.sync_engine.local_path () + relative_path;
        // SyncEngine.local_path () has a trailing slash, make sure to remove it if the
        // destination is empty.
        if (system_path.has_suffix ('/')) {
            system_path.truncate (system_path.length () - 1);
        }
        return system_path;
    }


    /***********************************************************
    ***********************************************************/
    private void inc_sync_count_and_emit_status_changed (string relative_path, SharedFlag shared_state) {
        // Will return 0 (and increase to 1) if the path wasn't in the map yet
        int count = this.sync_count[relative_path]++;
        if (!count) {
            SyncFileStatus status = shared_flag == SharedFlag.UNKNOWN_SHARED
                ? file_status (relative_path)
                : resolve_sync_and_error_status (relative_path, shared_flag);
            /* emit */ file_status_changed (get_system_destination (relative_path), status);

            // We passed from OK to SYNC, increment the parent to keep it marked as
            // SYNC while we propagate ourselves and our own children.
            //  ASSERT (!relative_path.has_suffix ('/'));
            int last_slash_index = relative_path.last_index_of ('/');
            if (last_slash_index != -1)
                inc_sync_count_and_emit_status_changed (relative_path.left (last_slash_index), SharedFlag.UNKNOWN_SHARED);
            else if (!relative_path.is_empty ())
                inc_sync_count_and_emit_status_changed ("", SharedFlag.UNKNOWN_SHARED);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void dec_sync_count_and_emit_status_changed (string relative_path, SharedFlag shared_state) {
        int count = --this.sync_count[relative_path];
        if (!count) {
            // Remove from the map, same as 0
            this.sync_count.remove (relative_path);

            SyncFileStatus status = shared_flag == SharedFlag.UNKNOWN_SHARED
                ? file_status (relative_path)
                : resolve_sync_and_error_status (relative_path, shared_flag);
            /* emit */ file_status_changed (get_system_destination (relative_path), status);

            // We passed from SYNC to OK, decrement our parent.
            //  ASSERT (!relative_path.has_suffix ('/'));
            int last_slash_index = relative_path.last_index_of ('/');
            if (last_slash_index != -1)
                dec_sync_count_and_emit_status_changed (relative_path.left (last_slash_index), SharedFlag.UNKNOWN_SHARED);
            else if (!relative_path.is_empty ())
                dec_sync_count_and_emit_status_changed ("", SharedFlag.UNKNOWN_SHARED);
        }
    }


    /***********************************************************
    ***********************************************************/
    private SyncFileStatus file_status (string relative_path) {
        //  ASSERT (!relative_path.has_suffix ('/'));

        if (relative_path.is_empty ()) {
            // This is the root sync folder, it doesn't have an entry in the database and won't be walked by csync, so resolve manually.
            return resolve_sync_and_error_status ("", SharedFlag.NOT_SHARED);
        }

        // The SyncEngine won't notify us at all for CSYNC_FILE_SILENTLY_EXCLUDED
        // and CSYNC_FILE_EXCLUDE_AND_REMOVE excludes. Even though it's possible
        // that the status of CSYNC_FILE_EXCLUDE_LIST excludes will change if the user
        // update the exclude list at runtime and doing it statically here removes
        // our ability to notify changes through the file_status_changed signal,
        // it's an acceptable compromize to treat all exclude types the same.
        // Update : This extra check shouldn't hurt even though silently excluded files
        // are now available via on_signal_add_silently_excluded ().
        if (this.sync_engine.excluded_files ().is_excluded (this.sync_engine.local_path () + relative_path,
                this.sync_engine.local_path (),
                this.sync_engine.ignore_hidden_files ())) {
            return SyncFileStatus.SyncFileStatusTag.STATUS_EXCLUDED;
        }

        if (this.dirty_paths.contains (relative_path))
            return SyncFileStatus.SyncFileStatusTag.STATUS_SYNC;

        // First look it up in the database to know if it's shared
        SyncJournalFileRecord record;
        if (this.sync_engine.journal ().get_file_record (relative_path, record) && record.is_valid ()) {
            return resolve_sync_and_error_status (relative_path, record.remote_perm.has_permission (RemotePermissions.Permissions.IS_SHARED) ? SharedFlag.SHARED : SharedFlag.NOT_SHARED);
        }

        // Must be a new file not yet in the database, check if it's syncing or has an error.
        return resolve_sync_and_error_status (relative_path, SharedFlag.NOT_SHARED, PathKnownFlag.PATH_UNKNOWN);
    }


    /***********************************************************
    ***********************************************************/
    private static int path_compare (string lhs, string rhs) {
        // Should match Utility.fs_case_preserving, we want don't want to pay for the runtime check on every comparison.
        return lhs.compare (rhs, Qt.CaseSensitive);
    }


    /***********************************************************
    ***********************************************************/
    private static bool path_starts_with (string lhs, string rhs) {
        return lhs.starts_with (rhs, Qt.CaseSensitive);
    }


    /***********************************************************
    Whether this item should get an ERROR icon through the
    Socket API.

    The Socket API should only present serious, permanent errors
    to the user. In particular Soft_errors should just retain
    their 'needs to be synced' icon as the problem is most
    likely going to resolve itself quickly and automatically.
    ***********************************************************/
    private static bool has_error_status (SyncFileItem item) {
        var status = item.status;
        return item.instruction == CSYNC_INSTRUCTION_ERROR
            || status == SyncFileItem.Status.NORMAL_ERROR
            || status == SyncFileItem.Status.FATAL_ERROR
            || status == SyncFileItem.Status.DETAIL_ERROR
            || status == SyncFileItem.Status.BLOCKLISTED_ERROR
            || item.has_blocklist_entry;
    }


    /***********************************************************
    ***********************************************************/
    private static bool has_excluded_status (SyncFileItem item) {
        var status = item.status;
        return item.instruction == CSYNC_INSTRUCTION_IGNORE
            || status == SyncFileItem.Status.FILE_IGNORED
            || status == SyncFileItem.Status.CONFLICT
            || status == SyncFileItem.Status.RESTORATION
            || status == SyncFileItem.Status.FILE_LOCKED;
    }

} // class SyncFileStatusTracker

} // namespace Occ
