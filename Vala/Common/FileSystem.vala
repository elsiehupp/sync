/***********************************************************
@author Olivier Goffart <ogoffart@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

//  #include <GLib.Dir>
//  #include <Gtk.Application>
//  #include <sys/stat.h>
//  #include <sys/types.h>


//  #include <ctime>
//  #include <GLib.FileInfo>
//  #include <QLoggingCategory>
//  #include <ocsynclib.h>


namespace Occ {

/***********************************************************
 \addtogroup libsync
 @{
***********************************************************/

/***********************************************************
@brief This file contains file system helper
***********************************************************/
public class FileSystem {

    static GLib.File.Permissions default_write_permissions;

    /***********************************************************
    @brief Mark the file as hidden  (only has effects on windows)

    OCSYNC_EXPORT
    ***********************************************************/
    public static void file_hidden (string filename, bool hidden) {
        //  Q_UNUSED (filename);
        //  Q_UNUSED (hidden);
    }


    /***********************************************************
    @brief Marks the file as read-only.

    On linux this either revokes all 'w' permissions or
    restores permissions according to the umask.

    OCSYNC_EXPORT
    ***********************************************************/
    public static void file_read_only (string filename, bool read_only) {
        GLib.File file = GLib.File.new_for_path (filename);
        GLib.File.Permissions permissions = file.permissions ();

        GLib.File.Permissions all_write_permissions =
            GLib.File.WriteUser | GLib.File.WriteGroup | GLib.File.WriteOther | GLib.File.WriteOwner;
        FileSystem.default_write_permissions = get_default_write_permissions ();

        permissions &= ~all_write_permissions;
        if (!read_only) {
            permissions |= default_write_permissions;
        }
        file.permissions (permissions);
    }


    /***********************************************************
    @brief Marks the file as read-only.

    It's like file_read_only (), but weaker : if read_only is false and t
    already has write permissions, no change to the permissions is made.

    This means that it will preserve explicitly set rw-r--r-- permissions even
    when the umask is 0002. (file_read_only () would adjust to rw-rw-r--)

    OCSYNC_EXPORT
    ***********************************************************/
    public static void file_read_only_weak (string filename, bool read_only) {
        GLib.File file = GLib.File.new_for_path (filename);
        GLib.File.Permissions permissions = file.permissions ();

        if (!read_only && (permissions & GLib.File.WriteOwner)) {
            return; // already writable enough
        }

        file_read_only (filename, read_only);
    }


    /***********************************************************
    @brief Try to set permissions so that other users on the
    local machine can not go into the folder.

    OCSYNC_EXPORT
    ***********************************************************/
    public static void folder_minimum_permissions (string filename) {
        //  Q_UNUSED (filename);
    }


    /***********************************************************
    convert a "normal" windows path into a path that can be 32k chars long.

    OCSYNC_EXPORT
    ***********************************************************/
    public static string long_win_path (string inpath) {
        return inpath;
    }


    /***********************************************************
    @brief Checks whether a file exists.

    Use this over GLib.FileInfo.exists () and GLib.File.exists () to avoid bugs with lnk
    files, see above.

    OCSYNC_EXPORT
    ***********************************************************/
    public static bool file_exists (string filename, GLib.FileInfo file_info = new GLib.FileInfo ()) {
        bool re = file_info.exists ();
        // if the filename is different from the filename in file_info, the file_info is
        // not valid. There needs to be one initialised here. Otherwise the incoming
        // file_info is re-used.
        if (file_info.file_path != filename) {
            GLib.FileInfo my_f_i = new GLib.FileInfo (filename);
            re = my_f_i.exists ();
        }
        return re;
    }


    /***********************************************************
    @brief Rename the file \a origin_filename to
    \a destination_filename.

    It behaves as GLib.File.rename () but handles .lnk files
    correctly on Windows.

    OCSYNC_EXPORT
    ***********************************************************/
    public static bool rename (string origin_filename,
        string destination_filename,
        string error_string = "") {
        bool success = false;
        string error;

        GLib.File orig = GLib.File.new_for_path (origin_filename);
        success = orig.rename (destination_filename);
        if (!success) {
            error = orig.error_string;
        }

        if (!success) {
            GLib.warning (
                "Error renaming file " + origin_filename
                + " to " + destination_filename
                + " failed: " + error);
            if (error_string) {
                *error_string = error;
            }
        }
        return success;
    }


    /***********************************************************
    Rename the file \a origin_filename to
    \a destination_filename, and overwrite the destination if
    it already exists, without extra checks.

    OCSYNC_EXPORT
    ***********************************************************/
    public static bool unchecked_rename_replace (
        string origin_filename,
        string destination_filename,
        string error_string) {

        bool success = false;
        GLib.File orig = new GLib.File (origin_filename);
        // We want a rename that also overwites.  GLib.File.rename does not overwite.
        // Qt 5.1 has QSaveFile.rename_overwrite we could use.
        // ### FIXME
        success = true;
        bool dest_exists = file_exists (destination_filename);
        if (dest_exists && !GLib.File.remove (destination_filename)) {
            *error_string = orig.error_string;
            GLib.warning ("Target file could not be removed.");
            success = false;
        }
        if (success) {
            success = orig.rename (destination_filename);
        }
        if (!success) {
            *error_string = orig.error_string;
            GLib.warning ("Renaming temp file to final failed: " + *error_string);
            return false;
        }

        return true;
    }


