/*
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/
// #pragma once

// #include <GLib.Object>

class QLocalSocket;

namespace Occ {
class SyncJournalDb;

namespace EncryptionHelper {
    class StreamingDecryptor;
};

class HydrationJob : GLib.Object {
public:
    enum Status {
        Success = 0,
        Error,
        Cancelled,
    };
    Q_ENUM (Status)

    HydrationJob (GLib.Object *parent = nullptr);

    AccountPtr account ();
    void setAccount (AccountPtr &account);

    QString remotePath ();
    void setRemotePath (QString &remotePath);

    QString localPath ();
    void setLocalPath (QString &localPath);

    SyncJournalDb *journal ();
    void setJournal (SyncJournalDb *journal);

    QString requestId ();
    void setRequestId (QString &requestId);

    QString folderPath ();
    void setFolderPath (QString &folderPath);

    bool isEncryptedFile ();
    void setIsEncryptedFile (bool isEncrypted);

    QString e2eMangledName ();
    void setE2eMangledName (QString &e2eMangledName);

    int64 fileTotalSize ();
    void setFileTotalSize (int64 totalSize);

    Status status ();

    void start ();
    void cancel ();
    void finalize (Occ.VfsCfApi *vfs);

public slots:
    void slotCheckFolderId (QStringList &list);
    void slotFolderIdError ();
    void slotCheckFolderEncryptedMetadata (QJsonDocument &json);
    void slotFolderEncryptedMetadataError (QByteArray &fileId, int httpReturnCode);

signals:
    void finished (HydrationJob *job);

private:
    void emitFinished (Status status);

    void onNewConnection ();
    void onCancellationServerNewConnection ();
    void onGetFinished ();

    void handleNewConnection ();
    void handleNewConnectionForEncryptedFile ();

    void startServerAndWaitForConnections ();

    AccountPtr _account;
    QString _remotePath;
    QString _localPath;
    SyncJournalDb *_journal = nullptr;
    bool _isCancelled = false;

    QString _requestId;
    QString _folderPath;

    bool _isEncryptedFile = false;
    QString _e2eMangledName;

    QLocalServer *_transferDataServer = nullptr;
    QLocalServer *_signalServer = nullptr;
    QLocalSocket *_transferDataSocket = nullptr;
    QLocalSocket *_signalSocket = nullptr;
    GETFileJob *_job = nullptr;
    Status _status = Success;
};

} // namespace Occ
