/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <csync_exclude.h>

// #include <QLoggingCategory>
// #include <QFileInfo>
// #include <QTextCodec>
// #include <cstring>

// #pragma once

// #include <QElapsedTimer>
// #include <string[]>
// #include <QMutex>
// #include <QWaitCondition>
// #include <QRunnable>
// #include <deque>


using CSync;
namespace Occ {

enum LocalDiscoveryStyle {
    FilesystemOnly, //< read all local data from the filesystem
    DatabaseAndFilesystem, //< read from the database, except for listed paths
}

class DiscoveryPhase : GLib.Object {

    friend class ProcessDirectoryJob;

    QPointer<ProcessDirectoryJob> this.current_root_job;


    /***********************************************************
    Maps the database-path of a deleted item to its SyncFileItem.

    If it turns out the item was renamed after all, the instruction
    can be changed. See find_and_cancel_deleted_job (). Note that
    item_discovered () will already have been emitted for the item.
    ***********************************************************/
    GLib.HashMap<string, SyncFileItemPtr> this.deleted_item;


    /***********************************************************
    Maps the database-path of a deleted folder to its queued job.

    If a folder is deleted and must be recursed into, its job isn't
    executed immediately. Instead it's queued here and only run
    once the rest of the discovery has on_finished and we are certain
    that the folder wasn't just renamed. This avoids running the
    discovery on contents in the old location of renamed folders.

    See find_and_cancel_deleted_job ().
    ***********************************************************/
    GLib.HashMap<string, ProcessDirectoryJob> this.queued_deleted_directories;

    // map source (original path) . destinations (current server or local path)
    GLib.HashMap<string, string> this.renamed_items_remote;
    GLib.HashMap<string, string> this.renamed_items_local;

    // set of paths that should not be removed even though they are removed locally:
    // there was a move to an invalid destination and now the source should be restored
    //
    // This applies recursively to subdirectories.
    // All entries should have a trailing slash (even files), so lookup with
    // lower_bound () is reliable.
    //
    // The value of this map doesn't matter.
    GLib.HashMap<string, bool> this.forbidden_deletes;


    /***********************************************************
    Returns whether the database-path has been renamed locally or on the remote.

    Useful for avoiding processing of items that have already been claimed in
    a rename (would otherwise be discovered as deletions).
    ***********************************************************/
    bool is_renamed (string p) {
        return this.renamed_items_local.contains (p) || this.renamed_items_remote.contains (p);
    }

    int this.currently_active_jobs = 0;

    // both must contain a sorted list
    string[] this.selective_sync_block_list;
    string[] this.selective_sync_allow_list;

    void schedule_more_jobs ();

    bool is_in_selective_sync_block_list (string path);

    // Check if the new folder should be deselected or not.
    // May be async. "Return" via the callback, true if the item is blocklisted
    void check_selective_sync_new_folder (string path, RemotePermissions rp,
        std.function<void (bool)> callback);


    /***********************************************************
    Given an original path, return the target path obtained when renaming is done.

    Note that it only considers parent directory renames. So if A/B got renamed to C/D,
    checking A/B/file would yield C/D/file, but checking A/B would yield A/B.
    ***********************************************************/
    string adjust_renamed_path (string original, SyncFileItem.Direction);


    /***********************************************************
    If the database-path is scheduled for deletion, on_abort it.

    Check if there is already a job to delete that item:
    If that's not the case, return { false, GLib.ByteArray () }.
    If there is such a job, cancel that job and return true and the old etag.

    Used when having detected a rename : The rename source
    discovered before and would have looked like a delete.

    See this.deleted_item and this.queued_deleted_directories.
    ***********************************************************/
    QPair<bool, GLib.ByteArray> find_and_cancel_deleted_job (string original_path);

