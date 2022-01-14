/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFile>
// #include <QStringList>
// #include <QDir>
// #pragma once

namespace Occ {

/***********************************************************
@brief The Move_job class
@ingroup libsync
***********************************************************/
class Move_job : AbstractNetworkJob {
    const string _destination;
    const QUrl _url; // Only used (instead of path) when the constructor taking an URL is used
    QMap<QByteArray, QByteArray> _extra_headers;

public:
    Move_job (AccountPtr account, string &path, string &destination, GLib.Object *parent = nullptr);
    Move_job (AccountPtr account, QUrl &url, string &destination,
        QMap<QByteArray, QByteArray> _extra_headers, GLib.Object *parent = nullptr);

    void start () override;
    bool finished () override;

signals:
    void finished_signal ();
};

/***********************************************************
@brief The Propagate_remote_move class
@ingroup libsync
***********************************************************/
class Propagate_remote_move : Propagate_item_job {
    QPointer<Move_job> _job;

public:
    Propagate_remote_move (Owncloud_propagator *propagator, Sync_file_item_ptr &item)
        : Propagate_item_job (propagator, item) {
    }
    void start () override;
    void abort (Propagator_job.Abort_type abort_type) override;
    Job_parallelism parallelism () override { return _item.is_directory () ? Wait_for_finished : Full_parallelism; }

    /***********************************************************
    Rename the directory in the selective sync list
    ***********************************************************/
    static bool adjust_selective_sync (SyncJournalDb *journal, string &from, string &to);

private slots:
    void slot_move_job_finished ();
    void finalize ();
};

    Move_job.Move_job (AccountPtr account, string &path,
        const string &destination, GLib.Object *parent)
        : AbstractNetworkJob (account, path, parent)
        , _destination (destination) {
    }
    
    Move_job.Move_job (AccountPtr account, QUrl &url, string &destination,
        QMap<QByteArray, QByteArray> extra_headers, GLib.Object *parent)
        : AbstractNetworkJob (account, string (), parent)
        , _destination (destination)
        , _url (url)
        , _extra_headers (extra_headers) {
    }
    
    void Move_job.start () {
        QNetworkRequest req;
        req.set_raw_header ("Destination", QUrl.to_percent_encoding (_destination, "/"));
        for (auto it = _extra_headers.const_begin (); it != _extra_headers.const_end (); ++it) {
            req.set_raw_header (it.key (), it.value ());
        }
        if (_url.is_valid ()) {
            send_request ("MOVE", _url, req);
        } else {
            send_request ("MOVE", make_dav_url (path ()), req);
        }
    
        if (reply ().error () != QNetworkReply.NoError) {
            q_c_warning (lc_propagate_remote_move) << " Network error : " << reply ().error_string ();
        }
        AbstractNetworkJob.start ();
    }
    
    bool Move_job.finished () {
        q_c_info (lc_move_job) << "MOVE of" << reply ().request ().url () << "FINISHED WITH STATUS"
                          << reply_status_string ();
    
        emit finished_signal ();
        return true;
    }
    
