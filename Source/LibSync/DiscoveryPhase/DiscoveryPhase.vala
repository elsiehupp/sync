/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <csync_exclude.h>

// #include <QLoggingCategory>
// #include <GLib.Uri>
// #include <GLib.File>
// #include <QFileInfo>
// #include <QTextCodec>
// #include <cstring>
// #include <QDateTime>

// #pragma once

// #include <QElapsedTimer>
// #include <string[]>
// #include <csync.h>
// #include <QMap>
// #include <GLib.Set>
// #include <QMutex>
// #include <QWaitCondition>
// #include <QRunnable>
// #include <deque>


namespace Occ {

enum class LocalDiscoveryStyle {
    FilesystemOnly, //< read all local data from the filesystem
    DatabaseAndFilesystem, //< read from the database, except for listed paths
};


/***********************************************************
Represent all the meta-data about a file in the server
***********************************************************/
struct RemoteInfo {
    /***********************************************************
    FileName of the entry (this does not contains any directory or path, just the plain name
    ***********************************************************/
    string name;
    GLib.ByteArray etag;
    GLib.ByteArray file_id;
    GLib.ByteArray checksum_header;
    Occ.RemotePermissions remote_perm;
    time_t modtime = 0;
    int64_t size = 0;
    int64_t size_of_folder = 0;
    bool is_directory = false;
    bool is_e2e_encrypted = false;
    string e2e_mangled_name;

    bool is_valid () {
        return !name.is_null ();
    }

    string direct_download_url;
    string direct_download_cookies;
};

struct LocalInfo {
    /***********************************************************
    FileName of the entry (this does not contains any directory or path, just the plain name
    ***********************************************************/
    string name;
    string rename_name;
    time_t modtime = 0;
    int64_t size = 0;
    uint64_t inode = 0;
    ItemType type = ItemTypeSkip;
    bool is_directory = false;
    bool is_hidden = false;
    bool is_virtual_file = false;
    bool is_sym_link = false;
    bool is_valid () {
        return !name.is_null ();
    }
};

/***********************************************************
@brief Run list on a local directory and process the results for Discovery

@ingroup libsync
***********************************************************/
class DiscoverySingleLocalDirectoryJob : GLib.Object, public QRunnable {

    public DiscoverySingleLocalDirectoryJob (AccountPointer &account, string local_path, Occ.Vfs vfs, GLib.Object parent = nullptr);

    public void run () override;
signals:
    void on_finished (QVector<LocalInfo> result);
    void finished_fatal_error (string error_string);
    void finished_non_fatal_error (string error_string);

    void item_discovered (SyncFileItemPtr item);
    void child_ignored (bool b);

    private string _local_path;
    private AccountPointer _account;
    private Occ.Vfs* _vfs;

};

/***********************************************************
@brief Run a PROPFIND on a directory and process the results for Discovery

@ingroup libsync
***********************************************************/
class DiscoverySingleDirectoryJob : GLib.Object {

    public DiscoverySingleDirectoryJob (AccountPointer &account, string path, GLib.Object parent = nullptr);
    // Specify that this is the root and we need to check the data-fingerprint
    public void set_is_root_path () {
        _is_root_path = true;
    }
    public void on_start ();


    public void on_abort ();

    // This is not actually a network job, it is just a job
signals:
    void first_directory_permissions (RemotePermissions);
    void etag (GLib.ByteArray , QDateTime &time);
    void finished (HttpResult<QVector<RemoteInfo>> &result);


    private void on_directory_listing_iterated_slot (string , QMap<string, string> &);
    private void on_ls_job_finished_without_error_slot ();
    private void on_ls_job_finished_with_error_slot (QNetworkReply *);
    private void on_fetch_e2e_metadata ();
    private void on_metadata_received (QJsonDocument &json, int status_code);
    private void on_metadata_error (GLib.ByteArray& file_id, int http_return_code);


