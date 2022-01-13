/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFile>
// #include <QFileInfo>
// #include <QDir>
// #include <QDirIterator>
// #include <QCoreApplication>

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
    @brief compare two files with given filename and return true if they have the same content
    ***********************************************************/
    bool fileEquals (string &fn1, string &fn2);

    /***********************************************************
    @brief Get the mtime for a filepath
    
    Use this over QFileInfo.lastModified () to avoid timezone related bugs. See
    owncloud/core#9781 for details.
    ***********************************************************/
    time_t getModTime (string &filename);

    bool setModTime (string &filename, time_t modTime);

    /***********************************************************
    @brief Get the size for a file
    
    Use this over QFileInfo.size () to avoid bugs with lnk files on Windows.
    See https://bugreports.qt.io/browse/QTBUG-24831.
    ***********************************************************/
    int64 getSize (string &filename);

    /***********************************************************
    @brief Retrieve a file inode with csync
    ***********************************************************/
    bool getInode (string &filename, uint64 *inode);

    /***********************************************************
    @brief Check if \a fileName has changed given previous size and mtime
    
    Nonexisting files are covered through mtime : they have an mtime of -1.

    @return true if the file's mtime or size are not what is expected.
    ***********************************************************/
    bool fileChanged (string &fileName,
        int64 previousSize,
        time_t previousMtime);

    /***********************************************************
    @brief Like !fileChanged () but with verbose logging if the file *did* change.
    ***********************************************************/
    bool verifyFileUnchanged (string &fileName,
        int64 previousSize,
        time_t previousMtime);

    /***********************************************************
    Removes a directory and its contents recursively
    
    Returns true if all removes succeeded.
    onDeleted () is called for each deleted file or directory, including the root.
    errors are collected in errors.
    ***********************************************************/
    bool removeRecursively (string &path,
        const std.function<void (string &path, bool isDir)> &onDeleted = nullptr,
        QStringList *errors = nullptr);
}



    bool FileSystem.fileEquals (string &fn1, string &fn2) {
        // compare two files with given filename and return true if they have the same content
        QFile f1 (fn1);
        QFile f2 (fn2);
        if (!f1.open (QIODevice.ReadOnly) || !f2.open (QIODevice.ReadOnly)) {
            qCWarning (lcFileSystem) << "fileEquals : Failed to open " << fn1 << "or" << fn2;
            return false;
        }
    
        if (getSize (fn1) != getSize (fn2)) {
            return false;
        }
    
        const int BufferSize = 16 * 1024;
        QByteArray buffer1 (BufferSize, 0);
        QByteArray buffer2 (BufferSize, 0);
        // the files have the same size, compare all of it
        while (!f1.atEnd ()){
            f1.read (buffer1.data (), BufferSize);
            f2.read (buffer2.data (), BufferSize);
            if (buffer1 != buffer2) {
                return false;
            }
        };
        return true;
    }
    
    time_t FileSystem.getModTime (string &filename) {
        csync_file_stat_t stat;
        int64 result = -1;
        if (csync_vio_local_stat (filename, &stat) != -1
            && (stat.modtime != 0)) {
            result = stat.modtime;
        } else {
            result = Utility.qDateTimeToTime_t (QFileInfo (filename).lastModified ());
            qCWarning (lcFileSystem) << "Could not get modification time for" << filename
                                    << "with csync, using QFileInfo:" << result;
        }
        return result;
    }
    
    bool FileSystem.setModTime (string &filename, time_t modTime) {
        struct timeval times[2];
        times[0].tv_sec = times[1].tv_sec = modTime;
        times[0].tv_usec = times[1].tv_usec = 0;
        int rc = c_utimes (filename, times);
        if (rc != 0) {
            qCWarning (lcFileSystem) << "Error setting mtime for" << filename
                                    << "failed : rc" << rc << ", errno:" << errno;
            return false;
        }
        return true;
    }
    
    bool FileSystem.fileChanged (string &fileName,
        int64 previousSize,
        time_t previousMtime) {
        return getSize (fileName) != previousSize
            || getModTime (fileName) != previousMtime;
    }
    
    bool FileSystem.verifyFileUnchanged (string &fileName,
        int64 previousSize,
        time_t previousMtime) {
        const int64 actualSize = getSize (fileName);
        const time_t actualMtime = getModTime (fileName);
        if ( (actualSize != previousSize && actualMtime > 0) || (actualMtime != previousMtime && previousMtime > 0 && actualMtime > 0)) {
            qCInfo (lcFileSystem) << "File" << fileName << "has changed:"
                                 << "size : " << previousSize << "<." << actualSize
                                 << ", mtime : " << previousMtime << "<." << actualMtime;
            return false;
        }
        return true;
    }
    
    int64 FileSystem.getSize (string &filename) {
        return QFileInfo (filename).size ();
    }
    
    // Code inspired from Qt5's QDir.removeRecursively
    bool FileSystem.removeRecursively (string &path, std.function<void (string &path, bool isDir)> &onDeleted, QStringList *errors) {
        bool allRemoved = true;
        QDirIterator di (path, QDir.AllEntries | QDir.Hidden | QDir.System | QDir.NoDotAndDotDot);
    
        while (di.hasNext ()) {
            di.next ();
            const QFileInfo &fi = di.fileInfo ();
            bool removeOk = false;
            // The use of isSymLink here is okay:
            // we never want to go into this branch for .lnk files
            bool isDir = fi.isDir () && !fi.isSymLink () && !FileSystem.isJunction (fi.absoluteFilePath ());
            if (isDir) {
                removeOk = removeRecursively (path + QLatin1Char ('/') + di.fileName (), onDeleted, errors); // recursive
            } else {
                string removeError;
                removeOk = FileSystem.remove (di.filePath (), &removeError);
                if (removeOk) {
                    if (onDeleted)
                        onDeleted (di.filePath (), false);
                } else {
                    if (errors) {
                        errors.append (QCoreApplication.translate ("FileSystem", "Error removing \"%1\" : %2")
                                           .arg (QDir.toNativeSeparators (di.filePath ()), removeError));
                    }
                    qCWarning (lcFileSystem) << "Error removing " << di.filePath () << ':' << removeError;
                }
            }
            if (!removeOk)
                allRemoved = false;
        }
        if (allRemoved) {
            allRemoved = QDir ().rmdir (path);
            if (allRemoved) {
                if (onDeleted)
                    onDeleted (path, true);
            } else {
                if (errors) {
                    errors.append (QCoreApplication.translate ("FileSystem", "Could not remove folder \"%1\"")
                                       .arg (QDir.toNativeSeparators (path)));
                }
                qCWarning (lcFileSystem) << "Error removing folder" << path;
            }
        }
        return allRemoved;
    }
    
    bool FileSystem.getInode (string &filename, uint64 *inode) {
        csync_file_stat_t fs;
        if (csync_vio_local_stat (filename, &fs) == 0) {
            *inode = fs.inode;
            return true;
        }
        return false;
    }
    
    } // namespace Occ
    