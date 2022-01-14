/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QTimer>
// #include <QUrl>
// #include <QDir>
// #include <QSettings>

// #include <QMessageBox>
// #include <QPushButton>
// #include <QApplication>

// #include <GLib.Object>
// #include <QStringList>
// #include <QUuid>
// #include <set>
// #include <chrono>
// #include <memory>


namespace Occ {

static const char version_c[] = "version";

class SyncRunFileLog;

/***********************************************************
@brief The FolderDefinition class
@ingroup gui
***********************************************************/
class FolderDefinition {

    /// The name of the folder in the ui and internally
    public string alias;
    /// path on local machine (always trailing /)
    public string local_path;
    /// path to the journal, usually relative to local_path
    public string journal_path;
    /// path on remote (usually no trailing /, exception "/")
    public string target_path;
    /// whether the folder is paused
    public bool paused = false;
    /// whether the folder syncs hidden files
    public bool ignore_hidden_files = false;
    /// Which virtual files setting the folder uses
    public Vfs.Mode virtual_files_mode = Vfs.Off;
    /// The CLSID where this folder appears in registry for the Explorer navigation pane entry.
    public QUuid navigation_pane_clsid;

    /// Whether the vfs mode shall silently be updated if possible
    public bool upgrade_vfs_mode = false;

    /// Saves the folder definition into the current settings group.
    public static void save (QSettings &settings, FolderDefinition &folder);

    /// Reads a folder definition from the current settings group.
    public static bool load (QSettings &settings, string &alias,
        FolderDefinition *folder);

    /***********************************************************
    The highest version in the settings that load () can read

    Version 1: initial version (default if value absent in settings)
    Version 2: introduction of metadata_parent hash in 2.6.0
               (version remains readable by 2.5.1)
    Version 3: introduction of new windows vfs mode in 2.6.0
    ***********************************************************/
    public static int max_settings_version () {
        return 3;
    }

    /// Ensure / as separator and trailing /.
    public static string prepare_local_path (string &path);

    /// Remove ending /, then ensure starting '/' : so "/foo/bar" and "/".
    public static string prepare_target_path (string &path);

    /// journal_path relative to local_path.
    public string absolute_journal_path ();

    /// Returns the relative journal path that's appropriate for this folder and account.
    public string default_journal_path (AccountPtr account);
};

/***********************************************************
@brief The Folder class
@ingroup gui
***********************************************************/
class Folder : GLib.Object {

    public enum class ChangeReason {
        Other,
        UnLock
    };

    /***********************************************************
    Create a new Folder
    ***********************************************************/
    public Folder (FolderDefinition &definition, AccountState *account_state, std.unique_ptr<Vfs> vfs, GLib.Object *parent = nullptr);

    public ~Folder () override;

    public using Map = QMap<string, Folder>;
    public using MapIterator = QMapIterator<string, Folder>;

    /***********************************************************
    The account the folder is configured on.
    ***********************************************************/
    public AccountState *account_state () {
        return _account_state.data ();
    }

    /***********************************************************
    alias or nickname
    ***********************************************************/
    public string alias ();
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

    public void set_navigation_pane_clsid (QUuid &clsid) {
        _definition.navigation_pane_clsid = clsid;
    }
    public QUuid navigation_pane_clsid () {
        return _definition.navigation_pane_clsid;
    }

    /***********************************************************
    remote folder path with server url
    ***********************************************************/
    public QUrl remote_url ();

    /***********************************************************
    switch sync on or off
    ***********************************************************/
    public void set_sync_paused (bool);

    public bool sync_paused ();

    /***********************************************************
    Returns true when the folder may sync.
    ***********************************************************/
    public bool can_sync ();

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

    public void on_associated_account_removed ();

    public void set_sync_state (SyncResult.Status state);

    public void set_dirty_network_limits ();

    /***********************************************************
    Ignore syncing of hidden files or not. This is defined in the
    folder definition
    ***********************************************************/
    public bool ignore_hidden_files ();
    public void set_ignore_hidden_files (bool ignore);

    // Used by the Socket API
    public SyncJournalDb *journal_db () {
        return &_journal;
    }
    public SyncEngine &sync_engine () {
        return *_engine;
    }
    public Vfs &vfs () {
        return *_vfs;
    }

    public RequestEtagJob *etag_job () {
        return _request_etag_job;
    }
    public std.chrono.milliseconds msec_since_last_sync () {
        return std.chrono.milliseconds (_time_since_last_sync_done.elapsed ());
    }
    public std.chrono.milliseconds msec_last_sync_duration () {
        return _last_sync_duration;
    }
    public int consecutive_follow_up_syncs () {
        return _consecutive_follow_up_syncs;
    }
    public int consecutive_failing_syncs () {
        return _consecutive_failing_syncs;
    }

    /// Saves the folder data in the account's settings.
    public void save_to_settings ();
    /// Removes the folder from the account's settings.
    public void remove_from_settings ();

    /***********************************************************
    Returns whether a file inside this folder should be excluded.
    ***********************************************************/
    public bool is_file_excluded_absolute (string &full_path) const;

    /***********************************************************
    Returns whether a file inside this folder should be excluded.
    ***********************************************************/
    public bool is_file_excluded_relative (string &relative_path) const;

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
    public void set_save_backwards_compatible (bool save);

