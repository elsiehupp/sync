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
@brief The MoveJob class
@ingroup libsync
*/
class OWNCLOUDSYNC_EXPORT MoveJob : AbstractNetworkJob {
    const QString _destination;
    const QUrl _url; // Only used (instead of path) when the constructor taking an URL is used
    QMap<QByteArray, QByteArray> _extraHeaders;

public:
    MoveJob (AccountPtr account, QString &path, QString &destination, GLib.Object *parent = nullptr);
    MoveJob (AccountPtr account, QUrl &url, QString &destination,
        QMap<QByteArray, QByteArray> _extraHeaders, GLib.Object *parent = nullptr);

    void start () override;
    bool finished () override;

signals:
    void finishedSignal ();
};

/**
@brief The PropagateRemoteMove class
@ingroup libsync
*/
class PropagateRemoteMove : PropagateItemJob {
    QPointer<MoveJob> _job;

public:
    PropagateRemoteMove (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item) {
    }
    void start () override;
    void abort (PropagatorJob.AbortType abortType) override;
    JobParallelism parallelism () override { return _item.isDirectory () ? WaitForFinished : FullParallelism; }

    /**
     * Rename the directory in the selective sync list
     */
    static bool adjustSelectiveSync (SyncJournalDb *journal, QString &from, QString &to);

private slots:
    void slotMoveJobFinished ();
    void finalize ();
};
}
