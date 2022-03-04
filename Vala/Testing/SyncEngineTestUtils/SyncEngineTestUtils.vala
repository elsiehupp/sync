/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QDir>
//  #include <QtTest>
//  #include <cstring>
//  #include <memory>

//  #include <cookiejar.h>
//  #include <QTimer>

namespace Testing {

/***********************************************************
TODO: In theory we should use QVERIFY instead of Q_ASSERT for testing, but this
only works when directly called from a QTest :- (
***********************************************************/

const GLib.Uri sRootUrl ("owncloud://somehost/owncloud/remote.php/dav/");
const GLib.Uri sRootUrl2 ("owncloud://somehost/owncloud/remote.php/dav/files/admin/");
const GLib.Uri sUploadUrl ("owncloud://somehost/owncloud/remote.php/dav/uploads/admin/");

inline string getFilePathFromUrl (GLib.Uri url) {
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

inline void addFiles (string[] dest, FileInfo fi) {
    if (fi.isDir) {
        dest += string ("%1 - directory").arg (fi.path ());
        foreach (FileInfo fi, fi.children)
            addFiles (dest, fi);
    } else {
        dest += string ("%1 - %2 %3-bytes").arg (fi.path ()).arg (fi.size).arg (fi.content_char);
    }
}

inline string toStringNoElide (FileInfo fi) {
    string[] files;
    foreach (FileInfo fi, fi.children)
        addFiles (files, fi);
    files.sort ();
    return string ("FileInfo with %1 files (\n\t%2\n)").arg (files.size ()).arg (files.join ("\n\t"));
}

inline char toString (FileInfo fi) {
    return QTest.toString (toStringNoElide (fi));
}

inline void addFilesDbData (string[] dest, FileInfo fi) {
    // could include etag, permissions etc, but would need extra work
    if (fi.isDir) {
        dest += string ("%1 - %2 %3 %4").arg (
            fi.name,
            fi.isDir ? "directory" : "file",
            string.number (fi.lastModified.toSecsSinceEpoch ()),
            fi.file_identifier);
        foreach (FileInfo fi, fi.children)
            addFilesDbData (dest, fi);
    } else {
        dest += string ("%1 - %2 %3 %4 %5").arg (
            fi.name,
            fi.isDir ? "directory" : "file",
            string.number (fi.size),
            string.number (fi.lastModified.toSecsSinceEpoch ()),
            fi.file_identifier);
    }
}

inline char printDbData (FileInfo fi) {
    string[] files;
    foreach (FileInfo fi, fi.children)
        addFilesDbData (files, fi);
    return QTest.toString (string ("FileInfo with %1 files (%2)").arg (files.size ()).arg (files.join (", ")));
}










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

