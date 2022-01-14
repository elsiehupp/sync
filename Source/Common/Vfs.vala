/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/
// #pragma once

// #include <GLib.Object>
// #include <QScopedPointer>
// #include <QSharedPointer>

// #include <memory>

using csync_file_stat_t = struct csync_file_stat_s;

namespace Occ {

using AccountPtr = QSharedPointer<Account>;

/***********************************************************
Collection of parameters for initializing a Vfs instance. */
struct OCSYNC_EXPORT VfsSetupParams {
    /***********************************************************
    The full path to the folder on the local filesystem

    Always ends with /.
    ***********************************************************/
    string filesystem_path;

    // Folder display name in Windows Explorer
    string display_name;

    // Folder alias
    string alias;

    /***********************************************************
    The path to the synced folder on the account

    Always ends with /.
    ***********************************************************/
    string remote_path;

    /// Account url, credentials etc for network calls
    AccountPtr account;

    /***********************************************************
    Access to the sync folder's database.

    Note : The journal must live at least until the Vfs.stop () call.
    ***********************************************************/
    SyncJournalDb *journal = nullptr;

    /// Strings potentially passed on to the platform
    string provider_name;
    string provider_version;

    /***********************************************************
    when registering with the system we might use
     a different presentaton to identify the accounts
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
    };
    public enum class ConvertToPlaceholderResult {
        Error,
        Ok,
        Locked
    };

    public static string mode_to_string (Mode mode);
    public static Optional<Mode> mode_from_string (string &str);

    public static Result<bool, string> check_availability (string &path);

    public enum class AvailabilityError {
        // Availability can't be retrieved due to db error
        DbError,
        // Availability not available since the item doesn't exist
        NoSuchItem,
    };
    public using AvailabilityResult = Result<VfsItemAvailability, AvailabilityError>;


    public Vfs (GLib.Object* parent = nullptr);
    public ~Vfs () override;

    public virtual Mode mode () const = 0;

    /// For WithSuffix modes : the suffix (including the dot)
    public virtual string file_suffix () const = 0;

    /// Access to the parameters the instance was start ()ed with.
    public const VfsSetupParams &params () { return _setup_params; }

    /***********************************************************
    Initializes interaction with the VFS provider.

    The plugin-specific work is done in start_impl ().
    ***********************************************************/
    public void start (VfsSetupParams &params);

    /// Stop interaction with VFS provider. Like when the client application quits.
    public virtual void stop () = 0;

    /// Deregister the folder with the sync provider, like when a folder is removed.
    public virtual void unregister_folder () = 0;

    /***********************************************************
    Whether the socket api should show pin state options

    Some plugins might provide alternate shell integration, making the normal
    context menu actions redundant.
    ***********************************************************/
    public virtual bool socket_api_pin_state_actions_shown () const = 0;

    /***********************************************************
    Return true when download of a file's data is currently ongoing.

    See also the begin_hydrating () and done_hydrating () signals.
    ***********************************************************/
    public virtual bool is_hydrating () const = 0;

    /***********************************************************
    Update placeholder metadata during discovery.

    If the remote metadata changes, the local placeholder's metadata should possibly
    change as well.
    ***********************************************************/
    public virtual Q_REQUIRED_RESULT Result<void, string> update_metadata (string &file_path, time_t modtime, int64 size, QByteArray &file_id) = 0;

    /// Create a new dehydrated placeholder. Called from PropagateDownload.
    public virtual Q_REQUIRED_RESULT Result<void, string> create_placeholder (SyncFileItem &item) = 0;

    /***********************************************************
    Convert a hydrated placeholder to a dehydrated one. Called from PropagateDownload.

    This is different from delete+create because preserving some file metadata
    (like pin states) may be essential for some vfs plugins.
    ***********************************************************/
    public virtual Q_REQUIRED_RESULT Result<void, string> dehydrate_placeholder (SyncFileItem &item) = 0;

    /***********************************************************
    Discovery hook : even unchanged files may need UPDATE_METADATA.

    For instance cfapi vfs wants local hydrated non-placeholder files to
    become hydrated placeholder files.
    ***********************************************************/
    public virtual Q_REQUIRED_RESULT bool needs_metadata_update (SyncFileItem &item) = 0;

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
    ***********************************************************/
    public virtual Q_REQUIRED_RESULT Result<Vfs.ConvertToPlaceholderResult, string> convert_to_placeholder (
        const string &filename,
        const SyncFileItem &item,
        const string &replaces_file = string ()) = 0;

