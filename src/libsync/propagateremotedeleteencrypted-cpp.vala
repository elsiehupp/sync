/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QFileInfo>

using namespace Occ;

Q_LOGGING_CATEGORY (PROPAGATE_REMOVE_ENCRYPTED, "nextcloud.sync.propagator.remove.encrypted")

PropagateRemoteDeleteEncrypted.PropagateRemoteDeleteEncrypted (OwncloudPropagator *propagator, SyncFileItemPtr item, GLib.Object *parent)
    : AbstractPropagateRemoteDeleteEncrypted (propagator, item, parent) {

}

void PropagateRemoteDeleteEncrypted.start () {
    Q_ASSERT (!_item._encryptedFileName.isEmpty ());

    const QFileInfo info (_item._encryptedFileName);
    startLsColJob (info.path ());
}

void PropagateRemoteDeleteEncrypted.slotFolderUnLockedSuccessfully (QByteArray &folderId) {
    AbstractPropagateRemoteDeleteEncrypted.slotFolderUnLockedSuccessfully (folderId);
    emit finished (!_isTaskFailed);
}

void PropagateRemoteDeleteEncrypted.slotFolderEncryptedMetadataReceived (QJsonDocument &json, int statusCode) {
    if (statusCode == 404) {
        qCDebug (PROPAGATE_REMOVE_ENCRYPTED) << "Metadata not found, but let's proceed with removing the file anyway.";
        deleteRemoteItem (_item._encryptedFileName);
        return;
    }

    FolderMetadata metadata (_propagator.account (), json.toJson (QJsonDocument.Compact), statusCode);

    qCDebug (PROPAGATE_REMOVE_ENCRYPTED) << "Metadata Received, preparing it for removal of the file";

    const QFileInfo info (_propagator.fullLocalPath (_item._file));
    const string fileName = info.fileName ();

    // Find existing metadata for this file
    bool found = false;
    const QVector<EncryptedFile> files = metadata.files ();
    for (EncryptedFile &file : files) {
        if (file.originalFilename == fileName) {
            metadata.removeEncryptedFile (file);
            found = true;
            break;
        }
    }

    if (!found) {
        // file is not found in the metadata, but we still need to remove it
        deleteRemoteItem (_item._encryptedFileName);
        return;
    }

    qCDebug (PROPAGATE_REMOVE_ENCRYPTED) << "Metadata updated, sending to the server.";

    auto job = new UpdateMetadataApiJob (_propagator.account (), _folderId, metadata.encryptedMetadata (), _folderToken);
    connect (job, &UpdateMetadataApiJob.success, this, [this] (QByteArray& fileId) {
        Q_UNUSED (fileId);
        deleteRemoteItem (_item._encryptedFileName);
    });
    connect (job, &UpdateMetadataApiJob.error, this, &PropagateRemoteDeleteEncrypted.taskFailed);
    job.start ();
}
