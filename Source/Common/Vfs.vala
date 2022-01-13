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
    string filesystemPath;

    // Folder display name in Windows Explorer
    string displayName;

    // Folder alias
    string alias;

    /***********************************************************
    The path to the synced folder on the account

    Always ends with /.
    ***********************************************************/
    string remotePath;

    /// Account url, credentials etc for network calls
    AccountPtr account;

    /***********************************************************
    Access to the sync folder's database.

    Note : The journal must live at least until the Vfs.stop () call.
    ***********************************************************/
    SyncJournalDb *journal = nullptr;

    /// Strings potentially passed on to the platform
    string providerName;
    string providerVersion;

    /***********************************************************
    when registering with the system we might use
     a different presentaton to identify the accounts
    ***********************************************************/
    bool multipleAccountsRegistered = false;
};

/***********************************************************
Interface describing how to deal with virtual/placeholder files.

There are different ways of representing files locally that will only
be filled with data (hydrated) on demand. One such way would be suffixed
files, others could be FUSE based or use Windows CfAPI.

This interface intends to decouple the sync algorithm
the details of how a particular VFS solution works.

An instance is usually created through a plugin via the createVfsFromPlugin ()
function.
***********************************************************/
class Vfs : GLib.Object {

public:
    /***********************************************************
    The kind of VFS in use (or no-VFS)

    Currently plugins and modes are one-to-one but that's not required.
    ***********************************************************/
    enum Mode {
        Off,
        WithSuffix,
        WindowsCfApi,
        XAttr,
    };
    Q_ENUM (Mode)
    enum class ConvertToPlaceholderResult {
        Error,
        Ok,
        Locked
    };
    Q_ENUM (ConvertToPlaceholderResult)

    static string modeToString (Mode mode);
    static Optional<Mode> modeFromString (string &str);

    static Result<bool, string> checkAvailability (string &path);

    enum class AvailabilityError {
        // Availability can't be retrieved due to db error
        DbError,
        // Availability not available since the item doesn't exist
        NoSuchItem,
    };
    using AvailabilityResult = Result<VfsItemAvailability, AvailabilityError>;

public:
    Vfs (GLib.Object* parent = nullptr);
    ~Vfs () override;

    virtual Mode mode () const = 0;

    /// For WithSuffix modes : the suffix (including the dot)
    virtual string fileSuffix () const = 0;

    /// Access to the parameters the instance was start ()ed with.
    const VfsSetupParams &params () { return _setupParams; }

    /***********************************************************
    Initializes interaction with the VFS provider.

    The plugin-specific work is done in startImpl ().
    ***********************************************************/
    void start (VfsSetupParams &params);

    /// Stop interaction with VFS provider. Like when the client application quits.
    virtual void stop () = 0;

    /// Deregister the folder with the sync provider, like when a folder is removed.
    virtual void unregisterFolder () = 0;

    /***********************************************************
    Whether the socket api should show pin state options

    Some plugins might provide alternate shell integration, making the normal
    context menu actions redundant.
    ***********************************************************/
    virtual bool socketApiPinStateActionsShown () const = 0;

    /***********************************************************
    Return true when download of a file's data is currently ongoing.

    See also the beginHydrating () and doneHydrating () signals.
    ***********************************************************/
    virtual bool isHydrating () const = 0;

    /***********************************************************
    Update placeholder metadata during discovery.

    If the remote metadata changes, the local placeholder's metadata should possibly
    change as well.
    ***********************************************************/
    virtual Q_REQUIRED_RESULT Result<void, string> updateMetadata (string &filePath, time_t modtime, int64 size, QByteArray &fileId) = 0;

    /// Create a new dehydrated placeholder. Called from PropagateDownload.
    virtual Q_REQUIRED_RESULT Result<void, string> createPlaceholder (SyncFileItem &item) = 0;

    /***********************************************************
    Convert a hydrated placeholder to a dehydrated one. Called from PropagateDownlaod.

    This is different from delete+create because preserving some file metadata
    (like pin states) may be essential for some vfs plugins.
    ***********************************************************/
    virtual Q_REQUIRED_RESULT Result<void, string> dehydratePlaceholder (SyncFileItem &item) = 0;

