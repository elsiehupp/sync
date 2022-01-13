/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.

***********************************************************/
// #pragma once

// #include <QDir>
// #include <QNetworkReply>
// #include <QMap>
// #include <QtTest>

// #include <cstring>
// #include <memory>

// #include <cookiejar.h>
// #include <QTimer>


/***********************************************************
TODO : In theory we should use QVERIFY instead of Q_ASSERT for testing, but this
only works when directly called from a QTest :- (
***********************************************************/

static const QUrl sRootUrl ("owncloud://somehost/owncloud/remote.php/dav/");
static const QUrl sRootUrl2 ("owncloud://somehost/owncloud/remote.php/dav/files/admin/");
static const QUrl sUploadUrl ("owncloud://somehost/owncloud/remote.php/dav/uploads/admin/");

inline string getFilePathFromUrl (QUrl &url) {
    string path = url.path ();
    if (path.startsWith (sRootUrl2.path ()))
        return path.mid (sRootUrl2.path ().length ());
    if (path.startsWith (sUploadUrl.path ()))
        return path.mid (sUploadUrl.path ().length ());
    if (path.startsWith (sRootUrl.path ()))
        return path.mid (sRootUrl.path ().length ());
    return {};
}

inline QByteArray generateEtag () {
    return QByteArray.number (QDateTime.currentDateTimeUtc ().toMSecsSinceEpoch (), 16) + QByteArray.number (Occ.Utility.rand (), 16);
}
inline QByteArray generateFileId () {
    return QByteArray.number (Occ.Utility.rand (), 16);
}

class PathComponents : QStringList {
public:
    PathComponents (char *path);
    PathComponents (string &path);
    PathComponents (QStringList &pathComponents);

    PathComponents parentDirComponents ();
    PathComponents subComponents () const &;
    PathComponents subComponents () && { removeFirst (); return std.move (*this); }
    string pathRoot () { return first (); }
    string fileName () { return last (); }
};

class FileModifier {
public:
    virtual ~FileModifier () = default;
    virtual void remove (string &relativePath) = 0;
    virtual void insert (string &relativePath, int64 size = 64, char contentChar = 'W') = 0;
    virtual void setContents (string &relativePath, char contentChar) = 0;
    virtual void appendByte (string &relativePath) = 0;
    virtual void mkdir (string &relativePath) = 0;
    virtual void rename (string &relativePath, string &relativeDestinationDirectory) = 0;
    virtual void setModTime (string &relativePath, QDateTime &modTime) = 0;
};

class DiskFileModifier : FileModifier {
    QDir _rootDir;
public:
    DiskFileModifier (string &rootDirPath) : _rootDir (rootDirPath) { }
    void remove (string &relativePath) override;
    void insert (string &relativePath, int64 size = 64, char contentChar = 'W') override;
    void setContents (string &relativePath, char contentChar) override;
    void appendByte (string &relativePath) override;

    void mkdir (string &relativePath) override;
    void rename (string &from, string &to) override;
    void setModTime (string &relativePath, QDateTime &modTime) override;
};

class FileInfo : FileModifier {
public:
    static FileInfo A12_B12_C12_S12 ();

    FileInfo () = default;
    FileInfo (string &name) : name{name} { }
    FileInfo (string &name, int64 size) : name{name}, isDir{false}, size{size} { }
    FileInfo (string &name, int64 size, char contentChar) : name{name}, isDir{false}, size{size}, contentChar{contentChar} { }
    FileInfo (string &name, std.initializer_list<FileInfo> &children);

    void addChild (FileInfo &info);

    void remove (string &relativePath) override;

    void insert (string &relativePath, int64 size = 64, char contentChar = 'W') override;

    void setContents (string &relativePath, char contentChar) override;

    void appendByte (string &relativePath) override;

    void mkdir (string &relativePath) override;

    void rename (string &oldPath, string &newPath) override;

    void setModTime (string &relativePath, QDateTime &modTime) override;

    FileInfo *find (PathComponents pathComponents, bool invalidateEtags = false);

    FileInfo *createDir (string &relativePath);

    FileInfo *create (string &relativePath, int64 size, char contentChar);

    bool operator< (FileInfo &other) {
        return name < other.name;
    }

    bool operator== (FileInfo &other) const;

    bool operator!= (FileInfo &other) {
        return !operator== (other);
    }

    string path ();
    string absolutePath ();

    void fixupParentPathRecursively ();

    string name;
    int operationStatus = 200;
    bool isDir = true;
    bool isShared = false;
    Occ.RemotePermissions permissions; // When uset, defaults to everything
    QDateTime lastModified = QDateTime.currentDateTimeUtc ().addDays (-7);
    QByteArray etag = generateEtag ();
    QByteArray fileId = generateFileId ();
    QByteArray checksums;
    QByteArray extraDavProperties;
    int64 size = 0;
    char contentChar = 'W';

    // Sorted by name to be able to compare trees
    QMap<string, FileInfo> children;
    string parentPath;

    FileInfo *findInvalidatingEtags (PathComponents pathComponents);

    friend inline QDebug operator<< (QDebug dbg, FileInfo& fi) {
        return dbg << "{ " << fi.path () << " : " << fi.children;
    }
};

class FakeReply : QNetworkReply {
public:
    FakeReply (GLib.Object *parent);
    ~FakeReply () override;

    // useful to be public for testing
    using QNetworkReply.setRawHeader;
};

class FakePropfindReply : FakeReply {
public:
    QByteArray payload;

    FakePropfindReply (FileInfo &remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest &request, GLib.Object *parent);

    Q_INVOKABLE void respond ();

    Q_INVOKABLE void respond404 ();

    void abort () override { }

    int64 bytesAvailable () const override;
    int64 readData (char *data, int64 maxlen) override;
};

class FakePutReply : FakeReply {
    FileInfo *fileInfo;
public:
    FakePutReply (FileInfo &remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest &request, QByteArray &putPayload, GLib.Object *parent);

    static FileInfo *perform (FileInfo &remoteRootFileInfo, QNetworkRequest &request, QByteArray &putPayload);

    Q_INVOKABLE virtual void respond ();

    void abort () override;
    int64 readData (char *, int64) override { return 0; }
};

class FakePutMultiFileReply : FakeReply {
public:
    FakePutMultiFileReply (FileInfo &remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest &request, string &contentType, QByteArray &putPayload, GLib.Object *parent);

    static QVector<FileInfo> performMultiPart (FileInfo &remoteRootFileInfo, QNetworkRequest &request, QByteArray &putPayload, string &contentType);

    Q_INVOKABLE virtual void respond ();

    void abort () override;

    int64 bytesAvailable () const override;
    int64 readData (char *data, int64 maxlen) override;

private:
    QVector<FileInfo> _allFileInfo;

    QByteArray _payload;
};

class FakeMkcolReply : FakeReply {
    FileInfo *fileInfo;
public:
    FakeMkcolReply (FileInfo &remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest &request, GLib.Object *parent);

    Q_INVOKABLE void respond ();

    void abort () override { }
    int64 readData (char *, int64) override { return 0; }
};

class FakeDeleteReply : FakeReply {
public:
    FakeDeleteReply (FileInfo &remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest &request, GLib.Object *parent);

    Q_INVOKABLE void respond ();

