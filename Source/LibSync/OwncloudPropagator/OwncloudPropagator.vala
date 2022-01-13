/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QLoggingCategory>
// #include <QNetworkReply>

// #include <QStack>
// #include <QFileInfo>
// #include <QDir>
// #include <QLoggingCategory>
// #include <QTimer>
// #include <GLib.Object>
// #include <QTimerEvent>
// #include <QRegularExpression>
// #include <qmath.h>

// #include <QHash>
// #include <GLib.Object>
// #include <QMap>
// #include <QElapsedTimer>
// #include <QTimer>
// #include <QPointer>
// #include <QIODevice>
// #include <QMutex>

// #include <deque>

namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lcPropagator)

/***********************************************************
Free disk space threshold below which syncs will abort and not even start.
***********************************************************/
int64 criticalFreeSpaceLimit ();

/***********************************************************
The client will not intentionally reduce the available free disk space below
 this limit.

Uploads will still run and downloads that are small enough will continue too.
***********************************************************/
int64 freeSpaceLimit ();

void blacklistUpdate (SyncJournalDb *journal, SyncFileItem &item);


/***********************************************************
@brief the base class of propagator jobs

This can either be a job, or a container for jobs.
If it is a composite job, it then inherits from PropagateDirectory

@ingroup libsync
***********************************************************/
class PropagatorJob : GLib.Object {

public:
    PropagatorJob (OwncloudPropagator *propagator);

    enum AbortType {
        Synchronous,
        Asynchronous
    };

    Q_ENUM (AbortType)

    enum JobState {
        NotYetStarted,
        Running,
        Finished
    };
    JobState _state;

    Q_ENUM (JobState)

    enum JobParallelism {

        /** Jobs can be run in parallel to this job */
        FullParallelism,

        /** No other job shall be started until this one has finished.
            So this job is guaranteed to finish before any jobs below it
            are executed. */
        WaitForFinished,
    };

    Q_ENUM (JobParallelism)

    virtual JobParallelism parallelism () { return FullParallelism; }

    /***********************************************************
    For "small" jobs
    ***********************************************************/
    virtual bool isLikelyFinishedQuickly () { return false; }

    /***********************************************************
    The space that the running jobs need to complete but don't actually use yet.

    Note that this does *not* include the disk space that's already
    in use by running jobs for things like a download-in-progress.
    ***********************************************************/
    virtual int64 committedDiskSpace () { return 0; }

    /***********************************************************
    Set the associated composite job

    Used only from PropagatorCompositeJob itself, when a job is added
    and from PropagateDirectory to associate the subJobs with the first
    job.
    ***********************************************************/
    void setAssociatedComposite (PropagatorCompositeJob *job) { _associatedComposite = job; }

public slots:
    /***********************************************************
    Asynchronous abort requires emit of abortFinished () signal,
    while synchronous is expected to abort immedietaly.
    */
    virtual void abort (PropagatorJob.AbortType abortType) {
        if (abortType == AbortType.Asynchronous)
            emit abortFinished ();
    }

    /***********************************************************
    Starts this job, or a new subjob
    returns true if a job was started.
    ***********************************************************/
    virtual bool scheduleSelfOrChild () = 0;
signals:
    /***********************************************************
    Emitted when the job is fully finished
    ***********************************************************/
    void finished (SyncFileItem.Status);

    /***********************************************************
    Emitted when the abort is fully finished
    ***********************************************************/
    void abortFinished (SyncFileItem.Status status = SyncFileItem.NormalError);
protected:
    OwncloudPropagator *propagator ();

    /***********************************************************
    If this job gets added to a composite job, this will point to the parent.

    For the PropagateDirectory._firstJob it will point to
    PropagateDirectory._subJobs.
    
    That can be useful for jobs that want to spawn follow-up jobs without
     * becoming composite jobs themselves.
    ***********************************************************/
    PropagatorCompositeJob *_associatedComposite = nullptr;
};

/***********************************************************
Abstract class to propagate a single item
***********************************************************/
class PropagateItemJob : PropagatorJob {
protected:
    virtual void done (SyncFileItem.Status status, string &errorString = string ());

    /***********************************************************
    set a custom restore job message that is used if the restore job succeeded.
    It is displayed in the activity view.
    ***********************************************************/
    string restoreJobMsg () {
        return _item._isRestoration ? _item._errorString : string ();
    }
    void setRestoreJobMsg (string &msg = string ()) {
        _item._isRestoration = true;
        _item._errorString = msg;
    }

    bool hasEncryptedAncestor ();

protected slots:
    void slotRestoreJobFinished (SyncFileItem.Status status);

private:
    QScopedPointer<PropagateItemJob> _restoreJob;
    JobParallelism _parallelism;

public:
    PropagateItemJob (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagatorJob (propagator)
        , _parallelism (FullParallelism)
        , _item (item) {
        // we should always execute jobs that process the E2EE API calls as sequential jobs
        // TODO : In fact, we must make sure Lock/Unlock are not colliding and always wait for each other to complete. So, we could refactor this "_parallelism" later
        // so every "PropagateItemJob" that will potentially execute Lock job on E2EE folder will get executed sequentially.
        // As an alternative, we could optimize Lock/Unlock calls, so we do a batch-write on one folder and only lock and unlock a folder once per batch.
        _parallelism = (_item._isEncrypted || hasEncryptedAncestor ()) ? WaitForFinished : FullParallelism;
    }
    ~PropagateItemJob () override;

    bool scheduleSelfOrChild () override {
        if (_state != NotYetStarted) {
            return false;
        }
        qCInfo (lcPropagator) << "Starting" << _item._instruction << "propagation of" << _item.destination () << "by" << this;

        _state = Running;
        QMetaObject.invokeMethod (this, "start"); // We could be in a different thread (neon jobs)
        return true;
    }

    JobParallelism parallelism () override { return _parallelism; }

    SyncFileItemPtr _item;

public slots:
    virtual void start () = 0;
};

/***********************************************************
@brief Job that runs subjobs. It becomes finished only when all subjobs are finished.
@ingroup libsync
***********************************************************/
class PropagatorCompositeJob : PropagatorJob {
public:
    QVector<PropagatorJob> _jobsToDo;
    SyncFileItemVector _tasksToDo;
    QVector<PropagatorJob> _runningJobs;
    SyncFileItem.Status _hasError; // NoStatus,  or NormalError / SoftError if there was an error
    uint64 _abortsCount;

    PropagatorCompositeJob (OwncloudPropagator *propagator)
        : PropagatorJob (propagator)
        , _hasError (SyncFileItem.NoStatus), _abortsCount (0) {
    }

    // Don't delete jobs in _jobsToDo and _runningJobs : they have parents
    // that will be responsible for cleanup. Deleting them here would risk
    // deleting something that has already been deleted by a shared parent.
    ~PropagatorCompositeJob () override = default;

    void appendJob (PropagatorJob *job);
    void appendTask (SyncFileItemPtr &item) {
        _tasksToDo.append (item);
    }

    bool scheduleSelfOrChild () override;
    JobParallelism parallelism () override;

    /***********************************************************
    Abort synchronously or asynchronously - some jobs
    require to be finished without immediete abort (abort on job might
    cause conflicts/duplicated files - owncloud/client/issues/5949)
    ***********************************************************/
    void abort (PropagatorJob.AbortType abortType) override {
        if (!_runningJobs.empty ()) {
            _abortsCount = _runningJobs.size ();
            foreach (PropagatorJob *j, _runningJobs) {
                if (abortType == AbortType.Asynchronous) {
                    connect (j, &PropagatorJob.abortFinished,
                            this, &PropagatorCompositeJob.slotSubJobAbortFinished);
                }
                j.abort (abortType);
            }
        } else if (abortType == AbortType.Asynchronous){
            emit abortFinished ();
        }
    }

    int64 committedDiskSpace () const override;

private slots:
    void slotSubJobAbortFinished ();
    bool possiblyRunNextJob (PropagatorJob *next) {
        if (next._state == NotYetStarted) {
            connect (next, &PropagatorJob.finished, this, &PropagatorCompositeJob.slotSubJobFinished);
        }
        return next.scheduleSelfOrChild ();
    }

    void slotSubJobFinished (SyncFileItem.Status status);
    void finalize ();
};

/***********************************************************
@brief Propagate a directory, and all its sub entries.
@ingroup libsync
***********************************************************/
class PropagateDirectory : PropagatorJob {
public:
    SyncFileItemPtr _item;
    // e.g : create the directory
    QScopedPointer<PropagateItemJob> _firstJob;

    PropagatorCompositeJob _subJobs;

    PropagateDirectory (OwncloudPropagator *propagator, SyncFileItemPtr &item);