    private QVector<RemoteInfo> _results;
    private string _sub_path;
    private GLib.ByteArray _first_etag;
    private GLib.ByteArray _file_id;
    private GLib.ByteArray _local_file_id;
    private AccountPointer _account;
    // The first result is for the directory itself and need to be ignored.
    // This flag is true if it was already ignored.
    private bool _ignored_first;
    // Set to true if this is the root path and we need to check the data-fingerprint
    private bool _is_root_path;
    // If this directory is an external storage (The first item has 'M' in its permission)
    private bool _is_external_storage;
    // If this directory is e2ee
    private bool _is_e2e_encrypted;
    // If set, the discovery will finish with an error
    private int64_t _size = 0;
    private string _error;
    private QPointer<LsColJob> _ls_col_job;


    private public GLib.ByteArray _data_fingerprint;
};

class DiscoveryPhase : GLib.Object {

    friend class ProcessDirectoryJob;

    QPointer<ProcessDirectoryJob> _current_root_job;


    /***********************************************************
    Maps the database-path of a deleted item to its SyncFileItem.

    If it turns out the item was renamed after all, the instruction
    can be changed. See find_and_cancel_deleted_job (). Note that
    item_discovered () will already have been emitted for the item.
    ***********************************************************/
    QMap<string, SyncFileItemPtr> _deleted_item;


    /***********************************************************
    Maps the database-path of a deleted folder to its queued job.

    If a folder is deleted and must be recursed into, its job isn't
    executed immediately. Instead it's queued here and only run
    once the rest of the discovery has on_finished and we are certain
    that the folder wasn't just renamed. This avoids running the
    discovery on contents in the old location of renamed folders.

    See find_and_cancel_deleted_job ().
    ***********************************************************/
    QMap<string, ProcessDirectoryJob> _queued_deleted_directories;

    // map source (original path) . destinations (current server or local path)
    QMap<string, string> _renamed_items_remote;
    QMap<string, string> _renamed_items_local;

    // set of paths that should not be removed even though they are removed locally:
    // there was a move to an invalid destination and now the source should be restored
    //
    // This applies recursively to subdirectories.
    // All entries should have a trailing slash (even files), so lookup with
    // lower_bound () is reliable.
    //
    // The value of this map doesn't matter.
    QMap<string, bool> _forbidden_deletes;


    /***********************************************************
    Returns whether the database-path has been renamed locally or on the remote.

    Useful for avoiding processing of items that have already been claimed in
    a rename (would otherwise be discovered as deletions).
    ***********************************************************/
    bool is_renamed (string p) {
        return _renamed_items_local.contains (p) || _renamed_items_remote.contains (p);
    }

    int _currently_active_jobs = 0;

    // both must contain a sorted list
    string[] _selective_sync_block_list;
    string[] _selective_sync_allow_list;

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

    See _deleted_item and _queued_deleted_directories.
    ***********************************************************/
    QPair<bool, GLib.ByteArray> find_and_cancel_deleted_job (string original_path);

    // input
    public string _local_dir; // absolute path to the local directory. ends with '/'
    public string _remote_folder; // remote folder, ends with '/'
    public SyncJournalDb _statedatabase;
    public AccountPointer _account;
    public SyncOptions _sync_options;
    public ExcludedFiles _excludes;
    public QRegularExpression _invalid_filename_rx; // FIXME : maybe move in ExcludedFiles
    public string[] _server_blocklisted_files; // The blocklist from the capabilities
    public bool _ignore_hidden_files = false;
    public std.function<bool (string )> _should_discover_localy;

    public void start_job (ProcessDirectoryJob *);

    public void set_selective_sync_block_list (string[] &list);


    public void set_selective_sync_allow_list (string[] &list);

    // output
    public GLib.ByteArray _data_fingerprint;
    public bool _another_sync_needed = false;

signals:
    void fatal_error (string error_string);
    void item_discovered (SyncFileItemPtr &item);
    void on_finished ();

    // A new folder was discovered and was not synced because of the confirmation feature
    void new_big_folder (string folder, bool is_external);


    /***********************************************************
    For excluded items that don't show up in item_discovered ()

    The path is relative to the sync folder, similar to item._file
    ***********************************************************/
    void silently_excluded (string folder_path);

    void add_error_to_gui (SyncFileItem.Status status, string error_message, string subject);
};

/// Implementation of DiscoveryPhase.adjust_renamed_path
string adjust_renamed_path (QMap<string, string> &renamed_items, string original);

