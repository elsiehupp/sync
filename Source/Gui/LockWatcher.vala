/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QList>
// #include <GLib.Object>
// #include <string>
// #include <QSet>
// #include <QTimer>

// #include <chrono>

namespace Occ {

/***********************************************************
@brief Monitors files that are locked, signaling when they become unlocked

Only relevant on Windows. Some high-profile applications like Microsoft
Word lock the document that is currently being edited. The syn
client will be unable to update them while they are locked.

In this situation we do want to st
becomes available again. To do that, we need to regularly check whether
the file is still being locked.

@ingroup gui
***********************************************************/

class LockWatcher : GLib.Object {
public:
    LockWatcher (GLib.Object *parent = nullptr);

    /** Start watching a file.
     *
     * If the file is not locked later on, the fileUnlocked signal will be
     * emitted once.
     */
    void addFile (string &path);

    /** Adjusts the default interval for checking whether the lock is still present */
    void setCheckInterval (std.chrono.milliseconds interval);

    /** Whether the path is being watched for lock-changes */
    bool contains (string &path);

signals:
    /** Emitted when one of the watched files is no longer
     *  being locked. */
    void fileUnlocked (string &path);

private slots:
    void checkFiles ();

private:
    QSet<string> _watchedPaths;
    QTimer _timer;
};
}







/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QTimer>

using namespace Occ;

Q_LOGGING_CATEGORY (lcLockWatcher, "nextcloud.gui.lockwatcher", QtInfoMsg)

static const int check_frequency = 20 * 1000; // ms

LockWatcher.LockWatcher (GLib.Object *parent)
    : GLib.Object (parent) {
    connect (&_timer, &QTimer.timeout,
        this, &LockWatcher.checkFiles);
    _timer.start (check_frequency);
}

void LockWatcher.addFile (string &path) {
    qCInfo (lcLockWatcher) << "Watching for lock of" << path << "being released";
    _watchedPaths.insert (path);
}

void LockWatcher.setCheckInterval (std.chrono.milliseconds interval) {
    _timer.start (interval.count ());
}

bool LockWatcher.contains (string &path) {
    return _watchedPaths.contains (path);
}

void LockWatcher.checkFiles () {
    QSet<string> unlocked;

    foreach (string &path, _watchedPaths) {
        if (!FileSystem.isFileLocked (path)) {
            qCInfo (lcLockWatcher) << "Lock of" << path << "was released";
            emit fileUnlocked (path);
            unlocked.insert (path);
        }
    }

    // Doing it this way instead of with a QMutableSetIterator
    // ensures that calling back into addFile from connected
    // slots isn't a problem.
    _watchedPaths.subtract (unlocked);
}
