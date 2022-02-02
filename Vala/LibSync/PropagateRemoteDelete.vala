/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #pragma once

namespace Occ {



/***********************************************************
@brief The PropagateRemoteDelete class
@ingroup libsync
***********************************************************/
class PropagateRemoteDelete : PropagateItemJob {
    QPointer<DeleteJob> this.job;
    AbstractPropagateRemoteDeleteEncrypted this.delete_encrypted_helper = nullptr;

    /***********************************************************
    ***********************************************************/
    public PropagateRemoteDelete (OwncloudPropagator propagator, SyncFileItemPtr item)
        : PropagateItemJob (propagator, item) {
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () override;
    public void create_delete_job (string filename);


    /***********************************************************
    ***********************************************************/
    public void on_abort (PropagatorJob.AbortType abort_type) override;

    /***********************************************************
    ***********************************************************/
    public bool is_likely_finished_quickly () override {
        return !this.item.is_directory ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_delete_job_finished ();
}

    void PropagateRemoteDelete.on_start () {
        q_c_info (lc_propagate_remote_delete) << "Start propagate remote delete job for" << this.item._file;

        if (propagator ()._abort_requested)
            return;

        if (!this.item._encrypted_filename.is_empty () || this.item._is_encrypted) {
            if (!this.item._encrypted_filename.is_empty ()) {
                this.delete_encrypted_helper = new Propagate_remote_delete_encrypted (propagator (), this.item, this);
            } else {
                this.delete_encrypted_helper = new Propagate_remote_delete_encrypted_root_folder (propagator (), this.item, this);
            }
            connect (this.delete_encrypted_helper, &AbstractPropagateRemoteDeleteEncrypted.on_finished, this, [this] (bool on_success) {
                if (!on_success) {
                    SyncFileItem.Status status = SyncFileItem.Status.NORMAL_ERROR;
                    if (this.delete_encrypted_helper.network_error () != Soup.Reply.NoError && this.delete_encrypted_helper.network_error () != Soup.Reply.ContentNotFoundError) {
                        status = classify_error (this.delete_encrypted_helper.network_error (), this.item._http_error_code, propagator ()._another_sync_needed);
                    }
                    on_done (status, this.delete_encrypted_helper.error_string ());
                } else {
                    on_done (SyncFileItem.Status.SUCCESS);
                }
            });
            this.delete_encrypted_helper.on_start ();
        } else {
            create_delete_job (this.item._file);
        }
    }

    void PropagateRemoteDelete.create_delete_job (string filename) {
        q_c_info (lc_propagate_remote_delete) << "Deleting file, local" << this.item._file << "remote" << filename;

        this.job = new DeleteJob (propagator ().account (),
            propagator ().full_remote_path (filename),
            this);

        connect (this.job.data (), &DeleteJob.finished_signal, this, &PropagateRemoteDelete.on_delete_job_finished);
        propagator ()._active_job_list.append (this);
        this.job.on_start ();
    }

    void PropagateRemoteDelete.on_abort (PropagatorJob.AbortType abort_type) {
        if (this.job && this.job.reply ())
            this.job.reply ().on_abort ();

        if (abort_type == AbortType.Asynchronous) {
            /* emit */ abort_finished ();
        }
    }

    void PropagateRemoteDelete.on_delete_job_finished () {
        propagator ()._active_job_list.remove_one (this);

        ASSERT (this.job);

        Soup.Reply.NetworkError err = this.job.reply ().error ();
        const int http_status = this.job.reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        this.item._http_error_code = http_status;
        this.item._response_time_stamp = this.job.response_timestamp ();
        this.item._request_id = this.job.request_id ();

        if (err != Soup.Reply.NoError && err != Soup.Reply.ContentNotFoundError) {
            SyncFileItem.Status status = classify_error (err, this.item._http_error_code,
                propagator ()._another_sync_needed);
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
                    .arg (this.item._http_error_code)
                    .arg (this.job.reply ().attribute (Soup.Request.HttpReasonPhraseAttribute).to_string ()));
            return;
        }

        propagator ()._journal.delete_file_record (this.item._original_file, this.item.is_directory ());
        propagator ()._journal.commit ("Remote Remove");

        on_done (SyncFileItem.Status.SUCCESS);
    }
    }
    