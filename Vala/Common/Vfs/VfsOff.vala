/***********************************************************
@author Christian Kamm <mail@ckamm.de>
@author Dominik Schmidt <dschmidt@owncloud.com>
@copyright GPLv3 or Later
***********************************************************/

namespace Occ {

/***********************************************************
Implementation of Vfs for Mode.OFF mode - does nothing
***********************************************************/
public class VfsOff : AbstractVfs {

    /***********************************************************
    ***********************************************************/
    public VfsOff (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public override Mode mode () {
        return Mode.OFF;
    }


    /***********************************************************
    ***********************************************************/
    public override string file_suffix () {
        return "";
    }


    /***********************************************************
    ***********************************************************/
    public override void stop () {}



    /***********************************************************
    ***********************************************************/
    public override bool socket_api_pin_state_actions_shown () {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public override bool is_hydrating () {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public override Result<void, string> update_metadata (string file_path, time_t modtime, int64 size, string file_id) {
        return {};
    }


    /***********************************************************
    ***********************************************************/
    public override Result<void, string> create_placeholder (SyncFileItem sync_file_item) {
        return {};
    }


    /***********************************************************
    ***********************************************************/
    public override Result<void, string> dehydrate_placeholder (SyncFileItem sync_file_item) {
        return {};
    }


    /***********************************************************
    ***********************************************************/
    public override Result<ConvertToPlaceholderResult, string> convert_to_placeholder (string string_value_1, SyncFileItem sync_file_item, string string_value_2) {
        return ConvertToPlaceholderResult.Ok;
    }


    /***********************************************************
    ***********************************************************/
    public override bool needs_metadata_update (SyncFileItem sync_file_item) {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public override bool is_dehydrated_placeholder (string file_path) {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public override bool stat_type_virtual_file (CSync.CSyncFileStatT csync_file_stat, void *stat_data) {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public override bool pin_state_for_path (string folder_path, PinState state) {
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public override Optional<PinState> pin_state_of_path (string folder_path) {
        return new Optional<PinState> ();
    }


    /***********************************************************
    ***********************************************************/
    public override AbstractVfs.AvailabilityResult availability (string folder_path) {
        return Vfs.ItemAvailability.PinState.ALWAYS_LOCAL;
    }


    /***********************************************************
    ***********************************************************/
    public override void on_signal_file_status_changed (string system_filename, SyncFileStatus file_status) {
        return;
    }


    /***********************************************************
    ***********************************************************/
    protected override void start_impl (Vfs.SetupParameters setup_parameters) {
        return;
    }


    /***********************************************************
    Check whether the plugin for the mode is available.
    OCSYNC_EXPORT
    ***********************************************************/
    bool is_vfs_plugin_available (AbstractVfs.Mode mode) {
        // TODO: cache plugins available?
        if (mode == AbstractVfs.Mode.Off) {
            return true;
        }

        var name = Mode.to_plugin_name (mode);
        if (name == "") {
            return false;
        }

        QPluginLoader loader = new QPluginLoader (plugin_filename ("vfs", name));

        const var base_meta_data = loader.meta_data ();
        if (base_meta_data == "" || !base_meta_data.contains ("IID")) {
            GLib.debug ("Plugin " + loader.filename () + " doesn't exist.");
            return false;
        }
        if (base_meta_data["IID"].to_string () != "org.owncloud.PluginFactory") {
            GLib.warning ("Plugin " + loader.filename () + " IID " + base_meta_data["IID"] + " is incorrect");
            return false;
        }

        const var metadata = base_meta_data["MetaData"].to_object ();
        if (metadata["type"].to_string () != "vfs") {
            GLib.warning ("Plugin " + loader.filename () + " metadata type " + metadata["type"] + " is incorrect");
            return false;
        }
        if (metadata["version"].to_string () != MIRALL_VERSION_STRING) {
            GLib.warning ("Plugin " + loader.filename () + " version " + metadata["version"] + " is incorrect");
            return false;
        }

        // Attempting to load the plugin is essential as it could have dependencies that
        // can't be resolved and thus not be available after all.
        if (!loader.on_signal_load ()) {
            GLib.warning ("Plugin " + loader.filename () + " failed to load with error " + loader.error_string);
            return false;
        }

        return true;
    }


    /***********************************************************
    Return the best available VFS mode.
    OCSYNC_EXPORT
    ***********************************************************/
    override AbstractVfs.Mode best_available_vfs_mode {
        get {
            if (is_vfs_plugin_available (Mode.WINDOWS_CF_API)) {
                return Mode.WINDOWS_CF_API;
            }

            if (is_vfs_plugin_available (Mode.WITH_SUFFIX)) {
                return Mode.WITH_SUFFIX;
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

            if (is_vfs_plugin_available (Mode.XATTR)) {
                return Mode.XATTR;
            }

            return Mode.OFF;
        }
    }


    /***********************************************************
    Create a VFS instance for the mode, returns null on failure.
    OCSYNC_EXPORT
    ***********************************************************/
    AbstractVfs create_vfs_from_plugin (AbstractVfs.Mode mode) {
        if (mode == Mode.OFF) {
            return new VfsOff ();
        }


        var name = Mode.to_plugin_name (mode);
        if (name == "") {
            return null;
        }

        string plugin_path = plugin_filename ("vfs", name);

        if (!is_vfs_plugin_available (mode)) {
            GLib.critical ("Could not load plugin " + AbstractVfs.Mode.to_string (mode) + " because " + plugin_path + " does not exist or has bad metadata.");
            return null;
        }

        QPluginLoader loader = new QPluginLoader (plugin_path);
        var plugin = loader.instance;
        if (!plugin) {
            GLib.critical ("Could not load plugin" + plugin_path + loader.error_string);
            return null;
        }

        var factory = (PluginFactory) plugin;
        if (!factory) {
            GLib.critical ("Plugin" + loader.filename () + " does not implement PluginFactory.");
            return null;
        }

        var vfs = (AbstractVfs) factory.create (null);
        if (!vfs) {
            GLib.critical ("Plugin" + loader.filename () + " does not create a Vfs instance.");
            return null;
        }

        GLib.info ("Created VFS instance from plugin " + plugin_path);
        return vfs;
    }


    /***********************************************************
    ***********************************************************/
    //  const int OCC_DEFINE_VFS_FACTORY (name, Type) {
    //      static_assert (std.is_base_of<Vfs, Type>.value, "Please define VFS factories only for Vfs subclasses");
    //  }


    /***********************************************************
    ***********************************************************/
    void init_plugin () {
        AbstractVfs.register_plugin (name, () => {
            return new AbstractVfs ();
        });
    }


    //  Q_COREAPP_STARTUP_FUNCTION (init_plugin)

}