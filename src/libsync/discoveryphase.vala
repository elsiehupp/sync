/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <GLib.Object>
// #include <QElapsedTimer>
// #include <QStringList>
// #include <csync.h>
// #include <QMap>
// #include <QSet>
// #include <QMutex>
// #include <QWaitCondition>
// #include <QRunnable>
// #include <deque>


namespace Occ {

enum class LocalDiscoveryStyle {
    FilesystemOnly, //< read all local data from the filesystem
    DatabaseAndFilesystem, //< read from the db, except for listed paths
};


/***********************************************************
Represent all the meta-data about a file in the server
***********************************************************/
struct RemoteInfo {
    /** FileName of the entry (this does not contains any directory or path, just the plain name */
    string name;
    QByteArray etag;
    QByteArray fileId;
    QByteArray checksumHeader;
    Occ.RemotePermissions remotePerm;
    time_t modtime = 0;
    int64_t size = 0;
    int64_t sizeOfFolder = 0;
    bool isDirectory = false;
    bool isE2eEncrypted = false;
    string e2eMangledName;

    bool isValid () { return !name.isNull (); }

    string directDownloadUrl;
    string directDownloadCookies;
};

struct LocalInfo {
    /** FileName of the entry (this does not contains any directory or path, just the plain name */
    string name;
    string renameName;
    time_t modtime = 0;
    int64_t size = 0;
    uint64_t inode = 0;
    ItemType type = ItemTypeSkip;
    bool isDirectory = false;
    bool isHidden = false;
    bool isVirtualFile = false;
    bool isSymLink = false;
    bool isValid () { return !name.isNull (); }
};

/***********************************************************
@brief Run list on a local directory and process the results for Discovery

@ingroup libsync
***********************************************************/
class DiscoverySingleLocalDirectoryJob : GLib.Object, public QRunnable {
public:
    DiscoverySingleLocalDirectoryJob (AccountPtr &account, string &localPath, Occ.Vfs *vfs, GLib.Object *parent = nullptr);

    void run () override;
signals:
    void finished (QVector<LocalInfo> result);
    void finishedFatalError (string errorString);
    void finishedNonFatalError (string errorString);

    void itemDiscovered (SyncFileItemPtr item);
    void childIgnored (bool b);
private slots:
private:
    string _localPath;
    AccountPtr _account;
    Occ.Vfs* _vfs;
public:
};

/***********************************************************
@brief Run a PROPFIND on a directory and process the results for Discovery

@ingroup libsync
***********************************************************/
class DiscoverySingleDirectoryJob : GLib.Object {
public:
    DiscoverySingleDirectoryJob (AccountPtr &account, string &path, GLib.Object *parent = nullptr);
    // Specify that this is the root and we need to check the data-fingerprint
    void setIsRootPath () { _isRootPath = true; }
    void start ();
    void abort ();

    // This is not actually a network job, it is just a job
signals:
    void firstDirectoryPermissions (RemotePermissions);
    void etag (QByteArray &, QDateTime &time);
    void finished (HttpResult<QVector<RemoteInfo>> &result);

private slots:
    void directoryListingIteratedSlot (string &, QMap<string, string> &);
    void lsJobFinishedWithoutErrorSlot ();
    void lsJobFinishedWithErrorSlot (QNetworkReply *);
    void fetchE2eMetadata ();
    void metadataReceived (QJsonDocument &json, int statusCode);
    void metadataError (QByteArray& fileId, int httpReturnCode);

private:
    QVector<RemoteInfo> _results;
    string _subPath;
    QByteArray _firstEtag;
    QByteArray _fileId;
    QByteArray _localFileId;
    AccountPtr _account;
    // The first result is for the directory itself and need to be ignored.
    // This flag is true if it was already ignored.
    bool _ignoredFirst;
    // Set to true if this is the root path and we need to check the data-fingerprint
    bool _isRootPath;
    // If this directory is an external storage (The first item has 'M' in its permission)
    bool _isExternalStorage;
    // If this directory is e2ee
    bool _isE2eEncrypted;
    // If set, the discovery will finish with an error
    int64_t _size = 0;
    string _error;
    QPointer<LsColJob> _lsColJob;

public:
    QByteArray _dataFingerprint;
};

class DiscoveryPhase : GLib.Object {

    friend class ProcessDirectoryJob;

    QPointer<ProcessDirectoryJob> _currentRootJob;

