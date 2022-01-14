/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
Removing the root encrypted folder is consisted of multiple steps:
- 1st step is to obtain the folder_iD via Ls_col_job so it then can be used for the next step
- 2nd step is to lock the root folder useing the folder_iD from the previous step. !!! NOTE : If there are no nested items in the folder, this, and subsequent steps are skipped until step 7.
- 3rd step is to obtain the root folder's metadata (it contains list of nested files and folders)
- 4th step is to remove the nested files and folders from the metadata and send it to the server via Update_metadata_api_job
- 5th step is to trigger Delete_job for every nested file and folder of the root folder
- 6th step is to unlock the root folder using the previously obtained token from locking
- 7th step is to decrypt and delete the root folder, because it is now possible as it has become empty
***********************************************************/

// #include <QFileInfo>
// #include <QLoggingCategory>

// #pragma once

// #include <QMap>

namespace Occ {


namespace {
    const char* encrypted_file_name_property_key = "encrypted_file_name";
}

class Propagate_remote_delete_encrypted_root_folder : Abstract_propagate_remote_delete_encrypted {
public:
    Propagate_remote_delete_encrypted_root_folder (Owncloud_propagator *propagator, Sync_file_item_ptr item, GLib.Object *parent);

    void start () override;

private:
    void slot_folder_un_locked_successfully (QByteArray &folder_id) override;
    void slot_folder_encrypted_metadata_received (QJsonDocument &json, int status_code) override;
    void slot_delete_nested_remote_item_finished ();

    void delete_nested_remote_item (string &filename);
    void decrypt_and_remote_delete ();

