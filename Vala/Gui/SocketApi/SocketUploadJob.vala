/***********************************************************
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QFileInfo>
//  #include <QJsonArray>
//  #include <QRegularExpression>

using namespace Occ;

//  #pragma once
//  #include <QTemporary_file>

namespace Occ {


class Socket_upload_job : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public Socket_upload_job (unowned<Socket_api_job_v2> job);

    /***********************************************************
    ***********************************************************/
    public void on_start ();


    /***********************************************************
    ***********************************************************/
    private unowned<Socket_api_job_v2> this.api_job;
    private string this.local_path;
    private string this.remote_path;
    private string this.pattern;
    private QTemporary_file this.tmp;
    private SyncJournalDb this.database;
    private SyncEngine this.engine;
    private string[] this.synced_files;
}
}









Socket_upload_job.Socket_upload_job (unowned<Socket_api_job_v2> job)
    : this.api_job (job) {
    connect (job.data (), &Socket_api_job_v2.on_finished, this, &Socket_upload_job.delete_later);

    this.local_path = this.api_job.arguments ()[QLatin1String ("local_path")].to_string ();
    this.remote_path = this.api_job.arguments ()[QLatin1String ("remote_path")].to_string ();
    if (!this.remote_path.starts_with ('/')) {
        this.remote_path = '/' + this.remote_path;
    }

    this.pattern = job.arguments ()[QLatin1String ("pattern")].to_string ();
    // TODO : use uuid
    const var accname = job.arguments ()[QLatin1String ("account")][QLatin1String ("name")].to_string ();
    var account = AccountManager.instance ().account (accname);

    if (!QFileInfo (this.local_path).is_absolute ()) {
        job.failure (QStringLiteral ("Local path must be a an absolute path"));
        return;
    }
    if (!this.tmp.open ()) {
        job.failure (QStringLiteral ("Failed to create temporary database"));
        return;
    }

    this.database = new SyncJournalDb (this.tmp.filename (), this);
    this.engine = new SyncEngine (account.account (), this.local_path.ends_with ('/') ? this.local_path : this.local_path + '/', this.remote_path, this.database);
    this.engine.parent (this.database);

    connect (this.engine, &Occ.SyncEngine.item_completed, this, [this] (Occ.SyncFileItemPtr item) {
        this.synced_files.append (item.file);
    });

    connect (this.engine, &Occ.SyncEngine.on_finished, this, [this] (bool ok) {
        if (ok) {
            this.api_job.on_success ({
                {
                    "local_path",
                    this.local_path
                },
                {
                    "synced_files",
                    QJsonArray.from_string_list (this.synced_files)
                }
            });
        }
    });
    connect (this.engine, &Occ.SyncEngine.sync_error, this, [this] (string error, ErrorCategory) {
        this.api_job.failure (error);
    });
}

void Socket_upload_job.on_start () {
    var opt = this.engine.sync_options ();
    opt.file_pattern (this.pattern);
    if (!opt.file_regex ().is_valid ()) {
        this.api_job.failure (opt.file_regex ().error_string ());
        return;
    }
    this.engine.sync_options (opt);

    // create the dir, fail if it already exists
    var mkdir = new Occ.MkColJob (this.engine.account (), this.remote_path);
    connect (mkdir, &Occ.MkColJob.finished_without_error, this.engine, &Occ.SyncEngine.on_start_sync);
    connect (mkdir, &Occ.MkColJob.finished_with_error, this, [this] (Soup.Reply reply) {
        if (reply.error () == 202) {
            this.api_job.failure (QStringLiteral ("Destination %1 already exists").arg (this.remote_path));
        } else {
            this.api_job.failure (reply.error_string ());
        }
    });
    mkdir.on_start ();
}
