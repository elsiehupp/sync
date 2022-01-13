/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <unistd.h>

// #include <climits>
// #include <cassert>
// #include <chrono>

// #include <QCoreApplication>
// #include <QSslSocket>
// #include <QDir>
// #include <QLoggingCategory>
// #include <QMutexLocker>
// #include <QThread>
// #include <QStringList>
// #include <QTextStream>
// #include <QTime>
// #include <QUrl>
// #include <QSslCertificate>
// #include <QProcess>
// #include <QElapsedTimer>
// #include <QFileInfo>
// #include <qtextcodec.h>

// #pragma once

// #include <cstdint>

// #include <QMutex>
// #include <QThread>
// #include <string>
// #include <QSet>
// #include <QMap>
// #include <QStringList>
// #include <QSharedPointer>
// #include <set>


namespace Occ {

class ProcessDirectoryJob;

enum AnotherSyncNeeded {
    NoFollowUpSync,
    ImmediateFollowUp, // schedule this again immediately (limited amount of times)
    DelayedFollowUp // regularly schedule this folder again (around 1/minute, unlimited)
};

/***********************************************************
@brief The SyncEngine class
@ingroup libsync
***********************************************************/
class SyncEngine : GLib.Object {
public:
    SyncEngine (AccountPtr account, string &localPath,
        const string &remotePath, SyncJournalDb *journal);
    ~SyncEngine () override;

    Q_INVOKABLE void startSync ();
    void setNetworkLimits (int upload, int download);

    /* Abort the sync.  Called from the main thread */
    void abort ();

    bool isSyncRunning () { return _syncRunning; }

    SyncOptions syncOptions () { return _syncOptions; }
    void setSyncOptions (SyncOptions &options) { _syncOptions = options; }
    bool ignoreHiddenFiles () { return _ignore_hidden_files; }
    void setIgnoreHiddenFiles (bool ignore) { _ignore_hidden_files = ignore; }

    ExcludedFiles &excludedFiles () { return *_excludedFiles; }
    Utility.StopWatch &stopWatch () { return _stopWatch; }
    SyncFileStatusTracker &syncFileStatusTracker () { return *_syncFileStatusTracker; }

    /* Returns whether another sync is needed to complete the sync */
    AnotherSyncNeeded isAnotherSyncNeeded () { return _anotherSyncNeeded; }

    bool wasFileTouched (string &fn) const;

    AccountPtr account ();
    SyncJournalDb *journal () { return _journal; }
    string localPath () { return _localPath; }

    /***********************************************************
    Duration in ms that uploads should be delayed after a file change

    In certain situations a file can be written to very regularly over a large
    amount of time. Copying a large file could take a while. A logfile could be
    updated every second.
    
    In these cases it isn't desirable to attempt to upload the "unfinished" file
    To avoid that, uploads of files where the distance between the mtime and the
    current time is less than this duration are skipped.
    ***********************************************************/
    static std.chrono.milliseconds minimumFileAgeForUpload;

    /***********************************************************
    Control whether local discovery should read from filesystem or db.
    
    If style is DatabaseAndFilesystem, paths a set of file paths relative
    the synced folder. All the parent directories of th
    be read from the db and scanned on the filesystem.
    
    Note, the style and paths are only retained for the next sync and
    revert afterwards. Use _lastLocalDiscoveryStyle to discover the last
    sync's style.
    ***********************************************************/
    void setLocalDiscoveryOptions (LocalDiscoveryStyle style, std.set<string> paths = {});

    /***********************************************************
    Returns whether the given folder-relative path should be locally discovered
    given the local discovery options.
    
    Example : If path is 'foo/bar' and style is DatabaseAndFilesystem and dirs contains
        'foo/bar/touched_file', then the result will be true.
    ***********************************************************/
    bool shouldDiscoverLocally (string &path) const;

    /***********************************************************
    Access the last sync run's local discovery style */
    LocalDiscoveryStyle lastLocalDiscoveryStyle () { return _lastLocalDiscoveryStyle; }

    /***********************************************************
    Removes all virtual file db entries and dehydrated local placeholders.

    Particularly useful when switching off vfs mode or switching to a
    different kind of vfs.
    
    Note that *hydrated* placeholder files might still be left. These will
    get cleaned up by Vfs.unregisterFolder ().
    ***********************************************************/
    static void wipeVirtualFiles (string &localPath, SyncJournalDb &journal, Vfs &vfs);

    static void switchToVirtualFiles (string &localPath, SyncJournalDb &journal, Vfs &vfs);

    auto getPropagator () { return _propagator; } // for the test

signals:
    // During update, before reconcile
    void rootEtag (QByteArray &, QDateTime &);

    // after the above signals. with the items that actually need propagating
    void aboutToPropagate (SyncFileItemVector &);

    // after each item completed by a job (successful or not)
    void itemCompleted (SyncFileItemPtr &);

    void transmissionProgress (ProgressInfo &progress);

    /// We've produced a new sync error of a type.
    void syncError (string &message, ErrorCategory category = ErrorCategory.Normal);

    void addErrorToGui (SyncFileItem.Status status, string &errorMessage, string &subject);

    void finished (bool success);
    void started ();

    /***********************************************************
    Emited when the sync engine detects that all the files have been removed or change.
    This usually happen when the server was reset or something.
    Set *cancel to true in a slot connected from this signal to abort the sync.
    ***********************************************************/
    void aboutToRemoveAllFiles (SyncFileItem.Direction direction, std.function<void (bool)> f);

    // A new folder was discovered and was not synced because of the confirmation feature
    void newBigFolder (string &folder, bool isExternal);

    /***********************************************************
    Emitted when propagation has problems with a locked file.

    Forwarded from OwncloudPropagator.seenLockedFile.
    ***********************************************************/
    void seenLockedFile (string &fileName);

private slots:
    void slotFolderDiscovered (bool local, string &folder);
    void slotRootEtagReceived (QByteArray &, QDateTime &time);

    /***********************************************************
    When the discovery phase discovers an item */
    void slotItemDiscovered (SyncFileItemPtr &item);

    /***********************************************************
    Called when a SyncFileItem gets accepted for a sync.

    Mostly done in initial creation inside treewalkFile but
    can also be called via the propagator for items that are
    created during propagation.
    ***********************************************************/
    void slotNewItem (SyncFileItemPtr &item);

    void slotItemCompleted (SyncFileItemPtr &item);
    void slotDiscoveryFinished ();
    void slotPropagationFinished (bool success);
    void slotProgress (SyncFileItem &item, int64 curent);
    void slotCleanPollsJobAborted (string &error);

    /***********************************************************
    Records that a file was touched by a job. */
    void slotAddTouchedFile (string &fn);