    void Propagate_remote_move.start () {
        if (propagator ()._abort_requested)
            return;
    
        string origin = propagator ().adjust_renamed_path (_item._file);
        q_c_debug (lc_propagate_remote_move) << origin << _item._rename_target;
    
        string target_file (propagator ().full_local_path (_item._rename_target));
    
        if (origin == _item._rename_target) {
            // The parent has been renamed already so there is nothing more to do.
    
            if (!_item._encrypted_file_name.is_empty ()) {
                // when renaming non-encrypted folder that contains encrypted folder, nested files of its encrypted folder are incorrectly displayed in the Settings dialog
                // encrypted name is displayed instead of a local folder name, unless the sync folder is removed, then added again and re-synced
                // we are fixing it by modifying the "_encrypted_file_name" in such a way so it will have a renamed root path at the beginning of it as expected
                // corrected "_encrypted_file_name" is later used in propagator ().update_metadata () call that will update the record in the Sync journal DB
    
                const auto path = _item._file;
                const auto slash_position = path.last_index_of ('/');
                const auto parent_path = slash_position >= 0 ? path.left (slash_position) : string ();
    
                SyncJournalFileRecord parent_rec;
                bool ok = propagator ()._journal.get_file_record (parent_path, &parent_rec);
                if (!ok) {
                    done (SyncFileItem.Normal_error);
                    return;
                }
    
                const auto remote_parent_path = parent_rec._e2e_mangled_name.is_empty () ? parent_path : parent_rec._e2e_mangled_name;
    
                const auto last_slash_position = _item._encrypted_file_name.last_index_of ('/');
                const auto encrypted_name = last_slash_position >= 0 ? _item._encrypted_file_name.mid (last_slash_position + 1) : string ();
    
                if (!encrypted_name.is_empty ()) {
                    _item._encrypted_file_name = remote_parent_path + "/" + encrypted_name;
                }
            }
    
            finalize ();
            return;
        }
    
        string remote_source = propagator ().full_remote_path (origin);
        string remote_destination = QDir.clean_path (propagator ().account ().dav_url ().path () + propagator ().full_remote_path (_item._rename_target));
    
        auto &vfs = propagator ().sync_options ()._vfs;
        auto itype = _item._type;
        ASSERT (itype != Item_type_virtual_file_download && itype != ItemTypeVirtualFileDehydration);
        if (vfs.mode () == Vfs.WithSuffix && itype != ItemTypeDirectory) {
            const auto suffix = vfs.file_suffix ();
            bool source_had_suffix = remote_source.ends_with (suffix);
            bool destination_had_suffix = remote_destination.ends_with (suffix);
    
            // Remote source and destination definitely shouldn't have the suffix
            if (source_had_suffix)
                remote_source.chop (suffix.size ());
            if (destination_had_suffix)
                remote_destination.chop (suffix.size ());
    
            string folder_target = _item._rename_target;
    
            // Users can rename the file *and at the same time* add or remove the vfs
            // suffix. That's a complicated case where a remote rename plus a local hydration
            // change is requested. We don't currently deal with that. Instead, the rename
            // is propagated and the local vfs suffix change is reverted.
            // The discovery would still set up _rename_target without the changed
            // suffix, since that's what must be propagated to the remote but the local
            // file may have a different name. folder_target_alt will contain this potential
            // name.
            string folder_target_alt = folder_target;
            if (itype == ItemTypeFile) {
                ASSERT (!source_had_suffix && !destination_had_suffix);
    
                // If foo . bar.owncloud, the rename target will be "bar"
                folder_target_alt = folder_target + suffix;
    
            } else if (itype == Item_type_virtual_file) {
                ASSERT (source_had_suffix && destination_had_suffix);
    
                // If foo.owncloud . bar, the rename target will be "bar.owncloud"
                folder_target_alt.chop (suffix.size ());
            }
    
            string local_target = propagator ().full_local_path (folder_target);
            string local_target_alt = propagator ().full_local_path (folder_target_alt);
    
            // If the expected target doesn't exist but a file with different hydration
            // state does, rename the local file to bring it in line with what the discovery
            // has set up.
            if (!FileSystem.file_exists (local_target) && FileSystem.file_exists (local_target_alt)) {
                string error;
                if (!FileSystem.unchecked_rename_replace (local_target_alt, local_target, &error)) {
                    done (SyncFileItem.Normal_error, tr ("Could not rename %1 to %2, error : %3")
                         .arg (folder_target_alt, folder_target, error));
                    return;
                }
                q_c_info (lc_propagate_remote_move) << "Suffix vfs required local rename of"
                                              << folder_target_alt << "to" << folder_target;
            }
        }
        q_c_debug (lc_propagate_remote_move) << remote_source << remote_destination;
    
        _job = new Move_job (propagator ().account (), remote_source, remote_destination, this);
        connect (_job.data (), &Move_job.finished_signal, this, &Propagate_remote_move.slot_move_job_finished);
        propagator ()._active_job_list.append (this);
        _job.start ();
    }
    
    void Propagate_remote_move.abort (Propagator_job.Abort_type abort_type) {
        if (_job && _job.reply ())
            _job.reply ().abort ();
    
        if (abort_type == Abort_type.Asynchronous) {
            emit abort_finished ();
        }
    }
    
