/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QList>
// #include <QLoggingCategory>
// #include <GLib.Object>
// #include <string>
// #include <QStringList>
// #include <QElapsedTimer>
// #include <QHash>
// #include <QScopedPointer>
// #include <QSet>
// #include <QDir>


namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lcFolderWatcher)


/***********************************************************
@brief Monitors a directory recursively for changes

Folder Watcher monitors a directory and its sub directories
for changes in the local file system.
through the pathChanged () signal.

@ingroup gui
***********************************************************/

class FolderWatcher : GLib.Object {
public:
    // Construct, connect signals, call init ()
    FolderWatcher (Folder *folder = nullptr);
    ~FolderWatcher () override;

    /***********************************************************
     * @param root Path of the root of the folder
     */
    void init (string &root);

    /* Check if the path is ignored. */
    bool pathIsIgnored (string &path);

    /***********************************************************
     * Returns false if the folder watcher can't be trusted to capture all
     * notifications.
     *
     * For example, this can happen on linux if the inotify user limit from
     * /proc/sys/fs/inotify/max_user_watches is exceeded.
     */
    bool isReliable ();

    /***********************************************************
     * Triggers a change in the path and verifies a notification arrives.
     *
     * If no notification is seen, the folderwatcher marks itself as unreliable.
     * The path must be ignored by the watcher.
     */
    void startNotificatonTest (string &path);

    /// For testing linux behavior only
    int testLinuxWatchCount ();

signals:
    /** Emitted when one of the watched directories or one
     *  of the contained files is changed. */
    void pathChanged (string &path);

    /***********************************************************
     * Emitted if some notifications were lost.
     *
     * Would happen, for example, if the number of pending notifications
     * exceeded the allocated buffer size on Windows. Note that the folder
     * watcher could still be able to capture all future notifications -
     * i.e. isReliable () is orthogonal to losing changes occasionally.
     */
    void lostChanges ();

    /***********************************************************
     * Signals when the watcher became unreliable. The string is a translated
     * message that can be shown to users.
     */
    void becameUnreliable (string &message);

protected slots:
    // called from the implementations to indicate a change in path
    void changeDetected (string &path);
    void changeDetected (QStringList &paths);

private slots:
    void startNotificationTestWhenReady ();

protected:
    QHash<string, int> _pendingPathes;

private:
    QScopedPointer<FolderWatcherPrivate> _d;
    QElapsedTimer _timer;
    QSet<string> _lastPaths;
    Folder *_folder;
    bool _isReliable = true;

    void appendSubPaths (QDir dir, QStringList& subPaths);

    /** Path of the expected test notification */
    string _testNotificationPath;

    friend class FolderWatcherPrivate;
};
}

#endif







/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// event masks

// #include <cstdint>

// #include <QFileInfo>
// #include <QFlags>
// #include <QDir>
// #include <QMutexLocker>
// #include <QStringList>
// #include <QTimer>

namespace Occ {

    Q_LOGGING_CATEGORY (lcFolderWatcher, "nextcloud.gui.folderwatcher", QtInfoMsg)
    
    FolderWatcher.FolderWatcher (Folder *folder)
        : GLib.Object (folder)
        , _folder (folder) {
    }
    
    FolderWatcher.~FolderWatcher () = default;
    
    void FolderWatcher.init (string &root) {
        _d.reset (new FolderWatcherPrivate (this, root));
        _timer.start ();
    }
    
    bool FolderWatcher.pathIsIgnored (string &path) {
        if (path.isEmpty ())
            return true;
        if (!_folder)
            return false;
    
    #ifndef OWNCLOUD_TEST
        if (_folder.isFileExcludedAbsolute (path) && !Utility.isConflictFile (path)) {
            qCDebug (lcFolderWatcher) << "* Ignoring file" << path;
            return true;
        }
    #endif
        return false;
    }
    
    bool FolderWatcher.isReliable () {
        return _isReliable;
    }
    
    void FolderWatcher.appendSubPaths (QDir dir, QStringList& subPaths) {
        QStringList newSubPaths = dir.entryList (QDir.NoDotAndDotDot | QDir.Dirs | QDir.Files);
        for (int i = 0; i < newSubPaths.size (); i++) {
            string path = dir.path () + "/" + newSubPaths[i];
            QFileInfo fileInfo (path);
            subPaths.append (path);
            if (fileInfo.isDir ()) {
                QDir dir (path);
                appendSubPaths (dir, subPaths);
            }
        }
    }
    
    void FolderWatcher.startNotificatonTest (string &path) {
        Q_ASSERT (_testNotificationPath.isEmpty ());
        _testNotificationPath = path;
    
        // Don't do the local file modification immediately:
        // wait for FolderWatchPrivate._ready
        startNotificationTestWhenReady ();
    }
    
    void FolderWatcher.startNotificationTestWhenReady () {
        if (!_d._ready) {
            QTimer.singleShot (1000, this, &FolderWatcher.startNotificationTestWhenReady);
            return;
        }
    
        auto path = _testNotificationPath;
        if (QFile.exists (path)) {
            auto mtime = FileSystem.getModTime (path);
            FileSystem.setModTime (path, mtime + 1);
        } else {
            QFile f (path);
            f.open (QIODevice.WriteOnly | QIODevice.Append);
        }
    
        QTimer.singleShot (5000, this, [this] () {
            if (!_testNotificationPath.isEmpty ())
                emit becameUnreliable (tr ("The watcher did not receive a test notification."));
            _testNotificationPath.clear ();
        });
    }
    
    int FolderWatcher.testLinuxWatchCount () {
    #ifdef Q_OS_LINUX
        return _d.testWatchCount ();
    #else
        return -1;
    #endif
    }
    
    void FolderWatcher.changeDetected (string &path) {
        QFileInfo fileInfo (path);
        QStringList paths (path);
        if (fileInfo.isDir ()) {
            QDir dir (path);
            appendSubPaths (dir, paths);
        }
        changeDetected (paths);
    }
    
    void FolderWatcher.changeDetected (QStringList &paths) {
        // TODO : this shortcut doesn't look very reliable:
        //   - why is the timeout only 1 second?
        //   - what if there is more than one file being updated frequently?
        //   - why do we skip the file altogether instead of e.g. reducing the upload frequency?
    
        // Check if the same path was reported within the last second.
        QSet<string> pathsSet = paths.toSet ();
        if (pathsSet == _lastPaths && _timer.elapsed () < 1000) {
            // the same path was reported within the last second. Skip.
            return;
        }
        _lastPaths = pathsSet;
        _timer.restart ();
    
        QSet<string> changedPaths;
    
        // ------- handle ignores:
        for (int i = 0; i < paths.size (); ++i) {
            string path = paths[i];
            if (!_testNotificationPath.isEmpty ()
                && Utility.fileNamesEqual (path, _testNotificationPath)) {
                _testNotificationPath.clear ();
            }
            if (pathIsIgnored (path)) {
                continue;
            }
    
            changedPaths.insert (path);
        }
        if (changedPaths.isEmpty ()) {
            return;
        }
    
        qCInfo (lcFolderWatcher) << "Detected changes in paths:" << changedPaths;
        foreach (string &path, changedPaths) {
            emit pathChanged (path);
        }
    }
    
    } // namespace Occ
    