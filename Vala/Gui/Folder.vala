/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QTimer>
//  #include <QDir>
//  #include <QSettings>
//  #include <QMessageBox>
//  #include <QPushButton>
//  #include <QApplicat
//  #include <stri
//  #include <QUuid>
//  #include <set>
//  #include <chrono>
//  #include <memory>


namespace Occ {

/***********************************************************
@brief The Folder class
@ingroup gui
***********************************************************/
class Folder : GLib.Object {

    const string VERSION_C = "version";

    /***********************************************************
    ***********************************************************/
    public enum ChangeReason {
        Other,
        UnLock
    }


    /***********************************************************
    Create a new Folder
    ***********************************************************/
    public Folder (FolderDefinition definition, AccountState account_state, std.unique_ptr<Vfs> vfs, GLib.Object parent = new GLib.Object ());

    ~Folder () override;

    /***********************************************************
    ***********************************************************/
    public using Map = GLib.HashMap<string, Folder>;
    public using MapIterator = QMapIterator<string, Folder>;


    /***********************************************************
    The account the folder is configured on.
    ***********************************************************/
    public AccountState account_state () {
        return this.account_state.data ();
    }


    /***********************************************************
    alias or nickname
    ***********************************************************/
    public string alias ();


    /***********************************************************
    ***********************************************************/
    public string short_gui_remote_path_or_app_name (); // since 2.0 we don't want to show aliases anymore, show the path instead

    /***********************************************************
    short local path to display on the GUI  (native separators)
    ***********************************************************/
    public string short_gui_local_path ();


    /***********************************************************
    canonical local folder path, always ends with /
    ***********************************************************/
    public string path ();


    /***********************************************************
    cleaned canonical folder path, like path () but never ends with a /

    Wrapper for QDir.clean_path (path ()) except for "Z:/",
    where it returns "Z:" instead of "Z:/".
    ***********************************************************/
    public string clean_path ();


    /***********************************************************
    remote folder path, usually without trailing /, exception "/"
    ***********************************************************/
    public string remote_path ();


    /***********************************************************
    remote folder path, always with a trailing /
    ***********************************************************/
    public string remote_path_trailing_slash ();

    /***********************************************************
    ***********************************************************/
    public void navigation_pane_clsid (QUuid clsid) {
        this.definition.navigation_pane_clsid = clsid;
    }


    /***********************************************************
    ***********************************************************/
    public QUuid navigation_pane_clsid () {
        return this.definition.navigation_pane_clsid;
    }


    /***********************************************************
    remote folder path with server url
    ***********************************************************/
    public GLib.Uri remote_url ();


    /***********************************************************
    switch sync on or off
    ***********************************************************/
    public void sync_paused (bool);

    /***********************************************************
    ***********************************************************/
    public bool sync_paused ();


    /***********************************************************
    Returns true when the folder may sync.
    ***********************************************************/
    public bool can_sync ();

    /***********************************************************
    ***********************************************************/
    public void prepare_to_sync ();


    /***********************************************************
    True if the folder is busy and can't initiate
    a synchronization
    ***********************************************************/
    public virtual bool is_busy ();


    /***********************************************************
    True if the folder is currently synchronizing
    ***********************************************************/
    public bool is_sync_running ();


    /***********************************************************
    return the last sync result with error message and status
    ***********************************************************/
    public SyncResult sync_result ();


    /***********************************************************
    This is called when the sync folder definition is removed. Do cleanups here.

    It removes the database, among other things.

    The folder is not in a valid state afterwards!
    ***********************************************************/
    public virtual void wipe_for_removal ();

    /***********************************************************
    ***********************************************************/
    public void on_associated_account_removed ();

    /***********************************************************
    ***********************************************************/
    public void sync_state (SyncResult.Status state);

    /***********************************************************
    ***********************************************************/
    public void dirty_network_limits ();


    /***********************************************************
    Ignore syncing of hidden files or not. This is defined in the
    folder definition
    ***********************************************************/
    public bool ignore_hidden_files ();


    /***********************************************************
    ***********************************************************/
    public void ignore_hidden_files (bool ignore);

    // Used by the Socket API
    public SyncJournalDb journal_database () {
        return this.journal;
    }


    /***********************************************************
    ***********************************************************/
    public SyncEngine sync_engine () {
    }


    /***********************************************************
    ***********************************************************/
    public Vfs vfs () {
        return this.vfs;
    }


    /***********************************************************
    ***********************************************************/
    public RequestEtagJob etag_job () {
        return this.request_etag_job;
    }


    /***********************************************************
    ***********************************************************/
    public std.chrono.milliseconds msec_since_last_sync () {
    }


    /***********************************************************
    ***********************************************************/
    public 
    }


    /***********************************************************
    ***********************************************************/
    public urn this.last_sync_duration;
    }


    /***********************************************************
    ***********************************************************/
    public int consecutive_follow_up_syncs () {
        return this.consecutive_follow_up_syncs;
    }
    public int consecutive_failing_syncs () {
        return this.consecutive_failing_syncs;
    }

    /// Saves the folder data in the account's settings.
    public void save_to_settings ();
    /// Removes the folder from the account's settings.
    public void remove_from_settings ();


    /***********************************************************
    Returns whether a file inside this folder should be excluded.
    ***********************************************************/
    public bool is_file_excluded_absolute (string full_path);


    /***********************************************************
    Returns whether a file inside this folder should be excluded.
    ***********************************************************/
    public bool is_file_excluded_relative (string relative_path);


    /***********************************************************
    Calls schedules this folder on the FolderMan after a short delay.

    This should be used in situations where a sync should be triggered
    because a local file was modified. Syncs don't upload files that were
    modified too recently, and this delay ensures the modification is
    far enough in the past.

    The delay doesn't reset with subsequent calls.
    ***********************************************************/
    public void schedule_this_folder_soon ();


    /***********************************************************
    Migration : When this flag is true, this folder will save to
    the backwards-compatible 'Folders' section in the config file.
    ***********************************************************/
    public void save_backwards_compatible (bool save);


    /***********************************************************
    Used to have placeholders : save in placeholder config section
    ***********************************************************/
    public void save_in_folders_with_placeholders () {
        this.save_in_folders_with_placeholders = true;
    }


    /***********************************************************
    Sets up this folder's folder_watcher if possible.

    May be called several times.
    ***********************************************************/
    public void register_folder_watcher ();


    /***********************************************************
    virtual files of some kind are enabled

    This is independent of whether new files will be virtual. It's possible to have this enabled
    and never have an automatic virtual file. But when it's on, the shell context menu will allow
    users to make existing files virtual.
    ***********************************************************/
    public bool virtual_files_enabled ();


    /***********************************************************
    ***********************************************************/
    public void virtual_files_enabled (bool enabled);

    /***********************************************************
    ***********************************************************/
    public void root_pin_state (PinState state);


    /***********************************************************
    Whether user desires a switch that couldn't be executed yet, see member
    ***********************************************************/
    public bool is_vfs_on_off_switch_pending () {
        return this.vfs_on_off_pending;
    }


    /***********************************************************
    ***********************************************************/
    public void vfs_on_off_switch_pending (bool pending) {
        this.vfs_on_off_pending = pending;
    }


    /***********************************************************
    ***********************************************************/
    public void switch_to_virtual_files ();

    /***********************************************************
    ***********************************************************/
    public void process_switched_to_virtual_files ();


    /***********************************************************
    Whether this folder should show selective sync ui
    ***********************************************************/
    public bool supports_selective_sync ();

    /***********************************************************
    ***********************************************************/
    public string file_from_local_path (string local_path);

