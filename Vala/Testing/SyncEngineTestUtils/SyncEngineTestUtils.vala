/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
//  #pragma once

//  #include <QDir>
//  #include <QtTest>
//  #include <cstring>
//  #include <memory>

//  #include <cookiejar.h>
//  #include <QTimer>


/***********************************************************
TODO : In theory we should use QVERIFY instead of Q_ASSERT for testing, but this
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
        dest += string ("%1 - dir").arg (fi.path ());
        foreach (FileInfo fi, fi.children)
            addFiles (dest, fi);
    } else {
        dest += string ("%1 - %2 %3-bytes").arg (fi.path ()).arg (fi.size).arg (fi.contentChar);
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
            fi.isDir ? "dir" : "file",
            string.number (fi.lastModified.toSecsSinceEpoch ()),
            fi.fileId);
        foreach (FileInfo fi, fi.children)
            addFilesDbData (dest, fi);
    } else {
        dest += string ("%1 - %2 %3 %4 %5").arg (
            fi.name,
            fi.isDir ? "dir" : "file",
            string.number (fi.size),
            string.number (fi.lastModified.toSecsSinceEpoch ()),
            fi.fileId);
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

PathComponents.PathComponents (char path)
    : PathComponents { string.fromUtf8 (path) } {
}

PathComponents.PathComponents (string path)
    : string[] { path.split ('/', Qt.SkipEmptyParts) } {
}

PathComponents.PathComponents (string[] pathComponents)
    : string[] { pathComponents } {
}

PathComponents PathComponents.parentDirComponents () {
    return PathComponents { mid (0, size () - 1) };
}

PathComponents PathComponents.subComponents () & {
    return PathComponents { mid (1) };
}

void DiskFileModifier.remove (string relativePath) {
    QFileInfo fi { this.rootDir.filePath (relativePath) };
    if (fi.isFile ())
        QVERIFY (this.rootDir.remove (relativePath));
    else
        QVERIFY (QDir { fi.filePath () }.removeRecursively ());
}

void DiskFileModifier.insert (string relativePath, int64 size, char contentChar) {
    GLib.File file { this.rootDir.filePath (relativePath) };
    QVERIFY (!file.exists ());
    file.open (GLib.File.WriteOnly);
    GLib.ByteArray buf (1024, contentChar);
    for (int x = 0; x < size / buf.size (); ++x) {
        file.write (buf);
    }
    file.write (buf.data (), size % buf.size ());
    file.close ();
    // Set the mtime 30 seconds in the past, for some tests that need to make sure that the mtime differs.
    Occ.FileSystem.setModTime (file.fileName (), Occ.Utility.qDateTimeToTime_t (GLib.DateTime.currentDateTimeUtc ().addSecs (-30)));
    QCOMPARE (file.size (), size);
}

void DiskFileModifier.setContents (string relativePath, char contentChar) {
    GLib.File file { this.rootDir.filePath (relativePath) };
    QVERIFY (file.exists ());
    int64 size = file.size ();
    file.open (GLib.File.WriteOnly);
    file.write (GLib.ByteArray {}.fill (contentChar, size));
}

void DiskFileModifier.appendByte (string relativePath) {
    GLib.File file { this.rootDir.filePath (relativePath) };
    QVERIFY (file.exists ());
    file.open (GLib.File.ReadWrite);
    GLib.ByteArray contents = file.read (1);
    file.seek (file.size ());
    file.write (contents);
}

void DiskFileModifier.mkdir (string relativePath) {
    this.rootDir.mkpath (relativePath);
}

void DiskFileModifier.rename (string from, string to) {
    QVERIFY (this.rootDir.exists (from));
    QVERIFY (this.rootDir.rename (from, to));
}

void DiskFileModifier.setModTime (string relativePath, GLib.DateTime modTime) {
    Occ.FileSystem.setModTime (this.rootDir.filePath (relativePath), Occ.Utility.qDateTimeToTime_t (modTime));
}

FileInfo FileInfo.A12_B12_C12_S12 () { { { QStringLiteral ("A"), { { QStringLiteral ("a1"), 4 }, { QStringLiteral ("a2"), 4 } } }, { QStringLiteral ("B"), { { QStringLiteral ("b1"), 16 }, { QStringLiteral ("b2"), 16 } } },
                                  { QStringLiteral ("C"), { { QStringLiteral ("c1"), 24 }, { QStringLiteral ("c2"), 24 } } },
                              } };
    FileInfo sharedFolder { QStringLiteral ("S"), { { QStringLiteral ("s1"), 32 }, { QStringLiteral ("s2"), 32 } } };
    sharedFolder.isShared = true;
    sharedFolder.children[QStringLiteral ("s1")].isShared = true;
    sharedFolder.children[QStringLiteral ("s2")].isShared = true;
    fi.children.insert (sharedFolder.name, std.move (sharedFolder));
    return fi;
}

FileInfo.FileInfo (string name, std.initializer_list<FileInfo> children)
    : name { name } {
    for (var source : children)
        addChild (source);
}

void FileInfo.addChild (FileInfo info) {
    var dest = this.children[info.name] = info;
    dest.parentPath = path ();
    dest.fixupParentPathRecursively ();
}

void FileInfo.remove (string relativePath) {
    const PathComponents pathComponents { relativePath };
    FileInfo parent = findInvalidatingEtags (pathComponents.parentDirComponents ());
    //  Q_ASSERT (parent);
    parent.children.erase (std.find_if (parent.children.begin (), parent.children.end (),
        [&pathComponents] (FileInfo fi) { return fi.name == pathComponents.fileName (); }));
}

void FileInfo.insert (string relativePath, int64 size, char contentChar) {
    create (relativePath, size, contentChar);
}

void FileInfo.setContents (string relativePath, char contentChar) {
    FileInfo file = findInvalidatingEtags (relativePath);
    //  Q_ASSERT (file);
    file.contentChar = contentChar;
}

void FileInfo.appendByte (string relativePath) {
    FileInfo file = findInvalidatingEtags (relativePath);
    //  Q_ASSERT (file);
    file.size += 1;
}

void FileInfo.mkdir (string relativePath) {
    createDir (relativePath);
}

void FileInfo.rename (string oldPath, string newPath) {
    const PathComponents newPathComponents { newPath };
    FileInfo dir = findInvalidatingEtags (newPathComponents.parentDirComponents ());
    //  Q_ASSERT (dir);
    //  Q_ASSERT (dir.isDir);
    const PathComponents pathComponents { oldPath };
    FileInfo parent = findInvalidatingEtags (pathComponents.parentDirComponents ());
    //  Q_ASSERT (parent);
    FileInfo fi = parent.children.take (pathComponents.fileName ());
    fi.parentPath = dir.path ();
    fi.name = newPathComponents.fileName ();
    fi.fixupParentPathRecursively ();
    dir.children.insert (newPathComponents.fileName (), std.move (fi));
}

void FileInfo.setModTime (string relativePath, GLib.DateTime modTime) {
    FileInfo file = findInvalidatingEtags (relativePath);
    //  Q_ASSERT (file);
    file.lastModified = modTime;
}

FileInfo *FileInfo.find (PathComponents pathComponents, bool invalidateEtags) {
    if (pathComponents.isEmpty ()) {
        if (invalidateEtags) {
            etag = generateEtag ();
        }
        return this;
    }
    string childName = pathComponents.pathRoot ();
    var it = children.find (childName);
    if (it != children.end ()) {
        var file = it.find (std.move (pathComponents).subComponents (), invalidateEtags);
        if (file && invalidateEtags) {
            // Update parents on the way back
            etag = generateEtag ();
        }
        return file;
    }
    return null;
}

FileInfo *FileInfo.createDir (string relativePath) {
    const PathComponents pathComponents { relativePath };
    FileInfo parent = findInvalidatingEtags (pathComponents.parentDirComponents ());
    //  Q_ASSERT (parent);
    FileInfo child = parent.children[pathComponents.fileName ()] = FileInfo { pathComponents.fileName () };
    child.parentPath = parent.path ();
    child.etag = generateEtag ();
    return child;
}

FileInfo *FileInfo.create (string relativePath, int64 size, char contentChar) {
    const PathComponents pathComponents { relativePath };
    FileInfo parent = findInvalidatingEtags (pathComponents.parentDirComponents ());
    //  Q_ASSERT (parent);
    FileInfo child = parent.children[pathComponents.fileName ()] = FileInfo { pathComponents.fileName (), size };
    child.parentPath = parent.path ();
    child.contentChar = contentChar;
    child.etag = generateEtag ();
    return child;
}

bool FileInfo.operator== (FileInfo other) {
    // Consider files to be equal between local<.remote as a user would.
    return name == other.name
        && isDir == other.isDir
        && size == other.size
        && contentChar == other.contentChar
        && children == other.children;
}

string FileInfo.path () {
    return (parentPath.isEmpty () ? "" : (parentPath + '/')) + name;
}

string FileInfo.absolutePath () {
    if (parentPath.endsWith ('/')) {
        return parentPath + name;
    } else {
        return parentPath + '/' + name;
    }
}

void FileInfo.fixupParentPathRecursively () {
    var p = path ();
    for (var it = children.begin (); it != children.end (); ++it) {
        //  Q_ASSERT (it.key () == it.name);
        it.parentPath = p;
        it.fixupParentPathRecursively ();
    }
}

FileInfo *FileInfo.findInvalidatingEtags (PathComponents pathComponents) {
    return find (std.move (pathComponents), true);
}

FakePropfindReply.FakePropfindReply (FileInfo remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.Object parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);

    string fileName = getFilePathFromUrl (request.url ());
    //  Q_ASSERT (!fileName.isNull ()); // for root, it should be empty
    const FileInfo fileInfo = remoteRootFileInfo.find (fileName);
    if (!fileInfo) {
        QMetaObject.invokeMethod (this, "respond404", Qt.QueuedConnection);
        return;
    }
    const string prefix = request.url ().path ().left (request.url ().path ().size () - fileName.size ());

    // Don't care about the request and just return a full propfind
    const string davUri { QStringLiteral ("DAV:") };
    const string ocUri { QStringLiteral ("http://owncloud.org/ns") };
    QBuffer buffer { payload };
    buffer.open (QIODevice.WriteOnly);
    QXmlStreamWriter xml (&buffer);
    xml.writeNamespace (davUri, QStringLiteral ("d"));
    xml.writeNamespace (ocUri, QStringLiteral ("oc"));
    xml.writeStartDocument ();
    xml.writeStartElement (davUri, QStringLiteral ("multistatus"));
    var writeFileResponse = [&] (FileInfo fileInfo) {
        xml.writeStartElement (davUri, QStringLiteral ("response"));

        var url = string.fromUtf8 (GLib.Uri.toPercentEncoding (fileInfo.absolutePath (), "/"));
        if (!url.endsWith (char ('/'))) {
            url.append (char ('/'));
        }
        const var href = Occ.Utility.concatUrlPath (prefix, url).path ();
        xml.writeTextElement (davUri, QStringLiteral ("href"), href);
        xml.writeStartElement (davUri, QStringLiteral ("propstat"));
        xml.writeStartElement (davUri, QStringLiteral ("prop"));

        if (fileInfo.isDir) {
            xml.writeStartElement (davUri, QStringLiteral ("resourcetype"));
            xml.writeEmptyElement (davUri, QStringLiteral ("collection"));
            xml.writeEndElement (); // resourcetype
        } else
            xml.writeEmptyElement (davUri, QStringLiteral ("resourcetype"));

        var gmtDate = fileInfo.lastModified.toUTC ();
        var stringDate = QLocale.c ().toString (gmtDate, QStringLiteral ("ddd, dd MMM yyyy HH:mm:ss 'GMT'"));
        xml.writeTextElement (davUri, QStringLiteral ("getlastmodified"), stringDate);
        xml.writeTextElement (davUri, QStringLiteral ("getcontentlength"), string.number (fileInfo.size));
        xml.writeTextElement (davUri, QStringLiteral ("getetag"), QStringLiteral ("\"%1\"").arg (string.fromLatin1 (fileInfo.etag)));
        xml.writeTextElement (ocUri, QStringLiteral ("permissions"), !fileInfo.permissions.isNull () ? string (fileInfo.permissions.toString ()) : fileInfo.isShared ? QStringLiteral ("SRDNVCKW") : QStringLiteral ("RDNVCKW"));
        xml.writeTextElement (ocUri, QStringLiteral ("identifier"), string.fromUtf8 (fileInfo.fileId));
        xml.writeTextElement (ocUri, QStringLiteral ("checksums"), string.fromUtf8 (fileInfo.checksums));
        buffer.write (fileInfo.extraDavProperties);
        xml.writeEndElement (); // prop
        xml.writeTextElement (davUri, QStringLiteral ("status"), QStringLiteral ("HTTP/1.1 200 OK"));
        xml.writeEndElement (); // propstat
        xml.writeEndElement (); // response
    };

    writeFileResponse (*fileInfo);
    foreach (FileInfo childFileInfo, fileInfo.children)
        writeFileResponse (childFileInfo);
    xml.writeEndElement (); // multistatus
    xml.writeEndDocument ();

    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
}

void FakePropfindReply.respond () {
    setHeader (QNetworkRequest.ContentLengthHeader, payload.size ());
    setHeader (QNetworkRequest.ContentTypeHeader, QByteArrayLiteral ("application/xml; charset=utf-8"));
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 207);
    setFinished (true);
    /* emit */ metaDataChanged ();
    if (bytesAvailable ())
        /* emit */ readyRead ();
    /* emit */ finished ();
}

