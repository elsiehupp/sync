/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QMetaType>
//  #include <QCoreApplication>
//  #include <QTime>
//  #include <QQueue>
//  #include <QElapsedTimer>
//  #include <QTimer>

namespace Occ {
namespace Progress {

/***********************************************************
@file progressdispatcher.h
@brief A singleton class to provide sync progress information to other gui classes.

How to use the ProgressDispatcher:
Just connect to the two signals either to progress for every individual file
or the overall sync progress.

***********************************************************/
class ProgressDispatcher : GLib.Object {

    //  friend class Folder; // only allow Folder class to access the setting slots.


    /***********************************************************
    ***********************************************************/
    private QElapsedTimer timer;
    private static ProgressDispatcher instance = null;


    /***********************************************************
    @brief Signals the progress of data transmission.

    @param[out]  folder The folder which is being processed
    @param[out]  progress   A struct with all progress info.

    ***********************************************************/
    signal void progress_info (string folder, ProgressInfo progress);


    /***********************************************************
    @brief : the item was completed by a job
    ***********************************************************/
    signal void item_completed (string folder, SyncFileItemPtr item);


    /***********************************************************
    @brief A new folder-wide sync error was seen.
    ***********************************************************/
    signal void sync_error (string folder, string message, ErrorCategory category);


    /***********************************************************
    @brief Emitted when an error needs to be added into GUI
    @param[out] folder The folder which is being processed
    @param[out] status of the error
    @param[out] full error message
    @param[out] subject (optional)
    ***********************************************************/
    signal void add_error_to_gui (string folder, SyncFileItem.Status status, string error_message, string subject);


    /***********************************************************
    @brief Emitted for a folder when a sync is done, listing all pending conflicts
    ***********************************************************/
    signal void folder_conflicts (string folder, string[] conflict_paths);


    /***********************************************************
    ***********************************************************/
    private ProgressDispatcher (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public static ProgressDispatcher instance () {
        if (!this.instance) {
            this.instance = new ProgressDispatcher ();
        }
        return this.instance;
    }


    /***********************************************************
    ***********************************************************/
    protected void progress_info (string folder, ProgressInfo progress) {
        if (folder.is_empty ()) {
        // The update phase now also has progress
        //            (progress.current_items.size () == 0
        //             && progress.total_file_count == 0) ) {
            return;
        }
        /* emit */ progress_info (folder, progress);
    }


    /***********************************************************
    ***********************************************************/
    private static bool should_count_progress (SyncFileItem item) {
        const var instruction = item.instruction;

        // Skip any ignored, error or non-propagated files and directories.
        if (instruction == CSYNC_INSTRUCTION_NONE
            || instruction == CSYNC_INSTRUCTION_UPDATE_METADATA
            || instruction == CSYNC_INSTRUCTION_IGNORE
            || instruction == CSYNC_INSTRUCTION_ERROR) {
            return false;
        }

        return true;
    }

} // class ProgressDispatcher

} // namespace Progress
} // namespace Occ
    