    /***********************************************************
    Discovery hook : even unchanged files may need UPDATE_METADATA.

    For instance cfapi vfs wants local hydrated non-placeholder files to
    become hydrated placeholder files.
    ***********************************************************/
    virtual Q_REQUIRED_RESULT bool needsMetadataUpdate (SyncFileItem &item) = 0;

    /***********************************************************
    Convert a new file to a hydrated placeholder.

    Some VFS integrations expect that every file, including those that have all
    the remote data, are "placeholders". This function is called by PropagateDownload
    to convert newly downloaded, fully hydrated files into placeholders.
    
    Implementations must make sure t
    is a placeholder is acceptable.
    
    replacesFile can optionally contain a filesystem path to a placeholder that this
     * new placeholder shall supersede, for rename-replace actions with new downloads,
     * for example.
    ***********************************************************/
    virtual Q_REQUIRED_RESULT Result<Vfs.ConvertToPlaceholderResult, string> convertToPlaceholder (
        const string &filename,
        const SyncFileItem &item,
        const string &replacesFile = string ()) = 0;

    /// Determine whether the file at the given absolute path is a dehydrated placeholder.
    virtual Q_REQUIRED_RESULT bool isDehydratedPlaceholder (string &filePath) = 0;

    /***********************************************************
    Similar to isDehydratedPlaceholder () but used from sync discovery.

    This function shall set stat.type if appropriate.
    It may rely on stat.path and stat_data (platform specific data).
    
     * Returning true means that type was fully determined.
    ***********************************************************/
    virtual Q_REQUIRED_RESULT bool statTypeVirtualFile (csync_file_stat_t *stat, void *stat_data) = 0;

    /***********************************************************
    Sets the pin state for the item at a path.

    The pin state is set on the item and for all items below it.
    
    Usually this would forward to setting the pin state flag in the db table,
    but some vfs plugins will store the pin state in file attributes instead.

     * folderPath is relative to the sync folder. Can be "" for root folder.
    ***********************************************************/
    virtual Q_REQUIRED_RESULT bool setPinState (string &folderPath, PinState state) = 0;

    /***********************************************************
    Returns the pin state of an item at a path.

    Usually backed by the db's effectivePinState () function but some vfs
    plugins will override it to retrieve the state from elsewhere.
    
    folderPath is relative to the sync folder. Can be "" for root folder.

     * Returns none on retrieval error.
    ***********************************************************/
    virtual Q_REQUIRED_RESULT Optional<PinState> pinState (string &folderPath) = 0;

    /***********************************************************
    Returns availability status of an item at a path.

    The availability is a condensed user-facing version of PinState. See
    VfsItemAvailability for details.
    
     * folderPath is relative to the sync folder. Can be "" for root folder.
    ***********************************************************/
    virtual Q_REQUIRED_RESULT AvailabilityResult availability (string &folderPath) = 0;

public slots:
    /***********************************************************
    Update in-sync state based on SyncFileStatusTracker signal.

    For some vfs plugins the icons aren't based on SocketAPI but rather on data shared
    via the vfs plugin. The connection to SyncFileStatusTracker allows both to be based
    on the same data.
    ***********************************************************/
    virtual void fileStatusChanged (string &systemFileName, SyncFileStatus fileStatus) = 0;

signals:
    /// Emitted when a user-initiated hydration starts
    void beginHydrating ();
    /// Emitted when the hydration ends
    void doneHydrating ();

protected:
    /***********************************************************
    Setup the plugin for the folder.

    For example, the VFS provider might monitor files to be able to start a file
    hydration (download of a file's remote contents) when the user wants to open
    it.
    
    Usually some registration needs to be done with the backend. This function
     * should take care of it if necessary.
    ***********************************************************/
    virtual void startImpl (VfsSetupParams &params) = 0;

    // Db-backed pin state handling. Derived classes may use it to implement pin states.
    bool setPinStateInDb (string &folderPath, PinState state);
    Optional<PinState> pinStateInDb (string &folderPath);
    AvailabilityResult availabilityInDb (string &folderPath);

    // the parameters passed to start ()
    VfsSetupParams _setupParams;
};