    /// Determine whether the file at the given absolute path is a dehydrated placeholder.
    public virtual Q_REQUIRED_RESULT bool is_dehydrated_placeholder (string &file_path) = 0;

    /***********************************************************
    Similar to is_dehydrated_placeholder () but used from sync discovery.

    This function shall set stat.type if appropriate.
    It may rely on stat.path and stat_data (platform specific data).
    
    Returning true means that type was fully determined.
    ***********************************************************/
    public virtual Q_REQUIRED_RESULT bool stat_type_virtual_file (csync_file_stat_t *stat, void *stat_data) = 0;

    /***********************************************************
    Sets the pin state for the item at a path.

    The pin state is set on the item and for all items below it.
    
    Usually this would forward to setting the pin state flag in the db table,
    but some vfs plugins will store the pin state in file attributes instead.

    folder_path is relative to the sync folder. Can be "" for root folder.
    ***********************************************************/
    public virtual Q_REQUIRED_RESULT bool set_pin_state (string &folder_path, PinState state) = 0;

    /***********************************************************
    Returns the pin state of an item at a path.

    Usually backed by the db's effective_pin_state () function but some vfs
    plugins will override it to retrieve the state from elsewhere.
    
    folder_path is relative to the sync folder. Can be "" for root folder.

    Returns none on retrieval error.
    ***********************************************************/
    public virtual Q_REQUIRED_RESULT Optional<PinState> pin_state (string &folder_path) = 0;

    /***********************************************************
    Returns availability status of an item at a path.

    The availability is a condensed user-facing version of PinState. See
    VfsItemAvailability for details.
    
    folder_path is relative to the sync folder. Can be "" for root folder.
    ***********************************************************/
    public virtual Q_REQUIRED_RESULT AvailabilityResult availability (string &folder_path) = 0;

public slots:
    /***********************************************************
    Update in-sync state based on SyncFileStatusTracker signal.

    For some vfs plugins the icons aren't based on SocketApi but rather on data shared
    via the vfs plugin. The connection to SyncFileStatusTracker allows both to be based
    on the same data.
    ***********************************************************/
    virtual void file_status_changed (string &system_file_name, SyncFileStatus file_status) = 0;

signals:
    /// Emitted when a user-initiated hydration starts
    void begin_hydrating ();
    /// Emitted when the hydration ends
    void done_hydrating ();

protected:
    /***********************************************************
    Setup the plugin for the folder.

    For example, the VFS provider might monitor files to be able to start a file
    hydration (download of a file's remote contents) when the user wants to open
    it.
    
    Usually some registration needs to be done with the backend. This function
    should take care of it if necessary.
    ***********************************************************/
    virtual void start_impl (VfsSetupParams &params) = 0;

    // Db-backed pin state handling. Derived classes may use it to implement pin states.
    bool set_pin_state_in_db (string &folder_path, PinState state);
    Optional<PinState> pin_state_in_db (string &folder_path);
    AvailabilityResult availability_in_db (string &folder_path);

    // the parameters passed to start ()
    VfsSetupParams _setup_params;
};

/// Implementation of Vfs for Vfs.Off mode - does nothing
class VfsOff : Vfs {

    public VfsOff (GLib.Object* parent = nullptr);
    public ~VfsOff () override;

    public Mode mode () const override { return Vfs.Off; }

    public string file_suffix () const override { return string (); }

    public void stop () override {}
    public void unregister_folder () override {}

    public bool socket_api_pin_state_actions_shown () const override { return false; }
    public bool is_hydrating () const override { return false; }

    public Result<void, string> update_metadata (string &, time_t, int64, QByteArray &) override { return {}; }
    public Result<void, string> create_placeholder (SyncFileItem &) override { return {}; }
    public Result<void, string> dehydrate_placeholder (SyncFileItem &) override { return {}; }
    public Result<ConvertToPlaceholderResult, string> convert_to_placeholder (string &, SyncFileItem &, string &) override { return ConvertToPlaceholderResult.Ok; }