    void appendJob (PropagatorJob *job) {
        _subJobs.appendJob (job);
    }

    void appendTask (SyncFileItemPtr &item) {
        _subJobs.appendTask (item);
    }

    bool scheduleSelfOrChild () override;
    JobParallelism parallelism () override;
    void abort (PropagatorJob.AbortType abortType) override {
        if (_firstJob)
            // Force first job to abort synchronously
            // even if caller allows async abort (asyncAbort)
            _firstJob.abort (AbortType.Synchronous);

        if (abortType == AbortType.Asynchronous){
            connect (&_subJobs, &PropagatorCompositeJob.abortFinished, this, &PropagateDirectory.abortFinished);
        }
        _subJobs.abort (abortType);
    }

    void increaseAffectedCount () {
        _firstJob._item._affectedItems++;
    }

    int64 committedDiskSpace () const override {
        return _subJobs.committedDiskSpace ();
    }

private slots:

    void slotFirstJobFinished (SyncFileItem.Status status);
    virtual void slotSubJobsFinished (SyncFileItem.Status status);

};

/***********************************************************
@brief Propagate the root directory, and all its sub entries.
@ingroup libsync

Primary difference to PropagateDirectory is that it keeps track of directory
deletions that must happen at the very end.
***********************************************************/
class PropagateRootDirectory : PropagateDirectory {
public:
    PropagatorCompositeJob _dirDeletionJobs;

    PropagateRootDirectory (OwncloudPropagator *propagator);

    bool scheduleSelfOrChild () override;
    JobParallelism parallelism () override;
    void abort (PropagatorJob.AbortType abortType) override;

    int64 committedDiskSpace () const override;

private slots:
    void slotSubJobsFinished (SyncFileItem.Status status) override;
    void slotDirDeletionJobsFinished (SyncFileItem.Status status);

private:

    bool scheduleDelayedJobs ();
};

/***********************************************************
@brief Dummy job that just mark it as completed and ignored
@ingroup libsync
***********************************************************/
class PropagateIgnoreJob : PropagateItemJob {
public:
    PropagateIgnoreJob (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item) {
    }
    void start () override {
        SyncFileItem.Status status = _item._status;
        if (status == SyncFileItem.NoStatus) {
            if (_item._instruction == CSYNC_INSTRUCTION_ERROR) {
                status = SyncFileItem.NormalError;
            } else {
                status = SyncFileItem.FileIgnored;
                ASSERT (_item._instruction == CSYNC_INSTRUCTION_IGNORE);
            }
        }
        done (status, _item._errorString);
    }
};


class OwncloudPropagator : GLib.Object {
public:
    SyncJournalDb *const _journal;
    bool _finishedEmited; // used to ensure that finished is only emitted once

public:
    OwncloudPropagator (AccountPtr account, string &localDir,
                       const string &remoteFolder, SyncJournalDb *progressDb,
                       QSet<string> &bulkUploadBlackList)
        : _journal (progressDb)
        , _finishedEmited (false)
        , _bandwidthManager (this)
        , _anotherSyncNeeded (false)
        , _chunkSize (10 * 1000 * 1000) // 10 MB, overridden in setSyncOptions
        , _account (account)
        , _localDir ( (localDir.endsWith (QChar ('/'))) ? localDir : localDir + '/')
        , _remoteFolder ( (remoteFolder.endsWith (QChar ('/'))) ? remoteFolder : remoteFolder + '/')
        , _bulkUploadBlackList (bulkUploadBlackList) {
        qRegisterMetaType<PropagatorJob.AbortType> ("PropagatorJob.AbortType");
    }

    ~OwncloudPropagator () override;

    void start (SyncFileItemVector &&_syncedItems);

    void startDirectoryPropagation (SyncFileItemPtr &item,
                                   QStack<QPair<string, PropagateDirectory>> &directories,
                                   QVector<PropagatorJob> &directoriesToRemove,
                                   string &removedDirectory,
                                   const SyncFileItemVector &items);

    void startFilePropagation (SyncFileItemPtr &item,
                              QStack<QPair<string, PropagateDirectory>> &directories,
                              QVector<PropagatorJob> &directoriesToRemove,
                              string &removedDirectory,
                              string &maybeConflictDirectory);

    const SyncOptions &syncOptions ();
    void setSyncOptions (SyncOptions &syncOptions);

    int _downloadLimit = 0;
    int _uploadLimit = 0;
    BandwidthManager _bandwidthManager;

    bool _abortRequested = false;

    /***********************************************************
    The list of currently active jobs.
        This list contains the jobs that are currently using ressources and is used purely to
        know how many jobs there is currently running for the scheduler.
        Jobs add themself to the list when they do an assynchronous operation.
        Jobs can be several time on the list (example, when several chunks are uploaded in parallel)
    ***********************************************************/
    QList<PropagateItemJob> _activeJobList;

    /***********************************************************
    We detected that another sync is required after this one */
    bool _anotherSyncNeeded;

    /***********************************************************
    Per-folder quota guesses.

    This starts out empty. When an upload in a folder fails due to insufficent
    remote quota, the quota guess is updated to be attempted_size-1 at maximum.
    
    Note that it will usually just an upper limit for the actual quota - but
    since the quota on the server might ch
    wrong in the other direction as well.

     * This allows skipping of uploads that have a very high likelihood of failure.
    ***********************************************************/
    QHash<string, int64> _folderQuota;

    /* the maximum number of jobs using bandwidth (uploads or downloads, in parallel) */
    int maximumActiveTransferJob ();

    /***********************************************************
    The size to use for upload chunks.

    Will be dynamically adjusted after each chunk upload finishes
    if Capabilities.desiredChunkUploadDuration has a target
    chunk-upload duration set.
    ***********************************************************/
    int64 _chunkSize;
    int64 smallFileSize ();

    /* The maximum number of active jobs in parallel  */
    int hardMaximumActiveJob ();

    /***********************************************************
    Check whether a download would clash with an existing file
    in filesystems that are only case-preserving.
    ***********************************************************/
    bool localFileNameClash (string &relfile);

    /***********************************************************
    Check whether a file is properly accessible for upload.

    It is possible to create files with filenames that differ
    only by case in NTFS, but most operations such as stat and
    open only target one of these by default.
    
    When that happens, we want to avoid uploading incorrect data
     * and give up on the file.
    ***********************************************************/
    bool hasCaseClashAccessibilityProblem (string &relfile);

    Q_REQUIRED_RESULT string fullLocalPath (string &tmp_file_name) const;
    string localPath ();

    /***********************************************************
    Returns the full remote path including the folder root of a
    folder sync path.
    ***********************************************************/
    Q_REQUIRED_RESULT string fullRemotePath (string &tmp_file_name) const;
    string remotePath ();

    /***********************************************************
    Creates the job for an item.
    ***********************************************************/
    PropagateItemJob *createJob (SyncFileItemPtr &item);

    void scheduleNextJob ();
    void reportProgress (SyncFileItem &, int64 bytes);

    void abort () {
        if (_abortRequested)
            return;
        if (_rootJob) {
            // Connect to abortFinished  which signals that abort has been asynchronously finished
            connect (_rootJob.data (), &PropagateDirectory.abortFinished, this, &OwncloudPropagator.emitFinished);

            // Use Queued Connection because we're possibly already in an item's finished stack
            QMetaObject.invokeMethod (_rootJob.data (), "abort", Qt.QueuedConnection,
                                      Q_ARG (PropagatorJob.AbortType, PropagatorJob.AbortType.Asynchronous));

            // Give asynchronous abort 5000 msec to finish on its own
            QTimer.singleShot (5000, this, SLOT (abortTimeout ()));
        } else {
            // No root job, call emitFinished
            emitFinished (SyncFileItem.NormalError);
        }
    }

    AccountPtr account ();

    enum DiskSpaceResult {
        DiskSpaceOk,
        DiskSpaceFailure,
        DiskSpaceCritical
    };

    /***********************************************************
    Checks whether there's enough disk space available to complete
     all jobs that are currently running.
    ***********************************************************/
    DiskSpaceResult diskSpaceCheck ();

    /***********************************************************
    Handles a conflict by renaming the file 'item'.

    Sets up conflict records.
    
    It also creates a new upload job in composite if the item
    moved away is a file and conflict uploads are requested.

     * Returns true on success, false and error on error.
    ***********************************************************/
    bool createConflict (SyncFileItemPtr &item,
        PropagatorCompositeJob *composite, string *error);

    // Map original path (as in the DB) to target final path
    QMap<string, string> _renamedDirectories;
    string adjustRenamedPath (string &original) const;

