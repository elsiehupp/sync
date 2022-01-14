/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QFileInfo>

using namespace Occ;


// #pragma once

namespace Occ {

class Propagate_remote_delete_encrypted : Abstract_propagate_remote_delete_encrypted {
public:
    Propagate_remote_delete_encrypted (Owncloud_propagator *propagator, SyncFileItemPtr item, GLib.Object *parent);

    void start () override;

private:
    void slot_folder_un_locked_successfully (QByteArray &folder_id) override;
    void slot_folder_encrypted_metadata_received (QJsonDocument &json, int status_code) override;
};

}







Propagate_remote_delete_encrypted.Propagate_remote_delete_encrypted (Owncloud_propagator *propagator, SyncFileItemPtr item, GLib.Object *parent)
    : Abstract_propagate_remote_delete_encrypted (propagator, item, parent) {

}

void Propagate_remote_delete_encrypted.start () {
    Q_ASSERT (!_item._encrypted_file_name.is_empty ());

    const QFileInfo info (_item._encrypted_file_name);
    start_ls_col_job (info.path ());
}

void Propagate_remote_delete_encrypted.slot_folder_un_locked_successfully (QByteArray &folder_id) {
    Abstract_propagate_remote_delete_encrypted.slot_folder_un_locked_successfully (folder_id);
    emit finished (!_is_task_failed);
}

void Propagate_remote_delete_encrypted.slot_folder_encrypted_metadata_received (QJsonDocument &json, int status_code) {
    if (status_code == 404) {
        q_c_debug (PROPAGATE_REMOVE_ENCRYPTED) << "Metadata not found, but let's proceed with removing the file anyway.";
        delete_remote_item (_item._encrypted_file_name);
        return;
    }

    Folder_metadata metadata (_propagator.account (), json.to_json (QJsonDocument.Compact), status_code);

    q_c_debug (PROPAGATE_REMOVE_ENCRYPTED) << "Metadata Received, preparing it for removal of the file";

    const QFileInfo info (_propagator.full_local_path (_item._file));
    const string file_name = info.file_name ();

    // Find existing metadata for this file
    bool found = false;
    const QVector<Encrypted_file> files = metadata.files ();
    for (Encrypted_file &file : files) {
        if (file.original_filename == file_name) {
            metadata.remove_encrypted_file (file);
            found = true;
            break;
        }
    }

    if (!found) {
        // file is not found in the metadata, but we still need to remove it
        delete_remote_item (_item._encrypted_file_name);
        return;
    }

    q_c_debug (PROPAGATE_REMOVE_ENCRYPTED) << "Metadata updated, sending to the server.";

    auto job = new Update_metadata_api_job (_propagator.account (), _folder_id, metadata.encrypted_metadata (), _folder_token);
    connect (job, &Update_metadata_api_job.success, this, [this] (QByteArray& file_id) {
        Q_UNUSED (file_id);
        delete_remote_item (_item._encrypted_file_name);
    });
    connect (job, &Update_metadata_api_job.error, this, &Propagate_remote_delete_encrypted.task_failed);
    job.start ();
}
