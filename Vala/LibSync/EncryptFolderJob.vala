/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #pragma once

namespace Occ {

class EncryptFolderJob : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum Status {
        SUCCESS = 0,
        ERROR,
    }


    /***********************************************************
    ***********************************************************/
    private AccountPointer account;
    private SyncJournalDb journal;
    private string path;
    private GLib.ByteArray file_identifier;
    private GLib.ByteArray folder_token;
    private string error_string;


    signal void on_finished (int status);


    /***********************************************************
    ***********************************************************/
    public EncryptFolderJob (AccountPointer account, SyncJournalDb journal, string path, GLib.ByteArray file_identifier, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.account = account;
        this.journal = journal;
        this.path = path;
        this.file_identifier = file_identifier;
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () {
        var job = new Occ.SetEncryptionFlagApiJob (this.account, this.file_identifier, Occ.SetEncryptionFlagApiJob.Set, this);
        connect (job, &Occ.SetEncryptionFlagApiJob.on_success, this, &EncryptFolderJob.on_encryption_flag_success);
        connect (job, &Occ.SetEncryptionFlagApiJob.error, this, &EncryptFolderJob.on_encryption_flag_error);
        job.on_start ();
    }


    /***********************************************************
    ***********************************************************/
    public string error_string () {
        return this.error_string;
    }


    /***********************************************************
    ***********************************************************/
    private void on_encryption_flag_success (GLib.ByteArray file_identifier) {
        SyncJournalFileRecord record;
        this.journal.get_file_record (this.path, record);
        if (record.is_valid ()) {
            record.is_e2e_encrypted = true;
            this.journal.set_file_record (record);
        }

        var lock_job = new LockEncryptFolderApiJob (this.account, file_identifier, this);
        connect (lock_job, &LockEncryptFolderApiJob.on_success,
                this, &EncryptFolderJob.on_lock_for_encryption_success);
        connect (lock_job, &LockEncryptFolderApiJob.error,
                this, &EncryptFolderJob.on_lock_for_encryption_error);
        lock_job.on_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_encryption_flag_error (GLib.ByteArray file_identifier, int http_error_code) {
        GLib.debug () << "Error on the encryption flag of" << file_identifier << "HTTP code:" << http_error_code;
        /* emit */ finished (Error);
    }


    /***********************************************************
    ***********************************************************/
    private void on_lock_for_encryption_success (GLib.ByteArray file_identifier, GLib.ByteArray token) {
        this.folder_token = token;

        FolderMetadata empty_metadata (this.account);
        var encrypted_metadata = empty_metadata.encrypted_metadata ();
        if (encrypted_metadata.is_empty ()) {
            //TODO : Mark the folder as unencrypted as the metadata generation failed.
            this.error_string = _("Could not generate the metadata for encryption, Unlocking the folder.\n"
                              "This can be an issue with your OpenSSL libraries.");
            /* emit */ finished (Error);
            return;
        }

        var store_metadata_job = new StoreMetaDataApiJob (this.account, file_identifier, empty_metadata.encrypted_metadata (), this);
        connect (store_metadata_job, &StoreMetaDataApiJob.on_success,
                this, &EncryptFolderJob.on_upload_metadata_success);
        connect (store_metadata_job, &StoreMetaDataApiJob.error,
                this, &EncryptFolderJob.on_update_metadata_error);
        store_metadata_job.on_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_lock_for_encryption_error (GLib.ByteArray file_identifier, int http_error_code) {
        GLib.info (lc_encrypt_folder_job ()) << "Locking error for" << file_identifier << "HTTP code:" << http_error_code;
        /* emit */ finished (Error);
    }


    /***********************************************************
    ***********************************************************/
    private void on_unlock_folder_success (GLib.ByteArray file_identifier) {
        GLib.info (lc_encrypt_folder_job ()) << "Unlocking on_success for" << file_identifier;
        /* emit */ finished (Success);
    }


    /***********************************************************
    ***********************************************************/
    private void on_unlock_folder_error (GLib.ByteArray file_identifier, int http_error_code) {
        GLib.info (lc_encrypt_folder_job ()) << "Unlocking error for" << file_identifier << "HTTP code:" << http_error_code;
        /* emit */ finished (Error);
    }


    /***********************************************************
    ***********************************************************/
    private void on_upload_metadata_success (GLib.ByteArray folder_identifier) {
        var unlock_job = new UnlockEncryptFolderApiJob (this.account, folder_identifier, this.folder_token, this);
        connect (unlock_job, &UnlockEncryptFolderApiJob.on_success,
                        this, &EncryptFolderJob.on_unlock_folder_success);
        connect (unlock_job, &UnlockEncryptFolderApiJob.error,
                        this, &EncryptFolderJob.on_unlock_folder_error);
        unlock_job.on_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_update_metadata_error (GLib.ByteArray folder_identifier, int http_return_code) {
        //  Q_UNUSED (http_return_code);

        var unlock_job = new UnlockEncryptFolderApiJob (this.account, folder_identifier, this.folder_token, this);
        connect (unlock_job, &UnlockEncryptFolderApiJob.on_success,
                        this, &EncryptFolderJob.on_unlock_folder_success);
        connect (unlock_job, &UnlockEncryptFolderApiJob.error,
                        this, &EncryptFolderJob.on_unlock_folder_error);
        unlock_job.on_start ();
    }

} // class EncryptFolderJob

} // namespace Occ
    