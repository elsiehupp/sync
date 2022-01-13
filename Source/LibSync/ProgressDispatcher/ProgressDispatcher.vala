/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Object>
// #include <QHash>
// #include <QTime>
// #include <QQueue>
// #include <QElapsedTimer>
// #include <QTimer>

namespace Occ {

/***********************************************************
@brief The ProgressInfo class
@ingroup libsync
***********************************************************/
class ProgressInfo : GLib.Object {
public:
    ProgressInfo ();

    /** Resets for a new sync run.
     */
    void reset ();

    /** Records the status of the sync run
     */
    enum Status {
        /// Emitted once at start
        Starting,

        /***********************************************************
         * Emitted once without _currentDiscoveredFolder when it starts,
         * then for each folder.
         */
        Discovery,

        /// Emitted once when reconcile starts
        Reconcile,

        /// Emitted during propagation, with progress data
        Propagation,

        /***********************************************************
         * Emitted once when done
         *
         * Except when SyncEngine jumps directly to finalize () without going
         * through slotPropagationFinished ().
         */
        Done
    };

    Status status ();

    /***********************************************************
     * Called when propagation starts.
     *
     * isUpdatingEstimates () will return true afterwards.
     */
    void startEstimateUpdates ();

    /***********************************************************
     * Returns true when startEstimateUpdates () was called.
     *
     * This is used when the SyncEngine wants to indicate a new sync
     * is about to start via the transmissionProgress () signal. The
     * first ProgressInfo will have isUpdatingEstimates () == false.
     */
    bool isUpdatingEstimates ();

    /***********************************************************
     * Increase the file and size totals by the amount indicated in item.
     */
    void adjustTotalsForFile (SyncFileItem &item);

    int64 totalFiles ();
    int64 completedFiles ();

    int64 totalSize ();
    int64 completedSize ();

    /** Number of a file that is currently in progress. */
    int64 currentFile ();

    /** Return true if the size needs to be taken in account in the total amount of time */
    static inline bool isSizeDependent (SyncFileItem &item) {
        return !item.isDirectory ()
            && (item._instruction == CSYNC_INSTRUCTION_CONFLICT
                || item._instruction == CSYNC_INSTRUCTION_SYNC
                || item._instruction == CSYNC_INSTRUCTION_NEW
                || item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE)
            && ! (item._type == ItemTypeVirtualFile
                 || item._type == ItemTypeVirtualFileDehydration);
    }

    /***********************************************************
     * Holds estimates about progress, returned to the user.
     */
    struct Estimates {
        /// Estimated completion amount per second. (of bytes or files)
        int64 estimatedBandwidth;

        /// Estimated time remaining in milliseconds.
        uint64 estimatedEta;
    };

    /***********************************************************
     * Holds the current state of something making progress and maintains an
     * estimate of the current progress per second.
     */
    struct Progress {
        /** Returns the estimates about progress per second and eta. */
        Estimates estimates ();

        int64 completed ();
        int64 remaining ();

    private:
        /***********************************************************
         * Update the exponential moving average estimate of _progressPerSec.
         */
        void update ();

        /***********************************************************
         * Changes the _completed value and does sanity checks on
         * _prevCompleted and _total.
         */
        void setCompleted (int64 completed);

        // Updated by update ()
        double _progressPerSec = 0;
        int64 _prevCompleted = 0;

        // Used to get to a good value faster when
        // progress measurement stats. See update ().
        double _initialSmoothing = 1.0;

        // Set and updated by ProgressInfo
        int64 _completed = 0;
        int64 _total = 0;

        friend class ProgressInfo;
    };

    Status _status;

    struct ProgressItem {
        SyncFileItem _item;
        Progress _progress;
    };
    QHash<string, ProgressItem> _currentItems;

    SyncFileItem _lastCompletedItem;

    // Used during local and remote update phase
    string _currentDiscoveredRemoteFolder;
    string _currentDiscoveredLocalFolder;

    void setProgressComplete (SyncFileItem &item);

    void setProgressItem (SyncFileItem &item, int64 completed);

    /***********************************************************
     * Get the total completion estimate
     */
    Estimates totalProgress ();

    /***********************************************************
     * Get the optimistic eta.
     *
     * This value is based on the highest observed transfer bandwidth
     * and files-per-second speed.
     */
    uint64 optimisticEta ();

