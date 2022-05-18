/***********************************************************
@author Duncan Mac-Vicar P. <duncan@kde.org>
@author Daniel Molkentin <danimo@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.Dir>
//  #include <GLib.Settings>
//  #include <Gtk.MessageBox>
//  #include <GLib.PushButton>
//  #include <GLib.Applicat
//  #include <stri
//  #include <GLib.Uuid>
//  #include <set>
//  #include <chrono>
//  #include <memory>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The FolderConnection class
@ingroup gui
***********************************************************/
public class FolderConnection : GLib.Object {

    public class Map : GLib.HashTable<string, FolderConnection> { }
    public class MapIterator : GLib.MapIterator<string, FolderConnection> { }


    /***********************************************************
    ***********************************************************/
    public enum ChangeReason {
        OTHER,
        //  UNLOCK
    }


    /***********************************************************
    ***********************************************************/
    private enum LogStatus {
        REMOVE,
        RENAME,
        MOVE,
        NEW,
        ERROR,
        CONFLICT,
        UPDATED,
        //  FILE_LOCKED
    }

    private const string VERSION_C = "version";

    /***********************************************************
    The account the folder_connection is configured on.
    ***********************************************************/
    public unowned AccountState account_state { public get; private set; }

    private FolderDefinition definition;

    /***********************************************************
    As returned with GLib.FileInfo/canonical_file_path.
    Always ends with "/"/
    ***********************************************************/
    private string canonical_local_path;

    /***********************************************************
    The last sync result with error message and status
    ***********************************************************/
    public LibSync.SyncResult sync_result { public get; private set; }

    private LibSync.SyncEngine engine;
    private RequestEtagJob request_etag_job;
    private string last_etag;
    private GLib.Timer time_since_last_sync_done;
    private GLib.Timer time_since_last_sync_start;
    private GLib.Timer time_since_last_full_local_discovery;

    /***********************************************************
    std.chrono.milliseconds
    ***********************************************************/
    int last_sync_duration { public get; private set; }

    /***********************************************************
    The number of syncs that failed in a row.
    Reset when a sync is successful.
    ***********************************************************/
    int consecutive_failing_syncs { public get; private set; }

    /***********************************************************
    The number of requested follow-up syncs.
    Reset when no follow-up is requested.
    ***********************************************************/
    int consecutive_follow_up_syncs { public get; private set; }

    /***********************************************************
    Public get is used by the Socket API
    ***********************************************************/
    public /*mutable*/ Common.SyncJournalDb journal_database { public get; private set; }

    /***********************************************************
    ***********************************************************/
    private SyncRunFileLog file_log;

    /***********************************************************
    When the same local path is synced to multiple accounts,
    only one of them can be stored in the settings in a way
    that's compatible with old clients that don't support it.
    This flag marks folders that shall be written in a
    backwards-compatible way, by being set on the first FolderConnection
    instance that was configured for each local path.

    Migration: When this flag is true, this folder_connection will save to
    the backwards-compatible 'Folders' section in the config file.
    ***********************************************************/
    public bool save_backwards_compatible { public get; private set; }

    /***********************************************************
    Whether the folder_connection should be saved in that settings group

    If it was read from there it had virtual files enabled at
    some point and might still have database entries or
    suffix-virtual files even if they are disabled right now.
    This flag ensures folders that were in that group once
    never go back.

    Used to have placeholders: save in placeholder config section

    Behavior should be that this defaults to false but is always true when toggled
    void set -> this.save_in_folders_with_placeholders = true;
    ***********************************************************/
    public bool save_in_folders_with_placeholders { public get; private set; }

    /***********************************************************
    virtual files of some kind are enabled

    This is independent of whether new files will be virtual.
    It's possible to have this enabled and never have an
    automatic virtual file. But when it's on, the shell context
    menu will allow users to make existing files virtual.
    ***********************************************************/
    public bool virtual_files_enabled {
        public get {
            return this.definition.virtual_files_mode != Common.AbstractVfs.Off && !is_vfs_on_signal_off_switch_pending ();
        }
        public set {
            Common.VfsMode new_mode = this.definition.virtual_files_mode;
            if (value && this.definition.virtual_files_mode == Common.AbstractVfs.Off) {
                new_mode = this.best_available_vfs_mode;
            } else if (!value && this.definition.virtual_files_mode != Common.AbstractVfs.Off) {
                new_mode = Common.AbstractVfs.Off;
            }

            if (new_mode != this.definition.virtual_files_mode) {
                // TODO: Must wait for current sync to finish!
                LibSync.SyncEngine.wipe_virtual_files (path, this.journal_database, this.vfs);

                this.vfs.stop ();
                this.vfs.unregister_folder ();

                disconnect (this.vfs, null, this, null);
                disconnect (this.engine.sync_file_status_tracker, null, this.vfs, null);

                this.vfs.reset (create_vfs_from_plugin (new_mode).release ());

                this.definition.virtual_files_mode = new_mode;
                start_vfs ();
                if (new_mode != Common.AbstractVfs.Off) {
                    this.save_in_folders_with_placeholders = true;
                    switch_to_virtual_files ();
                }
                save_to_settings ();
            }
        }
    }

    /***********************************************************
    Whether a vfs mode switch is pending

    When the user desires that vfs be switched on/off but it
    hasn't been executed yet (syncs are still running), some
    options should be hidden, disabled or different.
    ***********************************************************/
    private bool vfs_on_signal_off_pending = false;

    /***********************************************************
    Whether this folder_connection has just switched to VFS or not
    ***********************************************************/
    private bool has_switched_to_vfs = false;

    /***********************************************************
    Watches this folder_connection's local directory for changes.

    Created by register_folder_watcher (),
    triggers on_signal_watched_path_changed ()
    ***********************************************************/
    private FolderWatcher folder_watcher;

    /***********************************************************
    Keeps track of locally dirty files so we can skip local
    discovery sometimes.
    ***********************************************************/
    private LocalDiscoveryTracker local_discovery_tracker;

    /***********************************************************
    The vfs mode instance (created by plugin) to use. Never null.
    ***********************************************************/
    public unowned Common.AbstractVfs vfs { public get; private set; }

    /***********************************************************
    ***********************************************************/
    public GLib.Uuid navigation_pane_clsid {
        public get {
            return this.definition.navigation_pane_clsid;
        }
        public set {
            this.definition.navigation_pane_clsid = valie;
        }
    }



    /***********************************************************
    Switch sync on or off
    ***********************************************************/
    public bool sync_paused {
        public set {
            if (value == this.definition.paused) {
                return;
            }

            this.definition.paused = value;
            save_to_settings ();

            if (!value) {
                sync_state (LibSync.SyncResult.Status.NOT_YET_STARTED);
            } else {
                sync_state (LibSync.SyncResult.Status.PAUSED);
            }
            signal_sync_paused_changed (this, value);
            signal_sync_state_change ();
            signal_can_sync_changed ();
        }
        public get {
            return this.definition.paused;
        }
    }

