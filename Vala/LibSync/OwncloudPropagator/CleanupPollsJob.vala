namespace Occ {
namespace LibSync {

/***********************************************************
@class CleanupPollsJob

@brief Job that wait for all the poll jobs to be completed

@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class CleanupPollsJob : GLib.Object {
    GLib.List<Common.SyncJournalDb.PollInfo> poll_infos;
    unowned Account account;
    Common.SyncJournalDb journal;
    string local_path;
    unowned AbstractVfs vfs;

    internal signal void signal_finished ();
    internal signal void signal_aborted (string error);

    /***********************************************************
    ***********************************************************/
    public CleanupPollsJob (
        GLib.List<Common.SyncJournalDb.PollInfo> poll_infos,
        Account account,
        Common.SyncJournalDb journal,
        string local_path,
        AbstractVfs vfs,
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
    public new void start () {
        if (this.poll_infos.empty ()) {
            /* emit */ signal_finished ();
            delete_later ();
            return;
        }

        var info = this.poll_infos.nth_data (0);
        this.poll_infos.pop_front ();
        SyncFileItem item = new SyncFileItem ();
        item.file = info.file;
        item.modtime = info.modtime;
        item.size = info.file_size;
        var poll_job = new PollJob (this.account, info.url, item, this.journal, this.local_path, this);
        poll_job.signal_finished.connect (
            this.on_signal_poll_finished
        );
        poll_job.start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_poll_finished () {
        var poll_job = PollJob)sender ();
        //  ASSERT (poll_job);
        if (poll_job.item.status == SyncFileItem.Status.FATAL_ERROR) {
            /* emit */ aborted (poll_job.item.error_string);
            delete_later ();
            return;
        } else if (poll_job.item.status != SyncFileItem.Status.SUCCESS) {
            GLib.warning ("There was an error with file " + poll_job.item.file + poll_job.item.error_string);
        } else {
            if (!OwncloudPropagator.static_update_metadata (*poll_job.item, this.local_path, this.vfs, this.journal)) {
                GLib.warning ("Database error");
                poll_job.item.status = SyncFileItem.Status.FATAL_ERROR;
                poll_job.item.error_string = _("Error writing metadata to the database");
                /* emit */ aborted (poll_job.item.error_string);
                delete_later ();
                return;
            }
            this.journal.upload_info (poll_job.item.file, Common.SyncJournalDb.UploadInfo ());
        }
        // Continue with the next entry, or finish
        start ();
    }

} // namespace Occ

} // namespace LibSync
} // class CleanupPollsJob
