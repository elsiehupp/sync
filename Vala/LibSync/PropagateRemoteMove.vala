/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <GLib.File>
// #include <string[]>
// #include <QDir>
// #pragma once

namespace Occ {

/***********************************************************
@brief The Move_job class
@ingroup libsync
***********************************************************/
class Move_job : AbstractNetworkJob {
    const string this.destination;
    const GLib.Uri this.url; // Only used (instead of path) when the constructor taking an URL is used
    QMap<GLib.ByteArray, GLib.ByteArray> this.extra_headers;

    /***********************************************************
    ***********************************************************/
    public Move_job (AccountPointer account, string path, string destination, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public p<GLib.ByteArray, GLib.ByteArray> this.extra_headers, GLib.Object parent = new GLib.Object ());

    public void on_start () override;
    public bool on_finished () override;

signals:
    void finished_signal ();
};

/***********************************************************
@brief The PropagateRemoteMove class
@ingroup libsync
***********************************************************/
class PropagateRemoteMove : PropagateItemJob {
    QPointer<Move_job> this.job;

    /***********************************************************
    ***********************************************************/
    public PropagateRemoteMove (OwncloudPropagator propagator, SyncFileItemPtr item)
        : PropagateItemJob (propagator, item) {
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () override;
    public void on_abort (PropagatorJob.AbortType abort_type) override;
    public JobParallelism parallelism () override {
        return this.item.is_directory () ? WaitForFinished : FullParallelism;
    }


    /***********************************************************
    Rename the directory in the selective sync list
    ***********************************************************/
    public static bool adjust_selective_sync (SyncJournalDb journal, string from, string to);


    /***********************************************************
    ***********************************************************/
    private void on_move_job_finished ();
    private void on_finalize ();
};

    Move_job.Move_job (AccountPointer account, string path,
        const string destination, GLib.Object parent)
        : AbstractNetworkJob (account, path, parent)
        , this.destination (destination) {
    }

    Move_job.Move_job (AccountPointer account, GLib.Uri url, string destination,
        QMap<GLib.ByteArray, GLib.ByteArray> extra_headers, GLib.Object parent)
        : AbstractNetworkJob (account, "", parent)
        , this.destination (destination)
        , this.url (url)
        , this.extra_headers (extra_headers) {
    }

    void Move_job.on_start () {
        Soup.Request req;
        req.set_raw_header ("Destination", GLib.Uri.to_percent_encoding (this.destination, "/"));
        for (var it = this.extra_headers.const_begin (); it != this.extra_headers.const_end (); ++it) {
            req.set_raw_header (it.key (), it.value ());
        }
        if (this.url.is_valid ()) {
            send_request ("MOVE", this.url, req);
        } else {
            send_request ("MOVE", make_dav_url (path ()), req);
        }

        if (reply ().error () != QNetworkReply.NoError) {
            GLib.warn (lc_propagate_remote_move) << " Network error : " << reply ().error_string ();
        }
        AbstractNetworkJob.on_start ();
    }

    bool Move_job.on_finished () {
        q_c_info (lc_move_job) << "MOVE of" << reply ().request ().url () << "FINISHED WITH STATUS"
                          << reply_status_"";

        /* emit */ finished_signal ();
        return true;
    }

