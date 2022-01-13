/*
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QThread>
// #include <QAtomicInt>
// #include <windows.h>

namespace Occ {


/**
@brief The WatcherThread class
@ingroup gui
*/
class WatcherThread : QThread {
public:
    WatcherThread (QString &path)
        : QThread ()
        , _path (path + (path.endsWith (QLatin1Char ('/')) ? QString () : QStringLiteral ("/")))
        , _directory (0)
        , _resultEvent (0)
        , _stopEvent (0)
        , _done (false) {
    }

    ~WatcherThread ();

    void stop ();

protected:
    void run ();
    void watchChanges (size_t fileNotifyBufferSize,
        bool *increaseBufferSize);
    void closeHandle ();

signals:
    void changed (QString &path);
    void lostChanges ();
    void ready ();

private:
    QString _path;
    HANDLE _directory;
    HANDLE _resultEvent;
    HANDLE _stopEvent;
    QAtomicInt _done;
};

/**
@brief Windows implementation of FolderWatcher
@ingroup gui
*/
class FolderWatcherPrivate : GLib.Object {
public:
    FolderWatcherPrivate (FolderWatcher *p, QString &path);
    ~FolderWatcherPrivate ();

    /// Set to non-zero once the WatcherThread is capturing events.
    QAtomicInt _ready;

private:
    FolderWatcher *_parent;
    WatcherThread *_thread;
};
}
