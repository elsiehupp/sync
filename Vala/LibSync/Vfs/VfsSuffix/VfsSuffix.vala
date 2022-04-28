namespace Occ {
namespace LibSync {

/***********************************************************
@class VfsSuffix

@author Christian Kamm <mail@ckamm.de>

@copyright GPLv3 or Later
***********************************************************/
public class VfsSuffix : Common.AbstractVfs {

    /***********************************************************
    ***********************************************************/
    public VfsSuffix (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public Common.VfsMode mode () {
        return WithSuffix;
    }


    /***********************************************************
    ***********************************************************/
    public string file_suffix () {
        return APPLICATION_DOTVIRTUALFILE_SUFFIX;
    }


    /***********************************************************
    ***********************************************************/
    public void stop () {
        return;
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
            return new Result<void, string>.from_error(_("Error updating metadata due to invalid modified time"));
        }

        FileSystem.mod_time (file_path, modtime);
        return new Result<void, string> ();
    }


    /***********************************************************
    ***********************************************************/
    public Result<void, string> create_placeholder (SyncFileItem item) {
        if (item.modtime <= 0) {
            return new Result<void, string>.from_error(_("Error updating metadata due to invalid modified time"));
        }

        // The concrete shape of the placeholder is also used in is_dehydrated_placeholder () below
        string fn = this.setup_params.filesystem_path + item.file;
        if (!fn.has_suffix (file_suffix ())) {
            //  GLib.assert_true (false, "vfs file isn't ending with suffix");
            return "vfs file isn't ending with suffix";
        }

        GLib.File file = GLib.File.new_for_path (fn);
        if (file.exists () && file.size () > 1
            && !FileSystem.verify_file_unchanged (fn, item.size, item.modtime)) {
            return "Cannot create a placeholder because a file with the placeholder name already exist";
        }

        if (!file.open (GLib.File.ReadWrite | GLib.File.Truncate))
            return file.error_string;

        file.write (" ");
        file.close ();
        FileSystem.mod_time (fn, item.modtime);
        return {};
    }


    /***********************************************************
    ***********************************************************/
    public Result<void, string> dehydrate_placeholder (SyncFileItem item) {
        SyncFileItem virtual_item = new SyncFileItem (item);
        virtual_item.file = item.rename_target;
        var r = create_placeholder (virtual_item);
        if (!r)
            return r;

        if (item.file != item.rename_target) { // can be the same when renaming foo . foo.owncloud to dehydrate
            GLib.File.remove (this.setup_params.filesystem_path + item.file);
        }

        // Move the item's pin state
        var pin = this.setup_params.journal.internal_pin_states.raw_for_path (item.file.to_utf8 ());
        if (pin && *pin != PinState.PinState.INHERITED) {
            pin_state (item.rename_target, *pin);
            pin_state (item.file, PinState.PinState.INHERITED);
        }

        // Ensure the pin state isn't contradictory
        pin = pin_state (item.rename_target);
        if (pin && *pin == PinState.PinState.ALWAYS_LOCAL)
            pin_state (item.rename_target, PinState.PinState.UNSPECIFIED);
        return {};
    }


    /***********************************************************
    ***********************************************************/
    public Result<AbstractVfs.ConvertToPlaceholderResult, string> convert_to_placeholder (string filename, SyncFileItem item, string value) {
        // Nothing necessary
        return AbstractVfs.ConvertToPlaceholderResult.Ok;
    }


    /***********************************************************
    ***********************************************************/
    public bool needs_metadata_update (SyncFileItem item) {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_dehydrated_placeholder (string file_path) {
        if (!file_path.has_suffix (file_suffix ()))
            return false;
        GLib.FileInfo file_info = GLib.File.new_for_path (file_path);
        return file_info.exists () && file_info.size () == 1;
    }


    /***********************************************************
    ***********************************************************/
    public bool stat_type_virtual_file (CSync.FileStat stat, void stat_data) {
        if (stat.path.has_suffix (file_suffix ().to_utf8 ())) {
            stat.type = ItemType.VIRTUAL_FILE;
            return true;
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
        return new Optional<PinState> (null);
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
    protected void start_impl (Common.SetupParameters parameters) {
        // It is unsafe for the database to contain any ".owncloud" file entries
        // that are not marked as a virtual file. These could be real .owncloud
        // files that were synced before vfs was enabled.
        GLib.List<string> to_wipe;
        parameters.journal.get_files_below_path (
            "",
            VfsSuffix.record_filter
        );
        foreach (var path in to_wipe) {
            parameters.journal.delete_file_record (path);
        }
    }


    private static void record_filter (GLib.List<string> to_wipe, SyncJournalFileRecord record) {
        if (!record.is_virtual_file () && record.path.has_suffix (APPLICATION_DOTVIRTUALFILE_SUFFIX)) {
            to_wipe.append (record.path);
        }
    }

} // class VfsSuffix

} // namespace LibSync
} // namespace Occ
