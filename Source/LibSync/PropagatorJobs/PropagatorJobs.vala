/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <qfile.h>
// #include <qdir.h>
// #include <qdiriterator.h>
// #include <qtemporaryfile.h>
// #include <qsavefile.h>
// #include <QDateTime>
// #include <qstack.h>
// #include <QCoreApplication>

// #include <ctime>

// #pragma once

// #include <QFile>

namespace Occ {

/***********************************************************
Tags for checksum header.
It's here for being shared between Upload- and Download Job
***********************************************************/
static const char check_sum_header_c[] = "OC-Checksum";
static const char content_md5Header_c[] = "Content-MD5";

/***********************************************************
@brief Declaration of the other propagation jobs
@ingroup libsync
***********************************************************/
class PropagateLocalRemove : PropagateItemJob {

    public PropagateLocalRemove (OwncloudPropagator propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item) {
    }
    public void on_start () override;


    private bool remove_recursively (string path);
    private string _error;
    private bool _move_to_trash;
};

/***********************************************************
@brief The PropagateLocalMkdir class
@ingroup libsync
***********************************************************/
class PropagateLocalMkdir : PropagateItemJob {

    public PropagateLocalMkdir (OwncloudPropagator propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item)
        , _delete_existing_file (false) {
    }
    public void on_start () override;


    /***********************************************************
    Whether an existing file with the same name may be deleted before
    creating the directory.

    Default: false.
    ***********************************************************/
    public void set_delete_existing_file (bool enabled);


    private void start_local_mkdir ();
    private void start_demangling_name (string parent_path);

    private bool _delete_existing_file;
};

/***********************************************************
@brief The PropagateLocalRename class
@ingroup libsync
***********************************************************/
class PropagateLocalRename : PropagateItemJob {

    public PropagateLocalRename (OwncloudPropagator propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item) {
    }
    public void on_start () override;
    public JobParallelism parallelism () override {
        return _item.is_directory () ? WaitForFinished : FullParallelism;
    }
};

    GLib.ByteArray local_file_id_from_full_id (GLib.ByteArray id) {
        return id.left (8);
    }


    /***********************************************************
    The code will update the database in case of error.
    If everything goes well (no error, returns true), the caller is responsible for removing the entries
    in the database.  But in case of error, we need to remove the entries from the database of the files
    that were deleted.

    \a path is relative to propagator ()._local_dir + _item._file and should on_start with a slash
    ***********************************************************/
    bool PropagateLocalRemove.remove_recursively (string path) {
        string absolute = propagator ().full_local_path (_item._file + path);
        string[] errors;
        GLib.List<QPair<string, bool>> deleted;
        bool on_success = FileSystem.remove_recursively (
            absolute,
            [&deleted] (string path, bool is_dir) {
                // by prepending, a folder deletion may be followed by content deletions
                deleted.prepend (q_make_pair (path, is_dir));
            },
            &errors);

        if (!on_success) {
            // We need to delete the entries from the database now from the deleted vector.
            // Do it while avoiding redundant delete calls to the journal.
            string deleted_dir;
            foreach (var &it, deleted) {
                if (!it.first.starts_with (propagator ().local_path ()))
                    continue;
                if (!deleted_dir.is_empty () && it.first.starts_with (deleted_dir))
                    continue;
                if (it.second) {
                    deleted_dir = it.first;
                }
                propagator ()._journal.delete_file_record (it.first.mid (propagator ().local_path ().size ()), it.second);
            }

            _error = errors.join (", ");
        }
        return on_success;
    }

    void PropagateLocalRemove.on_start () {
        q_c_info (lc_propagate_local_remove) << "Start propagate local remove job";

        _move_to_trash = propagator ().sync_options ()._move_files_to_trash;

        if (propagator ()._abort_requested)
            return;

        const string filename = propagator ().full_local_path (_item._file);
        q_c_info (lc_propagate_local_remove) << "Going to delete:" << filename;

        if (propagator ().local_file_name_clash (_item._file)) {
            on_done (SyncFileItem.NormalError, tr ("Could not remove %1 because of a local file name clash").arg (QDir.to_native_separators (filename)));
            return;
        }

        string remove_error;
        if (_move_to_trash) {
            if ( (QDir (filename).exists () || FileSystem.file_exists (filename))
                && !FileSystem.move_to_trash (filename, &remove_error)) {
                on_done (SyncFileItem.NormalError, remove_error);
                return;
            }
        } else {
            if (_item.is_directory ()) {
                if (QDir (filename).exists () && !remove_recursively (string ())) {
                    on_done (SyncFileItem.NormalError, _error);
                    return;
                }
            } else {
                if (FileSystem.file_exists (filename)
                    && !FileSystem.remove (filename, &remove_error)) {
                    on_done (SyncFileItem.NormalError, remove_error);
                    return;
                }
            }
        }
        propagator ().report_progress (*_item, 0);
        propagator ()._journal.delete_file_record (_item._original_file, _item.is_directory ());
        propagator ()._journal.commit ("Local remove");
        on_done (SyncFileItem.Success);
    }

    void PropagateLocalMkdir.on_start () {
        if (propagator ()._abort_requested)
            return;

        start_local_mkdir ();
    }

    void PropagateLocalMkdir.set_delete_existing_file (bool enabled) {
        _delete_existing_file = enabled;
    }