    // input
    public string this.local_dir; // absolute path to the local directory. ends with '/'
    public string this.remote_folder; // remote folder, ends with '/'
    public SyncJournalDb this.statedatabase;
    public AccountPointer this.account;
    public SyncOptions this.sync_options;
    public ExcludedFiles this.excludes;
    public QRegularExpression this.invalid_filename_rx; // FIXME : maybe move in ExcludedFiles
    public string[] this.server_blocklisted_files; // The blocklist from the capabilities
    public bool this.ignore_hidden_files = false;
    public std.function<bool (string )> this.should_discover_localy;

    /***********************************************************
    ***********************************************************/
    public void start_job (ProcessDirectoryJob *);

    /***********************************************************
    ***********************************************************/
    public void set_selective_sync_block_list (string[] list);

    /***********************************************************
    ***********************************************************/
    public 
    public void set_selective_sync_allow_list (string[] list);

    // output
    public GLib.ByteArray this.data_fingerprint;
    public bool this.another_sync_needed = false;

signals:
    void fatal_error (string error_string);
    void item_discovered (SyncFileItemPtr item);
    void on_finished ();

    // A new folder was discovered and was not synced because of the confirmation feature
    void new_big_folder (string folder, bool is_external);


    /***********************************************************
    For excluded items that don't show up in item_discovered ()

    The path is relative to the sync folder, similar to item._file
    ***********************************************************/
    void silently_excluded (string folder_path);

    void add_error_to_gui (SyncFileItem.Status status, string error_message, string subject);
}

    /// Implementation of DiscoveryPhase.adjust_renamed_path
    string adjust_renamed_path (GLib.HashMap<string, string> renamed_items, string original);

    /* Given a sorted list of paths ending with '/', return whether or not the given path is within one of the paths of the list*/
    static bool find_path_in_list (string[] list, string path) {
        Q_ASSERT (std.is_sorted (list.begin (), list.end ()));

        if (list.size () == 1 && list.first () == QLatin1String ("/")) {
            // Special case for the case "/" is there, it matches everything
            return true;
        }

        string path_slash = path + '/';

        // Since the list is sorted, we can do a binary search.
        // If the path is a prefix of another item or right after in the lexical order.
        var it = std.lower_bound (list.begin (), list.end (), path_slash);

        if (it != list.end () && *it == path_slash) {
            return true;
        }

        if (it == list.begin ()) {
            return false;
        }
        --it;
        Q_ASSERT (it.ends_with ('/')); // Folder.set_selective_sync_block_list makes sure of that
        return path_slash.starts_with (*it);
    }

    bool DiscoveryPhase.is_in_selective_sync_block_list (string path) {
        if (this.selective_sync_block_list.is_empty ()) {
            // If there is no block list, everything is allowed
            return false;
        }

        // Block if it is in the block list
        if (find_path_in_list (this.selective_sync_block_list, path)) {
            return true;
        }

        return false;
    }

    void DiscoveryPhase.check_selective_sync_new_folder (string path, RemotePermissions remote_perm,
        std.function<void (bool)> callback) {
        if (this.sync_options._confirm_external_storage && this.sync_options._vfs.mode () == Vfs.Off
            && remote_perm.has_permission (RemotePermissions.IsMounted)) {
            // external storage.

            // Note: DiscoverySingleDirectoryJob.on_directory_listing_iterated_slot make sure that only the
            // root of a mounted storage has 'M', all sub entries have 'm'

            // Only allow it if the allow list contains exactly this path (not parents)
            // We want to ask confirmation for external storage even if the parents where selected
            if (this.selective_sync_allow_list.contains (path + '/')) {
                return callback (false);
            }

            /* emit */ new_big_folder (path, true);
            return callback (true);
        }

        // If this path or the parent is in the allow list, then we do not block this file
        if (find_path_in_list (this.selective_sync_allow_list, path)) {
            return callback (false);
        }

        var limit = this.sync_options._new_big_folder_size_limit;
        if (limit < 0 || this.sync_options._vfs.mode () != Vfs.Off) {
            // no limit, everything is allowed;
            return callback (false);
        }

        // do a PROPFIND to know the size of this folder
        var propfind_job = new PropfindJob (this.account, this.remote_folder + path, this);
        propfind_job.set_properties (GLib.List<GLib.ByteArray> () << "resourcetype"
                                                       << "http://owncloud.org/ns:size");
        GLib.Object.connect (propfind_job, &PropfindJob.finished_with_error,
            this, [=] {
                return callback (false);
            });
        GLib.Object.connect (propfind_job, &PropfindJob.result, this, [=] (QVariantMap values) {
            var result = values.value (QLatin1String ("size")).to_long_long ();
            if (result >= limit) {
                // we tell the UI there is a new folder
                /* emit */ new_big_folder (path, false);
                return callback (true);
            } else {
                // it is not too big, put it in the allow list (so we will not do more query for the children)
                // and and do not block.
                var p = path;
                if (!p.ends_with ('/'))
                    p += '/';
                this.selective_sync_allow_list.insert (
                    std.upper_bound (this.selective_sync_allow_list.begin (), this.selective_sync_allow_list.end (), p),
                    p);
                return callback (false);
            }
        });
        propfind_job.on_start ();
    }


