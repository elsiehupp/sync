/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <csync_exclude.h>

// #include <QLoggingCategory>
// #include <QUrl>
// #include <QFile>
// #include <QFileInfo>
// #include <QTextCodec>
// #include <cstring>
// #include <QDateTime>

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
    /***********************************************************
    FileName of the entry (this does not contains any directory or path, just the plain name */
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
    /***********************************************************
    FileName of the entry (this does not contains any directory or path, just the plain name */
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

    /***********************************************************
    Maps the db-path of a deleted item to its SyncFileItem.

    If it turns out the item was renamed after all, the instruction
    can be changed. See findAndCancelDeletedJob (). Note that
    itemDiscovered () will already have been emitted for the item.
    ***********************************************************/
    QMap<string, SyncFileItemPtr> _deletedItem;

    /***********************************************************
    Maps the db-path of a deleted folder to its queued job.

    If a folder is deleted and must be recursed into, its job isn't
    executed immediately. Instead it's queued here and only run
    once the rest of the discovery has finished and we are certain
    that the folder wasn't just renamed. This avoids running the
    discovery on contents in the old location of renamed folders.
    
    See findAndCancelDeletedJob ().
    ***********************************************************/
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

    /***********************************************************
    Returns whether the db-path has been renamed locally or on the remote.

    Useful for avoiding processing of items that have already been claimed in
    a rename (would otherwise be discovered as deletions).
    ***********************************************************/
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

    /***********************************************************
    Given an original path, return the target path obtained when renaming is done.

    Note that it only considers parent directory renames. So if A/B got renamed to C/D,
    checking A/B/file would yield C/D/file, but checking A/B would yield A/B.
    ***********************************************************/
    string adjustRenamedPath (string &original, SyncFileItem.Direction) const;

    /***********************************************************
    If the db-path is scheduled for deletion, abort it.

    Check if there is already a job to delete that item:
    If that's not the case, return { false, QByteArray () }.
    If there is such a job, cancel that job and return true and the old etag.
    
    Used when having detected a rename : The rename source 
    discovered before and would have looked like a delete.

    See _deletedItem and _queuedDeletedDirectories.
    ***********************************************************/
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

    /***********************************************************
    For excluded items that don't show up in itemDiscovered ()
      *
      * The path is relative to the sync folder, similar to item._file
      */
    void silentlyExcluded (string &folderPath);

    void addErrorToGui (SyncFileItem.Status status, string &errorMessage, string &subject);
};

