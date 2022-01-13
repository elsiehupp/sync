/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/
// #pragma once

namespace Occ {

/***********************************************************
@brief The MoveJob class
@ingroup libsync
***********************************************************/
class MoveJob : AbstractNetworkJob {
    const string _destination;
    const QUrl _url; // Only used (instead of path) when the constructor taking an URL is used
    QMap<QByteArray, QByteArray> _extraHeaders;

public:
    MoveJob (AccountPtr account, string &path, string &destination, GLib.Object *parent = nullptr);
    MoveJob (AccountPtr account, QUrl &url, string &destination,
        QMap<QByteArray, QByteArray> _extraHeaders, GLib.Object *parent = nullptr);

    void start () override;
    bool finished () override;

signals:
    void finishedSignal ();
};

/***********************************************************
@brief The PropagateRemoteMove class
@ingroup libsync
***********************************************************/
class PropagateRemoteMove : PropagateItemJob {
    QPointer<MoveJob> _job;

public:
    PropagateRemoteMove (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item) {
    }
    void start () override;
    void abort (PropagatorJob.AbortType abortType) override;
    JobParallelism parallelism () override { return _item.isDirectory () ? WaitForFinished : FullParallelism; }

    /***********************************************************
     * Rename the directory in the selective sync list
     */
    static bool adjustSelectiveSync (SyncJournalDb *journal, string &from, string &to);

private slots:
    void slotMoveJobFinished ();
    void finalize ();
};
}
