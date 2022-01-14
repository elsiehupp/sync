/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #pragma once

namespace Occ {



/***********************************************************
@brief The Propagate_remote_delete class
@ingroup libsync
***********************************************************/
class Propagate_remote_delete : Propagate_item_job {
    QPointer<DeleteJob> _job;
    Abstract_propagate_remote_delete_encrypted *_delete_encrypted_helper = nullptr;

public:
    Propagate_remote_delete (Owncloud_propagator *propagator, SyncFileItemPtr &item)
        : Propagate_item_job (propagator, item) {
    }
    void start () override;
    void create_delete_job (string &filename);
    void abort (Propagator_job.Abort_type abort_type) override;

    bool is_likely_finished_quickly () override { return !_item.is_directory (); }

private slots:
    void slot_delete_job_finished ();
};

    void Propagate_remote_delete.start () {
        q_c_info (lc_propagate_remote_delete) << "Start propagate remote delete job for" << _item._file;
    
        if (propagator ()._abort_requested)
            return;
    
        if (!_item._encrypted_file_name.is_empty () || _item._is_encrypted) {
            if (!_item._encrypted_file_name.is_empty ()) {
                _delete_encrypted_helper = new Propagate_remote_delete_encrypted (propagator (), _item, this);
            } else {
                _delete_encrypted_helper = new Propagate_remote_delete_encrypted_root_folder (propagator (), _item, this);
            }
            connect (_delete_encrypted_helper, &Abstract_propagate_remote_delete_encrypted.finished, this, [this] (bool success) {
                if (!success) {
                    SyncFileItem.Status status = SyncFileItem.Normal_error;
                    if (_delete_encrypted_helper.network_error () != QNetworkReply.NoError && _delete_encrypted_helper.network_error () != QNetworkReply.ContentNotFoundError) {
                        status = classify_error (_delete_encrypted_helper.network_error (), _item._http_error_code, &propagator ()._another_sync_needed);
                    }
                    done (status, _delete_encrypted_helper.error_string ());
                } else {
                    done (SyncFileItem.Success);
                }
            });
            _delete_encrypted_helper.start ();
        } else {
            create_delete_job (_item._file);
        }
    }
    
    void Propagate_remote_delete.create_delete_job (string &filename) {
        q_c_info (lc_propagate_remote_delete) << "Deleting file, local" << _item._file << "remote" << filename;
    
        _job = new DeleteJob (propagator ().account (),
            propagator ().full_remote_path (filename),
            this);
    
        connect (_job.data (), &DeleteJob.finished_signal, this, &Propagate_remote_delete.slot_delete_job_finished);
        propagator ()._active_job_list.append (this);
        _job.start ();
    }
    
    void Propagate_remote_delete.abort (Propagator_job.Abort_type abort_type) {
        if (_job && _job.reply ())
            _job.reply ().abort ();
    
        if (abort_type == Abort_type.Asynchronous) {
            emit abort_finished ();
        }
    }
    
    void Propagate_remote_delete.slot_delete_job_finished () {
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
            done (status, _job.error_string ());
            return;
        }
    
        // A 404 reply is also considered a success here : We want to make sure
        // a file is gone from the server. It not being there in the first place
        // is ok. This will happen for files that are in the DB but not on
        // the server or the local file system.
        if (http_status != 204 && http_status != 404) {
            // Normally we expect "204 No Content"
            // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
            // throw an error.
            done (SyncFileItem.Normal_error,
                tr ("Wrong HTTP code returned by server. Expected 204, but received \"%1 %2\".")
                    .arg (_item._http_error_code)
                    .arg (_job.reply ().attribute (QNetworkRequest.Http_reason_phrase_attribute).to_string ()));
            return;
        }
    
        propagator ()._journal.delete_file_record (_item._original_file, _item.is_directory ());
        propagator ()._journal.commit ("Remote Remove");
    
        done (SyncFileItem.Success);
    }
    }
    