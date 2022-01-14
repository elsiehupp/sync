/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFile>
// #pragma once

// #include <GLib.Object>
// #include <QScopedPointer>

namespace Occ {

class Vfs_suffix : Vfs {

public:
    Vfs_suffix (GLib.Object *parent = nullptr);
    ~Vfs_suffix () override;

    Mode mode () const override;
    string file_suffix () const override;

    void stop () override;
    void unregister_folder () override;

    bool socket_api_pin_state_actions_shown () const override { return true; }
    bool is_hydrating () const override;

    Result<void, string> update_metadata (string &file_path, time_t modtime, int64 size, QByteArray &file_id) override;

    Result<void, string> create_placeholder (SyncFileItem &item) override;
    Result<void, string> dehydrate_placeholder (SyncFileItem &item) override;
    Result<Vfs.ConvertToPlaceholderResult, string> convert_to_placeholder (string &filename, SyncFileItem &item, string &) override;

    bool needs_metadata_update (SyncFileItem &) override { return false; }
    bool is_dehydrated_placeholder (string &file_path) override;
    bool stat_type_virtual_file (csync_file_stat_t *stat, void *stat_data) override;

    bool set_pin_state (string &folder_path, PinState state) override { return set_pin_state_in_db (folder_path, state); } {ptional<PinState> pin_state (string &folder_path) override
    { return pin_state_in_db (folder_path); }
    AvailabilityResult availability (string &folder_path) override;

public slots:
    void file_status_changed (string &, SyncFileStatus) override {}

protected:
    void start_impl (VfsSetupParams &params) override;
};

class Suffix_vfs_plugin_factory : GLib.Object, public DefaultPluginFactory<Vfs_suffix> {
    Q_PLUGIN_METADATA (IID "org.owncloud.PluginFactory" FILE "vfspluginmetadata.json")
    Q_INTERFACES (Occ.PluginFactory)
};

    Vfs_suffix.Vfs_suffix (GLib.Object *parent)
        : Vfs (parent) {
    }
    
    Vfs_suffix.~Vfs_suffix () = default;
    
    Vfs.Mode Vfs_suffix.mode () {
        return WithSuffix;
    }
    
    string Vfs_suffix.file_suffix () {
        return QStringLiteral (APPLICATION_DOTVIRTUALFILE_SUFFIX);
    }
    
    void Vfs_suffix.start_impl (VfsSetupParams &params) {
        // It is unsafe for the database to contain any ".owncloud" file entries
        // that are not marked as a virtual file. These could be real .owncloud
        // files that were synced before vfs was enabled.
        QByte_array_list to_wipe;
        params.journal.get_files_below_path ("", [&to_wipe] (SyncJournalFileRecord &rec) {
            if (!rec.is_virtual_file () && rec._path.ends_with (APPLICATION_DOTVIRTUALFILE_SUFFIX))
                to_wipe.append (rec._path);
        });
        for (auto &path : to_wipe)
            params.journal.delete_file_record (path);
    }
    
    void Vfs_suffix.stop () {
    }
    
    void Vfs_suffix.unregister_folder () {
    }
    
    bool Vfs_suffix.is_hydrating () {
        return false;
    }
    
    Result<void, string> Vfs_suffix.update_metadata (string &file_path, time_t modtime, int64, QByteArray &) {
        if (modtime <= 0) {
            return {tr ("Error updating metadata due to invalid modified time")};
        }
    
        FileSystem.set_mod_time (file_path, modtime);
        return {};
    }
    
    Result<void, string> Vfs_suffix.create_placeholder (SyncFileItem &item) {
        if (item._modtime <= 0) {
            return {tr ("Error updating metadata due to invalid modified time")};
        }
    
        // The concrete shape of the placeholder is also used in is_dehydrated_placeholder () below
        string fn = _setup_params.filesystem_path + item._file;
        if (!fn.ends_with (file_suffix ())) {
            ASSERT (false, "vfs file isn't ending with suffix");
            return string ("vfs file isn't ending with suffix");
        }
    
        QFile file (fn);
        if (file.exists () && file.size () > 1
            && !FileSystem.verify_file_unchanged (fn, item._size, item._modtime)) {
            return string ("Cannot create a placeholder because a file with the placeholder name already exist");
        }
    
        if (!file.open (QFile.ReadWrite | QFile.Truncate))
            return file.error_string ();
    
        file.write (" ");
        file.close ();
        FileSystem.set_mod_time (fn, item._modtime);
        return {};
    }
    
    Result<void, string> Vfs_suffix.dehydrate_placeholder (SyncFileItem &item) {
        SyncFileItem virtual_item (item);
        virtual_item._file = item._rename_target;
        auto r = create_placeholder (virtual_item);
        if (!r)
            return r;
    
        if (item._file != item._rename_target) { // can be the same when renaming foo . foo.owncloud to dehydrate
            QFile.remove (_setup_params.filesystem_path + item._file);
        }
    
        // Move the item's pin state
        auto pin = _setup_params.journal.internal_pin_states ().raw_for_path (item._file.to_utf8 ());
        if (pin && *pin != PinState.Inherited) {
            set_pin_state (item._rename_target, *pin);
            set_pin_state (item._file, PinState.Inherited);
        }
    
        // Ensure the pin state isn't contradictory
        pin = pin_state (item._rename_target);
        if (pin && *pin == PinState.AlwaysLocal)
            set_pin_state (item._rename_target, PinState.Unspecified);
        return {};
    }
    
    Result<Vfs.ConvertToPlaceholderResult, string> Vfs_suffix.convert_to_placeholder (string &, SyncFileItem &, string &) {
        // Nothing necessary
        return Vfs.ConvertToPlaceholderResult.Ok;
    }
    
    bool Vfs_suffix.is_dehydrated_placeholder (string &file_path) {
        if (!file_path.ends_with (file_suffix ()))
            return false;
        QFileInfo fi (file_path);
        return fi.exists () && fi.size () == 1;
    }
    
    bool Vfs_suffix.stat_type_virtual_file (csync_file_stat_t *stat, void *) {
        if (stat.path.ends_with (file_suffix ().to_utf8 ())) {
            stat.type = Item_type_virtual_file;
            return true;
        }
        return false;
    }
    
    Vfs.AvailabilityResult Vfs_suffix.availability (string &folder_path) {
        return availability_in_db (folder_path);
    }
    
    } // namespace Occ
    