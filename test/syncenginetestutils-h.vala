/*
 *    This software is in the public domain, furnished "as is", without technical
 *    support, and with no warranty, express or implied, as to its usefulness for
 *    any purpose.
 *
 */
// #pragma once

// #include <QDir>
// #include <QNetworkReply>
// #include <QMap>
// #include <QtTest>

// #include <cstring>
// #include <memory>

// #include <cookiejar.h>
// #include <QTimer>

class QJsonDocument;

/*
 * TODO: In theory we should use QVERIFY instead of Q_ASSERT for testing, but this
 * only works when directly called from a QTest :-(
 */

static const QUrl sRootUrl("owncloud://somehost/owncloud/remote.php/dav/");
static const QUrl sRootUrl2("owncloud://somehost/owncloud/remote.php/dav/files/admin/");
static const QUrl sUploadUrl("owncloud://somehost/owncloud/remote.php/dav/uploads/admin/");

inline QString getFilePathFromUrl(QUrl &url) {
    QString path = url.path();
    if (path.startsWith(sRootUrl2.path()))
        return path.mid(sRootUrl2.path().length());
    if (path.startsWith(sUploadUrl.path()))
        return path.mid(sUploadUrl.path().length());
    if (path.startsWith(sRootUrl.path()))
        return path.mid(sRootUrl.path().length());
    return {};
}

inline QByteArray generateEtag() {
    return QByteArray::number(QDateTime::currentDateTimeUtc().toMSecsSinceEpoch(), 16) + QByteArray::number(OCC::Utility::rand(), 16);
}
inline QByteArray generateFileId() {
    return QByteArray::number(OCC::Utility::rand(), 16);
}

class PathComponents : public QStringList {
public:
    PathComponents(char *path);
    PathComponents(QString &path);
    PathComponents(QStringList &pathComponents);

    PathComponents parentDirComponents() const;
    PathComponents subComponents() const &;
    PathComponents subComponents() && { removeFirst(); return std::move(*this); }
    QString pathRoot() const { return first(); }
    QString fileName() const { return last(); }
};

class FileModifier {
public:
    virtual ~FileModifier() = default;
    virtual void remove(QString &relativePath) = 0;
    virtual void insert(QString &relativePath, qint64 size = 64, char contentChar = 'W') = 0;
    virtual void setContents(QString &relativePath, char contentChar) = 0;
    virtual void appendByte(QString &relativePath) = 0;
    virtual void mkdir(QString &relativePath) = 0;
    virtual void rename(QString &relativePath, QString &relativeDestinationDirectory) = 0;
    virtual void setModTime(QString &relativePath, QDateTime &modTime) = 0;
};

class DiskFileModifier : public FileModifier {
    QDir _rootDir;
public:
    DiskFileModifier(QString &rootDirPath) : _rootDir(rootDirPath) { }
    void remove(QString &relativePath) override;
    void insert(QString &relativePath, qint64 size = 64, char contentChar = 'W') override;
    void setContents(QString &relativePath, char contentChar) override;
    void appendByte(QString &relativePath) override;

    void mkdir(QString &relativePath) override;
    void rename(QString &from, QString &to) override;
    void setModTime(QString &relativePath, QDateTime &modTime) override;
};

class FileInfo : public FileModifier {
public:
    static FileInfo A12_B12_C12_S12();

    FileInfo() = default;
    FileInfo(QString &name) : name{name} { }
    FileInfo(QString &name, qint64 size) : name{name}, isDir{false}, size{size} { }
    FileInfo(QString &name, qint64 size, char contentChar) : name{name}, isDir{false}, size{size}, contentChar{contentChar} { }
    FileInfo(QString &name, std::initializer_list<FileInfo> &children);

    void addChild(FileInfo &info);

    void remove(QString &relativePath) override;

    void insert(QString &relativePath, qint64 size = 64, char contentChar = 'W') override;

    void setContents(QString &relativePath, char contentChar) override;

