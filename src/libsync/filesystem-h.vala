/*
 * Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
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

// #pragma once

// #include <QString>
// #include <ctime>
// #include <functional>

// #include <owncloudlib.h>
// Chain in the base include and extend the namespace

class QFile;

namespace OCC {

class SyncJournal;

/**
 *  \addtogroup libsync
 *  @{
 */

/**
 * @brief This file contains file system helper
 */
namespace FileSystem {

    /**
     * @brief compare two files with given filename and return true if they have the same content
     */
    bool fileEquals (QString &fn1, QString &fn2);

    /**
     * @brief Get the mtime for a filepath
     *
     * Use this over QFileInfo.lastModified () to avoid timezone related bugs. See
     * owncloud/core#9781 for details.
     */
    time_t OWNCLOUDSYNC_EXPORT getModTime (QString &filename);

    bool OWNCLOUDSYNC_EXPORT setModTime (QString &filename, time_t modTime);

    /**
     * @brief Get the size for a file
     *
     * Use this over QFileInfo.size () to avoid bugs with lnk files on Windows.
     * See https://bugreports.qt.io/browse/QTBUG-24831.
     */
    int64 OWNCLOUDSYNC_EXPORT getSize (QString &filename);

    /**
     * @brief Retrieve a file inode with csync
     */
    bool OWNCLOUDSYNC_EXPORT getInode (QString &filename, uint64 *inode);

    /**
     * @brief Check if \a fileName has changed given previous size and mtime
     *
     * Nonexisting files are covered through mtime: they have an mtime of -1.
     *
     * @return true if the file's mtime or size are not what is expected.
     */
    bool OWNCLOUDSYNC_EXPORT fileChanged (QString &fileName,
        int64 previousSize,
        time_t previousMtime);

    /**
     * @brief Like !fileChanged () but with verbose logging if the file *did* change.
     */
    bool OWNCLOUDSYNC_EXPORT verifyFileUnchanged (QString &fileName,
        int64 previousSize,
        time_t previousMtime);

    /**
     * Removes a directory and its contents recursively
     *
     * Returns true if all removes succeeded.
     * onDeleted () is called for each deleted file or directory, including the root.
     * errors are collected in errors.
     */
    bool OWNCLOUDSYNC_EXPORT removeRecursively (QString &path,
        const std.function<void (QString &path, bool isDir)> &onDeleted = nullptr,
        QStringList *errors = nullptr);
}

/** @} */
}
