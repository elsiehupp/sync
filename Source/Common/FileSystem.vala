/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <GLib.DateTime>
// #include <QDir>
// #include <GLib.Uri>
// #include <GLib.File>
// #include <QCoreApplication>

// #include <sys/stat.h>
// #include <sys/types.h>

// #pragma once

// #include <string>
// #include <ctime>
// #include <QFileInfo>
// #include <QLoggingCategory>

// #include <ocsynclib.h>


namespace Occ {

OCSYNC_EXPORT Q_DECLARE_LOGGING_CATEGORY (lc_file_system)

/***********************************************************
 \addtogroup libsync
 @{
***********************************************************/

/***********************************************************
@brief This file contains file system helper
***********************************************************/
namespace FileSystem {

    /***********************************************************
    @brief Mark the file as hidden  (only has effects on windows)

    OCSYNC_EXPORT
    ***********************************************************/
    void set_file_hidden (string filename, bool hidden) {
        Q_UNUSED (filename);
        Q_UNUSED (hidden);
    }


    /***********************************************************
    @brief Marks the file as read-only.

    On linux this either revokes all 'w' permissions or
    restores permissions according to the umask.

    OCSYNC_EXPORT
    ***********************************************************/
    void set_file_read_only (string filename, bool read_only) {
        GLib.File file = new GLib.File (filename);
        GLib.File.Permissions permissions = file.permissions ();

        GLib.File.Permissions all_write_permissions =
            GLib.File.Write_user | GLib.File.Write_group | GLib.File.Write_other | GLib.File.Write_owner;
        static GLib.File.Permissions default_write_permissions = get_default_write_permissions ();

        permissions &= ~all_write_permissions;
        if (!read_only) {
            permissions |= default_write_permissions;
        }
        file.set_permissions (permissions);
    }


    /***********************************************************
    @brief Marks the file as read-only.

    It's like set_file_read_only (), but weaker : if read_only is false and t
    already has write permissions, no change to the permissions is made.

    This means that it will preserve explicitly set rw-r--r-- permissions even
    when the umask is 0002. (set_file_read_only () would adjust to rw-rw-r--)

    OCSYNC_EXPORT
    ***********************************************************/
    void set_file_read_only_weak (string filename, bool read_only) {
        GLib.File file = new GLib.File (filename);
        GLib.File.Permissions permissions = file.permissions ();

        if (!read_only && (permissions & GLib.File.Write_owner)) {
            return; // already writable enough
        }

        set_file_read_only (filename, read_only);
    }


    /***********************************************************
    @brief Try to set permissions so that other users on the
    local machine can not go into the folder.

    OCSYNC_EXPORT
    ***********************************************************/
    void set_folder_minimum_permissions (string filename) {
        Q_UNUSED (filename);
    }


    /***********************************************************
    convert a "normal" windows path into a path that can be 32k chars long.

    OCSYNC_EXPORT
    ***********************************************************/
    string long_win_path (string inpath) {
        return inpath;
    }


    /***********************************************************
    @brief Checks whether a file exists.

    Use this over QFileInfo.exists () and GLib.File.exists () to avoid bugs with lnk
    files, see above.

    OCSYNC_EXPORT
    ***********************************************************/
    bool file_exists (string filename, QFileInfo file_info = new QFileInfo ()) {
        bool re = file_info.exists ();
        // if the filename is different from the filename in file_info, the file_info is
        // not valid. There needs to be one initialised here. Otherwise the incoming
        // file_info is re-used.
        if (file_info.file_path () != filename) {
            QFileInfo my_f_i (filename);
            re = my_f_i.exists ();
        }
        return re;
    }


    /***********************************************************
    @brief Rename the file \a origin_file_name to
    \a destination_file_name.

    It behaves as GLib.File.rename () but handles .lnk files
    correctly on Windows.

    OCSYNC_EXPORT
    ***********************************************************/
    bool rename (string origin_file_name,
        const string destination_file_name,
        string error_string = "") {
        bool on_success = false;
        string error;

        GLib.File orig (origin_file_name);
        on_success = orig.rename (destination_file_name);
        if (!on_success) {
            error = orig.error_string ();
        }

        if (!on_success) {
            GLib.warn (lc_file_system) << "Error renaming file" << origin_file_name
                                    << "to" << destination_file_name
                                    << "failed : " << error;
            if (error_string) {
                *error_string = error;
            }
        }
        return on_success;
    }