    /***********************************************************
    Used to have placeholders : save in placeholder config section
    ***********************************************************/
    public void set_save_in_folders_with_placeholders () {
        _save_in_folders_with_placeholders = true;
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
    public void set_virtual_files_enabled (bool enabled);

    public void set_root_pin_state (PinState state);

    /***********************************************************
    Whether user desires a switch that couldn't be executed yet, see member
    ***********************************************************/
    public bool is_vfs_on_off_switch_pending () {
        return _vfs_on_off_pending;
    }
    public void set_vfs_on_off_switch_pending (bool pending) {
        _vfs_on_off_pending = pending;
    }

    public void switch_to_virtual_files ();

    public void process_switched_to_virtual_files ();

    /***********************************************************
    Whether this folder should show selective sync ui
    ***********************************************************/
    public bool supports_selective_sync ();

    public string file_from_local_path (string &local_path) const;

signals:
    void sync_state_change ();
    void sync_started ();
    void sync_finished (SyncResult &result);
    void progress_info (ProgressInfo &progress);
    void new_big_folder_discovered (string &); // A new folder bigger than the threshold was discovered
    void sync_paused_changed (Folder *, bool paused);
    void can_sync_changed ();

    /***********************************************************
    Fires for each change inside this folder that wasn't caused
    by sync activity.
    ***********************************************************/
    void watched_file_changed_externally (string &path);

public slots:

    /***********************************************************
    terminate the current sync run
    ***********************************************************/
    void slot_terminate_sync ();

    // connected to the corresponding signals in the SyncEngine
    void slot_about_to_remove_all_files (SyncFileItem.Direction, std.function<void (bool)> callback);

    /***********************************************************
    Starts a sync operation

    If the list of changed files is known, it is passed.
    ***********************************************************/
    void start_sync (QStringList &path_list = QStringList ());

    int slot_discard_download_progress ();
    int download_info_count ();
    int slot_wipe_error_blacklist ();
    int error_black_list_entry_count ();

    /***********************************************************
    Triggered by the folder watcher when a file/dir in this folder
    changes. Needs to check whether this change should trigger a new
    sync run to be scheduled.
    ***********************************************************/
    void slot_watched_path_changed (string &path, ChangeReason reason);

    /***********************************************************
    Mark a virtual file as being requested for download, and start a sync.

    "implicit" here means that this download request comes from the user wan
    to access the file's data. The user did not change the file's pin state.
    If the file is currently OnlineOnly its state will change to Unspecif

    The download re
    in the database. This is necessary since the hydration is not driven by
    the pin state.

    relativepath is the folder-relative path to the file (including the extension)

    Note, passing directories is not supported. Files only.
    ***********************************************************/
    void implicitly_hydrate_file (string &relativepath);

    /***********************************************************
    Adds the path to the local discovery list

    A weaker version of slot_next_sync_full_local_discovery () that just
    schedules all parent and child items of the path for local
    discovery.
    ***********************************************************/
    void schedule_path_for_local_discovery (string &relative_path);

    /***********************************************************
    Ensures that the next sync performs a full local discovery.
    ***********************************************************/
    void slot_next_sync_full_local_discovery ();

private slots:
    void slot_sync_started ();
    void slot_sync_finished (bool);

    /***********************************************************
    Adds a error message that's not tied to a specific item.
    ***********************************************************/
    void slot_sync_error (string &message, ErrorCategory category = ErrorCategory.Normal);

    void slot_add_error_to_gui (SyncFileItem.Status status, string &error_message, string &subject = {});

    void slot_transmission_progress (ProgressInfo &pi);
    void slot_item_completed (SyncFileItemPtr &);

    void slot_run_etag_job ();
    void etag_retrieved (QByteArray &, QDateTime &tp);
    void etag_retrieved_from_sync_engine (QByteArray &, QDateTime &time);

    void slot_emit_finished_delayed ();

    void slot_new_big_folder_discovered (string &, bool is_external);

    void slot_log_propagation_start ();

    /***********************************************************
    Adds this folder to the list of scheduled folders in the
     FolderMan.
    ***********************************************************/
    void slot_schedule_this_folder ();

    /***********************************************************
    Adjust sync result based on conflict data from IssuesWidget.

    This is pretty awkward, but IssuesWidget just keeps better track
    of conflicts across partial local discovery.
    ***********************************************************/
    void slot_folder_conflicts (string &folder, QStringList &conflict_paths);

    /***********************************************************
    Warn users if they create a file or folder that is selective-sync excluded
    ***********************************************************/
    void warn_on_new_excluded_item (SyncJournalFileRecord &record, QStringRef &path);

    /***********************************************************
    Warn users about an unreliable folder watcher
    ***********************************************************/
    void slot_watcher_unreliable (string &message);

    /***********************************************************
    Aborts any running sync and blocks it until hydration is finished.

    Hydration circumvents the regular SyncEngine and both mustn't be running
    at the same time.
    ***********************************************************/
    void slot_hydration_starts ();

    /***********************************************************
    Unblocks normal sync operation
    ***********************************************************/
    void slot_hydration_done ();

private:
    void connect_sync_root ();

    bool reload_excludes ();

    void show_sync_result_popup ();

    void check_local_path ();

    void set_sync_options ();

    enum LogStatus {
        Log_status_remove,
        Log_status_rename,
        Log_status_move,
        Log_status_new,
        Log_status_error,
        Log_status_conflict,
        Log_status_updated,
        Log_status_file_locked
    };

    void create_gui_log (string &filename, LogStatus status, int count,
        const string &rename_target = string ());

    void start_vfs ();

    void correct_placeholder_files ();

    AccountStatePtr _account_state;
    FolderDefinition _definition;
    string _canonical_local_path; // As returned with QFileInfo:canonical_file_path.  Always ends with "/"

    SyncResult _sync_result;
    QScopedPointer<SyncEngine> _engine;
    QPointer<RequestEtagJob> _request_etag_job;
    QByteArray _last_etag;
    QElapsedTimer _time_since_last_sync_done;
    QElapsedTimer _time_since_last_sync_start;
    QElapsedTimer _time_since_last_full_local_discovery;
    std.chrono.milliseconds _last_sync_duration;

    /// The number of syncs that failed in a row.
    /// Reset when a sync is successful.
    int _consecutive_failing_syncs;

    /// The number of requested follow-up syncs.
    /// Reset when no follow-up is requested.
    int _consecutive_follow_up_syncs;

    mutable SyncJournalDb _journal;

    QScopedPointer<SyncRunFileLog> _file_log;

    QTimer _schedule_self_timer;

    /***********************************************************
    When the same local path is synced to multiple accounts, only one
    of them can be stored in the settings in a way that's compatible
    with old clients that don't support it. This flag marks folders
    that shall be written in a backwards-compatible way, by being set
    on the *first* Folder instance that was configured for each local
    path.
    ***********************************************************/
    bool _save_backwards_compatible = false;

    /***********************************************************
    Whether the folder should be saved in that settings group

    If it was read from there it had virtual files enabled at some
    point and might still have db entries or suffix-virtual files even
    if they are disabled right now. This flag ensures folders that
    were in that group once never go back.
    ***********************************************************/
    bool _save_in_folders_with_placeholders = false;

    /***********************************************************
    Whether a vfs mode switch is pending

    When the user desires that vfs be switched on/off but it hasn't been
    executed yet (syncs are still running), some options should be hidden,
    disabled or different.
    ***********************************************************/
    bool _vfs_on_off_pending = false;

    /***********************************************************
    Whether this folder has just switched to VFS or not
    ***********************************************************/
    bool _has_switched_to_vfs = false;

    /***********************************************************
    Watches this folder's local directory for changes.

    Created by register_folder_watcher (), triggers slot_watched_path_changed ()
    ***********************************************************/
    QScopedPointer<Folder_watcher> _folder_watcher;

    /***********************************************************
    Keeps track of locally dirty files so we can skip local discovery sometimes.
    ***********************************************************/
    QScopedPointer<LocalDiscoveryTracker> _local_discovery_tracker;

    /***********************************************************
    The vfs mode instance (created by plugin) to use. Never null.
    ***********************************************************/
    QSharedPointer<Vfs> _vfs;
};

Folder.Folder (FolderDefinition &definition,
    AccountState *account_state, std.unique_ptr<Vfs> vfs,
    GLib.Object *parent)
    : GLib.Object (parent)
    , _account_state (account_state)
    , _definition (definition)
    , _last_sync_duration (0)
    , _consecutive_failing_syncs (0)
    , _consecutive_follow_up_syncs (0)
    , _journal (_definition.absolute_journal_path ())
    , _file_log (new SyncRunFileLog)
    , _vfs (vfs.release ()) {
    _time_since_last_sync_start.start ();
    _time_since_last_sync_done.start ();

    SyncResult.Status status = SyncResult.NotYetStarted;
    if (definition.paused) {
        status = SyncResult.Paused;
    }
    _sync_result.set_status (status);

    // check if the local path exists
    check_local_path ();

    _sync_result.set_folder (_definition.alias);

    _engine.reset (new SyncEngine (_account_state.account (), path (), remote_path (), &_journal));
    // pass the setting if hidden files are to be ignored, will be read in csync_update
    _engine.set_ignore_hidden_files (_definition.ignore_hidden_files);

    ConfigFile.setup_default_exclude_file_paths (_engine.excluded_files ());
    if (!reload_excludes ())
        q_c_warning (lc_folder, "Could not read system exclude file");

    connect (_account_state.data (), &AccountState.is_connected_changed, this, &Folder.can_sync_changed);
    connect (_engine.data (), &SyncEngine.root_etag, this, &Folder.etag_retrieved_from_sync_engine);

    connect (_engine.data (), &SyncEngine.started, this, &Folder.slot_sync_started, Qt.QueuedConnection);
    connect (_engine.data (), &SyncEngine.finished, this, &Folder.slot_sync_finished, Qt.QueuedConnection);

    connect (_engine.data (), &SyncEngine.about_to_remove_all_files,
        this, &Folder.slot_about_to_remove_all_files);
    connect (_engine.data (), &SyncEngine.transmission_progress, this, &Folder.slot_transmission_progress);
    connect (_engine.data (), &SyncEngine.item_completed,
        this, &Folder.slot_item_completed);
    connect (_engine.data (), &SyncEngine.new_big_folder,
        this, &Folder.slot_new_big_folder_discovered);
    connect (_engine.data (), &SyncEngine.seen_locked_file, FolderMan.instance (), &FolderMan.slot_sync_once_file_unlocks);
    connect (_engine.data (), &SyncEngine.about_to_propagate,
        this, &Folder.slot_log_propagation_start);
    connect (_engine.data (), &SyncEngine.sync_error, this, &Folder.slot_sync_error);

    connect (_engine.data (), &SyncEngine.add_error_to_gui, this, &Folder.slot_add_error_to_gui);

    _schedule_self_timer.set_single_shot (true);
    _schedule_self_timer.set_interval (SyncEngine.minimum_file_age_for_upload);
    connect (&_schedule_self_timer, &QTimer.timeout,
        this, &Folder.slot_schedule_this_folder);

    connect (Progress_dispatcher.instance (), &Progress_dispatcher.folder_conflicts,
        this, &Folder.slot_folder_conflicts);

    _local_discovery_tracker.reset (new LocalDiscoveryTracker);
    connect (_engine.data (), &SyncEngine.finished,
        _local_discovery_tracker.data (), &LocalDiscoveryTracker.slot_sync_finished);
    connect (_engine.data (), &SyncEngine.item_completed,
        _local_discovery_tracker.data (), &LocalDiscoveryTracker.slot_item_completed);

    // Potentially upgrade suffix vfs to windows vfs
    ENFORCE (_vfs);
    if (_definition.virtual_files_mode == Vfs.WithSuffix
        && _definition.upgrade_vfs_mode) {
        if (is_vfs_plugin_available (Vfs.WindowsCfApi)) {
            if (auto winvfs = create_vfs_from_plugin (Vfs.WindowsCfApi)) {
                // Wipe the existing suffix files from fs and journal
                SyncEngine.wipe_virtual_files (path (), _journal, *_vfs);

                // Then switch to winvfs mode
                _vfs.reset (winvfs.release ());
                _definition.virtual_files_mode = Vfs.WindowsCfApi;
            }
        }
        save_to_settings ();
    }

    // Initialize the vfs plugin
    start_vfs ();
}

Folder.~Folder () {
    // If wipe_for_removal () was called the vfs has already shut down.
    if (_vfs)
        _vfs.stop ();

    // Reset then engine first as it will abort and try to access members of the Folder
    _engine.reset ();
}

void Folder.check_local_path () {
    const QFileInfo fi (_definition.local_path);
    _canonical_local_path = fi.canonical_file_path ();
    if (_canonical_local_path.is_empty ()) {
        q_c_warning (lc_folder) << "Broken symlink:" << _definition.local_path;
        _canonical_local_path = _definition.local_path;
    } else if (!_canonical_local_path.ends_with ('/')) {
        _canonical_local_path.append ('/');
    }

    if (fi.is_dir () && fi.is_readable ()) {
        q_c_debug (lc_folder) << "Checked local path ok";
    } else {
        // Check directory again
        if (!FileSystem.file_exists (_definition.local_path, fi)) {
            _sync_result.append_error_string (tr ("Local folder %1 does not exist.").arg (_definition.local_path));
            _sync_result.set_status (SyncResult.Setup_error);
        } else if (!fi.is_dir ()) {
            _sync_result.append_error_string (tr ("%1 should be a folder but is not.").arg (_definition.local_path));
            _sync_result.set_status (SyncResult.Setup_error);
        } else if (!fi.is_readable ()) {
            _sync_result.append_error_string (tr ("%1 is not readable.").arg (_definition.local_path));
            _sync_result.set_status (SyncResult.Setup_error);
        }
    }
}

string Folder.short_gui_remote_path_or_app_name () {
    if (remote_path ().length () > 0 && remote_path () != QLatin1String ("/")) {
        string a = QFile (remote_path ()).file_name ();
        if (a.starts_with ('/')) {
            a = a.remove (0, 1);
        }
        return a;
    } else {
        return Theme.instance ().app_name_g_u_i ();
    }
}

string Folder.alias () {
    return _definition.alias;
}

string Folder.path () {
    return _canonical_local_path;
}

string Folder.short_gui_local_path () {
    string p = _definition.local_path;
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
    bool re (_definition.ignore_hidden_files);
    return re;
}

void Folder.set_ignore_hidden_files (bool ignore) {
    _definition.ignore_hidden_files = ignore;
}

string Folder.clean_path () {
    string cleaned_path = QDir.clean_path (_canonical_local_path);

    if (cleaned_path.length () == 3 && cleaned_path.ends_with (":/"))
        cleaned_path.remove (2, 1);

    return cleaned_path;
}

bool Folder.is_busy () {
    return is_sync_running ();
}

bool Folder.is_sync_running () {
    return _engine.is_sync_running () || (_vfs && _vfs.is_hydrating ());
}

string Folder.remote_path () {
    return _definition.target_path;
}

string Folder.remote_path_trailing_slash () {
    string result = remote_path ();
    if (!result.ends_with ('/'))
        result.append ('/');
    return result;
}

QUrl Folder.remote_url () {
    return Utility.concat_url_path (_account_state.account ().dav_url (), remote_path ());
}

bool Folder.sync_paused () {
    return _definition.paused;
}

bool Folder.can_sync () {
    return !sync_paused () && account_state ().is_connected ();
}

void Folder.set_sync_paused (bool paused) {
    if (paused == _definition.paused) {
        return;
    }

    _definition.paused = paused;
    save_to_settings ();

    if (!paused) {
        set_sync_state (SyncResult.NotYetStarted);
    } else {
        set_sync_state (SyncResult.Paused);
    }
    emit sync_paused_changed (this, paused);
    emit sync_state_change ();
    emit can_sync_changed ();
}

void Folder.on_associated_account_removed () {
    if (_vfs) {
        _vfs.stop ();
        _vfs.unregister_folder ();
    }
}

void Folder.set_sync_state (SyncResult.Status state) {
    _sync_result.set_status (state);
}

SyncResult Folder.sync_result () {
    return _sync_result;
}

void Folder.prepare_to_sync () {
    _sync_result.reset ();
    _sync_result.set_status (SyncResult.NotYetStarted);
}

void Folder.slot_run_etag_job () {
    q_c_info (lc_folder) << "Trying to check" << remote_url ().to_string () << "for changes via ETag check. (time since last sync:" << (_time_since_last_sync_done.elapsed () / 1000) << "s)";

    AccountPtr account = _account_state.account ();

    if (_request_etag_job) {
        q_c_info (lc_folder) << remote_url ().to_string () << "has ETag job queued, not trying to sync";
        return;
    }

    if (!can_sync ()) {
        q_c_info (lc_folder) << "Not syncing.  :" << remote_url ().to_string () << _definition.paused << AccountState.state_string (_account_state.state ());
        return;
    }

    // Do the ordinary etag check for the root folder and schedule a
    // sync if it's different.

    _request_etag_job = new RequestEtagJob (account, remote_path (), this);
    _request_etag_job.set_timeout (60 * 1000);
    // check if the etag is different when retrieved
    GLib.Object.connect (_request_etag_job.data (), &RequestEtagJob.etag_retrieved, this, &Folder.etag_retrieved);
    FolderMan.instance ().slot_schedule_e_tag_job (alias (), _request_etag_job);
    // The _request_etag_job is auto deleting itself on finish. Our guard pointer _request_etag_job will then be null.
}

void Folder.etag_retrieved (QByteArray &etag, QDateTime &tp) {
    // re-enable sync if it was disabled because network was down
    FolderMan.instance ().set_sync_enabled (true);

    if (_last_etag != etag) {
        q_c_info (lc_folder) << "Compare etag with previous etag : last:" << _last_etag << ", received:" << etag << ". CHANGED";
        _last_etag = etag;
        slot_schedule_this_folder ();
    }

    _account_state.tag_last_successfull_e_tag_request (tp);
}

void Folder.etag_retrieved_from_sync_engine (QByteArray &etag, QDateTime &time) {
    q_c_info (lc_folder) << "Root etag from during sync:" << etag;
    account_state ().tag_last_successfull_e_tag_request (time);
    _last_etag = etag;
}

void Folder.show_sync_result_popup () {
    if (_sync_result.first_item_new ()) {
        create_gui_log (_sync_result.first_item_new ().destination (), Log_status_new, _sync_result.num_new_items ());
    }
    if (_sync_result.first_item_deleted ()) {
        create_gui_log (_sync_result.first_item_deleted ().destination (), Log_status_remove, _sync_result.num_removed_items ());
    }
    if (_sync_result.first_item_updated ()) {
        create_gui_log (_sync_result.first_item_updated ().destination (), Log_status_updated, _sync_result.num_updated_items ());
    }

    if (_sync_result.first_item_renamed ()) {
        LogStatus status (Log_status_rename);
        // if the path changes it's rather a move
        QDir ren_target = QFileInfo (_sync_result.first_item_renamed ()._rename_target).dir ();
        QDir ren_source = QFileInfo (_sync_result.first_item_renamed ()._file).dir ();
        if (ren_target != ren_source) {
            status = Log_status_move;
        }
        create_gui_log (_sync_result.first_item_renamed ()._file, status,
            _sync_result.num_renamed_items (), _sync_result.first_item_renamed ()._rename_target);
    }

    if (_sync_result.first_new_conflict_item ()) {
        create_gui_log (_sync_result.first_new_conflict_item ().destination (), Log_status_conflict, _sync_result.num_new_conflict_items ());
    }
    if (int error_count = _sync_result.num_error_items ()) {
        create_gui_log (_sync_result.first_item_error ()._file, Log_status_error, error_count);
    }

    if (int locked_count = _sync_result.num_locked_items ()) {
        create_gui_log (_sync_result.first_item_locked ()._file, Log_status_file_locked, locked_count);
    }

    q_c_info (lc_folder) << "Folder" << _sync_result.folder () << "sync result : " << _sync_result.status ();
}

void Folder.create_gui_log (string &filename, LogStatus status, int count,
    const string &rename_target) {
    if (count > 0) {
        Logger *logger = Logger.instance ();

        string file = QDir.to_native_separators (filename);
        string text;

        switch (status) {
        case Log_status_remove:
            if (count > 1) {
                text = tr ("%1 and %n other file (s) have been removed.", "", count - 1).arg (file);
            } else {
                text = tr ("%1 has been removed.", "%1 names a file.").arg (file);
            }
            break;
        case Log_status_new:
            if (count > 1) {
                text = tr ("%1 and %n other file (s) have been added.", "", count - 1).arg (file);
            } else {
                text = tr ("%1 has been added.", "%1 names a file.").arg (file);
            }
            break;
        case Log_status_updated:
            if (count > 1) {
                text = tr ("%1 and %n other file (s) have been updated.", "", count - 1).arg (file);
            } else {
                text = tr ("%1 has been updated.", "%1 names a file.").arg (file);
            }
            break;
        case Log_status_rename:
            if (count > 1) {
                text = tr ("%1 has been renamed to %2 and %n other file (s) have been renamed.", "", count - 1).arg (file, rename_target);
            } else {
                text = tr ("%1 has been renamed to %2.", "%1 and %2 name files.").arg (file, rename_target);
            }
            break;
        case Log_status_move:
            if (count > 1) {
                text = tr ("%1 has been moved to %2 and %n other file (s) have been moved.", "", count - 1).arg (file, rename_target);
            } else {
                text = tr ("%1 has been moved to %2.").arg (file, rename_target);
            }
            break;
        case Log_status_conflict:
            if (count > 1) {
                text = tr ("%1 has and %n other file (s) have sync conflicts.", "", count - 1).arg (file);
            } else {
                text = tr ("%1 has a sync conflict. Please check the conflict file!").arg (file);
            }
            break;
        case Log_status_error:
            if (count > 1) {
                text = tr ("%1 and %n other file (s) could not be synced due to errors. See the log for details.", "", count - 1).arg (file);
            } else {
                text = tr ("%1 could not be synced due to an error. See the log for details.").arg (file);
            }
            break;
        case Log_status_file_locked:
            if (count > 1) {
                text = tr ("%1 and %n other file (s) are currently locked.", "", count -1).arg (file);
            } else {
                text = tr ("%1 is currently locked.").arg (file);
            }
            break;
        }

        if (!text.is_empty ()) {
            // Ignores the settings in case of an error or conflict
            if (status == Log_status_error || status == Log_status_conflict)
                logger.post_optional_gui_log (tr ("Sync Activity"), text);
        }
    }
}

void Folder.start_vfs () {
    ENFORCE (_vfs);
    ENFORCE (_vfs.mode () == _definition.virtual_files_mode);

    VfsSetupParams vfs_params;
    vfs_params.filesystem_path = path ();
    vfs_params.display_name = short_gui_remote_path_or_app_name ();
    vfs_params.alias = alias ();
    vfs_params.remote_path = remote_path_trailing_slash ();
    vfs_params.account = _account_state.account ();
    vfs_params.journal = &_journal;
    vfs_params.provider_name = Theme.instance ().app_name_g_u_i ();
    vfs_params.provider_version = Theme.instance ().version ();
    vfs_params.multiple_accounts_registered = AccountManager.instance ().accounts ().size () > 1;

    connect (_vfs.data (), &Vfs.begin_hydrating, this, &Folder.slot_hydration_starts);
    connect (_vfs.data (), &Vfs.done_hydrating, this, &Folder.slot_hydration_done);

    connect (&_engine.sync_file_status_tracker (), &SyncFileStatusTracker.file_status_changed,
            _vfs.data (), &Vfs.file_status_changed);

    _vfs.start (vfs_params);

    // Immediately mark the sqlite temporaries as excluded. They get recreated
    // on db-open and need to get marked again every time.
    string state_db_file = _journal.database_file_path ();
    _journal.open ();
    _vfs.file_status_changed (state_db_file + "-wal", SyncFileStatus.SyncFileStatusTag.STATUS_EXCLUDED);
    _vfs.file_status_changed (state_db_file + "-shm", SyncFileStatus.SyncFileStatusTag.STATUS_EXCLUDED);
}

int Folder.slot_discard_download_progress () {
    // Delete from journal and from filesystem.
    QDir folderpath (_definition.local_path);
    QSet<string> keep_nothing;
    const QVector<SyncJournalDb.DownloadInfo> deleted_infos =
        _journal.get_and_delete_stale_download_infos (keep_nothing);
    for (auto &deleted_info : deleted_infos) {
        const string tmppath = folderpath.file_path (deleted_info._tmpfile);
        q_c_info (lc_folder) << "Deleting temporary file : " << tmppath;
        FileSystem.remove (tmppath);
    }
    return deleted_infos.size ();
}

int Folder.download_info_count () {
    return _journal.download_info_count ();
}

int Folder.error_black_list_entry_count () {
    return _journal.error_black_list_entry_count ();
}

int Folder.slot_wipe_error_blacklist () {
    return _journal.wipe_error_blacklist ();
}

void Folder.slot_watched_path_changed (string &path, ChangeReason reason) {
    if (!path.starts_with (this.path ())) {
        q_c_debug (lc_folder) << "Changed path is not contained in folder, ignoring:" << path;
        return;
    }

    auto relative_path = path.mid_ref (this.path ().size ());

    // Add to list of locally modified paths
    //
    // We do this before checking for our own sync-related changes to make
    // extra sure to not miss relevant changes.
    auto relative_path_bytes = relative_path.to_utf8 ();
    _local_discovery_tracker.add_touched_path (relative_path_bytes);

    // The folder watcher fires a lot of bogus notifications during
    // a sync operation, both for actual user files and the database
    // and log. Therefore we check notifications against operations
    // the sync is doing to filter out our own changes.

    // Use the path to figure out whether it was our own change
    if (_engine.was_file_touched (path)) {
        q_c_debug (lc_folder) << "Changed path was touched by SyncEngine, ignoring:" << path;
        return;
    }


    SyncJournalFileRecord record;
    _journal.get_file_record (relative_path_bytes, &record);
    if (reason != ChangeReason.UnLock) {
        // Check that the mtime/size actually changed or there was
        // an attribute change (pin state) that caused the notification
        bool spurious = false;
        if (record.is_valid ()
            && !FileSystem.file_changed (path, record._file_size, record._modtime)) {
            spurious = true;

            if (auto pin_state = _vfs.pin_state (relative_path.to_string ())) {
                if (*pin_state == PinState.AlwaysLocal && record.is_virtual_file ())
                    spurious = false;
                if (*pin_state == PinState.OnlineOnly && record.is_file ())
                    spurious = false;
            }
        }
        if (spurious) {
            q_c_info (lc_folder) << "Ignoring spurious notification for file" << relative_path;
            return; // probably a spurious notification
        }
    }
    warn_on_new_excluded_item (record, relative_path);

    emit watched_file_changed_externally (path);

    // Also schedule this folder for a sync, but only after some delay:
    // The sync will not upload files that were changed too recently.
    schedule_this_folder_soon ();
}

void Folder.implicitly_hydrate_file (string &relativepath) {
    q_c_info (lc_folder) << "Implicitly hydrate virtual file:" << relativepath;

    // Set in the database that we should download the file
    SyncJournalFileRecord record;
    _journal.get_file_record (relativepath.to_utf8 (), &record);
    if (!record.is_valid ()) {
        q_c_info (lc_folder) << "Did not find file in db";
        return;
    }
    if (!record.is_virtual_file ()) {
        q_c_info (lc_folder) << "The file is not virtual";
        return;
    }
    record._type = ItemTypeVirtualFileDownload;
    _journal.set_file_record (record);

    // Change the file's pin state if it's contradictory to being hydrated
    // (suffix-virtual file's pin state is stored at the hydrated path)
    const auto pin = _vfs.pin_state (relativepath);
    if (pin && *pin == PinState.OnlineOnly) {
        if (!_vfs.set_pin_state (relativepath, PinState.Unspecified)) {
            q_c_warning (lc_folder) << "Could not set pin state of" << relativepath << "to unspecified";
        }
    }

    // Add to local discovery
    schedule_path_for_local_discovery (relativepath);
    slot_schedule_this_folder ();
}

void Folder.set_virtual_files_enabled (bool enabled) {
    Vfs.Mode new_mode = _definition.virtual_files_mode;
    if (enabled && _definition.virtual_files_mode == Vfs.Off) {
        new_mode = best_available_vfs_mode ();
    } else if (!enabled && _definition.virtual_files_mode != Vfs.Off) {
        new_mode = Vfs.Off;
    }

    if (new_mode != _definition.virtual_files_mode) {
        // TODO : Must wait for current sync to finish!
        SyncEngine.wipe_virtual_files (path (), _journal, *_vfs);

        _vfs.stop ();
        _vfs.unregister_folder ();

        disconnect (_vfs.data (), nullptr, this, nullptr);
        disconnect (&_engine.sync_file_status_tracker (), nullptr, _vfs.data (), nullptr);

        _vfs.reset (create_vfs_from_plugin (new_mode).release ());

        _definition.virtual_files_mode = new_mode;
        start_vfs ();
        if (new_mode != Vfs.Off) {
            _save_in_folders_with_placeholders = true;
            switch_to_virtual_files ();
        }
        save_to_settings ();
    }
}

void Folder.set_root_pin_state (PinState state) {
    if (!_vfs.set_pin_state (string (), state)) {
        q_c_warning (lc_folder) << "Could not set root pin state of" << _definition.alias;
    }

    // We don't actually need discovery, but it's important to recurse
    // into all folders, so the changes can be applied.
    slot_next_sync_full_local_discovery ();
}

void Folder.switch_to_virtual_files () {
    SyncEngine.switch_to_virtual_files (path (), _journal, *_vfs);
    _has_switched_to_vfs = true;
}

void Folder.process_switched_to_virtual_files () {
    if (_has_switched_to_vfs) {
        _has_switched_to_vfs = false;
        save_to_settings ();
    }
}

bool Folder.supports_selective_sync () {
    return !virtual_files_enabled () && !is_vfs_on_off_switch_pending ();
}

void Folder.save_to_settings () {
    // Remove first to make sure we don't get duplicates
    remove_from_settings ();

    auto settings = _account_state.settings ();
    string settings_group = QStringLiteral ("Multifolders");

    // True if the folder path appears in only one account
    const auto folder_map = FolderMan.instance ().map ();
    const auto one_account_only = std.none_of (folder_map.cbegin (), folder_map.cend (), [this] (auto *other) {
        return other != this && other.clean_path () == this.clean_path ();
    });

    if (virtual_files_enabled () || _save_in_folders_with_placeholders) {
        // If virtual files are enabled or even were enabled at some point,
        // save the folder to a group that will not be read by older (<2.5.0) clients.
        // The name is from when virtual files were called placeholders.
        settings_group = QStringLiteral ("FoldersWithPlaceholders");
    } else if (_save_backwards_compatible || one_account_only) {
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
    // Note : Each of these groups might have a "version" tag, but that's
    //       currently unused.
    settings.begin_group (FolderMan.escape_alias (_definition.alias));
    FolderDefinition.save (*settings, _definition);

    settings.sync ();
    q_c_info (lc_folder) << "Saved folder" << _definition.alias << "to settings, status" << settings.status ();
}

void Folder.remove_from_settings () {
    auto settings = _account_state.settings ();
    settings.begin_group (QLatin1String ("Folders"));
    settings.remove (FolderMan.escape_alias (_definition.alias));
    settings.end_group ();
    settings.begin_group (QLatin1String ("Multifolders"));
    settings.remove (FolderMan.escape_alias (_definition.alias));
    settings.end_group ();
    settings.begin_group (QLatin1String ("FoldersWithPlaceholders"));
    settings.remove (FolderMan.escape_alias (_definition.alias));
}

bool Folder.is_file_excluded_absolute (string &full_path) {
    return _engine.excluded_files ().is_excluded (full_path, path (), _definition.ignore_hidden_files);
}

bool Folder.is_file_excluded_relative (string &relative_path) {
    return _engine.excluded_files ().is_excluded (path () + relative_path, path (), _definition.ignore_hidden_files);
}

void Folder.slot_terminate_sync () {
    q_c_info (lc_folder) << "folder " << alias () << " Terminating!";

    if (_engine.is_sync_running ()) {
        _engine.abort ();

        set_sync_state (SyncResult.Sync_abort_requested);
    }
}

void Folder.wipe_for_removal () {
    // Delete files that have been partially downloaded.
    slot_discard_download_progress ();

    // Unregister the socket API so it does not keep the .sync_journal file open
    FolderMan.instance ().socket_api ().slot_unregister_path (alias ());
    _journal.close (); // close the sync journal

    // Remove db and temporaries
    string state_db_file = _engine.journal ().database_file_path ();

    QFile file (state_db_file);
    if (file.exists ()) {
        if (!file.remove ()) {
            q_c_warning (lc_folder) << "Failed to remove existing csync State_d_b " << state_db_file;
        } else {
            q_c_info (lc_folder) << "wipe : Removed csync State_d_b " << state_db_file;
        }
    } else {
        q_c_warning (lc_folder) << "statedb is empty, can not remove.";
    }

    // Also remove other db related files
    QFile.remove (state_db_file + ".ctmp");
    QFile.remove (state_db_file + "-shm");
    QFile.remove (state_db_file + "-wal");
    QFile.remove (state_db_file + "-journal");

    _vfs.stop ();
    _vfs.unregister_folder ();
    _vfs.reset (nullptr); // warning : folder now in an invalid state
}

bool Folder.reload_excludes () {
    return _engine.excluded_files ().reload_exclude_files ();
}

void Folder.start_sync (QStringList &path_list) {
    Q_UNUSED (path_list)

    if (is_busy ()) {
        q_c_critical (lc_folder) << "ERROR csync is still running and new sync requested.";
        return;
    }

    _time_since_last_sync_start.start ();
    _sync_result.set_status (SyncResult.Sync_prepare);
    emit sync_state_change ();

    q_c_info (lc_folder) << "*** Start syncing " << remote_url ().to_string () << " -" << APPLICATION_NAME << "client version"
                     << q_printable (Theme.instance ().version ());

    _file_log.start (path ());

    if (!reload_excludes ()) {
        slot_sync_error (tr ("Could not read system exclude file"));
        QMetaObject.invoke_method (this, "slot_sync_finished", Qt.QueuedConnection, Q_ARG (bool, false));
        return;
    }

    set_dirty_network_limits ();
    set_sync_options ();

    static std.chrono.milliseconds full_local_discovery_interval = [] () {
        auto interval = ConfigFile ().full_local_discovery_interval ();
        QByteArray env = qgetenv ("OWNCLOUD_FULL_LOCAL_DISCOVERY_INTERVAL");
        if (!env.is_empty ()) {
            interval = std.chrono.milliseconds (env.to_long_long ());
        }
        return interval;
    } ();
    bool has_done_full_local_discovery = _time_since_last_full_local_discovery.is_valid ();
    bool periodic_full_local_discovery_now =
        full_local_discovery_interval.count () >= 0 // negative means we don't require periodic full runs
        && _time_since_last_full_local_discovery.has_expired (full_local_discovery_interval.count ());
    if (_folder_watcher && _folder_watcher.is_reliable ()
        && has_done_full_local_discovery
        && !periodic_full_local_discovery_now) {
        q_c_info (lc_folder) << "Allowing local discovery to read from the database";
        _engine.set_local_discovery_options (
            LocalDiscoveryStyle.DatabaseAndFilesystem,
            _local_discovery_tracker.local_discovery_paths ());
        _local_discovery_tracker.start_sync_partial_discovery ();
    } else {
        q_c_info (lc_folder) << "Forbidding local discovery to read from the database";
        _engine.set_local_discovery_options (LocalDiscoveryStyle.FilesystemOnly);
        _local_discovery_tracker.start_sync_full_discovery ();
    }

    _engine.set_ignore_hidden_files (_definition.ignore_hidden_files);

    correct_placeholder_files ();

    QMetaObject.invoke_method (_engine.data (), "start_sync", Qt.QueuedConnection);

    emit sync_started ();
}

void Folder.correct_placeholder_files () {
    if (_definition.virtual_files_mode == Vfs.Off) {
        return;
    }
    static const auto placeholders_corrected_key = QStringLiteral ("placeholders_corrected");
    const auto placeholders_corrected = _journal.key_value_store_get_int (placeholders_corrected_key, 0);
    if (!placeholders_corrected) {
        q_c_debug (lc_folder) << "Make sure all virtual files are placeholder files";
        switch_to_virtual_files ();
        _journal.key_value_store_set (placeholders_corrected_key, true);
    }
}

void Folder.set_sync_options () {
    SyncOptions opt;
    ConfigFile cfg_file;

    auto new_folder_limit = cfg_file.new_big_folder_size_limit ();
    opt._new_big_folder_size_limit = new_folder_limit.first ? new_folder_limit.second * 1000LL * 1000LL : -1; // convert from MB to B
    opt._confirm_external_storage = cfg_file.confirm_external_storage ();
    opt._move_files_to_trash = cfg_file.move_to_trash ();
    opt._vfs = _vfs;
    opt._parallel_network_jobs = _account_state.account ().is_http2Supported () ? 20 : 6;

    opt._initial_chunk_size = cfg_file.chunk_size ();
    opt._min_chunk_size = cfg_file.min_chunk_size ();
    opt._max_chunk_size = cfg_file.max_chunk_size ();
    opt._target_chunk_upload_duration = cfg_file.target_chunk_upload_duration ();

    opt.fill_from_environment_variables ();
    opt.verify_chunk_sizes ();

    _engine.set_sync_options (opt);
}

void Folder.set_dirty_network_limits () {
    ConfigFile cfg;
    int download_limit = -75; // 75%
    int use_down_limit = cfg.use_download_limit ();
    if (use_down_limit >= 1) {
        download_limit = cfg.download_limit () * 1000;
    } else if (use_down_limit == 0) {
        download_limit = 0;
    }

    int upload_limit = -75; // 75%
    int use_up_limit = cfg.use_upload_limit ();
    if (use_up_limit >= 1) {
        upload_limit = cfg.upload_limit () * 1000;
    } else if (use_up_limit == 0) {
        upload_limit = 0;
    }

    _engine.set_network_limits (upload_limit, download_limit);
}

void Folder.slot_sync_error (string &message, ErrorCategory category) {
    _sync_result.append_error_string (message);
    emit Progress_dispatcher.instance ().sync_error (alias (), message, category);
}

void Folder.slot_add_error_to_gui (SyncFileItem.Status status, string &error_message, string &subject) {
    emit Progress_dispatcher.instance ().add_error_to_gui (alias (), status, error_message, subject);
}

void Folder.slot_sync_started () {
    q_c_info (lc_folder) << "#### Propagation start ####################################################";
    _sync_result.set_status (SyncResult.Sync_running);
    emit sync_state_change ();
}

void Folder.slot_sync_finished (bool success) {
    q_c_info (lc_folder) << "Client version" << q_printable (Theme.instance ().version ())
                     << " Qt" << q_version ()
                     << " SSL " << QSslSocket.ssl_library_version_string ().to_utf8 ().data ()
        ;

    bool sync_error = !_sync_result.error_strings ().is_empty ();
    if (sync_error) {
        q_c_warning (lc_folder) << "SyncEngine finished with ERROR";
    } else {
        q_c_info (lc_folder) << "SyncEngine finished without problem.";
    }
    _file_log.finish ();
    show_sync_result_popup ();

    auto another_sync_needed = _engine.is_another_sync_needed ();

    if (sync_error) {
        _sync_result.set_status (SyncResult.Error);
    } else if (_sync_result.found_files_not_synced ()) {
        _sync_result.set_status (SyncResult.Problem);
    } else if (_definition.paused) {
        // Maybe the sync was terminated because the user paused the folder
        _sync_result.set_status (SyncResult.Paused);
    } else {
        _sync_result.set_status (SyncResult.Success);
    }

    // Count the number of syncs that have failed in a row.
    if (_sync_result.status () == SyncResult.Success
        || _sync_result.status () == SyncResult.Problem) {
        _consecutive_failing_syncs = 0;
    } else {
        _consecutive_failing_syncs++;
        q_c_info (lc_folder) << "the last" << _consecutive_failing_syncs << "syncs failed";
    }

    if (_sync_result.status () == SyncResult.Success && success) {
        // Clear the white list as all the folders that should be on that list are sync-ed
        journal_db ().set_selective_sync_list (SyncJournalDb.SelectiveSyncWhiteList, QStringList ());
    }

    if ( (_sync_result.status () == SyncResult.Success
            || _sync_result.status () == SyncResult.Problem)
        && success) {
        if (_engine.last_local_discovery_style () == LocalDiscoveryStyle.FilesystemOnly) {
            _time_since_last_full_local_discovery.start ();
        }
    }

    emit sync_state_change ();

    // The sync_finished result that is to be triggered here makes the folderman
    // clear the current running sync folder marker.
    // Lets wait a bit to do that because, as long as this marker is not cleared,
    // file system change notifications are ignored for that folder. And it takes
    // some time under certain conditions to make the file system notifications
    // all come in.
    QTimer.single_shot (200, this, &Folder.slot_emit_finished_delayed);

    _last_sync_duration = std.chrono.milliseconds (_time_since_last_sync_start.elapsed ());
    _time_since_last_sync_done.start ();

    // Increment the follow-up sync counter if necessary.
    if (another_sync_needed == Immediate_follow_up) {
        _consecutive_follow_up_syncs++;
        q_c_info (lc_folder) << "another sync was requested by the finished sync, this has"
                         << "happened" << _consecutive_follow_up_syncs << "times";
    } else {
        _consecutive_follow_up_syncs = 0;
    }

    // Maybe force a follow-up sync to take place, but only a couple of times.
    if (another_sync_needed == Immediate_follow_up && _consecutive_follow_up_syncs <= 3) {
        // Sometimes another sync is requested because a local file is still
        // changing, so wait at least a small amount of time before syncing
        // the folder again.
        schedule_this_folder_soon ();
    }
}

void Folder.slot_emit_finished_delayed () {
    emit sync_finished (_sync_result);

    // Immediately check the etag again if there was some sync activity.
    if ( (_sync_result.status () == SyncResult.Success
            || _sync_result.status () == SyncResult.Problem)
        && (_sync_result.first_item_deleted ()
               || _sync_result.first_item_new ()
               || _sync_result.first_item_renamed ()
               || _sync_result.first_item_updated ()
               || _sync_result.first_new_conflict_item ())) {
        slot_run_etag_job ();
    }
}

// the progress comes without a folder and the valid path set. Add that here
// and hand the result over to the progress dispatcher.
void Folder.slot_transmission_progress (ProgressInfo &pi) {
    emit progress_info (pi);
    Progress_dispatcher.instance ().set_progress_info (alias (), pi);
}

// a item is completed : count the errors and forward to the Progress_dispatcher
void Folder.slot_item_completed (SyncFileItemPtr &item) {
    if (item._instruction == CSYNC_INSTRUCTION_NONE || item._instruction == CSYNC_INSTRUCTION_UPDATE_METADATA) {
        // We only care about the updates that deserve to be shown in the UI
        return;
    }

    _sync_result.process_completed_item (item);

    _file_log.log_item (*item);
    emit Progress_dispatcher.instance ().item_completed (alias (), item);
}

void Folder.slot_new_big_folder_discovered (string &new_f, bool is_external) {
    auto new_folder = new_f;
    if (!new_folder.ends_with (QLatin1Char ('/'))) {
        new_folder += QLatin1Char ('/');
    }
    auto journal = journal_db ();

    // Add the entry to the blacklist if it is neither in the blacklist or whitelist already
    bool ok1 = false;
    bool ok2 = false;
    auto blacklist = journal.get_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, &ok1);
    auto whitelist = journal.get_selective_sync_list (SyncJournalDb.SelectiveSyncWhiteList, &ok2);
    if (ok1 && ok2 && !blacklist.contains (new_folder) && !whitelist.contains (new_folder)) {
        blacklist.append (new_folder);
        journal.set_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, blacklist);
    }

