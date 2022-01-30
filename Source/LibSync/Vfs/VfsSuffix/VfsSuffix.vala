/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <GLib.File>
// #pragma once

// #include <QScopedPointer>

namespace Occ {

class Vfs_suffix : Vfs {

    /***********************************************************
    ***********************************************************/
    public Vfs_suffix (GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public string file_suffix () override;

    /***********************************************************
    ***********************************************************/
    public void stop () override;
    public void unregister_folder () override;

    public bool socket_api_pin_state_actions_shown () override {
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_hydrating () override;

    /***********************************************************
    ***********************************************************/
    public Result<void, string> update_metadata (string file_path, time_t modtime, int64 size, GLib.ByteArray file_id) override;

    /***********************************************************
    ***********************************************************/
    public Result<void, string> create_placeholder (SyncFileItem &item) override;
    public Result<void, string> dehydrate_placeholder (SyncFileItem &item) override;
    public Result<Vfs.ConvertToPlaceholderResult, string> convert_to_placeholder (string filename, SyncFileItem &item, string ) override;

    /***********************************************************
    ***********************************************************/
    public bool needs_metadata_update (SyncFileItem &) override {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_dehydrated_placeholder (string file_path) override;

    /***********************************************************
    ***********************************************************/
    public 
    public bool set_pin_state (string folder_path, PinState state) override {
        return set_pin_state_in_database (folder_path, state);
    }


    /***********************************************************
    ***********************************************************/
    public Optional<PinState> pin_state (string folder_path) override {
    }


    /***********************************************************
    ***********************************************************/
    public 
    public AvailabilityResult availability (string folder_path) override;


    /***********************************************************
    ***********************************************************/
    public void on_file_status_changed (string , SyncFileStatus) override {}

    protected void start_impl (VfsSetupParams &parameters) override;
};

class Suffix_vfs_plugin_factory : GLib.Object, public DefaultPluginFactory<Vfs_suffix> {
    Q_PLUGIN_METADATA (IID "org.owncloud.PluginFactory" FILE "vfspluginmetadata.json")
    Q_INTERFACES (Occ.PluginFactory)
};

    Vfs_suffix.Vfs_suffix (GLib.Object parent)
        : Vfs (parent) {
    }

    Vfs_suffix.~Vfs_suffix () = default;

    Vfs.Mode Vfs_suffix.mode () {
        return WithSuffix;
    }

    string Vfs_suffix.file_suffix () {
        return QStringLiteral (APPLICATION_DOTVIRTUALFILE_SUFFIX);
    }

    void Vfs_suffix.start_impl (VfsSetupParams &parameters) {
        // It is unsafe for the database to contain any ".owncloud" file entries
        // that are not marked as a virtual file. These could be real .owncloud
        // files that were synced before vfs was enabled.
        QByte_array_list to_wipe;
        parameters.journal.get_files_below_path ("", [&to_wipe] (SyncJournalFileRecord &record) {
            if (!record.is_virtual_file () && record._path.ends_with (APPLICATION_DOTVIRTUALFILE_SUFFIX))
                to_wipe.append (record._path);
        });
        for (var &path : to_wipe)
            parameters.journal.delete_file_record (path);
    }

    void Vfs_suffix.stop () {
    }

    void Vfs_suffix.unregister_folder () {
    }

    bool Vfs_suffix.is_hydrating () {
        return false;
    }

    Result<void, string> Vfs_suffix.update_metadata (string file_path, time_t modtime, int64, GLib.ByteArray ) {
        if (modtime <= 0) {
            return {_("Error updating metadata due to invalid modified time")};
        }

        FileSystem.set_mod_time (file_path, modtime);
        return {};
    }

    Result<void, string> Vfs_suffix.create_placeholder (SyncFileItem &item) {
        if (item._modtime <= 0) {
            return {_("Error updating metadata due to invalid modified time")};
        }

        // The concrete shape of the placeholder is also used in is_dehydrated_placeholder () below
        string fn = _setup_params.filesystem_path + item._file;
        if (!fn.ends_with (file_suffix ())) {
            ASSERT (false, "vfs file isn't ending with suffix");
            return string ("vfs file isn't ending with suffix");
        }

        GLib.File file = new GLib.File (fn);
        if (file.exists () && file.size () > 1
            && !FileSystem.verify_file_unchanged (fn, item._size, item._modtime)) {
            return string ("Cannot create a placeholder because a file with the placeholder name already exist");
        }

        if (!file.open (GLib.File.ReadWrite | GLib.File.Truncate))
            return file.error_"";

        file.write (" ");
        file.close ();
        FileSystem.set_mod_time (fn, item._modtime);
        return {};
    }

    Result<void, string> Vfs_suffix.dehydrate_placeholder (SyncFileItem &item) {
        SyncFileItem virtual_item (item);
        virtual_item._file = item._rename_target;
        var r = create_placeholder (virtual_item);
        if (!r)
            return r;

        if (item._file != item._rename_target) { // can be the same when renaming foo . foo.owncloud to dehydrate
            GLib.File.remove (_setup_params.filesystem_path + item._file);
        }

        // Move the item's pin state
        var pin = _setup_params.journal.internal_pin_states ().raw_for_path (item._file.to_utf8 ());
        if (pin && *pin != PinState.PinState.INHERITED) {
            set_pin_state (item._rename_target, *pin);
            set_pin_state (item._file, PinState.PinState.INHERITED);
        }

        // Ensure the pin state isn't contradictory
        pin = pin_state (item._rename_target);
        if (pin && *pin == PinState.PinState.ALWAYS_LOCAL)
            set_pin_state (item._rename_target, PinState.PinState.UNSPECIFIED);
        return {};
    }

    Result<Vfs.ConvertToPlaceholderResult, string> Vfs_suffix.convert_to_placeholder (string , SyncFileItem &, string ) {
        // Nothing necessary
        return Vfs.ConvertToPlaceholderResult.Ok;
    }

    bool Vfs_suffix.is_dehydrated_placeholder (string file_path) {
        if (!file_path.ends_with (file_suffix ()))
            return false;
        QFileInfo fi (file_path);
        return fi.exists () && fi.size () == 1;
    }

    bool Vfs_suffix.stat_type_virtual_file (csync_file_stat_t stat, void *) {
        if (stat.path.ends_with (file_suffix ().to_utf8 ())) {
            stat.type = ItemTypeVirtualFile;
            return true;
        }
        return false;
    }

    Vfs.AvailabilityResult Vfs_suffix.availability (string folder_path) {
        return availability_in_database (folder_path);
    }

    } // namespace Occ
    