signals:
    void sync_state_change ();
    void sync_started ();
    void sync_finished (SyncResult result);
    void progress_info (ProgressInfo progress);
    void new_big_folder_discovered (string ); // A new folder bigger than the threshold was discovered
    void sync_paused_changed (Folder *, bool paused);
    void can_sync_changed ();


    /***********************************************************
    Fires for each change inside this folder that wasn't caused
    by sync activity.
    ***********************************************************/
    void watched_file_changed_externally (string path);


    /***********************************************************
    terminate the current sync run
    ***********************************************************/
    public void on_terminate_sync ();

    // connected to the corresponding signals in the SyncEngine
    public void on_about_to_remove_all_files (SyncFileItem.Direction, std.function<void (bool)> callback);


    /***********************************************************
    Starts a sync operation

    If the list of changed files is known, it is passed.
    ***********************************************************/
    public void on_start_sync (string[] path_list = string[] ());

    /***********************************************************
    ***********************************************************/
    public int on_discard_download_progress ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public int on_wipe_error_blocklist ();


    public int on_error_block_list_entry_count ();


    /***********************************************************
    Triggered by the folder watcher when a file/dir in this folder
    changes. Needs to check whether this change should trigger a new
    sync run to be scheduled.
    ***********************************************************/
    public void on_watched_path_changed (string path, ChangeReason reason);


    /***********************************************************
    Mark a virtual file as being requested for download, and on_start a sync.

    "implicit" here means that this download request comes from the user wan
    to access the file's data. The user did not change the file's pin state.
    If the file is currently VfsItemAvailability.ONLINE_ONLY its state will change to Unspecif

    The download re
    in the database. This is necessary since the hydration is not driven by
    the pin state.

    relativepath is the folder-relative path to the file (including the extension)

    Note, passing directories is not supported. Files only.
    ***********************************************************/
    public void on_implicitly_hydrate_file (string relativepath);


    /***********************************************************
    Adds the path to the local discovery list

    A weaker version of on_next_sync_full_local_discovery () that just
    schedules all parent and child items of the path for local
    discovery.
    ***********************************************************/
    public void on_schedule_path_for_local_discovery (string relative_path);


    /***********************************************************
    Ensures that the next sync performs a full local discovery.
    ***********************************************************/
    public void on_next_sync_full_local_discovery ();


    /***********************************************************
    ***********************************************************/
    private void on_sync_started ();
    private void on_sync_finished (bool);


    /***********************************************************
    Adds a error message that's not tied to a specific item.
    ***********************************************************/
    private void on_sync_error (string message, ErrorCategory category = ErrorCategory.NORMAL);

    /***********************************************************
    ***********************************************************/
    private void on_add_error_to_gui (SyncFileItem.Status status, string error_message, string subject = {});

    /***********************************************************
    ***********************************************************/
    private void on_transmission_progress (ProgressInfo pi);

    /***********************************************************
    ***********************************************************/
    private 
    private void on_run_etag_job ();
    private void on_etag_retrieved (GLib.ByteArray , GLib.DateTime tp);
    private void on_etag_retrieved_from_sync_engine (GLib.ByteArray , GLib.DateTime time);

    /***********************************************************
    ***********************************************************/
    private void on_emit_finished_delayed ();

    /***********************************************************
    ***********************************************************/
    private void on_new_big_folder_discovered (string , bool is_external);

    /***********************************************************
    ***********************************************************/
    private void on_log_propagation_start ();


    /***********************************************************
    Adds this folder to the list of scheduled folders in the
    FolderMan.
    ***********************************************************/
    private void on_schedule_this_folder ();


    /***********************************************************
    Adjust sync result based on conflict data from IssuesWidget.

    This is pretty awkward, but IssuesWidget just keeps better track
    of conflicts across partial local discovery.
    ***********************************************************/
    private void on_folder_conflicts (string folder, string[] conflict_paths);


    /***********************************************************
    Warn users if they create a file or folder that is selective-sync excluded
    ***********************************************************/
    private void on_warn_on_new_excluded_item (SyncJournalFileRecord record, QStringRef path);


    /***********************************************************
    Warn users about an unreliable folder watcher
    ***********************************************************/
    private void on_watcher_unreliable (string message);


    /***********************************************************
    Aborts any running sync and blocks it until hydration is on_finished.

    Hydration circumvents the regular SyncEngine and both mustn't be running
    at the same time.
    ***********************************************************/
    private void on_hydration_starts ();


    /***********************************************************
    Unblocks normal sync operation
    ***********************************************************/
    private void on_hydration_done ();


    /***********************************************************
    ***********************************************************/
    private void connect_sync_root ();

    /***********************************************************
    ***********************************************************/
    private bool reload_excludes ();

    /***********************************************************
    ***********************************************************/
    private void show_sync_result_popup ();

    /***********************************************************
    ***********************************************************/
    private void check_local_path ();

    /***********************************************************
    ***********************************************************/
    private void sync_options ();

    /***********************************************************
    ***********************************************************/
    private enum LogStatus {
        Log_status_remove,
        Log_status_rename,
        Log_status_move,
        Log_status_new,
        Log_status_error,
        Log_status_conflict,
        Log_status_updated,
        Log_status_file_locked
    }

    /***********************************************************
    ***********************************************************/
    private void create_gui_log (string filename, LogStatus status, int count,

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 
    private AccountStatePtr this.account_state;
    private FolderDefinition this.definition;
    private string this.canonical_local_path; // As returned with QFileInfo:canonical_file_path.  Always ends with "/"

    /***********************************************************
    ***********************************************************/
    private SyncResult this.sync_result;
    private QScopedPointer<SyncEngine> this.engine;
    private QPointer<RequestEtagJob> this.request_etag_job;
    private GLib.ByteArray this.last_etag;
    private QElapsedTimer this.time_since_last_sync_done;
    private QElapsedTimer this.time_since_last_sync_start;
    private QElapsedTimer this.time_since_last_full_local_discovery;
    private std.chrono.milliseconds this.last_sync_duration;

    /// The number of syncs that failed in a row.
    /// Reset when a sync is successful.
    private int this.consecutive_failing_syncs;

    /// The number of requested follow-up syncs.
    /// Reset when no follow-up is requested.
    private int this.consecutive_follow_up_syncs;

    /***********************************************************
    ***********************************************************/
    private mutable SyncJournalDb this.journal;

    /***********************************************************
    ***********************************************************/
    private QScopedPointer<SyncRunFileLog> this.file_log;

    /***********************************************************
    ***********************************************************/
    private QTimer this.schedule_self_timer;


    /***********************************************************
    When the same local path is synced to multiple accounts, only one
    of them can be stored in the settings in a way that's compatible
    with old clients that don't support it. This flag marks folders
    that shall be written in a backwards-compatible way, by being set
    on the first* Folder instance that was configured for each local
    path.
    ***********************************************************/
    private bool this.save_backwards_compatible = false;


    /***********************************************************
    Whether the folder should be saved in that settings group

    If it was read from there it had virtual files enabled at some
    point and might still have database entries or suffix-virtual files even
    if they are disabled right now. This flag ensures folders that
    were in that group once never go back.
    ***********************************************************/
    private bool this.save_in_folders_with_placeholders = false;


    /***********************************************************
    Whether a vfs mode switch is pending

    When the user desires that vfs be switched on/off but it hasn't been
    executed yet (syncs are still running), some options should be hidden,
    disabled or different.
    ***********************************************************/
    private bool this.vfs_on_off_pending = false;


    /***********************************************************
    Whether this folder has just switched to VFS or not
    ***********************************************************/
    private bool this.has_switched_to_vfs = false;


    /***********************************************************
    Watches this folder's local directory for changes.

    Created by register_folder_watcher (), triggers on_watched_path_changed ()
    ***********************************************************/
    private QScopedPointer<Folder_watcher> this.folder_watcher;


    /***********************************************************
    Keeps track of locally dirty files so we can skip local discovery sometimes.
    ***********************************************************/
    private QScopedPointer<LocalDiscoveryTracker> this.local_discovery_tracker;


    /***********************************************************
    The vfs mode instance (created by plugin) to use. Never null.
    ***********************************************************/
    private unowned<Vfs> this.vfs;
}

