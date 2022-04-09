namespace Occ {
namespace Common {

/***********************************************************
@class VfsOff

@brief Implementation of AbstractVfs for VfsMode.OFF mode - does nothing

@author Christian Kamm <mail@ckamm.de>
@author Dominik Schmidt <dschmidt@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class VfsOff : AbstractVfs {

    /***********************************************************
    ***********************************************************/
    public VfsOff (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public override VfsMode mode () {
        return VfsMode.OFF;
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
    public override bool stat_type_virtual_file (CSync.CSync.FileStat csync_file_stat, void *stat_data) {
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
        return ItemAvailability.PinState.ALWAYS_LOCAL;
    }


    /***********************************************************
    ***********************************************************/
    public override void on_signal_file_status_changed (string system_filename, SyncFileStatus file_status) {
        return;
    }


    /***********************************************************
    ***********************************************************/
    protected override void start_impl (SetupParameters setup_parameters) {
        return;
    }


    /***********************************************************
    Check whether the plugin for the mode is available.
    ***********************************************************/
    bool is_vfs_plugin_available (VfsMode mode) {
        // TODO: cache plugins available?
        if (mode == VfsMode.Off) {
            return true;
        }

        var name = VfsMode.to_plugin_name (mode);
        if (name == "") {
            return false;
        }

        GLib.PluginLoader loader = new GLib.PluginLoader (AbstractPluginFactory.plugin_filename ("vfs", name));

        var base_meta_data = loader.meta_data ();
        if (base_meta_data == "" || !base_meta_data.contains ("IID")) {
            GLib.debug ("Plugin " + loader.filename () + " doesn't exist.");
            return false;
        }
        if (base_meta_data["IID"].to_string () != "org.owncloud.AbstractPluginFactory") {
            GLib.warning ("Plugin " + loader.filename () + " IID " + base_meta_data["IID"] + " is incorrect");
            return false;
        }

        var metadata = base_meta_data["MetaData"].to_object ();
        if (metadata["type"].to_string () != "vfs") {
            GLib.warning ("Plugin " + loader.filename () + " metadata type " + metadata["type"] + " is incorrect");
            return false;
        }
        if (metadata["version"].to_string () != Common.Version.MIRALL_VERSION_STRING) {
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
    ***********************************************************/
    override VfsMode best_available_vfs_mode {
        get {
            if (is_vfs_plugin_available (VfsMode.WINDOWS_CF_API)) {
                return VfsMode.WINDOWS_CF_API;
            }

            if (is_vfs_plugin_available (VfsMode.WITH_SUFFIX)) {
                return VfsMode.WITH_SUFFIX;
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

            if (is_vfs_plugin_available (VfsMode.XATTR)) {
                return VfsMode.XATTR;
            }

            return VfsMode.OFF;
        }
    }


    /***********************************************************
    Create a VFS instance for the mode, returns null on failure.
    ***********************************************************/
    AbstractVfs create_vfs_from_plugin (VfsMode mode) throws VfsError {
        if (mode == VfsMode.OFF) {
            return new VfsOff ();
        }


        var name = VfsMode.to_plugin_name (mode);
        if (name == "") {
            throw new VfsError.NO_NAME_FOR_MODE (mode);
        }

        string plugin_path = AbstractPluginFactory.plugin_filename ("vfs", name);

        if (!is_vfs_plugin_available (mode)) {
            GLib.critical ("Could not load plugin " + VfsMode.to_string (mode) + " because " + plugin_path + " does not exist or has bad metadata.");
            throw new VfsError.NO_PLUGIN_FOR_MODE (mode);
        }

        GLib.PluginLoader loader = new GLib.PluginLoader (plugin_path);
        var plugin = loader.instance;
        if (!plugin) {
            GLib.critical ("Could not load plugin" + plugin_path + loader.error_string);
            throw new VfsError.NO_LOADER_FOR_PLUGIN (plugin);
        }

        var factory = (AbstractPluginFactory) plugin;
        if (!factory) {
            GLib.critical ("Plugin" + loader.filename () + " does not implement AbstractPluginFactory.");
            throw new VfsError.CAST_LOADER_TO_FACTORY_FAILED (plugin);
        }

        var vfs = (AbstractVfs) factory.create (null);
        if (!vfs) {
            GLib.critical ("Plugin" + loader.filename () + " does not create a AbstractVfs instance.");
            throw new VfsError.CAST_FACTORY_TO_VFS_FAILED (plugin);
        }

        GLib.info ("Created VFS instance from plugin " + plugin_path);
        return vfs;
    }


    /***********************************************************
    ***********************************************************/
    //  const int OCC_DEFINE_VFS_FACTORY (name, Type) {
    //      static_assert (std.is_base_of<AbstractVfs, Type>.value, "Please define VFS factories only for AbstractVfs subclasses");
    //  }


    /***********************************************************
    ***********************************************************/
    void init_plugin () {
        AbstractVfs.register_plugin (name, () => {
            return new AbstractVfs ();
        });
    }


    //  Q_COREAPP_STARTUP_FUNCTION (init_plugin)

} // class VfsOff

} // namespace Common
} // namespace Occ
