/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QDebug>
// #include <algorithm>
// #include <QEventLoop>
// #include <QDir>
// #include <set>
// #include <QTextCodec>
// #include <QFileInfo>
// #include <QFile>
// #include <QThreadPool>
// #include <common/checksums.h>
// #include <common/constants.h>

// #pragma once

// #include <GLib.Object>


namespace Occ {

/***********************************************************
Job that handles discovery of a directory.

This includes:
 - Do a DiscoverySingleDirectoryJob network job which will do a PRO
 - Stat all the entries in the local file system for this directory
 - Merge all information (and the information from
   to be done for every file within this directory.
 - For every sub-directory within this directory, "recursivel

This job is tightly coupled with the DiscoveryPhase class.

After being start ()'ed

Internally, this job will call DiscoveryPhase.schedule_more_jobs when one of its sub-jobs is
finished. DiscoveryPhase.schedule_more_jobs will call process_sub_jobs () to continue work until
the job is finished.

Results are fed outwards via the DiscoveryPhase.item_discovered () signal.
***********************************************************/
class ProcessDirectoryJob : GLib.Object {

    struct PathTuple;
public:
    enum Query_mode {
        Normal_query,
        Parent_dont_exist, // Do not query this folder because it does not exist
        Parent_not_changed, // No need to query this folder because it has not changed from what is in the DB
        In_black_list // Do not query this folder because it is in the blacklist (remote entries only)
    };
    Q_ENUM (Query_mode)

    /***********************************************************
    For creating the root job

    The base pin state is used if the root dir's pin state can't be retrieved.
    ***********************************************************/
    ProcessDirectoryJob (DiscoveryPhase *data, PinState base_pin_state,
        int64 last_sync_timestamp, GLib.Object *parent)
        : GLib.Object (parent)
        , _last_sync_timestamp (last_sync_timestamp)
        , _discovery_data (data) {
        compute_pin_state (base_pin_state);
    }

    /// For creating subjobs
    ProcessDirectoryJob (PathTuple &path, SyncFileItemPtr &dir_item,
        Query_mode query_local, Query_mode query_server, int64 last_sync_timestamp,
        ProcessDirectoryJob *parent)
        : GLib.Object (parent)
        , _dir_item (dir_item)
        , _last_sync_timestamp (last_sync_timestamp)
        , _query_server (query_server)
        , _query_local (query_local)
        , _discovery_data (parent._discovery_data)
        , _current_folder (path) {
        compute_pin_state (parent._pin_state);
    }

    void start ();
    /***********************************************************
    Start up to nb_jobs, return the number of job started; emit finished () when done
    ***********************************************************/
    int process_sub_jobs (int nb_jobs);

    void set_inside_encrypted_tree (bool is_inside_encrypted_tree) {
        _is_inside_encrypted_tree = is_inside_encrypted_tree;
    }

    bool is_inside_encrypted_tree () {
        return _is_inside_encrypted_tree;
    }

    SyncFileItemPtr _dir_item;

private:
    struct Entries {
        string name_override;
        SyncJournalFileRecord db_entry;
        RemoteInfo server_entry;
        LocalInfo local_entry;
    };

    /***********************************************************
    Structure representing a path during discovery. A same path may have different value locally
    or on the server in case of renames.

    These strings never start or ends with slashes. They are all relative to the fo
    Usually they are all the same and are even shared instance of the s

    _server and _local path
      remote renamed A/ to
        target :   B/Y/file
        original : A/X/file
        local :    A/Y/file
        server :   B/X/file
    ***********************************************************/
    struct PathTuple {
        string _original; // Path as in the DB (before the sync)
        string _target; // Path that will be the result after the sync (and will be in the DB)
        string _server; // Path on the server (before the sync)
        string _local; // Path locally (before the sync)
        static string path_append (string &base, string &name) {
            return base.is_empty () ? name : base + QLatin1Char ('/') + name;
        }
        PathTuple add_name (string &name) {
            PathTuple result;
            result._original = path_append (_original, name);
            auto build_string = [&] (string &other) {
                // Optimize by trying to keep all string implicitly shared if they are the same (common case)
                return other == _original ? result._original : path_append (other, name);
            };
            result._target = build_string (_target);
            result._server = build_string (_server);
            result._local = build_string (_local);
            return result;
        }
    };

    bool check_for_invalid_file_name (PathTuple &path, std.map<string, Entries> &entries, Entries &entry);

    /***********************************************************
    Iterate over entries inside the directory (non-recursively).

    Called once _server_entries and _local_entries are filled
    Calls process_file () for each non-excluded one.
    Will start scheduling subdir jobs when done.
    ***********************************************************/
    void process ();

    // return true if the file is excluded.
    // path is the full relative path of the file. local_name is the base name of the local entry.
    bool handle_excluded (string &path, string &local_name, bool is_directory,
        bool is_hidden, bool is_symlink);

    /***********************************************************
    Reconcile local/remote/db information for a single item.

    Can be a file or a directory.
    Usually ends up emitting item_discovered () or creating a subdirectory job.

    This main function delegates some work to the process_file* functions.
    ***********************************************************/
    void process_file (PathTuple, LocalInfo &, RemoteInfo &, SyncJournalFileRecord &);

    /// process_file helper for when remote information is available, typically flows into Analyze_local_info when done
    void process_file_analyze_remote_info (SyncFileItemPtr &item, PathTuple, LocalInfo &, RemoteInfo &, SyncJournalFileRecord &);

    /// process_file helper for reconciling local changes
    void process_file_analyze_local_info (SyncFileItemPtr &item, PathTuple, LocalInfo &, RemoteInfo &, SyncJournalFileRecord &, Query_mode recurse_query_server);

    /// process_file helper for local/remote conflicts
    void process_file_conflict (SyncFileItemPtr &item, PathTuple, LocalInfo &, RemoteInfo &, SyncJournalFileRecord &);

    /// process_file helper for common final processing
    void process_file_finalize (SyncFileItemPtr &item, PathTuple, bool recurse, Query_mode recurse_query_local, Query_mode recurse_query_server);

    /***********************************************************
    Checks the permission for this item, if needed, change the item to a restoration item.
    @return false indicate that this is an error and if it is a directory, one should not recurse
    inside it.
    ***********************************************************/
    bool check_permissions (SyncFileItemPtr &item);

    struct Move_permission_result {
        // whether moving/renaming the source is ok
        bool source_ok = false;
        // whether the destination accepts (always true for renames)
        bool destination_ok = false;
        // whether creating a new file/dir in the destination is ok
        bool destination_new_ok = false;
    };

    /***********************************************************
    Check if the move is of a specified file within this directory is allowed.
    Return true if it is allowed, false otherwise
    ***********************************************************/
    Move_permission_result check_move_permissions (RemotePermissions src_perm, string &src_path, bool is_directory);

    void process_blacklisted (PathTuple &, LocalInfo &, SyncJournalFileRecord &db_entry);
    void sub_job_finished ();

    /***********************************************************
    An DB operation failed
    ***********************************************************/
    void db_error ();

    void add_virtual_file_suffix (string &str) const;
    bool has_virtual_file_suffix (string &str) const;
    void chop_virtual_file_suffix (string &str) const;

    /***********************************************************
    Convenience to detect suffix-vfs modes
    ***********************************************************/
    bool is_vfs_with_suffix ();

    /***********************************************************
    Start a remote discovery network job

    It fills _server_normal_query_entries and sets _server_query_done when done.
    ***********************************************************/
    DiscoverySingleDirectoryJob *start_async_server_query ();

    /***********************************************************
    Discover the local directory

    Fills _local_normal_query_entries.
    ***********************************************************/
    void start_async_local_query ();

    /***********************************************************
    Sets _pin_state, the directory's pin state

    If the folder exists locally its state is retrieved, otherwise the
    parent's pin state is inherited.
    ***********************************************************/
    void compute_pin_state (PinState parent_state);

    /***********************************************************
    Adjust record._type if the db pin state suggests it.

    If the pin state is stored in the database (suffix vfs only right now)
    its effects won't be seen in local_entry._type. Instead the effects
    should materialize in db_entry._type.

    This function checks whether the combination of file type and pi
    state suggests a hydration or dehydration action and changes the
    _type field accordingly.
    ***********************************************************/
    void setup_db_pin_state_actions (SyncJournalFileRecord &record);

    int64 _last_sync_timestamp = 0;

    Query_mode _query_server = Query_mode.Normal_query;
    Query_mode _query_local = Query_mode.Normal_query;

    // Holds entries that resulted from a Normal_query
    QVector<RemoteInfo> _server_normal_query_entries;
    QVector<LocalInfo> _local_normal_query_entries;

    // Whether the local/remote directory item queries are done. Will be set
    // even even for do-nothing (!= Normal_query) queries.
    bool _server_query_done = false;
    bool _local_query_done = false;

    RemotePermissions _root_permissions;
    QPointer<DiscoverySingleDirectoryJob> _server_job;

    /***********************************************************
    Number of currently running async jobs.

    These "async jobs" have nothing to do with the jobs for subdirectories
    which are being tracked by _queued_jobs and _running_jobs.

    They are jobs that need to be completed to finish processing of direct
    entries. This variable is used to ensure this job doesn't finish while
    these jobs are still in flight.
    ***********************************************************/
    int _pending_async_jobs = 0;

    /***********************************************************
    The queued and running jobs for subdirectories.

    The jobs are enqueued while processind directory entries and
    then gradually run via calls to process_sub_jobs ().
    ***********************************************************/
    std.deque<ProcessDirectoryJob> _queued_jobs;
    QVector<ProcessDirectoryJob> _running_jobs;

    DiscoveryPhase *_discovery_data;

    PathTuple _current_folder;
    bool _child_modified = false; // the directory contains modified item what would prevent deletion
    bool _child_ignored = false; // The directory contains ignored item that would prevent deletion
    PinState _pin_state = PinState.Unspecified; // The directory's pin-state, see compute_pin_state ()
    bool _is_inside_encrypted_tree = false; // this directory is encrypted or is within the tree of directories with root directory encrypted

signals:
    void finished ();
    // The root etag of this directory was fetched
    void etag (QByteArray &, QDateTime &time);
};