void FakePropfindReply.respond404 () {
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 404);
    setError (InternalServerError, QStringLiteral ("Not Found"));
    /* emit */ metaDataChanged ();
    /* emit */ finished ();
}

int64 FakePropfindReply.bytesAvailable () {
    return payload.size () + QIODevice.bytesAvailable ();
}

int64 FakePropfindReply.readData (char data, int64 maxlen) {
    int64 len = std.min (int64 { payload.size () }, maxlen);
    std.copy (payload.cbegin (), payload.cbegin () + len, data);
    payload.remove (0, static_cast<int> (len));
    return len;
}

FakePutReply.FakePutReply (FileInfo remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.ByteArray putPayload, GLib.Object parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);
    fileInfo = perform (remoteRootFileInfo, request, putPayload);
    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
}

FileInfo *FakePutReply.perform (FileInfo remoteRootFileInfo, QNetworkRequest request, GLib.ByteArray putPayload) {
    string fileName = getFilePathFromUrl (request.url ());
    //  Q_ASSERT (!fileName.isEmpty ());
    FileInfo fileInfo = remoteRootFileInfo.find (fileName);
    if (fileInfo) {
        fileInfo.size = putPayload.size ();
        fileInfo.contentChar = putPayload.at (0);
    } else {
        // Assume that the file is filled with the same character
        fileInfo = remoteRootFileInfo.create (fileName, putPayload.size (), putPayload.at (0));
    }
    fileInfo.lastModified = Occ.Utility.qDateTimeFromTime_t (request.rawHeader ("X-OC-Mtime").toLongLong ());
    remoteRootFileInfo.find (fileName, /*invalidateEtags=*/true);
    return fileInfo;
}