    void abort () override { }
    int64 readData (char *, int64) override { return 0; }
};

class FakeMoveReply : FakeReply {
public:
    FakeMoveReply (FileInfo &remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest &request, GLib.Object *parent);

    Q_INVOKABLE void respond ();

    void abort () override { }
    int64 readData (char *, int64) override { return 0; }
};

class FakeGetReply : FakeReply {
public:
    const FileInfo *fileInfo;
    char payload;
    int size;
    bool aborted = false;

    FakeGetReply (FileInfo &remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest &request, GLib.Object *parent);

    Q_INVOKABLE void respond ();

    void abort () override;
    int64 bytesAvailable () const override;

    int64 readData (char *data, int64 maxlen) override;
};

class FakeGetWithDataReply : FakeReply {
public:
    const FileInfo *fileInfo;
    QByteArray payload;
    uint64 offset = 0;
    bool aborted = false;

    FakeGetWithDataReply (FileInfo &remoteRootFileInfo, QByteArray &data, QNetworkAccessManager.Operation op, QNetworkRequest &request, GLib.Object *parent);

    Q_INVOKABLE void respond ();

    void abort () override;
    int64 bytesAvailable () const override;

    int64 readData (char *data, int64 maxlen) override;
};

class FakeChunkMoveReply : FakeReply {
    FileInfo *fileInfo;
public:
    FakeChunkMoveReply (FileInfo &uploadsFileInfo, FileInfo &remoteRootFileInfo,
        QNetworkAccessManager.Operation op, QNetworkRequest &request,
        GLib.Object *parent);

    static FileInfo *perform (FileInfo &uploadsFileInfo, FileInfo &remoteRootFileInfo, QNetworkRequest &request);

    Q_INVOKABLE virtual void respond ();

    Q_INVOKABLE void respondPreconditionFailed ();

    void abort () override;

    int64 readData (char *, int64) override { return 0; }
};

class FakePayloadReply : FakeReply {
public:
    FakePayloadReply (QNetworkAccessManager.Operation op, QNetworkRequest &request,
        const QByteArray &body, GLib.Object *parent);

    FakePayloadReply (QNetworkAccessManager.Operation op, QNetworkRequest &request,
        const QByteArray &body, int delay, GLib.Object *parent);

    void respond ();

    void abort () override {}
    int64 readData (char *buf, int64 max) override;
    int64 bytesAvailable () const override;
    QByteArray _body;

    static const int defaultDelay = 10;
};

class FakeErrorReply : FakeReply {
public:
    FakeErrorReply (QNetworkAccessManager.Operation op, QNetworkRequest &request,
        GLib.Object *parent, int httpErrorCode, QByteArray &body = QByteArray ());

    Q_INVOKABLE virtual void respond ();

    // make public to give tests easy interface
    using QNetworkReply.setError;
    using QNetworkReply.setAttribute;

public slots:
    void slotSetFinished ();

public:
    void abort () override { }
    int64 readData (char *buf, int64 max) override;
    int64 bytesAvailable () const override;

    QByteArray _body;
};

class FakeJsonErrorReply : FakeErrorReply {
public:
    FakeJsonErrorReply (QNetworkAccessManager.Operation op,
                       const QNetworkRequest &request,
                       GLib.Object *parent,
                       int httpErrorCode,
                       const QJsonDocument &reply = QJsonDocument ());
};

// A reply that never responds
class FakeHangingReply : FakeReply {
public:
    FakeHangingReply (QNetworkAccessManager.Operation op, QNetworkRequest &request, GLib.Object *parent);

    void abort () override;
    int64 readData (char *, int64) override { return 0; }
};

// A delayed reply
template <class OriginalReply>
class DelayedReply : OriginalReply {
public:
    template <typename... Args>
    DelayedReply (uint64 delayMS, Args &&... args)
        : OriginalReply (std.forward<Args> (args)...)
        , _delayMs (delayMS) {
    }
    uint64 _delayMs;

    void respond () override {
        QTimer.singleShot (_delayMs, static_cast<OriginalReply> (this), [this] {
            // Explicit call to bases's respond ();
            this.OriginalReply.respond ();
        });
    }
};

class FakeQNAM : QNetworkAccessManager {
public:
    using Override = std.function<QNetworkReply * (Operation, QNetworkRequest &, QIODevice *)>;

private:
    FileInfo _remoteRootFileInfo;
    FileInfo _uploadFileInfo;
    // maps a path to an HTTP error
    QHash<string, int> _errorPaths;
    // monitor requests and optionally provide custom replies
    Override _override;

public:
    FakeQNAM (FileInfo initialRoot);
    FileInfo &currentRemoteState () { return _remoteRootFileInfo; }
    FileInfo &uploadState () { return _uploadFileInfo; }

    QHash<string, int> &errorPaths () { return _errorPaths; }

    void setOverride (Override &override) { _override = override; }

    QJsonObject forEachReplyPart (QIODevice *outgoingData,
                                 const string &contentType,
                                 std.function<QJsonObject (QMap<string, QByteArray> &)> replyFunction);

    QNetworkReply *overrideReplyWithError (string fileName, Operation op, QNetworkRequest newRequest);

protected:
    QNetworkReply *createRequest (Operation op, QNetworkRequest &request,
        QIODevice *outgoingData = nullptr) override;
};

class FakeCredentials : Occ.AbstractCredentials {
    QNetworkAccessManager *_qnam;
public:
    FakeCredentials (QNetworkAccessManager *qnam) : _qnam{qnam} { }
    string authType () const override { return "test"; }
    string user () const override { return "admin"; }
    string password () const override { return "password"; }
    QNetworkAccessManager *createQNAM () const override { return _qnam; }
    bool ready () const override { return true; }
    void fetchFromKeychain () override { }
    void askFromUser () override { }
    bool stillValid (QNetworkReply *) override { return true; }
    void persist () override { }
    void invalidateToken () override { }
    void forgetSensitiveData () override { }
};

class FakeFolder {
    QTemporaryDir _tempDir;
    DiskFileModifier _localModifier;
    // FIXME : Clarify ownership, double delete
    FakeQNAM *_fakeQnam;
    Occ.AccountPtr _account;
    std.unique_ptr<Occ.SyncJournalDb> _journalDb;
    std.unique_ptr<Occ.SyncEngine> _syncEngine;

public:
    FakeFolder (FileInfo &fileTemplate, Occ.Optional<FileInfo> &localFileInfo = {}, string &remotePath = {});

    void switchToVfs (QSharedPointer<Occ.Vfs> vfs);

    Occ.AccountPtr account () { return _account; }
    Occ.SyncEngine &syncEngine () { return *_syncEngine; }
    Occ.SyncJournalDb &syncJournal () { return *_journalDb; }

    FileModifier &localModifier () { return _localModifier; }
    FileInfo &remoteModifier () { return _fakeQnam.currentRemoteState (); }
    FileInfo currentLocalState ();

    FileInfo currentRemoteState () { return _fakeQnam.currentRemoteState (); }
    FileInfo &uploadState () { return _fakeQnam.uploadState (); }
    FileInfo dbState ();

