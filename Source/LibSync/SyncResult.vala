/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <string[]>
// #include <QHash>
// #include <QDateTime>

namespace Occ {

/***********************************************************
@brief The SyncResult class
@ingroup libsync
***********************************************************/
class SyncResult {
    Q_GADGET

    public enum Status {
        Undefined,
        NotYetStarted,
        Sync_prepare,
        Sync_running,
        Sync_abort_requested,
        Success,
        Problem,
        Error,
        Setup_error,
        Paused
    };

    public SyncResult ();
    public void on_reset ();

    public void append_error_string (string );
    public string error_string ();
    public string[] error_strings ();
    public void clear_errors ();

    public void set_status (Status);
    public Status status ();
    public string status_string ();
    public QDateTime sync_time ();
    public void set_folder (string folder);
    public string folder ();

    public bool found_files_not_synced () {
        return _found_files_not_synced;
    }
    public bool folder_structure_was_changed () {
        return _folder_structure_was_changed;
    }

    public int num_new_items () {
        return _num_new_items;
    }
    public int num_removed_items () {
        return _num_removed_items;
    }
    public int num_updated_items () {
        return _num_updated_items;
    }
    public int num_renamed_items () {
        return _num_renamed_items;
    }
    public int num_new_conflict_items () {
        return _num_new_conflict_items;
    }
    public int num_old_conflict_items () {
        return _num_old_conflict_items;
    }
    public void set_num_old_conflict_items (int n) {
        _num_old_conflict_items = n;
    }
    public int num_error_items () {
        return _num_error_items;
    }
    public bool has_unresolved_conflicts () {
        return _num_new_conflict_items + _num_old_conflict_items > 0;
    }

    public int num_locked_items () {
        return _num_locked_items;
    }
    public bool has_locked_files () {
        return _num_locked_items > 0;
    }

    public const SyncFileItemPtr &first_item_new () {
        return _first_item_new;
    }
    public const SyncFileItemPtr &first_item_deleted () {
        return _first_item_deleted;
    }
    public const SyncFileItemPtr &first_item_updated () {
        return _first_item_updated;
    }
    public const SyncFileItemPtr &first_item_renamed () {
        return _first_item_renamed;
    }
    public const SyncFileItemPtr &first_new_conflict_item () {
        return _first_new_conflict_item;
    }
    public const SyncFileItemPtr &first_item_error () {
        return _first_item_error;
    }
    public const SyncFileItemPtr &first_item_locked () {
        return _first_item_locked;
    }

    public void process_completed_item (SyncFileItemPtr &item);


    private Status _status = Undefined;
    private SyncFileItemVector _sync_items;
    private QDateTime _sync_time;
    private string _folder;
    /***********************************************************
    when the sync tool support this...
    ***********************************************************/
    private string[] _errors;
    private bool _found_files_not_synced = false;
    private bool _folder_structure_was_changed = false;

    // count new, removed and updated items
    private int _num_new_items = 0;
    private int _num_removed_items = 0;
    private int _num_updated_items = 0;
    private int _num_renamed_items = 0;
    private int _num_new_conflict_items = 0;
    private int _num_old_conflict_items = 0;
    private int _num_error_items = 0;
    private int _num_locked_items = 0;

    private SyncFileItemPtr _first_item_new;
    private SyncFileItemPtr _first_item_deleted;
    private SyncFileItemPtr _first_item_updated;
    private SyncFileItemPtr _first_item_renamed;
    private SyncFileItemPtr _first_new_conflict_item;
    private SyncFileItemPtr _first_item_error;
    private SyncFileItemPtr _first_item_locked;
};

    SyncResult.SyncResult () = default;

    SyncResult.Status SyncResult.status () {
        return _status;
    }

    void SyncResult.on_reset () {
        *this = SyncResult ();
    }