    /***********************************************************
    Update the database for an item.

    Typically after a sync operation succeeded. Updates the inode from
    the filesystem.
    
     * Will also trigger a Vfs.convertToPlaceholder.
    ***********************************************************/
    Result<Vfs.ConvertToPlaceholderResult, string> updateMetadata (SyncFileItem &item);

    /***********************************************************
    Update the database for an item.

    Typically after a sync operation succeeded. Updates the inode from
    the filesystem.
    
     * Will also trigger a Vfs.convertToPlaceholder.
    ***********************************************************/
    static Result<Vfs.ConvertToPlaceholderResult, string> staticUpdateMetadata (SyncFileItem &item, string localDir,
                                                                                 Vfs *vfs, SyncJournalDb * const journal);

    Q_REQUIRED_RESULT bool isDelayedUploadItem (SyncFileItemPtr &item) const;

    Q_REQUIRED_RESULT const std.deque<SyncFileItemPtr>& delayedTasks () {
        return _delayedTasks;
    }

    void setScheduleDelayedTasks (bool active);

    void clearDelayedTasks ();

    void addToBulkUploadBlackList (string &file);

    void removeFromBulkUploadBlackList (string &file);

    bool isInBulkUploadBlackList (string &file) const;

private slots:

    void abortTimeout () {
        // Abort synchronously and finish
        _rootJob.data ().abort (PropagatorJob.AbortType.Synchronous);
        emitFinished (SyncFileItem.NormalError);
    }

    /***********************************************************
    Emit the finished signal and make sure it is only emitted once */
    void emitFinished (SyncFileItem.Status status) {
        if (!_finishedEmited)
            emit finished (status == SyncFileItem.Success);
        _finishedEmited = true;
    }

    void scheduleNextJobImpl ();

signals:
    void newItem (SyncFileItemPtr &);
    void itemCompleted (SyncFileItemPtr &);
    void progress (SyncFileItem &, int64 bytes);
    void finished (bool success);

    /***********************************************************
    Emitted when propagation has problems with a locked file. */
    void seenLockedFile (string &fileName);

    /***********************************************************
    Emitted when propagation touches a file.

    Used to track our own file modifications such that notifications
    from the file watcher about these can be ignored.
    ***********************************************************/
    void touchedFile (string &fileName);

    void insufficientLocalStorage ();
    void insufficientRemoteStorage ();

private:
    std.unique_ptr<PropagateUploadFileCommon> createUploadJob (SyncFileItemPtr item,
                                                               bool deleteExisting);

    void pushDelayedUploadTask (SyncFileItemPtr item);

    void resetDelayedUploadTasks ();

    AccountPtr _account;
    QScopedPointer<PropagateRootDirectory> _rootJob;
    SyncOptions _syncOptions;
    bool _jobScheduled = false;

    const string _localDir; // absolute path to the local directory. ends with '/'
    const string _remoteFolder; // remote folder, ends with '/'

    std.deque<SyncFileItemPtr> _delayedTasks;
    bool _scheduleDelayedTasks = false;

    QSet<string> &_bulkUploadBlackList;

    static bool _allowDelayedUpload;
};

/***********************************************************
@brief Job that wait for all the poll jobs to be completed
@ingroup libsync
***********************************************************/
class CleanupPollsJob : GLib.Object {
    QVector<SyncJournalDb.PollInfo> _pollInfos;
    AccountPtr _account;
    SyncJournalDb *_journal;
    string _localPath;
    QSharedPointer<Vfs> _vfs;

public:
    CleanupPollsJob (QVector<SyncJournalDb.PollInfo> &pollInfos, AccountPtr account, SyncJournalDb *journal, string &localPath,
                             const QSharedPointer<Vfs> &vfs, GLib.Object *parent = nullptr)
        : GLib.Object (parent)
        , _pollInfos (pollInfos)
        , _account (account)
        , _journal (journal)
        , _localPath (localPath)
        , _vfs (vfs) {
    }

    ~CleanupPollsJob () override;

    /***********************************************************
    Start the job.  After the job is completed, it will emit either finished or aborted, and it
    will destroy itself.
    ***********************************************************/
    void start ();
signals:
    void finished ();
    void aborted (string &error);
private slots:
    void slotPollFinished ();
};

    int64 criticalFreeSpaceLimit () {
        int64 value = 50 * 1000 * 1000LL;
    
        static bool hasEnv = false;
        static int64 env = qgetenv ("OWNCLOUD_CRITICAL_FREE_SPACE_BYTES").toLongLong (&hasEnv);
        if (hasEnv) {
            value = env;
        }
    
        return qBound (0LL, value, freeSpaceLimit ());
    }
    
    int64 freeSpaceLimit () {
        int64 value = 250 * 1000 * 1000LL;
    
        static bool hasEnv = false;
        static int64 env = qgetenv ("OWNCLOUD_FREE_SPACE_BYTES").toLongLong (&hasEnv);
        if (hasEnv) {
            value = env;
        }
    
        return value;
    }
    
    OwncloudPropagator.~OwncloudPropagator () = default;
    
    int OwncloudPropagator.maximumActiveTransferJob () {
        if (_downloadLimit != 0
            || _uploadLimit != 0
            || !_syncOptions._parallelNetworkJobs) {
            // disable parallelism when there is a network limit.
            return 1;
        }
        return qMin (3, qCeil (_syncOptions._parallelNetworkJobs / 2.));
    }
    
    /* The maximum number of active jobs in parallel  */
    int OwncloudPropagator.hardMaximumActiveJob () {
        if (!_syncOptions._parallelNetworkJobs)
            return 1;
        return _syncOptions._parallelNetworkJobs;
    }
    
    PropagateItemJob.~PropagateItemJob () {
        if (auto p = propagator ()) {
            // Normally, every job should clean itself from the _activeJobList. So this should not be
            // needed. But if a job has a bug or is deleted before the network jobs signal get received,
            // we might risk end up with dangling pointer in the list which may cause crashes.
            p._activeJobList.removeAll (this);
        }
    }
    
    static int64 getMinBlacklistTime () {
        return qMax (qEnvironmentVariableIntValue ("OWNCLOUD_BLACKLIST_TIME_MIN"),
            25); // 25 seconds
    }
    
    static int64 getMaxBlacklistTime () {
        int v = qEnvironmentVariableIntValue ("OWNCLOUD_BLACKLIST_TIME_MAX");
        if (v > 0)
            return v;
        return 24 * 60 * 60; // 1 day
    }
    
    /***********************************************************
    Creates a blacklist entry, possibly taking into account an old one.
    
    The old entry may be invalid, then a fresh entry is created.
    ***********************************************************/
    static SyncJournalErrorBlacklistRecord createBlacklistEntry (
        const SyncJournalErrorBlacklistRecord &old, SyncFileItem &item) {
        SyncJournalErrorBlacklistRecord entry;
        entry._file = item._file;
        entry._errorString = item._errorString;
        entry._lastTryModtime = item._modtime;
        entry._lastTryEtag = item._etag;
        entry._lastTryTime = Utility.qDateTimeToTime_t (QDateTime.currentDateTimeUtc ());
        entry._renameTarget = item._renameTarget;
        entry._retryCount = old._retryCount + 1;
        entry._requestId = item._requestId;
    
        static int64 minBlacklistTime (getMinBlacklistTime ());
        static int64 maxBlacklistTime (qMax (getMaxBlacklistTime (), minBlacklistTime));
    
        // The factor of 5 feels natural : 25s, 2 min, 10 min, ~1h, ~5h, ~24h
        entry._ignoreDuration = old._ignoreDuration * 5;
    
        if (item._httpErrorCode == 403) {
            qCWarning (lcPropagator) << "Probably firewall error : " << item._httpErrorCode << ", blacklisting up to 1h only";
            entry._ignoreDuration = qMin (entry._ignoreDuration, int64 (60 * 60));
    
        } else if (item._httpErrorCode == 413 || item._httpErrorCode == 415) {
            qCWarning (lcPropagator) << "Fatal Error condition" << item._httpErrorCode << ", maximum blacklist ignore time!";
            entry._ignoreDuration = maxBlacklistTime;
        }
    
        entry._ignoreDuration = qBound (minBlacklistTime, entry._ignoreDuration, maxBlacklistTime);
    
        if (item._status == SyncFileItem.SoftError) {
            // Track these errors, but don't actively suppress them.
            entry._ignoreDuration = 0;
        }
    
        if (item._httpErrorCode == 507) {
            entry._errorCategory = SyncJournalErrorBlacklistRecord.InsufficientRemoteStorage;
        }
    
        return entry;
    }
    
