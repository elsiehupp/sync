namespace Occ {
namespace LibSync {

/***********************************************************
@lass SyncEngine

@brief The SyncEngine class

@author Duncan Mac-Vicar P. <duncan@kde.org>
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class SyncEngine { //: GLib.Object {

    public enum AnotherSyncNeeded {
        NO_FOLLOW_UP_SYNC,

        /***********************************************************
        Schedule this again immediately (limited amount of times)
        ***********************************************************/
        IMMEDIATE_FOLLOW_UP,

        /***********************************************************
        Regularly schedule this folder again (around 1/minute, unlimited)
        ***********************************************************/
        DELAYED_FOLLOW_UP
    }

    /***********************************************************
    Duration in ms that uploads should be delayed after a file change

    In certain situations a file can be written to very regularly over a large
    amount of time. Copying a large file could take a while. A logfile could be
    updated every second.

    In these cases it isn't desirable to attempt to upload the "unfinished" file
    To avoid that, uploads of files where the distance between the mtime and the
    current time is less than this duration are skipped.
    ***********************************************************/
    public static GLib.TimeSpan minimum_file_age_for_upload = 2000;


    /***********************************************************
    true when one sync is running somewhere (for debugging)
    ***********************************************************/
    private static bool is_any_sync_running = false;


    /***********************************************************
    Must only be acessed during update and reconcile
    ***********************************************************/
    private GLib.List<SyncFileItem> sync_items;


    /***********************************************************
    ***********************************************************/
    unowned Account account { public get; private set; }

    private bool needs_update;
    private bool sync_running;
    public string local_path { public get; private set; }
    private string remote_path;
    private string remote_root_etag;
    public Common.SyncJournalDb journal { public get; private set; }
    private DiscoveryPhase discovery_phase;
    private unowned OwncloudPropagator propagator;

    /***********************************************************
    ***********************************************************/
    private GLib.List<string> bulk_upload_block_list;

    /***********************************************************
    List of all files with conflicts
    ***********************************************************/
    private GLib.List<string> seen_conflict_files;

    /***********************************************************
    ***********************************************************/
    private ProgressInfo progress_info;

    /***********************************************************
    ***********************************************************/
    public CSync.ExcludedFiles excluded_files { public get; private set; }
    public SyncFileStatusTracker sync_file_status_tracker { public get; private set; }
    public Common.Utility.StopWatch stop_watch { public get; private set; }


    /***********************************************************
    true if there is at least one file which was not changed
    on the server
    ***********************************************************/
    private bool has_none_files;


    /***********************************************************
    true if there is at leasr one file with instruction REMOVE
    ***********************************************************/
    private bool has_remove_file;


    /***********************************************************
    If ignored files should be ignored
    ***********************************************************/
    public bool ignore_hidden_files = false;


    /***********************************************************
    ***********************************************************/
    private int upload_limit;
    private int download_limit;
    public SyncOptions sync_options;


    /***********************************************************
    ***********************************************************/
    private AnotherSyncNeeded another_sync_needed;


    /***********************************************************
    Stores the time since a job touched a file.
    ***********************************************************/
    private GLib.HashTable<GLib.Timer, string> touched_files;


    /***********************************************************
    ***********************************************************/
    private GLib.Timer last_update_progress_callback_call;


    /***********************************************************
    For clearing the touched_files variable after sync on_signal_finished
    ***********************************************************/
    private GLib.Timeout clear_touched_files_timer;


    /***********************************************************
    List of unique errors that occurred in a sync run.
    ***********************************************************/
    private GLib.List<string> unique_errors;


    /***********************************************************
    The kind of local discovery the last sync run used
    Access the last sync run's local discovery style
    ***********************************************************/
    DiscoveryPhase.LocalDiscoveryStyle last_local_discovery_style { public get; private set; }

    private DiscoveryPhase.LocalDiscoveryStyle local_discovery_style = DiscoveryPhase.LocalDiscoveryStyle.FILESYSTEM_ONLY;
    private GLib.List<string> local_discovery_paths;
    /***********************************************************
    When the client touches a file, block change notifications
    for this duration (ms)

    On Linux and Windows the file watcher can't distinguish a
    change that originates from the client (like a download
    during a sync operation) and an external change. To work
    around that, all files the client touches are recorded and
    file change notifications for these are blocked for some
    time. This value controls for how long.

    Reasons this delay can't be very small:
    - it takes time for the change notification to arrive and
    //    to be processed by th
    - some time could pass between the client recording that a
    //    file will be touched and its filesystem operation
    //    finishing, triggering the notification
    ***********************************************************/
    const int S_TOUCHED_FILES_MAX_AGE_MICROSECONDS = 3 * 1000 * 1000;


    /***********************************************************
    During update, before reconcile
    ***********************************************************/
    internal signal void signal_etag_retrieved_from_sync_engine (string value1, GLib.DateTime value2);


    /***********************************************************
    After the above signals. with the items that actually need propagating
    ***********************************************************/
    internal signal void signal_about_to_propagate (GLib.List<SyncFileItem> value);


    /***********************************************************
    After each item completed by a job (successful or not)
    ***********************************************************/
    internal signal void signal_item_completed (SyncFileItem value);


    /***********************************************************
    ***********************************************************/
    internal signal void signal_transmission_progress (ProgressInfo progress);


    /***********************************************************
    We've produced a new sync error of a type.
    ***********************************************************/
    internal signal void signal_sync_error (string message, ErrorCategory category = ErrorCategory.NORMAL);


    /***********************************************************
    ***********************************************************/
    internal signal void signal_add_error_to_gui (SyncFileItem.Status status, string error_message, string subject);


    /***********************************************************
    ***********************************************************/
    internal signal void signal_finished (bool success);


    /***********************************************************
    ***********************************************************/
    internal signal void signal_started ();


    delegate void RemoveDelegate (bool value);
    /***********************************************************
    Emited when the sync engine detects that all the files have
    been removed or change.  This usually happen when the server
    was reset or something. Set cancel to true in a slot
    connected from this signal to abort the sync.
    ***********************************************************/
    internal signal void signal_about_to_remove_all_files (SyncFileItem.Direction direction, RemoveDelegate f);


    /***********************************************************
    A new folder was discovered and was not synced because of
    the confirmation feature
    ***********************************************************/
    internal signal void signal_new_big_folder (string folder, bool is_external);


    /***********************************************************
    Emitted when propagation has problems with a locked file.

    Forwarded from OwncloudPropagator.signal_seen_locked_file.
    ***********************************************************/
    internal signal void signal_seen_locked_file (string filename);


    /***********************************************************
    ***********************************************************/
    public SyncEngine.for_account (
        Account account,
        string local_path,
        string remote_path,
        Common.SyncJournalDb journal
    ) {
        //  this.account = account;
        //  this.needs_update = false;
        //  this.sync_running = false;
        //  this.local_path = local_path;
        //  this.remote_path = remote_path;
        //  this.journal = journal;
        //  this.progress_info = new ProgressInfo ();
        //  this.has_none_files = false;
        //  this.has_remove_file = false;
        //  this.upload_limit = 0;
        //  this.download_limit = 0;
        //  this.another_sync_needed = AnotherSyncNeeded.NO_FOLLOW_UP_SYNC;
        //  this.last_local_discovery_style = DiscoveryPhase.LocalDiscoveryStyle.FILESYSTEM_ONLY;
        //  q_register_meta_type<SyncFileItem> ("SyncFileItem");
        //  q_register_meta_type<SyncFileItem> ("unowned SyncFileItem");
        //  q_register_meta_type<SyncFileItem.Status> ("SyncFileItem.Status");
        //  q_register_meta_type<SyncFileStatus> ("SyncFileStatus");
        //  q_register_meta_type<GLib.List<SyncFileItem>> ("GLib.List<SyncFileItem>");
        //  q_register_meta_type<SyncFileItem.Direction> ("SyncFileItem.Direction");

        //  // Everything in the SyncEngine expects a trailing slash for the local_path.
        //  //  GLib.assert_true (local_path.has_suffix ("/"));

        //  this.excluded_files.reset (new CSync.ExcludedFiles (local_path));

        //  this.sync_file_status_tracker.reset (new SyncFileStatusTracker (this));

        //  this.clear_touched_files_timer.single_shot (true);
        //  this.clear_touched_files_timer.interval (30 * 1000);
        //  this.clear_touched_files_timer.timeout.connect (
        //      this.on_signal_clear_touched_files_timer_timeout
        //  );
        //  this.signal_finished.connect (
        //      this.on_signal_finished
        //  );
    }


    private void on_signal_finished (bool finished) {
        //  this.journal.key_value_store_set ("last_sync", GLib.DateTime.current_secs_since_epoch ());
    }


    ~SyncEngine () {
        //  abort ();
        //  this.excluded_files.reset ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start_sync () {
        //  if (this.journal.exists ()) {
        //      GLib.List<Common.SyncJournalDb.PollInfo> poll_infos = this.journal.get_poll_infos ();
        //      if (!poll_infos == "") {
        //          GLib.info ("Finish Poll jobs before starting a sync");
        //          var cleanup_polls_job = new CleanupPollsJob (
        //              poll_infos,
        //              this.account,
        //              this.journal,
        //              this.local_path,
        //              this.sync_options.vfs,
        //              this
        //          );
        //          cleanup_polls_job.signal_finished.connect (
        //              this.on_signal_start_sync
        //          );
        //          cleanup_polls_job.signal_aborted.connect (
        //              this.on_signal_clean_polls_job_aborted
        //          );
        //          cleanup_polls_job.start ();
        //          return;
        //      }
        //  }

        //  if (is_any_sync_running || this.sync_running) {
        //      //  GLib.assert_true (false)
        //      return;
        //  }

        //  is_any_sync_running = true;
        //  this.sync_running = true;
        //  this.another_sync_needed = AnotherSyncNeeded.NO_FOLLOW_UP_SYNC;
        //  this.clear_touched_files_timer.stop ();

        //  this.has_none_files = false;
        //  this.has_remove_file = false;
        //  this.seen_conflict_files = new GLib.List<string> ();

        //  this.progress_info.reset ();

        //  if (!new GLib.Dir (this.local_path).exists ()) {
        //      this.another_sync_needed = AnotherSyncNeeded.DELAYED_FOLLOW_UP;
        //      // No this.tr, it should only occur in non-mirall
        //      signal_sync_error ("Unable to find local sync folder.");
        //      on_signal_finalize (false);
        //      return;
        //  }

        //  // Check free size on disk first.
        //  int64 min_free = critical_free_space_limit ();
        //  int64 free_bytes = Common.Utility.free_disk_space (this.local_path);
        //  if (free_bytes >= 0) {
        //      if (free_bytes < min_free) {
        //          GLib.warning ("Too little space available at" + this.local_path + ". Have"
        //                      + free_bytes + "bytes and require at least" + min_free + "bytes");
        //          this.another_sync_needed = AnotherSyncNeeded.DELAYED_FOLLOW_UP;
        //          signal_sync_error (
        //              _("Only %1 are available, need at least %2 to start"
        //              + "Placeholders are postfixed with file sizes using Common.Utility.octets_to_string ()")
        //                  .printf (
        //                      Common.Utility.octets_to_string (free_bytes),
        //                      Common.Utility.octets_to_string (min_free)));
        //          on_signal_finalize (false);
        //          return;
        //      } else {
        //          GLib.info ("There are" + free_bytes + "bytes available at" + this.local_path);
        //      }
        //  } else {
        //      GLib.warning ("Could not determine free space available at" + this.local_path);
        //  }

        //  foreach (var item in this.sync_items) {
        //      this.sync_items.remove (item);
        //  }
        //  this.needs_update = false;

        //  if (!this.journal.exists ()) {
        //      GLib.info ("New sync (no sync journal exists)");
        //  } else {
        //      GLib.info ("Sync with existing sync journal");
        //  }

        //  string version_string = "Using Qt ";
        //  version_string += q_version ();

        //  version_string += " SSL library " + GLib.SslSocket.ssl_library_version_string ().to_utf8 ();
        //  version_string += " on " + Common.Utility.platform_name ();
        //  GLib.info (version_string);

        //  // This creates the DB if it does not exist yet.
        //  if (!this.journal.open ()) {
        //      GLib.warning ("No way to create a sync journal!");
        //      signal_sync_error (_("Unable to open or create the local sync database. Make sure you have write access in the sync folder."));
        //      on_signal_finalize (false);
        //      return;
        //      // database creation error!
        //  }

        //  // Functionality like selective sync might have set up etag storage
        //  // filtering via schedule_path_for_remote_discovery (). This is* the next sync, so
        //  // undo the filter to allow this sync to retrieve and store the correct etags.
        //  this.journal.clear_etag_storage_filter ();

        //  this.excluded_files.exclude_conflict_files (!this.account.capabilities.upload_conflict_files);

        //  this.last_local_discovery_style = this.local_discovery_style;

        //  if (this.sync_options.vfs.mode () == Common.AbstractVfs.WithSuffix && this.sync_options.vfs.file_suffix () == "") {
        //      signal_sync_error (_("Using virtual files with suffix, but suffix is not set"));
        //      on_signal_finalize (false);
        //      return;
        //  }

        //  bool ok = false;
        //  var selective_sync_block_list = this.journal.get_selective_sync_list (Common.SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok);
        //  if (ok) {
        //      bool using_selective_sync = (!selective_sync_block_list == "");
        //      GLib.info (using_selective_sync ? "Using Selective Sync": "NOT Using Selective Sync");
        //  } else {
        //      GLib.warning ("Could not retrieve selective sync list from DB");
        //      signal_sync_error (_("Unable to read the blocklist from the local database"));
        //      on_signal_finalize (false);
        //      return;
        //  }

        //  this.stop_watch.start ();
        //  this.progress_info.status = ProgressInfo.Status.STARTING;
        //  signal_transmission_progress (this.progress_info);

        //  GLib.info ("#### Discovery start ####################################################");
        //  GLib.info ("Server" + account.server_version
        //                   + (account.is_http2Supported () ? "Using HTTP/2": ""));
        //  this.progress_info.status = ProgressInfo.Status.DISCOVERY;
        //  signal_transmission_progress (this.progress_info);

        //  this.discovery_phase.reset (new DiscoveryPhase ());
        //  this.discovery_phase.account = this.account;
        //  this.discovery_phase.excludes = this.excluded_files;
        //  string exclude_file_path = this.local_path + ".sync-exclude.lst";
        //  if (GLib.File.exists (exclude_file_path)) {
        //      this.discovery_phase.excludes.add_exclude_file_path (exclude_file_path);
        //      this.discovery_phase.excludes.on_signal_reload_exclude_files ();
        //  }
        //  this.discovery_phase.statedatabase = this.journal;
        //  this.discovery_phase.local_directory = this.local_path;
        //  if (!this.discovery_phase.local_directory.has_suffix ("/"))
        //      this.discovery_phase.local_directory+="/";
        //  this.discovery_phase.remote_folder = this.remote_path;
        //  if (!this.discovery_phase.remote_folder.has_suffix ("/"))
        //      this.discovery_phase.remote_folder+="/";
        //  this.discovery_phase.sync_options = this.sync_options;
        //  this.discovery_phase.local_discovery_delegate = this.local_discovery_delegate;
        //  this.discovery_phase.selective_sync_block_list = selective_sync_block_list;
        //  this.discovery_phase.selective_sync_allow_list = this.journal.get_selective_sync_list (Common.SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST, ok);
        //  if (!ok) {
        //      GLib.warning ("Unable to read selective sync list; aborting.");
        //      signal_sync_error (_("Unable to read from the sync journal."));
        //      on_signal_finalize (false);
        //      return;
        //  }

        //  // Check for invalid character in old server version
        //  string invalid_filename_pattern = this.account.capabilities.invalid_filename_regex;
        //  if (invalid_filename_pattern == null
        //      && this.account.server_version_int < Account.make_server_version (8, 1, 0)) {
        //      // Server versions older than 8.1 don't support some characters in filenames.
        //      // If the capability is not set, default to a pattern that avoids uploading
        //      // files with names that contain these.
        //      // It's important to respect the capability also for older servers -- the
        //      // version check doesn't make sense for custom servers.
        //      invalid_filename_pattern = " ([\\:?*\"<>|])";
        //  }
        //  if (invalid_filename_pattern != "")
        //      this.discovery_phase.invalid_filename_rx = new GLib.Regex (invalid_filename_pattern);
        //  this.discovery_phase.server_blocklisted_files = this.account.capabilities.blocklisted_files;
        //  this.discovery_phase.ignore_hidden_files = ignore_hidden_files;

        //  this.discovery_phase.signal_item_discovered.connect (
        //      this.on_signal_item_discovered
        //  );
        //  this.discovery_phase.signal_new_big_folder.connect (
        //      this.on_signal_new_big_folder
        //  );
        //  this.discovery_phase.signal_fatal_error.connect (
        //      this.on_signal_fatal_error
        //  );
        //  this.discovery_phase.signal_finished.connect (
        //      this.on_signal_discovery_finished
        //  );
        //  this.discovery_phase.signal_silently_excluded.connect (
        //      this.sync_file_status_tracker.on_signal_silently_excluded
        //  );
        //  var discovery_job = new ProcessDirectoryJob (
        //      this.discovery_phase,
        //      PinState.ALWAYS_LOCAL,
        //      this.journal.key_value_store_get_int ("last_sync", 0),
        //      this.discovery_phase
        //  );
        //  this.discovery_phase.start_job (discovery_job);
        //  discovery_job.signal_etag.connect (
        //      this.on_signal_root_etag_received
        //  );
        //  this.discovery_phase.signal_add_error_to_gui.connect (
        //      this.on_signal_add_error_to_gui
        //  );
    }


    private void on_signal_fatal_error (string error_string) {
        //  signal_sync_error (error_string);
        //  on_signal_finalize (false);
    }


    /***********************************************************
    ***********************************************************/
    public void network_limits (int upload, int download) {
        //  this.upload_limit = upload;
        //  this.download_limit = download;

        //  if (this.propagator == null) {
        //      return;
        //  }

        //  this.propagator.upload_limit = upload;
        //  this.propagator.download_limit = download;

        //  if (upload != 0 || download != 0) {
        //      GLib.info ("Network Limits (down/up) " + upload.to_string () + download.to_string ());
        //  }
    }


    /***********************************************************
    Abort the sync. Called from the main thread.
    ***********************************************************/
    public new void abort () {
        //  if (this.propagator != null) {
        //      GLib.info ("Aborting sync.");
        //  }

        //  if (this.propagator != null) {
        //      // If we're already in the propagation phase, aborting that is sufficient
        //      this.propagator.abort ();
        //  } else if (this.discovery_phase != null) {
        //      // Delete the discovery and all child jobs after ensuring
        //      // it can't finish_delegate and start the propagator
        //      disconnect (
        //          this.discovery_phase,
        //          null,
        //          this,
        //          null
        //      );
        //      this.discovery_phase.take ().delete_later ();

        //      signal_sync_error (_("Synchronization will resume shortly."));
        //      on_signal_finalize (false);
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public bool is_sync_running () {
        //  return this.sync_running;
    }


    /***********************************************************
    Returns whether another sync is needed to complete the sync
    ***********************************************************/
    public AnotherSyncNeeded is_another_sync_needed () {
        //  return this.another_sync_needed;
    }


    /***********************************************************
    Start from the end (most recent) and look for our path.
    Check the time just in case.
    ***********************************************************/
    public bool was_file_touched (string filename) {
        //  foreach (var touched_file in this.touched_files.reverse ()) {
        //      if (touched_file.value () == filename) {
        //          return touched_file.key ().elapsed () <= S_TOUCHED_FILES_MAX_AGE_MICROSECONDS;
        //      }
        //  }
        //  return false;
    }


    /***********************************************************
    Control whether local discovery should read from filesystem
    or database.

    If style is DATABASE_AND_FILESYSTEM, paths a set of file
    paths relative the synced folder. All the parent directories
    of th ... be read from the database and scanned on the filesystem.

    Note, the style and paths are only retained for the next
    sync and revert afterwards. Use
    this.last_local_discovery_style to discover the last
    sync's style.
    ***********************************************************/
    public void local_discovery_options (DiscoveryPhase.LocalDiscoveryStyle style, GLib.List<string> paths) {
        //  this.local_discovery_style = style;
        //  this.local_discovery_paths = std.move (paths);

        //  // Normalize to make sure that no path is a contained in another.
        //  // Note: for simplicity, this code consider anything less than "/" as a path separator, so for
        //  // example, this will remove "foo.bar" if "foo" is in the list. This will mean we might have
        //  // some false positive, but that's Ok.
        //  // This invariant is used in SyncEngine.local_discovery_delegate
        //  string prev;
        //  var it = this.local_discovery_paths.begin ();
        //  while (it != this.local_discovery_paths.end ()) {
        //      if (prev != null && it.has_prefix (prev) && (prev.has_suffix ("/") || *it == prev || it.at (prev.size ()) <= "/")) {
        //          it = this.local_discovery_paths.erase (it);
        //      } else {
        //          prev = *it;
        //          ++it;
        //      }
        //  }
    }


    /***********************************************************
    Returns whether the given folder-relative path should be
    locally discovered given the local discovery options.

    Example: If path is 'foo/bar' and style is
    DATABASE_AND_FILESYSTEM and dirs contains
    'foo/bar/signal_touched_file', then the result will be true.
    ***********************************************************/
    public bool local_discovery_delegate (string path) {
        //  if (this.local_discovery_style == DiscoveryPhase.LocalDiscoveryStyle.FILESYSTEM_ONLY)
        //      return true;

        //  // The intention is that if "A/X" is in this.local_discovery_paths:
        //  // - parent folders like "/", "A" will be discovered (to make sure the discovery reaches the
        //  //   point where something new happened)
        //  // - the folder itself "A/X" will be discovered
        //  // - subfolders like "A/X/Y" will be discovered (so data inside a new or renamed folder will be
        //  //   discovered in full)
        //  // Check out Test_local_discovery.TestLocalDiscoveryDecision ()

        //  var it = this.local_discovery_paths.lower_bound (path);
        //  if (it == this.local_discovery_paths.end () || !it.has_prefix (path)) {
        //      // Maybe a subfolder of something in the list?
        //      if (it != this.local_discovery_paths.begin () && path.has_prefix ( (--it))) {
        //          return it.has_suffix ("/") || (path.length > it.size () && path.at (it.size ()) <= "/");
        //      }
        //      return false;
        //  }

        //  // maybe an exact match or an empty path?
        //  if (it.size () == path.length || path == "")
        //      return true;

        //  // Maybe a parent folder of something in the list?
        //  // check for a prefix + / match
        //  while (true) {
        //      if (it.size () > path.length && it.at (path.size ()) == "/")
        //          return true;
        //      ++it;
        //      if (it == this.local_discovery_paths.end () || !it.has_prefix (path))
        //          return false;
        //  }
        //  return false;
    }




    /***********************************************************
    Removes all virtual file database entries and dehydrated local placeholders.

    Particularly useful when switching off vfs mode or switching to a
    different kind of vfs.

    Note that hydrated* placeholder files might still be left. These will
    get cleaned up by Common.AbstractVfs.unregister_folder ().
    ***********************************************************/
    public static void wipe_virtual_files (string local_path, Common.SyncJournalDb journal, Common.AbstractVfs vfs) {
        //  GLib.info ("Wiping virtual files inside " + local_path);
        //  journal.get_files_below_path (
        //      "",
        //      SyncEngine.files_below_path_wipe_filter
        //  );

        //  journal.force_remote_discovery_next_sync ();

        //  // Postcondition : No ItemType.VIRTUAL_FILE / ItemType.VIRTUAL_FILE_DOWNLOAD left in the database.
        //  // But hydrated placeholders may still be around.
    }


    private static void files_below_path_wipe_filter (Common.SyncJournalFileRecord record) {
        //  if (record.type != ItemType.VIRTUAL_FILE && record.type != ItemType.VIRTUAL_FILE_DOWNLOAD) {
        //      return;
        //  }

        //  GLib.debug ("Removing database record for " + record.path);
        //  journal.delete_file_record (record.path);

        //  // If the local file is a dehydrated placeholder, wipe it too.
        //  // Otherwise leave it to allow the next sync to have a new-new conflict.
        //  string local_file = local_path + record.path;
        //  if (GLib.File.exists (local_file) && vfs.is_dehydrated_placeholder (local_file)) {
        //      GLib.debug ("Removing local dehydrated placeholder " + record.path);
        //      GLib.File.remove (local_file);
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public static void switch_to_virtual_files (string local_path, Common.SyncJournalDb journal, Common.AbstractVfs vfs) {
        //  GLib.info ("Convert to virtual files inside" + local_path);
        //  journal.get_files_below_path (
        //      {},
        //      SyncEngine.files_below_path_switch_filter
        //  );
    }


    private static files_below_path_switch_filter (Common.SyncJournalFileRecord record) {
        //  var path = record.path;
        //  var filename = GLib.File.new_for_path (path).filename ();
        //  if (FileSystem.is_exclude_file (filename)) {
        //      return;
        //  }
        //  SyncFileItem item;
        //  string local_file = local_path + path;
        //  var result = vfs.convert_to_placeholder (local_file, item, local_file);
        //  if (!result.is_valid) {
        //      GLib.warning ("Could not convert file to placeholder" + result.error);
        //  }
    }


    /***********************************************************
    For the test
    ***********************************************************/
    public OwncloudPropagator get_propagator () {
        //  return this.propagator;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_discovered (bool local, string folder) {
        //  // Don't wanna overload the UI
        //  if (!this.last_update_progress_callback_call.is_valid || this.last_update_progress_callback_call.elapsed () >= 200) {
        //      this.last_update_progress_callback_call.start (); // first call or enough elapsed time
        //  } else {
        //      return;
        //  }

        //  if (local) {
        //      this.progress_info.current_discovered_local_folder = folder;
        //      this.progress_info.current_discovered_remote_folder = "";
        //  } else {
        //      this.progress_info.current_discovered_remote_folder = folder;
        //      this.progress_info.current_discovered_local_folder = "";
        //  }
        //  signal_transmission_progress (this.progress_info);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_root_etag_received (string e, GLib.DateTime time) {
        //  if (this.remote_root_etag == "") {
        //      GLib.debug ("Root etag: " + e);
        //      this.remote_root_etag = e;
        //      signal_etag_retrieved_from_sync_engine (this.remote_root_etag, time);
        //  }
    }


    /***********************************************************
    When the discovery phase discovers an item
    ***********************************************************/
    private void on_signal_item_discovered (SyncFileItem item) {
        //  if (Common.Utility.is_conflict_file (item.file)) {
        //      this.seen_conflict_files.insert (item.file);
        //  }
        //  if (item.instruction == CSync.SyncInstructions.UPDATE_METADATA && !item.is_directory ()) {
        //      // For directories, metadata-only updates will be done after all their files are propagated.

        //      // Update the database now already :  New remote fileid or Etag or Remote_perm
        //      // Or for files that were detected as "resolved conflict".
        //      // Or a local inode/mtime change

        //      // In case of "resolved conflict" : there should have been a conflict because they
        //      // both were new, or both had their local mtime or remote etag modified, but the
        //      // size and mtime is the same on the server.  This typically happens when the
        //      // database is removed. Nothing will be done for those files, but we still need
        //      // to update the database.

        //      // This metadata update could* be a propagation job of its own, but since it's
        //      // quick to do and we don't want to create a potentially large number of
        //      // mini-jobs later on, we just update metadata right now.

        //      if (item.direction == SyncFileItem.Direction.DOWN) {
        //          string file_path = this.local_path + item.file;

        //          // If the 'W' remote permission changed, update the local filesystem
        //          Common.SyncJournalFileRecord prev;
        //          if (this.journal.get_file_record (item.file, prev)
        //              && prev.is_valid
        //              && prev.remote_permissions.has_permission (Common.RemotePermissions.Permissions.CAN_WRITE) != item.remote_permissions.has_permission (Common.RemotePermissions.Permissions.CAN_WRITE)) {
        //              FileSystem.file_read_only_weak (file_path, item.remote_permissions != null && !item.remote_permissions.has_permission (Common.RemotePermissions.Permissions.CAN_WRITE));
        //          }
        //          var record = item.to_sync_journal_file_record_with_inode (file_path);
        //          if (record.checksum_header == "")
        //              record.checksum_header = prev.checksum_header;
        //          record.server_has_ignored_files |= prev.server_has_ignored_files;

        //          // Ensure it's a placeholder file on disk
        //          if (item.type == ItemType.FILE) {
        //              var result = this.sync_options.vfs.convert_to_placeholder (file_path, item);
        //              if (!result) {
        //                  item.instruction = CSync.SyncInstructions.ERROR;
        //                  item.error_string = _("Could not update file : %1").printf (result.error);
        //                  return;
        //              }
        //          }

        //          // Update on-disk virtual file metadata
        //          if (item.type == ItemType.VIRTUAL_FILE) {
        //              var r = this.sync_options.vfs.update_metadata (file_path, item.modtime, item.size, item.file_id);
        //              if (!r) {
        //                  item.instruction = CSync.SyncInstructions.ERROR;
        //                  item.error_string = _("Could not update virtual file metadata : %1").printf (r.error);
        //                  return;
        //              }
        //          }

        //          // Updating the database happens on on_signal_success
        //          this.journal.file_record (record);

        //          // This might have changed the shared flag, so we must notify SyncFileStatusTracker for example
        //          signal_item_completed (item);
        //      } else {
        //          // Update only outdated data from the disk.
        //          this.journal.update_local_metadata (item.file, item.modtime, item.size, item.inode);
        //      }
        //      this.has_none_files = true;
        //      return;
        //  } else if (item.instruction == CSync.SyncInstructions.NONE) {
        //      this.has_none_files = true;
        //      if (this.account.capabilities.upload_conflict_files && Common.Utility.is_conflict_file (item.file)) {
        //          // For uploaded conflict files, files with no action performed on them should
        //          // be displayed : but we mustn't overwrite the instruction if something happens
        //          // to the file!
        //          item.error_string = _("Unresolved conflict.");
        //          item.instruction = CSync.SyncInstructions.IGNORE;
        //          item.status = SyncFileItem.Status.CONFLICT;
        //      }
        //      return;
        //  } else if (item.instruction == CSync.SyncInstructions.REMOVE && !item.is_selective_sync) {
        //      this.has_remove_file = true;
        //  } else if (item.instruction == CSync.SyncInstructions.RENAME) {
        //      this.has_none_files = true; // If a file (or every file) has been renamed, it means not al files where deleted
        //  } else if (item.instruction == CSync.SyncInstructions.TYPE_CHANGE
        //      || item.instruction == CSync.SyncInstructions.SYNC) {
        //      if (item.direction == SyncFileItem.Direction.UP) {
        //          // An upload of an existing file means that the file was left unchanged on the server
        //          // This counts as a NONE for detecting if all the files on the server were changed
        //          this.has_none_files = true;
        //      }
        //  }

        //  // check for blocklisting of this item.
        //  // if the item is on blocklist, the instruction was set to ERROR
        //  check_error_blocklisting (item);
        //  this.needs_update = true;

        //  // Insert sorted
        //  var it = std.lower_bound ( this.sync_items.begin (), this.sync_items.end (), item ); // the this.sync_items is sorted
        //  this.sync_items.insert ( it, item );

        //  on_signal_new_item (item);

        //  if (item.is_directory ()) {
        //      on_signal_folder_discovered (item.etag == "", item.file);
        //  }
    }


    /***********************************************************
    Called when a SyncFileItem gets accepted for a sync.

    Mostly done in initial creation inside treewalk_file but
    can also be called via the propagator for items that are
    created during propagation.
    ***********************************************************/
    private void on_signal_new_item (SyncFileItem item) {
        //  this.progress_info.adjust_totals_for_file (item);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_item_completed (SyncFileItem item) {
        //  this.progress_info.progress_complete (item);

        //  signal_transmission_progress (this.progress_info);
        //  signal_item_completed (item);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_discovery_finished () {
        //  if (this.discovery_phase == null) {
        //      // There was an error that was already taken care of
        //      return;
        //  }

        //  GLib.info ("#### Discovery end #################################################### " + this.stop_watch.add_lap_time ("Discovery Finished") + "ms");

        //  // Sanity check
        //  if (!this.journal.open ()) {
        //      GLib.warning ("Bailing out, DB failure");
        //      signal_sync_error (_("Cannot open the sync journal"));
        //      on_signal_finalize (false);
        //      return;
        //  } else {
        //      // Commits a possibly existing (should not though) transaction and starts a new one for the propagate phase
        //      this.journal.commit_if_needed_and_start_new_transaction ("Post discovery");
        //  }

        //  this.progress_info.current_discovered_remote_folder = "";
        //  this.progress_info.current_discovered_local_folder = "";
        //  this.progress_info.status = ProgressInfo.Status.RECONCILE;
        //  signal_transmission_progress (this.progress_info);

        //  //    GLib.info ("Permissions of the root folder: " + this.csync_ctx.remote.root_perms.to_string ();

        //  if (!this.has_none_files && this.has_remove_file) {
        //      GLib.info ("All the files are going to be changed, asking the user");
        //      int side = 0; // > 0 means more deleted on the server.  < 0 means more deleted on the client
        //      foreach (var it in this.sync_items) {
        //          if (it.instruction == CSync.SyncInstructions.REMOVE) {
        //              side += it.direction == SyncFileItem.Direction.DOWN ? 1 : -1;
        //          }
        //      }

        //      GLib.Object guard = new GLib.Object ();
        //      GLib.Object self = this;
        //      signal_about_to_remove_all_files (side >= 0 ? SyncFileItem.Direction.DOWN : SyncFileItem.Direction.UP, callback);
        //      return;
        //  }
        //  finish_delegate ();
    }


    private delegate void FinishDelegate ();

    private void finish_delegate () {
        //  var database_fingerprint = this.journal.data_fingerprint ();
        //  // If database_fingerprint is empty, this means that there was no information in the database
        //  // (for example, upgrading from a previous version, or first sync, or server not supporting fingerprint)
        //  if (!database_fingerprint == "" && this.discovery_phase
        //      && this.discovery_phase.data_fingerprint != database_fingerprint) {
        //      GLib.info ("data fingerprint changed, assume restore from backup" + database_fingerprint + this.discovery_phase.data_fingerprint);
        //      restore_old_files (this.sync_items);
        //  }

        //  if (this.discovery_phase.another_sync_needed && this.another_sync_needed == AnotherSyncNeeded.NO_FOLLOW_UP_SYNC) {
        //      this.another_sync_needed = AnotherSyncNeeded.IMMEDIATE_FOLLOW_UP;
        //  }

        //  GLib.assert (std.is_sorted (this.sync_items.begin (), this.sync_items.end ()));

        //  GLib.info ("#### Reconcile (signal_about_to_propagate) #################################################### " + this.stop_watch.add_lap_time ("Reconcile (signal_about_to_propagate)") + "ms");

        //  this.local_discovery_paths = new GLib.List<string> ();

        //  // To announce the beginning of the sync
        //  signal_about_to_propagate (this.sync_items);

        //  GLib.info ("#### Reconcile (signal_about_to_propagate OK) #################################################### "<< this.stop_watch.add_lap_time ("Reconcile (signal_about_to_propagate OK)") + "ms");

        //  // it's important to do this before ProgressInfo.start (), to announce start of new sync
        //  this.progress_info.status = ProgressInfo.Status.PROPAGATION;
        //  signal_transmission_progress (this.progress_info);
        //  this.progress_info.start_estimate_updates ();

        //  // post update phase script : allow to tweak stuff by a custom script in debug mode.
        //  if (!q_environment_variable_is_empty ("OWNCLOUD_POST_UPDATE_SCRIPT")) {
    // #ifilenamedef NDEBUG
        //      string script = q_environment_variable ("OWNCLOUD_POST_UPDATE_SCRIPT");

        //      GLib.debug ("Post Update Script: " + script);
        //      var script_args = script.split (GLib.Regex ("\\s+"), GLib.SkipEmptyParts);
        //      if (script_args.size () > 0) {
        //          var script_executable = script_args.nth_data (0);
        //          script_args.remove (script_args.nth_data (0));
        //          GLib.Process.execute (script_executable, script_args);
        //      }
    // #else
        //      GLib.warning ("**** Attention : POST_UPDATE_SCRIPT installed, but not executed because compiled with NDEBUG");
    // #endif
        //  }

        //  // do a database commit
        //  this.journal.commit ("post treewalk");

        //  this.propagator = new OwncloudPropagator (
        //      this.account,
        //      this.local_path,
        //      this.remote_path,
        //      this.journal,
        //      this.bulk_upload_block_list
        //  );
        //  this.propagator.sync_options = this.sync_options;
        //  this.propagator.signal_item_completed.connect (
        //      this.on_signal_item_completed
        //  );
        //  this.propagator.signal_progress.connect (
        //      this.on_signal_progress
        //  );
        //  this.propagator.signal_finished.connect (
        //      this.on_signal_propagation_finished // GLib.QueuedConnection
        //  );
        //  this.propagator.signal_seen_locked_file.connect (
        //      this.on_signal_seen_locked_file
        //  );
        //  this.propagator.signal_touched_file.connect (
        //      this.on_signal_add_touched_file
        //  );
        //  this.propagator.signal_insufficient_local_storage.connect (
        //      this.on_signal_insufficient_local_storage
        //  );
        //  this.propagator.signal_insufficient_remote_storage.connect (
        //      this.on_signal_insufficient_remote_storage
        //  );
        //  this.propagator.signal_new_item.connect (
        //      this.on_signal_new_item
        //  );

        //  // apply the network limits to the propagator
        //  network_limits (this.upload_limit, this.download_limit);

        //  delete_stale_download_infos (this.sync_items);
        //  delete_stale_upload_infos (this.sync_items);
        //  delete_stale_error_blocklist_entries (this.sync_items);
        //  this.journal.commit ("post stale entry removal");

        //  // Emit the started signal only after the propagator has been set up.
        //  if (this.needs_update)
        //      signal_started ();

        //  this.propagator.start (std.move (this.sync_items));

        //  GLib.info ("#### Post-Reconcile end #################################################### " + this.stop_watch.add_lap_time ("Post-Reconcile Finished") + "ms");
    }



    private void callback (GLib.Object self, FinishDelegate finish_delegate, GLib.Object guard, bool cancel) {
        //  // use a guard to ensure its only called once...
        //  // qpointer to self to ensure we still exist
        //  if (guard == null || self == null) {
        //      return;
        //  }
        //  guard.delete_later ();
        //  if (cancel) {
        //      GLib.info ("User aborted sync.");
        //      on_signal_finalize (false);
        //      return;
        //  } else {
        //      finish_delegate ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_propagation_finished (bool on_signal_success) {
        //  if (this.propagator.another_sync_needed && this.another_sync_needed == AnotherSyncNeeded.NO_FOLLOW_UP_SYNC) {
        //      this.another_sync_needed = AnotherSyncNeeded.IMMEDIATE_FOLLOW_UP;
        //  }

        //  if (on_signal_success && this.discovery_phase) {
        //      this.journal.data_fingerprint (this.discovery_phase.data_fingerprint);
        //  }

        //  conflict_record_maintenance ();

        //  this.journal.delete_stale_flags_entries ();
        //  this.journal.commit ("All Finished.", false);

        //  // Send final progress information even if no
        //  // files needed propagation, but clear the last_completed_item
        //  // so we don't count this twice (like Recent Files)
        //  this.progress_info.last_completed_item = SyncFileItem ();
        //  this.progress_info.status = ProgressInfo.Status.DONE;
        //  signal_transmission_progress (this.progress_info);

        //  on_signal_finalize (on_signal_success);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_progress (SyncFileItem item, int64 current) {
        //  this.progress_info.progress_item (item, current);
        //  signal_transmission_progress (this.progress_info);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_clean_polls_job_aborted (string error) {
        //  signal_sync_error (error);
        //  on_signal_finalize (false);
    }


    /***********************************************************
    Records that a file was touched by a job.
    ***********************************************************/
    private void on_signal_add_touched_file (string filename) {
        //  GLib.Timer now;
        //  now.start ();
        //  string file = GLib.Dir.clean_path (filename);

        //  // Iterate from the oldest and remove anything older than 15 seconds.
        //  while (true) {
        //      var first = this.touched_files.begin ();
        //      if (first == this.touched_files.end ()) {
        //          break;
        //      }
        //      // Compare to our new GLib.Timer instead of using elapsed ().
        //      // This avoids querying the current time from the OS for every loop.
        //      var elapsed = GLib.TimeSpan (
        //          now.msecs_since_reference () - first.key ().msecs_since_reference ()
        //      );
        //      if (elapsed <= S_TOUCHED_FILES_MAX_AGE_MICROSECONDS) {
        //          // We found the first path younger than the maximum age, keep the rest.
        //          break;
        //      }

        //      this.touched_files.erase (first);
        //  }

        //  // This should be the largest GLib.Timer yet, use const_end () as hint.
        //  this.touched_files.insert (this.touched_files.const_end (), now, file);
    }


    /***********************************************************
    Wipes the this.touched_files hash
    ***********************************************************/
    private void on_signal_clear_touched_files_timer_timeout () {
        //  this.touched_files = new GLib.HashTable<GLib.Timer, string> ();
    }


    /***********************************************************
    Emit a summary error, unless it was seen before
    ***********************************************************/
    private void on_signal_summary_error (string message) {
        //  if (this.unique_errors.contains (message)) {
        //      return;
        //  }

        //  this.unique_errors.insert (message);
        //  signal_sync_error (message, ErrorCategory.NORMAL);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_insufficient_local_storage () {
        //  on_signal_summary_error (
        //      _("Disk space is low : Downloads that would reduce free space "
        //      + "below %1 were skipped.")
        //          .printf (Common.Utility.octets_to_string (free_space_limit ())));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_insufficient_remote_storage () {
        //  var message = _("There is insufficient space available on the server for some uploads.");
        //  if (this.unique_errors.contains (message))
        //      return;

        //  this.unique_errors.insert (message);
        //  signal_sync_error (message, ErrorCategory.INSUFFICIENT_REMOTE_STORAGE);
    }


    /***********************************************************
    Check if the item is in the blocklist. If it should not be
    sync'ed because of the blocklist, update the item with the
    error instruction and proper error message, and return true.
    If the item is not in the blocklist, or the blocklist is
    stale, return false.
    ***********************************************************/
    private bool check_error_blocklisting (SyncFileItem item) {
        //  if (this.journal == null) {
        //      GLib.critical ("Journal is undefined!");
        //      return false;
        //  }

        //  SyncJournalErrorBlocklistRecord entry = this.journal.error_blocklist_entry (item.file);
        //  item.has_blocklist_entry = false;

        //  if (!entry.is_valid) {
        //      return false;
        //  }

        //  item.has_blocklist_entry = true;

        //  // If duration has expired, it's not blocklisted anymore
        //  time_t now = Common.Utility.q_date_time_to_time_t (GLib.DateTime.current_date_time_utc ());
        //  if (now >= entry.last_try_time + entry.ignore_duration) {
        //      GLib.info ("blocklist entry for " + item.file + " has expired!");
        //      return false;
        //  }

        //  // If the file has changed locally or on the server, the blocklist
        //  // entry no longer applies
        //  if (item.direction == SyncFileItem.Direction.UP) { // check the modtime
        //      if (item.modtime == 0 || entry.last_try_modtime == 0) {
        //          return false;
        //      } else if (item.modtime != entry.last_try_modtime) {
        //          GLib.info (item.file + " is blocklisted, but has changed mtime!");
        //          return false;
        //      } else if (item.rename_target != entry.rename_target) {
        //          GLib.info (item.file + " is blocklisted, but rename target changed from " + entry.rename_target);
        //          return false;
        //      }
        //  } else if (item.direction == SyncFileItem.Direction.DOWN) {
        //      // download, check the etag.
        //      if (item.etag == "" || entry.last_try_etag == "") {
        //          GLib.info (item.file + " one ETag is empty; no blocklisting.");
        //          return false;
        //      } else if (item.etag != entry.last_try_etag) {
        //          GLib.info (item.file + " is blocklisted, but has changed etag!");
        //          return false;
        //      }
        //  }

        //  int64 wait_seconds = entry.last_try_time + entry.ignore_duration - now;
        //  GLib.info ("Item is on blocklist: " + entry.file
        //          + "retries:" + entry.retry_count
        //          + "for another" + wait_seconds + "s");

        //  // We need to indicate that we skip this file due to blocklisting
        //  // for reporting and for making sure we don't update the blocklist
        //  // entry yet.
        //  // Classification is this this.instruction and this.status
        //  item.instruction = CSync.SyncInstructions.IGNORE;
        //  item.status = SyncFileItem.Status.BLOCKLISTED_ERROR;

        //  var wait_seconds_str = Common.Utility.duration_to_descriptive_string1 (1000 * wait_seconds);
        //  item.error_string = _("%1 (skipped due to earlier error, trying again in %2)").printf (entry.error_string, wait_seconds_str);

        //  if (entry.error_category == SyncJournalErrorBlocklistRecord.INSUFFICIENT_REMOTE_STORAGE) {
        //      on_signal_insufficient_remote_storage ();
        //  }

        //  return true;
    }


    /***********************************************************
    Cleans up unnecessary downloadinfo entries in the journal as
    well as their temporary files.
    ***********************************************************/
    private void delete_stale_download_infos (GLib.List<SyncFileItem> sync_items) {
        //  // Find all downloadinfo paths that we want to preserve.
        //  GLib.List<string> download_file_paths;
        //  foreach (unowned SyncFileItem it in sync_items) {
        //      if (it.direction == SyncFileItem.Direction.DOWN
        //          && it.type == ItemType.FILE
        //          && is_file_transfer_instruction (it.instruction)) {
        //          download_file_paths.insert (it.file);
        //      }
        //  }

        //  // Delete from journal and from filesystem.
        //  GLib.List<Common.SyncJournalDb.DownloadInfo> deleted_infos =
        //      this.journal.get_and_delete_stale_download_infos (download_file_paths);
        //  foreach (Common.SyncJournalDb.DownloadInfo deleted_info in deleted_infos) {
        //      string temporary_path = this.propagator.full_local_path (deleted_info.temporaryfile);
        //      GLib.info ("Deleting stale temporary file: " + temporary_path);
        //      FileSystem.remove (temporary_path);
        //  }
    }


    /***********************************************************
    Removes stale uploadinfos from the journal.
    ***********************************************************/
    private void delete_stale_upload_infos (GLib.List<SyncFileItem> sync_items) {
        //  // Find all blocklisted paths that we want to preserve.
        //  GLib.List<string> upload_file_paths;
        //  foreach (unowned SyncFileItem it in sync_items) {
        //      if (it.direction == SyncFileItem.Direction.UP
        //          && it.type == ItemType.FILE
        //          && is_file_transfer_instruction (it.instruction)) {
        //          upload_file_paths.insert (it.file);
        //      }
        //  }

        //  // Delete from journal.
        //  var ids = this.journal.delete_stale_upload_infos (upload_file_paths);

        //  // Delete the stales chunk on the server.
        //  if (account.capabilities.chunking_ng ()) {
        //      foreach (uint32 transfer_identifier in ids) {
        //          if (!transfer_identifier)
        //              continue; // Was not a chunked upload
        //          GLib.Uri url = Common.Utility.concat_url_path (account.url, "remote.php/dav/uploads/" + account.dav_user + "/" + string.number (transfer_identifier));
        //          (new KeychainChunkDeleteJob (account, url, this)).start ();
        //      }
        //  }
    }


    /***********************************************************
    Removes stale error blocklist entries from the journal.
    ***********************************************************/
    private void delete_stale_error_blocklist_entries (GLib.List<SyncFileItem> sync_items) {
        //  // Find all blocklisted paths that we want to preserve.
        //  GLib.List<string> blocklist_file_paths;
        //  foreach (unowned SyncFileItem it in sync_items) {
        //      if (it.has_blocklist_entry)
        //          blocklist_file_paths.insert (it.file);
        //  }

        //  // Delete from journal.
        //  this.journal.delete_stale_error_blocklist_entries (blocklist_file_paths);
    }

    // #if (GLib.T_VERSION < 0x050600)
    //  template <typename T>
    //  const std.add_const<T>.type q_as_const (T t) noexcept {
        //  return t;
    //  }
    // #endif


    /***********************************************************
    Removes stale and adds missing conflict records after sync
    ***********************************************************/
    private void conflict_record_maintenance () {
        //  // Remove stale conflict entries from the database
        //  // by checking which files still exist and removing the
        //  // missing ones.
        //  var conflict_record_paths = this.journal.conflict_record_paths ();
        //  foreach (var path in conflict_record_paths) {
        //      var fs_path = this.propagator.full_local_path (string.from_utf8 (path));
        //      if (!GLib.File.new_for_path (fs_path).exists ()) {
        //          this.journal.delete_conflict_record (path);
        //      }
        //  }

        //  // Did the sync see any conflict files that don't yet have records?
        //  // If so, add them now.
        //  //  
        //  // This happens when the conflicts table is new or when conflict files
        //  // are downlaoded but the server doesn't send conflict headers.
        //  foreach (var path in q_as_const (this.seen_conflict_files)) {
        //      //  GLib.assert_true (Common.Utility.is_conflict_file (path));

        //      var bapath = path.to_utf8 ();
        //      if (!conflict_record_paths.contains (bapath)) {
        //          ConflictRecord record;
        //          record.path = bapath;
        //          var base_path = Common.Utility.conflict_file_base_name_from_pattern (bapath);
        //          record.initial_base_path = base_path;

        //          // Determine fileid of target file
        //          Common.SyncJournalFileRecord base_record;
        //          if (this.journal.get_file_record (base_path, base_record) && base_record.is_valid) {
        //              record.base_file_id = base_record.file_id;
        //          }

        //          this.journal.conflict_record (record);
        //      }
        //  }
    }


    /***********************************************************
    Cleanup and emit the on_signal_finished signal
    ***********************************************************/
    private void on_signal_finalize (bool on_signal_success) {
        //  GLib.info ("Sync run took " + this.stop_watch.add_lap_time ("Sync Finished") + "ms.");
        //  this.stop_watch.stop ();

        //  if (this.discovery_phase != null) {
        //      this.discovery_phase.take ().delete_later ();
        //  }
        //  is_any_sync_running = false;
        //  this.sync_running = false;
        //  signal_finished (on_signal_success);

        //  // Delete the propagator only after emitting the signal.
        //  this.propagator = null;
        //  this.seen_conflict_files = new GLib.List<string> ();
        //  this.unique_errors = new GLib.List<string> ();
        //  this.local_discovery_paths = new GLib.List<string> ();
        //  this.local_discovery_style = DiscoveryPhase.LocalDiscoveryStyle.FILESYSTEM_ONLY;

        //  this.clear_touched_files_timer.start ();
    }


    /***********************************************************
    Check if we are allowed to propagate everything, and if we
    are not, adjust the instructions to recover
    ***********************************************************/
    private void check_for_permission (GLib.List<SyncFileItem> sync_items);


    private Common.RemotePermissions get_permissions (string file);


    /***********************************************************
    Instead of downloading files from the server, upload the
    files to the server.

    When the server is trying to send us lots of file in the
    past, this means that a backup was restored in the server.
    In that case, we should not simply overwrite the newer file
    on the file system with the older file from the backup on
    the server. Instead, we will upload the client file. But
    we still downloaded the old file in a conflict file just
    in case.
    ***********************************************************/
    private void restore_old_files (GLib.List<SyncFileItem> sync_items) {

        //  foreach (var sync_item in q_as_const (sync_items)) {
        //      if (sync_item.direction != SyncFileItem.Direction.DOWN)
        //          continue;

        //      switch (sync_item.instruction) {
        //      case CSync.SyncInstructions.SYNC:
        //          GLib.warning ("restore_old_files: RESTORING " + sync_item.file);
        //          sync_item.instruction = CSync.SyncInstructions.CONFLICT;
        //          break;
        //      case CSync.SyncInstructions.REMOVE:
        //          GLib.warning ("restore_old_files: RESTORING " + sync_item.file);
        //          sync_item.instruction = CSync.SyncInstructions.NEW;
        //          sync_item.direction = SyncFileItem.Direction.UP;
        //          break;
        //      case CSync.SyncInstructions.RENAME:
        //      case CSync.SyncInstructions.NEW:
        //          // Ideally we should try to revert the rename or remove, but this would be dangerous
        //          // without re-doing the reconcile phase.  So just let it happen.
        //      default:
        //          break;
        //      }
        //  }
    }


    /***********************************************************
    ***********************************************************/
    private static bool is_file_transfer_instruction (CSync.SyncInstructions instruction) {
        //  return instruction == CSync.SyncInstructions.CONFLICT
        //      || instruction == CSync.SyncInstructions.NEW
        //      || instruction == CSync.SyncInstructions.SYNC
        //      || instruction == CSync.SyncInstructions.TYPE_CHANGE;
    }

} // class SyncEngine

} // namespace LibSync
} // namespace Occ
    