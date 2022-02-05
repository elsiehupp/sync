/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <QTimer>

//  #pragma once

//  #include <QTimer>
//  #include <chrono>

namespace Occ {
namespace Ui {

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

    const int check_frequency = 20 * 1000; // ms

    /***********************************************************
    ***********************************************************/
    public LockWatcher (GLib.Object parent = new GLib.Object ());


    /***********************************************************
    Start watching a file.

    If the file is not locked later on, the file_unlocked signal will be
    emitted once.
    ***********************************************************/
    public void add_file (string path);


    /***********************************************************
    Adjusts the default interval for checking whether the lock is still present
    ***********************************************************/
    public void check_interval (std.chrono.milliseconds interval);


    /***********************************************************
    Whether the path is being watched for lock-changes
    ***********************************************************/
    public bool contains (string path);

signals:
    /***********************************************************
    Emitted when one of the watched files is no longer
    being locked.
    ***********************************************************/
    void file_unlocked (string path);


    /***********************************************************
    ***********************************************************/
    private void on_check_files ();

    /***********************************************************
    ***********************************************************/
    private 
    private GLib.Set<string> this.watched_paths;
    private QTimer this.timer;
}
}








LockWatcher.LockWatcher (GLib.Object parent) {
    base (parent);
    connect (&this.timer, &QTimer.timeout,
        this, &LockWatcher.on_check_files);
    this.timer.on_start (check_frequency);
}

void LockWatcher.add_file (string path) {
    GLib.info (lc_lock_watcher) << "Watching for lock of" << path << "being released";
    this.watched_paths.insert (path);
}

void LockWatcher.check_interval (std.chrono.milliseconds interval) {
    this.timer.on_start (interval.count ());
}

bool LockWatcher.contains (string path) {
    return this.watched_paths.contains (path);
}

void LockWatcher.on_check_files () {
    GLib.Set<string> unlocked;

    foreach (string path, this.watched_paths) {
        if (!FileSystem.is_file_locked (path)) {
            GLib.info (lc_lock_watcher) << "Lock of" << path << "was released";
            /* emit */ file_unlocked (path);
            unlocked.insert (path);
        }
    }

    // Doing it this way instead of with a QMutableSetIterator
    // ensures that calling back into add_file from connected
    // slots isn't a problem.
    this.watched_paths.subtract (unlocked);
}