    /***********************************************************
    Wipes the _touchedFiles hash */
    void slotClearTouchedFiles ();

    /***********************************************************
    Emit a summary error, unless it was seen before */
    void slotSummaryError (string &message);

    void slotInsufficientLocalStorage ();
    void slotInsufficientRemoteStorage ();

private:
    bool checkErrorBlacklisting (SyncFileItem &item);

    // Cleans up unnecessary downloadinfo entries in the journal as well
    // as their temporary files.
    void deleteStaleDownloadInfos (SyncFileItemVector &syncItems);

    // Removes stale uploadinfos from the journal.
    void deleteStaleUploadInfos (SyncFileItemVector &syncItems);

    // Removes stale error blacklist entries from the journal.
    void deleteStaleErrorBlacklistEntries (SyncFileItemVector &syncItems);

    // Removes stale and adds missing conflict records after sync
    void conflictRecordMaintenance ();

    // cleanup and emit the finished signal
    void finalize (bool success);

    static bool s_anySyncRunning; //true when one sync is running somewhere (for debugging)

    // Must only be acessed during update and reconcile
    QVector<SyncFileItemPtr> _syncItems;

    AccountPtr _account;
    bool _needsUpdate;
    bool _syncRunning;
    string _localPath;
    string _remotePath;
    QByteArray _remoteRootEtag;
    SyncJournalDb *_journal;
    QScopedPointer<DiscoveryPhase> _discoveryPhase;
    QSharedPointer<OwncloudPropagator> _propagator;

    QSet<string> _bulkUploadBlackList;

    // List of all files with conflicts
    QSet<string> _seenConflictFiles;

    QScopedPointer<ProgressInfo> _progressInfo;

    QScopedPointer<ExcludedFiles> _excludedFiles;
    QScopedPointer<SyncFileStatusTracker> _syncFileStatusTracker;
    Utility.StopWatch _stopWatch;

    /***********************************************************
    check if we are allowed to propagate everything, and if we are not, adjust the instructions
    to recover
    ***********************************************************/
    void checkForPermission (SyncFileItemVector &syncItems);
    RemotePermissions getPermissions (string &file) const;

    /***********************************************************
    Instead of downloading files from the server, upload the files to the server
    ***********************************************************/
    void restoreOldFiles (SyncFileItemVector &syncItems);

    // true if there is at least one file which was not changed on the server
    bool _hasNoneFiles;

    // true if there is at leasr one file with instruction REMOVE
    bool _hasRemoveFile;

    // If ignored files should be ignored
    bool _ignore_hidden_files = false;

    int _uploadLimit;
    int _downloadLimit;
    SyncOptions _syncOptions;

    AnotherSyncNeeded _anotherSyncNeeded;

    /***********************************************************
    Stores the time since a job touched a file. */
    QMultiMap<QElapsedTimer, string> _touchedFiles;

    QElapsedTimer _lastUpdateProgressCallbackCall;

    /***********************************************************
    For clearing the _touchedFiles variable after sync finished */
    QTimer _clearTouchedFilesTimer;

    /***********************************************************
    List of unique errors that occurred in a sync run. */
    QSet<string> _uniqueErrors;

    /***********************************************************
    The kind of local discovery the last sync run used */
    LocalDiscoveryStyle _lastLocalDiscoveryStyle = LocalDiscoveryStyle.FilesystemOnly;
    LocalDiscoveryStyle _localDiscoveryStyle = LocalDiscoveryStyle.FilesystemOnly;
    std.set<string> _localDiscoveryPaths;
};

    bool SyncEngine.s_anySyncRunning = false;
    
    /***********************************************************
    When the client touches a file, block change notifications for this duration (ms)
    
    On Linux and Windows the file watcher can't distinguish a change that originates
    from the client (like a download during a sync operation) and an external change.
    To work around that, all files the client touches are recorded and file change
    notifications for these are blocked for some time. This value controls for how
    long.
    
    Reasons this delay can't be very small:
    - it takes time for the change notification to arrive and to be processed by th
    - some time could pass between the client recording that a file will be touched
      and its filesystem operation finishing, triggering the notification
    ***********************************************************/
    static const std.chrono.milliseconds s_touchedFilesMaxAgeMs (3 * 1000);
    
    // doc in header
    std.chrono.milliseconds SyncEngine.minimumFileAgeForUpload (2000);
    
    SyncEngine.SyncEngine (AccountPtr account, string &localPath,
        const string &remotePath, Occ.SyncJournalDb *journal)
        : _account (account)
        , _needsUpdate (false)
        , _syncRunning (false)
        , _localPath (localPath)
        , _remotePath (remotePath)
        , _journal (journal)
        , _progressInfo (new ProgressInfo)
        , _hasNoneFiles (false)
        , _hasRemoveFile (false)
        , _uploadLimit (0)
        , _downloadLimit (0)
        , _anotherSyncNeeded (NoFollowUpSync) {
        qRegisterMetaType<SyncFileItem> ("SyncFileItem");
        qRegisterMetaType<SyncFileItemPtr> ("SyncFileItemPtr");
        qRegisterMetaType<SyncFileItem.Status> ("SyncFileItem.Status");
        qRegisterMetaType<SyncFileStatus> ("SyncFileStatus");
        qRegisterMetaType<SyncFileItemVector> ("SyncFileItemVector");
        qRegisterMetaType<SyncFileItem.Direction> ("SyncFileItem.Direction");
    
        // Everything in the SyncEngine expects a trailing slash for the localPath.
        ASSERT (localPath.endsWith (QLatin1Char ('/')));
    
        _excludedFiles.reset (new ExcludedFiles (localPath));
    
        _syncFileStatusTracker.reset (new SyncFileStatusTracker (this));
    
        _clearTouchedFilesTimer.setSingleShot (true);
        _clearTouchedFilesTimer.setInterval (30 * 1000);
        connect (&_clearTouchedFilesTimer, &QTimer.timeout, this, &SyncEngine.slotClearTouchedFiles);
        connect (this, &SyncEngine.finished, [this] (bool /* finished */) {
            _journal.keyValueStoreSet ("last_sync", QDateTime.currentSecsSinceEpoch ());
        });
    }
    
    SyncEngine.~SyncEngine () {
        abort ();
        _excludedFiles.reset ();
    }
    
