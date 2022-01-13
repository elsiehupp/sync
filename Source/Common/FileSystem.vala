/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <string>
// #include <ctime>
// #include <QFileInfo>
// #include <QLoggingCategory>

// #include <ocsynclib.h>


namespace Occ {

OCSYNC_EXPORT Q_DECLARE_LOGGING_CATEGORY (lcFileSystem)

/***********************************************************
 \addtogroup libsync
 @{
***********************************************************/

/***********************************************************
@brief This file contains file system helper
***********************************************************/
namespace FileSystem {

    /***********************************************************
     * @brief Mark the file as hidden  (only has effects on windows)
     */
    void OCSYNC_EXPORT setFileHidden (string &filename, bool hidden);

    /***********************************************************
     * @brief Marks the file as read-only.
     *
     * On linux this either revokes all 'w' permissions or restores permissions
     * according to the umask.
     */
    void OCSYNC_EXPORT setFileReadOnly (string &filename, bool readonly);

    /***********************************************************
     * @brief Marks the file as read-only.
     *
     * It's like setFileReadOnly (), but weaker : if readonly is false and the user
     * already has write permissions, no change to the permissions is made.
     *
     * This means that it will preserve explicitly set rw-r--r-- permissions even
     * when the umask is 0002. (setFileReadOnly () would adjust to rw-rw-r--)
     */
    void OCSYNC_EXPORT setFileReadOnlyWeak (string &filename, bool readonly);

    /***********************************************************
     * @brief Try to set permissions so that other users on the local machine can not
     * go into the folder.
     */
    void OCSYNC_EXPORT setFolderMinimumPermissions (string &filename);

    /** convert a "normal" windows path into a path that can be 32k chars long. */
    string OCSYNC_EXPORT longWinPath (string &inpath);

    /***********************************************************
     * @brief Checks whether a file exists.
     *
     * Use this over QFileInfo.exists () and QFile.exists () to avoid bugs with lnk
     * files, see above.
     */
    bool OCSYNC_EXPORT fileExists (string &filename, QFileInfo & = QFileInfo ());

    /***********************************************************
     * @brief Rename the file \a originFileName to \a destinationFileName.
     *
     * It behaves as QFile.rename () but handles .lnk files correctly on Windows.
     */
    bool OCSYNC_EXPORT rename (string &originFileName,
        const string &destinationFileName,
        string *errorString = nullptr);

    /***********************************************************
     * Rename the file \a originFileName to \a destinationFileName, and
     * overwrite the destination if it already exists - without extra checks.
     */
    bool OCSYNC_EXPORT uncheckedRenameReplace (string &originFileName,
        const string &destinationFileName,
        string *errorString);

    /***********************************************************
     * Removes a file.
     *
     * Equivalent to QFile.remove (), except on Windows, where it will also
     * successfully remove read-only files.
     */
    bool OCSYNC_EXPORT remove (string &fileName, string *errorString = nullptr);

    /***********************************************************
     * Move the specified file or folder to the trash. (Only implemented on linux)
     */
    bool OCSYNC_EXPORT moveToTrash (string &filename, string *errorString);

    /***********************************************************
     * Replacement for QFile.open (ReadOnly) followed by a seek ().
     * This version sets a more permissive sharing mode on Windows.
     *
     * Warning : The resulting file may have an empty fileName and be unsuitable for use
     * with QFileInfo! Calling seek () on the QFile with >32bit signed values will fail!
     */
    bool OCSYNC_EXPORT openAndSeekFileSharedRead (QFile *file, string *error, int64 seek);

    /***********************************************************
     * Returns true when a file is locked. (Windows only)
     */
    bool OCSYNC_EXPORT isFileLocked (string &fileName);

    /***********************************************************
     * Returns whether the file is a shortcut file (ends with .lnk)
     */
    bool OCSYNC_EXPORT isLnkFile (string &filename);

    /***********************************************************
     * Returns whether the file is an exclude file (contains patterns to exclude from sync)
     */
    bool OCSYNC_EXPORT isExcludeFile (string &filename);

    /***********************************************************
     * Returns whether the file is a junction (windows only)
     */
    bool OCSYNC_EXPORT isJunction (string &filename);
}

/** @} */
}



/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <QDateTime>
// #include <QDir>
// #include <QUrl>
// #include <QFile>
// #include <QCoreApplication>

// #include <sys/stat.h>
// #include <sys/types.h>

namespace Occ {

    Q_LOGGING_CATEGORY (lcFileSystem, "nextcloud.sync.filesystem", QtInfoMsg)
    
    string FileSystem.longWinPath (string &inpath) {
        return inpath;
    }
    
