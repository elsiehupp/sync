/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QScopedPointer>

//  namespace xattr {
//      using XAttrWrapper;
//  }

namespace Occ {
namespace LibSync {

public class VfsXAttr : AbstractVfs {

    /***********************************************************
    ***********************************************************/
    public VfsXAttr (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public AbstractVfs.Mode mode () {
        return XAttr;
    }


    /***********************************************************
    ***********************************************************/
    public string file_suffix () {
        return "";
    }


    /***********************************************************
    ***********************************************************/
    public void stop () {
    }


    /***********************************************************
    ***********************************************************/
    public void unregister_folder () {
        return;
    }


    /***********************************************************
    ***********************************************************/
    public bool socket_api_pin_state_actions_shown () {
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_hydrating () {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public Result<void, string> update_metadata (string file_path, time_t modtime, int64 size, string file_identifier) {
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

        string path = this.setup_params.filesystem_path + item.file;
        GLib.File file = GLib.File.new_for_path (path);
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
        string path = this.setup_params.filesystem_path + item.file;
        GLib.File file = GLib.File.new_for_path (path);
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
        var file_info = GLib.File.new_for_path (file_path);
        return file_info.exists () &&
                xattr.has_nextcloud_placeholder_attributes (file_path);
    }


    /***********************************************************
    ***********************************************************/
    public bool stat_type_virtual_file (CSyncFileStatT stat, void stat_data) {
        if (stat.type == ItemType.DIRECTORY) {
            return false;
        }

        var parent_path = static_cast<string> (stat_data);
        GLib.assert (!parent_path.has_suffix ("/"));
        GLib.assert (!stat.path.starts_with ("/"));

        string path = parent_path + "/" + stat.path;
        var pin = () => {
            var absolute_path = string.from_utf8 (path);
            GLib.assert (absolute_path.starts_with (parameters ().filesystem_path.to_utf8 ()));
            var folder_path = absolute_path.mid (parameters ().filesystem_path.length ());
            return pin_state (folder_path);
        };

        if (xattr.has_nextcloud_placeholder_attributes (path)) {
            var should_download = pin && (*pin == PinState.PinState.ALWAYS_LOCAL);
            stat.type = should_download ? ItemType.VIRTUAL_FILE_DOWNLOAD : ItemType.VIRTUAL_FILE;
            return true;
        } else {
            var should_dehydrate = pin && (*pin == Vfs.ItemAvailability.ONLINE_ONLY);
            if (should_dehydrate) {
                stat.type = ItemType.VIRTUAL_FILE_DEHYDRATION;
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


    /***********************************************************
    ***********************************************************/
    protected void start_impl (Vfs.SetupParameters parameters) {
        return;
    }

} // class VfsXAttr

} // namespace LibSync
} // namespace Occ
    