    /***********************************************************
    Updates, creates or removes a blacklist entry for the given item.
    
    May adjust the status or item._errorString.
    ***********************************************************/
    void blacklistUpdate (SyncJournalDb *journal, SyncFileItem &item) {
        SyncJournalErrorBlacklistRecord oldEntry = journal.errorBlacklistEntry (item._file);
    
        bool mayBlacklist =
            item._errorMayBeBlacklisted // explicitly flagged for blacklisting
            || ( (item._status == SyncFileItem.NormalError
                    || item._status == SyncFileItem.SoftError
                    || item._status == SyncFileItem.DetailError)
                   && item._httpErrorCode != 0 // or non-local error
                   );
    
        // No new entry? Possibly remove the old one, then done.
        if (!mayBlacklist) {
            if (oldEntry.isValid ()) {
                journal.wipeErrorBlacklistEntry (item._file);
            }
            return;
        }
    
        auto newEntry = createBlacklistEntry (oldEntry, item);
        journal.setErrorBlacklistEntry (newEntry);
    
        // Suppress the error if it was and continues to be blacklisted.
        // An ignoreDuration of 0 mean we're tracking the error, but not actively
        // suppressing it.
        if (item._hasBlacklistEntry && newEntry._ignoreDuration > 0) {
            item._status = SyncFileItem.BlacklistedError;
    
            qCInfo (lcPropagator) << "blacklisting " << item._file
                                 << " for " << newEntry._ignoreDuration
                                 << ", retry count " << newEntry._retryCount;
    
            return;
        }
    
        // Some soft errors might become louder on repeat occurrence
        if (item._status == SyncFileItem.SoftError
            && newEntry._retryCount > 1) {
            qCWarning (lcPropagator) << "escalating soft error on " << item._file
                                    << " to normal error, " << item._httpErrorCode;
            item._status = SyncFileItem.NormalError;
            return;
        }
    }
    
    void PropagateItemJob.done (SyncFileItem.Status statusArg, string &errorString) {
        // Duplicate calls to done () are a logic error
        ENFORCE (_state != Finished);
        _state = Finished;
    
        _item._status = statusArg;
    
        if (_item._isRestoration) {
            if (_item._status == SyncFileItem.Success
                || _item._status == SyncFileItem.Conflict) {
                _item._status = SyncFileItem.Restoration;
            } else {
                _item._errorString += tr ("; Restoration Failed : %1").arg (errorString);
            }
        } else {
            if (_item._errorString.isEmpty ()) {
                _item._errorString = errorString;
            }
        }
    
        if (propagator ()._abortRequested && (_item._status == SyncFileItem.NormalError
                                              || _item._status == SyncFileItem.FatalError)) {
            // an abort request is ongoing. Change the status to Soft-Error
            _item._status = SyncFileItem.SoftError;
        }
    
        // Blacklist handling
        switch (_item._status) {
        case SyncFileItem.SoftError:
        case SyncFileItem.FatalError:
        case SyncFileItem.NormalError:
        case SyncFileItem.DetailError:
            // Check the blacklist, possibly adjusting the item (including its status)
            blacklistUpdate (propagator ()._journal, *_item);
            break;
        case SyncFileItem.Success:
        case SyncFileItem.Restoration:
            if (_item._hasBlacklistEntry) {
                // wipe blacklist entry.
                propagator ()._journal.wipeErrorBlacklistEntry (_item._file);
                // remove a blacklist entry in case the file was moved.
                if (_item._originalFile != _item._file) {
                    propagator ()._journal.wipeErrorBlacklistEntry (_item._originalFile);
                }
            }
            break;
        case SyncFileItem.Conflict:
        case SyncFileItem.FileIgnored:
        case SyncFileItem.NoStatus:
        case SyncFileItem.BlacklistedError:
        case SyncFileItem.FileLocked:
        case SyncFileItem.FileNameInvalid:
            // nothing
            break;
        }
    
        if (_item.hasErrorStatus ())
            qCWarning (lcPropagator) << "Could not complete propagation of" << _item.destination () << "by" << this << "with status" << _item._status << "and error:" << _item._errorString;
        else
            qCInfo (lcPropagator) << "Completed propagation of" << _item.destination () << "by" << this << "with status" << _item._status;
        emit propagator ().itemCompleted (_item);
        emit finished (_item._status);
    
        if (_item._status == SyncFileItem.FatalError) {
            // Abort all remaining jobs.
            propagator ().abort ();
        }
    }
    
    void PropagateItemJob.slotRestoreJobFinished (SyncFileItem.Status status) {
        string msg;
        if (_restoreJob) {
            msg = _restoreJob.restoreJobMsg ();
            _restoreJob.setRestoreJobMsg ();
        }
    
        if (status == SyncFileItem.Success || status == SyncFileItem.Conflict
            || status == SyncFileItem.Restoration) {
            done (SyncFileItem.SoftError, msg);
        } else {
            done (status, tr ("A file or folder was removed from a read only share, but restoring failed : %1").arg (msg));
        }
    }
    
    bool PropagateItemJob.hasEncryptedAncestor () {
        if (!propagator ().account ().capabilities ().clientSideEncryptionAvailable ()) {
            return false;
        }
    
        const auto path = _item._file;
        const auto slashPosition = path.lastIndexOf ('/');
        const auto parentPath = slashPosition >= 0 ? path.left (slashPosition) : string ();
    
        auto pathComponents = parentPath.split ('/');
        while (!pathComponents.isEmpty ()) {
            SyncJournalFileRecord rec;
            propagator ()._journal.getFileRecord (pathComponents.join ('/'), &rec);
            if (rec.isValid () && rec._isE2eEncrypted) {
                return true;
            }
            pathComponents.removeLast ();
        }
    
        return false;
    }
    
    // ================================================================================
    
    PropagateItemJob *OwncloudPropagator.createJob (SyncFileItemPtr &item) {
        bool deleteExisting = item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE;
        switch (item._instruction) {
        case CSYNC_INSTRUCTION_REMOVE:
            if (item._direction == SyncFileItem.Down)
                return new PropagateLocalRemove (this, item);
            else
                return new PropagateRemoteDelete (this, item);
        case CSYNC_INSTRUCTION_NEW:
        case CSYNC_INSTRUCTION_TYPE_CHANGE:
        case CSYNC_INSTRUCTION_CONFLICT:
            if (item.isDirectory ()) {
                // CONFLICT has _direction == None
                if (item._direction != SyncFileItem.Up) {
                    auto job = new PropagateLocalMkdir (this, item);
                    job.setDeleteExistingFile (deleteExisting);
                    return job;
                } else {
                    auto job = new PropagateRemoteMkdir (this, item);
                    job.setDeleteExisting (deleteExisting);
                    return job;
                }
            } //fall through
        case CSYNC_INSTRUCTION_SYNC:
            if (item._direction != SyncFileItem.Up) {
                auto job = new PropagateDownloadFile (this, item);
                job.setDeleteExistingFolder (deleteExisting);
                return job;
            } else {
                if (deleteExisting || !isDelayedUploadItem (item)) {
                    auto job = createUploadJob (item, deleteExisting);
                    return job.release ();
                } else {
                    pushDelayedUploadTask (item);
                    return nullptr;
                }
            }
        case CSYNC_INSTRUCTION_RENAME:
            if (item._direction == SyncFileItem.Up) {
                return new PropagateRemoteMove (this, item);
            } else {
                return new PropagateLocalRename (this, item);
            }
        case CSYNC_INSTRUCTION_IGNORE:
        case CSYNC_INSTRUCTION_ERROR:
            return new PropagateIgnoreJob (this, item);
        default:
            return nullptr;
        }
        return nullptr;
    }
    
    std.unique_ptr<PropagateUploadFileCommon> OwncloudPropagator.createUploadJob (SyncFileItemPtr item, bool deleteExisting) {
        auto job = std.unique_ptr<PropagateUploadFileCommon>{};
    
        if (item._size > syncOptions ()._initialChunkSize && account ().capabilities ().chunkingNg ()) {
            // Item is above _initialChunkSize, thus will be classified as to be chunked
            job = std.make_unique<PropagateUploadFileNG> (this, item);
        } else {
            job = std.make_unique<PropagateUploadFileV1> (this, item);
        }
    
        job.setDeleteExisting (deleteExisting);
    
        removeFromBulkUploadBlackList (item._file);
    
        return job;
    }
    
    void OwncloudPropagator.pushDelayedUploadTask (SyncFileItemPtr item) {
        _delayedTasks.push_back (item);
    }
    
    void OwncloudPropagator.resetDelayedUploadTasks () {
        _scheduleDelayedTasks = false;
        _delayedTasks.clear ();
    }
    
    int64 OwncloudPropagator.smallFileSize () {
        const int64 smallFileSize = 100 * 1024; //default to 1 MB. Not dynamic right now.
        return smallFileSize;
    }
    