    /***********************************************************
    Create a new FolderConnection
    ***********************************************************/
    public FolderConnection (FolderDefinition definition, AccountState account_state, Common.AbstractVfs vfs, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.account_state = account_state;
        this.definition = definition;
        this.last_sync_duration = 0;
        this.consecutive_failing_syncs = 0;
        this.consecutive_follow_up_syncs = 0;
        this.journal_database = this.definition.absolute_journal_path;
        this.file_log = new SyncRunFileLog ();
        this.vfs = vfs.release ();
        this.save_backwards_compatible = false;
        this.save_in_folders_with_placeholders = false;
        this.time_since_last_sync_start.on_signal_start ();
        this.time_since_last_sync_done.on_signal_start ();

        LibSync.SyncResult.Status status = LibSync.SyncResult.Status.NOT_YET_STARTED;
        if (definition.paused) {
            status = LibSync.SyncResult.Status.PAUSED;
        }
        this.sync_result.status (status);

        // check if the local path exists
        check_local_path;

        this.sync_result.folder_connection (this.definition.alias);

        this.engine.reset (new LibSync.SyncEngine (this.account_state.account, this.path, remote_path, this.journal_database));
        // pass the setting if hidden files are to be ignored, will be read in csync_update
        this.engine.ignore_hidden_files (this.definition.ignore_hidden_files);

        LibSync.ConfigFile.set_up_default_exclude_file_paths (this.engine.excluded_files ());
        if (!reload_excludes ()) {
            GLib.warning ();
        }

        this.account_state.signal_is_connected_changed.connect (
            this.on_signal_can_sync_changed
        );
        this.engine.signal_etag_retrieved_from_sync_engine.connect (
            this.on_signal_etag_retrieved_from_sync_engine
        );
        this.engine.signa_sync_started.connect (
            this.on_signal_sync_started // GLib.QueuedConnection
        );
        this.engine.signal_sync_finished.connect (
            this.on_signal_sync_finished // GLib.QueuedConnection
        );
        this.engine.signal_about_to_remove_all_files.connect (
            this.on_signal_about_to_remove_all_files
        );
        this.engine.signal_transmission_progress.connect (
            this.on_signal_transmission_progress
        );
        this.engine.signal_item_completed.connect (
            this.on_signal_item_completed
        );
        this.engine.signal_new_big_folder.connect (
            this.on_signal_new_big_folder_discovered
        );
        this.engine.signal_about_to_propagate.connect (
            this.on_signal_log_propagation_start
        );
        this.engine.signal_sync_error.connect (
            this.on_signal_sync_error
        );
        this.engine.signal_add_error_to_gui.connect (
            this.on_signal_add_error_to_gui
        );
        GLib.Timeout.single_shot (
            LibSync.SyncEngine.minimum_file_age_for_upload,
            this.on_signal_schedule_this_folder
        );
        ProgressDispatcher.instance.signal_folder_conflicts.connect (
            this.on_signal_folder_conflicts
        );
        this.local_discovery_tracker.reset (
            new LocalDiscoveryTracker ()
        );
        this.engine.signal_finished.connect (
            this.local_discovery_tracker.on_signal_sync_finished
        );
        this.engine.signal_item_completed.connect (
            this.local_discovery_tracker.on_signal_item_completed
        );

        // Potentially upgrade suffix vfs to windows vfs
        //  ENFORCE (this.vfs);
        if (this.definition.virtual_files_mode == Common.AbstractVfs.WithSuffix
            && this.definition.upgrade_vfs_mode) {
            if (is_vfs_plugin_available (Common.AbstractVfs.WindowsCfApi)) {
                var winvfs = create_vfs_from_plugin (Common.AbstractVfs.WindowsCfApi);
                if (winvfs) {
                    // Wipe the existing suffix files from fs and journal_database
                    LibSync.SyncEngine.wipe_virtual_files (path, this.journal_database, this.vfs);

                    // Then switch to winvfs mode
                    this.vfs.reset (winvfs.release ());
                    this.definition.virtual_files_mode = Common.AbstractVfs.WindowsCfApi;
                }
            }
            save_to_settings ();
        }

        // Initialize the vfs plugin
        start_vfs ();
    }


    ~FolderConnection () {
        // If wipe_for_removal () was called the vfs has already shut down.
        if (this.vfs != null) {
            this.vfs.stop ();
        }

        // Reset then engine first as it will abort and try to access members of the FolderConnection
        this.engine.reset ();
    }


    /***********************************************************
    The account the folder_connection is configured on.
    ***********************************************************/
    private void start_vfs () {
        //  ENFORCE (this.vfs);
        //  ENFORCE (this.vfs.mode () == this.definition.virtual_files_mode);

        Common.SetupParameters vfs_params;
        vfs_params.filesystem_path = this.path;
        vfs_params.display_name = short_gui_remote_path_or_app_name ();
        vfs_params.alias = alias ();
        vfs_params.remote_path = remote_path_trailing_slash;
        vfs_params.account = this.account_state.account;
        vfs_params.journal_database = this.journal_database;
        vfs_params.provider_name = LibSync.Theme.app_name_gui;
        vfs_params.provider_version = LibSync.Theme.version;
        vfs_params.multiple_accounts_registered = AccountManager.instance.accounts.size () > 1;

        this.vfs.signal_begin_hydrating.connect (
            this.on_signal_hydration_starts
        );
        this.vfs.signal_done_hydrating.connect (
            this.on_signal_hydration_done
        );

        this.engine.sync_file_status_tracker.signal_file_status_changed.connect (
            this.vfs.on_signal_file_status_changed
        );

        this.vfs.on_signal_start (vfs_params);

        // Immediately mark the sqlite temporaries as excluded. They get recreated
        // on database-open and need to get marked again every time.
        string state_database_file = this.journal_database.database_file_path;
        this.journal_database.open ();
        this.vfs.on_signal_file_status_changed (state_database_file + "-wal", SyncFileStatus.SyncFileStatusTag.STATUS_EXCLUDED);
        this.vfs.on_signal_file_status_changed (state_database_file + "-shm", SyncFileStatus.SyncFileStatusTag.STATUS_EXCLUDED);
    }


    /***********************************************************
    Alias or nickname
    ***********************************************************/
    public string alias () {
        return this.definition.alias;
    }


    /***********************************************************
    Since 2.0 we don't want to show aliases anymore, show the
    path instead
    ***********************************************************/
    public string short_gui_remote_path_or_app_name () {
        if (this.remote_path.length > 0 && this.remote_path != "/") {
            string a = new GLib.File (this.remote_path).filename ();
            if (a.has_prefix ("/")) {
                a = a.remove (0, 1);
            }
            return a;
        } else {
            return LibSync.Theme.app_name_gui;
        }
    }


    /***********************************************************
    Short local path to display on the GUI (native separators)
    ***********************************************************/
    public string short_gui_local_path {
        string p = this.definition.local_path;
        string home = GLib.Dir.home_path;
        if (!home.has_suffix ("/")) {
            home.append ("/");
        }
        if (p.has_prefix (home)) {
            p = p.mid (home.length);
        }
        if (p.length > 1 && p.has_suffix ("/")) {
            p.chop (1);
        }
        return GLib.Dir.to_native_separators (p);
    }


    /***********************************************************
    Canonical local folder_connection path, always ends with "/"
    ***********************************************************/
    public string this.path {
        return this.canonical_local_path;
    }


