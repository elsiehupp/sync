namespace Occ {
namespace LibSync {

/***********************************************************
@class PropagateLocalRename

@brief The PropagateLocalRename class

@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PropagateLocalRename : AbstractPropagateItemJob {

    /***********************************************************
    ***********************************************************/
    public PropagateLocalRename (OwncloudPropagator propagator, SyncFileItem item) {
        base (propagator, item);
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        if (this.propagator.abort_requested)
            return;

        string existing_file = this.propagator.full_local_path (this.propagator.adjust_renamed_path (this.item.file));
        string target_file = this.propagator.full_local_path (this.item.rename_target);

        // if the file is a file underneath a moved directory, the this.item.file is equal
        // to this.item.rename_target and the file is not moved as a result.
        if (this.item.file != this.item.rename_target) {
            this.propagator.report_progress (*this.item, 0);
            GLib.debug ("MOVE " + existing_file + " => " + target_file);

            if (string.compare (this.item.file, this.item.rename_target, Qt.CaseInsensitive) != 0
                && this.propagator.local_filename_clash (this.item.rename_target)) {
                // Only use local_filename_clash for the destination if we know that the source was not
                // the one conflicting  (renaming  A.txt . a.txt is OK)

                // Fixme : the file that is the reason for the clash could be named here,
                // it would have to come out the local_filename_clash function
                on_signal_done (SyncFileItem.Status.NORMAL_ERROR,
                    _("File %1 cannot be renamed to %2 because of a local file name clash")
                        .printf (GLib.Dir.to_native_separators (this.item.file))
                        .printf (GLib.Dir.to_native_separators (this.item.rename_target)));
                return;
            }

            /* emit */ this.propagator.signal_touched_file (existing_file);
            /* emit */ this.propagator.signal_touched_file (target_file);
            string rename_error;
            if (!FileSystem.rename (existing_file, target_file, rename_error)) {
                on_signal_done (SyncFileItem.Status.NORMAL_ERROR, rename_error);
                return;
            }
        }

        SyncJournalFileRecord old_record;
        this.propagator.journal.get_file_record (this.item.original_file, old_record);
        this.propagator.journal.delete_file_record (this.item.original_file);

        var vfs = this.propagator.sync_options.vfs;
        var pin_state = vfs.pin_state (this.item.original_file);
        if (!vfs.pin_state (this.item.original_file, PinState.PinState.INHERITED)) {
            GLib.warning ("Could not set pin state of " + this.item.original_file + " to inherited.");
        }

        var old_file = this.item.file;

        if (!this.item.is_directory ()) { // Directories are saved at the end
            SyncFileItem signal_new_item = new SyncFileItem (*this.item);
            if (old_record.is_valid) {
                signal_new_item.checksum_header = old_record.checksum_header;
            }
            var result = this.propagator.update_metadata (signal_new_item);
            if (!result) {
                on_signal_done (SyncFileItem.Status.FATAL_ERROR, _("Error updating metadata : %1").printf (result.error));
                return;
            } else if (*result == AbstractVfs.ConvertToPlaceholderResult.Locked) {
                on_signal_done (SyncFileItem.Status.SOFT_ERROR, _("The file %1 is currently in use").printf (signal_new_item.file));
                return;
            }
        } else {
            this.propagator.renamed_directories.insert (old_file, this.item.rename_target);
            if (!PropagateRemoteMove.adjust_selective_sync (this.propagator.journal, old_file, this.item.rename_target)) {
                on_signal_done (SyncFileItem.Status.FATAL_ERROR, _("Failed to rename file"));
                return;
            }
        }
        if (pin_state && *pin_state != PinState.PinState.INHERITED
            && !vfs.pin_state (this.item.rename_target, *pin_state)) {
            on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("Error setting pin state"));
            return;
        }

        this.propagator.journal.commit ("local_rename");

        on_signal_done (SyncFileItem.Status.SUCCESS);
    }


    public new JobParallelism parallelism () {
        return this.item.is_directory () ? JobParallelism.WAIT_FOR_FINISHED : JobParallelism.FULL_PARALLELISM;
    }

} // class PropagateLocalRenames

} // namespace LibSync
} // namespace Occ