    void PropagateRemoteMove.on_start () {
        if (propagator ()._abort_requested)
            return;

        string origin = propagator ().adjust_renamed_path (this.item._file);
        GLib.debug (lc_propagate_remote_move) << origin << this.item._rename_target;

        string target_file (propagator ().full_local_path (this.item._rename_target));

        if (origin == this.item._rename_target) {
            // The parent has been renamed already so there is nothing more to do.

            if (!this.item._encrypted_filename.is_empty ()) {
                // when renaming non-encrypted folder that contains encrypted folder, nested files of its encrypted folder are incorrectly displayed in the Settings dialog
                // encrypted name is displayed instead of a local folder name, unless the sync folder is removed, then added again and re-synced
                // we are fixing it by modifying the "this.encrypted_filename" in such a way so it will have a renamed root path at the beginning of it as expected
                // corrected "this.encrypted_filename" is later used in propagator ().update_metadata () call that will update the record in the Sync journal DB

                const var path = this.item._file;
                const var slash_position = path.last_index_of ('/');
                const var parent_path = slash_position >= 0 ? path.left (slash_position) : "";

                SyncJournalFileRecord parent_rec;
                bool ok = propagator ()._journal.get_file_record (parent_path, parent_rec);
                if (!ok) {
                    on_done (SyncFileItem.Status.NORMAL_ERROR);
                    return;
                }

                const var remote_parent_path = parent_rec._e2e_mangled_name.is_empty () ? parent_path : parent_rec._e2e_mangled_name;

                const var last_slash_position = this.item._encrypted_filename.last_index_of ('/');
                const var encrypted_name = last_slash_position >= 0 ? this.item._encrypted_filename.mid (last_slash_position + 1) : "";

                if (!encrypted_name.is_empty ()) {
                    this.item._encrypted_filename = remote_parent_path + "/" + encrypted_name;
                }
            }

            on_finalize ();
            return;
        }

        string remote_source = propagator ().full_remote_path (origin);
        string remote_destination = QDir.clean_path (propagator ().account ().dav_url ().path () + propagator ().full_remote_path (this.item._rename_target));

        var vfs = propagator ().sync_options ()._vfs;
        var itype = this.item._type;
        ASSERT (itype != ItemTypeVirtualFileDownload && itype != ItemTypeVirtualFileDehydration);
        if (vfs.mode () == Vfs.WithSuffix && itype != ItemTypeDirectory) {
            const var suffix = vfs.file_suffix ();
            bool source_had_suffix = remote_source.ends_with (suffix);
            bool destination_had_suffix = remote_destination.ends_with (suffix);

            // Remote source and destination definitely shouldn't have the suffix
            if (source_had_suffix)
                remote_source.chop (suffix.size ());
            if (destination_had_suffix)
                remote_destination.chop (suffix.size ());

            string folder_target = this.item._rename_target;

            // Users can rename the file and at the same time* add or remove the vfs
            // suffix. That's a complicated case where a remote rename plus a local hydration
            // change is requested. We don't currently deal with that. Instead, the rename
            // is propagated and the local vfs suffix change is reverted.
            // The discovery would still set up this.rename_target without the changed
            // suffix, since that's what must be propagated to the remote but the local
            // file may have a different name. folder_target_alt will contain this potential
            // name.
            string folder_target_alt = folder_target;
            if (itype == ItemTypeFile) {
                ASSERT (!source_had_suffix && !destination_had_suffix);

                // If foo . bar.owncloud, the rename target will be "bar"
                folder_target_alt = folder_target + suffix;

            } else if (itype == ItemTypeVirtualFile) {
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
                if (!FileSystem.unchecked_rename_replace (local_target_alt, local_target, error)) {
                    on_done (SyncFileItem.Status.NORMAL_ERROR, _("Could not rename %1 to %2, error : %3")
                         .arg (folder_target_alt, folder_target, error));
                    return;
                }
                q_c_info (lc_propagate_remote_move) << "Suffix vfs required local rename of"
                                              << folder_target_alt << "to" << folder_target;
            }
        }
        GLib.debug (lc_propagate_remote_move) << remote_source << remote_destination;

        this.job = new Move_job (propagator ().account (), remote_source, remote_destination, this);
        connect (this.job.data (), &Move_job.finished_signal, this, &PropagateRemoteMove.on_move_job_finished);
        propagator ()._active_job_list.append (this);
        this.job.on_start ();
    }

    void PropagateRemoteMove.on_abort (PropagatorJob.AbortType abort_type) {
        if (this.job && this.job.reply ())
            this.job.reply ().on_abort ();

        if (abort_type == AbortType.Asynchronous) {
            /* emit */ abort_finished ();
        }
    }

