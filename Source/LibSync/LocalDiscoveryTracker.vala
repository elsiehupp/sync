/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>

using namespace Occ;



// #include <set>
// #include <GLib.Object>
// #include <QByteArray>
// #include <QSharedPointer>

namespace Occ {

using SyncFileItemPtr = QSharedPointer<SyncFileItem>;

/***********************************************************
@brief Tracks files that must be rediscovered locally

It does this by being notified about
- modified files (add_touched_path
- starting syncs (start_sync* ())
- finished items (slot_item_completed (), by SyncEngine signal)
- finished syncs (slot_sync_finished (), by SyncEngine signal)

Then local_discovery_paths () can be used to determine paths to redis
and send to SyncEngine.set_local_disco

This class is primarily used from Folder and separate primarily for
readability and testing purposes.

All paths used in this class are expected to be utf8 encoded byte arrays,
relative to the folder that is being synced, without a starting slash.

@ingroup libsync
***********************************************************/
class Local_discovery_tracker : GLib.Object {
public:
    Local_discovery_tracker ();

    /***********************************************************
    Adds a path that must be locally rediscovered later.

    This should be a full relative file path, example:
      foo/bar/file.txt
    ***********************************************************/
    void add_touched_path (string &relative_path);

    /***********************************************************
    Call when a sync run starts that rediscovers all local files */
    void start_sync_full_discovery ();

    /***********************************************************
    Call when a sync using local_discovery_paths () starts */
    void start_sync_partial_discovery ();

    /***********************************************************
    Access list of files that shall be locally rediscovered. */
    const std.set<string> &local_discovery_paths ();

public slots:
    /***********************************************************
    Success and failure of sync items adjust what the next sync is
    supposed to do.
    ***********************************************************/
    void slot_item_completed (SyncFileItemPtr &item);

    /***********************************************************
    When a sync finishes, the lists must be updated
    ***********************************************************/
    void slot_sync_finished (bool success);

private:
    /***********************************************************
    The paths that should be checked by the next local discovery.
    
    Mostly a collection of files the filewatchers have reported as touched.
    Also includes files that have had errors in the last sync run.
    ***********************************************************/
    std.set<string> _local_discovery_paths;

    /***********************************************************
    The paths that the current sync run used for local discovery.
    
    For failing syncs, this list will be merged into _local_discovery_paths
    again when the sync is done to make sure everything is retried.
    ***********************************************************/
    std.set<string> _previous_local_discovery_paths;
};

} // namespace Occ

#endif









Local_discovery_tracker.Local_discovery_tracker () = default;

void Local_discovery_tracker.add_touched_path (string &relative_path) {
    q_c_debug (lc_local_discovery_tracker) << "inserted touched" << relative_path;
    _local_discovery_paths.insert (relative_path);
}

void Local_discovery_tracker.start_sync_full_discovery () {
    _local_discovery_paths.clear ();
    _previous_local_discovery_paths.clear ();
    q_c_debug (lc_local_discovery_tracker) << "full discovery";
}

void Local_discovery_tracker.start_sync_partial_discovery () {
    if (lc_local_discovery_tracker ().is_debug_enabled ()) {
        QStringList paths;
        for (auto &path : _local_discovery_paths)
            paths.append (path);
        q_c_debug (lc_local_discovery_tracker) << "partial discovery with paths : " << paths;
    }

    _previous_local_discovery_paths = std.move (_local_discovery_paths);
    _local_discovery_paths.clear ();
}

const std.set<string> &Local_discovery_tracker.local_discovery_paths () {
    return _local_discovery_paths;
}

void Local_discovery_tracker.slot_item_completed (SyncFileItemPtr &item) {
    // For successes, we want to wipe the file from the list to ensure we don't
    // rediscover it even if this overall sync fails.
    //
    // For failures, we want to add the file to the list so the next sync
    // will be able to retry it.
    if (item._status == SyncFileItem.Success
        || item._status == SyncFileItem.File_ignored
        || item._status == SyncFileItem.Restoration
        || item._status == SyncFileItem.Conflict
        || (item._status == SyncFileItem.No_status
               && (item._instruction == CSYNC_INSTRUCTION_NONE
                      || item._instruction == CSYNC_INSTRUCTION_UPDATE_METADATA))) {
        if (_previous_local_discovery_paths.erase (item._file.to_utf8 ()))
            q_c_debug (lc_local_discovery_tracker) << "wiped successful item" << item._file;
        if (!item._rename_target.is_empty () && _previous_local_discovery_paths.erase (item._rename_target.to_utf8 ()))
            q_c_debug (lc_local_discovery_tracker) << "wiped successful item" << item._rename_target;
    } else {
        _local_discovery_paths.insert (item._file.to_utf8 ());
        q_c_debug (lc_local_discovery_tracker) << "inserted error item" << item._file;
    }
}

void Local_discovery_tracker.slot_sync_finished (bool success) {
    if (success) {
        q_c_debug (lc_local_discovery_tracker) << "sync success, forgetting last sync's local discovery path list";
    } else {
        // On overall-failure we can't forget about last sync's local discovery
        // paths yet, reuse them for the next sync again.
        // C++17 : Could use std.set.merge ().
        _local_discovery_paths.insert (
            _previous_local_discovery_paths.begin (), _previous_local_discovery_paths.end ());
        q_c_debug (lc_local_discovery_tracker) << "sync failed, keeping last sync's local discovery path list";
    }
    _previous_local_discovery_paths.clear ();
}
