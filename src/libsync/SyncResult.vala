/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QStringList>
// #include <QHash>
// #include <QDateTime>

namespace Occ {

/***********************************************************
@brief The SyncResult class
@ingroup libsync
***********************************************************/
class SyncResult {
    Q_GADGET
public:
    enum Status {
        Undefined,
        NotYetStarted,
        SyncPrepare,
        SyncRunning,
        SyncAbortRequested,
        Success,
        Problem,
        Error,
        SetupError,
        Paused
    };
    Q_ENUM (Status);

    SyncResult ();
    void reset ();

    void appendErrorString (string &);
    string errorString ();
    QStringList errorStrings ();
    void clearErrors ();

    void setStatus (Status);
    Status status ();
    string statusString ();
    QDateTime syncTime ();
    void setFolder (string &folder);
    string folder ();

    bool foundFilesNotSynced () { return _foundFilesNotSynced; }
    bool folderStructureWasChanged () { return _folderStructureWasChanged; }

    int numNewItems () { return _numNewItems; }
    int numRemovedItems () { return _numRemovedItems; }
    int numUpdatedItems () { return _numUpdatedItems; }
    int numRenamedItems () { return _numRenamedItems; }
    int numNewConflictItems () { return _numNewConflictItems; }
    int numOldConflictItems () { return _numOldConflictItems; }
    void setNumOldConflictItems (int n) { _numOldConflictItems = n; }
    int numErrorItems () { return _numErrorItems; }
    bool hasUnresolvedConflicts () { return _numNewConflictItems + _numOldConflictItems > 0; }

    int numLockedItems () { return _numLockedItems; }
    bool hasLockedFiles () { return _numLockedItems > 0; }

    const SyncFileItemPtr &firstItemNew () { return _firstItemNew; }
    const SyncFileItemPtr &firstItemDeleted () { return _firstItemDeleted; }
    const SyncFileItemPtr &firstItemUpdated () { return _firstItemUpdated; }
    const SyncFileItemPtr &firstItemRenamed () { return _firstItemRenamed; }
    const SyncFileItemPtr &firstNewConflictItem () { return _firstNewConflictItem; }
    const SyncFileItemPtr &firstItemError () { return _firstItemError; }
    const SyncFileItemPtr &firstItemLocked () { return _firstItemLocked; }

    void processCompletedItem (SyncFileItemPtr &item);

private:
    Status _status = Undefined;
    SyncFileItemVector _syncItems;
    QDateTime _syncTime;
    string _folder;
    /***********************************************************
     * when the sync tool support this...
     */
    QStringList _errors;
    bool _foundFilesNotSynced = false;
    bool _folderStructureWasChanged = false;

    // count new, removed and updated items
    int _numNewItems = 0;
    int _numRemovedItems = 0;
    int _numUpdatedItems = 0;
    int _numRenamedItems = 0;
    int _numNewConflictItems = 0;
    int _numOldConflictItems = 0;
    int _numErrorItems = 0;
    int _numLockedItems = 0;

    SyncFileItemPtr _firstItemNew;
    SyncFileItemPtr _firstItemDeleted;
    SyncFileItemPtr _firstItemUpdated;
    SyncFileItemPtr _firstItemRenamed;
    SyncFileItemPtr _firstNewConflictItem;
    SyncFileItemPtr _firstItemError;
    SyncFileItemPtr _firstItemLocked;
};
}

#endif







