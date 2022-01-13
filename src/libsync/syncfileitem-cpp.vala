/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>

namespace Occ {

Q_LOGGING_CATEGORY (lcFileItem, "nextcloud.sync.fileitem", QtInfoMsg)

SyncJournalFileRecord SyncFileItem.toSyncJournalFileRecordWithInode (string &localFileName) {
    SyncJournalFileRecord rec;
    rec._path = destination ().toUtf8 ();
    rec._modtime = _modtime;

    // Some types should never be written to the database when propagation completes
    rec._type = _type;
    if (rec._type == ItemTypeVirtualFileDownload)
        rec._type = ItemTypeFile;
    if (rec._type == ItemTypeVirtualFileDehydration)
        rec._type = ItemTypeVirtualFile;

    rec._etag = _etag;
    rec._fileId = _fileId;
    rec._fileSize = _size;
    rec._remotePerm = _remotePerm;
    rec._serverHasIgnoredFiles = _serverHasIgnoredFiles;
    rec._checksumHeader = _checksumHeader;
    rec._e2eMangledName = _encryptedFileName.toUtf8 ();
    rec._isE2eEncrypted = _isEncrypted;

    // Update the inode if possible
    rec._inode = _inode;
    if (FileSystem.getInode (localFileName, &rec._inode)) {
        qCDebug (lcFileItem) << localFileName << "Retrieved inode " << rec._inode << " (previous item inode : " << _inode << ")";
    } else {
        // use the "old" inode coming with the item for the case where the
        // filesystem stat fails. That can happen if the the file was removed
        // or renamed meanwhile. For the rename case we still need the inode to
        // detect the rename though.
        qCWarning (lcFileItem) << "Failed to query the 'inode' for file " << localFileName;
    }
    return rec;
}

SyncFileItemPtr SyncFileItem.fromSyncJournalFileRecord (SyncJournalFileRecord &rec) {
    auto item = SyncFileItemPtr.create ();
    item._file = rec.path ();
    item._inode = rec._inode;
    item._modtime = rec._modtime;
    item._type = rec._type;
    item._etag = rec._etag;
    item._fileId = rec._fileId;
    item._size = rec._fileSize;
    item._remotePerm = rec._remotePerm;
    item._serverHasIgnoredFiles = rec._serverHasIgnoredFiles;
    item._checksumHeader = rec._checksumHeader;
    item._encryptedFileName = rec.e2eMangledName ();
    item._isEncrypted = rec._isE2eEncrypted;
    return item;
}

}
