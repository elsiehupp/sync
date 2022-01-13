/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/
// #pragma once

namespace Occ {



/***********************************************************
@brief The PropagateRemoteDelete class
@ingroup libsync
***********************************************************/
class PropagateRemoteDelete : PropagateItemJob {
    QPointer<DeleteJob> _job;
    AbstractPropagateRemoteDeleteEncrypted *_deleteEncryptedHelper = nullptr;

public:
    PropagateRemoteDelete (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item) {
    }
    void start () override;
    void createDeleteJob (string &filename);
    void abort (PropagatorJob.AbortType abortType) override;

    bool isLikelyFinishedQuickly () override { return !_item.isDirectory (); }

private slots:
    void slotDeleteJobFinished ();
};
}
