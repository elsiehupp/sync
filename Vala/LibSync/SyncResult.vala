/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/


namespace Occ {

/***********************************************************
@brief The SyncResult class
@ingroup libsync
***********************************************************/
class SyncResult {

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
    private Status status = Undefined;


    /***********************************************************
    ***********************************************************/
    private SyncFileItemVector sync_items;


    /***********************************************************
    ***********************************************************/
    private GLib.DateTime sync_time;


    /***********************************************************
    ***********************************************************/
    private string folder;


    /***********************************************************
    when the sync tool support this...
    ***********************************************************/
    private string[] errors;


    /***********************************************************
    ***********************************************************/
    private bool found_files_not_synced = false;


    /***********************************************************
    ***********************************************************/
    private bool folder_structure_was_changed = false;


    /***********************************************************
    Count new, removed and updated items
    ***********************************************************/
    private int num_new_items = 0;


    /***********************************************************
    ***********************************************************/
    private int num_removed_items = 0;


    /***********************************************************
    ***********************************************************/
    private int num_updated_items = 0;


    /***********************************************************
    ***********************************************************/
    private int num_renamed_items = 0;


    /***********************************************************
    ***********************************************************/
    private int num_new_conflict_items = 0;


    /***********************************************************
    ***********************************************************/
    private int num_old_conflict_items = 0;


    /***********************************************************
    ***********************************************************/
    private int num_error_items = 0;


    /***********************************************************
    ***********************************************************/
    private int num_locked_items = 0;

    /***********************************************************
    ***********************************************************/
    private SyncFileItemPtr first_item_new;


    /***********************************************************
    ***********************************************************/
    private SyncFileItemPtr first_item_deleted;


    /***********************************************************
    ***********************************************************/
    private SyncFileItemPtr first_item_updated;


    /***********************************************************
    ***********************************************************/
    private SyncFileItemPtr first_item_renamed;


    /***********************************************************
    ***********************************************************/
    private SyncFileItemPtr first_new_conflict_item;


    /***********************************************************
    ***********************************************************/
    private SyncFileItemPtr first_item_error;


    /***********************************************************
    ***********************************************************/
    private SyncFileItemPtr first_item_locked;


    /***********************************************************
    ***********************************************************/
    public SyncResult () = default;


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
    public SyncResult.Status status () {
        return this.status;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_reset () {
        *this = SyncResult ();
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
    public void status (Status stat) {
        this.status = stat;
        this.sync_time = GLib.DateTime.current_date_time_utc ();
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
    public GLib.DateTime sync_time () {
        return this.sync_time;
    }
    

    /***********************************************************
    ***********************************************************/
    public void folder (string folder) {
        this.folder = folder;
    }


    /***********************************************************
    ***********************************************************/
    public string folder () {
        return this.folder;
    }


    /***********************************************************
    ***********************************************************/
    public bool found_files_not_synced () {
        return this.found_files_not_synced;
    }


    /***********************************************************
    ***********************************************************/
    public bool folder_structure_was_changed () {
        return this.folder_structure_was_changed;
    }


    /***********************************************************
    ***********************************************************/
    public int num_new_items () {
        return this.num_new_items;
    }


    /***********************************************************
    ***********************************************************/
    public int num_removed_items () {
        return this.num_removed_items;
    }


    /***********************************************************
    ***********************************************************/
    public int num_updated_items () {
        return this.num_updated_items;
    }



    /***********************************************************
    ***********************************************************/
    public int num_renamed_items () {
        return this.num_renamed_items;
    }


    /***********************************************************
    ***********************************************************/
    public int num_new_conflict_items () {
        return this.num_new_conflict_items;
    }


    /***********************************************************
    ***********************************************************/
    public int num_old_conflict_items () {
        return this.num_old_conflict_items;
    }



    /***********************************************************
    ***********************************************************/
    public void num_old_conflict_items (int n) {
        this.num_old_conflict_items = n;
    }


    /***********************************************************
    ***********************************************************/
    public int num_error_items () {
        return this.num_error_items;
    }


    /***********************************************************
    ***********************************************************/
    public bool has_unresolved_conflicts () {
        return this.num_new_conflict_items + this.num_old_conflict_items > 0;
    }


    /***********************************************************
    ***********************************************************/
    public int num_locked_items () {
        return this.num_locked_items;
    }


    /***********************************************************
    ***********************************************************/
    public bool has_locked_files () {
        return this.num_locked_items > 0;
    }


    /***********************************************************
    ***********************************************************/
    public const SyncFileItemPtr first_item_new () {
        return this.first_item_new;
    }


    /***********************************************************
    ***********************************************************/
    public const SyncFileItemPtr first_item_deleted () {
        return this.first_item_deleted;
    }


    /***********************************************************
    ***********************************************************/
    public 
    }


    /***********************************************************
    ***********************************************************/
    public const SyncFileItemPtr first_item_updated () {
        return this.first_item_updated;
    }


    /***********************************************************
    ***********************************************************/
    public const SyncFileItemPtr first_item_renamed () {
    }


    /***********************************************************
    ***********************************************************/
    public 
    }


    /***********************************************************
    ***********************************************************/
    public urn this.first_new_conflict_item;
    }


    /***********************************************************
    ***********************************************************/
    public const SyncFileItemPtr first_item_error () {
        return this.first_item_error;
    }


    /***********************************************************
    ***********************************************************/
    public const SyncFileItemPtr first_item_locked () {
        return this.first_item_locked;
    }


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

}

} // namespace mirall
    