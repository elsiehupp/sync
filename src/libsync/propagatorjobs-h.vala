/*
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
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

// #pragma once

// #include <QFile>

namespace Occ {

/**
Tags for checksum header.
It's here for being shared between Upload- and Download Job
*/
static const char checkSumHeaderC[] = "OC-Checksum";
static const char contentMd5HeaderC[] = "Content-MD5";

/**
@brief Declaration of the other propagation jobs
@ingroup libsync
*/
class PropagateLocalRemove : PropagateItemJob {
public:
    PropagateLocalRemove (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item) {
    }
    void start () override;

private:
    bool removeRecursively (QString &path);
    QString _error;
    bool _moveToTrash;
};

/**
@brief The PropagateLocalMkdir class
@ingroup libsync
*/
class PropagateLocalMkdir : PropagateItemJob {
public:
    PropagateLocalMkdir (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item)
        , _deleteExistingFile (false) {
    }
    void start () override;

    /**
     * Whether an existing file with the same name may be deleted before
     * creating the directory.
     *
     * Default : false.
     */
    void setDeleteExistingFile (bool enabled);

private:
    void startLocalMkdir ();
    void startDemanglingName (QString &parentPath);

    bool _deleteExistingFile;
};

/**
@brief The PropagateLocalRename class
@ingroup libsync
*/
class PropagateLocalRename : PropagateItemJob {
public:
    PropagateLocalRename (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item) {
    }
    void start () override;
    JobParallelism parallelism () override { return _item.isDirectory () ? WaitForFinished : FullParallelism; }
};
}
