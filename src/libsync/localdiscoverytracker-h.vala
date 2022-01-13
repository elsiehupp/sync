/*
Copyright (C) by Christian Kamm <mail@ckamm.de>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <set>
// #include <GLib.Object>
// #include <QByteArray>
// #include <QSharedPointer>

namespace Occ {

using SyncFileItemPtr = QSharedPointer<SyncFileItem>;

/**
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
*/
class OWNCLOUDSYNC_EXPORT LocalDiscoveryTracker : GLib.Object {
public:
    LocalDiscoveryTracker ();

    /** Adds a path that must be locally rediscovered later.
     *
     * This should be a full relative file path, example:
     *   foo/bar/file.txt
     */
    void addTouchedPath (QString &relativePath);

    /** Call when a sync run starts that rediscovers all local files */
    void startSyncFullDiscovery ();

    /** Call when a sync using localDiscoveryPaths () starts */
    void startSyncPartialDiscovery ();

    /** Access list of files that shall be locally rediscovered. */
    const std.set<QString> &localDiscoveryPaths ();

public slots:
    /**
     * Success and failure of sync items adjust what the next sync is
     * supposed to do.
     */
    void slotItemCompleted (SyncFileItemPtr &item);

    /**
     * When a sync finishes, the lists must be updated
     */
    void slotSyncFinished (bool success);

private:
    /**
     * The paths that should be checked by the next local discovery.
     *
     * Mostly a collection of files the filewatchers have reported as touched.
     * Also includes files that have had errors in the last sync run.
     */
    std.set<QString> _localDiscoveryPaths;

    /**
     * The paths that the current sync run used for local discovery.
     *
     * For failing syncs, this list will be merged into _localDiscoveryPaths
     * again when the sync is done to make sure everything is retried.
     */
    std.set<QString> _previousLocalDiscoveryPaths;
};

} // namespace Occ

#endif
