/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Object>
// #include <QMetaType>
// #include <QCoreApplication>

// #include <GLib.Object>
// #include <QHash>
// #include <QTime>
// #include <QQueue>
// #include <QElapsedTimer>
// #include <QTimer>

namespace Occ {

/***********************************************************
@brief The Progress_info class
@ingroup libsync
***********************************************************/
class Progress_info : GLib.Object {
public:
    Progress_info ();

    /***********************************************************
    Resets for a new sync run.
    ***********************************************************/
    void reset ();

    /***********************************************************
    Records the status of the sync run
    ***********************************************************/
    enum Status {
        /// Emitted once at start
        Starting,

        /***********************************************************
         * Emitted once without _current_discovered_folder when it starts,
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
         * Except when Sync_engine jumps directly to finalize () without going
         * through slot_propagation_finished ().
         */
        Done
    };

    Status status ();

    /***********************************************************
    Called when propagation starts.
    
    is_updating_estimates () will return true afterwards.
    ***********************************************************/
    void start_estimate_updates ();

    /***********************************************************
    Returns true when start_estimate_updates () was called.
    
    This is used when the Sync_engine wants to indicate a new sync
    is about to start via the transmission_progress () signal. The
    first Progress_info will have is_updating_estimates () == false.
    ***********************************************************/
    bool is_updating_estimates ();

    /***********************************************************
    Increase the file and size totals by the amount indicated in item.
    ***********************************************************/
    void adjust_totals_for_file (SyncFileItem &item);

    int64 total_files ();
    int64 completed_files ();

    int64 total_size ();
    int64 completed_size ();

    /***********************************************************
    Number of a file that is currently in progress. */
    int64 current_file ();

    /***********************************************************
    Return true if the size needs to be taken in account in the total amount of time */
    static inline bool is_size_dependent (SyncFileItem &item) {
        return !item.is_directory ()
            && (item._instruction == CSYNC_INSTRUCTION_CONFLICT
                || item._instruction == CSYNC_INSTRUCTION_SYNC
                || item._instruction == CSYNC_INSTRUCTION_NEW
                || item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE)
            && ! (item._type == Item_type_virtual_file
                 || item._type == ItemTypeVirtualFileDehydration);
    }

    /***********************************************************
    Holds estimates about progress, returned to the user.
    ***********************************************************/
    struct Estimates {
        /// Estimated completion amount per second. (of bytes or files)
        int64 estimated_bandwidth;

        /// Estimated time remaining in milliseconds.
        uint64 estimated_eta;
    };

    /***********************************************************
    Holds the current state of something making progress and maintains an
    estimate of the current progress per second.
    ***********************************************************/
    struct Progress {
        /** Returns the estimates about progress per second and eta. */
        Estimates estimates ();

        int64 completed ();
        int64 remaining ();

    private:
        /***********************************************************
         * Update the exponential moving average estimate of _progress_per_sec.
         */
        void update ();

        /***********************************************************
         * Changes the _completed value and does sanity checks on
         * _prev_completed and _total.
         */
        void set_completed (int64 completed);

        // Updated by update ()
        double _progress_per_sec = 0;
        int64 _prev_completed = 0;

        // Used to get to a good value faster when
        // progress measurement stats. See update ().
        double _initial_smoothing = 1.0;

        // Set and updated by Progress_info
        int64 _completed = 0;
        int64 _total = 0;

        friend class Progress_info;
    };

    Status _status;

    struct Progress_item {
        SyncFileItem _item;
        Progress _progress;
    };
    QHash<string, Progress_item> _current_items;

    SyncFileItem _last_completed_item;

    // Used during local and remote update phase
    string _current_discovered_remote_folder;
    string _current_discovered_local_folder;

    void set_progress_complete (SyncFileItem &item);

    void set_progress_item (SyncFileItem &item, int64 completed);

    /***********************************************************
    Get the total completion estimate
    ***********************************************************/
    Estimates total_progress ();

    /***********************************************************
    Get the optimistic eta.
    
    This value is based on the highest observed transfer bandwidth
    and files-per-second speed.
    ***********************************************************/
    uint64 optimistic_eta ();

