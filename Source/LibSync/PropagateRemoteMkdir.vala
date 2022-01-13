/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFile>
// #include <QLoggingCategory>
// #pragma once

namespace Occ {


/***********************************************************
@brief The PropagateRemoteMkdir class
@ingroup libsync
***********************************************************/
class PropagateRemoteMkdir : PropagateItemJob {
    QPointer<AbstractNetworkJob> _job;
    bool _deleteExisting;
    PropagateUploadEncrypted *_uploadEncryptedHelper;
    friend class PropagateDirectory; // So it can access the _item;
public:
    PropagateRemoteMkdir (OwncloudPropagator *propagator, SyncFileItemPtr &item);

    void start () override;
    void abort (PropagatorJob.AbortType abortType) override;

    // Creating a directory should be fast.
    bool isLikelyFinishedQuickly () override { return true; }

    /***********************************************************
    Whether an existing entity with the same name may be deleted before
    creating the directory.
    
    Default : false.
    ***********************************************************/
    void setDeleteExisting (bool enabled);

private slots:
    void slotMkdir ();
    void slotStartMkcolJob ();
    void slotStartEncryptedMkcolJob (string &path, string &filename, uint64 size);
    void slotMkcolJobFinished ();
    void slotEncryptFolderFinished ();
    void success ();

private:
    void finalizeMkColJob (QNetworkReply.NetworkError err, string &jobHttpReasonPhraseString, string &jobPath);
};

    PropagateRemoteMkdir.PropagateRemoteMkdir (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item)
        , _deleteExisting (false)
        , _uploadEncryptedHelper (nullptr) {
        const auto path = _item._file;
        const auto slashPosition = path.lastIndexOf ('/');
        const auto parentPath = slashPosition >= 0 ? path.left (slashPosition) : string ();
    
        SyncJournalFileRecord parentRec;
        bool ok = propagator._journal.getFileRecord (parentPath, &parentRec);
        if (!ok) {
            return;
        }
    }
    
    void PropagateRemoteMkdir.start () {
        if (propagator ()._abortRequested)
            return;
    
        qCDebug (lcPropagateRemoteMkdir) << _item._file;
    
        propagator ()._activeJobList.append (this);
    
        if (!_deleteExisting) {
            slotMkdir ();
            return;
        }
    
        _job = new DeleteJob (propagator ().account (),
            propagator ().fullRemotePath (_item._file),
            this);
        connect (qobject_cast<DeleteJob> (_job), &DeleteJob.finishedSignal, this, &PropagateRemoteMkdir.slotMkdir);
        _job.start ();
    }
    
    void PropagateRemoteMkdir.slotStartMkcolJob () {
        if (propagator ()._abortRequested)
            return;
    
        qCDebug (lcPropagateRemoteMkdir) << _item._file;
    
        _job = new MkColJob (propagator ().account (),
            propagator ().fullRemotePath (_item._file),
            this);
        connect (qobject_cast<MkColJob> (_job), &MkColJob.finishedWithError, this, &PropagateRemoteMkdir.slotMkcolJobFinished);
        connect (qobject_cast<MkColJob> (_job), &MkColJob.finishedWithoutError, this, &PropagateRemoteMkdir.slotMkcolJobFinished);
        _job.start ();
    }
    
    void PropagateRemoteMkdir.slotStartEncryptedMkcolJob (string &path, string &filename, uint64 size) {
        Q_UNUSED (path)
        Q_UNUSED (size)
    
        if (propagator ()._abortRequested)
            return;
    
        qDebug () << filename;
        qCDebug (lcPropagateRemoteMkdir) << filename;
    
        auto job = new MkColJob (propagator ().account (),
                                propagator ().fullRemotePath (filename), {{"e2e-token", _uploadEncryptedHelper.folderToken () }},
                                this);
        connect (job, &MkColJob.finishedWithError, this, &PropagateRemoteMkdir.slotMkcolJobFinished);
        connect (job, &MkColJob.finishedWithoutError, this, &PropagateRemoteMkdir.slotMkcolJobFinished);
        _job = job;
        _job.start ();
    }
    
    void PropagateRemoteMkdir.abort (PropagatorJob.AbortType abortType) {
        if (_job && _job.reply ())
            _job.reply ().abort ();
    
        if (abortType == AbortType.Asynchronous) {
            emit abortFinished ();
        }
    }
    
    void PropagateRemoteMkdir.setDeleteExisting (bool enabled) {
        _deleteExisting = enabled;
    }
    