    /***********************************************************
    Check if the item is in the blacklist.
    If it should not be sync'ed because of the blacklist, update the item with the error instruction
    and proper error message, and return true.
    If the item is not in the blacklist, or the blacklist is stale, return false.
    ***********************************************************/
    bool SyncEngine.checkErrorBlacklisting (SyncFileItem &item) {
        if (!_journal) {
            qCCritical (lcEngine) << "Journal is undefined!";
            return false;
        }
    
        SyncJournalErrorBlacklistRecord entry = _journal.errorBlacklistEntry (item._file);
        item._hasBlacklistEntry = false;
    
        if (!entry.isValid ()) {
            return false;
        }
    
        item._hasBlacklistEntry = true;
    
        // If duration has expired, it's not blacklisted anymore
        time_t now = Utility.qDateTimeToTime_t (QDateTime.currentDateTimeUtc ());
        if (now >= entry._lastTryTime + entry._ignoreDuration) {
            qCInfo (lcEngine) << "blacklist entry for " << item._file << " has expired!";
            return false;
        }
    
        // If the file has changed locally or on the server, the blacklist
        // entry no longer applies
        if (item._direction == SyncFileItem.Up) { // check the modtime
            if (item._modtime == 0 || entry._lastTryModtime == 0) {
                return false;
            } else if (item._modtime != entry._lastTryModtime) {
                qCInfo (lcEngine) << item._file << " is blacklisted, but has changed mtime!";
                return false;
            } else if (item._renameTarget != entry._renameTarget) {
                qCInfo (lcEngine) << item._file << " is blacklisted, but rename target changed from" << entry._renameTarget;
                return false;
            }
        } else if (item._direction == SyncFileItem.Down) {
            // download, check the etag.
            if (item._etag.isEmpty () || entry._lastTryEtag.isEmpty ()) {
                qCInfo (lcEngine) << item._file << "one ETag is empty, no blacklisting";
                return false;
            } else if (item._etag != entry._lastTryEtag) {
                qCInfo (lcEngine) << item._file << " is blacklisted, but has changed etag!";
                return false;
            }
        }
    
        int64 waitSeconds = entry._lastTryTime + entry._ignoreDuration - now;
        qCInfo (lcEngine) << "Item is on blacklist : " << entry._file
                         << "retries:" << entry._retryCount
                         << "for another" << waitSeconds << "s";
    
        // We need to indicate that we skip this file due to blacklisting
        // for reporting and for making sure we don't update the blacklist
        // entry yet.
        // Classification is this _instruction and _status
        item._instruction = CSYNC_INSTRUCTION_IGNORE;
        item._status = SyncFileItem.BlacklistedError;
    
        auto waitSecondsStr = Utility.durationToDescriptiveString1 (1000 * waitSeconds);
        item._errorString = tr ("%1 (skipped due to earlier error, trying again in %2)").arg (entry._errorString, waitSecondsStr);
    
        if (entry._errorCategory == SyncJournalErrorBlacklistRecord.InsufficientRemoteStorage) {
            slotInsufficientRemoteStorage ();
        }
    
        return true;
    }
    
    static bool isFileTransferInstruction (SyncInstructions instruction) {
        return instruction == CSYNC_INSTRUCTION_CONFLICT
            || instruction == CSYNC_INSTRUCTION_NEW
            || instruction == CSYNC_INSTRUCTION_SYNC
            || instruction == CSYNC_INSTRUCTION_TYPE_CHANGE;
    }
    
    void SyncEngine.deleteStaleDownloadInfos (SyncFileItemVector &syncItems) {
        // Find all downloadinfo paths that we want to preserve.
        QSet<string> download_file_paths;
        foreach (SyncFileItemPtr &it, syncItems) {
            if (it._direction == SyncFileItem.Down
                && it._type == ItemTypeFile
                && isFileTransferInstruction (it._instruction)) {
                download_file_paths.insert (it._file);
            }
        }
    
        // Delete from journal and from filesystem.
        const QVector<SyncJournalDb.DownloadInfo> deleted_infos =
            _journal.getAndDeleteStaleDownloadInfos (download_file_paths);
        foreach (SyncJournalDb.DownloadInfo &deleted_info, deleted_infos) {
            const string tmppath = _propagator.fullLocalPath (deleted_info._tmpfile);
            qCInfo (lcEngine) << "Deleting stale temporary file : " << tmppath;
            FileSystem.remove (tmppath);
        }
    }
    
    void SyncEngine.deleteStaleUploadInfos (SyncFileItemVector &syncItems) {
        // Find all blacklisted paths that we want to preserve.
        QSet<string> upload_file_paths;
        foreach (SyncFileItemPtr &it, syncItems) {
            if (it._direction == SyncFileItem.Up
                && it._type == ItemTypeFile
                && isFileTransferInstruction (it._instruction)) {
                upload_file_paths.insert (it._file);
            }
        }
    
        // Delete from journal.
        auto ids = _journal.deleteStaleUploadInfos (upload_file_paths);
    
        // Delete the stales chunk on the server.
        if (account ().capabilities ().chunkingNg ()) {
            foreach (uint transferId, ids) {
                if (!transferId)
                    continue; // Was not a chunked upload
                QUrl url = Utility.concatUrlPath (account ().url (), QLatin1String ("remote.php/dav/uploads/") + account ().davUser () + QLatin1Char ('/') + string.number (transferId));
                (new DeleteJob (account (), url, this)).start ();
            }
        }
    }
    
    void SyncEngine.deleteStaleErrorBlacklistEntries (SyncFileItemVector &syncItems) {
        // Find all blacklisted paths that we want to preserve.
        QSet<string> blacklist_file_paths;
        foreach (SyncFileItemPtr &it, syncItems) {
            if (it._hasBlacklistEntry)
                blacklist_file_paths.insert (it._file);
        }
    
        // Delete from journal.
        _journal.deleteStaleErrorBlacklistEntries (blacklist_file_paths);
    }
    
    #if (QT_VERSION < 0x050600)
    template <typename T>
    constexpr typename std.add_const<T>.type &qAsConst (T &t) noexcept { return t; }
    #endif
    
    void SyncEngine.conflictRecordMaintenance () {
        // Remove stale conflict entries from the database
        // by checking which files still exist and removing the
        // missing ones.
        const auto conflictRecordPaths = _journal.conflictRecordPaths ();
        for (auto &path : conflictRecordPaths) {
            auto fsPath = _propagator.fullLocalPath (string.fromUtf8 (path));
            if (!QFileInfo (fsPath).exists ()) {
                _journal.deleteConflictRecord (path);
            }
        }
    
        // Did the sync see any conflict files that don't yet have records?
        // If so, add them now.
        //
        // This happens when the conflicts table is new or when conflict files
        // are downlaoded but the server doesn't send conflict headers.
        for (auto &path : qAsConst (_seenConflictFiles)) {
            ASSERT (Utility.isConflictFile (path));
    
            auto bapath = path.toUtf8 ();
            if (!conflictRecordPaths.contains (bapath)) {
                ConflictRecord record;
                record.path = bapath;
                auto basePath = Utility.conflictFileBaseNameFromPattern (bapath);
                record.initialBasePath = basePath;
    
                // Determine fileid of target file
                SyncJournalFileRecord baseRecord;
                if (_journal.getFileRecord (basePath, &baseRecord) && baseRecord.isValid ()) {
                    record.baseFileId = baseRecord._fileId;
                }
    
                _journal.setConflictRecord (record);
            }
        }
    }
    