    struct ErrorList {
        FakeQNAM *_qnam;
        void append (string &path, int error = 500) { _qnam.errorPaths ().insert (path, error); }
        void clear () { _qnam.errorPaths ().clear (); }
    };
    ErrorList serverErrorPaths () { return {_fakeQnam}; }
    void setServerOverride (FakeQNAM.Override &override) { _fakeQnam.setOverride (override); }
    QJsonObject forEachReplyPart (QIODevice *outgoingData,
                                 const string &contentType,
                                 std.function<QJsonObject (QMap<string, QByteArray>&)> replyFunction) {
        return _fakeQnam.forEachReplyPart (outgoingData, contentType, replyFunction);
    }

    string localPath ();

    void scheduleSync ();

    void execUntilBeforePropagation ();

    void execUntilItemCompleted (string &relativePath);

    bool execUntilFinished () {
        QSignalSpy spy (_syncEngine.get (), SIGNAL (finished (bool)));
        bool ok = spy.wait (3600000);
        Q_ASSERT (ok && "Sync timed out");
        return spy[0][0].toBool ();
    }

    bool syncOnce () {
        scheduleSync ();
        return execUntilFinished ();
    }

private:
    static void toDisk (QDir &dir, FileInfo &templateFi);

    static void fromDisk (QDir &dir, FileInfo &templateFi);
};

/* Return the FileInfo for a conflict file for the specified relative filename */
inline const FileInfo *findConflict (FileInfo &dir, string &filename) {
    QFileInfo info (filename);
    const FileInfo *parentDir = dir.find (info.path ());
    if (!parentDir)
        return nullptr;
    string start = info.baseName () + " (conflicted copy";
    for (auto &item : parentDir.children) {
        if (item.name.startsWith (start)) {
            return &item;
        }
    }
    return nullptr;
}

struct ItemCompletedSpy : QSignalSpy {
    ItemCompletedSpy (FakeFolder &folder)
        : QSignalSpy (&folder.syncEngine (), &Occ.SyncEngine.itemCompleted) {}

    Occ.SyncFileItemPtr findItem (string &path) const;

    Occ.SyncFileItemPtr findItemWithExpectedRank (string &path, int rank) const;
};

// QTest.toString overloads
namespace Occ {
    inline char *toString (SyncFileStatus &s) {
        return QTest.toString (string ("SyncFileStatus (" + s.toSocketAPIString () + ")"));
    }
}

inline void addFiles (QStringList &dest, FileInfo &fi) {
    if (fi.isDir) {
        dest += string ("%1 - dir").arg (fi.path ());
        foreach (FileInfo &fi, fi.children)
            addFiles (dest, fi);
    } else {
        dest += string ("%1 - %2 %3-bytes").arg (fi.path ()).arg (fi.size).arg (fi.contentChar);
    }
}

inline string toStringNoElide (FileInfo &fi) {
    QStringList files;
    foreach (FileInfo &fi, fi.children)
        addFiles (files, fi);
    files.sort ();
    return string ("FileInfo with %1 files (\n\t%2\n)").arg (files.size ()).arg (files.join ("\n\t"));
}

inline char *toString (FileInfo &fi) {
    return QTest.toString (toStringNoElide (fi));
}