    void appendByte(QString &relativePath) override;

    void mkdir(QString &relativePath) override;

    void rename(QString &oldPath, QString &newPath) override;

    void setModTime(QString &relativePath, QDateTime &modTime) override;

    FileInfo *find(PathComponents pathComponents, bool invalidateEtags = false);

    FileInfo *createDir(QString &relativePath);

    FileInfo *create(QString &relativePath, qint64 size, char contentChar);

    bool operator<(FileInfo &other) const {
        return name < other.name;
    }

    bool operator==(FileInfo &other) const;

    bool operator!=(FileInfo &other) const {
        return !operator==(other);
    }

    QString path() const;
    QString absolutePath() const;

    void fixupParentPathRecursively();

    QString name;
    int operationStatus = 200;
    bool isDir = true;
    bool isShared = false;
    OCC::RemotePermissions permissions; // When uset, defaults to everything
    QDateTime lastModified = QDateTime::currentDateTimeUtc().addDays(-7);
    QByteArray etag = generateEtag();
    QByteArray fileId = generateFileId();
    QByteArray checksums;
    QByteArray extraDavProperties;
    qint64 size = 0;
    char contentChar = 'W';

    // Sorted by name to be able to compare trees
    QMap<QString, FileInfo> children;
    QString parentPath;

    FileInfo *findInvalidatingEtags(PathComponents pathComponents);

    friend inline QDebug operator<<(QDebug dbg, FileInfo& fi) {
        return dbg << "{ " << fi.path() << ": " << fi.children;
    }
};

class FakeReply : public QNetworkReply {
public:
    FakeReply(QObject *parent);
    ~FakeReply() override;

    // useful to be public for testing
    using QNetworkReply::setRawHeader;
};

class FakePropfindReply : public FakeReply {
public:
    QByteArray payload;

    FakePropfindReply(FileInfo &remoteRootFileInfo, QNetworkAccessManager::Operation op, QNetworkRequest &request, QObject *parent);

    Q_INVOKABLE void respond();

    Q_INVOKABLE void respond404();

    void abort() override { }

    qint64 bytesAvailable() const override;
    qint64 readData(char *data, qint64 maxlen) override;
};

class FakePutReply : public FakeReply {
    FileInfo *fileInfo;
public:
    FakePutReply(FileInfo &remoteRootFileInfo, QNetworkAccessManager::Operation op, QNetworkRequest &request, QByteArray &putPayload, QObject *parent);

    static FileInfo *perform(FileInfo &remoteRootFileInfo, QNetworkRequest &request, QByteArray &putPayload);

    Q_INVOKABLE virtual void respond();

    void abort() override;
    qint64 readData(char *, qint64) override { return 0; }
};

class FakePutMultiFileReply : public FakeReply {
public:
    FakePutMultiFileReply(FileInfo &remoteRootFileInfo, QNetworkAccessManager::Operation op, QNetworkRequest &request, QString &contentType, QByteArray &putPayload, QObject *parent);

    static QVector<FileInfo *> performMultiPart(FileInfo &remoteRootFileInfo, QNetworkRequest &request, QByteArray &putPayload, QString &contentType);

    Q_INVOKABLE virtual void respond();

    void abort() override;

    qint64 bytesAvailable() const override;
    qint64 readData(char *data, qint64 maxlen) override;

private:
    QVector<FileInfo *> _allFileInfo;

    QByteArray _payload;
};

class FakeMkcolReply : public FakeReply {
    FileInfo *fileInfo;
public:
    FakeMkcolReply(FileInfo &remoteRootFileInfo, QNetworkAccessManager::Operation op, QNetworkRequest &request, QObject *parent);

    Q_INVOKABLE void respond();

    void abort() override { }
    qint64 readData(char *, qint64) override { return 0; }
};

class FakeDeleteReply : public FakeReply {
public:
    FakeDeleteReply(FileInfo &remoteRootFileInfo, QNetworkAccessManager::Operation op, QNetworkRequest &request, QObject *parent);

