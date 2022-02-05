/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>
Copyright (C) by Dominik Schmidt <dschmidt@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

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
    public bool pin_state (string , PinState) override {
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

        var name = Mode.to_plugin_name (mode);
        if (name.is_empty ()) {
            return false;
        }

        QPluginLoader loader (plugin_filename ("vfs", name));

        const var base_meta_data = loader.meta_data ();
        if (base_meta_data.is_empty () || !base_meta_data.contains ("IID")) {
            GLib.debug (lc_plugin) << "Plugin doesn't exist" << loader.filename ();
            return false;
        }
        if (base_meta_data["IID"].to_string () != "org.owncloud.PluginFactory") {
            GLib.warn (lc_plugin) << "Plugin has wrong IID" << loader.filename () << base_meta_data["IID"];
            return false;
        }

        const var metadata = base_meta_data["MetaData"].to_object ();
        if (metadata["type"].to_string () != "vfs") {
            GLib.warn (lc_plugin) << "Plugin has wrong type" << loader.filename () << metadata["type"];
            return false;
        }
        if (metadata["version"].to_string () != MIRALL_VERSION_STRING) {
            GLib.warn (lc_plugin) << "Plugin has wrong version" << loader.filename () << metadata["version"];
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
    Create a VFS instance for the mode, returns null on failure.
    OCSYNC_EXPORT
    ***********************************************************/
    std.unique_ptr<Vfs> create_vfs_from_plugin (Vfs.Mode mode) {
        if (mode == Vfs.Off)
            return std.unique_ptr<Vfs> (new VfsOff);

        var name = Mode.to_plugin_name (mode);
        if (name.is_empty ()) {
            return null;
        }

        const var plugin_path = plugin_filename ("vfs", name);

        if (!is_vfs_plugin_available (mode)) {
            q_c_critical (lc_plugin) << "Could not load plugin : not existant or bad metadata" << plugin_path;
            return null;
        }

        QPluginLoader loader (plugin_path);
        var plugin = loader.instance ();
        if (!plugin) {
            q_c_critical (lc_plugin) << "Could not load plugin" << plugin_path << loader.error_string ();
            return null;
        }

        var factory = qobject_cast<PluginFactory> (plugin);
        if (!factory) {
            q_c_critical (lc_plugin) << "Plugin" << loader.filename () << "does not implement PluginFactory";
            return null;
        }

        var vfs = std.unique_ptr<Vfs> (qobject_cast<Vfs> (factory.create (null)));
        if (!vfs) {
            q_c_critical (lc_plugin) << "Plugin" << loader.filename () << "does not create a Vfs instance";
            return null;
        }

        GLib.info (lc_plugin) << "Created VFS instance from plugin" << plugin_path;
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