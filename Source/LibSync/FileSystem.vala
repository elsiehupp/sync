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
    bool file_equals (string fn1, string fn2);


    /***********************************************************
    @brief Get the mtime for a filepath

    Use this over QFileInfo.last_modified () to avoid timezone related bugs. See
    owncloud/core#9781 for details.
    ***********************************************************/
    time_t get_mod_time (string filename);

    bool set_mod_time (string filename, time_t mod_time);


    /***********************************************************
    @brief Get the size for a file

    Use this over QFileInfo.size () to avoid bugs with lnk files on Windows.
    See https://bugreports.qt.io/browse/QTBUG-24831.
    ***********************************************************/
    int64 get_size (string filename);


    /***********************************************************
    @brief Retrieve a file inode with csync
    ***********************************************************/
    bool get_inode (string filename, uint64 inode);


    /***********************************************************
    @brief Check if \a file_name has changed given previous size and mtime

    Nonexisting files are covered through mtime : they have an mtime of -1.

    @return true if the file's mtime or size are not what is expected.
    ***********************************************************/
    bool file_changed (string file_name,
        int64 previous_size,
        time_t previous_mtime);


    /***********************************************************
    @brief Like !file_changed () but with verbose logging if the file did* change.
    ***********************************************************/
    bool verify_file_unchanged (string file_name,
        int64 previous_size,
        time_t previous_mtime);


    /***********************************************************
    Removes a directory and its contents recursively

    Returns true if all removes succeeded.
    on_deleted () is called for each deleted file or directory, including the root.
    errors are collected in errors.
    ***********************************************************/
    bool remove_recursively (string path,
        const std.function<void (string path, bool is_dir)> &on_deleted = nullptr,
        string[] *errors = nullptr);
}



    bool FileSystem.file_equals (string fn1, string fn2) {
        // compare two files with given filename and return true if they have the same content
        QFile f1 (fn1);
        QFile f2 (fn2);
        if (!f1.open (QIODevice.ReadOnly) || !f2.open (QIODevice.ReadOnly)) {
            q_c_warning (lc_file_system) << "file_equals : Failed to open " << fn1 << "or" << fn2;
            return false;
        }

        if (get_size (fn1) != get_size (fn2)) {
            return false;
        }

        const int BufferSize = 16 * 1024;
        GLib.ByteArray buffer1 (BufferSize, 0);
        GLib.ByteArray buffer2 (BufferSize, 0);
        // the files have the same size, compare all of it
        while (!f1.at_end ()){
            f1.read (buffer1.data (), BufferSize);
            f2.read (buffer2.data (), BufferSize);
            if (buffer1 != buffer2) {
                return false;
            }
        };
        return true;
    }

    time_t FileSystem.get_mod_time (string filename) {
        csync_file_stat_t stat;
        int64 result = -1;
        if (csync_vio_local_stat (filename, &stat) != -1
            && (stat.modtime != 0)) {
            result = stat.modtime;
        } else {
            result = Utility.q_date_time_to_time_t (QFileInfo (filename).last_modified ());
            q_c_warning (lc_file_system) << "Could not get modification time for" << filename
                                    << "with csync, using QFileInfo:" << result;
        }
        return result;
    }

    bool FileSystem.set_mod_time (string filename, time_t mod_time) {
        struct timeval times[2];
        times[0].tv_sec = times[1].tv_sec = mod_time;
        times[0].tv_usec = times[1].tv_usec = 0;
        int rc = c_utimes (filename, times);
        if (rc != 0) {
            q_c_warning (lc_file_system) << "Error setting mtime for" << filename
                                    << "failed : rc" << rc << ", errno:" << errno;
            return false;
        }
        return true;
    }

    bool FileSystem.file_changed (string file_name,
        int64 previous_size,
        time_t previous_mtime) {
        return get_size (file_name) != previous_size
            || get_mod_time (file_name) != previous_mtime;
    }

    bool FileSystem.verify_file_unchanged (string file_name,
        int64 previous_size,
        time_t previous_mtime) {
        const int64 actual_size = get_size (file_name);
        const time_t actual_mtime = get_mod_time (file_name);
        if ( (actual_size != previous_size && actual_mtime > 0) || (actual_mtime != previous_mtime && previous_mtime > 0 && actual_mtime > 0)) {
            q_c_info (lc_file_system) << "File" << file_name << "has changed:"
                                 << "size : " << previous_size << "<." << actual_size
                                 << ", mtime : " << previous_mtime << "<." << actual_mtime;
            return false;
        }
        return true;
    }

    int64 FileSystem.get_size (string filename) {
        return QFileInfo (filename).size ();
    }

    // Code inspired from Qt5's QDir.remove_recursively
    bool FileSystem.remove_recursively (string path, std.function<void (string path, bool is_dir)> &on_deleted, string[] *errors) {
        bool all_removed = true;
        QDirIterator di (path, QDir.AllEntries | QDir.Hidden | QDir.System | QDir.NoDotAndDotDot);

        while (di.has_next ()) {
            di.next ();
            const QFileInfo &fi = di.file_info ();
            bool remove_ok = false;
            // The use of is_sym_link here is okay:
            // we never want to go into this branch for .lnk files
            bool is_dir = fi.is_dir () && !fi.is_sym_link () && !FileSystem.is_junction (fi.absolute_file_path ());
            if (is_dir) {
                remove_ok = remove_recursively (path + QLatin1Char ('/') + di.file_name (), on_deleted, errors); // recursive
            } else {
                string remove_error;
                remove_ok = FileSystem.remove (di.file_path (), &remove_error);
                if (remove_ok) {
                    if (on_deleted)
                        on_deleted (di.file_path (), false);
                } else {
                    if (errors) {
                        errors.append (QCoreApplication.translate ("FileSystem", "Error removing \"%1\" : %2")
                                           .arg (QDir.to_native_separators (di.file_path ()), remove_error));
                    }
                    q_c_warning (lc_file_system) << "Error removing " << di.file_path () << ':' << remove_error;
                }
            }
            if (!remove_ok)
                all_removed = false;
        }
        if (all_removed) {
            all_removed = QDir ().rmdir (path);
            if (all_removed) {
                if (on_deleted)
                    on_deleted (path, true);
            } else {
                if (errors) {
                    errors.append (QCoreApplication.translate ("FileSystem", "Could not remove folder \"%1\"")
                                       .arg (QDir.to_native_separators (path)));
                }
                q_c_warning (lc_file_system) << "Error removing folder" << path;
            }
        }
        return all_removed;
    }

    bool FileSystem.get_inode (string filename, uint64 inode) {
        csync_file_stat_t fs;
        if (csync_vio_local_stat (filename, &fs) == 0) {
            *inode = fs.inode;
            return true;
        }
        return false;
    }

    } // namespace Occ
    