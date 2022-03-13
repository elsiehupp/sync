/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <GLib.FileInfo>
//  #include <QDir>
//  #include <QDirIterator>
//  #include <QCoreApplication>


//  #include <ctime>
//  #include <functional>
//  #include <owncloudlib.h>


// Chain in the base include and extend the namespace
namespace Occ {
namespace LibSync {

/***********************************************************
@brief This file contains file system helper

 \addtogroup libsync
 @{
***********************************************************/
class FileSystem : GLib.Object {

    /***********************************************************
    @brief compare two files with given filename and return true if they have the same content
    ***********************************************************/
    public static bool file_equals (string fn1, string fn2) {
        // compare two files with given filename and return true if they have the same content
        GLib.File f1 (fn1);
        GLib.File f2 (fn2);
        if (!f1.open (QIODevice.ReadOnly) || !f2.open (QIODevice.ReadOnly)) {
            GLib.warning ("file_equals : Failed to open " + fn1 + "or" + fn2;
            return false;
        }

        if (get_size (fn1) != get_size (fn2)) {
            return false;
        }

        const int BufferSize = 16 * 1024;
        GLib.ByteArray buffer1 (BufferSize, 0);
        GLib.ByteArray buffer2 (BufferSize, 0);
        // the files have the same size, compare all of it
        while (!f1.at_end ()) {
            f1.read (buffer1.data (), BufferSize);
            f2.read (buffer2.data (), BufferSize);
            if (buffer1 != buffer2) {
                return false;
            }
        }
        return true;
    }


    /***********************************************************
    @brief Get the mtime for a filepath

    Use this over GLib.FileInfo.last_modified () to avoid timezone related bugs. See
    owncloud/core#9781 for details.
    ***********************************************************/
    public static time_t get_mod_time (string filename) {
        csync_file_stat_t stat;
        int64 result = -1;
        if (csync_vio_local_stat (filename, stat) != -1
            && (stat.modtime != 0)) {
            result = stat.modtime;
        } else {
            result = Utility.q_date_time_to_time_t (GLib.FileInfo (filename).last_modified ());
            GLib.warning ("Could not get modification time for" + filename
                                    + "with csync, using GLib.FileInfo:" + result;
        }
        return result;
    }


    public static bool mod_time (string filename, time_t mod_time) {
        struct timeval times[2];
        times[0].tv_sec = times[1].tv_sec = mod_time;
        times[0].tv_usec = times[1].tv_usec = 0;
        int rc = c_utimes (filename, times);
        if (rc != 0) {
            GLib.warning ("Error setting mtime for" + filename
                                    + "failed : rc" + rc + ", errno:" + errno;
            return false;
        }
        return true;
    }


    /***********************************************************
    @brief Get the size for a file

    Use this over GLib.FileInfo.size () to avoid bugs with lnk files on Windows.
    See https://bugreports.qt.io/browse/QTBUG-24831.
    ***********************************************************/
    public static int64 get_size (string filename) {
        return GLib.FileInfo (filename).size ();
    }


    /***********************************************************
    @brief Retrieve a file inode with csync
    ***********************************************************/
    public static bool get_inode (string filename, uint64 inode) {
        csync_file_stat_t fs;
        if (csync_vio_local_stat (filename, fs) == 0) {
            *inode = fs.inode;
            return true;
        }
        return false;
    }


    /***********************************************************
    @brief Check if \a filename has changed given previous size and mtime

    Nonexisting files are covered through mtime : they have an mtime of -1.

    @return true if the file's mtime or size are not what is expected.
    ***********************************************************/
    public static bool file_changed (string filename,
        int64 previous_size,
        time_t previous_mtime) {
        return get_size (filename) != previous_size
            || get_mod_time (filename) != previous_mtime;
    }


    /***********************************************************
    @brief Like !file_changed () but with verbose logging if the file did* change.
    ***********************************************************/
    public static bool verify_file_unchanged (string filename,
        int64 previous_size,
        time_t previous_mtime) {
        const int64 actual_size = get_size (filename);
        const time_t actual_mtime = get_mod_time (filename);
        if ( (actual_size != previous_size && actual_mtime > 0) || (actual_mtime != previous_mtime && previous_mtime > 0 && actual_mtime > 0)) {
            GLib.info ("File" + filename + "has changed:"
                                    + "size: " + previous_size + "<." + actual_size
                                    + ", mtime: " + previous_mtime + "<." + actual_mtime;
            return false;
        }
        return true;
    }


    /***********************************************************
    Removes a directory and its contents recursively

    Returns true if all removes succeeded.
    on_signal_deleted () is called for each deleted file or directory, including the root.
    errors are collected in errors.

    Code inspired from Qt5's QDir.remove_recursively
    ***********************************************************/
    public static bool remove_recursively (string path,
        const std.function<void (string path, bool is_dir)> on_signal_deleted = null,
        string[] errors = null) {
        bool all_removed = true;
        QDirIterator di (path, QDir.AllEntries | QDir.Hidden | QDir.System | QDir.NoDotAndDotDot);

        while (di.has_next ()) {
            di.next ();
            const GLib.FileInfo file_info = di.file_info ();
            bool remove_ok = false;
            // The use of is_sym_link here is okay:
            // we never want to go into this branch for .lnk files
            bool is_dir = file_info.is_dir () && !file_info.is_sym_link ();
            if (is_dir) {
                remove_ok = remove_recursively (path + '/' + di.filename (), on_signal_deleted, errors); // recursive
            } else {
                string remove_error;
                remove_ok = FileSystem.remove (di.file_path (), remove_error);
                if (remove_ok) {
                    if (on_signal_deleted)
                        on_signal_deleted (di.file_path (), false);
                } else {
                    if (errors) {
                        errors.append (_("FileSystem", "Error removing \"%1\" : %2")
                                            .arg (QDir.to_native_separators (di.file_path ()), remove_error));
                    }
                    GLib.warning ("Error removing " + di.file_path () + ':' + remove_error;
                }
            }
            if (!remove_ok)
                all_removed = false;
        }
        if (all_removed) {
            all_removed = QDir ().rmdir (path);
            if (all_removed) {
                if (on_signal_deleted)
                    on_signal_deleted (path, true);
            } else {
                if (errors) {
                    errors.append (_("FileSystem", "Could not remove folder \"%1\"")
                                        .arg (QDir.to_native_separators (path)));
                }
                GLib.warning ("Error removing folder" + path;
            }
        }
        return all_removed;
    }

} // class FileSystem

} // namespace LibSync
} // namespace Occ
    