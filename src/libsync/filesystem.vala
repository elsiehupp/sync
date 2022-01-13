/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <string>
// #include <ctime>
// #include <functional>

// #include <owncloudlib.h>
// Chain in the base include and extend the namespace


namespace Occ {


/***********************************************************
 \addtogroup libsync
 @{
***********************************************************/

/***********************************************************
@brief This file contains file system helper
***********************************************************/
namespace FileSystem {

    /***********************************************************
     * @brief compare two files with given filename and return true if they have the same content
     */
    bool fileEquals (string &fn1, string &fn2);

    /***********************************************************
     * @brief Get the mtime for a filepath
     *
     * Use this over QFileInfo.lastModified () to avoid timezone related bugs. See
     * owncloud/core#9781 for details.
     */
    time_t OWNCLOUDSYNC_EXPORT getModTime (string &filename);

    bool OWNCLOUDSYNC_EXPORT setModTime (string &filename, time_t modTime);

    /***********************************************************
     * @brief Get the size for a file
     *
     * Use this over QFileInfo.size () to avoid bugs with lnk files on Windows.
     * See https://bugreports.qt.io/browse/QTBUG-24831.
     */
    int64 OWNCLOUDSYNC_EXPORT getSize (string &filename);

    /***********************************************************
     * @brief Retrieve a file inode with csync
     */
    bool OWNCLOUDSYNC_EXPORT getInode (string &filename, uint64 *inode);

    /***********************************************************
     * @brief Check if \a fileName has changed given previous size and mtime
     *
     * Nonexisting files are covered through mtime : they have an mtime of -1.
     *
     * @return true if the file's mtime or size are not what is expected.
     */
    bool OWNCLOUDSYNC_EXPORT fileChanged (string &fileName,
        int64 previousSize,
        time_t previousMtime);

    /***********************************************************
     * @brief Like !fileChanged () but with verbose logging if the file *did* change.
     */
    bool OWNCLOUDSYNC_EXPORT verifyFileUnchanged (string &fileName,
        int64 previousSize,
        time_t previousMtime);

    /***********************************************************
     * Removes a directory and its contents recursively
     *
     * Returns true if all removes succeeded.
     * onDeleted () is called for each deleted file or directory, including the root.
     * errors are collected in errors.
     */
    bool OWNCLOUDSYNC_EXPORT removeRecursively (string &path,
        const std.function<void (string &path, bool isDir)> &onDeleted = nullptr,
        QStringList *errors = nullptr);
}

/** @} */
}
