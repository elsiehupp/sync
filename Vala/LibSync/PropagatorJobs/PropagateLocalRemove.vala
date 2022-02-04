/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
@brief Declaration of the other propagation jobs
@ingroup libsync
***********************************************************/
class PropagateLocalRemove : PropagateItemJob {

    /***********************************************************
    ***********************************************************/
    public PropagateLocalRemove (OwncloudPropagator propagator, SyncFileItemPtr item)
        : PropagateItemJob (propagator, item) {
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () override;


    /***********************************************************
    ***********************************************************/
    private bool remove_recursively (string path);
    private string this.error;
    private bool this.move_to_trash;
}



    /***********************************************************
    The code will update the database in case of error.
    If everything goes well (no error, returns true), the caller is responsible for removing the entries
    in the database.  But in case of error, we need to remove the entries from the database of the files
    that were deleted.

    \a path is relative to propagator ().local_dir + this.item.file and should on_start with a slash
    ***********************************************************/
    bool PropagateLocalRemove.remove_recursively (string path) {
        string absolute = propagator ().full_local_path (this.item.file + path);
        string[] errors;
        GLib.List<QPair<string, bool>> deleted;
        bool on_success = FileSystem.remove_recursively (
            absolute,
            [&deleted] (string path, bool is_dir) {
                // by prepending, a folder deletion may be followed by content deletions
                deleted.prepend (q_make_pair (path, is_dir));
            },
            errors);

        if (!on_success) {
            // We need to delete the entries from the database now from the deleted vector.
            // Do it while avoiding redundant delete calls to the journal.
            string deleted_dir;
            foreach (var it, deleted) {
                if (!it.first.starts_with (propagator ().local_path ()))
                    continue;
                if (!deleted_dir.is_empty () && it.first.starts_with (deleted_dir))
                    continue;
                if (it.second) {
                    deleted_dir = it.first;
                }
                propagator ().journal.delete_file_record (it.first.mid (propagator ().local_path ().size ()), it.second);
            }

            this.error = errors.join (", ");
        }
        return on_success;
    }

    void PropagateLocalRemove.on_start () {
        GLib.Info (lc_propagate_local_remove) << "Start propagate local remove job";

        this.move_to_trash = propagator ().sync_options ().move_files_to_trash;

        if (propagator ().abort_requested)
            return;

        const string filename = propagator ().full_local_path (this.item.file);
        GLib.Info (lc_propagate_local_remove) << "Going to delete:" << filename;

        if (propagator ().local_filename_clash (this.item.file)) {
            on_done (SyncFileItem.Status.NORMAL_ERROR, _("Could not remove %1 because of a local file name clash").arg (QDir.to_native_separators (filename)));
            return;
        }

        string remove_error;
        if (this.move_to_trash) {
            if ( (QDir (filename).exists () || FileSystem.file_exists (filename))
                && !FileSystem.move_to_trash (filename, remove_error)) {
                on_done (SyncFileItem.Status.NORMAL_ERROR, remove_error);
                return;
            }
        } else {
            if (this.item.is_directory ()) {
                if (QDir (filename).exists () && !remove_recursively ("")) {
                    on_done (SyncFileItem.Status.NORMAL_ERROR, this.error);
                    return;
                }
            } else {
                if (FileSystem.file_exists (filename)
                    && !FileSystem.remove (filename, remove_error)) {
                    on_done (SyncFileItem.Status.NORMAL_ERROR, remove_error);
                    return;
                }
            }
        }
        propagator ().report_progress (*this.item, 0);
        propagator ().journal.delete_file_record (this.item.original_file, this.item.is_directory ());
        propagator ().journal.commit ("Local remove");
        on_done (SyncFileItem.Status.SUCCESS);
    }