/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QScopedPointer>

namespace xattr {
    using namespace Occ.XAttr_wrapper;
}

namespace Occ {

class Vfs_xAttr : Vfs {

    /***********************************************************
    ***********************************************************/
    public Vfs_xAttr (GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public string file_suffix () override;

    /***********************************************************
    ***********************************************************/
    public void stop () override;

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public bool is_hydrating () override;

    public Result<void, string> update_metadata (string file_path, time_t modtime, int64 size, GLib.ByteArray file_identifier) override;

    public Result<void, string> create_placeholder (SyncFileItem item) override;
    public Result<void, string> dehydrate_placeholder (SyncFileItem item) override;
    public Result<ConvertToPlaceholderResult, string> convert_to_placeholder (string filename, SyncFileItem item, string replaces_file) override;

    /***********************************************************
    ***********************************************************/
    public bool needs_metadata_update (SyncFileItem item) override;
    public bool is_dehydrated_placeholder (string file_path) override;
    public bool stat_type_virtual_file (csync_file_stat_t stat, void stat_data) override;

    /***********************************************************
    ***********************************************************/
    public bool pin_state (string folder_path, PinState state) override;
    public Optional<PinState> pin_state (string folder_path) override;
    public AvailabilityResult availability (string folder_path) override;


    /***********************************************************
    ***********************************************************/
    public void on_signal_file_status_changed (string system_filename, SyncFileStatus file_status) override;


    protected void start_impl (VfsSetupParams parameters) override;
}


    Vfs_xAttr.Vfs_xAttr (GLib.Object parent)
        : Vfs (parent) {
    }

    Vfs_xAttr.~Vfs_xAttr () = default;

    Vfs.Mode Vfs_xAttr.mode () {
        return XAttr;
    }

    string Vfs_xAttr.file_suffix () {
        return "";
    }

    void Vfs_xAttr.start_impl (VfsSetupParams &) {
    }

    void Vfs_xAttr.stop () {
    }

    void Vfs_xAttr.unregister_folder () {
    }

    bool Vfs_xAttr.socket_api_pin_state_actions_shown () {
        return true;
    }

    bool Vfs_xAttr.is_hydrating () {
        return false;
    }

    Result<void, string> Vfs_xAttr.update_metadata (string file_path, time_t modtime, int64, GLib.ByteArray ) {
        if (modtime <= 0) {
            return {_("Error updating metadata due to invalid modified time")};
        }

        FileSystem.mod_time (file_path, modtime);
        return {};
    }

    Result<void, string> Vfs_xAttr.create_placeholder (SyncFileItem item) {
        if (item.modtime <= 0) {
            return {_("Error updating metadata due to invalid modified time")};
        }

        const var path = string (this.setup_params.filesystem_path + item.file);
        GLib.File file = new GLib.File (path);
        if (file.exists () && file.size () > 1
            && !FileSystem.verify_file_unchanged (path, item.size, item.modtime)) {
            return QStringLiteral ("Cannot create a placeholder because a file with the placeholder name already exist");
        }

        if (!file.open (GLib.File.ReadWrite | GLib.File.Truncate)) {
            return file.error_string ();
        }

        file.write (" ");
        file.close ();
        FileSystem.mod_time (path, item.modtime);
        return xattr.add_nextcloud_placeholder_attributes (path);
    }

    Result<void, string> Vfs_xAttr.dehydrate_placeholder (SyncFileItem item) {
        const var path = string (this.setup_params.filesystem_path + item.file);
        GLib.File file = new GLib.File (path);
        if (!file.remove ()) {
            return QStringLiteral ("Couldn't remove the original file to dehydrate");
        }
        var r = create_placeholder (item);
        if (!r) {
            return r;
        }

        // Ensure the pin state isn't contradictory
        const var pin = pin_state (item.file);
        if (pin && *pin == PinState.PinState.ALWAYS_LOCAL) {
            pin_state (item.rename_target, PinState.PinState.UNSPECIFIED);
        }
        return {};
    }

    Result<Vfs.ConvertToPlaceholderResult, string> Vfs_xAttr.convert_to_placeholder (string , SyncFileItem &, string ) {
        // Nothing necessary
        return {ConvertToPlaceholderResult.Ok};
    }

    bool Vfs_xAttr.needs_metadata_update (SyncFileItem &) {
        return false;
    }

    bool Vfs_xAttr.is_dehydrated_placeholder (string file_path) {
        const var fi = QFileInfo (file_path);
        return fi.exists () &&
                xattr.has_nextcloud_placeholder_attributes (file_path);
    }

    bool Vfs_xAttr.stat_type_virtual_file (csync_file_stat_t stat, void stat_data) {
        if (stat.type == ItemTypeDirectory) {
            return false;
        }

        const var parent_path = static_cast<GLib.ByteArray> (stat_data);
        //  Q_ASSERT (!parent_path.ends_with ('/'));
        //  Q_ASSERT (!stat.path.starts_with ('/'));

        const var path = GLib.ByteArray (*parent_path + '/' + stat.path);
        const var pin = [=] {
            const var absolute_path = string.from_utf8 (path);
            //  Q_ASSERT (absolute_path.starts_with (parameters ().filesystem_path.to_utf8 ()));
            const var folder_path = absolute_path.mid (parameters ().filesystem_path.length ());
            return pin_state (folder_path);
        } ();

        if (xattr.has_nextcloud_placeholder_attributes (path)) {
            const var should_download = pin && (*pin == PinState.PinState.ALWAYS_LOCAL);
            stat.type = should_download ? ItemTypeVirtualFileDownload : ItemTypeVirtualFile;
            return true;
        } else {
            const var should_dehydrate = pin && (*pin == PinState.VfsItemAvailability.ONLINE_ONLY);
            if (should_dehydrate) {
                stat.type = ItemTypeVirtualFileDehydration;
                return true;
            }
        }
        return false;
    }

    bool Vfs_xAttr.pin_state (string folder_path, PinState state) {
        return pin_state_in_database (folder_path, state);
    }

    Optional<PinState> Vfs_xAttr.pin_state (string folder_path) {
        return pin_state_in_database (folder_path);
    }

    Vfs.AvailabilityResult Vfs_xAttr.availability (string folder_path) {
        return availability_in_database (folder_path);
    }

    void Vfs_xAttr.on_signal_file_status_changed (string , SyncFileStatus) {
    }

    } // namespace Occ
    