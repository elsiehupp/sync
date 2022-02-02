/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
Removing the root encrypted folder is consisted of multiple steps:
- 1st step is to obtain the folder_iD via LsColJob so it then can be used for the next step
- 2nd step is to lock the root folder useing the folder_iD from the previous step. !!! Note: If there are no nested items in the folder, this, and subsequent steps are skipped until step 7.
- 3rd step is to obtain the root folder's metadata (it contains list of nested files and folders)
- 4th step is to remove the nested files and folders from the metadata and send it to the server via UpdateMetadataApiJob
- 5th step is to trigger DeleteJob for every nested file and folder of the root folder
- 6th step is to unlock the root folder using the previously obtained token from locking
- 7th step is to decrypt and delete the root folder, because it is now possible as it has become empty
***********************************************************/

// #include <QFileInfo>
// #include <QLoggingCategory>

// #pragma once

// #include <QMap>

namespace Occ {


namespace {
    const char* encrypted_filename_property_key = "encrypted_filename";
}

class Propagate_remote_delete_encrypted_root_folder : AbstractPropagateRemoteDeleteEncrypted {

    /***********************************************************
    ***********************************************************/
    public Propagate_remote_delete_encrypted_root_folder (OwncloudPropagator propagator, SyncFileItemPtr item, GLib.Object parent);

    /***********************************************************
    ***********************************************************/
    public void on_start () override;


    /***********************************************************
    ***********************************************************/
    private void on_folder_un_locked_successfully (GLib.ByteArray folder_id) override;
    private void on_folder_encrypted_metadata_received (QJsonDocument json, int status_code) override;
    private void on_delete_nested_remote_item_finished ();

    /***********************************************************
    ***********************************************************/
    private void delete_nested_remote_item (string filename);