    void PropagateLocalMkdir.start_local_mkdir () {
        QDir new_dir (propagator ().full_local_path (_item._file));
        string new_dir_str = QDir.to_native_separators (new_dir.path ());

        // When turning something that used to be a file into a directory
        // we need to delete the file first.
        QFileInfo fi (new_dir_str);
        if (fi.exists () && fi.is_file ()) {
            if (_delete_existing_file) {
                string remove_error;
                if (!FileSystem.remove (new_dir_str, &remove_error)) {
                    on_done (SyncFileItem.NormalError,
                        tr ("could not delete file %1, error : %2")
                            .arg (new_dir_str, remove_error));
                    return;
                }
            } else if (_item._instruction == CSYNC_INSTRUCTION_CONFLICT) {
                string error;
                if (!propagator ().create_conflict (_item, _associated_composite, &error)) {
                    on_done (SyncFileItem.SoftError, error);
                    return;
                }
            }
        }

        if (Utility.fs_case_preserving () && propagator ().local_file_name_clash (_item._file)) {
            q_c_warning (lc_propagate_local_mkdir) << "New folder to create locally already exists with different case:" << _item._file;
            on_done (SyncFileItem.NormalError, tr ("Attention, possible case sensitivity clash with %1").arg (new_dir_str));
            return;
        }
        emit propagator ().touched_file (new_dir_str);
        QDir local_dir (propagator ().local_path ());
        if (!local_dir.mkpath (_item._file)) {
            on_done (SyncFileItem.NormalError, tr ("Could not create folder %1").arg (new_dir_str));
            return;
        }

        // Insert the directory into the database. The correct etag will be set later,
        // once all contents have been propagated, because should_update_metadata is true.
        // Adding an entry with a dummy etag to the database still makes sense here
        // so the database is aware that this folder exists even if the sync is aborted
        // before the correct etag is stored.
        SyncFileItem new_item (*_item);
        new_item._etag = "_invalid_";
        const var result = propagator ().update_metadata (new_item);
        if (!result) {
            on_done (SyncFileItem.FatalError, tr ("Error updating metadata : %1").arg (result.error ()));
            return;
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            on_done (SyncFileItem.SoftError, tr ("The file %1 is currently in use").arg (new_item._file));
            return;
        }
        propagator ()._journal.commit ("local_mkdir");

        var result_status = _item._instruction == CSYNC_INSTRUCTION_CONFLICT
            ? SyncFileItem.Conflict
            : SyncFileItem.Success;
        on_done (result_status);
    }

    void PropagateLocalRename.on_start () {
        if (propagator ()._abort_requested)
            return;

        string existing_file = propagator ().full_local_path (propagator ().adjust_renamed_path (_item._file));
        string target_file = propagator ().full_local_path (_item._rename_target);

        // if the file is a file underneath a moved dir, the _item.file is equal
        // to _item.rename_target and the file is not moved as a result.
        if (_item._file != _item._rename_target) {
            propagator ().report_progress (*_item, 0);
            q_c_debug (lc_propagate_local_rename) << "MOVE " << existing_file << " => " << target_file;

            if (string.compare (_item._file, _item._rename_target, Qt.CaseInsensitive) != 0
                && propagator ().local_file_name_clash (_item._rename_target)) {
                // Only use local_file_name_clash for the destination if we know that the source was not
                // the one conflicting  (renaming  A.txt . a.txt is OK)

                // Fixme : the file that is the reason for the clash could be named here,
                // it would have to come out the local_file_name_clash function
                on_done (SyncFileItem.NormalError,
                    tr ("File %1 cannot be renamed to %2 because of a local file name clash")
                        .arg (QDir.to_native_separators (_item._file))
                        .arg (QDir.to_native_separators (_item._rename_target)));
                return;
            }

            emit propagator ().touched_file (existing_file);
            emit propagator ().touched_file (target_file);
            string rename_error;
            if (!FileSystem.rename (existing_file, target_file, &rename_error)) {
                on_done (SyncFileItem.NormalError, rename_error);
                return;
            }
        }

        SyncJournalFileRecord old_record;
        propagator ()._journal.get_file_record (_item._original_file, &old_record);
        propagator ()._journal.delete_file_record (_item._original_file);

        var &vfs = propagator ().sync_options ()._vfs;
        var pin_state = vfs.pin_state (_item._original_file);
        if (!vfs.set_pin_state (_item._original_file, PinState.PinState.INHERITED)) {
            q_c_warning (lc_propagate_local_rename) << "Could not set pin state of" << _item._original_file << "to inherited";
        }

        const var old_file = _item._file;

        if (!_item.is_directory ()) { // Directories are saved at the end
            SyncFileItem new_item (*_item);
            if (old_record.is_valid ()) {
                new_item._checksum_header = old_record._checksum_header;
            }
            const var result = propagator ().update_metadata (new_item);
            if (!result) {
                on_done (SyncFileItem.FatalError, tr ("Error updating metadata : %1").arg (result.error ()));
                return;
            } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
                on_done (SyncFileItem.SoftError, tr ("The file %1 is currently in use").arg (new_item._file));
                return;
            }
        } else {
            propagator ()._renamed_directories.insert (old_file, _item._rename_target);
            if (!PropagateRemoteMove.adjust_selective_sync (propagator ()._journal, old_file, _item._rename_target)) {
                on_done (SyncFileItem.FatalError, tr ("Failed to rename file"));
                return;
            }
        }
        if (pin_state && *pin_state != PinState.PinState.INHERITED
            && !vfs.set_pin_state (_item._rename_target, *pin_state)) {
            on_done (SyncFileItem.NormalError, tr ("Error setting pin state"));
            return;
        }

        propagator ()._journal.commit ("local_rename");

        on_done (SyncFileItem.Success);
    }
    }
    