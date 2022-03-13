/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The SyncResult class
@ingroup libsync
***********************************************************/
public class SyncResult : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum Status {
        UNDEFINED,
        NOT_YET_STARTED,
        SYNC_PREPARE,
        SYNC_RUNNING,
        SYNC_ABORT_REQUESTED,
        SUCCESS,
        PROBLEM,
        ERROR,
        SETUP_ERROR,
        PAUSED
    }


    /***********************************************************
    ***********************************************************/
    Status status {
        public get {
            return this.status;
        }
        public set {
            this.status = value;
            this.sync_time = GLib.DateTime.current_date_time_utc ();
        }
    }

    /***********************************************************
    ***********************************************************/
    private SyncFileItemVector sync_items;


    /***********************************************************
    ***********************************************************/
    GLib.DateTime sync_time { public get; private set; }


    /***********************************************************
    ***********************************************************/
    public string folder;


    /***********************************************************
    when the sync tool support this...
    ***********************************************************/
    private string[] errors;


    /***********************************************************
    ***********************************************************/
    bool found_files_not_synced { public get; private set; }


    /***********************************************************
    ***********************************************************/
    bool folder_structure_was_changed { public get; private set; }


    /***********************************************************
    Count new, removed and updated items
    ***********************************************************/
    int num_new_items { public get; private set; }


    /***********************************************************
    ***********************************************************/
    int num_removed_items { public get; private set; }


    /***********************************************************
    ***********************************************************/
    int num_updated_items { public get; private set; }


    /***********************************************************
    ***********************************************************/
    int num_renamed_items { public get; private set; }


    /***********************************************************
    ***********************************************************/
    int num_new_conflict_items { public get; private set; }


    /***********************************************************
    ***********************************************************/
    int num_old_conflict_items { public get; public set; }


    /***********************************************************
    ***********************************************************/
    int num_error_items { public get; private set; }


    /***********************************************************
    ***********************************************************/
    int num_locked_items { public get; private set; }


    /***********************************************************
    ***********************************************************/
    SyncFileItemPtr first_item_new { public get; private set; }


    /***********************************************************
    ***********************************************************/
    SyncFileItemPtr first_item_deleted { public get; private set; }


    /***********************************************************
    ***********************************************************/
    SyncFileItemPtr first_item_updated { public get; private set; }


    /***********************************************************
    ***********************************************************/
    SyncFileItemPtr first_item_renamed { public get; private set; }


    /***********************************************************
    ***********************************************************/
    SyncFileItemPtr first_new_conflict_item { public get; private set; }


    /***********************************************************
    ***********************************************************/
    SyncFileItemPtr first_item_error { public get; private set; }


    /***********************************************************
    ***********************************************************/
    SyncFileItemPtr first_item_locked { public get; private set; }


    /***********************************************************
    ***********************************************************/
    public SyncResult () {
        this.status = Status.UNDEFINED;
        this.found_files_not_synced = false;
        this.folder_structure_was_changed = false;
        this.num_new_items = 0;
        this.num_removed_items = 0;
        this.num_updated_items = 0;
        this.num_renamed_items = 0;
        this.num_new_conflict_items = 0;
        this.num_old_conflict_items = 0;
        this.num_error_items = 0;
        this.num_locked_items = 0;
    }


    /***********************************************************
    ***********************************************************/
    public string[] error_strings () {
        return this.errors;
    }


    /***********************************************************
    ***********************************************************/
    public void append_error_string (string err) {
        this.errors.append (err);
    }




    /***********************************************************
    ***********************************************************/
    public void on_signal_reset () {
        SyncResult ();
    }


    /***********************************************************
    ***********************************************************/
    public string error_string () {
        if (this.errors.is_empty ())
            return "";
        return this.errors.first ();
    }


    /***********************************************************
    ***********************************************************/
    public void clear_errors () {
        this.errors.clear ();
    }


    /***********************************************************
    ***********************************************************/
    public string status_string () {
        switch (status ()) {
        case Undefined:
            return "Undefined";
        case NotYetStarted:
            return "Not yet Started";
        case Sync_running:
            return "Sync Running";
        case Success:
            return "Success";
        case Error:
            return "Error";
        case Setup_error:
            return "Setup_error";
        case Sync_prepare:
            return "Sync_prepare";
        case Problem:
            return "Success, some files were ignored.";
        case Sync_abort_requested:
            return "Sync Request aborted by user";
        case Paused:
            return "Sync Paused";
        }
        return "";
    }


    /***********************************************************
    ***********************************************************/
    public bool has_unresolved_conflicts () {
        return this.num_new_conflict_items + this.num_old_conflict_items > 0;
    }


    /***********************************************************
    ***********************************************************/
    public bool has_locked_files () {
        return this.num_locked_items > 0;
    }


    /***********************************************************
    ***********************************************************/
    //  public 
    //  }


    /***********************************************************
    ***********************************************************/
    //  public 
    //  }


    /***********************************************************
    ***********************************************************/
    public void process_completed_item (SyncFileItemPtr item) {
        if (Progress.is_warning_kind (item.status)) {
            // Count any error conditions, error strings will have priority anyway.
            this.found_files_not_synced = true;
        }

        if (item.is_directory () && (item.instruction == CSYNC_INSTRUCTION_NEW
                                      || item.instruction == CSYNC_INSTRUCTION_TYPE_CHANGE
                                      || item.instruction == CSYNC_INSTRUCTION_REMOVE
                                      || item.instruction == CSYNC_INSTRUCTION_RENAME)) {
            this.folder_structure_was_changed = true;
        }

        if (item.status == SyncFileItem.Status.FILE_LOCKED) {
            this.num_locked_items++;
            if (!this.first_item_locked) {
                this.first_item_locked = item;
            }
        }

        // Process the item to the gui
        if (item.status == SyncFileItem.Status.FATAL_ERROR || item.status == SyncFileItem.Status.NORMAL_ERROR) {
            // : this displays an error string (%2) for a file %1
            append_error_string (GLib.Object._("%1 : %2").arg (item.file, item.error_string));
            this.num_error_items++;
            if (!this.first_item_error) {
                this.first_item_error = item;
            }
        } else if (item.status == SyncFileItem.Status.CONFLICT) {
            if (item.instruction == CSYNC_INSTRUCTION_CONFLICT) {
                this.num_new_conflict_items++;
                if (!this.first_new_conflict_item) {
                    this.first_new_conflict_item = item;
                }
            } else {
                this.num_old_conflict_items++;
            }
        } else {
            if (!item.has_error_status () && item.status != SyncFileItem.Status.FILE_IGNORED && item.direction == SyncFileItem.Direction.DOWN) {
                switch (item.instruction) {
                case CSYNC_INSTRUCTION_NEW:
                case CSYNC_INSTRUCTION_TYPE_CHANGE:
                    this.num_new_items++;
                    if (!this.first_item_new)
                        this.first_item_new = item;
                    break;
                case CSYNC_INSTRUCTION_REMOVE:
                    this.num_removed_items++;
                    if (!this.first_item_deleted)
                        this.first_item_deleted = item;
                    break;
                case CSYNC_INSTRUCTION_SYNC:
                    this.num_updated_items++;
                    if (!this.first_item_updated)
                        this.first_item_updated = item;
                    break;
                case CSYNC_INSTRUCTION_RENAME:
                    if (!this.first_item_renamed) {
                        this.first_item_renamed = item;
                    }
                    this.num_renamed_items++;
                    break;
                default:
                    // nothing.
                    break;
                }
            } else if (item.instruction == CSYNC_INSTRUCTION_IGNORE) {
                this.found_files_not_synced = true;
            }
        }
    }

} // class SyncResult

} // namespace LibSync
} // namespace Occ