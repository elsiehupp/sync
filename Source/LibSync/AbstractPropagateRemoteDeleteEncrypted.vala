/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <GLib.Object>
// #include <string>
// #include <QNetworkReply>
// #include <QFileInfo>
// #include <QLoggingCategory>

namespace Occ {

/***********************************************************
@brief The AbstractPropagateRemoteDeleteEncrypted class is the base class for Propagate Remote Delete Encrypted jobs
@ingroup libsync
***********************************************************/
class AbstractPropagateRemoteDeleteEncrypted : GLib.Object {
public:
    AbstractPropagateRemoteDeleteEncrypted (OwncloudPropagator *propagator, SyncFileItemPtr item, GLib.Object *parent);
    ~AbstractPropagateRemoteDeleteEncrypted () override = default;

    QNetworkReply.NetworkError networkError ();
    string errorString ();

    virtual void start () = 0;

signals:
    void finished (bool success);

protected:
    void storeFirstError (QNetworkReply.NetworkError err);
    void storeFirstErrorString (string &errString);

    void startLsColJob (string &path);
    void slotFolderEncryptedIdReceived (QStringList &list);
    void slotTryLock (QByteArray &folderId);
    void slotFolderLockedSuccessfully (QByteArray &folderId, QByteArray &token);
    virtual void slotFolderUnLockedSuccessfully (QByteArray &folderId);
    virtual void slotFolderEncryptedMetadataReceived (QJsonDocument &json, int statusCode) = 0;
    void slotDeleteRemoteItemFinished ();

    void deleteRemoteItem (string &filename);
    void unlockFolder ();
    void taskFailed ();

protected:
    OwncloudPropagator *_propagator = nullptr;
    SyncFileItemPtr _item;
    QByteArray _folderToken;
    QByteArray _folderId;
    bool _folderLocked = false;
    bool _isTaskFailed = false;
    QNetworkReply.NetworkError _networkError = QNetworkReply.NoError;
    string _errorString;
};

}

AbstractPropagateRemoteDeleteEncrypted.AbstractPropagateRemoteDeleteEncrypted (OwncloudPropagator *propagator, SyncFileItemPtr item, GLib.Object *parent)
    : GLib.Object (parent)
    , _propagator (propagator)
    , _item (item) {}

QNetworkReply.NetworkError AbstractPropagateRemoteDeleteEncrypted.networkError () {
    return _networkError;
}

string AbstractPropagateRemoteDeleteEncrypted.errorString () {
    return _errorString;
}

void AbstractPropagateRemoteDeleteEncrypted.storeFirstError (QNetworkReply.NetworkError err) {
    if (_networkError == QNetworkReply.NetworkError.NoError) {
        _networkError = err;
    }
}

void AbstractPropagateRemoteDeleteEncrypted.storeFirstErrorString (string &errString) {
    if (_errorString.isEmpty ()) {
        _errorString = errString;
    }
}

void AbstractPropagateRemoteDeleteEncrypted.startLsColJob (string &path) {
    qCDebug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Folder is encrypted, let's get the Id from it.";
    auto job = new LsColJob (_propagator.account (), _propagator.fullRemotePath (path), this);
    job.setProperties ({"resourcetype", "http://owncloud.org/ns:fileid"});
    connect (job, &LsColJob.directoryListingSubfolders, this, &AbstractPropagateRemoteDeleteEncrypted.slotFolderEncryptedIdReceived);
    connect (job, &LsColJob.finishedWithError, this, &AbstractPropagateRemoteDeleteEncrypted.taskFailed);
    job.start ();
}

void AbstractPropagateRemoteDeleteEncrypted.slotFolderEncryptedIdReceived (QStringList &list) {
    qCDebug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Received id of folder, trying to lock it so we can prepare the metadata";
    auto job = qobject_cast<LsColJob> (sender ());
    const ExtraFolderInfo folderInfo = job._folderInfos.value (list.first ());
    slotTryLock (folderInfo.fileId);
}

void AbstractPropagateRemoteDeleteEncrypted.slotTryLock (QByteArray &folderId) {
    auto lockJob = new LockEncryptFolderApiJob (_propagator.account (), folderId, this);
    connect (lockJob, &LockEncryptFolderApiJob.success, this, &AbstractPropagateRemoteDeleteEncrypted.slotFolderLockedSuccessfully);
    connect (lockJob, &LockEncryptFolderApiJob.error, this, &AbstractPropagateRemoteDeleteEncrypted.taskFailed);
    lockJob.start ();
}

