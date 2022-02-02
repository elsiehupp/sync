/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
@brief The PropagateLocalRename class
@ingroup libsync
***********************************************************/
class PropagateLocalRename : PropagateItemJob {

    /***********************************************************
    ***********************************************************/
    public PropagateLocalRename (OwncloudPropagator propagator, SyncFileItemPtr item)
        : PropagateItemJob (propagator, item) {
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () override;
    public JobParallelism parallelism () override {
        return this.item.is_directory () ? WaitForFinished : FullParallelism;
    }
}





void PropagateLocalRename.on_start () {
    if (propagator ()._abort_requested)
        return;

    string existing_file = propagator ().full_local_path (propagator ().adjust_renamed_path (this.item._file));
    string target_file = propagator ().full_local_path (this.item._rename_target);

    // if the file is a file underneath a moved dir, the this.item.file is equal
    // to this.item.rename_target and the file is not moved as a result.
    if (this.item._file != this.item._rename_target) {
        propagator ().report_progress (*this.item, 0);
        GLib.debug (lc_propagate_local_rename) << "MOVE " << existing_file << " => " << target_file;

        if (string.compare (this.item._file, this.item._rename_target, Qt.CaseInsensitive) != 0
            && propagator ().local_filename_clash (this.item._rename_target)) {
            // Only use local_filename_clash for the destination if we know that the source was not
            // the one conflicting  (renaming  A.txt . a.txt is OK)

            // Fixme : the file that is the reason for the clash could be named here,
            // it would have to come out the local_filename_clash function
            on_done (SyncFileItem.Status.NORMAL_ERROR,
                _("File %1 cannot be renamed to %2 because of a local file name clash")
                    .arg (QDir.to_native_separators (this.item._file))
                    .arg (QDir.to_native_separators (this.item._rename_target)));
            return;
        }

        /* emit */ propagator ().touched_file (existing_file);
        /* emit */ propagator ().touched_file (target_file);
        string rename_error;
        if (!FileSystem.rename (existing_file, target_file, rename_error)) {
            on_done (SyncFileItem.Status.NORMAL_ERROR, rename_error);
            return;
        }
    }

    SyncJournalFileRecord old_record;
    propagator ()._journal.get_file_record (this.item._original_file, old_record);
    propagator ()._journal.delete_file_record (this.item._original_file);

    var vfs = propagator ().sync_options ()._vfs;
    var pin_state = vfs.pin_state (this.item._original_file);
    if (!vfs.set_pin_state (this.item._original_file, PinState.PinState.INHERITED)) {
        GLib.warn (lc_propagate_local_rename) << "Could not set pin state of" << this.item._original_file << "to inherited";
    }

    const var old_file = this.item._file;

    if (!this.item.is_directory ()) { // Directories are saved at the end
        SyncFileItem new_item (*this.item);
        if (old_record.is_valid ()) {
            new_item._checksum_header = old_record._checksum_header;
        }
        const var result = propagator ().update_metadata (new_item);
        if (!result) {
            on_done (SyncFileItem.Status.FATAL_ERROR, _("Error updating metadata : %1").arg (result.error ()));
            return;
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            on_done (SyncFileItem.Status.SOFT_ERROR, _("The file %1 is currently in use").arg (new_item._file));
            return;
        }
    } else {
        propagator ()._renamed_directories.insert (old_file, this.item._rename_target);
        if (!PropagateRemoteMove.adjust_selective_sync (propagator ()._journal, old_file, this.item._rename_target)) {
            on_done (SyncFileItem.Status.FATAL_ERROR, _("Failed to rename file"));
            return;
        }
    }
    if (pin_state && *pin_state != PinState.PinState.INHERITED
        && !vfs.set_pin_state (this.item._rename_target, *pin_state)) {
        on_done (SyncFileItem.Status.NORMAL_ERROR, _("Error setting pin state"));
        return;
    }

    propagator ()._journal.commit ("local_rename");

    on_done (SyncFileItem.Status.SUCCESS);
}
}