Folder.Folder (FolderDefinition definition,
    AccountState account_state, std.unique_ptr<Vfs> vfs,
    GLib.Object parent)
    : GLib.Object (parent)
    this.account_state (account_state)
    this.definition (definition)
    this.last_sync_duration (0)
    this.consecutive_failing_syncs (0)
    this.consecutive_follow_up_syncs (0)
    this.journal (this.definition.absolute_journal_path ())
    this.file_log (new SyncRunFileLog)
    this.vfs (vfs.release ()) {
    this.time_since_last_sync_start.on_start ();
    this.time_since_last_sync_done.on_start ();

    SyncResult.Status status = SyncResult.Status.NOT_YET_STARTED;
    if (definition.paused) {
        status = SyncResult.Status.PAUSED;
    }
    this.sync_result.status (status);

    // check if the local path exists
    check_local_path ();

    this.sync_result.folder (this.definition.alias);

    this.engine.on_reset (new SyncEngine (this.account_state.account (), path (), remote_path (), this.journal));
    // pass the setting if hidden files are to be ignored, will be read in csync_update
    this.engine.ignore_hidden_files (this.definition.ignore_hidden_files);

    ConfigFile.setup_default_exclude_file_paths (this.engine.excluded_files ());
    if (!reload_excludes ())
        GLib.warn (lc_folder, "Could not read system exclude file");

    connect (this.account_state.data (), &AccountState.is_connected_changed, this, &Folder.can_sync_changed);
    connect (this.engine.data (), &SyncEngine.root_etag, this, &Folder.on_etag_retrieved_from_sync_engine);

    connect (this.engine.data (), &SyncEngine.started, this, &Folder.on_sync_started, Qt.QueuedConnection);
    connect (this.engine.data (), &SyncEngine.on_finished, this, &Folder.on_sync_finished, Qt.QueuedConnection);

    connect (this.engine.data (), &SyncEngine.about_to_remove_all_files,
        this, &Folder.on_about_to_remove_all_files);
    connect (this.engine.data (), &SyncEngine.transmission_progress, this, &Folder.on_transmission_progress);
    connect (this.engine.data (), &SyncEngine.item_completed,
        this, &Folder.on_item_completed);
    connect (this.engine.data (), &SyncEngine.new_big_folder,
        this, &Folder.on_new_big_folder_discovered);
    connect (this.engine.data (), &SyncEngine.seen_locked_file, FolderMan.instance (), &FolderMan.on_sync_once_file_unlocks);
    connect (this.engine.data (), &SyncEngine.about_to_propagate,
        this, &Folder.on_log_propagation_start);
    connect (this.engine.data (), &SyncEngine.sync_error, this, &Folder.on_sync_error);

    connect (this.engine.data (), &SyncEngine.add_error_to_gui, this, &Folder.on_add_error_to_gui);

    this.schedule_self_timer.single_shot (true);
    this.schedule_self_timer.interval (SyncEngine.minimum_file_age_for_upload);
    connect (&this.schedule_self_timer, &QTimer.timeout,
        this, &Folder.on_schedule_this_folder);

    connect (ProgressDispatcher.instance (), &ProgressDispatcher.folder_conflicts,
        this, &Folder.on_folder_conflicts);

    this.local_discovery_tracker.on_reset (new LocalDiscoveryTracker);
    connect (this.engine.data (), &SyncEngine.on_finished,
        this.local_discovery_tracker.data (), &LocalDiscoveryTracker.on_sync_finished);
    connect (this.engine.data (), &SyncEngine.item_completed,
        this.local_discovery_tracker.data (), &LocalDiscoveryTracker.on_item_completed);

    // Potentially upgrade suffix vfs to windows vfs
    ENFORCE (this.vfs);
    if (this.definition.virtual_files_mode == Vfs.WithSuffix
        && this.definition.upgrade_vfs_mode) {
        if (is_vfs_plugin_available (Vfs.WindowsCfApi)) {
            if (var winvfs = create_vfs_from_plugin (Vfs.WindowsCfApi)) {
                // Wipe the existing suffix files from fs and journal
                SyncEngine.wipe_virtual_files (path (), this.journal, this.vfs);

                // Then switch to winvfs mode
                this.vfs.on_reset (winvfs.release ());
                this.definition.virtual_files_mode = Vfs.WindowsCfApi;
            }
        }
        save_to_settings ();
    }

    // Initialize the vfs plugin
    start_vfs ();
}

Folder.~Folder () {
    // If wipe_for_removal () was called the vfs has already shut down.
    if (this.vfs)
        this.vfs.stop ();

    // Reset then engine first as it will on_abort and try to access members of the Folder
    this.engine.on_reset ();
}

void Folder.check_local_path () {
    const QFileInfo fi (this.definition.local_path);
    this.canonical_local_path = fi.canonical_file_path ();
    if (this.canonical_local_path.is_empty ()) {
        GLib.warn (lc_folder) << "Broken symlink:" << this.definition.local_path;
        this.canonical_local_path = this.definition.local_path;
    } else if (!this.canonical_local_path.ends_with ('/')) {
        this.canonical_local_path.append ('/');
    }

    if (fi.is_dir () && fi.is_readable ()) {
        GLib.debug (lc_folder) << "Checked local path ok";
    } else {
        // Check directory again
        if (!FileSystem.file_exists (this.definition.local_path, fi)) {
            this.sync_result.append_error_string (_("Local folder %1 does not exist.").arg (this.definition.local_path));
            this.sync_result.status (SyncResult.Status.SETUP_ERROR);
        } else if (!fi.is_dir ()) {
            this.sync_result.append_error_string (_("%1 should be a folder but is not.").arg (this.definition.local_path));
            this.sync_result.status (SyncResult.Status.SETUP_ERROR);
        } else if (!fi.is_readable ()) {
            this.sync_result.append_error_string (_("%1 is not readable.").arg (this.definition.local_path));
            this.sync_result.status (SyncResult.Status.SETUP_ERROR);
        }
    }
}

string Folder.short_gui_remote_path_or_app_name () {
    if (remote_path ().length () > 0 && remote_path () != QLatin1String ("/")) {
        string a = GLib.File (remote_path ()).filename ();
        if (a.starts_with ('/')) {
            a = a.remove (0, 1);
        }
        return a;
    } else {
        return Theme.instance ().app_name_gui ();
    }
}

string Folder.alias () {
    return this.definition.alias;
}

string Folder.path () {
    return this.canonical_local_path;
}

string Folder.short_gui_local_path () {
    string p = this.definition.local_path;
    string home = QDir.home_path ();
    if (!home.ends_with ('/')) {
        home.append ('/');
    }
    if (p.starts_with (home)) {
        p = p.mid (home.length ());
    }
    if (p.length () > 1 && p.ends_with ('/')) {
        p.chop (1);
    }
    return QDir.to_native_separators (p);
}

bool Folder.ignore_hidden_files () {
    bool re (this.definition.ignore_hidden_files);
    return re;
}

void Folder.ignore_hidden_files (bool ignore) {
    this.definition.ignore_hidden_files = ignore;
}

string Folder.clean_path () {
    string cleaned_path = QDir.clean_path (this.canonical_local_path);

    if (cleaned_path.length () == 3 && cleaned_path.ends_with (":/"))
        cleaned_path.remove (2, 1);

    return cleaned_path;
}

