/*
 * Copyright (C) by Klaas Freitag <freitag@owncloud.com>
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

// #include <QObject>
// #include <QString>
// #include <QSocketNotifier>
// #include <QHash>
// #include <QDir>

class QTimer;

namespace OCC {

/**
 * @brief Linux (inotify) API implementation of FolderWatcher
 * @ingroup gui
 */
class FolderWatcherPrivate : public QObject {
public:
    FolderWatcherPrivate () = default;
    FolderWatcherPrivate (FolderWatcher *p, QString &path);
    ~FolderWatcherPrivate () override;

    int testWatchCount () { return _pathToWatch.size (); }

    /// On linux the watcher is ready when the ctor finished.
    bool _ready = true;

protected slots:
    void slotReceivedNotification (int fd);
    void slotAddFolderRecursive (QString &path);

protected:
    bool findFoldersBelow (QDir &dir, QStringList &fullList);
    void inotifyRegisterPath (QString &path);
    void removeFoldersBelow (QString &path);

private:
    FolderWatcher *_parent;

    QString _folder;
    QHash<int, QString> _watchToPath;
    QMap<QString, int> _pathToWatch;
    QScopedPointer<QSocketNotifier> _socket;
    int _fd;
};
}

#endif