    bool ProcessDirectoryJob.check_for_invalid_file_name (PathTuple &path,
        const std.map<string, Entries> &entries, Entries &entry) {
        const auto original_file_name = entry.local_entry.name;
        const auto new_file_name = original_file_name.trimmed ();

        if (original_file_name == new_file_name) {
            return true;
        }

        const auto entries_iter = entries.find (new_file_name);
        if (entries_iter != entries.end ()) {
            string error_message;
            const auto new_file_name_entry = entries_iter.second;
            if (new_file_name_entry.server_entry.is_valid ()) {
                error_message = tr ("File contains trailing spaces and could not be renamed, because a file with the same name already exists on the server.");
            }
            if (new_file_name_entry.local_entry.is_valid ()) {
                error_message = tr ("File contains trailing spaces and could not be renamed, because a file with the same name already exists locally.");
            }

            if (!error_message.is_empty ()) {
                auto item = SyncFileItemPtr.create ();
                if (entry.local_entry.is_directory) {
                    item._type = CSync_enums.ItemTypeDirectory;
                } else {
                    item._type = CSync_enums.ItemTypeFile;
                }
                item._file = path._target;
                item._original_file = path._target;
                item._instruction = CSYNC_INSTRUCTION_ERROR;
                item._status = SyncFileItem.NormalError;
                item._error_string = error_message;
                emit _discovery_data.item_discovered (item);
                return false;
            }
        }

        entry.local_entry.rename_name = new_file_name;

        return true;
    }

    void ProcessDirectoryJob.start () {
        q_c_info (lc_disco) << "STARTING" << _current_folder._server << _query_server << _current_folder._local << _query_local;

        if (_query_server == Normal_query) {
            _server_job = start_async_server_query ();
        } else {
            _server_query_done = true;
        }

        // Check whether a normal local query is even necessary
        if (_query_local == Normal_query) {
            if (!_discovery_data._should_discover_localy (_current_folder._local)
                && (_current_folder._local == _current_folder._original || !_discovery_data._should_discover_localy (_current_folder._original))) {
                _query_local = Parent_not_changed;
            }
        }

        if (_query_local == Normal_query) {
            start_async_local_query ();
        } else {
            _local_query_done = true;
        }

        if (_local_query_done && _server_query_done) {
            process ();
        }
    }