    /* Given a sorted list of paths ending with '/', return whether or not the given path is within one of the paths of the list*/
    static bool find_path_in_list (string[] &list, string path) {
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
        if (_selective_sync_block_list.is_empty ()) {
            // If there is no block list, everything is allowed
            return false;
        }

        // Block if it is in the block list
        if (find_path_in_list (_selective_sync_block_list, path)) {
            return true;
        }

        return false;
    }

    void DiscoveryPhase.check_selective_sync_new_folder (string path, RemotePermissions remote_perm,
        std.function<void (bool)> callback) {
        if (_sync_options._confirm_external_storage && _sync_options._vfs.mode () == Vfs.Off
            && remote_perm.has_permission (RemotePermissions.IsMounted)) {
            // external storage.

            // Note: DiscoverySingleDirectoryJob.on_directory_listing_iterated_slot make sure that only the
            // root of a mounted storage has 'M', all sub entries have 'm'

            // Only allow it if the allow list contains exactly this path (not parents)
            // We want to ask confirmation for external storage even if the parents where selected
            if (_selective_sync_allow_list.contains (path + '/')) {
                return callback (false);
            }

            emit new_big_folder (path, true);
            return callback (true);
        }

        // If this path or the parent is in the allow list, then we do not block this file
        if (find_path_in_list (_selective_sync_allow_list, path)) {
            return callback (false);
        }

        var limit = _sync_options._new_big_folder_size_limit;
        if (limit < 0 || _sync_options._vfs.mode () != Vfs.Off) {
            // no limit, everything is allowed;
            return callback (false);
        }

        // do a PROPFIND to know the size of this folder
        var propfind_job = new PropfindJob (_account, _remote_folder + path, this);
        propfind_job.set_properties (GLib.List<GLib.ByteArray> () << "resourcetype"
                                                       << "http://owncloud.org/ns:size");
        GLib.Object.connect (propfind_job, &PropfindJob.finished_with_error,
            this, [=] {
                return callback (false);
            });
        GLib.Object.connect (propfind_job, &PropfindJob.result, this, [=] (QVariantMap &values) {
            var result = values.value (QLatin1String ("size")).to_long_long ();
            if (result >= limit) {
                // we tell the UI there is a new folder
                emit new_big_folder (path, false);
                return callback (true);
            } else {
                // it is not too big, put it in the allow list (so we will not do more query for the children)
                // and and do not block.
                var p = path;
                if (!p.ends_with ('/'))
                    p += '/';
                _selective_sync_allow_list.insert (
                    std.upper_bound (_selective_sync_allow_list.begin (), _selective_sync_allow_list.end (), p),
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
        return Occ.adjust_renamed_path (d == SyncFileItem.Down ? _renamed_items_remote : _renamed_items_local, original);
    }

    string adjust_renamed_path (QMap<string, string> &renamed_items, string original) {
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
        var it = _deleted_item.find (original_path);
        if (it != _deleted_item.end ()) {
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
                    emit fatal_error (_("Error while canceling delete of %1").arg (original_path));
                }
                (*it)._instruction = CSYNC_INSTRUCTION_NONE;
                result = true;
                old_etag = (*it)._etag;
            }
            _deleted_item.erase (it);
        }
        if (var other_job = _queued_deleted_directories.take (original_path)) {
            old_etag = other_job._dir_item._etag;
            delete other_job;
            result = true;
        }
        return {
            result, old_etag
        };
    }

    void DiscoveryPhase.start_job (ProcessDirectoryJob job) {
        ENFORCE (!_current_root_job);
        connect (job, &ProcessDirectoryJob.on_finished, this, [this, job] {
            ENFORCE (_current_root_job == sender ());
            _current_root_job = nullptr;
            if (job._dir_item)
                emit item_discovered (job._dir_item);
            job.delete_later ();

            // Once the main job has on_finished recurse here to execute the remaining
            // jobs for queued deleted directories.
            if (!_queued_deleted_directories.is_empty ()) {
                var next_job = _queued_deleted_directories.take (_queued_deleted_directories.first_key ());
                start_job (next_job);
            } else {
                emit finished ();
            }
        });
        _current_root_job = job;
        job.on_start ();
    }

    void DiscoveryPhase.set_selective_sync_block_list (string[] &list) {
        _selective_sync_block_list = list;
        std.sort (_selective_sync_block_list.begin (), _selective_sync_block_list.end ());
    }

    void DiscoveryPhase.set_selective_sync_allow_list (string[] &list) {
        _selective_sync_allow_list = list;
        std.sort (_selective_sync_allow_list.begin (), _selective_sync_allow_list.end ());
    }

    void DiscoveryPhase.schedule_more_jobs () {
        var limit = q_max (1, _sync_options._parallel_network_jobs);
        if (_current_root_job && _currently_active_jobs < limit) {
            _current_root_job.process_sub_jobs (limit - _currently_active_jobs);
        }
    }

    DiscoverySingleLocalDirectoryJob.DiscoverySingleLocalDirectoryJob (AccountPointer &account, string local_path, Occ.Vfs vfs, GLib.Object parent)
     : GLib.Object (parent), QRunnable (), _local_path (local_path), _account (account), _vfs (vfs) {
        q_register_meta_type<QVector<LocalInfo> > ("QVector<LocalInfo>");
    }

    // Use as QRunnable
    void DiscoverySingleLocalDirectoryJob.run () {
        string local_path = _local_path;
        if (local_path.ends_with ('/')) // Happens if _current_folder._local.is_empty ()
            local_path.chop (1);

        var dh = csync_vio_local_opendir (local_path);
        if (!dh) {
            q_c_info (lc_discovery) << "Error while opening directory" << (local_path) << errno;
            string error_string = _("Error while opening directory %1").arg (local_path);
            if (errno == EACCES) {
                error_string = _("Directory not accessible on client, permission denied");
                emit finished_non_fatal_error (error_string);
                return;
            } else if (errno == ENOENT) {
                error_string = _("Directory not found : %1").arg (local_path);
            } else if (errno == ENOTDIR) {
                // Not a directory..
                // Just consider it is empty
                return;
            }
            emit finished_fatal_error (error_string);
            return;
        }

        QVector<LocalInfo> results;
        while (true) {
            errno = 0;
            var dirent = csync_vio_local_readdir (dh, _vfs);
            if (!dirent)
                break;
            if (dirent.type == ItemTypeSkip)
                continue;
            LocalInfo i;
            static QTextCodec codec = QTextCodec.codec_for_name ("UTF-8");
            ASSERT (codec);
            QTextCodec.ConverterState state;
            i.name = codec.to_unicode (dirent.path, dirent.path.size (), &state);
            if (state.invalid_chars > 0 || state.remaining_chars > 0) {
                emit child_ignored (true);
                var item = SyncFileItemPtr.create ();
                //item._file = _current_folder._target + i.name;
                // FIXME ^^ do we really need to use _target or is local fine?
                item._file = _local_path + i.name;
                item._instruction = CSYNC_INSTRUCTION_IGNORE;
                item._status = SyncFileItem.NormalError;
                item._error_string = _("Filename encoding is not valid");
                emit item_discovered (item);
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
            emit finished_fatal_error (_("Error while reading directory %1").arg (local_path));
            return;
        }

        errno = 0;
        csync_vio_local_closedir (dh);
        if (errno != 0) {
            GLib.warn (lc_discovery) << "closedir failed for file in " << local_path << " - errno : " << errno;
        }

        emit finished (results);
    }

    DiscoverySingleDirectoryJob.DiscoverySingleDirectoryJob (AccountPointer &account, string path, GLib.Object parent)
        : GLib.Object (parent)
        , _sub_path (path)
        , _account (account)
        , _ignored_first (false)
        , _is_root_path (false)
        , _is_external_storage (false)
        , _is_e2e_encrypted (false) {
    }

    void DiscoverySingleDirectoryJob.on_start () {
        // Start the actual HTTP job
        var ls_col_job = new LsColJob (_account, _sub_path, this);

        GLib.List<GLib.ByteArray> props;
        props << "resourcetype"
              << "getlastmodified"
              << "getcontentlength"
              << "getetag"
              << "http://owncloud.org/ns:size"
              << "http://owncloud.org/ns:id"
              << "http://owncloud.org/ns:fileid"
              << "http://owncloud.org/ns:download_uRL"
              << "http://owncloud.org/ns:d_dC"
              << "http://owncloud.org/ns:permissions"
              << "http://owncloud.org/ns:checksums";
        if (_is_root_path)
            props << "http://owncloud.org/ns:data-fingerprint";
        if (_account.server_version_int () >= Account.make_server_version (10, 0, 0)) {
            // Server older than 10.0 have performances issue if we ask for the share-types on every PROPFIND
            props << "http://owncloud.org/ns:share-types";
        }
        if (_account.capabilities ().client_side_encryption_available ()) {
            props << "http://nextcloud.org/ns:is-encrypted";
        }

        ls_col_job.set_properties (props);

        GLib.Object.connect (ls_col_job, &LsColJob.directory_listing_iterated,
            this, &DiscoverySingleDirectoryJob.on_directory_listing_iterated_slot);
        GLib.Object.connect (ls_col_job, &LsColJob.finished_with_error, this, &DiscoverySingleDirectoryJob.on_ls_job_finished_with_error_slot);
        GLib.Object.connect (ls_col_job, &LsColJob.finished_without_error, this, &DiscoverySingleDirectoryJob.on_ls_job_finished_without_error_slot);
        ls_col_job.on_start ();

        _ls_col_job = ls_col_job;
    }

    void DiscoverySingleDirectoryJob.on_abort () {
        if (_ls_col_job && _ls_col_job.reply ()) {
            _ls_col_job.reply ().on_abort ();
        }
    }

    static void property_map_to_remote_info (QMap<string, string> &map, RemoteInfo &result) {
        for (var it = map.const_begin (); it != map.const_end (); ++it) {
            string property = it.key ();
            string value = it.value ();
            if (property == QLatin1String ("resourcetype")) {
                result.is_directory = value.contains (QLatin1String ("collection"));
            } else if (property == QLatin1String ("getlastmodified")) {
                const var date = QDateTime.from_string (value, Qt.RFC2822Date);
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
                result.file_id = value.to_utf8 ();
            } else if (property == "download_uRL") {
                result.direct_download_url = value;
            } else if (property == "d_dC") {
                result.direct_download_cookies = value;
            } else if (property == "permissions") {
                result.remote_perm = RemotePermissions.from_server_string (value);
            } else if (property == "checksums") {
                result.checksum_header = find_best_checksum (value.to_utf8 ());
            } else if (property == "share-types" && !value.is_empty ()) {
                // Since QMap is sorted, "share-types" is always after "permissions".
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

    void DiscoverySingleDirectoryJob.on_directory_listing_iterated_slot (string file, QMap<string, string> &map) {
        if (!_ignored_first) {
            // The first entry is for the folder itself, we should process it differently.
            _ignored_first = true;
            if (map.contains ("permissions")) {
                var perm = RemotePermissions.from_server_string (map.value ("permissions"));
                emit first_directory_permissions (perm);
                _is_external_storage = perm.has_permission (RemotePermissions.IsMounted);
            }
            if (map.contains ("data-fingerprint")) {
                _data_fingerprint = map.value ("data-fingerprint").to_utf8 ();
                if (_data_fingerprint.is_empty ()) {
                    // Placeholder that means that the server supports the feature even if it did not set one.
                    _data_fingerprint = "[empty]";
                }
            }
            if (map.contains (QStringLiteral ("fileid"))) {
                _local_file_id = map.value (QStringLiteral ("fileid")).to_utf8 ();
            }
            if (map.contains ("id")) {
                _file_id = map.value ("id").to_utf8 ();
            }
            if (map.contains ("is-encrypted") && map.value ("is-encrypted") == QStringLiteral ("1")) {
                _is_e2e_encrypted = true;
                Q_ASSERT (!_file_id.is_empty ());
            }
            if (map.contains ("size")) {
                _size = map.value ("size").to_int ();
            }
        } else {

            RemoteInfo result;
            int slash = file.last_index_of ('/');
            result.name = file.mid (slash + 1);
            result.size = -1;
            property_map_to_remote_info (map, result);
            if (result.is_directory)
                result.size = 0;

            if (_is_external_storage && result.remote_perm.has_permission (RemotePermissions.IsMounted)) {
                // All the entries in a external storage have 'M' in their permission. However, for all
                // purposes in the desktop client, we only need to know about the mount points.
                // So replace the 'M' by a 'm' for every sub entries in an external storage
                result.remote_perm.unset_permission (RemotePermissions.IsMounted);
                result.remote_perm.set_permission (RemotePermissions.IsMountedSub);
            }
            _results.push_back (std.move (result));
        }

        //This works in concerto with the RequestEtagJob and the Folder object to check if the remote folder changed.
        if (map.contains ("getetag")) {
            if (_first_etag.is_empty ()) {
                _first_etag = parse_etag (map.value (QStringLiteral ("getetag")).to_utf8 ()); // for directory itself
            }
        }
    }

    void DiscoverySingleDirectoryJob.on_ls_job_finished_without_error_slot () {
        if (!_ignored_first) {
            // This is a sanity check, if we haven't _ignored_first then it means we never received any on_directory_listing_iterated_slot
            // which means somehow the server XML was bogus
            emit finished (HttpError {
                0, _("Server error : PROPFIND reply is not XML formatted!")
            });
            delete_later ();
            return;
        } else if (!_error.is_empty ()) {
            emit finished (HttpError {
                0, _error
            });
            delete_later ();
            return;
        } else if (_is_e2e_encrypted) {
            emit etag (_first_etag, QDateTime.from_string (string.from_utf8 (_ls_col_job.response_timestamp ()), Qt.RFC2822Date));
            on_fetch_e2e_metadata ();
            return;
        }
        emit etag (_first_etag, QDateTime.from_string (string.from_utf8 (_ls_col_job.response_timestamp ()), Qt.RFC2822Date));
        emit finished (_results);
        delete_later ();
    }

    void DiscoverySingleDirectoryJob.on_ls_job_finished_with_error_slot (QNetworkReply r) {
        string content_type = r.header (QNetworkRequest.ContentTypeHeader).to_string ();
        int http_code = r.attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
        string msg = r.error_string ();
        GLib.warn (lc_discovery) << "LSCOL job error" << r.error_string () << http_code << r.error ();
        if (r.error () == QNetworkReply.NoError
            && !content_type.contains ("application/xml; charset=utf-8")) {
            msg = _("Server error : PROPFIND reply is not XML formatted!");
        }
        emit finished (HttpError {
            http_code, msg
        });
        delete_later ();
    }

    void DiscoverySingleDirectoryJob.on_fetch_e2e_metadata () {
        const var job = new GetMetadataApiJob (_account, _local_file_id);
        connect (job, &GetMetadataApiJob.json_received,
                this, &DiscoverySingleDirectoryJob.on_metadata_received);
        connect (job, &GetMetadataApiJob.error,
                this, &DiscoverySingleDirectoryJob.on_metadata_error);
        job.on_start ();
    }

    void DiscoverySingleDirectoryJob.on_metadata_received (QJsonDocument &json, int status_code) {
        GLib.debug (lc_discovery) << "Metadata received, applying it to the result list";
        Q_ASSERT (_sub_path.starts_with ('/'));

        const var metadata = FolderMetadata (_account, json.to_json (QJsonDocument.Compact), status_code);
        const var encrypted_files = metadata.files ();

        const var find_encrypted_file = [=] (string name) {
            const var it = std.find_if (std.cbegin (encrypted_files), std.cend (encrypted_files), [=] (EncryptedFile &file) {
                return file.encrypted_filename == name;
            });
            if (it == std.cend (encrypted_files)) {
                return Optional<EncryptedFile> ();
            } else {
                return Optional<EncryptedFile> (*it);
            }
        };

        std.transform (std.cbegin (_results), std.cend (_results), std.begin (_results), [=] (RemoteInfo &info) {
            var result = info;
            const var encrypted_file_info = find_encrypted_file (result.name);
            if (encrypted_file_info) {
                result.is_e2e_encrypted = true;
                result.e2e_mangled_name = _sub_path.mid (1) + '/' + result.name;
                result.name = encrypted_file_info.original_filename;
            }
            return result;
        });

        emit finished (_results);
        delete_later ();
    }

    void DiscoverySingleDirectoryJob.on_metadata_error (GLib.ByteArray file_id, int http_return_code) {
        GLib.warn (lc_discovery) << "E2EE Metadata job error. Trying to proceed without it." << file_id << http_return_code;
        emit finished (_results);
        delete_later ();
    }
    }
    