/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {

    SyncResult.SyncResult () = default;
    
    SyncResult.Status SyncResult.status () {
        return _status;
    }
    
    void SyncResult.reset () {
        *this = SyncResult ();
    }
    
    string SyncResult.statusString () {
        string re;
        Status stat = status ();
    
        switch (stat) {
        case Undefined:
            re = QLatin1String ("Undefined");
            break;
        case NotYetStarted:
            re = QLatin1String ("Not yet Started");
            break;
        case SyncRunning:
            re = QLatin1String ("Sync Running");
            break;
        case Success:
            re = QLatin1String ("Success");
            break;
        case Error:
            re = QLatin1String ("Error");
            break;
        case SetupError:
            re = QLatin1String ("SetupError");
            break;
        case SyncPrepare:
            re = QLatin1String ("SyncPrepare");
            break;
        case Problem:
            re = QLatin1String ("Success, some files were ignored.");
            break;
        case SyncAbortRequested:
            re = QLatin1String ("Sync Request aborted by user");
            break;
        case Paused:
            re = QLatin1String ("Sync Paused");
            break;
        }
        return re;
    }
    
    void SyncResult.setStatus (Status stat) {
        _status = stat;
        _syncTime = QDateTime.currentDateTimeUtc ();
    }
    
    QDateTime SyncResult.syncTime () {
        return _syncTime;
    }
    
    QStringList SyncResult.errorStrings () {
        return _errors;
    }
    
    void SyncResult.appendErrorString (string &err) {
        _errors.append (err);
    }
    
    string SyncResult.errorString () {
        if (_errors.isEmpty ())
            return string ();
        return _errors.first ();
    }
    
    void SyncResult.clearErrors () {
        _errors.clear ();
    }
    
    void SyncResult.setFolder (string &folder) {
        _folder = folder;
    }
    
    string SyncResult.folder () {
        return _folder;
    }
    
    void SyncResult.processCompletedItem (SyncFileItemPtr &item) {
        if (Progress.isWarningKind (item._status)) {
            // Count any error conditions, error strings will have priority anyway.
            _foundFilesNotSynced = true;
        }
    
        if (item.isDirectory () && (item._instruction == CSYNC_INSTRUCTION_NEW
                                      || item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE
                                      || item._instruction == CSYNC_INSTRUCTION_REMOVE
                                      || item._instruction == CSYNC_INSTRUCTION_RENAME)) {
            _folderStructureWasChanged = true;
        }
    
        if (item._status == SyncFileItem.FileLocked){
            _numLockedItems++;
            if (!_firstItemLocked) {
                _firstItemLocked = item;
            }
        }
    
        // Process the item to the gui
        if (item._status == SyncFileItem.FatalError || item._status == SyncFileItem.NormalError) {
            // : this displays an error string (%2) for a file %1
            appendErrorString (GLib.Object.tr ("%1 : %2").arg (item._file, item._errorString));
            _numErrorItems++;
            if (!_firstItemError) {
                _firstItemError = item;
            }
        } else if (item._status == SyncFileItem.Conflict) {
            if (item._instruction == CSYNC_INSTRUCTION_CONFLICT) {
                _numNewConflictItems++;
                if (!_firstNewConflictItem) {
                    _firstNewConflictItem = item;
                }
            } else {
                _numOldConflictItems++;
            }
        } else {
            if (!item.hasErrorStatus () && item._status != SyncFileItem.FileIgnored && item._direction == SyncFileItem.Down) {
                switch (item._instruction) {
                case CSYNC_INSTRUCTION_NEW:
                case CSYNC_INSTRUCTION_TYPE_CHANGE:
                    _numNewItems++;
                    if (!_firstItemNew)
                        _firstItemNew = item;
                    break;
                case CSYNC_INSTRUCTION_REMOVE:
                    _numRemovedItems++;
                    if (!_firstItemDeleted)
                        _firstItemDeleted = item;
                    break;
                case CSYNC_INSTRUCTION_SYNC:
                    _numUpdatedItems++;
                    if (!_firstItemUpdated)
                        _firstItemUpdated = item;
                    break;
                case CSYNC_INSTRUCTION_RENAME:
                    if (!_firstItemRenamed) {
                        _firstItemRenamed = item;
                    }
                    _numRenamedItems++;
                    break;
                default:
                    // nothing.
                    break;
                }
            } else if (item._instruction == CSYNC_INSTRUCTION_IGNORE) {
                _foundFilesNotSynced = true;
            }
        }
    }
    
    } // ns mirall
    