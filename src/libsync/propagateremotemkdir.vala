/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/
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
     * Whether an existing entity with the same name may be deleted before
     * creating the directory.
     *
     * Default : false.
     */
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
}