    /***********************************************************
    Cleaned canonical folder_connection path, like this.path but never ends
    with a "/".

    Wrapper for GLib.Dir.clean_path (path) except for "Z:/",
    where it returns "Z:" instead of "Z:/".
    ***********************************************************/
    public string clean_path {
        public get {
            string cleaned_path = GLib.Dir.clean_path (this.canonical_local_path);

            if (cleaned_path.length == 3 && cleaned_path.has_suffix (":/")) {
                cleaned_path.remove (2, 1);
            }

            return cleaned_path;
        }
    }


    /***********************************************************
    Remote folder_connection path, usually without trailing "/", exception "/"
    ***********************************************************/
    public string remote_path {
        public get {
            return this.definition.target_path;
        }
    }


    /***********************************************************
    Remote folder_connection path, always with a trailing "/"
    ***********************************************************/
    public string remote_path_trailing_slash {
        public get {
            string result = remote_path;
            if (!result.has_suffix ("/")) {
                result += "/";
            }
            return result;
        }
    }


    /***********************************************************
    Remote folder_connection path with server url
    ***********************************************************/
    public GLib.Uri remote_url () {
        return Utility.concat_url_path (this.account_state.account.dav_url (), remote_path);
    }


    /***********************************************************
    Returns true when the folder_connection may sync.
    ***********************************************************/
    public bool can_sync () {
        return !sync_paused && account_state.is_connected;
    }


    /***********************************************************
    ***********************************************************/
    public void prepare_to_sync () {
        this.sync_result.reset ();
        this.sync_result.status (LibSync.SyncResult.Status.NOT_YET_STARTED);
    }


    /***********************************************************
    True if the folder_connection is busy and can't initiate a
    synchronization
    ***********************************************************/
    public virtual bool is_busy () {
        return is_sync_running ();
    }


    /***********************************************************
    True if the folder_connection is currently synchronizing
    ***********************************************************/
    public bool is_sync_running () {
        return this.engine.is_sync_running () || (this.vfs != null && this.vfs.is_hydrating ());
    }


