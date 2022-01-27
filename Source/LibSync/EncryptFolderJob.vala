/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #pragma once

// #include <GLib.Object>

namespace Occ {

class EncryptFolderJob : GLib.Object {

    public enum Status {
        Success = 0,
        Error,
    };

    public EncryptFolderJob (AccountPtr &account, SyncJournalDb *journal, string path, GLib.ByteArray &file_id, GLib.Object *parent = nullptr);
    public void on_start ();

    public string error_string ();

signals:
    void on_finished (int status);


    private void on_encryption_flag_success (GLib.ByteArray &folder_id);
    private void on_encryption_flag_error (GLib.ByteArray &folder_id, int http_return_code);
    private void on_lock_for_encryption_success (GLib.ByteArray &folder_id, GLib.ByteArray &token);
    private void on_lock_for_encryption_error (GLib.ByteArray &folder_id, int http_return_code);
    private void on_unlock_folder_success (GLib.ByteArray &folder_id);
    private void on_unlock_folder_error (GLib.ByteArray &folder_id, int http_return_code);
    private void on_upload_metadata_success (GLib.ByteArray &folder_id);
    private void on_update_metadata_error (GLib.ByteArray &folder_id, int http_return_code);


    private AccountPtr _account;
    private SyncJournalDb _journal;
    private string _path;
    private GLib.ByteArray _file_id;
    private GLib.ByteArray _folder_token;
    private string _error_string;
};

    EncryptFolderJob.EncryptFolderJob (AccountPtr &account, SyncJournalDb *journal, string path, GLib.ByteArray &file_id, GLib.Object *parent)
        : GLib.Object (parent)
        , _account (account)
        , _journal (journal)
        , _path (path)
        , _file_id (file_id) {
    }

    void EncryptFolderJob.on_start () {
        auto job = new Occ.SetEncryptionFlagApiJob (_account, _file_id, Occ.SetEncryptionFlagApiJob.Set, this);
        connect (job, &Occ.SetEncryptionFlagApiJob.on_success, this, &EncryptFolderJob.on_encryption_flag_success);
        connect (job, &Occ.SetEncryptionFlagApiJob.error, this, &EncryptFolderJob.on_encryption_flag_error);
        job.on_start ();
    }

    string EncryptFolderJob.error_string () {
        return _error_string;
    }

    void EncryptFolderJob.on_encryption_flag_success (GLib.ByteArray &file_id) {
        SyncJournalFileRecord rec;
        _journal.get_file_record (_path, &rec);
        if (rec.is_valid ()) {
            rec._is_e2e_encrypted = true;
            _journal.set_file_record (rec);
        }

        auto lock_job = new LockEncryptFolderApiJob (_account, file_id, this);
        connect (lock_job, &LockEncryptFolderApiJob.on_success,
                this, &EncryptFolderJob.on_lock_for_encryption_success);
        connect (lock_job, &LockEncryptFolderApiJob.error,
                this, &EncryptFolderJob.on_lock_for_encryption_error);
        lock_job.on_start ();
    }

    void EncryptFolderJob.on_encryption_flag_error (GLib.ByteArray &file_id, int http_error_code) {
        q_debug () << "Error on the encryption flag of" << file_id << "HTTP code:" << http_error_code;
        emit on_finished (Error);
    }

    void EncryptFolderJob.on_lock_for_encryption_success (GLib.ByteArray &file_id, GLib.ByteArray &token) {
        _folder_token = token;

        FolderMetadata empty_metadata (_account);
        auto encrypted_metadata = empty_metadata.encrypted_metadata ();
        if (encrypted_metadata.is_empty ()) {
            //TODO : Mark the folder as unencrypted as the metadata generation failed.
            _error_string = tr ("Could not generate the metadata for encryption, Unlocking the folder.\n"
                              "This can be an issue with your OpenSSL libraries.");
            emit on_finished (Error);
            return;
        }

        auto store_metadata_job = new StoreMetaDataApiJob (_account, file_id, empty_metadata.encrypted_metadata (), this);
        connect (store_metadata_job, &StoreMetaDataApiJob.on_success,
                this, &EncryptFolderJob.on_upload_metadata_success);
        connect (store_metadata_job, &StoreMetaDataApiJob.error,
                this, &EncryptFolderJob.on_update_metadata_error);
        store_metadata_job.on_start ();
    }

    void EncryptFolderJob.on_upload_metadata_success (GLib.ByteArray &folder_id) {
        auto unlock_job = new UnlockEncryptFolderApiJob (_account, folder_id, _folder_token, this);
        connect (unlock_job, &UnlockEncryptFolderApiJob.on_success,
                        this, &EncryptFolderJob.on_unlock_folder_success);
        connect (unlock_job, &UnlockEncryptFolderApiJob.error,
                        this, &EncryptFolderJob.on_unlock_folder_error);
        unlock_job.on_start ();
    }

    void EncryptFolderJob.on_update_metadata_error (GLib.ByteArray &folder_id, int http_return_code) {
        Q_UNUSED (http_return_code);

        auto unlock_job = new UnlockEncryptFolderApiJob (_account, folder_id, _folder_token, this);
        connect (unlock_job, &UnlockEncryptFolderApiJob.on_success,
                        this, &EncryptFolderJob.on_unlock_folder_success);
        connect (unlock_job, &UnlockEncryptFolderApiJob.error,
                        this, &EncryptFolderJob.on_unlock_folder_error);
        unlock_job.on_start ();
    }

    void EncryptFolderJob.on_lock_for_encryption_error (GLib.ByteArray &file_id, int http_error_code) {
        q_c_info (lc_encrypt_folder_job ()) << "Locking error for" << file_id << "HTTP code:" << http_error_code;
        emit on_finished (Error);
    }

    void EncryptFolderJob.on_unlock_folder_error (GLib.ByteArray &file_id, int http_error_code) {
        q_c_info (lc_encrypt_folder_job ()) << "Unlocking error for" << file_id << "HTTP code:" << http_error_code;
        emit on_finished (Error);
    }
    void EncryptFolderJob.on_unlock_folder_success (GLib.ByteArray &file_id) {
        q_c_info (lc_encrypt_folder_job ()) << "Unlocking on_success for" << file_id;
        emit on_finished (Success);
    }

    }
    