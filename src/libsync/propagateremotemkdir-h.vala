/*
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

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

namespace Occ {


/**
@brief The PropagateRemoteMkdir class
@ingroup libsync
*/
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

    /**
     * Whether an existing entity with the same name may be deleted before
     * creating the directory.
     *
     * Default : false.
     */
    void setDeleteExisting (bool enabled);

private slots:
    void slotMkdir ();
    void slotStartMkcolJob ();
    void slotStartEncryptedMkcolJob (QString &path, QString &filename, uint64 size);
    void slotMkcolJobFinished ();
    void slotEncryptFolderFinished ();
    void success ();

private:
    void finalizeMkColJob (QNetworkReply.NetworkError err, QString &jobHttpReasonPhraseString, QString &jobPath);
};
}
