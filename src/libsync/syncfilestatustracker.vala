/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Jocelyn Turcotte <jturcotte@woboq.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// // #include <map>
// #include <QSet>

namespace Occ {


/***********************************************************
@brief Takes care of tracking the status of individual files as they
       go through the SyncEngine, to be reported as overlay icons in the shell.
@ingroup libsync
***********************************************************/
class SyncFileStatusTracker : GLib.Object {
public:
    SyncFileStatusTracker (SyncEngine *syncEngine);
    SyncFileStatus fileStatus (string &relativePath);

public slots:
    void slotPathTouched (string &fileName);
    // path relative to folder
    void slotAddSilentlyExcluded (string &folderPath);

signals:
    void fileStatusChanged (string &systemFileName, SyncFileStatus fileStatus);

private slots:
    void slotAboutToPropagate (SyncFileItemVector &items);
    void slotItemCompleted (SyncFileItemPtr &item);
    void slotSyncFinished ();
    void slotSyncEngineRunningChanged ();

private:
    struct PathComparator {
        bool operator () ( const string& lhs, string& rhs ) const;
    };
    using ProblemsMap = std.map<string, SyncFileStatus.SyncFileStatusTag, PathComparator>;
    SyncFileStatus.SyncFileStatusTag lookupProblem (string &pathToMatch, ProblemsMap &problemMap);

    enum SharedFlag { UnknownShared,
        NotShared,
        Shared };
    enum PathKnownFlag { PathUnknown = 0,
        PathKnown };
    SyncFileStatus resolveSyncAndErrorStatus (string &relativePath, SharedFlag sharedState, PathKnownFlag isPathKnown = PathKnown);

    void invalidateParentPaths (string &path);
    string getSystemDestination (string &relativePath);
    void incSyncCountAndEmitStatusChanged (string &relativePath, SharedFlag sharedState);
    void decSyncCountAndEmitStatusChanged (string &relativePath, SharedFlag sharedState);

    SyncEngine *_syncEngine;

    ProblemsMap _syncProblems;
    QSet<string> _dirtyPaths;
    // Counts the number direct children currently being synced (has unfinished propagation jobs).
    // We'll show a file/directory as SYNC as long as its sync count is > 0.
    // A directory that starts/ends propagation will in turn increase/decrease its own parent by 1.
    QHash<string, int> _syncCount;
};
}

#endif