inline void addFilesDbData (QStringList &dest, FileInfo &fi) {
    // could include etag, permissions etc, but would need extra work
    if (fi.isDir) {
        dest += string ("%1 - %2 %3 %4").arg (
            fi.name,
            fi.isDir ? "dir" : "file",
            string.number (fi.lastModified.toSecsSinceEpoch ()),
            fi.fileId);
        foreach (FileInfo &fi, fi.children)
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

inline char *printDbData (FileInfo &fi) {
    QStringList files;
    foreach (FileInfo &fi, fi.children)
        addFilesDbData (files, fi);
    return QTest.toString (string ("FileInfo with %1 files (%2)").arg (files.size ()).arg (files.join (", ")));
}










/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.

***********************************************************/

// #include <QJsonDocument>
// #include <QJsonArray>
// #include <QJsonObject>
// #include <QJsonValue>

// #include <memory>

PathComponents.PathComponents (char *path)
    : PathComponents { string.fromUtf8 (path) } {
}

PathComponents.PathComponents (string &path)
    : QStringList { path.split (QLatin1Char ('/'), Qt.SkipEmptyParts) } {
}

PathComponents.PathComponents (QStringList &pathComponents)
    : QStringList { pathComponents } {
}

PathComponents PathComponents.parentDirComponents () {
    return PathComponents { mid (0, size () - 1) };
}

PathComponents PathComponents.subComponents () const & {
    return PathComponents { mid (1) };
}

void DiskFileModifier.remove (string &relativePath) {
    QFileInfo fi { _rootDir.filePath (relativePath) };
    if (fi.isFile ())
        QVERIFY (_rootDir.remove (relativePath));
    else
        QVERIFY (QDir { fi.filePath () }.removeRecursively ());
}

void DiskFileModifier.insert (string &relativePath, int64 size, char contentChar) {
    QFile file { _rootDir.filePath (relativePath) };
    QVERIFY (!file.exists ());
    file.open (QFile.WriteOnly);
    QByteArray buf (1024, contentChar);
    for (int x = 0; x < size / buf.size (); ++x) {
        file.write (buf);
    }
    file.write (buf.data (), size % buf.size ());
    file.close ();
    // Set the mtime 30 seconds in the past, for some tests that need to make sure that the mtime differs.
    Occ.FileSystem.setModTime (file.fileName (), Occ.Utility.qDateTimeToTime_t (QDateTime.currentDateTimeUtc ().addSecs (-30)));
    QCOMPARE (file.size (), size);
}

void DiskFileModifier.setContents (string &relativePath, char contentChar) {
    QFile file { _rootDir.filePath (relativePath) };
    QVERIFY (file.exists ());
    int64 size = file.size ();
    file.open (QFile.WriteOnly);
    file.write (QByteArray {}.fill (contentChar, size));
}

void DiskFileModifier.appendByte (string &relativePath) {
    QFile file { _rootDir.filePath (relativePath) };
    QVERIFY (file.exists ());
    file.open (QFile.ReadWrite);
    QByteArray contents = file.read (1);
    file.seek (file.size ());
    file.write (contents);
}

void DiskFileModifier.mkdir (string &relativePath) {
    _rootDir.mkpath (relativePath);
}

void DiskFileModifier.rename (string &from, string &to) {
    QVERIFY (_rootDir.exists (from));
    QVERIFY (_rootDir.rename (from, to));
}

void DiskFileModifier.setModTime (string &relativePath, QDateTime &modTime) {
    Occ.FileSystem.setModTime (_rootDir.filePath (relativePath), Occ.Utility.qDateTimeToTime_t (modTime));
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

FileInfo.FileInfo (string &name, std.initializer_list<FileInfo> &children)
    : name { name } {
    for (auto &source : children)
        addChild (source);
}

void FileInfo.addChild (FileInfo &info) {
    auto &dest = this.children[info.name] = info;
    dest.parentPath = path ();
    dest.fixupParentPathRecursively ();
}

void FileInfo.remove (string &relativePath) {
    const PathComponents pathComponents { relativePath };
    FileInfo *parent = findInvalidatingEtags (pathComponents.parentDirComponents ());
    Q_ASSERT (parent);
    parent.children.erase (std.find_if (parent.children.begin (), parent.children.end (),
        [&pathComponents] (FileInfo &fi) { return fi.name == pathComponents.fileName (); }));
}

void FileInfo.insert (string &relativePath, int64 size, char contentChar) {
    create (relativePath, size, contentChar);
}

void FileInfo.setContents (string &relativePath, char contentChar) {
    FileInfo *file = findInvalidatingEtags (relativePath);
    Q_ASSERT (file);
    file.contentChar = contentChar;
}

void FileInfo.appendByte (string &relativePath) {
    FileInfo *file = findInvalidatingEtags (relativePath);
    Q_ASSERT (file);
    file.size += 1;
}

void FileInfo.mkdir (string &relativePath) {
    createDir (relativePath);
}

void FileInfo.rename (string &oldPath, string &newPath) {
    const PathComponents newPathComponents { newPath };
    FileInfo *dir = findInvalidatingEtags (newPathComponents.parentDirComponents ());
    Q_ASSERT (dir);
    Q_ASSERT (dir.isDir);
    const PathComponents pathComponents { oldPath };
    FileInfo *parent = findInvalidatingEtags (pathComponents.parentDirComponents ());
    Q_ASSERT (parent);
    FileInfo fi = parent.children.take (pathComponents.fileName ());
    fi.parentPath = dir.path ();
    fi.name = newPathComponents.fileName ();
    fi.fixupParentPathRecursively ();
    dir.children.insert (newPathComponents.fileName (), std.move (fi));
}

void FileInfo.setModTime (string &relativePath, QDateTime &modTime) {
    FileInfo *file = findInvalidatingEtags (relativePath);
    Q_ASSERT (file);
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
    auto it = children.find (childName);
    if (it != children.end ()) {
        auto file = it.find (std.move (pathComponents).subComponents (), invalidateEtags);
        if (file && invalidateEtags) {
            // Update parents on the way back
            etag = generateEtag ();
        }
        return file;
    }
    return nullptr;
}

FileInfo *FileInfo.createDir (string &relativePath) {
    const PathComponents pathComponents { relativePath };
    FileInfo *parent = findInvalidatingEtags (pathComponents.parentDirComponents ());
    Q_ASSERT (parent);
    FileInfo &child = parent.children[pathComponents.fileName ()] = FileInfo { pathComponents.fileName () };
    child.parentPath = parent.path ();
    child.etag = generateEtag ();
    return &child;
}

FileInfo *FileInfo.create (string &relativePath, int64 size, char contentChar) {
    const PathComponents pathComponents { relativePath };
    FileInfo *parent = findInvalidatingEtags (pathComponents.parentDirComponents ());
    Q_ASSERT (parent);
    FileInfo &child = parent.children[pathComponents.fileName ()] = FileInfo { pathComponents.fileName (), size };
    child.parentPath = parent.path ();
    child.contentChar = contentChar;
    child.etag = generateEtag ();
    return &child;
}

bool FileInfo.operator== (FileInfo &other) {
    // Consider files to be equal between local<.remote as a user would.
    return name == other.name
        && isDir == other.isDir
        && size == other.size
        && contentChar == other.contentChar
        && children == other.children;
}

string FileInfo.path () {
    return (parentPath.isEmpty () ? string () : (parentPath + QLatin1Char ('/'))) + name;
}

string FileInfo.absolutePath () {
    if (parentPath.endsWith (QLatin1Char ('/'))) {
        return parentPath + name;
    } else {
        return parentPath + QLatin1Char ('/') + name;
    }
}

void FileInfo.fixupParentPathRecursively () {
    auto p = path ();
    for (auto it = children.begin (); it != children.end (); ++it) {
        Q_ASSERT (it.key () == it.name);
        it.parentPath = p;
        it.fixupParentPathRecursively ();
    }
}

FileInfo *FileInfo.findInvalidatingEtags (PathComponents pathComponents) {
    return find (std.move (pathComponents), true);
}

FakePropfindReply.FakePropfindReply (FileInfo &remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest &request, GLib.Object *parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);

    string fileName = getFilePathFromUrl (request.url ());
    Q_ASSERT (!fileName.isNull ()); // for root, it should be empty
    const FileInfo *fileInfo = remoteRootFileInfo.find (fileName);
    if (!fileInfo) {
        QMetaObject.invokeMethod (this, "respond404", Qt.QueuedConnection);
        return;
    }
    const string prefix = request.url ().path ().left (request.url ().path ().size () - fileName.size ());

    // Don't care about the request and just return a full propfind
    const string davUri { QStringLiteral ("DAV:") };
    const string ocUri { QStringLiteral ("http://owncloud.org/ns") };
    QBuffer buffer { &payload };
    buffer.open (QIODevice.WriteOnly);
    QXmlStreamWriter xml (&buffer);
    xml.writeNamespace (davUri, QStringLiteral ("d"));
    xml.writeNamespace (ocUri, QStringLiteral ("oc"));
    xml.writeStartDocument ();
    xml.writeStartElement (davUri, QStringLiteral ("multistatus"));
    auto writeFileResponse = [&] (FileInfo &fileInfo) {
        xml.writeStartElement (davUri, QStringLiteral ("response"));

        auto url = string.fromUtf8 (QUrl.toPercentEncoding (fileInfo.absolutePath (), "/"));
        if (!url.endsWith (QChar ('/'))) {
            url.append (QChar ('/'));
        }
        const auto href = Occ.Utility.concatUrlPath (prefix, url).path ();
        xml.writeTextElement (davUri, QStringLiteral ("href"), href);
        xml.writeStartElement (davUri, QStringLiteral ("propstat"));
        xml.writeStartElement (davUri, QStringLiteral ("prop"));

        if (fileInfo.isDir) {
            xml.writeStartElement (davUri, QStringLiteral ("resourcetype"));
            xml.writeEmptyElement (davUri, QStringLiteral ("collection"));
            xml.writeEndElement (); // resourcetype
        } else
            xml.writeEmptyElement (davUri, QStringLiteral ("resourcetype"));

        auto gmtDate = fileInfo.lastModified.toUTC ();
        auto stringDate = QLocale.c ().toString (gmtDate, QStringLiteral ("ddd, dd MMM yyyy HH:mm:ss 'GMT'"));
        xml.writeTextElement (davUri, QStringLiteral ("getlastmodified"), stringDate);
        xml.writeTextElement (davUri, QStringLiteral ("getcontentlength"), string.number (fileInfo.size));
        xml.writeTextElement (davUri, QStringLiteral ("getetag"), QStringLiteral ("\"%1\"").arg (string.fromLatin1 (fileInfo.etag)));
        xml.writeTextElement (ocUri, QStringLiteral ("permissions"), !fileInfo.permissions.isNull () ? string (fileInfo.permissions.toString ()) : fileInfo.isShared ? QStringLiteral ("SRDNVCKW") : QStringLiteral ("RDNVCKW"));
        xml.writeTextElement (ocUri, QStringLiteral ("id"), string.fromUtf8 (fileInfo.fileId));
        xml.writeTextElement (ocUri, QStringLiteral ("checksums"), string.fromUtf8 (fileInfo.checksums));
        buffer.write (fileInfo.extraDavProperties);
        xml.writeEndElement (); // prop
        xml.writeTextElement (davUri, QStringLiteral ("status"), QStringLiteral ("HTTP/1.1 200 OK"));
        xml.writeEndElement (); // propstat
        xml.writeEndElement (); // response
    };

    writeFileResponse (*fileInfo);
    foreach (FileInfo &childFileInfo, fileInfo.children)
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
    emit metaDataChanged ();
    if (bytesAvailable ())
        emit readyRead ();
    emit finished ();
}

void FakePropfindReply.respond404 () {
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 404);
    setError (InternalServerError, QStringLiteral ("Not Found"));
    emit metaDataChanged ();
    emit finished ();
}

int64 FakePropfindReply.bytesAvailable () {
    return payload.size () + QIODevice.bytesAvailable ();
}

int64 FakePropfindReply.readData (char *data, int64 maxlen) {
    int64 len = std.min (int64 { payload.size () }, maxlen);
    std.copy (payload.cbegin (), payload.cbegin () + len, data);
    payload.remove (0, static_cast<int> (len));
    return len;
}

FakePutReply.FakePutReply (FileInfo &remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest &request, QByteArray &putPayload, GLib.Object *parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);
    fileInfo = perform (remoteRootFileInfo, request, putPayload);
    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
}