    /***********************************************************
    Given a path on the remote, give the path as it is when the rename is done
    ***********************************************************/
    string DiscoveryPhase.adjust_renamed_path (string original, SyncFileItem.Direction d) {
        return Occ.adjust_renamed_path (d == SyncFileItem.Direction.DOWN ? this.renamed_items_remote : this.renamed_items_local, original);
    }

    string adjust_renamed_path (GLib.HashMap<string, string> renamed_items, string original) {
        int slash_pos = original.size ();
        while ( (slash_pos = original.last_index_of ('/', slash_pos - 1)) > 0) {
            var it = renamed_items.const_find (original.left (slash_pos));
            if (it != renamed_items.const_end ()) {
                return it + original.mid (slash_pos);
            }
        }
        return original;
    }

    QPair<bool, GLib.ByteArray> DiscoveryPhase.find_and_cancel_deleted_job (string original_path) {
        bool result = false;
        GLib.ByteArray old_etag;
        var it = this.deleted_item.find (original_path);
        if (it != this.deleted_item.end ()) {
            const SyncInstructions instruction = (*it)._instruction;
            if (instruction == CSYNC_INSTRUCTION_IGNORE && (*it)._type == ItemTypeVirtualFile) {
                // re-creation of virtual files count as a delete
                // a file might be in an error state and thus gets marked as CSYNC_INSTRUCTION_IGNORE
                // after it was initially marked as CSYNC_INSTRUCTION_REMOVE
                // return true, to not trigger any additional actions on that file that could elad to dataloss
                result = true;
                old_etag = (*it)._etag;
            } else {
                if (! (instruction == CSYNC_INSTRUCTION_REMOVE
                        // re-creation of virtual files count as a delete
                        || ( (*it)._type == ItemTypeVirtualFile && instruction == CSYNC_INSTRUCTION_NEW)
                        || ( (*it)._is_restoration && instruction == CSYNC_INSTRUCTION_NEW))) {
                    GLib.warn (lc_discovery) << "ENFORCE (FAILING)" << original_path;
                    GLib.warn (lc_discovery) << "instruction == CSYNC_INSTRUCTION_REMOVE" << (instruction == CSYNC_INSTRUCTION_REMOVE);
                    GLib.warn (lc_discovery) << " ( (*it)._type == ItemTypeVirtualFile && instruction == CSYNC_INSTRUCTION_NEW)"
                                           << ( (*it)._type == ItemTypeVirtualFile && instruction == CSYNC_INSTRUCTION_NEW);
                    GLib.warn (lc_discovery) << " ( (*it)._is_restoration && instruction == CSYNC_INSTRUCTION_NEW))"
                                           << ( (*it)._is_restoration && instruction == CSYNC_INSTRUCTION_NEW);
                    GLib.warn (lc_discovery) << "instruction" << instruction;
                    GLib.warn (lc_discovery) << " (*it)._type" << (*it)._type;
                    GLib.warn (lc_discovery) << " (*it)._is_restoration " << (*it)._is_restoration;
                    Q_ASSERT (false);
                    add_error_to_gui (SyncFileItem.Status.FatalError, _("Error while canceling delete of a file"), original_path);
                    /* emit */ fatal_error (_("Error while canceling delete of %1").arg (original_path));
                }
                (*it)._instruction = CSYNC_INSTRUCTION_NONE;
                result = true;
                old_etag = (*it)._etag;
            }
            this.deleted_item.erase (it);
        }
        if (var other_job = this.queued_deleted_directories.take (original_path)) {
            old_etag = other_job._dir_item._etag;
            delete other_job;
            result = true;
        }
        return {
            result, old_etag
        };
    }

