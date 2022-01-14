/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <GLib.Object>
// #include <string>
// #include <QNetworkReply>
// #include <QFileInfo>
// #include <QLoggingCategory>

namespace Occ {

/***********************************************************
@brief The Abstract_propagate_remote_delete_encrypted class is the base class for Propagate Remote Delete Encrypted jobs
@ingroup libsync
***********************************************************/
class Abstract_propagate_remote_delete_encrypted : GLib.Object {
public:
    Abstract_propagate_remote_delete_encrypted (Owncloud_propagator *propagator, Sync_file_item_ptr item, GLib.Object *parent);
    ~Abstract_propagate_remote_delete_encrypted () override = default;

    QNetworkReply.NetworkError network_error ();
    string error_string ();

    virtual void start () = 0;

signals:
    void finished (bool success);

protected:
    void store_first_error (QNetworkReply.NetworkError err);
    void store_first_error_string (string &err_string);

    void start_ls_col_job (string &path);
    void slot_folder_encrypted_id_received (QStringList &list);
    void slot_try_lock (QByteArray &folder_id);
    void slot_folder_locked_successfully (QByteArray &folder_id, QByteArray &token);
    virtual void slot_folder_un_locked_successfully (QByteArray &folder_id);
    virtual void slot_folder_encrypted_metadata_received (QJsonDocument &json, int status_code) = 0;
    void slot_delete_remote_item_finished ();

    void delete_remote_item (string &filename);
    void unlock_folder ();
    void task_failed ();

protected:
    Owncloud_propagator *_propagator = nullptr;
    Sync_file_item_ptr _item;
    QByteArray _folder_token;
    QByteArray _folder_id;
    bool _folder_locked = false;
    bool _is_task_failed = false;
    QNetworkReply.NetworkError _network_error = QNetworkReply.NoError;
    string _error_string;
};

}

Abstract_propagate_remote_delete_encrypted.Abstract_propagate_remote_delete_encrypted (Owncloud_propagator *propagator, Sync_file_item_ptr item, GLib.Object *parent)
    : GLib.Object (parent)
    , _propagator (propagator)
    , _item (item) {}

QNetworkReply.NetworkError Abstract_propagate_remote_delete_encrypted.network_error () {
    return _network_error;
}

string Abstract_propagate_remote_delete_encrypted.error_string () {
    return _error_string;
}

void Abstract_propagate_remote_delete_encrypted.store_first_error (QNetworkReply.NetworkError err) {
    if (_network_error == QNetworkReply.NetworkError.NoError) {
        _network_error = err;
    }
}

void Abstract_propagate_remote_delete_encrypted.store_first_error_string (string &err_string) {
    if (_error_string.is_empty ()) {
        _error_string = err_string;
    }
}

void Abstract_propagate_remote_delete_encrypted.start_ls_col_job (string &path) {
    q_c_debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Folder is encrypted, let's get the Id from it.";
    auto job = new Ls_col_job (_propagator.account (), _propagator.full_remote_path (path), this);
    job.set_properties ({"resourcetype", "http://owncloud.org/ns:fileid"});
    connect (job, &Ls_col_job.directory_listing_subfolders, this, &Abstract_propagate_remote_delete_encrypted.slot_folder_encrypted_id_received);
    connect (job, &Ls_col_job.finished_with_error, this, &Abstract_propagate_remote_delete_encrypted.task_failed);
    job.start ();
}

void Abstract_propagate_remote_delete_encrypted.slot_folder_encrypted_id_received (QStringList &list) {
    q_c_debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Received id of folder, trying to lock it so we can prepare the metadata";
    auto job = qobject_cast<Ls_col_job> (sender ());
    const Extra_folder_info folder_info = job._folder_infos.value (list.first ());
    slot_try_lock (folder_info.file_id);
}

void Abstract_propagate_remote_delete_encrypted.slot_try_lock (QByteArray &folder_id) {
    auto lock_job = new Lock_encrypt_folder_api_job (_propagator.account (), folder_id, this);
    connect (lock_job, &Lock_encrypt_folder_api_job.success, this, &Abstract_propagate_remote_delete_encrypted.slot_folder_locked_successfully);
    connect (lock_job, &Lock_encrypt_folder_api_job.error, this, &Abstract_propagate_remote_delete_encrypted.task_failed);
    lock_job.start ();
}