    void OwncloudPropagator.start (SyncFileItemVector &&items) {
        Q_ASSERT (std.is_sorted (items.begin (), items.end ()));
    
        /* This builds all the jobs needed for the propagation.
         * Each directory is a PropagateDirectory job, which contains the files in it.
         * In order to do that we loop over the items. (which are sorted by destination)
         * When we enter a directory, we can create the directory job and push it on the stack. */
    
        const auto regex = syncOptions ().fileRegex ();
        if (regex.isValid ()) {
            QSet<QStringRef> names;
            for (auto &i : items) {
                if (regex.match (i._file).hasMatch ()) {
                    int index = -1;
                    QStringRef ref;
                    do {
                        ref = i._file.midRef (0, index);
                        names.insert (ref);
                        index = ref.lastIndexOf (QLatin1Char ('/'));
                    } while (index > 0);
                }
            }
            items.erase (std.remove_if (items.begin (), items.end (), [&names] (auto i) {
                return !names.contains (QStringRef { &i._file });
            }),
                items.end ());
        }
    
        resetDelayedUploadTasks ();
        _rootJob.reset (new PropagateRootDirectory (this));
        QStack<QPair<string /* directory name */, PropagateDirectory * /* job */>> directories;
        directories.push (qMakePair (string (), _rootJob.data ()));
        QVector<PropagatorJob> directoriesToRemove;
        string removedDirectory;
        string maybeConflictDirectory;
        foreach (SyncFileItemPtr &item, items) {
            if (!removedDirectory.isEmpty () && item._file.startsWith (removedDirectory)) {
                // this is an item in a directory which is going to be removed.
                auto *delDirJob = qobject_cast<PropagateDirectory> (directoriesToRemove.first ());
    
                const auto isNewDirectory = item.isDirectory () &&
                        (item._instruction == CSYNC_INSTRUCTION_NEW || item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE);
    
                if (item._instruction == CSYNC_INSTRUCTION_REMOVE || isNewDirectory) {
                    // If it is a remove it is already taken care of by the removal of the parent directory
    
                    // If it is a new directory then it is inside a deleted directory... That can happen if
                    // the directory etag was not fetched properly on the previous sync because the sync was
                    // aborted while uploading this directory (which is now removed).  We can ignore it.
    
                    // increase the number of subjobs that would be there.
                    if (delDirJob) {
                        delDirJob.increaseAffectedCount ();
                    }
                    continue;
                } else if (item._instruction == CSYNC_INSTRUCTION_IGNORE) {
                    continue;
                } else if (item._instruction == CSYNC_INSTRUCTION_RENAME) {
                    // all is good, the rename will be executed before the directory deletion
                } else {
                    qCWarning (lcPropagator) << "WARNING :  Job within a removed directory?  This should not happen!"
                                            << item._file << item._instruction;
                }
            }
    
            // If a CONFLICT item contains files these can't be processed because
            // the conflict handling is likely to rename the directory. This can happen
            // when there's a new local directory at the same time as a remote file.
            if (!maybeConflictDirectory.isEmpty ()) {
                if (item.destination ().startsWith (maybeConflictDirectory)) {
                    qCInfo (lcPropagator) << "Skipping job inside CONFLICT directory"
                                         << item._file << item._instruction;
                    item._instruction = CSYNC_INSTRUCTION_NONE;
                    continue;
                } else {
                    maybeConflictDirectory.clear ();
                }
            }
    
            while (!item.destination ().startsWith (directories.top ().first)) {
                directories.pop ();
            }
    
            if (item.isDirectory ()) {
                startDirectoryPropagation (item,
                                          directories,
                                          directoriesToRemove,
                                          removedDirectory,
                                          items);
            } else {
                startFilePropagation (item,
                                     directories,
                                     directoriesToRemove,
                                     removedDirectory,
                                     maybeConflictDirectory);
            }
        }
    
        foreach (PropagatorJob *it, directoriesToRemove) {
            _rootJob._dirDeletionJobs.appendJob (it);
        }
    
        connect (_rootJob.data (), &PropagatorJob.finished, this, &OwncloudPropagator.emitFinished);
    
        _jobScheduled = false;
        scheduleNextJob ();
    }
    
    void OwncloudPropagator.startDirectoryPropagation (SyncFileItemPtr &item,
                                                       QStack<QPair<string, PropagateDirectory>> &directories,
                                                       QVector<PropagatorJob> &directoriesToRemove,
                                                       string &removedDirectory,
                                                       const SyncFileItemVector &items) {
        auto directoryPropagationJob = std.make_unique<PropagateDirectory> (this, item);
    
        if (item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE
            && item._direction == SyncFileItem.Up) {
            // Skip all potential uploads to the new folder.
            // Processing them now leads to problems with permissions:
            // checkForPermissions () has already run and used the permissions
            // of the file we're about to delete to decide whether uploading
            // to the new dir is ok...
            foreach (SyncFileItemPtr &dirItem, items) {
                if (dirItem.destination ().startsWith (item.destination () + "/")) {
                    dirItem._instruction = CSYNC_INSTRUCTION_NONE;
                    _anotherSyncNeeded = true;
                }
            }
        }
    
        if (item._instruction == CSYNC_INSTRUCTION_REMOVE) {
            // We do the removal of directories at the end, because there might be moves from
            // these directories that will happen later.
            directoriesToRemove.prepend (directoryPropagationJob.get ());
            removedDirectory = item._file + "/";
    
            // We should not update the etag of parent directories of the removed directory
            // since it would be done before the actual remove (issue #1845)
            // NOTE : Currently this means that we don't update those etag at all in this sync,
            //       but it should not be a problem, they will be updated in the next sync.
            for (int i = 0; i < directories.size (); ++i) {
                if (directories[i].second._item._instruction == CSYNC_INSTRUCTION_UPDATE_METADATA) {
                    directories[i].second._item._instruction = CSYNC_INSTRUCTION_NONE;
                }
            }
        } else {
            const auto currentDirJob = directories.top ().second;
            currentDirJob.appendJob (directoryPropagationJob.get ());
        }
        directories.push (qMakePair (item.destination () + "/", directoryPropagationJob.release ()));
    }
    
    void OwncloudPropagator.startFilePropagation (SyncFileItemPtr &item,
                                                  QStack<QPair<string, PropagateDirectory> > &directories,
                                                  QVector<PropagatorJob> &directoriesToRemove,
                                                  string &removedDirectory,
                                                  string &maybeConflictDirectory) {
        if (item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE) {
            // will delete directories, so defer execution
            auto job = createJob (item);
            if (job) {
                directoriesToRemove.prepend (job);
            }
            removedDirectory = item._file + "/";
        } else {
            directories.top ().second.appendTask (item);
        }
    
        if (item._instruction == CSYNC_INSTRUCTION_CONFLICT) {
            // This might be a file or a directory on the local side. If it's a
            // directory we want to skip processing items inside it.
            maybeConflictDirectory = item._file + "/";
        }
    }
    
    const SyncOptions &OwncloudPropagator.syncOptions () {
        return _syncOptions;
    }
    
    void OwncloudPropagator.setSyncOptions (SyncOptions &syncOptions) {
        _syncOptions = syncOptions;
        _chunkSize = syncOptions._initialChunkSize;
    }
    
    bool OwncloudPropagator.localFileNameClash (string &relFile) {
        const string file (_localDir + relFile);
        Q_ASSERT (!file.isEmpty ());
    
        if (!file.isEmpty () && Utility.fsCasePreserving ()) {
            qCDebug (lcPropagator) << "CaseClashCheck for " << file;
            // On Linux, the file system is case sensitive, but this code is useful for testing.
            // Just check that there is no other file with the same name and different casing.
            QFileInfo fileInfo (file);
            const string fn = fileInfo.fileName ();
            const QStringList list = fileInfo.dir ().entryList ({ fn });
            if (list.count () > 1 || (list.count () == 1 && list[0] != fn)) {
                return true;
            }
        }
        return false;
    }
    
    bool OwncloudPropagator.hasCaseClashAccessibilityProblem (string &relfile) {
        Q_UNUSED (relfile);
        return false;
    }
    
    string OwncloudPropagator.fullLocalPath (string &tmp_file_name) {
        return _localDir + tmp_file_name;
    }
    
    string OwncloudPropagator.localPath () {
        return _localDir;
    }
    
    void OwncloudPropagator.scheduleNextJob () {
        if (_jobScheduled) return; // don't schedule more than 1
        _jobScheduled = true;
        QTimer.singleShot (3, this, &OwncloudPropagator.scheduleNextJobImpl);
    }
    
