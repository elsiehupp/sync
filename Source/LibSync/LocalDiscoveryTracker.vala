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
- modified files (addTouchedPath
- starting syncs (startSync* ())
- finished items (slotItemCompleted (), by SyncEngine signal)
- finished syncs (slotSyncFinished (), by SyncEngine signal)

Then localDiscoveryPaths () can be used to determine paths to redis
and send to SyncEngine.setLocalDisco

This class is primarily used from Folder and separate primarily for
readability and testing purposes.

All paths used in this class are expected to be utf8 encoded byte arrays,
relative to the folder that is being synced, without a starting slash.

@ingroup libsync
***********************************************************/
class LocalDiscoveryTracker : GLib.Object {
public:
    LocalDiscoveryTracker ();

    /***********************************************************
    Adds a path that must be locally rediscovered later.

    This should be a full relative file path, example:
      foo/bar/file.txt
    ***********************************************************/
    void addTouchedPath (string &relativePath);

    /***********************************************************
    Call when a sync run starts that rediscovers all local files */
    void startSyncFullDiscovery ();

    /***********************************************************
    Call when a sync using localDiscoveryPaths () starts */
    void startSyncPartialDiscovery ();

    /***********************************************************
    Access list of files that shall be locally rediscovered. */
    const std.set<string> &localDiscoveryPaths ();

public slots:
    /***********************************************************
    Success and failure of sync items adjust what the next sync is
    supposed to do.
    ***********************************************************/
    void slotItemCompleted (SyncFileItemPtr &item);

    /***********************************************************
    When a sync finishes, the lists must be updated
    ***********************************************************/
    void slotSyncFinished (bool success);

private:
    /***********************************************************
    The paths that should be checked by the next local discovery.
    
    Mostly a collection of files the filewatchers have reported as touched.
     * Also includes files that have had errors in the last sync run.
    ***********************************************************/
    std.set<string> _localDiscoveryPaths;

    /***********************************************************
    The paths that the current sync run used for local discovery.
    
    For failing syncs, this list will be merged into _localDiscoveryPaths
     * again when the sync is done to make sure everything is retried.
    ***********************************************************/
    std.set<string> _previousLocalDiscoveryPaths;
};

} // namespace Occ

#endif









LocalDiscoveryTracker.LocalDiscoveryTracker () = default;

void LocalDiscoveryTracker.addTouchedPath (string &relativePath) {
    qCDebug (lcLocalDiscoveryTracker) << "inserted touched" << relativePath;
    _localDiscoveryPaths.insert (relativePath);
}

void LocalDiscoveryTracker.startSyncFullDiscovery () {
    _localDiscoveryPaths.clear ();
    _previousLocalDiscoveryPaths.clear ();
    qCDebug (lcLocalDiscoveryTracker) << "full discovery";
}

void LocalDiscoveryTracker.startSyncPartialDiscovery () {
    if (lcLocalDiscoveryTracker ().isDebugEnabled ()) {
        QStringList paths;
        for (auto &path : _localDiscoveryPaths)
            paths.append (path);
        qCDebug (lcLocalDiscoveryTracker) << "partial discovery with paths : " << paths;
    }

    _previousLocalDiscoveryPaths = std.move (_localDiscoveryPaths);
    _localDiscoveryPaths.clear ();
}

const std.set<string> &LocalDiscoveryTracker.localDiscoveryPaths () {
    return _localDiscoveryPaths;
}

void LocalDiscoveryTracker.slotItemCompleted (SyncFileItemPtr &item) {
    // For successes, we want to wipe the file from the list to ensure we don't
    // rediscover it even if this overall sync fails.
    //
    // For failures, we want to add the file to the list so the next sync
    // will be able to retry it.
    if (item._status == SyncFileItem.Success
        || item._status == SyncFileItem.FileIgnored
        || item._status == SyncFileItem.Restoration
        || item._status == SyncFileItem.Conflict
        || (item._status == SyncFileItem.NoStatus
               && (item._instruction == CSYNC_INSTRUCTION_NONE
                      || item._instruction == CSYNC_INSTRUCTION_UPDATE_METADATA))) {
        if (_previousLocalDiscoveryPaths.erase (item._file.toUtf8 ()))
            qCDebug (lcLocalDiscoveryTracker) << "wiped successful item" << item._file;
        if (!item._renameTarget.isEmpty () && _previousLocalDiscoveryPaths.erase (item._renameTarget.toUtf8 ()))
            qCDebug (lcLocalDiscoveryTracker) << "wiped successful item" << item._renameTarget;
    } else {
        _localDiscoveryPaths.insert (item._file.toUtf8 ());
        qCDebug (lcLocalDiscoveryTracker) << "inserted error item" << item._file;
    }
}

void LocalDiscoveryTracker.slotSyncFinished (bool success) {
    if (success) {
        qCDebug (lcLocalDiscoveryTracker) << "sync success, forgetting last sync's local discovery path list";
    } else {
        // On overall-failure we can't forget about last sync's local discovery
        // paths yet, reuse them for the next sync again.
        // C++17 : Could use std.set.merge ().
        _localDiscoveryPaths.insert (
            _previousLocalDiscoveryPaths.begin (), _previousLocalDiscoveryPaths.end ());
        qCDebug (lcLocalDiscoveryTracker) << "sync failed, keeping last sync's local discovery path list";
    }
    _previousLocalDiscoveryPaths.clear ();
}
