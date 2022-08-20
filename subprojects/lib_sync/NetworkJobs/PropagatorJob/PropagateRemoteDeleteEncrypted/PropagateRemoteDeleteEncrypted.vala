namespace Occ {
namespace LibSync {

/***********************************************************
@class PropagateRemoteDeleteEncrypted

@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PropagateRemoteDeleteEncrypted : AbstractPropagateRemoteDeleteEncrypted {

//    /***********************************************************
//    ***********************************************************/
//    public PropagateRemoteDeleteEncrypted (OwncloudPropagator propagator, SyncFileItem item, GLib.Object parent) {
//        base (propagator, item, parent);

//    }

//    /***********************************************************
//    ***********************************************************/
//    public new void start () {
//        GLib.assert (this.item.encrypted_filename != "");

//        start_lscol_job (GLib.File.new_for_path (this.item.encrypted_filename).path);
//    }


//    /***********************************************************
//    ***********************************************************/
//    private new void on_signal_folder_unlocked_successfully (string folder_identifier) {
//        AbstractPropagateRemoteDeleteEncrypted.on_signal_folder_unlocked_successfully (folder_identifier);
//        signal_finished (!this.is_task_failed);
//    }


//    /***********************************************************
//    ***********************************************************/
//    private new void on_signal_folder_encrypted_metadata_received (GLib.JsonDocument json, int status_code){
//        if (status_code == 404) {
//            GLib.debug (PROPAGATE_REMOVE_ENCRYPTED + "Metadata not found, but let's proceed with removing the file anyway.");
//            delete_remote_item (this.item.encrypted_filename);
//            return;
//        }

//        FolderMetadata metadata = new FolderMetadata (this.propagator.account, json.to_json (GLib.JsonDocument.Compact), status_code);

//        GLib.debug (PROPAGATE_REMOVE_ENCRYPTED + "Metadata Received, preparing it for removal of the file");

//        GLib.FileInfo info = GLib.File.new_for_path (this.propagator.full_local_path (this.item.file));
//        string filename = info.filename ();

//        // Find existing metadata for this file
//        bool found = false;
//        GLib.List<EncryptedFile> files = metadata.files ();
//        foreach (EncryptedFile file in files) {
//            if (file.original_filename == filename) {
//                metadata.remove_encrypted_file (file);
//                found = true;
//                break;
//            }
//        }

//        if (!found) {
//            // file is not found in the metadata, but we still need to remove it
//            delete_remote_item (this.item.encrypted_filename);
//            return;
//        }

//        GLib.debug (PROPAGATE_REMOVE_ENCRYPTED + "Metadata updated, sending to the server.");

//        var update_metadata_api_job = new UpdateMetadataApiJob (this.propagator.account, this.folder_identifier, metadata.encrypted_metadata (), this.folder_token);
//        update_metadata_api_job.signal_success.connect (
//            this.on_signal_update_metadata_api_job_success
//        );
//        update_metadata_api_job.signal_error.connect (
//            this.on_signal_task_failed
//        );
//        update_metadata_api_job.start ();
//    }


//    private void on_signal_update_metadata_api_job_success (string file_identifier) {
//        //  Q_UNUSED (file_identifier);
//        delete_remote_item (this.item.encrypted_filename);
//    }

} // class PropagateRemoteDeleteEncrypted

} // namespace LibSync
} // namespace Occ