    void OwncloudPropagator.scheduleNextJobImpl () {
        // TODO : If we see that the automatic up-scaling has a bad impact we
        // need to check how to avoid this.
        // Down-scaling on slow networks? https://github.com/owncloud/client/issues/3382
        // Making sure we do up/down at same time? https://github.com/owncloud/client/issues/1633
    
        _jobScheduled = false;
    
        if (_activeJobList.count () < maximumActiveTransferJob ()) {
            if (_rootJob.scheduleSelfOrChild ()) {
                scheduleNextJob ();
            }
        } else if (_activeJobList.count () < hardMaximumActiveJob ()) {
            int likelyFinishedQuicklyCount = 0;
            // NOTE : Only counts the first 3 jobs! Then for each
            // one that is likely finished quickly, we can launch another one.
            // When a job finishes another one will "move up" to be one of the first 3 and then
            // be counted too.
            for (int i = 0; i < maximumActiveTransferJob () && i < _activeJobList.count (); i++) {
                if (_activeJobList.at (i).isLikelyFinishedQuickly ()) {
                    likelyFinishedQuicklyCount++;
                }
            }
            if (_activeJobList.count () < maximumActiveTransferJob () + likelyFinishedQuicklyCount) {
                qCDebug (lcPropagator) << "Can pump in another request! activeJobs =" << _activeJobList.count ();
                if (_rootJob.scheduleSelfOrChild ()) {
                    scheduleNextJob ();
                }
            }
        }
    }
    
    void OwncloudPropagator.reportProgress (SyncFileItem &item, int64 bytes) {
        emit progress (item, bytes);
    }
    
    AccountPtr OwncloudPropagator.account () {
        return _account;
    }
    
    OwncloudPropagator.DiskSpaceResult OwncloudPropagator.diskSpaceCheck () {
        const int64 freeBytes = Utility.freeDiskSpace (_localDir);
        if (freeBytes < 0) {
            return DiskSpaceOk;
        }
    
        if (freeBytes < criticalFreeSpaceLimit ()) {
            return DiskSpaceCritical;
        }
    
        if (freeBytes - _rootJob.committedDiskSpace () < freeSpaceLimit ()) {
            return DiskSpaceFailure;
        }
    
        return DiskSpaceOk;
    }
    
    bool OwncloudPropagator.createConflict (SyncFileItemPtr &item,
        PropagatorCompositeJob *composite, string *error) {
        string fn = fullLocalPath (item._file);
    
        string renameError;
        auto conflictModTime = FileSystem.getModTime (fn);
        if (conflictModTime <= 0) {
            *error = tr ("Impossible to get modification time for file in conflict %1").arg (fn);
            return false;
        }
        string conflictUserName;
        if (account ().capabilities ().uploadConflictFiles ())
            conflictUserName = account ().davDisplayName ();
        string conflictFileName = Utility.makeConflictFileName (
            item._file, Utility.qDateTimeFromTime_t (conflictModTime), conflictUserName);
        string conflictFilePath = fullLocalPath (conflictFileName);
    
        emit touchedFile (fn);
        emit touchedFile (conflictFilePath);
    
        if (!FileSystem.rename (fn, conflictFilePath, &renameError)) {
            // If the rename fails, don't replace it.
    
            // If the file is locked, we want to retry this sync when it
            // becomes available again.
            if (FileSystem.isFileLocked (fn)) {
                emit seenLockedFile (fn);
            }
    
            if (error)
                *error = renameError;
            return false;
        }
        qCInfo (lcPropagator) << "Created conflict file" << fn << "." << conflictFileName;
    
        // Create a new conflict record. To get the base etag, we need to read it from the db.
        ConflictRecord conflictRecord;
        conflictRecord.path = conflictFileName.toUtf8 ();
        conflictRecord.baseModtime = item._previousModtime;
        conflictRecord.initialBasePath = item._file.toUtf8 ();
    
        SyncJournalFileRecord baseRecord;
        if (_journal.getFileRecord (item._originalFile, &baseRecord) && baseRecord.isValid ()) {
            conflictRecord.baseEtag = baseRecord._etag;
            conflictRecord.baseFileId = baseRecord._fileId;
        } else {
            // We might very well end up with no fileid/etag for new/new conflicts
        }
    
        _journal.setConflictRecord (conflictRecord);
    
        // Create a new upload job if the new conflict file should be uploaded
        if (account ().capabilities ().uploadConflictFiles ()) {
            if (composite && !QFileInfo (conflictFilePath).isDir ()) {
                SyncFileItemPtr conflictItem = SyncFileItemPtr (new SyncFileItem);
                conflictItem._file = conflictFileName;
                conflictItem._type = ItemTypeFile;
                conflictItem._direction = SyncFileItem.Up;
                conflictItem._instruction = CSYNC_INSTRUCTION_NEW;
                conflictItem._modtime = conflictModTime;
                conflictItem._size = item._previousSize;
                emit newItem (conflictItem);
                composite.appendTask (conflictItem);
            }
        }
    
        // Need a new sync to detect the created copy of the conflicting file
        _anotherSyncNeeded = true;
    
        return true;
    }
    
    string OwncloudPropagator.adjustRenamedPath (string &original) {
        return Occ.adjustRenamedPath (_renamedDirectories, original);
    }
    
    Result<Vfs.ConvertToPlaceholderResult, string> OwncloudPropagator.updateMetadata (SyncFileItem &item) {
        return OwncloudPropagator.staticUpdateMetadata (item, _localDir, syncOptions ()._vfs.data (), _journal);
    }
    
    Result<Vfs.ConvertToPlaceholderResult, string> OwncloudPropagator.staticUpdateMetadata (SyncFileItem &item, string localDir,
                                                                                              Vfs *vfs, SyncJournalDb *const journal) {
        const string fsPath = localDir + item.destination ();
        const auto result = vfs.convertToPlaceholder (fsPath, item);
        if (!result) {
            return result.error ();
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            return Vfs.ConvertToPlaceholderResult.Locked;
        }
        auto record = item.toSyncJournalFileRecordWithInode (fsPath);
        const auto dBresult = journal.setFileRecord (record);
        if (!dBresult) {
            return dBresult.error ();
        }
        return Vfs.ConvertToPlaceholderResult.Ok;
    }
    
    bool OwncloudPropagator.isDelayedUploadItem (SyncFileItemPtr &item) {
        return account ().capabilities ().bulkUpload () && !_scheduleDelayedTasks && !item._isEncrypted && _syncOptions._minChunkSize > item._size && !isInBulkUploadBlackList (item._file);
    }
    
    void OwncloudPropagator.setScheduleDelayedTasks (bool active) {
        _scheduleDelayedTasks = active;
    }
    
    void OwncloudPropagator.clearDelayedTasks () {
        _delayedTasks.clear ();
    }
    
    void OwncloudPropagator.addToBulkUploadBlackList (string &file) {
        qCDebug (lcPropagator) << "black list for bulk upload" << file;
        _bulkUploadBlackList.insert (file);
    }
    
    void OwncloudPropagator.removeFromBulkUploadBlackList (string &file) {
        qCDebug (lcPropagator) << "black list for bulk upload" << file;
        _bulkUploadBlackList.remove (file);
    }
    
    bool OwncloudPropagator.isInBulkUploadBlackList (string &file) {
        return _bulkUploadBlackList.contains (file);
    }
    
    // ================================================================================
    
    PropagatorJob.PropagatorJob (OwncloudPropagator *propagator)
        : GLib.Object (propagator)
        , _state (NotYetStarted) {
    }
    
    OwncloudPropagator *PropagatorJob.propagator () {
        return qobject_cast<OwncloudPropagator> (parent ());
    }
    
    // ================================================================================
    
    PropagatorJob.JobParallelism PropagatorCompositeJob.parallelism () {
        // If any of the running sub jobs is not parallel, we have to wait
        for (int i = 0; i < _runningJobs.count (); ++i) {
            if (_runningJobs.at (i).parallelism () != FullParallelism) {
                return _runningJobs.at (i).parallelism ();
            }
        }
        return FullParallelism;
    }
    
    void PropagatorCompositeJob.slotSubJobAbortFinished () {
        // Count that job has been finished
        _abortsCount--;
    
        // Emit abort if last job has been aborted
        if (_abortsCount == 0) {
            emit abortFinished ();
        }
    }
    
    void PropagatorCompositeJob.appendJob (PropagatorJob *job) {
        job.setAssociatedComposite (this);
        _jobsToDo.append (job);
    }
    