    void PropagateRemoteMkdir.finalizeMkColJob (QNetworkReply.NetworkError err, string &jobHttpReasonPhraseString, string &jobPath) {
        if (_item._httpErrorCode == 405) {
            // This happens when the directory already exists. Nothing to do.
            qDebug (lcPropagateRemoteMkdir) << "Folder" << jobPath << "already exists.";
        } else if (err != QNetworkReply.NoError) {
            SyncFileItem.Status status = classifyError (err, _item._httpErrorCode,
                &propagator ()._anotherSyncNeeded);
            done (status, _item._errorString);
            return;
        } else if (_item._httpErrorCode != 201) {
            // Normally we expect "201 Created"
            // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
            // throw an error.
            done (SyncFileItem.NormalError,
                tr ("Wrong HTTP code returned by server. Expected 201, but received \"%1 %2\".")
                    .arg (_item._httpErrorCode)
                    .arg (jobHttpReasonPhraseString));
            return;
        }
    
        propagator ()._activeJobList.append (this);
        auto propfindJob = new PropfindJob (propagator ().account (), jobPath, this);
        propfindJob.setProperties ({"http://owncloud.org/ns:permissions"});
        connect (propfindJob, &PropfindJob.result, this, [this, jobPath] (QVariantMap &result){
            propagator ()._activeJobList.removeOne (this);
            _item._remotePerm = RemotePermissions.fromServerString (result.value (QStringLiteral ("permissions")).toString ());
    
            if (!_uploadEncryptedHelper && !_item._isEncrypted) {
                success ();
            } else {
                // We still need to mark that folder encrypted in case we were uploading it as encrypted one
                // Another scenario, is we are creating a new folder because of move operation on an encrypted folder that works via remove + re-upload
                propagator ()._activeJobList.append (this);
    
                // We're expecting directory path in /Foo/Bar convention...
                Q_ASSERT (jobPath.startsWith ('/') && !jobPath.endsWith ('/'));
                // But encryption job expect it in Foo/Bar/ convention
                auto job = new Occ.EncryptFolderJob (propagator ().account (), propagator ()._journal, jobPath.mid (1), _item._fileId, this);
                connect (job, &Occ.EncryptFolderJob.finished, this, &PropagateRemoteMkdir.slotEncryptFolderFinished);
                job.start ();
            }
        });
        connect (propfindJob, &PropfindJob.finishedWithError, this, [this]{
            // ignore the PROPFIND error
            propagator ()._activeJobList.removeOne (this);
            done (SyncFileItem.NormalError);
        });
        propfindJob.start ();
    }
    
    void PropagateRemoteMkdir.slotMkdir () {
        const auto path = _item._file;
        const auto slashPosition = path.lastIndexOf ('/');
        const auto parentPath = slashPosition >= 0 ? path.left (slashPosition) : string ();
    
        SyncJournalFileRecord parentRec;
        bool ok = propagator ()._journal.getFileRecord (parentPath, &parentRec);
        if (!ok) {
            done (SyncFileItem.NormalError);
            return;
        }
    
        if (!hasEncryptedAncestor ()) {
            slotStartMkcolJob ();
            return;
        }
    
        // We should be encrypted as well since our parent is
        const auto remoteParentPath = parentRec._e2eMangledName.isEmpty () ? parentPath : parentRec._e2eMangledName;
        _uploadEncryptedHelper = new PropagateUploadEncrypted (propagator (), remoteParentPath, _item, this);
        connect (_uploadEncryptedHelper, &PropagateUploadEncrypted.finalized,
          this, &PropagateRemoteMkdir.slotStartEncryptedMkcolJob);
        connect (_uploadEncryptedHelper, &PropagateUploadEncrypted.error,
          []{ qCDebug (lcPropagateRemoteMkdir) << "Error setting up encryption."; });
        _uploadEncryptedHelper.start ();
    }
    
    void PropagateRemoteMkdir.slotMkcolJobFinished () {
        propagator ()._activeJobList.removeOne (this);
    
        ASSERT (_job);
    
        QNetworkReply.NetworkError err = _job.reply ().error ();
        _item._httpErrorCode = _job.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
        _item._responseTimeStamp = _job.responseTimestamp ();
        _item._requestId = _job.requestId ();
    
        _item._fileId = _job.reply ().rawHeader ("OC-FileId");
    
        _item._errorString = _job.errorString ();
    
        const auto jobHttpReasonPhraseString = _job.reply ().attribute (QNetworkRequest.HttpReasonPhraseAttribute).toString ();
    
        const auto jobPath = _job.path ();
    
        if (_uploadEncryptedHelper && _uploadEncryptedHelper.isFolderLocked () && !_uploadEncryptedHelper.isUnlockRunning ()) {
            // since we are done, we need to unlock a folder in case it was locked
            connect (_uploadEncryptedHelper, &PropagateUploadEncrypted.folderUnlocked, this, [this, err, jobHttpReasonPhraseString, jobPath] () {
                finalizeMkColJob (err, jobHttpReasonPhraseString, jobPath);
            });
            _uploadEncryptedHelper.unlockFolder ();
        } else {
            finalizeMkColJob (err, jobHttpReasonPhraseString, jobPath);
        }
    }
    
    void PropagateRemoteMkdir.slotEncryptFolderFinished () {
        qCDebug (lcPropagateRemoteMkdir) << "Success making the new folder encrypted";
        propagator ()._activeJobList.removeOne (this);
        _item._isEncrypted = true;
        success ();
    }
    
    void PropagateRemoteMkdir.success () {
        // Never save the etag on first mkdir.
        // Only fully propagated directories should have the etag set.
        auto itemCopy = *_item;
        itemCopy._etag.clear ();
    
        // save the file id already so we can detect rename or remove
        const auto result = propagator ().updateMetadata (itemCopy);
        if (!result) {
            done (SyncFileItem.FatalError, tr ("Error writing metadata to the database : %1").arg (result.error ()));
            return;
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            done (SyncFileItem.FatalError, tr ("The file %1 is currently in use").arg (_item._file));
            return;
        }
    
        done (SyncFileItem.Success);
    }
    }
    