bool Folder.is_busy () {
    return is_sync_running ();
}

bool Folder.is_sync_running () {
    return this.engine.is_sync_running () || (this.vfs && this.vfs.is_hydrating ());
}

string Folder.remote_path () {
    return this.definition.target_path;
}

string Folder.remote_path_trailing_slash () {
    string result = remote_path ();
    if (!result.ends_with ('/'))
        result.append ('/');
    return result;
}

GLib.Uri Folder.remote_url () {
    return Utility.concat_url_path (this.account_state.account ().dav_url (), remote_path ());
}

bool Folder.sync_paused () {
    return this.definition.paused;
}

bool Folder.can_sync () {
    return !sync_paused () && account_state ().is_connected ();
}

void Folder.sync_paused (bool paused) {
    if (paused == this.definition.paused) {
        return;
    }

    this.definition.paused = paused;
    save_to_settings ();

    if (!paused) {
        sync_state (SyncResult.Status.NOT_YET_STARTED);
    } else {
        sync_state (SyncResult.Status.PAUSED);
    }
    /* emit */ sync_paused_changed (this, paused);
    /* emit */ sync_state_change ();
    /* emit */ can_sync_changed ();
}

void Folder.on_associated_account_removed () {
    if (this.vfs) {
        this.vfs.stop ();
        this.vfs.unregister_folder ();
    }
}

void Folder.sync_state (SyncResult.Status state) {
    this.sync_result.status (state);
}

SyncResult Folder.sync_result () {
    return this.sync_result;
}

void Folder.prepare_to_sync () {
    this.sync_result.on_reset ();
    this.sync_result.status (SyncResult.Status.NOT_YET_STARTED);
}

void Folder.on_run_etag_job () {
    GLib.info (lc_folder) << "Trying to check" << remote_url ().to_string () << "for changes via ETag check. (time since last sync:" << (this.time_since_last_sync_done.elapsed () / 1000) << "s)";

    AccountPointer account = this.account_state.account ();

    if (this.request_etag_job) {
        GLib.info (lc_folder) << remote_url ().to_string () << "has ETag job queued, not trying to sync";
        return;
    }

    if (!can_sync ()) {
        GLib.info (lc_folder) << "Not syncing.  :" << remote_url ().to_string () << this.definition.paused << AccountState.state_string (this.account_state.state ());
        return;
    }

    // Do the ordinary etag check for the root folder and schedule a
    // sync if it's different.

    this.request_etag_job = new RequestEtagJob (account, remote_path (), this);
    this.request_etag_job.on_timeout (60 * 1000);
    // check if the etag is different when retrieved
    GLib.Object.connect (this.request_etag_job.data (), &RequestEtagJob.on_etag_retrieved, this, &Folder.on_etag_retrieved);
    FolderMan.instance ().on_schedule_e_tag_job (alias (), this.request_etag_job);
    // The this.request_etag_job is var deleting itself on finish. Our guard pointer this.request_etag_job will then be null.
}

void Folder.on_etag_retrieved (GLib.ByteArray etag, GLib.DateTime tp) {
    // re-enable sync if it was disabled because network was down
    FolderMan.instance ().sync_enabled (true);

    if (this.last_etag != etag) {
        GLib.info (lc_folder) << "Compare etag with previous etag : last:" << this.last_etag << ", received:" << etag << ". CHANGED";
        this.last_etag = etag;
        on_schedule_this_folder ();
    }

    this.account_state.tag_last_successful_etag_request (tp);
}

void Folder.on_etag_retrieved_from_sync_engine (GLib.ByteArray etag, GLib.DateTime time) {
    GLib.info (lc_folder) << "Root etag from during sync:" << etag;
    account_state ().tag_last_successful_etag_request (time);
    this.last_etag = etag;
}

void Folder.show_sync_result_popup () {
    if (this.sync_result.first_item_new ()) {
        create_gui_log (this.sync_result.first_item_new ().destination (), Log_status_new, this.sync_result.num_new_items ());
    }
    if (this.sync_result.first_item_deleted ()) {
        create_gui_log (this.sync_result.first_item_deleted ().destination (), Log_status_remove, this.sync_result.num_removed_items ());
    }
    if (this.sync_result.first_item_updated ()) {
        create_gui_log (this.sync_result.first_item_updated ().destination (), Log_status_updated, this.sync_result.num_updated_items ());
    }

    if (this.sync_result.first_item_renamed ()) {
        LogStatus status (Log_status_rename);
        // if the path changes it's rather a move
        QDir ren_target = QFileInfo (this.sync_result.first_item_renamed ().rename_target).dir ();
        QDir ren_source = QFileInfo (this.sync_result.first_item_renamed ().file).dir ();
        if (ren_target != ren_source) {
            status = Log_status_move;
        }
        create_gui_log (this.sync_result.first_item_renamed ().file, status,
            this.sync_result.num_renamed_items (), this.sync_result.first_item_renamed ().rename_target);
    }

    if (this.sync_result.first_new_conflict_item ()) {
        create_gui_log (this.sync_result.first_new_conflict_item ().destination (), Log_status_conflict, this.sync_result.num_new_conflict_items ());
    }
    if (int error_count = this.sync_result.num_error_items ()) {
        create_gui_log (this.sync_result.first_item_error ().file, Log_status_error, error_count);
    }

    if (int locked_count = this.sync_result.num_locked_items ()) {
        create_gui_log (this.sync_result.first_item_locked ().file, Log_status_file_locked, locked_count);
    }

    GLib.info (lc_folder) << "Folder" << this.sync_result.folder () << "sync result : " << this.sync_result.status ();
}

void Folder.create_gui_log (string filename, LogStatus status, int count,
    const string rename_target) {
    if (count > 0) {
        Logger logger = Logger.instance ();

        string file = QDir.to_native_separators (filename);
        string text;

        switch (status) {
        case Log_status_remove:
            if (count > 1) {
                text = _("%1 and %n other file (s) have been removed.", "", count - 1).arg (file);
            } else {
                text = _("%1 has been removed.", "%1 names a file.").arg (file);
            }
            break;
        case Log_status_new:
            if (count > 1) {
                text = _("%1 and %n other file (s) have been added.", "", count - 1).arg (file);
            } else {
                text = _("%1 has been added.", "%1 names a file.").arg (file);
            }
            break;
        case Log_status_updated:
            if (count > 1) {
                text = _("%1 and %n other file (s) have been updated.", "", count - 1).arg (file);
            } else {
                text = _("%1 has been updated.", "%1 names a file.").arg (file);
            }
            break;
        case Log_status_rename:
            if (count > 1) {
                text = _("%1 has been renamed to %2 and %n other file (s) have been renamed.", "", count - 1).arg (file, rename_target);
            } else {
                text = _("%1 has been renamed to %2.", "%1 and %2 name files.").arg (file, rename_target);
            }
            break;
        case Log_status_move:
            if (count > 1) {
                text = _("%1 has been moved to %2 and %n other file (s) have been moved.", "", count - 1).arg (file, rename_target);
            } else {
                text = _("%1 has been moved to %2.").arg (file, rename_target);
            }
            break;
        case Log_status_conflict:
            if (count > 1) {
                text = _("%1 has and %n other file (s) have sync conflicts.", "", count - 1).arg (file);
            } else {
                text = _("%1 has a sync conflict. Please check the conflict file!").arg (file);
            }
            break;
        case Log_status_error:
            if (count > 1) {
                text = _("%1 and %n other file (s) could not be synced due to errors. See the log for details.", "", count - 1).arg (file);
            } else {
                text = _("%1 could not be synced due to an error. See the log for details.").arg (file);
            }
            break;
        case Log_status_file_locked:
            if (count > 1) {
                text = _("%1 and %n other file (s) are currently locked.", "", count -1).arg (file);
            } else {
                text = _("%1 is currently locked.").arg (file);
            }
            break;
        }

        if (!text.is_empty ()) {
            // Ignores the settings in case of an error or conflict
            if (status == Log_status_error || status == Log_status_conflict)
                logger.post_optional_gui_log (_("Sync Activity"), text);
        }
    }
}