    void PropagateRemoteMove.on_move_job_finished () {
        propagator ()._active_job_list.remove_one (this);

        ASSERT (this.job);

        QNetworkReply.NetworkError err = this.job.reply ().error ();
        this.item._http_error_code = this.job.reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        this.item._response_time_stamp = this.job.response_timestamp ();
        this.item._request_id = this.job.request_id ();

        if (err != QNetworkReply.NoError) {
            SyncFileItem.Status status = classify_error (err, this.item._http_error_code,
                propagator ()._another_sync_needed);
            on_done (status, this.job.error_string ());
            return;
        }

        if (this.item._http_error_code != 201) {
            // Normally we expect "201 Created"
            // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
            // throw an error.
            on_done (SyncFileItem.Status.NORMAL_ERROR,
                _("Wrong HTTP code returned by server. Expected 201, but received \"%1 %2\".")
                    .arg (this.item._http_error_code)
                    .arg (this.job.reply ().attribute (Soup.Request.HttpReasonPhraseAttribute).to_string ()));
            return;
        }

        on_finalize ();
    }

    void PropagateRemoteMove.on_finalize () {
        // Retrieve old database data.
        // if reading from database failed still continue hoping that delete_file_record
        // reopens the database successfully.
        // The database is only queried to transfer the content checksum from the old
        // to the new record. It is not a problem to skip it here.
        SyncJournalFileRecord old_record;
        propagator ()._journal.get_file_record (this.item._original_file, old_record);
        var vfs = propagator ().sync_options ()._vfs;
        var pin_state = vfs.pin_state (this.item._original_file);

        // Delete old database data.
        propagator ()._journal.delete_file_record (this.item._original_file);
        if (!vfs.set_pin_state (this.item._original_file, PinState.PinState.INHERITED)) {
            GLib.warn (lc_propagate_remote_move) << "Could not set pin state of" << this.item._original_file << "to inherited";
        }

        SyncFileItem new_item (*this.item);
        new_item._type = this.item._type;
        if (old_record.is_valid ()) {
            new_item._checksum_header = old_record._checksum_header;
            if (new_item._size != old_record._file_size) {
                GLib.warn (lc_propagate_remote_move) << "File sizes differ on server vs sync journal : " << new_item._size << old_record._file_size;

                // the server might have claimed a different size, we take the old one from the DB
                new_item._size = old_record._file_size;
            }
        }
        const var result = propagator ().update_metadata (new_item);
        if (!result) {
            on_done (SyncFileItem.Status.FATAL_ERROR, _("Error updating metadata : %1").arg (result.error ()));
            return;
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            on_done (SyncFileItem.Status.SOFT_ERROR, _("The file %1 is currently in use").arg (new_item._file));
            return;
        }
        if (pin_state && *pin_state != PinState.PinState.INHERITED
            && !vfs.set_pin_state (new_item._rename_target, *pin_state)) {
            on_done (SyncFileItem.Status.NORMAL_ERROR, _("Error setting pin state"));
            return;
        }

        if (this.item.is_directory ()) {
            propagator ()._renamed_directories.insert (this.item._file, this.item._rename_target);
            if (!adjust_selective_sync (propagator ()._journal, this.item._file, this.item._rename_target)) {
                on_done (SyncFileItem.Status.FATAL_ERROR, _("Error writing metadata to the database"));
                return;
            }
        }

        propagator ()._journal.commit ("Remote Rename");
        on_done (SyncFileItem.Status.SUCCESS);
    }

    bool PropagateRemoteMove.adjust_selective_sync (SyncJournalDb journal, string from_, string to_) {
        bool ok = false;
        // We only care about preserving the blocklist.   The allow list should anyway be empty.
        // And the undecided list will be repopulated on the next sync, if there is anything too big.
        string[] list = journal.get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok);
        if (!ok)
            return false;

        bool changed = false;
        ASSERT (!from_.ends_with (QLatin1String ("/")));
        ASSERT (!to_.ends_with (QLatin1String ("/")));
        string from = from_ + QLatin1String ("/");
        string to = to_ + QLatin1String ("/");

        for (var s : list) {
            if (s.starts_with (from)) {
                s = s.replace (0, from.size (), to);
                changed = true;
            }
        }

        if (changed) {
            journal.set_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, list);
        }
        return true;
    }
    }
    