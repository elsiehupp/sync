/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QNetworkReply>
// #include <QFileInfo>
// #include <QLoggingCategory>

namespace Occ {

/***********************************************************
@brief The AbstractPropagateRemoteDeleteEncrypted class is
the base class for Propagate Remote Delete Encrypted jobs
@ingroup libsync
***********************************************************/
class AbstractPropagateRemoteDeleteEncrypted : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public AbstractPropagateRemoteDeleteEncrypted (OwncloudPropagator propagator, SyncFileItemPtr item, GLib.Object parent);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public string error_string ();

    public virtual void on_start ();

signals:
    void on_finished (bool on_success);


    protected void store_first_error (QNetworkReply.NetworkError err);
    protected void store_first_error_string (string err_string);

    protected void start_ls_col_job (string path);
    protected void on_folder_encrypted_id_received (string[] list);
    protected void on_try_lock (GLib.ByteArray folder_id);
    protected void on_folder_locked_successfully (GLib.ByteArray folder_id, GLib.ByteArray token);
    protected virtual void on_folder_un_locked_successfully (GLib.ByteArray folder_id);
    protected virtual void on_folder_encrypted_metadata_received (QJsonDocument json, int status_code);
    protected void on_delete_remote_item_finished ();

    protected void delete_remote_item (string filename);
    protected void unlock_folder ();
    protected void task_failed ();


    protected OwncloudPropagator this.propagator = nullptr;
    protected SyncFileItemPtr this.item;
    protected GLib.ByteArray this.folder_token;
    protected GLib.ByteArray this.folder_id;
    protected bool this.folder_locked = false;
    protected bool this.is_task_failed = false;
    protected QNetworkReply.NetworkError this.network_error = QNetworkReply.NoError;
    protected string this.error_string;
};

}

AbstractPropagateRemoteDeleteEncrypted.AbstractPropagateRemoteDeleteEncrypted (OwncloudPropagator propagator, SyncFileItemPtr item, GLib.Object parent)
    : GLib.Object (parent)
    , this.propagator (propagator)
    , this.item (item) {}

QNetworkReply.NetworkError AbstractPropagateRemoteDeleteEncrypted.network_error () {
    return this.network_error;
}

string AbstractPropagateRemoteDeleteEncrypted.error_string () {
    return this.error_string;
}

void AbstractPropagateRemoteDeleteEncrypted.store_first_error (QNetworkReply.NetworkError err) {
    if (this.network_error == QNetworkReply.NetworkError.NoError) {
        this.network_error = err;
    }
}

void AbstractPropagateRemoteDeleteEncrypted.store_first_error_string (string err_string) {
    if (this.error_string.is_empty ()) {
        this.error_string = err_string;
    }
}

void AbstractPropagateRemoteDeleteEncrypted.start_ls_col_job (string path) {
    GLib.debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Folder is encrypted, let's get the Id from it.";
    var job = new LsColJob (this.propagator.account (), this.propagator.full_remote_path (path), this);
    job.set_properties ({"resourcetype", "http://owncloud.org/ns:fileid"});
    connect (job, &LsColJob.directory_listing_subfolders, this, &AbstractPropagateRemoteDeleteEncrypted.on_folder_encrypted_id_received);
    connect (job, &LsColJob.finished_with_error, this, &AbstractPropagateRemoteDeleteEncrypted.task_failed);
    job.on_start ();
}

void AbstractPropagateRemoteDeleteEncrypted.on_folder_encrypted_id_received (string[] list) {
    GLib.debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Received id of folder, trying to lock it so we can prepare the metadata";
    var job = qobject_cast<LsColJob> (sender ());
    const ExtraFolderInfo folder_info = job._folder_infos.value (list.first ());
    on_try_lock (folder_info.file_identifier);
}

void AbstractPropagateRemoteDeleteEncrypted.on_try_lock (GLib.ByteArray folder_id) {
    var lock_job = new LockEncryptFolderApiJob (this.propagator.account (), folder_id, this);
    connect (lock_job, &LockEncryptFolderApiJob.on_success, this, &AbstractPropagateRemoteDeleteEncrypted.on_folder_locked_successfully);
    connect (lock_job, &LockEncryptFolderApiJob.error, this, &AbstractPropagateRemoteDeleteEncrypted.task_failed);
    lock_job.on_start ();
}

