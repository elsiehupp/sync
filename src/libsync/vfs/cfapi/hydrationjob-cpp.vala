/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <clientsideencryptionjobs.h>

// #include <QLocalServer>
// #include <QLocalSocket>

Q_LOGGING_CATEGORY (lcHydration, "nextcloud.sync.vfs.hydrationjob", QtInfoMsg)

Occ.HydrationJob.HydrationJob (GLib.Object *parent)
    : GLib.Object (parent) {
}

Occ.AccountPtr Occ.HydrationJob.account () {
    return _account;
}

void Occ.HydrationJob.setAccount (AccountPtr &account) {
    _account = account;
}

string Occ.HydrationJob.remotePath () {
    return _remotePath;
}

void Occ.HydrationJob.setRemotePath (string &remotePath) {
    _remotePath = remotePath;
}

string Occ.HydrationJob.localPath () {
    return _localPath;
}

void Occ.HydrationJob.setLocalPath (string &localPath) {
    _localPath = localPath;
}

Occ.SyncJournalDb *Occ.HydrationJob.journal () {
    return _journal;
}

void Occ.HydrationJob.setJournal (SyncJournalDb *journal) {
    _journal = journal;
}

string Occ.HydrationJob.requestId () {
    return _requestId;
}

void Occ.HydrationJob.setRequestId (string &requestId) {
    _requestId = requestId;
}

string Occ.HydrationJob.folderPath () {
    return _folderPath;
}

void Occ.HydrationJob.setFolderPath (string &folderPath) {
    _folderPath = folderPath;
}

bool Occ.HydrationJob.isEncryptedFile () {
    return _isEncryptedFile;
}

void Occ.HydrationJob.setIsEncryptedFile (bool isEncrypted) {
    _isEncryptedFile = isEncrypted;
}

string Occ.HydrationJob.e2eMangledName () {
    return _e2eMangledName;
}

void Occ.HydrationJob.setE2eMangledName (string &e2eMangledName) {
    _e2eMangledName = e2eMangledName;
}

Occ.HydrationJob.Status Occ.HydrationJob.status () {
    return _status;
}

void Occ.HydrationJob.start () {
    Q_ASSERT (_account);
    Q_ASSERT (_journal);
    Q_ASSERT (!_remotePath.isEmpty () && !_localPath.isEmpty ());
    Q_ASSERT (!_requestId.isEmpty () && !_folderPath.isEmpty ());

    Q_ASSERT (_remotePath.endsWith ('/'));
    Q_ASSERT (_localPath.endsWith ('/'));
    Q_ASSERT (!_folderPath.startsWith ('/'));

    const auto startServer = [this] (string &serverName) . QLocalServer * {
        const auto server = new QLocalServer (this);
        const auto listenResult = server.listen (serverName);
        if (!listenResult) {
            qCCritical (lcHydration) << "Couldn't get server to listen" << serverName
                                    << _localPath << _folderPath;
            if (!_isCancelled) {
                emitFinished (Error);
            }
            return nullptr;
        }
        qCInfo (lcHydration) << "Server ready, waiting for connections" << serverName
                            << _localPath << _folderPath;
        return server;
    };

    // Start cancellation server
    _signalServer = startServer (_requestId + ":cancellation");
    Q_ASSERT (_signalServer);
    if (!_signalServer) {
        return;
    }
    connect (_signalServer, &QLocalServer.newConnection, this, &HydrationJob.onCancellationServerNewConnection);

    // Start transfer data server
    _transferDataServer = startServer (_requestId);
    Q_ASSERT (_transferDataServer);
    if (!_transferDataServer) {
        return;
    }
    connect (_transferDataServer, &QLocalServer.newConnection, this, &HydrationJob.onNewConnection);
}

void Occ.HydrationJob.slotFolderIdError () {
    // TODO : the following code is borrowed from PropagateDownloadEncrypted (see HydrationJob.onNewConnection () for explanation of next steps)
    qCCritical (lcHydration) << "Failed to get encrypted metadata of folder" << _requestId << _localPath << _folderPath;
    emitFinished (Error);
}

void Occ.HydrationJob.slotCheckFolderId (QStringList &list) {
    // TODO : the following code is borrowed from PropagateDownloadEncrypted (see HydrationJob.onNewConnection () for explanation of next steps)
    auto job = qobject_cast<LsColJob> (sender ());
    const string folderId = list.first ();
    qCDebug (lcHydration) << "Received id of folder" << folderId;

    const ExtraFolderInfo &folderInfo = job._folderInfos.value (folderId);

    // Now that we have the folder-id we need it's JSON metadata
    auto metadataJob = new GetMetadataApiJob (_account, folderInfo.fileId);
    connect (metadataJob, &GetMetadataApiJob.jsonReceived,
        this, &HydrationJob.slotCheckFolderEncryptedMetadata);
    connect (metadataJob, &GetMetadataApiJob.error,
        this, &HydrationJob.slotFolderEncryptedMetadataError);

    metadataJob.start ();
}

void Occ.HydrationJob.slotFolderEncryptedMetadataError (QByteArray & /*fileId*/, int /*httpReturnCode*/) {
    // TODO : the following code is borrowed from PropagateDownloadEncrypted (see HydrationJob.onNewConnection () for explanation of next steps)
    qCCritical (lcHydration) << "Failed to find encrypted metadata information of remote file" << e2eMangledName ();
    emitFinished (Error);
    return;
}