    Q_INVOKABLE void respond();

    void abort() override { }
    qint64 readData(char *, qint64) override { return 0; }
};

class FakeMoveReply : public FakeReply {
public:
    FakeMoveReply(FileInfo &remoteRootFileInfo, QNetworkAccessManager::Operation op, QNetworkRequest &request, QObject *parent);

    Q_INVOKABLE void respond();

    void abort() override { }
    qint64 readData(char *, qint64) override { return 0; }
};

class FakeGetReply : public FakeReply {
public:
    const FileInfo *fileInfo;
    char payload;
    int size;
    bool aborted = false;

    FakeGetReply(FileInfo &remoteRootFileInfo, QNetworkAccessManager::Operation op, QNetworkRequest &request, QObject *parent);

    Q_INVOKABLE void respond();

    void abort() override;
    qint64 bytesAvailable() const override;

    qint64 readData(char *data, qint64 maxlen) override;
};

class FakeGetWithDataReply : public FakeReply {
public:
    const FileInfo *fileInfo;
    QByteArray payload;
    quint64 offset = 0;
    bool aborted = false;

    FakeGetWithDataReply(FileInfo &remoteRootFileInfo, QByteArray &data, QNetworkAccessManager::Operation op, QNetworkRequest &request, QObject *parent);

    Q_INVOKABLE void respond();

    void abort() override;
    qint64 bytesAvailable() const override;

    qint64 readData(char *data, qint64 maxlen) override;
};

class FakeChunkMoveReply : public FakeReply {
    FileInfo *fileInfo;
public:
    FakeChunkMoveReply(FileInfo &uploadsFileInfo, FileInfo &remoteRootFileInfo,
        QNetworkAccessManager::Operation op, QNetworkRequest &request,
        QObject *parent);

    static FileInfo *perform(FileInfo &uploadsFileInfo, FileInfo &remoteRootFileInfo, QNetworkRequest &request);

    Q_INVOKABLE virtual void respond();

    Q_INVOKABLE void respondPreconditionFailed();

    void abort() override;

    qint64 readData(char *, qint64) override { return 0; }
};

class FakePayloadReply : public FakeReply {
public:
    FakePayloadReply(QNetworkAccessManager::Operation op, QNetworkRequest &request,
        const QByteArray &body, QObject *parent);

    FakePayloadReply(QNetworkAccessManager::Operation op, QNetworkRequest &request,
        const QByteArray &body, int delay, QObject *parent);

    void respond();

    void abort() override {}
    qint64 readData(char *buf, qint64 max) override;
    qint64 bytesAvailable() const override;
    QByteArray _body;

    static const int defaultDelay = 10;
};

class FakeErrorReply : public FakeReply {
public:
    FakeErrorReply(QNetworkAccessManager::Operation op, QNetworkRequest &request,
        QObject *parent, int httpErrorCode, QByteArray &body = QByteArray());

    Q_INVOKABLE virtual void respond();

    // make public to give tests easy interface
    using QNetworkReply::setError;
    using QNetworkReply::setAttribute;

public slots:
    void slotSetFinished();

public:
    void abort() override { }
    qint64 readData(char *buf, qint64 max) override;
    qint64 bytesAvailable() const override;

    QByteArray _body;
};

class FakeJsonErrorReply : public FakeErrorReply {
public:
    FakeJsonErrorReply(QNetworkAccessManager::Operation op,
                       const QNetworkRequest &request,
                       QObject *parent,
                       int httpErrorCode,
                       const QJsonDocument &reply = QJsonDocument());
};

// A reply that never responds
class FakeHangingReply : public FakeReply {
public:
    FakeHangingReply(QNetworkAccessManager::Operation op, QNetworkRequest &request, QObject *parent);

    void abort() override;
    qint64 readData(char *, qint64) override { return 0; }
};

