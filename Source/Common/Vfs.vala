/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>
Copyright (C) by Dominik Schmidt <dschmidt@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QPluginLoader>
// #include <QLoggingCategory>
// #pragma once
// #include <QScopedPointer>
// #include <memory>

namespace Occ {

using csync_file_stat_t = struct csync_file_stat_s;
using AccountPointer = unowned<Account>;

/***********************************************************
Collection of parameters for initializing a Vfs instance.
OCSYNC_EXPORT
***********************************************************/
struct VfsSetupParams {
    /***********************************************************
    The full path to the folder on the local filesystem

    Always ends with /.
    ***********************************************************/
    string filesystem_path;


    /***********************************************************
    Folder display name in Windows Explorer
    ***********************************************************/
    string display_name;


    /***********************************************************
    Folder alias
    ***********************************************************/
    string alias;


    /***********************************************************
    The path to the synced folder on the account

    Always ends with /.
    ***********************************************************/
    string remote_path;


    /***********************************************************
    Account url, credentials etc for network calls
    ***********************************************************/
    AccountPointer account;


    /***********************************************************
    Access to the sync folder's database.

    Note: The journal must live at least until the Vfs.stop () call.
    ***********************************************************/
    SyncJournalDb journal = nullptr;


    /***********************************************************
    Strings potentially passed on to the platform
    ***********************************************************/
    string provider_name;


    /***********************************************************
    ***********************************************************/
    string provider_version;


    /***********************************************************
    When registering with the system we might use a different
    presentaton to identify the accounts
    ***********************************************************/
    bool multiple_accounts_registered = false;
};

/***********************************************************
Interface describing how to deal with virtual/placeholder files.

There are different ways of representing files locally that will only
be filled with data (hydrated) on demand. One such way would be suffixed
files, others could be FUSE based or use Windows CfApi.

This interface intends to decouple the sync algorithm
the details of how a particular VFS solution works.

An instance is usually created through a plugin via the create_vfs_from_plugin ()
function.
***********************************************************/
class Vfs : GLib.Object {


    /***********************************************************
    The kind of VFS in use (or no-VFS)

    Currently plugins and modes are one-to-one but that's not required.
    ***********************************************************/
    public enum Mode {
        Off,
        WithSuffix,
        WindowsCfApi,
        XAttr,
    }


    /***********************************************************
    ***********************************************************/
    public enum class ConvertToPlaceholderResult {
        Error,
        Ok,
        Locked
    }

    /***********************************************************
    ***********************************************************/
    public static string mode_to_string (Mode mode) {
        // Note: Strings are used for config and must be stable
        switch (mode) {
        case Off:
            return "off";
        case WithSuffix:
            return "suffix";
        case WindowsCfApi:
            return "wincfapi";
        case XAttr:
            return "xattr";
        }
        return "off";
    }


    /***********************************************************
    ***********************************************************/
    public static Optional<Mode> mode_from_string (string string_value) {
        // Note: Strings are used for config and must be stable
        if (string_value == "off") {
            return Off;
        } else if (string_value == "suffix") {
            return WithSuffix;
        } else if (string_value == "wincfapi") {
            return WindowsCfApi;
        }
        return {};
    }


    protected static string mode_to_plugin_name (Vfs.Mode mode) {
        if (mode == Vfs.WithSuffix)
            return "suffix";
        if (mode == Vfs.WindowsCfApi)
            return "cfapi";
        if (mode == Vfs.XAttr)
            return "xattr";
        return "";
    }