void Occ.HydrationJob.slotCheckFolderEncryptedMetadata (QJsonDocument &json) {
    // TODO : the following code is borrowed from PropagateDownloadEncrypted (see HydrationJob.onNewConnection () for explanation of next steps)
    qCDebug (lcHydration) << "Metadata Received reading" << e2eMangledName ();
    const string filename = e2eMangledName ();
    auto meta = new FolderMetadata (_account, json.toJson (QJsonDocument.Compact));
    const QVector<EncryptedFile> files = meta.files ();

    EncryptedFile encryptedInfo = {};

    const string encryptedFileExactName = e2eMangledName ().section (QLatin1Char ('/'), -1);
    for (EncryptedFile &file : files) {
        if (encryptedFileExactName == file.encryptedFilename) {
            EncryptedFile encryptedInfo = file;
            encryptedInfo = file;

            qCDebug (lcHydration) << "Found matching encrypted metadata for file, starting download" << _requestId << _folderPath;
            _transferDataSocket = _transferDataServer.nextPendingConnection ();
            _job = new GETEncryptedFileJob (_account, _remotePath + e2eMangledName (), _transferDataSocket, {}, {}, 0, encryptedInfo, this);

            connect (qobject_cast<GETEncryptedFileJob> (_job), &GETEncryptedFileJob.finishedSignal, this, &HydrationJob.onGetFinished);
            _job.start ();
            return;
        }
    }

    qCCritical (lcHydration) << "Failed to find encrypted metadata information of a remote file" << filename;
    emitFinished (Error);
}

void Occ.HydrationJob.cancel () {
    Q_ASSERT (_signalSocket);

    _isCancelled = true;
    if (_job) {
        _job.cancel ();
    }

    _signalSocket.write ("cancelled");
    _signalSocket.close ();
    _transferDataSocket.close ();

    emitFinished (Cancelled);
}

void Occ.HydrationJob.emitFinished (Status status) {
    _status = status;
    _signalSocket.close ();

    if (status == Success) {
        connect (_transferDataSocket, &QLocalSocket.disconnected, this, [=] {
            _transferDataSocket.close ();
            emit finished (this);
        });
        _transferDataSocket.disconnectFromServer ();
        return;
    }
    _transferDataSocket.close ();

    emit finished (this);
}

void Occ.HydrationJob.onCancellationServerNewConnection () {
    Q_ASSERT (!_signalSocket);

    qCInfo (lcHydration) << "Got new connection on cancellation server" << _requestId << _folderPath;
    _signalSocket = _signalServer.nextPendingConnection ();
}

void Occ.HydrationJob.onNewConnection () {
    Q_ASSERT (!_transferDataSocket);
    Q_ASSERT (!_job);

    if (isEncryptedFile ()) {
        handleNewConnectionForEncryptedFile ();
    } else {
        handleNewConnection ();
    }
}

void Occ.HydrationJob.finalize (Occ.VfsCfApi *vfs) {
    // Mark the file as hydrated in the sync journal
    SyncJournalFileRecord record;
    _journal.getFileRecord (_folderPath, &record);
    Q_ASSERT (record.isValid ());
    if (!record.isValid ()) {
        qCWarning (lcHydration) << "Couldn't find record to update after hydration" << _requestId << _folderPath;
        // emitFinished (Error);
        return;
    }

    if (_isCancelled) {
        // Remove placeholder file because there might be already pumped
        // some data into it
        QFile.remove (_localPath + _folderPath);
        // Create a new placeholder file
        const auto item = SyncFileItem.fromSyncJournalFileRecord (record);
        vfs.createPlaceholder (*item);
        return;
    }

    record._type = ItemTypeFile;
    // store the actual size of a file that has been decrypted as we will need its actual size when dehydrating it if requested
    record._fileSize = FileSystem.getSize (localPath () + folderPath ());

    _journal.setFileRecord (record);
}

void Occ.HydrationJob.onGetFinished () {
    qCInfo (lcHydration) << "GETFileJob finished" << _requestId << _folderPath << _job.reply ().error ();

    const auto isGetJobResultError = _job.reply ().error ();
    // GETFileJob deletes itself after this signal was handled
    _job = nullptr;
    if (_isCancelled) {
        return;
    }

    if (isGetJobResultError) {
        emitFinished (Error);
        return;
    }
    emitFinished (Success);
}

void Occ.HydrationJob.handleNewConnection () {
    qCInfo (lcHydration) << "Got new connection starting GETFileJob" << _requestId << _folderPath;
    _transferDataSocket = _transferDataServer.nextPendingConnection ();
    _job = new GETFileJob (_account, _remotePath + _folderPath, _transferDataSocket, {}, {}, 0, this);
    connect (_job, &GETFileJob.finishedSignal, this, &HydrationJob.onGetFinished);
    _job.start ();
}

void Occ.HydrationJob.handleNewConnectionForEncryptedFile () {
    // TODO : the following code is borrowed from PropagateDownloadEncrypted (should we factor it out and reuse? YES! Should we do it now? Probably not, as, this would imply modifying PropagateDownloadEncrypted, so we need a separate PR)
    qCInfo (lcHydration) << "Got new connection for encrypted file. Getting required info for decryption...";
    const auto rootPath = [=] () {
        const auto result = _remotePath;
        if (result.startsWith ('/')) {
            return result.mid (1);
        } else {
            return result;
        }
    } ();

    const auto remoteFilename = e2eMangledName ();
    const auto remotePath = string (rootPath + remoteFilename);
    const auto remoteParentPath = remotePath.left (remotePath.lastIndexOf ('/'));

    auto job = new LsColJob (_account, remoteParentPath, this);
    job.setProperties ({ "resourcetype", "http://owncloud.org/ns:fileid" });
    connect (job, &LsColJob.directoryListingSubfolders,
        this, &HydrationJob.slotCheckFolderId);
    connect (job, &LsColJob.finishedWithError,
        this, &HydrationJob.slotFolderIdError);
    job.start ();
}