    void Propagate_remote_move.slot_move_job_finished () {
        propagator ()._active_job_list.remove_one (this);
    
        ASSERT (_job);
    
        QNetworkReply.NetworkError err = _job.reply ().error ();
        _item._http_error_code = _job.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
        _item._response_time_stamp = _job.response_timestamp ();
        _item._request_id = _job.request_id ();
    
        if (err != QNetworkReply.NoError) {
            SyncFileItem.Status status = classify_error (err, _item._http_error_code,
                &propagator ()._another_sync_needed);
            done (status, _job.error_string ());
            return;
        }
    
        if (_item._http_error_code != 201) {
            // Normally we expect "201 Created"
            // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
            // throw an error.
            done (SyncFileItem.Normal_error,
                tr ("Wrong HTTP code returned by server. Expected 201, but received \"%1 %2\".")
                    .arg (_item._http_error_code)
                    .arg (_job.reply ().attribute (QNetworkRequest.Http_reason_phrase_attribute).to_string ()));
            return;
        }
    
        finalize ();
    }
    
    void Propagate_remote_move.finalize () {
        // Retrieve old db data.
        // if reading from db failed still continue hoping that delete_file_record
        // reopens the db successfully.
        // The db is only queried to transfer the content checksum from the old
        // to the new record. It is not a problem to skip it here.
        SyncJournalFileRecord old_record;
        propagator ()._journal.get_file_record (_item._original_file, &old_record);
        auto &vfs = propagator ().sync_options ()._vfs;
        auto pin_state = vfs.pin_state (_item._original_file);
    
        // Delete old db data.
        propagator ()._journal.delete_file_record (_item._original_file);
        if (!vfs.set_pin_state (_item._original_file, PinState.Inherited)) {
            q_c_warning (lc_propagate_remote_move) << "Could not set pin state of" << _item._original_file << "to inherited";
        }
    
        SyncFileItem new_item (*_item);
        new_item._type = _item._type;
        if (old_record.is_valid ()) {
            new_item._checksum_header = old_record._checksum_header;
            if (new_item._size != old_record._file_size) {
                q_c_warning (lc_propagate_remote_move) << "File sizes differ on server vs sync journal : " << new_item._size << old_record._file_size;
    
                // the server might have claimed a different size, we take the old one from the DB
                new_item._size = old_record._file_size;
            }
        }
        const auto result = propagator ().update_metadata (new_item);
        if (!result) {
            done (SyncFileItem.Fatal_error, tr ("Error updating metadata : %1").arg (result.error ()));
            return;
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            done (SyncFileItem.Soft_error, tr ("The file %1 is currently in use").arg (new_item._file));
            return;
        }
        if (pin_state && *pin_state != PinState.Inherited
            && !vfs.set_pin_state (new_item._rename_target, *pin_state)) {
            done (SyncFileItem.Normal_error, tr ("Error setting pin state"));
            return;
        }
    
        if (_item.is_directory ()) {
            propagator ()._renamed_directories.insert (_item._file, _item._rename_target);
            if (!adjust_selective_sync (propagator ()._journal, _item._file, _item._rename_target)) {
                done (SyncFileItem.Fatal_error, tr ("Error writing metadata to the database"));
                return;
            }
        }
    
        propagator ()._journal.commit ("Remote Rename");
        done (SyncFileItem.Success);
    }
    
    bool Propagate_remote_move.adjust_selective_sync (SyncJournalDb *journal, string &from_, string &to_) {
        bool ok = false;
        // We only care about preserving the blacklist.   The white list should anyway be empty.
        // And the undecided list will be repopulated on the next sync, if there is anything too big.
        QStringList list = journal.get_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, &ok);
        if (!ok)
            return false;
    
        bool changed = false;
        ASSERT (!from_.ends_with (QLatin1String ("/")));
        ASSERT (!to_.ends_with (QLatin1String ("/")));
        string from = from_ + QLatin1String ("/");
        string to = to_ + QLatin1String ("/");
    
        for (auto &s : list) {
            if (s.starts_with (from)) {
                s = s.replace (0, from.size (), to);
                changed = true;
            }
        }
    
        if (changed) {
            journal.set_selective_sync_list (SyncJournalDb.SelectiveSyncBlackList, list);
        }
        return true;
    }
    }
    