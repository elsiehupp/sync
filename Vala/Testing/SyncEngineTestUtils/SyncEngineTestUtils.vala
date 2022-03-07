/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QJsonDocument>
//  #include <QJsonArray>
//  #include <QJsonObject>
//  #include <QJsonValue>
//  #include <memory>

//  #include <QDir>
//  #include <QtTest>
//  #include <cstring>
//  #include <memory>

//  #include <cookiejar.h>
//  #include <QTimer>

namespace Testing {

/***********************************************************
TODO: In theory we should use QVERIFY instead of Q_ASSERT
for testing, but this only works when directly called from
a QTest :- (
***********************************************************/

const GLib.Uri sRootUrl = "owncloud://somehost/owncloud/remote.php/dav/";
const GLib.Uri sRootUrl2 = "owncloud://somehost/owncloud/remote.php/dav/files/admin/";
const GLib.Uri sUploadUrl = "owncloud://somehost/owncloud/remote.php/dav/uploads/admin/";

inline string get_file_path_from_url (GLib.Uri url) {
    string path = url.path ();
    if (path.startsWith (sRootUrl2.path ()))
        return path.mid (sRootUrl2.path ().length ());
    if (path.startsWith (sUploadUrl.path ()))
        return path.mid (sUploadUrl.path ().length ());
    if (path.startsWith (sRootUrl.path ()))
        return path.mid (sRootUrl.path ().length ());
    return {};
}

inline GLib.ByteArray generateEtag () {
    return GLib.ByteArray.number (GLib.DateTime.currentDateTimeUtc ().toMSecsSinceEpoch (), 16) + GLib.ByteArray.number (Occ.Utility.rand (), 16);
}
inline GLib.ByteArray generateFileId () {
    return GLib.ByteArray.number (Occ.Utility.rand (), 16);
}

// QTest.toString overloads
namespace Occ {
    inline char toString (SyncFileStatus s) {
        return QTest.toString (string ("SyncFileStatus (" + s.toSocketAPIString () + ")"));
    }
}

inline void addFiles (string[] dest, FileInfo file_info) {
    if (file_info.isDir) {
        dest += "%1 - directory".arg (file_info.path ());
        foreach (FileInfo file_info in file_info.children) {
            addFiles (dest, file_info);
        }
    } else {
        dest += "%1 - %2 %3-bytes".arg (file_info.path ()).arg (file_info.size).arg (file_info.content_char);
    }
}

inline string toStringNoElide (FileInfo file_info) {
    string[] files;
    foreach (FileInfo file_info in file_info.children) {
        addFiles (files, file_info);
    }
    files.sort ();
    return "FileInfo with %1 files (\n\t%2\n)".arg (files.size ()).arg (files.join ("\n\t"));
}

inline char toString (FileInfo file_info) {
    return QTest.toString (toStringNoElide (file_info));
}

inline void addFilesDbData (string[] dest, FileInfo file_info) {
    // could include etag, permissions etc, but would need extra work
    if (file_info.isDir) {
        dest += string ("%1 - %2 %3 %4").arg (
            file_info.name,
            file_info.isDir ? "directory" : "file",
            string.number (file_info.lastModified.toSecsSinceEpoch ()),
            file_info.file_identifier);
        foreach (FileInfo file_info, file_info.children)
            addFilesDbData (dest, file_info);
    } else {
        dest += string ("%1 - %2 %3 %4 %5").arg (
            file_info.name,
            file_info.isDir ? "directory" : "file",
            string.number (file_info.size),
            string.number (file_info.lastModified.toSecsSinceEpoch ()),
            file_info.file_identifier);
    }
}

inline char printDbData (FileInfo file_info) {
    string[] files;
    foreach (FileInfo file_info, file_info.children)
        addFilesDbData (files, file_info);
    return QTest.toString (string ("FileInfo with %1 files (%2)").arg (files.size ()).arg (files.join (", ")));
}

}
}