    public bool needs_metadata_update (SyncFileItem &) override { return false; }
    public bool is_dehydrated_placeholder (string &) override { return false; }
    public bool stat_type_virtual_file (csync_file_stat_t *, void *) override { return false; }

    public bool set_pin_state (string &, PinState) override { return true; }
    public Optional<PinState> pin_state (string &) override { return PinState.AlwaysLocal; }
    public AvailabilityResult availability (string &) override { return VfsItemAvailability.AlwaysLocal; }

public slots:
    void file_status_changed (string &, SyncFileStatus) override {}

protected:
    void start_impl (VfsSetupParams &) override {}
};

/// Check whether the plugin for the mode is available.
OCSYNC_EXPORT bool is_vfs_plugin_available (Vfs.Mode mode);

/// Return the best available VFS mode.
OCSYNC_EXPORT Vfs.Mode best_available_vfs_mode ();

/// Create a VFS instance for the mode, returns nullptr on failure.
OCSYNC_EXPORT std.unique_ptr<Vfs> create_vfs_from_plugin (Vfs.Mode mode);

} // namespace Occ

const int OCC_DEFINE_VFS_FACTORY (name, Type)
    static_assert (std.is_base_of<Occ.Vfs, Type>.value, "Please define VFS factories only for Occ.Vfs subclasses");
    namespace {
    void init_plugin () \ {
        Occ.Vfs.register_plugin (QStringLiteral (name), [] () . Occ.Vfs * { return new (Type); });
    }
    Q_COREAPP_STARTUP_FUNCTION (init_plugin)
    }