    /***********************************************************
     * Whether the remaining-time estimate is trusted.
     *
     * We don't trust it if it is hugely above the optimistic estimate.
     * See #5046.
     */
    bool trustEta ();

    /***********************************************************
     * Get the current file completion estimate structure
     */
    Estimates fileProgress (SyncFileItem &item) const;

private slots:
    /***********************************************************
     * Called every second once started, this function updates the
     * estimates.
     */
    void updateEstimates ();

private:
    // Sets the completed size by summing finished jobs with the progress
    // of active ones.
    void recomputeCompletedSize ();

    // Triggers the update () slot every second once propagation started.
    QTimer _updateEstimatesTimer;

    Progress _sizeProgress;
    Progress _fileProgress;

    // All size from completed jobs only.
    int64 _totalSizeOfCompletedJobs;

    // The fastest observed rate of files per second in this sync.
    double _maxFilesPerSecond;
    double _maxBytesPerSecond;
};

namespace Progress {

    string asActionString (SyncFileItem &item);
    string asResultString (SyncFileItem &item);

    bool isWarningKind (SyncFileItem.Status);
    bool isIgnoredKind (SyncFileItem.Status);
}

/** Type of error

Used for ProgressDispatcher.syncError. May trigger error interactivity
in IssuesWidget.
***********************************************************/
enum class ErrorCategory {
    Normal,
    InsufficientRemoteStorage,
};

/***********************************************************
@file progressdispatcher.h
@brief A singleton class to provide sync progress information to other gui classes.

How to use the ProgressDispatcher:
Just connect to the two signals either to progress for every individual file
or the overall sync progress.

***********************************************************/
class ProgressDispatcher : GLib.Object {

    friend class Folder; // only allow Folder class to access the setting slots.
public:
    static ProgressDispatcher *instance ();
    ~ProgressDispatcher () override;

signals:
    /***********************************************************
      @brief Signals the progress of data transmission.

      @param[out]  folder The folder which is being processed
      @param[out]  progress   A struct with all progress info.

     */
    void progressInfo (string &folder, ProgressInfo &progress);
    /***********************************************************
     * @brief : the item was completed by a job
     */
    void itemCompleted (string &folder, SyncFileItemPtr &item);

    /***********************************************************
     * @brief A new folder-wide sync error was seen.
     */
    void syncError (string &folder, string &message, ErrorCategory category);

    /***********************************************************
     * @brief Emitted when an error needs to be added into GUI
     * @param[out] folder The folder which is being processed
     * @param[out] status of the error
     * @param[out] full error message
     * @param[out] subject (optional)
     */
    void addErrorToGui (string &folder, SyncFileItem.Status status, string &errorMessage, string &subject);

    /***********************************************************
     * @brief Emitted for a folder when a sync is done, listing all pending conflicts
     */
    void folderConflicts (string &folder, QStringList &conflictPaths);

protected:
    void setProgressInfo (string &folder, ProgressInfo &progress);

private:
    ProgressDispatcher (GLib.Object *parent = nullptr);

    QElapsedTimer _timer;
    static ProgressDispatcher *_instance;
};
}












/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Object>
// #include <QMetaType>
// #include <QCoreApplication>

namespace Occ {

    ProgressDispatcher *ProgressDispatcher._instance = nullptr;
    