FileInfo *FakePutReply.perform (FileInfo &remoteRootFileInfo, QNetworkRequest &request, QByteArray &putPayload) {
    string fileName = getFilePathFromUrl (request.url ());
    Q_ASSERT (!fileName.isEmpty ());
    FileInfo *fileInfo = remoteRootFileInfo.find (fileName);
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
    emit uploadProgress (fileInfo.size, fileInfo.size);
    setRawHeader ("OC-ETag", fileInfo.etag);
    setRawHeader ("ETag", fileInfo.etag);
    setRawHeader ("OC-FileID", fileInfo.fileId);
    setRawHeader ("X-OC-MTime", "accepted"); // Prevents Q_ASSERT (!_runningNow) since we'll call PropagateItemJob.done twice in that case.
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 200);
    emit metaDataChanged ();
    emit finished ();
}

void FakePutReply.abort () {
    setError (OperationCanceledError, QStringLiteral ("abort"));
    emit finished ();
}

FakePutMultiFileReply.FakePutMultiFileReply (FileInfo &remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest &request, string &contentType, QByteArray &putPayload, GLib.Object *parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);
    _allFileInfo = performMultiPart (remoteRootFileInfo, request, putPayload, contentType);
    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
}

QVector<FileInfo> FakePutMultiFileReply.performMultiPart (FileInfo &remoteRootFileInfo, QNetworkRequest &request, QByteArray &putPayload, string &contentType) {
    QVector<FileInfo> result;

    auto stringPutPayload = string.fromUtf8 (putPayload);
    constexpr int boundaryPosition = sizeof ("multipart/related; boundary=");
    const string boundaryValue = QStringLiteral ("--") + contentType.mid (boundaryPosition, contentType.length () - boundaryPosition - 1) + QStringLiteral ("\r\n");
    auto stringPutPayloadRef = string{stringPutPayload}.left (stringPutPayload.size () - 2 - boundaryValue.size ());
    auto allParts = stringPutPayloadRef.split (boundaryValue, Qt.SkipEmptyParts);
    for (auto &onePart : allParts) {
        auto headerEndPosition = onePart.indexOf (QStringLiteral ("\r\n\r\n"));
        auto onePartHeaderPart = onePart.left (headerEndPosition);
        auto onePartBody = onePart.mid (headerEndPosition + 4, onePart.size () - headerEndPosition - 6);
        auto onePartHeaders = onePartHeaderPart.split (QStringLiteral ("\r\n"));
        QMap<string, string> allHeaders;
        for (auto oneHeader : onePartHeaders) {
            auto headerParts = oneHeader.split (QStringLiteral (" : "));
            allHeaders[headerParts.at (0)] = headerParts.at (1);
        }
        auto fileName = allHeaders[QStringLiteral ("X-File-Path")];
        Q_ASSERT (!fileName.isEmpty ());
        FileInfo *fileInfo = remoteRootFileInfo.find (fileName);
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
    std.for_each (_allFileInfo.begin (), _allFileInfo.end (), [&totalSize] (auto &fileInfo) {
        totalSize += fileInfo.size;
    });

    for (auto fileInfo : qAsConst (_allFileInfo)) {
        QJsonObject fileInfoReply;
        fileInfoReply.insert ("error", QStringLiteral ("false"));
        fileInfoReply.insert ("OC-OperationStatus", fileInfo.operationStatus);
        fileInfoReply.insert ("X-File-Path", fileInfo.path ());
        fileInfoReply.insert ("OC-ETag", QLatin1String{fileInfo.etag});
        fileInfoReply.insert ("ETag", QLatin1String{fileInfo.etag});
        fileInfoReply.insert ("etag", QLatin1String{fileInfo.etag});
        fileInfoReply.insert ("OC-FileID", QLatin1String{fileInfo.fileId});
        fileInfoReply.insert ("X-OC-MTime", "accepted"); // Prevents Q_ASSERT (!_runningNow) since we'll call PropagateItemJob.done twice in that case.
        emit uploadProgress (fileInfo.size, totalSize);
        allFileInfoReply.insert (QChar ('/') + fileInfo.path (), fileInfoReply);
    }
    reply.setObject (allFileInfoReply);
    _payload = reply.toJson ();

    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 200);

    setFinished (true);
    if (bytesAvailable ()) {
        emit readyRead ();
    }

    emit metaDataChanged ();
    emit finished ();
}

void FakePutMultiFileReply.abort () {
    setError (OperationCanceledError, QStringLiteral ("abort"));
    emit finished ();
}

int64 FakePutMultiFileReply.bytesAvailable () {
    return _payload.size () + QIODevice.bytesAvailable ();
}

int64 FakePutMultiFileReply.readData (char *data, int64 maxlen) {
    int64 len = std.min (int64 { _payload.size () }, maxlen);
    std.copy (_payload.cbegin (), _payload.cbegin () + len, data);
    _payload.remove (0, static_cast<int> (len));
    return len;
}

FakeMkcolReply.FakeMkcolReply (FileInfo &remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest &request, GLib.Object *parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);

    string fileName = getFilePathFromUrl (request.url ());
    Q_ASSERT (!fileName.isEmpty ());
    fileInfo = remoteRootFileInfo.createDir (fileName);

    if (!fileInfo) {
        abort ();
        return;
    }
    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
}

void FakeMkcolReply.respond () {
    setRawHeader ("OC-FileId", fileInfo.fileId);
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 201);
    emit metaDataChanged ();
    emit finished ();
}

FakeDeleteReply.FakeDeleteReply (FileInfo &remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest &request, GLib.Object *parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);

    string fileName = getFilePathFromUrl (request.url ());
    Q_ASSERT (!fileName.isEmpty ());
    remoteRootFileInfo.remove (fileName);
    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
}

void FakeDeleteReply.respond () {
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 204);
    emit metaDataChanged ();
    emit finished ();
}

FakeMoveReply.FakeMoveReply (FileInfo &remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest &request, GLib.Object *parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);

    string fileName = getFilePathFromUrl (request.url ());
    Q_ASSERT (!fileName.isEmpty ());
    string dest = getFilePathFromUrl (QUrl.fromEncoded (request.rawHeader ("Destination")));
    Q_ASSERT (!dest.isEmpty ());
    remoteRootFileInfo.rename (fileName, dest);
    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);
}

