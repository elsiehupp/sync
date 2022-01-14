/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFile>
// #include <QLoggingCategory>
// #pragma once

namespace Occ {


/***********************************************************
@brief The Propagate_remote_mkdir class
@ingroup libsync
***********************************************************/
class Propagate_remote_mkdir : Propagate_item_job {
    QPointer<AbstractNetworkJob> _job;
    bool _delete_existing;
    Propagate_upload_encrypted *_upload_encrypted_helper;
    friend class Propagate_directory; // So it can access the _item;
public:
    Propagate_remote_mkdir (Owncloud_propagator *propagator, SyncFileItemPtr &item);

    void start () override;
    void abort (Propagator_job.Abort_type abort_type) override;

    // Creating a directory should be fast.
    bool is_likely_finished_quickly () override {
        return true;
    }

    /***********************************************************
    Whether an existing entity with the same name may be deleted before
    creating the directory.

    Default: false.
    ***********************************************************/
    void set_delete_existing (bool enabled);

private slots:
    void slot_mkdir ();
    void slot_start_mkcol_job ();
    void slot_start_encrypted_mkcol_job (string &path, string &filename, uint64 size);
    void slot_mkcol_job_finished ();
    void slot_encrypt_folder_finished ();
    void success ();

private:
    void finalize_mk_col_job (QNetworkReply.NetworkError err, string &job_http_reason_phrase_string, string &job_path);
};

    Propagate_remote_mkdir.Propagate_remote_mkdir (Owncloud_propagator *propagator, SyncFileItemPtr &item)
        : Propagate_item_job (propagator, item)
        , _delete_existing (false)
        , _upload_encrypted_helper (nullptr) {
        const auto path = _item._file;
        const auto slash_position = path.last_index_of ('/');
        const auto parent_path = slash_position >= 0 ? path.left (slash_position) : string ();

        SyncJournalFileRecord parent_rec;
        bool ok = propagator._journal.get_file_record (parent_path, &parent_rec);
        if (!ok) {
            return;
        }
    }

    void Propagate_remote_mkdir.start () {
        if (propagator ()._abort_requested)
            return;

        q_c_debug (lc_propagate_remote_mkdir) << _item._file;

        propagator ()._active_job_list.append (this);

        if (!_delete_existing) {
            slot_mkdir ();
            return;
        }

        _job = new DeleteJob (propagator ().account (),
            propagator ().full_remote_path (_item._file),
            this);
        connect (qobject_cast<DeleteJob> (_job), &DeleteJob.finished_signal, this, &Propagate_remote_mkdir.slot_mkdir);
        _job.start ();
    }

    void Propagate_remote_mkdir.slot_start_mkcol_job () {
        if (propagator ()._abort_requested)
            return;

        q_c_debug (lc_propagate_remote_mkdir) << _item._file;

        _job = new Mk_col_job (propagator ().account (),
            propagator ().full_remote_path (_item._file),
            this);
        connect (qobject_cast<Mk_col_job> (_job), &Mk_col_job.finished_with_error, this, &Propagate_remote_mkdir.slot_mkcol_job_finished);
        connect (qobject_cast<Mk_col_job> (_job), &Mk_col_job.finished_without_error, this, &Propagate_remote_mkdir.slot_mkcol_job_finished);
        _job.start ();
    }

    void Propagate_remote_mkdir.slot_start_encrypted_mkcol_job (string &path, string &filename, uint64 size) {
        Q_UNUSED (path)
        Q_UNUSED (size)

        if (propagator ()._abort_requested)
            return;

        q_debug () << filename;
        q_c_debug (lc_propagate_remote_mkdir) << filename;

        auto job = new Mk_col_job (propagator ().account (),
                                propagator ().full_remote_path (filename), {{"e2e-token", _upload_encrypted_helper.folder_token () }},
                                this);
        connect (job, &Mk_col_job.finished_with_error, this, &Propagate_remote_mkdir.slot_mkcol_job_finished);
        connect (job, &Mk_col_job.finished_without_error, this, &Propagate_remote_mkdir.slot_mkcol_job_finished);
        _job = job;
        _job.start ();
    }

    void Propagate_remote_mkdir.abort (Propagator_job.Abort_type abort_type) {
        if (_job && _job.reply ())
            _job.reply ().abort ();

        if (abort_type == Abort_type.Asynchronous) {
            emit abort_finished ();
        }
    }

    void Propagate_remote_mkdir.set_delete_existing (bool enabled) {
        _delete_existing = enabled;
    }