    QMap<string, Occ.SyncJournalFileRecord> _nested_items; // Nested files and folders
};











Propagate_remote_delete_encrypted_root_folder.Propagate_remote_delete_encrypted_root_folder (Owncloud_propagator *propagator, Sync_file_item_ptr item, GLib.Object *parent)
    : Abstract_propagate_remote_delete_encrypted (propagator, item, parent) {

}

void Propagate_remote_delete_encrypted_root_folder.start () {
    Q_ASSERT (_item._is_encrypted);

    const bool list_files_result = _propagator._journal.list_files_in_path (_item._file.to_utf8 (), [this] (Occ.SyncJournalFileRecord &record) {
        _nested_items[record._e2e_mangled_name] = record;
    });

    if (!list_files_result || _nested_items.is_empty ()) {
        // if the folder is empty, just decrypt and delete it
        decrypt_and_remote_delete ();
        return;
    }

    start_ls_col_job (_item._file);
}

void Propagate_remote_delete_encrypted_root_folder.slot_folder_un_locked_successfully (QByteArray &folder_id) {
    Abstract_propagate_remote_delete_encrypted.slot_folder_un_locked_successfully (folder_id);
    decrypt_and_remote_delete ();
}

void Propagate_remote_delete_encrypted_root_folder.slot_folder_encrypted_metadata_received (QJsonDocument &json, int status_code) {
    if (status_code == 404) {
        // we've eneded up having no metadata, but, _nested_items is not empty since we went this far, let's proceed with removing the nested items without modifying the metadata
        q_c_debug (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) << "There is no metadata for this folder. Just remove it's nested items.";
        for (auto it = _nested_items.const_begin (); it != _nested_items.const_end (); ++it) {
            delete_nested_remote_item (it.key ());
        }
        return;
    }

    Folder_metadata metadata (_propagator.account (), json.to_json (QJsonDocument.Compact), status_code);

    q_c_debug (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) << "It's a root encrypted folder. Let's remove nested items first.";

    metadata.remove_all_encrypted_files ();

    q_c_debug (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) << "Metadata updated, sending to the server.";

    auto job = new Update_metadata_api_job (_propagator.account (), _folder_id, metadata.encrypted_metadata (), _folder_token);
    connect (job, &Update_metadata_api_job.success, this, [this] (QByteArray& file_id) {
        Q_UNUSED (file_id);
        for (auto it = _nested_items.const_begin (); it != _nested_items.const_end (); ++it) {
            delete_nested_remote_item (it.key ());
        }
    });
    connect (job, &Update_metadata_api_job.error, this, &Propagate_remote_delete_encrypted_root_folder.task_failed);
    job.start ();
}

void Propagate_remote_delete_encrypted_root_folder.slot_delete_nested_remote_item_finished () {
    auto *delete_job = qobject_cast<Delete_job> (GLib.Object.sender ());

    Q_ASSERT (delete_job);

    if (!delete_job) {
        return;
    }

    const string encrypted_file_name = delete_job.property (encrypted_file_name_property_key).to_string ();

    if (!encrypted_file_name.is_empty ()) {
        const auto nested_item = _nested_items.take (encrypted_file_name);

        if (nested_item.is_valid ()) {
            _propagator._journal.delete_file_record (nested_item._path, nested_item._type == ItemTypeDirectory);
            _propagator._journal.commit ("Remote Remove");
        }
    }

    QNetworkReply.NetworkError err = delete_job.reply ().error ();

    const auto http_error_code = delete_job.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    _item._response_time_stamp = delete_job.response_timestamp ();
    _item._request_id = delete_job.request_id ();

    if (err != QNetworkReply.NoError && err != QNetworkReply.ContentNotFoundError) {
        store_first_error (err);
        store_first_error_string (delete_job.error_string ());
        q_c_warning (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) << "Delete nested item finished with error" << err << ".";
    } else if (http_error_code != 204 && http_error_code != 404) {
        // A 404 reply is also considered a success here : We want to make sure
        // a file is gone from the server. It not being there in the first place
        // is ok. This will happen for files that are in the DB but not on
        // the server or the local file system.

        // Normally we expect "204 No Content"
        // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
        // throw an error.
        store_first_error_string (tr ("Wrong HTTP code returned by server. Expected 204, but received \"%1 %2\".")
                        .arg (http_error_code)
                        .arg (delete_job.reply ().attribute (QNetworkRequest.Http_reason_phrase_attribute).to_string ()));
        if (_item._http_error_code == 0) {
            _item._http_error_code = http_error_code;
        }

        q_c_warning (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) << "Delete nested item finished with error" << http_error_code << ".";
    }

    if (_nested_items.size () == 0) {
        // we wait for all _nested_items' Delete_jobs to finish, and then - fail if any of those jobs has failed
        if (network_error () != QNetworkReply.NetworkError.NoError || _item._http_error_code != 0) {
            const int error_code = network_error () != QNetworkReply.NetworkError.NoError ? network_error () : _item._http_error_code;
            q_c_critical (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) << "Delete of nested items finished with error" << error_code << ". Failing the entire sequence.";
            task_failed ();
            return;
        }
        unlock_folder ();
    }
}

void Propagate_remote_delete_encrypted_root_folder.delete_nested_remote_item (string &filename) {
    q_c_info (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) << "Deleting nested encrypted remote item" << filename;

    auto delete_job = new Delete_job (_propagator.account (), _propagator.full_remote_path (filename), this);
    delete_job.set_folder_token (_folder_token);
    delete_job.set_property (encrypted_file_name_property_key, filename);

    connect (delete_job, &Delete_job.finished_signal, this, &Propagate_remote_delete_encrypted_root_folder.slot_delete_nested_remote_item_finished);

    delete_job.start ();
}

void Propagate_remote_delete_encrypted_root_folder.decrypt_and_remote_delete () {
    auto job = new Occ.Set_encryption_flag_api_job (_propagator.account (), _item._file_id, Occ.Set_encryption_flag_api_job.Clear, this);
    connect (job, &Occ.Set_encryption_flag_api_job.success, this, [this] (QByteArray &file_id) {
        Q_UNUSED (file_id);
        delete_remote_item (_item._file);
    });
    connect (job, &Occ.Set_encryption_flag_api_job.error, this, [this] (QByteArray &file_id, int http_return_code) {
        Q_UNUSED (file_id);
        _item._http_error_code = http_return_code;
        task_failed ();
    });
    job.start ();
}


}