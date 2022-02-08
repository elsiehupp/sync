/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QDir>

namespace Occ {

/***********************************************************
@brief The PropagateRemoteMove class
@ingroup libsync
***********************************************************/
class PropagateRemoteMove : PropagateItemJob {

    QPointer<MoveJob> job;

    /***********************************************************
    ***********************************************************/
    public PropagateRemoteMove (OwncloudPropagator propagator, SyncFileItemPtr item) {
        base (propagator, item);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        if (propagator ().abort_requested)
            return;

        string origin = propagator ().adjust_renamed_path (this.item.file);
        GLib.debug () + origin + this.item.rename_target;

        string target_file (propagator ().full_local_path (this.item.rename_target));

        if (origin == this.item.rename_target) {
            // The parent has been renamed already so there is nothing more to do.

            if (!this.item.encrypted_filename.is_empty ()) {
                // when renaming non-encrypted folder that contains encrypted folder, nested files of its encrypted folder are incorrectly displayed in the Settings dialog
                // encrypted name is displayed instead of a local folder name, unless the sync folder is removed, then added again and re-synced
                // we are fixing it by modifying the "this.encrypted_filename" in such a way so it will have a renamed root path at the beginning of it as expected
                // corrected "this.encrypted_filename" is later used in propagator ().update_metadata () call that will update the record in the Sync journal DB

                const var path = this.item.file;
                const var slash_position = path.last_index_of ('/');
                const var parent_path = slash_position >= 0 ? path.left (slash_position) : "";

                SyncJournalFileRecord parent_rec;
                bool ok = propagator ().journal.get_file_record (parent_path, parent_rec);
                if (!ok) {
                    on_signal_done (SyncFileItem.Status.NORMAL_ERROR);
                    return;
                }

                const var remote_parent_path = parent_rec.e2e_mangled_name.is_empty () ? parent_path : parent_rec.e2e_mangled_name;

                const var last_slash_position = this.item.encrypted_filename.last_index_of ('/');
                const var encrypted_name = last_slash_position >= 0 ? this.item.encrypted_filename.mid (last_slash_position + 1) : "";

                if (!encrypted_name.is_empty ()) {
                    this.item.encrypted_filename = remote_parent_path + "/" + encrypted_name;
                }
            }

            on_signal_finalize ();
            return;
        }

        string remote_source = propagator ().full_remote_path (origin);
        string remote_destination = QDir.clean_path (propagator ().account ().dav_url ().path () + propagator ().full_remote_path (this.item.rename_target));

        var vfs = propagator ().sync_options ().vfs;
        var itype = this.item.type;
        //  ASSERT (itype != ItemTypeVirtualFileDownload && itype != ItemTypeVirtualFileDehydration);
        if (vfs.mode () == Vfs.WithSuffix && itype != ItemTypeDirectory) {
            const var suffix = vfs.file_suffix ();
            bool source_had_suffix = remote_source.ends_with (suffix);
            bool destination_had_suffix = remote_destination.ends_with (suffix);

            // Remote source and destination definitely shouldn't have the suffix
            if (source_had_suffix)
                remote_source.chop (suffix.size ());
            if (destination_had_suffix)
                remote_destination.chop (suffix.size ());

            string folder_target = this.item.rename_target;

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
                //  ASSERT (!source_had_suffix && !destination_had_suffix);

                // If foo . bar.owncloud, the rename target will be "bar"
                folder_target_alt = folder_target + suffix;

            } else if (itype == ItemTypeVirtualFile) {
                //  ASSERT (source_had_suffix && destination_had_suffix);

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
                    on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("Could not rename %1 to %2, error : %3")
                         .arg (folder_target_alt, folder_target, error));
                    return;
                }
                GLib.info ("Suffix vfs required local rename of"
                                              + folder_target_alt + "to" + folder_target;
            }
        }
        GLib.debug () + remote_source + remote_destination;

