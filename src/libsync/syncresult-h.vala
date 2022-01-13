/*
 * Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 */

// #include <QStringList>
// #include <QHash>
// #include <QDateTime>

namespace OCC {

/**
 * @brief The SyncResult class
 * @ingroup libsync
 */
class OWNCLOUDSYNC_EXPORT SyncResult {
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

    void appendErrorString (QString &);
    QString errorString () const;
    QStringList errorStrings () const;
    void clearErrors ();

    void setStatus (Status);
    Status status () const;
    QString statusString () const;
    QDateTime syncTime () const;
    void setFolder (QString &folder);
    QString folder () const;

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
    QString _folder;
    /**
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