void FakePutReply.respond () {
    /* emit */ uploadProgress (fileInfo.size, fileInfo.size);
    setRawHeader ("OC-ETag", fileInfo.etag);
    setRawHeader ("ETag", fileInfo.etag);
    setRawHeader ("OC-FileID", fileInfo.fileId);
    setRawHeader ("X-OC-MTime", "accepted"); // Prevents Q_ASSERT (!this.runningNow) since we'll call PropagateItemJob.done twice in that case.
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 200);
    /* emit */ metaDataChanged ();
    /* emit */ finished ();
}

void FakePutReply.on_abort () {
    setError (OperationCanceledError, QStringLiteral ("on_abort"));
    /* emit */ finished ();
}

FakePutMultiFileReply.FakePutMultiFileReply (FileInfo remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest request, string contentType, GLib.ByteArray putPayload, GLib.Object parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);
    this.allFileInfo = performMultiPart (remoteRootFileInfo, request, putPayload, contentType);
    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
}

GLib.Vector<FileInfo> FakePutMultiFileReply.performMultiPart (FileInfo remoteRootFileInfo, QNetworkRequest request, GLib.ByteArray putPayload, string contentType) {
    GLib.Vector<FileInfo> result;

    var stringPutPayload = string.fromUtf8 (putPayload);
    const int boundaryPosition = sizeof ("multipart/related; boundary=");
    const string boundaryValue = QStringLiteral ("--") + contentType.mid (boundaryPosition, contentType.length () - boundaryPosition - 1) + QStringLiteral ("\r\n");
    var stringPutPayloadRef = string{stringPutPayload}.left (stringPutPayload.size () - 2 - boundaryValue.size ());
    var allParts = stringPutPayloadRef.split (boundaryValue, Qt.SkipEmptyParts);
    for (var onePart : allParts) {
        var headerEndPosition = onePart.indexOf (QStringLiteral ("\r\n\r\n"));
        var onePartHeaderPart = onePart.left (headerEndPosition);
        var onePartBody = onePart.mid (headerEndPosition + 4, onePart.size () - headerEndPosition - 6);
        var onePartHeaders = onePartHeaderPart.split (QStringLiteral ("\r\n"));
        GLib.HashMap<string, string> allHeaders;
        for (var oneHeader : onePartHeaders) {
            var headerParts = oneHeader.split (QStringLiteral (" : "));
            allHeaders[headerParts.at (0)] = headerParts.at (1);
        }
        var fileName = allHeaders[QStringLiteral ("X-File-Path")];
        //  Q_ASSERT (!fileName.isEmpty ());
        FileInfo fileInfo = remoteRootFileInfo.find (fileName);
        if (fileInfo) {
            fileInfo.size = onePartBody.size ();
            fileInfo.contentChar = onePartBody.at (0).toLatin1 ();
        } else {
            // Assume that the file is filled with the same character
            fileInfo = remoteRootFileInfo.create (fileName, onePartBody.size (), onePartBody.at (0).toLatin1 ());
        }
        fileInfo.lastModified = Occ.Utility.qDateTimeFromTime_t (request.rawHeader ("X-OC-Mtime").toLongLong ());
        remoteRootFileInfo.find (fileName, /*invalidateEtags=*/true);
        result.push_back (fileInfo);
    }
    return result;
}

