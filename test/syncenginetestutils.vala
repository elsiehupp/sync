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
