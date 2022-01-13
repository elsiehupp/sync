/*
 * Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 */
// #pragma once

// #include <QObject>

namespace OCC {
class SyncJournalDb;

class OWNCLOUDSYNC_EXPORT EncryptFolderJob : public QObject {
public:
    enum Status {
        Success = 0,
        Error,
    };
    Q_ENUM (Status)

    explicit EncryptFolderJob (AccountPtr &account, SyncJournalDb *journal, QString &path, QByteArray &fileId, QObject *parent = nullptr);
    void start ();

    QString errorString () const;

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
    QString _path;
    QByteArray _fileId;
    QByteArray _folderToken;
    QString _errorString;
};
}