void FakePutMultiFileReply.respond () {
    QJsonDocument reply;
    QJsonObject allFileInfoReply;

    int64 totalSize = 0;
    std.for_each (this.allFileInfo.begin (), this.allFileInfo.end (), [&totalSize] (var fileInfo) {
        totalSize += fileInfo.size;
    });

    for (var fileInfo : qAsConst (this.allFileInfo)) {
        QJsonObject fileInfoReply;
        fileInfoReply.insert ("error", QStringLiteral ("false"));
        fileInfoReply.insert ("OC-OperationStatus", fileInfo.operationStatus);
        fileInfoReply.insert ("X-File-Path", fileInfo.path ());
        fileInfoReply.insert ("OC-ETag", QLatin1String{fileInfo.etag});
        fileInfoReply.insert ("ETag", QLatin1String{fileInfo.etag});
        fileInfoReply.insert ("etag", QLatin1String{fileInfo.etag});
        fileInfoReply.insert ("OC-FileID", QLatin1String{fileInfo.fileId});
        fileInfoReply.insert ("X-OC-MTime", "accepted"); // Prevents Q_ASSERT (!this.runningNow) since we'll call PropagateItemJob.done twice in that case.
        /* emit */ uploadProgress (fileInfo.size, totalSize);
        allFileInfoReply.insert (char ('/') + fileInfo.path (), fileInfoReply);
    }
    reply.setObject (allFileInfoReply);
    this.payload = reply.toJson ();

    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 200);

    setFinished (true);
    if (bytesAvailable ()) {
        /* emit */ readyRead ();
    }

    /* emit */ metaDataChanged ();
    /* emit */ finished ();
}

void FakePutMultiFileReply.on_abort () {
    setError (OperationCanceledError, QStringLiteral ("on_abort"));
    /* emit */ finished ();
}

int64 FakePutMultiFileReply.bytesAvailable () {
    return this.payload.size () + QIODevice.bytesAvailable ();
}

int64 FakePutMultiFileReply.readData (char data, int64 maxlen) {
    int64 len = std.min (int64 { this.payload.size () }, maxlen);
    std.copy (this.payload.cbegin (), this.payload.cbegin () + len, data);
    this.payload.remove (0, static_cast<int> (len));
    return len;
}

FakeMkcolReply.FakeMkcolReply (FileInfo remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.Object parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);

    string fileName = getFilePathFromUrl (request.url ());
    //  Q_ASSERT (!fileName.isEmpty ());
    fileInfo = remoteRootFileInfo.createDir (fileName);

    if (!fileInfo) {
        on_abort ();
        return;
    }
    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
}

void FakeMkcolReply.respond () {
    setRawHeader ("OC-FileId", fileInfo.fileId);
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 201);
    /* emit */ metaDataChanged ();
    /* emit */ finished ();
}

FakeDeleteReply.FakeDeleteReply (FileInfo remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.Object parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);

    string fileName = getFilePathFromUrl (request.url ());
    //  Q_ASSERT (!fileName.isEmpty ());
    remoteRootFileInfo.remove (fileName);
    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
}

void FakeDeleteReply.respond () {
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 204);
    /* emit */ metaDataChanged ();
    /* emit */ finished ();
}

FakeMoveReply.FakeMoveReply (FileInfo remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.Object parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);

    string fileName = getFilePathFromUrl (request.url ());
    //  Q_ASSERT (!fileName.isEmpty ());
    string dest = getFilePathFromUrl (GLib.Uri.fromEncoded (request.rawHeader ("Destination")));
    //  Q_ASSERT (!dest.isEmpty ());
    remoteRootFileInfo.rename (fileName, dest);
    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
}

void FakeMoveReply.respond () {
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 201);
    /* emit */ metaDataChanged ();
    /* emit */ finished ();
}

FakeGetReply.FakeGetReply (FileInfo remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.Object parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);

    string fileName = getFilePathFromUrl (request.url ());
    //  Q_ASSERT (!fileName.isEmpty ());
    fileInfo = remoteRootFileInfo.find (fileName);
    if (!fileInfo) {
        qDebug () << "meh;";
    }
    Q_ASSERT_X (fileInfo, Q_FUNC_INFO, "Could not find file on the remote");
    QMetaObject.invokeMethod (this, &FakeGetReply.respond, Qt.QueuedConnection);
}

void FakeGetReply.respond () {
    if (aborted) {
        setError (OperationCanceledError, QStringLiteral ("Operation Canceled"));
        /* emit */ metaDataChanged ();
        /* emit */ finished ();
        return;
    }
    payload = fileInfo.contentChar;
    size = fileInfo.size;
    setHeader (QNetworkRequest.ContentLengthHeader, size);
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 200);
    setRawHeader ("OC-ETag", fileInfo.etag);
    setRawHeader ("ETag", fileInfo.etag);
    setRawHeader ("OC-FileId", fileInfo.fileId);
    /* emit */ metaDataChanged ();
    if (bytesAvailable ())
        /* emit */ readyRead ();
    /* emit */ finished ();
}

