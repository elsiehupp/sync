/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/
// #pragma once

// #include <GLib.Object>


namespace Occ {

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

    string remotePath ();
    void setRemotePath (string &remotePath);

    string localPath ();
    void setLocalPath (string &localPath);

    SyncJournalDb *journal ();
    void setJournal (SyncJournalDb *journal);

    string requestId ();
    void setRequestId (string &requestId);

    string folderPath ();
    void setFolderPath (string &folderPath);

    bool isEncryptedFile ();
    void setIsEncryptedFile (bool isEncrypted);

    string e2eMangledName ();
    void setE2eMangledName (string &e2eMangledName);

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
    string _remotePath;
    string _localPath;
    SyncJournalDb *_journal = nullptr;
    bool _isCancelled = false;

    string _requestId;
    string _folderPath;

    bool _isEncryptedFile = false;
    string _e2eMangledName;

    QLocalServer *_transferDataServer = nullptr;
    QLocalServer *_signalServer = nullptr;
    QLocalSocket *_transferDataSocket = nullptr;
    QLocalSocket *_signalSocket = nullptr;
    GETFileJob *_job = nullptr;
    Status _status = Success;
};

} // namespace Occ