    /***********************************************************
    Removes a file.

    Equivalent to GLib.File.remove (), except on Windows, where it will also
    successfully remove read-only files.

    OCSYNC_EXPORT
    ***********************************************************/
    public static bool remove (string filename, string error_string = "") {
        GLib.File file = GLib.File.new_for_path (filename);
        if (!file.remove ()) {
            if (error_string) {
                *error_string = file.error_string;
            }
            return false;
        }
        return true;
    }


    /***********************************************************
    Move the specified file or folder to the trash.
    (Only implemented on linux)

    OCSYNC_EXPORT
    ***********************************************************/
    public static bool move_to_trash (string filename, string error_string) {
        // TODO : Qt 5.15 bool GLib.File.move_to_trash ()
        string trash_path, trash_file_path, trash_info_path;
        string xdg_data_home = GLib.File.decode_name (qgetenv ("XDG_DATA_HOME"));
        if (xdg_data_home == "") {
            trash_path = GLib.Dir.home_path + "/.local/share/Trash/"; // trash path that should exist
        } else {
            trash_path = xdg_data_home + "/Trash/";
        }

        trash_file_path = trash_path + "files/"; // trash file path contain delete files
        trash_info_path = trash_path + "info/"; // trash info path contain delete files information

        if (! (GLib.Dir ().mkpath (trash_file_path) && GLib.Dir ().mkpath (trash_info_path))) {
            *error_string = _("FileSystem", "Could not make directories in trash");
            return false; //mkpath will return true if path exists
        }

        GLib.FileInfo file_info = new GLib.FileInfo (filename);

        GLib.Dir file;
        int suffix_number = 1;
        if (file.exists (trash_file_path + file_info.filename ())) { //file in trash already exists, move to "filename.1"
            string path = trash_file_path + file_info.filename () + '.';
            while (file.exists (path + string.number (suffix_number))) { //or to "filename.2" if "filename.1" exists, etc
                suffix_number++;
            }
            if (!file.rename (file_info.absolute_file_path, path + string.number (suffix_number))) { // rename (file old path, file trash path)
                *error_string = _("FileSystem", " (Could not move \"%1\" to \"%2\")")
                                   .printf (file_info.absolute_file_path, path + string.number (suffix_number));
                return false;
            }
        } else {
            if (!file.rename (file_info.absolute_file_path, trash_file_path + file_info.filename ())) { // rename (file old path, file trash path)
                *error_string = _("FileSystem", " (Could not move \"%1\" to \"%2\")")
                                   .printf (file_info.absolute_file_path, trash_file_path + file_info.filename ());
                return false;
            }
        }

        // create file format for trash info file----- START
        GLib.File info_file;
        if (file.exists (trash_info_path + file_info.filename () + ".trashinfo")) { // TrashInfo file already exists, create "filename.1.trashinfo"
            string filename = trash_info_path + file_info.filename () + '.' + string.number (suffix_number) + ".trashinfo";
            info_file.filename (filename); //filename+.trashinfo //  create file information file in /.local/share/Trash/info/ folder
        } else {
            string filename = trash_info_path + file_info.filename () + ".trashinfo";
            info_file.filename (filename); //filename+.trashinfo //  create file information file in /.local/share/Trash/info/ folder
        }

        info_file.open (QIODevice.ReadWrite);

        QTextStream stream = new QTextStream (info_file); // for write data on open file

        stream += "[Trash Info]\n"
               + "Path="
               + GLib.Uri.to_percent_encoding (file_info.absolute_file_path, "~this.-./")
               + "\n"
               + "DeletionDate="
               + GLib.DateTime.current_date_time ().to_string (Qt.ISODate)
               + '\n';
        info_file.close ();

        // create info file format of trash file----- END

        return true;
    }


    /***********************************************************
    Replacement for GLib.File.open (ReadOnly) followed by a seek ().
    This version sets a more permissive sharing mode on Windows.

    Warning : The resulting file may have an empty filename and be unsuitable for use
    with GLib.FileInfo! Calling seek () on the GLib.File with >32bit signed values will fail!

    OCSYNC_EXPORT
    ***********************************************************/
    public static bool open_and_seek_file_shared_read (GLib.File file, string error_or_null, int64 seek) {
        string error_dummy;
        // avoid many if (error_or_null) later.
        string error = error_or_null ? *error_or_null : error_dummy;
        error.clear ();

        if (!file.open (GLib.File.ReadOnly)) {
            error = file.error_string;
            return false;
        }
        if (!file.seek (seek)) {
            error = file.error_string;
            return false;
        }
        return true;
    }


    /***********************************************************
    Returns whether the file is a shortcut file (ends with .lnk)

    OCSYNC_EXPORT
    ***********************************************************/
    public static bool is_lnk_file (string filename) {
        return filename.ends_with (".lnk");
    }


    /***********************************************************
    Returns whether the file is an exclude file (contains patterns to exclude from sync)

    OCSYNC_EXPORT
    ***********************************************************/
    public static bool is_exclude_file (string filename) {
        return filename.down () == ".sync-exclude.lst"
            || filename.down () == "exclude.lst"
            || filename.down ().has_suffix ("/.sync-exclude.lst")
            || filename.down ().has_suffix ("/exclude.lst");
    }


    /***********************************************************
    ***********************************************************/
    private static GLib.File.Permissions get_default_write_permissions () {
        GLib.File.Permissions result = GLib.File.WriteUser;
        mode_t mask = umask (0);
        umask (mask);
        if (! (mask & S_IWGRP)) {
            result |= GLib.File.WriteGroup;
        }
        if (! (mask & S_IWOTH)) {
            result |= GLib.File.WriteOther;
        }
        return result;
    }
}

} // namespace Occ
    