    void DiscoveryPhase.start_job (ProcessDirectoryJob job) {
        ENFORCE (!this.current_root_job);
        connect (job, &ProcessDirectoryJob.on_finished, this, [this, job] {
            ENFORCE (this.current_root_job == sender ());
            this.current_root_job = nullptr;
            if (job._dir_item)
                /* emit */ item_discovered (job._dir_item);
            job.delete_later ();

            // Once the main job has on_finished recurse here to execute the remaining
            // jobs for queued deleted directories.
            if (!this.queued_deleted_directories.is_empty ()) {
                var next_job = this.queued_deleted_directories.take (this.queued_deleted_directories.first_key ());
                start_job (next_job);
            } else {
                /* emit */ finished ();
            }
        });
        this.current_root_job = job;
        job.on_start ();
    }

    void DiscoveryPhase.set_selective_sync_block_list (string[] list) {
        this.selective_sync_block_list = list;
        std.sort (this.selective_sync_block_list.begin (), this.selective_sync_block_list.end ());
    }

    void DiscoveryPhase.set_selective_sync_allow_list (string[] list) {
        this.selective_sync_allow_list = list;
        std.sort (this.selective_sync_allow_list.begin (), this.selective_sync_allow_list.end ());
    }

    void DiscoveryPhase.schedule_more_jobs () {
        var limit = q_max (1, this.sync_options._parallel_network_jobs);
        if (this.current_root_job && this.currently_active_jobs < limit) {
            this.current_root_job.process_sub_jobs (limit - this.currently_active_jobs);
        }
    }

    DiscoverySingleLocalDirectoryJob.DiscoverySingleLocalDirectoryJob (AccountPointer account, string local_path, Occ.Vfs vfs, GLib.Object parent)
     : GLib.Object (parent), QRunnable (), this.local_path (local_path), this.account (account), this.vfs (vfs) {
        q_register_meta_type<GLib.Vector<LocalInfo> > ("GLib.Vector<LocalInfo>");
    }

