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

class QLocalServer;
class QLocalSocket;

namespace OCC {
class GETFileJob;
class SyncJournalDb;
class VfsCfApi;

namespace EncryptionHelper {
    class StreamingDecryptor;
};

class HydrationJob : public QObject {
public:
    enum Status {
        Success = 0,
        Error,
        Cancelled,
    };
    Q_ENUM (Status)

    explicit HydrationJob (QObject *parent = nullptr);

    AccountPtr account () const;
    void setAccount (AccountPtr &account);

    QString remotePath () const;
    void setRemotePath (QString &remotePath);

    QString localPath () const;
    void setLocalPath (QString &localPath);

    SyncJournalDb *journal () const;
    void setJournal (SyncJournalDb *journal);

    QString requestId () const;
    void setRequestId (QString &requestId);

    QString folderPath () const;
    void setFolderPath (QString &folderPath);

    bool isEncryptedFile () const;
    void setIsEncryptedFile (bool isEncrypted);

    QString e2eMangledName () const;
    void setE2eMangledName (QString &e2eMangledName);

    qint64 fileTotalSize () const;
    void setFileTotalSize (qint64 totalSize);

    Status status () const;

    void start ();
    void cancel ();
    void finalize (OCC.VfsCfApi *vfs);

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

} // namespace OCC
