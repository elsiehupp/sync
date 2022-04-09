namespace Occ {
namespace LibSync {

/***********************************************************
@class PropagateLocalRemove

@brief Declaration of the other propagation jobs

@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PropagateLocalRemove : AbstractPropagateItemJob {

    private string error;
    private bool move_to_trash;

    /***********************************************************
    ***********************************************************/
    public PropagateLocalRemove (OwncloudPropagator propagator, SyncFileItem item) {
        base (propagator, item);
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        GLib.info ("Start propagate local remove job");

        this.move_to_trash = this.propagator.sync_options.move_files_to_trash;

        if (this.propagator.abort_requested)
            return;

        string filename = this.propagator.full_local_path (this.item.file);
        GLib.info ("Going to delete:" + filename);

        if (this.propagator.local_filename_clash (this.item.file)) {
            on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("Could not remove %1 because of a local file name clash").printf (GLib.Dir.to_native_separators (filename)));
            return;
        }

        string remove_error;
        if (this.move_to_trash) {
            if ( (new GLib.Dir (filename).exists () || FileSystem.file_exists (filename))
                && !FileSystem.move_to_trash (filename, remove_error)) {
                on_signal_done (SyncFileItem.Status.NORMAL_ERROR, remove_error);
                return;
            }
        } else {
            if (this.item.is_directory ()) {
                if (new GLib.Dir (filename).exists () && !remove_recursively ("")) {
                    on_signal_done (SyncFileItem.Status.NORMAL_ERROR, this.error);
                    return;
                }
            } else {
                if (FileSystem.file_exists (filename)
                    && !FileSystem.remove (filename, remove_error)) {
                    on_signal_done (SyncFileItem.Status.NORMAL_ERROR, remove_error);
                    return;
                }
            }
        }
        this.propagator.report_progress (*this.item, 0);
        this.propagator.journal.delete_file_record (this.item.original_file, this.item.is_directory ());
        this.propagator.journal.commit ("Local remove");
        on_signal_done (SyncFileItem.Status.SUCCESS);
    }


    /***********************************************************
    The code will update the database in case of error.
    If everything goes well (no error, returns true), the caller is responsible for removing the entries
    in the database.  But in case of error, we need to remove the entries from the database of the files
    that were deleted.

    \a path is relative to this.propagator.local_dir + this.item.file and should start with a slash
    ***********************************************************/
    private bool remove_recursively (string path) {
        string absolute = this.propagator.full_local_path (this.item.file + path);
        GLib.List<string> errors;
        GLib.List<GLib.Pair<string, bool>> deleted;
        bool on_signal_success = FileSystem.remove_recursively (
            absolute,
            PropagateLocalRemove.recursive_remove_filter,
            errors
        );

        if (!on_signal_success) {
            // We need to delete the entries from the database now from the deleted vector.
            // Do it while avoiding redundant delete calls to the journal.
            string deleted_dir;
            foreach (var it in deleted) {
                if (!it.first.has_prefix (this.propagator.local_path))
                    continue;
                if (deleted_dir != "" && it.first.has_prefix (deleted_dir))
                    continue;
                if (it.second) {
                    deleted_dir = it.first;
                }
                this.propagator.journal.delete_file_record (it.first.mid (this.propagator.local_path.size ()), it.second);
            }

            this.error = errors.join (", ");
        }
        return on_signal_success;
    }


    private static void recursive_remove_filter (GLib.List<GLib.Pair<string, bool>> deleted, string path, bool is_dir) {
        // by prepending, a folder deletion may be followed by content deletions
        deleted.prepend (q_make_pair (path, is_dir));
    }

} // class PropagateLocalRemove

} // namespace LibSync
} // namespace Occ