    /***********************************************************
    Whether the remaining-time estimate is trusted.
    
    We don't trust it if it is hugely above the optimistic estimate.
    See #5046.
    ***********************************************************/
    bool trust_eta ();

    /***********************************************************
    Get the current file completion estimate structure
    ***********************************************************/
    Estimates file_progress (SyncFileItem &item) const;

private slots:
    /***********************************************************
    Called every second once started, this function updates the
    estimates.
    ***********************************************************/
    void update_estimates ();

private:
    // Sets the completed size by summing finished jobs with the progress
    // of active ones.
    void recompute_completed_size ();

    // Triggers the update () slot every second once propagation started.
    QTimer _update_estimates_timer;

    Progress _size_progress;
    Progress _file_progress;

    // All size from completed jobs only.
    int64 _total_size_of_completed_jobs;

    // The fastest observed rate of files per second in this sync.
    double _max_files_per_second;
    double _max_bytes_per_second;
};

namespace Progress {

    string as_action_string (SyncFileItem &item);
    string as_result_string (SyncFileItem &item);

    bool is_warning_kind (SyncFileItem.Status);
    bool is_ignored_kind (SyncFileItem.Status);
}

/***********************************************************
Type of error

Used for Progress_dispatcher.sync_error. May trigger error interactivity
in Issues_widget.
***********************************************************/
enum class Error_category {
    Normal,
    Insufficient_remote_storage,
};

/***********************************************************
@file progressdispatcher.h
@brief A singleton class to provide sync progress information to other gui classes.

How to use the Progress_dispatcher:
Just connect to the two signals either to progress for every individual file
or the overall sync progress.

***********************************************************/
class Progress_dispatcher : GLib.Object {

    friend class Folder; // only allow Folder class to access the setting slots.
public:
    static Progress_dispatcher *instance ();
    ~Progress_dispatcher () override;

signals:
    /***********************************************************
      @brief Signals the progress of data transmission.

      @param[out]  folder The folder which is being processed
      @param[out]  progress   A struct with all progress info.

    ***********************************************************/
    void progress_info (string &folder, Progress_info &progress);
    /***********************************************************
    @brief : the item was completed by a job
    ***********************************************************/
    void item_completed (string &folder, Sync_file_item_ptr &item);

    /***********************************************************
    @brief A new folder-wide sync error was seen.
    ***********************************************************/
    void sync_error (string &folder, string &message, Error_category category);

    /***********************************************************
    @brief Emitted when an error needs to be added into GUI
    @param[out] folder The folder which is being processed
    @param[out] status of the error
    @param[out] full error message
    @param[out] subject (optional)
    ***********************************************************/
    void add_error_to_gui (string &folder, SyncFileItem.Status status, string &error_message, string &subject);

    /***********************************************************
    @brief Emitted for a folder when a sync is done, listing all pending conflicts
    ***********************************************************/
    void folder_conflicts (string &folder, QStringList &conflict_paths);

protected:
    void set_progress_info (string &folder, Progress_info &progress);

private:
    Progress_dispatcher (GLib.Object *parent = nullptr);

    QElapsedTimer _timer;
    static Progress_dispatcher *_instance;
};

    Progress_dispatcher *Progress_dispatcher._instance = nullptr;
    