    // Use as QRunnable
    void DiscoverySingleLocalDirectoryJob.run () {
        string local_path = this.local_path;
        if (local_path.ends_with ('/')) // Happens if this.current_folder._local.is_empty ()
            local_path.chop (1);

        var dh = csync_vio_local_opendir (local_path);
        if (!dh) {
            q_c_info (lc_discovery) << "Error while opening directory" << (local_path) << errno;
            string error_string = _("Error while opening directory %1").arg (local_path);
            if (errno == EACCES) {
                error_string = _("Directory not accessible on client, permission denied");
                /* emit */ finished_non_fatal_error (error_string);
                return;
            } else if (errno == ENOENT) {
                error_string = _("Directory not found : %1").arg (local_path);
            } else if (errno == ENOTDIR) {
                // Not a directory..
                // Just consider it is empty
                return;
            }
            /* emit */ finished_fatal_error (error_string);
            return;
        }

        GLib.Vector<LocalInfo> results;
        while (true) {
            errno = 0;
            var dirent = csync_vio_local_readdir (dh, this.vfs);
            if (!dirent)
                break;
            if (dirent.type == ItemTypeSkip)
                continue;
            LocalInfo i;
            static QTextCodec codec = QTextCodec.codec_for_name ("UTF-8");
            ASSERT (codec);
            QTextCodec.ConverterState state;
            i.name = codec.to_unicode (dirent.path, dirent.path.size (), state);
            if (state.invalid_chars > 0 || state.remaining_chars > 0) {
                /* emit */ child_ignored (true);
                var item = SyncFileItemPtr.create ();
                //item._file = this.current_folder._target + i.name;
                // FIXME ^^ do we really need to use this.target or is local fine?
                item._file = this.local_path + i.name;
                item._instruction = CSYNC_INSTRUCTION_IGNORE;
                item._status = SyncFileItem.Status.NORMAL_ERROR;
                item._error_string = _("Filename encoding is not valid");
                /* emit */ item_discovered (item);
                continue;
            }
            i.modtime = dirent.modtime;
            i.size = dirent.size;
            i.inode = dirent.inode;
            i.is_directory = dirent.type == ItemTypeDirectory;
            i.is_hidden = dirent.is_hidden;
            i.is_sym_link = dirent.type == ItemTypeSoftLink;
            i.is_virtual_file = dirent.type == ItemTypeVirtualFile || dirent.type == ItemTypeVirtualFileDownload;
            i.type = dirent.type;
            results.push_back (i);
        }
        if (errno != 0) {
            csync_vio_local_closedir (dh);

            // Note: Windows vio converts any error into EACCES
            GLib.warn (lc_discovery) << "readdir failed for file in " << local_path << " - errno : " << errno;
            /* emit */ finished_fatal_error (_("Error while reading directory %1").arg (local_path));
            return;
        }

        errno = 0;
        csync_vio_local_closedir (dh);
        if (errno != 0) {
            GLib.warn (lc_discovery) << "closedir failed for file in " << local_path << " - errno : " << errno;
        }

        /* emit */ finished (results);
    }


    /***********************************************************
    ***********************************************************/
    static void property_map_to_remote_info (GLib.HashMap<string, string> map, RemoteInfo result) {
        for (var it = map.const_begin (); it != map.const_end (); ++it) {
            string property = it.key ();
            string value = it.value ();
            if (property == QLatin1String ("resourcetype")) {
                result.is_directory = value.contains (QLatin1String ("collection"));
            } else if (property == QLatin1String ("getlastmodified")) {
                const var date = GLib.DateTime.from_string (value, Qt.RFC2822Date);
                Q_ASSERT (date.is_valid ());
                result.modtime = date.to_time_t ();
            } else if (property == QLatin1String ("getcontentlength")) {
                // See #4573, sometimes negative size values are returned
                bool ok = false;
                qlonglong ll = value.to_long_long (&ok);
                if (ok && ll >= 0) {
                    result.size = ll;
                } else {
                    result.size = 0;
                }
            } else if (property == "getetag") {
                result.etag = Utility.normalize_etag (value.to_utf8 ());
            } else if (property == "id") {
                result.file_identifier = value.to_utf8 ();
            } else if (property == "download_uRL") {
                result.direct_download_url = value;
            } else if (property == "d_dC") {
                result.direct_download_cookies = value;
            } else if (property == "permissions") {
                result.remote_perm = RemotePermissions.from_server_string (value);
            } else if (property == "checksums") {
                result.checksum_header = find_best_checksum (value.to_utf8 ());
            } else if (property == "share-types" && !value.is_empty ()) {
                // Since GLib.HashMap is sorted, "share-types" is always after "permissions".
                if (result.remote_perm.is_null ()) {
                    q_warning () << "Server returned a share type, but no permissions?";
                } else {
                    // S means shared with me.
                    // But for our purpose, we want to know if the file is shared. It does not matter
                    // if we are the owner or not.
                    // Piggy back on the persmission field
                    result.remote_perm.set_permission (RemotePermissions.IsShared);
                }
            } else if (property == "is-encrypted" && value == QStringLiteral ("1")) {
                result.is_e2e_encrypted = true;
            }
        }

        if (result.is_directory && map.contains ("size")) {
            result.size_of_folder = map.value ("size").to_int ();
        }
    }

    }
    