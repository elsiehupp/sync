/*
 * Copyright (C) by Daniel Molkentin <danimo@owncloud.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

// #include <QDateTime>
// #include <QDir>
// #include <QUrl>
// #include <QFile>
// #include <QCoreApplication>

// #include <sys/stat.h>
// #include <sys/types.h>

namespace OCC {

Q_LOGGING_CATEGORY (lcFileSystem, "nextcloud.sync.filesystem", QtInfoMsg)

QString FileSystem.longWinPath (QString &inpath) {
    return inpath;
}

void FileSystem.setFileHidden (QString &filename, bool hidden) {
#ifdef _WIN32
    QString fName = longWinPath (filename);
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

void FileSystem.setFileReadOnly (QString &filename, bool readonly) {
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

void FileSystem.setFolderMinimumPermissions (QString &filename) {
    Q_UNUSED (filename);
}

void FileSystem.setFileReadOnlyWeak (QString &filename, bool readonly) {
    QFile file (filename);
    QFile.Permissions permissions = file.permissions ();

    if (!readonly && (permissions & QFile.WriteOwner)) {
        return; // already writable enough
    }

    setFileReadOnly (filename, readonly);
}

bool FileSystem.rename (QString &originFileName,
    const QString &destinationFileName,
    QString *errorString) {
    bool success = false;
    QString error;

    QFile orig (originFileName);
    success = orig.rename (destinationFileName);
    if (!success) {
        error = orig.errorString ();
    }

    if (!success) {
        qCWarning (lcFileSystem) << "Error renaming file" << originFileName
                                << "to" << destinationFileName
                                << "failed: " << error;
        if (errorString) {
            *errorString = error;
        }
    }
    return success;
}

bool FileSystem.uncheckedRenameReplace (QString &originFileName,
    const QString &destinationFileName,
    QString *errorString) {

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
        qCWarning (lcFileSystem) << "Renaming temp file to final failed: " << *errorString;
        return false;
    }

    return true;
}

bool FileSystem.openAndSeekFileSharedRead (QFile *file, QString *errorOrNull, int64 seek) {
    QString errorDummy;
    // avoid many if (errorOrNull) later.
    QString &error = errorOrNull ? *errorOrNull : errorDummy;
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

bool FileSystem.fileExists (QString &filename, QFileInfo &fileInfo) {
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

bool FileSystem.remove (QString &fileName, QString *errorString) {
    QFile f (fileName);
    if (!f.remove ()) {
        if (errorString) {
            *errorString = f.errorString ();
        }
        return false;
    }
    return true;
}

bool FileSystem.moveToTrash (QString &fileName, QString *errorString) {
    // TODO: Qt 5.15 bool QFile.moveToTrash ()
    QString trashPath, trashFilePath, trashInfoPath;
    QString xdgDataHome = QFile.decodeName (qgetenv ("XDG_DATA_HOME"));
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
        QString path = trashFilePath + f.fileName () + QLatin1Char ('.');
        while (file.exists (path + QString.number (suffix_number))) { //or to "filename.2" if "filename.1" exists, etc
            suffix_number++;
        }
        if (!file.rename (f.absoluteFilePath (), path + QString.number (suffix_number))) { // rename (file old path, file trash path)
            *errorString = QCoreApplication.translate ("FileSystem", R" (Could not move "%1" to "%2")")
                               .arg (f.absoluteFilePath (), path + QString.number (suffix_number));
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
        QString filename = trashInfoPath + f.fileName () + QLatin1Char ('.') + QString.number (suffix_number) + QStringLiteral (".trashinfo");
        infoFile.setFileName (filename); //filename+.trashinfo //  create file information file in /.local/share/Trash/info/ folder
    } else {
        QString filename = trashInfoPath + f.fileName () + QStringLiteral (".trashinfo");
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

bool FileSystem.isFileLocked (QString &fileName) {
    Q_UNUSED (fileName);
    return false;
}

bool FileSystem.isLnkFile (QString &filename) {
    return filename.endsWith (QLatin1String (".lnk"));
}

bool FileSystem.isExcludeFile (QString &filename) {
    return filename.compare (QStringLiteral (".sync-exclude.lst"), Qt.CaseInsensitive) == 0
        || filename.compare (QStringLiteral ("exclude.lst"), Qt.CaseInsensitive) == 0
        || filename.endsWith (QStringLiteral ("/.sync-exclude.lst"), Qt.CaseInsensitive)
        || filename.endsWith (QStringLiteral ("/exclude.lst"), Qt.CaseInsensitive);
}

bool FileSystem.isJunction (QString &filename) {
    Q_UNUSED (filename);
    return false;
}

} // namespace OCC