void Folder.start_vfs () {
    ENFORCE (this.vfs);
    ENFORCE (this.vfs.mode () == this.definition.virtual_files_mode);

    VfsSetupParams vfs_params;
    vfs_params.filesystem_path = path ();
    vfs_params.display_name = short_gui_remote_path_or_app_name ();
    vfs_params.alias = alias ();
    vfs_params.remote_path = remote_path_trailing_slash ();
    vfs_params.account = this.account_state.account ();
    vfs_params.journal = this.journal;
    vfs_params.provider_name = Theme.instance ().app_name_gui ();
    vfs_params.provider_version = Theme.instance ().version ();
    vfs_params.multiple_accounts_registered = AccountManager.instance ().accounts ().size () > 1;

    connect (this.vfs.data (), &Vfs.begin_hydrating, this, &Folder.on_hydration_starts);
    connect (this.vfs.data (), &Vfs.done_hydrating, this, &Folder.on_hydration_done);

    connect (&this.engine.sync_file_status_tracker (), &SyncFileStatusTracker.file_status_changed,
            this.vfs.data (), &Vfs.on_file_status_changed);

    this.vfs.on_start (vfs_params);

    // Immediately mark the sqlite temporaries as excluded. They get recreated
    // on database-open and need to get marked again every time.
    string state_database_file = this.journal.database_file_path ();
    this.journal.open ();
    this.vfs.on_file_status_changed (state_database_file + "-wal", SyncFileStatus.SyncFileStatusTag.STATUS_EXCLUDED);
    this.vfs.on_file_status_changed (state_database_file + "-shm", SyncFileStatus.SyncFileStatusTag.STATUS_EXCLUDED);
}

int Folder.on_discard_download_progress () {
    // Delete from journal and from filesystem.
    QDir folderpath (this.definition.local_path);
    GLib.Set<string> keep_nothing;
    const GLib.Vector<SyncJournalDb.DownloadInfo> deleted_infos =
        this.journal.get_and_delete_stale_download_infos (keep_nothing);
    for (var deleted_info : deleted_infos) {
        const string tmppath = folderpath.file_path (deleted_info.tmpfile);
        GLib.info (lc_folder) << "Deleting temporary file : " << tmppath;
        FileSystem.remove (tmppath);
    }
    return deleted_infos.size ();
}

int Folder.on_download_info_count () {
    return this.journal.on_download_info_count ();
}

int Folder.on_error_block_list_entry_count () {
    return this.journal.on_error_block_list_entry_count ();
}

int Folder.on_wipe_error_blocklist () {
    return this.journal.wipe_error_blocklist ();
}

void Folder.on_watched_path_changed (string path, ChangeReason reason) {
    if (!path.starts_with (this.path ())) {
        GLib.debug (lc_folder) << "Changed path is not contained in folder, ignoring:" << path;
        return;
    }

    var relative_path = path.mid_ref (this.path ().size ());

    // Add to list of locally modified paths
    //
    // We do this before checking for our own sync-related changes to make
    // extra sure to not miss relevant changes.
    var relative_path_bytes = relative_path.to_utf8 ();
    this.local_discovery_tracker.add_touched_path (relative_path_bytes);

    // The folder watcher fires a lot of bogus notifications during
    // a sync operation, both for actual user files and the database
    // and log. Therefore we check notifications against operations
    // the sync is doing to filter out our own changes.

    // Use the path to figure out whether it was our own change
    if (this.engine.was_file_touched (path)) {
        GLib.debug (lc_folder) << "Changed path was touched by SyncEngine, ignoring:" << path;
        return;
    }


    SyncJournalFileRecord record;
    this.journal.get_file_record (relative_path_bytes, record);
    if (reason != ChangeReason.UnLock) {
        // Check that the mtime/size actually changed or there was
        // an attribute change (pin state) that caused the notification
        bool spurious = false;
        if (record.is_valid ()
            && !FileSystem.file_changed (path, record.file_size, record.modtime)) {
            spurious = true;

            if (var pin_state = this.vfs.pin_state (relative_path.to_string ())) {
                if (*pin_state == PinState.PinState.ALWAYS_LOCAL && record.is_virtual_file ())
                    spurious = false;
                if (*pin_state == PinState.VfsItemAvailability.ONLINE_ONLY && record.is_file ())
                    spurious = false;
            }
        }
        if (spurious) {
            GLib.info (lc_folder) << "Ignoring spurious notification for file" << relative_path;
            return; // probably a spurious notification
        }
    }
    on_warn_on_new_excluded_item (record, relative_path);

    /* emit */ watched_file_changed_externally (path);

    // Also schedule this folder for a sync, but only after some delay:
    // The sync will not upload files that were changed too recently.
    schedule_this_folder_soon ();
}

void Folder.on_implicitly_hydrate_file (string relativepath) {
    GLib.info (lc_folder) << "Implicitly hydrate virtual file:" << relativepath;

    // Set in the database that we should download the file
    SyncJournalFileRecord record;
    this.journal.get_file_record (relativepath.to_utf8 (), record);
    if (!record.is_valid ()) {
        GLib.info (lc_folder) << "Did not find file in database";
        return;
    }
    if (!record.is_virtual_file ()) {
        GLib.info (lc_folder) << "The file is not virtual";
        return;
    }
    record.type = ItemTypeVirtualFileDownload;
    this.journal.file_record (record);

    // Change the file's pin state if it's contradictory to being hydrated
    // (suffix-virtual file's pin state is stored at the hydrated path)
    const var pin = this.vfs.pin_state (relativepath);
    if (pin && *pin == PinState.VfsItemAvailability.ONLINE_ONLY) {
        if (!this.vfs.pin_state (relativepath, PinState.PinState.UNSPECIFIED)) {
            GLib.warn (lc_folder) << "Could not set pin state of" << relativepath << "to unspecified";
        }
    }

    // Add to local discovery
    on_schedule_path_for_local_discovery (relativepath);
    on_schedule_this_folder ();
}

void Folder.virtual_files_enabled (bool enabled) {
    Vfs.Mode new_mode = this.definition.virtual_files_mode;
    if (enabled && this.definition.virtual_files_mode == Vfs.Off) {
        new_mode = best_available_vfs_mode ();
    } else if (!enabled && this.definition.virtual_files_mode != Vfs.Off) {
        new_mode = Vfs.Off;
    }

    if (new_mode != this.definition.virtual_files_mode) {
        // TODO : Must wait for current sync to finish!
        SyncEngine.wipe_virtual_files (path (), this.journal, this.vfs);

        this.vfs.stop ();
        this.vfs.unregister_folder ();

        disconnect (this.vfs.data (), null, this, null);
        disconnect (&this.engine.sync_file_status_tracker (), null, this.vfs.data (), null);

        this.vfs.on_reset (create_vfs_from_plugin (new_mode).release ());

        this.definition.virtual_files_mode = new_mode;
        start_vfs ();
        if (new_mode != Vfs.Off) {
            this.save_in_folders_with_placeholders = true;
            switch_to_virtual_files ();
        }
        save_to_settings ();
    }
}

void Folder.root_pin_state (PinState state) {
    if (!this.vfs.pin_state ("", state)) {
        GLib.warn (lc_folder) << "Could not set root pin state of" << this.definition.alias;
    }

    // We don't actually need discovery, but it's important to recurse
    // into all folders, so the changes can be applied.
    on_next_sync_full_local_discovery ();
}