    string Progress.as_result_string (SyncFileItem &item) {
        switch (item._instruction) {
        case CSYNC_INSTRUCTION_SYNC:
        case CSYNC_INSTRUCTION_NEW:
        case CSYNC_INSTRUCTION_TYPE_CHANGE:
            if (item._direction != SyncFileItem.Up) {
                if (item._type == Item_type_virtual_file) {
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
            return QCoreApplication.translate ("progress", "Moved to %1").arg (item._rename_target);
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
    
    string Progress.as_action_string (SyncFileItem &item) {
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
    
    bool Progress.is_warning_kind (SyncFileItem.Status kind) {
        return kind == SyncFileItem.Soft_error || kind == SyncFileItem.Normal_error
            || kind == SyncFileItem.Fatal_error || kind == SyncFileItem.File_ignored
            || kind == SyncFileItem.Conflict || kind == SyncFileItem.Restoration
            || kind == SyncFileItem.Detail_error || kind == SyncFileItem.Blacklisted_error
            || kind == SyncFileItem.File_locked;
    }
    
    bool Progress.is_ignored_kind (SyncFileItem.Status kind) {
        return kind == SyncFileItem.File_ignored;
    }
    
    Progress_dispatcher *Progress_dispatcher.instance () {
        if (!_instance) {
            _instance = new Progress_dispatcher ();
        }
        return _instance;
    }
    
    Progress_dispatcher.Progress_dispatcher (GLib.Object *parent)
        : GLib.Object (parent) {
    }
    
    Progress_dispatcher.~Progress_dispatcher () = default;
    
    void Progress_dispatcher.set_progress_info (string &folder, Progress_info &progress) {
        if (folder.is_empty ())
        // The update phase now also has progress
        //            (progress._current_items.size () == 0
        //             && progress._total_file_count == 0) ) {
            return;
        }
        emit progress_info (folder, progress);
    }
    
    Progress_info.Progress_info () {
        connect (&_update_estimates_timer, &QTimer.timeout, this, &Progress_info.update_estimates);
        reset ();
    }
    
    void Progress_info.reset () {
        _status = Starting;
    
        _current_items.clear ();
        _current_discovered_remote_folder.clear ();
        _current_discovered_local_folder.clear ();
        _size_progress = Progress ();
        _file_progress = Progress ();
        _total_size_of_completed_jobs = 0;
    
        // Historically, these starting estimates were way lower, but that lead
        // to gross overestimation of ETA when a good estimate wasn't available.
        _max_bytes_per_second = 2000000.0; // 2 MB/s
        _max_files_per_second = 10.0;
    
        _update_estimates_timer.stop ();
        _last_completed_item = SyncFileItem ();
    }
    
    Progress_info.Status Progress_info.status () {
        return _status;
    }
    
    void Progress_info.start_estimate_updates () {
        _update_estimates_timer.start (1000);
    }
    
    bool Progress_info.is_updating_estimates () {
        return _update_estimates_timer.is_active ();
    }
    
    static bool should_count_progress (SyncFileItem &item) {
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
    
    void Progress_info.adjust_totals_for_file (SyncFileItem &item) {
        if (!should_count_progress (item)) {
            return;
        }
    
        _file_progress._total += item._affected_items;
        if (is_size_dependent (item)) {
            _size_progress._total += item._size;
        }
    }
    
    int64 Progress_info.total_files () {
        return _file_progress._total;
    }
    
    int64 Progress_info.completed_files () {
        return _file_progress._completed;
    }
    
    int64 Progress_info.current_file () {
        return completed_files () + _current_items.size ();
    }
    
    int64 Progress_info.total_size () {
        return _size_progress._total;
    }
    
    int64 Progress_info.completed_size () {
        return _size_progress._completed;
    }
    
    void Progress_info.set_progress_complete (SyncFileItem &item) {
        if (!should_count_progress (item)) {
            return;
        }
    
        _current_items.remove (item._file);
        _file_progress.set_completed (_file_progress._completed + item._affected_items);
        if (Progress_info.is_size_dependent (item)) {
            _total_size_of_completed_jobs += item._size;
        }
        recompute_completed_size ();
        _last_completed_item = item;
    }
    
    void Progress_info.set_progress_item (SyncFileItem &item, int64 completed) {
        if (!should_count_progress (item)) {
            return;
        }
    
        _current_items[item._file]._item = item;
        _current_items[item._file]._progress._total = item._size;
        _current_items[item._file]._progress.set_completed (completed);
        recompute_completed_size ();
    
        // This seems dubious!
        _last_completed_item = SyncFileItem ();
    }
    
    Progress_info.Estimates Progress_info.total_progress () {
        Estimates file = _file_progress.estimates ();
        if (_size_progress._total == 0) {
            return file;
        }
    
        Estimates size = _size_progress.estimates ();
    
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
        double fps = _file_progress._progress_per_sec;
        double fps_l = 0.5;
        double fps_u = 0.8;
        double near_max_fps =
            q_bound (0.0,
                (fps - fps_l * _max_files_per_second) / ( (fps_u - fps_l) * _max_files_per_second),
                1.0);
    
        // Compute a value that is 0 when transfer is >= U*max and
        // 1 when transfer is <= L*max
        double trans = _size_progress._progress_per_sec;
        double trans_u = 0.1;
        double trans_l = 0.01;
        double slow_transfer = 1.0 - q_bound (0.0,
                                        (trans - trans_l * _max_bytes_per_second) / ( (trans_u - trans_l) * _max_bytes_per_second),
                                        1.0);
    
        double be_optimistic = near_max_fps * slow_transfer;
        size.estimated_eta = uint64 ( (1.0 - be_optimistic) * size.estimated_eta
            + be_optimistic * optimistic_eta ());
    
        return size;
    }
    
    uint64 Progress_info.optimistic_eta () {
        // This assumes files and transfers finish as quickly as possible
        // *but* note that max_per_second could be serious underestimate
        // (if we never got to fully excercise transfer or files/second)
    
        return _file_progress.remaining () / _max_files_per_second * 1000
            + _size_progress.remaining () / _max_bytes_per_second * 1000;
    }
    
    bool Progress_info.trust_eta () {
        return total_progress ().estimated_eta < 100 * optimistic_eta ();
    }
    
    Progress_info.Estimates Progress_info.file_progress (SyncFileItem &item) {
        return _current_items[item._file]._progress.estimates ();
    }
    
    void Progress_info.update_estimates () {
        _size_progress.update ();
        _file_progress.update ();
    
        // Update progress of all running items.
        QMutable_hash_iterator<string, Progress_item> it (_current_items);
        while (it.has_next ()) {
            it.next ();
            it.value ()._progress.update ();
        }
    
        _max_files_per_second = q_max (_file_progress._progress_per_sec,
            _max_files_per_second);
        _max_bytes_per_second = q_max (_size_progress._progress_per_sec,
            _max_bytes_per_second);
    }
    
    void Progress_info.recompute_completed_size () {
        int64 r = _total_size_of_completed_jobs;
        foreach (Progress_item &i, _current_items) {
            if (is_size_dependent (i._item))
                r += i._progress._completed;
        }
        _size_progress.set_completed (r);
    }
    
    Progress_info.Estimates Progress_info.Progress.estimates () {
        Estimates est;
        est.estimated_bandwidth = _progress_per_sec;
        if (_progress_per_sec != 0) {
            est.estimated_eta = q_round64 (static_cast<double> (_total - _completed) / _progress_per_sec) * 1000;
        } else {
            est.estimated_eta = 0; // looks better than int64 max
        }
        return est;
    }
    
    int64 Progress_info.Progress.completed () {
        return _completed;
    }
    
    int64 Progress_info.Progress.remaining () {
        return _total - _completed;
    }
    
    void Progress_info.Progress.update () {
        // A good way to think about the smoothing factor:
        // If we make progress P per sec and then stop making progress at all,
        // after N calls to this function (and thus seconds) the _progress_per_sec
        // will have reduced to P*smoothing^N.
        // With a value of 0.9, only 4% of the original value is left after 30s
        //
        // In the first few updates we want to go to the correct value quickly.
        // Therefore, smoothing starts at 0 and ramps up to its final value over time.
        const double smoothing = 0.9 * (1.0 - _initial_smoothing);
        _initial_smoothing *= 0.7; // goes from 1 to 0.03 in 10s
        _progress_per_sec = smoothing * _progress_per_sec + (1.0 - smoothing) * static_cast<double> (_completed - _prev_completed);
        _prev_completed = _completed;
    }
    
    void Progress_info.Progress.set_completed (int64 completed) {
        _completed = q_min (completed, _total);
        _prev_completed = q_min (_prev_completed, _completed);
    }
    }
    