void FakeGetReply.on_abort () {
    setError (OperationCanceledError, QStringLiteral ("Operation Canceled"));
    aborted = true;
}

int64 FakeGetReply.bytesAvailable () {
    if (aborted)
        return 0;
    return size + QIODevice.bytesAvailable ();
}

int64 FakeGetReply.readData (char data, int64 maxlen) {
    int64 len = std.min (int64 { size }, maxlen);
    std.fill_n (data, len, payload);
    size -= len;
    return len;
}

FakeGetWithDataReply.FakeGetWithDataReply (FileInfo remoteRootFileInfo, GLib.ByteArray data, QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.Object parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);

    //  Q_ASSERT (!data.isEmpty ());
    payload = data;
    string fileName = getFilePathFromUrl (request.url ());
    //  Q_ASSERT (!fileName.isEmpty ());
    fileInfo = remoteRootFileInfo.find (fileName);
    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);

    if (request.hasRawHeader ("Range")) {
        const string range = string.fromUtf8 (request.rawHeader ("Range"));
        const QRegularExpression bytesPattern (QStringLiteral ("bytes= (?<on_start>\\d+)- (?<end>\\d+)"));
        const QRegularExpressionMatch match = bytesPattern.match (range);
        if (match.hasMatch ()) {
            const int on_start = match.captured (QStringLiteral ("on_start")).toInt ();
            const int end = match.captured (QStringLiteral ("end")).toInt ();
            payload = payload.mid (on_start, end - on_start + 1);
        }
    }
}

void FakeGetWithDataReply.respond () {
    if (aborted) {
        setError (OperationCanceledError, QStringLiteral ("Operation Canceled"));
        /* emit */ metaDataChanged ();
        /* emit */ finished ();
        return;
    }
    setHeader (QNetworkRequest.ContentLengthHeader, payload.size ());
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 200);
    setRawHeader ("OC-ETag", fileInfo.etag);
    setRawHeader ("ETag", fileInfo.etag);
    setRawHeader ("OC-FileId", fileInfo.fileId);
    /* emit */ metaDataChanged ();
    if (bytesAvailable ())
        /* emit */ readyRead ();
    /* emit */ finished ();
}

void FakeGetWithDataReply.on_abort () {
    setError (OperationCanceledError, QStringLiteral ("Operation Canceled"));
    aborted = true;
}

int64 FakeGetWithDataReply.bytesAvailable () {
    if (aborted)
        return 0;
    return payload.size () - offset + QIODevice.bytesAvailable ();
}

int64 FakeGetWithDataReply.readData (char data, int64 maxlen) {
    int64 len = std.min (payload.size () - offset, uint64 (maxlen));
    std.memcpy (data, payload.constData () + offset, len);
    offset += len;
    return len;
}

FakeChunkMoveReply.FakeChunkMoveReply (FileInfo uploadsFileInfo, FileInfo remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.Object parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);
    fileInfo = perform (uploadsFileInfo, remoteRootFileInfo, request);
    if (!fileInfo) {
        QTimer.singleShot (0, this, &FakeChunkMoveReply.respondPreconditionFailed);
    } else {
        QTimer.singleShot (0, this, &FakeChunkMoveReply.respond);
    }
}

FileInfo *FakeChunkMoveReply.perform (FileInfo uploadsFileInfo, FileInfo remoteRootFileInfo, QNetworkRequest request) {
    string source = getFilePathFromUrl (request.url ());
    //  Q_ASSERT (!source.isEmpty ());
    //  Q_ASSERT (source.endsWith (QLatin1String ("/.file")));
    source = source.left (source.length () - static_cast<int> (qstrlen ("/.file")));

    var sourceFolder = uploadsFileInfo.find (source);
    //  Q_ASSERT (sourceFolder);
    //  Q_ASSERT (sourceFolder.isDir);
    int count = 0;
    qlonglong size = 0;
    char payload = '\0';

    string fileName = getFilePathFromUrl (GLib.Uri.fromEncoded (request.rawHeader ("Destination")));
    //  Q_ASSERT (!fileName.isEmpty ());

    // Compute the size and content from the chunks if possible
    for (var chunkName : sourceFolder.children.keys ()) {
        var x = sourceFolder.children[chunkName];
        //  Q_ASSERT (!x.isDir);
        //  Q_ASSERT (x.size > 0); // There should not be empty chunks
        size += x.size;
        //  Q_ASSERT (!payload || payload == x.contentChar);
        payload = x.contentChar;
        ++count;
    }
    //  Q_ASSERT (sourceFolder.children.count () == count); // There should not be holes or extra files

    // Note: This does not actually assemble the file data from the chunks!
    FileInfo fileInfo = remoteRootFileInfo.find (fileName);
    if (fileInfo) {
        // The client should put this header
        //  Q_ASSERT (request.hasRawHeader ("If"));

        // And it should condition on the destination file
        var on_start = GLib.ByteArray ("<" + request.rawHeader ("Destination") + ">");
        //  Q_ASSERT (request.rawHeader ("If").startsWith (on_start));

        if (request.rawHeader ("If") != on_start + " ([\"" + fileInfo.etag + "\"])") {
            return null;
        }
        fileInfo.size = size;
        fileInfo.contentChar = payload;
    } else {
        //  Q_ASSERT (!request.hasRawHeader ("If"));
        // Assume that the file is filled with the same character
        fileInfo = remoteRootFileInfo.create (fileName, size, payload);
    }
    fileInfo.lastModified = Occ.Utility.qDateTimeFromTime_t (request.rawHeader ("X-OC-Mtime").toLongLong ());
    remoteRootFileInfo.find (fileName, /*invalidateEtags=*/true);

    return fileInfo;
}