void AbstractPropagateRemoteDeleteEncrypted.on_folder_locked_successfully (GLib.ByteArray folder_id, GLib.ByteArray token) {
    GLib.debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Folder id" << folder_id << "Locked Successfully for Upload, Fetching Metadata";
    this.folder_locked = true;
    this.folder_token = token;
    this.folder_id = folder_id;

    var job = new GetMetadataApiJob (this.propagator.account (), this.folder_id);
    connect (job, &GetMetadataApiJob.json_received, this, &AbstractPropagateRemoteDeleteEncrypted.on_folder_encrypted_metadata_received);
    connect (job, &GetMetadataApiJob.error, this, &AbstractPropagateRemoteDeleteEncrypted.task_failed);
    job.on_start ();
}

void AbstractPropagateRemoteDeleteEncrypted.on_folder_un_locked_successfully (GLib.ByteArray folder_id) {
    Q_UNUSED (folder_id);
    GLib.debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Folder id" << folder_id << "successfully unlocked";
    this.folder_locked = false;
    this.folder_token = "";
}

void AbstractPropagateRemoteDeleteEncrypted.on_delete_remote_item_finished () {
    var delete_job = qobject_cast<DeleteJob> (GLib.Object.sender ());

    Q_ASSERT (delete_job);

    if (!delete_job) {
        q_c_critical (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Sender is not a DeleteJob instance.";
        task_failed ();
        return;
    }

    const var err = delete_job.reply ().error ();

    this.item._http_error_code = delete_job.reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
    this.item._response_time_stamp = delete_job.response_timestamp ();
    this.item._request_id = delete_job.request_id ();

    if (err != QNetworkReply.NoError && err != QNetworkReply.ContentNotFoundError) {
        store_first_error_string (delete_job.error_string ());
        store_first_error (err);

        task_failed ();
        return;
    }

    // A 404 reply is also considered a on_success here : We want to make sure
    // a file is gone from the server. It not being there in the first place
    // is ok. This will happen for files that are in the DB but not on
    // the server or the local file system.
    if (this.item._http_error_code != 204 && this.item._http_error_code != 404) {
        // Normally we expect "204 No Content"
        // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
        // throw an error.
        store_first_error_string (_("Wrong HTTP code returned by server. Expected 204, but received \"%1 %2\".")
                       .arg (this.item._http_error_code)
                       .arg (delete_job.reply ().attribute (Soup.Request.HttpReasonPhraseAttribute).to_string ()));

        task_failed ();
        return;
    }

    this.propagator._journal.delete_file_record (this.item._original_file, this.item.is_directory ());
    this.propagator._journal.commit ("Remote Remove");

    unlock_folder ();
}

void AbstractPropagateRemoteDeleteEncrypted.delete_remote_item (string filename) {
    q_c_info (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Deleting nested encrypted item" << filename;

    var delete_job = new DeleteJob (this.propagator.account (), this.propagator.full_remote_path (filename), this);
    delete_job.set_folder_token (this.folder_token);

    connect (delete_job, &DeleteJob.finished_signal, this, &AbstractPropagateRemoteDeleteEncrypted.on_delete_remote_item_finished);

    delete_job.on_start ();
}

void AbstractPropagateRemoteDeleteEncrypted.unlock_folder () {
    if (!this.folder_locked) {
        /* emit */ finished (true);
        return;
    }

    GLib.debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Unlocking folder" << this.folder_id;
    var unlock_job = new UnlockEncryptFolderApiJob (this.propagator.account (), this.folder_id, this.folder_token, this);

    connect (unlock_job, &UnlockEncryptFolderApiJob.on_success, this, &AbstractPropagateRemoteDeleteEncrypted.on_folder_un_locked_successfully);
    connect (unlock_job, &UnlockEncryptFolderApiJob.error, this, [this] (GLib.ByteArray file_identifier, int http_return_code) {
        Q_UNUSED (file_identifier);
        this.folder_locked = false;
        this.folder_token = "";
        this.item._http_error_code = http_return_code;
        this.error_string = _("\"%1 Failed to unlock encrypted folder %2\".")
                .arg (http_return_code)
                .arg (string.from_utf8 (file_identifier));
        this.item._error_string =this.error_string;
        task_failed ();
    });
    unlock_job.on_start ();
}

void AbstractPropagateRemoteDeleteEncrypted.task_failed () {
    GLib.debug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Task failed for job" << sender ();
    this.is_task_failed = true;
    if (this.folder_locked) {
        unlock_folder ();
    } else {
        /* emit */ finished (false);
    }
}

} // namespace Occ