    /***********************************************************
    ***********************************************************/
    public static Result<bool, string> check_availability (string path) {
        const var mode = best_available_vfs_mode ();
        Q_UNUSED (mode)
        Q_UNUSED (path)
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public enum AvailabilityError {
        /***********************************************************
        Availability can't be retrieved due to database error
        ***********************************************************/
        DbError,

        /***********************************************************
        Availability not available since the item doesn't exist
        ***********************************************************/
        NoSuchItem,
    };


    public using AvailabilityResult = Result<VfsItemAvailability, AvailabilityError>;


    /***********************************************************
    the parameters passed to on_start ()
    ***********************************************************/
    protected VfsSetupParams _setup_params;


    /***********************************************************
    ***********************************************************/
    public Vfs (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public virtual Mode mode ();


    /***********************************************************
    For WithSuffix modes: the suffix (including the dot)
    ***********************************************************/
    public virtual string file_suffix ();


    /***********************************************************
    Access to the parameters the instance was on_start ()ed with.
    ***********************************************************/
    public VfsSetupParams parameters () {
        return _setup_params;
    }


    /***********************************************************
    Initializes interaction with the VFS provider.

    The plugin-specific work is done in start_impl ().
    ***********************************************************/
    public void on_start (VfsSetupParams parameters) {
        this._setup_params = parameters;
        start_impl (parameters);
    }


    /***********************************************************
    Stop interaction with VFS provider. Like when the client application quits.
    ***********************************************************/
    public virtual void stop ();


    /***********************************************************
    Deregister the folder with the sync provider, like when a folder is removed.
    ***********************************************************/
    public virtual void unregister_folder ();


    /***********************************************************
    Whether the socket api should show pin state options

    Some plugins might provide alternate shell integration, making the normal
    context menu actions redundant.
    ***********************************************************/
    public virtual bool socket_api_pin_state_actions_shown ();


    /***********************************************************
    Return true when download of a file's data is currently ongoing.

    See also the begin_hydrating () and done_hydrating () signals.
    ***********************************************************/
    public virtual bool is_hydrating ();


    /***********************************************************
    Update placeholder metadata during discovery.

    If the remote metadata changes, the local placeholder's metadata should possibly
    change as well.
    Q_REQUIRED_RESULT
    ***********************************************************/
    public virtual Result<void, string> update_metadata (string file_path, time_t modtime, int64 size, GLib.ByteArray file_id);


    /***********************************************************
    Create a new dehydrated placeholder. Called from PropagateDownload.
    Q_REQUIRED_RESULT
    ***********************************************************/
    public virtual Result<void, string> create_placeholder (SyncFileItem &item);


    /***********************************************************
    Convert a hydrated placeholder to a dehydrated one. Called from PropagateDownload.

    This is different from delete+create because preserving some file metadata
    (like pin states) may be essential for some vfs plugins.
    Q_REQUIRED_RESULT
    ***********************************************************/
    public virtual Result<void, string> dehydrate_placeholder (SyncFileItem &item);


    /***********************************************************
    Discovery hook: even unchanged files may need UPDATE_METADATA.

    For instance cfapi vfs wants local hydrated non-placeholder files to
    become hydrated placeholder files.
    Q_REQUIRED_RESULT
    ***********************************************************/
    public virtual bool needs_metadata_update (SyncFileItem &item);


    /***********************************************************
    Convert a new file to a hydrated placeholder.

    Some VFS integrations expect that every file, including those that have all
    the remote data, are "placeholders". This function is called by PropagateDownload
    to convert newly downloaded, fully hydrated files into placeholders.

    Implementations must make sure t
    is a placeholder is acceptable.

    replaces_file can optionally contain a filesystem path to a placeholder that this
    new placeholder shall supersede, for rename-replace actions with new downloads,
    for example.
    Q_REQUIRED_RESULT
    ***********************************************************/
    public virtual Result<Vfs.ConvertToPlaceholderResult, string> convert_to_placeholder (
        string filename,
        SyncFileItem item,
        string replaces_file = "");


    /***********************************************************
    Determine whether the file at the given absolute path is a dehydrated placeholder.
    Q_REQUIRED_RESULT
    ***********************************************************/
    public virtual bool is_dehydrated_placeholder (string file_path);


    /***********************************************************
    Similar to is_dehydrated_placeholder () but used from sync discovery.

    This function shall set stat.type if appropriate.
    It may rely on stat.path and stat_data (platform specific data).

    Returning true means that type was fully determined.
    Q_REQUIRED_RESULT
    ***********************************************************/
    public virtual bool stat_type_virtual_file (csync_file_stat_t stat, void stat_data);


    /***********************************************************
    Sets the pin state for the item at a path.

    The pin state is set on the item and for all items below it.

    Usually this would forward to setting the pin state flag in the database table,
    but some vfs plugins will store the pin state in file attributes instead.

    folder_path is relative to the sync folder. Can be "" for root folder.
    Q_REQUIRED_RESULT
    ***********************************************************/
    public virtual bool set_pin_state (string folder_path, PinState state);


    /***********************************************************
    Returns the pin state of an item at a path.

    Usually backed by the database's effective_pin_state () function but some vfs
    plugins will override it to retrieve the state from elsewhere.

    folder_path is relative to the sync folder. Can be "" for root folder.

    Returns none on retrieval error.
    Q_REQUIRED_RESULT
    ***********************************************************/
    public virtual Optional<PinState> pin_state (string folder_path);


    /***********************************************************
    Returns availability status of an item at a path.

    The availability is a condensed user-facing version of PinState. See
    VfsItemAvailability for details.

    folder_path is relative to the sync folder. Can be "" for root folder.
    Q_REQUIRED_RESULT
    ***********************************************************/
    public virtual AvailabilityResult availability (string folder_path);


    /***********************************************************
    Update in-sync state based on SyncFileStatusTracker signal.

    For some vfs plugins the icons aren't based on SocketApi but rather on data shared
    via the vfs plugin. The connection to SyncFileStatusTracker allows both to be based
    on the same data.
    ***********************************************************/
    public virtual void on_file_status_changed (string system_file_name, SyncFileStatus file_status);


    /***********************************************************
    Emitted when a user-initiated hydration starts
    ***********************************************************/
    signal void begin_hydrating ();


    /***********************************************************
    Emitted when the hydration ends
    ***********************************************************/
    signal void done_hydrating ();


    /***********************************************************
    Setup the plugin for the folder.

    For example, the VFS provider might monitor files to be able to on_start a file
    hydration (download of a file's remote contents) when the user wants to open
    it.

    Usually some registration needs to be done with the backend. This function
    should take care of it if necessary.
    ***********************************************************/
    protected virtual void start_impl (VfsSetupParams parameters);


    /***********************************************************
    Db-backed pin state handling. Derived classes may use it to implement pin states.
    ***********************************************************/
    protected bool set_pin_state_in_database (string folder_path, PinState state) {
        var path = folder_path.to_utf8 ();
        _setup_params.journal.internal_pin_states ().wipe_for_path_and_below (path);
        if (state != PinState.PinState.INHERITED)
            _setup_params.journal.internal_pin_states ().set_for_path (path, state);
        return true;
    }


    /***********************************************************
    ***********************************************************/
    protected Optional<PinState> pin_state_in_database (string folder_path) {
        var pin = _setup_params.journal.internal_pin_states ().effective_for_path (folder_path.to_utf8 ());
        return pin;
    }


    /***********************************************************
    ***********************************************************/
    protected AvailabilityResult availability_in_database (string folder_path) {
        var path = folder_path.to_utf8 ();
        var pin = _setup_params.journal.internal_pin_states ().effective_for_path_recursive (path);
        // not being able to retrieve the pin state isn't too bad
        var hydration_status = _setup_params.journal.has_hydrated_or_dehydrated_files (path);
        if (!hydration_status)
            return AvailabilityError.DbError;

        if (hydration_status.has_dehydrated) {
            if (hydration_status.has_hydrated)
                return VfsItemAvailability.VfsItemAvailability.MIXED;
            if (pin && *pin == PinState.VfsItemAvailability.ONLINE_ONLY)
                return VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY;
            else
                return VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED;
        } else if (hydration_status.has_hydrated) {
            if (pin && *pin == PinState.PinState.ALWAYS_LOCAL)
                return VfsItemAvailability.PinState.ALWAYS_LOCAL;
            else
                return VfsItemAvailability.VfsItemAvailability.ALL_HYDRATED;
        }
        return AvailabilityError.NoSuchItem;
    }
};


/***********************************************************
Implementation of Vfs for Vfs.Off mode - does nothing
***********************************************************/
class VfsOff : Vfs {

    /***********************************************************
    ***********************************************************/
    public VfsOff (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    ~VfsOff () = default;

    /***********************************************************
    ***********************************************************/
    public Mode mode () override {
        return Vfs.Off;
    }


    /***********************************************************
    ***********************************************************/
    public string file_suffix () override {
        return "";
    }


    /***********************************************************
    ***********************************************************/
    public void stop () override {}



    /***********************************************************
    ***********************************************************/
    public bool socket_api_pin_state_actions_shown () override {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_hydrating () override {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public Result<void, string> update_metadata (string , time_t, int64, GLib.ByteArray ) override {
        return {};
    }


    /***********************************************************
    ***********************************************************/
    public Result<void, string> create_placeholder (SyncFileItem &) override {
        return {};
    }


    /***********************************************************
    ***********************************************************/
    public Result<void, string> dehydrate_placeholder (SyncFileItem &) override {
        return {};
    }


    /***********************************************************
    ***********************************************************/
    public Result<ConvertToPlaceholderResult, string> convert_to_placeholder (string , SyncFileItem &, string ) override {
        return ConvertToPlaceholderResult.Ok;
    }


    /***********************************************************
    ***********************************************************/
    public bool needs_metadata_update (SyncFileItem &) override {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_dehydrated_placeholder (string ) override {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public bool stat_type_virtual_file (csync_file_stat_t *, void *) override {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public bool set_pin_state (string , PinState) override {
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public Optional<PinState> pin_state (string ) override {
    }


    /***********************************************************
    ***********************************************************/
    public AvailabilityResult availability (string ) override {
        return VfsItemAvailability.PinState.ALWAYS_LOCAL;
    }


    /***********************************************************
    ***********************************************************/
    public void on_file_status_changed (string , SyncFileStatus) override {}


    /***********************************************************
    ***********************************************************/
    protected void start_impl (VfsSetupParams &) override {}


    /***********************************************************
    Check whether the plugin for the mode is available.
    OCSYNC_EXPORT
    ***********************************************************/
    bool is_vfs_plugin_available (Vfs.Mode mode) {
        // TODO : cache plugins available?
        if (mode == Vfs.Off) {
            return true;
        }

        var name = mode_to_plugin_name (mode);
        if (name.is_empty ()) {
            return false;
        }

        QPluginLoader loader (plugin_file_name ("vfs", name));

        const var base_meta_data = loader.meta_data ();
        if (base_meta_data.is_empty () || !base_meta_data.contains ("IID")) {
            GLib.debug (lc_plugin) << "Plugin doesn't exist" << loader.file_name ();
            return false;
        }
        if (base_meta_data["IID"].to_"" != "org.owncloud.PluginFactory") {
            GLib.warn (lc_plugin) << "Plugin has wrong IID" << loader.file_name () << base_meta_data["IID"];
            return false;
        }

        const var metadata = base_meta_data["MetaData"].to_object ();
        if (metadata["type"].to_"" != "vfs") {
            GLib.warn (lc_plugin) << "Plugin has wrong type" << loader.file_name () << metadata["type"];
            return false;
        }
        if (metadata["version"].to_"" != MIRALL_VERSION_STRING) {
            GLib.warn (lc_plugin) << "Plugin has wrong version" << loader.file_name () << metadata["version"];
            return false;
        }

        // Attempting to load the plugin is essential as it could have dependencies that
        // can't be resolved and thus not be available after all.
        if (!loader.on_load ()) {
            GLib.warn (lc_plugin) << "Plugin failed to load:" << loader.error_string ();
            return false;
        }

        return true;
    }


    /***********************************************************
    Return the best available VFS mode.
    OCSYNC_EXPORT
    ***********************************************************/
    Vfs.Mode best_available_vfs_mode () {
        if (is_vfs_plugin_available (Vfs.WindowsCfApi)) {
            return Vfs.WindowsCfApi;
        }

        if (is_vfs_plugin_available (Vfs.WithSuffix)) {
            return Vfs.WithSuffix;
        }

        // For now the "suffix" backend has still precedence over the "xattr" backend.
        // Ultimately the order of those ifs will change when xattr will be more mature.
        // But what does "more mature" means here?
        //
        //  * On Mac when it properly reads and writes com.apple.LaunchServices.OpenWith
        // This will require reverse engineering to see what they stuff in there. Maybe a good
        // starting point:
        // https://eclecticlight.co/2017/12/20/xattr-com-apple-launchservices-openwith-sets-a-custom-app-to-open-a-file/
        //
        //  * On Linux when our user.nextcloud.hydrate_exec is adopted by at least KDE and Gnome
        // the "user.nextcloud" prefix might turn into "user.xdg" in the process since it would
        // be best to have a freedesktop.org spec for it.
        // When that time comes, it might still require detecting at runtime if that's indeed
        // supported in the user session or even per sync folder (in case user would pick a folder
        // which wouldn't support xattr for some reason)

        if (is_vfs_plugin_available (Vfs.XAttr)) {
            return Vfs.XAttr;
        }

        return Vfs.Off;
    }

    /***********************************************************
    Create a VFS instance for the mode, returns nullptr on failure.
    OCSYNC_EXPORT
    ***********************************************************/
    std.unique_ptr<Vfs> create_vfs_from_plugin (Vfs.Mode mode) {
        if (mode == Vfs.Off)
            return std.unique_ptr<Vfs> (new VfsOff);

        var name = mode_to_plugin_name (mode);
        if (name.is_empty ()) {
            return nullptr;
        }

        const var plugin_path = plugin_file_name ("vfs", name);

        if (!is_vfs_plugin_available (mode)) {
            q_c_critical (lc_plugin) << "Could not load plugin : not existant or bad metadata" << plugin_path;
            return nullptr;
        }

        QPluginLoader loader (plugin_path);
        var plugin = loader.instance ();
        if (!plugin) {
            q_c_critical (lc_plugin) << "Could not load plugin" << plugin_path << loader.error_string ();
            return nullptr;
        }

        var factory = qobject_cast<PluginFactory> (plugin);
        if (!factory) {
            q_c_critical (lc_plugin) << "Plugin" << loader.file_name () << "does not implement PluginFactory";
            return nullptr;
        }

        var vfs = std.unique_ptr<Vfs> (qobject_cast<Vfs> (factory.create (nullptr)));
        if (!vfs) {
            q_c_critical (lc_plugin) << "Plugin" << loader.file_name () << "does not create a Vfs instance";
            return nullptr;
        }

        q_c_info (lc_plugin) << "Created VFS instance from plugin" << plugin_path;
        return vfs;
    }


    /***********************************************************
    ***********************************************************/
    const int OCC_DEFINE_VFS_FACTORY (name, Type) {
        static_assert (std.is_base_of<Occ.Vfs, Type>.value, "Please define VFS factories only for Occ.Vfs subclasses");
    }


    /***********************************************************
    ***********************************************************/
    void init_plugin () {
        Occ.Vfs.register_plugin (name, [] () . Occ.Vfs * {
            return new (Type);
        });
    }


    //  Q_COREAPP_STARTUP_FUNCTION (init_plugin)

}

} // namespace Occ