    string Progress.asResultString (SyncFileItem &item) {
        switch (item._instruction) {
        case CSYNC_INSTRUCTION_SYNC:
        case CSYNC_INSTRUCTION_NEW:
        case CSYNC_INSTRUCTION_TYPE_CHANGE:
            if (item._direction != SyncFileItem.Up) {
                if (item._type == ItemTypeVirtualFile) {
                    return QCoreApplication.translate ("progress", "Virtual file created");
                } else if (item._type == ItemTypeVirtualFileDehydration) {
                    return QCoreApplication.translate ("progress", "Replaced by virtual file");
                } else {
                    return QCoreApplication.translate ("progress", "Downloaded");
                }
            } else {
                return QCoreApplication.translate ("progress", "Uploaded");
            }
        case CSYNC_INSTRUCTION_CONFLICT:
            return QCoreApplication.translate ("progress", "Server version downloaded, copied changed local file into conflict file");
        case CSYNC_INSTRUCTION_REMOVE:
            return QCoreApplication.translate ("progress", "Deleted");
        case CSYNC_INSTRUCTION_EVAL_RENAME:
        case CSYNC_INSTRUCTION_RENAME:
            return QCoreApplication.translate ("progress", "Moved to %1").arg (item._renameTarget);
        case CSYNC_INSTRUCTION_IGNORE:
            return QCoreApplication.translate ("progress", "Ignored");
        case CSYNC_INSTRUCTION_STAT_ERROR:
            return QCoreApplication.translate ("progress", "Filesystem access error");
        case CSYNC_INSTRUCTION_ERROR:
            return QCoreApplication.translate ("progress", "Error");
        case CSYNC_INSTRUCTION_UPDATE_METADATA:
            return QCoreApplication.translate ("progress", "Updated local metadata");
        case CSYNC_INSTRUCTION_NONE:
        case CSYNC_INSTRUCTION_EVAL:
            return QCoreApplication.translate ("progress", "Unknown");
        }
        return QCoreApplication.translate ("progress", "Unknown");
    }
    
    string Progress.asActionString (SyncFileItem &item) {
        switch (item._instruction) {
        case CSYNC_INSTRUCTION_CONFLICT:
        case CSYNC_INSTRUCTION_SYNC:
        case CSYNC_INSTRUCTION_NEW:
        case CSYNC_INSTRUCTION_TYPE_CHANGE:
            if (item._direction != SyncFileItem.Up)
                return QCoreApplication.translate ("progress", "downloading");
            else
                return QCoreApplication.translate ("progress", "uploading");
        case CSYNC_INSTRUCTION_REMOVE:
            return QCoreApplication.translate ("progress", "deleting");
        case CSYNC_INSTRUCTION_EVAL_RENAME:
        case CSYNC_INSTRUCTION_RENAME:
            return QCoreApplication.translate ("progress", "moving");
        case CSYNC_INSTRUCTION_IGNORE:
            return QCoreApplication.translate ("progress", "ignoring");
        case CSYNC_INSTRUCTION_STAT_ERROR:
        case CSYNC_INSTRUCTION_ERROR:
            return QCoreApplication.translate ("progress", "error");
        case CSYNC_INSTRUCTION_UPDATE_METADATA:
            return QCoreApplication.translate ("progress", "updating local metadata");
        case CSYNC_INSTRUCTION_NONE:
        case CSYNC_INSTRUCTION_EVAL:
            break;
        }
        return string ();
    }
    
    bool Progress.isWarningKind (SyncFileItem.Status kind) {
        return kind == SyncFileItem.SoftError || kind == SyncFileItem.NormalError
            || kind == SyncFileItem.FatalError || kind == SyncFileItem.FileIgnored
            || kind == SyncFileItem.Conflict || kind == SyncFileItem.Restoration
            || kind == SyncFileItem.DetailError || kind == SyncFileItem.BlacklistedError
            || kind == SyncFileItem.FileLocked;
    }
    
    bool Progress.isIgnoredKind (SyncFileItem.Status kind) {
        return kind == SyncFileItem.FileIgnored;
    }
    
    ProgressDispatcher *ProgressDispatcher.instance () {
        if (!_instance) {
            _instance = new ProgressDispatcher ();
        }
        return _instance;
    }
    
    ProgressDispatcher.ProgressDispatcher (GLib.Object *parent)
        : GLib.Object (parent) {
    }
    
    ProgressDispatcher.~ProgressDispatcher () = default;
    