void AbstractPropagateRemoteDeleteEncrypted.slotFolderLockedSuccessfully (QByteArray &folderId, QByteArray &token) {
    qCDebug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Folder id" << folderId << "Locked Successfully for Upload, Fetching Metadata";
    _folderLocked = true;
    _folderToken = token;
    _folderId = folderId;

    auto job = new GetMetadataApiJob (_propagator.account (), _folderId);
    connect (job, &GetMetadataApiJob.jsonReceived, this, &AbstractPropagateRemoteDeleteEncrypted.slotFolderEncryptedMetadataReceived);
    connect (job, &GetMetadataApiJob.error, this, &AbstractPropagateRemoteDeleteEncrypted.taskFailed);
    job.start ();
}

void AbstractPropagateRemoteDeleteEncrypted.slotFolderUnLockedSuccessfully (QByteArray &folderId) {
    Q_UNUSED (folderId);
    qCDebug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Folder id" << folderId << "successfully unlocked";
    _folderLocked = false;
    _folderToken = "";
}

void AbstractPropagateRemoteDeleteEncrypted.slotDeleteRemoteItemFinished () {
    auto *deleteJob = qobject_cast<DeleteJob> (GLib.Object.sender ());

    Q_ASSERT (deleteJob);

    if (!deleteJob) {
        qCCritical (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Sender is not a DeleteJob instance.";
        taskFailed ();
        return;
    }

    const auto err = deleteJob.reply ().error ();

    _item._httpErrorCode = deleteJob.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
    _item._responseTimeStamp = deleteJob.responseTimestamp ();
    _item._requestId = deleteJob.requestId ();

    if (err != QNetworkReply.NoError && err != QNetworkReply.ContentNotFoundError) {
        storeFirstErrorString (deleteJob.errorString ());
        storeFirstError (err);

        taskFailed ();
        return;
    }

    // A 404 reply is also considered a success here : We want to make sure
    // a file is gone from the server. It not being there in the first place
    // is ok. This will happen for files that are in the DB but not on
    // the server or the local file system.
    if (_item._httpErrorCode != 204 && _item._httpErrorCode != 404) {
        // Normally we expect "204 No Content"
        // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
        // throw an error.
        storeFirstErrorString (tr ("Wrong HTTP code returned by server. Expected 204, but received \"%1 %2\".")
                       .arg (_item._httpErrorCode)
                       .arg (deleteJob.reply ().attribute (QNetworkRequest.HttpReasonPhraseAttribute).toString ()));

        taskFailed ();
        return;
    }

    _propagator._journal.deleteFileRecord (_item._originalFile, _item.isDirectory ());
    _propagator._journal.commit ("Remote Remove");

    unlockFolder ();
}

void AbstractPropagateRemoteDeleteEncrypted.deleteRemoteItem (string &filename) {
    qCInfo (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Deleting nested encrypted item" << filename;

    auto deleteJob = new DeleteJob (_propagator.account (), _propagator.fullRemotePath (filename), this);
    deleteJob.setFolderToken (_folderToken);

    connect (deleteJob, &DeleteJob.finishedSignal, this, &AbstractPropagateRemoteDeleteEncrypted.slotDeleteRemoteItemFinished);

    deleteJob.start ();
}

void AbstractPropagateRemoteDeleteEncrypted.unlockFolder () {
    if (!_folderLocked) {
        emit finished (true);
        return;
    }

    qCDebug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Unlocking folder" << _folderId;
    auto unlockJob = new UnlockEncryptFolderApiJob (_propagator.account (), _folderId, _folderToken, this);

    connect (unlockJob, &UnlockEncryptFolderApiJob.success, this, &AbstractPropagateRemoteDeleteEncrypted.slotFolderUnLockedSuccessfully);
    connect (unlockJob, &UnlockEncryptFolderApiJob.error, this, [this] (QByteArray& fileId, int httpReturnCode) {
        Q_UNUSED (fileId);
        _folderLocked = false;
        _folderToken = "";
        _item._httpErrorCode = httpReturnCode;
        _errorString = tr ("\"%1 Failed to unlock encrypted folder %2\".")
                .arg (httpReturnCode)
                .arg (string.fromUtf8 (fileId));
        _item._errorString =_errorString;
        taskFailed ();
    });
    unlockJob.start ();
}

void AbstractPropagateRemoteDeleteEncrypted.taskFailed () {
    qCDebug (ABSTRACT_PROPAGATE_REMOVE_ENCRYPTED) << "Task failed for job" << sender ();
    _isTaskFailed = true;
    if (_folderLocked) {
        unlockFolder ();
    } else {
        emit finished (false);
    }
}

} // namespace Occ