    void ProcessDirectoryJob.process () {
        ASSERT (_local_query_done && _server_query_done);

        // Build lookup tables for local, remote and db entries.
        // For suffix-virtual files, the key will normally be the base file name
        // without the suffix.
        // However, if foo and foo.owncloud exists locally, there'll be "foo"
        // with local, db, server entries and "foo.owncloud" with only a local
        // entry.
        std.map<string, Entries> entries;
        for (auto &e : _server_normal_query_entries) {
            entries[e.name].server_entry = std.move (e);
        }
        _server_normal_query_entries.clear ();

        // fetch all the name from the DB
        auto path_u8 = _current_folder._original.to_utf8 ();
        if (!_discovery_data._statedb.list_files_in_path (path_u8, [&] (SyncJournalFileRecord &rec) {
                auto name = path_u8.is_empty () ? rec._path : string.from_utf8 (rec._path.const_data () + (path_u8.size () + 1));
                if (rec.is_virtual_file () && is_vfs_with_suffix ())
                    chop_virtual_file_suffix (name);
                auto &db_entry = entries[name].db_entry;
                db_entry = rec;
                setup_db_pin_state_actions (db_entry);
            })) {
            db_error ();
            return;
        }

        for (auto &e : _local_normal_query_entries) {
            entries[e.name].local_entry = e;
        }
        if (is_vfs_with_suffix ()) {
            // For vfs-suffix the local data for suffixed files should usually be associated
            // with the non-suffixed name. Unless both names exist locally or there's
            // other data about the suffixed file.
            // This is done in a second path in order to not depend on the order of
            // _local_normal_query_entries.
            for (auto &e : _local_normal_query_entries) {
                if (!e.is_virtual_file)
                    continue;
                auto &suffixed_entry = entries[e.name];
                bool has_other_data = suffixed_entry.server_entry.is_valid () || suffixed_entry.db_entry.is_valid ();

                auto nonvirtual_name = e.name;
                chop_virtual_file_suffix (nonvirtual_name);
                auto &nonvirtual_entry = entries[nonvirtual_name];
                // If the non-suffixed entry has no data, move it
                if (!nonvirtual_entry.local_entry.is_valid ()) {
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
        _local_normal_query_entries.clear ();

        //
        // Iterate over entries and process them
        //
        for (auto &f : entries) {
            auto &e = f.second;

            PathTuple path;
            path = _current_folder.add_name (e.name_override.is_empty () ? f.first : e.name_override);

            if (is_vfs_with_suffix ()) {
                // Without suffix vfs the paths would be good. But since the db_entry and local_entry
                // can have different names from f.first when suffix vfs is on, make sure the
                // corresponding _original and _local paths are right.

                if (e.db_entry.is_valid ()) {
                    path._original = e.db_entry._path;
                } else if (e.local_entry.is_virtual_file) {
                    // We don't have a db entry - but it should be at this path
                    path._original = PathTuple.path_append (_current_folder._original,  e.local_entry.name);
                }
                if (e.local_entry.is_valid ()) {
                    path._local = PathTuple.path_append (_current_folder._local, e.local_entry.name);
                } else if (e.db_entry.is_virtual_file ()) {
                    // We don't have a local entry - but it should be at this path
                    add_virtual_file_suffix (path._local);
                }
            }

            // On the server the path is mangled in case of E2EE
            if (!e.server_entry.e2e_mangled_name.is_empty ()) {
                Q_ASSERT (_discovery_data._remote_folder.starts_with ('/'));
                Q_ASSERT (_discovery_data._remote_folder.ends_with ('/'));

                const auto root_path = _discovery_data._remote_folder.mid (1);
                Q_ASSERT (e.server_entry.e2e_mangled_name.starts_with (root_path));

                path._server = e.server_entry.e2e_mangled_name.mid (root_path.length ());
            }

            // If the filename starts with a . we consider it a hidden file
            // For windows, the hidden state is also discovered within the vio
            // local stat function.
            // Recall file shall not be ignored (#4420)
            bool is_hidden = e.local_entry.is_hidden || (!f.first.is_empty () && f.first[0] == '.' && f.first != QLatin1String (".sys.admin#recall#"));
            const bool is_server_entry_windows_shortcut = false;
            if (handle_excluded (path._target, e.local_entry.name,
                    e.local_entry.is_directory || e.server_entry.is_directory, is_hidden,
                    e.local_entry.is_sym_link || is_server_entry_windows_shortcut))
                continue;

            if (_query_server == In_black_list || _discovery_data.is_in_selective_sync_black_list (path._original)) {
                process_blacklisted (path, e.local_entry, e.db_entry);
                continue;
            }
            if (!check_for_invalid_file_name (path, entries, e)) {
                continue;
            }
            process_file (std.move (path), e.local_entry, e.server_entry, e.db_entry);
        }
        QTimer.single_shot (0, _discovery_data, &DiscoveryPhase.schedule_more_jobs);
    }

    bool ProcessDirectoryJob.handle_excluded (string &path, string &local_name, bool is_directory, bool is_hidden, bool is_symlink) {
        auto excluded = _discovery_data._excludes.traversal_pattern_match (path, is_directory ? ItemTypeDirectory : ItemTypeFile);

        // FIXME : move to ExcludedFiles 's regexp ?
        bool is_invalid_pattern = false;
        if (excluded == CSYNC_NOT_EXCLUDED && !_discovery_data._invalid_filename_rx.pattern ().is_empty ()) {
            if (path.contains (_discovery_data._invalid_filename_rx)) {
                excluded = CSYNC_FILE_EXCLUDE_INVALID_CHAR;
                is_invalid_pattern = true;
            }
        }
        if (excluded == CSYNC_NOT_EXCLUDED && _discovery_data._ignore_hidden_files && is_hidden) {
            excluded = CSYNC_FILE_EXCLUDE_HIDDEN;
        }
        if (excluded == CSYNC_NOT_EXCLUDED && !local_name.is_empty ()
                && _discovery_data._server_blacklisted_files.contains (local_name)) {
            excluded = CSYNC_FILE_EXCLUDE_SERVER_BLACKLISTED;
            is_invalid_pattern = true;
        }

        auto local_codec = QTextCodec.codec_for_locale ();
        if (local_codec.mib_enum () != 106) {
            // If the locale codec is not UTF-8, we must check that the filename from the server can
            // be encoded in the local file system.
            //
            // We cannot use QTextCodec.can_encode () since that can incorrectly return true, see
            // https://bugreports.qt.io/browse/QTBUG-6925.
            QText_encoder encoder (local_codec, QTextCodec.Convert_invalid_to_null);
            if (encoder.from_unicode (path).contains ('\0')) {
                q_c_warning (lc_disco) << "Cannot encode " << path << " to local encoding " << local_codec.name ();
                excluded = CSYNC_FILE_EXCLUDE_CANNOT_ENCODE;
            }
        }

        if (excluded == CSYNC_NOT_EXCLUDED && !is_symlink) {
            return false;
        } else if (excluded == CSYNC_FILE_SILENTLY_EXCLUDED || excluded == CSYNC_FILE_EXCLUDE_AND_REMOVE) {
            emit _discovery_data.silently_excluded (path);
            return true;
        }

        auto item = SyncFileItemPtr.create ();
        item._file = path;
        item._original_file = path;
        item._instruction = CSYNC_INSTRUCTION_IGNORE;

        if (is_symlink) {
            // Symbolic links are ignored.
            item._error_string = tr ("Symbolic links are not supported in syncing.");
        } else {
            switch (excluded) {
            case CSYNC_NOT_EXCLUDED:
            case CSYNC_FILE_SILENTLY_EXCLUDED:
            case CSYNC_FILE_EXCLUDE_AND_REMOVE:
                q_fatal ("These were handled earlier");
            case CSYNC_FILE_EXCLUDE_LIST:
                item._error_string = tr ("File is listed on the ignore list.");
                break;
            case CSYNC_FILE_EXCLUDE_INVALID_CHAR:
                if (item._file.ends_with ('.')) {
                    item._error_string = tr ("File names ending with a period are not supported on this file system.");
                } else {
                    char invalid = '\0';
                    foreach (char x, QByteArray ("\\:?*\"<>|")) {
                        if (item._file.contains (x)) {
                            invalid = x;
                            break;
                        }
                    }
                    if (invalid) {
                        item._error_string = tr ("File names containing the character \"%1\" are not supported on this file system.").arg (QLatin1Char (invalid));
                    } else if (is_invalid_pattern) {
                        item._error_string = tr ("File name contains at least one invalid character");
                    } else {
                        item._error_string = tr ("The file name is a reserved name on this file system.");
                    }
                }
                item._status = SyncFileItem.FileNameInvalid;
                break;
            case CSYNC_FILE_EXCLUDE_TRAILING_SPACE:
                item._error_string = tr ("Filename contains trailing spaces.");
                item._status = SyncFileItem.FileNameInvalid;
                break;
            case CSYNC_FILE_EXCLUDE_LONG_FILENAME:
                item._error_string = tr ("Filename is too long.");
                item._status = SyncFileItem.FileNameInvalid;
                break;
            case CSYNC_FILE_EXCLUDE_HIDDEN:
                item._error_string = tr ("File/Folder is ignored because it's hidden.");
                break;
            case CSYNC_FILE_EXCLUDE_STAT_FAILED:
                item._error_string = tr ("Stat failed.");
                break;
            case CSYNC_FILE_EXCLUDE_CONFLICT:
                item._error_string = tr ("Conflict : Server version downloaded, local copy renamed and not uploaded.");
                item._status = SyncFileItem.Conflict;
            break;
            case CSYNC_FILE_EXCLUDE_CANNOT_ENCODE:
                item._error_string = tr ("The filename cannot be encoded on your file system.");
                break;
            case CSYNC_FILE_EXCLUDE_SERVER_BLACKLISTED:
                item._error_string = tr ("The filename is blacklisted on the server.");
                break;
            }
        }

        _child_ignored = true;
        emit _discovery_data.item_discovered (item);
        return true;
    }

    void ProcessDirectoryJob.process_file (PathTuple path,
        const LocalInfo &local_entry, RemoteInfo &server_entry,
        const SyncJournalFileRecord &db_entry) {
        const char *has_server = server_entry.is_valid () ? "true" : _query_server == Parent_not_changed ? "db" : "false";
        const char *has_local = local_entry.is_valid () ? "true" : _query_local == Parent_not_changed ? "db" : "false";
        q_c_info (lc_disco).nospace () << "Processing " << path._original
                                  << " | valid : " << db_entry.is_valid () << "/" << has_local << "/" << has_server
                                  << " | mtime : " << db_entry._modtime << "/" << local_entry.modtime << "/" << server_entry.modtime
                                  << " | size : " << db_entry._file_size << "/" << local_entry.size << "/" << server_entry.size
                                  << " | etag : " << db_entry._etag << "//" << server_entry.etag
                                  << " | checksum : " << db_entry._checksum_header << "//" << server_entry.checksum_header
                                  << " | perm : " << db_entry._remote_perm << "//" << server_entry.remote_perm
                                  << " | fileid : " << db_entry._file_id << "//" << server_entry.file_id
                                  << " | inode : " << db_entry._inode << "/" << local_entry.inode << "/"
                                  << " | type : " << db_entry._type << "/" << local_entry.type << "/" << (server_entry.is_directory ? ItemTypeDirectory : ItemTypeFile)
                                  << " | e2ee : " << db_entry._is_e2e_encrypted << "/" << server_entry.is_e2e_encrypted
                                  << " | e2ee_mangled_name : " << db_entry.e2e_mangled_name () << "/" << server_entry.e2e_mangled_name;

        if (local_entry.is_valid ()
            && !server_entry.is_valid ()
            && !db_entry.is_valid ()
            && local_entry.modtime < _last_sync_timestamp) {
            q_c_warning (lc_disco) << "File" << path._original << "was modified before the last sync run and is not in the sync journal and server";
        }

        if (_discovery_data.is_renamed (path._original)) {
            q_c_debug (lc_disco) << "Ignoring renamed";
            return; // Ignore this.
        }

        auto item = SyncFileItem.from_sync_journal_file_record (db_entry);
        item._file = path._target;
        item._original_file = path._original;
        item._previous_size = db_entry._file_size;
        item._previous_modtime = db_entry._modtime;
        if (!local_entry.rename_name.is_empty ()) {
            if (_dir_item) {
                item._rename_target = _dir_item._file + "/" + local_entry.rename_name;
            } else {
                item._rename_target = local_entry.rename_name;
            }
        }

        if (db_entry._modtime == local_entry.modtime && db_entry._type == ItemTypeVirtualFile && local_entry.type == ItemTypeFile) {
            item._type = ItemTypeFile;
        }

        // The item shall only have this type if the db request for the virtual download
        // was successful (like : no conflicting remote remove etc). This decision is done
        // either in process_file_analyze_remote_info () or further down here.
        if (item._type == ItemTypeVirtualFileDownload)
            item._type = ItemTypeVirtualFile;
        // Similarly db entries with a dehydration request denote a regular file
        // until the request is processed.
        if (item._type == ItemTypeVirtualFileDehydration)
            item._type = ItemTypeFile;

        // VFS suffixed files on the server are ignored
        if (is_vfs_with_suffix ()) {
            if (has_virtual_file_suffix (server_entry.name)
                || (local_entry.is_virtual_file && !db_entry.is_virtual_file () && has_virtual_file_suffix (db_entry._path))) {
                item._instruction = CSYNC_INSTRUCTION_IGNORE;
                item._error_string = tr ("File has extension reserved for virtual files.");
                _child_ignored = true;
                emit _discovery_data.item_discovered (item);
                return;
            }
        }

        if (server_entry.is_valid ()) {
            process_file_analyze_remote_info (item, path, local_entry, server_entry, db_entry);
            return;
        }

        // Downloading a virtual file is like a server action and can happen even if
        // server-side nothing has changed
        // NOTE : Normally setting the Virtual_file_download flag means that local and
        // remote will be rediscovered. This is just a fallback for a similar check
        // in process_file_analyze_remote_info ().
        if (_query_server == Parent_not_changed
            && db_entry.is_valid ()
            && (db_entry._type == ItemTypeVirtualFileDownload
                || local_entry.type == ItemTypeVirtualFileDownload)
            && (local_entry.is_valid () || _query_local == Parent_not_changed)) {
            item._direction = SyncFileItem.Down;
            item._instruction = CSYNC_INSTRUCTION_SYNC;
            item._type = ItemTypeVirtualFileDownload;
        }

        process_file_analyze_local_info (item, path, local_entry, server_entry, db_entry, _query_server);
    }

    // Compute the checksum of the given file and assign the result in item._checksum_header
    // Returns true if the checksum was successfully computed
    static bool compute_local_checksum (QByteArray &header, string &path, SyncFileItemPtr &item) {
        auto type = parse_checksum_header_type (header);
        if (!type.is_empty ()) {
            // TODO : compute async?
            QByteArray checksum = ComputeChecksum.compute_now_on_file (path, type);
            if (!checksum.is_empty ()) {
                item._checksum_header = make_checksum_header (type, checksum);
                return true;
            }
        }
        return false;
    }

    void ProcessDirectoryJob.process_file_analyze_remote_info (
        const SyncFileItemPtr &item, PathTuple path, LocalInfo &local_entry,
        const RemoteInfo &server_entry, SyncJournalFileRecord &db_entry) {
        item._checksum_header = server_entry.checksum_header;
        item._file_id = server_entry.file_id;
        item._remote_perm = server_entry.remote_perm;
        item._type = server_entry.is_directory ? ItemTypeDirectory : ItemTypeFile;
        item._etag = server_entry.etag;
        item._direct_download_url = server_entry.direct_download_url;
        item._direct_download_cookies = server_entry.direct_download_cookies;
        item._is_encrypted = server_entry.is_e2e_encrypted;
        item._encrypted_file_name = [=] {
            if (server_entry.e2e_mangled_name.is_empty ()) {
                return string ();
            }

            Q_ASSERT (_discovery_data._remote_folder.starts_with ('/'));
            Q_ASSERT (_discovery_data._remote_folder.ends_with ('/'));

            const auto root_path = _discovery_data._remote_folder.mid (1);
            Q_ASSERT (server_entry.e2e_mangled_name.starts_with (root_path));
            return server_entry.e2e_mangled_name.mid (root_path.length ());
        } ();

        // Check for missing server data {
            QStringList missing_data;
            if (server_entry.size == -1)
                missing_data.append (tr ("size"));
            if (server_entry.remote_perm.is_null ())
                missing_data.append (tr ("permission"));
            if (server_entry.etag.is_empty ())
                missing_data.append ("ETag");
            if (server_entry.file_id.is_empty ())
                missing_data.append (tr ("file id"));
            if (!missing_data.is_empty ()) {
                item._instruction = CSYNC_INSTRUCTION_ERROR;
                _child_ignored = true;
                item._error_string = tr ("Server reported no %1").arg (missing_data.join (QLatin1String (", ")));
                emit _discovery_data.item_discovered (item);
                return;
            }
        }

        // The file is known in the db already
        if (db_entry.is_valid ()) {
            const bool is_db_entry_an_e2Ee_placeholder = db_entry.is_virtual_file () && !db_entry.e2e_mangled_name ().is_empty ();
            Q_ASSERT (!is_db_entry_an_e2Ee_placeholder || server_entry.size >= Constants.e2Ee_tag_size);
            const bool is_virtual_e2Ee_placeholder = is_db_entry_an_e2Ee_placeholder && server_entry.size >= Constants.e2Ee_tag_size;
            const int64 size_on_server = is_virtual_e2Ee_placeholder ? server_entry.size - Constants.e2Ee_tag_size : server_entry.size;
            const bool meta_data_size_needs_update_for_e2Ee_file_placeholder = is_virtual_e2Ee_placeholder && db_entry._file_size == server_entry.size;

            if (server_entry.is_directory != db_entry.is_directory ()) {
                // If the type of the entity changed, it's like NEW, but
                // needs to delete the other entity first.
                item._instruction = CSYNC_INSTRUCTION_TYPE_CHANGE;
                item._direction = SyncFileItem.Down;
                item._modtime = server_entry.modtime;
                item._size = size_on_server;
            } else if ( (db_entry._type == ItemTypeVirtualFileDownload || local_entry.type == ItemTypeVirtualFileDownload)
                && (local_entry.is_valid () || _query_local == Parent_not_changed)) {
                // The above check for the local_entry existing is important. Otherwise it breaks
                // the case where a file is moved and simultaneously tagged for download in the db.
                item._direction = SyncFileItem.Down;
                item._instruction = CSYNC_INSTRUCTION_SYNC;
                item._type = ItemTypeVirtualFileDownload;
            } else if (db_entry._etag != server_entry.etag) {
                item._direction = SyncFileItem.Down;
                item._modtime = server_entry.modtime;
                item._size = size_on_server;
                if (server_entry.is_directory) {
                    ENFORCE (db_entry.is_directory ());
                    item._instruction = CSYNC_INSTRUCTION_UPDATE_METADATA;
                } else if (!local_entry.is_valid () && _query_local != Parent_not_changed) {
                    // Deleted locally, changed on server
                    item._instruction = CSYNC_INSTRUCTION_NEW;
                } else {
                    item._instruction = CSYNC_INSTRUCTION_SYNC;
                }
            } else if (db_entry._modtime <= 0 && server_entry.modtime > 0) {
                item._direction = SyncFileItem.Down;
                item._modtime = server_entry.modtime;
                item._size = size_on_server;
                if (server_entry.is_directory) {
                    ENFORCE (db_entry.is_directory ());
                    item._instruction = CSYNC_INSTRUCTION_UPDATE_METADATA;
                } else if (!local_entry.is_valid () && _query_local != Parent_not_changed) {
                    // Deleted locally, changed on server
                    item._instruction = CSYNC_INSTRUCTION_NEW;
                } else {
                    item._instruction = CSYNC_INSTRUCTION_SYNC;
                }
            } else if (db_entry._remote_perm != server_entry.remote_perm || db_entry._file_id != server_entry.file_id || meta_data_size_needs_update_for_e2Ee_file_placeholder) {
                if (meta_data_size_needs_update_for_e2Ee_file_placeholder) {
                    // we are updating placeholder sizes after migrating from older versions with VFS + E2EE implicit hydration not supported
                    q_c_debug (lc_disco) << "Migrating the E2EE VFS placeholder " << db_entry.path () << " from older version. The old size is " << item._size << ". The new size is " << size_on_server;
                    item._size = size_on_server;
                }
                item._instruction = CSYNC_INSTRUCTION_UPDATE_METADATA;
                item._direction = SyncFileItem.Down;
            } else {
                // if (is virtual mode enabled and folder is encrypted - check if the size is the same as on the server and then - trigger server query
                // to update a placeholder with corrected size (-16 Bytes)
                // or, maybe, add a flag to the database - vfs_e2ee_size_corrected? if it is not set - subtract it from the placeholder's size and re-create/update a placeholder?
                const Query_mode server_query_mode = [this, &db_entry, &server_entry] () {
                    const bool is_vfs_mode_on = _discovery_data && _discovery_data._sync_options._vfs && _discovery_data._sync_options._vfs.mode () != Vfs.Off;
                    if (is_vfs_mode_on && db_entry.is_directory () && db_entry._is_e2e_encrypted) {
                        int64 local_folder_size = 0;
                        const auto list_files_callback = [&local_folder_size] (Occ.SyncJournalFileRecord &record) {
                            if (record.is_file ()) {
                                // add Constants.e2Ee_tag_size so we will know the size of E2EE file on the server
                                local_folder_size += record._file_size + Constants.e2Ee_tag_size;
                            } else if (record.is_virtual_file ()) {
                                // just a virtual file, so, the size must contain Constants.e2Ee_tag_size if it was not corrected already
                                local_folder_size += record._file_size;
                            }
                        };

                        const bool list_files_succeeded = _discovery_data._statedb.list_files_in_path (db_entry.path ().to_utf8 (), list_files_callback);

                        if (list_files_succeeded && local_folder_size != 0 && local_folder_size == server_entry.size_of_folder) {
                            q_c_info (lc_disco) << "Migration of E2EE folder " << db_entry.path () << " from older version to the one, supporting the implicit VFS hydration.";
                            return Normal_query;
                        }
                    }
                    return Parent_not_changed;
                } ();

                process_file_analyze_local_info (item, path, local_entry, server_entry, db_entry, server_query_mode);
                return;
            }

            process_file_analyze_local_info (item, path, local_entry, server_entry, db_entry, _query_server);
            return;
        }

        // Unknown in db : new file on the server
        Q_ASSERT (!db_entry.is_valid ());

        item._instruction = CSYNC_INSTRUCTION_NEW;
        item._direction = SyncFileItem.Down;
        item._modtime = server_entry.modtime;
        item._size = server_entry.size;

        auto post_process_server_new = [=] () mutable {
            if (item.is_directory ()) {
                _pending_async_jobs++;
                _discovery_data.check_selective_sync_new_folder (path._server, server_entry.remote_perm,
                    [=] (bool result) {
                        --_pending_async_jobs;
                        if (!result) {
                            process_file_analyze_local_info (item, path, local_entry, server_entry, db_entry, _query_server);
                        }
                        QTimer.single_shot (0, _discovery_data, &DiscoveryPhase.schedule_more_jobs);
                    });
                return;
            }
            // Turn new remote files into virtual files if the option is enabled.
            auto &opts = _discovery_data._sync_options;
            if (!local_entry.is_valid ()
                && item._type == ItemTypeFile
                && opts._vfs.mode () != Vfs.Off
                && _pin_state != PinState.AlwaysLocal
                && !FileSystem.is_exclude_file (item._file)) {
                item._type = ItemTypeVirtualFile;
                if (is_vfs_with_suffix ())
                    add_virtual_file_suffix (path._original);
            }

            if (opts._vfs.mode () != Vfs.Off && !item._encrypted_file_name.is_empty ()) {
                // We are syncing a file for the first time (local entry is invalid) and it is encrypted file that will be virtual once synced
                // to avoid having error of "file has changed during sync" when trying to hydrate it excplicitly - we must remove Constants.e2Ee_tag_size bytes from the end
                // as explicit hydration does not care if these bytes are present in the placeholder or not, but, the size must not change in the middle of the sync
                // this way it works for both implicit and explicit hydration by making a placeholder size that does not includes encryption tag Constants.e2Ee_tag_size bytes
                // another scenario - we are syncing a file which is on disk but not in the database (database was removed or file was not written there yet)
                item._size = server_entry.size - Constants.e2Ee_tag_size;
            }
            process_file_analyze_local_info (item, path, local_entry, server_entry, db_entry, _query_server);
        };

        // Potential NEW/NEW conflict is handled in Analyze_local
        if (local_entry.is_valid ()) {
            post_process_server_new ();
            return;
        }

        // Not in db or locally : either new or a rename
        Q_ASSERT (!db_entry.is_valid () && !local_entry.is_valid ());

        // Check for renames (if there is a file with the same file id)
        bool done = false;
        bool async = false;
        // This function will be executed for every candidate
        auto rename_candidate_processing = [&] (Occ.SyncJournalFileRecord &base) {
            if (done)
                return;
            if (!base.is_valid ())
                return;

            // Remote rename of a virtual file we have locally scheduled for download.
            if (base._type == ItemTypeVirtualFileDownload) {
                // We just consider this NEW but mark it for download.
                item._type = ItemTypeVirtualFileDownload;
                done = true;
                return;
            }

            // Remote rename targets a file that shall be locally dehydrated.
            if (base._type == ItemTypeVirtualFileDehydration) {
                // Don't worry about the rename, just consider it DELETE + NEW (virtual)
                done = true;
                return;
            }

            // Some things prohibit rename detection entirely.
            // Since we don't do the same checks again in reconcile, we can't
            // just skip the candidate, but have to give up completely.
            if (base.is_directory () != item.is_directory ()) {
                q_c_info (lc_disco, "file types different, not a rename");
                done = true;
                return;
            }
            if (!server_entry.is_directory && base._etag != server_entry.etag) {
                // File with different etag, don't do a rename, but download the file again
                q_c_info (lc_disco, "file etag different, not a rename");
                done = true;
                return;
            }

            // Now we know there is a sane rename candidate.
            string original_path = base.path ();

            if (_discovery_data.is_renamed (original_path)) {
                q_c_info (lc_disco, "folder already has a rename entry, skipping");
                return;
            }

            // A remote rename can also mean Encryption Mangled Name.
            // if we find one of those in the database, we ignore it.
            if (!base._e2e_mangled_name.is_empty ()) {
                q_c_warning (lc_disco, "Encrypted file can not rename");
                done = true;
                return;
            }

            string original_path_adjusted = _discovery_data.adjust_renamed_path (original_path, SyncFileItem.Up);

            if (!base.is_directory ()) {
                csync_file_stat_t buf;
                if (csync_vio_local_stat (_discovery_data._local_dir + original_path_adjusted, &buf)) {
                    q_c_info (lc_disco) << "Local file does not exist anymore." << original_path_adjusted;
                    return;
                }
                // NOTE : This prohibits some VFS renames from being detected since
                // suffix-file size is different from the db size. That's ok, they'll DELETE+NEW.
                if (buf.modtime != base._modtime || buf.size != base._file_size || buf.type == ItemTypeDirectory) {
                    q_c_info (lc_disco) << "File has changed locally, not a rename." << original_path;
                    return;
                }
            } else {
                if (!QFileInfo (_discovery_data._local_dir + original_path_adjusted).is_dir ()) {
                    q_c_info (lc_disco) << "Local directory does not exist anymore." << original_path_adjusted;
                    return;
                }
            }

            // Renames of virtuals are possible
            if (base.is_virtual_file ()) {
                item._type = ItemTypeVirtualFile;
            }

            bool was_deleted_on_server = _discovery_data.find_and_cancel_deleted_job (original_path).first;

            auto post_process_rename = [this, item, base, original_path] (PathTuple &path) {
                auto adjusted_original_path = _discovery_data.adjust_renamed_path (original_path, SyncFileItem.Up);
                _discovery_data._renamed_items_remote.insert (original_path, path._target);
                item._modtime = base._modtime;
                item._inode = base._inode;
                item._instruction = CSYNC_INSTRUCTION_RENAME;
                item._direction = SyncFileItem.Down;
                item._rename_target = path._target;
                item._file = adjusted_original_path;
                item._original_file = original_path;
                path._original = original_path;
                path._local = adjusted_original_path;
                q_c_info (lc_disco) << "Rename detected (down) " << item._file << " . " << item._rename_target;
            };

            if (was_deleted_on_server) {
                post_process_rename (path);
                done = true;
            } else {
                // we need to make a request to the server to know that the original file is deleted on the server
                _pending_async_jobs++;
                auto job = new RequestEtagJob (_discovery_data._account, _discovery_data._remote_folder + original_path, this);
                connect (job, &RequestEtagJob.finished_with_result, this, [=] (HttpResult<QByteArray> &etag) mutable {
                    _pending_async_jobs--;
                    QTimer.single_shot (0, _discovery_data, &DiscoveryPhase.schedule_more_jobs);
                    if (etag || etag.error ().code != 404 ||
                        // Somehow another item claimed this original path, consider as if it existed
                        _discovery_data.is_renamed (original_path)) {
                        // If the file exist or if there is another error, consider it is a new file.
                        post_process_server_new ();
                        return;
                    }

                    // The file do not exist, it is a rename

                    // In case the deleted item was discovered in parallel
                    _discovery_data.find_and_cancel_deleted_job (original_path);

                    post_process_rename (path);
                    process_file_finalize (item, path, item.is_directory (), item._instruction == CSYNC_INSTRUCTION_RENAME ? Normal_query : Parent_dont_exist, _query_server);
                });
                job.start ();
                done = true; // Ideally, if the origin still exist on the server, we should continue searching...  but that'd be difficult
                async = true;
            }
        };
        if (!_discovery_data._statedb.get_file_records_by_file_id (server_entry.file_id, rename_candidate_processing)) {
            db_error ();
            return;
        }
        if (async) {
            return; // We went async
        }

        if (item._instruction == CSYNC_INSTRUCTION_NEW) {
            post_process_server_new ();
            return;
        }
        process_file_analyze_local_info (item, path, local_entry, server_entry, db_entry, _query_server);
    }

    void ProcessDirectoryJob.process_file_analyze_local_info (
        const SyncFileItemPtr &item, PathTuple path, LocalInfo &local_entry,
        const RemoteInfo &server_entry, SyncJournalFileRecord &db_entry, Query_mode recurse_query_server) {
        bool no_server_entry = (_query_server != Parent_not_changed && !server_entry.is_valid ())
            || (_query_server == Parent_not_changed && !db_entry.is_valid ());

        if (no_server_entry)
            recurse_query_server = Parent_dont_exist;

        bool server_modified = item._instruction == CSYNC_INSTRUCTION_NEW || item._instruction == CSYNC_INSTRUCTION_SYNC
            || item._instruction == CSYNC_INSTRUCTION_RENAME || item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE;

        // Decay server modifications to UPDATE_METADATA if the local virtual exists
        bool has_local_virtual = local_entry.is_virtual_file || (_query_local == Parent_not_changed && db_entry.is_virtual_file ());
        bool virtual_file_download = item._type == ItemTypeVirtualFileDownload;
        if (server_modified && !virtual_file_download && has_local_virtual) {
            item._instruction = CSYNC_INSTRUCTION_UPDATE_METADATA;
            server_modified = false;
            item._type = ItemTypeVirtualFile;
        }

        if (db_entry.is_virtual_file () && (!local_entry.is_valid () || local_entry.is_virtual_file) && !virtual_file_download) {
            item._type = ItemTypeVirtualFile;
        }

        _child_modified |= server_modified;

        auto finalize = [&] {
            bool recurse = item.is_directory () || local_entry.is_directory || server_entry.is_directory;
            // Even if we have a local directory : If the remote is a file that's propagated as a
            // conflict we don't need to recurse into it. (local c1.owncloud, c1/ ; remote : c1)
            if (item._instruction == CSYNC_INSTRUCTION_CONFLICT && !item.is_directory ())
                recurse = false;
            if (_query_local != Normal_query && _query_server != Normal_query)
                recurse = false;

            auto recurse_query_local = _query_local == Parent_not_changed ? Parent_not_changed : local_entry.is_directory || item._instruction == CSYNC_INSTRUCTION_RENAME ? Normal_query : Parent_dont_exist;
            process_file_finalize (item, path, recurse, recurse_query_local, recurse_query_server);
        };

        if (!local_entry.is_valid ()) {
            if (_query_local == Parent_not_changed && db_entry.is_valid ()) {
                // Not modified locally (Parent_not_changed)
                if (no_server_entry) {
                    // not on the server : Removed on the server, delete locally
                    q_c_info (lc_disco) << "File" << item._file << "is not anymore on server. Going to delete it locally.";
                    item._instruction = CSYNC_INSTRUCTION_REMOVE;
                    item._direction = SyncFileItem.Down;
                } else if (db_entry._type == ItemTypeVirtualFileDehydration) {
                    // dehydration requested
                    item._direction = SyncFileItem.Down;
                    item._instruction = CSYNC_INSTRUCTION_SYNC;
                    item._type = ItemTypeVirtualFileDehydration;
                }
            } else if (no_server_entry) {
                // Not locally, not on the server. The entry is stale!
                q_c_info (lc_disco) << "Stale DB entry";
                _discovery_data._statedb.delete_file_record (path._original, true);
                return;
            } else if (db_entry._type == ItemTypeVirtualFile && is_vfs_with_suffix ()) {
                // If the virtual file is removed, recreate it.
                // This is a precaution since the suffix files don't look like the real ones
                // and we don't want users to accidentally delete server data because they
                // might not expect that deleting the placeholder will have a remote effect.
                item._instruction = CSYNC_INSTRUCTION_NEW;
                item._direction = SyncFileItem.Down;
                item._type = ItemTypeVirtualFile;
            } else if (!server_modified) {
                // Removed locally : also remove on the server.
                if (!db_entry._server_has_ignored_files) {
                    q_c_info (lc_disco) << "File" << item._file << "was deleted locally. Going to delete it on the server.";
                    item._instruction = CSYNC_INSTRUCTION_REMOVE;
                    item._direction = SyncFileItem.Up;
                }
            }

            finalize ();
            return;
        }

        Q_ASSERT (local_entry.is_valid ());

        item._inode = local_entry.inode;

        if (db_entry.is_valid ()) {
            bool type_change = local_entry.is_directory != db_entry.is_directory ();
            if (!type_change && local_entry.is_virtual_file) {
                if (no_server_entry) {
                    item._instruction = CSYNC_INSTRUCTION_REMOVE;
                    item._direction = SyncFileItem.Down;
                } else if (!db_entry.is_virtual_file () && is_vfs_with_suffix ()) {
                    // If we find what looks to be a spurious "abc.owncloud" the base file "abc"
                    // might have been renamed to that. Make sure that the base file is not
                    // deleted from the server.
                    if (db_entry._modtime == local_entry.modtime && db_entry._file_size == local_entry.size) {
                        q_c_info (lc_disco) << "Base file was renamed to virtual file:" << item._file;
                        item._direction = SyncFileItem.Down;
                        item._instruction = CSYNC_INSTRUCTION_SYNC;
                        item._type = ItemTypeVirtualFileDehydration;
                        add_virtual_file_suffix (item._file);
                        item._rename_target = item._file;
                    } else {
                        q_c_info (lc_disco) << "Virtual file with non-virtual db entry, ignoring:" << item._file;
                        item._instruction = CSYNC_INSTRUCTION_IGNORE;
                    }
                }
            } else if (!type_change && ( (db_entry._modtime == local_entry.modtime && db_entry._file_size == local_entry.size) || local_entry.is_directory)) {
                // Local file unchanged.
                if (no_server_entry) {
                    q_c_info (lc_disco) << "File" << item._file << "is not anymore on server. Going to delete it locally.";
                    item._instruction = CSYNC_INSTRUCTION_REMOVE;
                    item._direction = SyncFileItem.Down;
                } else if (db_entry._type == ItemTypeVirtualFileDehydration || local_entry.type == ItemTypeVirtualFileDehydration) {
                    item._direction = SyncFileItem.Down;
                    item._instruction = CSYNC_INSTRUCTION_SYNC;
                    item._type = ItemTypeVirtualFileDehydration;
                } else if (!server_modified
                    && (db_entry._inode != local_entry.inode
                        || _discovery_data._sync_options._vfs.needs_metadata_update (*item))) {
                    item._instruction = CSYNC_INSTRUCTION_UPDATE_METADATA;
                    item._direction = SyncFileItem.Down;
                }
            } else if (!type_change && is_vfs_with_suffix ()
                && db_entry.is_virtual_file () && !local_entry.is_virtual_file
                && db_entry._inode == local_entry.inode
                && db_entry._modtime == local_entry.modtime
                && local_entry.size == 1) {
                // A suffix vfs file can be downloaded by renaming it to remove the suffix.
                // This check leaks some details of Vfs_suffix, particularly the size of placeholders.
                item._direction = SyncFileItem.Down;
                if (no_server_entry) {
                    item._instruction = CSYNC_INSTRUCTION_REMOVE;
                    item._type = ItemTypeFile;
                } else {
                    item._instruction = CSYNC_INSTRUCTION_SYNC;
                    item._type = ItemTypeVirtualFileDownload;
                    item._previous_size = 1;
                }
            } else if (server_modified
                || (is_vfs_with_suffix () && db_entry.is_virtual_file ())) {
                // There's a local change and a server change : Conflict!
                // Alternatively, this might be a suffix-file that's virtual in the db but
                // not locally. These also become conflicts. For in-place placeholders that's
                // not necessary : they could be replaced by real files and should then trigger
                // a regular SYNC upwards when there's no server change.
                process_file_conflict (item, path, local_entry, server_entry, db_entry);
            } else if (type_change) {
                item._instruction = CSYNC_INSTRUCTION_TYPE_CHANGE;
                item._direction = SyncFileItem.Up;
                item._checksum_header.clear ();
                item._size = local_entry.size;
                item._modtime = local_entry.modtime;
                item._type = local_entry.is_directory ? ItemTypeDirectory : ItemTypeFile;
                _child_modified = true;
            } else if (db_entry._modtime > 0 && local_entry.modtime <= 0) {
                item._instruction = CSYNC_INSTRUCTION_SYNC;
                item._direction = SyncFileItem.Down;
                item._size = local_entry.size > 0 ? local_entry.size : db_entry._file_size;
                item._modtime = db_entry._modtime;
                item._previous_modtime = db_entry._modtime;
                item._type = local_entry.is_directory ? ItemTypeDirectory : ItemTypeFile;
                _child_modified = true;
            } else {
                // Local file was changed
                item._instruction = CSYNC_INSTRUCTION_SYNC;
                if (no_server_entry) {
                    // Special case! deleted on server, modified on client, the instruction is then NEW
                    item._instruction = CSYNC_INSTRUCTION_NEW;
                }
                item._direction = SyncFileItem.Up;
                item._checksum_header.clear ();
                item._size = local_entry.size;
                item._modtime = local_entry.modtime;
                _child_modified = true;

                // Checksum comparison at this stage is only enabled for .eml files,
                // check #4754 #4755
                bool is_eml_file = path._original.ends_with (QLatin1String (".eml"), Qt.CaseInsensitive);
                if (is_eml_file && db_entry._file_size == local_entry.size && !db_entry._checksum_header.is_empty ()) {
                    if (compute_local_checksum (db_entry._checksum_header, _discovery_data._local_dir + path._local, item)
                            && item._checksum_header == db_entry._checksum_header) {
                        q_c_info (lc_disco) << "NOTE : Checksums are identical, file did not actually change : " << path._local;
                        item._instruction = CSYNC_INSTRUCTION_UPDATE_METADATA;
                    }
                }
            }

            finalize ();
            return;
        }

        Q_ASSERT (!db_entry.is_valid ());

        if (local_entry.is_virtual_file && !no_server_entry) {
            // Somehow there is a missing DB entry while the virtual file already exists.
            // The instruction should already be set correctly.
            ASSERT (item._instruction == CSYNC_INSTRUCTION_UPDATE_METADATA);
            ASSERT (item._type == ItemTypeVirtualFile);
            finalize ();
            return;
        } else if (server_modified) {
            process_file_conflict (item, path, local_entry, server_entry, db_entry);
            finalize ();
            return;
        }

        // New local file or rename
        item._instruction = CSYNC_INSTRUCTION_NEW;
        item._direction = SyncFileItem.Up;
        item._checksum_header.clear ();
        item._size = local_entry.size;
        item._modtime = local_entry.modtime;
        item._type = local_entry.is_directory ? ItemTypeDirectory : local_entry.is_virtual_file ? ItemTypeVirtualFile : ItemTypeFile;
        _child_modified = true;

        auto post_process_local_new = [item, local_entry, path, this] () {
            // TODO : We may want to execute the same logic for non-VFS mode, as, moving/renaming the same folder by 2 or more clients at the same time is not possible in Web UI.
            // Keeping it like this (for VFS files and folders only) just to fix a user issue.

            if (! (_discovery_data && _discovery_data._sync_options._vfs && _discovery_data._sync_options._vfs.mode () != Vfs.Off)) {
                // for VFS files and folders only
                return;
            }

            if (!local_entry.is_virtual_file && !local_entry.is_directory) {
                return;
            }

            if (local_entry.is_directory && _discovery_data._sync_options._vfs.mode () != Vfs.WindowsCfApi) {
                // for VFS folders on Windows only
                return;
            }

            Q_ASSERT (item._instruction == CSYNC_INSTRUCTION_NEW);
            if (item._instruction != CSYNC_INSTRUCTION_NEW) {
                q_c_warning (lc_disco) << "Trying to wipe a virtual item" << path._local << " with item._instruction" << item._instruction;
                return;
            }

            // must be a dehydrated placeholder
            const bool is_file_place_holder = !local_entry.is_directory && _discovery_data._sync_options._vfs.is_dehydrated_placeholder (_discovery_data._local_dir + path._local);

            // either correct availability, or a result with error if the folder is new or otherwise has no availability set yet
            const auto folder_place_holder_availability = local_entry.is_directory ? _discovery_data._sync_options._vfs.availability (path._local) : Vfs.AvailabilityResult (Vfs.AvailabilityError.NoSuchItem);

            const auto folder_pin_state = local_entry.is_directory ? _discovery_data._sync_options._vfs.pin_state (path._local) : Optional<Pin_state_enums.PinState> (PinState.Unspecified);

            if (!is_file_place_holder && !folder_place_holder_availability.is_valid () && !folder_pin_state.is_valid ()) {
                // not a file placeholder and not a synced folder placeholder (new local folder)
                return;
            }

            const auto is_folder_pin_state_online_only = (folder_pin_state.is_valid () && *folder_pin_state == PinState.OnlineOnly);

            const auto isfolder_place_holder_availability_online_only = (folder_place_holder_availability.is_valid () && *folder_place_holder_availability == VfsItemAvailability.OnlineOnly);

            // a folder is considered online-only if : no files are hydrated, or, if it's an empty folder
            const auto is_online_only_folder = isfolder_place_holder_availability_online_only || (!folder_place_holder_availability && is_folder_pin_state_online_only);

            if (!is_file_place_holder && !is_online_only_folder) {
                if (local_entry.is_directory && folder_place_holder_availability.is_valid () && !is_online_only_folder) {
                    // a VFS folder but is not online0only (has some files hydrated)
                    q_c_info (lc_disco) << "Virtual directory without db entry for" << path._local << "but it contains hydrated file (s), so let's keep it and reupload.";
                    emit _discovery_data.add_error_to_gui (SyncFileItem.SoftError, tr ("Conflict when uploading some files to a folder. Those, conflicted, are going to get cleared!"), path._local);
                    return;
                }
                q_c_warning (lc_disco) << "Virtual file without db entry for" << path._local
                                   << "but looks odd, keeping";
                item._instruction = CSYNC_INSTRUCTION_IGNORE;

                return;
            }

            if (is_online_only_folder) {
                // if we're wiping a folder, we will only get this function called once and will wipe a folder along with it's files and also display one error in GUI
                q_c_info (lc_disco) << "Wiping virtual folder without db entry for" << path._local;
                if (isfolder_place_holder_availability_online_only && folder_place_holder_availability.is_valid ()) {
                    q_c_info (lc_disco) << "*folder_place_holder_availability:" << *folder_place_holder_availability;
                }
                if (is_folder_pin_state_online_only && folder_pin_state.is_valid ()) {
                    q_c_info (lc_disco) << "*folder_pin_state:" << *folder_pin_state;
                }
                emit _discovery_data.add_error_to_gui (SyncFileItem.SoftError, tr ("Conflict when uploading a folder. It's going to get cleared!"), path._local);
            } else {
                q_c_info (lc_disco) << "Wiping virtual file without db entry for" << path._local;
                emit _discovery_data.add_error_to_gui (SyncFileItem.SoftError, tr ("Conflict when uploading a file. It's going to get removed!"), path._local);
            }
            item._instruction = CSYNC_INSTRUCTION_REMOVE;
            item._direction = SyncFileItem.Down;
            // this flag needs to be unset, otherwise a folder would get marked as new in the process_sub_jobs
            _child_modified = false;
        };

        // Check if it is a move
        Occ.SyncJournalFileRecord base;
        if (!_discovery_data._statedb.get_file_record_by_inode (local_entry.inode, &base)) {
            db_error ();
            return;
        }
        const auto original_path = base.path ();

        // Function to gradually check conditions for accepting a move-candidate
        auto move_check = [&] () {
            if (!base.is_valid ()) {
                q_c_info (lc_disco) << "Not a move, no item in db with inode" << local_entry.inode;
                return false;
            }

            if (base._is_e2e_encrypted || is_inside_encrypted_tree ()) {
                return false;
            }

            if (base.is_directory () != item.is_directory ()) {
                q_c_info (lc_disco) << "Not a move, types don't match" << base._type << item._type << local_entry.type;
                return false;
            }
            // Directories and virtual files don't need size/mtime equality
            if (!local_entry.is_directory && !base.is_virtual_file ()
                && (base._modtime != local_entry.modtime || base._file_size != local_entry.size)) {
                q_c_info (lc_disco) << "Not a move, mtime or size differs, "
                                << "modtime:" << base._modtime << local_entry.modtime << ", "
                                << "size:" << base._file_size << local_entry.size;
                return false;
            }

            // The old file must have been deleted.
            if (QFile.exists (_discovery_data._local_dir + original_path)
                // Exception : If the rename changes case only (like "foo" . "Foo") the
                // old filename might still point to the same file.
                && ! (Utility.fs_case_preserving ()
                     && original_path.compare (path._local, Qt.CaseInsensitive) == 0
                     && original_path != path._local)) {
                q_c_info (lc_disco) << "Not a move, base file still exists at" << original_path;
                return false;
            }

            // Verify the checksum where possible
            if (!base._checksum_header.is_empty () && item._type == ItemTypeFile && base._type == ItemTypeFile) {
                if (compute_local_checksum (base._checksum_header, _discovery_data._local_dir + path._original, item)) {
                    q_c_info (lc_disco) << "checking checksum of potential rename " << path._original << item._checksum_header << base._checksum_header;
                    if (item._checksum_header != base._checksum_header) {
                        q_c_info (lc_disco) << "Not a move, checksums differ";
                        return false;
                    }
                }
            }

            if (_discovery_data.is_renamed (original_path)) {
                q_c_info (lc_disco) << "Not a move, base path already renamed";
                return false;
            }

            return true;
        };

        // If it's not a move it's just a local-NEW
        if (!move_check ()) {
            if (base._is_e2e_encrypted) {
                // renaming the encrypted folder is done via remove + re-upload hence we need to mark the newly created folder as encrypted
                // base is a record in the SyncJournal database that contains the data about the being-renamed folder with it's old name and encryption information
                item._is_encrypted = true;
            }
            post_process_local_new ();
            finalize ();
            return;
        }

        // Check local permission if we are allowed to put move the file here
        // Technically we should use the permissions from the server, but we'll assume it is the same
        auto move_perms = check_move_permissions (base._remote_perm, original_path, item.is_directory ());
        if (!move_perms.source_ok || !move_perms.destination_ok) {
            q_c_info (lc_disco) << "Move without permission to rename base file, "
                            << "source:" << move_perms.source_ok
                            << ", target:" << move_perms.destination_ok
                            << ", target_new:" << move_perms.destination_new_ok;

            // If we can create the destination, do that.
            // Permission errors on the destination will be handled by check_permissions later.
            post_process_local_new ();
            finalize ();

            // If the destination upload will work, we're fine with the source deletion.
            // If the source deletion can't work, check_permissions will error.
            if (move_perms.destination_new_ok)
                return;

            // Here we know the new location can't be uploaded : must prevent the source delete.
            // Two cases : either the source item was already processed or not.
            auto was_deleted_on_client = _discovery_data.find_and_cancel_deleted_job (original_path);
            if (was_deleted_on_client.first) {
                // More complicated. The REMOVE is canceled. Restore will happen next sync.
                q_c_info (lc_disco) << "Undid remove instruction on source" << original_path;
                _discovery_data._statedb.delete_file_record (original_path, true);
                _discovery_data._statedb.schedule_path_for_remote_discovery (original_path);
                _discovery_data._another_sync_needed = true;
            } else {
                // Signal to future check_permissions () to forbid the REMOVE and set to restore instead
                q_c_info (lc_disco) << "Preventing future remove on source" << original_path;
                _discovery_data._forbidden_deletes[original_path + '/'] = true;
            }
            return;
        }

        auto was_deleted_on_client = _discovery_data.find_and_cancel_deleted_job (original_path);

        auto process_rename = [item, original_path, base, this] (PathTuple &path) {
            auto adjusted_original_path = _discovery_data.adjust_renamed_path (original_path, SyncFileItem.Down);
            _discovery_data._renamed_items_local.insert (original_path, path._target);
            item._rename_target = path._target;
            path._server = adjusted_original_path;
            item._file = path._server;
            path._original = original_path;
            item._original_file = path._original;
            item._modtime = base._modtime;
            item._inode = base._inode;
            item._instruction = CSYNC_INSTRUCTION_RENAME;
            item._direction = SyncFileItem.Up;
            item._file_id = base._file_id;
            item._remote_perm = base._remote_perm;
            item._etag = base._etag;
            item._type = base._type;

            // Discard any download/dehydrate tags on the base file.
            // They could be preserved and honored in a follow-up sync,
            // but it complicates handling a lot and will happen rarely.
            if (item._type == ItemTypeVirtualFileDownload)
                item._type = ItemTypeVirtualFile;
            if (item._type == ItemTypeVirtualFileDehydration)
                item._type = ItemTypeFile;

            q_c_info (lc_disco) << "Rename detected (up) " << item._file << " . " << item._rename_target;
        };
        if (was_deleted_on_client.first) {
            recurse_query_server = was_deleted_on_client.second == base._etag ? Parent_not_changed : Normal_query;
            process_rename (path);
        } else {
            // We must query the server to know if the etag has not changed
            _pending_async_jobs++;
            string server_original_path = _discovery_data._remote_folder + _discovery_data.adjust_renamed_path (original_path, SyncFileItem.Down);
            if (base.is_virtual_file () && is_vfs_with_suffix ())
                chop_virtual_file_suffix (server_original_path);
            auto job = new RequestEtagJob (_discovery_data._account, server_original_path, this);
            connect (job, &RequestEtagJob.finished_with_result, this, [=] (HttpResult<QByteArray> &etag) mutable {
                if (!etag || (etag.get () != base._etag && !item.is_directory ()) || _discovery_data.is_renamed (original_path)) {
                    q_c_info (lc_disco) << "Can't rename because the etag has changed or the directory is gone" << original_path;
                    // Can't be a rename, leave it as a new.
                    post_process_local_new ();
                } else {
                    // In case the deleted item was discovered in parallel
                    _discovery_data.find_and_cancel_deleted_job (original_path);
                    process_rename (path);
                    recurse_query_server = etag.get () == base._etag ? Parent_not_changed : Normal_query;
                }
                process_file_finalize (item, path, item.is_directory (), Normal_query, recurse_query_server);
                _pending_async_jobs--;
                QTimer.single_shot (0, _discovery_data, &DiscoveryPhase.schedule_more_jobs);
            });
            job.start ();
            return;
        }

        finalize ();
    }

    void ProcessDirectoryJob.process_file_conflict (SyncFileItemPtr &item, ProcessDirectoryJob.PathTuple path, LocalInfo &local_entry, RemoteInfo &server_entry, SyncJournalFileRecord &db_entry) {
        item._previous_size = local_entry.size;
        item._previous_modtime = local_entry.modtime;

        if (server_entry.is_directory && local_entry.is_directory) {
            // Folders of the same path are always considered equals
            item._instruction = CSYNC_INSTRUCTION_UPDATE_METADATA;
            return;
        }

        // A conflict with a virtual should lead to virtual file download
        if (db_entry.is_virtual_file () || local_entry.is_virtual_file)
            item._type = ItemTypeVirtualFileDownload;

        // If there's no content hash, use heuristics
        if (server_entry.checksum_header.is_empty ()) {
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
            item._instruction = is_conflict ? CSYNC_INSTRUCTION_CONFLICT : CSYNC_INSTRUCTION_UPDATE_METADATA;
            item._direction = is_conflict ? SyncFileItem.None : SyncFileItem.Down;
            return;
        }

        // Do we have an UploadInfo for this?
        // Maybe the Upload was completed, but the connection was broken just before
        // we recieved the etag (Issue #5106)
        auto up = _discovery_data._statedb.get_upload_info (path._original);
        if (up._valid && up._content_checksum == server_entry.checksum_header) {
            // Solve the conflict into an upload, or nothing
            item._instruction = up._modtime == local_entry.modtime && up._size == local_entry.size
                ? CSYNC_INSTRUCTION_NONE : CSYNC_INSTRUCTION_SYNC;
            item._direction = SyncFileItem.Up;

            // Update the etag and other server metadata in the journal already
            // (We can't use a typical CSYNC_INSTRUCTION_UPDATE_METADATA because
            // we must not store the size/modtime from the file system)
            Occ.SyncJournalFileRecord rec;
            if (_discovery_data._statedb.get_file_record (path._original, &rec)) {
                rec._path = path._original.to_utf8 ();
                rec._etag = server_entry.etag;
                rec._file_id = server_entry.file_id;
                rec._modtime = server_entry.modtime;
                rec._type = item._type;
                rec._file_size = server_entry.size;
                rec._remote_perm = server_entry.remote_perm;
                rec._checksum_header = server_entry.checksum_header;
                _discovery_data._statedb.set_file_record (rec);
            }
            return;
        }

        // Rely on content hash comparisons to optimize away non-conflicts inside the job
        item._instruction = CSYNC_INSTRUCTION_CONFLICT;
        item._direction = SyncFileItem.None;
    }

    void ProcessDirectoryJob.process_file_finalize (
        const SyncFileItemPtr &item, PathTuple path, bool recurse,
        Query_mode recurse_query_local, Query_mode recurse_query_server) {
        // Adjust target path for virtual-suffix files
        if (is_vfs_with_suffix ()) {
            if (item._type == ItemTypeVirtualFile) {
                add_virtual_file_suffix (path._target);
                if (item._instruction == CSYNC_INSTRUCTION_RENAME)
                    add_virtual_file_suffix (item._rename_target);
                else
                    add_virtual_file_suffix (item._file);
            }
            if (item._type == ItemTypeVirtualFileDehydration
                && item._instruction == CSYNC_INSTRUCTION_SYNC) {
                if (item._rename_target.is_empty ()) {
                    item._rename_target = item._file;
                    add_virtual_file_suffix (item._rename_target);
                }
            }
        }

        if (path._original != path._target && (item._instruction == CSYNC_INSTRUCTION_UPDATE_METADATA || item._instruction == CSYNC_INSTRUCTION_NONE)) {
            ASSERT (_dir_item && _dir_item._instruction == CSYNC_INSTRUCTION_RENAME);
            // This is because otherwise subitems are not updated!  (ideally renaming a directory could
            // update the database for all items!  See PropagateDirectory.slot_sub_jobs_finished)
            item._instruction = CSYNC_INSTRUCTION_RENAME;
            item._rename_target = path._target;
            item._direction = _dir_item._direction;
        }

        q_c_info (lc_disco) << "Discovered" << item._file << item._instruction << item._direction << item._type;

        if (item.is_directory () && item._instruction == CSYNC_INSTRUCTION_SYNC)
            item._instruction = CSYNC_INSTRUCTION_UPDATE_METADATA;
        bool removed = item._instruction == CSYNC_INSTRUCTION_REMOVE;
        if (check_permissions (item)) {
            if (item._is_restoration && item.is_directory ())
                recurse = true;
        } else {
            recurse = false;
        }
        if (recurse) {
            auto job = new ProcessDirectoryJob (path, item, recurse_query_local, recurse_query_server,
                _last_sync_timestamp, this);
            job.set_inside_encrypted_tree (is_inside_encrypted_tree () || item._is_encrypted);
            if (removed) {
                job.set_parent (_discovery_data);
                _discovery_data._queued_deleted_directories[path._original] = job;
            } else {
                connect (job, &ProcessDirectoryJob.finished, this, &ProcessDirectoryJob.sub_job_finished);
                _queued_jobs.push_back (job);
            }
        } else {
            if (removed
                // For the purpose of rename deletion, restored deleted placeholder is as if it was deleted
                || (item._type == ItemTypeVirtualFile && item._instruction == CSYNC_INSTRUCTION_NEW)) {
                _discovery_data._deleted_item[path._original] = item;
            }
            emit _discovery_data.item_discovered (item);
        }
    }

    void ProcessDirectoryJob.process_blacklisted (PathTuple &path, Occ.LocalInfo &local_entry,
        const SyncJournalFileRecord &db_entry) {
        if (!local_entry.is_valid ())
            return;

        auto item = SyncFileItem.from_sync_journal_file_record (db_entry);
        item._file = path._target;
        item._original_file = path._original;
        item._inode = local_entry.inode;
        item._is_selective_sync = true;
        if (db_entry.is_valid () && ( (db_entry._modtime == local_entry.modtime && db_entry._file_size == local_entry.size) || (local_entry.is_directory && db_entry.is_directory ()))) {
            item._instruction = CSYNC_INSTRUCTION_REMOVE;
            item._direction = SyncFileItem.Down;
        } else {
            item._instruction = CSYNC_INSTRUCTION_IGNORE;
            item._status = SyncFileItem.FileIgnored;
            item._error_string = tr ("Ignored because of the \"choose what to sync\" blacklist");
            _child_ignored = true;
        }

        q_c_info (lc_disco) << "Discovered (blacklisted) " << item._file << item._instruction << item._direction << item.is_directory ();

        if (item.is_directory () && item._instruction != CSYNC_INSTRUCTION_IGNORE) {
            auto job = new ProcessDirectoryJob (path, item, Normal_query, In_black_list, _last_sync_timestamp, this);
            connect (job, &ProcessDirectoryJob.finished, this, &ProcessDirectoryJob.sub_job_finished);
            _queued_jobs.push_back (job);
        } else {
            emit _discovery_data.item_discovered (item);
        }
    }

    bool ProcessDirectoryJob.check_permissions (Occ.SyncFileItemPtr &item) {
        if (item._direction != SyncFileItem.Up) {
            // Currently we only check server-side permissions
            return true;
        }

        switch (item._instruction) {
        case CSYNC_INSTRUCTION_TYPE_CHANGE:
        case CSYNC_INSTRUCTION_NEW : {
            const auto perms = !_root_permissions.is_null () ? _root_permissions
                                                          : _dir_item ? _dir_item._remote_perm : _root_permissions;
            if (perms.is_null ()) {
                // No permissions set
                return true;
            } else if (item.is_directory () && !perms.has_permission (RemotePermissions.Can_add_sub_directories)) {
                q_c_warning (lc_disco) << "check_for_permission : ERROR" << item._file;
                item._instruction = CSYNC_INSTRUCTION_ERROR;
                item._error_string = tr ("Not allowed because you don't have permission to add subfolders to that folder");
                return false;
            } else if (!item.is_directory () && !perms.has_permission (RemotePermissions.Can_add_file)) {
                q_c_warning (lc_disco) << "check_for_permission : ERROR" << item._file;
                item._instruction = CSYNC_INSTRUCTION_ERROR;
                item._error_string = tr ("Not allowed because you don't have permission to add files in that folder");
                return false;
            }
            break;
        }
        case CSYNC_INSTRUCTION_SYNC : {
            const auto perms = item._remote_perm;
            if (perms.is_null ()) {
                // No permissions set
                return true;
            }
            if (!perms.has_permission (RemotePermissions.Can_write)) {
                item._instruction = CSYNC_INSTRUCTION_CONFLICT;
                item._error_string = tr ("Not allowed to upload this file because it is read-only on the server, restoring");
                item._direction = SyncFileItem.Down;
                item._is_restoration = true;
                q_c_warning (lc_disco) << "check_for_permission : RESTORING" << item._file << item._error_string;
                // Take the things to write to the db from the "other" node (i.e : info from server).
                // Do a lookup into the csync remote tree to get the metadata we need to restore.
                q_swap (item._size, item._previous_size);
                q_swap (item._modtime, item._previous_modtime);
                return false;
            }
            break;
        }
        case CSYNC_INSTRUCTION_REMOVE : {
            string file_slash = item._file + '/';
            auto forbidden_it = _discovery_data._forbidden_deletes.upper_bound (file_slash);
            if (forbidden_it != _discovery_data._forbidden_deletes.begin ())
                forbidden_it -= 1;
            if (forbidden_it != _discovery_data._forbidden_deletes.end ()
                && file_slash.starts_with (forbidden_it.key ())) {
                item._instruction = CSYNC_INSTRUCTION_NEW;
                item._direction = SyncFileItem.Down;
                item._is_restoration = true;
                item._error_string = tr ("Moved to invalid target, restoring");
                q_c_warning (lc_disco) << "check_for_permission : RESTORING" << item._file << item._error_string;
                return true; // restore sub items
            }
            const auto perms = item._remote_perm;
            if (perms.is_null ()) {
                // No permissions set
                return true;
            }
            if (!perms.has_permission (RemotePermissions.Can_delete)) {
                item._instruction = CSYNC_INSTRUCTION_NEW;
                item._direction = SyncFileItem.Down;
                item._is_restoration = true;
                item._error_string = tr ("Not allowed to remove, restoring");
                q_c_warning (lc_disco) << "check_for_permission : RESTORING" << item._file << item._error_string;
                return true; // (we need to recurse to restore sub items)
            }
            break;
        }
        default:
            break;
        }
        return true;
    }

    auto ProcessDirectoryJob.check_move_permissions (RemotePermissions src_perm, string &src_path,
                                                   bool is_directory)
        . Move_permission_result {
        auto dest_perms = !_root_permissions.is_null () ? _root_permissions
                                                    : _dir_item ? _dir_item._remote_perm : _root_permissions;
        auto file_perms = src_perm;
        //true when it is just a rename in the same directory. (not a move)
        bool is_rename = src_path.starts_with (_current_folder._original)
            && src_path.last_index_of ('/') == _current_folder._original.size ();
        // Check if we are allowed to move to the destination.
        bool destination_oK = true;
        bool destination_new_oK = true;
        if (dest_perms.is_null ()) {
        } else if ( (is_directory && !dest_perms.has_permission (RemotePermissions.Can_add_sub_directories)) ||
                  (!is_directory && !dest_perms.has_permission (RemotePermissions.Can_add_file))) {
            destination_new_oK = false;
        }
        if (!is_rename && !destination_new_oK) {
            // no need to check for the destination dir permission for renames
            destination_oK = false;
        }

        // check if we are allowed to move from the source
        bool source_oK = true;
        if (!file_perms.is_null ()
            && ( (is_rename && !file_perms.has_permission (RemotePermissions.Can_rename))
                    || (!is_rename && !file_perms.has_permission (RemotePermissions.Can_move)))) {
            // We are not allowed to move or rename this file
            source_oK = false;
        }
        return Move_permission_result{source_oK, destination_oK, destination_new_oK};
    }

    void ProcessDirectoryJob.sub_job_finished () {
        auto job = qobject_cast<ProcessDirectoryJob> (sender ());
        ASSERT (job);

        _child_ignored |= job._child_ignored;
        _child_modified |= job._child_modified;

        if (job._dir_item)
            emit _discovery_data.item_discovered (job._dir_item);

        int count = _running_jobs.remove_all (job);
        ASSERT (count == 1);
        job.delete_later ();
        QTimer.single_shot (0, _discovery_data, &DiscoveryPhase.schedule_more_jobs);
    }

    int ProcessDirectoryJob.process_sub_jobs (int nb_jobs) {
        if (_queued_jobs.empty () && _running_jobs.empty () && _pending_async_jobs == 0) {
            _pending_async_jobs = -1; // We're finished, we don't want to emit finished again
            if (_dir_item) {
                if (_child_modified && _dir_item._instruction == CSYNC_INSTRUCTION_REMOVE) {
                    // re-create directory that has modified contents
                    _dir_item._instruction = CSYNC_INSTRUCTION_NEW;
                    _dir_item._direction = _dir_item._direction == SyncFileItem.Up ? SyncFileItem.Down : SyncFileItem.Up;
                }
                if (_child_modified && _dir_item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE && !_dir_item.is_directory ()) {
                    // Replacing a directory by a file is a conflict, if the directory had modified children
                    _dir_item._instruction = CSYNC_INSTRUCTION_CONFLICT;
                    if (_dir_item._direction == SyncFileItem.Up) {
                        _dir_item._type = ItemTypeDirectory;
                        _dir_item._direction = SyncFileItem.Down;
                    }
                }
                if (_child_ignored && _dir_item._instruction == CSYNC_INSTRUCTION_REMOVE) {
                    // Do not remove a directory that has ignored files
                    _dir_item._instruction = CSYNC_INSTRUCTION_NONE;
                }
            }
            emit finished ();
        }

        int started = 0;
        foreach (auto *rj, _running_jobs) {
            started += rj.process_sub_jobs (nb_jobs - started);
            if (started >= nb_jobs)
                return started;
        }

        while (started < nb_jobs && !_queued_jobs.empty ()) {
            auto f = _queued_jobs.front ();
            _queued_jobs.pop_front ();
            _running_jobs.push_back (f);
            f.start ();
            started++;
        }
        return started;
    }

    void ProcessDirectoryJob.db_error () {
        _discovery_data.fatal_error (tr ("Error while reading the database"));
    }

    void ProcessDirectoryJob.add_virtual_file_suffix (string ==&str) {
        str.append (_discovery_data._sync_options._vfs.file_suffix ());
    }

    bool ProcessDirectoryJob.has_virtual_file_suffix (string &str) {
        if (!is_vfs_with_suffix ())
            return false;
        return str.ends_with (_discovery_data._sync_options._vfs.file_suffix ());
    }

    void ProcessDirectoryJob.chop_virtual_file_suffix (string &str) {
        if (!is_vfs_with_suffix ())
            return;
        bool has_suffix = has_virtual_file_suffix (str);
        ASSERT (has_suffix);
        if (has_suffix)
            str.chop (_discovery_data._sync_options._vfs.file_suffix ().size ());
    }

    DiscoverySingleDirectoryJob *ProcessDirectoryJob.start_async_server_query () {
        auto server_job = new DiscoverySingleDirectoryJob (_discovery_data._account,
            _discovery_data._remote_folder + _current_folder._server, this);
        if (!_dir_item)
            server_job.set_is_root_path (); // query the fingerprint on the root
        connect (server_job, &DiscoverySingleDirectoryJob.etag, this, &ProcessDirectoryJob.etag);
        _discovery_data._currently_active_jobs++;
        _pending_async_jobs++;
        connect (server_job, &DiscoverySingleDirectoryJob.finished, this, [this, server_job] (auto &results) {
            _discovery_data._currently_active_jobs--;
            _pending_async_jobs--;
            if (results) {
                _server_normal_query_entries = *results;
                _server_query_done = true;
                if (!server_job._data_fingerprint.is_empty () && _discovery_data._data_fingerprint.is_empty ())
                    _discovery_data._data_fingerprint = server_job._data_fingerprint;
                if (_local_query_done)
                    this.process ();
            } else {
                auto code = results.error ().code;
                q_c_warning (lc_disco) << "Server error in directory" << _current_folder._server << code;
                if (_dir_item && code >= 403) {
                    // In case of an HTTP error, we ignore that directory
                    // 403 Forbidden can be sent by the server if the file firewall is active.
                    // A file or directory should be ignored and sync must continue. See #3490
                    // The server usually replies with the custom "503 Storage not available"
                    // if some path is temporarily unavailable. But in some cases a standard 503
                    // is returned too. Thus we can't distinguish the two and will treat any
                    // 503 as request to ignore the folder. See #3113 #2884.
                    // Similarly, the server might also return 404 or 50x in case of bugs. #7199 #7586
                    _dir_item._instruction = CSYNC_INSTRUCTION_IGNORE;
                    _dir_item._error_string = results.error ().message;
                    emit this.finished ();
                } else {
                    // Fatal for the root job since it has no SyncFileItem, or for the network errors
                    emit _discovery_data.fatal_error (tr ("Server replied with an error while reading directory \"%1\" : %2")
                        .arg (_current_folder._server, results.error ().message));
                }
            }
        });
        connect (server_job, &DiscoverySingleDirectoryJob.first_directory_permissions, this,
            [this] (RemotePermissions &perms) {
                _root_permissions = perms;
            });
        server_job.start ();
        return server_job;
    }

    void ProcessDirectoryJob.start_async_local_query () {
        string local_path = _discovery_data._local_dir + _current_folder._local;
        auto local_job = new DiscoverySingleLocalDirectoryJob (_discovery_data._account, local_path, _discovery_data._sync_options._vfs.data ());

        _discovery_data._currently_active_jobs++;
        _pending_async_jobs++;

        connect (local_job, &DiscoverySingleLocalDirectoryJob.item_discovered, _discovery_data, &DiscoveryPhase.item_discovered);

        connect (local_job, &DiscoverySingleLocalDirectoryJob.child_ignored, this, [this] (bool b) {
            _child_ignored = b;
        });

        connect (local_job, &DiscoverySingleLocalDirectoryJob.finished_fatal_error, this, [this] (string &msg) {
            _discovery_data._currently_active_jobs--;
            _pending_async_jobs--;
            if (_server_job)
                _server_job.abort ();

            emit _discovery_data.fatal_error (msg);
        });

        connect (local_job, &DiscoverySingleLocalDirectoryJob.finished_non_fatal_error, this, [this] (string &msg) {
            _discovery_data._currently_active_jobs--;
            _pending_async_jobs--;

            if (_dir_item) {
                _dir_item._instruction = CSYNC_INSTRUCTION_IGNORE;
                _dir_item._error_string = msg;
                emit this.finished ();
            } else {
                // Fatal for the root job since it has no SyncFileItem
                emit _discovery_data.fatal_error (msg);
            }
        });

        connect (local_job, &DiscoverySingleLocalDirectoryJob.finished, this, [this] (auto &results) {
            _discovery_data._currently_active_jobs--;
            _pending_async_jobs--;

            _local_normal_query_entries = results;
            _local_query_done = true;

            if (_server_query_done)
                this.process ();
        });

        QThreadPool *pool = QThreadPool.global_instance ();
        pool.start (local_job); // QThreadPool takes ownership
    }

    bool ProcessDirectoryJob.is_vfs_with_suffix () {
        return _discovery_data._sync_options._vfs.mode () == Vfs.WithSuffix;
    }

    void ProcessDirectoryJob.compute_pin_state (PinState parent_state) {
        _pin_state = parent_state;
        if (_query_local != Parent_dont_exist) {
            if (auto state = _discovery_data._sync_options._vfs.pin_state (_current_folder._local)) // ouch! pin local or original?
                _pin_state = *state;
        }
    }

    void ProcessDirectoryJob.setup_db_pin_state_actions (SyncJournalFileRecord &record) {
        // Only suffix-vfs uses the db for pin states.
        // Other plugins will set local_entry._type according to the file's pin state.
        if (!is_vfs_with_suffix ())
            return;

        auto pin = _discovery_data._statedb.internal_pin_states ().raw_for_path (record._path);
        if (!pin || *pin == PinState.Inherited)
            pin = _pin_state;

        // OnlineOnly hydrated files want to be dehydrated
        if (record._type == ItemTypeFile && *pin == PinState.OnlineOnly)
            record._type = ItemTypeVirtualFileDehydration;

        // AlwaysLocal dehydrated files want to be hydrated
        if (record._type == ItemTypeVirtualFile && *pin == PinState.AlwaysLocal)
            record._type = ItemTypeVirtualFileDownload;
    }

    }
    