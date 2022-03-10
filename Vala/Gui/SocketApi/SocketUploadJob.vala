/***********************************************************
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <GLib.FileInfo>
//  #include <QJsonArray>
//  #include <QRegularExpression>
//  #include <QTemporary_file>

namespace Occ {
namespace Ui {

class SocketUploadJob : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private unowned SocketApiJobV2 api_job;
    private string local_path;
    private string remote_path;
    private string pattern;
    private QTemporary_file tmp;
    private SyncJournalDb database;
    private SyncEngine engine;
    private string[] synced_files;

    /***********************************************************
    ***********************************************************/
    public SocketUploadJob (unowned SocketApiJobV2 job) {
        this.api_job = job;
        connect (job.data (), &SocketApiJobV2.on_signal_finished, this, &SocketUploadJob.delete_later);

        this.local_path = this.api_job.arguments ()[QLatin1String ("local_path")].to_string ();
        this.remote_path = this.api_job.arguments ()[QLatin1String ("remote_path")].to_string ();
        if (!this.remote_path.starts_with ('/')) {
            this.remote_path = '/' + this.remote_path;
        }

        this.pattern = job.arguments ()[QLatin1String ("pattern")].to_string ();
        // TODO: use uuid
        const var accname = job.arguments ()[QLatin1String ("account")][QLatin1String ("name")].to_string ();
        var account = AccountManager.instance ().account (accname);

        if (!GLib.FileInfo (this.local_path).is_absolute ()) {
            job.failure ("Local path must be a an absolute path");
            return;
        }
        if (!this.tmp.open ()) {
            job.failure ("Failed to create temporary database");
            return;
        }

        this.database = new SyncJournalDb (this.tmp.filename (), this);
        this.engine = new SyncEngine (account.account (), this.local_path.ends_with ('/') ? this.local_path : this.local_path + '/', this.remote_path, this.database);
        this.engine.parent (this.database);

        connect (this.engine, &Occ.SyncEngine.item_completed, this, [this] (Occ.SyncFileItemPtr item) {
            this.synced_files.append (item.file);
        });

        connect (this.engine, &Occ.SyncEngine.on_signal_finished, this, [this] (bool ok) {
            if (ok) {
                this.api_job.on_signal_success ({
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

    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        var opt = this.engine.sync_options ();
        opt.file_pattern (this.pattern);
        if (!opt.file_regex ().is_valid ()) {
            this.api_job.failure (opt.file_regex ().error_string ());
            return;
        }
        this.engine.sync_options (opt);

        // create the directory, fail if it already exists
        var mkdir = new Occ.MkColJob (this.engine.account (), this.remote_path);
        connect (mkdir, &Occ.MkColJob.finished_without_error, this.engine, &Occ.SyncEngine.on_signal_start_sync);
        connect (mkdir, &Occ.MkColJob.finished_with_error, this, [this] (Soup.Reply reply) {
            if (reply.error () == 202) {
                this.api_job.failure ("Destination %1 already exists".arg (this.remote_path));
            } else {
                this.api_job.failure (reply.error_string ());
            }
        });
        mkdir.on_signal_start ();
    }

} // class SocketUploadJob

} // namespace Ui
} // namespace Occ
