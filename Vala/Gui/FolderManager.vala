/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
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
@brief The FolderManager class
@ingroup gui

The FolderManager knows about all load
scheduling them when nece

A folder_connection is scheduled if:
- The configured force-sync-interval has expired
  (this.time_scheduler and on_signal_schedule_folder_by_time ())

- A folder_connection watcher re
  (this.folder_watchers and FolderConnection.on_signal_watched_pat

- The folder_connection etag on the server has changed
  (this.etag_poll_timer)

- The locks of a monitored file are released
  (this.lock_watcher and on_signal_watched_file_unlocked ())

- There was a sync error or a follow-up sync is r
  (this.time_scheduler and on_signal_schedule_folder_by_time ()
   and FolderConnection.on_signal_sync_finished ())
***********************************************************/
public class FolderManager : GLib.Object {

    private const string VERSION_C = "version";
    const int MAX_FOLDERS_VERSION = 1;

    private const string SLASH_TAG = "__SLASH__";
    private const string BSLASH_TAG = "__BSLASH__";
    private const string QMARK_TAG = "__QMARK__";
    private const string PERCENT_TAG = "__PERCENT__";
    private const string STAR_TAG = "__STAR__";
    private const string COLON_TAG = "__COLON__";
    private const string PIPE_TAG = "__PIPE__";
    private const string QUOTE_TAG = "__QUOTE__";
    private const string LT_TAG = "__LESS_THAN__";
    private const string GT_TAG = "__GREATER_THAN__";
    private const string PAR_O_TAG = "__PAR_OPEN__";
    private const string PAR_C_TAG = "__PAR_CLOSE__";

    public static FolderManager instance { public get; private set; }
    // = null;

    /***********************************************************
    ***********************************************************/
    private GLib.List<FolderConnection> disabled_folders;
    private FolderConnection.Map folder_map;
    private string folder_config_path;

    /***********************************************************
    Access to the currently syncing folder_connection.

    Note: This is only the folder_connection that's currently syncing
    as-scheduled may be externally-managed syncs such as from
    placeholder hydrations.

    See also is_any_sync_running ()
    ***********************************************************/
    public FolderConnection current_sync_folder { public get; private set; }

    private FolderConnection last_sync_folder;

    /***********************************************************
    If enabled is set to false, no new folders will start to
    sync. The current one will finish.

    Only enable or disable foldermans will schedule and do syncs.
    this is not the same as Pause and Resume of folders.
    ***********************************************************/
    public bool sync_enabled {
        public set {
            if (!this.sync_enabled && value && this.scheduled_folders != null) {
                // We have things in our queue that were waiting for the connection to come back on.
                start_scheduled_sync_soon ();
            }
            this.sync_enabled = value;
            // force a redraw in case the network connect status changed
            /* emit */ (signal_folder_sync_state_change (null));
        }
        private get {
            return this.sync_enabled;
        }
    }

    public bool ignore_hidden_files {
        /***********************************************************
        While ignoring hidden files can theoretically be switched
        per folder_connection, it's currently a global setting that users can
        only change for all folders at once.

        These helper functions can be removed once it's properly
        per-folder_connection.
        ***********************************************************/
        public get {
            if (this.folder_map.empty ()) {
                // Currently no folders in the manager . return default
                return false;
            }
            // Since the hidden_files settings is the same for all folders, just return the settings of the first folder_connection
            return this.folder_map.begin ().value ().ignore_hidden_files;
        }
        /***********************************************************
        Note that the setting will revert to 'true' if all folders
        are deleted...
        ***********************************************************/
        public set {
            foreach (FolderConnection folder_connection in this.folder_map) {
                folder_connection.ignore_hidden_files (value);
                folder_connection.save_to_settings ();
            }
        }
    }

    /***********************************************************
    FolderConnection aliases from the settings that weren't read
    ***********************************************************/
    private GLib.List<string> additional_blocked_folder_aliases;

    /***********************************************************
    Starts regular etag query jobs
    ***********************************************************/
    private GLib.Timeout etag_poll_timer;

    /***********************************************************
    The currently running etag query
    ***********************************************************/
    private RequestEtagJob current_etag_job;

    /***********************************************************
    Occasionally schedules folders
    ***********************************************************/
    private GLib.Timeout time_scheduler;

    /***********************************************************
    Scheduled folders that should be synced as soon as possible
    ***********************************************************/
    private QQueue<FolderConnection> scheduled_folders;

    /***********************************************************
    Picks the next scheduled folder_connection and starts the sync
    ***********************************************************/
    private GLib.Timeout start_scheduled_sync_timer;

    /***********************************************************
    ***********************************************************/
    public SocketApi socket_api {
        public get {
            return this.socket_api;
        }
        private set {
            this.socket_api = value;
        }
    }

    /***********************************************************
    ***********************************************************/

    //  private friend class Application;
    //  private friend class .TestFolderMan;

    /***********************************************************
    Signal to indicate a folder_connection has changed its sync state.

    Attention: The folder_connection may be zero. Do a general update of the state then.
    ***********************************************************/
    internal signal void signal_folder_sync_state_change (FolderConnection folder_connection);

    /***********************************************************
    Indicates when the schedule queue changes.
    ***********************************************************/
    internal signal void signal_schedule_queue_changed ();

    /***********************************************************
    Emitted whenever the list of configured folders changes.
    ***********************************************************/
    internal signal void signal_folder_list_changed (FolderConnection.Map folder_map);

    /***********************************************************
    Emitted once on_signal_remove_folders_for_account is done wiping
    ***********************************************************/
    internal signal void signal_wipe_done (AccountState account, bool on_signal_success);

    /***********************************************************
    ***********************************************************/
    private FolderManager (GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.navigation_pane_helper = this;
        //  ASSERT (!this.instance);
        this.instance = this;
        this.sync_enabled = true;
        this.current_sync_folder = null;

        this.socket_api = new SocketApi ();

        ConfigFile config;
        // std.chrono.milliseconds polltime_in_microseconds
        GLib.TimeSpan polltime_in_microseconds = config.remote_poll_interval ();
        GLib.info ("setting remote poll timer interval to " + polltime_in_microseconds.count () + "msec");
        this.etag_poll_timer.interval (polltime_in_microseconds.count ());
        this.etag_poll_timer.timeout.connect (
            this.on_signal_etag_poll_timer_timeout
        );
        this.etag_poll_timer.on_signal_start ();

        this.start_scheduled_sync_timer.single_shot (true);
        this.start_scheduled_sync_timer.timeout.connect (
            this.on_signal_start_scheduled_folder_sync
        );
        this.time_scheduler.interval (5000);
        this.time_scheduler.single_shot (false);
        this.time_scheduler.timeout.connect (
            this.on_signal_schedule_folder_by_time
        );
        this.time_scheduler.on_signal_start ();

        AccountManager.instance.signal_remove_account_folders.connect (
            this.on_signal_remove_folders_for_account
        );
        AccountManager.instance.signal_account_sync_connection_removed.connect (
            this.on_signal_account_removed
        );
        this.signal_folder_list_changed.connect (
            this.on_signal_setup_push_notifications
        );
    }


    /***********************************************************
    ***********************************************************/
    ~FolderManager () {
        q_delete_all (this.folder_map);
        this.instance = null;
    }


    /***********************************************************
    ***********************************************************/
    public static FolderManager instance {
        return this.instance;
    }


    /***********************************************************
    ***********************************************************/
    public int set_up_folders () {
        unload_and_delete_all_folders ();

        string[] skip_settings_keys;
        backward_migration_settings_keys (skip_settings_keys, skip_settings_keys);

        var settings = ConfigFile.settings_with_group ("Accounts");
        const var accounts_with_settings = settings.child_groups ();
        if (accounts_with_settings == "") {
            int r = setup_folders_migration ();
            if (r > 0) {
                AccountManager.instance.save (false); // don't save credentials, they had not been loaded from keychain
            }
            return r;
        }

        GLib.info ("Setup folders from settings file.");

        foreach (var account in AccountManager.instance.accounts) {
            const int identifier = account.account.identifier;
            if (!accounts_with_settings.contains (identifier)) {
                continue;
            }
            settings.begin_group (identifier);

            process (settings, skip_settings_keys, "Folders", true, false);

            // See FolderConnection.save_to_settings for details about why these exists.
            process (settings, skip_settings_keys, "Multifolders", false, false);
            process (settings, skip_settings_keys, "FoldersWithPlaceholders", false, true);

            settings.end_group (); // <account>
        }

        /* emit */ signal_folder_list_changed (this.folder_map);

        foreach (var folder_connection in this.folder_map) {
            folder_connection.process_switched_to_virtual_files ();
        }

        return this.folder_map.size ();
    }


    /***********************************************************
    The "backwards_compatible" flag here is related to migrating
    old database locations
    ***********************************************************/
    private void process (Settings settings, string[] skip_settings_keys, string group_name, bool backwards_compatible, bool folders_with_placeholders) {
        settings.begin_group (group_name);
        if (skip_settings_keys.contains (settings.group ())) {
            // Should not happen : bad container keys should have been deleted
            GLib.warning ("FolderConnection structure " + group_name + " is too new; ignoring.");
        } else {
            setup_folders_helper (*settings, account, skip_settings_keys, backwards_compatible, folders_with_placeholders);
        }
        settings.end_group ();
    }


    /***********************************************************
    ***********************************************************/
    public int setup_folders_migration () {
        ConfigFile config;
        GLib.Dir storage_dir = new GLib.Dir (config.config_path);
        this.folder_config_path = config.config_path + "folders";

        GLib.info ("Setup folders from " + this.folder_config_path + " (migration).");

        GLib.Dir directory = new GLib.Dir (this.folder_config_path);
        //We need to include hidden files just in case the alias starts with '.'
        directory.filter (GLib.Dir.Files | GLib.Dir.Hidden);
        const var list = directory.entry_list ();

        // Normally there should be only one account when migrating.
        AccountState account_state = AccountManager.instance.accounts.value (0);
        foreach (var alias in list) {
            FolderConnection folder_connection = set_up_folder_from_old_config_file (alias, account_state);
            if (folder_connection) {
                schedule_folder (folder_connection);
                /* emit */ signal_folder_sync_state_change (folder_connection);
            }
        }

        /* emit */ signal_folder_list_changed (this.folder_map);

        // return the number of valid folders.
        return this.folder_map.size ();
    }


    /***********************************************************
    Returns a list of keys that can't be read because they are
    from future versions.
    ***********************************************************/
    public static void backward_migration_settings_keys (string[] delete_keys, string[] ignore_keys) {
        var settings = ConfigFile.settings_with_group ("Accounts");

        foreach (var account_id in settings.child_groups ()) {
            settings.begin_group (account_id);
            process_subgroup (settings, "Folders");
            process_subgroup (settings, "Multifolders");
            process_subgroup (settings, "FoldersWithPlaceholders");
            settings.end_group ();
        }

        return { delete_keys, ignore_keys };
    }


    /***********************************************************
    ***********************************************************/
    private void process_subgroup (var settings, string name) {
        settings.begin_group (name);
        const int folders_version = settings.value (VERSION_C, 1).to_int ();
        if (folders_version <= MAX_FOLDERS_VERSION) {
            foreach (var folder_alias in settings.child_groups ()) {
                settings.begin_group (folder_alias);
                const int folder_version = settings.value (VERSION_C, 1).to_int ();
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


    /***********************************************************
    ***********************************************************/
    public FolderConnection.Map map () {
        return this.folder_map;
    }


    /***********************************************************
    Adds a folder_connection for an account, ensures the journal is gone and saves it in the settings.
    ***********************************************************/
    public FolderConnection add_folder (AccountState account_state, FolderDefinition folder_definition) {
        // Choose a database filename
        var definition = folder_definition;
        definition.journal_path = definition.default_journal_path (account_state.account);

        if (!ensure_journal_gone (definition.absolute_journal_path)) {
            return null;
        }

        var vfs = create_vfs_from_plugin (folder_definition.virtual_files_mode);
        if (!vfs) {
            GLib.warning ("Could not load plugin for mode " + folder_definition.virtual_files_mode);
            return null;
        }

        var folder_connection = add_folder_internal (definition, account_state, std.move (vfs));

        // Migration: The first account that's configured for a local folder_connection shall
        // be saved in a backwards-compatible way.
        const var folder_list = FolderManager.instance.map ();
        int count = 0;
        foreach (var FolderConnection in FolderManager.instance.map ()) {
            if (other != folder_connection && other.clean_path == folder_connection.clean_path) {
                count++;
            }
        }
        const bool one_account_only = count < 2;

        folder_connection.save_backwards_compatible (one_account_only);

        if (folder_connection) {
            folder_connection.save_backwards_compatible (one_account_only);
            folder_connection.save_to_settings ();
            /* emit */ signal_folder_sync_state_change (folder_connection);
            /* emit */ signal_folder_list_changed (this.folder_map);
        }

        this.navigation_pane_helper.schedule_update_cloud_storage_registry ();
        return folder_connection;
    }


    /***********************************************************
    Removes a folder_connection
    ***********************************************************/
    public void remove_folder (FolderConnection folder_connection) {
        if (!folder_connection) {
            GLib.critical ("Can not remove null folder_connection.");
            return;
        }

        GLib.info ("Removing " + folder_connection.alias ());

        const bool currently_running = folder_connection.is_sync_running ();
        if (currently_running) {
            // on_signal_abort the sync now
            folder_connection.on_signal_terminate_sync ();
        }

        if (this.scheduled_folders.remove_all (folder_connection) > 0) {
            /* emit */ signal_schedule_queue_changed ();
        }

        folder_connection.sync_paused = true;
        folder_connection.wipe_for_removal ();

        // remove the folder_connection configuration
        folder_connection.remove_from_settings ();

        unload_folder (folder_connection);
        if (currently_running) {
            // We want to schedule the next folder_connection once this is done
            folder_connection.signal_sync_finished.connect (
                this.on_signal_folder_sync_finished
            );
            // Let the folder_connection delete itself when done.
            folder_connection.signal_sync_finished.connect (
                folder_connection.delete_later
            );
        } else {
            delete folder_connection;
        }

        this.navigation_pane_helper.schedule_update_cloud_storage_registry ();

        /* emit */ signal_folder_list_changed (this.folder_map);
    }


    /***********************************************************
    Returns the folder_connection which the file or directory stored in path is in
    ***********************************************************/
    public FolderConnection folder_for_path (string path) {
        foreach (var folder_connection in this.map ().values ()) {
            if ((GLib.Dir.clean_path (path) + '/').has_prefix (folder_connection.clean_path + '/', (Utility.is_windows () || Utility.is_mac ()) ? Qt.CaseInsensitive : Qt.CaseSensitive)) {
                return folder_connection;
            }
        }
        return null;
    }


    /***********************************************************
    returns a list of local files that exist on the local harddisk for an
    incoming relative server path. The method checks with all existing sync
    folders.
    ***********************************************************/
    public string[] find_file_in_local_folders (string rel_path, unowned Account acc) {
        string[] re;

        // We'll be comparing against FolderConnection.remote_path which always starts with /
        string server_path = rel_path;
        if (!server_path.has_prefix ('/')) {
            server_path.prepend ('/');
        }

        foreach (FolderConnection folder_connection in this.map ().values ()) {
            if (acc && folder_connection.account_state.account != acc) {
                continue;
            }
            if (!server_path.has_prefix (folder_connection.remote_path)) {
                continue;
            }

            string path = folder_connection.clean_path + '/';
            path += server_path.mid_ref (folder_connection.remote_path_trailing_slash.length);
            if (GLib.File.exists (path)) {
                re.append (path);
            }
        }
        return re;
    }


    /***********************************************************
    Returns the folder_connection by alias or \c null if no folder_connection with the alias exists.
    ***********************************************************/
    public FolderConnection folder_by_alias (string alias) {
        if (alias != "") {
            if (this.folder_map.contains (alias)) {
                return this.folder_map[alias];
            }
        }
        return null;
    }


    /***********************************************************
    Migrate accounts from owncloud < 2.0
    Creates a folder_connection for a specific configuration, identified by
    alias.

    filename is the name of the file only, it does not include
    the configuration directory path

    WARNING: Do not remove this code, it is used for
    predefined/automated deployments (2016)
    ***********************************************************/
    public FolderConnection set_up_folder_from_old_config_file (string file, AccountState account_state) {
        FolderConnection folder_connection = null;

        GLib.info ("  ` . setting up: " + file);
        string escaped_alias = file;
        // check the unescaped variant (for the case when the filename comes out
        // of the directory listing). If the file does not exist, escape the
        // file and try again.
        GLib.FileInfo config_file = new GLib.FileInfo (this.folder_config_path, file);

        if (!config_file.exists) {
            // try the escaped variant.
            escaped_alias = escape_alias (file);
            config_file.file (this.folder_config_path, escaped_alias);
        }
        if (!config_file.is_readable ()) {
            GLib.warning ("Cannot read folder_connection definition for alias " + config_file.file_path);
            return folder_connection;
        }

        GLib.Settings settings = new GLib.Settings (this.folder_config_path + '/' + escaped_alias, GLib.Settings.IniFormat);
        GLib.info ("    . file path: " + settings.filename ());

        // Check if the filename is equal to the group setting. If not, use the group
        // name as an alias.
        string[] groups = settings.child_groups ();

        if (!groups.contains (escaped_alias) && groups.count () > 0) {
            escaped_alias = groups.first ();
        }

        settings.begin_group (escaped_alias); // read the group with the same name as the file which is the folder_connection alias

        string path = settings.value ("local_path").to_string ();
        string backend = settings.value ("backend").to_string ();
        string target_path = settings.value ("target_path").to_string ();
        bool paused = settings.value ("paused", false).to_bool ();
        // string connection = settings.value ("connection").to_string ();
        string alias = unescape_alias (escaped_alias);

        if (backend == "" || backend != "owncloud") {
            GLib.warning ("obsolete configuration of type" + backend);
            return null;
        }

        // cut off the leading slash, oc_url always has a trailing.
        if (target_path.has_prefix ('/')) {
            target_path.remove (0, 1);
        }

        if (!account_state) {
            GLib.critical ("can't create folder_connection without an account.");
            return null;
        }

        FolderDefinition folder_definition;
        folder_definition.alias = alias;
        folder_definition.local_path = path;
        folder_definition.target_path = target_path;
        folder_definition.paused = paused;
        folder_definition.ignore_hidden_files = ignore_hidden_files;

        folder_connection = add_folder_internal (folder_definition, account_state, std.make_unique<VfsOff> ());
        if (folder_connection != null) {
            string[] block_list = settings.value ("block_list").to_string_list ();
            if (!block_list.empty ()) {
                // migrate settings
                folder_connection.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, block_list);
                settings.remove ("block_list");
                // FIXME: If you remove this codepath, you need to provide another way to do
                // this via theme.h or the normal FolderManager.set_up_folders
            }

            folder_connection.save_to_settings ();
        }
        GLib.info ("Migrated! " + folder_connection);
        settings.sync ();
        return folder_connection;
    }


    /***********************************************************
    Ensures that a given directory does not contain a sync journal file.

    @returns false if the journal could not be removed, true otherwise.
    ***********************************************************/
    public static bool ensure_journal_gone (string journal_database_file) {
        // remove the old journal file
        while (GLib.File.exists (journal_database_file) && !GLib.File.remove (journal_database_file)) {
            GLib.warning ("Could not remove old database file at " + journal_database_file);
            int ret = Gtk.MessageBox.warning (null, _("Could not reset folder_connection state"),
                _("An old sync journal \"%1\" was found, "
                + "but could not be removed. Please make sure "
                + "that no application is currently using it.")
                    .printf (GLib.Dir.from_native_separators (GLib.Dir.clean_path (journal_database_file))),
                Gtk.MessageBox.Retry | Gtk.MessageBox.Abort);
            if (ret == Gtk.MessageBox.Abort) {
                return false;
            }
        }
        return true;
    }


    /***********************************************************
    Creates a new and empty local directory.
    ***********************************************************/
    public bool start_from_scratch (string local_folder) {
        if (local_folder == "") {
            return false;
        }

        GLib.FileInfo file_info = new GLib.FileInfo (local_folder);
        GLib.Dir parent_dir = new GLib.Dir (file_info.directory ());
        string folder_name = file_info.filename ();

        // Adjust for case where local_folder ends with a /
        if (file_info.is_dir ()) {
            folder_name = parent_dir.dir_name ();
            parent_dir.cd_up ();
        }

        if (file_info.exists ()) {
            // It exists, but is empty . just reuse it.
            if (file_info.is_dir () && file_info.directory ().count () == 0) {
                GLib.debug ("start_from_scratch: Directory is empty!");
                return true;
            }
            // Disconnect the socket api from the database to avoid that locking of the
            // database file does not allow to move this directory.
            FolderConnection folder_connection = folder_for_path (local_folder);
            if (folder_connection != null) {
                if (local_folder.has_prefix (folder_connection.path)) {
                    this.socket_api.on_signal_unregister_path (folder_connection.alias ());
                }
                folder_connection.journal_database ().close ();
                folder_connection.on_signal_terminate_sync (); // Normally it should not be running, but viel hilft viel
            }

            // Make a backup of the folder_connection/file.
            string new_name = backup_name (parent_dir.absolute_file_path (folder_name));
            string rename_error;
            if (!FileSystem.rename (file_info.absolute_file_path, new_name, rename_error)) {
                GLib.warning (
                    "start_from_scratch: Could not rename " + file_info.absolute_file_path
                    + " to " + new_name + " error: " + rename_error);
                return false;
            }
        }

        if (!parent_dir.mkdir (file_info.absolute_file_path)) {
            GLib.warning ("start_from_scratch: Could not mkdir " + file_info.absolute_file_path);
            return false;
        }

        return true;
    }


    /***********************************************************
    Produce text for use in the tray tooltip
    ***********************************************************/
    public static string tray_tooltip_status_string (LibSync.SyncResult.Status sync_status, bool has_unresolved_conflicts, bool paused) {
        string folder_message;
        switch (sync_status) {
        case LibSync.SyncResult.Status.UNDEFINED:
            folder_message = _("Undefined State.");
            break;
        case LibSync.SyncResult.Status.NOT_YET_STARTED:
            folder_message = _("Waiting to on_signal_start syncing.");
            break;
        case LibSync.SyncResult.Status.SYNC_PREPARE:
            folder_message = _("Preparing for sync.");
            break;
        case LibSync.SyncResult.Status.SYNC_RUNNING:
            folder_message = _("Sync is running.");
            break;
        case LibSync.SyncResult.Status.SUCCESS:
        case LibSync.SyncResult.Status.PROBLEM:
            if (has_unresolved_conflicts) {
                folder_message = _("Sync on_signal_finished with unresolved conflicts.");
            } else {
                folder_message = _("Last Sync was successful.");
            }
            break;
        case LibSync.SyncResult.Status.ERROR:
            break;
        case LibSync.SyncResult.Status.SETUP_ERROR:
            folder_message = _("Setup Error.");
            break;
        case LibSync.SyncResult.Status.SYNC_ABORT_REQUESTED:
            folder_message = _("User Abort.");
            break;
        case LibSync.SyncResult.Status.PAUSED:
            folder_message = _("Sync is paused.");
            break;
            // no default case on purpose, check compiler warnings
        }
        if (paused) {
            // sync is disabled.
            folder_message = _("%1 (Sync is paused)").printf (folder_message);
        }
        return folder_message;
    }


    /***********************************************************
    Compute status summarizing multiple folders
    ***********************************************************/
    public static void tray_overall_status (GLib.List<FolderConnection> folders,
        LibSync.SyncResult.Status status, bool unresolved_conflicts) {
        *status = LibSync.SyncResult.Status.UNDEFINED;
        *unresolved_conflicts = false;

        int count = folders.count ();

        // if one folder_connection: show the state of the one folder_connection.
        // if more folders:
        //   if one of them has an error -> show error
        //   if one is paused, but others ok, show ok
        // do not show "problem" in the tray
        if (count == 1) {
            FolderConnection folder_connection = folders.at (0);
            if (folder_connection) {
                var sync_result = folder_connection.sync_result;
                if (folder_connection.sync_paused) {
                    *status = LibSync.SyncResult.Status.PAUSED;
                } else {
                    LibSync.SyncResult.Status sync_status = sync_result.status ();
                    switch (sync_status) {
                    case LibSync.SyncResult.Status.UNDEFINED:
                        *status = LibSync.SyncResult.Status.ERROR;
                        break;
                    case LibSync.SyncResult.Status.PROBLEM : // don't show the problem icon in tray.
                        *status = LibSync.SyncResult.Status.SUCCESS;
                        break;
                    default:
                        *status = sync_status;
                        break;
                    }
                }
                *unresolved_conflicts = sync_result.has_unresolved_conflicts;
            }
        } else {
            int errors_seen = 0;
            int good_seen = 0;
            int abort_or_paused_seen = 0;
            int run_seen = 0;
            int various = 0;

            foreach (FolderConnection folder_connection in folders) {
                LibSync.SyncResult folder_result = folder_connection.sync_result;
                if (folder_connection.sync_paused) {
                    abort_or_paused_seen++;
                } else {
                    LibSync.SyncResult.Status sync_status = folder_result.status ();

                    switch (sync_status) {
                    case LibSync.SyncResult.Status.UNDEFINED:
                    case LibSync.SyncResult.Status.NOT_YET_STARTED:
                        various++;
                        break;
                    case LibSync.SyncResult.Status.SYNC_PREPARE:
                    case LibSync.SyncResult.Status.SYNC_RUNNING:
                        run_seen++;
                        break;
                    case LibSync.SyncResult.Status.PROBLEM : // don't show the problem icon in tray.
                    case LibSync.SyncResult.Status.SUCCESS:
                        good_seen++;
                        break;
                    case LibSync.SyncResult.Status.ERROR:
                    case LibSync.SyncResult.Status.SETUP_ERROR:
                        errors_seen++;
                        break;
                    case LibSync.SyncResult.Status.SYNC_ABORT_REQUESTED:
                    case LibSync.SyncResult.Status.PAUSED:
                        abort_or_paused_seen++;
                        // no default case on purpose, check compiler warnings
                    }
                }
                if (folder_result.has_unresolved_conflicts)
                    *unresolved_conflicts = true;
            }
            if (errors_seen > 0) {
                *status = LibSync.SyncResult.Status.ERROR;
            } else if (abort_or_paused_seen > 0 && abort_or_paused_seen == count) {
                // only if all folders are paused
                *status = LibSync.SyncResult.Status.PAUSED;
            } else if (run_seen > 0) {
                *status = LibSync.SyncResult.Status.SYNC_RUNNING;
            } else if (good_seen > 0) {
                *status = LibSync.SyncResult.Status.SUCCESS;
            }
        }
    }


    /***********************************************************
    Escaping of the alias which is used in GLib.Settings AND the
    file system, thus need to be escaped.
    ***********************************************************/
    public static string escape_alias (string alias) {
        string a = alias;

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


    /***********************************************************
    ***********************************************************/
    public static string unescape_alias (string alias) {
        string a = alias;

        a.replace (SLASH_TAG, "/");
        a.replace (BSLASH_TAG, "\\");
        a.replace (QMARK_TAG, "?");
        a.replace (PERCENT_TAG, "%");
        a.replace (STAR_TAG, "*");
        a.replace (COLON_TAG, ":");
        a.replace (PIPE_TAG, "|");
        a.replace (QUOTE_TAG, "\"");
        a.replace (LT_TAG, "<");
        a.replace (GT_TAG, ">");
        a.replace (PAR_O_TAG, "[");
        a.replace (PAR_C_TAG, "]");

        return a;
    }


    /***********************************************************
    ***********************************************************/
    private bool push_notifications_files_ready (Account account) {
        const var push_notifications = account.push_notifications ();
        const var push_files_available = account.capabilities.available_push_notifications () & PushNotificationType.FILES;

        return push_files_available && push_notifications && push_notifications.is_ready ();
    }


    /***********************************************************
    ***********************************************************/
    public NavigationPaneHelper navigation_pane_helper {
        public get {
            return this.navigation_pane_helper;
        }
    }


    /***********************************************************
    Check if @a path is a valid path for a new folder_connection considering the already sync'ed items.
    Make sure that this folder_connection, or any subfolder is not sync'ed already.

    Note that different accounts are allowed to sync to the same folder_connection.

    @returns an empty string if it is allowed, or an error if it is not allowed
    ***********************************************************/
    public string check_path_validity_for_new_folder (string path, GLib.Uri server_url = GLib.Uri ()) {
        string recursive_validity = check_path_validity_recursive (path);
        if (!recursive_validity == "") {
            GLib.debug (path + recursive_validity);
            return recursive_validity;
        }

        // check if the local directory isn't used yet in another own_cloud sync
        Qt.CaseSensitivity case_sensitivity = Qt.CaseSensitive;
        if (Utility.fs_case_preserving ()) {
            case_sensitivity = Qt.CaseInsensitive;
        }

        const string user_dir = GLib.Dir.clean_path (canonical_path (path)) + '/';
        for (var i = this.folder_map.const_begin (); i != this.folder_map.const_end (); ++i) {
            var folder_connection = static_cast<FolderConnection> (i.value ());
            string folder_dir = GLib.Dir.clean_path (canonical_path (folder_connection.path)) + '/';

            bool different_paths = string.compare (folder_dir, user_dir, case_sensitivity) != 0;
            if (different_paths && folder_dir.has_prefix (user_dir, case_sensitivity)) {
                return _("The local folder_connection %1 already contains a folder_connection used in a folder_connection sync connection. "
                       + "Please pick another one!")
                            .printf (GLib.Dir.to_native_separators (path));
            }

            if (different_paths && user_dir.has_prefix (folder_dir, case_sensitivity)) {
                return _("The local folder_connection %1 is already contained in a folder_connection used in a folder_connection sync connection. "
                       + "Please pick another one!")
                            .printf (GLib.Dir.to_native_separators (path));
            }

            // if both pathes are equal, the server url needs to be different
            // otherwise it would mean that a new connection from the same local folder_connection
            // to the same account is added which is not wanted. The account must differ.
            if (server_url.is_valid () && !different_paths) {
                GLib.Uri folder_url = folder_connection.account_state.account.url;
                string user = folder_connection.account_state.account.credentials ().user ();
                folder_url.user_name (user);

                if (server_url == folder_url) {
                    return _("There is already a sync from the server to this local folder_connection. "
                           + "Please pick another local folder_connection!");
                }
            }
        }

        return "";
    }


    /***********************************************************
    Attempts to find a non-existing, acceptable path for creating a new sync folder_connection.

    Uses \a base_path as the baseline. It'll return this path if it's acceptable.

    Note that this can fail. If someone syncs ~ and \a base_path is ~/own_cloud, no
    subfolder of ~ would be a good candidate. When that happens \a base_path
    is returned.
    ***********************************************************/
    public string find_good_path_for_new_sync_folder (string base_path, GLib.Uri server_url) {
        string folder_connection = base_path;

        // If the parent folder_connection is a sync folder_connection or contained in one, we can't
        // possibly find a valid sync folder_connection inside it.
        // Example: Someone syncs their home directory. Then ~/foobar is not
        // going to be an acceptable sync folder_connection path for any value of foobar.
        string parent_folder = GLib.FileInfo (folder_connection).directory ().canonical_path;
        if (FolderManager.instance.folder_for_path (parent_folder)) {
            // Any path with that parent is going to be unacceptable,
            // so just keep it as-is.
            return base_path;
        }

        int attempt = 1;
        while (true) {
            const bool is_good =
                !GLib.FileInfo (folder_connection).exists ()
                && FolderManager.instance.check_path_validity_for_new_folder (folder_connection, server_url) == "";
            if (is_good) {
                break;
            }

            // Count attempts and give up eventually
            attempt++;
            if (attempt > 100) {
                return base_path;
            }

            folder_connection = base_path + string.number (attempt);
        }

        return folder_connection;
    }


    /***********************************************************
    Access to the current queue of scheduled folders.
    ***********************************************************/
    public QQueue<FolderConnection> schedule_queue () {
        return this.scheduled_folders;
    }


    /***********************************************************
    Returns true if any folder_connection is currently syncing.

    This might be a FolderManager-scheduled sync, or a externally
    managed sync like a placeholder hydration.
    ***********************************************************/
    public bool is_any_sync_running () {
        if (this.current_sync_folder != null) {
            return true;
        }

        foreach (var folder_connection in this.folder_map) {
            if (folder_connection.is_sync_running ()) {
                return true;
            }
        }
        return false;
    }


    /***********************************************************
    Removes all folders
    ***********************************************************/
    public int unload_and_delete_all_folders () {
        int count = 0;

        // clear the list of existing folders.
        foreach (FolderConnection folder_connection in this.folder_map) {
            unload_folder (folder_connection);
            delete folder_connection;
            count++;
        }
        //  ASSERT (this.folder_map == "");

        this.last_sync_folder = null;
        this.current_sync_folder = null;
        this.scheduled_folders.clear ();
        /* emit */ signal_folder_list_changed (this.folder_map);
        /* emit */ signal_schedule_queue_changed ();

        return count;
    }


    /***********************************************************
    Queues a folder_connection for syncing.


    If a folder_connection wants to be synced, it calls this slot and is
    added to the queue. The slot to actually start a sync is
    called afterwards.
    ***********************************************************/
    public void schedule_folder (FolderConnection folder_connection) {
        if (!folder_connection) {
            GLib.critical ("on_signal_schedule_sync called with null folder_connection.");
            return;
        }
        var alias = folder_connection.alias ();

        GLib.info ("Schedule folder_connection " + alias + " to sync!");

        if (!this.scheduled_folders.contains (folder_connection)) {
            if (!folder_connection.can_sync ()) {
                GLib.info ("FolderConnection is not ready to sync, not scheduled!");
                this.socket_api.on_signal_update_folder_view (folder_connection);
                return;
            }
            folder_connection.prepare_to_sync ();
            /* emit */ signal_folder_sync_state_change (folder_connection);
            this.scheduled_folders.enqueue (folder_connection);
            /* emit */ signal_schedule_queue_changed ();
        } else {
            GLib.info ("Sync for folder_connection " + alias + " already scheduled, do not enqueue!");
        }

        start_scheduled_sync_soon ();
    }


    /***********************************************************
    Puts a folder_connection in the very front of the queue.
    ***********************************************************/
    public void schedule_folder_next (FolderConnection folder_connection) {
        var alias = folder_connection.alias ();
        GLib.info ("Schedule folder_connection " + alias + " to sync! Front-of-queue.");

        if (!folder_connection.can_sync ()) {
            GLib.info ("FolderConnection is not ready to sync, not scheduled!");
            return;
        }

        this.scheduled_folders.remove_all (folder_connection);

        folder_connection.prepare_to_sync ();
        /* emit */ signal_folder_sync_state_change (folder_connection);
        this.scheduled_folders.prepend (folder_connection);
        /* emit */ signal_schedule_queue_changed ();

        start_scheduled_sync_soon ();
    }


    /***********************************************************
    Queues all folders for syncing.
    ***********************************************************/
    public void schedule_all_folders () {
        foreach (FolderConnection folder_connection in this.folder_map.values ()) {
            if (folder_connection && folder_connection.can_sync ()) {
                schedule_folder (folder_connection);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public void dirty_proxy () {
        foreach (FolderConnection folder_connection in this.folder_map.values ()) {
            if (folder_connection) {
                if (folder_connection.account_state && folder_connection.account_state.account
                    && folder_connection.account_state.account.network_access_manager) {
                    // Need to do this so we do not use the old determined system proxy
                    folder_connection.account_state.account.network_access_manager.proxy (
                        QNetworkProxy (QNetworkProxy.DefaultProxy));
                }
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public void dirty_network_limits () {
        foreach (FolderConnection folder_connection in this.folder_map.values ()) {
            // set only in busy folders. Otherwise they read the config anyway.
            if (folder_connection && folder_connection.is_busy ()) {
                folder_connection.dirty_network_limits ();
            }
        }
    }


    /***********************************************************
    Schedules folders of newly connected accounts, terminates and
    de-schedules folders of disconnected accounts.
    ***********************************************************/
    public void on_signal_account_state_changed () {
        var account_state = qobject_cast<AccountState> (sender ());
        if (!account_state) {
            return;
        }
        string account_name = account_state.account.display_name;

        if (account_state.is_connected) {
            GLib.info ("Account " + account_name + " connected, scheduling its folders.");

            foreach (FolderConnection folder_connection in this.folder_map.values ()) {
                if (folder_connection
                    && folder_connection.can_sync ()
                    && folder_connection.account_state == account_state) {
                    schedule_folder (folder_connection);
                }
            }
        } else {
            GLib.info ("Account " + account_name
                + " disconnected or paused, terminating or descheduling sync folders.");

            foreach (FolderConnection folder_connection in this.folder_map.values ()) {
                if (folder_connection
                    && folder_connection.is_sync_running ()
                    && folder_connection.account_state == account_state) {
                    folder_connection.on_signal_terminate_sync ();
                }
            }

            foreach (FolderConnection folder_connection in this.scheduled_folders) {
                if (folder_connection.account_state == account_state) {
                    this.scheduled_folders.remove (folder_connection);
                }
            }
            /* emit */ signal_schedule_queue_changed ();
        }
    }


    /***********************************************************
    Restart the client as soon as it is possible, ie. no folders syncing.
    ***********************************************************/
    public void on_signal_schedule_app_restart () {
        this.app_restart_required = true;
        GLib.info ("Application restart requested!");
    }


    /***********************************************************
    Slot to schedule an ETag job (from FolderConnection only)
    ***********************************************************/
    public void on_signal_schedule_e_tag_job (string alias, RequestEtagJob request_etag_job) {
        request_etag_job.destroyed.connect (
            this.on_signal_etag_job_destroyed
        );
        GLib.Object.invoke_method (
            this,
            "on_signal_run_one_etag_job",
            Qt.QueuedConnection
        );
        // maybe: add to queue
    }


    /***********************************************************
    Wipe folder_connection
    ***********************************************************/
    public void on_signal_wipe_folder_for_account (AccountState account_state) {
        GLib.List<FolderConnection> folders_to_remove; // QVarLengthArray<FolderConnection *, 16>

        foreach (FolderConnection folder_connection in this.folder_map) {
            if (folder_connection.account_state == account_state) {
                folders_to_remove.append (folder_connection);
            }
        }

        bool on_signal_success = false;
        foreach (FolderConnection folder_connection in folders_to_remove) {
            if (!folder_connection) {
                GLib.critical ("Can not remove null folder_connection.");
                return;
            }

            GLib.info ("Removing " + folder_connection.alias ());

            const bool currently_running = (this.current_sync_folder == folder_connection);
            if (currently_running) {
                // on_signal_abort the sync now
                this.current_sync_folder.on_signal_terminate_sync ();
            }

            if (this.scheduled_folders.remove_all (folder_connection) > 0) {
                /* emit */ signal_schedule_queue_changed ();
            }

            // wipe database
            folder_connection.wipe_for_removal ();

            // wipe data
            GLib.Dir user_folder = new GLib.Dir (folder_connection.path);
            if (user_folder.exists ()) {
                on_signal_success = user_folder.remove_recursively ();
                if (!on_signal_success) {
                    GLib.warning ("Failed to remove existing folder_connection " + folder_connection.path);
                } else {
                    GLib.info ("Wipe: Removed  file " + folder_connection.path);
                }

            } else {
                on_signal_success = true;
                GLib.warning ("FolderConnection does not exist, can not remove.");
            }

            folder_connection.sync_paused = true;

            // remove the folder_connection configuration
            folder_connection.remove_from_settings ();

            unload_folder (folder_connection);
            if (currently_running) {
                delete folder_connection;
            }

            this.navigation_pane_helper.schedule_update_cloud_storage_registry ();
        }

        /* emit */ signal_folder_list_changed (this.folder_map);
        /* emit */ signal_wipe_done (account_state, on_signal_success);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_sync_paused (FolderConnection folder_connection, bool paused) {
        if (!folder_connection) {
            GLib.critical ("on_signal_folder_sync_paused called with empty folder_connection.");
            return;
        }

        if (!paused) {
            this.disabled_folders.remove (folder_connection);
            schedule_folder (folder_connection);
        } else {
            this.disabled_folders.insert (folder_connection);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_can_sync_changed () {
        var folder_connection = qobject_cast<FolderConnection> (sender ());
         //  ASSERT (folder_connection);
        if (folder_connection.can_sync ()) {
            this.socket_api.on_signal_register_path (folder_connection.alias ());
        } else {
            this.socket_api.on_signal_unregister_path (folder_connection.alias ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_sync_started () {
        var folder_connection = qobject_cast<FolderConnection> (sender ());
        //  ASSERT (folder_connection);
        if (!folder_connection)
            return;

        GLib.info (lc_folder_man, ">========== Sync started for folder_connection [%s] of account [%s] with remote [%s]",
            q_printable (folder_connection.short_gui_local_path),
            q_printable (folder_connection.account_state.account.display_name),
            q_printable (folder_connection.remote_url ().to_string ()));
    }


    /***********************************************************
    a folder_connection indicates that its syncing is on_signal_finished.
    Start the next sync after the system had some milliseconds to breath.
    This delay is particularly useful to avoid late file change notifications
    (that we caused ourselves by syncing) from triggering another spurious sync.
    ***********************************************************/
    private void on_signal_folder_sync_finished (LibSync.SyncResult result) {
        var folder_connection = qobject_cast<FolderConnection> (sender ());
        //  ASSERT (folder_connection);
        if (!folder_connection)
            return;

        GLib.info (lc_folder_man, "<========== Sync on_signal_finished for folder_connection [%s] of account [%s] with remote [%s]",
            q_printable (folder_connection.short_gui_local_path),
            q_printable (folder_connection.account_state.account.display_name),
            q_printable (folder_connection.remote_url ().to_string ()));

        if (folder_connection == this.current_sync_folder) {
            this.last_sync_folder = this.current_sync_folder;
            this.current_sync_folder = null;
        }
        if (!is_any_sync_running ())
            start_scheduled_sync_soon ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_run_one_etag_job () {
        if (this.current_etag_job == null) {
            foreach (FolderConnection folder_connection in this.folder_map) {
                if (folder_connection.etag_job ()) {
                    // Caveat: always grabs the first folder_connection with a job, but we think this is Ok for now and avoids us having a seperate queue.
                    this.current_etag_job = folder_connection.etag_job ();
                    folder_connection = folder_connection;
                    break;
                }
            }
            if (this.current_etag_job == null) {
                //GLib.debug ("No more remote ETag check jobs to schedule.";

                // now it might be a good time to check for restarting...
                if (!is_any_sync_running () && this.app_restart_required) {
                    restart_application ();
                }
            } else {
                GLib.debug ("Scheduling " + folder_connection.remote_url ().to_string () + "to check remote ETag.");
                this.current_etag_job.on_signal_start (); // on destroy/end it will continue the queue via on_signal_etag_job_destroyed
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_etag_job_destroyed (GLib.Object object) {
        // this.current_etag_job is automatically cleared
        // maybe : remove from queue
        GLib.Object.invoke_method (this, "on_signal_run_one_etag_job", Qt.QueuedConnection);
    }



    /***********************************************************
    Slot to take the next folder_connection from queue and start syncing.

    Slot to start folder_connection syncs.

    It is either called from the slot where folders enqueue
    themselves for syncing or after a folder_connection sync was finished.
    ***********************************************************/
    private void on_signal_start_scheduled_folder_sync () {
        if (is_any_sync_running ()) {
            foreach (FolderConnection folder_connection in this.folder_map) {
                if (folder_connection.is_sync_running ()) {
                    GLib.info ("Currently folder_connection " + folder_connection.remote_url ().to_string () + " is running, wait for finish!");
                }
            }
            return;
        }

        if (!this.sync_enabled) {
            GLib.info ("FolderManager: Syncing is disabled; no scheduling.");
            return;
        }

        GLib.debug ("folder_queue size: " + this.scheduled_folders.count ());
        if (this.scheduled_folders == "") {
            return;
        }

        // Find the first folder_connection in the queue that can be synced.
        FolderConnection folder_connection = null;
        while (!this.scheduled_folders == "") {
            FolderConnection g = this.scheduled_folders.dequeue ();
            if (g.can_sync ()) {
                folder_connection = g;
                break;
            }
        }

        /* emit */ signal_schedule_queue_changed ();

        // Start syncing this folder_connection!
        if (folder_connection != null) {
            // Safe to call several times, and necessary to try again if
            // the folder_connection path didn't exist previously.
            folder_connection.register_folder_watcher ();
            register_folder_with_socket_api (folder_connection);

            this.current_sync_folder = folder_connection;
            folder_connection.on_signal_start_sync ({});
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_etag_poll_timer_timeout () {
        GLib.info ("Etag poll timer timeout.");
        GLib.info ("Folders to sync: " + this.folder_map.size ());
        GLib.List<FolderConnection> folders_to_run = new GLib.List<FolderConnection> ();

        // Some folders need not to be checked because they use the push notifications
        foreach (FolderConnection folder_connection in this.folder_map) {
            if (!push_notifications_files_ready (folder_connection.account_state.account)) {
                folders_to_run.append (folder_connection);
            }
        }

        GLib.info ("Number of folders that don't use push notifications: " + folders_to_run.size ());

        run_etag_jobs_if_possible (folders_to_run);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_account_removed (AccountState account_state) {
        foreach (FolderConnection folder_connection in this.folder_map) {
            if (folder_connection.account_state == account_state) {
                folder_connection.on_signal_associated_account_removed ();
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_remove_folders_for_account (AccountState account_state) {
        GLib.List<FolderConnection> folders_to_remove = new GLib.List<FolderConnection> ();
        foreach (FolderConnection folder_connection in this.folder_map) {
            if (folder_connection.account_state == account_state) {
                folders_to_remove.append (folder_connection);
            }
        }

        foreach (FolderConnection folder_connection in folders_to_remove) {
            remove_folder (folder_connection);
        }
        /* emit */ signal_folder_list_changed (this.folder_map);
    }


    /***********************************************************
    Wraps the FolderConnection.signal_sync_state_change () signal into the
    FolderManager.signal_folder_sync_state_change (FolderConnection*) signal.
    ***********************************************************/
    private void on_signal_forward_folder_sync_state_change () {
        var folder_connection = (FolderConnection) sender ();
        if (folder_connection) {
            /* emit */ signal_folder_sync_state_change (folder_connection);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_server_version_changed (Account account) {
        // Pause folders if the server version is unsupported
        if (account.server_version_unsupported) {
            GLib.warning (
                "The server version is unsupported: "
                + account.server_version ()
                + "pausing all folders on the account.");

            foreach (FolderConnection folder_connection in this.folder_map) {
                if (folder_connection.account_state.account == account) {
                    folder_connection.sync_paused = true;
                }
            }
        }
    }


    /***********************************************************
    A file whose locks were being monitored has become unlocked.

    This schedules the folder_connection for synchronization that contains
    the file with the given path.
    ***********************************************************/
    private void on_signal_watched_file_unlocked (string path) {
        FolderConnection folder_connection = folder_for_path (path);
        if (folder_connection != null) {
            // Treat this equivalently to the file being reported by the file watcher
            folder_connection.on_signal_watched_path_changed (path, FolderConnection.ChangeReason.ChangeReason.UNLOCK);
        }
    }


    /***********************************************************
    Schedules folders whose time to sync has come.

    Either because a long time has passed since the last sync or
    because of previous failures.
    ***********************************************************/
    private void on_signal_schedule_folder_by_time () {
        foreach (FolderConnection folder_connection in this.folder_map) {
            // Never schedule if syncing is disabled or when we're currently
            // querying the server for etags
            if (!folder_connection.can_sync () || folder_connection.etag_job ()) {
                continue;
            }

            var msecs_since_sync = folder_connection.microseconds_since_last_sync ();

            // Possibly it's just time for a new sync run
            bool force_sync_interval_expired = msecs_since_sync > ConfigFile ().force_sync_interval ();
            if (force_sync_interval_expired) {
                GLib.info (
                    "Scheduling folder_connection " + folder_connection.alias ()
                    + " because it has been " + msecs_since_sync.count () + "ms "
                    + " since the last sync.");

                schedule_folder (folder_connection);
                continue;
            }

            // Retry a couple of times after failure; or regularly if requested
            bool sync_again =
                (folder_connection.consecutive_failing_syncs () > 0 && folder_connection.consecutive_failing_syncs () < 3)
                || folder_connection.sync_engine.is_another_sync_needed () == AnotherSyncNeeded.DELAYED_FOLLOW_UP;
            var sync_again_delay = std.chrono.seconds (10); // 10s for the first retry-after-fail
            if (folder_connection.consecutive_failing_syncs () > 1)
                sync_again_delay = std.chrono.seconds (60); // 60s for each further attempt
            if (sync_again && msecs_since_sync > sync_again_delay) {
                GLib.info (
                    "Scheduling folder_connection " + folder_connection.alias ()
                    + ", the last " + folder_connection.consecutive_failing_syncs () + " syncs failed "
                    + ", another_sync_needed " + folder_connection.sync_engine.is_another_sync_needed ()
                    + ", last status: " + folder_connection.sync_result.status_string
                    + ", time since last sync: " + msecs_since_sync.count ());

                schedule_folder (folder_connection);
                continue;
            }

            // Do we want to retry failing syncs or another-sync-needed runs more often?
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_setup_push_notifications (FolderConnection.Map folder_map) {
        foreach (FolderConnection folder_connection in folder_map) {
            const Account account = folder_connection.account_state.account;

            // See if the account already provides the PushNotificationManager object and if yes connect to it.
            // If we can't connect at this point, the signals will be connected in on_signal_push_notifications_ready ()
            // after the Push_notification object emitted the ready signal
            on_signal_connect_to_push_notifications (account);
            account.push_notifications_ready.connect (
                this.on_signal_connect_to_push_notifications // Qt.UniqueConnection
            );
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_process_files_push_notification (Account account) {
        GLib.info ("Got files push notification for account " + account);

        foreach (FolderConnection folder_connection in this.folder_map) {
            // Just run on the folders that belong to this account
            if (folder_connection.account_state.account != account) {
                continue;
            }

            GLib.info ("Schedule folder_connection " + folder_connection + " for sync.");
            schedule_folder (folder_connection);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_connect_to_push_notifications (Account account) {
        const PushNotificationManager push_notifications = account.push_notifications ();

        if (push_notifications_files_ready (account)) {
            GLib.info ("Push notifications ready.");
            push_notifications.files_changed.connect (
                this.on_signal_process_files_push_notification // Qt.UniqueConnection
            );
        }
    }


    /***********************************************************
    Adds a new folder_connection, does not add it to the account settings and
    does not set an account on the new folder_connection.
    ***********************************************************/
    private FolderConnection add_folder_internal (FolderDefinition folder_definition,
        AccountState account_state, AbstractVfs vfs) {
        var alias = folder_definition.alias;
        int count = 0;
        while (folder_definition.alias == ""
            || this.folder_map.contains (folder_definition.alias)
            || this.additional_blocked_folder_aliases.contains (folder_definition.alias)) {
            // There is already a folder_connection configured with this name and folder_connection names need to be unique
            folder_definition.alias = alias + string.number (++count);
        }

        var folder_connection = new FolderConnection (folder_definition, account_state, std.move (vfs), this);

        if (this.navigation_pane_helper.show_in_explorer_navigation_pane && folder_definition.navigation_pane_clsid == null) {
            folder_connection.navigation_pane_clsid (QUuid.create_uuid ());
            folder_connection.save_to_settings ();
        }

        GLib.info ("Adding folder_connection to FolderConnection Map " + folder_connection + folder_connection.alias ());
        this.folder_map[folder_connection.alias ()] = folder_connection;
        if (folder_connection.sync_paused) {
            this.disabled_folders.insert (folder_connection);
        }

        // See matching disconnects in unload_folder ().
        folder_connection.signal_sync_started.connect (
            this.on_signal_folder_sync_started
        );
        folder_connection.signal_sync_finished.connect (
            this.on_signal_folder_sync_finished
        );
        folder_connection.signal_sync_state_change.connect (
            this.on_signal_forward_folder_sync_state_change
        );
        folder_connection.signal_sync_paused_changed.connect (
            this.on_signal_folder_sync_paused
        );
        folder_connection.signal_can_sync_changed.connect (
            this.on_signal_folder_can_sync_changed
        );
        folder_connection.sync_engine.sync_file_status_tracker.signal_file_status_changed.connect (
            this.socket_api.on_signal_broadcast_status_push_message
        );
        folder_connection.signal_watched_file_changed_externally.connect (
            folder_connection.sync_engine.sync_file_status_tracker.on_signal_path_touched
        );

        folder_connection.register_folder_watcher ();
        register_folder_with_socket_api (folder_connection);
        return folder_connection;
    }


    /***********************************************************
    unloads a folder_connection object, does not delete it
    ***********************************************************/
    private void unload_folder (FolderConnection folder_connection) {
        if (folder_connection == null) {
            return;
        }

        this.socket_api.on_signal_unregister_path (folder_connection.alias ());

        this.folder_map.remove (folder_connection.alias ());

        disconnect (
            folder_connection,
            FolderConnection.signal_sync_started,
            this,
            FolderManager.on_signal_folder_sync_started
        );
        disconnect (
            folder_connection,
            FolderConnection.signal_sync_finished,
            this,
            FolderManager.on_signal_folder_sync_finished
        );
        disconnect (
            folder_connection,
            FolderConnection.signal_sync_state_change,
            this,
            FolderManager.on_signal_forward_folder_sync_state_change
        );
        disconnect (
            folder_connection,
            FolderConnection.signal_sync_paused_changed,
            this,
            FolderManager.on_signal_folder_sync_paused
        );
        disconnect (
            folder_connection.sync_engine.sync_file_status_tracker,
            SyncFileStatusTracker.signal_file_status_changed,
            this.socket_api,
            SocketApi.on_signal_broadcast_status_push_message
        );
        disconnect (
            folder_connection,
            FolderConnection.signal_watched_file_changed_externally,
            folder_connection.sync_engine.sync_file_status_tracker,
            SyncFileStatusTracker.on_signal_path_touched
        );
    }


    /***********************************************************
    Will start a sync after a bit of delay.
    ***********************************************************/
    private void start_scheduled_sync_soon () {
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
        FolderConnection last_folder = this.last_sync_folder;
        if (last_folder != null) {
            ms_since_last_sync = last_folder.microseconds_since_last_sync ().count ();

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

        GLib.info ("Starting the next scheduled sync in " + (ms_delay / 1000) + " seconds.");
        this.start_scheduled_sync_timer.on_signal_start (ms_delay);
    }


    /***********************************************************
    Finds all folder_connection configuration files and create the folders
    ***********************************************************/
    private string backup_name (string full_path_name) {
        if (full_path_name.has_suffix ("/")) {
            full_path_name.chop (1);
        }

        if (full_path_name == "") {
            return "";
        }

        string new_name = full_path_name + _(" (backup)");
        GLib.FileInfo file_info = new GLib.FileInfo (new_name);
        int count = 2;
        do {
            if (file_info.exists ()) {
                new_name = full_path_name + _(" (backup %1)").printf (count++);
                file_info.file (new_name);
            }
        } while (file_info.exists ());

        return new_name;
    }


    /***********************************************************
    Makes the folder_connection known to the socket api
    ***********************************************************/
    private void register_folder_with_socket_api (FolderConnection folder_connection) {
        if (!folder_connection)
            return;
        if (!GLib.Dir (folder_connection.path).exists ())
            return;

        // register the folder_connection with the socket API
        if (folder_connection.can_sync ())
            this.socket_api.on_signal_register_path (folder_connection.alias ());
    }


    /***********************************************************
    Restarts the application (Linux only)
    ***********************************************************/
    private void restart_application () {
        if (Utility.is_linux ()) {
            // restart:
            GLib.info ("Restarting application NOW, PID " + Gtk.Application.application_pid () + " is ending.");
            Gtk.Application.quit ();
            string[] args = Gtk.Application.arguments ();
            string prg = args.take_first ();

            QProcess.start_detached (prg, args);
        } else {
            GLib.debug ("On this platform we do not restart.");
        }
    }


    /***********************************************************
    ***********************************************************/
    private void setup_folders_helper (GLib.Settings settings, unowned AccountState account, string[] ignore_keys, bool backwards_compatible, bool folders_with_placeholders) {
        foreach (var folder_alias in settings.child_groups ()) {
            // Skip folders with too-new version
            settings.begin_group (folder_alias);
            if (ignore_keys.contains (settings.group ())) {
                GLib.info ("FolderConnection " + folder_alias + " is too new; ignoring.");
                this.additional_blocked_folder_aliases.insert (folder_alias);
                settings.end_group ();
                continue;
            }
            settings.end_group ();

            FolderDefinition folder_definition;
            settings.begin_group (folder_alias);
            if (FolderDefinition.on_signal_load (settings, folder_alias, folder_definition)) {
                var default_journal_path = folder_definition.default_journal_path (account.account);

                // Migration : Old settings don't have journal_path
                if (folder_definition.journal_path == "") {
                    folder_definition.journal_path = default_journal_path;
                }

                // Migration #2 : journal_path might be absolute (in DataAppDir most likely) move it back to the root of local tree
                if (folder_definition.journal_path.at (0) != char ('.')) {
                    GLib.File old_journal = new GLib.File (folder_definition.journal_path);
                    GLib.File old_journal_shm = new GLib.File (folder_definition.journal_path + "-shm");
                    GLib.File old_journal_wal = new GLib.File (folder_definition.journal_path + "-wal");

                    folder_definition.journal_path = default_journal_path;

                    socket_api ().on_signal_unregister_path (folder_alias);
                    var settings = account.settings ();

                    var journal_file_move_success = true;
                    // Due to database logic can't be sure which of these file exist.
                    if (old_journal.exists ()) {
                        journal_file_move_success &= old_journal.rename (folder_definition.local_path + "/" + folder_definition.journal_path);
                    }
                    if (old_journal_shm.exists ()) {
                        journal_file_move_success &= old_journal_shm.rename (folder_definition.local_path + "/" + folder_definition.journal_path + "-shm");
                    }
                    if (old_journal_wal.exists ()) {
                        journal_file_move_success &= old_journal_wal.rename (folder_definition.local_path + "/" + folder_definition.journal_path + "-wal");
                    }

                    if (!journal_file_move_success) {
                        GLib.warning ("Wasn't able to move 3.0 syncjournal database files to new location. One-time loss off sync settings possible.");
                    } else {
                        GLib.info ("Successfully migrated syncjournal database.");
                    }

                    var vfs = create_vfs_from_plugin (folder_definition.virtual_files_mode);
                    if (!vfs && folder_definition.virtual_files_mode != AbstractVfs.Off) {
                        GLib.warning ("Could not load plugin for mode " + folder_definition.virtual_files_mode);
                    }

                    FolderConnection folder_connection = add_folder_internal (folder_definition, account, std.move (vfs));
                    folder_connection.save_to_settings ();

                    continue;
                }

                // Migration : . files sometimes can't be created.
                // So if the configured journal_path has a dot-underscore (".sync_*.db")
                // but the current default doesn't have the underscore, switch to the
                // new default if no database exists yet.
                if (folder_definition.journal_path.has_prefix (".sync_")
                    && default_journal_path.has_prefix (".sync_")
                    && !GLib.File.exists (folder_definition.absolute_journal_path)) {
                    folder_definition.journal_path = default_journal_path;
                }

                // Migration : If an old database is found, move it to the new name.
                if (backwards_compatible) {
                    SyncJournalDb.maybe_migrate_database (folder_definition.local_path, folder_definition.absolute_journal_path);
                }

                const var switch_to_vfs = is_switch_to_vfs_needed (folder_definition);
                if (switch_to_vfs) {
                    folder_definition.virtual_files_mode = this.best_available_vfs_mode;
                }

                var vfs = create_vfs_from_plugin (folder_definition.virtual_files_mode);
                if (!vfs) {
                    // TODO: Must do better error handling
                    q_fatal ("Could not load plugin");
                }

                FolderConnection folder_connection = add_folder_internal (std.move (folder_definition), account, std.move (vfs));
                if (folder_connection) {
                    if (switch_to_vfs) {
                        folder_connection.switch_to_virtual_files ();
                    }
                    // Migrate the old "use_placeholders" setting to the root folder_connection pin state
                    if (settings.value (VERSION_C, 1).to_int () == 1
                        && settings.value ("use_placeholders", false).to_bool ()) {
                        GLib.info ("Migrate: From use_placeholders to Common.ItemAvailability.ONLINE_ONLY");
                        folder_connection.root_pin_state (Common.ItemAvailability.ONLINE_ONLY);
                    }

                    // Migration: Mark folders that shall be saved in a backwards-compatible way
                    if (backwards_compatible) {
                        folder_connection.save_backwards_compatible (true);
                    }
                    if (folders_with_placeholders) {
                        folder_connection.save_in_folders_with_placeholders ();
                    }

                    schedule_folder (folder_connection);
                    /* emit */ signal_folder_sync_state_change (folder_connection);
                }
            }
            settings.end_group ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private bool is_switch_to_vfs_needed (FolderDefinition folder_definition) {
        var result = false;
        if (ENFORCE_VIRTUAL_FILES_SYNC_FOLDER &&
            folder_definition.virtual_files_mode != this.best_available_vfs_mode &&
            folder_definition.virtual_files_mode == AbstractVfs.Off &&
            Theme.show_virtual_files_option
        ) {
            result = true;
        }

        return result;
    }


    /***********************************************************
    ***********************************************************/
    private void run_etag_jobs_if_possible (GLib.List<FolderConnection> folder_map) {
        foreach (FolderConnection folder_connection in folder_map) {
            run_etag_job_if_possible (folder_connection);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void run_etag_job_if_possible (FolderConnection folder_connection) {
        const ConfigFile config = new ConfigFile ();
        const var polltime_in_microseconds = config.remote_poll_interval ();

        GLib.info ("Run etag job on folder_connection " + folder_connection);

        if (!folder_connection) {
            return;
        }
        if (folder_connection.is_sync_running ()) {
            GLib.info ("Can not run etag job: Sync is running");
            return;
        }
        if (this.scheduled_folders.contains (folder_connection)) {
            GLib.info ("Can not run etag job: FolderConnection is alreday scheduled.");
            return;
        }
        if (this.disabled_folders.contains (folder_connection)) {
            GLib.info ("Can not run etag job: FolderConnection is disabled.");
            return;
        }
        if (folder_connection.etag_job () != null || folder_connection.is_busy () || !folder_connection.can_sync ()) {
            GLib.info ("Can not run etag job: FolderConnection is busy.");
            return;
        }
        // When not using push notifications, make sure polltime_in_microseconds is reached
        if (!push_notifications_files_ready (folder_connection.account_state.account)) {
            if (folder_connection.microseconds_since_last_sync () < polltime_in_microseconds) {
                GLib.info ("Can not run etag job: Polltime not reached.");
                return;
            }
        }

        GLib.Object.invoke_method (
            folder_connection,
            "on_signal_run_etag_job",
            Qt.QueuedConnection
        );
    }


    /***********************************************************
    ***********************************************************/
    private static string check_path_validity_recursive (string path) {
        if (path == "") {
            return FolderManager._("No valid folder_connection selected!");
        }

        const GLib.FileInfo sel_file = new GLib.FileInfo (path);

        if (!sel_file.exists ()) {
            string parent_path = sel_file.directory ().path;
            if (parent_path != path) {
                return check_path_validity_recursive (parent_path);
            }
            return _("The selected path does not exist!");
        }
        if (!sel_file.is_dir ()) {
            return _("The selected path is not a folder_connection!");
        }
        if (!sel_file.is_writable ()) {
            return _("You have no permission to write to the selected folder_connection!");
        }
        return "";
    }


    /***********************************************************
    GLib.FileInfo.canonical_path returns an empty string if the
    file does not exist. This function also works with files
    that does not exist and resolve the symlinks in the parent
    directories.
    ***********************************************************/
    private static string canonical_path (string path) {
        GLib.FileInfo sel_file = new GLib.FileInfo (path);
        if (!sel_file.exists ()) {
            const var parent_path = sel_file.directory ().path;

            // It's possible for the parent_path to match the path
            // (possibly we've arrived at a non-existant drive root on Windows)
            // and recursing would be fatal.
            if (parent_path == path) {
                return path;
            }

            return canonical_path (parent_path) + '/' + sel_file.filename ();
        }
        return sel_file.canonical_file_path;
    }

} // class FolderManager

} // namespace Ui
} // namespace Occ
