/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <set>

namespace Occ {

/***********************************************************
@brief Tracks files that must be rediscovered locally

It does this by being notified about
- modified files (add_touched_path
- starting syncs (on_start_sync* ())
- on_finished items (on_item_completed (), by SyncEngine signal)
- on_finished syncs (on_sync_finished (), by SyncEngine signal)

Then local_discovery_paths () can be used to determine paths to redis
and send to SyncEngine.local_disco

This class is primarily used from Folder and separate primarily for
readability and testing purposes.

All paths used in this class are expected to be utf8 encoded byte arrays,
relative to the folder that is being synced, without a starting slash.

@ingroup libsync
***********************************************************/
class LocalDiscoveryTracker : GLib.Object {

    struct SyncFileItemPtr : unowned SyncFileItem { }


    /***********************************************************
    The paths that should be checked by the next local discovery.

    Mostly a collection of files the filewatchers have reported as touched.
    Also includes files that have had errors in the last sync run.
    ***********************************************************/
    private GLib.Set<string> local_discovery_paths;


    /***********************************************************
    The paths that the current sync run used for local discovery.

    For failing syncs, this list will be merged into
    this.local_discovery_paths again when the sync is done to
    make sure everything is retried.
    ***********************************************************/
    private GLib.Set<string> previous_local_discovery_paths;


    /***********************************************************
    ***********************************************************/
    public LocalDiscoveryTracker () = default;


    /***********************************************************
    Adds a path that must be locally rediscovered later.

    This should be a full relative file path, example:
    foo/bar/file.txt
    ***********************************************************/
    public void add_touched_path (string relative_path) {
        GLib.debug (lc_local_discovery_tracker) << "inserted touched" << relative_path;
        this.local_discovery_paths.insert (relative_path);
    }


    /***********************************************************
    Call when a sync run starts that rediscovers all local files
    ***********************************************************/
    public void start_sync_full_discovery () {
        this.local_discovery_paths.clear ();
        this.previous_local_discovery_paths.clear ();
        GLib.debug (lc_local_discovery_tracker) << "full discovery";
    }


    /***********************************************************
    Call when a sync using local_discovery_paths () starts
    ***********************************************************/
    public void start_sync_partial_discovery () {
        if (lc_local_discovery_tracker ().is_debug_enabled ()) {
            string[] paths;
            for (var path : this.local_discovery_paths)
                paths.append (path);
            GLib.debug (lc_local_discovery_tracker) << "partial discovery with paths : " << paths;
        }

        this.previous_local_discovery_paths = std.move (this.local_discovery_paths);
        this.local_discovery_paths.clear ();
    }


    /***********************************************************
    Access list of files that shall be locally rediscovered.
    ***********************************************************/
    public GLib.Set<string> local_discovery_paths () {
        return this.local_discovery_paths;
    }


    /***********************************************************
    Success and failure of sync items adjust what the next sync is
    supposed to do.
    ***********************************************************/
    public void on_item_completed (SyncFileItemPtr item) {
        // For successes, we want to wipe the file from the list to ensure we don't
        // rediscover it even if this overall sync fails.
        //
        // For failures, we want to add the file to the list so the next sync
        // will be able to retry it.
        if (item.status == SyncFileItem.Status.SUCCESS
            || item.status == SyncFileItem.Status.FILE_IGNORED
            || item.status == SyncFileItem.Status.RESTORATION
            || item.status == SyncFileItem.Status.CONFLICT
            || (item.status == SyncFileItem.Status.NO_STATUS
                && (item.instruction == CSYNC_INSTRUCTION_NONE
                        || item.instruction == CSYNC_INSTRUCTION_UPDATE_METADATA))) {
            if (this.previous_local_discovery_paths.erase (item.file.to_utf8 ()))
                GLib.debug (lc_local_discovery_tracker) << "wiped successful item" << item.file;
            if (!item.rename_target.is_empty () && this.previous_local_discovery_paths.erase (item.rename_target.to_utf8 ()))
                GLib.debug (lc_local_discovery_tracker) << "wiped successful item" << item.rename_target;
        } else {
            this.local_discovery_paths.insert (item.file.to_utf8 ());
            GLib.debug (lc_local_discovery_tracker) << "inserted error item" << item.file;
        }
    }


    /***********************************************************
    When a sync finishes, the lists must be updated
    ***********************************************************/
    public void on_sync_finished (bool on_success) {
        if (on_success) {
            GLib.debug (lc_local_discovery_tracker) << "sync on_success, forgetting last sync's local discovery path list";
        } else {
            // On overall-failure we can't forget about last sync's local discovery
            // paths yet, reuse them for the next sync again.
            // C++17 : Could use std.set.merge ().
            this.local_discovery_paths.insert (
                this.previous_local_discovery_paths.begin (), this.previous_local_discovery_paths.end ());
            GLib.debug (lc_local_discovery_tracker) << "sync failed, keeping last sync's local discovery path list";
        }
        this.previous_local_discovery_paths.clear ();
    }

} // class LocalDiscoveryTracker

} // namespace Occ

//  #endif