    void Occ.SyncEngine.slotItemDiscovered (Occ.SyncFileItemPtr &item) {
        if (Utility.isConflictFile (item._file))
            _seenConflictFiles.insert (item._file);
        if (item._instruction == CSYNC_INSTRUCTION_UPDATE_METADATA && !item.isDirectory ()) {
            // For directories, metadata-only updates will be done after all their files are propagated.
    
            // Update the database now already :  New remote fileid or Etag or RemotePerm
            // Or for files that were detected as "resolved conflict".
            // Or a local inode/mtime change
    
            // In case of "resolved conflict" : there should have been a conflict because they
            // both were new, or both had their local mtime or remote etag modified, but the
            // size and mtime is the same on the server.  This typically happens when the
            // database is removed. Nothing will be done for those files, but we still need
            // to update the database.
    
            // This metadata update *could* be a propagation job of its own, but since it's
            // quick to do and we don't want to create a potentially large number of
            // mini-jobs later on, we just update metadata right now.
    
            if (item._direction == SyncFileItem.Down) {
                string filePath = _localPath + item._file;
    
                // If the 'W' remote permission changed, update the local filesystem
                SyncJournalFileRecord prev;
                if (_journal.getFileRecord (item._file, &prev)
                    && prev.isValid ()
                    && prev._remotePerm.hasPermission (RemotePermissions.CanWrite) != item._remotePerm.hasPermission (RemotePermissions.CanWrite)) {
                    const bool isReadOnly = !item._remotePerm.isNull () && !item._remotePerm.hasPermission (RemotePermissions.CanWrite);
                    FileSystem.setFileReadOnlyWeak (filePath, isReadOnly);
                }
                auto rec = item.toSyncJournalFileRecordWithInode (filePath);
                if (rec._checksumHeader.isEmpty ())
                    rec._checksumHeader = prev._checksumHeader;
                rec._serverHasIgnoredFiles |= prev._serverHasIgnoredFiles;
    
                // Ensure it's a placeholder file on disk
                if (item._type == ItemTypeFile) {
                    const auto result = _syncOptions._vfs.convertToPlaceholder (filePath, *item);
                    if (!result) {
                        item._instruction = CSYNC_INSTRUCTION_ERROR;
                        item._errorString = tr ("Could not update file : %1").arg (result.error ());
                        return;
                    }
                }
    
                // Update on-disk virtual file metadata
                if (item._type == ItemTypeVirtualFile) {
                    auto r = _syncOptions._vfs.updateMetadata (filePath, item._modtime, item._size, item._fileId);
                    if (!r) {
                        item._instruction = CSYNC_INSTRUCTION_ERROR;
                        item._errorString = tr ("Could not update virtual file metadata : %1").arg (r.error ());
                        return;
                    }
                }
    
                // Updating the db happens on success
                _journal.setFileRecord (rec);
    
                // This might have changed the shared flag, so we must notify SyncFileStatusTracker for example
                emit itemCompleted (item);
            } else {
                // Update only outdated data from the disk.
                _journal.updateLocalMetadata (item._file, item._modtime, item._size, item._inode);
            }
            _hasNoneFiles = true;
            return;
        } else if (item._instruction == CSYNC_INSTRUCTION_NONE) {
            _hasNoneFiles = true;
            if (_account.capabilities ().uploadConflictFiles () && Utility.isConflictFile (item._file)) {
                // For uploaded conflict files, files with no action performed on them should
                // be displayed : but we mustn't overwrite the instruction if something happens
                // to the file!
                item._errorString = tr ("Unresolved conflict.");
                item._instruction = CSYNC_INSTRUCTION_IGNORE;
                item._status = SyncFileItem.Conflict;
            }
            return;
        } else if (item._instruction == CSYNC_INSTRUCTION_REMOVE && !item._isSelectiveSync) {
            _hasRemoveFile = true;
        } else if (item._instruction == CSYNC_INSTRUCTION_RENAME) {
            _hasNoneFiles = true; // If a file (or every file) has been renamed, it means not al files where deleted
        } else if (item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE
            || item._instruction == CSYNC_INSTRUCTION_SYNC) {
            if (item._direction == SyncFileItem.Up) {
                // An upload of an existing file means that the file was left unchanged on the server
                // This counts as a NONE for detecting if all the files on the server were changed
                _hasNoneFiles = true;
            }
        }
    
        // check for blacklisting of this item.
        // if the item is on blacklist, the instruction was set to ERROR
        checkErrorBlacklisting (*item);
        _needsUpdate = true;
    
        // Insert sorted
        auto it = std.lower_bound ( _syncItems.begin (), _syncItems.end (), item ); // the _syncItems is sorted
        _syncItems.insert ( it, item );
    
        slotNewItem (item);
    
        if (item.isDirectory ()) {
            slotFolderDiscovered (item._etag.isEmpty (), item._file);
        }
    }
    