    /***********************************************************
    This is called when the sync folder_connection definition is removed.
    Do cleanups here.

    It removes the database, among other things.

    The folder_connection is not in a valid state afterwards!
    ***********************************************************/
    public virtual void wipe_for_removal () {
        // Delete files that have been partially downloaded.
        on_signal_discard_download_progress ();

        // Unregister the socket API so it does not keep the .sync_journal file open
        FolderManager.instance.socket_api.on_signal_unregister_path (alias ());
        this.journal_database.close (); // close the sync journal_database

        // Remove database and temporaries
        string state_database_file = this.engine.journal_database.database_file_path;

        GLib.File file = GLib.File.new_for_path (state_database_file);
        if (file.exists ()) {
            if (!file.remove ()) {
                GLib.warning ("Failed to remove existing csync state database " + state_database_file);
            } else {
                GLib.info ("Wipe: Removed csync state database " + state_database_file);
            }
        } else {
            GLib.warning ("State database is empty; cannot remove.");
        }

        // Also remove other database related files
        GLib.File.remove (state_database_file + ".ctemporary");
        GLib.File.remove (state_database_file + "-shm");
        GLib.File.remove (state_database_file + "-wal");
        GLib.File.remove (state_database_file + "-journal");

        this.vfs.stop ();
        this.vfs.unregister_folder ();
        this.vfs.reset (null); // warning : folder_connection now in an invalid state
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_associated_account_removed () {
        if (this.vfs != null) {
            this.vfs.stop ();
            this.vfs.unregister_folder ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void sync_state (LibSync.SyncResult.Status state) {
        this.sync_result.status (state);
    }


    /***********************************************************
    ***********************************************************/
    public void dirty_network_limits () {
        LibSync.ConfigFile config;
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


    /***********************************************************
    Ignore syncing of hidden files or not. This is defined in the
    folder_connection definition
    ***********************************************************/
    bool ignore_hidden_files {
        public get {
            return this.definition.ignore_hidden_files;
        }
        public set {
            this.definition.ignore_hidden_files = value;
        }
    }


    /***********************************************************
    ***********************************************************/
    public LibSync.SyncEngine sync_engine {
        return;
    }


    /***********************************************************
    ***********************************************************/
    public RequestEtagJob etag_job () {
        return this.request_etag_job;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.TimeSpan microseconds_since_last_sync () { }


    /***********************************************************
    Saves the folder_connection data in the account's settings.
    ***********************************************************/
    public void save_to_settings () {
        // Remove first to make sure we don't get duplicates
        remove_from_settings ();

        var settings = this.account_state.settings ();
        string settings_group = "Multifolders";

        // True if the folder_connection path appears in only one account
        int accounts = 1;
        foreach (var FolderConnection in FolderManager.instance.map ()){
            if (other != this && other.clean_path == this.clean_path) {
                accounts++;
            }
        }

        if (this.virtual_files_enabled || this.save_in_folders_with_placeholders) {
            // If virtual files are enabled or even were enabled at some point,
            // save the folder_connection to a group that will not be read by older (<2.5.0) clients.
            // The name is from when virtual files were called placeholders.
            settings_group = "FoldersWithPlaceholders";
        } else if (this.save_backwards_compatible || accounts == 1) {
            // The folder_connection is saved to backwards-compatible "Folders"
            // section only if it has the migrate flag set (i.e. was in
            // there before) or if the folder_connection is the only one for the
            // given target path.
            // This ensures that older clients will not read a configuration
            // where two folders for different accounts point at the same
            // local folders.
            settings_group = "Folders";
        }

        settings.begin_group (settings_group);
        // Note: Each of these groups might have a "version" tag, but that's
        //       currently unused.
        settings.begin_group (FolderManager.escape_alias (this.definition.alias));
        FolderDefinition.save (settings, this.definition);

        settings.sync ();
        GLib.info ("Saved folder_connection " + this.definition.alias +  "to settings, status " + settings.status ());
    }


    /***********************************************************
    Removes the folder_connection from the account's settings.
    ***********************************************************/
    public void remove_from_settings () {
        var settings = this.account_state.settings ();
        settings.begin_group ("Folders");
        settings.remove (FolderManager.escape_alias (this.definition.alias));
        settings.end_group ();
        settings.begin_group ("Multifolders");
        settings.remove (FolderManager.escape_alias (this.definition.alias));
        settings.end_group ();
        settings.begin_group ("FoldersWithPlaceholders");
        settings.remove (FolderManager.escape_alias (this.definition.alias));
    }


    /***********************************************************
    Returns whether a file inside this folder_connection should be excluded.
    ***********************************************************/
    public bool is_file_excluded_absolute (string full_path) {
        return this.engine.excluded_files ().is_excluded (full_path, this.path, this.definition.ignore_hidden_files);
    }


    /***********************************************************
    Returns whether a file inside this folder_connection should be excluded.
    ***********************************************************/
    public bool is_file_excluded_relative (string relative_path) {
        return this.engine.excluded_files ().is_excluded (path + relative_path, this.path, this.definition.ignore_hidden_files);
    }


    /***********************************************************
    Calls schedules this folder_connection on the FolderManager after a short
    delay.

    This should be used in situations where a sync should be
    triggered because a local file was modified. Syncs don't
    upload files that were modified too recently, and this delay
    ensures the modification is far enough in the past.

    The delay doesn't reset with subsequent calls.
    ***********************************************************/
    public void schedule_this_folder_soon () {
        //  if (!this.schedule_self_timer.is_active ()) {
        //      this.schedule_self_timer.on_signal_start ();
        //  }
    }


    /***********************************************************
    Sets up this folder_connection's folder_watcher if possible.

    May be called several times.
    ***********************************************************/
    public void register_folder_watcher () {
        if (this.folder_watcher != null) {
            return;
        }
        if (!new GLib.Dir (path).exists ()) {
            return;
        }

        this.folder_watcher.reset (new FolderWatcher (this));
        this.folder_watcher.signal_path_changed.connect (
            this.on_signal_path_changed
        );
        this.folder_watcher.signal_lost_changes.connect (
            this.on_signal_next_sync_full_local_discovery
        );
        this.folder_watcher.signal_became_unreliable.connect (
            this.on_signal_watcher_unreliable
        );
        this.folder_watcher.init (path);
        this.folder_watcher.start_notificaton_test (path + ".owncloudsync.log");
    }


    private void on_signal_path_changed (string path) {
        on_signal_watched_path_changed (path, FolderConnection.ChangeReason.ChangeReason.OTHER);
    }


    /***********************************************************
    ***********************************************************/
    public void root_pin_state (PinState state) {
        if (!this.vfs.pin_state ("", state)) {
            GLib.warning ("Could not set root pin state of " + this.definition.alias);
        }

        // We don't actually need discovery, but it's important to recurse
        // into all folders, so the changes can be applied.
        on_signal_next_sync_full_local_discovery ();
    }


    /***********************************************************
    Whether user desires a switch that couldn't be executed yet,
    see member
    ***********************************************************/
    public bool is_vfs_on_signal_off_switch_pending () {
        return this.vfs_on_signal_off_pending;
    }


    /***********************************************************
    ***********************************************************/
    public void vfs_on_signal_off_switch_pending (bool pending) {
        this.vfs_on_signal_off_pending = pending;
    }


    /***********************************************************
    ***********************************************************/
    public void switch_to_virtual_files () {
        LibSync.SyncEngine.switch_to_virtual_files (path, this.journal_database, this.vfs);
        this.has_switched_to_vfs = true;
    }


    /***********************************************************
    ***********************************************************/
    public void process_switched_to_virtual_files () {
        if (this.has_switched_to_vfs) {
            this.has_switched_to_vfs = false;
            save_to_settings ();
        }
    }


    /***********************************************************
    Whether this folder_connection should show selective sync instance
    ***********************************************************/
    public bool supports_selective_sync {
        public get {
            return !this.virtual_files_enabled && !is_vfs_on_signal_off_switch_pending ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public string file_from_local_path (string local_path) {
        return local_path.mid (clean_path.length + 1);
    }


    internal signal void signal_sync_state_change ();
    internal signal void signal_sync_started ();
    internal signal void signal_sync_finished (LibSync.SyncResult result);
    internal signal void signal_progress_info (ProgressInfo progress);
    /***********************************************************
    A new folder bigger than the threshold was discovered
    ***********************************************************/
    internal signal void signal_new_big_folder_discovered (string value);
    internal signal void signal_sync_paused_changed (FolderConnection folder_connection, bool paused);
    internal signal void signal_can_sync_changed ();
    /***********************************************************
    Fires for each change inside this folder that wasn't caused
    by sync activity.
    ***********************************************************/
    internal signal void signal_watched_file_changed_externally (string path);


    /***********************************************************
    Terminate the current sync run
    ***********************************************************/
    public void on_signal_terminate_sync () {
        GLib.info ("FolderConnection " + this.alias () + " terminating!");

        if (this.engine.is_sync_running ()) {
            this.engine.on_signal_abort ();

            sync_state (LibSync.SyncResult.Status.SYNC_ABORT_REQUESTED);
        }
    }


    private delegate void Callback (bool value);


    /***********************************************************
    Connected to the corresponding signals in the LibSync.SyncEngine
    ***********************************************************/
    public void on_signal_about_to_remove_all_files (LibSync.LibSync.SyncFileItem.Direction directory, Callback callback) {
        LibSync.ConfigFile config_file;
        if (!LibSync.ConfigFile.prompt_delete_files ()) {
            callback (false);
            return;
        }

        string message = directory == LibSync.LibSync.SyncFileItem.Direction.DOWN
            ? _("All files in the sync folder_connection \"%1\" folder_connection were deleted on the server.\n"
              + "These deletes will be synchronized to your local sync folder_connection, making such files "
              + "unavailable unless you have a right to restore. \n"
              + "If you decide to restore the files, they will be re-synced with the server if you have rights to do so.\n"
              + "If you decide to delete the files, they will be unavailable to you, unless you are the owner.")
            : _("All the files in your local sync folder_connection \"%1\" were deleted. These deletes will be "
              + "synchronized with your server, making such files unavailable unless restored.\n"
              + "Are you sure you want to sync those actions with the server?\n"
              + "If this was an accident and you decide to keep your files, they will be re-synced from the server.");
        var message_box = new Gtk.MessageBox (
            Gtk.MessageBox.Warning, _("Remove All Files?"),
            message.printf (short_gui_local_path),
            Gtk.MessageBox.NoButton
        );
        message_box.attribute (GLib.WA_DeleteOnClose);
        message_box.window_flags (message_box.window_flags () | GLib.Window_stays_on_signal_top_hint);
        message_box.add_button (_("Remove all files"), Gtk.MessageBox.DestructiveRole);
        GLib.PushButton keep_button = message_box.add_button (_("Keep files"), Gtk.MessageBox.AcceptRole);
        bool old_paused = sync_paused;
        this.sync_paused = true;
        message_box.signal_finished.connect (
            this.on_signal_message_box_finished
        );
        this.destroyed.connect (
            message_box.delete_later
        );
        message_box.open ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_message_box_finished (Gtk.MessageBox message_box, GLib.PushButton keep_button, Callback callback, bool old_paused) {
        bool cancel = message_box.clicked_button () == keep_button;
        callback (cancel);
        if (cancel) {
            FileSystem.folder_minimum_permissions (path);
            journal_database.clear_file_table ();
            this.last_etag = "";
            on_signal_schedule_this_folder ();
        }
        this.sync_paused = old_paused;
    }


    /***********************************************************
    Starts a sync operation

    If the list of changed files is known, it is passed.
    ***********************************************************/
    public void on_signal_start_sync (GLib.List<string> path_list = new GLib.List<string> ()) {
        //  Q_UNUSED (path_list)

        if (is_busy ()) {
            GLib.critical ("ERROR csync is still running and new sync requested.");
            return;
        }

        this.time_since_last_sync_start.on_signal_start ();
        this.sync_result.status (LibSync.SyncResult.Status.SYNC_PREPARE);
        signal_sync_state_change ();

        GLib.info (
            "*** Start syncing " + remote_url ().to_string ()
            + " -" + Common.Config.APPLICATION_NAME + "client version"
            + LibSync.Theme.version.to_string ()
        );

        this.file_log.on_signal_start (path);

        if (!reload_excludes ()) {
            on_signal_sync_error (_("Could not read system exclude file"));
            GLib.Object.invoke_method (this, "on_signal_sync_finished", GLib.QueuedConnection, Q_ARG (bool, false));
            return;
        }

        dirty_network_limits ();
        sync_options ();

        bool has_done_full_local_discovery = this.time_since_last_full_local_discovery.is_valid;
        bool periodic_full_local_discovery_now =
            full_local_discovery_interval.length >= 0 // negative means we don't require periodic full runs
            && this.time_since_last_full_local_discovery.has_expired (full_local_discovery_interval.length);
        if (this.folder_watcher != null && this.folder_watcher.is_reliable
            && has_done_full_local_discovery
            && !periodic_full_local_discovery_now) {
            GLib.info ("Allowing local discovery to read from the database.");
            this.engine.local_discovery_options (
                LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM,
                this.local_discovery_tracker.local_discovery_paths ());
            this.local_discovery_tracker.start_sync_partial_discovery ();
        } else {
            GLib.info ("Forbidding local discovery to read from the database.");
            this.engine.local_discovery_options (LocalDiscoveryStyle.FILESYSTEM_ONLY);
            this.local_discovery_tracker.start_sync_full_discovery ();
        }

        this.engine.ignore_hidden_files (this.definition.ignore_hidden_files);

        correct_placeholder_files ();

        GLib.Object.invoke_method (this.engine, "on_signal_start_sync", GLib.QueuedConnection);

        signal_sync_started ();
    }



    /***********************************************************
    Maybe multiply times 1000?
    ***********************************************************/
    private static GLib.TimeSpan full_local_discovery_interval () {
        var interval = LibSync.ConfigFile ().full_local_discovery_interval ();
        string env = qgetenv ("OWNCLOUD_FULL_LOCAL_DISCOVERY_INTERVAL");
        if (!env == "") {
            interval = env.to_long_long ();
        }
        return interval;
    }


    /***********************************************************
    ***********************************************************/
    private void correct_placeholder_files () {
        if (this.definition.virtual_files_mode == Common.AbstractVfs.Off) {
            return;
        }
        string placeholders_corrected_key = "placeholders_corrected";
        int placeholders_corrected = this.journal_database.key_value_store_get_int (placeholders_corrected_key, 0);
        if (!placeholders_corrected) {
            GLib.debug ("Make sure all virtual files are placeholder files.");
            switch_to_virtual_files ();
            this.journal_database.key_value_store_set (placeholders_corrected_key, true);
        }
    }


    /***********************************************************
    ***********************************************************/
    public int on_signal_discard_download_progress () {
        // Delete from journal_database and from filesystem.
        GLib.Dir folderpath = new GLib.Dir (this.definition.local_path);
        GLib.List<string> keep_nothing;
        GLib.List<Common.SyncJournalDb.DownloadInfo> deleted_infos =
            this.journal_database.and_delete_stale_download_infos (keep_nothing);
        foreach (var deleted_info in deleted_infos) {
            string temporary_path = folderpath.file_path (deleted_info.temporaryfile);
            GLib.info ("Deleting temporary file: " + temporary_path);
            FileSystem.remove (temporary_path);
        }
        return deleted_infos.size ();
    }


    /***********************************************************
    ***********************************************************/
    public int on_signal_download_info_count () {
        return this.journal_database.on_signal_download_info_count ();
    }


    /***********************************************************
    ***********************************************************/
    public int on_signal_wipe_error_blocklist () {
        return this.journal_database.wipe_error_blocklist ();
    }


    /***********************************************************
    ***********************************************************/
    public int on_signal_error_block_list_entry_count () {
        return this.journal_database.on_signal_error_block_list_entry_count ();
    }


    /***********************************************************
    Triggered by the folder_connection watcher when a file/directory in this
    folder_connection changes. Needs to check whether this change should
    trigger a new sync run to be scheduled.
    ***********************************************************/
    public void on_signal_watched_path_changed (string path, ChangeReason reason) {
        if (!path.has_prefix (this.path)) {
            GLib.debug ("Changed path is not contained in folder_connection, ignoring: " + path);
            return;
        }

        var relative_path = path.mid_ref (this.path.size ());

        // Add to list of locally modified paths
        //  
        // We do this before checking for our own sync-related changes to make
        // extra sure to not miss relevant changes.
        var relative_path_bytes = relative_path.to_utf8 ();
        this.local_discovery_tracker.add_touched_path (relative_path_bytes);

        // The folder_connection watcher fires a lot of bogus notifications during
        // a sync operation, both for actual user files and the database
        // and log. Therefore we check notifications against operations
        // the sync is doing to filter out our own changes.

        // Use the path to figure out whether it was our own change
        if (this.engine.was_file_touched (path)) {
            GLib.debug ("Changed path was touched by LibSync.SyncEngine, ignoring: " + path);
            return;
        }


        SyncJournalFileRecord record;
        this.journal_database.file_record (relative_path_bytes, record);
        if (reason != ChangeReason.ChangeReason.UNLOCK) {
            // Check that the mtime/size actually changed or there was
            // an attribute change (pin state) that caused the notification
            bool spurious = false;
            if (record.is_valid
                && !FileSystem.file_changed (path, record.file_size, record.modtime)) {
                spurious = true;

                var pin_state = this.vfs.pin_state (relative_path.to_string ());
                if (pin_state) {
                    if (pin_state == PinState.ALWAYS_LOCAL && record.is_virtual_file ()) {
                        spurious = false;
                    }
                    if (pin_state == Common.ItemAvailability.ONLINE_ONLY && record.is_file ()) {
                        spurious = false;
                    }
                }
            }
            if (spurious) {
                GLib.info ("Ignoring spurious notification for file " + relative_path);
                return; // probably a spurious notification
            }
        }
        on_signal_warn_on_signal_new_excluded_item (record, relative_path);

        signal_watched_file_changed_externally (path);

        // Also schedule this folder_connection for a sync, but only after some delay:
        // The sync will not upload files that were changed too recently.
        schedule_this_folder_soon ();
    }


    /***********************************************************
    Mark a virtual file as being requested for download, and
    start a sync.

    "implicit" here means that this download request comes from
    the user wan to access the file's data. The user did not
    change the file's pin state. If the file is currently
    Common.ItemAvailability.ONLINE_ONLY its state will change to
    Unspecif

    The download re (...) in the database. This is necessary
    since the hydration is not driven by the pin state.

    relative_path is the folder_connection-relative path to the file
    (including the extension)

    Note, passing directories is not supported. Files only.
    ***********************************************************/
    public void on_signal_implicitly_hydrate_file (string relative_path) {
        GLib.info ("Implicitly hydrate virtual file: " + relative_path);

        // Set in the database that we should download the file
        SyncJournalFileRecord record;
        this.journal_database.file_record (relative_path.to_utf8 (), record);
        if (!record.is_valid) {
            GLib.info ("Did not find file in database.");
            return;
        }
        if (!record.is_virtual_file ()) {
            GLib.info ("The file is not virtual.");
            return;
        }
        record.type = ItemType.VIRTUAL_FILE_DOWNLOAD;
        this.journal_database.file_record (record);

        // Change the file's pin state if it's contradictory to being hydrated
        // (suffix-virtual file's pin state is stored at the hydrated path)
        var pin = this.vfs.pin_state (relative_path);
        if (pin && *pin == Common.ItemAvailability.ONLINE_ONLY) {
            if (!this.vfs.pin_state (relative_path, PinState.UNSPECIFIED)) {
                GLib.warning ("Could not set pin state of " + relative_path + " to unspecified.");
            }
        }

        // Add to local discovery
        on_signal_schedule_path_for_local_discovery (relative_path);
        on_signal_schedule_this_folder ();
    }


    /***********************************************************
    Adds the path to the local discovery list

    A weaker version of on_signal_next_sync_full_local_discovery ()
    that just schedules all parent and child items of the path
    for local discovery.
    ***********************************************************/
    public void on_signal_schedule_path_for_local_discovery (string relative_path) {
        this.local_discovery_tracker.add_touched_path (relative_path.to_utf8 ());
    }


    /***********************************************************
    Ensures that the next sync performs a full local discovery.
    ***********************************************************/
    public void on_signal_next_sync_full_local_discovery () {
        this.time_since_last_full_local_discovery.invalidate ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sync_started () {
        GLib.info ("#### Propagation on_signal_start ####################################################");
        this.sync_result.status (LibSync.SyncResult.Status.SYNC_RUNNING);
        signal_sync_state_change ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sync_finished (bool success) {
        GLib.info (
            "Client version" + LibSync.Theme.version.to_string ()
            + " Qt " + q_version ()
            + " SSL " + GLib.SslSocket.ssl_library_version_string ().to_utf8 ()
        );

        bool sync_error = !this.sync_result.error_strings () = "";
        if (sync_error) {
            GLib.warning ("LibSync.SyncEngine finished with ERROR.");
        } else {
            GLib.info ("LibSync.SyncEngine finished without problem.");
        }
        this.file_log.finish ();
        show_sync_result_popup ();

        var another_sync_needed = this.engine.is_another_sync_needed ();

        if (sync_error) {
            this.sync_result.status (LibSync.SyncResult.Status.ERROR);
        } else if (this.sync_result.found_files_not_synced ()) {
            this.sync_result.status (LibSync.SyncResult.Status.PROBLEM);
        } else if (this.definition.paused) {
            // Maybe the sync was terminated because the user paused the folder_connection
            this.sync_result.status (LibSync.SyncResult.Status.PAUSED);
        } else {
            this.sync_result.status (LibSync.SyncResult.Status.SUCCESS);
        }

        // Count the number of syncs that have failed in a row.
        if (this.sync_result.status () == LibSync.SyncResult.Status.SUCCESS
            || this.sync_result.status () == LibSync.SyncResult.Status.PROBLEM) {
            this.consecutive_failing_syncs = 0;
        } else {
            this.consecutive_failing_syncs++;
            GLib.info ("The last " + this.consecutive_failing_syncs.to_string () + " syncs failed.");
        }

        if (this.sync_result.status () == LibSync.SyncResult.Status.SUCCESS && success) {
            // Clear the allow list as all the folders that should be on that list are sync-ed
            journal_database.selective_sync_list (Common.SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST, {});
        }

        if ((this.sync_result.status () == LibSync.SyncResult.Status.SUCCESS
            || this.sync_result.status () == LibSync.SyncResult.Status.PROBLEM)
            && success) {
            if (this.engine.last_local_discovery_style () == LocalDiscoveryStyle.FILESYSTEM_ONLY) {
                this.time_since_last_full_local_discovery.on_signal_start ();
            }
        }

        signal_sync_state_change ();

        // The signal_sync_finished result that is to be triggered here makes the folderman
        // clear the current running sync folder_connection marker.
        // Lets wait a bit to do that because, as long as this marker is not cleared,
        // file system change notifications are ignored for that folder_connection. And it takes
        // some time under certain conditions to make the file system notifications
        // all come in.
        GLib.Timeout.add (200, this.on_signal_emit_finished_delayed);

        this.last_sync_duration = std.chrono.milliseconds (this.time_since_last_sync_start.elapsed ());
        this.time_since_last_sync_done.on_signal_start ();

        // Increment the follow-up sync counter if necessary.
        if (another_sync_needed == AnotherSyncNeeded.IMMEDIATE_FOLLOW_UP) {
            this.consecutive_follow_up_syncs++;
            GLib.info ("Another sync was requested by the finished sync. This has happened "
                + this.consecutive_follow_up_syncs.to_string () + " times.");
        } else {
            this.consecutive_follow_up_syncs = 0;
        }

        // Maybe force a follow-up sync to take place, but only a couple of times.
        if (another_sync_needed == AnotherSyncNeeded.IMMEDIATE_FOLLOW_UP && this.consecutive_follow_up_syncs <= 3) {
            // Sometimes another sync is requested because a local file is still
            // changing, so wait at least a small amount of time before syncing
            // the folder_connection again.
            schedule_this_folder_soon ();
        }
    }


    /***********************************************************
    Adds a error message that's not tied to a specific item.
    ***********************************************************/
    private void on_signal_sync_error (string message, ErrorCategory category = ErrorCategory.NORMAL) {
        this.sync_result.append_error_string (message);
        ProgressDispatcher.instance.signal_sync_erroralias (), message, category);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_add_error_to_gui (LibSync.LibSync.SyncFileItem.Status status, string error_message, string subject = "") {
        ProgressDispatcher.instance.signal_add_error_to_gui (alias (), status, error_message, subject);
    }


    /***********************************************************
    // the progress comes without a folder_connection and the valid path set. Add that here
    // and hand the result over to the progress dispatcher.
    ***********************************************************/
    private void on_signal_transmission_progress (ProgressInfo progress_info) {
        signal_progress_info (progress_info);
        ProgressDispatcher.instance.signal_progress_info (alias (), progress_info);
    }


    /***********************************************************
    A item is completed. Count the errors and forward to the
    ProgressDispatcher
    ***********************************************************/
    private void on_signal_item_completed (LibSync.SyncFileItem item) {
        if (item.instruction == CSync.SyncInstructions.NONE || item.instruction == CSync.SyncInstructions.UPDATE_METADATA) {
            // We only care about the updates that deserve to be shown in the UI
            return;
        }

        this.sync_result.process_completed_item (item);

        this.file_log.log_item (item);
        ProgressDispatcher.instance.signal_item_completed (alias (), item);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_run_etag_job () {
        GLib.info ("Trying to check " + remote_url ().to_string () + " for changes via ETag check. (time since last sync: " + (this.time_since_last_sync_done.elapsed () / 1000).to_string () + "s)");

        LibSync.Account account = this.account_state.account;

        if (this.request_etag_job != null) {
            GLib.info (remote_url ().to_string () + " has ETag job queued, not trying to sync");
            return;
        }

        if (!can_sync ()) {
            GLib.info ("Not syncing: " + remote_url ().to_string () + this.definition.paused + AccountState.state_string (this.account_state.state));
            return;
        }

        // Do the ordinary etag check for the root folder_connection and schedule a
        // sync if it's different.

        this.request_etag_job = new RequestEtagJob (account, remote_path, this);
        this.request_etag_job.on_signal_timeout (60 * 1000);
        // check if the etag is different when retrieved
        this.request_etag_job.signal_etag_retrieved.connect (
            this.on_signal_etag_retrieved
        );
        FolderManager.instance.on_signal_schedule_e_tag_job (alias (), this.request_etag_job);
        // The this.request_etag_job is var deleting itself on finish. Our guard pointer this.request_etag_job will then be null.
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_etag_retrieved (string value1, GLib.DateTime tp) {
        // re-enable sync if it was disabled because network was down
        FolderManager.instance.sync_enabled = true;

        if (this.last_etag != etag) {
            GLib.info ("Compare etag with previous etag: last: " + this.last_etag + ", received: " + etag + ". CHANGED");
            this.last_etag = etag;
            on_signal_schedule_this_folder ();
        }

        this.account_state.tag_last_successful_etag_request (tp);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_etag_retrieved_from_sync_engine (string etag, GLib.DateTime time) {
        GLib.info ("Root etag from during sync: " + etag);
        account_state.tag_last_successful_etag_request (time);
        this.last_etag = etag;
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_emit_finished_delayed () {
        signal_sync_finished (this.sync_result);

        // Immediately check the etag again if there was some sync activity.
        if ((this.sync_result.status () == LibSync.SyncResult.Status.SUCCESS
            || this.sync_result.status () == LibSync.SyncResult.Status.PROBLEM)
            && (this.sync_result.first_item_deleted ()
                   || this.sync_result.first_item_new ()
                   || this.sync_result.first_item_renamed ()
                   || this.sync_result.first_item_updated ()
                   || this.sync_result.first_new_conflict_item ())) {
            on_signal_run_etag_job ();
        }
        return false; // only run once
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_new_big_folder_discovered (string new_folder, bool is_external) {
        var new_folder = new_folder;
        if (!new_folder.has_suffix ("/")) {
            new_folder += "/";
        }

        // Add the entry to the blocklist if it is neither in the blocklist or allowlist already
        bool ok1 = false;
        bool ok2 = false;
        var blocklist = journal_database.selective_sync_list (Common.SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok1);
        var allowlist = journal_database.selective_sync_list (Common.SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST, ok2);
        if (ok1 && ok2 && !blocklist.contains (new_folder) && !allowlist.contains (new_folder)) {
            blocklist.append (new_folder);
            journal_database.selective_sync_list (Common.SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, blocklist);
        }

        // And add the entry to the undecided list and signal the UI
        var undecided_list = journal_database.selective_sync_list (Common.SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_UNDECIDEDLIST, ok1);
        if (ok1) {
            if (!undecided_list.contains (new_folder)) {
                undecided_list.append (new_folder);
                journal_database.selective_sync_list (Common.SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_UNDECIDEDLIST, undecided_list);
                signal_new_big_folder_discovered (new_folder);
            }
            string message = !is_external ? (_("A new folder_connection larger than %1 MB has been added : %2.\n")
                                                    .printf (LibSync.ConfigFile ().new_big_folder_size_limit.second)
                                                    .printf (new_folder))
                                          : (_("A folder_connection from an external storage has been added.\n"));
            message += _("Please go in the settings to select it if you wish to download it.");

            var logger = LibSync.Logger.instance;
            logger.post_optional_gui_log (LibSync.Theme.app_name_gui, message);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_log_propagation_start () {
        this.file_log.log_lap ("Propagation starts");
    }



    /***********************************************************
    Adds this folder_connection to the list of scheduled folders in the
    FolderManager.
    ***********************************************************/
    private bool on_signal_schedule_this_folder () {
        FolderManager.instance.schedule_folder (this);
        return false; // only run once
    }


    /***********************************************************
    Adjust sync result based on conflict data from IssuesWidget.

    This is pretty awkward, but IssuesWidget just keeps better track
    of conflicts across partial local discovery.
    ***********************************************************/
    private void on_signal_folder_conflicts (string folder_connection, GLib.List<string> conflict_paths) {
        if (folder_connection != this.definition.alias) {
            return;
        }
        var r = this.sync_result;

        // If the number of conflicts is too low, adjust it upwards
        if (conflict_paths.size () > r.number_of_new_conflict_items () + r.number_of_old_conflict_items ())
            r.number_of_old_conflict_items (conflict_paths.size () - r.number_of_new_conflict_items ());
    }


    /***********************************************************
    Warn users if they create a file or folder_connection that is selective-sync excluded
    ***********************************************************/
    private void on_signal_warn_on_signal_new_excluded_item (SyncJournalFileRecord record, /* GLib.StringRef */ string path) {
        // Never warn for items in the database
        if (record.is_valid) {
            return;
        }

        // Don't warn for items that no longer exist.
        // Note: This assumes we're getting file watcher notifications
        // for folders only on creation and deletion - if we got a notification
        // on content change that would create spurious warnings.
        GLib.FileInfo file_info = new GLib.FileInfo (this.canonical_local_path + path);
        if (!file_info.exists ()) {
            return;
        }

        bool ok = false;
        var blocklist = this.journal_database.selective_sync_list (Common.SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok);
        if (!ok) {
            return;
        }
        if (!blocklist.contains (path + "/")) {
            return;
        }

        string message = file_info.is_dir ()
            ? _("The folder_connection %1 was created but was excluded from synchronization previously. "
                + "Data inside it will not be synchronized.")
                  .printf (file_info.file_path)
            : _("The file %1 was created but was excluded from synchronization previously. "
                + "It will not be synchronized.")
                  .printf (file_info.file_path);

        LibSync.Logger.post_optional_gui_log (LibSync.Theme.app_name_gui, message);
    }


    /***********************************************************
    Warn users about an unreliable folder_connection watcher
    ***********************************************************/
    private void on_signal_watcher_unreliable (string message) {
        GLib.warning ("FolderConnection watcher for " + this.path + " became unreliable: " + message);
        var full_message =
            _("Changes in synchronized folders could not be tracked reliably.\n"
            + "\n"
            + "This means that the synchronization client might not upload local changes "
            + "immediately and will instead only scan for local changes and upload them "
            + "occasionally (every two hours by default).\n"
            + "\n"
            + "%1"
            ).printf (message);
        LibSync.Logger.post_gui_log (LibSync.Theme.app_name_gui, full_message);
    }


    /***********************************************************
    Aborts any running sync and blocks it until hydration is on_signal_finished.

    Hydration circumvents the regular LibSync.SyncEngine and both mustn't be running
    at the same time.
    ***********************************************************/
    private void on_signal_hydration_starts () {
        // Abort any running full sync run and reschedule
        if (this.engine.is_sync_running ()) {
            on_signal_terminate_sync ();
            schedule_this_folder_soon ();
            // TODO: This sets the sync state to Abort_requested on done, we don't want that
        }

        // Let everyone know we're syncing
        this.sync_result.reset ();
        this.sync_result.status (LibSync.SyncResult.Status.SYNC_RUNNING);
        signal_sync_started ();
        signal_sync_state_change ();
    }


    /***********************************************************
    Unblocks normal sync operation
    ***********************************************************/
    private void on_signal_hydration_done () {
        // emit signal to update instance and reschedule normal syncs if necessary
        this.sync_result.status (LibSync.SyncResult.Status.SUCCESS);
        signal_sync_finished (this.sync_result);
        signal_sync_state_change ();
    }


    /***********************************************************
    ***********************************************************/
    private void connect_sync_root ();


    /***********************************************************
    ***********************************************************/
    private bool reload_excludes () {
        return this.engine.excluded_files ().on_signal_reload_exclude_files ();
    }


    /***********************************************************
    ***********************************************************/
    private void show_sync_result_popup () {
        if (this.sync_result.first_item_new ()) {
            create_gui_log (this.sync_result.first_item_new ().destination (), LogStatus.NEW, this.sync_result.number_of_new_items ());
        }
        if (this.sync_result.first_item_deleted ()) {
            create_gui_log (this.sync_result.first_item_deleted ().destination (), LogStatus.REMOVE, this.sync_result.number_of_removed_items ());
        }
        if (this.sync_result.first_item_updated ()) {
            create_gui_log (this.sync_result.first_item_updated ().destination (), LogStatus.UPDATED, this.sync_result.number_of_updated_items ());
        }

        if (this.sync_result.first_item_renamed ()) {
            LogStatus status = LogStatus.RENAME;
            // if the path changes it's rather a move
            GLib.Dir ren_target = new GLib.FileInfo (this.sync_result.first_item_renamed ().rename_target).directory ();
            GLib.Dir ren_source = new GLib.FileInfo (this.sync_result.first_item_renamed ().file).directory ();
            if (ren_target != ren_source) {
                status = LogStatus.MOVE;
            }
            create_gui_log (this.sync_result.first_item_renamed ().file, status,
                this.sync_result.number_of_renamed_items (), this.sync_result.first_item_renamed ().rename_target);
        }

        if (this.sync_result.first_new_conflict_item ()) {
            create_gui_log (this.sync_result.first_new_conflict_item ().destination (), LogStatus.CONFLICT, this.sync_result.number_of_new_conflict_items ());
        }
        int error_count = this.sync_result.number_of_error_items ();
        if (error_count > 0) {
            create_gui_log (this.sync_result.first_item_error ().file, LogStatus.ERROR, error_count);
        }

        int locked_count = this.sync_result.number_of_locked_items ();
        if (locked_count > 0) {
            create_gui_log (this.sync_result.first_item_locked ().file, LogStatus.FILE_LOCKED, locked_count);
        }

        GLib.info ("FolderConnection " + this.sync_result.folder_connection + " sync result: " + this.sync_result.status ());
    }


    /***********************************************************
    ***********************************************************/
    private void check_local_path {
        GLib.FileInfo file_info = new GLib.FileInfo (this.definition.local_path);
        this.canonical_local_path = file_info.canonical_file_path;
        if (this.canonical_local_path == "") {
            GLib.warning ("Broken symlink: " + this.definition.local_path);
            this.canonical_local_path = this.definition.local_path;
        } else if (!this.canonical_local_path.has_suffix ("/")) {
            this.canonical_local_path.append ("/");
        }

        if (file_info.is_dir () && file_info.is_readable ()) {
            GLib.debug ("Checked local path ok.");
        } else {
            // Check directory again
            if (!FileSystem.file_exists (this.definition.local_path, file_info)) {
                this.sync_result.append_error_string (_("Local folder_connection %1 does not exist.").printf (this.definition.local_path));
                this.sync_result.status (LibSync.SyncResult.Status.SETUP_ERROR);
            } else if (!file_info.is_dir ()) {
                this.sync_result.append_error_string (_("%1 should be a folder_connection but is not.").printf (this.definition.local_path));
                this.sync_result.status (LibSync.SyncResult.Status.SETUP_ERROR);
            } else if (!file_info.is_readable ()) {
                this.sync_result.append_error_string (_("%1 is not readable.").printf (this.definition.local_path));
                this.sync_result.status (LibSync.SyncResult.Status.SETUP_ERROR);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void sync_options () {
        LibSync.SyncOptions opt;
        LibSync.ConfigFile config_file;

        var new_folder_limit = LibSync.ConfigFile.new_big_folder_size_limit;
        opt.new_big_folder_size_limit = new_folder_limit.first ? new_folder_limit.second * 1000LL * 1000LL : -1; // convert from MB to B
        opt.confirm_external_storage = LibSync.ConfigFile.confirm_external_storage ();
        opt.move_files_to_trash = LibSync.ConfigFile.move_to_trash ();
        opt.vfs = this.vfs;
        opt.parallel_network_jobs = this.account_state.account.is_http2Supported () ? 20 : 6;

        opt.initial_chunk_size = LibSync.ConfigFile.chunk_size ();
        opt.min_chunk_size = LibSync.ConfigFile.min_chunk_size ();
        opt.max_chunk_size = LibSync.ConfigFile.max_chunk_size ();
        opt.target_chunk_upload_duration = LibSync.ConfigFile.target_chunk_upload_duration ();

        opt.fill_from_environment_variables ();
        opt.verify_chunk_sizes ();

        this.engine.sync_options (opt);
    }


    /***********************************************************
    ***********************************************************/
    private void create_gui_log (
        string filename, LogStatus status,
        int count, string rename_target) {
        if (count > 0) {
            LibSync.Logger logger = LibSync.Logger.instance;

            string file = GLib.Dir.to_native_separators (filename);
            string text;

            switch (status) {
            case LogStatus.REMOVE:
                if (count > 1) {
                    text = _("%1 and %n other file (s) have been removed.", "", count - 1).printf (file);
                } else {
                    text = _("%1 has been removed.", "%1 names a file.").printf (file);
                }
                break;
            case LogStatus.NEW:
                if (count > 1) {
                    text = _("%1 and %n other file (s) have been added.", "", count - 1).printf (file);
                } else {
                    text = _("%1 has been added.", "%1 names a file.").printf (file);
                }
                break;
            case LogStatus.UPDATED:
                if (count > 1) {
                    text = _("%1 and %n other file (s) have been updated.", "", count - 1).printf (file);
                } else {
                    text = _("%1 has been updated.", "%1 names a file.").printf (file);
                }
                break;
            case LogStatus.RENAME:
                if (count > 1) {
                    text = _("%1 has been renamed to %2 and %n other file (s) have been renamed.", "", count - 1).printf (file, rename_target);
                } else {
                    text = _("%1 has been renamed to %2.", "%1 and %2 name files.").printf (file, rename_target);
                }
                break;
            case LogStatus.MOVE:
                if (count > 1) {
                    text = _("%1 has been moved to %2 and %n other file (s) have been moved.", "", count - 1).printf (file, rename_target);
                } else {
                    text = _("%1 has been moved to %2.").printf (file, rename_target);
                }
                break;
            case LogStatus.CONFLICT:
                if (count > 1) {
                    text = _("%1 has and %n other file (s) have sync conflicts.", "", count - 1).printf (file);
                } else {
                    text = _("%1 has a sync conflict. Please check the conflict file!").printf (file);
                }
                break;
            case LogStatus.ERROR:
                if (count > 1) {
                    text = _("%1 and %n other file (s) could not be synced due to errors. See the log for details.", "", count - 1).printf (file);
                } else {
                    text = _("%1 could not be synced due to an error. See the log for details.").printf (file);
                }
                break;
            case LogStatus.FILE_LOCKED:
                if (count > 1) {
                    text = _("%1 and %n other file (s) are currently locked.", "", count -1).printf (file);
                } else {
                    text = _("%1 is currently locked.").printf (file);
                }
                break;
            }

            if (text != "") {
                // Ignores the settings in case of an error or conflict
                if (status == LogStatus.ERROR || status == LogStatus.CONFLICT) {
                    logger.post_optional_gui_log (_("Sync Activity"), text);
                }
            }
        }
    }

} // class FolderConnection

} // namespace Ui
} // namespace Occ