/// Implementation of DiscoveryPhase.adjustRenamedPath
string adjustRenamedPath (QMap<string, string> &renamedItems, string &original);

    /* Given a sorted list of paths ending with '/', return whether or not the given path is within one of the paths of the list*/
    static bool findPathInList (QStringList &list, string &path) {
        Q_ASSERT (std.is_sorted (list.begin (), list.end ()));
    
        if (list.size () == 1 && list.first () == QLatin1String ("/")) {
            // Special case for the case "/" is there, it matches everything
            return true;
        }
    
        string pathSlash = path + QLatin1Char ('/');
    
        // Since the list is sorted, we can do a binary search.
        // If the path is a prefix of another item or right after in the lexical order.
        auto it = std.lower_bound (list.begin (), list.end (), pathSlash);
    
        if (it != list.end () && *it == pathSlash) {
            return true;
        }
    
        if (it == list.begin ()) {
            return false;
        }
        --it;
        Q_ASSERT (it.endsWith (QLatin1Char ('/'))); // Folder.setSelectiveSyncBlackList makes sure of that
        return pathSlash.startsWith (*it);
    }
    
    bool DiscoveryPhase.isInSelectiveSyncBlackList (string &path) {
        if (_selectiveSyncBlackList.isEmpty ()) {
            // If there is no black list, everything is allowed
            return false;
        }
    
        // Block if it is in the black list
        if (findPathInList (_selectiveSyncBlackList, path)) {
            return true;
        }
    
        return false;
    }
    
    void DiscoveryPhase.checkSelectiveSyncNewFolder (string &path, RemotePermissions remotePerm,
        std.function<void (bool)> callback) {
        if (_syncOptions._confirmExternalStorage && _syncOptions._vfs.mode () == Vfs.Off
            && remotePerm.hasPermission (RemotePermissions.IsMounted)) {
            // external storage.
    
            /* Note : DiscoverySingleDirectoryJob.directoryListingIteratedSlot make sure that only the
             * root of a mounted storage has 'M', all sub entries have 'm' */
    
            // Only allow it if the white list contains exactly this path (not parents)
            // We want to ask confirmation for external storage even if the parents where selected
            if (_selectiveSyncWhiteList.contains (path + QLatin1Char ('/'))) {
                return callback (false);
            }
    
            emit newBigFolder (path, true);
            return callback (true);
        }
    
        // If this path or the parent is in the white list, then we do not block this file
        if (findPathInList (_selectiveSyncWhiteList, path)) {
            return callback (false);
        }
    
        auto limit = _syncOptions._newBigFolderSizeLimit;
        if (limit < 0 || _syncOptions._vfs.mode () != Vfs.Off) {
            // no limit, everything is allowed;
            return callback (false);
        }
    
        // do a PROPFIND to know the size of this folder
        auto propfindJob = new PropfindJob (_account, _remoteFolder + path, this);
        propfindJob.setProperties (QList<QByteArray> () << "resourcetype"
                                                       << "http://owncloud.org/ns:size");
        GLib.Object.connect (propfindJob, &PropfindJob.finishedWithError,
            this, [=] { return callback (false); });
        GLib.Object.connect (propfindJob, &PropfindJob.result, this, [=] (QVariantMap &values) {
            auto result = values.value (QLatin1String ("size")).toLongLong ();
            if (result >= limit) {
                // we tell the UI there is a new folder
                emit newBigFolder (path, false);
                return callback (true);
            } else {
                // it is not too big, put it in the white list (so we will not do more query for the children)
                // and and do not block.
                auto p = path;
                if (!p.endsWith (QLatin1Char ('/')))
                    p += QLatin1Char ('/');
                _selectiveSyncWhiteList.insert (
                    std.upper_bound (_selectiveSyncWhiteList.begin (), _selectiveSyncWhiteList.end (), p),
                    p);
                return callback (false);
            }
        });
        propfindJob.start ();
    }
    
    /* Given a path on the remote, give the path as it is when the rename is done */
    string DiscoveryPhase.adjustRenamedPath (string &original, SyncFileItem.Direction d) {
        return Occ.adjustRenamedPath (d == SyncFileItem.Down ? _renamedItemsRemote : _renamedItemsLocal, original);
    }
    
    string adjustRenamedPath (QMap<string, string> &renamedItems, string &original) {
        int slashPos = original.size ();
        while ( (slashPos = original.lastIndexOf ('/', slashPos - 1)) > 0) {
            auto it = renamedItems.constFind (original.left (slashPos));
            if (it != renamedItems.constEnd ()) {
                return *it + original.mid (slashPos);
            }
        }
        return original;
    }
    
    QPair<bool, QByteArray> DiscoveryPhase.findAndCancelDeletedJob (string &originalPath) {
        bool result = false;
        QByteArray oldEtag;
        auto it = _deletedItem.find (originalPath);
        if (it != _deletedItem.end ()) {
            const SyncInstructions instruction = (*it)._instruction;
            if (instruction == CSYNC_INSTRUCTION_IGNORE && (*it)._type == ItemTypeVirtualFile) {
                // re-creation of virtual files count as a delete
                // a file might be in an error state and thus gets marked as CSYNC_INSTRUCTION_IGNORE
                // after it was initially marked as CSYNC_INSTRUCTION_REMOVE
                // return true, to not trigger any additional actions on that file that could elad to dataloss
                result = true;
                oldEtag = (*it)._etag;
            } else {
                if (! (instruction == CSYNC_INSTRUCTION_REMOVE
                        // re-creation of virtual files count as a delete
                        || ( (*it)._type == ItemTypeVirtualFile && instruction == CSYNC_INSTRUCTION_NEW)
                        || ( (*it)._isRestoration && instruction == CSYNC_INSTRUCTION_NEW))) {
                    qCWarning (lcDiscovery) << "ENFORCE (FAILING)" << originalPath;
                    qCWarning (lcDiscovery) << "instruction == CSYNC_INSTRUCTION_REMOVE" << (instruction == CSYNC_INSTRUCTION_REMOVE);
                    qCWarning (lcDiscovery) << " ( (*it)._type == ItemTypeVirtualFile && instruction == CSYNC_INSTRUCTION_NEW)"
                                           << ( (*it)._type == ItemTypeVirtualFile && instruction == CSYNC_INSTRUCTION_NEW);
                    qCWarning (lcDiscovery) << " ( (*it)._isRestoration && instruction == CSYNC_INSTRUCTION_NEW))"
                                           << ( (*it)._isRestoration && instruction == CSYNC_INSTRUCTION_NEW);
                    qCWarning (lcDiscovery) << "instruction" << instruction;
                    qCWarning (lcDiscovery) << " (*it)._type" << (*it)._type;
                    qCWarning (lcDiscovery) << " (*it)._isRestoration " << (*it)._isRestoration;
                    Q_ASSERT (false);
                    addErrorToGui (SyncFileItem.Status.FatalError, tr ("Error while canceling delete of a file"), originalPath);
                    emit fatalError (tr ("Error while canceling delete of %1").arg (originalPath));
                }
                (*it)._instruction = CSYNC_INSTRUCTION_NONE;
                result = true;
                oldEtag = (*it)._etag;
            }
            _deletedItem.erase (it);
        }
        if (auto *otherJob = _queuedDeletedDirectories.take (originalPath)) {
            oldEtag = otherJob._dirItem._etag;
            delete otherJob;
            result = true;
        }
        return { result, oldEtag };
    }
    
    void DiscoveryPhase.startJob (ProcessDirectoryJob *job) {
        ENFORCE (!_currentRootJob);
        connect (job, &ProcessDirectoryJob.finished, this, [this, job] {
            ENFORCE (_currentRootJob == sender ());
            _currentRootJob = nullptr;
            if (job._dirItem)
                emit itemDiscovered (job._dirItem);
            job.deleteLater ();
    
            // Once the main job has finished recurse here to execute the remaining
            // jobs for queued deleted directories.
            if (!_queuedDeletedDirectories.isEmpty ()) {
                auto nextJob = _queuedDeletedDirectories.take (_queuedDeletedDirectories.firstKey ());
                startJob (nextJob);
            } else {
                emit finished ();
            }
        });
        _currentRootJob = job;
        job.start ();
    }
    
    void DiscoveryPhase.setSelectiveSyncBlackList (QStringList &list) {
        _selectiveSyncBlackList = list;
        std.sort (_selectiveSyncBlackList.begin (), _selectiveSyncBlackList.end ());
    }
    
    void DiscoveryPhase.setSelectiveSyncWhiteList (QStringList &list) {
        _selectiveSyncWhiteList = list;
        std.sort (_selectiveSyncWhiteList.begin (), _selectiveSyncWhiteList.end ());
    }
    
    void DiscoveryPhase.scheduleMoreJobs () {
        auto limit = qMax (1, _syncOptions._parallelNetworkJobs);
        if (_currentRootJob && _currentlyActiveJobs < limit) {
            _currentRootJob.processSubJobs (limit - _currentlyActiveJobs);
        }
    }
    
    DiscoverySingleLocalDirectoryJob.DiscoverySingleLocalDirectoryJob (AccountPtr &account, string &localPath, Occ.Vfs *vfs, GLib.Object *parent)
     : GLib.Object (parent), QRunnable (), _localPath (localPath), _account (account), _vfs (vfs) {
        qRegisterMetaType<QVector<LocalInfo> > ("QVector<LocalInfo>");
    }
    
    // Use as QRunnable
    void DiscoverySingleLocalDirectoryJob.run () {
        string localPath = _localPath;
        if (localPath.endsWith ('/')) // Happens if _currentFolder._local.isEmpty ()
            localPath.chop (1);
    
        auto dh = csync_vio_local_opendir (localPath);
        if (!dh) {
            qCInfo (lcDiscovery) << "Error while opening directory" << (localPath) << errno;
            string errorString = tr ("Error while opening directory %1").arg (localPath);
            if (errno == EACCES) {
                errorString = tr ("Directory not accessible on client, permission denied");
                emit finishedNonFatalError (errorString);
                return;
            } else if (errno == ENOENT) {
                errorString = tr ("Directory not found : %1").arg (localPath);
            } else if (errno == ENOTDIR) {
                // Not a directory..
                // Just consider it is empty
                return;
            }
            emit finishedFatalError (errorString);
            return;
        }
    
        QVector<LocalInfo> results;
        while (true) {
            errno = 0;
            auto dirent = csync_vio_local_readdir (dh, _vfs);
            if (!dirent)
                break;
            if (dirent.type == ItemTypeSkip)
                continue;
            LocalInfo i;
            static QTextCodec *codec = QTextCodec.codecForName ("UTF-8");
            ASSERT (codec);
            QTextCodec.ConverterState state;
            i.name = codec.toUnicode (dirent.path, dirent.path.size (), &state);
            if (state.invalidChars > 0 || state.remainingChars > 0) {
                emit childIgnored (true);
                auto item = SyncFileItemPtr.create ();
                //item._file = _currentFolder._target + i.name;
                // FIXME ^^ do we really need to use _target or is local fine?
                item._file = _localPath + i.name;
                item._instruction = CSYNC_INSTRUCTION_IGNORE;
                item._status = SyncFileItem.NormalError;
                item._errorString = tr ("Filename encoding is not valid");
                emit itemDiscovered (item);
                continue;
            }
            i.modtime = dirent.modtime;
            i.size = dirent.size;
            i.inode = dirent.inode;
            i.isDirectory = dirent.type == ItemTypeDirectory;
            i.isHidden = dirent.is_hidden;
            i.isSymLink = dirent.type == ItemTypeSoftLink;
            i.isVirtualFile = dirent.type == ItemTypeVirtualFile || dirent.type == ItemTypeVirtualFileDownload;
            i.type = dirent.type;
            results.push_back (i);
        }
        if (errno != 0) {
            csync_vio_local_closedir (dh);
    
            // Note : Windows vio converts any error into EACCES
            qCWarning (lcDiscovery) << "readdir failed for file in " << localPath << " - errno : " << errno;
            emit finishedFatalError (tr ("Error while reading directory %1").arg (localPath));
            return;
        }
    
        errno = 0;
        csync_vio_local_closedir (dh);
        if (errno != 0) {
            qCWarning (lcDiscovery) << "closedir failed for file in " << localPath << " - errno : " << errno;
        }
    
        emit finished (results);
    }
    
    DiscoverySingleDirectoryJob.DiscoverySingleDirectoryJob (AccountPtr &account, string &path, GLib.Object *parent)
        : GLib.Object (parent)
        , _subPath (path)
        , _account (account)
        , _ignoredFirst (false)
        , _isRootPath (false)
        , _isExternalStorage (false)
        , _isE2eEncrypted (false) {
    }
    
    void DiscoverySingleDirectoryJob.start () {
        // Start the actual HTTP job
        auto *lsColJob = new LsColJob (_account, _subPath, this);
    
        QList<QByteArray> props;
        props << "resourcetype"
              << "getlastmodified"
              << "getcontentlength"
              << "getetag"
              << "http://owncloud.org/ns:size"
              << "http://owncloud.org/ns:id"
              << "http://owncloud.org/ns:fileid"
              << "http://owncloud.org/ns:downloadURL"
              << "http://owncloud.org/ns:dDC"
              << "http://owncloud.org/ns:permissions"
              << "http://owncloud.org/ns:checksums";
        if (_isRootPath)
            props << "http://owncloud.org/ns:data-fingerprint";
        if (_account.serverVersionInt () >= Account.makeServerVersion (10, 0, 0)) {
            // Server older than 10.0 have performances issue if we ask for the share-types on every PROPFIND
            props << "http://owncloud.org/ns:share-types";
        }
        if (_account.capabilities ().clientSideEncryptionAvailable ()) {
            props << "http://nextcloud.org/ns:is-encrypted";
        }
    
        lsColJob.setProperties (props);
    
        GLib.Object.connect (lsColJob, &LsColJob.directoryListingIterated,
            this, &DiscoverySingleDirectoryJob.directoryListingIteratedSlot);
        GLib.Object.connect (lsColJob, &LsColJob.finishedWithError, this, &DiscoverySingleDirectoryJob.lsJobFinishedWithErrorSlot);
        GLib.Object.connect (lsColJob, &LsColJob.finishedWithoutError, this, &DiscoverySingleDirectoryJob.lsJobFinishedWithoutErrorSlot);
        lsColJob.start ();
    
        _lsColJob = lsColJob;
    }
    
    void DiscoverySingleDirectoryJob.abort () {
        if (_lsColJob && _lsColJob.reply ()) {
            _lsColJob.reply ().abort ();
        }
    }
    
    static void propertyMapToRemoteInfo (QMap<string, string> &map, RemoteInfo &result) {
        for (auto it = map.constBegin (); it != map.constEnd (); ++it) {
            string property = it.key ();
            string value = it.value ();
            if (property == QLatin1String ("resourcetype")) {
                result.isDirectory = value.contains (QLatin1String ("collection"));
            } else if (property == QLatin1String ("getlastmodified")) {
                const auto date = QDateTime.fromString (value, Qt.RFC2822Date);
                Q_ASSERT (date.isValid ());
                result.modtime = date.toTime_t ();
            } else if (property == QLatin1String ("getcontentlength")) {
                // See #4573, sometimes negative size values are returned
                bool ok = false;
                qlonglong ll = value.toLongLong (&ok);
                if (ok && ll >= 0) {
                    result.size = ll;
                } else {
                    result.size = 0;
                }
            } else if (property == "getetag") {
                result.etag = Utility.normalizeEtag (value.toUtf8 ());
            } else if (property == "id") {
                result.fileId = value.toUtf8 ();
            } else if (property == "downloadURL") {
                result.directDownloadUrl = value;
            } else if (property == "dDC") {
                result.directDownloadCookies = value;
            } else if (property == "permissions") {
                result.remotePerm = RemotePermissions.fromServerString (value);
            } else if (property == "checksums") {
                result.checksumHeader = findBestChecksum (value.toUtf8 ());
            } else if (property == "share-types" && !value.isEmpty ()) {
                // Since QMap is sorted, "share-types" is always after "permissions".
                if (result.remotePerm.isNull ()) {
                    qWarning () << "Server returned a share type, but no permissions?";
                } else {
                    // S means shared with me.
                    // But for our purpose, we want to know if the file is shared. It does not matter
                    // if we are the owner or not.
                    // Piggy back on the persmission field
                    result.remotePerm.setPermission (RemotePermissions.IsShared);
                }
            } else if (property == "is-encrypted" && value == QStringLiteral ("1")) {
                result.isE2eEncrypted = true;
            }
        }
    
        if (result.isDirectory && map.contains ("size")) {
            result.sizeOfFolder = map.value ("size").toInt ();
        }
    }
    
    void DiscoverySingleDirectoryJob.directoryListingIteratedSlot (string &file, QMap<string, string> &map) {
        if (!_ignoredFirst) {
            // The first entry is for the folder itself, we should process it differently.
            _ignoredFirst = true;
            if (map.contains ("permissions")) {
                auto perm = RemotePermissions.fromServerString (map.value ("permissions"));
                emit firstDirectoryPermissions (perm);
                _isExternalStorage = perm.hasPermission (RemotePermissions.IsMounted);
            }
            if (map.contains ("data-fingerprint")) {
                _dataFingerprint = map.value ("data-fingerprint").toUtf8 ();
                if (_dataFingerprint.isEmpty ()) {
                    // Placeholder that means that the server supports the feature even if it did not set one.
                    _dataFingerprint = "[empty]";
                }
            }
            if (map.contains (QStringLiteral ("fileid"))) {
                _localFileId = map.value (QStringLiteral ("fileid")).toUtf8 ();
            }
            if (map.contains ("id")) {
                _fileId = map.value ("id").toUtf8 ();
            }
            if (map.contains ("is-encrypted") && map.value ("is-encrypted") == QStringLiteral ("1")) {
                _isE2eEncrypted = true;
                Q_ASSERT (!_fileId.isEmpty ());
            }
            if (map.contains ("size")) {
                _size = map.value ("size").toInt ();
            }
        } else {
    
            RemoteInfo result;
            int slash = file.lastIndexOf ('/');
            result.name = file.mid (slash + 1);
            result.size = -1;
            propertyMapToRemoteInfo (map, result);
            if (result.isDirectory)
                result.size = 0;
    
            if (_isExternalStorage && result.remotePerm.hasPermission (RemotePermissions.IsMounted)) {
                /* All the entries in a external storage have 'M' in their permission. However, for all
                   purposes in the desktop client, we only need to know about the mount points.
                   So replace the 'M' by a 'm' for every sub entries in an external storage */
                result.remotePerm.unsetPermission (RemotePermissions.IsMounted);
                result.remotePerm.setPermission (RemotePermissions.IsMountedSub);
            }
            _results.push_back (std.move (result));
        }
    
        //This works in concerto with the RequestEtagJob and the Folder object to check if the remote folder changed.
        if (map.contains ("getetag")) {
            if (_firstEtag.isEmpty ()) {
                _firstEtag = parseEtag (map.value (QStringLiteral ("getetag")).toUtf8 ()); // for directory itself
            }
        }
    }
    
    void DiscoverySingleDirectoryJob.lsJobFinishedWithoutErrorSlot () {
        if (!_ignoredFirst) {
            // This is a sanity check, if we haven't _ignoredFirst then it means we never received any directoryListingIteratedSlot
            // which means somehow the server XML was bogus
            emit finished (HttpError{ 0, tr ("Server error : PROPFIND reply is not XML formatted!") });
            deleteLater ();
            return;
        } else if (!_error.isEmpty ()) {
            emit finished (HttpError{ 0, _error });
            deleteLater ();
            return;
        } else if (_isE2eEncrypted) {
            emit etag (_firstEtag, QDateTime.fromString (string.fromUtf8 (_lsColJob.responseTimestamp ()), Qt.RFC2822Date));
            fetchE2eMetadata ();
            return;
        }
        emit etag (_firstEtag, QDateTime.fromString (string.fromUtf8 (_lsColJob.responseTimestamp ()), Qt.RFC2822Date));
        emit finished (_results);
        deleteLater ();
    }
    
    void DiscoverySingleDirectoryJob.lsJobFinishedWithErrorSlot (QNetworkReply *r) {
        string contentType = r.header (QNetworkRequest.ContentTypeHeader).toString ();
        int httpCode = r.attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
        string msg = r.errorString ();
        qCWarning (lcDiscovery) << "LSCOL job error" << r.errorString () << httpCode << r.error ();
        if (r.error () == QNetworkReply.NoError
            && !contentType.contains ("application/xml; charset=utf-8")) {
            msg = tr ("Server error : PROPFIND reply is not XML formatted!");
        }
        emit finished (HttpError{ httpCode, msg });
        deleteLater ();
    }
    
    void DiscoverySingleDirectoryJob.fetchE2eMetadata () {
        const auto job = new GetMetadataApiJob (_account, _localFileId);
        connect (job, &GetMetadataApiJob.jsonReceived,
                this, &DiscoverySingleDirectoryJob.metadataReceived);
        connect (job, &GetMetadataApiJob.error,
                this, &DiscoverySingleDirectoryJob.metadataError);
        job.start ();
    }
    
    void DiscoverySingleDirectoryJob.metadataReceived (QJsonDocument &json, int statusCode) {
        qCDebug (lcDiscovery) << "Metadata received, applying it to the result list";
        Q_ASSERT (_subPath.startsWith ('/'));
    
        const auto metadata = FolderMetadata (_account, json.toJson (QJsonDocument.Compact), statusCode);
        const auto encryptedFiles = metadata.files ();
    
        const auto findEncryptedFile = [=] (string &name) {
            const auto it = std.find_if (std.cbegin (encryptedFiles), std.cend (encryptedFiles), [=] (EncryptedFile &file) {
                return file.encryptedFilename == name;
            });
            if (it == std.cend (encryptedFiles)) {
                return Optional<EncryptedFile> ();
            } else {
                return Optional<EncryptedFile> (*it);
            }
        };
    
        std.transform (std.cbegin (_results), std.cend (_results), std.begin (_results), [=] (RemoteInfo &info) {
            auto result = info;
            const auto encryptedFileInfo = findEncryptedFile (result.name);
            if (encryptedFileInfo) {
                result.isE2eEncrypted = true;
                result.e2eMangledName = _subPath.mid (1) + QLatin1Char ('/') + result.name;
                result.name = encryptedFileInfo.originalFilename;
            }
            return result;
        });
    
        emit finished (_results);
        deleteLater ();
    }
    
    void DiscoverySingleDirectoryJob.metadataError (QByteArray &fileId, int httpReturnCode) {
        qCWarning (lcDiscovery) << "E2EE Metadata job error. Trying to proceed without it." << fileId << httpReturnCode;
        emit finished (_results);
        deleteLater ();
    }
    }
    