    void FileSystem.setFileHidden (string &filename, bool hidden) {
    #ifdef _WIN32
        string fName = longWinPath (filename);
        DWORD dwAttrs;
    
        dwAttrs = GetFileAttributesW ( (wchar_t *)fName.utf16 ());
    
        if (dwAttrs != INVALID_FILE_ATTRIBUTES) {
            if (hidden && ! (dwAttrs & FILE_ATTRIBUTE_HIDDEN)) {
                SetFileAttributesW ( (wchar_t *)fName.utf16 (), dwAttrs | FILE_ATTRIBUTE_HIDDEN);
            } else if (!hidden && (dwAttrs & FILE_ATTRIBUTE_HIDDEN)) {
                SetFileAttributesW ( (wchar_t *)fName.utf16 (), dwAttrs & ~FILE_ATTRIBUTE_HIDDEN);
            }
        }
    #else
        Q_UNUSED (filename);
        Q_UNUSED (hidden);
    #endif
    }
    
    static QFile.Permissions getDefaultWritePermissions () {
        QFile.Permissions result = QFile.WriteUser;
        mode_t mask = umask (0);
        umask (mask);
        if (! (mask & S_IWGRP)) {
            result |= QFile.WriteGroup;
        }
        if (! (mask & S_IWOTH)) {
            result |= QFile.WriteOther;
        }
        return result;
    }
    
    void FileSystem.setFileReadOnly (string &filename, bool readonly) {
        QFile file (filename);
        QFile.Permissions permissions = file.permissions ();
    
        QFile.Permissions allWritePermissions =
            QFile.WriteUser | QFile.WriteGroup | QFile.WriteOther | QFile.WriteOwner;
        static QFile.Permissions defaultWritePermissions = getDefaultWritePermissions ();
    
        permissions &= ~allWritePermissions;
        if (!readonly) {
            permissions |= defaultWritePermissions;
        }
        file.setPermissions (permissions);
    }
    
    void FileSystem.setFolderMinimumPermissions (string &filename) {
        Q_UNUSED (filename);
    }
    
    void FileSystem.setFileReadOnlyWeak (string &filename, bool readonly) {
        QFile file (filename);
        QFile.Permissions permissions = file.permissions ();
    
        if (!readonly && (permissions & QFile.WriteOwner)) {
            return; // already writable enough
        }
    
        setFileReadOnly (filename, readonly);
    }
    
    bool FileSystem.rename (string &originFileName,
        const string &destinationFileName,
        string *errorString) {
        bool success = false;
        string error;
    
        QFile orig (originFileName);
        success = orig.rename (destinationFileName);
        if (!success) {
            error = orig.errorString ();
        }
    
        if (!success) {
            qCWarning (lcFileSystem) << "Error renaming file" << originFileName
                                    << "to" << destinationFileName
                                    << "failed : " << error;
            if (errorString) {
                *errorString = error;
            }
        }
        return success;
    }
    
    bool FileSystem.uncheckedRenameReplace (string &originFileName,
        const string &destinationFileName,
        string *errorString) {
    
        bool success = false;
        QFile orig (originFileName);
        // We want a rename that also overwites.  QFile.rename does not overwite.
        // Qt 5.1 has QSaveFile.renameOverwrite we could use.
        // ### FIXME
        success = true;
        bool destExists = fileExists (destinationFileName);
        if (destExists && !QFile.remove (destinationFileName)) {
            *errorString = orig.errorString ();
            qCWarning (lcFileSystem) << "Target file could not be removed.";
            success = false;
        }
        if (success) {
            success = orig.rename (destinationFileName);
        }
        if (!success) {
            *errorString = orig.errorString ();
            qCWarning (lcFileSystem) << "Renaming temp file to final failed : " << *errorString;
            return false;
        }
    
        return true;
    }
    
    bool FileSystem.openAndSeekFileSharedRead (QFile *file, string *errorOrNull, int64 seek) {
        string errorDummy;
        // avoid many if (errorOrNull) later.
        string &error = errorOrNull ? *errorOrNull : errorDummy;
        error.clear ();
    
        if (!file.open (QFile.ReadOnly)) {
            error = file.errorString ();
            return false;
        }
        if (!file.seek (seek)) {
            error = file.errorString ();
            return false;
        }
        return true;
    }
    
    bool FileSystem.fileExists (string &filename, QFileInfo &fileInfo) {
        bool re = fileInfo.exists ();
        // if the filename is different from the filename in fileInfo, the fileInfo is
        // not valid. There needs to be one initialised here. Otherwise the incoming
        // fileInfo is re-used.
        if (fileInfo.filePath () != filename) {
            QFileInfo myFI (filename);
            re = myFI.exists ();
        }
        return re;
    }
    