void FakeMoveReply.respond () {
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 201);
    emit metaDataChanged ();
    emit finished ();
}

FakeGetReply.FakeGetReply (FileInfo &remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest &request, GLib.Object *parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);

    string fileName = getFilePathFromUrl (request.url ());
    Q_ASSERT (!fileName.isEmpty ());
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
        emit metaDataChanged ();
        emit finished ();
        return;
    }
    payload = fileInfo.contentChar;
    size = fileInfo.size;
    setHeader (QNetworkRequest.ContentLengthHeader, size);
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 200);
    setRawHeader ("OC-ETag", fileInfo.etag);
    setRawHeader ("ETag", fileInfo.etag);
    setRawHeader ("OC-FileId", fileInfo.fileId);
    emit metaDataChanged ();
    if (bytesAvailable ())
        emit readyRead ();
    emit finished ();
}

void FakeGetReply.abort () {
    setError (OperationCanceledError, QStringLiteral ("Operation Canceled"));
    aborted = true;
}

int64 FakeGetReply.bytesAvailable () {
    if (aborted)
        return 0;
    return size + QIODevice.bytesAvailable ();
}

int64 FakeGetReply.readData (char *data, int64 maxlen) {
    int64 len = std.min (int64 { size }, maxlen);
    std.fill_n (data, len, payload);
    size -= len;
    return len;
}

FakeGetWithDataReply.FakeGetWithDataReply (FileInfo &remoteRootFileInfo, QByteArray &data, QNetworkAccessManager.Operation op, QNetworkRequest &request, GLib.Object *parent)
    : FakeReply { parent } {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);

    Q_ASSERT (!data.isEmpty ());
    payload = data;
    string fileName = getFilePathFromUrl (request.url ());
    Q_ASSERT (!fileName.isEmpty ());
    fileInfo = remoteRootFileInfo.find (fileName);
    QMetaObject.invokeMethod (this, "respond", Qt.QueuedConnection);

    if (request.hasRawHeader ("Range")) {
        const string range = string.fromUtf8 (request.rawHeader ("Range"));
        const QRegularExpression bytesPattern (QStringLiteral ("bytes= (?<start>\\d+)- (?<end>\\d+)"));
        const QRegularExpressionMatch match = bytesPattern.match (range);
        if (match.hasMatch ()) {
            const int start = match.captured (QStringLiteral ("start")).toInt ();
            const int end = match.captured (QStringLiteral ("end")).toInt ();
            payload = payload.mid (start, end - start + 1);
        }
    }
}

void FakeGetWithDataReply.respond () {
    if (aborted) {
        setError (OperationCanceledError, QStringLiteral ("Operation Canceled"));
        emit metaDataChanged ();
        emit finished ();
        return;
    }
    setHeader (QNetworkRequest.ContentLengthHeader, payload.size ());
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 200);
    setRawHeader ("OC-ETag", fileInfo.etag);
    setRawHeader ("ETag", fileInfo.etag);
    setRawHeader ("OC-FileId", fileInfo.fileId);
    emit metaDataChanged ();
    if (bytesAvailable ())
        emit readyRead ();
    emit finished ();
}

void FakeGetWithDataReply.abort () {
    setError (OperationCanceledError, QStringLiteral ("Operation Canceled"));
    aborted = true;
}

int64 FakeGetWithDataReply.bytesAvailable () {
    if (aborted)
        return 0;
    return payload.size () - offset + QIODevice.bytesAvailable ();
}

int64 FakeGetWithDataReply.readData (char *data, int64 maxlen) {
    int64 len = std.min (payload.size () - offset, uint64 (maxlen));
    std.memcpy (data, payload.constData () + offset, len);
    offset += len;
    return len;
}

FakeChunkMoveReply.FakeChunkMoveReply (FileInfo &uploadsFileInfo, FileInfo &remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest &request, GLib.Object *parent)
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

FileInfo *FakeChunkMoveReply.perform (FileInfo &uploadsFileInfo, FileInfo &remoteRootFileInfo, QNetworkRequest &request) {
    string source = getFilePathFromUrl (request.url ());
    Q_ASSERT (!source.isEmpty ());
    Q_ASSERT (source.endsWith (QLatin1String ("/.file")));
    source = source.left (source.length () - static_cast<int> (qstrlen ("/.file")));

    auto sourceFolder = uploadsFileInfo.find (source);
    Q_ASSERT (sourceFolder);
    Q_ASSERT (sourceFolder.isDir);
    int count = 0;
    qlonglong size = 0;
    char payload = '\0';

    string fileName = getFilePathFromUrl (QUrl.fromEncoded (request.rawHeader ("Destination")));
    Q_ASSERT (!fileName.isEmpty ());

    // Compute the size and content from the chunks if possible
    for (auto chunkName : sourceFolder.children.keys ()) {
        auto &x = sourceFolder.children[chunkName];
        Q_ASSERT (!x.isDir);
        Q_ASSERT (x.size > 0); // There should not be empty chunks
        size += x.size;
        Q_ASSERT (!payload || payload == x.contentChar);
        payload = x.contentChar;
        ++count;
    }
    Q_ASSERT (sourceFolder.children.count () == count); // There should not be holes or extra files

    // NOTE : This does not actually assemble the file data from the chunks!
    FileInfo *fileInfo = remoteRootFileInfo.find (fileName);
    if (fileInfo) {
        // The client should put this header
        Q_ASSERT (request.hasRawHeader ("If"));

        // And it should condition on the destination file
        auto start = QByteArray ("<" + request.rawHeader ("Destination") + ">");
        Q_ASSERT (request.rawHeader ("If").startsWith (start));

        if (request.rawHeader ("If") != start + " ([\"" + fileInfo.etag + "\"])") {
            return nullptr;
        }
        fileInfo.size = size;
        fileInfo.contentChar = payload;
    } else {
        Q_ASSERT (!request.hasRawHeader ("If"));
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
    emit metaDataChanged ();
    emit finished ();
}

void FakeChunkMoveReply.respondPreconditionFailed () {
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 412);
    setError (InternalServerError, QStringLiteral ("Precondition Failed"));
    emit metaDataChanged ();
    emit finished ();
}

void FakeChunkMoveReply.abort () {
    setError (OperationCanceledError, QStringLiteral ("abort"));
    emit finished ();
}

FakePayloadReply.FakePayloadReply (QNetworkAccessManager.Operation op, QNetworkRequest &request, QByteArray &body, GLib.Object *parent)
    : FakePayloadReply (op, request, body, FakePayloadReply.defaultDelay, parent) {
}

FakePayloadReply.FakePayloadReply (
    QNetworkAccessManager.Operation op, QNetworkRequest &request, QByteArray &body, int delay, GLib.Object *parent)
    : FakeReply{parent}
    , _body (body) {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);
    QTimer.singleShot (delay, this, &FakePayloadReply.respond);
}

void FakePayloadReply.respond () {
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, 200);
    setHeader (QNetworkRequest.ContentLengthHeader, _body.size ());
    emit metaDataChanged ();
    emit readyRead ();
    setFinished (true);
    emit finished ();
}