// A delayed reply
template <class OriginalReply>
class DelayedReply : public OriginalReply {
public:
    template <typename... Args>
    explicit DelayedReply(quint64 delayMS, Args &&... args)
        : OriginalReply(std::forward<Args>(args)...)
        , _delayMs(delayMS) {
    }
    quint64 _delayMs;

    void respond() override {
        QTimer::singleShot(_delayMs, static_cast<OriginalReply *>(this), [this] {
            // Explicit call to bases's respond();
            this->OriginalReply::respond();
        });
    }
};

class FakeQNAM : public QNetworkAccessManager {
public:
    using Override = std::function<QNetworkReply *(Operation, QNetworkRequest &, QIODevice *)>;

private:
    FileInfo _remoteRootFileInfo;
    FileInfo _uploadFileInfo;
    // maps a path to an HTTP error
    QHash<QString, int> _errorPaths;
    // monitor requests and optionally provide custom replies
    Override _override;

public:
    FakeQNAM(FileInfo initialRoot);
    FileInfo &currentRemoteState() { return _remoteRootFileInfo; }
    FileInfo &uploadState() { return _uploadFileInfo; }

    QHash<QString, int> &errorPaths() { return _errorPaths; }

    void setOverride(Override &override) { _override = override; }

    QJsonObject forEachReplyPart(QIODevice *outgoingData,
                                 const QString &contentType,
                                 std::function<QJsonObject(QMap<QString, QByteArray> &)> replyFunction);

    QNetworkReply *overrideReplyWithError(QString fileName, Operation op, QNetworkRequest newRequest);

protected:
    QNetworkReply *createRequest(Operation op, QNetworkRequest &request,
        QIODevice *outgoingData = nullptr) override;
};

class FakeCredentials : public OCC::AbstractCredentials {
    QNetworkAccessManager *_qnam;
public:
    FakeCredentials(QNetworkAccessManager *qnam) : _qnam{qnam} { }
    QString authType() const override { return "test"; }
    QString user() const override { return "admin"; }
    QString password() const override { return "password"; }
    QNetworkAccessManager *createQNAM() const override { return _qnam; }
    bool ready() const override { return true; }
    void fetchFromKeychain() override { }
    void askFromUser() override { }
    bool stillValid(QNetworkReply *) override { return true; }
    void persist() override { }
    void invalidateToken() override { }
    void forgetSensitiveData() override { }
};

class FakeFolder {
    QTemporaryDir _tempDir;
    DiskFileModifier _localModifier;
    // FIXME: Clarify ownership, double delete
    FakeQNAM *_fakeQnam;
    OCC::AccountPtr _account;
    std::unique_ptr<OCC::SyncJournalDb> _journalDb;
    std::unique_ptr<OCC::SyncEngine> _syncEngine;

public:
    FakeFolder(FileInfo &fileTemplate, OCC::Optional<FileInfo> &localFileInfo = {}, QString &remotePath = {});

    void switchToVfs(QSharedPointer<OCC::Vfs> vfs);

    OCC::AccountPtr account() const { return _account; }
    OCC::SyncEngine &syncEngine() const { return *_syncEngine; }
    OCC::SyncJournalDb &syncJournal() const { return *_journalDb; }

    FileModifier &localModifier() { return _localModifier; }
    FileInfo &remoteModifier() { return _fakeQnam->currentRemoteState(); }
    FileInfo currentLocalState();

    FileInfo currentRemoteState() { return _fakeQnam->currentRemoteState(); }
    FileInfo &uploadState() { return _fakeQnam->uploadState(); }
    FileInfo dbState() const;

