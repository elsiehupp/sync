namespace Occ {
namespace LibSync {

/***********************************************************
@brief The SyncResult class

@author Duncan Mac-Vicar P. <duncan@kde.org>

@copyright GPLv3 or Later
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
    private GLib.List<SyncFileItem> sync_items;

    /***********************************************************
    ***********************************************************/
    GLib.DateTime sync_time { public get; private set; }

    /***********************************************************
    ***********************************************************/
    public string folder;

    /***********************************************************
    when the sync tool support this...
    ***********************************************************/
    private GLib.List<string> errors = new GLib.List<string> ();

    /***********************************************************
    ***********************************************************/
    bool found_files_not_synced { public get; private set; }

    /***********************************************************
    ***********************************************************/
    bool folder_structure_was_changed { public get; private set; }

    /***********************************************************
    Count new, removed and updated items
    ***********************************************************/
    int number_of_new_items { public get; private set; }

    /***********************************************************
    ***********************************************************/
    int number_of_removed_items { public get; private set; }

    /***********************************************************
    ***********************************************************/
    int number_of_updated_items { public get; private set; }

    /***********************************************************
    ***********************************************************/
    int number_of_renamed_items { public get; private set; }

    /***********************************************************
    ***********************************************************/
    int number_of_new_conflict_items { public get; private set; }

    /***********************************************************
    ***********************************************************/
    int number_of_old_conflict_items { public get; public set; }

    /***********************************************************
    ***********************************************************/
    int number_of_error_items { public get; private set; }

    /***********************************************************
    ***********************************************************/
    int number_of_locked_items { public get; private set; }

    /***********************************************************
    ***********************************************************/
    unowned SyncFileItem first_item_new { public get; private set; }

    /***********************************************************
    ***********************************************************/
    unowned SyncFileItem first_item_deleted { public get; private set; }

    /***********************************************************
    ***********************************************************/
    unowned SyncFileItem first_item_updated { public get; private set; }

    /***********************************************************
    ***********************************************************/
    unowned SyncFileItem first_item_renamed { public get; private set; }

    /***********************************************************
    ***********************************************************/
    unowned SyncFileItem first_new_conflict_item { public get; private set; }

    /***********************************************************
    ***********************************************************/
    unowned SyncFileItem first_item_error { public get; private set; }

    /***********************************************************
    ***********************************************************/
    unowned SyncFileItem first_item_locked { public get; private set; }

    /***********************************************************
    ***********************************************************/
    construct {
        this.status = Status.UNDEFINED;
        this.found_files_not_synced = false;
        this.folder_structure_was_changed = false;
        this.number_of_new_items = 0;
        this.number_of_removed_items = 0;
        this.number_of_updated_items = 0;
        this.number_of_renamed_items = 0;
        this.number_of_new_conflict_items = 0;
        this.number_of_old_conflict_items = 0;
        this.number_of_error_items = 0;
        this.number_of_locked_items = 0;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.List<string> error_strings () {
        return this.errors;
    }


    /***********************************************************
    ***********************************************************/
    public void append_error_string (string err) {
        this.errors.append (err);
    }


    /***********************************************************
    ***********************************************************/
    public void reset () {
        this = new SyncResult ();
    }


    /***********************************************************
    ***********************************************************/
    public string error_string {
        public get {
            if (this.errors.length () == 0) {
                return "";
            }
            return this.errors.nth_data (0);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void clear_errors () {
        this.errors = new GLib.List<string> ();
    }


    /***********************************************************
    ***********************************************************/
    public string status_string {
        public get {
            switch (this.status) {
            case Status.UNDEFINED:
                return "Undefined";
            case Status.NOT_YET_STARTED:
                return "Not yet Started";
            case Status.SYNC_RUNNING:
                return "Sync Running";
            case Status.SUCCESS:
                return "Success";
            case Status.ERROR:
                return "Error";
            case Status.SETUP_ERROR:
                return "Setup_error";
            case Status.SYNC_PREPARE:
                return "Sync_prepare";
            case Status.PROBLEM:
                return "Success, some files were ignored.";
            case Status.SYNC_ABORT_REQUESTED:
                return "Sync Request aborted by user";
            case Status.PAUSED:
                return "Sync Paused";
            }
            return "";
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool has_unresolved_conflicts {
        public get {
            return this.number_of_new_conflict_items + this.number_of_old_conflict_items > 0;
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool has_locked_files {
        public get {
            return this.number_of_locked_items > 0;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void process_completed_item (SyncFileItem item) {
        if (Progress.is_warning_kind (item.status)) {
            // Count any error conditions, error strings will have priority anyway.
            this.found_files_not_synced = true;
        }

        if (item.is_directory () && (
            item.instruction == CSync.SyncInstructions.NEW
            || item.instruction == CSync.SyncInstructions.TYPE_CHANGE
            || item.instruction == CSync.SyncInstructions.REMOVE
            || item.instruction == CSync.SyncInstructions.RENAME
        )) {
            this.folder_structure_was_changed = true;
        }

        if (item.status == SyncFileItem.Status.FILE_LOCKED) {
            this.number_of_locked_items++;
            if (this.first_item_locked == null) {
                this.first_item_locked = item;
            }
        }

        // Process the item to the gui
        if (item.status == SyncFileItem.Status.FATAL_ERROR || item.status == SyncFileItem.Status.NORMAL_ERROR) {
            // : this displays an error string (%2) for a file %1
            append_error_string (_("%1 : %2").printf (item.file, item.error_string));
            this.number_of_error_items++;
            if (this.first_item_error == null) {
                this.first_item_error = item;
            }
        } else if (item.status == SyncFileItem.Status.CONFLICT) {
            if (item.instruction == CSync.CSync.SyncInstructions.CONFLICT) {
                this.number_of_new_conflict_items++;
                if (this.first_new_conflict_item == null) {
                    this.first_new_conflict_item = item;
                }
            } else {
                this.number_of_old_conflict_items++;
            }
        } else {
            if (!item.has_error_status () && item.status != SyncFileItem.Status.FILE_IGNORED && item.direction == SyncFileItem.Direction.DOWN) {
                switch (item.instruction) {
                case CSync.SyncInstructions.NEW:
                case CSync.SyncInstructions.TYPE_CHANGE:
                    this.number_of_new_items++;
                    if (!this.first_item_new)
                        this.first_item_new = item;
                    break;
                case CSync.SyncInstructions.REMOVE:
                    this.number_of_removed_items++;
                    if (!this.first_item_deleted)
                        this.first_item_deleted = item;
                    break;
                case CSync.SyncInstructions.SYNC:
                    this.number_of_updated_items++;
                    if (!this.first_item_updated)
                        this.first_item_updated = item;
                    break;
                case CSync.SyncInstructions.RENAME:
                    if (!this.first_item_renamed) {
                        this.first_item_renamed = item;
                    }
                    this.number_of_renamed_items++;
                    break;
                default:
                    // nothing.
                    break;
                }
            } else if (item.instruction == CSync.SyncInstructions.IGNORE) {
                this.found_files_not_synced = true;
            }
        }
    }

} // class SyncResult

} // namespace LibSync
} // namespace Occ