void Folder.switch_to_virtual_files () {
    SyncEngine.switch_to_virtual_files (path (), this.journal, this.vfs);
    this.has_switched_to_vfs = true;
}

void Folder.process_switched_to_virtual_files () {
    if (this.has_switched_to_vfs) {
        this.has_switched_to_vfs = false;
        save_to_settings ();
    }
}

bool Folder.supports_selective_sync () {
    return !virtual_files_enabled () && !is_vfs_on_off_switch_pending ();
}

void Folder.save_to_settings () {
    // Remove first to make sure we don't get duplicates
    remove_from_settings ();

    var settings = this.account_state.settings ();
    string settings_group = QStringLiteral ("Multifolders");

    // True if the folder path appears in only one account
    const var folder_map = FolderMan.instance ().map ();
    const var one_account_only = std.none_of (folder_map.cbegin (), folder_map.cend (), [this] (var other) {
        return other != this && other.clean_path () == this.clean_path ();
    });

    if (virtual_files_enabled () || this.save_in_folders_with_placeholders) {
        // If virtual files are enabled or even were enabled at some point,
        // save the folder to a group that will not be read by older (<2.5.0) clients.
        // The name is from when virtual files were called placeholders.
        settings_group = QStringLiteral ("FoldersWithPlaceholders");
    } else if (this.save_backwards_compatible || one_account_only) {
        // The folder is saved to backwards-compatible "Folders"
        // section only if it has the migrate flag set (i.e. was in
        // there before) or if the folder is the only one for the
        // given target path.
        // This ensures that older clients will not read a configuration
        // where two folders for different accounts point at the same
        // local folders.
        settings_group = QStringLiteral ("Folders");
    }

    settings.begin_group (settings_group);
    // Note: Each of these groups might have a "version" tag, but that's
    //       currently unused.
    settings.begin_group (FolderMan.escape_alias (this.definition.alias));
    FolderDefinition.save (*settings, this.definition);

    settings.sync ();
    GLib.info (lc_folder) << "Saved folder" << this.definition.alias << "to settings, status" << settings.status ();
}

void Folder.remove_from_settings () {
    var settings = this.account_state.settings ();
    settings.begin_group (QLatin1String ("Folders"));
    settings.remove (FolderMan.escape_alias (this.definition.alias));
    settings.end_group ();
    settings.begin_group (QLatin1String ("Multifolders"));
    settings.remove (FolderMan.escape_alias (this.definition.alias));
    settings.end_group ();
    settings.begin_group (QLatin1String ("FoldersWithPlaceholders"));
    settings.remove (FolderMan.escape_alias (this.definition.alias));
}

bool Folder.is_file_excluded_absolute (string full_path) {
    return this.engine.excluded_files ().is_excluded (full_path, path (), this.definition.ignore_hidden_files);
}

bool Folder.is_file_excluded_relative (string relative_path) {
    return this.engine.excluded_files ().is_excluded (path () + relative_path, path (), this.definition.ignore_hidden_files);
}

void Folder.on_terminate_sync () {
    GLib.info (lc_folder) << "folder " << alias () << " Terminating!";

    if (this.engine.is_sync_running ()) {
        this.engine.on_abort ();

        sync_state (SyncResult.Status.SYNC_ABORT_REQUESTED);
    }
}

void Folder.wipe_for_removal () {
    // Delete files that have been partially downloaded.
    on_discard_download_progress ();

    // Unregister the socket API so it does not keep the .sync_journal file open
    FolderMan.instance ().socket_api ().on_unregister_path (alias ());
    this.journal.close (); // close the sync journal

    // Remove database and temporaries
    string state_database_file = this.engine.journal ().database_file_path ();

    GLib.File file = new GLib.File (state_database_file);
    if (file.exists ()) {
        if (!file.remove ()) {
            GLib.warn (lc_folder) << "Failed to remove existing csync State_d_b " << state_database_file;
        } else {
            GLib.info (lc_folder) << "wipe : Removed csync State_d_b " << state_database_file;
        }
    } else {
        GLib.warn (lc_folder) << "statedatabase is empty, can not remove.";
    }

    // Also remove other database related files
    GLib.File.remove (state_database_file + ".ctmp");
    GLib.File.remove (state_database_file + "-shm");
    GLib.File.remove (state_database_file + "-wal");
    GLib.File.remove (state_database_file + "-journal");

    this.vfs.stop ();
    this.vfs.unregister_folder ();
    this.vfs.on_reset (null); // warning : folder now in an invalid state
}

bool Folder.reload_excludes () {
    return this.engine.excluded_files ().on_reload_exclude_files ();
}

void Folder.on_start_sync (string[] path_list) {
    //  Q_UNUSED (path_list)

    if (is_busy ()) {
        q_c_critical (lc_folder) << "ERROR csync is still running and new sync requested.";
        return;
    }

    this.time_since_last_sync_start.on_start ();
    this.sync_result.status (SyncResult.Status.SYNC_PREPARE);
    /* emit */ sync_state_change ();

    GLib.info (lc_folder) << "*** Start syncing " << remote_url ().to_string () << " -" << APPLICATION_NAME << "client version"
                     << q_printable (Theme.instance ().version ());

    this.file_log.on_start (path ());

    if (!reload_excludes ()) {
        on_sync_error (_("Could not read system exclude file"));
        QMetaObject.invoke_method (this, "on_sync_finished", Qt.QueuedConnection, Q_ARG (bool, false));
        return;
    }

    dirty_network_limits ();
    sync_options ();

    /***********************************************************
    ***********************************************************/
    static std.chrono.milliseconds full_local_discovery_interval = [] () {
        var interval = ConfigFile ().full_local_discovery_interval ();
        GLib.ByteArray env = qgetenv ("OWNCLOUD_FULL_LOCAL_DISCOVERY_INTERVAL");
        if (!env.is_empty ()) {
            interval = std.chrono.milliseconds (env.to_long_long ());
        }
        return interval;
    } ();
    bool has_done_full_local_discovery = this.time_since_last_full_local_discovery.is_valid ();
    bool periodic_full_local_discovery_now =
        full_local_discovery_interval.count () >= 0 // negative means we don't require periodic full runs
        && this.time_since_last_full_local_discovery.has_expired (full_local_discovery_interval.count ());
    if (this.folder_watcher && this.folder_watcher.is_reliable ()
        && has_done_full_local_discovery
        && !periodic_full_local_discovery_now) {
        GLib.info (lc_folder) << "Allowing local discovery to read from the database";
        this.engine.local_discovery_options (
            LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM,
            this.local_discovery_tracker.local_discovery_paths ());
        this.local_discovery_tracker.start_sync_partial_discovery ();
    } else {
        GLib.info (lc_folder) << "Forbidding local discovery to read from the database";
        this.engine.local_discovery_options (LocalDiscoveryStyle.FILESYSTEM_ONLY);
        this.local_discovery_tracker.start_sync_full_discovery ();
    }

    this.engine.ignore_hidden_files (this.definition.ignore_hidden_files);

    correct_placeholder_files ();

    QMetaObject.invoke_method (this.engine.data (), "on_start_sync", Qt.QueuedConnection);

    /* emit */ sync_started ();
}

void Folder.correct_placeholder_files () {
    if (this.definition.virtual_files_mode == Vfs.Off) {
        return;
    }
    const var placeholders_corrected_key = QStringLiteral ("placeholders_corrected");
    const var placeholders_corrected = this.journal.key_value_store_get_int (placeholders_corrected_key, 0);
    if (!placeholders_corrected) {
        GLib.debug (lc_folder) << "Make sure all virtual files are placeholder files";
        switch_to_virtual_files ();
        this.journal.key_value_store_set (placeholders_corrected_key, true);
    }
}