void FakeChunkMoveReply.respond () {
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 201);
    setRawHeader ("OC-ETag", fileInfo.etag);
    setRawHeader ("ETag", fileInfo.etag);
    setRawHeader ("OC-FileId", fileInfo.fileId);
    /* emit */ metaDataChanged ();
    /* emit */ finished ();
}

void FakeChunkMoveReply.respondPreconditionFailed () {
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 412);
    setError (InternalServerError, QStringLiteral ("Precondition Failed"));
    /* emit */ metaDataChanged ();
    /* emit */ finished ();
}

void FakeChunkMoveReply.on_abort () {
    setError (OperationCanceledError, QStringLiteral ("on_abort"));
    /* emit */ finished ();
}

FakePayloadReply.FakePayloadReply (QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.ByteArray body, GLib.Object parent)
    : FakePayloadReply (op, request, body, FakePayloadReply.defaultDelay, parent) {
}

FakePayloadReply.FakePayloadReply (
    QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.ByteArray body, int delay, GLib.Object parent)
    : FakeReply{parent}
    this.body (body) {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);
    QTimer.singleShot (delay, this, &FakePayloadReply.respond);
}

void FakePayloadReply.respond () {
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 200);
    setHeader (QNetworkRequest.ContentLengthHeader, this.body.size ());
    /* emit */ metaDataChanged ();
    /* emit */ readyRead ();
    setFinished (true);
    /* emit */ finished ();
}

int64 FakePayloadReply.readData (char buf, int64 max) {
    max = qMin<int64> (max, this.body.size ());
    memcpy (buf, this.body.constData (), max);
    this.body = this.body.mid (max);
    return max;
}

int64 FakePayloadReply.bytesAvailable () {
    return this.body.size ();
}

FakeErrorReply.FakeErrorReply (QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.Object parent, int httpErrorCode, GLib.ByteArray body)
    : FakeReply { parent }
    this.body (body) {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, httpErrorCode);
    setError (InternalServerError, QStringLiteral ("Internal Server Fake Error"));
    QMetaObject.invokeMethod (this, &FakeErrorReply.respond, Qt.QueuedConnection);
}

void FakeErrorReply.respond () {
    /* emit */ metaDataChanged ();
    /* emit */ readyRead ();
    // finishing can come strictly after readyRead was called
    QTimer.singleShot (5, this, &FakeErrorReply.on_slot_set_finished);
}

void FakeErrorReply.on_slot_set_finished () {
    setFinished (true);
    /* emit */ finished ();
}

int64 FakeErrorReply.readData (char buf, int64 max) {
    max = qMin<int64> (max, this.body.size ());
    memcpy (buf, this.body.constData (), max);
    this.body = this.body.mid (max);
    return max;
}

int64 FakeErrorReply.bytesAvailable () {
    return this.body.size ();
}

FakeHangingReply.FakeHangingReply (QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.Object parent)
    : FakeReply (parent) {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);
}

void FakeHangingReply.on_abort () {
    // Follow more or less the implementation of QNetworkReplyImpl.on_abort
    close ();
    setError (OperationCanceledError, _("Operation canceled"));
    /* emit */ errorOccurred (OperationCanceledError);
    setFinished (true);
    /* emit */ finished ();
}

FakeQNAM.FakeQNAM (FileInfo initialRoot)
    : this.remoteRootFileInfo { std.move (initialRoot) } {
    setCookieJar (new Occ.CookieJar);
}

QJsonObject FakeQNAM.forEachReplyPart (QIODevice outgoingData,
                                       const string contentType,
                                       std.function<QJsonObject (GLib.HashMap<string, GLib.ByteArray> &)> replyFunction) {
    var fullReply = QJsonObject{};
    var putPayload = outgoingData.peek (outgoingData.bytesAvailable ());
    outgoingData.on_reset ();
    var stringPutPayload = string.fromUtf8 (putPayload);
    const int boundaryPosition = sizeof ("multipart/related; boundary=");
    const string boundaryValue = QStringLiteral ("--") + contentType.mid (boundaryPosition, contentType.length () - boundaryPosition - 1) + QStringLiteral ("\r\n");
    var stringPutPayloadRef = string{stringPutPayload}.left (stringPutPayload.size () - 2 - boundaryValue.size ());
    var allParts = stringPutPayloadRef.split (boundaryValue, Qt.SkipEmptyParts);
    for (var onePart : qAsConst (allParts)) {
        var headerEndPosition = onePart.indexOf (QStringLiteral ("\r\n\r\n"));
        var onePartHeaderPart = onePart.left (headerEndPosition);
        var onePartHeaders = onePartHeaderPart.split (QStringLiteral ("\r\n"));
        GLib.HashMap<string, GLib.ByteArray> allHeaders;
        for (var oneHeader : qAsConst (onePartHeaders)) {
            var headerParts = oneHeader.split (QStringLiteral (" : "));
            allHeaders[headerParts.at (0)] = headerParts.at (1).toLatin1 ();
        }

        var reply = replyFunction (allHeaders);
        if (reply.contains (QStringLiteral ("error")) &&
                reply.contains (QStringLiteral ("etag"))) {
            fullReply.insert (allHeaders[QStringLiteral ("X-File-Path")], reply);
        }
    }

    return fullReply;
}

