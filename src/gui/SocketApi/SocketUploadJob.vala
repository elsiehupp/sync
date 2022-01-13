/***********************************************************
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once
// #include <GLib.Object>
// #include <QTemporaryFile>

namespace Occ {


class SocketUploadJob : GLib.Object {
public:
    SocketUploadJob (QSharedPointer<SocketApiJobV2> &job);
    void start ();

private:
    QSharedPointer<SocketApiJobV2> _apiJob;
    string _localPath;
    string _remotePath;
    string _pattern;
    QTemporaryFile _tmp;
    SyncJournalDb *_db;
    SyncEngine *_engine;
    QStringList _syncedFiles;
};
}








/***********************************************************
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QFileInfo>
// #include <QJsonArray>
// #include <QRegularExpression>

using namespace Occ;

SocketUploadJob.SocketUploadJob (QSharedPointer<SocketApiJobV2> &job)
    : _apiJob (job) {
    connect (job.data (), &SocketApiJobV2.finished, this, &SocketUploadJob.deleteLater);

    _localPath = _apiJob.arguments ()[QLatin1String ("localPath")].toString ();
    _remotePath = _apiJob.arguments ()[QLatin1String ("remotePath")].toString ();
    if (!_remotePath.startsWith (QLatin1Char ('/'))) {
        _remotePath = QLatin1Char ('/') + _remotePath;
    }

    _pattern = job.arguments ()[QLatin1String ("pattern")].toString ();
    // TODO : use uuid
    const auto accname = job.arguments ()[QLatin1String ("account")][QLatin1String ("name")].toString ();
    auto account = AccountManager.instance ().account (accname);

    if (!QFileInfo (_localPath).isAbsolute ()) {
        job.failure (QStringLiteral ("Local path must be a an absolute path"));
        return;
    }
    if (!_tmp.open ()) {
        job.failure (QStringLiteral ("Failed to create temporary database"));
        return;
    }

    _db = new SyncJournalDb (_tmp.fileName (), this);
    _engine = new SyncEngine (account.account (), _localPath.endsWith (QLatin1Char ('/')) ? _localPath : _localPath + QLatin1Char ('/'), _remotePath, _db);
    _engine.setParent (_db);

    connect (_engine, &Occ.SyncEngine.itemCompleted, this, [this] (Occ.SyncFileItemPtr item) {
        _syncedFiles.append (item._file);
    });

    connect (_engine, &Occ.SyncEngine.finished, this, [this] (bool ok) {
        if (ok) {
            _apiJob.success ({ { "localPath", _localPath }, { "syncedFiles", QJsonArray.fromStringList (_syncedFiles) } });
        }
    });
    connect (_engine, &Occ.SyncEngine.syncError, this, [this] (string &error, ErrorCategory) {
        _apiJob.failure (error);
    });
}

void SocketUploadJob.start () {
    auto opt = _engine.syncOptions ();
    opt.setFilePattern (_pattern);
    if (!opt.fileRegex ().isValid ()) {
        _apiJob.failure (opt.fileRegex ().errorString ());
        return;
    }
    _engine.setSyncOptions (opt);

    // create the dir, fail if it already exists
    auto mkdir = new Occ.MkColJob (_engine.account (), _remotePath);
    connect (mkdir, &Occ.MkColJob.finishedWithoutError, _engine, &Occ.SyncEngine.startSync);
    connect (mkdir, &Occ.MkColJob.finishedWithError, this, [this] (QNetworkReply *reply) {
        if (reply.error () == 202) {
            _apiJob.failure (QStringLiteral ("Destination %1 already exists").arg (_remotePath));
        } else {
            _apiJob.failure (reply.errorString ());
        }
    });
    mkdir.start ();
}