    void Propagate_remote_mkdir.finalize_mk_col_job (QNetworkReply.NetworkError err, string &job_http_reason_phrase_string, string &job_path) {
        if (_item._http_error_code == 405) {
            // This happens when the directory already exists. Nothing to do.
            q_debug (lc_propagate_remote_mkdir) << "Folder" << job_path << "already exists.";
        } else if (err != QNetworkReply.NoError) {
            SyncFileItem.Status status = classify_error (err, _item._http_error_code,
                &propagator ()._another_sync_needed);
            done (status, _item._error_string);
            return;
        } else if (_item._http_error_code != 201) {
            // Normally we expect "201 Created"
            // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
            // throw an error.
            done (SyncFileItem.Normal_error,
                tr ("Wrong HTTP code returned by server. Expected 201, but received \"%1 %2\".")
                    .arg (_item._http_error_code)
                    .arg (job_http_reason_phrase_string));
            return;
        }

        propagator ()._active_job_list.append (this);
        auto propfind_job = new PropfindJob (propagator ().account (), job_path, this);
        propfind_job.set_properties ({"http://owncloud.org/ns:permissions"});
        connect (propfind_job, &PropfindJob.result, this, [this, job_path] (QVariantMap &result){
            propagator ()._active_job_list.remove_one (this);
            _item._remote_perm = RemotePermissions.from_server_string (result.value (QStringLiteral ("permissions")).to_string ());

            if (!_upload_encrypted_helper && !_item._is_encrypted) {
                success ();
            } else {
                // We still need to mark that folder encrypted in case we were uploading it as encrypted one
                // Another scenario, is we are creating a new folder because of move operation on an encrypted folder that works via remove + re-upload
                propagator ()._active_job_list.append (this);

                // We're expecting directory path in /Foo/Bar convention...
                Q_ASSERT (job_path.starts_with ('/') && !job_path.ends_with ('/'));
                // But encryption job expect it in Foo/Bar/ convention
                auto job = new Occ.EncryptFolderJob (propagator ().account (), propagator ()._journal, job_path.mid (1), _item._file_id, this);
                connect (job, &Occ.EncryptFolderJob.finished, this, &Propagate_remote_mkdir.slot_encrypt_folder_finished);
                job.start ();
            }
        });
        connect (propfind_job, &PropfindJob.finished_with_error, this, [this]{
            // ignore the PROPFIND error
            propagator ()._active_job_list.remove_one (this);
            done (SyncFileItem.Normal_error);
        });
        propfind_job.start ();
    }

    void Propagate_remote_mkdir.slot_mkdir () {
        const auto path = _item._file;
        const auto slash_position = path.last_index_of ('/');
        const auto parent_path = slash_position >= 0 ? path.left (slash_position) : string ();

        SyncJournalFileRecord parent_rec;
        bool ok = propagator ()._journal.get_file_record (parent_path, &parent_rec);
        if (!ok) {
            done (SyncFileItem.Normal_error);
            return;
        }

        if (!has_encrypted_ancestor ()) {
            slot_start_mkcol_job ();
            return;
        }

        // We should be encrypted as well since our parent is
        const auto remote_parent_path = parent_rec._e2e_mangled_name.is_empty () ? parent_path : parent_rec._e2e_mangled_name;
        _upload_encrypted_helper = new Propagate_upload_encrypted (propagator (), remote_parent_path, _item, this);
        connect (_upload_encrypted_helper, &Propagate_upload_encrypted.finalized,
            this, &Propagate_remote_mkdir.slot_start_encrypted_mkcol_job);
        connect (_upload_encrypted_helper, &Propagate_upload_encrypted.error,
            [] {
                q_c_debug (lc_propagate_remote_mkdir) << "Error setting up encryption.";
            });
        _upload_encrypted_helper.start ();
    }

    void Propagate_remote_mkdir.slot_mkcol_job_finished () {
        propagator ()._active_job_list.remove_one (this);

        ASSERT (_job);

        QNetworkReply.NetworkError err = _job.reply ().error ();
        _item._http_error_code = _job.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
        _item._response_time_stamp = _job.response_timestamp ();
        _item._request_id = _job.request_id ();

        _item._file_id = _job.reply ().raw_header ("OC-File_id");

        _item._error_string = _job.error_string ();

        const auto job_http_reason_phrase_string = _job.reply ().attribute (QNetworkRequest.Http_reason_phrase_attribute).to_string ();

        const auto job_path = _job.path ();

        if (_upload_encrypted_helper && _upload_encrypted_helper.is_folder_locked () && !_upload_encrypted_helper.is_unlock_running ()) {
            // since we are done, we need to unlock a folder in case it was locked
            connect (_upload_encrypted_helper, &Propagate_upload_encrypted.folder_unlocked, this, [this, err, job_http_reason_phrase_string, job_path] () {
                finalize_mk_col_job (err, job_http_reason_phrase_string, job_path);
            });
            _upload_encrypted_helper.unlock_folder ();
        } else {
            finalize_mk_col_job (err, job_http_reason_phrase_string, job_path);
        }
    }

    void Propagate_remote_mkdir.slot_encrypt_folder_finished () {
        q_c_debug (lc_propagate_remote_mkdir) << "Success making the new folder encrypted";
        propagator ()._active_job_list.remove_one (this);
        _item._is_encrypted = true;
        success ();
    }

    void Propagate_remote_mkdir.success () {
        // Never save the etag on first mkdir.
        // Only fully propagated directories should have the etag set.
        auto item_copy = *_item;
        item_copy._etag.clear ();

        // save the file id already so we can detect rename or remove
        const auto result = propagator ().update_metadata (item_copy);
        if (!result) {
            done (SyncFileItem.Fatal_error, tr ("Error writing metadata to the database : %1").arg (result.error ()));
            return;
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            done (SyncFileItem.Fatal_error, tr ("The file %1 is currently in use").arg (_item._file));
            return;
        }

        done (SyncFileItem.Success);
    }
    }
    