    bool FileSystem.remove (string &fileName, string *errorString) {
        QFile f (fileName);
        if (!f.remove ()) {
            if (errorString) {
                *errorString = f.errorString ();
            }
            return false;
        }
        return true;
    }
    
    bool FileSystem.moveToTrash (string &fileName, string *errorString) {
        // TODO : Qt 5.15 bool QFile.moveToTrash ()
        string trashPath, trashFilePath, trashInfoPath;
        string xdgDataHome = QFile.decodeName (qgetenv ("XDG_DATA_HOME"));
        if (xdgDataHome.isEmpty ()) {
            trashPath = QDir.homePath () + QStringLiteral ("/.local/share/Trash/"); // trash path that should exist
        } else {
            trashPath = xdgDataHome + QStringLiteral ("/Trash/");
        }
    
        trashFilePath = trashPath + QStringLiteral ("files/"); // trash file path contain delete files
        trashInfoPath = trashPath + QStringLiteral ("info/"); // trash info path contain delete files information
    
        if (! (QDir ().mkpath (trashFilePath) && QDir ().mkpath (trashInfoPath))) {
            *errorString = QCoreApplication.translate ("FileSystem", "Could not make directories in trash");
            return false; //mkpath will return true if path exists
        }
    
        QFileInfo f (fileName);
    
        QDir file;
        int suffix_number = 1;
        if (file.exists (trashFilePath + f.fileName ())) { //file in trash already exists, move to "filename.1"
            string path = trashFilePath + f.fileName () + QLatin1Char ('.');
            while (file.exists (path + string.number (suffix_number))) { //or to "filename.2" if "filename.1" exists, etc
                suffix_number++;
            }
            if (!file.rename (f.absoluteFilePath (), path + string.number (suffix_number))) { // rename (file old path, file trash path)
                *errorString = QCoreApplication.translate ("FileSystem", R" (Could not move "%1" to "%2")")
                                   .arg (f.absoluteFilePath (), path + string.number (suffix_number));
                return false;
            }
        } else {
            if (!file.rename (f.absoluteFilePath (), trashFilePath + f.fileName ())) { // rename (file old path, file trash path)
                *errorString = QCoreApplication.translate ("FileSystem", R" (Could not move "%1" to "%2")")
                                   .arg (f.absoluteFilePath (), trashFilePath + f.fileName ());
                return false;
            }
        }
    
        // create file format for trash info file----- START
        QFile infoFile;
        if (file.exists (trashInfoPath + f.fileName () + QStringLiteral (".trashinfo"))) { //TrashInfo file already exists, create "filename.1.trashinfo"
            string filename = trashInfoPath + f.fileName () + QLatin1Char ('.') + string.number (suffix_number) + QStringLiteral (".trashinfo");
            infoFile.setFileName (filename); //filename+.trashinfo //  create file information file in /.local/share/Trash/info/ folder
        } else {
            string filename = trashInfoPath + f.fileName () + QStringLiteral (".trashinfo");
            infoFile.setFileName (filename); //filename+.trashinfo //  create file information file in /.local/share/Trash/info/ folder
        }
    
        infoFile.open (QIODevice.ReadWrite);
    
        QTextStream stream (&infoFile); // for write data on open file
    
        stream << "[Trash Info]\n"
               << "Path="
               << QUrl.toPercentEncoding (f.absoluteFilePath (), "~_-./")
               << "\n"
               << "DeletionDate="
               << QDateTime.currentDateTime ().toString (Qt.ISODate)
               << '\n';
        infoFile.close ();
    
        // create info file format of trash file----- END
    
        return true;
    }
    
    bool FileSystem.isFileLocked (string &fileName) {
        Q_UNUSED (fileName);
        return false;
    }
    
    bool FileSystem.isLnkFile (string &filename) {
        return filename.endsWith (QLatin1String (".lnk"));
    }
    
    bool FileSystem.isExcludeFile (string &filename) {
        return filename.compare (QStringLiteral (".sync-exclude.lst"), Qt.CaseInsensitive) == 0
            || filename.compare (QStringLiteral ("exclude.lst"), Qt.CaseInsensitive) == 0
            || filename.endsWith (QStringLiteral ("/.sync-exclude.lst"), Qt.CaseInsensitive)
            || filename.endsWith (QStringLiteral ("/exclude.lst"), Qt.CaseInsensitive);
    }
    
    bool FileSystem.isJunction (string &filename) {
        Q_UNUSED (filename);
        return false;
    }
    
    } // namespace Occ
    