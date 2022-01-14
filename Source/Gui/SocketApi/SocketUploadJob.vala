/***********************************************************
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFileInfo>
// #include <QJsonArray>
// #include <QRegularExpression>

using namespace Occ;

// #pragma once
// #include <GLib.Object>
// #include <QTemporary_file>

namespace Occ {


class Socket_upload_job : GLib.Object {
public:
    Socket_upload_job (QSharedPointer<Socket_api_job_v2> &job);
    void start ();

private:
    QSharedPointer<Socket_api_job_v2> _api_job;
    string _local_path;
    string _remote_path;
    string _pattern;
    QTemporary_file _tmp;
    SyncJournalDb *_db;
    Sync_engine *_engine;
    QStringList _synced_files;
};
}









Socket_upload_job.Socket_upload_job (QSharedPointer<Socket_api_job_v2> &job)
    : _api_job (job) {
    connect (job.data (), &Socket_api_job_v2.finished, this, &Socket_upload_job.delete_later);

    _local_path = _api_job.arguments ()[QLatin1String ("local_path")].to_string ();
    _remote_path = _api_job.arguments ()[QLatin1String ("remote_path")].to_string ();
    if (!_remote_path.starts_with (QLatin1Char ('/'))) {
        _remote_path = QLatin1Char ('/') + _remote_path;
    }

    _pattern = job.arguments ()[QLatin1String ("pattern")].to_string ();
    // TODO : use uuid
    const auto accname = job.arguments ()[QLatin1String ("account")][QLatin1String ("name")].to_string ();
    auto account = AccountManager.instance ().account (accname);

    if (!QFileInfo (_local_path).is_absolute ()) {
        job.failure (QStringLiteral ("Local path must be a an absolute path"));
        return;
    }
    if (!_tmp.open ()) {
        job.failure (QStringLiteral ("Failed to create temporary database"));
        return;
    }

    _db = new SyncJournalDb (_tmp.file_name (), this);
    _engine = new Sync_engine (account.account (), _local_path.ends_with (QLatin1Char ('/')) ? _local_path : _local_path + QLatin1Char ('/'), _remote_path, _db);
    _engine.set_parent (_db);

    connect (_engine, &Occ.Sync_engine.item_completed, this, [this] (Occ.Sync_file_item_ptr item) {
        _synced_files.append (item._file);
    });

    connect (_engine, &Occ.Sync_engine.finished, this, [this] (bool ok) {
        if (ok) {
            _api_job.success ({ { "local_path", _local_path }, { "synced_files", QJsonArray.from_string_list (_synced_files) } });
        }
    });
    connect (_engine, &Occ.Sync_engine.sync_error, this, [this] (string &error, Error_category) {
        _api_job.failure (error);
    });
}

void Socket_upload_job.start () {
    auto opt = _engine.sync_options ();
    opt.set_file_pattern (_pattern);
    if (!opt.file_regex ().is_valid ()) {
        _api_job.failure (opt.file_regex ().error_string ());
        return;
    }
    _engine.set_sync_options (opt);

    // create the dir, fail if it already exists
    auto mkdir = new Occ.Mk_col_job (_engine.account (), _remote_path);
    connect (mkdir, &Occ.Mk_col_job.finished_without_error, _engine, &Occ.Sync_engine.start_sync);
    connect (mkdir, &Occ.Mk_col_job.finished_with_error, this, [this] (QNetworkReply *reply) {
        if (reply.error () == 202) {
            _api_job.failure (QStringLiteral ("Destination %1 already exists").arg (_remote_path));
        } else {
            _api_job.failure (reply.error_string ());
        }
    });
    mkdir.start ();
}