    // And add the entry to the undecided list and signal the UI
    auto undecided_list = journal.get_selective_sync_list (SyncJournalDb.SelectiveSyncUndecidedList, &ok1);
    if (ok1) {
        if (!undecided_list.contains (new_folder)) {
            undecided_list.append (new_folder);
            journal.set_selective_sync_list (SyncJournalDb.SelectiveSyncUndecidedList, undecided_list);
            emit new_big_folder_discovered (new_folder);
        }
        string message = !is_external ? (tr ("A new folder larger than %1 MB has been added : %2.\n")
                                                .arg (ConfigFile ().new_big_folder_size_limit ().second)
                                                .arg (new_f))
                                      : (tr ("A folder from an external storage has been added.\n"));
        message += tr ("Please go in the settings to select it if you wish to download it.");

        auto logger = Logger.instance ();
        logger.post_optional_gui_log (Theme.instance ().app_name_g_u_i (), message);
    }
}

void Folder.slot_log_propagation_start () {
    _file_log.log_lap ("Propagation starts");
}

void Folder.slot_schedule_this_folder () {
    FolderMan.instance ().schedule_folder (this);
}

void Folder.slot_next_sync_full_local_discovery () {
    _time_since_last_full_local_discovery.invalidate ();
}

void Folder.schedule_path_for_local_discovery (string &relative_path) {
    _local_discovery_tracker.add_touched_path (relative_path.to_utf8 ());
}

void Folder.slot_folder_conflicts (string &folder, QStringList &conflict_paths) {
    if (folder != _definition.alias)
        return;
    auto &r = _sync_result;

    // If the number of conflicts is too low, adjust it upwards
    if (conflict_paths.size () > r.num_new_conflict_items () + r.num_old_conflict_items ())
        r.set_num_old_conflict_items (conflict_paths.size () - r.num_new_conflict_items ());
}

void Folder.warn_on_new_excluded_item (SyncJournalFileRecord &record, QStringRef &path) {
    // Never warn for items in the database
    if (record.is_valid ())
        return;

    // Don't warn for items that no longer exist.
    // Note : This assumes we're getting file watcher notifications
    // for folders only on creation and deletion - if we got a notification
    // on content change that would create spurious warnings.
    QFileInfo fi (_canonical_local_path + path);
    if (!fi.exists ())
        return;

    bool ok = false;
    auto blacklist = _journal.get_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, &ok);
    if (!ok)
        return;
    if (!blacklist.contains (path + "/"))
        return;

