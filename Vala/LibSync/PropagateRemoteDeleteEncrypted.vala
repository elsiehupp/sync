/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QFileInfo>

using namespace Occ;


// #pragma once

namespace Occ {

class Propagate_remote_delete_encrypted : AbstractPropagateRemoteDeleteEncrypted {

    /***********************************************************
    ***********************************************************/
    public Propagate_remote_delete_encrypted (OwncloudPropagator propagator, SyncFileItemPtr item, GLib.Object parent);

    /***********************************************************
    ***********************************************************/
    public void on_start () override;


    /***********************************************************
    ***********************************************************/
    private void on_folder_un_locked_successfully (GLib.ByteArray folder_id) override;
    private void on_folder_encrypted_metadata_received (QJsonDocument json, int status_code) override;
}

}







Propagate_remote_delete_encrypted.Propagate_remote_delete_encrypted (OwncloudPropagator propagator, SyncFileItemPtr item, GLib.Object parent)
    : AbstractPropagateRemoteDeleteEncrypted (propagator, item, parent) {

}

void Propagate_remote_delete_encrypted.on_start () {
    Q_ASSERT (!this.item._encrypted_filename.is_empty ());

    const QFileInfo info (this.item._encrypted_filename);
    start_ls_col_job (info.path ());
}

void Propagate_remote_delete_encrypted.on_folder_un_locked_successfully (GLib.ByteArray folder_id) {
    AbstractPropagateRemoteDeleteEncrypted.on_folder_un_locked_successfully (folder_id);
    /* emit */ finished (!this.is_task_failed);
}

void Propagate_remote_delete_encrypted.on_folder_encrypted_metadata_received (QJsonDocument json, int status_code) {
    if (status_code == 404) {
        GLib.debug (PROPAGATE_REMOVE_ENCRYPTED) << "Metadata not found, but let's proceed with removing the file anyway.";
        delete_remote_item (this.item._encrypted_filename);
        return;
    }

    FolderMetadata metadata (this.propagator.account (), json.to_json (QJsonDocument.Compact), status_code);

    GLib.debug (PROPAGATE_REMOVE_ENCRYPTED) << "Metadata Received, preparing it for removal of the file";

    const QFileInfo info (this.propagator.full_local_path (this.item._file));
    const string filename = info.filename ();

    // Find existing metadata for this file
    bool found = false;
    const GLib.Vector<EncryptedFile> files = metadata.files ();
    for (EncryptedFile file : files) {
        if (file.original_filename == filename) {
            metadata.remove_encrypted_file (file);
            found = true;
            break;
        }
    }

    if (!found) {
        // file is not found in the metadata, but we still need to remove it
        delete_remote_item (this.item._encrypted_filename);
        return;
    }

    GLib.debug (PROPAGATE_REMOVE_ENCRYPTED) << "Metadata updated, sending to the server.";

    var job = new UpdateMetadataApiJob (this.propagator.account (), this.folder_id, metadata.encrypted_metadata (), this.folder_token);
    connect (job, &UpdateMetadataApiJob.on_success, this, [this] (GLib.ByteArray file_identifier) {
        Q_UNUSED (file_identifier);
        delete_remote_item (this.item._encrypted_filename);
    });
    connect (job, &UpdateMetadataApiJob.error, this, &Propagate_remote_delete_encrypted.task_failed);
    job.on_start ();
}
