/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #pragma once

// #include <GLib.Object>

namespace Occ {

class EncryptFolderJob : GLib.Object {
public:
    enum Status {
        Success = 0,
        Error,
    };
    Q_ENUM (Status)

    EncryptFolderJob (AccountPtr &account, SyncJournalDb *journal, string &path, QByteArray &file_id, GLib.Object *parent = nullptr);
    void start ();

    string error_string ();

signals:
    void finished (int status);

private slots:
    void slot_encryption_flag_success (QByteArray &folder_id);
    void slot_encryption_flag_error (QByteArray &folder_id, int http_return_code);
    void slot_lock_for_encryption_success (QByteArray &folder_id, QByteArray &token);
    void slot_lock_for_encryption_error (QByteArray &folder_id, int http_return_code);
    void slot_unlock_folder_success (QByteArray &folder_id);
    void slot_unlock_folder_error (QByteArray &folder_id, int http_return_code);
    void slot_upload_metadata_success (QByteArray &folder_id);
    void slot_update_metadata_error (QByteArray &folder_id, int http_return_code);

private:
    AccountPtr _account;
    SyncJournalDb *_journal;
    string _path;
    QByteArray _file_id;
    QByteArray _folder_token;
    string _error_string;
};

    EncryptFolderJob.EncryptFolderJob (AccountPtr &account, SyncJournalDb *journal, string &path, QByteArray &file_id, GLib.Object *parent)
        : GLib.Object (parent)
        , _account (account)
        , _journal (journal)
        , _path (path)
        , _file_id (file_id) {
    }

    void EncryptFolderJob.start () {
        auto job = new Occ.SetEncryptionFlagApiJob (_account, _file_id, Occ.SetEncryptionFlagApiJob.Set, this);
        connect (job, &Occ.SetEncryptionFlagApiJob.success, this, &EncryptFolderJob.slot_encryption_flag_success);
        connect (job, &Occ.SetEncryptionFlagApiJob.error, this, &EncryptFolderJob.slot_encryption_flag_error);
        job.start ();
    }

    string EncryptFolderJob.error_string () {
        return _error_string;
    }

    void EncryptFolderJob.slot_encryption_flag_success (QByteArray &file_id) {
        SyncJournalFileRecord rec;
        _journal.get_file_record (_path, &rec);
        if (rec.is_valid ()) {
            rec._is_e2e_encrypted = true;
            _journal.set_file_record (rec);
        }

        auto lock_job = new LockEncryptFolderApiJob (_account, file_id, this);
        connect (lock_job, &LockEncryptFolderApiJob.success,
                this, &EncryptFolderJob.slot_lock_for_encryption_success);
        connect (lock_job, &LockEncryptFolderApiJob.error,
                this, &EncryptFolderJob.slot_lock_for_encryption_error);
        lock_job.start ();
    }

    void EncryptFolderJob.slot_encryption_flag_error (QByteArray &file_id, int http_error_code) {
        q_debug () << "Error on the encryption flag of" << file_id << "HTTP code:" << http_error_code;
        emit finished (Error);
    }

    void EncryptFolderJob.slot_lock_for_encryption_success (QByteArray &file_id, QByteArray &token) {
        _folder_token = token;

        FolderMetadata empty_metadata (_account);
        auto encrypted_metadata = empty_metadata.encrypted_metadata ();
        if (encrypted_metadata.is_empty ()) {
            //TODO : Mark the folder as unencrypted as the metadata generation failed.
            _error_string = tr ("Could not generate the metadata for encryption, Unlocking the folder.\n"
                              "This can be an issue with your OpenSSL libraries.");
            emit finished (Error);
            return;
        }

        auto store_metadata_job = new StoreMetaDataApiJob (_account, file_id, empty_metadata.encrypted_metadata (), this);
        connect (store_metadata_job, &StoreMetaDataApiJob.success,
                this, &EncryptFolderJob.slot_upload_metadata_success);
        connect (store_metadata_job, &StoreMetaDataApiJob.error,
                this, &EncryptFolderJob.slot_update_metadata_error);
        store_metadata_job.start ();
    }

    void EncryptFolderJob.slot_upload_metadata_success (QByteArray &folder_id) {
        auto unlock_job = new UnlockEncryptFolderApiJob (_account, folder_id, _folder_token, this);
        connect (unlock_job, &UnlockEncryptFolderApiJob.success,
                        this, &EncryptFolderJob.slot_unlock_folder_success);
        connect (unlock_job, &UnlockEncryptFolderApiJob.error,
                        this, &EncryptFolderJob.slot_unlock_folder_error);
        unlock_job.start ();
    }

    void EncryptFolderJob.slot_update_metadata_error (QByteArray &folder_id, int http_return_code) {
        Q_UNUSED (http_return_code);

        auto unlock_job = new UnlockEncryptFolderApiJob (_account, folder_id, _folder_token, this);
        connect (unlock_job, &UnlockEncryptFolderApiJob.success,
                        this, &EncryptFolderJob.slot_unlock_folder_success);
        connect (unlock_job, &UnlockEncryptFolderApiJob.error,
                        this, &EncryptFolderJob.slot_unlock_folder_error);
        unlock_job.start ();
    }

    void EncryptFolderJob.slot_lock_for_encryption_error (QByteArray &file_id, int http_error_code) {
        q_c_info (lc_encrypt_folder_job ()) << "Locking error for" << file_id << "HTTP code:" << http_error_code;
        emit finished (Error);
    }

    void EncryptFolderJob.slot_unlock_folder_error (QByteArray &file_id, int http_error_code) {
        q_c_info (lc_encrypt_folder_job ()) << "Unlocking error for" << file_id << "HTTP code:" << http_error_code;
        emit finished (Error);
    }
    void EncryptFolderJob.slot_unlock_folder_success (QByteArray &file_id) {
        q_c_info (lc_encrypt_folder_job ()) << "Unlocking success for" << file_id;
        emit finished (Success);
    }

    }
    