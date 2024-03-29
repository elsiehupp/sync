namespace Occ {
namespace LibSync {
namespace Progress {

/***********************************************************
@brief The ProgressInfo class

@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class ProgressInfo { //: GLib.Object {

    /***********************************************************
    Records the status of the sync run
    ***********************************************************/
    public enum Status {
        /***********************************************************
        Emitted once at start
        ***********************************************************/
        STARTING,

        /***********************************************************
        Emitted once without this.current_discovered_folder when it starts,
        then for each folder.
        ***********************************************************/
        DISCOVERY,

        /***********************************************************
        Emitted once when reconcile starts
        ***********************************************************/
        RECONCILE,

        /***********************************************************
        Emitted during propagation, with progress data
        ***********************************************************/
        PROPAGATION,

        /***********************************************************
        Emitted once when done

        Except when SyncEngine jumps directly to on_signal_finalize () without going
        through on_signal_propagation_finished ().
        ***********************************************************/
        DONE;


        static string as_action_string (SyncFileItem item) {
            switch (item.instruction) {
            case CSync.SyncInstructions.CONFLICT:
            case CSync.SyncInstructions.SYNC:
            case CSync.SyncInstructions.NEW:
            case CSync.SyncInstructions.TYPE_CHANGE:
                if (item.direction != SyncFileItem.Direction.UP)
                    return _(/*"progress",*/ "downloading");
                else
                    return _(/*"progress",*/ "uploading");
            case CSync.SyncInstructions.REMOVE:
                return _(/*"progress",*/ "deleting");
            case CSync.SyncInstructions.EVAL_RENAME:
            case CSync.SyncInstructions.RENAME:
                return _(/*"progress",*/ "moving");
            case CSync.SyncInstructions.IGNORE:
                return _(/*"progress",*/ "ignoring");
            case CSync.SyncInstructions.STAT_ERROR:
            case CSync.SyncInstructions.ERROR:
                return _(/*"progress",*/ "error");
            case CSync.SyncInstructions.UPDATE_METADATA:
                return _(/*"progress",*/ "updating local metadata");
            case CSync.SyncInstructions.NONE:
            case CSync.SyncInstructions.EVAL:
                break;
            }
            return "";
        }


        static string as_result_string (SyncFileItem item) {
            switch (item.instruction) {
            case CSync.SyncInstructions.SYNC:
            case CSync.SyncInstructions.NEW:
            case CSync.SyncInstructions.TYPE_CHANGE:
                if (item.direction != SyncFileItem.Direction.UP) {
                    if (item.type == ItemType.VIRTUAL_FILE) {
                        return _(/*"progress",*/ "Virtual file created");
                    } else if (item.type == ItemType.VIRTUAL_FILE_DEHYDRATION) {
                        return _(/*"progress",*/ "Replaced by virtual file");
                    } else {
                        return _(/*"progress",*/ "Downloaded");
                    }
                } else {
                    return _(/*"progress",*/ "Uploaded");
                }
            case CSync.SyncInstructions.CONFLICT:
                return _(/*"progress",*/ "Server version downloaded, copied changed local file into conflict file");
            case CSync.SyncInstructions.REMOVE:
                return _(/*"progress",*/ "Deleted");
            case CSync.SyncInstructions.EVAL_RENAME:
            case CSync.SyncInstructions.RENAME:
                return _(/*"progress",*/ "Moved to %1").printf (item.rename_target);
            case CSync.SyncInstructions.IGNORE:
                return _(/*"progress",*/ "Ignored");
            case CSync.SyncInstructions.STAT_ERROR:
                return _(/*"progress",*/ "Filesystem access error");
            case CSync.SyncInstructions.ERROR:
                return _(/*"progress",*/ "Error");
            case CSync.SyncInstructions.UPDATE_METADATA:
                return _(/*"progress",*/ "Updated local metadata");
            case CSync.SyncInstructions.NONE:
            case CSync.SyncInstructions.EVAL:
                return _(/*"progress",*/ "Unknown");
            }
            return _(/*"progress",*/ "Unknown");
        }


        public static bool is_warning_kind (SyncFileItem.Status kind) {
            return kind == SyncFileItem.Status.SOFT_ERROR || kind == SyncFileItem.Status.NORMAL_ERROR
                || kind == SyncFileItem.Status.FATAL_ERROR || kind == SyncFileItem.Status.FILE_IGNORED
                || kind == SyncFileItem.Status.CONFLICT || kind == SyncFileItem.Status.RESTORATION
                || kind == SyncFileItem.Status.DETAIL_ERROR || kind == SyncFileItem.Status.BLOCKLISTED_ERROR
                || kind == SyncFileItem.Status.FILE_LOCKED;
        }


        public static bool is_ignored_kind (SyncFileItem.Status kind) {
            return kind == SyncFileItem.Status.FILE_IGNORED;
        }
    }


    /***********************************************************
    Holds estimates about progress, returned to the user.
    ***********************************************************/
    public class Estimates {
        /***********************************************************
        Estimated completion amount per second. (of bytes or files)
        ***********************************************************/
        public int64 estimated_bandwidth;

        /***********************************************************
        Estimated time remaining in milliseconds.
        ***********************************************************/
        public uint64 estimated_eta;
    }


    /***********************************************************
    Holds the current state of something making progress and maintains an
    estimate of the current progress per second.
    ***********************************************************/
    public class Progress { //: GLib.Object {

        //  /***********************************************************
        //  Updated by update ()
        //  ***********************************************************/
        //  public double progress_per_sec = 0;

        //  /***********************************************************
        //  Updated by update ()
        //  ***********************************************************/
        //  private int64 prev_completed = 0;

        //  /***********************************************************
        //  Used to get to a good value faster when progress measurement
        //  stats. See update ().
        //  ***********************************************************/
        //  private double initial_smoothing = 1.0;

        //  /***********************************************************
        //  Set and updated by ProgressInfo
        //  ***********************************************************/
        //  public int64 completed {
        //      public get {
        //          return this.completed; // = 0
        //      }
        //      /***********************************************************
        //      Changes the this.completed value and does sanity checks on
        //      this.prev_completed and this.total.
        //      ***********************************************************/
        //      internal set {
        //          this.completed = int64.min (value, this.total);
        //          this.prev_completed = int64.min (this.prev_completed, this.completed);
        //      }
        //  }

        //  /***********************************************************
        //  Set and updated by ProgressInfo
        //  ***********************************************************/
        //  public int64 total = 0;

        //  /***********************************************************
        //  Returns the estimates about progress per second and eta.
        //  ***********************************************************/
        //  public Estimates estimates {
        //      public get {
        //          Estimates est;
        //          est.estimated_bandwidth = (int64)this.progress_per_sec;
        //          if (this.progress_per_sec != 0) {
        //              est.estimated_eta = GLib.Math.llrint ((double)(this.total - this.completed) / this.progress_per_sec) * 1000;
        //          } else {
        //              est.estimated_eta = 0; // looks better than int64 max
        //          }
        //          return est;
        //      }
        //  }


        //  /***********************************************************
        //  ***********************************************************/
        //  public int64 remaining {
        //      public get {
        //          return this.total - this.completed;
        //      }
        //  }


        //  /***********************************************************
        //  Update the exponential moving average estimate of
        //  this.progress_per_sec.
        //  ***********************************************************/
        //  public void update () {
        //      // A good way to think about the smoothing factor:
        //      // If we make progress P per sec and then stop making progress at all,
        //      // after N calls to this function (and thus seconds) the this.progress_per_sec
        //      // will have reduced to P*smoothing^N.
        //      // With a value of 0.9, only 4% of the original value is left after 30s
        //      //  
        //      // In the first few updates we want to go to the correct value quickly.
        //      // Therefore, smoothing starts at 0 and ramps up to its final value over time.
        //      double smoothing = 0.9 * (1.0 - this.initial_smoothing);
        //      this.initial_smoothing *= 0.7; // goes from 1 to 0.03 in 10s
        //      this.progress_per_sec = smoothing * this.progress_per_sec + (1.0 - smoothing) * (double) (this.completed - this.prev_completed);
        //      this.prev_completed = this.completed;
        //  }

    }


    /***********************************************************
    ***********************************************************/
    class ProgressItem {
        //  SyncFileItem item;
        //  Progress progress;
    }


    /***********************************************************
    ***********************************************************/
    Status status;

    /***********************************************************
    Triggers the update () slot every second once propagation
    started.
    ***********************************************************/
    private GLib.Timeout update_estimates_timer;

    /***********************************************************
    ***********************************************************/
    private Progress size_progress;
    private Progress file_progress;

    /***********************************************************
    All size from completed jobs only.
    ***********************************************************/
    private int64 total_size_of_completed_jobs;

    /***********************************************************
    The fastest observed rate of files per second in this sync.
    ***********************************************************/
    private double max_files_per_second;

    /***********************************************************
    The fastest observed rate of files per second in this sync.
    ***********************************************************/
    private double max_bytes_per_second;

    /***********************************************************
    ***********************************************************/
    GLib.HashTable<string, ProgressItem?> current_items;

    /***********************************************************
    ***********************************************************/
    SyncFileItem last_completed_item;

    /***********************************************************
    Used during local and remote update phase
    ***********************************************************/
    string current_discovered_remote_folder;

    /***********************************************************
    Used during local and remote update phase
    ***********************************************************/
    string current_discovered_local_folder;


    /***********************************************************
    ***********************************************************/
    public ProgressInfo () {
        //  this.update_estimates_timer.timeout.connect (
        //      this.on_signal_update_estimates_timer_timeout
        //  );
        //  this.reset ();
    }


    /***********************************************************
    Resets for a new sync run.
    ***********************************************************/
    public void reset () {
        //  this.status = Status.STARTING;

        //  this.current_items = new GLib.HashTable<string, ProgressItem?> ();
        //  this.current_discovered_remote_folder = "";
        //  this.current_discovered_local_folder = "";
        //  this.size_progress = new Progress ();
        //  this.file_progress = new Progress ();
        //  this.total_size_of_completed_jobs = 0;

        //  // Historically, these starting estimates were way lower, but that lead
        //  // to gross overestimation of ETA when a good estimate wasn't available.
        //  this.max_bytes_per_second = 2000000.0; // 2 MB/s
        //  this.max_files_per_second = 10.0;

        //  this.update_estimates_timer.stop ();
        //  this.last_completed_item = new SyncFileItem ();
    }




    /***********************************************************
    Called when propagation starts.

    is_updating_estimates () will return true afterwards.
    ***********************************************************/
    public void start_estimate_updates () {
        //  this.update_estimates_timer.start (1000);
    }


    /***********************************************************
    Returns true when start_estimate_updates () was called.

    This is used when the SyncEngine wants to indicate a new sync
    is about to start via the signal_transmission_progress () signal. The
    first ProgressInfo will have is_updating_estimates () == false.
    ***********************************************************/
    public bool is_updating_estimates () {
        //  return this.update_estimates_timer.is_active ();
    }


    /***********************************************************
    Increase the file and size totals by the amount indicated
    in item.
    ***********************************************************/
    public void adjust_totals_for_file (SyncFileItem item) {
        //  if (!should_count_progress (item)) {
        //      return;
        //  }

        //  this.file_progress.total += item.affected_items;
        //  if (is_size_dependent (item)) {
        //      this.size_progress.total += item.size;
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public int64 total_files () {
        //  return this.file_progress.total;
    }


    /***********************************************************
    ***********************************************************/
    public int64 completed_files () {
        //  return this.file_progress.completed;
    }


    /***********************************************************
    ***********************************************************/
    public int64 total_size () {
        //  return this.size_progress.total;
    }


    /***********************************************************
    ***********************************************************/
    public int64 completed_size () {
        //  return this.size_progress.completed;
    }


    /***********************************************************
    Number of a file that is currently in progress.
    ***********************************************************/
    public int64 current_file () {
        //  return completed_files () + this.current_items.size ();
    }


    /***********************************************************
    Return true if the size needs to be taken in account in the
    total amount of time
    ***********************************************************/
    public static inline bool is_size_dependent (SyncFileItem item) {
        //  return !item.is_directory
        //      && (item.instruction == CSync.SyncInstructions.CONFLICT
        //          || item.instruction == CSync.SyncInstructions.SYNC
        //          || item.instruction == CSync.SyncInstructions.NEW
        //          || item.instruction == CSync.SyncInstructions.TYPE_CHANGE)
        //      && ! (item.type == ItemType.VIRTUAL_FILE
        //           || item.type == ItemType.VIRTUAL_FILE_DEHYDRATION);
    }


    /***********************************************************
    ***********************************************************/
    void progress_complete (SyncFileItem item) {
        //  if (!should_count_progress (item)) {
        //      return;
        //  }

        //  this.current_items.remove (item.file);
        //  this.file_progress.completed = this.file_progress.completed + item.affected_items;
        //  if (ProgressInfo.is_size_dependent (item)) {
        //      this.total_size_of_completed_jobs += item.size;
        //  }
        //  this.recompute_completed_size ();
        //  this.last_completed_item = item;
    }


    /***********************************************************
    ***********************************************************/
    void progress_item (SyncFileItem item, int64 completed) {
        //  if (!this.should_count_progress (item)) {
        //      return;
        //  }

        //  this.current_items[item.file].item = item;
        //  this.current_items[item.file].progress.total = item.size;
        //  this.current_items[item.file].progress.completed = completed;
        //  this.recompute_completed_size ();

        //  // This seems dubious!
        //  this.last_completed_item = new SyncFileItem ();
    }


    /***********************************************************
    Get the total completion estimate
    ***********************************************************/
    Estimates total_progress () {
        //  Estimates file = this.file_progress.estimates;
        //  if (this.size_progress.total == 0) {
        //      return file;
        //  }

        //  Estimates size = this.size_progress.estimates;

        //  // Ideally the remaining time would be modeled as:
        //  //   remaning_file_sizes / transfer_speed
        //  //   + remaining_file_count * per_file_overhead
        //  //   + remaining_chunked_file_sizes / chunked_reassembly_speed
        //  // with us estimating the three parameters in conjunction.
        //  //  
        //  // But we currently only model the bandwidth and the files per
        //  // second independently, which leads to incorrect values. To slightly
        //  // mitigate this problem, we combine the two models depending on
        //  // which factor dominates (essentially big-file-upload vs.
        //  // many-small-files)
        //  //  
        //  // If we have size information, we prefer an estimate based
        //  // on the upload speed. That's particularly relevant for large file
        //  // up/downloads, where files per second will be close to 0.
        //  //  
        //  // However, when many small* files are transfered, the estimate
        //  // can become very pessimistic as the transfered amount per second
        //  // drops significantly.
        //  //  
        //  // So, if we detect a high rate of files per second or a very low
        //  // transfer rate (often drops hugely during a sequence of deletes,
        //  // for instance), we gradually prefer an optimistic estimate and
        //  // assume the remaining transfer will be done with the highest speed
        //  // we've seen.

        //  // Compute a value that is 0 when fps is <=L*max and 1 when fps is >=U*max
        //  double fps = this.file_progress.progress_per_sec;
        //  double fps_l = 0.5;
        //  double fps_u = 0.8;
        //  double near_max_fps =
        //      q_bound (0.0,
        //          (fps - fps_l * this.max_files_per_second) / ( (fps_u - fps_l) * this.max_files_per_second),
        //          1.0);

        //  // Compute a value that is 0 when transfer is >= U*max and
        //  // 1 when transfer is <= L*max
        //  double trans = this.size_progress.progress_per_sec;
        //  double trans_u = 0.1;
        //  double trans_l = 0.01;
        //  double slow_transfer = 1.0 - q_bound (0.0,
        //                                  (trans - trans_l * this.max_bytes_per_second) / ( (trans_u - trans_l) * this.max_bytes_per_second),
        //                                  1.0);

        //  double be_optimistic = near_max_fps * slow_transfer;
        //  size.estimated_eta = (uint64) ( (1.0 - be_optimistic) * size.estimated_eta
        //      + be_optimistic * optimistic_eta);

        //  return size;
    }


    /***********************************************************
    Get the optimistic eta.

    This value is based on the highest observed transfer bandwidth
    and files-per-second speed.
    ***********************************************************/
    uint64 optimistic_eta {
        private get {
            // This assumes files and transfers finish as quickly as possible
            // *but* note that max_per_second could be serious underestimate
            // (if we never got to fully excercise transfer or files/second)

            return this.file_progress.remaining / this.max_files_per_second * 1000
                + this.size_progress.remaining / this.max_bytes_per_second * 1000;
        }
    }


    /***********************************************************
    Whether the remaining-time estimate is trusted.

    We don't trust it if it is hugely above the optimistic estimate.
    See #5046.
    ***********************************************************/
    bool trust_eta () {
        //  return total_progress ().estimated_eta < 100 * optimistic_eta;
    }


    /***********************************************************
    Get the current file completion estimate structure
    ***********************************************************/
    Estimates file_progress_for_item (SyncFileItem item) {
        //  return this.current_items[item.file].progress.estimates;
    }


    /***********************************************************
    Called every second once started, this function updates the
    estimates.
    ***********************************************************/
    private void on_signal_update_estimates_timer_timeout () {
        //  this.size_progress.update ();
        //  this.file_progress.update ();

        //  // Update progress of all running items.
        //  GLib.Mutable_hash_iterator<string, ProgressItem> it = new GLib.Mutable_hash_iterator (this.current_items);
        //  while (it.has_next ()) {
        //      it.next ();
        //      it.value ().progress.update ();
        //  }

        //  this.max_files_per_second = double.max (this.file_progress.progress_per_sec,
        //      this.max_files_per_second);
        //  this.max_bytes_per_second = double.max (this.size_progress.progress_per_sec,
        //      this.max_bytes_per_second);
    }


    /***********************************************************
    Sets the completed size by summing on_signal_finished jobs with the
    progress of active ones.
    ***********************************************************/
    private void recompute_completed_size () {
        //  int64 recomputed_size = this.total_size_of_completed_jobs;
        //  foreach (ProgressItem progress_item in this.current_items) {
        //      if (is_size_dependent (progress_item.item)) {
        //          recomputed_size += progress_item.progress.completed;
        //      }
        //  }
        //  this.size_progress.completed = recomputed_size;
    }



} // class ProgressInfo

} // namespace Progress
} // namespace LibSync
} // namespace Occ