int64 FakePayloadReply.readData (char *buf, int64 max) {
    max = qMin<int64> (max, _body.size ());
    memcpy (buf, _body.constData (), max);
    _body = _body.mid (max);
    return max;
}

int64 FakePayloadReply.bytesAvailable () {
    return _body.size ();
}

FakeErrorReply.FakeErrorReply (QNetworkAccessManager.Operation op, QNetworkRequest &request, GLib.Object *parent, int httpErrorCode, QByteArray &body)
    : FakeReply { parent }
    , _body (body) {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);
    setAttribute (QNetworkRequest.HttpStatusCodeAttribute, httpErrorCode);
    setError (InternalServerError, QStringLiteral ("Internal Server Fake Error"));
    QMetaObject.invokeMethod (this, &FakeErrorReply.respond, Qt.QueuedConnection);
}

void FakeErrorReply.respond () {
    emit metaDataChanged ();
    emit readyRead ();
    // finishing can come strictly after readyRead was called
    QTimer.singleShot (5, this, &FakeErrorReply.slotSetFinished);
}

void FakeErrorReply.slotSetFinished () {
    setFinished (true);
    emit finished ();
}

int64 FakeErrorReply.readData (char *buf, int64 max) {
    max = qMin<int64> (max, _body.size ());
    memcpy (buf, _body.constData (), max);
    _body = _body.mid (max);
    return max;
}

int64 FakeErrorReply.bytesAvailable () {
    return _body.size ();
}

FakeHangingReply.FakeHangingReply (QNetworkAccessManager.Operation op, QNetworkRequest &request, GLib.Object *parent)
    : FakeReply (parent) {
    setRequest (request);
    setUrl (request.url ());
    setOperation (op);
    open (QIODevice.ReadOnly);
}

void FakeHangingReply.abort () {
    // Follow more or less the implementation of QNetworkReplyImpl.abort
    close ();
    setError (OperationCanceledError, tr ("Operation canceled"));
    emit errorOccurred (OperationCanceledError);
    setFinished (true);
    emit finished ();
}

FakeQNAM.FakeQNAM (FileInfo initialRoot)
    : _remoteRootFileInfo { std.move (initialRoot) } {
    setCookieJar (new Occ.CookieJar);
}

QJsonObject FakeQNAM.forEachReplyPart (QIODevice *outgoingData,
                                       const string &contentType,
                                       std.function<QJsonObject (QMap<string, QByteArray> &)> replyFunction) {
    auto fullReply = QJsonObject{};
    auto putPayload = outgoingData.peek (outgoingData.bytesAvailable ());
    outgoingData.reset ();
    auto stringPutPayload = string.fromUtf8 (putPayload);
    constexpr int boundaryPosition = sizeof ("multipart/related; boundary=");
    const string boundaryValue = QStringLiteral ("--") + contentType.mid (boundaryPosition, contentType.length () - boundaryPosition - 1) + QStringLiteral ("\r\n");
    auto stringPutPayloadRef = string{stringPutPayload}.left (stringPutPayload.size () - 2 - boundaryValue.size ());
    auto allParts = stringPutPayloadRef.split (boundaryValue, Qt.SkipEmptyParts);
    for (auto &onePart : qAsConst (allParts)) {
        auto headerEndPosition = onePart.indexOf (QStringLiteral ("\r\n\r\n"));
        auto onePartHeaderPart = onePart.left (headerEndPosition);
        auto onePartHeaders = onePartHeaderPart.split (QStringLiteral ("\r\n"));
        QMap<string, QByteArray> allHeaders;
        for (auto &oneHeader : qAsConst (onePartHeaders)) {
            auto headerParts = oneHeader.split (QStringLiteral (" : "));
            allHeaders[headerParts.at (0)] = headerParts.at (1).toLatin1 ();
        }

        auto reply = replyFunction (allHeaders);
        if (reply.contains (QStringLiteral ("error")) &&
                reply.contains (QStringLiteral ("etag"))) {
            fullReply.insert (allHeaders[QStringLiteral ("X-File-Path")], reply);
        }
    }

    return fullReply;
}

