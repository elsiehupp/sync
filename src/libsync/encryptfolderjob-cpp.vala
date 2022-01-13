/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>

namespace Occ {

Q_LOGGING_CATEGORY (lcEncryptFolderJob, "nextcloud.sync.propagator.encryptfolder", QtInfoMsg)

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
