/***********************************************************
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFileInfo>
// #include <QJsonArray>
// #include <QRegularExpression>

using namespace Occ;

// #pragma once
// #include <QTemporary_file>

namespace Occ {


class Socket_upload_job : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public Socket_upload_job (unowned<Socket_api_job_v2> &job);

    /***********************************************************
    ***********************************************************/
    public 
    public void on_start ();


    /***********************************************************
    ***********************************************************/
    private unowned<Socket_api_job_v2> _api_job;
    private string _local_path;
    private string _remote_path;
    private string _pattern;
    private QTemporary_file _tmp;
    private SyncJournalDb _database;
    private SyncEngine _engine;
    private string[] _synced_files;
};
}









Socket_upload_job.Socket_upload_job (unowned<Socket_api_job_v2> &job)
    : _api_job (job) {
    connect (job.data (), &Socket_api_job_v2.on_finished, this, &Socket_upload_job.delete_later);

    _local_path = _api_job.arguments ()[QLatin1String ("local_path")].to_"";
    _remote_path = _api_job.arguments ()[QLatin1String ("remote_path")].to_"";
    if (!_remote_path.starts_with ('/')) {
        _remote_path = '/' + _remote_path;
    }

    _pattern = job.arguments ()[QLatin1String ("pattern")].to_"";
    // TODO : use uuid
    const var accname = job.arguments ()[QLatin1String ("account")][QLatin1String ("name")].to_"";
    var account = AccountManager.instance ().account (accname);

    if (!QFileInfo (_local_path).is_absolute ()) {
        job.failure (QStringLiteral ("Local path must be a an absolute path"));
        return;
    }
    if (!_tmp.open ()) {
        job.failure (QStringLiteral ("Failed to create temporary database"));
        return;
    }

    _database = new SyncJournalDb (_tmp.file_name (), this);
    _engine = new SyncEngine (account.account (), _local_path.ends_with ('/') ? _local_path : _local_path + '/', _remote_path, _database);
    _engine.set_parent (_database);

    connect (_engine, &Occ.SyncEngine.item_completed, this, [this] (Occ.SyncFileItemPtr item) {
        _synced_files.append (item._file);
    });

    connect (_engine, &Occ.SyncEngine.on_finished, this, [this] (bool ok) {
        if (ok) {
            _api_job.on_success ({
                {
                    "local_path",
                    _local_path
                },
                {
                    "synced_files",
                    QJsonArray.from_string_list (_synced_files)
                }
            });
        }
    });
    connect (_engine, &Occ.SyncEngine.sync_error, this, [this] (string error, ErrorCategory) {
        _api_job.failure (error);
    });
}

void Socket_upload_job.on_start () {
    var opt = _engine.sync_options ();
    opt.set_file_pattern (_pattern);
    if (!opt.file_regex ().is_valid ()) {
        _api_job.failure (opt.file_regex ().error_"");
        return;
    }
    _engine.set_sync_options (opt);

    // create the dir, fail if it already exists
    var mkdir = new Occ.MkColJob (_engine.account (), _remote_path);
    connect (mkdir, &Occ.MkColJob.finished_without_error, _engine, &Occ.SyncEngine.on_start_sync);
    connect (mkdir, &Occ.MkColJob.finished_with_error, this, [this] (QNetworkReply reply) {
        if (reply.error () == 202) {
            _api_job.failure (QStringLiteral ("Destination %1 already exists").arg (_remote_path));
        } else {
            _api_job.failure (reply.error_"");
        }
    });
    mkdir.on_start ();
}