    const auto message = fi.is_dir ()
        ? tr ("The folder %1 was created but was excluded from synchronization previously. "
             "Data inside it will not be synchronized.")
              .arg (fi.file_path ())
        : tr ("The file %1 was created but was excluded from synchronization previously. "
             "It will not be synchronized.")
              .arg (fi.file_path ());

    Logger.instance ().post_optional_gui_log (Theme.instance ().app_name_g_u_i (), message);
}

void Folder.slot_watcher_unreliable (string &message) {
    q_c_warning (lc_folder) << "Folder watcher for" << path () << "became unreliable:" << message;
    auto full_message =
        tr ("Changes in synchronized folders could not be tracked reliably.\n"
           "\n"
           "This means that the synchronization client might not upload local changes "
           "immediately and will instead only scan for local changes and upload them "
           "occasionally (every two hours by default).\n"
           "\n"
           "%1").arg (message);
    Logger.instance ().post_gui_log (Theme.instance ().app_name_g_u_i (), full_message);
}

void Folder.slot_hydration_starts () {
    // Abort any running full sync run and reschedule
    if (_engine.is_sync_running ()) {
        slot_terminate_sync ();
        schedule_this_folder_soon ();
        // TODO : This sets the sync state to Abort_requested on done, we don't want that
    }

    // Let everyone know we're syncing
    _sync_result.reset ();
    _sync_result.set_status (SyncResult.Sync_running);
    emit sync_started ();
    emit sync_state_change ();
}