void Abstract_propagate_remote_delete_encrypted.slot_folder_locked_successfully (QByteArray &folder_id, QByteArray &token) {
    q_c_debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Folder id" << folder_id << "Locked Successfully for Upload, Fetching Metadata";
    _folder_locked = true;
    _folder_token = token;
    _folder_id = folder_id;

    auto job = new Get_metadata_api_job (_propagator.account (), _folder_id);
    connect (job, &Get_metadata_api_job.json_received, this, &Abstract_propagate_remote_delete_encrypted.slot_folder_encrypted_metadata_received);
    connect (job, &Get_metadata_api_job.error, this, &Abstract_propagate_remote_delete_encrypted.task_failed);
    job.start ();
}

void Abstract_propagate_remote_delete_encrypted.slot_folder_un_locked_successfully (QByteArray &folder_id) {
    Q_UNUSED (folder_id);
    q_c_debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Folder id" << folder_id << "successfully unlocked";
    _folder_locked = false;
    _folder_token = "";
}

void Abstract_propagate_remote_delete_encrypted.slot_delete_remote_item_finished () {
    auto *delete_job = qobject_cast<Delete_job> (GLib.Object.sender ());

    Q_ASSERT (delete_job);

    if (!delete_job) {
        q_c_critical (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Sender is not a Delete_job instance.";
        task_failed ();
        return;
    }

    const auto err = delete_job.reply ().error ();

    _item._http_error_code = delete_job.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    _item._response_time_stamp = delete_job.response_timestamp ();
    _item._request_id = delete_job.request_id ();

    if (err != QNetworkReply.NoError && err != QNetworkReply.ContentNotFoundError) {
        store_first_error_string (delete_job.error_string ());
        store_first_error (err);

        task_failed ();
        return;
    }

    // A 404 reply is also considered a success here : We want to make sure
    // a file is gone from the server. It not being there in the first place
    // is ok. This will happen for files that are in the DB but not on
    // the server or the local file system.
    if (_item._http_error_code != 204 && _item._http_error_code != 404) {
        // Normally we expect "204 No Content"
        // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
        // throw an error.
        store_first_error_string (tr ("Wrong HTTP code returned by server. Expected 204, but received \"%1 %2\".")
                       .arg (_item._http_error_code)
                       .arg (delete_job.reply ().attribute (QNetworkRequest.Http_reason_phrase_attribute).to_string ()));

        task_failed ();
        return;
    }

    _propagator._journal.delete_file_record (_item._original_file, _item.is_directory ());
    _propagator._journal.commit ("Remote Remove");

    unlock_folder ();
}

void Abstract_propagate_remote_delete_encrypted.delete_remote_item (string &filename) {
    q_c_info (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Deleting nested encrypted item" << filename;

    auto delete_job = new Delete_job (_propagator.account (), _propagator.full_remote_path (filename), this);
    delete_job.set_folder_token (_folder_token);

    connect (delete_job, &Delete_job.finished_signal, this, &Abstract_propagate_remote_delete_encrypted.slot_delete_remote_item_finished);

    delete_job.start ();
}

void Abstract_propagate_remote_delete_encrypted.unlock_folder () {
    if (!_folder_locked) {
        emit finished (true);
        return;
    }

    q_c_debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Unlocking folder" << _folder_id;
    auto unlock_job = new Unlock_encrypt_folder_api_job (_propagator.account (), _folder_id, _folder_token, this);

    connect (unlock_job, &Unlock_encrypt_folder_api_job.success, this, &Abstract_propagate_remote_delete_encrypted.slot_folder_un_locked_successfully);
    connect (unlock_job, &Unlock_encrypt_folder_api_job.error, this, [this] (QByteArray& file_id, int http_return_code) {
        Q_UNUSED (file_id);
        _folder_locked = false;
        _folder_token = "";
        _item._http_error_code = http_return_code;
        _error_string = tr ("\"%1 Failed to unlock encrypted folder %2\".")
                .arg (http_return_code)
                .arg (string.from_utf8 (file_id));
        _item._error_string =_error_string;
        task_failed ();
    });
    unlock_job.start ();
}

void Abstract_propagate_remote_delete_encrypted.task_failed () {
    q_c_debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Task failed for job" << sender ();
    _is_task_failed = true;
    if (_folder_locked) {
        unlock_folder ();
    } else {
        emit finished (false);
    }
}

} // namespace Occ
