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
class SyncEngineTestUtils {

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

    // QTest.to_string overloads
    //  namespace Occ {
    inline char sync_file_status_to_string (SyncFileStatus status) {
        return QTest.to_string ("SyncFileStatus (" + status.toSocketAPIString () + ")");
    }
    //  }

    inline char file_info_to_string (FileInfo file_info) {
        return QTest.to_string (to_string_no_elide (file_info));
    }

    inline void add_files (string[] dest, FileInfo file_info) {
        if (file_info.isDir) {
            dest += "%1 - directory".arg (file_info.path ());
            foreach (FileInfo file_info in file_info.children) {
                add_files (dest, file_info);
            }
        } else {
            dest += "%1 - %2 %3-bytes".arg (file_info.path ()).arg (file_info.size).arg (file_info.content_char);
        }
    }

    inline string to_string_no_elide (FileInfo file_info) {
        string[] files;
        foreach (FileInfo file_info in file_info.children) {
            add_files (files, file_info);
        }
        files.sort ();
        return "FileInfo with %1 files (\n\t%2\n)".arg (files.size ()).arg (files.join ("\n\t"));
    }

    inline void add_files_database_data (string[] dest, FileInfo file_info) {
        // could include etag, permissions etc, but would need extra work
        if (file_info.isDir) {
            dest += "%1 - %2 %3 %4".arg (
                file_info.name,
                file_info.isDir ? "directory" : "file",
                string.number (file_info.last_modified.to_seconds_since_epoch ()),
                file_info.file_identifier);
            foreach (FileInfo file_info in file_info.children) {
                add_files_database_data (dest, file_info);
            }
        } else {
            dest += "%1 - %2 %3 %4 %5".arg (
                file_info.name,
                file_info.isDir ? "directory" : "file",
                string.number (file_info.size),
                string.number (file_info.last_modified.to_seconds_since_epoch ()),
                file_info.file_identifier);
        }
    }

    inline char printDbData (FileInfo file_info) {
        string[] files;
        foreach (FileInfo file_info in file_info.children) {
            add_files_database_data (files, file_info);
        }
        return QTest.to_string ("FileInfo with %1 files (%2)".arg (files.size ()).arg (files.join (", ")));
    }

} // class SyncEngineTestUtils
} // namespace Testing
