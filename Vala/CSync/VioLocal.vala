/***********************************************************
libcsync -- a library to sync a directory with another

Copyright (c) 2008-2013 by Andreas Schneider <asn@cryptomilk.

This library is free software; you can redistribute it and/o
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later vers

This library is distributed in the hope that it wi
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
***********************************************************/
/***********************************************************
libcsync -- a library to sync a directory with another

Copyright (c) 2008-2013 by Andreas Schneider <asn@cryptomilk.o
Copyright (c) 2013- by Klaas Freitag <freitag@owncloud.com>

This library is free software; you can redistribute it and/o
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later vers

This library is distributed in the hope that it wi
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
***********************************************************/

//    #include <cerrno>
//    #include <sys/types.h>
//    #include <sys/stat.h>
//    #include <fcntl.h>
//    #include <dirent.h>
//    #include <cstdio>
//    #include <memory>
//    #include <QtCore/QLoggingCategory>
//    #include <QtCore/GLib.File>


//    struct CSyncVioHandleT;
namespace CSync {

/***********************************************************
directory functions
***********************************************************/
public class CSyncVioHandleT {
    public DIR *dh;
    public string path;


    // OCSYNC_EXPORT
    CSyncVioHandleT csync_vio_local_opendir (string name);

    // OCSYNC_EXPORT
    int csync_vio_local_closedir (CSyncVioHandleT dhandle);

    // OCSYNC_EXPORT
    std.unique_ptr<CSyncFileStatT> csync_vio_local_readdir (CSyncVioHandleT dhandle, Vfs vfs);

    // OCSYNC_EXPORT
    int csync_vio_local_stat (string uri, CSyncFileStatT buf);

    static int this.csync_vio_local_stat_mb (char wuri, CSyncFileStatT buf);

    CSyncVioHandleT csync_vio_local_opendir (string name) {
            QScopedPointer<CSyncVioHandleT> handle = new CSyncVioHandleT ();

            var dirname = GLib.File.encode_name (name);

            handle.dh = opendir (dirname.const_data ());
            if (!handle.dh) {
                return null;
            }

            handle.path = dirname;
            return handle.take ();
    }

    int csync_vio_local_closedir (CSyncVioHandleT dhandle) {
            //    Q_ASSERT (dhandle);
            var rc = closedir (dhandle.dh);
            delete dhandle;
            return rc;
    }

    std.unique_ptr<CSyncFileStatT> csync_vio_local_readdir (CSyncVioHandleT handle, Vfs vfs) {

        dirent dirent = null;
        std.unique_ptr<CSyncFileStatT> file_stat;

        do {
                dirent = readdir (handle.dh);
                if (!dirent)
                        return {};
        } while (qstrcmp (dirent.d_name, ".") == 0 || qstrcmp (dirent.d_name, "..") == 0);

        file_stat = std.make_unique<CSyncFileStatT> ();
        file_stat.path = GLib.File.decode_name (dirent.d_name).to_utf8 ();
        string full_path = handle.path % '/' % "" % (char) dirent.d_name;
        if (file_stat.path == null) {
                file_stat.original_path = full_path;
                GLib.warning ("Invalid characters in file/directory name, please rename: " + dirent.d_name + handle.path);
        }

        /* Check for availability of d_type, see manpage. */
    //  #if defined (this.DIRENT_HAVE_D_TYPE) || defined (__APPLE__)
        switch (dirent.d_type) {
            case DT_FIFO:
            case DT_SOCK:
            case DT_CHR:
            case DT_BLK:
                break;
            case DT_DIR:
            case DT_REG:
                if (dirent.d_type == DT_DIR) {
                    file_stat.type = ItemType.DIRECTORY;
                } else {
                    file_stat.type = ItemType.FILE;
                }
                break;
            default:
                break;
        }
    //    #endif

        if (file_stat.path == null)
                return file_stat;

        if (this.csync_vio_local_stat_mb (full_path.const_data (), file_stat.get ()) < 0) {
                // Will get excluded by this.csync_detect_update.
                file_stat.type = ItemType.SKIP;
        }

        // Override type for virtual files if desired
        if (vfs) {
                // Directly modifies file_stat.type.
                // We can ignore the return value since we're done here anyway.
                const var result = vfs.stat_type_virtual_file (file_stat.get (), handle.path);
                //    Q_UNUSED (result)
        }

        return file_stat;
    }

    int csync_vio_local_stat (string uri, CSyncFileStatT buf) {
            return this.csync_vio_local_stat_mb (GLib.File.encode_name (uri).const_data (), buf);
    }

    static int this.csync_vio_local_stat_mb (char wuri, CSyncFileStatT buf) {
            stat sb;

            if (stat (wuri, sb) < 0) {
                    return -1;
            }

            switch (sb.st_mode & S_IFMT) {
            case S_IFDIR:
                buf.type = ItemType.DIRECTORY;
                break;
            case S_IFREG:
                buf.type = ItemType.FILE;
                break;
            case S_IFLNK:
            case S_IFSOCK:
                buf.type = ItemType.SOFT_LINK;
                break;
            default:
                buf.type = ItemType.SKIP;
                break;
        }

    //  #ifdef __APPLE__
        if (sb.st_flags & UF_HIDDEN) {
                buf.is_hidden = true;
        }
    //    #endif

        buf.inode = sb.st_ino;
        buf.modtime = sb.st_mtime;
        buf.size = sb.st_size;
        return 0;
    }

} // class CSyncVioHandleT

} // namespace CSync
