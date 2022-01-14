/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QTimer>

using namespace Occ;

static const int check_frequency = 20 * 1000; // ms

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

    public LockWatcher (GLib.Object *parent = nullptr);

    /***********************************************************
    Start watching a file.

    If the file is not locked later on, the file_unlocked signal will be
    emitted once.
    ***********************************************************/
    public void add_file (string &path);

    /***********************************************************
    Adjusts the default interval for checking whether the lock is still present
    ***********************************************************/
    public void set_check_interval (std.chrono.milliseconds interval);

    /***********************************************************
    Whether the path is being watched for lock-changes
    ***********************************************************/
    public bool contains (string &path);

signals:
    /***********************************************************
    Emitted when one of the watched files is no longer
    being locked.
    ***********************************************************/
    void file_unlocked (string &path);

private slots:
    void check_files ();

private:
    QSet<string> _watched_paths;
    QTimer _timer;
};
}








LockWatcher.LockWatcher (GLib.Object *parent)
    : GLib.Object (parent) {
    connect (&_timer, &QTimer.timeout,
        this, &LockWatcher.check_files);
    _timer.start (check_frequency);
}

void LockWatcher.add_file (string &path) {
    q_c_info (lc_lock_watcher) << "Watching for lock of" << path << "being released";
    _watched_paths.insert (path);
}

void LockWatcher.set_check_interval (std.chrono.milliseconds interval) {
    _timer.start (interval.count ());
}

bool LockWatcher.contains (string &path) {
    return _watched_paths.contains (path);
}

void LockWatcher.check_files () {
    QSet<string> unlocked;

    foreach (string &path, _watched_paths) {
        if (!FileSystem.is_file_locked (path)) {
            q_c_info (lc_lock_watcher) << "Lock of" << path << "was released";
            emit file_unlocked (path);
            unlocked.insert (path);
        }
    }

    // Doing it this way instead of with a QMutableSetIterator
    // ensures that calling back into add_file from connected
    // slots isn't a problem.
    _watched_paths.subtract (unlocked);
}
