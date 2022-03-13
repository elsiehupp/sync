/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <GLib.FileInfo>

namespace Occ {
namespace LibSync {

public class PropagateRemoteCeleteEncrypted : AbstractPropagateRemoteDeleteEncrypted {

    /***********************************************************
    ***********************************************************/
    public PropagateRemoteCeleteEncrypted (OwncloudPropagator propagator, SyncFileItemPtr item, GLib.Object parent) {
        base (propagator, item, parent);

    }

    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        //  Q_ASSERT (!this.item.encrypted_filename.is_empty ());

        const GLib.FileInfo info = new GLib.FileInfo (this.item.encrypted_filename);
        start_ls_col_job (info.path ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_unlocked_successfully (GLib.ByteArray folder_identifier) {
        AbstractPropagateRemoteDeleteEncrypted.on_signal_folder_unlocked_successfully (folder_identifier);
        /* emit */ finished (!this.is_task_failed);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_encrypted_metadata_received (QJsonDocument json, int status_code){
        if (status_code == 404) {
            GLib.debug (PROPAGATE_REMOVE_ENCRYPTED + "Metadata not found, but let's proceed with removing the file anyway.");
            delete_remote_item (this.item.encrypted_filename);
            return;
        }

        FolderMetadata metadata = new FolderMetadata (this.propagator.account (), json.to_json (QJsonDocument.Compact), status_code);

        GLib.debug (PROPAGATE_REMOVE_ENCRYPTED + "Metadata Received, preparing it for removal of the file");

        const GLib.FileInfo info = new GLib.FileInfo (this.propagator.full_local_path (this.item.file));
        const string filename = info.filename ();

        // Find existing metadata for this file
        bool found = false;
        const GLib.List<EncryptedFile> files = metadata.files ();
        foreach (EncryptedFile file in files) {
            if (file.original_filename == filename) {
                metadata.remove_encrypted_file (file);
                found = true;
                break;
            }
        }

        if (!found) {
            // file is not found in the metadata, but we still need to remove it
            delete_remote_item (this.item.encrypted_filename);
            return;
        }

        GLib.debug (PROPAGATE_REMOVE_ENCRYPTED + "Metadata updated, sending to the server.");

        var job = new UpdateMetadataApiJob (this.propagator.account (), this.folder_identifier, metadata.encrypted_metadata (), this.folder_token);
        connect (job, UpdateMetadataApiJob.on_signal_success, this, (GLib.ByteArray file_identifier) {
            //  Q_UNUSED (file_identifier);
            delete_remote_item (this.item.encrypted_filename);
        });
        connect (job, UpdateMetadataApiJob.error, this, PropagateRemoteCeleteEncrypted.task_failed);
        job.on_signal_start ();
    }

} // class PropagateRemoteCeleteEncrypted

} // namespace LibSync
} // namespace Occ
