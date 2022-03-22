namespace Occ {
namespace LibSync {

/***********************************************************
@class DiscoveryPhase

@author Olivier Goffart <ogoffart@woboq.com>

@copyright GPLv3 or Later
***********************************************************/
public class DiscoveryPhase : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum LocalDiscoveryStyle {

        /***********************************************************
        Read all local data from the filesystem
        ***********************************************************/
        FILESYSTEM_ONLY,

        /***********************************************************
        Read from the database, except for listed paths
        ***********************************************************/
        DATABASE_AND_FILESYSTEM,
    }

    //  friend class ProcessDirectoryJob;

    /***********************************************************
    ***********************************************************/
    ProcessDirectoryJob current_root_job;


    /***********************************************************
    Maps the database-path of a deleted item to its SyncFileItem.

    If it turns out the item was renamed after all, the instruction
    can be changed. See find_and_cancel_deleted_job (). Note that
    signal_item_discovered () will already have been emitted for the item.
    ***********************************************************/
    GLib.HashTable<string, unowned SyncFileItem> deleted_item;


    /***********************************************************
    Maps the database-path of a deleted folder to its queued job.

    If a folder is deleted and must be recursed into, its job isn't
    executed immediately. Instead it's queued here and only run
    once the rest of the discovery has on_signal_finished and we are certain
    that the folder wasn't just renamed. This avoids running the
    discovery on contents in the old location of renamed folders.

    See find_and_cancel_deleted_job ().
    ***********************************************************/
    GLib.HashTable<string, ProcessDirectoryJob> queued_deleted_directories;

    /***********************************************************
    Map source (original path)
    ***********************************************************/
    GLib.HashTable<string, string> renamed_items_remote;

    /***********************************************************
    Map destinations (current server or local path)
    ***********************************************************/
    GLib.HashTable<string, string> renamed_items_local;

    /***********************************************************
    Set of paths that should not be removed even though they are
    removed locally: there was a move to an invalid destination
    and now the source should be restored

    This applies recursively to subdirectories. All entries
    should have a trailing slash (even files), so lookup with
    lower_bound () is reliable.

    The value of this map doesn't matter.
    ***********************************************************/
    GLib.HashTable<string, bool> forbidden_deletes;

    /***********************************************************
    Input
    Absolute path to the local directory. ends with "/"
    ***********************************************************/
    public string local_dir;

    /***********************************************************
    Input
    Remote folder, ends with "/"
    ***********************************************************/
    public string remote_folder;

    /***********************************************************
    Input
    ***********************************************************/
    public SyncJournalDb statedatabase;

    /***********************************************************
    Input
    ***********************************************************/
    public unowned Account account;

    /***********************************************************
    Input
    ***********************************************************/
    public SyncOptions sync_options;

    /***********************************************************
    Input
    ***********************************************************/
    public ExcludedFiles excludes;

    /***********************************************************
    Input
    FIXME: maybe move in ExcludedFiles
    ***********************************************************/
    public GLib.Regex invalid_filename_rx;

    /***********************************************************
    Input
    The blocklist from the capabilities
    ***********************************************************/
    public string[] server_blocklisted_files;

    /***********************************************************
    Input
    ***********************************************************/
    public bool ignore_hidden_files = false;

    /***********************************************************
    Input
    ***********************************************************/
    public delegate bool ShouldDiscoverLocally (string value);
    public ShouldDiscoverLocally local_discovery_delegate;

    /***********************************************************
    ***********************************************************/
    int currently_active_jobs = 0;

    /***********************************************************
    Both must contain a sorted list
    ***********************************************************/
    string[] selective_sync_block_list;
    string[] selective_sync_allow_list;


    /***********************************************************
    Output
    ***********************************************************/
    public string data_fingerprint;


    /***********************************************************
    Output
    ***********************************************************/
    public bool another_sync_needed = false;


    internal signal void signal_fatal_error (string error_string);
    internal signal void signal_item_discovered (SyncFileItem item);
    internal signal void signal_finished ();


    /***********************************************************
    A new folder was discovered and was not synced because of
    the confirmation feature.
    ***********************************************************/
    internal signal void signal_new_big_folder (string folder, bool is_external);


    /***********************************************************
    For excluded items that don't show up in signal_item_discovered ()

    The path is relative to the sync folder, similar to item.file
    ***********************************************************/
    internal signal void signal_silently_excluded (string folder_path);

    /***********************************************************
    ***********************************************************/
    internal signal void add_error_to_gui (SyncFileItem.Status status, string error_message, string subject);


    /***********************************************************
    Returns whether the database-path has been renamed locally or on the remote.

    Useful for avoiding processing of items that have already been claimed in
    a rename (would otherwise be discovered as deletions).
    ***********************************************************/
    bool is_renamed (string p) {
        return this.renamed_items_local.contains (p) || this.renamed_items_remote.contains (p);
    }


    /***********************************************************
    ***********************************************************/
    void schedule_more_jobs () {
        var limit = q_max (1, this.sync_options.parallel_network_jobs);
        if (this.current_root_job && this.currently_active_jobs < limit) {
            this.current_root_job.process_sub_jobs (limit - this.currently_active_jobs);
        }
    }


    /***********************************************************
    ***********************************************************/
    bool is_in_selective_sync_block_list (string path) {
        if (this.selective_sync_block_list == "") {
            // If there is no block list, everything is allowed
            return false;
        }

        // Block if it is in the block list
        if (find_path_in_list (this.selective_sync_block_list, path)) {
            return true;
        }

        return false;
    }


    private delegate void Callback (bool value);


    /***********************************************************
    Check if the new folder should be deselected or not.
    May be async. "Return" via the callback, true if the item
    is blocklisted.
    ***********************************************************/
    void check_selective_sync_new_folder (
        string path,
        RemotePermissions remote_perm,
        Callback callback) {
        if (this.sync_options.confirm_external_storage && this.sync_options.vfs.mode () == AbstractVfs.Off
            && remote_perm.has_permission (RemotePermissions.Permissions.IS_MOUNTED)) {
            // external storage.

            // Note: DiscoverySingleDirectoryJob.on_signal_directory_listing_iterated_slot make sure that only the
            // root of a mounted storage has 'M', all sub entries have 'm'

            // Only allow it if the allow list contains exactly this path (not parents)
            // We want to ask confirmation for external storage even if the parents where selected
            if (this.selective_sync_allow_list.contains (path + "/")) {
                return callback (false);
            }

            /* emit */ signal_new_big_folder (path, true);
            return callback (true);
        }

        // If this path or the parent is in the allow list, then we do not block this file
        if (find_path_in_list (this.selective_sync_allow_list, path)) {
            return callback (false);
        }

        var limit = this.sync_options.new_big_folder_size_limit;
        if (limit < 0 || this.sync_options.vfs.mode () != AbstractVfs.Off) {
            // no limit, everything is allowed;
            return callback (false);
        }

        // do a PROPFIND to know the size of this folder
        var propfind_job = new PropfindJob (this.account, this.remote_folder + path, this);
        propfind_job.properties (
            new GLib.List<string> (
                "resourcetype"
                + "http://owncloud.org/ns:size"));
        GLib.Object.connect (
            propfind_job,
            PropfindJob.signal_finished_with_error,
            this, () => {
                return callback (false);
            });
        GLib.Object.connect (
            propfind_job,
            PropfindJob.result,
            this,
            this.on_signal_prop_find_job_result
        );
        propfind_job.start ();
    }


    private void on_signal_prop_find_job_result (GLib.HashTable<string, GLib.Variant> values) {
        var result = values.value ("size").to_long_long ();
        if (result >= limit) {
            // we tell the UI there is a new folder
            /* emit */ signal_new_big_folder (path, false);
            return callback (true);
        } else {
            // it is not too big, put it in the allow list (so we will not do more query for the children)
            // and and do not block.
            var p = path;
            if (!p.has_suffix ("/"))
                p += "/";
            this.selective_sync_allow_list.insert (
                std.upper_bound (this.selective_sync_allow_list.begin (), this.selective_sync_allow_list.end (), p),
                p);
            return callback (false);
        }
    }


    /***********************************************************
    ***********************************************************/
    //  string adjust_renamed_path (string original, SyncFileItem.Direction d) {
    //      return adjust_renamed_path (d == SyncFileItem.Direction.DOWN ? this.renamed_items_remote : this.renamed_items_local, original);
    //  }


    /***********************************************************
    Given an original path, return the target path obtained when
    renaming is done.

    Note that it only considers parent directory renames. So if
    A/B got renamed to C/D, checking A/B/file would yield
    C/D/file, but checking A/B would yield A/B.

    Implementation of DiscoveryPhase.adjust_renamed_path
    ***********************************************************/
    string adjust_renamed_path (GLib.HashTable<string, string> renamed_items, string original) {
        int slash_pos = original.size ();
        while ( (slash_pos = original.last_index_of ("/", slash_pos - 1)) > 0) {
            var it = renamed_items.const_find (original.left (slash_pos));
            if (it != renamed_items.const_end ()) {
                return it + original.mid (slash_pos);
            }
        }
        return original;
    }


    /***********************************************************
    If the database-path is scheduled for deletion, abort it.

    Check if there is already a job to delete that item:
    If that's not the case, return { false, "" }.
    If there is such a job, cancel that job and return true and
    the old etag.

    Used when having detected a rename : The rename source
    discovered before and would have looked like a delete.

    See this.deleted_item and this.queued_deleted_directories.
    ***********************************************************/
    public QPair<bool, string> find_and_cancel_deleted_job (string original_path) {
        bool result = false;
        string old_etag;
        var it = this.deleted_item.find (original_path);
        if (it != this.deleted_item.end ()) {
            const CSync.SyncInstructions instruction = (*it).instruction;
            if (instruction == CSync.SyncInstructions.IGNORE && (*it).type == ItemType.VIRTUAL_FILE) {
                // re-creation of virtual files count as a delete
                // a file might be in an error state and thus gets marked as CSync.SyncInstructions.IGNORE
                // after it was initially marked as CSync.SyncInstructions.REMOVE
                // return true, to not trigger any additional actions on that file that could elad to dataloss
                result = true;
                old_etag = (*it).etag;
            } else {
                if (! (instruction == CSync.SyncInstructions.REMOVE
                        // re-creation of virtual files count as a delete
                        || ( (*it).type == ItemType.VIRTUAL_FILE && instruction == CSync.SyncInstructions.NEW)
                        || ( (*it).is_restoration && instruction == CSync.SyncInstructions.NEW))) {
                    GLib.warning ("ENFORCE (FAILING) " + original_path);
                    GLib.warning ("instruction == CSync.SyncInstructions.REMOVE " + (instruction == CSync.SyncInstructions.REMOVE));
                    GLib.warning (" ( (*it).type == ItemType.VIRTUAL_FILE && instruction == CSync.SyncInstructions.NEW)"
                                           + ( (*it).type == ItemType.VIRTUAL_FILE && instruction == CSync.SyncInstructions.NEW));
                    GLib.warning (" ( (*it).is_restoration && instruction == CSync.SyncInstructions.NEW))"
                                           + ( (*it).is_restoration && instruction == CSync.SyncInstructions.NEW));
                    GLib.warning ("instruction" + instruction);
                    GLib.warning (" (*it).type" + (*it).type);
                    GLib.warning (" (*it).is_restoration " + (*it).is_restoration);
                    GLib.assert (false);
                    add_error_to_gui (SyncFileItem.Status.FatalError, _("Error while canceling delete of a file"), original_path);
                    /* emit */ signal_fatal_error (_("Error while canceling delete of %1").printf (original_path));
                }
                (*it).instruction = CSync.SyncInstructions.NONE;
                result = true;
                old_etag = (*it).etag;
            }
            this.deleted_item.erase (it);
        }
        var other_job = this.queued_deleted_directories.take (original_path);
        if (other_job) {
            old_etag = other_job.dir_item.etag;
            delete other_job;
            result = true;
        }
        return new QPair<bool, string> (
            result, old_etag
        );
    }


    /***********************************************************
    ***********************************************************/
    public void start_job (ProcessDirectoryJob process_directory_job) {
        //  ENFORCE (!this.current_root_job);
        process_directory_job.signal_finished.connect (
            this.on_signal_process_directory_job_finished
        );
        this.current_root_job = process_directory_job;
        process_directory_job.start ();
    }


    private void on_signal_process_directory_job_finished (ProcessDirectoryJob process_directory_job) {
        //  ENFORCE (this.current_root_job == sender ());
        this.current_root_job = null;
        if (process_directory_job.dir_item)
            /* emit */ signal_item_discovered (process_directory_job.dir_item);
        process_directory_job.delete_later ();

        // Once the main process_directory_job has on_signal_finished recurse here to execute the remaining
        // jobs for queued deleted directories.
        if (!this.queued_deleted_directories == "") {
            var next_job = this.queued_deleted_directories.take (this.queued_deleted_directories.first_key ());
            start_job (next_job);
        } else {
            /* emit */ signal_finished ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void selective_sync_block_list (string[] list) {
        this.selective_sync_block_list = list;
        std.sort (this.selective_sync_block_list.begin (), this.selective_sync_block_list.end ());
    }


    /***********************************************************
    ***********************************************************/
    public void selective_sync_allow_list (string[] list) {
        this.selective_sync_allow_list = list;
        std.sort (this.selective_sync_allow_list.begin (), this.selective_sync_allow_list.end ());
    }


    /***********************************************************
    Given a sorted list of paths ending with "/", return whether
    or not the given path is within one of the paths of the list
    ***********************************************************/
    private static bool find_path_in_list (string[] list, string path) {
        GLib.assert (std.is_sorted (list.begin (), list.end ()));

        if (list.size () == 1 && list.first () == "/") {
            // Special case for the case "/" is there, it matches everything
            return true;
        }

        string path_slash = path + "/";

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
        GLib.assert (it.has_suffix ("/")); // FolderConnection.selective_sync_block_list makes sure of that
        return path_slash.has_prefix (*it);
    }


    /***********************************************************
    ***********************************************************/
    private static void property_map_to_remote_info (GLib.HashTable<string, string> map, RemoteInfo result) {
        for (var it = map.const_begin (); it != map.const_end (); ++it) {
            string property = it.key ();
            string value = it.value ();
            if (property == "resourcetype") {
                result.is_directory = value.contains ("collection");
            } else if (property == "getlastmodified") {
                var date = GLib.DateTime.from_string (value, Qt.RFC2822Date);
                GLib.assert (date.is_valid ());
                result.modtime = date.to_time_t ();
            } else if (property == "getcontentlength") {
                // See #4573, sometimes negative size values are returned
                bool ok = false;
                int64 ll = value.to_long_long (&ok);
                if (ok && ll >= 0) {
                    result.size = ll;
                } else {
                    result.size = 0;
                }
            } else if (property == "getetag") {
                result.etag = Utility.normalize_etag (value.to_utf8 ());
            } else if (property == "identifier") {
                result.file_identifier = value.to_utf8 ();
            } else if (property == "download_uRL") {
                result.direct_download_url = value;
            } else if (property == "d_dC") {
                result.direct_download_cookies = value;
            } else if (property == "permissions") {
                result.remote_perm = RemotePermissions.from_server_string (value);
            } else if (property == "checksums") {
                result.checksum_header = find_best_checksum (value.to_utf8 ());
            } else if (property == "share-types" && !value == "") {
                // Since GLib.HashTable is sorted, "share-types" is always after "permissions".
                if (result.remote_perm == null) {
                    GLib.warning ("Server returned a share type but no permissions?");
                } else {
                    // S means shared with me.
                    // But for our purpose, we want to know if the file is shared. It does not matter
                    // if we are the owner or not.
                    // Piggy back on the persmission field
                    result.remote_perm.permission (RemotePermissions.Permissions.IS_SHARED);
                }
            } else if (property == "is-encrypted" && value == "1") {
                result.is_e2e_encrypted = true;
            }
        }

        if (result.is_directory && map.contains ("size")) {
            result.size_of_folder = map.value ("size").to_int ();
        }
    }

} // class DiscoveryPhase

} // namespace LibSync
} // namespace Occ
    