QNetworkReply *FakeQNAM.createRequest (QNetworkAccessManager.Operation op, QNetworkRequest &request, QIODevice *outgoingData) {
    QNetworkReply *reply = nullptr;
    auto newRequest = request;
    newRequest.setRawHeader ("X-Request-ID", Occ.AccessManager.generateRequestId ());
    auto contentType = request.header (QNetworkRequest.ContentTypeHeader).toString ();
    if (_override) {
        if (auto _reply = _override (op, newRequest, outgoingData)) {
            reply = _reply;
        }
    }
    if (!reply) {
        reply = overrideReplyWithError (getFilePathFromUrl (newRequest.url ()), op, newRequest);
    }
    if (!reply) {
        const bool isUpload = newRequest.url ().path ().startsWith (sUploadUrl.path ());
        FileInfo &info = isUpload ? _uploadFileInfo : _remoteRootFileInfo;

        auto verb = newRequest.attribute (QNetworkRequest.CustomVerbAttribute);
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
            reply = new FakeChunkMoveReply { info, _remoteRootFileInfo, op, newRequest, this };
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

QNetworkReply * FakeQNAM.overrideReplyWithError (string fileName, QNetworkAccessManager.Operation op, QNetworkRequest newRequest) {
    QNetworkReply *reply = nullptr;

    Q_ASSERT (!fileName.isNull ());
    if (_errorPaths.contains (fileName)) {
        reply = new FakeErrorReply { op, newRequest, this, _errorPaths[fileName] };
    }

    return reply;
}

FakeFolder.FakeFolder (FileInfo &fileTemplate, Occ.Optional<FileInfo> &localFileInfo, string &remotePath)
    : _localModifier (_tempDir.path ()) {
    // Needs to be done once
    Occ.SyncEngine.minimumFileAgeForUpload = std.chrono.milliseconds (0);
    Occ.Logger.instance ().setLogFile (QStringLiteral ("-"));
    Occ.Logger.instance ().addLogRule ({ QStringLiteral ("sync.httplogger=true") });

    QDir rootDir { _tempDir.path () };
    qDebug () << "FakeFolder operating on" << rootDir;
    if (localFileInfo) {
        toDisk (rootDir, *localFileInfo);
    } else {
        toDisk (rootDir, fileTemplate);
    }

    _fakeQnam = new FakeQNAM (fileTemplate);
    _account = Occ.Account.create ();
    _account.setUrl (QUrl (QStringLiteral ("http://admin:admin@localhost/owncloud")));
    _account.setCredentials (new FakeCredentials { _fakeQnam });
    _account.setDavDisplayName (QStringLiteral ("fakename"));
    _account.setServerVersion (QStringLiteral ("10.0.0"));

    _journalDb = std.make_unique<Occ.SyncJournalDb> (localPath () + QStringLiteral (".sync_test.db"));
    _syncEngine = std.make_unique<Occ.SyncEngine> (_account, localPath (), remotePath, _journalDb.get ());
    // Ignore temporary files from the download. (This is in the default exclude list, but we don't load it)
    _syncEngine.excludedFiles ().addManualExclude (QStringLiteral ("]*.~*"));

    // handle aboutToRemoveAllFiles with a timeout in case our test does not handle it
    GLib.Object.connect (_syncEngine.get (), &Occ.SyncEngine.aboutToRemoveAllFiles, _syncEngine.get (), [this] (Occ.SyncFileItem.Direction, std.function<void (bool)> callback) {
        QTimer.singleShot (1 * 1000, _syncEngine.get (), [callback] {
            callback (false);
        });
    });

    // Ensure we have a valid VfsOff instance "running"
    switchToVfs (_syncEngine.syncOptions ()._vfs);

    // A new folder will update the local file state database on first sync.
    // To have a state matching what users will encounter, we have to a sync
    // using an identical local/remote file tree first.
    ENFORCE (syncOnce ());
}

void FakeFolder.switchToVfs (QSharedPointer<Occ.Vfs> vfs) {
    auto opts = _syncEngine.syncOptions ();

    opts._vfs.stop ();
    GLib.Object.disconnect (_syncEngine.get (), nullptr, opts._vfs.data (), nullptr);

    opts._vfs = vfs;
    _syncEngine.setSyncOptions (opts);

    Occ.VfsSetupParams vfsParams;
    vfsParams.filesystemPath = localPath ();
    vfsParams.remotePath = QLatin1Char ('/');
    vfsParams.account = _account;
    vfsParams.journal = _journalDb.get ();
    vfsParams.providerName = QStringLiteral ("OC-TEST");
    vfsParams.providerVersion = QStringLiteral ("0.1");
    GLib.Object.connect (_syncEngine.get (), &GLib.Object.destroyed, vfs.data (), [vfs] () {
        vfs.stop ();
        vfs.unregisterFolder ();
    });

    vfs.start (vfsParams);
}

FileInfo FakeFolder.currentLocalState () {
    QDir rootDir { _tempDir.path () };
    FileInfo rootTemplate;
    fromDisk (rootDir, rootTemplate);
    rootTemplate.fixupParentPathRecursively ();
    return rootTemplate;
}

string FakeFolder.localPath () {
    // SyncEngine wants a trailing slash
    if (_tempDir.path ().endsWith (QLatin1Char ('/')))
        return _tempDir.path ();
    return _tempDir.path () + QLatin1Char ('/');
}

void FakeFolder.scheduleSync () {
    // Have to be done async, else, an error before exec () does not terminate the event loop.
    QMetaObject.invokeMethod (_syncEngine.get (), "startSync", Qt.QueuedConnection);
}

void FakeFolder.execUntilBeforePropagation () {
    QSignalSpy spy (_syncEngine.get (), SIGNAL (aboutToPropagate (SyncFileItemVector &)));
    QVERIFY (spy.wait ());
}

void FakeFolder.execUntilItemCompleted (string &relativePath) {
    QSignalSpy spy (_syncEngine.get (), SIGNAL (itemCompleted (SyncFileItemPtr &)));
    QElapsedTimer t;
    t.start ();
    while (t.elapsed () < 5000) {
        spy.clear ();
        QVERIFY (spy.wait ());
        for (QList<QVariant> &args : spy) {
            auto item = args[0].value<Occ.SyncFileItemPtr> ();
            if (item.destination () == relativePath)
                return;
        }
    }
    QVERIFY (false);
}

void FakeFolder.toDisk (QDir &dir, FileInfo &templateFi) {
    foreach (FileInfo &child, templateFi.children) {
        if (child.isDir) {
            QDir subDir (dir);
            dir.mkdir (child.name);
            subDir.cd (child.name);
            toDisk (subDir, child);
        } else {
            QFile file { dir.filePath (child.name) };
            file.open (QFile.WriteOnly);
            file.write (QByteArray {}.fill (child.contentChar, child.size));
            file.close ();
            Occ.FileSystem.setModTime (file.fileName (), Occ.Utility.qDateTimeToTime_t (child.lastModified));
        }
    }
}

void FakeFolder.fromDisk (QDir &dir, FileInfo &templateFi) {
    foreach (QFileInfo &diskChild, dir.entryInfoList (QDir.AllEntries | QDir.NoDotAndDotDot)) {
        if (diskChild.isDir ()) {
            QDir subDir = dir;
            subDir.cd (diskChild.fileName ());
            FileInfo &subFi = templateFi.children[diskChild.fileName ()] = FileInfo { diskChild.fileName () };
            fromDisk (subDir, subFi);
        } else {
            QFile f { diskChild.filePath () };
            f.open (QFile.ReadOnly);
            auto content = f.read (1);
            if (content.size () == 0) {
                qWarning () << "Empty file at:" << diskChild.filePath ();
                continue;
            }
            char contentChar = content.at (0);
            templateFi.children.insert (diskChild.fileName (), FileInfo { diskChild.fileName (), diskChild.size (), contentChar });
        }
    }
}

static FileInfo &findOrCreateDirs (FileInfo &base, PathComponents components) {
    if (components.isEmpty ())
        return base;
    auto childName = components.pathRoot ();
    auto it = base.children.find (childName);
    if (it != base.children.end ()) {
        return findOrCreateDirs (*it, components.subComponents ());
    }
    auto &newDir = base.children[childName] = FileInfo { childName };
    newDir.parentPath = base.path ();
    return findOrCreateDirs (newDir, components.subComponents ());
}

FileInfo FakeFolder.dbState () {
    FileInfo result;
    _journalDb.getFilesBelowPath ("", [&] (Occ.SyncJournalFileRecord &record) {
        auto components = PathComponents (record.path ());
        auto &parentDir = findOrCreateDirs (result, components.parentDirComponents ());
        auto name = components.fileName ();
        auto &item = parentDir.children[name];
        item.name = name;
        item.parentPath = parentDir.path ();
        item.size = record._fileSize;
        item.isDir = record._type == ItemTypeDirectory;
        item.permissions = record._remotePerm;
        item.etag = record._etag;
        item.lastModified = Occ.Utility.qDateTimeFromTime_t (record._modtime);
        item.fileId = record._fileId;
        item.checksums = record._checksumHeader;
        // item.contentChar can't be set from the db
    });
    return result;
}

Occ.SyncFileItemPtr ItemCompletedSpy.findItem (string &path) {
    for (QList<QVariant> &args : *this) {
        auto item = args[0].value<Occ.SyncFileItemPtr> ();
        if (item.destination () == path)
            return item;
    }
    return Occ.SyncFileItemPtr.create ();
}

Occ.SyncFileItemPtr ItemCompletedSpy.findItemWithExpectedRank (string &path, int rank) {
    Q_ASSERT (size () > rank);
    Q_ASSERT (! (*this)[rank].isEmpty ());

    auto item = (*this)[rank][0].value<Occ.SyncFileItemPtr> ();
    if (item.destination () == path) {
        return item;
    } else {
        return Occ.SyncFileItemPtr.create ();
    }
}

FakeReply.FakeReply (GLib.Object *parent)
    : QNetworkReply (parent) {
    setRawHeader (QByteArrayLiteral ("Date"), QDateTime.currentDateTimeUtc ().toString (Qt.RFC2822Date).toUtf8 ());
}

FakeReply.~FakeReply () = default;

FakeJsonErrorReply.FakeJsonErrorReply (QNetworkAccessManager.Operation op,
                                       const QNetworkRequest &request,
                                       GLib.Object *parent,
                                       int httpErrorCode,
                                       const QJsonDocument &reply)
    : FakeErrorReply{ op, request, parent, httpErrorCode, reply.toJson () } {
}