    struct ErrorList {
        FakeQNAM *_qnam;
        void append(QString &path, int error = 500) { _qnam->errorPaths().insert(path, error); }
        void clear() { _qnam->errorPaths().clear(); }
    };
    ErrorList serverErrorPaths() { return {_fakeQnam}; }
    void setServerOverride(FakeQNAM::Override &override) { _fakeQnam->setOverride(override); }
    QJsonObject forEachReplyPart(QIODevice *outgoingData,
                                 const QString &contentType,
                                 std::function<QJsonObject(QMap<QString, QByteArray>&)> replyFunction) {
        return _fakeQnam->forEachReplyPart(outgoingData, contentType, replyFunction);
    }

    QString localPath() const;

    void scheduleSync();

    void execUntilBeforePropagation();

    void execUntilItemCompleted(QString &relativePath);

    bool execUntilFinished() {
        QSignalSpy spy(_syncEngine.get(), SIGNAL(finished(bool)));
        bool ok = spy.wait(3600000);
        Q_ASSERT(ok && "Sync timed out");
        return spy[0][0].toBool();
    }

    bool syncOnce() {
        scheduleSync();
        return execUntilFinished();
    }

private:
    static void toDisk(QDir &dir, FileInfo &templateFi);

    static void fromDisk(QDir &dir, FileInfo &templateFi);
};

/* Return the FileInfo for a conflict file for the specified relative filename */
inline const FileInfo *findConflict(FileInfo &dir, QString &filename) {
    QFileInfo info(filename);
    const FileInfo *parentDir = dir.find(info.path());
    if (!parentDir)
        return nullptr;
    QString start = info.baseName() + " (conflicted copy";
    for (auto &item : parentDir->children) {
        if (item.name.startsWith(start)) {
            return &item;
        }
    }
    return nullptr;
}

struct ItemCompletedSpy : QSignalSpy {
    explicit ItemCompletedSpy(FakeFolder &folder)
        : QSignalSpy(&folder.syncEngine(), &OCC::SyncEngine::itemCompleted) {}

    OCC::SyncFileItemPtr findItem(QString &path) const;

    OCC::SyncFileItemPtr findItemWithExpectedRank(QString &path, int rank) const;
};

// QTest::toString overloads
namespace OCC {
    inline char *toString(SyncFileStatus &s) {
        return QTest::toString(QString("SyncFileStatus(" + s.toSocketAPIString() + ")"));
    }
}

inline void addFiles(QStringList &dest, FileInfo &fi) {
    if (fi.isDir) {
        dest += QString("%1 - dir").arg(fi.path());
        foreach (FileInfo &fi, fi.children)
            addFiles(dest, fi);
    } else {
        dest += QString("%1 - %2 %3-bytes").arg(fi.path()).arg(fi.size).arg(fi.contentChar);
    }
}

inline QString toStringNoElide(FileInfo &fi) {
    QStringList files;
    foreach (FileInfo &fi, fi.children)
        addFiles(files, fi);
    files.sort();
    return QString("FileInfo with %1 files(\n\t%2\n)").arg(files.size()).arg(files.join("\n\t"));
}

inline char *toString(FileInfo &fi) {
    return QTest::toString(toStringNoElide(fi));
}

inline void addFilesDbData(QStringList &dest, FileInfo &fi) {
    // could include etag, permissions etc, but would need extra work
    if (fi.isDir) {
        dest += QString("%1 - %2 %3 %4").arg(
            fi.name,
            fi.isDir ? "dir" : "file",
            QString::number(fi.lastModified.toSecsSinceEpoch()),
            fi.fileId);
        foreach (FileInfo &fi, fi.children)
            addFilesDbData(dest, fi);
    } else {
        dest += QString("%1 - %2 %3 %4 %5").arg(
            fi.name,
            fi.isDir ? "dir" : "file",
            QString::number(fi.size),
            QString::number(fi.lastModified.toSecsSinceEpoch()),
            fi.fileId);
    }
}

inline char *printDbData(FileInfo &fi) {
    QStringList files;
    foreach (FileInfo &fi, fi.children)
        addFilesDbData(files, fi);
    return QTest::toString(QString("FileInfo with %1 files(%2)").arg(files.size()).arg(files.join(", ")));
}
