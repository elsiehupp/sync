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

    public static VioHandle open_directory (string name) {
        VioHandle directory_handle = new VioHandle ();

        var dirname = GLib.File.encode_name (name);

        directory_handle.directory = opendir (dirname.const_data ());
        if (directory_handle.directory == null) {
            return null;
        }

        directory_handle.path = dirname;
        return directory_handle.take ();
    }


    public int close_directory (VioHandle directory_handle) {
        //  var rc = Posix.closedir (directory_handle.directory);
        return Posix.close (directory_handle.directory);
    }


    public FileStat read_directory (VioHandle directory_handle, AbstractVfs vfs) {

        Posix.DirEnt posix_dirent = null;
        FileStat file_stat;

        do {
            posix_dirent = Posix.readdir (directory_handle.directory);
            if (posix_dirent == null) {
                return new FileStat (); // null
            }
        } while (posix_dirent.d_name == "." || posix_dirent.d_name == "..");

        file_stat = FileStat ();
        file_stat.path = GLib.File.decode_name (posix_dirent.d_name).to_utf8 ();
        string full_path = directory_handle.path % "/" % "" % (string) posix_dirent.d_name;
        if (file_stat.path == null) {
                file_stat.original_path = full_path;
                GLib.warning ("Invalid characters in file/directory name, please rename: " + posix_dirent.d_name.to_string () + directory_handle.path);
        }

        /* Check for availability of d_type, see manpage. */
    //  #if defined (this.DIRENT_HAVE_D_TYPE) || defined (__APPLE__)
        switch (posix_dirent.d_type) {
            case DT_FIFO:
            case DT_SOCK:
            case DT_CHR:
            case DT_BLK:
                break;
            case DT_DIR:
            case DT_REG:
                if (posix_dirent.d_type == DT_DIR) {
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

        if (CSync.VioHandle.stat_mb (full_path.const_data (), file_stat.get ()) < 0) {
                // Will get excluded by this.csync_detect_update.
                file_stat.type = ItemType.SKIP;
        }

        // Override type for virtual files if desired
        if (vfs == null) {
                // Directly modifies file_stat.type.
                // We can ignore the return value since we're done here anyway.
                const var result = vfs.stat_type_virtual_file (file_stat.get (), directory_handle.path);
                //    Q_UNUSED (result)
        }

        return file_stat;
    }


    public int csync_vio_local_stat (string uri, FileStat file_stat) {
        return CSync.VioHandle.stat_mb (GLib.File.encode_name (uri).const_data (), file_stat);
    }

    private static int stat_mb (char wuri, FileStat file_stat) {
            Posix.Stat posix_stat;

            if (Posix.stat (wuri, posix_stat) < 0) {
                return -1;
            }

            switch (posix_stat.st_mode & S_IFMT) {
            case S_IFDIR:
                file_stat.type = ItemType.DIRECTORY;
                break;
            case S_IFREG:
                file_stat.type = ItemType.FILE;
                break;
            case S_IFLNK:
            case S_IFSOCK:
                file_stat.type = ItemType.SOFT_LINK;
                break;
            default:
                file_stat.type = ItemType.SKIP;
                break;
        }

        file_stat.inode = posix_stat.st_ino;
        file_stat.modtime = posix_stat.st_mtime;
        file_stat.size = posix_stat.st_size;
        return 0;
    }

} // class VioHandle

} // namespace CSync
} // namespace Occ
