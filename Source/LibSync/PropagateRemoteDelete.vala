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
    QPointer<DeleteJob> _job;
    AbstractPropagateRemoteDeleteEncrypted _delete_encrypted_helper = nullptr;

    /***********************************************************
    ***********************************************************/
    public PropagateRemoteDelete (OwncloudPropagator propagator, SyncFileItemPtr &item)
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
        return !_item.is_directory ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_delete_job_finished ();
};

    void PropagateRemoteDelete.on_start () {
        q_c_info (lc_propagate_remote_delete) << "Start propagate remote delete job for" << _item._file;

        if (propagator ()._abort_requested)
            return;

        if (!_item._encrypted_file_name.is_empty () || _item._is_encrypted) {
            if (!_item._encrypted_file_name.is_empty ()) {
                _delete_encrypted_helper = new Propagate_remote_delete_encrypted (propagator (), _item, this);
            } else {
                _delete_encrypted_helper = new Propagate_remote_delete_encrypted_root_folder (propagator (), _item, this);
            }
            connect (_delete_encrypted_helper, &AbstractPropagateRemoteDeleteEncrypted.on_finished, this, [this] (bool on_success) {
                if (!on_success) {
                    SyncFileItem.Status status = SyncFileItem.NormalError;
                    if (_delete_encrypted_helper.network_error () != QNetworkReply.NoError && _delete_encrypted_helper.network_error () != QNetworkReply.ContentNotFoundError) {
                        status = classify_error (_delete_encrypted_helper.network_error (), _item._http_error_code, &propagator ()._another_sync_needed);
                    }
                    on_done (status, _delete_encrypted_helper.error_"");
                } else {
                    on_done (SyncFileItem.Success);
                }
            });
            _delete_encrypted_helper.on_start ();
        } else {
            create_delete_job (_item._file);
        }
    }

    void PropagateRemoteDelete.create_delete_job (string filename) {
        q_c_info (lc_propagate_remote_delete) << "Deleting file, local" << _item._file << "remote" << filename;

        _job = new DeleteJob (propagator ().account (),
            propagator ().full_remote_path (filename),
            this);

        connect (_job.data (), &DeleteJob.finished_signal, this, &PropagateRemoteDelete.on_delete_job_finished);
        propagator ()._active_job_list.append (this);
        _job.on_start ();
    }

    void PropagateRemoteDelete.on_abort (PropagatorJob.AbortType abort_type) {
        if (_job && _job.reply ())
            _job.reply ().on_abort ();

        if (abort_type == AbortType.Asynchronous) {
            emit abort_finished ();
        }
    }

    void PropagateRemoteDelete.on_delete_job_finished () {
        propagator ()._active_job_list.remove_one (this);

        ASSERT (_job);

        QNetworkReply.NetworkError err = _job.reply ().error ();
        const int http_status = _job.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
        _item._http_error_code = http_status;
        _item._response_time_stamp = _job.response_timestamp ();
        _item._request_id = _job.request_id ();

        if (err != QNetworkReply.NoError && err != QNetworkReply.ContentNotFoundError) {
            SyncFileItem.Status status = classify_error (err, _item._http_error_code,
                &propagator ()._another_sync_needed);
            on_done (status, _job.error_"");
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
            on_done (SyncFileItem.NormalError,
                _("Wrong HTTP code returned by server. Expected 204, but received \"%1 %2\".")
                    .arg (_item._http_error_code)
                    .arg (_job.reply ().attribute (QNetworkRequest.HttpReasonPhraseAttribute).to_""));
            return;
        }

        propagator ()._journal.delete_file_record (_item._original_file, _item.is_directory ());
        propagator ()._journal.commit ("Remote Remove");

        on_done (SyncFileItem.Success);
    }
    }
    