Soup.Reply *FakeQNAM.createRequest (QNetworkAccessManager.Operation op, QNetworkRequest request, QIODevice outgoingData) {
    Soup.Reply reply = null;
    var newRequest = request;
    newRequest.setRawHeader ("X-Request-ID", Occ.AccessManager.generateRequestId ());
    var contentType = request.header (QNetworkRequest.ContentTypeHeader).toString ();
    if (this.override) {
        if (var this.reply = this.override (op, newRequest, outgoingData)) {
            reply = this.reply;
        }
    }
    if (!reply) {
        reply = overrideReplyWithError (getFilePathFromUrl (newRequest.url ()), op, newRequest);
    }
    if (!reply) {
        const bool isUpload = newRequest.url ().path ().startsWith (sUploadUrl.path ());
        FileInfo info = isUpload ? this.uploadFileInfo : this.remoteRootFileInfo;

        var verb = newRequest.attribute (QNetworkRequest.CustomVerbAttribute);
        if (verb == QLatin1String ("PROPFIND")) {
            // Ignore outgoingData always returning somethign good enough, works for now.
            reply = new FakePropfindReply { info, op, newRequest, this };
        } else if (verb == QLatin1String ("GET") || op == QNetworkAccessManager.GetOperation) {
            reply = new FakeGetReply { info, op, newRequest, this };
        } else if (verb == QLatin1String ("PUT") || op == QNetworkAccessManager.PutOperation) {
            reply = new FakePutReply { info, op, newRequest, outgoingData.readAll (), this };
        } else if (verb == QLatin1String ("MKCOL")) {
            reply = new FakeMkcolReply { info, op, newRequest, this };
        } else if (verb == QLatin1String ("DELETE") || op == QNetworkAccessManager.DeleteOperation) {
            reply = new FakeDeleteReply { info, op, newRequest, this };
        } else if (verb == QLatin1String ("MOVE") && !isUpload) {
            reply = new FakeMoveReply { info, op, newRequest, this };
        } else if (verb == QLatin1String ("MOVE") && isUpload) {
            reply = new FakeChunkMoveReply { info, this.remoteRootFileInfo, op, newRequest, this };
        } else if (verb == QLatin1String ("POST") || op == QNetworkAccessManager.PostOperation) {
            if (contentType.startsWith (QStringLiteral ("multipart/related; boundary="))) {
                reply = new FakePutMultiFileReply { info, op, newRequest, contentType, outgoingData.readAll (), this };
            }
        } else {
            qDebug () << verb << outgoingData;
            Q_UNREACHABLE ();
        }
    }
    Occ.HttpLogger.logRequest (reply, op, outgoingData);
    return reply;
}

Soup.Reply * FakeQNAM.overrideReplyWithError (string fileName, QNetworkAccessManager.Operation op, QNetworkRequest newRequest) {
    Soup.Reply reply = null;

    //  Q_ASSERT (!fileName.isNull ());
    if (this.errorPaths.contains (fileName)) {
        reply = new FakeErrorReply { op, newRequest, this, this.errorPaths[fileName] };
    }

    return reply;
}

FakeFolder.FakeFolder (FileInfo fileTemplate, Occ.Optional<FileInfo> localFileInfo, string remotePath)
    : this.localModifier (this.tempDir.path ()) {
    // Needs to be done once
    Occ.SyncEngine.minimumFileAgeForUpload = std.chrono.milliseconds (0);
    Occ.Logger.instance ().setLogFile (QStringLiteral ("-"));
    Occ.Logger.instance ().addLogRule ({ QStringLiteral ("sync.httplogger=true") });

    QDir rootDir { this.tempDir.path () };
    qDebug () << "FakeFolder operating on" << rootDir;
    if (localFileInfo) {
        toDisk (rootDir, *localFileInfo);
    } else {
        toDisk (rootDir, fileTemplate);
    }

    this.fakeQnam = new FakeQNAM (fileTemplate);
    this.account = Occ.Account.create ();
    this.account.setUrl (GLib.Uri (QStringLiteral ("http://admin:admin@localhost/owncloud")));
    this.account.setCredentials (new FakeCredentials { this.fakeQnam });
    this.account.setDavDisplayName (QStringLiteral ("fakename"));
    this.account.setServerVersion (QStringLiteral ("10.0.0"));

    this.journalDb = std.make_unique<Occ.SyncJournalDb> (localPath () + QStringLiteral (".sync_test.db"));
    this.syncEngine = std.make_unique<Occ.SyncEngine> (this.account, localPath (), remotePath, this.journalDb.get ());
    // Ignore temporary files from the download. (This is in the default exclude list, but we don't load it)
    this.syncEngine.excludedFiles ().addManualExclude (QStringLiteral ("]*.~*"));

    // handle aboutToRemoveAllFiles with a timeout in case our test does not handle it
    GLib.Object.connect (this.syncEngine.get (), &Occ.SyncEngine.aboutToRemoveAllFiles, this.syncEngine.get (), [this] (Occ.SyncFileItem.Direction, std.function<void (bool)> callback) {
        QTimer.singleShot (1 * 1000, this.syncEngine.get (), [callback] {
            callback (false);
        });
    });

    // Ensure we have a valid VfsOff instance "running"
    switchToVfs (this.syncEngine.syncOptions ().vfs);

    // A new folder will update the local file state database on first sync.
    // To have a state matching what users will encounter, we have to a sync
    // using an identical local/remote file tree first.
    ENFORCE (syncOnce ());
}

void FakeFolder.switchToVfs (unowned<Occ.Vfs> vfs) {
    var opts = this.syncEngine.syncOptions ();

    opts.vfs.stop ();
    GLib.Object.disconnect (this.syncEngine.get (), null, opts.vfs.data (), null);

    opts.vfs = vfs;
    this.syncEngine.setSyncOptions (opts);

    Occ.VfsSetupParams vfsParams;
    vfsParams.filesystemPath = localPath ();
    vfsParams.remotePath = '/';
    vfsParams.account = this.account;
    vfsParams.journal = this.journalDb.get ();
    vfsParams.providerName = QStringLiteral ("OC-TEST");
    vfsParams.providerVersion = QStringLiteral ("0.1");
    GLib.Object.connect (this.syncEngine.get (), &GLib.Object.destroyed, vfs.data (), [vfs] () {
        vfs.stop ();
        vfs.unregisterFolder ();
    });

    vfs.on_start (vfsParams);
}

