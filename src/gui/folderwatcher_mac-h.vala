/*
Copyright (C) by Markus Goetz <markus@woboq.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <GLib.Object>
// #include <QString>

// #include <CoreServices/CoreServices.h>

namespace Occ {

/**
@brief Mac OS X API implementation of FolderWatcher
@ingroup gui
*/
class FolderWatcherPrivate {
public:
    FolderWatcherPrivate (FolderWatcher *p, QString &path);
    ~FolderWatcherPrivate ();

    void startWatching ();
    QStringList addCoalescedPaths (QStringList &) const;
    void doNotifyParent (QStringList &);

    /// On OSX the watcher is ready when the ctor finished.
    bool _ready = true;

private:
    FolderWatcher *_parent;

    QString _folder;

    FSEventStreamRef _stream;
};
}

#endif