void Folder.sync_options () {
    SyncOptions opt;
    ConfigFile cfg_file;

    var new_folder_limit = cfg_file.new_big_folder_size_limit ();
    opt.new_big_folder_size_limit = new_folder_limit.first ? new_folder_limit.second * 1000LL * 1000LL : -1; // convert from MB to B
    opt.confirm_external_storage = cfg_file.confirm_external_storage ();
    opt.move_files_to_trash = cfg_file.move_to_trash ();
    opt.vfs = this.vfs;
    opt.parallel_network_jobs = this.account_state.account ().is_http2Supported () ? 20 : 6;

    opt.initial_chunk_size = cfg_file.chunk_size ();
    opt.min_chunk_size = cfg_file.min_chunk_size ();
    opt.max_chunk_size = cfg_file.max_chunk_size ();
    opt.target_chunk_upload_duration = cfg_file.target_chunk_upload_duration ();

    opt.fill_from_environment_variables ();
    opt.verify_chunk_sizes ();

    this.engine.sync_options (opt);
}

void Folder.dirty_network_limits () {
    ConfigFile config;
    int download_limit = -75; // 75%
    int use_down_limit = config.use_download_limit ();
    if (use_down_limit >= 1) {
        download_limit = config.download_limit () * 1000;
    } else if (use_down_limit == 0) {
        download_limit = 0;
    }

    int upload_limit = -75; // 75%
    int use_up_limit = config.use_upload_limit ();
    if (use_up_limit >= 1) {
        upload_limit = config.upload_limit () * 1000;
    } else if (use_up_limit == 0) {
        upload_limit = 0;
    }

    this.engine.network_limits (upload_limit, download_limit);
}

void Folder.on_sync_error (string message, ErrorCategory category) {
    this.sync_result.append_error_string (message);
    /* emit */ ProgressDispatcher.instance ().sync_error (alias (), message, category);
}

void Folder.on_add_error_to_gui (SyncFileItem.Status status, string error_message, string subject) {
    /* emit */ ProgressDispatcher.instance ().add_error_to_gui (alias (), status, error_message, subject);
}

void Folder.on_sync_started () {
    GLib.info (lc_folder) << "#### Propagation on_start ####################################################";
    this.sync_result.status (SyncResult.Status.SYNC_RUNNING);
    /* emit */ sync_state_change ();
}

void Folder.on_sync_finished (bool on_success) {
    GLib.info (lc_folder) << "Client version" << q_printable (Theme.instance ().version ())
                     << " Qt" << q_version ()
                     << " SSL " << QSslSocket.ssl_library_version_"".to_utf8 ().data ()
        ;

    bool sync_error = !this.sync_result.error_strings ().is_empty ();
    if (sync_error) {
        GLib.warn (lc_folder) << "SyncEngine on_finished with ERROR";
    } else {
        GLib.info (lc_folder) << "SyncEngine on_finished without problem.";
    }
    this.file_log.finish ();
    show_sync_result_popup ();

    var another_sync_needed = this.engine.is_another_sync_needed ();

    if (sync_error) {
        this.sync_result.status (SyncResult.Status.ERROR);
    } else if (this.sync_result.found_files_not_synced ()) {
        this.sync_result.status (SyncResult.Status.PROBLEM);
    } else if (this.definition.paused) {
        // Maybe the sync was terminated because the user paused the folder
        this.sync_result.status (SyncResult.Status.PAUSED);
    } else {
        this.sync_result.status (SyncResult.Status.SUCCESS);
    }

    // Count the number of syncs that have failed in a row.
    if (this.sync_result.status () == SyncResult.Status.SUCCESS
        || this.sync_result.status () == SyncResult.Status.PROBLEM) {
        this.consecutive_failing_syncs = 0;
    } else {
        this.consecutive_failing_syncs++;
        GLib.info (lc_folder) << "the last" << this.consecutive_failing_syncs << "syncs failed";
    }

    if (this.sync_result.status () == SyncResult.Status.SUCCESS && on_success) {
        // Clear the allow list as all the folders that should be on that list are sync-ed
        journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST, string[] ());
    }

    if ( (this.sync_result.status () == SyncResult.Status.SUCCESS
            || this.sync_result.status () == SyncResult.Status.PROBLEM)
        && on_success) {
        if (this.engine.last_local_discovery_style () == LocalDiscoveryStyle.FILESYSTEM_ONLY) {
            this.time_since_last_full_local_discovery.on_start ();
        }
    }

    /* emit */ sync_state_change ();

    // The sync_finished result that is to be triggered here makes the folderman
    // clear the current running sync folder marker.
    // Lets wait a bit to do that because, as long as this marker is not cleared,
    // file system change notifications are ignored for that folder. And it takes
    // some time under certain conditions to make the file system notifications
    // all come in.
    QTimer.single_shot (200, this, &Folder.on_emit_finished_delayed);

    this.last_sync_duration = std.chrono.milliseconds (this.time_since_last_sync_start.elapsed ());
    this.time_since_last_sync_done.on_start ();

    // Increment the follow-up sync counter if necessary.
    if (another_sync_needed == AnotherSyncNeeded.IMMEDIATE_FOLLOW_UP) {
        this.consecutive_follow_up_syncs++;
        GLib.info (lc_folder) << "another sync was requested by the on_finished sync, this has"
                         << "happened" << this.consecutive_follow_up_syncs << "times";
    } else {
        this.consecutive_follow_up_syncs = 0;
    }

    // Maybe force a follow-up sync to take place, but only a couple of times.
    if (another_sync_needed == AnotherSyncNeeded.IMMEDIATE_FOLLOW_UP && this.consecutive_follow_up_syncs <= 3) {
        // Sometimes another sync is requested because a local file is still
        // changing, so wait at least a small amount of time before syncing
        // the folder again.
        schedule_this_folder_soon ();
    }
}

void Folder.on_emit_finished_delayed () {
    /* emit */ sync_finished (this.sync_result);

    // Immediately check the etag again if there was some sync activity.
    if ( (this.sync_result.status () == SyncResult.Status.SUCCESS
            || this.sync_result.status () == SyncResult.Status.PROBLEM)
        && (this.sync_result.first_item_deleted ()
               || this.sync_result.first_item_new ()
               || this.sync_result.first_item_renamed ()
               || this.sync_result.first_item_updated ()
               || this.sync_result.first_new_conflict_item ())) {
        on_run_etag_job ();
    }
}

// the progress comes without a folder and the valid path set. Add that here
// and hand the result over to the progress dispatcher.
void Folder.on_transmission_progress (ProgressInfo pi) {
    /* emit */ progress_info (pi);
    ProgressDispatcher.instance ().progress_info (alias (), pi);
}

// a item is completed : count the errors and forward to the ProgressDispatcher
void Folder.on_item_completed (SyncFileItemPtr item) {
    if (item.instruction == CSYNC_INSTRUCTION_NONE || item.instruction == CSYNC_INSTRUCTION_UPDATE_METADATA) {
        // We only care about the updates that deserve to be shown in the UI
        return;
    }

    this.sync_result.process_completed_item (item);

    this.file_log.log_item (*item);
    /* emit */ ProgressDispatcher.instance ().item_completed (alias (), item);
}

