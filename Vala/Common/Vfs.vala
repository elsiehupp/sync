/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>
Copyright (C) by Dominik Schmidt <dschmidt@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QPluginLoader>
//  #include <QLoggingCategory>
//  #includeonce
//  #include <QScopedPointer>
//  #include <memory>

namespace Occ {

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
public class Vfs : GLib.Object {

    struct csync_file_stat_t : csync_file_stat_s { }
    public class AvailabilityResult : Result<VfsItemAvailability, AvailabilityError> { }

    /***********************************************************
    The kind of VFS in use (or no-VFS)

    Currently plugins and modes are one-to-one but that's not required.
    ***********************************************************/
    public enum Mode {
        OFF,
        WITH_SUFFIX,
        WINDOWS_CF_API,
        XATTR;

        /***********************************************************
        Note: Strings are used for config and must be stable
        ***********************************************************/
        public static string to_string (Mode mode) {
            switch (mode) {
            case OFF:
                return "off";
            case WITH_SUFFIX:
                return "suffix";
            case WINDOWS_CF_API:
                return "wincfapi";
            case XATTR:
                return "xattr";
            }
            return "off";
        }


        /***********************************************************
        ***********************************************************/
        public static Optional<Mode> from_string (string string_value) {
            // Note: Strings are used for config and must be stable
            if (string_value == "off") {
                return OFF;
            } else if (string_value == "suffix") {
                return WITH_SUFFIX;
            } else if (string_value == "wincfapi") {
                return WINDOWS_CF_API;
            }
            return {};
        }

    
        protected static string to_plugin_name (Vfs.Mode mode) {
            if (mode == Vfs.WITH_SUFFIX)
                return "suffix";
            if (mode == Vfs.WINDOWS_CF_API)
                return "cfapi";
            if (mode == Vfs.XATTR)
                return "xattr";
            return "";
        }
    }


    /***********************************************************
    ***********************************************************/
    public enum ConvertToPlaceholderResult {
        ERROR,
        OK,
        LOCKED
    }


    /***********************************************************
    ***********************************************************/
    public enum AvailabilityError {
        /***********************************************************
        Availability can't be retrieved due to database error
        ***********************************************************/
        DATABASE_ERROR,

        /***********************************************************
        Availability not available since the item doesn't exist
        ***********************************************************/
        NO_SUCH_ITEM,
    }


    /***********************************************************
    ***********************************************************/
    public static Result<bool, string> check_availability (string path) {
        const var mode = best_available_vfs_mode ();
        //  Q_UNUSED (mode)
        //  Q_UNUSED (path)
        return true;
    }


    /***********************************************************
    the parameters passed to on_signal_start ()
    ***********************************************************/
    protected VfsSetupParams setup_params;


    /***********************************************************
    ***********************************************************/
    public Vfs (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public virtual Mode mode ();


    /***********************************************************
    For WITH_SUFFIX modes: the suffix (including the dot)
    ***********************************************************/
    public virtual string file_suffix ();


    /***********************************************************
    Access to the parameters the instance was on_signal_start ()ed with.
    ***********************************************************/
    public VfsSetupParams parameters () {
        return this.setup_params;
    }


    /***********************************************************
    Initializes interaction with the VFS provider.

    The plugin-specific work is done in start_impl ().
    ***********************************************************/
    public void on_signal_start (VfsSetupParams parameters) {
        this.setup_params = parameters;
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
    public virtual Result<void, string> create_placeholder (SyncFileItem item);


    /***********************************************************
    Convert a hydrated placeholder to a dehydrated one. Called from PropagateDownload.

    This is different from delete+create because preserving some file metadata
    (like pin states) may be essential for some vfs plugins.
    Q_REQUIRED_RESULT
    ***********************************************************/
    public virtual Result<void, string> dehydrate_placeholder (SyncFileItem item);


    /***********************************************************
    Discovery hook: even unchanged files may need UPDATE_METADATA.

    For instance cfapi vfs wants local hydrated non-placeholder files to
    become hydrated placeholder files.
    Q_REQUIRED_RESULT
    ***********************************************************/
    public virtual bool needs_metadata_update (SyncFileItem item);


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
    public virtual bool pin_state_for_path (string folder_path, PinState state);


    /***********************************************************
    Returns the pin state of an item at a path.

    Usually backed by the database's effective_pin_state () function but some vfs
    plugins will override it to retrieve the state from elsewhere.

    folder_path is relative to the sync folder. Can be "" for root folder.

    Returns none on retrieval error.
    Q_REQUIRED_RESULT
    ***********************************************************/
    public virtual Optional<PinState> pin_state_of_path (string folder_path);


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
    public virtual void on_signal_file_status_changed (string system_filename, SyncFileStatus file_status);


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

    For example, the VFS provider might monitor files to be able to on_signal_start a file
    hydration (download of a file's remote contents) when the user wants to open
    it.

    Usually some registration needs to be done with the backend. This function
    should take care of it if necessary.
    ***********************************************************/
    protected virtual void start_impl (VfsSetupParams parameters);


    /***********************************************************
    Db-backed pin state handling. Derived classes may use it to implement pin states.
    ***********************************************************/
    protected bool is_pin_state_in_database (string folder_path, PinState state) {
        var path = folder_path.to_utf8 ();
        this.setup_params.journal.internal_pin_states ().wipe_for_path_and_below (path);
        if (state != PinState.PinState.INHERITED)
            this.setup_params.journal.internal_pin_states ().for_path (path, state);
        return true;
    }


    /***********************************************************
    ***********************************************************/
    protected Optional<PinState> find_pin_state_in_database (string folder_path) {
        var pin = this.setup_params.journal.internal_pin_states ().effective_for_path (folder_path.to_utf8 ());
        return pin;
    }


    /***********************************************************
    ***********************************************************/
    protected AvailabilityResult availability_in_database (string folder_path) {
        var path = folder_path.to_utf8 ();
        var pin = this.setup_params.journal.internal_pin_states ().effective_for_path_recursive (path);
        // not being able to retrieve the pin state isn't too bad
        var hydration_status = this.setup_params.journal.has_hydrated_or_dehydrated_files (path);
        if (!hydration_status)
            return AvailabilityError.DATABASE_ERROR;

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
        return AvailabilityError.NO_SUCH_ITEM;
    }

} // class Vfs

} // namespace Occ
