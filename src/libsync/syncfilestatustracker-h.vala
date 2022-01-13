/*
 * Copyright (C) by Klaas Freitag <freitag@owncloud.com>
 * Copyright (C) by Jocelyn Turcotte <jturcotte@woboq.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 */

// // #include <map>
// #include <QSet>

namespace OCC {

class SyncEngine;

/**
 * @brief Takes care of tracking the status of individual files as they
 *        go through the SyncEngine, to be reported as overlay icons in the shell.
 * @ingroup libsync
 */
class OWNCLOUDSYNC_EXPORT SyncFileStatusTracker : public QObject {
public:
    explicit SyncFileStatusTracker(SyncEngine *syncEngine);
    SyncFileStatus fileStatus(QString &relativePath);

public slots:
    void slotPathTouched(QString &fileName);
    // path relative to folder
    void slotAddSilentlyExcluded(QString &folderPath);

signals:
    void fileStatusChanged(QString &systemFileName, SyncFileStatus fileStatus);

private slots:
    void slotAboutToPropagate(SyncFileItemVector &items);
    void slotItemCompleted(SyncFileItemPtr &item);
    void slotSyncFinished();
    void slotSyncEngineRunningChanged();

private:
    struct PathComparator {
        bool operator()( const QString& lhs, QString& rhs ) const;
    };
    using ProblemsMap = std::map<QString, SyncFileStatus::SyncFileStatusTag, PathComparator>;
    SyncFileStatus::SyncFileStatusTag lookupProblem(QString &pathToMatch, ProblemsMap &problemMap);

    enum SharedFlag { UnknownShared,
        NotShared,
        Shared };
    enum PathKnownFlag { PathUnknown = 0,
        PathKnown };
    SyncFileStatus resolveSyncAndErrorStatus(QString &relativePath, SharedFlag sharedState, PathKnownFlag isPathKnown = PathKnown);

    void invalidateParentPaths(QString &path);
    QString getSystemDestination(QString &relativePath);
    void incSyncCountAndEmitStatusChanged(QString &relativePath, SharedFlag sharedState);
    void decSyncCountAndEmitStatusChanged(QString &relativePath, SharedFlag sharedState);

    SyncEngine *_syncEngine;

    ProblemsMap _syncProblems;
    QSet<QString> _dirtyPaths;
    // Counts the number direct children currently being synced (has unfinished propagation jobs).
    // We'll show a file/directory as SYNC as long as its sync count is > 0.
    // A directory that starts/ends propagation will in turn increase/decrease its own parent by 1.
    QHash<QString, int> _syncCount;
};
}

#endif
