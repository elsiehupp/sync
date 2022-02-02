
/***********************************************************
@brief Job that wait for all the poll jobs to be completed
@ingroup libsync
***********************************************************/
class CleanupPollsJob : GLib.Object {
    GLib.Vector<SyncJournalDb.PollInfo> this.poll_infos;
    AccountPointer this.account;
    SyncJournalDb this.journal;
    string this.local_path;
    unowned<Vfs> this.vfs;

    /***********************************************************
    ***********************************************************/
    public CleanupPollsJob (GLib.Vector<SyncJournalDb.PollInfo> poll_infos, AccountPointer account, SyncJournalDb journal, string local_path,
                             const unowned<Vfs> vfs, GLib.Object parent = new GLib.Object ())
        : GLib.Object (parent)
        , this.poll_infos (poll_infos)
        , this.account (account)
        , this.journal (journal)
        , this.local_path (local_path)
        , this.vfs (vfs) {
    }

    ~CleanupPollsJob () override;


    /***********************************************************
    Start the job.  After the job is completed, it will emit either on_finished or aborted, and it
    will destroy itself.
    ***********************************************************/
    public void on_start ();
signals:
    void on_finished ();
    void aborted (string error);

    /***********************************************************
    ***********************************************************/
    private void on_poll_finished ();
}




    CleanupPollsJob.~CleanupPollsJob () = default;

    void CleanupPollsJob.on_start () {
        if (this.poll_infos.empty ()) {
            /* emit */ finished ();
            delete_later ();
            return;
        }

        var info = this.poll_infos.first ();
        this.poll_infos.pop_front ();
        SyncFileItemPtr item (new SyncFileItem);
        item._file = info._file;
        item._modtime = info._modtime;
        item._size = info._file_size;
        var job = new PollJob (this.account, info._url, item, this.journal, this.local_path, this);
        connect (job, &PollJob.finished_signal, this, &CleanupPollsJob.on_poll_finished);
        job.on_start ();
    }

    void CleanupPollsJob.on_poll_finished () {
        var job = qobject_cast<PollJob> (sender ());
        ASSERT (job);
        if (job._item._status == SyncFileItem.Status.FATAL_ERROR) {
            /* emit */ aborted (job._item._error_string);
            delete_later ();
            return;
        } else if (job._item._status != SyncFileItem.Status.SUCCESS) {
            GLib.warn (lc_cleanup_polls) << "There was an error with file " << job._item._file << job._item._error_string;
        } else {
            if (!OwncloudPropagator.static_update_metadata (*job._item, this.local_path, this.vfs.data (), this.journal)) {
                GLib.warn (lc_cleanup_polls) << "database error";
                job._item._status = SyncFileItem.Status.FATAL_ERROR;
                job._item._error_string = _("Error writing metadata to the database");
                /* emit */ aborted (job._item._error_string);
                delete_later ();
                return;
            }
            this.journal.set_upload_info (job._item._file, SyncJournalDb.UploadInfo ());
        }
        // Continue with the next entry, or finish
        on_start ();
    }