    bool PropagatorCompositeJob.scheduleSelfOrChild () {
        if (_state == Finished) {
            return false;
        }
    
        // Start the composite job
        if (_state == NotYetStarted) {
            _state = Running;
        }
    
        // Ask all the running composite jobs if they have something new to schedule.
        for (auto runningJob : qAsConst (_runningJobs)) {
            ASSERT (runningJob._state == Running);
    
            if (possiblyRunNextJob (runningJob)) {
                return true;
            }
    
            // If any of the running sub jobs is not parallel, we have to cancel the scheduling
            // of the rest of the list and wait for the blocking job to finish and schedule the next one.
            auto paral = runningJob.parallelism ();
            if (paral == WaitForFinished) {
                return false;
            }
        }
    
        // Now it's our turn, check if we have something left to do.
        // First, convert a task to a job if necessary
        while (_jobsToDo.isEmpty () && !_tasksToDo.isEmpty ()) {
            SyncFileItemPtr nextTask = _tasksToDo.first ();
            _tasksToDo.remove (0);
            PropagatorJob *job = propagator ().createJob (nextTask);
            if (!job) {
                qCWarning (lcDirectory) << "Useless task found for file" << nextTask.destination () << "instruction" << nextTask._instruction;
                continue;
            }
            appendJob (job);
            break;
        }
        // Then run the next job
        if (!_jobsToDo.isEmpty ()) {
            PropagatorJob *nextJob = _jobsToDo.first ();
            _jobsToDo.remove (0);
            _runningJobs.append (nextJob);
            return possiblyRunNextJob (nextJob);
        }
    
        // If neither us or our children had stuff left to do we could hang. Make sure
        // we mark this job as finished so that the propagator can schedule a new one.
        if (_jobsToDo.isEmpty () && _tasksToDo.isEmpty () && _runningJobs.isEmpty ()) {
            // Our parent jobs are already iterating over their running jobs, post to the event loop
            // to avoid removing ourself from that list while they iterate.
            QMetaObject.invokeMethod (this, "finalize", Qt.QueuedConnection);
        }
        return false;
    }
    
    void PropagatorCompositeJob.slotSubJobFinished (SyncFileItem.Status status) {
        auto *subJob = static_cast<PropagatorJob> (sender ());
        ASSERT (subJob);
    
        // Delete the job and remove it from our list of jobs.
        subJob.deleteLater ();
        int i = _runningJobs.indexOf (subJob);
        ENFORCE (i >= 0); // should only happen if this function is called more than once
        _runningJobs.remove (i);
    
        // Any sub job error will cause the whole composite to fail. This is important
        // for knowing whether to update the etag in PropagateDirectory, for example.
        if (status == SyncFileItem.FatalError
            || status == SyncFileItem.NormalError
            || status == SyncFileItem.SoftError
            || status == SyncFileItem.DetailError
            || status == SyncFileItem.BlacklistedError) {
            _hasError = status;
        }
    
        if (_jobsToDo.isEmpty () && _tasksToDo.isEmpty () && _runningJobs.isEmpty ()) {
            finalize ();
        } else {
            propagator ().scheduleNextJob ();
        }
    }
    
    void PropagatorCompositeJob.finalize () {
        // The propagator will do parallel scheduling and this could be posted
        // multiple times on the event loop, ignore the duplicate calls.
        if (_state == Finished)
            return;
    
        _state = Finished;
        emit finished (_hasError == SyncFileItem.NoStatus ? SyncFileItem.Success : _hasError);
    }
    
    int64 PropagatorCompositeJob.committedDiskSpace () {
        int64 needed = 0;
        foreach (PropagatorJob *job, _runningJobs) {
            needed += job.committedDiskSpace ();
        }
        return needed;
    }
    
    // ================================================================================
    
    PropagateDirectory.PropagateDirectory (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagatorJob (propagator)
        , _item (item)
        , _firstJob (propagator.createJob (item))
        , _subJobs (propagator) {
        if (_firstJob) {
            connect (_firstJob.data (), &PropagatorJob.finished, this, &PropagateDirectory.slotFirstJobFinished);
            _firstJob.setAssociatedComposite (&_subJobs);
        }
        connect (&_subJobs, &PropagatorJob.finished, this, &PropagateDirectory.slotSubJobsFinished);
    }
    
    PropagatorJob.JobParallelism PropagateDirectory.parallelism () {
        // If any of the non-finished sub jobs is not parallel, we have to wait
        if (_firstJob && _firstJob.parallelism () != FullParallelism) {
            return WaitForFinished;
        }
        if (_subJobs.parallelism () != FullParallelism) {
            return WaitForFinished;
        }
        return FullParallelism;
    }
    
    bool PropagateDirectory.scheduleSelfOrChild () {
        if (_state == Finished) {
            return false;
        }
    
        if (_state == NotYetStarted) {
            _state = Running;
        }
    
        if (_firstJob && _firstJob._state == NotYetStarted) {
            return _firstJob.scheduleSelfOrChild ();
        }
    
        if (_firstJob && _firstJob._state == Running) {
            // Don't schedule any more job until this is done.
            return false;
        }
    
        return _subJobs.scheduleSelfOrChild ();
    }
    
    void PropagateDirectory.slotFirstJobFinished (SyncFileItem.Status status) {
        _firstJob.take ().deleteLater ();
    
        if (status != SyncFileItem.Success
            && status != SyncFileItem.Restoration
            && status != SyncFileItem.Conflict) {
            if (_state != Finished) {
                // Synchronously abort
                abort (AbortType.Synchronous);
                _state = Finished;
                qCInfo (lcPropagator) << "PropagateDirectory.slotFirstJobFinished" << "emit finished" << status;
                emit finished (status);
            }
            return;
        }
    
        propagator ().scheduleNextJob ();
    }
    
    void PropagateDirectory.slotSubJobsFinished (SyncFileItem.Status status) {
        if (!_item.isEmpty () && status == SyncFileItem.Success) {
            // If a directory is renamed, recursively delete any stale items
            // that may still exist below the old path.
            if (_item._instruction == CSYNC_INSTRUCTION_RENAME
                && _item._originalFile != _item._renameTarget) {
                propagator ()._journal.deleteFileRecord (_item._originalFile, true);
            }
    
            if (_item._instruction == CSYNC_INSTRUCTION_NEW && _item._direction == SyncFileItem.Down) {
                // special case for local MKDIR, set local directory mtime
                // (it's not synced later at all, but can be nice to have it set initially)
    
                if (_item._modtime <= 0) {
                    status = _item._status = SyncFileItem.NormalError;
                    _item._errorString = tr ("Error updating metadata due to invalid modified time");
                    qCWarning (lcDirectory) << "Error writing to the database for file" << _item._file;
                }
    
                FileSystem.setModTime (propagator ().fullLocalPath (_item.destination ()), _item._modtime);
            }
    
            // For new directories we always want to update the etag once
            // the directory has been propagated. Otherwise the directory
            // could appear locally without being added to the database.
            if (_item._instruction == CSYNC_INSTRUCTION_RENAME
                || _item._instruction == CSYNC_INSTRUCTION_NEW
                || _item._instruction == CSYNC_INSTRUCTION_UPDATE_METADATA) {
                const auto result = propagator ().updateMetadata (*_item);
                if (!result) {
                    status = _item._status = SyncFileItem.FatalError;
                    _item._errorString = tr ("Error updating metadata : %1").arg (result.error ());
                    qCWarning (lcDirectory) << "Error writing to the database for file" << _item._file << "with" << result.error ();
                } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
                    _item._status = SyncFileItem.SoftError;
                    _item._errorString = tr ("File is currently in use");
                }
            }
        }
        _state = Finished;
        qCInfo (lcPropagator) << "PropagateDirectory.slotSubJobsFinished" << "emit finished" << status;
        emit finished (status);
    }
    
    PropagateRootDirectory.PropagateRootDirectory (OwncloudPropagator *propagator)
        : PropagateDirectory (propagator, SyncFileItemPtr (new SyncFileItem))
        , _dirDeletionJobs (propagator) {
        connect (&_dirDeletionJobs, &PropagatorJob.finished, this, &PropagateRootDirectory.slotDirDeletionJobsFinished);
    }
    
    PropagatorJob.JobParallelism PropagateRootDirectory.parallelism () {
        // the root directory parallelism isn't important
        return WaitForFinished;
    }
    
