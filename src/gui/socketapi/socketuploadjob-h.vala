/*
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

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
// #include <GLib.Object>
// #include <QTemporaryFile>

namespace Occ {

class SyncEngine;

class SocketUploadJob : GLib.Object {
public:
    SocketUploadJob (QSharedPointer<SocketApiJobV2> &job);
    void start ();

private:
    QSharedPointer<SocketApiJobV2> _apiJob;
    QString _localPath;
    QString _remotePath;
    QString _pattern;
    QTemporaryFile _tmp;
    SyncJournalDb *_db;
    SyncEngine *_engine;
    QStringList _syncedFiles;
};
}