void Folder.slot_hydration_done () {
    // emit signal to update ui and reschedule normal syncs if necessary
    _sync_result.set_status (SyncResult.Success);
    emit sync_finished (_sync_result);
    emit sync_state_change ();
}

void Folder.schedule_this_folder_soon () {
    if (!_schedule_self_timer.is_active ()) {
        _schedule_self_timer.start ();
    }
}

void Folder.set_save_backwards_compatible (bool save) {
    _save_backwards_compatible = save;
}

void Folder.register_folder_watcher () {
    if (_folder_watcher)
        return;
    if (!QDir (path ()).exists ())
        return;

    _folder_watcher.reset (new Folder_watcher (this));
    connect (_folder_watcher.data (), &Folder_watcher.path_changed,
        this, [this] (string &path) {
            slot_watched_path_changed (path, Folder.ChangeReason.Other);
        });
    connect (_folder_watcher.data (), &Folder_watcher.lost_changes,
        this, &Folder.slot_next_sync_full_local_discovery);
    connect (_folder_watcher.data (), &Folder_watcher.became_unreliable,
        this, &Folder.slot_watcher_unreliable);
    _folder_watcher.init (path ());
    _folder_watcher.start_notificaton_test (path () + QLatin1String (".owncloudsync.log"));
}

bool Folder.virtual_files_enabled () {
    return _definition.virtual_files_mode != Vfs.Off && !is_vfs_on_off_switch_pending ();
}

