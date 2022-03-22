namespace Occ {
namespace CSync {

/***********************************************************
@class VioHandle

@brief CSync directory functions

libcsync -- a library to sync a directory with another

@author 2008-2013 by Andreas Schneider <asn@cryptomilk.org>
@author 2013- by Klaas Freitag <freitag@owncloud.com>

@copyright LGPL 2.1 or later
***********************************************************/
public class VioHandle : GLib.Object {

    public Posix.Dir *directory;
    public string path;

    public static VioHandle csync_vio_local_opendir (string name) {
        VioHandle handle = new VioHandle ();

        var dirname = GLib.File.encode_name (name);

        handle.directory = opendir (dirname.const_data ());
        if (handle.directory == null) {
            return null;
        }

        handle.path = dirname;
        return handle.take ();
    }


    public int csync_vio_local_closedir (VioHandle directory_handle) {
        //    Q_ASSERT (directory_handle);
        var rc = closedir (directory_handle.directory);
        delete directory_handle;
        return rc;
    }


    public FileStat csync_vio_local_readdir (VioHandle directory_handle, Vfs vfs) {

        Posix.DirEnt dirent = null;
        FileStat file_stat;

        do {
                dirent = readdir (handle.directory);
                if (!dirent)
                        return {};
        } while (qstrcmp (dirent.d_name, ".") == 0 || qstrcmp (dirent.d_name, "..") == 0);

        file_stat = std.make_unique<FileStat> ();
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


    public int csync_vio_local_stat (string uri, FileStat buf) {
            return this.csync_vio_local_stat_mb (GLib.File.encode_name (uri).const_data (), buf);
    }

    private static int csync_vio_local_stat_mb (char wuri, FileStat buf) {
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

        buf.inode = sb.st_ino;
        buf.modtime = sb.st_mtime;
        buf.size = sb.st_size;
        return 0;
    }

} // class VioHandle

} // namespace CSync
} // namespace Occ
