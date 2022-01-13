/*
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QList>
// #include <QLoggingCategory>
// #include <GLib.Object>
// #include <QString>
// #include <QStringList>
// #include <QElapsedTimer>
// #include <QHash>
// #include <QScopedPointer>
// #include <QSet>
// #include <QDir>


namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lcFolderWatcher)

class Folder;

/**
@brief Monitors a directory recursively for changes

Folder Watcher monitors a directory and its sub directories
for changes in the local file system.
through the pathChanged () signal.

@ingroup gui
*/

class FolderWatcher : GLib.Object {
public:
    // Construct, connect signals, call init ()
    FolderWatcher (Folder *folder = nullptr);
    ~FolderWatcher () override;

    /**
     * @param root Path of the root of the folder
     */
    void init (QString &root);

    /* Check if the path is ignored. */
    bool pathIsIgnored (QString &path);

    /**
     * Returns false if the folder watcher can't be trusted to capture all
     * notifications.
     *
     * For example, this can happen on linux if the inotify user limit from
     * /proc/sys/fs/inotify/max_user_watches is exceeded.
     */
    bool isReliable ();

    /**
     * Triggers a change in the path and verifies a notification arrives.
     *
     * If no notification is seen, the folderwatcher marks itself as unreliable.
     * The path must be ignored by the watcher.
     */
    void startNotificatonTest (QString &path);

    /// For testing linux behavior only
    int testLinuxWatchCount ();

signals:
    /** Emitted when one of the watched directories or one
     *  of the contained files is changed. */
    void pathChanged (QString &path);

    /**
     * Emitted if some notifications were lost.
     *
     * Would happen, for example, if the number of pending notifications
     * exceeded the allocated buffer size on Windows. Note that the folder
     * watcher could still be able to capture all future notifications -
     * i.e. isReliable () is orthogonal to losing changes occasionally.
     */
    void lostChanges ();

    /**
     * Signals when the watcher became unreliable. The string is a translated
     * message that can be shown to users.
     */
    void becameUnreliable (QString &message);

protected slots:
    // called from the implementations to indicate a change in path
    void changeDetected (QString &path);
    void changeDetected (QStringList &paths);

private slots:
    void startNotificationTestWhenReady ();

protected:
    QHash<QString, int> _pendingPathes;

private:
    QScopedPointer<FolderWatcherPrivate> _d;
    QElapsedTimer _timer;
    QSet<QString> _lastPaths;
    Folder *_folder;
    bool _isReliable = true;

    void appendSubPaths (QDir dir, QStringList& subPaths);

    /** Path of the expected test notification */
    QString _testNotificationPath;

    friend class FolderWatcherPrivate;
};
}

#endif
