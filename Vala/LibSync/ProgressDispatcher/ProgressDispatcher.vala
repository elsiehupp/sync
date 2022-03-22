namespace Occ {
namespace LibSync {
namespace Progress {

/***********************************************************
@class ProgressDispatcher

@brief A singleton class to provide sync progress
information to other gui classes.

@details How to use the ProgressDispatcher:
Just connect to the two signals either to progress for
every individual file or the overall sync progress.

@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class ProgressDispatcher : GLib.Object {

    //  friend class Folder; // only allow Folder class to access the setting slots.

    /***********************************************************
    ***********************************************************/
    private GLib.Timer timer;
    static ProgressDispatcher instance {
        public get {
            if (!this.instance) {
                this.instance = new ProgressDispatcher ();
            }
            return this.instance;
        }
        private set {
            this.instance = value;
        }
    }
    //  this.instance = null;


    /***********************************************************
    @brief Signals the progress of data transmission.

    @param[out]  folder The folder which is being processed
    @param[out]  progress   A struct with all progress info.

    ***********************************************************/
    internal signal void signal_progress_info (string folder, ProgressInfo progress);


    /***********************************************************
    @brief the item was completed by a job
    ***********************************************************/
    internal signal void signal_item_completed (string folder, SyncFileItem item);


    /***********************************************************
    @brief A new folder-wide sync error was seen.
    ***********************************************************/
    internal signal void signal_sync_error (string folder, string message, ErrorCategory category);


    /***********************************************************
    @brief Emitted when an error needs to be added into GUI
    @param[out] folder The folder which is being processed
    @param[out] status of the error
    @param[out] full error message
    @param[out] subject (optional)
    ***********************************************************/
    internal signal void add_error_to_gui (string folder, SyncFileItem.Status status, string error_message, string subject);


    /***********************************************************
    @brief Emitted for a folder when a sync is done, listing all pending conflicts
    ***********************************************************/
    internal signal void signal_folder_conflicts (string folder, string[] conflict_paths);


    /***********************************************************
    ***********************************************************/
    private ProgressDispatcher (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }




    /***********************************************************
    ***********************************************************/
    protected void progress_info (string folder, ProgressInfo progress) {
        if (folder == "") {
        // The update phase now also has progress
        //            (progress.current_items.size () == 0
        //             && progress.total_file_count == 0) ) {
            return;
        }
        /* emit */ signal_progress_info (folder, progress);
    }


    /***********************************************************
    ***********************************************************/
    private static bool should_count_progress (SyncFileItem item) {
        var instruction = item.instruction;

        // Skip any ignored, error or non-propagated files and directories.
        if (instruction == CSync.SyncInstructions.NONE
            || instruction == CSync.SyncInstructions.UPDATE_METADATA
            || instruction == CSync.SyncInstructions.IGNORE
            || instruction == CSync.SyncInstructions.ERROR) {
            return false;
        }

        return true;
    }

} // class ProgressDispatcher

} // namespace Progress
} // namespace LibSync
} // namespace Occ
    