void Folder.slot_about_to_remove_all_files (SyncFileItem.Direction dir, std.function<void (bool)> callback) {
    ConfigFile cfg_file;
    if (!cfg_file.prompt_delete_files ()) {
        callback (false);
        return;
    }

    const string msg = dir == SyncFileItem.Down ? tr ("All files in the sync folder \"%1\" folder were deleted on the server.\n"
                                                 "These deletes will be synchronized to your local sync folder, making such files "
                                                 "unavailable unless you have a right to restore. \n"
                                                 "If you decide to restore the files, they will be re-synced with the server if you have rights to do so.\n"
                                                 "If you decide to delete the files, they will be unavailable to you, unless you are the owner.")
                                            : tr ("All the files in your local sync folder \"%1\" were deleted. These deletes will be "
                                                 "synchronized with your server, making such files unavailable unless restored.\n"
                                                 "Are you sure you want to sync those actions with the server?\n"
                                                 "If this was an accident and you decide to keep your files, they will be re-synced from the server.");
    auto msg_box = new QMessageBox (QMessageBox.Warning, tr ("Remove All Files?"),
        msg.arg (short_gui_local_path ()), QMessageBox.NoButton);
    msg_box.set_attribute (Qt.WA_DeleteOnClose);
    msg_box.set_window_flags (msg_box.window_flags () | Qt.Window_stays_on_top_hint);
    msg_box.add_button (tr ("Remove all files"), QMessageBox.DestructiveRole);
    QPushButton *keep_btn = msg_box.add_button (tr ("Keep files"), QMessageBox.AcceptRole);
    bool old_paused = sync_paused ();
    set_sync_paused (true);
    connect (msg_box, &QMessageBox.finished, this, [msg_box, keep_btn, callback, old_paused, this] {
        const bool cancel = msg_box.clicked_button () == keep_btn;
        callback (cancel);
        if (cancel) {
            FileSystem.set_folder_minimum_permissions (path ());
            journal_db ().clear_file_table ();
            _last_etag.clear ();
            slot_schedule_this_folder ();
        }
        set_sync_paused (old_paused);
    });
    connect (this, &Folder.destroyed, msg_box, &QMessageBox.delete_later);
    msg_box.open ();
}

