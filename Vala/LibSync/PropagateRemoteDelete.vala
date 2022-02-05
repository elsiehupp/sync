/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>

namespace Occ {

/***********************************************************
@brief The PropagateRemoteDelete class
@ingroup libsync
***********************************************************/
class PropagateRemoteDelete : PropagateItemJob {

    QPointer<DeleteJob> job;
    AbstractPropagateRemoteDeleteEncrypted delete_encrypted_helper = null;

    /***********************************************************
    ***********************************************************/
    public PropagateRemoteDelete (OwncloudPropagator propagator, SyncFileItemPtr item) {
        base (propagator, item);
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () {
        GLib.info (lc_propagate_remote_delete) << "Start propagate remote delete job for" << this.item.file;

        if (propagator ().abort_requested)
            return;

        if (!this.item.encrypted_filename.is_empty () || this.item.is_encrypted) {
            if (!this.item.encrypted_filename.is_empty ()) {
                this.delete_encrypted_helper = new Propagate_remote_delete_encrypted (propagator (), this.item, this);
            } else {
                this.delete_encrypted_helper = new PropagateRemoteDeleteEncryptedRootFolder (propagator (), this.item, this);
            }
            connect (this.delete_encrypted_helper, &AbstractPropagateRemoteDeleteEncrypted.on_finished, this, [this] (bool on_success) {
                if (!on_success) {
                    SyncFileItem.Status status = SyncFileItem.Status.NORMAL_ERROR;
                    if (this.delete_encrypted_helper.network_error () != Soup.Reply.NoError && this.delete_encrypted_helper.network_error () != Soup.Reply.ContentNotFoundError) {
                        status = classify_error (this.delete_encrypted_helper.network_error (), this.item.http_error_code, propagator ().another_sync_needed);
                    }
                    on_done (status, this.delete_encrypted_helper.error_string ());
                } else {
                    on_done (SyncFileItem.Status.SUCCESS);
                }
            });
            this.delete_encrypted_helper.on_start ();
        } else {
            create_delete_job (this.item.file);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void create_delete_job (string filename) {
        GLib.info (lc_propagate_remote_delete) << "Deleting file, local" << this.item.file << "remote" << filename;

        this.job = new DeleteJob (propagator ().account (),
            propagator ().full_remote_path (filename),
            this);

        connect (this.job.data (), &DeleteJob.finished_signal, this, &PropagateRemoteDelete.on_delete_job_finished);
        propagator ().active_job_list.append (this);
        this.job.on_start ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_abort (PropagatorJob.AbortType abort_type) {
        if (this.job && this.job.reply ())
            this.job.reply ().on_abort ();

        if (abort_type == AbortType.ASYNCHRONOUS) {
            /* emit */ abort_finished ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool is_likely_finished_quickly () {
        return !this.item.is_directory ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_delete_job_finished () {
        propagator ().active_job_list.remove_one (this);

        //  ASSERT (this.job);

        Soup.Reply.NetworkError err = this.job.reply ().error ();
        const int http_status = this.job.reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        this.item.http_error_code = http_status;
        this.item.response_time_stamp = this.job.response_timestamp ();
        this.item.request_id = this.job.request_id ();

        if (err != Soup.Reply.NoError && err != Soup.Reply.ContentNotFoundError) {
            SyncFileItem.Status status = classify_error (err, this.item.http_error_code,
                propagator ().another_sync_needed);
            on_done (status, this.job.error_string ());
            return;
        }

        // A 404 reply is also considered a on_success here : We want to make sure
        // a file is gone from the server. It not being there in the first place
        // is ok. This will happen for files that are in the DB but not on
        // the server or the local file system.
        if (http_status != 204 && http_status != 404) {
            // Normally we expect "204 No Content"
            // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
            // throw an error.
            on_done (SyncFileItem.Status.NORMAL_ERROR,
                _("Wrong HTTP code returned by server. Expected 204, but received \"%1 %2\".")
                    .arg (this.item.http_error_code)
                    .arg (this.job.reply ().attribute (Soup.Request.HttpReasonPhraseAttribute).to_string ()));
            return;
        }

        propagator ().journal.delete_file_record (this.item.original_file, this.item.is_directory ());
        propagator ().journal.commit ("Remote Remove");

        on_done (SyncFileItem.Status.SUCCESS);
    }

} // class PropagateRemoteDelete

} // namespace Occ
