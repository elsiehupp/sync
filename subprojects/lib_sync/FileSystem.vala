namespace Occ {
namespace LibSync {

/***********************************************************
@class FileSystem

@brief This file contains file system helper

@author Olivier Goffart <ogoffart@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class FileSystem { //: GLib.Object {

//    /***********************************************************
//    @brief compare two files with given filename and return true if they have the same content
//    ***********************************************************/
//    public static bool file_equals (string filename_1, string filename_2) {
//        // compare two files with given filename and return true if they have the same content
//        GLib.File file_1 = new GLib.File (filename_1);
//        GLib.File file_2 = new GLib.File (filename_2);
//        if (!file_1.open (GLib.IODevice.ReadOnly) || !file_2.open (GLib.IODevice.ReadOnly)) {
//            GLib.warning ("file_equals: Failed to open " + filename_1 + " or " + filename_2);
//            return false;
//        }

//        if (get_size (filename_1) != get_size (filename_2)) {
//            return false;
//        }

//        int BUFFER_SIZE = 16 * 1024;
//        string buffer1;
//        string buffer2;
//        // the files have the same size, compare all of it
//        while (!file_1.at_end ()) {
//            file_1.read (buffer1, BUFFER_SIZE);
//            file_2.read (buffer2, BUFFER_SIZE);
//            if (buffer1 != buffer2) {
//                return false;
//            }
//        }
//        return true;
//    }


//    /***********************************************************
//    @brief Get the mtime for a filepath

//    Use this over GLib.FileInfo.last_modified () to avoid timezone related bugs. See
//    owncloud/core#9781 for details.
//    ***********************************************************/
//    public static time_t get_mod_time (string filename) {
//        CSync.FileStat stat;
//        int64 result = -1;
//        if (csync_vio_local_stat (filename, stat) != -1
//            && (stat.modtime != 0)) {
//            result = stat.modtime;
//        } else {
//            result = Utility.q_date_time_to_time_t (GLib.File.new_for_path (filename).last_modified ());
//            GLib.warning ("Could not get modification time for " + filename
//                        + "with csync, using GLib.FileInfo: " + result.to_string ());
//        }
//        return result;
//    }


//    public static bool mod_time (string filename, time_t mod_time) {
//        time_t times[2];
//        times[0].tv_sec = times[1].tv_sec = mod_time;
//        times[0].tv_usec = times[1].tv_usec = 0;
//        int rc = GLib.FileUtils.utime ( (filename, times);
//        if (rc != 0) {
//            GLib.warning ("Error setting mtime for " + filename
//                        + "failed: rc " + rc + ", errno: " + errno);
//            return false;
//        }
//        return true;
//    }


//    /***********************************************************
//    @brief Get the size for a file

//    Use this over GLib.FileInfo.size () to avoid bugs with lnk files on Windows.
//    See https://bugreports.qt.io/browse/GLib.TBUG-24831.
//    ***********************************************************/
//    public static int64 get_size (string filename) {
//        return GLib.File.new_for_path (filename).size ();
//    }


//    /***********************************************************
//    @brief Retrieve a file inode with csync
//    ***********************************************************/
//    public static bool get_inode (string filename, uint64 inode) {
//        CSync.FileStat fs;
//        if (csync_vio_local_stat (filename, fs) == 0) {
//            *inode = fs.inode;
//            return true;
//        }
//        return false;
//    }


//    /***********************************************************
//    @brief Check if \a filename has changed given previous size and mtime

//    Nonexisting files are covered through mtime : they have an mtime of -1.

//    @return true if the file's mtime or size are not what is expected.
//    ***********************************************************/
//    public static bool file_changed (string filename,
//        int64 previous_size,
//        time_t previous_mtime) {
//        return get_size (filename) != previous_size
//            || get_mod_time (filename) != previous_mtime;
//    }


//    /***********************************************************
//    @brief Like !file_changed () but with verbose logging if the file did* change.
//    ***********************************************************/
//    public static bool verify_file_unchanged (string filename,
//        int64 previous_size,
//        time_t previous_mtime) {
//        int64 actual_size = get_size (filename);
//        time_t actual_mtime = get_mod_time (filename);
//        if ( (actual_size != previous_size && actual_mtime > 0) || (actual_mtime != previous_mtime && previous_mtime > 0 && actual_mtime > 0)) {
//            GLib.info ("File " + filename + " has changed: "
//                     + "size: " + previous_size.to_string () + " <-> " + actual_size.to_string ()
//                     + ", mtime: " + previous_mtime.to_string () + " <-> " + actual_mtime.to_string ());
//            return false;
//        }
//        return true;
//    }


//    private delegate void SignalDelegate (string path, bool is_dir);


//    /***********************************************************
//    Removes a directory and its contents recursively

//    Returns true if all removes succeeded.
//    signal_delegate () is called for each deleted file or directory, including the root.
//    errors are collected in errors.

//    Code inspired from Qt5's GLib.Dir.remove_recursively
//    ***********************************************************/
//    public static bool remove_recursively (
//        string path,
//        SignalDelegate signal_delegate,
//        GLib.List<string> errors = new GLib.List<string> ()) {
//        bool all_removed = true;
//        GLib.DirIterator dir_iterator = new GLib.DirIterator (path, GLib.Dir.AllEntries | GLib.Dir.Hidden | GLib.Dir.System | GLib.Dir.NoDotAndDotDot);

//        while (dir_iterator.has_next ()) {
//            dir_iterator.next ();
//            GLib.FileInfo file_info = dir_iterator.file_info ();
//            bool remove_ok = false;
//            // The use of is_sym_link here is okay:
//            // we never want to go into this branch for .lnk files
//            bool is_dir = file_info.query_info ().get_file_type () == FileType.DIRECTORY && !file_info.is_sym_link ();
//            if (is_dir) {
//                remove_ok = remove_recursively (path + "/" + dir_iterator.filename (), signal_delegate, errors); // recursive
//            } else {
//                string remove_error;
//                remove_ok = FileSystem.remove (dir_iterator.file_path, remove_error);
//                if (remove_ok) {
//                    if (signal_delegate)
//                        signal_delegate (dir_iterator.file_path, false);
//                } else {
//                    if (errors != null) {
//                        errors.append (_("FileSystem", "Error removing \"%1\" : %2")
//                                            .printf (GLib.Dir.to_native_separators (dir_iterator.file_path), remove_error));
//                    }
//                    GLib.warning ("Error removing " + dir_iterator.file_path + " : " + remove_error);
//                }
//            }
//            if (!remove_ok) {
//                all_removed = false;
//            }
//        }
//        if (all_removed) {
//            all_removed = new GLib.Dir ().rmdir (path);
//            if (all_removed) {
//                if (signal_delegate)
//                    signal_delegate (path, true);
//            } else {
//                if (errors != null) {
//                    errors.append (_("FileSystem", "Could not remove folder \"%1\"")
//                                        .printf (GLib.Dir.to_native_separators (path)));
//                }
//                GLib.warning ("Error removing folder " + path);
//            }
//        }
//        return all_removed;
//    }

} // class FileSystem

} // namespace LibSync
} // namespace Occ
//    