string Folder.file_from_local_path (string &local_path) {
    return local_path.mid (clean_path ().length () + 1);
}

void FolderDefinition.save (QSettings &settings, FolderDefinition &folder) {
    settings.set_value (QLatin1String ("local_path"), folder.local_path);
    settings.set_value (QLatin1String ("journal_path"), folder.journal_path);
    settings.set_value (QLatin1String ("target_path"), folder.target_path);
    settings.set_value (QLatin1String ("paused"), folder.paused);
    settings.set_value (QLatin1String ("ignore_hidden_files"), folder.ignore_hidden_files);

    settings.set_value (QStringLiteral ("virtual_files_mode"), Vfs.mode_to_string (folder.virtual_files_mode));

    // Ensure new vfs modes won't be attempted by older clients
    if (folder.virtual_files_mode == Vfs.WindowsCfApi) {
        settings.set_value (QLatin1String (version_c), 3);
    } else {
        settings.set_value (QLatin1String (version_c), 2);
    }

    // Happens only on Windows when the explorer integration is enabled.
    if (!folder.navigation_pane_clsid.is_null ())
        settings.set_value (QLatin1String ("navigation_pane_clsid"), folder.navigation_pane_clsid);
    else
        settings.remove (QLatin1String ("navigation_pane_clsid"));
}

