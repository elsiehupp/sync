/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QScopedPointer>

//  namespace xattr {
//      using namespace Occ.XAttr_wrapper;
//  }

namespace Occ {

class Vfs_xAttr : Vfs {

    /***********************************************************
    ***********************************************************/
    public Vfs_xAttr (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }

    /***********************************************************
    ***********************************************************/
    public Vfs.Mode mode () {
        return XAttr;
    }

    /***********************************************************
    ***********************************************************/
    public string file_suffix () {
        return "";
    }

    /***********************************************************
    ***********************************************************/
    public void stop ();
    void Vfs_xAttr.stop () {
    }


    /***********************************************************
    ***********************************************************/
    public 
    void Vfs_xAttr.unregister_folder () {
    }

    bool Vfs_xAttr.socket_api_pin_state_actions_shown () {
        return true;
    }

    /***********************************************************
    ***********************************************************/
    public bool is_hydrating () {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public Result<void, string> update_metadata (string file_path, time_t modtime, int64 size, GLib.ByteArray file_identifier) {
        if (modtime <= 0) {
            return new Result<void, string>.from_error (_("Error updating metadata due to invalid modified time."));
        }

        FileSystem.mod_time (file_path, modtime);
        return new Result<void, string> ();
    }


    /***********************************************************
    ***********************************************************/
    public Result<void, string> create_placeholder (SyncFileItem item) {
        if (item.modtime <= 0) {
            return new Result<void, string>.from_error (_("Error updating metadata due to invalid modified time."));
        }

        var path = string (this.setup_params.filesystem_path + item.file);
        GLib.File file = new GLib.File (path);
        if (file.exists () && file.size () > 1
            && !FileSystem.verify_file_unchanged (path, item.size, item.modtime)) {
            return new Result<void, string>.from_error (_("Cannot create a placeholder because a file with the placeholder name already exists."));
        }

        if (!file.open (GLib.File.ReadWrite | GLib.File.Truncate)) {
            return file.error_string ();
        }

        file.write (" ");
        file.close ();
        FileSystem.mod_time (path, item.modtime);
        return xattr.add_nextcloud_placeholder_attributes (path);
    }


    /***********************************************************
    ***********************************************************/
    public Result<void, string> dehydrate_placeholder (SyncFileItem item) {
        var path = string (this.setup_params.filesystem_path + item.file);
        GLib.File file = new GLib.File (path);
        if (!file.remove ()) {
            return new Result<void, string>.from_error (_("Couldn't remove the original file to dehydrate."));
        }
        var r = create_placeholder (item);
        if (!r) {
            return r;
        }

        // Ensure the pin state isn't contradictory
        var pin = pin_state (item.file);
        if (pin && *pin == PinState.PinState.ALWAYS_LOCAL) {
            pin_state (item.rename_target, PinState.PinState.UNSPECIFIED);
        }
        return new Result<void, string> ();
    }


    /***********************************************************
    ***********************************************************/
    public Result<ConvertToPlaceholderResult, string> convert_to_placeholder (string filename, SyncFileItem item, string replaces_file) {
        // Nothing necessary
        return new Result<ConvertToPlaceholderResult, string>.from_result (ConvertToPlaceholderResult.Ok);
    }


    /***********************************************************
    ***********************************************************/
    public bool needs_metadata_update (SyncFileItem item){
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_dehydrated_placeholder (string file_path) {
        var file_info = QFileInfo (file_path);
        return file_info.exists () &&
                xattr.has_nextcloud_placeholder_attributes (file_path);
    }


    /***********************************************************
    ***********************************************************/
    public bool stat_type_virtual_file (csync_file_stat_t stat, void stat_data) {
        if (stat.type == ItemTypeDirectory) {
            return false;
        }

        var parent_path = static_cast<GLib.ByteArray> (stat_data);
        //  Q_ASSERT (!parent_path.ends_with ('/'));
        //  Q_ASSERT (!stat.path.starts_with ('/'));

        var path = new GLib.ByteArray (*parent_path + '/' + stat.path);
        var pin = () => {
            var absolute_path = string.from_utf8 (path);
            //  Q_ASSERT (absolute_path.starts_with (parameters ().filesystem_path.to_utf8 ()));
            var folder_path = absolute_path.mid (parameters ().filesystem_path.length ());
            return pin_state (folder_path);
        };

        if (xattr.has_nextcloud_placeholder_attributes (path)) {
            var should_download = pin && (*pin == PinState.PinState.ALWAYS_LOCAL);
            stat.type = should_download ? ItemTypeVirtualFileDownload : ItemTypeVirtualFile;
            return true;
        } else {
            var should_dehydrate = pin && (*pin == PinState.VfsItemAvailability.ONLINE_ONLY);
            if (should_dehydrate) {
                stat.type = ItemTypeVirtualFileDehydration;
                return true;
            }
        }
        return false;
    }

    /***********************************************************
    ***********************************************************/
    //  public bool pin_state (string folder_path, PinState state) {
    //      return pin_state_in_database (folder_path, state);
    //  }



    /***********************************************************
    ***********************************************************/
    public Optional<PinState> pin_state (string folder_path) {
        return pin_state_in_database (folder_path);
    }


    /***********************************************************
    ***********************************************************/
    public AvailabilityResult availability (string folder_path) {
        return availability_in_database (folder_path);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_file_status_changed (string system_filename, SyncFileStatus file_status) {
        return;
    }


    protected void start_impl (VfsSetupParams parameters) {
        return;
    }

} // class Vfs_xAttr

} // namespace Occ
    