/// Implementation of Vfs for Vfs.Off mode - does nothing
class VfsOff : Vfs {

public:
    VfsOff (GLib.Object* parent = nullptr);
    ~VfsOff () override;

    Mode mode () const override { return Vfs.Off; }

    string fileSuffix () const override { return string (); }

    void stop () override {}
    void unregisterFolder () override {}

    bool socketApiPinStateActionsShown () const override { return false; }
    bool isHydrating () const override { return false; }

    Result<void, string> updateMetadata (string &, time_t, int64, QByteArray &) override { return {}; }
    Result<void, string> createPlaceholder (SyncFileItem &) override { return {}; }
    Result<void, string> dehydratePlaceholder (SyncFileItem &) override { return {}; }
    Result<ConvertToPlaceholderResult, string> convertToPlaceholder (string &, SyncFileItem &, string &) override { return ConvertToPlaceholderResult.Ok; }

    bool needsMetadataUpdate (SyncFileItem &) override { return false; }
    bool isDehydratedPlaceholder (string &) override { return false; }
    bool statTypeVirtualFile (csync_file_stat_t *, void *) override { return false; }

    bool setPinState (string &, PinState) override { return true; }
    Optional<PinState> pinState (string &) override { return PinState.AlwaysLocal; }
    AvailabilityResult availability (string &) override { return VfsItemAvailability.AlwaysLocal; }

public slots:
    void fileStatusChanged (string &, SyncFileStatus) override {}

protected:
    void startImpl (VfsSetupParams &) override {}
};

/// Check whether the plugin for the mode is available.
OCSYNC_EXPORT bool isVfsPluginAvailable (Vfs.Mode mode);

/// Return the best available VFS mode.
OCSYNC_EXPORT Vfs.Mode bestAvailableVfsMode ();

/// Create a VFS instance for the mode, returns nullptr on failure.
OCSYNC_EXPORT std.unique_ptr<Vfs> createVfsFromPlugin (Vfs.Mode mode);

} // namespace Occ