    string SyncResult.status_string () {
        string re;
        Status stat = status ();

        switch (stat) {
        case Undefined:
            re = QLatin1String ("Undefined");
            break;
        case NotYetStarted:
            re = QLatin1String ("Not yet Started");
            break;
        case Sync_running:
            re = QLatin1String ("Sync Running");
            break;
        case Success:
            re = QLatin1String ("Success");
            break;
        case Error:
            re = QLatin1String ("Error");
            break;
        case Setup_error:
            re = QLatin1String ("Setup_error");
            break;
        case Sync_prepare:
            re = QLatin1String ("Sync_prepare");
            break;
        case Problem:
            re = QLatin1String ("Success, some files were ignored.");
            break;
        case Sync_abort_requested:
            re = QLatin1String ("Sync Request aborted by user");
            break;
        case Paused:
            re = QLatin1String ("Sync Paused");
            break;
        }
        return re;
    }

    void SyncResult.set_status (Status stat) {
        _status = stat;
        _sync_time = QDateTime.current_date_time_utc ();
    }

    QDateTime SyncResult.sync_time () {
        return _sync_time;
    }

    string[] SyncResult.error_strings () {
        return _errors;
    }

    void SyncResult.append_error_string (string err) {
        _errors.append (err);
    }

    string SyncResult.error_string () {
        if (_errors.is_empty ())
            return string ();
        return _errors.first ();
    }

    void SyncResult.clear_errors () {
        _errors.clear ();
    }

    void SyncResult.set_folder (string folder) {
        _folder = folder;
    }

    string SyncResult.folder () {
        return _folder;
    }

    void SyncResult.process_completed_item (SyncFileItemPtr &item) {
        if (Progress.is_warning_kind (item._status)) {
            // Count any error conditions, error strings will have priority anyway.
            _found_files_not_synced = true;
        }

        if (item.is_directory () && (item._instruction == CSYNC_INSTRUCTION_NEW
                                      || item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE
                                      || item._instruction == CSYNC_INSTRUCTION_REMOVE
                                      || item._instruction == CSYNC_INSTRUCTION_RENAME)) {
            _folder_structure_was_changed = true;
        }

        if (item._status == SyncFileItem.FileLocked){
            _num_locked_items++;
            if (!_first_item_locked) {
                _first_item_locked = item;
            }
        }

        // Process the item to the gui
        if (item._status == SyncFileItem.FatalError || item._status == SyncFileItem.NormalError) {
            // : this displays an error string (%2) for a file %1
            append_error_string (GLib.Object.tr ("%1 : %2").arg (item._file, item._error_string));
            _num_error_items++;
            if (!_first_item_error) {
                _first_item_error = item;
            }
        } else if (item._status == SyncFileItem.Conflict) {
            if (item._instruction == CSYNC_INSTRUCTION_CONFLICT) {
                _num_new_conflict_items++;
                if (!_first_new_conflict_item) {
                    _first_new_conflict_item = item;
                }
            } else {
                _num_old_conflict_items++;
            }
        } else {
            if (!item.has_error_status () && item._status != SyncFileItem.FileIgnored && item._direction == SyncFileItem.Down) {
                switch (item._instruction) {
                case CSYNC_INSTRUCTION_NEW:
                case CSYNC_INSTRUCTION_TYPE_CHANGE:
                    _num_new_items++;
                    if (!_first_item_new)
                        _first_item_new = item;
                    break;
                case CSYNC_INSTRUCTION_REMOVE:
                    _num_removed_items++;
                    if (!_first_item_deleted)
                        _first_item_deleted = item;
                    break;
                case CSYNC_INSTRUCTION_SYNC:
                    _num_updated_items++;
                    if (!_first_item_updated)
                        _first_item_updated = item;
                    break;
                case CSYNC_INSTRUCTION_RENAME:
                    if (!_first_item_renamed) {
                        _first_item_renamed = item;
                    }
                    _num_renamed_items++;
                    break;
                default:
                    // nothing.
                    break;
                }
            } else if (item._instruction == CSYNC_INSTRUCTION_IGNORE) {
                _found_files_not_synced = true;
            }
        }
    }

    } // ns mirall
    