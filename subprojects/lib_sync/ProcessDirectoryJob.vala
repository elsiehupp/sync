namespace Occ {
namespace LibSync {

/***********************************************************
@class ProcessDirectoryJob

@brief Job that handles discovery of a directory.

@details This includes:
 - Do a DiscoverySingleDirectoryJob network job which will do a PRO
 - Stat all the entries in the local file system for this directory
 - Merge all information (and the information from
   to be done for every file within this directory.
 - For every sub-directory within this directory, "recursivel

This job is tightly coupled with the DiscoveryPhase class.

After being start ()'ed

Internally, this job will call DiscoveryPhase.on_signal_schedule_more_jobs when one of its sub-jobs is
finished. DiscoveryPhase.on_signal_schedule_more_jobs will call process_sub_jobs () to continue work until
the job is finished.

Results are fed outwards via the DiscoveryPhase.signal_item_discovered () signal.

@author Olivier Goffart <ogoffart@woboq.com>

@copyright GPLv3 or Later
***********************************************************/
public class ProcessDirectoryJob : GLib.Object {

    //  struct PathTuple;

    /***********************************************************
    ***********************************************************/
    public enum QueryMode {

        /***********************************************************
        ***********************************************************/
        NORMAL_QUERY,

        /***********************************************************
        Do not query this folder because it does not exist
        ***********************************************************/
        PARENT_DOES_NOT_EXIST,

        /***********************************************************
        No need to query this folder because it has not changed from
        what is in the DB
        ***********************************************************/
        PARENT_NOT_CHANGED,

        /***********************************************************
        Do not query this folder because it is in the blocklist
        (remote entries only)
        ***********************************************************/
        IN_BLOCK_LIST
    }


    /***********************************************************
    ***********************************************************/
    private struct Entries {
        string name_override;
        Common.SyncJournalFileRecord database_entry;
        RemoteInfo server_entry;
        LocalInfo local_entry;
    }


    /***********************************************************
    Structure representing a path during discovery. A same path may have different value locally
    or on the server in case of renames.

    These strings never start or ends with slashes. They are all relative to the fo
    Usually they are all the same and are even shared instance of the s

    this.server and this.local path
      remote renamed A/ to
        target :   B/Y/file
        original : A/X/file
        local :    A/Y/file
        server :   B/X/file
    ***********************************************************/
    public struct PathTuple {

        /***********************************************************
        Path as in the DB (before the sync)
        ***********************************************************/
        string original;

        /***********************************************************
        Path that will be the result after the sync (and will be in
        the DB)
        ***********************************************************/
        string target;

        /***********************************************************
        Path on the server (before the sync)
        ***********************************************************/
        string server;

        /***********************************************************
        Path locally (before the sync)
        ***********************************************************/
        string local;


        static string path_append (string base_record, string name) {
            return base_record == "" ? name : base_record + "/" + name;
        }


        PathTuple add_name (string name) {
            PathTuple result;
            result.original = path_append (this.original, name);
            result.target = build_string (this.target, name, result);
            result.server = build_string (this.server, name, result);
            result.local = build_string (this.local, name, result);
            return result;
        }


        private string build_string (string other, string name, PathTuple result) {
            // Optimize by trying to keep all string implicitly shared if they are the same (common case)
            if (other == this.original) {
                return result.original;
            } else {
                path_append (other, name);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private class MovePermissionResult {

        /***********************************************************
        Whether moving/renaming the source is ok
        ***********************************************************/
        bool source_ok;

        /***********************************************************
        Whether the destination accepts (always true for renames)
        ***********************************************************/
        bool destination_ok;

        /***********************************************************
        Whether creating a new file/directory in the destination is ok
        ***********************************************************/
        bool destination_new_ok;

        construct {
            source_ok = false;
            destination_ok = false;
            destination_new_ok = false;
        }
    }


    /***********************************************************
    ***********************************************************/
    private int64 last_sync_timestamp = 0;

    /***********************************************************
    ***********************************************************/
    private QueryMode query_server = QueryMode.NORMAL_QUERY;

    /***********************************************************
    ***********************************************************/
    private QueryMode query_local = QueryMode.NORMAL_QUERY;

    /***********************************************************
    Holds entries that resulted from a NORMAL_QUERY
    ***********************************************************/
    private GLib.List<RemoteInfo> server_normal_query_entries;

    /***********************************************************
    Holds entries that resulted from a NORMAL_QUERY
    ***********************************************************/
    private GLib.List<LocalInfo> local_normal_query_entries;

    /***********************************************************
    Whether the local/remote directory item queries are done.
    Will be set even even for do-nothing (!= NORMAL_QUERY) queries.
    ***********************************************************/
    private bool server_query_done = false;

    /***********************************************************
    Whether the local/remote directory item queries are done.
    Will be set even even for do-nothing (!= NORMAL_QUERY) queries.
    ***********************************************************/
    private bool local_query_done = false;

    /***********************************************************
    ***********************************************************/
    private Common.RemotePermissions root_permissions;

    /***********************************************************
    ***********************************************************/
    private DiscoverySingleDirectoryJob discovery_single_directory_job;

    /***********************************************************
    Number of currently running async jobs.

    These "async jobs" have nothing to do with the jobs for subdirectories
    which are being tracked by this.queued_jobs and this.running_jobs.

    They are jobs that need to be completed to finish processing of direct
    entries. This variable is used to ensure this job doesn't finish while
    these jobs are still in flight.
    ***********************************************************/
    private int pending_async_jobs = 0;

    /***********************************************************
    The queued jobs for subdirectories.

    The jobs are enqueued while processind directory entries and
    then gradually run via calls to process_sub_jobs ().
    ***********************************************************/
    private GLib.Deque<ProcessDirectoryJob> queued_jobs;

    /***********************************************************
    The running jobs for subdirectories.

    The jobs are enqueued while processind directory entries and
    then gradually run via calls to process_sub_jobs ().
    ***********************************************************/
    private GLib.List<ProcessDirectoryJob> running_jobs;

    /***********************************************************
    ***********************************************************/
    private DiscoveryPhase discovery_data;

    /***********************************************************
    ***********************************************************/
    private PathTuple current_folder;

    /***********************************************************
    The directory contains modified item what would prevent deletion
    ***********************************************************/
    private bool child_modified = false;

    /***********************************************************
    The directory contains ignored item that would prevent
    deletion
    ***********************************************************/
    private bool child_ignored = false;

    /***********************************************************
    The directory's pin-state, see compute_pin_state ()
    ***********************************************************/
    private Common.PinState pin_state = Common.PinState.UNSPECIFIED;

    /***********************************************************
    This directory is encrypted or is within the tree of
    directories with root directory encrypted
    ***********************************************************/
    public bool is_inside_encrypted_tree = false;

    /***********************************************************
    ***********************************************************/
    public unowned SyncFileItem dir_item;

    /***********************************************************
    ***********************************************************/
    internal signal void signal_finished ();

    /***********************************************************
    The root etag of this directory was fetched
    ***********************************************************/
    internal signal void etag (string array, GLib.DateTime time);

    /***********************************************************
    For creating the root job

    The base_record pin state is used if the root directory's pin state can't be retrieved.
    ***********************************************************/
    public ProcessDirectoryJob.root_job (
        DiscoveryPhase data,
        Common.PinState base_pin_state,
        int64 last_sync_timestamp,
        GLib.Object parent
    ) {
        base (parent);
        this.last_sync_timestamp = last_sync_timestamp;
        this.discovery_data = data;
        compute_pin_state (base_pin_state);
    }


    /***********************************************************
    For creating subjobs
    ***********************************************************/
    public ProcessDirectoryJob.sub_job (
        PathTuple path,
        SyncFileItem dir_item,
        QueryMode query_local,
        QueryMode query_server,
        int64 last_sync_timestamp,
        ProcessDirectoryJob parent) {
        base_record (parent);
        this.dir_item = dir_item;
        this.last_sync_timestamp = last_sync_timestamp;
        this.query_server = query_server;
        this.query_local = query_local;
        this.discovery_data = parent.discovery_data;
        this.current_folder = path;
        compute_pin_state (parent.pin_state);
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        GLib.info ("STARTING " + this.current_folder.server.to_string () + this.query_server.to_string () + this.current_folder.local.to_string () + this.query_local.to_string ());

        if (this.query_server == NORMAL_QUERY) {
            this.server_job = start_async_server_query ();
        } else {
            this.server_query_done = true;
        }

        // Check whether a normal local query is even necessary
        if (this.query_local == NORMAL_QUERY) {
            if (!this.discovery_data.local_discovery_delegate (this.current_folder.local)
                && (this.current_folder.local == this.current_folder.original || !this.discovery_data.local_discovery_delegate (this.current_folder.original))) {
                this.query_local = PARENT_NOT_CHANGED;
            }
        }

        if (this.query_local == NORMAL_QUERY) {
            start_async_local_query ();
        } else {
            this.local_query_done = true;
        }

        if (this.local_query_done && this.server_query_done) {
            process ();
        }
    }


    /***********************************************************
    Start up to number_of_jobs, return the number of job
    started; emit finished () when done
    ***********************************************************/
    public int process_sub_jobs (int number_of_jobs) {
        if (this.queued_jobs.empty () && this.running_jobs.empty () && this.pending_async_jobs == 0) {
            this.pending_async_jobs = -1; // We're finished, we don't want to emit finished again
            if (this.dir_item != null) {
                if (this.child_modified && this.dir_item.instruction == CSync.SyncInstructions.REMOVE) {
                    // re-create directory that has modified contents
                    this.dir_item.instruction = CSync.SyncInstructions.NEW;
                    this.dir_item.direction = this.dir_item.direction == SyncFileItem.Direction.UP ? SyncFileItem.Direction.DOWN : SyncFileItem.Direction.UP;
                }
                if (this.child_modified && this.dir_item.instruction == CSync.SyncInstructions.TYPE_CHANGE && !this.dir_item.is_directory ()) {
                    // Replacing a directory by a file is a conflict, if the directory had modified children
                    this.dir_item.instruction = CSync.SyncInstructions.CONFLICT;
                    if (this.dir_item.direction == SyncFileItem.Direction.UP) {
                        this.dir_item.type = ItemType.DIRECTORY;
                        this.dir_item.direction = SyncFileItem.Direction.DOWN;
                    }
                }
                if (this.child_ignored && this.dir_item.instruction == CSync.SyncInstructions.REMOVE) {
                    // Do not remove a directory that has ignored files
                    this.dir_item.instruction = CSync.SyncInstructions.NONE;
                }
            }
            signal_finished ();
        }

        int started = 0;
        foreach (var rj in this.running_jobs) {
            started += rj.process_sub_jobs (number_of_jobs - started);
            if (started >= number_of_jobs)
                return started;
        }

        while (started < number_of_jobs && !this.queued_jobs.empty ()) {
            var f = this.queued_jobs.front ();
            this.queued_jobs.pop_front ();
            this.running_jobs.push_back (f);
            f.start ();
            started++;
        }
        return started;
    }




    /***********************************************************
    ***********************************************************/
    private bool check_for_invalid_filename (PathTuple path, GLib.HashTable<string, Entries?> entries, Entries entry) {
        var original_filename = entry.local_entry.name;
        var new_filename = original_filename.trimmed ();

        if (original_filename == new_filename) {
            return true;
        }

        var entries_iter = entries.find (new_filename);
        if (entries_iter != entries.end ()) {
            string error_message;
            var new_filename_entry = entries_iter.second;
            if (new_filename_entry.server_entry.is_valid) {
                error_message = _("File contains trailing spaces and could not be renamed, because a file with the same name already exists on the server.");
            }
            if (new_filename_entry.local_entry.is_valid) {
                error_message = _("File contains trailing spaces and could not be renamed, because a file with the same name already exists locally.");
            }

            if (error_message != "") {
                SyncFileItem item = new SyncFileItem ();
                if (entry.local_entry.is_directory) {
                    item.type = ItemType.DIRECTORY;
                } else {
                    item.type = ItemType.FILE;
                }
                item.file = path.target;
                item.original_file = path.target;
                item.instruction = CSync.SyncInstructions.ERROR;
                item.status = SyncFileItem.Status.NORMAL_ERROR;
                item.error_string = error_message;
                this.discovery_data.signal_item_discovered (item);
                return false;
            }
        }

        entry.local_entry.rename_name = new_filename;

        return true;
    }


    /***********************************************************
    Iterate over entries inside the directory (non-recursively).

    Called once this.server_entries and this.local_entries are filled
    Calls process_file () for each non-excluded one.
    Will start scheduling subdir jobs when done.
    ***********************************************************/
    private void process () {
        //  GLib.assert_true (this.local_query_done && this.server_query_done);

        // Build lookup tables for local, remote and database entries.
        // For suffix-virtual files, the key will normally be the base_record file name
        // without the suffix.
        // However, if foo and foo.owncloud exists locally, there'll be "foo"
        // with local, database, server entries and "foo.owncloud" with only a local
        // entry.
        GLib.HashTable<string, Entries?> entries;
        foreach (var e in this.server_normal_query_entries) {
            entries[e.name].server_entry = std.move (e);
        }
        this.server_normal_query_entries = new GLib.List<LocalInfo> ();

        // fetch all the name from the DB
        var path_u8 = this.current_folder.original.to_utf8 ();
        if (!this.discovery_data.statedatabase.list_files_in_path (path_u8, (record) => {
                var name = path_u8 == "" ? record.path : string.from_utf8 (record.path.const_data () + (path_u8.size () + 1));
                if (record.is_virtual_file () && is_vfs_with_suffix ()) {
                    chop_virtual_file_suffix (name);
                }
                var database_entry = entries[name].database_entry;
                database_entry = record;
                up_database_pin_state_actions (database_entry);
            })) {
            db_error ();
            return;
        }

        foreach (var e in this.local_normal_query_entries) {
            entries[e.name].local_entry = e;
        }
        if (is_vfs_with_suffix ()) {
            // For vfs-suffix the local data for suffixed files should usually be associated
            // with the non-suffixed name. Unless both names exist locally or there's
            // other data about the suffixed file.
            // This is done in a second path in order to not depend on the order of
            // this.local_normal_query_entries.
            foreach (var e in this.local_normal_query_entries) {
                if (!e.is_virtual_file)
                    continue;
                var suffixed_entry = entries[e.name];
                bool has_other_data = suffixed_entry.server_entry.is_valid || suffixed_entry.database_entry.is_valid;

                var nonvirtual_name = e.name;
                chop_virtual_file_suffix (nonvirtual_name);
                var nonvirtual_entry = entries[nonvirtual_name];
                // If the non-suffixed entry has no data, move it
                if (!nonvirtual_entry.local_entry.is_valid) {
                    std.swap (nonvirtual_entry.local_entry, suffixed_entry.local_entry);
                    if (!has_other_data)
                        entries.erase (e.name);
                } else if (!has_other_data) {
                    // Normally a lone local suffixed file would be processed under the
                    // unsuffixed name. In this special case it's under the suffixed name.
                    // To avoid lots of special casing, make sure PathTuple.add_name ()
                    // will be called with the unsuffixed name anyway.
                    suffixed_entry.name_override = nonvirtual_name;
                }
            }
        }
        this.local_normal_query_entries = new GLib.List<LocalInfo> ();

        //  
        // Iterate over entries and process them
        //  
        foreach (var f in entries) {
            var e = f.second;

            PathTuple path;
            path = this.current_folder.add_name (e.name_override == "" ? f.first : e.name_override);

            if (is_vfs_with_suffix ()) {
                // Without suffix vfs the paths would be good. But since the database_entry and local_entry
                // can have different names from f.first when suffix vfs is on, make sure the
                // corresponding this.original and this.local paths are right.

                if (e.database_entry.is_valid) {
                    path.original = e.database_entry.path;
                } else if (e.local_entry.is_virtual_file) {
                    // We don't have a database entry - but it should be at this path
                    path.original = PathTuple.path_append (this.current_folder.original,  e.local_entry.name);
                }
                if (e.local_entry.is_valid) {
                    path.local = PathTuple.path_append (this.current_folder.local, e.local_entry.name);
                } else if (e.database_entry.is_virtual_file ()) {
                    // We don't have a local entry - but it should be at this path
                    path.local = add_virtual_file_suffix (path.local);
                }
            }

            // On the server the path is mangled in case of E2EE
            if (!e.server_entry.e2e_mangled_name == "") {
                GLib.assert (this.discovery_data.remote_folder.has_prefix ("/"));
                GLib.assert (this.discovery_data.remote_folder.has_suffix ("/"));

                var root_path = this.discovery_data.remote_folder.mid (1);
                GLib.assert (e.server_entry.e2e_mangled_name.has_prefix (root_path));

                path.server = e.server_entry.e2e_mangled_name.mid (root_path.length);
            }

            // If the filename starts with a . we consider it a hidden file
            // For windows, the hidden state is also discovered within the vio
            // local stat function.
            // Recall file shall not be ignored (#4420)
            bool is_hidden = e.local_entry.is_hidden || (!f.first == "" && f.first[0] == '.' && f.first != ".sys.admin#recall#");
            bool is_server_entry_windows_shortcut = false;
            if (handle_excluded (path.target, e.local_entry.name,
                    e.local_entry.is_directory || e.server_entry.is_directory, is_hidden,
                    e.local_entry.is_sym_link || is_server_entry_windows_shortcut))
                continue;

            if (this.query_server == IN_BLOCK_LIST || this.discovery_data.is_in_selective_sync_block_list (path.original)) {
                process_blocklisted (path, e.local_entry, e.database_entry);
                continue;
            }
            if (!check_for_invalid_filename (path, entries, e)) {
                continue;
            }
            process_file (std.move (path), e.local_entry, e.server_entry, e.database_entry);
        }
        GLib.Timeout.add (0, this.discovery_data.on_signal_schedule_more_jobs);
    }


    /***********************************************************
    Return true if the file is excluded. Path is the full
    relative path of the file. local_name is the base_record name of
    the local entry.
    ***********************************************************/
    private bool handle_excluded (string path, string local_name, bool is_directory,
        bool is_hidden, bool is_symlink) {
        var excluded = this.discovery_data.excludes.traversal_pattern_match (path, is_directory ? ItemType.DIRECTORY : ItemType.FILE);

        // FIXME: move to CSync.ExcludedFiles 's regular_expression ?
        bool is_invalid_pattern = false;
        if (excluded == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED && !this.discovery_data.invalid_filename_rx.pattern () == "") {
            if (path.contains (this.discovery_data.invalid_filename_rx)) {
                excluded = CSync.CSync.ExcludedFiles.Type.INVALID_CHAR;
                is_invalid_pattern = true;
            }
        }
        if (excluded == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED && this.discovery_data.ignore_hidden_files && is_hidden) {
            excluded = CSync.CSync.ExcludedFiles.Type.HIDDEN;
        }
        if (excluded == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED
            && local_name != ""
            && this.discovery_data.server_blocklisted_files.contains (local_name)
        ) {
            excluded = CSync.CSync.ExcludedFiles.Type.SERVER_BLOCKLISTED;
            is_invalid_pattern = true;
        }

        // Ignored because Vala is already Unicode?
        //  var local_codec = GMime.Encoding.codec_for_locale ();
        //  if (local_codec.mib_enum () != 106) {
        //      // If the locale codec is not UTF-8, we must check that the filename from the server can
        //      // be encoded in the local file system.
        //      //  
        //      // We cannot use GMime.Encoding.can_encode () since that can incorrectly return true, see
        //      // https://bugreports.qt.io/browse/GLib.TBUG-6925.
        //      GLib.TextEncoder encoder = new GLib.TextEncoder (local_codec, GMime.Encoding.Convert_invalid_to_null);
        //      if (encoder.from_unicode (path).contains ('\0')) {
        //          GLib.warning ("Cannot encode " + path + " to local encoding " + local_codec.name ());
        //          excluded = CSync.CSync.ExcludedFiles.Type.CANNOT_ENCODE;
        //      }
        //  }

        if (excluded == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED && !is_symlink) {
            return false;
        } else if (excluded == CSync.CSync.ExcludedFiles.Type.EXCLUDE_SILENT || excluded == CSync.CSync.ExcludedFiles.Type.EXCLUDE_AND_REMOVE) {
            this.discovery_data.signal_silently_excluded (path);
            return true;
        }

        SyncFileItem item = new SyncFileItem ();
        item.file = path;
        item.original_file = path;
        item.instruction = CSync.SyncInstructions.IGNORE;

        if (is_symlink) {
            // Symbolic links are ignored.
            item.error_string = _("Symbolic links are not supported in syncing.");
        } else {
            switch (excluded) {
            case CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED:
            case CSync.CSync.ExcludedFiles.Type.EXCLUDE_SILENT:
            case CSync.CSync.ExcludedFiles.Type.EXCLUDE_AND_REMOVE:
                GLib.fatal ("These were handled earlier");
            case CSync.CSync.ExcludedFiles.Type.LIST:
                item.error_string = _("File is listed on the ignore list.");
                break;
            case CSync.CSync.ExcludedFiles.Type.INVALID_CHAR:
                if (item.file.has_suffix ('.')) {
                    item.error_string = _("File names ending with a period are not supported on this file system.");
                } else {
                    char invalid = '\0';
                    foreach (char x in "\\:?*\"<>|") {
                        if (item.file.contains (x)) {
                            invalid = x;
                            break;
                        }
                    }
                    if (invalid) {
                        item.error_string = _("File names containing the character \"%1\" are not supported on this file system.").printf (invalid);
                    } else if (is_invalid_pattern) {
                        item.error_string = _("File name contains at least one invalid character");
                    } else {
                        item.error_string = _("The file name is a reserved name on this file system.");
                    }
                }
                item.status = SyncFileItem.Status.FILENAME_INVALID;
                break;
            case CSync.CSync.ExcludedFiles.Type.TRAILING_SPACE:
                item.error_string = _("Filename contains trailing spaces.");
                item.status = SyncFileItem.Status.FILENAME_INVALID;
                break;
            case CSync.CSync.ExcludedFiles.Type.LONG_FILENAME:
                item.error_string = _("Filename is too long.");
                item.status = SyncFileItem.Status.FILENAME_INVALID;
                break;
            case CSync.CSync.ExcludedFiles.Type.HIDDEN:
                item.error_string = _("File/FolderConnection is ignored because it's hidden.");
                break;
            case CSync.CSync.ExcludedFiles.Type.STAT_FAILED:
                item.error_string = _("Stat failed.");
                break;
            case CSync.CSync.ExcludedFiles.Type.CONFLICT:
                item.error_string = _("Conflict : Server version downloaded, local copy renamed and not uploaded.");
                item.status = SyncFileItem.Status.CONFLICT;
            break;
            case CSync.CSync.ExcludedFiles.Type.CANNOT_ENCODE:
                item.error_string = _("The filename cannot be encoded on your file system.");
                break;
            case CSync.CSync.ExcludedFiles.Type.SERVER_BLOCKLISTED:
                item.error_string = _("The filename is blocklisted on the server.");
                break;
            }
        }

        this.child_ignored = true;
        this.discovery_data.signal_item_discovered (item);
        return true;
    }


    /***********************************************************
    Reconcile local/remote/database information for a single item.

    Can be a file or a directory.
    Usually ends up emitting signal_item_discovered () or creating a subdirectory job.

    This main function delegates some work to the process_file* functions.
    ***********************************************************/
    private void process_file (PathTuple path,
        LocalInfo local_entry,
        RemoteInfo server_entry,
        Common.SyncJournalFileRecord database_entry
    ) {
        string has_server = server_entry.is_valid ? "true" : this.query_server == PARENT_NOT_CHANGED ? "database": "false";
        string has_local = local_entry.is_valid ? "true" : this.query_local == PARENT_NOT_CHANGED ? "database": "false";
        GLib.info (
            "Processing " + path.original
            + " | valid: " + database_entry.is_valid + "/" + has_local + "/" + has_server
            + " | mtime: " + database_entry.modtime + "/" + local_entry.modtime + "/" + server_entry.modtime
            + " | size: " + database_entry.file_size + "/" + local_entry.size + "/" + server_entry.size
            + " | etag: " + database_entry.etag + "//" + server_entry.etag
            + " | checksum: " + database_entry.checksum_header + "//" + server_entry.checksum_header
            + " | perm: " + database_entry.remote_permissions + "//" + server_entry.remote_permissions
            + " | fileid: " + database_entry.file_id + "//" + server_entry.file_identifier
            + " | inode: " + database_entry.inode + "/" + local_entry.inode + "/"
            + " | type: " + database_entry.type + "/" + local_entry.type + "/" + (server_entry.is_directory ? ItemType.DIRECTORY : ItemType.FILE)
            + " | e2ee: " + database_entry.is_e2e_encrypted + "/" + server_entry.is_e2e_encrypted
            + " | e2ee_mangled_name: " + database_entry.e2e_mangled_name () + "/" + server_entry.e2e_mangled_name
        );

        if (local_entry.is_valid
            && !server_entry.is_valid
            && !database_entry.is_valid
            && local_entry.modtime < this.last_sync_timestamp) {
            GLib.warning ("File " + path.original + " was modified before the last sync run and is not in the sync journal and server.");
        }

        if (this.discovery_data.is_renamed (path.original)) {
            GLib.debug ("Ignoring renamed.");
            return; // Ignore this.
        }

        SyncFileItem item = SyncFileItem.from_sync_journal_file_record (database_entry);
        item.file = path.target;
        item.original_file = path.original;
        item.previous_size = database_entry.file_size;
        item.previous_modtime = database_entry.modtime;
        if (local_entry.rename_name != "") {
            if (this.dir_item != null) {
                item.rename_target = this.dir_item.file + "/" + local_entry.rename_name;
            } else {
                item.rename_target = local_entry.rename_name;
            }
        }

        if (database_entry.modtime == local_entry.modtime && database_entry.type == ItemType.VIRTUAL_FILE && local_entry.type == ItemType.FILE) {
            item.type = ItemType.FILE;
        }

        // The item shall only have this type if the database request for the virtual download
        // was successful (like : no conflicting remote remove etc). This decision is done
        // either in process_file_analyze_remote_info () or further down here.
        if (item.type == ItemType.VIRTUAL_FILE_DOWNLOAD)
            item.type = ItemType.VIRTUAL_FILE;
        // Similarly database entries with a dehydration request denote a regular file
        // until the request is processed.
        if (item.type == ItemType.VIRTUAL_FILE_DEHYDRATION)
            item.type = ItemType.FILE;

        // VFS suffixed files on the server are ignored
        if (is_vfs_with_suffix ()) {
            if (has_virtual_file_suffix (server_entry.name)
                || (local_entry.is_virtual_file && !database_entry.is_virtual_file () && has_virtual_file_suffix (database_entry.path))) {
                item.instruction = CSync.SyncInstructions.IGNORE;
                item.error_string = _("File has extension reserved for virtual files.");
                this.child_ignored = true;
                this.discovery_data.signal_item_discovered (item);
                return;
            }
        }

        if (server_entry.is_valid) {
            process_file_analyze_remote_info (item, path, local_entry, server_entry, database_entry);
            return;
        }

        // Downloading a virtual file is like a server action and can happen even if
        // server-side nothing has changed
        // Note: Normally setting the Virtual_file_download flag means that local and
        // remote will be rediscovered. This is just a fallback for a similar check
        // in process_file_analyze_remote_info ().
        if (this.query_server == PARENT_NOT_CHANGED
            && database_entry.is_valid
            && (database_entry.type == ItemType.VIRTUAL_FILE_DOWNLOAD
                || local_entry.type == ItemType.VIRTUAL_FILE_DOWNLOAD)
            && (local_entry.is_valid || this.query_local == PARENT_NOT_CHANGED)) {
            item.direction = SyncFileItem.Direction.DOWN;
            item.instruction = CSync.SyncInstructions.SYNC;
            item.type = ItemType.VIRTUAL_FILE_DOWNLOAD;
        }

        process_file_analyze_local_info (item, path, local_entry, server_entry, database_entry, this.query_server);
    }


    /***********************************************************
    process_file helper for when remote information is available, typically flows into Analyze_local_info when done
    ***********************************************************/
    private void process_file_analyze_remote_info (
        SyncFileItem item, PathTuple path, LocalInfo local_entry,
        RemoteInfo server_entry, Common.SyncJournalFileRecord database_entry) {
        item.checksum_header = server_entry.checksum_header;
        item.file_id = server_entry.file_identifier;
        item.remote_permissions = server_entry.remote_permissions;
        item.type = server_entry.is_directory ? ItemType.DIRECTORY : ItemType.FILE;
        item.etag = server_entry.etag;
        item.direct_download_url = server_entry.direct_download_url;
        item.direct_download_cookies = server_entry.direct_download_cookies;
        item.is_encrypted = server_entry.is_e2e_encrypted;
        item.encrypted_filename = () => {
            if (server_entry.e2e_mangled_name == "") {
                return "";
            }

            GLib.assert (this.discovery_data.remote_folder.has_prefix ("/"));
            GLib.assert (this.discovery_data.remote_folder.has_suffix ("/"));

            var root_path = this.discovery_data.remote_folder.mid (1);
            GLib.assert (server_entry.e2e_mangled_name.has_prefix (root_path));
            return server_entry.e2e_mangled_name.mid (root_path.length);
        };

        // Check for missing server data {
        GLib.List<string> missing_data = new GLib.List<string> ();
        if (server_entry.size == -1) {
            missing_data.append (_("size"));
        }
        if (server_entry.remote_permissions == null) {
            missing_data.append (_("permission"));
        }
        if (server_entry.etag == "") {
            missing_data.append ("ETag");
        }
        if (server_entry.file_identifier == "") {
            missing_data.append (_("file identifier"));
        }
        if (missing_data != null) {
            item.instruction = CSync.SyncInstructions.ERROR;
            this.child_ignored = true;
            item.error_string = _("Server reported no %1").printf (missing_data.join (", "));
            this.discovery_data.signal_item_discovered (item);
            return;
        }

        // The file is known in the database already
        if (database_entry.is_valid) {
            bool is_database_entry_an_e2Ee_placeholder = database_entry.is_virtual_file () && !database_entry.e2e_mangled_name () = "";
            GLib.assert (!is_database_entry_an_e2Ee_placeholder || server_entry.size >= Constants.E2EE_TAG_SIZE);
            bool is_virtual_e2Ee_placeholder = is_database_entry_an_e2Ee_placeholder && server_entry.size >= Constants.E2EE_TAG_SIZE;
            int64 size_on_signal_server = is_virtual_e2Ee_placeholder ? server_entry.size - Constants.E2EE_TAG_SIZE : server_entry.size;
            bool meta_data_size_needs_update_for_e2Ee_file_placeholder = is_virtual_e2Ee_placeholder && database_entry.file_size == server_entry.size;

            if (server_entry.is_directory != database_entry.is_directory ()) {
                // If the type of the entity changed, it's like NEW, but
                // needs to delete the other entity first.
                item.instruction = CSync.SyncInstructions.TYPE_CHANGE;
                item.direction = SyncFileItem.Direction.DOWN;
                item.modtime = server_entry.modtime;
                item.size = size_on_signal_server;
            } else if ( (database_entry.type == ItemType.VIRTUAL_FILE_DOWNLOAD || local_entry.type == ItemType.VIRTUAL_FILE_DOWNLOAD)
                && (local_entry.is_valid || this.query_local == PARENT_NOT_CHANGED)) {
                // The above check for the local_entry existing is important. Otherwise it breaks
                // the case where a file is moved and simultaneously tagged for download in the database.
                item.direction = SyncFileItem.Direction.DOWN;
                item.instruction = CSync.SyncInstructions.SYNC;
                item.type = ItemType.VIRTUAL_FILE_DOWNLOAD;
            } else if (database_entry.etag != server_entry.etag) {
                item.direction = SyncFileItem.Direction.DOWN;
                item.modtime = server_entry.modtime;
                item.size = size_on_signal_server;
                if (server_entry.is_directory) {
                    //  ENFORCE (database_entry.is_directory ());
                    item.instruction = CSync.SyncInstructions.UPDATE_METADATA;
                } else if (!local_entry.is_valid && this.query_local != PARENT_NOT_CHANGED) {
                    // Deleted locally, changed on server
                    item.instruction = CSync.SyncInstructions.NEW;
                } else {
                    item.instruction = CSync.SyncInstructions.SYNC;
                }
            } else if (database_entry.modtime <= 0 && server_entry.modtime > 0) {
                item.direction = SyncFileItem.Direction.DOWN;
                item.modtime = server_entry.modtime;
                item.size = size_on_signal_server;
                if (server_entry.is_directory) {
                    //  ENFORCE (database_entry.is_directory ());
                    item.instruction = CSync.SyncInstructions.UPDATE_METADATA;
                } else if (!local_entry.is_valid && this.query_local != PARENT_NOT_CHANGED) {
                    // Deleted locally, changed on server
                    item.instruction = CSync.SyncInstructions.NEW;
                } else {
                    item.instruction = CSync.SyncInstructions.SYNC;
                }
            } else if (database_entry.remote_permissions != server_entry.remote_permissions || database_entry.file_id != server_entry.file_identifier || meta_data_size_needs_update_for_e2Ee_file_placeholder) {
                if (meta_data_size_needs_update_for_e2Ee_file_placeholder) {
                    // we are updating placeholder sizes after migrating from older versions with VFS + E2EE implicit hydration not supported
                    GLib.debug ("Migrating the E2EE VFS placeholder " + database_entry.path + " from older version. The old size is " + item.size + ". The new size is " + size_on_signal_server);
                    item.size = size_on_signal_server;
                }
                item.instruction = CSync.SyncInstructions.UPDATE_METADATA;
                item.direction = SyncFileItem.Direction.DOWN;
            } else {
                process_file_analyze_local_info (item, path, local_entry, server_entry, database_entry, server_query_mode);
                return;
            }
            process_file_analyze_local_info (item, path, local_entry, server_entry, database_entry, this.query_server);
            return;
        }

        // Unknown in database : new file on the server
        GLib.assert (!database_entry.is_valid);

        item.instruction = CSync.SyncInstructions.NEW;
        item.direction = SyncFileItem.Direction.DOWN;
        item.modtime = server_entry.modtime;
        item.size = server_entry.size;

        // Potential NEW/NEW conflict is handled in Analyze_local
        if (local_entry.is_valid) {
            post_process_server_new ();
            return;
        }

        // Not in database or locally : either new or a rename
        GLib.assert (!database_entry.is_valid && !local_entry.is_valid);

        // Check for renames (if there is a file with the same file identifier)
        bool done = false;
        bool async = false;

        if (!this.discovery_data.statedatabase.get_file_records_by_file_id (server_entry.file_identifier, rename_candidate_processing)) {
            db_error ();
            return;
        }
        if (async) {
            return; // We went async
        }

        if (item.instruction == CSync.SyncInstructions.NEW) {
            post_process_server_new ();
            return;
        }
        process_file_analyze_local_info (item, path, local_entry, server_entry, database_entry, this.query_server);
    }


    /***********************************************************
    if (is virtual mode enabled and folder is encrypted - check
    if the size is the same as on the server and then - trigger
    server query to update a placeholder with corrected size
    (-16 Bytes) or, maybe, add a flag to the database -
    vfs_e2ee_size_corrected? if it is not set - subtract it
    from the placeholder's size and re-create/update a
    placeholder?
    ***********************************************************/
    private QueryMode server_query_mode (Common.SyncJournalFileRecord database_entry, RemoteInfo server_entry) {
        if (this.discovery_data != null
            && this.discovery_data.sync_options.vfs
            && this.discovery_data.sync_options.vfs.mode () != Common.AbstractVfs.Off
            && database_entry.is_directory ()
            && database_entry.is_e2e_encrypted
        ) {
            int64 local_folder_size = 0;

            bool list_files_succeeded = this.discovery_data.statedatabase.list_files_in_path (database_entry.path.to_utf8 (), list_files_callback);

            if (list_files_succeeded && local_folder_size != 0 && local_folder_size == server_entry.size_of_folder) {
                GLib.info ("Migration of E2EE folder " + database_entry.path + " from older version to the one, supporting the implicit VFS hydration.");
                return NORMAL_QUERY;
            }
        }
        return PARENT_NOT_CHANGED;
    }



    private void post_process_server_new () /*mutable*/ {
        if (item.is_directory ()) {
            this.pending_async_jobs++;
            this.discovery_data.check_selective_sync_new_folder (
                path.server,
                server_entry.remote_permissions,
                this.selective_sync_filter
            );
            return;
        }
        // Turn new remote files into virtual files if the option is enabled.
        var opts = this.discovery_data.sync_options;
        if (!local_entry.is_valid
            && item.type == ItemType.FILE
            && opts.vfs.mode () != Common.AbstractVfs.Off
            && this.pin_state != PinState.ALWAYS_LOCAL
            && !FileSystem.is_exclude_file (item.file)) {
            item.type = ItemType.VIRTUAL_FILE;
            if (is_vfs_with_suffix ()) {
                path.original = add_virtual_file_suffix (path.original);
            }
        }

        if (opts.vfs.mode () != Common.AbstractVfs.Off && !item.encrypted_filename == "") {
            // We are syncing a file for the first time (local entry is invalid) and it is encrypted file that will be virtual once synced
            // to avoid having error of "file has changed during sync" when trying to hydrate it excplicitly - we must remove Constants.E2EE_TAG_SIZE bytes from the end
            // as explicit hydration does not care if these bytes are present in the placeholder or not, but, the size must not change in the middle of the sync
            // this way it works for both implicit and explicit hydration by making a placeholder size that does not includes encryption tag Constants.E2EE_TAG_SIZE bytes
            // another scenario - we are syncing a file which is on disk but not in the database (database was removed or file was not written there yet)
            item.size = server_entry.size - Constants.E2EE_TAG_SIZE;
        }
        process_file_analyze_local_info (item, path, local_entry, server_entry, database_entry, this.query_server);
    }


    private void selective_sync_filter (bool result) {
        --this.pending_async_jobs;
        if (!result) {
            process_file_analyze_local_info (item, path, local_entry, server_entry, database_entry, this.query_server);
        }
        GLib.Timeout.add (0, this.discovery_data.on_signal_schedule_more_jobs);
    }


    private void list_files_callback (int64 local_folder_size, Common.SyncJournalFileRecord record) {
        if (record.is_file ()) {
            // add Constants.E2EE_TAG_SIZE so we will know the size of E2EE file on the server
            local_folder_size += record.file_size + Constants.E2EE_TAG_SIZE;
        } else if (record.is_virtual_file ()) {
            // just a virtual file, so, the size must contain Constants.E2EE_TAG_SIZE if it was not corrected already
            local_folder_size += record.file_size;
        }
    }


    private void post_process_rename (SyncFileItem item, Common.SyncJournalFileRecord base_record, string original_path, PathTuple path) {
        var adjusted_original_path = this.discovery_data.adjust_renamed_path (original_path, SyncFileItem.Direction.UP);
        this.discovery_data.renamed_items_remote.insert (original_path, path.target);
        item.modtime = base_record.modtime;
        item.inode = base_record.inode;
        item.instruction = CSync.SyncInstructions.RENAME;
        item.direction = SyncFileItem.Direction.DOWN;
        item.rename_target = path.target;
        item.file = adjusted_original_path;
        item.original_file = original_path;
        path.original = original_path;
        path.local = adjusted_original_path;
        GLib.info ("Rename detected (down) " + item.file + " . " + item.rename_target);
    }


    private void on_signal_request_etag_job_finished_with_result (Result<T, HttpError><string> etag) /*mutable*/ {
        this.pending_async_jobs--;
        GLib.Timeout.add (0, this.discovery_data.on_signal_schedule_more_jobs);
        if (etag || etag.error.code != 404 ||
            // Somehow another item claimed this original path, consider as if it existed
            this.discovery_data.is_renamed (original_path)) {
            // If the file exist or if there is another error, consider it is a new file.
            post_process_server_new ();
            return;
        }

        // The file do not exist, it is a rename

        // In case the deleted item was discovered in parallel
        this.discovery_data.find_and_cancel_deleted_job (original_path);

        post_process_rename (path);
        process_file_finalize (item, path, item.is_directory (), item.instruction == CSync.SyncInstructions.RENAME ? NORMAL_QUERY : PARENT_DOES_NOT_EXIST, this.query_server);
    }



    // This function will be executed for every candidate
    private void rename_candidate_processing (Common.SyncJournalFileRecord base_record) {
        if (done)
            return;
        if (!base_record.is_valid)
            return;

        // Remote rename of a virtual file we have locally scheduled for download.
        if (base_record.type == ItemType.VIRTUAL_FILE_DOWNLOAD) {
            // We just consider this NEW but mark it for download.
            item.type = ItemType.VIRTUAL_FILE_DOWNLOAD;
            done = true;
            return;
        }

        // Remote rename targets a file that shall be locally dehydrated.
        if (base_record.type == ItemType.VIRTUAL_FILE_DEHYDRATION) {
            // Don't worry about the rename, just consider it DELETE + NEW (virtual)
            done = true;
            return;
        }

        // Some things prohibit rename detection entirely.
        // Since we don't do the same checks again in reconcile, we can't
        // just skip the candidate, but have to give up completely.
        if (base_record.is_directory () != item.is_directory ()) {
            GLib.info ();
            done = true;
            return;
        }
        if (!server_entry.is_directory && base_record.etag != server_entry.etag) {
            // File with different etag, don't do a rename, but download the file again
            GLib.info ();
            done = true;
            return;
        }

        // Now we know there is a sane rename candidate.
        string original_path = base_record.path;

        if (this.discovery_data.is_renamed (original_path)) {
            GLib.info ();
            return;
        }

        // A remote rename can also mean Encryption Mangled Name.
        // if we find one of those in the database, we ignore it.
        if (!base_record.e2e_mangled_name == "") {
            GLib.warning ();
            done = true;
            return;
        }

        string original_path_adjusted = this.discovery_data.adjust_renamed_path (original_path, SyncFileItem.Direction.UP);

        if (!base_record.is_directory ()) {
            CSync.FileStat buf;
            if (csync_vio_local_stat (this.discovery_data.local_directory + original_path_adjusted, buf)) {
                GLib.info ("Local file does not exist anymore. " + original_path_adjusted);
                return;
            }
            // Note: This prohibits some VFS renames from being detected since
            // suffix-file size is different from the database size. That's ok, they'll DELETE+NEW.
            if (buf.modtime != base_record.modtime || buf.size != base_record.file_size || buf.type == ItemType.DIRECTORY) {
                GLib.info ("File has changed locally; not a rename. " + original_path);
                return;
            }
        } else {
            if (!GLib.File.new_for_path (this.discovery_data.local_directory + original_path_adjusted).query_info ().get_file_type () == FileType.DIRECTORY) {
                GLib.info ("Local directory does not exist anymore. " + original_path_adjusted);
                return;
            }
        }

        // Renames of virtuals are possible
        if (base_record.is_virtual_file ()) {
            item.type = ItemType.VIRTUAL_FILE;
        }

        bool was_deleted_on_signal_server = this.discovery_data.find_and_cancel_deleted_job (original_path).first;

        if (was_deleted_on_signal_server) {
            post_process_rename (path);
            done = true;
        } else {
            // we need to make a request to the server to know that the original file is deleted on the server
            this.pending_async_jobs++;
            var request_etag_job = new RequestEtagJob (this.discovery_data.account, this.discovery_data.remote_folder + original_path, this);
            request_etag_job.signal_finished_with_result.connect (
                this.on_signal_request_etag_job_finished_with_result
            );
            request_etag_job.start ();
            done = true; // Ideally, if the origin still exist on the server, we should continue searching...  but that'd be difficult
            async = true;
        }
    }


    /***********************************************************
    process_file helper for reconciling local changes
    ***********************************************************/
    private void process_file_analyze_local_info (
        SyncFileItem item,
        PathTuple path,
        LocalInfo local_entry,
        RemoteInfo server_entry,
        Common.SyncJournalFileRecord database_entry,
        QueryMode recurse_query_server) {
        bool no_server_entry = (this.query_server != PARENT_NOT_CHANGED && !server_entry.is_valid)
            || (this.query_server == PARENT_NOT_CHANGED && !database_entry.is_valid);

        if (no_server_entry)
            recurse_query_server = PARENT_DOES_NOT_EXIST;

        bool server_modified = item.instruction == CSync.SyncInstructions.NEW || item.instruction == CSync.SyncInstructions.SYNC
            || item.instruction == CSync.SyncInstructions.RENAME || item.instruction == CSync.SyncInstructions.TYPE_CHANGE;

        // Decay server modifications to UPDATE_METADATA if the local virtual exists
        bool has_local_virtual = local_entry.is_virtual_file || (this.query_local == PARENT_NOT_CHANGED && database_entry.is_virtual_file ());
        bool virtual_file_download = item.type == ItemType.VIRTUAL_FILE_DOWNLOAD;
        if (server_modified && !virtual_file_download && has_local_virtual) {
            item.instruction = CSync.SyncInstructions.UPDATE_METADATA;
            server_modified = false;
            item.type = ItemType.VIRTUAL_FILE;
        }

        if (database_entry.is_virtual_file () && (!local_entry.is_valid || local_entry.is_virtual_file) && !virtual_file_download) {
            item.type = ItemType.VIRTUAL_FILE;
        }

        this.child_modified |= server_modified;

        if (!local_entry.is_valid) {
            if (this.query_local == PARENT_NOT_CHANGED && database_entry.is_valid) {
                // Not modified locally (PARENT_NOT_CHANGED)
                if (no_server_entry) {
                    // not on the server : Removed on the server, delete locally
                    GLib.info ("File " + item.file + " is not anymore on server. Going to delete it locally.");
                    item.instruction = CSync.SyncInstructions.REMOVE;
                    item.direction = SyncFileItem.Direction.DOWN;
                } else if (database_entry.type == ItemType.VIRTUAL_FILE_DEHYDRATION) {
                    // dehydration requested
                    item.direction = SyncFileItem.Direction.DOWN;
                    item.instruction = CSync.SyncInstructions.SYNC;
                    item.type = ItemType.VIRTUAL_FILE_DEHYDRATION;
                }
            } else if (no_server_entry) {
                // Not locally, not on the server. The entry is stale!
                GLib.info ("Stale DB entry.");
                this.discovery_data.statedatabase.delete_file_record (path.original, true);
                return;
            } else if (database_entry.type == ItemType.VIRTUAL_FILE && is_vfs_with_suffix ()) {
                // If the virtual file is removed, recreate it.
                // This is a precaution since the suffix files don't look like the real ones
                // and we don't want users to accidentally delete server data because they
                // might not expect that deleting the placeholder will have a remote effect.
                item.instruction = CSync.SyncInstructions.NEW;
                item.direction = SyncFileItem.Direction.DOWN;
                item.type = ItemType.VIRTUAL_FILE;
            } else if (!server_modified) {
                // Removed locally : also remove on the server.
                if (!database_entry.server_has_ignored_files) {
                    GLib.info ("File " + item.file + " was deleted locally. Going to delete it on the server.");
                    item.instruction = CSync.SyncInstructions.REMOVE;
                    item.direction = SyncFileItem.Direction.UP;
                }
            }

            on_signal_finalize ();
            return;
        }

        GLib.assert (local_entry.is_valid);

        item.inode = local_entry.inode;

        if (database_entry.is_valid) {
            bool type_change = local_entry.is_directory != database_entry.is_directory ();
            if (!type_change && local_entry.is_virtual_file) {
                if (no_server_entry) {
                    item.instruction = CSync.SyncInstructions.REMOVE;
                    item.direction = SyncFileItem.Direction.DOWN;
                } else if (!database_entry.is_virtual_file () && is_vfs_with_suffix ()) {
                    // If we find what looks to be a spurious "abc.owncloud" the base_record file "abc"
                    // might have been renamed to that. Make sure that the base_record file is not
                    // deleted from the server.
                    if (database_entry.modtime == local_entry.modtime && database_entry.file_size == local_entry.size) {
                        GLib.info ("Base file was renamed to virtual file: " + item.file);
                        item.direction = SyncFileItem.Direction.DOWN;
                        item.instruction = CSync.SyncInstructions.SYNC;
                        item.type = ItemType.VIRTUAL_FILE_DEHYDRATION;
                        item.file = add_virtual_file_suffix (item.file);
                        item.rename_target = item.file;
                    } else {
                        GLib.info ("Virtual file with non-virtual database entry; ignoring: " + item.file);
                        item.instruction = CSync.SyncInstructions.IGNORE;
                    }
                }
            } else if (!type_change && ( (database_entry.modtime == local_entry.modtime && database_entry.file_size == local_entry.size) || local_entry.is_directory)) {
                // Local file unchanged.
                if (no_server_entry) {
                    GLib.info ("File " + item.file + " is not anymore on server. Going to delete it locally.");
                    item.instruction = CSync.SyncInstructions.REMOVE;
                    item.direction = SyncFileItem.Direction.DOWN;
                } else if (database_entry.type == ItemType.VIRTUAL_FILE_DEHYDRATION || local_entry.type == ItemType.VIRTUAL_FILE_DEHYDRATION) {
                    item.direction = SyncFileItem.Direction.DOWN;
                    item.instruction = CSync.SyncInstructions.SYNC;
                    item.type = ItemType.VIRTUAL_FILE_DEHYDRATION;
                } else if (!server_modified
                    && (database_entry.inode != local_entry.inode
                        || this.discovery_data.sync_options.vfs.needs_metadata_update (item))) {
                    item.instruction = CSync.SyncInstructions.UPDATE_METADATA;
                    item.direction = SyncFileItem.Direction.DOWN;
                }
            } else if (!type_change && is_vfs_with_suffix ()
                && database_entry.is_virtual_file () && !local_entry.is_virtual_file
                && database_entry.inode == local_entry.inode
                && database_entry.modtime == local_entry.modtime
                && local_entry.size == 1) {
                // A suffix vfs file can be downloaded by renaming it to remove the suffix.
                // This check leaks some details of VfsSuffix, particularly the size of placeholders.
                item.direction = SyncFileItem.Direction.DOWN;
                if (no_server_entry) {
                    item.instruction = CSync.SyncInstructions.REMOVE;
                    item.type = ItemType.FILE;
                } else {
                    item.instruction = CSync.SyncInstructions.SYNC;
                    item.type = ItemType.VIRTUAL_FILE_DOWNLOAD;
                    item.previous_size = 1;
                }
            } else if (server_modified
                || (is_vfs_with_suffix () && database_entry.is_virtual_file ())) {
                // There's a local change and a server change : Conflict!
                // Alternatively, this might be a suffix-file that's virtual in the database but
                // not locally. These also become conflicts. For in-place placeholders that's
                // not necessary : they could be replaced by real files and should then trigger
                // a regular SYNC upwards when there's no server change.
                process_file_conflict (item, path, local_entry, server_entry, database_entry);
            } else if (type_change) {
                item.instruction = CSync.SyncInstructions.TYPE_CHANGE;
                item.direction = SyncFileItem.Direction.UP;
                item.checksum_header = "";
                item.size = local_entry.size;
                item.modtime = local_entry.modtime;
                item.type = local_entry.is_directory ? ItemType.DIRECTORY : ItemType.FILE;
                this.child_modified = true;
            } else if (database_entry.modtime > 0 && local_entry.modtime <= 0) {
                item.instruction = CSync.SyncInstructions.SYNC;
                item.direction = SyncFileItem.Direction.DOWN;
                item.size = local_entry.size > 0 ? local_entry.size : database_entry.file_size;
                item.modtime = database_entry.modtime;
                item.previous_modtime = database_entry.modtime;
                item.type = local_entry.is_directory ? ItemType.DIRECTORY : ItemType.FILE;
                this.child_modified = true;
            } else {
                // Local file was changed
                item.instruction = CSync.SyncInstructions.SYNC;
                if (no_server_entry) {
                    // Special case! deleted on server, modified on client, the instruction is then NEW
                    item.instruction = CSync.SyncInstructions.NEW;
                }
                item.direction = SyncFileItem.Direction.UP;
                item.checksum_header = "";
                item.size = local_entry.size;
                item.modtime = local_entry.modtime;
                this.child_modified = true;

                // Checksum comparison at this stage is only enabled for .eml files,
                // check #4754 #4755
                bool is_eml_file = path.original.has_suffix (".eml", GLib.CaseInsensitive);
                if (is_eml_file && database_entry.file_size == local_entry.size && !database_entry.checksum_header == "") {
                    if (compute_local_checksum (database_entry.checksum_header, this.discovery_data.local_directory + path.local, item)
                            && item.checksum_header == database_entry.checksum_header) {
                        GLib.info ("Note: Checksums are identical, file did not actually change: " + path.local);
                        item.instruction = CSync.SyncInstructions.UPDATE_METADATA;
                    }
                }
            }

            on_signal_finalize ();
            return;
        }

        GLib.assert (!database_entry.is_valid);

        if (local_entry.is_virtual_file && !no_server_entry) {
            // Somehow there is a missing DB entry while the virtual file already exists.
            // The instruction should already be set correctly.
            //  GLib.assert_true (item.instruction == CSync.SyncInstructions.UPDATE_METADATA);
            //  GLib.assert_true (item.type == ItemType.VIRTUAL_FILE);
            on_signal_finalize ();
            return;
        } else if (server_modified) {
            process_file_conflict (item, path, local_entry, server_entry, database_entry);
            on_signal_finalize ();
            return;
        }

        // New local file or rename
        item.instruction = CSync.SyncInstructions.NEW;
        item.direction = SyncFileItem.Direction.UP;
        item.checksum_header = "";
        item.size = local_entry.size;
        item.modtime = local_entry.modtime;
        item.type = local_entry.is_directory ? ItemType.DIRECTORY : local_entry.is_virtual_file ? ItemType.VIRTUAL_FILE : ItemType.FILE;
        this.child_modified = true;

        // Check if it is a move
        Common.SyncJournalFileRecord base_record;
        if (!this.discovery_data.statedatabase.get_file_record_by_inode (local_entry.inode, base_record)) {
            db_error ();
            return;
        }
        var original_path = base_record.path;

        // If it's not a move it's just a local-NEW
        if (!move_check ()) {
            if (base_record.is_e2e_encrypted) {
                // renaming the encrypted folder is done via remove + re-upload hence we need to mark the newly created folder as encrypted
                // base_record is a record in the SyncJournal database that contains the data about the being-renamed folder with it's old name and encryption information
                item.is_encrypted = true;
            }
            post_process_local_new ();
            on_signal_finalize ();
            return;
        }

        // Check local permission if we are allowed to put move the file here
        // Technically we should use the permissions from the server, but we'll assume it is the same
        var move_perms = check_move_permissions (base_record.remote_permissions, original_path, item.is_directory ());
        if (!move_perms.source_ok || !move_perms.destination_ok) {
            GLib.info (
                "Move without permission to rename base_record file, "
                + "source: " + move_perms.source_ok
                + ", target: " + move_perms.destination_ok
                + ", target_new: " + move_perms.destination_new_ok
            );

            // If we can create the destination, do that.
            // Permission errors on the destination will be handled by check_permissions later.
            post_process_local_new ();
            on_signal_finalize ();

            // If the destination upload will work, we're fine with the source deletion.
            // If the source deletion can't work, check_permissions will error.
            if (move_perms.destination_new_ok)
                return;

            // Here we know the new location can't be uploaded : must prevent the source delete.
            // Two cases : either the source item was already processed or not.
            var was_deleted_on_signal_client = this.discovery_data.find_and_cancel_deleted_job (original_path);
            if (was_deleted_on_signal_client.first) {
                // More complicated. The REMOVE is canceled. Restore will happen next sync.
                GLib.info ("Undid remove instruction on source " + original_path);
                this.discovery_data.statedatabase.delete_file_record (original_path, true);
                this.discovery_data.statedatabase.schedule_path_for_remote_discovery (original_path);
                this.discovery_data.another_sync_needed = true;
            } else {
                // Signal to future check_permissions () to forbid the REMOVE and set to restore instead
                GLib.info ("Preventing future remove on source " + original_path);
                this.discovery_data.forbidden_deletes[original_path + "/"] = true;
            }
            return;
        }

        var was_deleted_on_signal_client = this.discovery_data.find_and_cancel_deleted_job (original_path);

        if (was_deleted_on_signal_client.first) {
            recurse_query_server = was_deleted_on_signal_client.second == base_record.etag ? PARENT_NOT_CHANGED : NORMAL_QUERY;
            process_rename (path);
        } else {
            // We must query the server to know if the etag has not changed
            this.pending_async_jobs++;
            string server_original_path = this.discovery_data.remote_folder + this.discovery_data.adjust_renamed_path (original_path, SyncFileItem.Direction.DOWN);
            if (base_record.is_virtual_file () && is_vfs_with_suffix ())
                chop_virtual_file_suffix (server_original_path);
            var request_etag_job = new RequestEtagJob (this.discovery_data.account, server_original_path, this);
            request_etag_job.signal_finished_with_result.connect (
                this.on_signal_request_etag_job_finished_with_result
            );
            request_etag_job.start ();
            return;
        }

        on_signal_finalize ();
    }


    private void on_signal_finalize () {
        bool recurse = item.is_directory () || local_entry.is_directory || server_entry.is_directory;
        // Even if we have a local directory : If the remote is a file that's propagated as a
        // conflict we don't need to recurse into it. (local c1.owncloud, c1/ ; remote : c1)
        if (item.instruction == CSync.SyncInstructions.CONFLICT && !item.is_directory ()) {
            recurse = false;
        }
        if (this.query_local != NORMAL_QUERY && this.query_server != NORMAL_QUERY) {
            recurse = false;
        }

        var recurse_query_local = this.query_local == PARENT_NOT_CHANGED ? PARENT_NOT_CHANGED : local_entry.is_directory || item.instruction == CSync.SyncInstructions.RENAME ? NORMAL_QUERY : PARENT_DOES_NOT_EXIST;
        process_file_finalize (item, path, recurse, recurse_query_local, recurse_query_server);
    }


    private void on_signal_request_etag_job_finished_with_result (Result<T, HttpError><string> etag) /*mutable*/ {
        if (!etag || (etag != base_record.etag && !item.is_directory ()) || this.discovery_data.is_renamed (original_path)) {
            GLib.info ("Can't rename because the etag has changed or the directory is gone " + original_path);
            // Can't be a rename, leave it as a new.
            post_process_local_new ();
        } else {
            // In case the deleted item was discovered in parallel
            this.discovery_data.find_and_cancel_deleted_job (original_path);
            process_rename (path);
            recurse_query_server = etag == base_record.etag ? PARENT_NOT_CHANGED : NORMAL_QUERY;
        }
        process_file_finalize (item, path, item.is_directory (), NORMAL_QUERY, recurse_query_server);
        this.pending_async_jobs--;
        GLib.Timeout.add (0, this.discovery_data.on_signal_schedule_more_jobs);
    }


    private void post_process_local_new (SyncFileItem item, LocalInfo local_entry, string path) {
        // TODO: We may want to execute the same logic for non-VFS mode, as, moving/renaming the same folder by 2 or more clients at the same time is not possible in Web UI.
        // Keeping it like this (for VFS files and folders only) just to fix a user issue.

        if (! (this.discovery_data != null && this.discovery_data.sync_options.vfs && this.discovery_data.sync_options.vfs.mode () != Common.AbstractVfs.Off)) {
            // for VFS files and folders only
            return;
        }

        if (!local_entry.is_virtual_file && !local_entry.is_directory) {
            return;
        }

        if (local_entry.is_directory && this.discovery_data.sync_options.vfs.mode () != Common.AbstractVfs.WindowsCfApi) {
            // for VFS folders on Windows only
            return;
        }

        GLib.assert (item.instruction == CSync.SyncInstructions.NEW);
        if (item.instruction != CSync.SyncInstructions.NEW) {
            GLib.warning ("Trying to wipe a virtual item " + path.local + " with item.instruction " + item.instruction);
            return;
        }

        // must be a dehydrated placeholder
        bool is_file_place_holder = !local_entry.is_directory && this.discovery_data.sync_options.vfs.is_dehydrated_placeholder (this.discovery_data.local_directory + path.local);

        // either correct availability, or a result with error if the folder is new or otherwise has no availability set yet
        var folder_place_holder_availability = local_entry.is_directory ? this.discovery_data.sync_options.vfs.availability (path.local) : Common.AbstractVfs.AvailabilityResult (Common.AbstractVfs.AvailabilityError.NO_SUCH_ITEM);

        var folder_pin_state = local_entry.is_directory ? this.discovery_data.sync_options.vfs.pin_state (path.local) : Gpseq.Optional<Common.AbstractVfs.PinState> (PinState.UNSPECIFIED);

        if (!is_file_place_holder && !folder_place_holder_availability.is_valid && !folder_pin_state.is_valid) {
            // not a file placeholder and not a synced folder placeholder (new local folder)
            return;
        }

        var is_folder_pin_state_online_only = (folder_pin_state.is_valid && *folder_pin_state == Common.ItemAvailability.ONLINE_ONLY);

        var isfolder_place_holder_availability_online_only = (folder_place_holder_availability.is_valid && *folder_place_holder_availability == Common.ItemAvailability.ONLINE_ONLY);

        // a folder is considered online-only if : no files are hydrated, or, if it's an empty folder
        var is_online_only_folder = isfolder_place_holder_availability_online_only || (!folder_place_holder_availability && is_folder_pin_state_online_only);

        if (!is_file_place_holder && !is_online_only_folder) {
            if (local_entry.is_directory && folder_place_holder_availability.is_valid && !is_online_only_folder) {
                // a VFS folder but is not online0only (has some files hydrated)
                GLib.info ("Virtual directory without database entry for " + path.local + " but it contains hydrated file (s), so let's keep it and reupload.");
                this.discovery_data.signal_add_error_to_gui (SyncFileItem.Status.SOFT_ERROR, _("Conflict when uploading some files to a folder. Those, conflicted, are going to get cleared!"), path.local);
                return;
            }
            GLib.warning (
                "Virtual file without database entry for " + path.local
                + " but looks odd; keeping."
            );
            item.instruction = CSync.SyncInstructions.IGNORE;

            return;
        }

        if (is_online_only_folder) {
            // if we're wiping a folder, we will only get this function called once and will wipe a folder along with it's files and also display one error in GUI
            GLib.info ("Wiping virtual folder without database entry for " + path.local);
            if (isfolder_place_holder_availability_online_only && folder_place_holder_availability.is_valid) {
                GLib.info ("folder_place_holder_availability: " + folder_place_holder_availability);
            }
            if (is_folder_pin_state_online_only && folder_pin_state.is_valid) {
                GLib.info ("folder_pin_state: " + folder_pin_state);
            }
            this.discovery_data.signal_add_error_to_gui (SyncFileItem.Status.SOFT_ERROR, _("Conflict when uploading a folder. It's going to get cleared!"), path.local);
        } else {
            GLib.info ("Wiping virtual file without database entry for " + path.local);
            this.discovery_data.signal_add_error_to_gui (SyncFileItem.Status.SOFT_ERROR, _("Conflict when uploading a file. It's going to get removed!"), path.local);
        }
        item.instruction = CSync.SyncInstructions.REMOVE;
        item.direction = SyncFileItem.Direction.DOWN;
        // this flag needs to be unset, otherwise a folder would get marked as new in the process_sub_jobs
        this.child_modified = false;
    }


    private void process_rename (
        SyncFileItem item,
        string original_path,
        Common.SyncJournalFileRecord base_record,
        PathTuple path) {
        var adjusted_original_path = this.discovery_data.adjust_renamed_path (original_path, SyncFileItem.Direction.DOWN);
        this.discovery_data.renamed_items_local.insert (original_path, path.target);
        item.rename_target = path.target;
        path.server = adjusted_original_path;
        item.file = path.server;
        path.original = original_path;
        item.original_file = path.original;
        item.modtime = base_record.modtime;
        item.inode = base_record.inode;
        item.instruction = CSync.SyncInstructions.RENAME;
        item.direction = SyncFileItem.Direction.UP;
        item.file_id = base_record.file_id;
        item.remote_permissions = base_record.remote_permissions;
        item.etag = base_record.etag;
        item.type = base_record.type;

        // Discard any download/dehydrate tags on the base_record file.
        // They could be preserved and honored in a follow-up sync,
        // but it complicates handling a lot and will happen rarely.
        if (item.type == ItemType.VIRTUAL_FILE_DOWNLOAD)
            item.type = ItemType.VIRTUAL_FILE;
        if (item.type == ItemType.VIRTUAL_FILE_DEHYDRATION)
            item.type = ItemType.FILE;

        GLib.info ("Rename detected (up) " + item.file + " . " + item.rename_target);
    }


    /***********************************************************
    Function to gradually check conditions for accepting a
    move-candidate
    ***********************************************************/
    private void move_check () {
        if (!base_record.is_valid) {
            GLib.info ("Not a move; no item in database with inode " + local_entry.inode);
            return false;
        }

        if (base_record.is_e2e_encrypted || this.is_inside_encrypted_tree) {
            return false;
        }

        if (base_record.is_directory () != item.is_directory ()) {
            GLib.info ("Not a move, types don't match " + base_record.type + item.type + local_entry.type);
            return false;
        }
        // Directories and virtual files don't need size/mtime equality
        if (!local_entry.is_directory && !base_record.is_virtual_file ()
            && (base_record.modtime != local_entry.modtime || base_record.file_size != local_entry.size)) {
            GLib.info (
                "Not a move, mtime or size differs, "
                + "modtime: " + base_record.modtime + local_entry.modtime + ", "
                + "size: " + base_record.file_size + local_entry.size
            );
            return false;
        }

        // The old file must have been deleted.
        if (GLib.File.exists (this.discovery_data.local_directory + original_path)
            // Exception : If the rename changes case only (like "foo" . "Foo") the
            // old filename might still point to the same file.
            && ! (Utility.fs_case_preserving
                    && original_path.compare (path.local, GLib.CaseInsensitive) == 0
                    && original_path != path.local)) {
            GLib.info ("Not a move; base_record file still exists at " + original_path);
            return false;
        }

        // Verify the checksum where possible
        if (!base_record.checksum_header == "" && item.type == ItemType.FILE && base_record.type == ItemType.FILE) {
            if (compute_local_checksum (base_record.checksum_header, this.discovery_data.local_directory + path.original, item)) {
                GLib.info ("checking checksum of potential rename " + path.original + item.checksum_header + base_record.checksum_header);
                if (item.checksum_header != base_record.checksum_header) {
                    GLib.info ("Not a move, checksums differ.");
                    return false;
                }
            }
        }

        if (this.discovery_data.is_renamed (original_path)) {
            GLib.info ("Not a move, base_record path already renamed.");
            return false;
        }

        return true;
    }


    /***********************************************************
    process_file helper for local/remote conflicts
    ***********************************************************/
    private void process_file_conflict (SyncFileItem item, ProcessDirectoryJob.PathTuple path, LocalInfo local_entry, RemoteInfo server_entry, Common.SyncJournalFileRecord database_entry) {
        item.previous_size = local_entry.size;
        item.previous_modtime = local_entry.modtime;

        if (server_entry.is_directory && local_entry.is_directory) {
            // Folders of the same path are always considered equals
            item.instruction = CSync.SyncInstructions.UPDATE_METADATA;
            return;
        }

        // A conflict with a virtual should lead to virtual file download
        if (database_entry.is_virtual_file () || local_entry.is_virtual_file)
            item.type = ItemType.VIRTUAL_FILE_DOWNLOAD;

        // If there's no content hash, use heuristics
        if (server_entry.checksum_header == "") {
            // If the size or mtime is different, it's definitely a conflict.
            bool is_conflict = (server_entry.size != local_entry.size) || (server_entry.modtime != local_entry.modtime);

            // It could be a conflict even if size and mtime match!
            //  
            // In older client versions we always treated these cases as a
            // non-conflict. This behavior is preserved in case the server
            // doesn't provide a content checksum.
            // SO : If there is no checksum, we can have !is_conflict here
            // even though the files might have different content! This is an
            // intentional tradeoff. Downloading and comparing files would
            // be technically correct in this situation but leads to too
            // much waste.
            // In particular this kind of NEW/NEW situation with identical
            // sizes and mtimes pops up when the local database is lost for
            // whatever reason.
            item.instruction = is_conflict ? CSync.SyncInstructions.CONFLICT : CSync.SyncInstructions.UPDATE_METADATA;
            item.direction = is_conflict ? SyncFileItem.Direction.NONE : SyncFileItem.Direction.DOWN;
            return;
        }

        // Do we have an UploadInfo for this?
        // Maybe the Upload was completed, but the connection was broken just before
        // we recieved the etag (Issue #5106)
        var up = this.discovery_data.statedatabase.get_upload_info (path.original);
        if (up.valid && up.content_checksum == server_entry.checksum_header) {
            // Solve the conflict into an upload, or nothing
            item.instruction = up.modtime == local_entry.modtime && up.size == local_entry.size
                ? CSync.SyncInstructions.NONE : CSync.SyncInstructions.SYNC;
            item.direction = SyncFileItem.Direction.UP;

            // Update the etag and other server metadata in the journal already
            // (We can't use a typical CSync.SyncInstructions.UPDATE_METADATA because
            // we must not store the size/modtime from the file system)
            Common.SyncJournalFileRecord record;
            if (this.discovery_data.statedatabase.get_file_record (path.original, record)) {
                record.path = path.original.to_utf8 ();
                record.etag = server_entry.etag;
                record.file_id = server_entry.file_identifier;
                record.modtime = server_entry.modtime;
                record.type = item.type;
                record.file_size = server_entry.size;
                record.remote_permissions = server_entry.remote_permissions;
                record.checksum_header = server_entry.checksum_header;
                this.discovery_data.statedatabase.file_record (record);
            }
            return;
        }

        // Rely on content hash comparisons to optimize away non-conflicts inside the job
        item.instruction = CSync.SyncInstructions.CONFLICT;
        item.direction = SyncFileItem.Direction.NONE;
    }


    /***********************************************************
    process_file helper for common final processing
    ***********************************************************/
    private void process_file_finalize (
        SyncFileItem item, PathTuple path, bool recurse,
        QueryMode recurse_query_local, QueryMode recurse_query_server) {
        // Adjust target path for virtual-suffix files
        if (is_vfs_with_suffix ()) {
            if (item.type == ItemType.VIRTUAL_FILE) {
                path.target = add_virtual_file_suffix (path.target);
                if (item.instruction == CSync.SyncInstructions.RENAME) {
                    item.rename_target = add_virtual_file_suffix (item.rename_target);
                } else {
                    item.file = add_virtual_file_suffix (item.file);
                }
            }
            if (item.type == ItemType.VIRTUAL_FILE_DEHYDRATION
                && item.instruction == CSync.SyncInstructions.SYNC) {
                if (item.rename_target == "") {
                    item.rename_target = item.file;
                    item.rename_target = add_virtual_file_suffix (item.rename_target);
                }
            }
        }

        if (path.original != path.target && (item.instruction == CSync.SyncInstructions.UPDATE_METADATA || item.instruction == CSync.SyncInstructions.NONE)) {
            //  GLib.assert_true (this.dir_item && this.dir_item.instruction == CSync.SyncInstructions.RENAME);
            // This is because otherwise subitems are not updated!  (ideally renaming a directory could
            // update the database for all items!  See PropagateDirectory.on_signal_sub_jobs_finished)
            item.instruction = CSync.SyncInstructions.RENAME;
            item.rename_target = path.target;
            item.direction = this.dir_item.direction;
        }

        GLib.info ("Discovered " + item.file + item.instruction + item.direction + item.type);

        if (item.is_directory () && item.instruction == CSync.SyncInstructions.SYNC)
            item.instruction = CSync.SyncInstructions.UPDATE_METADATA;
        bool removed = item.instruction == CSync.SyncInstructions.REMOVE;
        if (check_permissions (item)) {
            if (item.is_restoration && item.is_directory ())
                recurse = true;
        } else {
            recurse = false;
        }
        if (recurse) {
            var process_directory_job = new ProcessDirectoryJob (path, item, recurse_query_local, recurse_query_server,
                this.last_sync_timestamp, this);
            process_directory_job.is_inside_encrypted_tree (is_inside_encrypted_tree () || item.is_encrypted);
            if (removed) {
                process_directory_job.parent (this.discovery_data);
                this.discovery_data.queued_deleted_directories[path.original] = process_directory_job;
            } else {
                ProcessDirectoryJob.signal_finished.connect (
                    process_directory_job, ProcessDirectoryJob.sub_job_finished
                );
                this.queued_jobs.push_back (process_directory_job);
            }
        } else {
            if (removed
                // For the purpose of rename deletion, restored deleted placeholder is as if it was deleted
                || (item.type == ItemType.VIRTUAL_FILE && item.instruction == CSync.SyncInstructions.NEW)) {
                this.discovery_data.deleted_item[path.original] = item;
            }
            this.discovery_data.signal_item_discovered (item);
        }
    }


    /***********************************************************
    Checks the permission for this item, if needed, change the item to a restoration item.
    @return false indicate that this is an error and if it is a directory, one should not recurse
    inside it.
    ***********************************************************/
    private bool check_permissions (SyncFileItem item) {
        if (item.direction != SyncFileItem.Direction.UP) {
            // Currently we only check server-side permissions
            return true;
        }

        switch (item.instruction) {
        case CSync.SyncInstructions.TYPE_CHANGE:
        case CSync.SyncInstructions.NEW: {
            var perms = !this.root_permissions == null ? this.root_permissions
                                                          : this.dir_item ? this.dir_item.remote_permissions : this.root_permissions;
            if (perms == null) {
                // No permissions set
                return true;
            } else if (item.is_directory () && !perms.has_permission (Common.RemotePermissions.Permissions.CAN_ADD_SUB_DIRECTORIES)) {
                GLib.warning ("check_for_permission: ERROR " + item.file);
                item.instruction = CSync.SyncInstructions.ERROR;
                item.error_string = _("Not allowed because you don't have permission to add subfolders to that folder");
                return false;
            } else if (!item.is_directory () && !perms.has_permission (Common.RemotePermissions.Permissions.CAN_ADD_FILE)) {
                GLib.warning ("check_for_permission: ERROR " + item.file);
                item.instruction = CSync.SyncInstructions.ERROR;
                item.error_string = _("Not allowed because you don't have permission to add files in that folder");
                return false;
            }
            break;
        }
        case CSync.SyncInstructions.SYNC: {
            var perms = item.remote_permissions;
            if (perms == null) {
                // No permissions set
                return true;
            }
            if (!perms.has_permission (Common.RemotePermissions.Permissions.CAN_WRITE)) {
                item.instruction = CSync.SyncInstructions.CONFLICT;
                item.error_string = _("Not allowed to upload this file because it is read-only on the server, restoring");
                item.direction = SyncFileItem.Direction.DOWN;
                item.is_restoration = true;
                GLib.warning ("check_for_permission: RESTORING " + item.file + item.error_string);
                // Take the things to write to the database from the "other" node (i.e : info from server).
                // Do a lookup into the csync remote tree to get the metadata we need to restore.
                q_swap (item.size, item.previous_size);
                q_swap (item.modtime, item.previous_modtime);
                return false;
            }
            break;
        }
        case CSync.SyncInstructions.REMOVE: {
            string file_slash = item.file + "/";
            var forbidden_it = this.discovery_data.forbidden_deletes.upper_bound (file_slash);
            if (forbidden_it != this.discovery_data.forbidden_deletes.begin ()) {
                forbidden_it -= 1;
            }
            if (forbidden_it != this.discovery_data.forbidden_deletes.end ()
                && file_slash.has_prefix (forbidden_it.key ())) {
                item.instruction = CSync.SyncInstructions.NEW;
                item.direction = SyncFileItem.Direction.DOWN;
                item.is_restoration = true;
                item.error_string = _("Moved to invalid target, restoring");
                GLib.warning ("check_for_permission: RESTORING " + item.file + item.error_string);
                return true; // restore sub items
            }
            var perms = item.remote_permissions;
            if (perms == null) {
                // No permissions set
                return true;
            }
            if (!perms.has_permission (Common.RemotePermissions.Permissions.CAN_DELETE)) {
                item.instruction = CSync.SyncInstructions.NEW;
                item.direction = SyncFileItem.Direction.DOWN;
                item.is_restoration = true;
                item.error_string = _("Not allowed to remove, restoring");
                GLib.warning ("check_for_permission: RESTORING " + item.file + item.error_string);
                return true; // (we need to recurse to restore sub items)
            }
            break;
        }
        default:
            break;
        }
        return true;
    }


    /***********************************************************
    Check if the move is of a specified file within this
    directory is allowed. Return true if it is allowed, false
    otherwise
    ***********************************************************/
    private MovePermissionResult check_move_permissions (Common.RemotePermissions src_perm, string src_path, bool is_directory) {
        //  . MovePermissionResult {
        Common.RemotePermissions dest_perms;
        if (this.root_permissions != null) {
            dest_perms = this.root_permissions;
        } else if (this.dir_item) {
            dest_perms = this.dir_item.remote_permissions;
        } else {
            dest_perms = this.root_permissions;
        }
        var file_perms = src_perm;
        //  true when it is just a rename in the same directory. (not a move)
        bool is_rename = src_path.has_prefix (this.current_folder.original)
            && src_path.last_index_of ("/") == this.current_folder.original.size ();
        // Check if we are allowed to move to the destination.
        bool destination_ok = true;
        bool destination_new_ok = true;
        if (dest_perms == null) {
        } else if ( (is_directory && !dest_perms.has_permission (Common.RemotePermissions.Permissions.CAN_ADD_SUB_DIRECTORIES)) ||
                  (!is_directory && !dest_perms.has_permission (Common.RemotePermissions.Permissions.CAN_ADD_FILE))) {
            destination_new_ok = false;
        }
        if (!is_rename && !destination_new_ok) {
            // no need to check for the destination directory permission for renames
            destination_ok = false;
        }

        // check if we are allowed to move from the source
        bool source_ok = true;
        if (!file_perms == null
            && ( (is_rename && !file_perms.has_permission (Common.RemotePermissions.Permissions.CAN_RENAME))
                    || (!is_rename && !file_perms.has_permission (Common.RemotePermissions.Permissions.CAN_MOVE)))) {
            // We are not allowed to move or rename this file
            source_ok = false;
        }
        return new MovePermissionResult (source_ok, destination_ok, destination_new_ok);
    }


    /***********************************************************
    ***********************************************************/
    void process_blocklisted (
        PathTuple path,
        LocalInfo local_entry,
        Common.SyncJournalFileRecord database_entry
    ) {
        if (!local_entry.is_valid) {
            return;
        }

        var item = SyncFileItem.from_sync_journal_file_record (database_entry);
        item.file = path.target;
        item.original_file = path.original;
        item.inode = local_entry.inode;
        item.is_selective_sync = true;
        if (database_entry.is_valid && ( (database_entry.modtime == local_entry.modtime && database_entry.file_size == local_entry.size) || (local_entry.is_directory && database_entry.is_directory ()))) {
            item.instruction = CSync.SyncInstructions.REMOVE;
            item.direction = SyncFileItem.Direction.DOWN;
        } else {
            item.instruction = CSync.SyncInstructions.IGNORE;
            item.status = SyncFileItem.Status.FILE_IGNORED;
            item.error_string = _("Ignored because of the \"choose what to sync\" blocklist");
            this.child_ignored = true;
        }

        GLib.info ("Discovered (blocklisted) " + item.file + item.instruction + item.direction + item.is_directory ());

        if (item.is_directory () && item.instruction != CSync.SyncInstructions.IGNORE) {
            var process_directory_job = new ProcessDirectoryJob (path, item, NORMAL_QUERY, IN_BLOCK_LIST, this.last_sync_timestamp, this);
            process_directory_job.signal_finished.connect (
                this.on_signal_sub_job_finished
            );
            this.queued_jobs.push_back (process_directory_job);
        } else {
            this.discovery_data.signal_item_discovered (item);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void sub_job_finished () {
        var process_directory_job = (ProcessDirectoryJob)sender ();
        //  GLib.assert_true (process_directory_job);

        this.child_ignored |= process_directory_job.child_ignored;
        this.child_modified |= process_directory_job.child_modified;

        if (process_directory_job.dir_item)
            this.discovery_data.signal_item_discovered (process_directory_job.dir_item);

        int count = this.running_jobs.remove_all (process_directory_job);
        //  GLib.assert_true (count == 1);
        process_directory_job.delete_later ();
        GLib.Timeout.add (0, this.discovery_data.on_signal_schedule_more_jobs);
    }


    /***********************************************************
    An DB operation failed
    ***********************************************************/
    private void db_error () {
        this.discovery_data.signal_fatal_error (_("Error while reading the database"));
    }


    /***********************************************************
    ***********************************************************/
    private string add_virtual_file_suffix (string string_value) {
        return string_value + this.discovery_data.sync_options.vfs.file_suffix ();
    }


    /***********************************************************
    ***********************************************************/
    private bool has_virtual_file_suffix (string string_value) {
        if (!is_vfs_with_suffix ())
            return false;
        return string_value.has_suffix (this.discovery_data.sync_options.vfs.file_suffix ());
    }


    /***********************************************************
    ***********************************************************/
    private void chop_virtual_file_suffix (string string_value) {
        if (!is_vfs_with_suffix ())
            return;
        bool has_suffix = has_virtual_file_suffix (string_value);
        //  GLib.assert_true (has_suffix);
        if (has_suffix)
            string_value.chop (this.discovery_data.sync_options.vfs.file_suffix ().size ());
    }


    /***********************************************************
    Convenience to detect suffix-vfs modes
    ***********************************************************/
    private bool is_vfs_with_suffix () {
        return this.discovery_data.sync_options.vfs.mode () == Common.AbstractVfs.WithSuffix;
    }


    /***********************************************************
    Start a remote discovery network job

    It fills this.server_normal_query_entries and sets this.server_query_done when done.
    ***********************************************************/
    private DiscoverySingleDirectoryJob start_async_server_query () {
        var discovery_single_directory_job = new DiscoverySingleDirectoryJob (
            this.discovery_data.account,
            this.discovery_data.remote_folder + this.current_folder.server,
            this
        );
        if (this.dir_item == null) {
            discovery_single_directory_job.is_root_path_true (); // query the fingerprint on the root
        }
        discovery_single_directory_job.signal_etag.connect (
            this.on_signal_etag
        );
        this.discovery_data.currently_active_jobs++;
        this.pending_async_jobs++;
        discovery_single_directory_job.signal_finished.connect (
            this.on_signal_discovery_single_directory_job_finished
        );
        discovery_single_directory_job.signal_first_directory_permissions.connect (
            this.on_signal_discovery_single_directory_job_first_directory_permissions
        );
        discovery_single_directory_job.start ();
        return discovery_single_directory_job;
    }


    private void on_signal_discovery_single_directory_job_finished (DiscoverySingleDirectoryJob discovery_single_directory_job, var results) {
        this.discovery_data.currently_active_jobs--;
        this.pending_async_jobs--;
        if (results != null) {
            this.server_normal_query_entries = *results;
            this.server_query_done = true;
            if (!discovery_single_directory_job.data_fingerprint == "" && this.discovery_data.data_fingerprint == "")
                this.discovery_data.data_fingerprint = discovery_single_directory_job.data_fingerprint;
            if (this.local_query_done)
                this.process ();
        } else {
            var code = results.error.code;
            GLib.warning ("Server error in directory " + this.current_folder.server + code);
            if (this.dir_item != null && code >= 403) {
                // In case of an HTTP error, we ignore that directory
                // 403 Forbidden can be sent by the server if the file firewall is active.
                // A file or directory should be ignored and sync must continue. See #3490
                // The server usually replies with the custom "503 Storage not available"
                // if some path is temporarily unavailable. But in some cases a standard 503
                // is returned too. Thus we can't distinguish the two and will treat any
                // 503 as request to ignore the folder. See #3113 #2884.
                // Similarly, the server might also return 404 or 50x in case of bugs. #7199 #7586
                this.dir_item.instruction = CSync.SyncInstructions.IGNORE;
                this.dir_item.error_string = results.error.message;
                this.signal_finished ();
            } else {
                // Fatal for the root job since it has no SyncFileItem, or for the network errors
                this.discovery_data.signal_fatal_error (_("Server replied with an error while reading directory \"%1\" : %2")
                    .printf (this.current_folder.server, results.error.message));
            }
        }
    }


    private void on_signal_discovery_single_directory_job_first_directory_permissions (Common.RemotePermissions perms) {
        this.root_permissions = perms;
    }


    /***********************************************************
    Discover the local directory

    Fills this.local_normal_query_entries.
    ***********************************************************/
    private void start_async_local_query () {
        string local_path = this.discovery_data.local_directory + this.current_folder.local;
        var local_job = new DiscoverySingleLocalDirectoryJob (this.discovery_data.account, local_path, this.discovery_data.sync_options.vfs);

        this.discovery_data.currently_active_jobs++;
        this.pending_async_jobs++;

        local_job.signal_item_discovered.connect (
            this.discovery_data.on_signal_item_discovered
        );

        local_job.signal_child_ignored.connect (
            this.on_signal_discovery_single_local_directory_job_child_ignored
        );

        local_job.signal_finished_fatal_error.connect (
            this.on_signal_discovery_single_local_directory_job_finished_fatal_error
        );

        local_job.signal_finished_non_fatal_error.connect (
            this.on_signal_discovery_single_local_directory_job_finished_non_fatal_error
        );

        local_job.signal_finished.connect (
            this.on_signal_discovery_single_local_directory_job_finished
        );

        GLib.ThreadPool pool = GLib.ThreadPool.global_instance;
        pool.start (local_job); // GLib.ThreadPool takes ownership
    }


    private void on_signal_discovery_single_local_directory_job_child_ignored (bool b) {
        this.child_ignored = b;
    }


    private void on_signal_discovery_single_local_directory_job_finished_fatal_error (string message) {
        this.discovery_data.currently_active_jobs--;
        this.pending_async_jobs--;
        if (this.discovery_single_directory_job != null) {
            this.discovery_single_directory_job.abort ();
        }

        this.discovery_data.signal_fatal_error (message);
    }


    private void on_signal_discovery_single_local_directory_job_finished_non_fatal_error (string message) {
        this.discovery_data.currently_active_jobs--;
        this.pending_async_jobs--;

        if (this.dir_item != null) {
            this.dir_item.instruction = CSync.SyncInstructions.IGNORE;
            this.dir_item.error_string = message;
            this.signal_finished ();
        } else {
            // Fatal for the root job since it has no SyncFileItem
            this.discovery_data.signal_fatal_error (message);
        }
    }


    private void on_signal_discovery_single_local_directory_job_finished (var results) {
        this.discovery_data.currently_active_jobs--;
        this.pending_async_jobs--;

        this.local_normal_query_entries = results;
        this.local_query_done = true;

        if (this.server_query_done) {
            this.process ();
        }
    }


    /***********************************************************
    Sets this.pin_state, the directory's pin state

    If the folder exists locally its state is retrieved, otherwise the
    parent's pin state is inherited.
    ***********************************************************/
    private void compute_pin_state (Common.PinState parent_state) {
        this.pin_state = parent_state;
        if (this.query_local != PARENT_DOES_NOT_EXIST) {
            var state = this.discovery_data.sync_options.vfs.pin_state (this.current_folder.local);
            if (state) { // ouch! pin local or original?
                this.pin_state = state;
            }
        }
    }


    /***********************************************************
    Adjust record.type if the database pin state suggests it.

    If the pin state is stored in the database (suffix vfs only right now)
    its effects won't be seen in local_entry.type. Instead the effects
    should materialize in database_entry.type.

    This function checks whether the combination of file type and pi
    state suggests a hydration or dehydration action and changes the
    this.type field accordingly.
    ***********************************************************/
    private void up_database_pin_state_actions (Common.SyncJournalFileRecord record) {
        // Only suffix-vfs uses the database for pin states.
        // Other plugins will set local_entry.type according to the file's pin state.
        if (!is_vfs_with_suffix ())
            return;

        var pin = this.discovery_data.statedatabase.internal_pin_states.raw_for_path (record.path);
        if (!pin || *pin == Common.PinState.INHERITED)
            pin = this.pin_state;

        // Common.ItemAvailability.ONLINE_ONLY hydrated files want to be dehydrated
        if (record.type == ItemType.FILE && *pin == Common.ItemAvailability.ONLINE_ONLY)
            record.type = ItemType.VIRTUAL_FILE_DEHYDRATION;

        // PinState.ALWAYS_LOCAL dehydrated files want to be hydrated
        if (record.type == ItemType.VIRTUAL_FILE && *pin == Common.PinState.ALWAYS_LOCAL)
            record.type = ItemType.VIRTUAL_FILE_DOWNLOAD;
    }


    /***********************************************************
    Compute the checksum of the given file and assign the result
    in item.checksum_header. Returns true if the checksum was
    successfully computed.
    ***********************************************************/
    private static bool compute_local_checksum (string header, string path, SyncFileItem item) {
        var type = parse_checksum_header_type (header);
        if (!type == "") {
            // TODO: compute async?
            string checksum = ComputeChecksum.compute_now_on_signal_file (path, type);
            if (!checksum == "") {
                item.checksum_header = make_checksum_header (type, checksum);
                return true;
            }
        }
        return false;
    }

} // class ProcessDirectoryJob

} // namespace LibSync
} // namespace Occ