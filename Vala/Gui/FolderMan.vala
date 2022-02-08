/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <pushnotifications.h>
//  #include <syncengine.h>
//  #include <QMessag
//  #include <QtCore>
//  #include <QMutableSetIter
//  #include <QNetwor
//  #include <QQueue>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The FolderMan class
@ingroup gui

The FolderMan knows about all load
scheduling them when nece

A folder is scheduled if:
- The configured force-sync-interval has expired
  (this.time_scheduler and on_signal_schedule_folder_by_time ())

- A folder watcher re
  (this.folder_watchers and Folder.on_signal_watched_pat

- The folder etag on the server has changed
  (this.etag_poll_timer)

- The locks of a monitored file are released
  (this.lock_watcher and on_signal_watched_file_unlocked ())

- There was a sync error or a follow-up sync is r
  (this.time_scheduler and on_signal_schedule_folder_by_time ()
   and Folder.on_signal_sync_finished ())
***********************************************************/
class FolderMan : GLib.Object {

    const string VERSION_C = "version";
    const int max_folders_version = 1;

    ~FolderMan () override;
    public static FolderMan instance ();

    /***********************************************************
    ***********************************************************/
    public int setup_folders ();

    /***********************************************************
    ***********************************************************/
    public int setup_folders_migration ();


    /***********************************************************
    Returns a list of keys that can't be read because they are from
    future versions.
    ***********************************************************/
    public static void backward_migration_settings_keys (string[] *delete_keys, string[] *ignore_keys);

    /***********************************************************
    ***********************************************************/
    public const Folder.Map map ();


    /***********************************************************
    Adds a folder for an account, ensures the journal is gone and saves it in the settings.
    ***********************************************************/
    public Folder add_folder (AccountState account_state, FolderDefinition folder_definition);


    /***********************************************************
    Removes a folder
    ***********************************************************/
    public void remove_folder (Folder *);


    /***********************************************************
    Returns the folder which the file or directory stored in path is in
    ***********************************************************/
    public Folder folder_for_path (string path);


    /***********************************************************
    returns a list of local files that exist on the local harddisk for an
    incoming relative server path. The method checks with all existing sync
    folders.
    ***********************************************************/
    public string[] find_file_in_local_folders (string rel_path, AccountPointer acc);


    /***********************************************************
    Returns the folder by alias or \c null if no folder with the alias exists.
    ***********************************************************/
    public Folder folder (string );


    /***********************************************************
    Migrate accounts from owncloud < 2.0
    Creates a folder for a specific configuration, identified by alias.
    ***********************************************************/
    public Folder setup_folder_from_old_config_file (string , AccountState account);


    /***********************************************************
    Ensures that a given directory does not contain a sync journal file.

    @returns false if the journal could not be removed, true otherwise.
    ***********************************************************/
    public static bool ensure_journal_gone (string journal_database_file);


    /***********************************************************
    Creates a new and empty local directory.
    ***********************************************************/
    public bool start_from_scratch (string );

    /// Produce text for use in the tray tooltip
    public static string tray_tooltip_status_string (SyncResult.Status sync_status, bool has_unresolved_conflicts, bool paused);

    /// Compute status summarizing multiple folders
    public static void tray_overall_status (GLib.List<Folder> folders,
        SyncResult.Status status, bool unresolved_conflicts);

    // Escaping of the alias which is used in QSettings AND the file
    // system, thus need to be escaped.
    public static string escape_alias (string );


    /***********************************************************
    ***********************************************************/
    public static string unescape_alias (string );

    /***********************************************************
    ***********************************************************/
    public SocketApi socket_api ();

    /***********************************************************
    ***********************************************************/
    public NavigationPaneHelper navigation_pane_helper () {
        return this.navigation_pane_helper;
    }


    /***********************************************************
    Check if @a path is a valid path for a new folder considering the already sync'ed items.
    Make sure that this folder, or any subfolder is not sync'ed already.

    Note that different accounts are allowed to sync to the same folder.

    @returns an empty string if it is allowed, or an error if it is not allowed
    ***********************************************************/
    public string check_path_validity_for_new_folder (string path, GLib.Uri server_url = GLib.Uri ());


    /***********************************************************
    Attempts to find a non-existing, acceptable path for creating a new sync folder.

    Uses \a base_path as the baseline. It'll return this path if it's acceptable.

    Note that this can fail. If someone syncs ~ and \a base_path is ~/own_cloud, no
    subfolder of ~ would be a good candidate. When that happens \a base_path
    is returned.
    ***********************************************************/
    public string find_good_path_for_new_sync_folder (string base_path, GLib.Uri server_url);


    /***********************************************************
    While ignoring hidden files can theoretically be switched per folder,
    it's currently a global setting that users can only change for all folders
    at once.
    These helper functions can be removed once it's properly per-folder.
    ***********************************************************/
    public bool ignore_hidden_files ();


    /***********************************************************
    ***********************************************************/
    public void ignore_hidden_files (bool ignore);


    /***********************************************************
    Access to the current queue of scheduled folders.
    ***********************************************************/
    public QQueue<Folder> schedule_queue ();


    /***********************************************************
    Access to the currently syncing folder.

    Note: This is only the folder that's currently syncing as-scheduled
    may be externally-managed syncs such as from placeholder hydrations.

    See also is_any_sync_running ()
    ***********************************************************/
    public Folder current_sync_folder ();


    /***********************************************************
    Returns true if any folder is currently syncing.

    This might be a FolderMan-scheduled sync, or a externally
    managed sync like a placeholder hydration.
    ***********************************************************/
    public bool is_any_sync_running ();


    /***********************************************************
    Removes all folders
    ***********************************************************/
    public int unload_and_delete_all_folders ();


    /***********************************************************
    If enabled is set to false, no new folders will on_signal_start to sync.
    The current one will finish.
    ***********************************************************/
    public void sync_enabled (bool);


    /***********************************************************
    Queues a folder for syncing.
    ***********************************************************/
    public void schedule_folder (Folder *);


    /***********************************************************
    Puts a folder in the very front of the queue.
    ***********************************************************/
    public void schedule_folder_next (Folder *);


    /***********************************************************
    Queues all folders for syncing.
    ***********************************************************/
    public void schedule_all_folders ();

    /***********************************************************
    ***********************************************************/
    public void dirty_proxy ();

    /***********************************************************
    ***********************************************************/
    public void dirty_network_limits ();

signals:
    /***********************************************************
    signal to indicate a folder has changed its sync state.

    Attention : The folder may be zero. Do a general update of the state then.
    ***********************************************************/
    void folder_sync_state_change (Folder *);


    /***********************************************************
    Indicates when the schedule queue changes.
    ***********************************************************/
    void schedule_queue_changed ();


    /***********************************************************
    Emitted whenever the list of configured folders changes.
    ***********************************************************/
    void folder_list_changed (Folder.Map &);


    /***********************************************************
    Emitted once on_signal_remove_folders_for_account is done wiping
    ***********************************************************/
    void wipe_done (AccountState account, bool on_signal_success);


    /***********************************************************
    Schedules folders of newly connected accounts, terminates and
    de-schedules folders of disconnected accounts.
    ***********************************************************/
    public void on_signal_account_state_changed ();


    /***********************************************************
    restart the client as soon as it is possible, ie. no folders syncing.
    ***********************************************************/
    public void on_signal_schedule_app_restart ();


    /***********************************************************
    Triggers a sync run once the lock on the given file is removed.

    Automatically detemines the folder that's responsible for the file.
    See on_signal_watched_file_unlocked ().
    ***********************************************************/
    public void on_signal_sync_once_file_unlocks (string path);

    // slot to schedule an ETag job (from Folder only)
    public void on_signal_schedule_e_tag_job (string alias, RequestEtagJob job);


    /***********************************************************
    Wipe folder
    ***********************************************************/
    public void on_signal_wipe_folder_for_account (AccountState account_state);


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_sync_paused (Folder *, bool paused);
    private void on_signal_folder_can_sync_changed ();
    private void on_signal_folder_sync_started ();
    private void on_signal_folder_sync_finished (SyncResult &);

    /***********************************************************
    ***********************************************************/
    private void on_signal_run_one_etag_job ();
    private void on_signal_etag_job_destroyed (GLib.Object *);

    // slot to take the next folder from queue and on_signal_start syncing.
    private void on_signal_start_scheduled_folder_sync ();
    private void on_signal_etag_poll_timer_timeout ();

    /***********************************************************
    ***********************************************************/
    private void on_signal_account_removed (AccountState account_state);

    /***********************************************************
    ***********************************************************/
    private void on_signal_remove_folders_for_account (AccountState account_state);

    // Wraps the Folder.sync_state_change () signal into the
    // FolderMan.folder_sync_state_change (Folder*) signal.
    private void on_signal_forward_folder_sync_state_change ();

    /***********************************************************
    ***********************************************************/
    private void on_signal_server_version_changed (Account account);


    /***********************************************************
    A file whose locks were being monitored has become unlocked.

    This schedules the folder for synchronization that contains
    the file with the given path.
    ***********************************************************/
    void on_signal_watched_file_unlocked (string path);


    /***********************************************************
    Schedules folders whose time to sync has come.

    Either because a long time has passed since the last sync or
    because of previous failures.
    ***********************************************************/
    void on_signal_schedule_folder_by_time ();

    void on_signal_setup_push_notifications (Folder.Map &);
    void on_signal_process_files_push_notification (Account account);
    void on_signal_connect_to_push_notifications (Account account);


    /***********************************************************
    Adds a new folder, does not add it to the account settings and
    does not set an account on the new folder.
    ***********************************************************/
    private Folder add_folder_internal (FolderDefinition folder_definition,
        AccountState account_state, std.unique_ptr<Vfs> vfs);


    /***********************************************************
    unloads a folder object, does not delete it
    ***********************************************************/
    private void unload_folder (Folder *);


    /***********************************************************
    Will on_signal_start a sync after a bit of delay.
    ***********************************************************/
    private void start_scheduled_sync_soon ();

    // finds all folder configuration files
    // and create the folders
    private string get_backup_name (string full_path_name);

    // makes the folder known to the socket api
    private void register_folder_with_socket_api (Folder folder);

    // restarts the application (Linux only)
    private void restart_application ();

    /***********************************************************
    ***********************************************************/
    private void setup_folders_helper (QSettings settings, AccountStatePtr account, string[] ignore_keys, bool backwards_compatible, bool folders_with_placeholders);

    /***********************************************************
    ***********************************************************/
    private void run_etag_jobs_if_possible (GLib.List<Folder> folder_map);

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 
    private GLib.Set<Folder> this.disabled_folders;
    private Folder.Map this.folder_map;
    private string this.folder_config_path;
    private Folder this.current_sync_folder = null;
    private QPointer<Folder> this.last_sync_folder;
    private bool this.sync_enabled = true;

    /// Folder aliases from the settings that weren't read
    private GLib.Set<string> this.additional_blocked_folder_aliases;

    /// Starts regular etag query jobs
    private QTimer this.etag_poll_timer;
    /// The currently running etag query
    private QPointer<RequestEtagJob> this.current_etag_job;

    /// Watches files that couldn't be synced due to locks
    private QScopedPointer<LockWatcher> this.lock_watcher;

    /// Occasionally schedules folders
    private QTimer this.time_scheduler;

    /// Scheduled folders that should be synced as soon as possible
    private QQueue<Folder> this.scheduled_folders;

    /// Picks the next scheduled folder and starts the sync
    private QTimer this.start_scheduled_sync_timer;

    /***********************************************************
    ***********************************************************/
    private QScopedPointer<SocketApi> this.socket_api;

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private 
    private static FolderMan this.instance;
    private FolderMan (GLib.Object parent = new GLib.Object ());
    private friend class Occ.Application;
    private friend class .TestFolderMan;
}

FolderMan *FolderMan.instance = null;

FolderMan.FolderMan (GLib.Object parent)
    : GLib.Object (parent)
    this.lock_watcher (new LockWatcher)
    this.navigation_pane_helper (this) {
    //  ASSERT (!this.instance);
    this.instance = this;

    this.socket_api.on_signal_reset (new SocketApi);

    ConfigFile config;
    std.chrono.milliseconds polltime = config.remote_poll_interval ();
    GLib.info ("setting remote poll timer interval to" + polltime.count ("msec";
    this.etag_poll_timer.interval (polltime.count ());
    GLib.Object.connect (&this.etag_poll_timer, &QTimer.timeout, this, &FolderMan.on_signal_etag_poll_timer_timeout);
    this.etag_poll_timer.on_signal_start ();

    this.start_scheduled_sync_timer.single_shot (true);
    connect (&this.start_scheduled_sync_timer, &QTimer.timeout,
        this, &FolderMan.on_signal_start_scheduled_folder_sync);

    this.time_scheduler.interval (5000);
    this.time_scheduler.single_shot (false);
    connect (&this.time_scheduler, &QTimer.timeout,
        this, &FolderMan.on_signal_schedule_folder_by_time);
    this.time_scheduler.on_signal_start ();

    connect (AccountManager.instance (), &AccountManager.remove_account_folders,
        this, &FolderMan.on_signal_remove_folders_for_account);

    connect (AccountManager.instance (), &AccountManager.account_sync_connection_removed,
        this, &FolderMan.on_signal_account_removed);

    connect (this.lock_watcher.data (), &LockWatcher.file_unlocked,
        this, &FolderMan.on_signal_watched_file_unlocked);

    connect (this, &FolderMan.folder_list_changed, this, &FolderMan.on_signal_setup_push_notifications);
}

FolderMan *FolderMan.instance () {
    return this.instance;
}

FolderMan.~FolderMan () {
    q_delete_all (this.folder_map);
    this.instance = null;
}

const Occ.Folder.Map &FolderMan.map () {
    return this.folder_map;
}

void FolderMan.unload_folder (Folder f) {
    if (!f) {
        return;
    }

    this.socket_api.on_signal_unregister_path (f.alias ());

    this.folder_map.remove (f.alias ());

    disconnect (f, &Folder.sync_started,
        this, &FolderMan.on_signal_folder_sync_started);
    disconnect (f, &Folder.sync_finished,
        this, &FolderMan.on_signal_folder_sync_finished);
    disconnect (f, &Folder.sync_state_change,
        this, &FolderMan.on_signal_forward_folder_sync_state_change);
    disconnect (f, &Folder.sync_paused_changed,
        this, &FolderMan.on_signal_folder_sync_paused);
    disconnect (&f.sync_engine ().sync_file_status_tracker (), &SyncFileStatusTracker.file_status_changed,
        this.socket_api.data (), &SocketApi.on_signal_broadcast_status_push_message);
    disconnect (f, &Folder.watched_file_changed_externally,
        f.sync_engine ().sync_file_status_tracker (), &SyncFileStatusTracker.on_signal_path_touched);
}

int FolderMan.unload_and_delete_all_folders () {
    int cnt = 0;

    // clear the list of existing folders.
    Folder.MapIterator i (this.folder_map);
    while (i.has_next ()) {
        i.next ();
        Folder f = i.value ();
        unload_folder (f);
        delete f;
        cnt++;
    }
    //  ASSERT (this.folder_map.is_empty ());

    this.last_sync_folder = null;
    this.current_sync_folder = null;
    this.scheduled_folders.clear ();
    /* emit */ folder_list_changed (this.folder_map);
    /* emit */ schedule_queue_changed ();

    return cnt;
}

void FolderMan.register_folder_with_socket_api (Folder folder) {
    if (!folder)
        return;
    if (!QDir (folder.path ()).exists ())
        return;

    // register the folder with the socket API
    if (folder.can_sync ())
        this.socket_api.on_signal_register_path (folder.alias ());
}

int FolderMan.setup_folders () {
    unload_and_delete_all_folders ();

    string[] skip_settings_keys;
    backward_migration_settings_keys (&skip_settings_keys, skip_settings_keys);

    var settings = ConfigFile.settings_with_group (QLatin1String ("Accounts"));
    const var accounts_with_settings = settings.child_groups ();
    if (accounts_with_settings.is_empty ()) {
        int r = setup_folders_migration ();
        if (r > 0) {
            AccountManager.instance ().save (false); // don't save credentials, they had not been loaded from keychain
        }
        return r;
    }

    GLib.info ("Setup folders from settings file";

    for (var account : AccountManager.instance ().accounts ()) {
        const var identifier = account.account ().identifier ();
        if (!accounts_with_settings.contains (identifier)) {
            continue;
        }
        settings.begin_group (identifier);

        // The "backwards_compatible" flag here is related to migrating old
        // database locations
        var process = [&] (string group_name, bool backwards_compatible, bool folders_with_placeholders) {
            settings.begin_group (group_name);
            if (skip_settings_keys.contains (settings.group ())) {
                // Should not happen : bad container keys should have been deleted
                GLib.warn ("Folder structure" + group_name + "is too new, ignoring";
            } else {
                setup_folders_helper (*settings, account, skip_settings_keys, backwards_compatible, folders_with_placeholders);
            }
            settings.end_group ();
        }

        process (QStringLiteral ("Folders"), true, false);

        // See Folder.save_to_settings for details about why these exists.
        process (QStringLiteral ("Multifolders"), false, false);
        process (QStringLiteral ("FoldersWithPlaceholders"), false, true);

        settings.end_group (); // <account>
    }

    /* emit */ folder_list_changed (this.folder_map);

    for (var folder : this.folder_map) {
        folder.process_switched_to_virtual_files ();
    }

    return this.folder_map.size ();
}

void FolderMan.setup_folders_helper (QSettings settings, AccountStatePtr account, string[] ignore_keys, bool backwards_compatible, bool folders_with_placeholders) {
    for (var folder_alias : settings.child_groups ()) {
        // Skip folders with too-new version
        settings.begin_group (folder_alias);
        if (ignore_keys.contains (settings.group ())) {
            GLib.info ("Folder" + folder_alias + "is too new, ignoring";
            this.additional_blocked_folder_aliases.insert (folder_alias);
            settings.end_group ();
            continue;
        }
        settings.end_group ();

        FolderDefinition folder_definition;
        settings.begin_group (folder_alias);
        if (FolderDefinition.on_signal_load (settings, folder_alias, folder_definition)) {
            var default_journal_path = folder_definition.default_journal_path (account.account ());

            // Migration : Old settings don't have journal_path
            if (folder_definition.journal_path.is_empty ()) {
                folder_definition.journal_path = default_journal_path;
            }

            // Migration #2 : journal_path might be absolute (in DataAppDir most likely) move it back to the root of local tree
            if (folder_definition.journal_path.at (0) != char ('.')) {
                GLib.File old_journal (folder_definition.journal_path);
                GLib.File old_journal_shm (folder_definition.journal_path + QStringLiteral ("-shm"));
                GLib.File old_journal_wal (folder_definition.journal_path + QStringLiteral ("-wal"));

                folder_definition.journal_path = default_journal_path;

                socket_api ().on_signal_unregister_path (folder_alias);
                var settings = account.settings ();

                var journal_file_move_success = true;
                // Due to database logic can't be sure which of these file exist.
                if (old_journal.exists ()) {
                    journal_file_move_success &= old_journal.rename (folder_definition.local_path + "/" + folder_definition.journal_path);
                }
                if (old_journal_shm.exists ()) {
                    journal_file_move_success &= old_journal_shm.rename (folder_definition.local_path + "/" + folder_definition.journal_path + QStringLiteral ("-shm"));
                }
                if (old_journal_wal.exists ()) {
                    journal_file_move_success &= old_journal_wal.rename (folder_definition.local_path + "/" + folder_definition.journal_path + QStringLiteral ("-wal"));
                }

                if (!journal_file_move_success) {
                    GLib.warn ("Wasn't able to move 3.0 syncjournal database files to new location. One-time loss off sync settings possible.";
                } else {
                    GLib.info ("Successfully migrated syncjournal database.";
                }

                var vfs = create_vfs_from_plugin (folder_definition.virtual_files_mode);
                if (!vfs && folder_definition.virtual_files_mode != Vfs.Off) {
                    GLib.warn ("Could not load plugin for mode" + folder_definition.virtual_files_mode;
                }

                Folder f = add_folder_internal (folder_definition, account.data (), std.move (vfs));
                f.save_to_settings ();

                continue;
            }

            // Migration : . files sometimes can't be created.
            // So if the configured journal_path has a dot-underscore (".sync_*.db")
            // but the current default doesn't have the underscore, switch to the
            // new default if no database exists yet.
            if (folder_definition.journal_path.starts_with (".sync_")
                && default_journal_path.starts_with (".sync_")
                && !GLib.File.exists (folder_definition.absolute_journal_path ())) {
                folder_definition.journal_path = default_journal_path;
            }

            // Migration : If an old database is found, move it to the new name.
            if (backwards_compatible) {
                SyncJournalDb.maybe_migrate_database (folder_definition.local_path, folder_definition.absolute_journal_path ());
            }

            const var switch_to_vfs = is_switch_to_vfs_needed (folder_definition);
            if (switch_to_vfs) {
                folder_definition.virtual_files_mode = best_available_vfs_mode ();
            }

            var vfs = create_vfs_from_plugin (folder_definition.virtual_files_mode);
            if (!vfs) {
                // TODO : Must do better error handling
                q_fatal ("Could not load plugin");
            }

            Folder f = add_folder_internal (std.move (folder_definition), account.data (), std.move (vfs));
            if (f) {
                if (switch_to_vfs) {
                    f.switch_to_virtual_files ();
                }
                // Migrate the old "use_placeholders" setting to the root folder pin state
                if (settings.value (QLatin1String (VERSION_C), 1).to_int () == 1
                    && settings.value (QLatin1String ("use_placeholders"), false).to_bool ()) {
                    GLib.info ("Migrate : From use_placeholders to PinState.VfsItemAvailability.ONLINE_ONLY";
                    f.root_pin_state (PinState.VfsItemAvailability.ONLINE_ONLY);
                }

                // Migration : Mark folders that shall be saved in a backwards-compatible way
                if (backwards_compatible)
                    f.save_backwards_compatible (true);
                if (folders_with_placeholders)
                    f.save_in_folders_with_placeholders ();

                schedule_folder (f);
                /* emit */ folder_sync_state_change (f);
            }
        }
        settings.end_group ();
    }
}

int FolderMan.setup_folders_migration () {
    ConfigFile config;
    QDir storage_dir (config.config_path ());
    this.folder_config_path = config.config_path () + QLatin1String ("folders");

    GLib.info ("Setup folders from " + this.folder_config_path + " (migration)";

    QDir dir (this.folder_config_path);
    //We need to include hidden files just in case the alias starts with '.'
    dir.filter (QDir.Files | QDir.Hidden);
    const var list = dir.entry_list ();

    // Normally there should be only one account when migrating.
    AccountState account_state = AccountManager.instance ().accounts ().value (0).data ();
    for (var alias : list) {
        Folder f = setup_folder_from_old_config_file (alias, account_state);
        if (f) {
            schedule_folder (f);
            /* emit */ folder_sync_state_change (f);
        }
    }

    /* emit */ folder_list_changed (this.folder_map);

    // return the number of valid folders.
    return this.folder_map.size ();
}

void FolderMan.backward_migration_settings_keys (string[] *delete_keys, string[] *ignore_keys) {
    var settings = ConfigFile.settings_with_group (QLatin1String ("Accounts"));

    var process_subgroup = [&] (string name) {
        settings.begin_group (name);
        const int folders_version = settings.value (QLatin1String (VERSION_C), 1).to_int ();
        if (folders_version <= max_folders_version) {
            foreach (var folder_alias, settings.child_groups ()) {
                settings.begin_group (folder_alias);
                const int folder_version = settings.value (QLatin1String (VERSION_C), 1).to_int ();
                if (folder_version > FolderDefinition.max_settings_version ()) {
                    ignore_keys.append (settings.group ());
                }
                settings.end_group ();
            }
        } else {
            delete_keys.append (settings.group ());
        }
        settings.end_group ();
    }

    for (var account_id : settings.child_groups ()) {
        settings.begin_group (account_id);
        process_subgroup ("Folders");
        process_subgroup ("Multifolders");
        process_subgroup ("FoldersWithPlaceholders");
        settings.end_group ();
    }
}

bool FolderMan.ensure_journal_gone (string journal_database_file) {
    // remove the old journal file
    while (GLib.File.exists (journal_database_file) && !GLib.File.remove (journal_database_file)) {
        GLib.warn ("Could not remove old database file at" + journal_database_file;
        int ret = QMessageBox.warning (null, _("Could not reset folder state"),
            _("An old sync journal \"%1\" was found, "
               "but could not be removed. Please make sure "
               "that no application is currently using it.")
                .arg (QDir.from_native_separators (QDir.clean_path (journal_database_file))),
            QMessageBox.Retry | QMessageBox.Abort);
        if (ret == QMessageBox.Abort) {
            return false;
        }
    }
    return true;
}

const int SLASH_TAG QLatin1String ("__SLASH__")
const int BSLASH_TAG QLatin1String ("__BSLASH__")
const int QMARK_TAG QLatin1String ("__QMARK__")
const int PERCENT_TAG QLatin1String ("__PERCENT__")
const int STAR_TAG QLatin1String ("__STAR__")
const int COLON_TAG QLatin1String ("__COLON__")
const int PIPE_TAG QLatin1String ("__PIPE__")
const int QUOTE_TAG QLatin1String ("__QUOTE__")
const int LT_TAG QLatin1String ("__LESS_THAN__")
const int GT_TAG QLatin1String ("__GREATER_THAN__")
const int PAR_O_TAG QLatin1String ("__PAR_OPEN__")
const int PAR_C_TAG QLatin1String ("__PAR_CLOSE__")

string FolderMan.escape_alias (string alias) {
    string a (alias);

    a.replace ('/', SLASH_TAG);
    a.replace ('\\', BSLASH_TAG);
    a.replace ('?', QMARK_TAG);
    a.replace ('%', PERCENT_TAG);
    a.replace ('*', STAR_TAG);
    a.replace (':', COLON_TAG);
    a.replace ('|', PIPE_TAG);
    a.replace ('"', QUOTE_TAG);
    a.replace ('<', LT_TAG);
    a.replace ('>', GT_TAG);
    a.replace ('[', PAR_O_TAG);
    a.replace (']', PAR_C_TAG);
    return a;
}

SocketApi *FolderMan.socket_api () {
    return this.socket_api.data ();
}

string FolderMan.unescape_alias (string alias) {
    string a (alias);

    a.replace (SLASH_TAG, QLatin1String ("/"));
    a.replace (BSLASH_TAG, QLatin1String ("\\"));
    a.replace (QMARK_TAG, QLatin1String ("?"));
    a.replace (PERCENT_TAG, QLatin1String ("%"));
    a.replace (STAR_TAG, QLatin1String ("*"));
    a.replace (COLON_TAG, QLatin1String (":"));
    a.replace (PIPE_TAG, QLatin1String ("|"));
    a.replace (QUOTE_TAG, QLatin1String ("\""));
    a.replace (LT_TAG, QLatin1String ("<"));
    a.replace (GT_TAG, QLatin1String (">"));
    a.replace (PAR_O_TAG, QLatin1String ("["));
    a.replace (PAR_C_TAG, QLatin1String ("]"));

    return a;
}

// filename is the name of the file only, it does not include
// the configuration directory path
// WARNING : Do not remove this code, it is used for predefined/automated deployments (2016)
Folder *FolderMan.setup_folder_from_old_config_file (string file, AccountState account_state) {
    Folder folder = null;

    GLib.info ("  ` . setting up:" + file;
    string escaped_alias (file);
    // check the unescaped variant (for the case when the filename comes out
    // of the directory listing). If the file does not exist, escape the
    // file and try again.
    QFileInfo cfg_file (this.folder_config_path, file);

    if (!cfg_file.exists ()) {
        // try the escaped variant.
        escaped_alias = escape_alias (file);
        cfg_file.file (this.folder_config_path, escaped_alias);
    }
    if (!cfg_file.is_readable ()) {
        GLib.warn ("Cannot read folder definition for alias " + cfg_file.file_path ();
        return folder;
    }

    QSettings settings = new QSettings (this.folder_config_path + '/' + escaped_alias, QSettings.IniFormat);
    GLib.info ("    . file path : " + settings.filename ();

    // Check if the filename is equal to the group setting. If not, use the group
    // name as an alias.
    string[] groups = settings.child_groups ();

    if (!groups.contains (escaped_alias) && groups.count () > 0) {
        escaped_alias = groups.first ();
    }

    settings.begin_group (escaped_alias); // read the group with the same name as the file which is the folder alias

    string path = settings.value (QLatin1String ("local_path")).to_string ();
    string backend = settings.value (QLatin1String ("backend")).to_string ();
    string target_path = settings.value (QLatin1String ("target_path")).to_string ();
    bool paused = settings.value (QLatin1String ("paused"), false).to_bool ();
    // string connection = settings.value ( QLatin1String ("connection") ).to_string ();
    string alias = unescape_alias (escaped_alias);

    if (backend.is_empty () || backend != QLatin1String ("owncloud")) {
        GLib.warn ("obsolete configuration of type" + backend;
        return null;
    }

    // cut off the leading slash, oc_url always has a trailing.
    if (target_path.starts_with ('/')) {
        target_path.remove (0, 1);
    }

    if (!account_state) {
        GLib.critical ("can't create folder without an account";
        return null;
    }

    FolderDefinition folder_definition;
    folder_definition.alias = alias;
    folder_definition.local_path = path;
    folder_definition.target_path = target_path;
    folder_definition.paused = paused;
    folder_definition.ignore_hidden_files = ignore_hidden_files ();

    folder = add_folder_internal (folder_definition, account_state, std.make_unique<VfsOff> ());
    if (folder) {
        string[] block_list = settings.value (QLatin1String ("block_list")).to_string_list ();
        if (!block_list.empty ()) {
            //migrate settings
            folder.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, block_list);
            settings.remove (QLatin1String ("block_list"));
            // FIXME : If you remove this codepath, you need to provide another way to do
            // this via theme.h or the normal FolderMan.setup_folders
        }

        folder.save_to_settings ();
    }
    GLib.info ("Migrated!" + folder;
    settings.sync ();
    return folder;
}

void FolderMan.on_signal_folder_sync_paused (Folder f, bool paused) {
    if (!f) {
        GLib.critical ("on_signal_folder_sync_paused called with empty folder";
        return;
    }

    if (!paused) {
        this.disabled_folders.remove (f);
        schedule_folder (f);
    } else {
        this.disabled_folders.insert (f);
    }
}

void FolderMan.on_signal_folder_can_sync_changed () {
    var f = qobject_cast<Folder> (sender ());
     //  ASSERT (f);
    if (f.can_sync ()) {
        this.socket_api.on_signal_register_path (f.alias ());
    } else {
        this.socket_api.on_signal_unregister_path (f.alias ());
    }
}

Folder *FolderMan.folder (string alias) {
    if (!alias.is_empty ()) {
        if (this.folder_map.contains (alias)) {
            return this.folder_map[alias];
        }
    }
    return null;
}

void FolderMan.schedule_all_folders () {
    for (Folder f : this.folder_map.values ()) {
        if (f && f.can_sync ()) {
            schedule_folder (f);
        }
    }
}

void FolderMan.on_signal_schedule_app_restart () {
    this.app_restart_required = true;
    GLib.info ("Application restart requested!";
}

void FolderMan.on_signal_sync_once_file_unlocks (string path) {
    this.lock_watcher.add_file (path);
}

/***********************************************************
if a folder wants to be synced, it calls this slot and is added
to the queue. The slot to actually on_signal_start a sync is called afterwards.
***********************************************************/
void FolderMan.schedule_folder (Folder f) {
    if (!f) {
        GLib.critical ("on_signal_schedule_sync called with null folder";
        return;
    }
    var alias = f.alias ();

    GLib.info ("Schedule folder " + alias + " to sync!";

    if (!this.scheduled_folders.contains (f)) {
        if (!f.can_sync ()) {
            GLib.info ("Folder is not ready to sync, not scheduled!";
            this.socket_api.on_signal_update_folder_view (f);
            return;
        }
        f.prepare_to_sync ();
        /* emit */ folder_sync_state_change (f);
        this.scheduled_folders.enqueue (f);
        /* emit */ schedule_queue_changed ();
    } else {
        GLib.info ("Sync for folder " + alias + " already scheduled, do not enqueue!";
    }

    start_scheduled_sync_soon ();
}

void FolderMan.schedule_folder_next (Folder f) {
    var alias = f.alias ();
    GLib.info ("Schedule folder " + alias + " to sync! Front-of-queue.";

    if (!f.can_sync ()) {
        GLib.info ("Folder is not ready to sync, not scheduled!";
        return;
    }

    this.scheduled_folders.remove_all (f);

    f.prepare_to_sync ();
    /* emit */ folder_sync_state_change (f);
    this.scheduled_folders.prepend (f);
    /* emit */ schedule_queue_changed ();

    start_scheduled_sync_soon ();
}

void FolderMan.on_signal_schedule_e_tag_job (string  /*alias*/, RequestEtagJob job) {
    GLib.Object.connect (job, &GLib.Object.destroyed, this, &FolderMan.on_signal_etag_job_destroyed);
    QMetaObject.invoke_method (this, "on_signal_run_one_etag_job", Qt.QueuedConnection);
    // maybe : add to queue
}

void FolderMan.on_signal_etag_job_destroyed (GLib.Object * /*o*/) {
    // this.current_etag_job is automatically cleared
    // maybe : remove from queue
    QMetaObject.invoke_method (this, "on_signal_run_one_etag_job", Qt.QueuedConnection);
}

void FolderMan.on_signal_run_one_etag_job () {
    if (this.current_etag_job.is_null ()) {
        Folder folder = null;
        for (Folder f : q_as_const (this.folder_map)) {
            if (f.etag_job ()) {
                // Caveat: always grabs the first folder with a job, but we think this is Ok for now and avoids us having a seperate queue.
                this.current_etag_job = f.etag_job ();
                folder = f;
                break;
            }
        }
        if (this.current_etag_job.is_null ()) {
            //GLib.debug ("No more remote ETag check jobs to schedule.";

            // now it might be a good time to check for restarting...
            if (!is_any_sync_running () && this.app_restart_required) {
                restart_application ();
            }
        } else {
            GLib.debug ("Scheduling" + folder.remote_url ().to_string ("to check remote ETag";
            this.current_etag_job.on_signal_start (); // on destroy/end it will continue the queue via on_signal_etag_job_destroyed
        }
    }
}

void FolderMan.on_signal_account_state_changed () {
    var account_state = qobject_cast<AccountState> (sender ());
    if (!account_state) {
        return;
    }
    string account_name = account_state.account ().display_name ();

    if (account_state.is_connected ()) {
        GLib.info ("Account" + account_name + "connected, scheduling its folders";

        for (Folder f : this.folder_map.values ()) {
            if (f
                && f.can_sync ()
                && f.account_state () == account_state) {
                schedule_folder (f);
            }
        }
    } else {
        GLib.info ("Account" + account_name + "disconnected or paused, "
                                                           "terminating or descheduling sync folders";

        foreach (Folder f, this.folder_map.values ()) {
            if (f
                && f.is_sync_running ()
                && f.account_state () == account_state) {
                f.on_signal_terminate_sync ();
            }
        }

        QMutableListIterator<Folder> it (this.scheduled_folders);
        while (it.has_next ()) {
            Folder f = it.next ();
            if (f.account_state () == account_state) {
                it.remove ();
            }
        }
        /* emit */ schedule_queue_changed ();
    }
}

// only enable or disable foldermans will schedule and do syncs.
// this is not the same as Pause and Resume of folders.
void FolderMan.sync_enabled (bool enabled) {
    if (!this.sync_enabled && enabled && !this.scheduled_folders.is_empty ()) {
        // We have things in our queue that were waiting for the connection to come back on.
        start_scheduled_sync_soon ();
    }
    this.sync_enabled = enabled;
    // force a redraw in case the network connect status changed
    /* emit */ (folder_sync_state_change (null));
}

void FolderMan.start_scheduled_sync_soon () {
    if (this.start_scheduled_sync_timer.is_active ()) {
        return;
    }
    if (this.scheduled_folders.empty ()) {
        return;
    }
    if (is_any_sync_running ()) {
        return;
    }

    int64 ms_delay = 100; // 100ms minimum delay
    int64 ms_since_last_sync = 0;

    // Require a pause based on the duration of the last sync run.
    if (Folder last_folder = this.last_sync_folder) {
        ms_since_last_sync = last_folder.msec_since_last_sync ().count ();

        //  1s   . 1.5s pause
        // 10s   . 5s pause
        //  1min . 12s pause
        //  1h   . 90s pause
        int64 pause = q_sqrt (last_folder.msec_last_sync_duration ().count ()) / 20.0 * 1000.0;
        ms_delay = q_max (ms_delay, pause);
    }

    // Delays beyond one minute seem too big, particularly since there
    // could be things later in the queue that shouldn't be punished by a
    // long delay!
    ms_delay = q_min (ms_delay, 60 * 1000ll);

    // Time since the last sync run counts against the delay
    ms_delay = q_max (1ll, ms_delay - ms_since_last_sync);

    GLib.info ("Starting the next scheduled sync in" + (ms_delay / 1000) + "seconds";
    this.start_scheduled_sync_timer.on_signal_start (ms_delay);
}

/***********************************************************
slot to on_signal_start folder syncs.
It is either called from the slot where folders enqueue themselves for
syncing or after a folder sync was on_signal_finished.
***********************************************************/
void FolderMan.on_signal_start_scheduled_folder_sync () {
    if (is_any_sync_running ()) {
        for (var f : this.folder_map) {
            if (f.is_sync_running ())
                GLib.info ("Currently folder " + f.remote_url ().to_string (" is running, wait for finish!";
        }
        return;
    }

    if (!this.sync_enabled) {
        GLib.info ("FolderMan : Syncing is disabled, no scheduling.";
        return;
    }

    GLib.debug ("folder_queue size : " + this.scheduled_folders.count ();
    if (this.scheduled_folders.is_empty ()) {
        return;
    }

    // Find the first folder in the queue that can be synced.
    Folder folder = null;
    while (!this.scheduled_folders.is_empty ()) {
        Folder g = this.scheduled_folders.dequeue ();
        if (g.can_sync ()) {
            folder = g;
            break;
        }
    }

    /* emit */ schedule_queue_changed ();

    // Start syncing this folder!
    if (folder) {
        // Safe to call several times, and necessary to try again if
        // the folder path didn't exist previously.
        folder.register_folder_watcher ();
        register_folder_with_socket_api (folder);

        this.current_sync_folder = folder;
        folder.on_signal_start_sync (string[] ());
    }
}

bool FolderMan.push_notifications_files_ready (Account account) {
    const var push_notifications = account.push_notifications ();
    const var push_files_available = account.capabilities ().available_push_notifications () & PushNotificationType.FILES;

    return push_files_available && push_notifications && push_notifications.is_ready ();
}

bool FolderMan.is_switch_to_vfs_needed (FolderDefinition folder_definition) {
    var result = false;
    if (ENFORCE_VIRTUAL_FILES_SYNC_FOLDER &&
            folder_definition.virtual_files_mode != best_available_vfs_mode () &&
            folder_definition.virtual_files_mode == Vfs.Off &&
            Occ.Theme.instance ().show_virtual_files_option ()) {
        result = true;
    }

    return result;
}

void FolderMan.on_signal_etag_poll_timer_timeout () {
    GLib.info ("Etag poll timer timeout";

    const var folder_map_values = this.folder_map.values ();

    GLib.info ("Folders to sync:" + folder_map_values.size ();

    GLib.List<Folder> folders_to_run;

    // Some folders need not to be checked because they use the push notifications
    std.copy_if (folder_map_values.begin (), folder_map_values.end (), std.back_inserter (folders_to_run), [this] (Folder folder) . bool {
        const var account = folder.account_state ().account ();
        return !push_notifications_files_ready (account.data ());
    });

    GLib.info ("Number of folders that don't use push notifications:" + folders_to_run.size ();

    run_etag_jobs_if_possible (folders_to_run);
}

void FolderMan.run_etag_jobs_if_possible (GLib.List<Folder> folder_map) {
    for (var folder : folder_map) {
        run_etag_job_if_possible (folder);
    }
}

void FolderMan.run_etag_job_if_possible (Folder folder) {
    const ConfigFile config;
    const var polltime = config.remote_poll_interval ();

    GLib.info ("Run etag job on folder" + folder;

    if (!folder) {
        return;
    }
    if (folder.is_sync_running ()) {
        GLib.info ("Can not run etag job : Sync is running";
        return;
    }
    if (this.scheduled_folders.contains (folder)) {
        GLib.info ("Can not run etag job : Folder is alreday scheduled";
        return;
    }
    if (this.disabled_folders.contains (folder)) {
        GLib.info ("Can not run etag job : Folder is disabled";
        return;
    }
    if (folder.etag_job () || folder.is_busy () || !folder.can_sync ()) {
        GLib.info ("Can not run etag job : Folder is busy";
        return;
    }
    // When not using push notifications, make sure polltime is reached
    if (!push_notifications_files_ready (folder.account_state ().account ().data ())) {
        if (folder.msec_since_last_sync () < polltime) {
            GLib.info ("Can not run etag job : Polltime not reached";
            return;
        }
    }

    QMetaObject.invoke_method (folder, "on_signal_run_etag_job", Qt.QueuedConnection);
}

void FolderMan.on_signal_account_removed (AccountState account_state) {
    for (var folder : q_as_const (this.folder_map)) {
        if (folder.account_state () == account_state) {
            folder.on_signal_associated_account_removed ();
        }
    }
}

void FolderMan.on_signal_remove_folders_for_account (AccountState account_state) {
    QVarLengthArray<Folder *, 16> folders_to_remove;
    Folder.MapIterator i (this.folder_map);
    while (i.has_next ()) {
        i.next ();
        Folder folder = i.value ();
        if (folder.account_state () == account_state) {
            folders_to_remove.append (folder);
        }
    }

    for (var f : q_as_const (folders_to_remove)) {
        remove_folder (f);
    }
    /* emit */ folder_list_changed (this.folder_map);
}

void FolderMan.on_signal_forward_folder_sync_state_change () {
    if (var f = qobject_cast<Folder> (sender ())) {
        /* emit */ folder_sync_state_change (f);
    }
}

void FolderMan.on_signal_server_version_changed (Account account) {
    // Pause folders if the server version is unsupported
    if (account.server_version_unsupported ()) {
        GLib.warn ("The server version is unsupported:" + account.server_version ()
                               + "pausing all folders on the account";

        for (var f : q_as_const (this.folder_map)) {
            if (f.account_state ().account ().data () == account) {
                f.sync_paused (true);
            }
        }
    }
}

void FolderMan.on_signal_watched_file_unlocked (string path) {
    if (Folder f = folder_for_path (path)) {
        // Treat this equivalently to the file being reported by the file watcher
        f.on_signal_watched_path_changed (path, Folder.ChangeReason.UnLock);
    }
}

void FolderMan.on_signal_schedule_folder_by_time () {
    for (var f : q_as_const (this.folder_map)) {
        // Never schedule if syncing is disabled or when we're currently
        // querying the server for etags
        if (!f.can_sync () || f.etag_job ()) {
            continue;
        }

        var msecs_since_sync = f.msec_since_last_sync ();

        // Possibly it's just time for a new sync run
        bool force_sync_interval_expired = msecs_since_sync > ConfigFile ().force_sync_interval ();
        if (force_sync_interval_expired) {
            GLib.info ("Scheduling folder" + f.alias ()
                                + "because it has been" + msecs_since_sync.count ("ms "
                                + "since the last sync";

            schedule_folder (f);
            continue;
        }

        // Retry a couple of times after failure; or regularly if requested
        bool sync_again =
            (f.consecutive_failing_syncs () > 0 && f.consecutive_failing_syncs () < 3)
            || f.sync_engine ().is_another_sync_needed () == AnotherSyncNeeded.DELAYED_FOLLOW_UP;
        var sync_again_delay = std.chrono.seconds (10); // 10s for the first retry-after-fail
        if (f.consecutive_failing_syncs () > 1)
            sync_again_delay = std.chrono.seconds (60); // 60s for each further attempt
        if (sync_again && msecs_since_sync > sync_again_delay) {
            GLib.info ("Scheduling folder" + f.alias ()
                                + ", the last" + f.consecutive_failing_syncs ("syncs failed"
                                + ", another_sync_needed" + f.sync_engine ().is_another_sync_needed ()
                                + ", last status:" + f.sync_result ().status_string ()
                                + ", time since last sync:" + msecs_since_sync.count ();

            schedule_folder (f);
            continue;
        }

        // Do we want to retry failing syncs or another-sync-needed runs more often?
    }
}

bool FolderMan.is_any_sync_running () {
    if (this.current_sync_folder)
        return true;

    for (var f : this.folder_map) {
        if (f.is_sync_running ())
            return true;
    }
    return false;
}

void FolderMan.on_signal_folder_sync_started () {
    var f = qobject_cast<Folder> (sender ());
    //  ASSERT (f);
    if (!f)
        return;

    GLib.info (lc_folder_man, ">========== Sync started for folder [%s] of account [%s] with remote [%s]",
        q_printable (f.short_gui_local_path ()),
        q_printable (f.account_state ().account ().display_name ()),
        q_printable (f.remote_url ().to_string ()));
}

/***********************************************************
a folder indicates that its syncing is on_signal_finished.
Start the next sync after the system had some milliseconds to breath.
This delay is particularly useful to avoid late file change notifications
(that we caused ourselves by syncing) from triggering another spurious sync.
***********************************************************/
void FolderMan.on_signal_folder_sync_finished (SyncResult &) {
    var f = qobject_cast<Folder> (sender ());
    //  ASSERT (f);
    if (!f)
        return;

    GLib.info (lc_folder_man, "<========== Sync on_signal_finished for folder [%s] of account [%s] with remote [%s]",
        q_printable (f.short_gui_local_path ()),
        q_printable (f.account_state ().account ().display_name ()),
        q_printable (f.remote_url ().to_string ()));

    if (f == this.current_sync_folder) {
        this.last_sync_folder = this.current_sync_folder;
        this.current_sync_folder = null;
    }
    if (!is_any_sync_running ())
        start_scheduled_sync_soon ();
}

Folder *FolderMan.add_folder (AccountState account_state, FolderDefinition folder_definition) {
    // Choose a database filename
    var definition = folder_definition;
    definition.journal_path = definition.default_journal_path (account_state.account ());

    if (!ensure_journal_gone (definition.absolute_journal_path ())) {
        return null;
    }

    var vfs = create_vfs_from_plugin (folder_definition.virtual_files_mode);
    if (!vfs) {
        GLib.warn ("Could not load plugin for mode" + folder_definition.virtual_files_mode;
        return null;
    }

    var folder = add_folder_internal (definition, account_state, std.move (vfs));

    // Migration : The first account that's configured for a local folder shall
    // be saved in a backwards-compatible way.
    const var folder_list = FolderMan.instance ().map ();
    const var one_account_only = std.none_of (folder_list.cbegin (), folder_list.cend (), [folder] (var other) {
        return other != folder && other.clean_path () == folder.clean_path ();
    });

    folder.save_backwards_compatible (one_account_only);

    if (folder) {
        folder.save_backwards_compatible (one_account_only);
        folder.save_to_settings ();
        /* emit */ folder_sync_state_change (folder);
        /* emit */ folder_list_changed (this.folder_map);
    }

    this.navigation_pane_helper.schedule_update_cloud_storage_registry ();
    return folder;
}

Folder *FolderMan.add_folder_internal (
    FolderDefinition folder_definition,
    AccountState account_state,
    std.unique_ptr<Vfs> vfs) {
    var alias = folder_definition.alias;
    int count = 0;
    while (folder_definition.alias.is_empty ()
        || this.folder_map.contains (folder_definition.alias)
        || this.additional_blocked_folder_aliases.contains (folder_definition.alias)) {
        // There is already a folder configured with this name and folder names need to be unique
        folder_definition.alias = alias + string.number (++count);
    }

    var folder = new Folder (folder_definition, account_state, std.move (vfs), this);

    if (this.navigation_pane_helper.show_in_explorer_navigation_pane () && folder_definition.navigation_pane_clsid.is_null ()) {
        folder.navigation_pane_clsid (QUuid.create_uuid ());
        folder.save_to_settings ();
    }

    GLib.info ("Adding folder to Folder Map " + folder + folder.alias ();
    this.folder_map[folder.alias ()] = folder;
    if (folder.sync_paused ()) {
        this.disabled_folders.insert (folder);
    }

    // See matching disconnects in unload_folder ().
    connect (folder, &Folder.sync_started, this, &FolderMan.on_signal_folder_sync_started);
    connect (folder, &Folder.sync_finished, this, &FolderMan.on_signal_folder_sync_finished);
    connect (folder, &Folder.sync_state_change, this, &FolderMan.on_signal_forward_folder_sync_state_change);
    connect (folder, &Folder.sync_paused_changed, this, &FolderMan.on_signal_folder_sync_paused);
    connect (folder, &Folder.can_sync_changed, this, &FolderMan.on_signal_folder_can_sync_changed);
    connect (&folder.sync_engine ().sync_file_status_tracker (), &SyncFileStatusTracker.file_status_changed,
        this.socket_api.data (), &SocketApi.on_signal_broadcast_status_push_message);
    connect (folder, &Folder.watched_file_changed_externally,
        folder.sync_engine ().sync_file_status_tracker (), &SyncFileStatusTracker.on_signal_path_touched);

    folder.register_folder_watcher ();
    register_folder_with_socket_api (folder);
    return folder;
}

Folder *FolderMan.folder_for_path (string path) {
    string absolute_path = QDir.clean_path (path) + '/';

    const var folders = this.map ().values ();
    const var it = std.find_if (folders.cbegin (), folders.cend (), [absolute_path] (var folder) {
        const string folder_path = folder.clean_path () + '/';
        return absolute_path.starts_with (folder_path, (Utility.is_windows () || Utility.is_mac ()) ? Qt.CaseInsensitive : Qt.CaseSensitive);
    });

    return it != folders.cend () ? *it : null;
}

string[] FolderMan.find_file_in_local_folders (string rel_path, AccountPointer acc) {
    string[] re;

    // We'll be comparing against Folder.remote_path which always starts with /
    string server_path = rel_path;
    if (!server_path.starts_with ('/'))
        server_path.prepend ('/');

    for (Folder folder : this.map ().values ()) {
        if (acc && folder.account_state ().account () != acc) {
            continue;
        }
        if (!server_path.starts_with (folder.remote_path ()))
            continue;

        string path = folder.clean_path () + '/';
        path += server_path.mid_ref (folder.remote_path_trailing_slash ().length ());
        if (GLib.File.exists (path)) {
            re.append (path);
        }
    }
    return re;
}

void FolderMan.remove_folder (Folder f) {
    if (!f) {
        GLib.critical ("Can not remove null folder";
        return;
    }

    GLib.info ("Removing " + f.alias ();

    const bool currently_running = f.is_sync_running ();
    if (currently_running) {
        // on_signal_abort the sync now
        f.on_signal_terminate_sync ();
    }

    if (this.scheduled_folders.remove_all (f) > 0) {
        /* emit */ schedule_queue_changed ();
    }

    f.sync_paused (true);
    f.wipe_for_removal ();

    // remove the folder configuration
    f.remove_from_settings ();

    unload_folder (f);
    if (currently_running) {
        // We want to schedule the next folder once this is done
        connect (f, &Folder.sync_finished,
            this, &FolderMan.on_signal_folder_sync_finished);
        // Let the folder delete itself when done.
        connect (f, &Folder.sync_finished, f, &GLib.Object.delete_later);
    } else {
        delete f;
    }

    this.navigation_pane_helper.schedule_update_cloud_storage_registry ();

    /* emit */ folder_list_changed (this.folder_map);
}

string FolderMan.get_backup_name (string full_path_name) {
    if (full_path_name.ends_with ("/"))
        full_path_name.chop (1);

    if (full_path_name.is_empty ())
        return "";

    string new_name = full_path_name + _(" (backup)");
    QFileInfo fi (new_name);
    int cnt = 2;
    do {
        if (fi.exists ()) {
            new_name = full_path_name + _(" (backup %1)").arg (cnt++);
            fi.file (new_name);
        }
    } while (fi.exists ());

    return new_name;
}

bool FolderMan.start_from_scratch (string local_folder) {
    if (local_folder.is_empty ()) {
        return false;
    }

    QFileInfo fi (local_folder);
    QDir parent_dir (fi.dir ());
    string folder_name = fi.filename ();

    // Adjust for case where local_folder ends with a /
    if (fi.is_dir ()) {
        folder_name = parent_dir.dir_name ();
        parent_dir.cd_up ();
    }

    if (fi.exists ()) {
        // It exists, but is empty . just reuse it.
        if (fi.is_dir () && fi.dir ().count () == 0) {
            GLib.debug ("start_from_scratch : Directory is empty!";
            return true;
        }
        // Disconnect the socket api from the database to avoid that locking of the
        // database file does not allow to move this dir.
        Folder f = folder_for_path (local_folder);
        if (f) {
            if (local_folder.starts_with (f.path ())) {
                this.socket_api.on_signal_unregister_path (f.alias ());
            }
            f.journal_database ().close ();
            f.on_signal_terminate_sync (); // Normally it should not be running, but viel hilft viel
        }

        // Make a backup of the folder/file.
        string new_name = get_backup_name (parent_dir.absolute_file_path (folder_name));
        string rename_error;
        if (!FileSystem.rename (fi.absolute_file_path (), new_name, rename_error)) {
            GLib.warn ("start_from_scratch : Could not rename" + fi.absolute_file_path ()
                                   + "to" + new_name + "error:" + rename_error;
            return false;
        }
    }

    if (!parent_dir.mkdir (fi.absolute_file_path ())) {
        GLib.warn ("start_from_scratch : Could not mkdir" + fi.absolute_file_path ();
        return false;
    }

    return true;
}

void FolderMan.on_signal_wipe_folder_for_account (AccountState account_state) {
    QVarLengthArray<Folder *, 16> folders_to_remove;
    Folder.MapIterator i (this.folder_map);
    while (i.has_next ()) {
        i.next ();
        Folder folder = i.value ();
        if (folder.account_state () == account_state) {
            folders_to_remove.append (folder);
        }
    }

    bool on_signal_success = false;
    for (var f : q_as_const (folders_to_remove)) {
        if (!f) {
            GLib.critical ("Can not remove null folder";
            return;
        }

        GLib.info ("Removing " + f.alias ();

        const bool currently_running = (this.current_sync_folder == f);
        if (currently_running) {
            // on_signal_abort the sync now
            this.current_sync_folder.on_signal_terminate_sync ();
        }

        if (this.scheduled_folders.remove_all (f) > 0) {
            /* emit */ schedule_queue_changed ();
        }

        // wipe database
        f.wipe_for_removal ();

        // wipe data
        QDir user_folder (f.path ());
        if (user_folder.exists ()) {
            on_signal_success = user_folder.remove_recursively ();
            if (!on_signal_success) {
                GLib.warn ("Failed to remove existing folder " + f.path ();
            } else {
                GLib.info ("wipe : Removed  file " + f.path ();
            }

        } else {
            on_signal_success = true;
            GLib.warn ("folder does not exist, can not remove.";
        }

        f.sync_paused (true);

        // remove the folder configuration
        f.remove_from_settings ();

        unload_folder (f);
        if (currently_running) {
            delete f;
        }

        this.navigation_pane_helper.schedule_update_cloud_storage_registry ();
    }

    /* emit */ folder_list_changed (this.folder_map);
    /* emit */ wipe_done (account_state, on_signal_success);
}

void FolderMan.dirty_proxy () {
    for (Folder f : this.folder_map.values ()) {
        if (f) {
            if (f.account_state () && f.account_state ().account ()
                && f.account_state ().account ().network_access_manager ()) {
                // Need to do this so we do not use the old determined system proxy
                f.account_state ().account ().network_access_manager ().proxy (
                    QNetworkProxy (QNetworkProxy.DefaultProxy));
            }
        }
    }
}

void FolderMan.dirty_network_limits () {
    for (Folder f : this.folder_map.values ()) {
        // set only in busy folders. Otherwise they read the config anyway.
        if (f && f.is_busy ()) {
            f.dirty_network_limits ();
        }
    }
}

void FolderMan.tray_overall_status (GLib.List<Folder> folders,
    SyncResult.Status status, bool unresolved_conflicts) {
    *status = SyncResult.Status.UNDEFINED;
    *unresolved_conflicts = false;

    int cnt = folders.count ();

    // if one folder : show the state of the one folder.
    // if more folders:
    // if one of them has an error . show error
    // if one is paused, but others ok, show ok
    // do not show "problem" in the tray
    //
    if (cnt == 1) {
        Folder folder = folders.at (0);
        if (folder) {
            var sync_result = folder.sync_result ();
            if (folder.sync_paused ()) {
                *status = SyncResult.Status.PAUSED;
            } else {
                SyncResult.Status sync_status = sync_result.status ();
                switch (sync_status) {
                case SyncResult.Status.UNDEFINED:
                    *status = SyncResult.Status.ERROR;
                    break;
                case SyncResult.Status.PROBLEM : // don't show the problem icon in tray.
                    *status = SyncResult.Status.SUCCESS;
                    break;
                default:
                    *status = sync_status;
                    break;
                }
            }
            *unresolved_conflicts = sync_result.has_unresolved_conflicts ();
        }
    } else {
        int errors_seen = 0;
        int good_seen = 0;
        int abort_or_paused_seen = 0;
        int run_seen = 0;
        int various = 0;

        for (Folder folder : q_as_const (folders)) {
            SyncResult folder_result = folder.sync_result ();
            if (folder.sync_paused ()) {
                abort_or_paused_seen++;
            } else {
                SyncResult.Status sync_status = folder_result.status ();

                switch (sync_status) {
                case SyncResult.Status.UNDEFINED:
                case SyncResult.Status.NOT_YET_STARTED:
                    various++;
                    break;
                case SyncResult.Status.SYNC_PREPARE:
                case SyncResult.Status.SYNC_RUNNING:
                    run_seen++;
                    break;
                case SyncResult.Status.PROBLEM : // don't show the problem icon in tray.
                case SyncResult.Status.SUCCESS:
                    good_seen++;
                    break;
                case SyncResult.Status.ERROR:
                case SyncResult.Status.SETUP_ERROR:
                    errors_seen++;
                    break;
                case SyncResult.Status.SYNC_ABORT_REQUESTED:
                case SyncResult.Status.PAUSED:
                    abort_or_paused_seen++;
                    // no default case on purpose, check compiler warnings
                }
            }
            if (folder_result.has_unresolved_conflicts ())
                *unresolved_conflicts = true;
        }
        if (errors_seen > 0) {
            *status = SyncResult.Status.ERROR;
        } else if (abort_or_paused_seen > 0 && abort_or_paused_seen == cnt) {
            // only if all folders are paused
            *status = SyncResult.Status.PAUSED;
        } else if (run_seen > 0) {
            *status = SyncResult.Status.SYNC_RUNNING;
        } else if (good_seen > 0) {
            *status = SyncResult.Status.SUCCESS;
        }
    }
}

string FolderMan.tray_tooltip_status_string (
    SyncResult.Status sync_status, bool has_unresolved_conflicts, bool paused) {
    string folder_message;
    switch (sync_status) {
    case SyncResult.Status.UNDEFINED:
        folder_message = _("Undefined State.");
        break;
    case SyncResult.Status.NOT_YET_STARTED:
        folder_message = _("Waiting to on_signal_start syncing.");
        break;
    case SyncResult.Status.SYNC_PREPARE:
        folder_message = _("Preparing for sync.");
        break;
    case SyncResult.Status.SYNC_RUNNING:
        folder_message = _("Sync is running.");
        break;
    case SyncResult.Status.SUCCESS:
    case SyncResult.Status.PROBLEM:
        if (has_unresolved_conflicts) {
            folder_message = _("Sync on_signal_finished with unresolved conflicts.");
        } else {
            folder_message = _("Last Sync was successful.");
        }
        break;
    case SyncResult.Status.ERROR:
        break;
    case SyncResult.Status.SETUP_ERROR:
        folder_message = _("Setup Error.");
        break;
    case SyncResult.Status.SYNC_ABORT_REQUESTED:
        folder_message = _("User Abort.");
        break;
    case SyncResult.Status.PAUSED:
        folder_message = _("Sync is paused.");
        break;
        // no default case on purpose, check compiler warnings
    }
    if (paused) {
        // sync is disabled.
        folder_message = _("%1 (Sync is paused)").arg (folder_message);
    }
    return folder_message;
}

static string check_path_validity_recursive (string path) {
    if (path.is_empty ()) {
        return FolderMan._("No valid folder selected!");
    }

    const QFileInfo sel_file (path);

    if (!sel_file.exists ()) {
        string parent_path = sel_file.dir ().path ();
        if (parent_path != path)
            return check_path_validity_recursive (parent_path);
        return FolderMan._("The selected path does not exist!");
    }

    if (!sel_file.is_dir ()) {
        return FolderMan._("The selected path is not a folder!");
    }

    if (!sel_file.is_writable ()) {
        return FolderMan._("You have no permission to write to the selected folder!");
    }
    return "";
}

// QFileInfo.canonical_path returns an empty string if the file does not exist.
// This function also works with files that does not exist and resolve the symlinks in the
// parent directories.
static string canonical_path (string path) {
    QFileInfo sel_file (path);
    if (!sel_file.exists ()) {
        const var parent_path = sel_file.dir ().path ();

        // It's possible for the parent_path to match the path
        // (possibly we've arrived at a non-existant drive root on Windows)
        // and recursing would be fatal.
        if (parent_path == path) {
            return path;
        }

        return canonical_path (parent_path) + '/' + sel_file.filename ();
    }
    return sel_file.canonical_file_path ();
}

string FolderMan.check_path_validity_for_new_folder (string path, GLib.Uri server_url) {
    string recursive_validity = check_path_validity_recursive (path);
    if (!recursive_validity.is_empty ()) {
        GLib.debug () + path + recursive_validity;
        return recursive_validity;
    }

    // check if the local directory isn't used yet in another own_cloud sync
    Qt.Case_sensitivity cs = Qt.CaseSensitive;
    if (Utility.fs_case_preserving ()) {
        cs = Qt.CaseInsensitive;
    }

    const string user_dir = QDir.clean_path (canonical_path (path)) + '/';
    for (var i = this.folder_map.const_begin (); i != this.folder_map.const_end (); ++i) {
        var f = static_cast<Folder> (i.value ());
        string folder_dir = QDir.clean_path (canonical_path (f.path ())) + '/';

        bool different_paths = string.compare (folder_dir, user_dir, cs) != 0;
        if (different_paths && folder_dir.starts_with (user_dir, cs)) {
            return _("The local folder %1 already contains a folder used in a folder sync connection. "
                      "Please pick another one!")
                .arg (QDir.to_native_separators (path));
        }

        if (different_paths && user_dir.starts_with (folder_dir, cs)) {
            return _("The local folder %1 is already contained in a folder used in a folder sync connection. "
                      "Please pick another one!")
                .arg (QDir.to_native_separators (path));
        }

        // if both pathes are equal, the server url needs to be different
        // otherwise it would mean that a new connection from the same local folder
        // to the same account is added which is not wanted. The account must differ.
        if (server_url.is_valid () && !different_paths) {
            GLib.Uri folder_url = f.account_state ().account ().url ();
            string user = f.account_state ().account ().credentials ().user ();
            folder_url.user_name (user);

            if (server_url == folder_url) {
                return _("There is already a sync from the server to this local folder. "
                          "Please pick another local folder!");
            }
        }
    }

    return "";
}

string FolderMan.find_good_path_for_new_sync_folder (string base_path, GLib.Uri server_url) {
    string folder = base_path;

    // If the parent folder is a sync folder or contained in one, we can't
    // possibly find a valid sync folder inside it.
    // Example: Someone syncs their home directory. Then ~/foobar is not
    // going to be an acceptable sync folder path for any value of foobar.
    string parent_folder = QFileInfo (folder).dir ().canonical_path ();
    if (FolderMan.instance ().folder_for_path (parent_folder)) {
        // Any path with that parent is going to be unacceptable,
        // so just keep it as-is.
        return base_path;
    }

    int attempt = 1;
    while (true) {
        const bool is_good =
            !QFileInfo (folder).exists ()
            && FolderMan.instance ().check_path_validity_for_new_folder (folder, server_url).is_empty ();
        if (is_good) {
            break;
        }

        // Count attempts and give up eventually
        attempt++;
        if (attempt > 100) {
            return base_path;
        }

        folder = base_path + string.number (attempt);
    }

    return folder;
}

bool FolderMan.ignore_hidden_files () {
    if (this.folder_map.empty ()) {
        // Currently no folders in the manager . return default
        return false;
    }
    // Since the hidden_files settings is the same for all folders, just return the settings of the first folder
    return this.folder_map.begin ().value ().ignore_hidden_files ();
}

void FolderMan.ignore_hidden_files (bool ignore) {
    // Note that the setting will revert to 'true' if all folders
    // are deleted...
    for (Folder folder : q_as_const (this.folder_map)) {
        folder.ignore_hidden_files (ignore);
        folder.save_to_settings ();
    }
}

QQueue<Folder> FolderMan.schedule_queue () {
    return this.scheduled_folders;
}

Folder *FolderMan.current_sync_folder () {
    return this.current_sync_folder;
}

void FolderMan.restart_application () {
    if (Utility.is_linux ()) {
        // restart:
        GLib.info ("Restarting application NOW, PID" + Gtk.Application.application_pid ("is ending.";
        Gtk.Application.quit ();
        string[] args = Gtk.Application.arguments ();
        string prg = args.take_first ();

        QProcess.start_detached (prg, args);
    } else {
        GLib.debug ("On this platform we do not restart.";
    }
}

void FolderMan.on_signal_setup_push_notifications (Folder.Map folder_map) {
    for (var folder : folder_map) {
        const var account = folder.account_state ().account ();

        // See if the account already provides the PushNotifications object and if yes connect to it.
        // If we can't connect at this point, the signals will be connected in on_signal_push_notifications_ready ()
        // after the Push_notification object emitted the ready signal
        on_signal_connect_to_push_notifications (account.data ());
        connect (account.data (), &Account.push_notifications_ready, this, &FolderMan.on_signal_connect_to_push_notifications, Qt.UniqueConnection);
    }
}

void FolderMan.on_signal_process_files_push_notification (Account account) {
    GLib.info ("Got files push notification for account" + account;

    for (var folder : this.folder_map) {
        // Just run on the folders that belong to this account
        if (folder.account_state ().account () != account) {
            continue;
        }

        GLib.info ("Schedule folder" + folder + "for sync";
        schedule_folder (folder);
    }
}

void FolderMan.on_signal_connect_to_push_notifications (Account account) {
    const var push_notifications = account.push_notifications ();

    if (push_notifications_files_ready (account)) {
        GLib.info ("Push notifications ready";
        connect (push_notifications, &PushNotifications.files_changed, this, &FolderMan.on_signal_process_files_push_notification, Qt.UniqueConnection);
    }
}

} // namespace Occ
