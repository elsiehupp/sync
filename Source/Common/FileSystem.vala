/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <QDateTime>
// #include <QDir>
// #include <QUrl>
// #include <QFile>
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
    ***********************************************************/
    void OCSYNC_EXPORT set_file_hidden (string &filename, bool hidden);

    /***********************************************************
    @brief Marks the file as read-only.

    On linux this either revokes all 'w' permissions or restores permissions
    according to the umask.
    ***********************************************************/
    void OCSYNC_EXPORT set_file_read_only (string &filename, bool readonly);

    /***********************************************************
    @brief Marks the file as read-only.

    It's like set_file_read_only (), but weaker : if readonly is false and t
    already has write permissions, no change to the permissions is made.

    This means that it will preserve explicitly set rw-r--r-- permissions even
    when the umask is 0002. (set_file_read_only () would adjust to rw-rw-r--)
    ***********************************************************/
    void OCSYNC_EXPORT set_file_read_only_weak (string &filename, bool readonly);

    /***********************************************************
    @brief Try to set permissions so that other users on the local machine can not
    go into the folder.
    ***********************************************************/
    void OCSYNC_EXPORT set_folder_minimum_permissions (string &filename);

    /***********************************************************
    convert a "normal" windows path into a path that can be 32k chars long.
    ***********************************************************/
    string OCSYNC_EXPORT long_win_path (string &inpath);

    /***********************************************************
    @brief Checks whether a file exists.

    Use this over QFileInfo.exists () and QFile.exists () to avoid bugs with lnk
    files, see above.
    ***********************************************************/
    bool OCSYNC_EXPORT file_exists (string &filename, QFileInfo & = QFileInfo ());

    /***********************************************************
    @brief Rename the file \a origin_file_name to \a destination_file_name.

    It behaves as QFile.rename () but handles .lnk files correctly on Windows.
    ***********************************************************/
    bool OCSYNC_EXPORT rename (string &origin_file_name,
        const string &destination_file_name,
        string *error_string = nullptr);

    /***********************************************************
    Rename the file \a origin_file_name to \a destination_file_name, and
    overwrite the destination if it already exists - without extra checks.
    ***********************************************************/
    bool OCSYNC_EXPORT unchecked_rename_replace (string &origin_file_name,
        const string &destination_file_name,
        string *error_string);

    /***********************************************************
    Removes a file.

    Equivalent to QFile.remove (), except on Windows, where it will also
    successfully remove read-only files.
    ***********************************************************/
    bool OCSYNC_EXPORT remove (string &file_name, string *error_string = nullptr);

    /***********************************************************
    Move the specified file or folder to the trash. (Only implemented on linux)
    ***********************************************************/
    bool OCSYNC_EXPORT move_to_trash (string &filename, string *error_string);

    /***********************************************************
    Replacement for QFile.open (Read_only) followed by a seek ().
    This version sets a more permissive sharing mode on Windows.

    Warning : The resulting file may have an empty file_name and be unsuitable for use
    with QFileInfo! Calling seek () on the QFile with >32bit signed values will fail!
    ***********************************************************/
    bool OCSYNC_EXPORT open_and_seek_file_shared_read (QFile *file, string *error, int64 seek);

    /***********************************************************
    Returns true when a file is locked. (Windows only)
    ***********************************************************/
    bool OCSYNC_EXPORT is_file_locked (string &file_name);

    /***********************************************************
    Returns whether the file is a shortcut file (ends with .lnk)
    ***********************************************************/
    bool OCSYNC_EXPORT is_lnk_file (string &filename);

    /***********************************************************
    Returns whether the file is an exclude file (contains patterns to exclude from sync)
    ***********************************************************/
    bool OCSYNC_EXPORT is_exclude_file (string &filename);

    /***********************************************************
    Returns whether the file is a junction (windows only)
    ***********************************************************/
    bool OCSYNC_EXPORT is_junction (string &filename);
}





    string FileSystem.long_win_path (string &inpath) {
        return inpath;
    }

    void FileSystem.set_file_hidden (string &filename, bool hidden) {
    #ifdef _WIN32
        string f_name = long_win_path (filename);
        DWORD dw_attrs;

        dw_attrs = Get_file_attributes_w ( (wchar_t *)f_name.utf16 ());

        if (dw_attrs != INVALID_FILE_ATTRIBUTES) {
            if (hidden && ! (dw_attrs & FILE_ATTRIBUTE_HIDDEN)) {
                Set_file_attributes_w ( (wchar_t *)f_name.utf16 (), dw_attrs | FILE_ATTRIBUTE_HIDDEN);
            } else if (!hidden && (dw_attrs & FILE_ATTRIBUTE_HIDDEN)) {
                Set_file_attributes_w ( (wchar_t *)f_name.utf16 (), dw_attrs & ~FILE_ATTRIBUTE_HIDDEN);
            }
        }
    #else
        Q_UNUSED (filename);
        Q_UNUSED (hidden);
    #endif
    }

    static QFile.Permissions get_default_write_permissions () {
        QFile.Permissions result = QFile.Write_user;
        mode_t mask = umask (0);
        umask (mask);
        if (! (mask & S_IWGRP)) {
            result |= QFile.Write_group;
        }
        if (! (mask & S_IWOTH)) {
            result |= QFile.Write_other;
        }
        return result;
    }

    void FileSystem.set_file_read_only (string &filename, bool readonly) {
        QFile file (filename);
        QFile.Permissions permissions = file.permissions ();

        QFile.Permissions all_write_permissions =
            QFile.Write_user | QFile.Write_group | QFile.Write_other | QFile.Write_owner;
        static QFile.Permissions default_write_permissions = get_default_write_permissions ();

        permissions &= ~all_write_permissions;
        if (!readonly) {
            permissions |= default_write_permissions;
        }
        file.set_permissions (permissions);
    }

    void FileSystem.set_folder_minimum_permissions (string &filename) {
        Q_UNUSED (filename);
    }

    void FileSystem.set_file_read_only_weak (string &filename, bool readonly) {
        QFile file (filename);
        QFile.Permissions permissions = file.permissions ();

        if (!readonly && (permissions & QFile.Write_owner)) {
            return; // already writable enough
        }

        set_file_read_only (filename, readonly);
    }

    bool FileSystem.rename (string &origin_file_name,
        const string &destination_file_name,
        string *error_string) {
        bool success = false;
        string error;

        QFile orig (origin_file_name);
        success = orig.rename (destination_file_name);
        if (!success) {
            error = orig.error_string ();
        }

        if (!success) {
            q_c_warning (lc_file_system) << "Error renaming file" << origin_file_name
                                    << "to" << destination_file_name
                                    << "failed : " << error;
            if (error_string) {
                *error_string = error;
            }
        }
        return success;
    }

    bool FileSystem.unchecked_rename_replace (string &origin_file_name,
        const string &destination_file_name,
        string *error_string) {

        bool success = false;
        QFile orig (origin_file_name);
        // We want a rename that also overwites.  QFile.rename does not overwite.
        // Qt 5.1 has QSave_file.rename_overwrite we could use.
        // ### FIXME
        success = true;
        bool dest_exists = file_exists (destination_file_name);
        if (dest_exists && !QFile.remove (destination_file_name)) {
            *error_string = orig.error_string ();
            q_c_warning (lc_file_system) << "Target file could not be removed.";
            success = false;
        }
        if (success) {
            success = orig.rename (destination_file_name);
        }
        if (!success) {
            *error_string = orig.error_string ();
            q_c_warning (lc_file_system) << "Renaming temp file to final failed : " << *error_string;
            return false;
        }

        return true;
    }

    bool FileSystem.open_and_seek_file_shared_read (QFile *file, string *error_or_null, int64 seek) {
        string error_dummy;
        // avoid many if (error_or_null) later.
        string &error = error_or_null ? *error_or_null : error_dummy;
        error.clear ();

        if (!file.open (QFile.Read_only)) {
            error = file.error_string ();
            return false;
        }
        if (!file.seek (seek)) {
            error = file.error_string ();
            return false;
        }
        return true;
    }

    bool FileSystem.file_exists (string &filename, QFileInfo &file_info) {
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

    bool FileSystem.remove (string &file_name, string *error_string) {
        QFile f (file_name);
        if (!f.remove ()) {
            if (error_string) {
                *error_string = f.error_string ();
            }
            return false;
        }
        return true;
    }

    bool FileSystem.move_to_trash (string &file_name, string *error_string) {
        // TODO : Qt 5.15 bool QFile.move_to_trash ()
        string trash_path, trash_file_path, trash_info_path;
        string xdg_data_home = QFile.decode_name (qgetenv ("XDG_DATA_HOME"));
        if (xdg_data_home.is_empty ()) {
            trash_path = QDir.home_path () + QStringLiteral ("/.local/share/Trash/"); // trash path that should exist
        } else {
            trash_path = xdg_data_home + QStringLiteral ("/Trash/");
        }

        trash_file_path = trash_path + QStringLiteral ("files/"); // trash file path contain delete files
        trash_info_path = trash_path + QStringLiteral ("info/"); // trash info path contain delete files information

        if (! (QDir ().mkpath (trash_file_path) && QDir ().mkpath (trash_info_path))) {
            *error_string = QCoreApplication.translate ("FileSystem", "Could not make directories in trash");
            return false; //mkpath will return true if path exists
        }

        QFileInfo f (file_name);

        QDir file;
        int suffix_number = 1;
        if (file.exists (trash_file_path + f.file_name ())) { //file in trash already exists, move to "filename.1"
            string path = trash_file_path + f.file_name () + QLatin1Char ('.');
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
        QFile info_file;
        if (file.exists (trash_info_path + f.file_name () + QStringLiteral (".trashinfo"))) { //Trash_info file already exists, create "filename.1.trashinfo"
            string filename = trash_info_path + f.file_name () + QLatin1Char ('.') + string.number (suffix_number) + QStringLiteral (".trashinfo");
            info_file.set_file_name (filename); //filename+.trashinfo //  create file information file in /.local/share/Trash/info/ folder
        } else {
            string filename = trash_info_path + f.file_name () + QStringLiteral (".trashinfo");
            info_file.set_file_name (filename); //filename+.trashinfo //  create file information file in /.local/share/Trash/info/ folder
        }

        info_file.open (QIODevice.ReadWrite);

        QTextStream stream (&info_file); // for write data on open file

        stream << "[Trash Info]\n"
               << "Path="
               << QUrl.to_percent_encoding (f.absolute_file_path (), "~_-./")
               << "\n"
               << "Deletion_date="
               << QDateTime.current_date_time ().to_string (Qt.ISODate)
               << '\n';
        info_file.close ();

        // create info file format of trash file----- END

        return true;
    }

    bool FileSystem.is_file_locked (string &file_name) {
        Q_UNUSED (file_name);
        return false;
    }

    bool FileSystem.is_lnk_file (string &filename) {
        return filename.ends_with (QLatin1String (".lnk"));
    }

    bool FileSystem.is_exclude_file (string &filename) {
        return filename.compare (QStringLiteral (".sync-exclude.lst"), Qt.CaseInsensitive) == 0
            || filename.compare (QStringLiteral ("exclude.lst"), Qt.CaseInsensitive) == 0
            || filename.ends_with (QStringLiteral ("/.sync-exclude.lst"), Qt.CaseInsensitive)
            || filename.ends_with (QStringLiteral ("/exclude.lst"), Qt.CaseInsensitive);
    }

    bool FileSystem.is_junction (string &filename) {
        Q_UNUSED (filename);
        return false;
    }

    } // namespace Occ
    