        this.job = new MoveJob (propagator ().account (), remote_source, remote_destination, this);
        connect (this.job.data (), &MoveJob.finished_signal, this, &PropagateRemoteMove.on_signal_move_job_finished);
        propagator ().active_job_list.append (this);
        this.job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_abort (PropagatorJob.AbortType abort_type) {
        if (this.job && this.job.reply ())
            this.job.reply ().on_signal_abort ();

        if (abort_type == AbortType.ASYNCHRONOUS) {
            /* emit */ abort_finished ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public JobParallelism parallelism () {
        return this.item.is_directory () ? JobParallelism.WAIT_FOR_FINISHED : JobParallelism.FULL_PARALLELISM;
    }


    /***********************************************************
    Rename the directory in the selective sync list
    ***********************************************************/
    public static bool adjust_selective_sync (SyncJournalDb journal, string from_, string to_) {
        bool ok = false;
        // We only care about preserving the blocklist.   The allow list should anyway be empty.
        // And the undecided list will be repopulated on the next sync, if there is anything too big.
        string[] list = journal.get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok);
        if (!ok)
            return false;

        bool changed = false;
        //  ASSERT (!from_.ends_with (QLatin1String ("/")));
        //  ASSERT (!to_.ends_with (QLatin1String ("/")));
        string from = from_ + QLatin1String ("/");
        string to = to_ + QLatin1String ("/");

        for (var s : list) {
            if (s.starts_with (from)) {
                s = s.replace (0, from.size (), to);
                changed = true;
            }
        }

        if (changed) {
            journal.selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, list);
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_move_job_finished () {
        propagator ().active_job_list.remove_one (this);

        //  ASSERT (this.job);

        Soup.Reply.NetworkError err = this.job.reply ().error ();
        this.item.http_error_code = this.job.reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        this.item.response_time_stamp = this.job.response_timestamp ();
        this.item.request_id = this.job.request_id ();

        if (err != Soup.Reply.NoError) {
            SyncFileItem.Status status = classify_error (err, this.item.http_error_code,
                propagator ().another_sync_needed);
            on_signal_done (status, this.job.error_string ());
            return;
        }

        if (this.item.http_error_code != 201) {
            // Normally we expect "201 Created"
            // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
            // throw an error.
            on_signal_done (SyncFileItem.Status.NORMAL_ERROR,
                _("Wrong HTTP code returned by server. Expected 201, but received \"%1 %2\".")
                    .arg (this.item.http_error_code)
                    .arg (this.job.reply ().attribute (Soup.Request.HttpReasonPhraseAttribute).to_string ()));
            return;
        }

        on_signal_finalize ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_finalize () {
        // Retrieve old database data.
        // if reading from database failed still continue hoping that delete_file_record
        // reopens the database successfully.
        // The database is only queried to transfer the content checksum from the old
        // to the new record. It is not a problem to skip it here.
        SyncJournalFileRecord old_record;
        propagator ().journal.get_file_record (this.item.original_file, old_record);
        var vfs = propagator ().sync_options ().vfs;
        var pin_state = vfs.pin_state (this.item.original_file);

        // Delete old database data.
        propagator ().journal.delete_file_record (this.item.original_file);
        if (!vfs.pin_state (this.item.original_file, PinState.PinState.INHERITED)) {
            GLib.warn ("Could not set pin state of" + this.item.original_file + "to inherited";
        }

        SyncFileItem new_item (*this.item);
        new_item.type = this.item.type;
        if (old_record.is_valid ()) {
            new_item.checksum_header = old_record.checksum_header;
            if (new_item.size != old_record.file_size) {
                GLib.warn ("File sizes differ on server vs sync journal : " + new_item.size + old_record.file_size;

                // the server might have claimed a different size, we take the old one from the DB
                new_item.size = old_record.file_size;
            }
        }
        const var result = propagator ().update_metadata (new_item);
        if (!result) {
            on_signal_done (SyncFileItem.Status.FATAL_ERROR, _("Error updating metadata : %1").arg (result.error ()));
            return;
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            on_signal_done (SyncFileItem.Status.SOFT_ERROR, _("The file %1 is currently in use").arg (new_item.file));
            return;
        }
        if (pin_state && *pin_state != PinState.PinState.INHERITED
            && !vfs.pin_state (new_item.rename_target, *pin_state)) {
            on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("Error setting pin state"));
            return;
        }

        if (this.item.is_directory ()) {
            propagator ().renamed_directories.insert (this.item.file, this.item.rename_target);
            if (!adjust_selective_sync (propagator ().journal, this.item.file, this.item.rename_target)) {
                on_signal_done (SyncFileItem.Status.FATAL_ERROR, _("Error writing metadata to the database"));
                return;
            }
        }

        propagator ().journal.commit ("Remote Rename");
        on_signal_done (SyncFileItem.Status.SUCCESS);
    }

} // class PropagateRemoteMove

} // namespace Occ