FileInfo FakeFolder.currentLocalState () {
    QDir rootDir { this.tempDir.path () };
    FileInfo rootTemplate;
    fromDisk (rootDir, rootTemplate);
    rootTemplate.fixupParentPathRecursively ();
    return rootTemplate;
}

string FakeFolder.localPath () {
    // SyncEngine wants a trailing slash
    if (this.tempDir.path ().endsWith ('/'))
        return this.tempDir.path ();
    return this.tempDir.path () + '/';
}

void FakeFolder.scheduleSync () {
    // Have to be done async, else, an error before exec () does not terminate the event loop.
    QMetaObject.invokeMethod (this.syncEngine.get (), "startSync", Qt.QueuedConnection);
}

void FakeFolder.execUntilBeforePropagation () {
    QSignalSpy spy (this.syncEngine.get (), SIGNAL (aboutToPropagate (SyncFileItemVector &)));
    QVERIFY (spy.wait ());
}

void FakeFolder.execUntilItemCompleted (string relativePath) {
    QSignalSpy spy (this.syncEngine.get (), SIGNAL (itemCompleted (SyncFileItemPtr &)));
    QElapsedTimer t;
    t.on_start ();
    while (t.elapsed () < 5000) {
        spy.clear ();
        QVERIFY (spy.wait ());
        for (GLib.List<GLib.Variant> args : spy) {
            var item = args[0].value<Occ.SyncFileItemPtr> ();
            if (item.destination () == relativePath)
                return;
        }
    }
    QVERIFY (false);
}

void FakeFolder.toDisk (QDir dir, FileInfo templateFi) {
    foreach (FileInfo child, templateFi.children) {
        if (child.isDir) {
            QDir subDir (dir);
            dir.mkdir (child.name);
            subDir.cd (child.name);
            toDisk (subDir, child);
        } else {
            GLib.File file { dir.filePath (child.name) };
            file.open (GLib.File.WriteOnly);
            file.write (GLib.ByteArray {}.fill (child.contentChar, child.size));
            file.close ();
            Occ.FileSystem.setModTime (file.fileName (), Occ.Utility.qDateTimeToTime_t (child.lastModified));
        }
    }
}

void FakeFolder.fromDisk (QDir dir, FileInfo templateFi) {
    foreach (QFileInfo diskChild, dir.entryInfoList (QDir.AllEntries | QDir.NoDotAndDotDot)) {
        if (diskChild.isDir ()) {
            QDir subDir = dir;
            subDir.cd (diskChild.fileName ());
            FileInfo subFi = templateFi.children[diskChild.fileName ()] = FileInfo { diskChild.fileName () };
            fromDisk (subDir, subFi);
        } else {
            GLib.File f { diskChild.filePath () };
            f.open (GLib.File.ReadOnly);
            var content = f.read (1);
            if (content.size () == 0) {
                qWarning () << "Empty file at:" << diskChild.filePath ();
                continue;
            }
            char contentChar = content.at (0);
            templateFi.children.insert (diskChild.fileName (), FileInfo { diskChild.fileName (), diskChild.size (), contentChar });
        }
    }
}

static FileInfo findOrCreateDirs (FileInfo base, PathComponents components) {
    if (components.isEmpty ())
        return base;
    var childName = components.pathRoot ();
    var it = base.children.find (childName);
    if (it != base.children.end ()) {
        return findOrCreateDirs (*it, components.subComponents ());
    }
    var newDir = base.children[childName] = FileInfo { childName };
    newDir.parentPath = base.path ();
    return findOrCreateDirs (newDir, components.subComponents ());
}

FileInfo FakeFolder.dbState () {
    FileInfo result;
    this.journalDb.getFilesBelowPath ("", [&] (Occ.SyncJournalFileRecord record) {
        var components = PathComponents (record.path ());
        var parentDir = findOrCreateDirs (result, components.parentDirComponents ());
        var name = components.fileName ();
        var item = parentDir.children[name];
        item.name = name;
        item.parentPath = parentDir.path ();
        item.size = record.fileSize;
        item.isDir = record.type == ItemTypeDirectory;
        item.permissions = record.remotePerm;
        item.etag = record.etag;
        item.lastModified = Occ.Utility.qDateTimeFromTime_t (record.modtime);
        item.fileId = record.fileId;
        item.checksums = record.checksumHeader;
        // item.contentChar can't be set from the database
    });
    return result;
}

Occ.SyncFileItemPtr ItemCompletedSpy.findItem (string path) {
    for (GLib.List<GLib.Variant> args : *this) {
        var item = args[0].value<Occ.SyncFileItemPtr> ();
        if (item.destination () == path)
            return item;
    }
    return Occ.SyncFileItemPtr.create ();
}

Occ.SyncFileItemPtr ItemCompletedSpy.findItemWithExpectedRank (string path, int rank) {
    //  Q_ASSERT (size () > rank);
    //  Q_ASSERT (! (*this)[rank].isEmpty ());

    var item = (*this)[rank][0].value<Occ.SyncFileItemPtr> ();
    if (item.destination () == path) {
        return item;
    } else {
        return Occ.SyncFileItemPtr.create ();
    }
}

FakeReply.FakeReply (GLib.Object parent)
    : Soup.Reply (parent) {
    setRawHeader (QByteArrayLiteral ("Date"), GLib.DateTime.currentDateTimeUtc ().toString (Qt.RFC2822Date).toUtf8 ());
}

FakeReply.~FakeReply () = default;

FakeJsonErrorReply.FakeJsonErrorReply (QNetworkAccessManager.Operation op,
                                       const QNetworkRequest request,
                                       GLib.Object parent,
                                       int httpErrorCode,
                                       const QJsonDocument reply)
    : FakeErrorReply{ op, request, parent, httpErrorCode, reply.toJson () } {
}
