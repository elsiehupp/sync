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

    EncryptFolderJob (AccountPtr &account, SyncJournalDb *journal, string &path, QByteArray &fileId, GLib.Object *parent = nullptr);
    void start ();

    string errorString ();

signals:
    void finished (int status);

private slots:
    void slotEncryptionFlagSuccess (QByteArray &folderId);
    void slotEncryptionFlagError (QByteArray &folderId, int httpReturnCode);
    void slotLockForEncryptionSuccess (QByteArray &folderId, QByteArray &token);
    void slotLockForEncryptionError (QByteArray &folderId, int httpReturnCode);
    void slotUnlockFolderSuccess (QByteArray &folderId);
    void slotUnlockFolderError (QByteArray &folderId, int httpReturnCode);
    void slotUploadMetadataSuccess (QByteArray &folderId);
    void slotUpdateMetadataError (QByteArray &folderId, int httpReturnCode);

private:
    AccountPtr _account;
    SyncJournalDb *_journal;
    string _path;
    QByteArray _fileId;
    QByteArray _folderToken;
    string _errorString;
};

    EncryptFolderJob.EncryptFolderJob (AccountPtr &account, SyncJournalDb *journal, string &path, QByteArray &fileId, GLib.Object *parent)
        : GLib.Object (parent)
        , _account (account)
        , _journal (journal)
        , _path (path)
        , _fileId (fileId) {
    }
    
    void EncryptFolderJob.start () {
        auto job = new Occ.SetEncryptionFlagApiJob (_account, _fileId, Occ.SetEncryptionFlagApiJob.Set, this);
        connect (job, &Occ.SetEncryptionFlagApiJob.success, this, &EncryptFolderJob.slotEncryptionFlagSuccess);
        connect (job, &Occ.SetEncryptionFlagApiJob.error, this, &EncryptFolderJob.slotEncryptionFlagError);
        job.start ();
    }
    
    string EncryptFolderJob.errorString () {
        return _errorString;
    }
    
    void EncryptFolderJob.slotEncryptionFlagSuccess (QByteArray &fileId) {
        SyncJournalFileRecord rec;
        _journal.getFileRecord (_path, &rec);
        if (rec.isValid ()) {
            rec._isE2eEncrypted = true;
            _journal.setFileRecord (rec);
        }
    
        auto lockJob = new LockEncryptFolderApiJob (_account, fileId, this);
        connect (lockJob, &LockEncryptFolderApiJob.success,
                this, &EncryptFolderJob.slotLockForEncryptionSuccess);
        connect (lockJob, &LockEncryptFolderApiJob.error,
                this, &EncryptFolderJob.slotLockForEncryptionError);
        lockJob.start ();
    }
    
    void EncryptFolderJob.slotEncryptionFlagError (QByteArray &fileId, int httpErrorCode) {
        qDebug () << "Error on the encryption flag of" << fileId << "HTTP code:" << httpErrorCode;
        emit finished (Error);
    }
    
    void EncryptFolderJob.slotLockForEncryptionSuccess (QByteArray &fileId, QByteArray &token) {
        _folderToken = token;
    
        FolderMetadata emptyMetadata (_account);
        auto encryptedMetadata = emptyMetadata.encryptedMetadata ();
        if (encryptedMetadata.isEmpty ()) {
            //TODO : Mark the folder as unencrypted as the metadata generation failed.
            _errorString = tr ("Could not generate the metadata for encryption, Unlocking the folder.\n"
                              "This can be an issue with your OpenSSL libraries.");
            emit finished (Error);
            return;
        }
    
        auto storeMetadataJob = new StoreMetaDataApiJob (_account, fileId, emptyMetadata.encryptedMetadata (), this);
        connect (storeMetadataJob, &StoreMetaDataApiJob.success,
                this, &EncryptFolderJob.slotUploadMetadataSuccess);
        connect (storeMetadataJob, &StoreMetaDataApiJob.error,
                this, &EncryptFolderJob.slotUpdateMetadataError);
        storeMetadataJob.start ();
    }
    
    void EncryptFolderJob.slotUploadMetadataSuccess (QByteArray &folderId) {
        auto unlockJob = new UnlockEncryptFolderApiJob (_account, folderId, _folderToken, this);
        connect (unlockJob, &UnlockEncryptFolderApiJob.success,
                        this, &EncryptFolderJob.slotUnlockFolderSuccess);
        connect (unlockJob, &UnlockEncryptFolderApiJob.error,
                        this, &EncryptFolderJob.slotUnlockFolderError);
        unlockJob.start ();
    }
    
    void EncryptFolderJob.slotUpdateMetadataError (QByteArray &folderId, int httpReturnCode) {
        Q_UNUSED (httpReturnCode);
    
        auto unlockJob = new UnlockEncryptFolderApiJob (_account, folderId, _folderToken, this);
        connect (unlockJob, &UnlockEncryptFolderApiJob.success,
                        this, &EncryptFolderJob.slotUnlockFolderSuccess);
        connect (unlockJob, &UnlockEncryptFolderApiJob.error,
                        this, &EncryptFolderJob.slotUnlockFolderError);
        unlockJob.start ();
    }
    
    void EncryptFolderJob.slotLockForEncryptionError (QByteArray &fileId, int httpErrorCode) {
        qCInfo (lcEncryptFolderJob ()) << "Locking error for" << fileId << "HTTP code:" << httpErrorCode;
        emit finished (Error);
    }
    
    void EncryptFolderJob.slotUnlockFolderError (QByteArray &fileId, int httpErrorCode) {
        qCInfo (lcEncryptFolderJob ()) << "Unlocking error for" << fileId << "HTTP code:" << httpErrorCode;
        emit finished (Error);
    }
    void EncryptFolderJob.slotUnlockFolderSuccess (QByteArray &fileId) {
        qCInfo (lcEncryptFolderJob ()) << "Unlocking success for" << fileId;
        emit finished (Success);
    }
    
    }
    