    void PropagateRootDirectory.abort (PropagatorJob.AbortType abortType) {
        if (_firstJob)
            // Force first job to abort synchronously
            // even if caller allows async abort (asyncAbort)
            _firstJob.abort (AbortType.Synchronous);
    
        if (abortType == AbortType.Asynchronous) {
            struct AbortsFinished {
                bool subJobsFinished = false;
                bool dirDeletionFinished = false;
            };
            auto abortStatus = QSharedPointer<AbortsFinished> (new AbortsFinished);
    
            connect (&_subJobs, &PropagatorCompositeJob.abortFinished, this, [this, abortStatus] () {
                abortStatus.subJobsFinished = true;
                if (abortStatus.subJobsFinished && abortStatus.dirDeletionFinished)
                    emit abortFinished ();
            });
            connect (&_dirDeletionJobs, &PropagatorCompositeJob.abortFinished, this, [this, abortStatus] () {
                abortStatus.dirDeletionFinished = true;
                if (abortStatus.subJobsFinished && abortStatus.dirDeletionFinished)
                    emit abortFinished ();
            });
        }
        _subJobs.abort (abortType);
        _dirDeletionJobs.abort (abortType);
    }
    
    int64 PropagateRootDirectory.committedDiskSpace () {
        return _subJobs.committedDiskSpace () + _dirDeletionJobs.committedDiskSpace ();
    }
    
    bool PropagateRootDirectory.scheduleSelfOrChild () {
        qCInfo (lcRootDirectory ()) << "scheduleSelfOrChild" << _state << "pending uploads" << propagator ().delayedTasks ().size () << "subjobs state" << _subJobs._state;
    
        if (_state == Finished) {
            return false;
        }
    
        if (PropagateDirectory.scheduleSelfOrChild () && propagator ().delayedTasks ().empty ()) {
            return true;
        }
    
        // Important : Finish _subJobs before scheduling any deletes.
        if (_subJobs._state != Finished) {
            return false;
        }
    
        if (!propagator ().delayedTasks ().empty ()) {
            return scheduleDelayedJobs ();
        }
    
        return _dirDeletionJobs.scheduleSelfOrChild ();
    }
    
    void PropagateRootDirectory.slotSubJobsFinished (SyncFileItem.Status status) {
        qCInfo (lcRootDirectory ()) << status << "slotSubJobsFinished" << _state << "pending uploads" << propagator ().delayedTasks ().size () << "subjobs state" << _subJobs._state;
    
        if (!propagator ().delayedTasks ().empty ()) {
            scheduleDelayedJobs ();
            return;
        }
    
        if (status != SyncFileItem.Success
            && status != SyncFileItem.Restoration
            && status != SyncFileItem.Conflict) {
            if (_state != Finished) {
                // Synchronously abort
                abort (AbortType.Synchronous);
                _state = Finished;
                qCInfo (lcPropagator) << "PropagateRootDirectory.slotSubJobsFinished" << "emit finished" << status;
                emit finished (status);
            }
            return;
        }
    
        propagator ().scheduleNextJob ();
    }
    
    void PropagateRootDirectory.slotDirDeletionJobsFinished (SyncFileItem.Status status) {
        _state = Finished;
        qCInfo (lcPropagator) << "PropagateRootDirectory.slotDirDeletionJobsFinished" << "emit finished" << status;
        emit finished (status);
    }
    
    bool PropagateRootDirectory.scheduleDelayedJobs () {
        qCInfo (lcPropagator) << "PropagateRootDirectory.scheduleDelayedJobs";
        propagator ().setScheduleDelayedTasks (true);
        auto bulkPropagatorJob = std.make_unique<BulkPropagatorJob> (propagator (), propagator ().delayedTasks ());
        propagator ().clearDelayedTasks ();
        _subJobs.appendJob (bulkPropagatorJob.release ());
        _subJobs._state = Running;
        return _subJobs.scheduleSelfOrChild ();
    }
    
    // ================================================================================
    
    CleanupPollsJob.~CleanupPollsJob () = default;
    
    void CleanupPollsJob.start () {
        if (_pollInfos.empty ()) {
            emit finished ();
            deleteLater ();
            return;
        }
    
        auto info = _pollInfos.first ();
        _pollInfos.pop_front ();
        SyncFileItemPtr item (new SyncFileItem);
        item._file = info._file;
        item._modtime = info._modtime;
        item._size = info._fileSize;
        auto *job = new PollJob (_account, info._url, item, _journal, _localPath, this);
        connect (job, &PollJob.finishedSignal, this, &CleanupPollsJob.slotPollFinished);
        job.start ();
    }
    
    void CleanupPollsJob.slotPollFinished () {
        auto *job = qobject_cast<PollJob> (sender ());
        ASSERT (job);
        if (job._item._status == SyncFileItem.FatalError) {
            emit aborted (job._item._errorString);
            deleteLater ();
            return;
        } else if (job._item._status != SyncFileItem.Success) {
            qCWarning (lcCleanupPolls) << "There was an error with file " << job._item._file << job._item._errorString;
        } else {
            if (!OwncloudPropagator.staticUpdateMetadata (*job._item, _localPath, _vfs.data (), _journal)) {
                qCWarning (lcCleanupPolls) << "database error";
                job._item._status = SyncFileItem.FatalError;
                job._item._errorString = tr ("Error writing metadata to the database");
                emit aborted (job._item._errorString);
                deleteLater ();
                return;
            }
            _journal.setUploadInfo (job._item._file, SyncJournalDb.UploadInfo ());
        }
        // Continue with the next entry, or finish
        start ();
    }
    
    string OwncloudPropagator.fullRemotePath (string &tmp_file_name) {
        // TODO : should this be part of the _item (SyncFileItemPtr)?
        return _remoteFolder + tmp_file_name;
    }
    
    string OwncloudPropagator.remotePath () {
        return _remoteFolder;
    }
    
    }
    











namespace {

    /***********************************************************
    We do not want to upload files that are currently being modified.
    To avoid that, we don't upload files that have a modification time
    that is too close to the current time.
    
    This interacts with the msBetweenRequestAndSync delay in the fol
    manager. If that delay between file-change notification and sync
    has passed, we should accept the file for upload here.
    ***********************************************************/
    inline bool fileIsStillChanging (Occ.SyncFileItem &item) {
        const auto modtime = Occ.Utility.qDateTimeFromTime_t (item._modtime);
        const int64 msSinceMod = modtime.msecsTo (QDateTime.currentDateTimeUtc ());
    
        return std.chrono.milliseconds (msSinceMod) < Occ.SyncEngine.minimumFileAgeForUpload
            // if the mtime is too much in the future we *do* upload the file
            && msSinceMod > -10000;
    }
    
    }
    
    namespace Occ {
    
    inline QByteArray getEtagFromReply (QNetworkReply *reply) {
        QByteArray ocEtag = parseEtag (reply.rawHeader ("OC-ETag"));
        QByteArray etag = parseEtag (reply.rawHeader ("ETag"));
        QByteArray ret = ocEtag;
        if (ret.isEmpty ()) {
            ret = etag;
        }
        if (ocEtag.length () > 0 && ocEtag != etag) {
            qCDebug (lcPropagator) << "Quite peculiar, we have an etag != OC-Etag [no problem!]" << etag << ocEtag;
        }
        return ret;
    }
    
    /***********************************************************
    Given an error from the network, map to a SyncFileItem.Status error
    ***********************************************************/
    inline SyncFileItem.Status classifyError (QNetworkReply.NetworkError nerror,
        int httpCode, bool *anotherSyncNeeded = nullptr, QByteArray &errorBody = QByteArray ()) {
        Q_ASSERT (nerror != QNetworkReply.NoError); // we should only be called when there is an error
    
        if (nerror == QNetworkReply.RemoteHostClosedError) {
            // Sometimes server bugs lead to a connection close on certain files,
            // that shouldn't bring the rest of the syncing to a halt.
            return SyncFileItem.NormalError;
        }
    
        if (nerror > QNetworkReply.NoError && nerror <= QNetworkReply.UnknownProxyError) {
            // network error or proxy error . fatal
            return SyncFileItem.FatalError;
        }
    
        if (httpCode == 503) {
            // When the server is in maintenance mode, we want to exit the sync immediatly
            // so that we do not flood the server with many requests
            // BUG : This relies on a translated string and is thus unreliable.
            //      In the future it should return a NormalError and trigger a status.php
            //      check that detects maintenance mode reliably and will terminate the sync run.
            auto probablyMaintenance =
                    errorBody.contains (R" (>Sabre\DAV\Exception\ServiceUnavailable<)")
                    && !errorBody.contains ("Storage is temporarily not available");
            return probablyMaintenance ? SyncFileItem.FatalError : SyncFileItem.NormalError;
        }
    
        if (httpCode == 412) {
            // "Precondition Failed"
            // Happens when the e-tag has changed
            return SyncFileItem.SoftError;
        }
    
        if (httpCode == 423) {
            // "Locked"
            // Should be temporary.
            if (anotherSyncNeeded) {
                *anotherSyncNeeded = true;
            }
            return SyncFileItem.FileLocked;
        }
    
        return SyncFileItem.NormalError;
    }
    }
    