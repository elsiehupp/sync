/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief Job that wait for all the poll jobs to be completed
@ingroup libsync
***********************************************************/
public class CleanupPollsJob : GLib.Object {
    GLib.List<SyncJournalDb.PollInfo> poll_infos;
    unowned Account account;
    SyncJournalDb journal;
    string local_path;
    unowned Vfs vfs;

    signal void signal_finished ();
    signal void aborted (string error);

    /***********************************************************
    ***********************************************************/
    public CleanupPollsJob (
        GLib.List<SyncJournalDb.PollInfo> poll_infos,
        Account account,
        SyncJournalDb journal,
        string local_path,
        Vfs vfs,
        GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.poll_infos = poll_infos;
        this.account = account;
        this.journal = journal;
        this.local_path = local_path;
        this.vfs = vfs;
    }


    /***********************************************************
    Start the job.  After the job is completed, it will emit either on_signal_finished or aborted, and it
    will destroy itself.
    ***********************************************************/
    public void on_signal_start () {
        if (this.poll_infos.empty ()) {
            /* emit */ finished ();
            delete_later ();
            return;
        }

        var info = this.poll_infos.first ();
        this.poll_infos.pop_front ();
        SyncFileItem item = new SyncFileItem ();
        item.file = info.file;
        item.modtime = info.modtime;
        item.size = info.file_size;
        var job = new PollJob (this.account, info.url, item, this.journal, this.local_path, this);
        connect (job, PollJob.signal_finished, this, CleanupPollsJob.on_signal_poll_finished);
        job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_poll_finished () {
        var job = qobject_cast<PollJob> (sender ());
        //  ASSERT (job);
        if (job.item.status == SyncFileItem.Status.FATAL_ERROR) {
            /* emit */ aborted (job.item.error_string);
            delete_later ();
            return;
        } else if (job.item.status != SyncFileItem.Status.SUCCESS) {
            GLib.warning ("There was an error with file " + job.item.file + job.item.error_string);
        } else {
            if (!OwncloudPropagator.static_update_metadata (*job.item, this.local_path, this.vfs.data (), this.journal)) {
                GLib.warning ("Database error");
                job.item.status = SyncFileItem.Status.FATAL_ERROR;
                job.item.error_string = _("Error writing metadata to the database");
                /* emit */ aborted (job.item.error_string);
                delete_later ();
                return;
            }
            this.journal.upload_info (job.item.file, SyncJournalDb.UploadInfo ());
        }
        // Continue with the next entry, or finish
        on_signal_start ();
    }

} // namespace Occ

} // namespace LibSync
} // class CleanupPollsJob