    void ProgressDispatcher.setProgressInfo (string &folder, ProgressInfo &progress) {
        if (folder.isEmpty ())
        // The update phase now also has progress
        //            (progress._currentItems.size () == 0
        //             && progress._totalFileCount == 0) ) {
            return;
        }
        emit progressInfo (folder, progress);
    }
    
    ProgressInfo.ProgressInfo () {
        connect (&_updateEstimatesTimer, &QTimer.timeout, this, &ProgressInfo.updateEstimates);
        reset ();
    }
    
    void ProgressInfo.reset () {
        _status = Starting;
    
        _currentItems.clear ();
        _currentDiscoveredRemoteFolder.clear ();
        _currentDiscoveredLocalFolder.clear ();
        _sizeProgress = Progress ();
        _fileProgress = Progress ();
        _totalSizeOfCompletedJobs = 0;
    
        // Historically, these starting estimates were way lower, but that lead
        // to gross overestimation of ETA when a good estimate wasn't available.
        _maxBytesPerSecond = 2000000.0; // 2 MB/s
        _maxFilesPerSecond = 10.0;
    
        _updateEstimatesTimer.stop ();
        _lastCompletedItem = SyncFileItem ();
    }
    
    ProgressInfo.Status ProgressInfo.status () {
        return _status;
    }
    
    void ProgressInfo.startEstimateUpdates () {
        _updateEstimatesTimer.start (1000);
    }
    
    bool ProgressInfo.isUpdatingEstimates () {
        return _updateEstimatesTimer.isActive ();
    }
    
    static bool shouldCountProgress (SyncFileItem &item) {
        const auto instruction = item._instruction;
    
        // Skip any ignored, error or non-propagated files and directories.
        if (instruction == CSYNC_INSTRUCTION_NONE
            || instruction == CSYNC_INSTRUCTION_UPDATE_METADATA
            || instruction == CSYNC_INSTRUCTION_IGNORE
            || instruction == CSYNC_INSTRUCTION_ERROR) {
            return false;
        }
    
        return true;
    }
    
    void ProgressInfo.adjustTotalsForFile (SyncFileItem &item) {
        if (!shouldCountProgress (item)) {
            return;
        }
    
        _fileProgress._total += item._affectedItems;
        if (isSizeDependent (item)) {
            _sizeProgress._total += item._size;
        }
    }
    
    int64 ProgressInfo.totalFiles () {
        return _fileProgress._total;
    }
    
    int64 ProgressInfo.completedFiles () {
        return _fileProgress._completed;
    }
    
    int64 ProgressInfo.currentFile () {
        return completedFiles () + _currentItems.size ();
    }
    
    int64 ProgressInfo.totalSize () {
        return _sizeProgress._total;
    }
    
    int64 ProgressInfo.completedSize () {
        return _sizeProgress._completed;
    }
    
    void ProgressInfo.setProgressComplete (SyncFileItem &item) {
        if (!shouldCountProgress (item)) {
            return;
        }
    
        _currentItems.remove (item._file);
        _fileProgress.setCompleted (_fileProgress._completed + item._affectedItems);
        if (ProgressInfo.isSizeDependent (item)) {
            _totalSizeOfCompletedJobs += item._size;
        }
        recomputeCompletedSize ();
        _lastCompletedItem = item;
    }
    
    void ProgressInfo.setProgressItem (SyncFileItem &item, int64 completed) {
        if (!shouldCountProgress (item)) {
            return;
        }
    
        _currentItems[item._file]._item = item;
        _currentItems[item._file]._progress._total = item._size;
        _currentItems[item._file]._progress.setCompleted (completed);
        recomputeCompletedSize ();
    
        // This seems dubious!
        _lastCompletedItem = SyncFileItem ();
    }
    
    ProgressInfo.Estimates ProgressInfo.totalProgress () {
        Estimates file = _fileProgress.estimates ();
        if (_sizeProgress._total == 0) {
            return file;
        }
    
        Estimates size = _sizeProgress.estimates ();
    
        // Ideally the remaining time would be modeled as:
        //   remaning_file_sizes / transfer_speed
        //   + remaining_file_count * per_file_overhead
        //   + remaining_chunked_file_sizes / chunked_reassembly_speed
        // with us estimating the three parameters in conjunction.
        //
        // But we currently only model the bandwidth and the files per
        // second independently, which leads to incorrect values. To slightly
        // mitigate this problem, we combine the two models depending on
        // which factor dominates (essentially big-file-upload vs.
        // many-small-files)
        //
        // If we have size information, we prefer an estimate based
        // on the upload speed. That's particularly relevant for large file
        // up/downloads, where files per second will be close to 0.
        //
        // However, when many *small* files are transfered, the estimate
        // can become very pessimistic as the transfered amount per second
        // drops significantly.
        //
        // So, if we detect a high rate of files per second or a very low
        // transfer rate (often drops hugely during a sequence of deletes,
        // for instance), we gradually prefer an optimistic estimate and
        // assume the remaining transfer will be done with the highest speed
        // we've seen.
    
        // Compute a value that is 0 when fps is <=L*max and 1 when fps is >=U*max
        double fps = _fileProgress._progressPerSec;
        double fpsL = 0.5;
        double fpsU = 0.8;
        double nearMaxFps =
            qBound (0.0,
                (fps - fpsL * _maxFilesPerSecond) / ( (fpsU - fpsL) * _maxFilesPerSecond),
                1.0);
    
        // Compute a value that is 0 when transfer is >= U*max and
        // 1 when transfer is <= L*max
        double trans = _sizeProgress._progressPerSec;
        double transU = 0.1;
        double transL = 0.01;
        double slowTransfer = 1.0 - qBound (0.0,
                                        (trans - transL * _maxBytesPerSecond) / ( (transU - transL) * _maxBytesPerSecond),
                                        1.0);
    
        double beOptimistic = nearMaxFps * slowTransfer;
        size.estimatedEta = uint64 ( (1.0 - beOptimistic) * size.estimatedEta
            + beOptimistic * optimisticEta ());
    
        return size;
    }
    
    uint64 ProgressInfo.optimisticEta () {
        // This assumes files and transfers finish as quickly as possible
        // *but* note that maxPerSecond could be serious underestimate
        // (if we never got to fully excercise transfer or files/second)
    
        return _fileProgress.remaining () / _maxFilesPerSecond * 1000
            + _sizeProgress.remaining () / _maxBytesPerSecond * 1000;
    }
    
    bool ProgressInfo.trustEta () {
        return totalProgress ().estimatedEta < 100 * optimisticEta ();
    }
    
    ProgressInfo.Estimates ProgressInfo.fileProgress (SyncFileItem &item) {
        return _currentItems[item._file]._progress.estimates ();
    }
    
    void ProgressInfo.updateEstimates () {
        _sizeProgress.update ();
        _fileProgress.update ();
    
        // Update progress of all running items.
        QMutableHashIterator<string, ProgressItem> it (_currentItems);
        while (it.hasNext ()) {
            it.next ();
            it.value ()._progress.update ();
        }
    
        _maxFilesPerSecond = qMax (_fileProgress._progressPerSec,
            _maxFilesPerSecond);
        _maxBytesPerSecond = qMax (_sizeProgress._progressPerSec,
            _maxBytesPerSecond);
    }
    
    void ProgressInfo.recomputeCompletedSize () {
        int64 r = _totalSizeOfCompletedJobs;
        foreach (ProgressItem &i, _currentItems) {
            if (isSizeDependent (i._item))
                r += i._progress._completed;
        }
        _sizeProgress.setCompleted (r);
    }
    
    ProgressInfo.Estimates ProgressInfo.Progress.estimates () {
        Estimates est;
        est.estimatedBandwidth = _progressPerSec;
        if (_progressPerSec != 0) {
            est.estimatedEta = qRound64 (static_cast<double> (_total - _completed) / _progressPerSec) * 1000;
        } else {
            est.estimatedEta = 0; // looks better than int64 max
        }
        return est;
    }
    
    int64 ProgressInfo.Progress.completed () {
        return _completed;
    }
    
    int64 ProgressInfo.Progress.remaining () {
        return _total - _completed;
    }
    
    void ProgressInfo.Progress.update () {
        // A good way to think about the smoothing factor:
        // If we make progress P per sec and then stop making progress at all,
        // after N calls to this function (and thus seconds) the _progressPerSec
        // will have reduced to P*smoothing^N.
        // With a value of 0.9, only 4% of the original value is left after 30s
        //
        // In the first few updates we want to go to the correct value quickly.
        // Therefore, smoothing starts at 0 and ramps up to its final value over time.
        const double smoothing = 0.9 * (1.0 - _initialSmoothing);
        _initialSmoothing *= 0.7; // goes from 1 to 0.03 in 10s
        _progressPerSec = smoothing * _progressPerSec + (1.0 - smoothing) * static_cast<double> (_completed - _prevCompleted);
        _prevCompleted = _completed;
    }
    
    void ProgressInfo.Progress.setCompleted (int64 completed) {
        _completed = qMin (completed, _total);
        _prevCompleted = qMin (_prevCompleted, _completed);
    }
    }
    