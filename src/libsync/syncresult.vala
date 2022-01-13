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