const int OCC_DEFINE_VFS_FACTORY (name, Type)
    static_assert (std.is_base_of<Occ.Vfs, Type>.value, "Please define VFS factories only for Occ.Vfs subclasses");
    namespace {
    void initPlugin () \ {
        Occ.Vfs.registerPlugin (QStringLiteral (name), [] () . Occ.Vfs * { return new (Type); });
    }
    Q_COREAPP_STARTUP_FUNCTION (initPlugin)
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

string Vfs.modeToString (Mode mode) {
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

Optional<Vfs.Mode> Vfs.modeFromString (string &str) {
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

Result<bool, string> Vfs.checkAvailability (string &path) {
    const auto mode = bestAvailableVfsMode ();
    Q_UNUSED (mode)
    Q_UNUSED (path)
    return true;
}

void Vfs.start (VfsSetupParams &params) {
    _setupParams = params;
    startImpl (params);
}

bool Vfs.setPinStateInDb (string &folderPath, PinState state) {
    auto path = folderPath.toUtf8 ();
    _setupParams.journal.internalPinStates ().wipeForPathAndBelow (path);
    if (state != PinState.Inherited)
        _setupParams.journal.internalPinStates ().setForPath (path, state);
    return true;
}

Optional<PinState> Vfs.pinStateInDb (string &folderPath) {
    auto pin = _setupParams.journal.internalPinStates ().effectiveForPath (folderPath.toUtf8 ());
    return pin;
}

Vfs.AvailabilityResult Vfs.availabilityInDb (string &folderPath) {
    auto path = folderPath.toUtf8 ();
    auto pin = _setupParams.journal.internalPinStates ().effectiveForPathRecursive (path);
    // not being able to retrieve the pin state isn't too bad
    auto hydrationStatus = _setupParams.journal.hasHydratedOrDehydratedFiles (path);
    if (!hydrationStatus)
        return AvailabilityError.DbError;

    if (hydrationStatus.hasDehydrated) {
        if (hydrationStatus.hasHydrated)
            return VfsItemAvailability.Mixed;
        if (pin && *pin == PinState.OnlineOnly)
            return VfsItemAvailability.OnlineOnly;
        else
            return VfsItemAvailability.AllDehydrated;
    } else if (hydrationStatus.hasHydrated) {
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

static string modeToPluginName (Vfs.Mode mode) {
    if (mode == Vfs.WithSuffix)
        return QStringLiteral ("suffix");
    if (mode == Vfs.WindowsCfApi)
        return QStringLiteral ("cfapi");
    if (mode == Vfs.XAttr)
        return QStringLiteral ("xattr");
    return string ();
}


bool Occ.isVfsPluginAvailable (Vfs.Mode mode) {
    // TODO : cache plugins available?
    if (mode == Vfs.Off) {
        return true;
    }

    auto name = modeToPluginName (mode);
    if (name.isEmpty ()) {
        return false;
    }

    QPluginLoader loader (pluginFileName (QStringLiteral ("vfs"), name));

    const auto baseMetaData = loader.metaData ();
    if (baseMetaData.isEmpty () || !baseMetaData.contains (QStringLiteral ("IID"))) {
        qCDebug (lcPlugin) << "Plugin doesn't exist" << loader.fileName ();
        return false;
    }
    if (baseMetaData[QStringLiteral ("IID")].toString () != QStringLiteral ("org.owncloud.PluginFactory")) {
        qCWarning (lcPlugin) << "Plugin has wrong IID" << loader.fileName () << baseMetaData[QStringLiteral ("IID")];
        return false;
    }

    const auto metadata = baseMetaData[QStringLiteral ("MetaData")].toObject ();
    if (metadata[QStringLiteral ("type")].toString () != QStringLiteral ("vfs")) {
        qCWarning (lcPlugin) << "Plugin has wrong type" << loader.fileName () << metadata[QStringLiteral ("type")];
        return false;
    }
    if (metadata[QStringLiteral ("version")].toString () != QStringLiteral (MIRALL_VERSION_STRING)) {
        qCWarning (lcPlugin) << "Plugin has wrong version" << loader.fileName () << metadata[QStringLiteral ("version")];
        return false;
    }

    // Attempting to load the plugin is essential as it could have dependencies that
    // can't be resolved and thus not be available after all.
    if (!loader.load ()) {
        qCWarning (lcPlugin) << "Plugin failed to load:" << loader.errorString ();
        return false;
    }

    return true;
}

Vfs.Mode Occ.bestAvailableVfsMode () {
    if (isVfsPluginAvailable (Vfs.WindowsCfApi)) {
        return Vfs.WindowsCfApi;
    }

    if (isVfsPluginAvailable (Vfs.WithSuffix)) {
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

    if (isVfsPluginAvailable (Vfs.XAttr)) {
        return Vfs.XAttr;
    }

    return Vfs.Off;
}

std.unique_ptr<Vfs> Occ.createVfsFromPlugin (Vfs.Mode mode) {
    if (mode == Vfs.Off)
        return std.unique_ptr<Vfs> (new VfsOff);

    auto name = modeToPluginName (mode);
    if (name.isEmpty ()) {
        return nullptr;
    }

    const auto pluginPath = pluginFileName (QStringLiteral ("vfs"), name);

    if (!isVfsPluginAvailable (mode)) {
        qCCritical (lcPlugin) << "Could not load plugin : not existant or bad metadata" << pluginPath;
        return nullptr;
    }

    QPluginLoader loader (pluginPath);
    auto plugin = loader.instance ();
    if (!plugin) {
        qCCritical (lcPlugin) << "Could not load plugin" << pluginPath << loader.errorString ();
        return nullptr;
    }

    auto factory = qobject_cast<PluginFactory> (plugin);
    if (!factory) {
        qCCritical (lcPlugin) << "Plugin" << loader.fileName () << "does not implement PluginFactory";
        return nullptr;
    }

    auto vfs = std.unique_ptr<Vfs> (qobject_cast<Vfs> (factory.create (nullptr)));
    if (!vfs) {
        qCCritical (lcPlugin) << "Plugin" << loader.fileName () << "does not create a Vfs instance";
        return nullptr;
    }

    qCInfo (lcPlugin) << "Created VFS instance from plugin" << pluginPath;
    return vfs;
}
