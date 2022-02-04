/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
@brief The PropagateLocalMkdir class
@ingroup libsync
***********************************************************/
class PropagateLocalMkdir : PropagateItemJob {

    /***********************************************************
    ***********************************************************/
    public PropagateLocalMkdir (OwncloudPropagator propagator, SyncFileItemPtr item)
        : PropagateItemJob (propagator, item)
        this.delete_existing_file (false) {
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () override;


    /***********************************************************
    Whether an existing file with the same name may be deleted before
    creating the directory.

    Default: false.
    ***********************************************************/
    public void set_delete_existing_file (bool enabled);


    /***********************************************************
    ***********************************************************/
    private void start_local_mkdir ();

    /***********************************************************
    ***********************************************************/
    private 
    private bool this.delete_existing_file;
}





void PropagateLocalMkdir.on_start () {
    if (propagator ().abort_requested)
        return;

    start_local_mkdir ();
}

void PropagateLocalMkdir.set_delete_existing_file (bool enabled) {
    this.delete_existing_file = enabled;
}

void PropagateLocalMkdir.start_local_mkdir () {
    QDir new_dir (propagator ().full_local_path (this.item.file));
    string new_dir_str = QDir.to_native_separators (new_dir.path ());

    // When turning something that used to be a file into a directory
    // we need to delete the file first.
    QFileInfo fi (new_dir_str);
    if (fi.exists () && fi.is_file ()) {
        if (this.delete_existing_file) {
            string remove_error;
            if (!FileSystem.remove (new_dir_str, remove_error)) {
                on_done (SyncFileItem.Status.NORMAL_ERROR,
                    _("could not delete file %1, error : %2")
                        .arg (new_dir_str, remove_error));
                return;
            }
        } else if (this.item.instruction == CSYNC_INSTRUCTION_CONFLICT) {
            string error;
            if (!propagator ().create_conflict (this.item, this.associated_composite, error)) {
                on_done (SyncFileItem.Status.SOFT_ERROR, error);
                return;
            }
        }
    }

    if (Utility.fs_case_preserving () && propagator ().local_filename_clash (this.item.file)) {
        GLib.warn (lc_propagate_local_mkdir) << "New folder to create locally already exists with different case:" << this.item.file;
        on_done (SyncFileItem.Status.NORMAL_ERROR, _("Attention, possible case sensitivity clash with %1").arg (new_dir_str));
        return;
    }
    /* emit */ propagator ().touched_file (new_dir_str);
    QDir local_dir (propagator ().local_path ());
    if (!local_dir.mkpath (this.item.file)) {
        on_done (SyncFileItem.Status.NORMAL_ERROR, _("Could not create folder %1").arg (new_dir_str));
        return;
    }

    // Insert the directory into the database. The correct etag will be set later,
    // once all contents have been propagated, because should_update_metadata is true.
    // Adding an entry with a dummy etag to the database still makes sense here
    // so the database is aware that this folder exists even if the sync is aborted
    // before the correct etag is stored.
    SyncFileItem new_item (*this.item);
    new_item.etag = "this.invalid_";
    const var result = propagator ().update_metadata (new_item);
    if (!result) {
        on_done (SyncFileItem.Status.FATAL_ERROR, _("Error updating metadata : %1").arg (result.error ()));
        return;
    } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
        on_done (SyncFileItem.Status.SOFT_ERROR, _("The file %1 is currently in use").arg (new_item.file));
        return;
    }
    propagator ().journal.commit ("local_mkdir");

    var result_status = this.item.instruction == CSYNC_INSTRUCTION_CONFLICT
        ? SyncFileItem.Status.CONFLICT
        : SyncFileItem.Status.SUCCESS;
    on_done (result_status);
}