    /** Maps the db-path of a deleted item to its SyncFileItem.
     *
     * If it turns out the item was renamed after all, the instruction
     * can be changed. See findAndCancelDeletedJob (). Note that
     * itemDiscovered () will already have been emitted for the item.
     */
    QMap<string, SyncFileItemPtr> _deletedItem;

    /** Maps the db-path of a deleted folder to its queued job.
     *
     * If a folder is deleted and must be recursed into, its job isn't
     * executed immediately. Instead it's queued here and only run
     * once the rest of the discovery has finished and we are certain
     * that the folder wasn't just renamed. This avoids running the
     * discovery on contents in the old location of renamed folders.
     *
     * See findAndCancelDeletedJob ().
     */
    QMap<string, ProcessDirectoryJob> _queuedDeletedDirectories;

    // map source (original path) . destinations (current server or local path)
    QMap<string, string> _renamedItemsRemote;
    QMap<string, string> _renamedItemsLocal;

    // set of paths that should not be removed even though they are removed locally:
    // there was a move to an invalid destination and now the source should be restored
    //
    // This applies recursively to subdirectories.
    // All entries should have a trailing slash (even files), so lookup with
    // lowerBound () is reliable.
    //
    // The value of this map doesn't matter.
    QMap<string, bool> _forbiddenDeletes;

    /** Returns whether the db-path has been renamed locally or on the remote.
     *
     * Useful for avoiding processing of items that have already been claimed in
     * a rename (would otherwise be discovered as deletions).
     */
    bool isRenamed (string &p) { return _renamedItemsLocal.contains (p) || _renamedItemsRemote.contains (p); }

    int _currentlyActiveJobs = 0;

    // both must contain a sorted list
    QStringList _selectiveSyncBlackList;
    QStringList _selectiveSyncWhiteList;

    void scheduleMoreJobs ();

    bool isInSelectiveSyncBlackList (string &path) const;

    // Check if the new folder should be deselected or not.
    // May be async. "Return" via the callback, true if the item is blacklisted
    void checkSelectiveSyncNewFolder (string &path, RemotePermissions rp,
        std.function<void (bool)> callback);

    /** Given an original path, return the target path obtained when renaming is done.
     *
     * Note that it only considers parent directory renames. So if A/B got renamed to C/D,
     * checking A/B/file would yield C/D/file, but checking A/B would yield A/B.
     */
    string adjustRenamedPath (string &original, SyncFileItem.Direction) const;

    /** If the db-path is scheduled for deletion, abort it.
     *
     * Check if there is already a job to delete that item:
     * If that's not the case, return { false, QByteArray () }.
     * If there is such a job, cancel that job and return true and the old etag.
     *
     * Used when having detected a rename : The rename source may have been
     * discovered before and would have looked like a delete.
     *
     * See _deletedItem and _queuedDeletedDirectories.
     */
    QPair<bool, QByteArray> findAndCancelDeletedJob (string &originalPath);

public:
    // input
    string _localDir; // absolute path to the local directory. ends with '/'
    string _remoteFolder; // remote folder, ends with '/'
    SyncJournalDb *_statedb;
    AccountPtr _account;
    SyncOptions _syncOptions;
    ExcludedFiles *_excludes;
    QRegularExpression _invalidFilenameRx; // FIXME : maybe move in ExcludedFiles
    QStringList _serverBlacklistedFiles; // The blacklist from the capabilities
    bool _ignoreHiddenFiles = false;
    std.function<bool (string &)> _shouldDiscoverLocaly;

    void startJob (ProcessDirectoryJob *);

    void setSelectiveSyncBlackList (QStringList &list);
    void setSelectiveSyncWhiteList (QStringList &list);

    // output
    QByteArray _dataFingerprint;
    bool _anotherSyncNeeded = false;

signals:
    void fatalError (string &errorString);
    void itemDiscovered (SyncFileItemPtr &item);
    void finished ();

    // A new folder was discovered and was not synced because of the confirmation feature
    void newBigFolder (string &folder, bool isExternal);

    /** For excluded items that don't show up in itemDiscovered ()
      *
      * The path is relative to the sync folder, similar to item._file
      */
    void silentlyExcluded (string &folderPath);

    void addErrorToGui (SyncFileItem.Status status, string &errorMessage, string &subject);
};

/// Implementation of DiscoveryPhase.adjustRenamedPath
string adjustRenamedPath (QMap<string, string> &renamedItems, string &original);
}
