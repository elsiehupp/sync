/***********************************************************
@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>
@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The PropagateLocalMkdir class
@ingroup libsync
***********************************************************/
public class PropagateLocalMkdir : PropagateItemJob {

    /***********************************************************
    Whether an existing file with the same name may be deleted before
    creating the directory.

    Default: false.
    ***********************************************************/
    bool delete_existing_file { public get; private set; }

    /***********************************************************
    ***********************************************************/
    public PropagateLocalMkdir (OwncloudPropagator propagator, SyncFileItem item) {
        base (propagator, item);
        this.delete_existing_file = false;
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        if (this.propagator.abort_requested)
            return;

        start_local_mkdir ();
    }


    /***********************************************************
    ***********************************************************/
    private void start_local_mkdir () {
        GLib.Dir new_dir = new GLib.Dir (this.propagator.full_local_path (this.item.file));
        string new_dir_str = GLib.Dir.to_native_separators (new_dir.path);

        // When turning something that used to be a file into a directory
        // we need to delete the file first.
        GLib.FileInfo file_info = GLib.File.new_for_path (new_dir_str);
        if (file_info.exists () && file_info.is_file ()) {
            if (this.delete_existing_file) {
                string remove_error;
                if (!FileSystem.remove (new_dir_str, remove_error)) {
                    on_signal_done (SyncFileItem.Status.NORMAL_ERROR,
                        _("could not delete file %1, error : %2")
                            .printf (new_dir_str, remove_error));
                    return;
                }
            } else if (this.item.instruction == CSync.SyncInstructions.CONFLICT) {
                string error;
                if (!this.propagator.create_conflict (this.item, this.associated_composite, error)) {
                    on_signal_done (SyncFileItem.Status.SOFT_ERROR, error);
                    return;
                }
            }
        }

        if (Utility.fs_case_preserving () && this.propagator.local_filename_clash (this.item.file)) {
            GLib.warning ("New folder to create locally already exists with different case:" + this.item.file);
            on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("Attention, possible case sensitivity clash with %1").printf (new_dir_str));
            return;
        }
        /* emit */ this.propagator.signal_touched_file (new_dir_str);
        GLib.Dir local_dir = new GLib.Dir (this.propagator.local_path);
        if (!local_dir.mkpath (this.item.file)) {
            on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("Could not create folder %1").printf (new_dir_str));
            return;
        }

        // Insert the directory into the database. The correct etag will be set later,
        // once all contents have been propagated, because should_update_metadata is true.
        // Adding an entry with a dummy etag to the database still makes sense here
        // so the database is aware that this folder exists even if the sync is aborted
        // before the correct etag is stored.
        SyncFileItem signal_new_item = new SyncFileItem (this.item);
        signal_new_item.etag = "this.invalid_";
        var result = this.propagator.update_metadata (signal_new_item);
        if (!result) {
            on_signal_done (SyncFileItem.Status.FATAL_ERROR, _("Error updating metadata : %1").printf (result.error));
            return;
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            on_signal_done (SyncFileItem.Status.SOFT_ERROR, _("The file %1 is currently in use").printf (signal_new_item.file));
            return;
        }
        this.propagator.journal.commit ("local_mkdir");

        var result_status = this.item.instruction == CSync.SyncInstructions.CONFLICT
            ? SyncFileItem.Status.CONFLICT
            : SyncFileItem.Status.SUCCESS;
        on_signal_done (result_status);
    }

} // class PropagateLocalMkdir

} // namespace LibSync
} // namespace Occ