bool FolderDefinition.load (QSettings &settings, string &alias,
    FolderDefinition *folder) {
    folder.alias = FolderMan.unescape_alias (alias);
    folder.local_path = settings.value (QLatin1String ("local_path")).to_string ();
    folder.journal_path = settings.value (QLatin1String ("journal_path")).to_string ();
    folder.target_path = settings.value (QLatin1String ("target_path")).to_string ();
    folder.paused = settings.value (QLatin1String ("paused")).to_bool ();
    folder.ignore_hidden_files = settings.value (QLatin1String ("ignore_hidden_files"), QVariant (true)).to_bool ();
    folder.navigation_pane_clsid = settings.value (QLatin1String ("navigation_pane_clsid")).to_uuid ();

    folder.virtual_files_mode = Vfs.Off;
    string vfs_mode_string = settings.value (QStringLiteral ("virtual_files_mode")).to_string ();
    if (!vfs_mode_string.is_empty ()) {
        if (auto mode = Vfs.mode_from_string (vfs_mode_string)) {
            folder.virtual_files_mode = *mode;
        } else {
            q_c_warning (lc_folder) << "Unknown virtual_files_mode:" << vfs_mode_string << "assuming 'off'";
        }
    } else {
        if (settings.value (QLatin1String ("use_placeholders")).to_bool ()) {
            folder.virtual_files_mode = Vfs.WithSuffix;
            folder.upgrade_vfs_mode = true; // maybe winvfs is available?
        }
    }

    // Old settings can contain paths with native separators. In the rest of the
    // code we assume /, so clean it up now.
    folder.local_path = prepare_local_path (folder.local_path);

    // Target paths also have a convention
    folder.target_path = prepare_target_path (folder.target_path);

    return true;
}

string FolderDefinition.prepare_local_path (string &path) {
    string p = QDir.from_native_separators (path);
    if (!p.ends_with (QLatin1Char ('/'))) {
        p.append (QLatin1Char ('/'));
    }
    return p;
}

string FolderDefinition.prepare_target_path (string &path) {
    string p = path;
    if (p.ends_with (QLatin1Char ('/'))) {
        p.chop (1);
    }
    // Doing this second ensures the empty string or "/" come
    // out as "/".
    if (!p.starts_with (QLatin1Char ('/'))) {
        p.prepend (QLatin1Char ('/'));
    }
    return p;
}

string FolderDefinition.absolute_journal_path () {
    return QDir (local_path).file_path (journal_path);
}

string FolderDefinition.default_journal_path (AccountPtr account) {
    return SyncJournalDb.make_db_name (local_path, account.url (), target_path, account.credentials ().user ());
}

} // namespace Occ