void Folder.on_new_big_folder_discovered (string new_f, bool is_external) {
    var new_folder = new_f;
    if (!new_folder.ends_with ('/')) {
        new_folder += '/';
    }
    var journal = journal_database ();

    // Add the entry to the blocklist if it is neither in the blocklist or allowlist already
    bool ok1 = false;
    bool ok2 = false;
    var blocklist = journal.get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok1);
    var allowlist = journal.get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST, ok2);
    if (ok1 && ok2 && !blocklist.contains (new_folder) && !allowlist.contains (new_folder)) {
        blocklist.append (new_folder);
        journal.selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, blocklist);
    }

    // And add the entry to the undecided list and signal the UI
    var undecided_list = journal.get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_UNDECIDEDLIST, ok1);
    if (ok1) {
        if (!undecided_list.contains (new_folder)) {
            undecided_list.append (new_folder);
            journal.selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_UNDECIDEDLIST, undecided_list);
            /* emit */ new_big_folder_discovered (new_folder);
        }
        string message = !is_external ? (_("A new folder larger than %1 MB has been added : %2.\n")
                                                .arg (ConfigFile ().new_big_folder_size_limit ().second)
                                                .arg (new_f))
                                      : (_("A folder from an external storage has been added.\n"));
        message += _("Please go in the settings to select it if you wish to download it.");

        var logger = Logger.instance ();
        logger.post_optional_gui_log (Theme.instance ().app_name_gui (), message);
    }
}

void Folder.on_log_propagation_start () {
    this.file_log.log_lap ("Propagation starts");
}

void Folder.on_schedule_this_folder () {
    FolderMan.instance ().schedule_folder (this);
}

void Folder.on_next_sync_full_local_discovery () {
    this.time_since_last_full_local_discovery.invalidate ();
}

void Folder.on_schedule_path_for_local_discovery (string relative_path) {
    this.local_discovery_tracker.add_touched_path (relative_path.to_utf8 ());
}

void Folder.on_folder_conflicts (string folder, string[] conflict_paths) {
    if (folder != this.definition.alias)
        return;
    var r = this.sync_result;

    // If the number of conflicts is too low, adjust it upwards
    if (conflict_paths.size () > r.num_new_conflict_items () + r.num_old_conflict_items ())
        r.num_old_conflict_items (conflict_paths.size () - r.num_new_conflict_items ());
}

void Folder.on_warn_on_new_excluded_item (SyncJournalFileRecord record, QStringRef path) {
    // Never warn for items in the database
    if (record.is_valid ())
        return;

    // Don't warn for items that no longer exist.
    // Note: This assumes we're getting file watcher notifications
    // for folders only on creation and deletion - if we got a notification
    // on content change that would create spurious warnings.
    QFileInfo fi (this.canonical_local_path + path);
    if (!fi.exists ())
        return;

    bool ok = false;
    var blocklist = this.journal.get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok);
    if (!ok)
        return;
    if (!blocklist.contains (path + "/"))
        return;

    const var message = fi.is_dir ()
        ? _("The folder %1 was created but was excluded from synchronization previously. "
             "Data inside it will not be synchronized.")
              .arg (fi.file_path ())
        : _("The file %1 was created but was excluded from synchronization previously. "
             "It will not be synchronized.")
              .arg (fi.file_path ());

    Logger.instance ().post_optional_gui_log (Theme.instance ().app_name_gui (), message);
}

void Folder.on_watcher_unreliable (string message) {
    GLib.warn (lc_folder) << "Folder watcher for" << path () << "became unreliable:" << message;
    var full_message =
        _("Changes in synchronized folders could not be tracked reliably.\n"
           "\n"
           "This means that the synchronization client might not upload local changes "
           "immediately and will instead only scan for local changes and upload them "
           "occasionally (every two hours by default).\n"
           "\n"
           "%1").arg (message);
    Logger.instance ().post_gui_log (Theme.instance ().app_name_gui (), full_message);
}

void Folder.on_hydration_starts () {
    // Abort any running full sync run and reschedule
    if (this.engine.is_sync_running ()) {
        on_terminate_sync ();
        schedule_this_folder_soon ();
        // TODO : This sets the sync state to Abort_requested on done, we don't want that
    }

    // Let everyone know we're syncing
    this.sync_result.on_reset ();
    this.sync_result.status (SyncResult.Status.SYNC_RUNNING);
    /* emit */ sync_started ();
    /* emit */ sync_state_change ();
}

void Folder.on_hydration_done () {
    // emit signal to update ui and reschedule normal syncs if necessary
    this.sync_result.status (SyncResult.Status.SUCCESS);
    /* emit */ sync_finished (this.sync_result);
    /* emit */ sync_state_change ();
}

void Folder.schedule_this_folder_soon () {
    if (!this.schedule_self_timer.is_active ()) {
        this.schedule_self_timer.on_start ();
    }
}

void Folder.save_backwards_compatible (bool save) {
    this.save_backwards_compatible = save;
}

void Folder.register_folder_watcher () {
    if (this.folder_watcher)
        return;
    if (!QDir (path ()).exists ())
        return;

    this.folder_watcher.on_reset (new Folder_watcher (this));
    connect (this.folder_watcher.data (), &Folder_watcher.path_changed,
        this, [this] (string path) {
            on_watched_path_changed (path, Folder.ChangeReason.Other);
        });
    connect (this.folder_watcher.data (), &Folder_watcher.lost_changes,
        this, &Folder.on_next_sync_full_local_discovery);
    connect (this.folder_watcher.data (), &Folder_watcher.became_unreliable,
        this, &Folder.on_watcher_unreliable);
    this.folder_watcher.on_init (path ());
    this.folder_watcher.start_notificaton_test (path () + QLatin1String (".owncloudsync.log"));
}

bool Folder.virtual_files_enabled () {
    return this.definition.virtual_files_mode != Vfs.Off && !is_vfs_on_off_switch_pending ();
}

void Folder.on_about_to_remove_all_files (SyncFileItem.Direction dir, std.function<void (bool)> callback) {
    ConfigFile cfg_file;
    if (!cfg_file.prompt_delete_files ()) {
        callback (false);
        return;
    }

    const string message = dir == SyncFileItem.Direction.DOWN ? _("All files in the sync folder \"%1\" folder were deleted on the server.\n"
                                                 "These deletes will be synchronized to your local sync folder, making such files "
                                                 "unavailable unless you have a right to restore. \n"
                                                 "If you decide to restore the files, they will be re-synced with the server if you have rights to do so.\n"
                                                 "If you decide to delete the files, they will be unavailable to you, unless you are the owner.")
                                            : _("All the files in your local sync folder \"%1\" were deleted. These deletes will be "
                                                 "synchronized with your server, making such files unavailable unless restored.\n"
                                                 "Are you sure you want to sync those actions with the server?\n"
                                                 "If this was an accident and you decide to keep your files, they will be re-synced from the server.");
    var msg_box = new QMessageBox (QMessageBox.Warning, _("Remove All Files?"),
        message.arg (short_gui_local_path ()), QMessageBox.NoButton);
    msg_box.attribute (Qt.WA_DeleteOnClose);
    msg_box.window_flags (msg_box.window_flags () | Qt.Window_stays_on_top_hint);
    msg_box.add_button (_("Remove all files"), QMessageBox.DestructiveRole);
    QPushButton keep_btn = msg_box.add_button (_("Keep files"), QMessageBox.AcceptRole);
    bool old_paused = sync_paused ();
    sync_paused (true);
    connect (msg_box, &QMessageBox.on_finished, this, [msg_box, keep_btn, callback, old_paused, this] {
        const bool cancel = msg_box.clicked_button () == keep_btn;
        callback (cancel);
        if (cancel) {
            FileSystem.folder_minimum_permissions (path ());
            journal_database ().clear_file_table ();
            this.last_etag.clear ();
            on_schedule_this_folder ();
        }
        sync_paused (old_paused);
    });
    connect (this, &Folder.destroyed, msg_box, &QMessageBox.delete_later);
    msg_box.open ();
}

string Folder.file_from_local_path (string local_path) {
    return local_path.mid (clean_path ().length () + 1);
}

} // namespace Occ