    /***********************************************************
    ***********************************************************/
    private 
    private QMap<string, Occ.SyncJournalFileRecord> this.nested_items; // Nested files and folders
};











Propagate_remote_delete_encrypted_root_folder.Propagate_remote_delete_encrypted_root_folder (OwncloudPropagator propagator, SyncFileItemPtr item, GLib.Object parent)
    : AbstractPropagateRemoteDeleteEncrypted (propagator, item, parent) {

}

void Propagate_remote_delete_encrypted_root_folder.on_start () {
    Q_ASSERT (this.item._is_encrypted);

    const bool list_files_result = this.propagator._journal.list_files_in_path (this.item._file.to_utf8 (), [this] (Occ.SyncJournalFileRecord record) {
        this.nested_items[record._e2e_mangled_name] = record;
    });

    if (!list_files_result || this.nested_items.is_empty ()) {
        // if the folder is empty, just decrypt and delete it
        decrypt_and_remote_delete ();
        return;
    }

    start_ls_col_job (this.item._file);
}

void Propagate_remote_delete_encrypted_root_folder.on_folder_un_locked_successfully (GLib.ByteArray folder_id) {
    AbstractPropagateRemoteDeleteEncrypted.on_folder_un_locked_successfully (folder_id);
    decrypt_and_remote_delete ();
}

void Propagate_remote_delete_encrypted_root_folder.on_folder_encrypted_metadata_received (QJsonDocument json, int status_code) {
    if (status_code == 404) {
        // we've eneded up having no metadata, but, this.nested_items is not empty since we went this far, let's proceed with removing the nested items without modifying the metadata
        GLib.debug (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) << "There is no metadata for this folder. Just remove it's nested items.";
        for (var it = this.nested_items.const_begin (); it != this.nested_items.const_end (); ++it) {
            delete_nested_remote_item (it.key ());
        }
        return;
    }

    FolderMetadata metadata (this.propagator.account (), json.to_json (QJsonDocument.Compact), status_code);

    GLib.debug (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) << "It's a root encrypted folder. Let's remove nested items first.";

    metadata.remove_all_encrypted_files ();

    GLib.debug (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) << "Metadata updated, sending to the server.";

    var job = new UpdateMetadataApiJob (this.propagator.account (), this.folder_id, metadata.encrypted_metadata (), this.folder_token);
    connect (job, &UpdateMetadataApiJob.on_success, this, [this] (GLib.ByteArray& file_id) {
        Q_UNUSED (file_id);
        for (var it = this.nested_items.const_begin (); it != this.nested_items.const_end (); ++it) {
            delete_nested_remote_item (it.key ());
        }
    });
    connect (job, &UpdateMetadataApiJob.error, this, &Propagate_remote_delete_encrypted_root_folder.task_failed);
    job.on_start ();
}

void Propagate_remote_delete_encrypted_root_folder.on_delete_nested_remote_item_finished () {
    var delete_job = qobject_cast<DeleteJob> (GLib.Object.sender ());

    Q_ASSERT (delete_job);

    if (!delete_job) {
        return;
    }

    const string encrypted_filename = delete_job.property (encrypted_filename_property_key).to_"";

    if (!encrypted_filename.is_empty ()) {
        const var nested_item = this.nested_items.take (encrypted_filename);

        if (nested_item.is_valid ()) {
            this.propagator._journal.delete_file_record (nested_item._path, nested_item._type == ItemTypeDirectory);
            this.propagator._journal.commit ("Remote Remove");
        }
    }

    QNetworkReply.NetworkError err = delete_job.reply ().error ();

    const var http_error_code = delete_job.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    this.item._response_time_stamp = delete_job.response_timestamp ();
    this.item._request_id = delete_job.request_id ();

    if (err != QNetworkReply.NoError && err != QNetworkReply.ContentNotFoundError) {
        store_first_error (err);
        store_first_error_string (delete_job.error_string ());
        GLib.warn (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) << "Delete nested item on_finished with error" << err << ".";
    } else if (http_error_code != 204 && http_error_code != 404) {
        // A 404 reply is also considered a on_success here : We want to make sure
        // a file is gone from the server. It not being there in the first place
        // is ok. This will happen for files that are in the DB but not on
        // the server or the local file system.

        // Normally we expect "204 No Content"
        // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
        // throw an error.
        store_first_error_string (_("Wrong HTTP code returned by server. Expected 204, but received \"%1 %2\".")
                        .arg (http_error_code)
                        .arg (delete_job.reply ().attribute (QNetworkRequest.HttpReasonPhraseAttribute).to_""));
        if (this.item._http_error_code == 0) {
            this.item._http_error_code = http_error_code;
        }

        GLib.warn (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) << "Delete nested item on_finished with error" << http_error_code << ".";
    }

    if (this.nested_items.size () == 0) {
        // we wait for all this.nested_items' Delete_jobs to finish, and then - fail if any of those jobs has failed
        if (network_error () != QNetworkReply.NetworkError.NoError || this.item._http_error_code != 0) {
            const int error_code = network_error () != QNetworkReply.NetworkError.NoError ? network_error () : this.item._http_error_code;
            q_c_critical (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) << "Delete of nested items on_finished with error" << error_code << ". Failing the entire sequence.";
            task_failed ();
            return;
        }
        unlock_folder ();
    }
}

void Propagate_remote_delete_encrypted_root_folder.delete_nested_remote_item (string filename) {
    q_c_info (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) << "Deleting nested encrypted remote item" << filename;

    var delete_job = new DeleteJob (this.propagator.account (), this.propagator.full_remote_path (filename), this);
    delete_job.set_folder_token (this.folder_token);
    delete_job.set_property (encrypted_filename_property_key, filename);

    connect (delete_job, &DeleteJob.finished_signal, this, &Propagate_remote_delete_encrypted_root_folder.on_delete_nested_remote_item_finished);

    delete_job.on_start ();
}

void Propagate_remote_delete_encrypted_root_folder.decrypt_and_remote_delete () {
    var job = new Occ.SetEncryptionFlagApiJob (this.propagator.account (), this.item._file_id, Occ.SetEncryptionFlagApiJob.Clear, this);
    connect (job, &Occ.SetEncryptionFlagApiJob.on_success, this, [this] (GLib.ByteArray file_id) {
        Q_UNUSED (file_id);
        delete_remote_item (this.item._file);
    });
    connect (job, &Occ.SetEncryptionFlagApiJob.error, this, [this] (GLib.ByteArray file_id, int http_return_code) {
        Q_UNUSED (file_id);
        this.item._http_error_code = http_return_code;
        task_failed ();
    });
    job.on_start ();
}


}