    void SyncEngine.startSync () {
        if (_journal.exists ()) {
            QVector<SyncJournalDb.PollInfo> pollInfos = _journal.getPollInfos ();
            if (!pollInfos.isEmpty ()) {
                qCInfo (lcEngine) << "Finish Poll jobs before starting a sync";
                auto *job = new CleanupPollsJob (pollInfos, _account,
                    _journal, _localPath, _syncOptions._vfs, this);
                connect (job, &CleanupPollsJob.finished, this, &SyncEngine.startSync);
                connect (job, &CleanupPollsJob.aborted, this, &SyncEngine.slotCleanPollsJobAborted);
                job.start ();
                return;
            }
        }
    
        if (s_anySyncRunning || _syncRunning) {
            ASSERT (false)
            return;
        }
    
        s_anySyncRunning = true;
        _syncRunning = true;
        _anotherSyncNeeded = NoFollowUpSync;
        _clearTouchedFilesTimer.stop ();
    
        _hasNoneFiles = false;
        _hasRemoveFile = false;
        _seenConflictFiles.clear ();
    
        _progressInfo.reset ();
    
        if (!QDir (_localPath).exists ()) {
            _anotherSyncNeeded = DelayedFollowUp;
            // No _tr, it should only occur in non-mirall
            Q_EMIT syncError (QStringLiteral ("Unable to find local sync folder."));
            finalize (false);
            return;
        }
    
        // Check free size on disk first.
        const int64 minFree = criticalFreeSpaceLimit ();
        const int64 freeBytes = Utility.freeDiskSpace (_localPath);
        if (freeBytes >= 0) {
            if (freeBytes < minFree) {
                qCWarning (lcEngine ()) << "Too little space available at" << _localPath << ". Have"
                                      << freeBytes << "bytes and require at least" << minFree << "bytes";
                _anotherSyncNeeded = DelayedFollowUp;
                Q_EMIT syncError (tr ("Only %1 are available, need at least %2 to start",
                    "Placeholders are postfixed with file sizes using Utility.octetsToString ()")
                                     .arg (
                                         Utility.octetsToString (freeBytes),
                                         Utility.octetsToString (minFree)));
                finalize (false);
                return;
            } else {
                qCInfo (lcEngine) << "There are" << freeBytes << "bytes available at" << _localPath;
            }
        } else {
            qCWarning (lcEngine) << "Could not determine free space available at" << _localPath;
        }
    
        _syncItems.clear ();
        _needsUpdate = false;
    
        if (!_journal.exists ()) {
            qCInfo (lcEngine) << "New sync (no sync journal exists)";
        } else {
            qCInfo (lcEngine) << "Sync with existing sync journal";
        }
    
        string verStr ("Using Qt ");
        verStr.append (qVersion ());
    
        verStr.append (" SSL library ").append (QSslSocket.sslLibraryVersionString ().toUtf8 ().data ());
        verStr.append (" on ").append (Utility.platformName ());
        qCInfo (lcEngine) << verStr;
    
        // This creates the DB if it does not exist yet.
        if (!_journal.open ()) {
            qCWarning (lcEngine) << "No way to create a sync journal!";
            Q_EMIT syncError (tr ("Unable to open or create the local sync database. Make sure you have write access in the sync folder."));
            finalize (false);
            return;
            // database creation error!
        }
    
        // Functionality like selective sync might have set up etag storage
        // filtering via schedulePathForRemoteDiscovery (). This *is* the next sync, so
        // undo the filter to allow this sync to retrieve and store the correct etags.
        _journal.clearEtagStorageFilter ();
    
        _excludedFiles.setExcludeConflictFiles (!_account.capabilities ().uploadConflictFiles ());
    
        _lastLocalDiscoveryStyle = _localDiscoveryStyle;
    
        if (_syncOptions._vfs.mode () == Vfs.WithSuffix && _syncOptions._vfs.fileSuffix ().isEmpty ()) {
            Q_EMIT syncError (tr ("Using virtual files with suffix, but suffix is not set"));
            finalize (false);
            return;
        }
    
        bool ok = false;
        auto selectiveSyncBlackList = _journal.getSelectiveSyncList (SyncJournalDb.SelectiveSyncBlackList, &ok);
        if (ok) {
            bool usingSelectiveSync = (!selectiveSyncBlackList.isEmpty ());
            qCInfo (lcEngine) << (usingSelectiveSync ? "Using Selective Sync" : "NOT Using Selective Sync");
        } else {
            qCWarning (lcEngine) << "Could not retrieve selective sync list from DB";
            Q_EMIT syncError (tr ("Unable to read the blacklist from the local database"));
            finalize (false);
            return;
        }
    
        _stopWatch.start ();
        _progressInfo._status = ProgressInfo.Starting;
        emit transmissionProgress (*_progressInfo);
    
        qCInfo (lcEngine) << "#### Discovery start ####################################################";
        qCInfo (lcEngine) << "Server" << account ().serverVersion ()
                         << (account ().isHttp2Supported () ? "Using HTTP/2" : "");
        _progressInfo._status = ProgressInfo.Discovery;
        emit transmissionProgress (*_progressInfo);
    
        _discoveryPhase.reset (new DiscoveryPhase);
        _discoveryPhase._account = _account;
        _discoveryPhase._excludes = _excludedFiles.data ();
        const string excludeFilePath = _localPath + QStringLiteral (".sync-exclude.lst");
        if (QFile.exists (excludeFilePath)) {
            _discoveryPhase._excludes.addExcludeFilePath (excludeFilePath);
            _discoveryPhase._excludes.reloadExcludeFiles ();
        }
        _discoveryPhase._statedb = _journal;
        _discoveryPhase._localDir = _localPath;
        if (!_discoveryPhase._localDir.endsWith ('/'))
            _discoveryPhase._localDir+='/';
        _discoveryPhase._remoteFolder = _remotePath;
        if (!_discoveryPhase._remoteFolder.endsWith ('/'))
            _discoveryPhase._remoteFolder+='/';
        _discoveryPhase._syncOptions = _syncOptions;
        _discoveryPhase._shouldDiscoverLocaly = [this] (string &s) { return shouldDiscoverLocally (s); };
        _discoveryPhase.setSelectiveSyncBlackList (selectiveSyncBlackList);
        _discoveryPhase.setSelectiveSyncWhiteList (_journal.getSelectiveSyncList (SyncJournalDb.SelectiveSyncWhiteList, &ok));
        if (!ok) {
            qCWarning (lcEngine) << "Unable to read selective sync list, aborting.";
            Q_EMIT syncError (tr ("Unable to read from the sync journal."));
            finalize (false);
            return;
        }
    
        // Check for invalid character in old server version
        string invalidFilenamePattern = _account.capabilities ().invalidFilenameRegex ();
        if (invalidFilenamePattern.isNull ()
            && _account.serverVersionInt () < Account.makeServerVersion (8, 1, 0)) {
            // Server versions older than 8.1 don't support some characters in filenames.
            // If the capability is not set, default to a pattern that avoids uploading
            // files with names that contain these.
            // It's important to respect the capability also for older servers -- the
            // version check doesn't make sense for custom servers.
            invalidFilenamePattern = R" ([\\:?*"<>|])";
        }
        if (!invalidFilenamePattern.isEmpty ())
            _discoveryPhase._invalidFilenameRx = QRegularExpression (invalidFilenamePattern);
        _discoveryPhase._serverBlacklistedFiles = _account.capabilities ().blacklistedFiles ();
        _discoveryPhase._ignoreHiddenFiles = ignoreHiddenFiles ();
    
        connect (_discoveryPhase.data (), &DiscoveryPhase.itemDiscovered, this, &SyncEngine.slotItemDiscovered);
        connect (_discoveryPhase.data (), &DiscoveryPhase.newBigFolder, this, &SyncEngine.newBigFolder);
        connect (_discoveryPhase.data (), &DiscoveryPhase.fatalError, this, [this] (string &errorString) {
            Q_EMIT syncError (errorString);
            finalize (false);
        });
        connect (_discoveryPhase.data (), &DiscoveryPhase.finished, this, &SyncEngine.slotDiscoveryFinished);
        connect (_discoveryPhase.data (), &DiscoveryPhase.silentlyExcluded,
            _syncFileStatusTracker.data (), &SyncFileStatusTracker.slotAddSilentlyExcluded);
    
        auto discoveryJob = new ProcessDirectoryJob (
            _discoveryPhase.data (), PinState.AlwaysLocal, _journal.keyValueStoreGetInt ("last_sync", 0), _discoveryPhase.data ());
        _discoveryPhase.startJob (discoveryJob);
        connect (discoveryJob, &ProcessDirectoryJob.etag, this, &SyncEngine.slotRootEtagReceived);
        connect (_discoveryPhase.data (), &DiscoveryPhase.addErrorToGui, this, &SyncEngine.addErrorToGui);
    }
    
    void SyncEngine.slotFolderDiscovered (bool local, string &folder) {
        // Don't wanna overload the UI
        if (!_lastUpdateProgressCallbackCall.isValid () || _lastUpdateProgressCallbackCall.elapsed () >= 200) {
            _lastUpdateProgressCallbackCall.start (); // first call or enough elapsed time
        } else {
            return;
        }
    
        if (local) {
            _progressInfo._currentDiscoveredLocalFolder = folder;
            _progressInfo._currentDiscoveredRemoteFolder.clear ();
        } else {
            _progressInfo._currentDiscoveredRemoteFolder = folder;
            _progressInfo._currentDiscoveredLocalFolder.clear ();
        }
        emit transmissionProgress (*_progressInfo);
    }
    
    void SyncEngine.slotRootEtagReceived (QByteArray &e, QDateTime &time) {
        if (_remoteRootEtag.isEmpty ()) {
            qCDebug (lcEngine) << "Root etag:" << e;
            _remoteRootEtag = e;
            emit rootEtag (_remoteRootEtag, time);
        }
    }
    
    void SyncEngine.slotNewItem (SyncFileItemPtr &item) {
        _progressInfo.adjustTotalsForFile (*item);
    }
    
    void SyncEngine.slotDiscoveryFinished () {
        if (!_discoveryPhase) {
            // There was an error that was already taken care of
            return;
        }
    
        qCInfo (lcEngine) << "#### Discovery end #################################################### " << _stopWatch.addLapTime (QLatin1String ("Discovery Finished")) << "ms";
    
        // Sanity check
        if (!_journal.open ()) {
            qCWarning (lcEngine) << "Bailing out, DB failure";
            Q_EMIT syncError (tr ("Cannot open the sync journal"));
            finalize (false);
            return;
        } else {
            // Commits a possibly existing (should not though) transaction and starts a new one for the propagate phase
            _journal.commitIfNeededAndStartNewTransaction ("Post discovery");
        }
    
        _progressInfo._currentDiscoveredRemoteFolder.clear ();
        _progressInfo._currentDiscoveredLocalFolder.clear ();
        _progressInfo._status = ProgressInfo.Reconcile;
        emit transmissionProgress (*_progressInfo);
    
        //    qCInfo (lcEngine) << "Permissions of the root folder : " << _csync_ctx.remote.root_perms.toString ();
        auto finish = [this]{
            auto databaseFingerprint = _journal.dataFingerprint ();
            // If databaseFingerprint is empty, this means that there was no information in the database
            // (for example, upgrading from a previous version, or first sync, or server not supporting fingerprint)
            if (!databaseFingerprint.isEmpty () && _discoveryPhase
                && _discoveryPhase._dataFingerprint != databaseFingerprint) {
                qCInfo (lcEngine) << "data fingerprint changed, assume restore from backup" << databaseFingerprint << _discoveryPhase._dataFingerprint;
                restoreOldFiles (_syncItems);
            }
    
            if (_discoveryPhase._anotherSyncNeeded && _anotherSyncNeeded == NoFollowUpSync) {
                _anotherSyncNeeded = ImmediateFollowUp;
            }
    
            Q_ASSERT (std.is_sorted (_syncItems.begin (), _syncItems.end ()));
    
            qCInfo (lcEngine) << "#### Reconcile (aboutToPropagate) #################################################### " << _stopWatch.addLapTime (QStringLiteral ("Reconcile (aboutToPropagate)")) << "ms";
    
            _localDiscoveryPaths.clear ();
    
            // To announce the beginning of the sync
            emit aboutToPropagate (_syncItems);
    
            qCInfo (lcEngine) << "#### Reconcile (aboutToPropagate OK) #################################################### "<< _stopWatch.addLapTime (QStringLiteral ("Reconcile (aboutToPropagate OK)")) << "ms";
    
            // it's important to do this before ProgressInfo.start (), to announce start of new sync
            _progressInfo._status = ProgressInfo.Propagation;
            emit transmissionProgress (*_progressInfo);
            _progressInfo.startEstimateUpdates ();
    
            // post update phase script : allow to tweak stuff by a custom script in debug mode.
            if (!qEnvironmentVariableIsEmpty ("OWNCLOUD_POST_UPDATE_SCRIPT")) {
        #ifndef NDEBUG
                const string script = qEnvironmentVariable ("OWNCLOUD_POST_UPDATE_SCRIPT");
    
                qCDebug (lcEngine) << "Post Update Script : " << script;
                auto scriptArgs = script.split (QRegularExpression ("\\s+"), Qt.SkipEmptyParts);
                if (scriptArgs.size () > 0) {
                    const auto scriptExecutable = scriptArgs.takeFirst ();
                    QProcess.execute (scriptExecutable, scriptArgs);
                }
    #else
                qCWarning (lcEngine) << "**** Attention : POST_UPDATE_SCRIPT installed, but not executed because compiled with NDEBUG";
        #endif
            }
    
            // do a database commit
            _journal.commit (QStringLiteral ("post treewalk"));
    
            _propagator = QSharedPointer<OwncloudPropagator> (
                new OwncloudPropagator (_account, _localPath, _remotePath, _journal, _bulkUploadBlackList));
            _propagator.setSyncOptions (_syncOptions);
            connect (_propagator.data (), &OwncloudPropagator.itemCompleted,
                this, &SyncEngine.slotItemCompleted);
            connect (_propagator.data (), &OwncloudPropagator.progress,
                this, &SyncEngine.slotProgress);
            connect (_propagator.data (), &OwncloudPropagator.finished, this, &SyncEngine.slotPropagationFinished, Qt.QueuedConnection);
            connect (_propagator.data (), &OwncloudPropagator.seenLockedFile, this, &SyncEngine.seenLockedFile);
            connect (_propagator.data (), &OwncloudPropagator.touchedFile, this, &SyncEngine.slotAddTouchedFile);
            connect (_propagator.data (), &OwncloudPropagator.insufficientLocalStorage, this, &SyncEngine.slotInsufficientLocalStorage);
            connect (_propagator.data (), &OwncloudPropagator.insufficientRemoteStorage, this, &SyncEngine.slotInsufficientRemoteStorage);
            connect (_propagator.data (), &OwncloudPropagator.newItem, this, &SyncEngine.slotNewItem);
    
            // apply the network limits to the propagator
            setNetworkLimits (_uploadLimit, _downloadLimit);
    
            deleteStaleDownloadInfos (_syncItems);
            deleteStaleUploadInfos (_syncItems);
            deleteStaleErrorBlacklistEntries (_syncItems);
            _journal.commit (QStringLiteral ("post stale entry removal"));
    
            // Emit the started signal only after the propagator has been set up.
            if (_needsUpdate)
                Q_EMIT started ();
    
            _propagator.start (std.move (_syncItems));
    
            qCInfo (lcEngine) << "#### Post-Reconcile end #################################################### " << _stopWatch.addLapTime (QStringLiteral ("Post-Reconcile Finished")) << "ms";
        };
    
        if (!_hasNoneFiles && _hasRemoveFile) {
            qCInfo (lcEngine) << "All the files are going to be changed, asking the user";
            int side = 0; // > 0 means more deleted on the server.  < 0 means more deleted on the client
            foreach (auto &it, _syncItems) {
                if (it._instruction == CSYNC_INSTRUCTION_REMOVE) {
                    side += it._direction == SyncFileItem.Down ? 1 : -1;
                }
            }
    
            QPointer<GLib.Object> guard = new GLib.Object ();
            QPointer<GLib.Object> self = this;
            auto callback = [this, self, finish, guard] (bool cancel) . void {
                // use a guard to ensure its only called once...
                // qpointer to self to ensure we still exist
                if (!guard || !self) {
                    return;
                }
                guard.deleteLater ();
                if (cancel) {
                    qCInfo (lcEngine) << "User aborted sync";
                    finalize (false);
                    return;
                } else {
                    finish ();
                }
            };
            emit aboutToRemoveAllFiles (side >= 0 ? SyncFileItem.Down : SyncFileItem.Up, callback);
            return;
        }
        finish ();
    }
    
    void SyncEngine.slotCleanPollsJobAborted (string &error) {
        syncError (error);
        finalize (false);
    }
    
    void SyncEngine.setNetworkLimits (int upload, int download) {
        _uploadLimit = upload;
        _downloadLimit = download;
    
        if (!_propagator)
            return;
    
        _propagator._uploadLimit = upload;
        _propagator._downloadLimit = download;
    
        if (upload != 0 || download != 0) {
            qCInfo (lcEngine) << "Network Limits (down/up) " << upload << download;
        }
    }
    
    void SyncEngine.slotItemCompleted (SyncFileItemPtr &item) {
        _progressInfo.setProgressComplete (*item);
    
        emit transmissionProgress (*_progressInfo);
        emit itemCompleted (item);
    }
    
    void SyncEngine.slotPropagationFinished (bool success) {
        if (_propagator._anotherSyncNeeded && _anotherSyncNeeded == NoFollowUpSync) {
            _anotherSyncNeeded = ImmediateFollowUp;
        }
    
        if (success && _discoveryPhase) {
            _journal.setDataFingerprint (_discoveryPhase._dataFingerprint);
        }
    
        conflictRecordMaintenance ();
    
        _journal.deleteStaleFlagsEntries ();
        _journal.commit ("All Finished.", false);
    
        // Send final progress information even if no
        // files needed propagation, but clear the lastCompletedItem
        // so we don't count this twice (like Recent Files)
        _progressInfo._lastCompletedItem = SyncFileItem ();
        _progressInfo._status = ProgressInfo.Done;
        emit transmissionProgress (*_progressInfo);
    
        finalize (success);
    }
    
    void SyncEngine.finalize (bool success) {
        qCInfo (lcEngine) << "Sync run took " << _stopWatch.addLapTime (QLatin1String ("Sync Finished")) << "ms";
        _stopWatch.stop ();
    
        if (_discoveryPhase) {
            _discoveryPhase.take ().deleteLater ();
        }
        s_anySyncRunning = false;
        _syncRunning = false;
        emit finished (success);
    
        // Delete the propagator only after emitting the signal.
        _propagator.clear ();
        _seenConflictFiles.clear ();
        _uniqueErrors.clear ();
        _localDiscoveryPaths.clear ();
        _localDiscoveryStyle = LocalDiscoveryStyle.FilesystemOnly;
    
        _clearTouchedFilesTimer.start ();
    }
    
    void SyncEngine.slotProgress (SyncFileItem &item, int64 current) {
        _progressInfo.setProgressItem (item, current);
        emit transmissionProgress (*_progressInfo);
    }
    
    void SyncEngine.restoreOldFiles (SyncFileItemVector &syncItems) {
        /* When the server is trying to send us lots of file in the past, this means that a backup
           was restored in the server.  In that case, we should not simply overwrite the newer file
           on the file system with the older file from the backup on the server. Instead, we will
           upload the client file. But we still downloaded the old file in a conflict file just in case
        */
    
        for (auto &syncItem : qAsConst (syncItems)) {
            if (syncItem._direction != SyncFileItem.Down)
                continue;
    
            switch (syncItem._instruction) {
            case CSYNC_INSTRUCTION_SYNC:
                qCWarning (lcEngine) << "restoreOldFiles : RESTORING" << syncItem._file;
                syncItem._instruction = CSYNC_INSTRUCTION_CONFLICT;
                break;
            case CSYNC_INSTRUCTION_REMOVE:
                qCWarning (lcEngine) << "restoreOldFiles : RESTORING" << syncItem._file;
                syncItem._instruction = CSYNC_INSTRUCTION_NEW;
                syncItem._direction = SyncFileItem.Up;
                break;
            case CSYNC_INSTRUCTION_RENAME:
            case CSYNC_INSTRUCTION_NEW:
                // Ideally we should try to revert the rename or remove, but this would be dangerous
                // without re-doing the reconcile phase.  So just let it happen.
            default:
                break;
            }
        }
    }
    
    void SyncEngine.slotAddTouchedFile (string &fn) {
        QElapsedTimer now;
        now.start ();
        string file = QDir.cleanPath (fn);
    
        // Iterate from the oldest and remove anything older than 15 seconds.
        while (true) {
            auto first = _touchedFiles.begin ();
            if (first == _touchedFiles.end ())
                break;
            // Compare to our new QElapsedTimer instead of using elapsed ().
            // This avoids querying the current time from the OS for every loop.
            auto elapsed = std.chrono.milliseconds (now.msecsSinceReference () - first.key ().msecsSinceReference ());
            if (elapsed <= s_touchedFilesMaxAgeMs) {
                // We found the first path younger than the maximum age, keep the rest.
                break;
            }
    
            _touchedFiles.erase (first);
        }
    
        // This should be the largest QElapsedTimer yet, use constEnd () as hint.
        _touchedFiles.insert (_touchedFiles.constEnd (), now, file);
    }
    
    void SyncEngine.slotClearTouchedFiles () {
        _touchedFiles.clear ();
    }
    
    bool SyncEngine.wasFileTouched (string &fn) {
        // Start from the end (most recent) and look for our path. Check the time just in case.
        auto begin = _touchedFiles.constBegin ();
        for (auto it = _touchedFiles.constEnd (); it != begin; --it) {
            if ( (it-1).value () == fn)
                return std.chrono.milliseconds ( (it-1).key ().elapsed ()) <= s_touchedFilesMaxAgeMs;
        }
        return false;
    }
    
    AccountPtr SyncEngine.account () {
        return _account;
    }
    
    void SyncEngine.setLocalDiscoveryOptions (LocalDiscoveryStyle style, std.set<string> paths) {
        _localDiscoveryStyle = style;
        _localDiscoveryPaths = std.move (paths);
    
        // Normalize to make sure that no path is a contained in another.
        // Note : for simplicity, this code consider anything less than '/' as a path separator, so for
        // example, this will remove "foo.bar" if "foo" is in the list. This will mean we might have
        // some false positive, but that's Ok.
        // This invariant is used in SyncEngine.shouldDiscoverLocally
        string prev;
        auto it = _localDiscoveryPaths.begin ();
        while (it != _localDiscoveryPaths.end ()) {
            if (!prev.isNull () && it.startsWith (prev) && (prev.endsWith ('/') || *it == prev || it.at (prev.size ()) <= '/')) {
                it = _localDiscoveryPaths.erase (it);
            } else {
                prev = *it;
                ++it;
            }
        }
    }
    
    bool SyncEngine.shouldDiscoverLocally (string &path) {
        if (_localDiscoveryStyle == LocalDiscoveryStyle.FilesystemOnly)
            return true;
    
        // The intention is that if "A/X" is in _localDiscoveryPaths:
        // - parent folders like "/", "A" will be discovered (to make sure the discovery reaches the
        //   point where something new happened)
        // - the folder itself "A/X" will be discovered
        // - subfolders like "A/X/Y" will be discovered (so data inside a new or renamed folder will be
        //   discovered in full)
        // Check out TestLocalDiscovery.testLocalDiscoveryDecision ()
    
        auto it = _localDiscoveryPaths.lower_bound (path);
        if (it == _localDiscoveryPaths.end () || !it.startsWith (path)) {
            // Maybe a subfolder of something in the list?
            if (it != _localDiscoveryPaths.begin () && path.startsWith (* (--it))) {
                return it.endsWith ('/') || (path.size () > it.size () && path.at (it.size ()) <= '/');
            }
            return false;
        }
    
        // maybe an exact match or an empty path?
        if (it.size () == path.size () || path.isEmpty ())
            return true;
    
        // Maybe a parent folder of something in the list?
        // check for a prefix + / match
        forever {
            if (it.size () > path.size () && it.at (path.size ()) == '/')
                return true;
            ++it;
            if (it == _localDiscoveryPaths.end () || !it.startsWith (path))
                return false;
        }
        return false;
    }
    
    void SyncEngine.wipeVirtualFiles (string &localPath, SyncJournalDb &journal, Vfs &vfs) {
        qCInfo (lcEngine) << "Wiping virtual files inside" << localPath;
        journal.getFilesBelowPath (QByteArray (), [&] (SyncJournalFileRecord &rec) {
            if (rec._type != ItemTypeVirtualFile && rec._type != ItemTypeVirtualFileDownload)
                return;
    
            qCDebug (lcEngine) << "Removing db record for" << rec.path ();
            journal.deleteFileRecord (rec._path);
    
            // If the local file is a dehydrated placeholder, wipe it too.
            // Otherwise leave it to allow the next sync to have a new-new conflict.
            string localFile = localPath + rec._path;
            if (QFile.exists (localFile) && vfs.isDehydratedPlaceholder (localFile)) {
                qCDebug (lcEngine) << "Removing local dehydrated placeholder" << rec.path ();
                QFile.remove (localFile);
            }
        });
    
        journal.forceRemoteDiscoveryNextSync ();
    
        // Postcondition : No ItemTypeVirtualFile / ItemTypeVirtualFileDownload left in the db.
        // But hydrated placeholders may still be around.
    }
    
    void SyncEngine.switchToVirtualFiles (string &localPath, SyncJournalDb &journal, Vfs &vfs) {
        qCInfo (lcEngine) << "Convert to virtual files inside" << localPath;
        journal.getFilesBelowPath ({}, [&] (SyncJournalFileRecord &rec) {
            const auto path = rec.path ();
            const auto fileName = QFileInfo (path).fileName ();
            if (FileSystem.isExcludeFile (fileName)) {
                return;
            }
            SyncFileItem item;
            string localFile = localPath + path;
            const auto result = vfs.convertToPlaceholder (localFile, item, localFile);
            if (!result.isValid ()) {
                qCWarning (lcEngine) << "Could not convert file to placeholder" << result.error ();
            }
        });
    }
    
    void SyncEngine.abort () {
        if (_propagator)
            qCInfo (lcEngine) << "Aborting sync";
    
        if (_propagator) {
            // If we're already in the propagation phase, aborting that is sufficient
            _propagator.abort ();
        } else if (_discoveryPhase) {
            // Delete the discovery and all child jobs after ensuring
            // it can't finish and start the propagator
            disconnect (_discoveryPhase.data (), nullptr, this, nullptr);
            _discoveryPhase.take ().deleteLater ();
    
            Q_EMIT syncError (tr ("Synchronization will resume shortly."));
            finalize (false);
        }
    }
    
    void SyncEngine.slotSummaryError (string &message) {
        if (_uniqueErrors.contains (message))
            return;
    
        _uniqueErrors.insert (message);
        emit syncError (message, ErrorCategory.Normal);
    }
    
    void SyncEngine.slotInsufficientLocalStorage () {
        slotSummaryError (
            tr ("Disk space is low : Downloads that would reduce free space "
               "below %1 were skipped.")
                .arg (Utility.octetsToString (freeSpaceLimit ())));
    }
    
    void SyncEngine.slotInsufficientRemoteStorage () {
        auto msg = tr ("There is insufficient space available on the server for some uploads.");
        if (_uniqueErrors.contains (msg))
            return;
    
        _uniqueErrors.insert (msg);
        emit syncError (msg, ErrorCategory.InsufficientRemoteStorage);
    }
    
    } // namespace Occ
    