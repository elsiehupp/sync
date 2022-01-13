/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/
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
}