/***********************************************************
Copyright (C) by Dominik Schmidt <dschmidt@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <QPluginLoader>
// #include <QLoggingCategory>

using namespace Occ;

Vfs.Vfs (GLib.Object* parent)
    : GLib.Object (parent) {
}

Vfs.~Vfs () = default;

string Vfs.mode_to_string (Mode mode) {
    // Note : Strings are used for config and must be stable
    switch (mode) {
    case Off:
        return QStringLiteral ("off");
    case WithSuffix:
        return QStringLiteral ("suffix");
    case WindowsCfApi:
        return QStringLiteral ("wincfapi");
    case XAttr:
        return QStringLiteral ("xattr");
    }
    return QStringLiteral ("off");
}

Optional<Vfs.Mode> Vfs.mode_from_string (string &str) {
    // Note : Strings are used for config and must be stable
    if (str == QLatin1String ("off")) {
        return Off;
    } else if (str == QLatin1String ("suffix")) {
        return WithSuffix;
    } else if (str == QLatin1String ("wincfapi")) {
        return WindowsCfApi;
    }
    return {};
}

Result<bool, string> Vfs.check_availability (string &path) {
    const auto mode = best_available_vfs_mode ();
    Q_UNUSED (mode)
    Q_UNUSED (path)
    return true;
}

void Vfs.start (VfsSetupParams &params) {
    _setup_params = params;
    start_impl (params);
}

bool Vfs.set_pin_state_in_db (string &folder_path, PinState state) {
    auto path = folder_path.to_utf8 ();
    _setup_params.journal.internal_pin_states ().wipe_for_path_and_below (path);
    if (state != PinState.Inherited)
        _setup_params.journal.internal_pin_states ().set_for_path (path, state);
    return true;
}

Optional<PinState> Vfs.pin_state_in_db (string &folder_path) {
    auto pin = _setup_params.journal.internal_pin_states ().effective_for_path (folder_path.to_utf8 ());
    return pin;
}

Vfs.AvailabilityResult Vfs.availability_in_db (string &folder_path) {
    auto path = folder_path.to_utf8 ();
    auto pin = _setup_params.journal.internal_pin_states ().effective_for_path_recursive (path);
    // not being able to retrieve the pin state isn't too bad
    auto hydration_status = _setup_params.journal.has_hydrated_or_dehydrated_files (path);
    if (!hydration_status)
        return AvailabilityError.DbError;

    if (hydration_status.has_dehydrated) {
        if (hydration_status.has_hydrated)
            return VfsItemAvailability.Mixed;
        if (pin && *pin == PinState.OnlineOnly)
            return VfsItemAvailability.OnlineOnly;
        else
            return VfsItemAvailability.AllDehydrated;
    } else if (hydration_status.has_hydrated) {
        if (pin && *pin == PinState.AlwaysLocal)
            return VfsItemAvailability.AlwaysLocal;
        else
            return VfsItemAvailability.AllHydrated;
    }
    return AvailabilityError.NoSuchItem;
}

VfsOff.VfsOff (GLib.Object *parent)
    : Vfs (parent) {
}

VfsOff.~VfsOff () = default;

static string mode_to_plugin_name (Vfs.Mode mode) {
    if (mode == Vfs.WithSuffix)
        return QStringLiteral ("suffix");
    if (mode == Vfs.WindowsCfApi)
        return QStringLiteral ("cfapi");
    if (mode == Vfs.XAttr)
        return QStringLiteral ("xattr");
    return string ();
}


bool Occ.is_vfs_plugin_available (Vfs.Mode mode) {
    // TODO : cache plugins available?
    if (mode == Vfs.Off) {
        return true;
    }

    auto name = mode_to_plugin_name (mode);
    if (name.is_empty ()) {
        return false;
    }

    QPluginLoader loader (plugin_file_name (QStringLiteral ("vfs"), name));

    const auto base_meta_data = loader.meta_data ();
    if (base_meta_data.is_empty () || !base_meta_data.contains (QStringLiteral ("IID"))) {
        q_c_debug (lc_plugin) << "Plugin doesn't exist" << loader.file_name ();
        return false;
    }
    if (base_meta_data[QStringLiteral ("IID")].to_string () != QStringLiteral ("org.owncloud.PluginFactory")) {
        q_c_warning (lc_plugin) << "Plugin has wrong IID" << loader.file_name () << base_meta_data[QStringLiteral ("IID")];
        return false;
    }

    const auto metadata = base_meta_data[QStringLiteral ("MetaData")].to_object ();
    if (metadata[QStringLiteral ("type")].to_string () != QStringLiteral ("vfs")) {
        q_c_warning (lc_plugin) << "Plugin has wrong type" << loader.file_name () << metadata[QStringLiteral ("type")];
        return false;
    }
    if (metadata[QStringLiteral ("version")].to_string () != QStringLiteral (MIRALL_VERSION_STRING)) {
        q_c_warning (lc_plugin) << "Plugin has wrong version" << loader.file_name () << metadata[QStringLiteral ("version")];
        return false;
    }

    // Attempting to load the plugin is essential as it could have dependencies that
    // can't be resolved and thus not be available after all.
    if (!loader.load ()) {
        q_c_warning (lc_plugin) << "Plugin failed to load:" << loader.error_string ();
        return false;
    }

    return true;
}

Vfs.Mode Occ.best_available_vfs_mode () {
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

std.unique_ptr<Vfs> Occ.create_vfs_from_plugin (Vfs.Mode mode) {
    if (mode == Vfs.Off)
        return std.unique_ptr<Vfs> (new VfsOff);

    auto name = mode_to_plugin_name (mode);
    if (name.is_empty ()) {
        return nullptr;
    }

    const auto plugin_path = plugin_file_name (QStringLiteral ("vfs"), name);

    if (!is_vfs_plugin_available (mode)) {
        q_c_critical (lc_plugin) << "Could not load plugin : not existant or bad metadata" << plugin_path;
        return nullptr;
    }

    QPluginLoader loader (plugin_path);
    auto plugin = loader.instance ();
    if (!plugin) {
        q_c_critical (lc_plugin) << "Could not load plugin" << plugin_path << loader.error_string ();
        return nullptr;
    }

    auto factory = qobject_cast<PluginFactory> (plugin);
    if (!factory) {
        q_c_critical (lc_plugin) << "Plugin" << loader.file_name () << "does not implement PluginFactory";
        return nullptr;
    }

    auto vfs = std.unique_ptr<Vfs> (qobject_cast<Vfs> (factory.create (nullptr)));
    if (!vfs) {
        q_c_critical (lc_plugin) << "Plugin" << loader.file_name () << "does not create a Vfs instance";
        return nullptr;
    }

    q_c_info (lc_plugin) << "Created VFS instance from plugin" << plugin_path;
    return vfs;
}