    /***********************************************************
    Rename the file \a origin_file_name to
    \a destination_file_name, and overwrite the destination if
    it already exists, without extra checks.

    OCSYNC_EXPORT
    ***********************************************************/
    bool unchecked_rename_replace (string origin_file_name,
        const string destination_file_name,
        string error_string) {

        bool on_success = false;
        GLib.File orig (origin_file_name);
        // We want a rename that also overwites.  GLib.File.rename does not overwite.
        // Qt 5.1 has QSave_file.rename_overwrite we could use.
        // ### FIXME
        on_success = true;
        bool dest_exists = file_exists (destination_file_name);
        if (dest_exists && !GLib.File.remove (destination_file_name)) {
            *error_string = orig.error_string ();
            GLib.warn (lc_file_system) << "Target file could not be removed.";
            on_success = false;
        }
        if (on_success) {
            on_success = orig.rename (destination_file_name);
        }
        if (!on_success) {
            *error_string = orig.error_string ();
            GLib.warn (lc_file_system) << "Renaming temp file to final failed : " << *error_string;
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
    bool remove (string file_name, string error_string = "") {
        GLib.File f (file_name);
        if (!f.remove ()) {
            if (error_string) {
                *error_string = f.error_string ();
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
    bool move_to_trash (string filename, string error_string) {
        // TODO : Qt 5.15 bool GLib.File.move_to_trash ()
        string trash_path, trash_file_path, trash_info_path;
        string xdg_data_home = GLib.File.decode_name (qgetenv ("XDG_DATA_HOME"));
        if (xdg_data_home.is_empty ()) {
            trash_path = QDir.home_path () + "/.local/share/Trash/"; // trash path that should exist
        } else {
            trash_path = xdg_data_home + "/Trash/";
        }

        trash_file_path = trash_path + "files/"; // trash file path contain delete files
        trash_info_path = trash_path + "info/"; // trash info path contain delete files information

        if (! (QDir ().mkpath (trash_file_path) && QDir ().mkpath (trash_info_path))) {
            *error_string = QCoreApplication.translate ("FileSystem", "Could not make directories in trash");
            return false; //mkpath will return true if path exists
        }

        QFileInfo f (file_name);

        QDir file;
        int suffix_number = 1;
        if (file.exists (trash_file_path + f.file_name ())) { //file in trash already exists, move to "filename.1"
            string path = trash_file_path + f.file_name () + '.';
            while (file.exists (path + string.number (suffix_number))) { //or to "filename.2" if "filename.1" exists, etc
                suffix_number++;
            }
            if (!file.rename (f.absolute_file_path (), path + string.number (suffix_number))) { // rename (file old path, file trash path)
                *error_string = QCoreApplication.translate ("FileSystem", R" (Could not move "%1" to "%2")")
                                   .arg (f.absolute_file_path (), path + string.number (suffix_number));
                return false;
            }
        } else {
            if (!file.rename (f.absolute_file_path (), trash_file_path + f.file_name ())) { // rename (file old path, file trash path)
                *error_string = QCoreApplication.translate ("FileSystem", R" (Could not move "%1" to "%2")")
                                   .arg (f.absolute_file_path (), trash_file_path + f.file_name ());
                return false;
            }
        }

        // create file format for trash info file----- START
        GLib.File info_file;
        if (file.exists (trash_info_path + f.file_name () + ".trashinfo")) { //Trash_info file already exists, create "filename.1.trashinfo"
            string filename = trash_info_path + f.file_name () + '.' + string.number (suffix_number) + ".trashinfo";
            info_file.set_file_name (filename); //filename+.trashinfo //  create file information file in /.local/share/Trash/info/ folder
        } else {
            string filename = trash_info_path + f.file_name () + ".trashinfo";
            info_file.set_file_name (filename); //filename+.trashinfo //  create file information file in /.local/share/Trash/info/ folder
        }

        info_file.open (QIODevice.ReadWrite);

        QTextStream stream (&info_file); // for write data on open file

        stream << "[Trash Info]\n"
               << "Path="
               << GLib.Uri.to_percent_encoding (f.absolute_file_path (), "~_-./")
               << "\n"
               << "Deletion_date="
               << GLib.DateTime.current_date_time ().to_string (Qt.ISODate)
               << '\n';
        info_file.close ();

        // create info file format of trash file----- END

        return true;
    }


    /***********************************************************
    Replacement for GLib.File.open (ReadOnly) followed by a seek ().
    This version sets a more permissive sharing mode on Windows.

    Warning : The resulting file may have an empty file_name and be unsuitable for use
    with QFileInfo! Calling seek () on the GLib.File with >32bit signed values will fail!

    OCSYNC_EXPORT
    ***********************************************************/
    bool open_and_seek_file_shared_read (GLib.File file, string error_or_null, int64 seek) {
        string error_dummy;
        // avoid many if (error_or_null) later.
        string error = error_or_null ? *error_or_null : error_dummy;
        error.clear ();

        if (!file.open (GLib.File.ReadOnly)) {
            error = file.error_string ();
            return false;
        }
        if (!file.seek (seek)) {
            error = file.error_string ();
            return false;
        }
        return true;
    }


    /***********************************************************
    Returns true when a file is locked. (Windows only)

    OCSYNC_EXPORT
    ***********************************************************/
    bool is_file_locked (string file_name) {
        Q_UNUSED (file_name);
        return false;
    }


    /***********************************************************
    Returns whether the file is a shortcut file (ends with .lnk)

    OCSYNC_EXPORT
    ***********************************************************/
    bool is_lnk_file (string filename) {
        return filename.ends_with (QLatin1String (".lnk"));
    }


    /***********************************************************
    Returns whether the file is an exclude file (contains patterns to exclude from sync)

    OCSYNC_EXPORT
    ***********************************************************/
    bool is_exclude_file (string filename) {
        return filename.compare (".sync-exclude.lst", Qt.CaseInsensitive) == 0
            || filename.compare ("exclude.lst", Qt.CaseInsensitive) == 0
            || filename.ends_with ("/.sync-exclude.lst", Qt.CaseInsensitive)
            || filename.ends_with ("/exclude.lst", Qt.CaseInsensitive);
    }


    /***********************************************************
    Returns whether the file is a junction (windows only)

    OCSYNC_EXPORT
    ***********************************************************/
    bool is_junction (string filename) {
        Q_UNUSED (filename);
        return false;
    }


    /***********************************************************
    ***********************************************************/
    private static GLib.File.Permissions get_default_write_permissions () {
        GLib.File.Permissions result = GLib.File.Write_user;
        mode_t mask = umask (0);
        umask (mask);
        if (! (mask & S_IWGRP)) {
            result |= GLib.File.Write_group;
        }
        if (! (mask & S_IWOTH)) {
            result |= GLib.File.Write_other;
        }
        return result;
    }
}

} // namespace Occ
    