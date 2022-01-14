/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <QCryptographicHash>
// #include <QFile>
// #include <QLoggingCategory>
// #include <QStringList>
// #include <QElapsedTimer>
// #include <QUrl>
// #include <QDir>
// #include <Sqlite3.h>
// #include <cstring>

// SQL expression to check whether path.startswith (prefix + '/')
// Note : '/' + 1 == '0'
const int IS_PREFIX_PATH_OF (prefix, path)
" (" path " > (" prefix "||'/') AND " path " < (" prefix "||'0'))"
const int IS_PREFIX_PATH_OR_EQUAL (prefix, path)
" (" path " == " prefix " OR " IS_PREFIX_PATH_OF (prefix, path) ")"

// #include <GLib.Object>
// #include <QDateTime>
// #include <QHash>
// #include <QMutex>
// #include <QVariant>
// #include <functional>

namespace Occ {

/***********************************************************
@brief Class that handles the sync database

This class is thread safe. All public functions lock the mutex.
@ingroup libsync
***********************************************************/
class SyncJournalDb : GLib.Object {

    public SyncJournalDb (string &db_file_path, GLib.Object *parent = nullptr);
    public ~SyncJournalDb () override;

    /// Create a journal path for a specific configuration
    public static string make_db_name (string &local_path,
        const QUrl &remote_url,
        const string &remote_path,
        const string &user);

    /// Migrate a csync_journal to the new path, if necessary. Returns false on error
    public static bool maybe_migrate_db (string &local_path, string &absolute_journal_path);

    // To verify that the record could be found check with SyncJournalFileRecord.is_valid ()
    public bool get_file_record (string &filename, SyncJournalFileRecord *rec) {
        return get_file_record (filename.to_utf8 (), rec);
    }
    public bool get_file_record (QByteArray &filename, SyncJournalFileRecord *rec);
    public bool get_file_record_by_e2e_mangled_name (string &mangled_name, SyncJournalFileRecord *rec);
    public bool get_file_record_by_inode (uint64 inode, SyncJournalFileRecord *rec);
    public bool get_file_records_by_file_id (QByteArray &file_id, std.function<void (SyncJournalFileRecord &)> &row_callback);
    public bool get_files_below_path (QByteArray &path, std.function<void (SyncJournalFileRecord&)> &row_callback);
    public bool list_files_in_path (QByteArray &path, std.function<void (SyncJournalFileRecord&)> &row_callback);
    public Result<void, string> set_file_record (SyncJournalFileRecord &record);

    public void key_value_store_set (string &key, QVariant value);
    public int64 key_value_store_get_int (string &key, int64 default_value);
    public void key_value_store_delete (string &key);

    public bool delete_file_record (string &filename, bool recursively = false);
    public bool update_file_record_checksum (string &filename,
        const QByteArray &content_checksum,
        const QByteArray &content_checksum_type);
    public bool update_local_metadata (string &filename,
        int64 modtime, int64 size, uint64 inode);

    /// Return value for has_hydrated_or_dehydrated_files ()
    public struct Has_hydrated_dehydrated {
        bool has_hydrated = false;
        bool has_dehydrated = false;
    };

    /***********************************************************
    Returns whether the item or any subitems are dehydrated
    ***********************************************************/
    public Optional<Has_hydrated_dehydrated> has_hydrated_or_dehydrated_files (QByteArray &filename);

    public bool exists ();
    public void wal_checkpoint ();

    public string database_file_path ();

    public static int64 get_pHash (QByteArray &);

    public void set_error_blacklist_entry (SyncJournalErrorBlacklistRecord &item);
    public void wipe_error_blacklist_entry (string &file);
    public void wipe_error_blacklist_category (SyncJournalErrorBlacklistRecord.Category category);
    public int wipe_error_blacklist ();
    public int error_black_list_entry_count ();

    public struct DownloadInfo {
        string _tmpfile;
        QByteArray _etag;
        int _error_count = 0;
        bool _valid = false;
    };
    public struct UploadInfo {
        int _chunk = 0;
        uint _transferid = 0;
        int64 _size = 0;
        int64 _modtime = 0;
        int _error_count = 0;
        bool _valid = false;
        QByteArray _content_checksum;
        /***********************************************************
        Returns true if this entry refers to a chunked upload that can be continued.
        (As opposed to a small file transfer which is stored in the db so we can detect the case
        when the upload succeeded, but the connection was dropped before we got the answer)
        ***********************************************************/
        bool is_chunked () {
            return _transferid != 0;
        }
    };

    public struct Poll_info {
        string _file; // The relative path of a file
        string _url; // the poll url. (This pollinfo is invalid if _url is empty)
        int64 _modtime; // The modtime of the file being uploaded
        int64 _file_size;
    };

    public DownloadInfo get_download_info (string &file);
    public void set_download_info (string &file, DownloadInfo &i);
    public QVector<DownloadInfo> get_and_delete_stale_download_infos (QSet<string> &keep);
    public int download_info_count ();

    public UploadInfo get_upload_info (string &file);
    public void set_upload_info (string &file, UploadInfo &i);
    // Return the list of transfer ids that were removed.
    public QVector<uint> delete_stale_upload_infos (QSet<string> &keep);

    public SyncJournalErrorBlacklistRecord error_blacklist_entry (string &);
    public bool delete_stale_error_blacklist_entries (QSet<string> &keep);

    /// Delete flags table entries that have no metadata correspondent
    public void delete_stale_flags_entries ();

    public void avoid_renames_on_next_sync (string &path) {
        avoid_renames_on_next_sync (path.to_utf8 ());
    }
    public void avoid_renames_on_next_sync (QByteArray &path);
    public void set_poll_info (Poll_info &);

    public QVector<Poll_info> get_poll_infos ();

    public enum Selective_sync_list_type {
        /***********************************************************
        The black list is the list of folders that are unselected in the selective sync dialog.
        For the sync engine, those folders are considered as if they were not there, so the local
        folders will be deleted
        ***********************************************************/
        SelectiveSyncBlackList = 1,
        /***********************************************************
        When a shared folder has a size bigger than a configured size, it is by default not sync'ed
        Unless it is in the white list, in which case the folder is sync'ed and all its children.
        If a folder is both on the black and the white list, the black list wins
        ***********************************************************/
        SelectiveSyncWhiteList = 2,
        /***********************************************************
        List of big sync folders that have not been confirmed by the user yet and that the UI
        should notify about
        ***********************************************************/
        SelectiveSyncUndecidedList = 3
    };
    /***********************************************************
    return the specified list from the database
    ***********************************************************/
    public QStringList get_selective_sync_list (Selective_sync_list_type type, bool *ok);
    /***********************************************************
    Write the selective sync list (remove all other entries of that list
    ***********************************************************/
    public void set_selective_sync_list (Selective_sync_list_type type, QStringList &list);

    /***********************************************************
    Make sure that on the next sync file_name and its parents are discovered from the server.

    That means its metadata and, if it's a directory, its direct contents.

    Specifically, etag
    That causes a metadata difference and a resulting discovery from the remote f
    affected folders.

    Since folders in the selective sync list will not be rediscovered (csync_ftw,
    _csync_detect_update skip them), the _invalid_ marker will stay. And any
    child items in the db will be ignored when reading a remote tree from the database.

    Any set_file_record () call to affected directories before the next sync run will be
    adjusted to retain the invalid etag via _etag_storage_filter.
    ***********************************************************/
    public void schedule_path_for_remote_discovery (string &file_name) {
        schedule_path_for_remote_discovery (file_name.to_utf8 ());
    }
    public void schedule_path_for_remote_discovery (QByteArray &file_name);

    /***********************************************************
    Wipe _etag_storage_filter. Also done implicitly on close ().
    ***********************************************************/
    public void clear_etag_storage_filter ();

    /***********************************************************
    Ensures full remote discovery happens on the next sync.

    Equivalent to calling schedule_path_for_remote_discovery () for all files.
    ***********************************************************/
    public void force_remote_discovery_next_sync ();

    /* Because sqlite transactions are really slow, we encapsulate everything in big transactions
    Commit will actually commit the transaction and create a new one.
    ***********************************************************/
    public void commit (string &context, bool start_trans = true);
    public void commit_if_needed_and_start_new_transaction (string &context);

    /***********************************************************
    Open the db if it isn't already.

    This usually creates some temporary files next to the db file, like
    $dbfile-shm or $dbfile-wal.

    returns true if it could be openend or is currently opened.
    ***********************************************************/
    public bool open ();

    /***********************************************************
    Returns whether the db is currently openend.
    ***********************************************************/
    public bool is_open ();

    /***********************************************************
    Close the database
    ***********************************************************/
    public void close ();

    /***********************************************************
    Returns the checksum type for an id.
    ***********************************************************/
    public QByteArray get_checksum_type (int checksum_type_id);

    /***********************************************************
    The data-fingerprint used to detect backup
    ***********************************************************/
    void set_data_fingerprint (QByteArray &data_fingerprint);
    QByteArray data_fingerprint ();

    // Conflict record functions

    /// Store a new or updated record in the database
    public void set_conflict_record (Conflict_record &record);

    /// Retrieve a conflict record by path of the file with the conflict tag
    public Conflict_record conflict_record (QByteArray &path);

    /// Delete a conflict record by path of the file with the conflict tag
    public void delete_conflict_record (QByteArray &path);

    /// Return all paths of files with a conflict tag in the name and records in the db
    public QByte_array_list conflict_record_paths ();

    /***********************************************************
    Find the base name for a conflict file name, using journal or name pattern

    The path must be sync-folder relative.

    Will return an empty string if it's not even a conflict file by pattern.
    ***********************************************************/
    public QByteArray conflict_file_base_name (QByteArray &conflict_name);

    /***********************************************************
    Delete any file entry. This will force the next sync to re-sync everything as if it was new,
    restoring everyfile on every remote. If a file is there both on the client and server side,
    it will be a conflict that will be automatically resolved if the file is the same.
    ***********************************************************/
    public void clear_file_table ();

    /***********************************************************
    Set the 'Item_type_virtual_file_download' to all the files that have the Item_type_virtual_file flag
    within the directory specified path path

    The path "" marks everything.
    ***********************************************************/
    public void mark_virtual_file_for_download_recursively (QByteArray &path);

    /***********************************************************
    Grouping for all functions relating to pin states,

    Use internal_pin_states () to get at them.
    ***********************************************************/
    public struct OCSYNC_EXPORT PinStateInterface {
        PinStateInterface (PinStateInterface &) = delete;
        PinStateInterface (PinStateInterface &&) = delete;

        /***********************************************************
        Gets the PinState for the path without considering parents.

        If a path has no explicit PinState "Inherited" is returned.

        The path should not have a trailing slash.
        It's valid to use the root path "".

        Returns none on db error.
        ***********************************************************/
        Optional<PinState> raw_for_path (QByteArray &path);

        /***********************************************************
        Gets the PinState for the path after inheriting from parents.

        If the exact path has no entry or has an Inherited state,
        the state of the closest parent path is returned.

        The path should not have a trailing slash.
        It's valid to use the root path "".

        Never returns PinState.Inherited. If the root is "Inherited"
        or there's an error, "AlwaysLocal" is returned.

        Returns none on db error.
        ***********************************************************/
        Optional<PinState> effective_for_path (QByteArray &path);

        /***********************************************************
        Like effective_for_path () but also considers subitem pin states.

        If the path's pin state and all subitem's pin states are identical
        then that pin state will be returned.

        If some subitem's pin state is different from the path's state,
        PinState.Inherited will be returned. Inherited isn't returned in
        any other cases.

        It's valid to use the root path "".
        Returns none on db error.
        ***********************************************************/
        Optional<PinState> effective_for_path_recursive (QByteArray &path);

        /***********************************************************
        Sets a path's pin state.

        The path should not have a trailing slash.
        It's valid to use the root path "".
        ***********************************************************/
        void set_for_path (QByteArray &path, PinState state);

        /***********************************************************
        Wipes pin states for a path and below.

        Used when the user asks a subtree to have a particular pin state.
        The path should not have a trailing slash.
        The path "" wipes every entry.
        ***********************************************************/
        void wipe_for_path_and_below (QByteArray &path);

        /***********************************************************
        Returns list of all paths with their pin state as in the db.
        Returns nothing on db error.
        Note that this will have an entry for "".
        ***********************************************************/
        Optional<QVector<QPair<QByteArray, PinState>>> raw_list ();

        SyncJournalDb *_db;
    };
    public friend struct PinStateInterface;

    /***********************************************************
    Access to PinStates stored in the database.

    Important : Not all vfs plugins store the pin states in the database,
    prefer to use Vfs.pin_state () etc.
    ***********************************************************/
    public PinStateInterface internal_pin_states ();

    /***********************************************************
    Only used for auto-test:
    when positive, will decrease the counter for every database operation.
    reaching 0 makes the operation fails
    ***********************************************************/
    public int autotest_fail_counter = -1;

private:
    int get_file_record_count ();
    bool update_database_structure ();
    bool update_metadata_table_structure ();
    bool update_error_blacklist_table_structure ();
    bool sql_fail (string &log, SqlQuery &query);
    void commit_internal (string &context, bool start_trans = true);
    void start_transaction ();
    void commit_transaction ();
    QVector<QByteArray> table_columns (QByteArray &table);
    bool check_connect ();

    // Same as force_remote_discovery_next_sync but without acquiring the lock
    void force_remote_discovery_next_sync_locked ();

    // Returns the integer id of the checksum type
    //
    // Returns 0 on failure and for empty checksum types.
    int map_checksum_type (QByteArray &checksum_type);

    SqlDatabase _db;
    string _db_file;
    QRecursiveMutex _mutex; // Public functions are protected with the mutex.
    QMap<QByteArray, int> _checksym_type_cache;
    int _transaction;
    bool _metadata_table_is_empty;

    /* Storing etags to these folders, or their parent folders, is filtered out.

    When schedule_path_for_remote_discovery () is called some etags to _invalid_ in the
    database. If this is done during a sync run, a later propagation job might
    undo that by writing the correct etag to the database instead. This filter
    will prevent this write and instead guarantee the _invalid_ etag stays in
    place.

    The list is cleared on close () (end of sync ru
    clear_etag_storage_filter () (start of sync run).

    The contained paths have a trailing /.
    ***********************************************************/
    QList<QByteArray> _etag_storage_filter;

    /***********************************************************
    The journal mode to use for the db.

    Typically WAL initially, but may be set to other modes via environment
    variable, for specific filesystems, or when WAL fails in a particular way.
    ***********************************************************/
    QByteArray _journal_mode;

    PreparedSqlQueryManager _query_manager;
};

bool OCSYNC_EXPORT
operator== (SyncJournalDb.DownloadInfo &lhs,
    const SyncJournalDb.DownloadInfo &rhs);
bool OCSYNC_EXPORT
operator== (SyncJournalDb.UploadInfo &lhs,
    const SyncJournalDb.UploadInfo &rhs);




const int GET_FILE_RECORD_QUERY
        "SELECT path, inode, modtime, type, md5, fileid, remote_perm, filesize,"
        "  ignored_children_remote, contentchecksumtype.name || ':' || content_checksum, e2e_mangled_name, is_e2e_encrypted "
        " FROM metadata"
        "  LEFT JOIN checksumtype as contentchecksumtype ON metadata.content_checksum_type_id == contentchecksumtype.id"

static void fill_file_record_from_get_query (SyncJournalFileRecord &rec, SqlQuery &query) {
    rec._path = query.ba_value (0);
    rec._inode = query.int64Value (1);
    rec._modtime = query.int64Value (2);
    rec._type = static_cast<ItemType> (query.int_value (3));
    rec._etag = query.ba_value (4);
    rec._file_id = query.ba_value (5);
    rec._remote_perm = RemotePermissions.from_db_value (query.ba_value (6));
    rec._file_size = query.int64Value (7);
    rec._server_has_ignored_files = (query.int_value (8) > 0);
    rec._checksum_header = query.ba_value (9);
    rec._e2e_mangled_name = query.ba_value (10);
    rec._is_e2e_encrypted = query.int_value (11) > 0;
}

static QByteArray default_journal_mode (string &db_path) {
    Q_UNUSED (db_path)
    return "WAL";
}

SyncJournalDb.SyncJournalDb (string &db_file_path, GLib.Object *parent)
    : GLib.Object (parent)
    , _db_file (db_file_path)
    , _transaction (0)
    , _metadata_table_is_empty (false) {
    // Allow forcing the journal mode for debugging
    static QByteArray env_journal_mode = qgetenv ("OWNCLOUD_SQLITE_JOURNAL_MODE");
    _journal_mode = env_journal_mode;
    if (_journal_mode.is_empty ()) {
        _journal_mode = default_journal_mode (_db_file);
    }
}

string SyncJournalDb.make_db_name (string &local_path,
    const QUrl &remote_url,
    const string &remote_path,
    const string &user) {
    string journal_path = QStringLiteral (".sync_");

    string key = QStringLiteral ("%1@%2:%3").arg (user, remote_url.to_string (), remote_path);

    QByteArray ba = QCryptographicHash.hash (key.to_utf8 (), QCryptographicHash.Md5);
    journal_path += string.from_latin1 (ba.left (6).to_hex ()) + QStringLiteral (".db");

    // If it exists already, the path is clearly usable
    QFile file (QDir (local_path).file_path (journal_path));
    if (file.exists ()) {
        return journal_path;
    }

    // Try to create a file there
    if (file.open (QIODevice.ReadWrite)) {
        // Ok, all good.
        file.close ();
        file.remove ();
        return journal_path;
    }

    // Error during creation, just keep the original and throw errors later
    q_c_warning (lc_db) << "Could not find a writable database path" << file.file_name () << file.error_string ();
    return journal_path;
}

bool SyncJournalDb.maybe_migrate_db (string &local_path, string &absolute_journal_path) {
    const string old_db_name = local_path + QLatin1String (".csync_journal.db");
    if (!FileSystem.file_exists (old_db_name)) {
        return true;
    }
    const string old_db_name_shm = old_db_name + QStringLiteral ("-shm");
    const string old_db_name_wal = old_db_name + QStringLiteral ("-wal");

    const string new_db_name = absolute_journal_path;
    const string new_db_name_shm = new_db_name + QStringLiteral ("-shm");
    const string new_db_name_wal = new_db_name + QStringLiteral ("-wal");

    // Whenever there is an old db file, migrate it to the new db path.
    // This is done to make switching from older versions to newer versions
    // work correctly even if the user had previously used a new version
    // and therefore already has an (outdated) new-style db file.
    string error;

    if (FileSystem.file_exists (new_db_name)) {
        if (!FileSystem.remove (new_db_name, &error)) {
            q_c_warning (lc_db) << "Database migration : Could not remove db file" << new_db_name
                            << "due to" << error;
            return false;
        }
    }
    if (FileSystem.file_exists (new_db_name_wal)) {
        if (!FileSystem.remove (new_db_name_wal, &error)) {
            q_c_warning (lc_db) << "Database migration : Could not remove db WAL file" << new_db_name_wal
                            << "due to" << error;
            return false;
        }
    }
    if (FileSystem.file_exists (new_db_name_shm)) {
        if (!FileSystem.remove (new_db_name_shm, &error)) {
            q_c_warning (lc_db) << "Database migration : Could not remove db SHM file" << new_db_name_shm
                            << "due to" << error;
            return false;
        }
    }

    if (!FileSystem.rename (old_db_name, new_db_name, &error)) {
        q_c_warning (lc_db) << "Database migration : could not rename" << old_db_name
                        << "to" << new_db_name << ":" << error;
        return false;
    }
    if (!FileSystem.rename (old_db_name_wal, new_db_name_wal, &error)) {
        q_c_warning (lc_db) << "Database migration : could not rename" << old_db_name_wal
                        << "to" << new_db_name_wal << ":" << error;
        return false;
    }
    if (!FileSystem.rename (old_db_name_shm, new_db_name_shm, &error)) {
        q_c_warning (lc_db) << "Database migration : could not rename" << old_db_name_shm
                        << "to" << new_db_name_shm << ":" << error;
        return false;
    }

    q_c_info (lc_db) << "Journal successfully migrated from" << old_db_name << "to" << new_db_name;
    return true;
}

bool SyncJournalDb.exists () {
    QMutexLocker locker (&_mutex);
    return (!_db_file.is_empty () && QFile.exists (_db_file));
}

string SyncJournalDb.database_file_path () {
    return _db_file;
}

// Note that this does not change the size of the -wal file, but it is supposed to make
// the normal .db faster since the changes from the wal will be incorporated into it.
// Then the next sync (and the SocketApi) will have a faster access.
void SyncJournalDb.wal_checkpoint () {
    QElapsedTimer t;
    t.start ();
    SqlQuery pragma1 (_db);
    pragma1.prepare ("PRAGMA wal_checkpoint (FULL);");
    if (pragma1.exec ()) {
        q_c_debug (lc_db) << "took" << t.elapsed () << "msec";
    }
}

void SyncJournalDb.start_transaction () {
    if (_transaction == 0) {
        if (!_db.transaction ()) {
            q_c_warning (lc_db) << "ERROR starting transaction:" << _db.error ();
            return;
        }
        _transaction = 1;
    } else {
        q_c_debug (lc_db) << "Database Transaction is running, not starting another one!";
    }
}

void SyncJournalDb.commit_transaction () {
    if (_transaction == 1) {
        if (!_db.commit ()) {
            q_c_warning (lc_db) << "ERROR committing to the database:" << _db.error ();
            return;
        }
        _transaction = 0;
    } else {
        q_c_debug (lc_db) << "No database Transaction to commit";
    }
}

bool SyncJournalDb.sql_fail (string &log, SqlQuery &query) {
    commit_transaction ();
    q_c_warning (lc_db) << "SQL Error" << log << query.error ();
    _db.close ();
    ASSERT (false);
    return false;
}

bool SyncJournalDb.check_connect () {
    if (autotest_fail_counter >= 0) {
        if (!autotest_fail_counter--) {
            q_c_info (lc_db) << "Error Simulated";
            return false;
        }
    }

    if (_db.is_open ()) {
        // Unfortunately the sqlite is_open check can return true even when the underlying storage
        // has become unavailable - and then some operations may cause crashes. See #6049
        if (!QFile.exists (_db_file)) {
            q_c_warning (lc_db) << "Database open, but file" << _db_file << "does not exist";
            close ();
            return false;
        }
        return true;
    }

    if (_db_file.is_empty ()) {
        q_c_warning (lc_db) << "Database filename" << _db_file << "is empty";
        return false;
    }

    // The database file is created by this call (SQLITE_OPEN_CREATE)
    if (!_db.open_or_create_read_write (_db_file)) {
        string error = _db.error ();
        q_c_warning (lc_db) << "Error opening the db:" << error;
        return false;
    }

    if (!QFile.exists (_db_file)) {
        q_c_warning (lc_db) << "Database file" << _db_file << "does not exist";
        return false;
    }

    SqlQuery pragma1 (_db);
    pragma1.prepare ("SELECT sqlite_version ();");
    if (!pragma1.exec ()) {
        return sql_fail (QStringLiteral ("SELECT sqlite_version ()"), pragma1);
    } else {
        pragma1.next ();
        q_c_info (lc_db) << "Sqlite3 version" << pragma1.string_value (0);
    }

    // Set locking mode to avoid issues with WAL on Windows
    static QByteArray locking_mode_env = qgetenv ("OWNCLOUD_SQLITE_LOCKING_MODE");
    if (locking_mode_env.is_empty ())
        locking_mode_env = "EXCLUSIVE";
    pragma1.prepare ("PRAGMA locking_mode=" + locking_mode_env + ";");
    if (!pragma1.exec ()) {
        return sql_fail (QStringLiteral ("Set PRAGMA locking_mode"), pragma1);
    } else {
        pragma1.next ();
        q_c_info (lc_db) << "Sqlite3 locking_mode=" << pragma1.string_value (0);
    }

    pragma1.prepare ("PRAGMA journal_mode=" + _journal_mode + ";");
    if (!pragma1.exec ()) {
        return sql_fail (QStringLiteral ("Set PRAGMA journal_mode"), pragma1);
    } else {
        pragma1.next ();
        q_c_info (lc_db) << "Sqlite3 journal_mode=" << pragma1.string_value (0);
    }

    // For debugging purposes, allow temp_store to be set
    static QByteArray env_temp_store = qgetenv ("OWNCLOUD_SQLITE_TEMP_STORE");
    if (!env_temp_store.is_empty ()) {
        pragma1.prepare ("PRAGMA temp_store = " + env_temp_store + ";");
        if (!pragma1.exec ()) {
            return sql_fail (QStringLiteral ("Set PRAGMA temp_store"), pragma1);
        }
        q_c_info (lc_db) << "Sqlite3 with temp_store =" << env_temp_store;
    }

    // With WAL journal the NORMAL sync mode is safe from corruption,
    // otherwise use the standard FULL mode.
    QByteArray synchronous_mode = "FULL";
    if (string.from_utf8 (_journal_mode).compare (QStringLiteral ("wal"), Qt.CaseInsensitive) == 0)
        synchronous_mode = "NORMAL";
    pragma1.prepare ("PRAGMA synchronous = " + synchronous_mode + ";");
    if (!pragma1.exec ()) {
        return sql_fail (QStringLiteral ("Set PRAGMA synchronous"), pragma1);
    } else {
        q_c_info (lc_db) << "Sqlite3 synchronous=" << synchronous_mode;
    }

    pragma1.prepare ("PRAGMA case_sensitive_like = ON;");
    if (!pragma1.exec ()) {
        return sql_fail (QStringLiteral ("Set PRAGMA case_sensitivity"), pragma1);
    }

    sqlite3_create_function (_db.sqlite_db (), "parent_hash", 1, SQLITE_UTF8 | SQLITE_DETERMINISTIC, nullptr,
                                [] (sqlite3_context *ctx,int, sqlite3_value **argv) {
                                    auto text = reinterpret_cast<const char> (sqlite3_value_text (argv[0]));
                                    const char *end = std.strrchr (text, '/');
                                    if (!end) end = text;
                                    sqlite3_result_int64 (ctx, c_jhash64 (reinterpret_cast<const uint8_t> (text),
                                                                        end - text, 0));
                                }, nullptr, nullptr);

    // Because insert is so slow, we do everything in a transaction, and only need one call to commit
    start_transaction ();

    SqlQuery create_query (_db);
    create_query.prepare ("CREATE TABLE IF NOT EXISTS metadata ("
                        "phash INTEGER (8),"
                        "pathlen INTEGER,"
                        "path VARCHAR (4096),"
                        "inode INTEGER,"
                        "uid INTEGER,"
                        "gid INTEGER,"
                        "mode INTEGER,"
                        "modtime INTEGER (8),"
                        "type INTEGER,"
                        "md5 VARCHAR (32)," // This is the etag.  Called md5 for compatibility
                        // update_database_structure () will add
                        // fileid
                        // remote_perm
                        // filesize
                        // ignored_children_remote
                        // content_checksum
                        // content_checksum_type_id
                        "PRIMARY KEY (phash)"
                        ");");

#ifndef SQLITE_IOERR_SHMMAP
// Requires sqlite >= 3.7.7 but old CentOS6 has sqlite-3.6.20
// Definition taken from https://sqlite.org/c3ref/c_abort_rollback.html
const int SQLITE_IOERR_SHMMAP            (SQLITE_IOERR | (21<<8))
#endif

    if (!create_query.exec ()) {
        // In certain situations the io error can be avoided by switching
        // to the DELETE journal mode, see #5723
        if (_journal_mode != "DELETE"
            && create_query.error_id () == SQLITE_IOERR
            && sqlite3_extended_errcode (_db.sqlite_db ()) == SQLITE_IOERR_SHMMAP) {
            q_c_warning (lc_db) << "IO error SHMMAP on table creation, attempting with DELETE journal mode";
            _journal_mode = "DELETE";
            commit_transaction ();
            _db.close ();
            return check_connect ();
        }

        return sql_fail (QStringLiteral ("Create table metadata"), create_query);
    }

    create_query.prepare ("CREATE TABLE IF NOT EXISTS key_value_store (key VARCHAR (4096), value VARCHAR (4096), PRIMARY KEY (key));");

    if (!create_query.exec ()) {
        return sql_fail (QStringLiteral ("Create table key_value_store"), create_query);
    }

    create_query.prepare ("CREATE TABLE IF NOT EXISTS downloadinfo ("
                        "path VARCHAR (4096),"
                        "tmpfile VARCHAR (4096),"
                        "etag VARCHAR (32),"
                        "errorcount INTEGER,"
                        "PRIMARY KEY (path)"
                        ");");

    if (!create_query.exec ()) {
        return sql_fail (QStringLiteral ("Create table downloadinfo"), create_query);
    }

    create_query.prepare ("CREATE TABLE IF NOT EXISTS uploadinfo ("
                        "path VARCHAR (4096),"
                        "chunk INTEGER,"
                        "transferid INTEGER,"
                        "errorcount INTEGER,"
                        "size INTEGER (8),"
                        "modtime INTEGER (8),"
                        "content_checksum TEXT,"
                        "PRIMARY KEY (path)"
                        ");");

    if (!create_query.exec ()) {
        return sql_fail (QStringLiteral ("Create table uploadinfo"), create_query);
    }

    // create the blacklist table.
    create_query.prepare ("CREATE TABLE IF NOT EXISTS blacklist ("
                        "path VARCHAR (4096),"
                        "last_try_etag VARCHAR[32],"
                        "last_try_modtime INTEGER[8],"
                        "retrycount INTEGER,"
                        "errorstring VARCHAR[4096],"
                        "PRIMARY KEY (path)"
                        ");");

    if (!create_query.exec ()) {
        return sql_fail (QStringLiteral ("Create table blacklist"), create_query);
    }

    create_query.prepare ("CREATE TABLE IF NOT EXISTS async_poll ("
                        "path VARCHAR (4096),"
                        "modtime INTEGER (8),"
                        "filesize BIGINT,"
                        "pollpath VARCHAR (4096));");
    if (!create_query.exec ()) {
        return sql_fail (QStringLiteral ("Create table async_poll"), create_query);
    }

    // create the selectivesync table.
    create_query.prepare ("CREATE TABLE IF NOT EXISTS selectivesync ("
                        "path VARCHAR (4096),"
                        "type INTEGER"
                        ");");

    if (!create_query.exec ()) {
        return sql_fail (QStringLiteral ("Create table selectivesync"), create_query);
    }

    // create the checksumtype table.
    create_query.prepare ("CREATE TABLE IF NOT EXISTS checksumtype ("
                        "id INTEGER PRIMARY KEY,"
                        "name TEXT UNIQUE"
                        ");");
    if (!create_query.exec ()) {
        return sql_fail (QStringLiteral ("Create table checksumtype"), create_query);
    }

    // create the datafingerprint table.
    create_query.prepare ("CREATE TABLE IF NOT EXISTS datafingerprint ("
                        "fingerprint TEXT UNIQUE"
                        ");");
    if (!create_query.exec ()) {
        return sql_fail (QStringLiteral ("Create table datafingerprint"), create_query);
    }

    // create the flags table.
    create_query.prepare ("CREATE TABLE IF NOT EXISTS flags ("
                        "path TEXT PRIMARY KEY,"
                        "pin_state INTEGER"
                        ");");
    if (!create_query.exec ()) {
        return sql_fail (QStringLiteral ("Create table flags"), create_query);
    }

    // create the conflicts table.
    create_query.prepare ("CREATE TABLE IF NOT EXISTS conflicts ("
                        "path TEXT PRIMARY KEY,"
                        "base_file_id TEXT,"
                        "base_etag TEXT,"
                        "base_modtime INTEGER"
                        ");");
    if (!create_query.exec ()) {
        return sql_fail (QStringLiteral ("Create table conflicts"), create_query);
    }

    create_query.prepare ("CREATE TABLE IF NOT EXISTS version ("
                        "major INTEGER (8),"
                        "minor INTEGER (8),"
                        "patch INTEGER (8),"
                        "custom VARCHAR (256)"
                        ");");
    if (!create_query.exec ()) {
        return sql_fail (QStringLiteral ("Create table version"), create_query);
    }

    bool force_remote_discovery = false;

    SqlQuery version_query ("SELECT major, minor, patch FROM version;", _db);
    if (!version_query.next ().has_data) {
        force_remote_discovery = true;

        create_query.prepare ("INSERT INTO version VALUES (?1, ?2, ?3, ?4);");
        create_query.bind_value (1, MIRALL_VERSION_MAJOR);
        create_query.bind_value (2, MIRALL_VERSION_MINOR);
        create_query.bind_value (3, MIRALL_VERSION_PATCH);
        create_query.bind_value (4, MIRALL_VERSION_BUILD);
        if (!create_query.exec ()) {
            return sql_fail (QStringLiteral ("Update version"), create_query);
        }

    } else {
        int major = version_query.int_value (0);
        int minor = version_query.int_value (1);
        int patch = version_query.int_value (2);

        if (major == 1 && minor == 8 && (patch == 0 || patch == 1)) {
            q_c_info (lc_db) << "possible_upgrade_from_mirall_1_8_0_or_1 detected!";
            force_remote_discovery = true;
        }

        // There was a bug in versions <2.3.0 that could lead to stale
        // local files and a remote discovery will fix them.
        // See #5190 #5242.
        if (major == 2 && minor < 3) {
            q_c_info (lc_db) << "upgrade form client < 2.3.0 detected! forcing remote discovery";
            force_remote_discovery = true;
        }

        // Not comparing the BUILD id here, correct?
        if (! (major == MIRALL_VERSION_MAJOR && minor == MIRALL_VERSION_MINOR && patch == MIRALL_VERSION_PATCH)) {
            create_query.prepare ("UPDATE version SET major=?1, minor=?2, patch =?3, custom=?4 "
                                "WHERE major=?5 AND minor=?6 AND patch=?7;");
            create_query.bind_value (1, MIRALL_VERSION_MAJOR);
            create_query.bind_value (2, MIRALL_VERSION_MINOR);
            create_query.bind_value (3, MIRALL_VERSION_PATCH);
            create_query.bind_value (4, MIRALL_VERSION_BUILD);
            create_query.bind_value (5, major);
            create_query.bind_value (6, minor);
            create_query.bind_value (7, patch);
            if (!create_query.exec ()) {
                return sql_fail (QStringLiteral ("Update version"), create_query);
            }
        }
    }

    commit_internal (QStringLiteral ("check_connect"));

    bool rc = update_database_structure ();
    if (!rc) {
        q_c_warning (lc_db) << "Failed to update the database structure!";
    }

    /***********************************************************
    If we are upgrading from a client version older than 1.5,
    we cannot read from the database because we need to fetch the files id and etags.

     If 1.8.0 caused missing data in the l
     to get back the files that were gone.
     In 1.8.1 we had a fix to re-get the data, but this one here is better
    ***********************************************************/
    if (force_remote_discovery) {
        force_remote_discovery_next_sync_locked ();
    }
    const auto delete_download_info = _query_manager.get (PreparedSqlQueryManager.DeleteDownloadInfoQuery, QByteArrayLiteral ("DELETE FROM downloadinfo WHERE path=?1"), _db);
    if (!delete_download_info) {
        return sql_fail (QStringLiteral ("prepare _delete_download_info_query"), *delete_download_info);
    }

    const auto delete_upload_info_query = _query_manager.get (PreparedSqlQueryManager.DeleteUploadInfoQuery, QByteArrayLiteral ("DELETE FROM uploadinfo WHERE path=?1"), _db);
    if (!delete_upload_info_query) {
        return sql_fail (QStringLiteral ("prepare _delete_upload_info_query"), *delete_upload_info_query);
    }

    QByteArray sql ("SELECT last_try_etag, last_try_modtime, retrycount, errorstring, last_try_time, ignore_duration, rename_target, error_category, request_id "
                   "FROM blacklist WHERE path=?1");
    if (Utility.fs_case_preserving ()) {
        // if the file system is case preserving we have to check the blacklist
        // case insensitively
        sql += " COLLATE NOCASE";
    }
    const auto get_error_blacklist_query = _query_manager.get (PreparedSqlQueryManager.GetErrorBlacklistQuery, sql, _db);
    if (!get_error_blacklist_query) {
        return sql_fail (QStringLiteral ("prepare _get_error_blacklist_query"), *get_error_blacklist_query);
    }

    // don't start a new transaction now
    commit_internal (QStringLiteral ("check_connect End"), false);

    // This avoid reading from the DB if we already know it is empty
    // thereby speeding up the initial discovery significantly.
    _metadata_table_is_empty = (get_file_record_count () == 0);

    // Hide 'em all!
    FileSystem.set_file_hidden (database_file_path (), true);
    FileSystem.set_file_hidden (database_file_path () + QStringLiteral ("-wal"), true);
    FileSystem.set_file_hidden (database_file_path () + QStringLiteral ("-shm"), true);
    FileSystem.set_file_hidden (database_file_path () + QStringLiteral ("-journal"), true);

    return rc;
}

void SyncJournalDb.close () {
    QMutexLocker locker (&_mutex);
    q_c_info (lc_db) << "Closing DB" << _db_file;

    commit_transaction ();

    _db.close ();
    clear_etag_storage_filter ();
    _metadata_table_is_empty = false;
}

bool SyncJournalDb.update_database_structure () {
    if (!update_metadata_table_structure ())
        return false;
    if (!update_error_blacklist_table_structure ())
        return false;
    return true;
}

bool SyncJournalDb.update_metadata_table_structure () {

    auto columns = table_columns ("metadata");
    bool re = true;

    // check if the file_id column is there and create it if not
    if (columns.is_empty ()) {
        return false;
    }

    if (columns.index_of ("fileid") == -1) {
        SqlQuery query (_db);
        query.prepare ("ALTER TABLE metadata ADD COLUMN fileid VARCHAR (128);");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_metadata_table_structure : Add column fileid"), query);
            re = false;
        }

        query.prepare ("CREATE INDEX metadata_file_id ON metadata (fileid);");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_metadata_table_structure : create index fileid"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure : add fileid col"));
    }
    if (columns.index_of ("remote_perm") == -1) {
        SqlQuery query (_db);
        query.prepare ("ALTER TABLE metadata ADD COLUMN remote_perm VARCHAR (128);");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_metadata_table_structure : add column remote_perm"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure (remote_perm)"));
    }
    if (columns.index_of ("filesize") == -1) {
        SqlQuery query (_db);
        query.prepare ("ALTER TABLE metadata ADD COLUMN filesize BIGINT;");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_database_structure : add column filesize"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure : add filesize col"));
    }

    if (true) {
        SqlQuery query (_db);
        query.prepare ("CREATE INDEX IF NOT EXISTS metadata_inode ON metadata (inode);");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_metadata_table_structure : create index inode"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure : add inode index"));
    }

    if (true) {
        SqlQuery query (_db);
        query.prepare ("CREATE INDEX IF NOT EXISTS metadata_path ON metadata (path);");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_metadata_table_structure : create index path"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure : add path index"));
    }

    if (true) {
        SqlQuery query (_db);
        query.prepare ("CREATE INDEX IF NOT EXISTS metadata_parent ON metadata (parent_hash (path));");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_metadata_table_structure : create index parent"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure : add parent index"));
    }

    if (columns.index_of ("ignored_children_remote") == -1) {
        SqlQuery query (_db);
        query.prepare ("ALTER TABLE metadata ADD COLUMN ignored_children_remote INT;");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_metadata_table_structure : add ignored_children_remote column"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure : add ignored_children_remote col"));
    }

    if (columns.index_of ("content_checksum") == -1) {
        SqlQuery query (_db);
        query.prepare ("ALTER TABLE metadata ADD COLUMN content_checksum TEXT;");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_metadata_table_structure : add content_checksum column"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure : add content_checksum col"));
    }
    if (columns.index_of ("content_checksum_type_id") == -1) {
        SqlQuery query (_db);
        query.prepare ("ALTER TABLE metadata ADD COLUMN content_checksum_type_id INTEGER;");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_metadata_table_structure : add content_checksum_type_id column"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure : add content_checksum_type_id col"));
    }

    if (!columns.contains ("e2e_mangled_name")) {
        SqlQuery query (_db);
        query.prepare ("ALTER TABLE metadata ADD COLUMN e2e_mangled_name TEXT;");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_metadata_table_structure : add e2e_mangled_name column"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure : add e2e_mangled_name col"));
    }

    if (!columns.contains ("is_e2e_encrypted")) {
        SqlQuery query (_db);
        query.prepare ("ALTER TABLE metadata ADD COLUMN is_e2e_encrypted INTEGER;");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_metadata_table_structure : add is_e2e_encrypted column"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure : add is_e2e_encrypted col"));
    }

    auto upload_info_columns = table_columns ("uploadinfo");
    if (upload_info_columns.is_empty ())
        return false;
    if (!upload_info_columns.contains ("content_checksum")) {
        SqlQuery query (_db);
        query.prepare ("ALTER TABLE uploadinfo ADD COLUMN content_checksum TEXT;");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_metadata_table_structure : add content_checksum column"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure : add content_checksum col for uploadinfo"));
    }

    auto conflicts_columns = table_columns ("conflicts");
    if (conflicts_columns.is_empty ())
        return false;
    if (!conflicts_columns.contains ("base_path")) {
        SqlQuery query (_db);
        query.prepare ("ALTER TABLE conflicts ADD COLUMN base_path TEXT;");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_metadata_table_structure : add base_path column"), query);
            re = false;
        }
    }

    if (true) {
        SqlQuery query (_db);
        query.prepare ("CREATE INDEX IF NOT EXISTS metadata_e2e_id ON metadata (e2e_mangled_name);");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_metadata_table_structure : create index e2e_mangled_name"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure : add e2e_mangled_name index"));
    }

    return re;
}

bool SyncJournalDb.update_error_blacklist_table_structure () {
    auto columns = table_columns ("blacklist");
    bool re = true;

    if (columns.is_empty ()) {
        return false;
    }

    if (columns.index_of ("last_try_time") == -1) {
        SqlQuery query (_db);
        query.prepare ("ALTER TABLE blacklist ADD COLUMN last_try_time INTEGER (8);");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_blacklist_table_structure : Add last_try_time fileid"), query);
            re = false;
        }
        query.prepare ("ALTER TABLE blacklist ADD COLUMN ignore_duration INTEGER (8);");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_blacklist_table_structure : Add ignore_duration fileid"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure : add last_try_time, ignore_duration cols"));
    }
    if (columns.index_of ("rename_target") == -1) {
        SqlQuery query (_db);
        query.prepare ("ALTER TABLE blacklist ADD COLUMN rename_target VARCHAR (4096);");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_blacklist_table_structure : Add rename_target"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure : add rename_target col"));
    }

    if (columns.index_of ("error_category") == -1) {
        SqlQuery query (_db);
        query.prepare ("ALTER TABLE blacklist ADD COLUMN error_category INTEGER (8);");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_blacklist_table_structure : Add error_category"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure : add error_category col"));
    }

    if (columns.index_of ("request_id") == -1) {
        SqlQuery query (_db);
        query.prepare ("ALTER TABLE blacklist ADD COLUMN request_id VARCHAR (36);");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_blacklist_table_structure : Add request_id"), query);
            re = false;
        }
        commit_internal (QStringLiteral ("update database structure : add error_category col"));
    }

    SqlQuery query (_db);
    query.prepare ("CREATE INDEX IF NOT EXISTS blacklist_index ON blacklist (path collate nocase);");
    if (!query.exec ()) {
        sql_fail (QStringLiteral ("update_error_blacklist_table_structure : create index blacklit"), query);
        re = false;
    }

    return re;
}

QVector<QByteArray> SyncJournalDb.table_columns (QByteArray &table) {
    QVector<QByteArray> columns;
    if (!check_connect ()) {
        return columns;
    }
    SqlQuery query ("PRAGMA table_info ('" + table + "');", _db);
    if (!query.exec ()) {
        return columns;
    }
    while (query.next ().has_data) {
        columns.append (query.ba_value (1));
    }
    q_c_debug (lc_db) << "Columns in the current journal:" << columns;
    return columns;
}

int64 SyncJournalDb.get_pHash (QByteArray &file) {
    int64 h = 0;
    int len = file.length ();

    h = c_jhash64 ( (uint8_t *)file.data (), len, 0);
    return h;
}

Result<void, string> SyncJournalDb.set_file_record (SyncJournalFileRecord &_record) {
    SyncJournalFileRecord record = _record;
    QMutexLocker locker (&_mutex);

    if (!_etag_storage_filter.is_empty ()) {
        // If we are a directory that should not be read from db next time, don't write the etag
        QByteArray prefix = record._path + "/";
        foreach (QByteArray &it, _etag_storage_filter) {
            if (it.starts_with (prefix)) {
                q_c_info (lc_db) << "Filtered writing the etag of" << prefix << "because it is a prefix of" << it;
                record._etag = "_invalid_";
                break;
            }
        }
    }

    q_c_info (lc_db) << "Updating file record for path:" << record.path () << "inode:" << record._inode
                 << "modtime:" << record._modtime << "type:" << record._type
                 << "etag:" << record._etag << "file_id:" << record._file_id << "remote_perm:" << record._remote_perm.to_string ()
                 << "file_size:" << record._file_size << "checksum:" << record._checksum_header
                 << "e2e_mangled_name:" << record.e2e_mangled_name () << "is_e2e_encrypted:" << record._is_e2e_encrypted;

    const int64 phash = get_pHash (record._path);
    if (check_connect ()) {
        int plen = record._path.length ();

        QByteArray etag (record._etag);
        if (etag.is_empty ())
            etag = "";
        QByteArray file_id (record._file_id);
        if (file_id.is_empty ())
            file_id = "";
        QByteArray remote_perm = record._remote_perm.to_db_value ();
        QByteArray checksum_type, checksum;
        parse_checksum_header (record._checksum_header, &checksum_type, &checksum);
        int content_checksum_type_id = map_checksum_type (checksum_type);

        const auto query = _query_manager.get (PreparedSqlQueryManager.SetFileRecordQuery, QByteArrayLiteral ("INSERT OR REPLACE INTO metadata "
                                                                                                            " (phash, pathlen, path, inode, uid, gid, mode, modtime, type, md5, fileid, remote_perm, filesize, ignored_children_remote, content_checksum, content_checksum_type_id, e2e_mangled_name, is_e2e_encrypted) "
                                                                                                            "VALUES (?1 , ?2, ?3 , ?4 , ?5 , ?6 , ?7,  ?8 , ?9 , ?10, ?11, ?12, ?13, ?14, ?15, ?16, ?17, ?18);"),
            _db);
        if (!query) {
            return query.error ();
        }

        query.bind_value (1, phash);
        query.bind_value (2, plen);
        query.bind_value (3, record._path);
        query.bind_value (4, record._inode);
        query.bind_value (5, 0); // uid Not used
        query.bind_value (6, 0); // gid Not used
        query.bind_value (7, 0); // mode Not used
        query.bind_value (8, record._modtime);
        query.bind_value (9, record._type);
        query.bind_value (10, etag);
        query.bind_value (11, file_id);
        query.bind_value (12, remote_perm);
        query.bind_value (13, record._file_size);
        query.bind_value (14, record._server_has_ignored_files ? 1 : 0);
        query.bind_value (15, checksum);
        query.bind_value (16, content_checksum_type_id);
        query.bind_value (17, record._e2e_mangled_name);
        query.bind_value (18, record._is_e2e_encrypted);

        if (!query.exec ()) {
            return query.error ();
        }

        // Can't be true anymore.
        _metadata_table_is_empty = false;

        return {};
    } else {
        q_c_warning (lc_db) << "Failed to connect database.";
        return tr ("Failed to connect database."); // check_connect failed.
    }
}

void SyncJournalDb.key_value_store_set (string &key, QVariant value) {
    QMutexLocker locker (&_mutex);
    if (!check_connect ()) {
        return;
    }

    const auto query = _query_manager.get (PreparedSqlQueryManager.SetKeyValueStoreQuery, QByteArrayLiteral ("INSERT OR REPLACE INTO key_value_store (key, value) VALUES (?1, ?2);"), _db);
    if (!query) {
        return;
    }

    query.bind_value (1, key);
    query.bind_value (2, value);
    query.exec ();
}

int64 SyncJournalDb.key_value_store_get_int (string &key, int64 default_value) {
    QMutexLocker locker (&_mutex);
    if (!check_connect ()) {
        return default_value;
    }

    const auto query = _query_manager.get (PreparedSqlQueryManager.GetKeyValueStoreQuery, QByteArrayLiteral ("SELECT value FROM key_value_store WHERE key=?1"), _db);
    if (!query) {
        return default_value;
    }

    query.bind_value (1, key);
    query.exec ();
    auto result = query.next ();

    if (!result.ok || !result.has_data) {
        return default_value;
    }

    return query.int64Value (0);
}

void SyncJournalDb.key_value_store_delete (string &key) {
    const auto query = _query_manager.get (PreparedSqlQueryManager.DeleteKeyValueStoreQuery, QByteArrayLiteral ("DELETE FROM key_value_store WHERE key=?1;"), _db);
    if (!query) {
        q_c_warning (lc_db) << "Failed to init_or_reset _delete_key_value_store_query";
        Q_ASSERT (false);
    }
    query.bind_value (1, key);
    if (!query.exec ()) {
        q_c_warning (lc_db) << "Failed to exec _delete_key_value_store_query for key" << key;
        Q_ASSERT (false);
    }
}

// TODO : filename . QBytearray?
bool SyncJournalDb.delete_file_record (string &filename, bool recursively) {
    QMutexLocker locker (&_mutex);

    if (check_connect ()) {
        // if (!recursively) {
        // always delete the actual file.
 {
            const auto query = _query_manager.get (PreparedSqlQueryManager.DeleteFileRecordPhash, QByteArrayLiteral ("DELETE FROM metadata WHERE phash=?1"), _db);
            if (!query) {
                return false;
            }

            const int64 phash = get_pHash (filename.to_utf8 ());
            query.bind_value (1, phash);

            if (!query.exec ()) {
                return false;
            }
        }

        if (recursively) {
            const auto query = _query_manager.get (PreparedSqlQueryManager.DeleteFileRecordRecursively, QByteArrayLiteral ("DELETE FROM metadata WHERE " IS_PREFIX_PATH_OF ("?1", "path")), _db);
            if (!query)
                return false;
            query.bind_value (1, filename);
            if (!query.exec ()) {
                return false;
            }
        }
        return true;
    } else {
        q_c_warning (lc_db) << "Failed to connect database.";
        return false; // check_connect failed.
    }
}

bool SyncJournalDb.get_file_record (QByteArray &filename, SyncJournalFileRecord *rec) {
    QMutexLocker locker (&_mutex);

    // Reset the output var in case the caller is reusing it.
    Q_ASSERT (rec);
    rec._path.clear ();
    Q_ASSERT (!rec.is_valid ());

    if (_metadata_table_is_empty)
        return true; // no error, yet nothing found (rec.is_valid () == false)

    if (!check_connect ())
        return false;

    if (!filename.is_empty ()) {
        const auto query = _query_manager.get (PreparedSqlQueryManager.Key.GET_FILE_RECORD_QUERY, QByteArrayLiteral (GET_FILE_RECORD_QUERY " WHERE phash=?1"), _db);
        if (!query) {
            return false;
        }

        query.bind_value (1, get_pHash (filename));

        if (!query.exec ()) {
            close ();
            return false;
        }

        auto next = query.next ();
        if (!next.ok) {
            string err = query.error ();
            q_c_warning (lc_db) << "No journal entry found for" << filename << "Error:" << err;
            close ();
            return false;
        }
        if (next.has_data) {
            fill_file_record_from_get_query (*rec, *query);
        }
    }
    return true;
}

bool SyncJournalDb.get_file_record_by_e2e_mangled_name (string &mangled_name, SyncJournalFileRecord *rec) {
    QMutexLocker locker (&_mutex);

    // Reset the output var in case the caller is reusing it.
    Q_ASSERT (rec);
    rec._path.clear ();
    Q_ASSERT (!rec.is_valid ());

    if (_metadata_table_is_empty) {
        return true; // no error, yet nothing found (rec.is_valid () == false)
    }

    if (!check_connect ()) {
        return false;
    }

    if (!mangled_name.is_empty ()) {
        const auto query = _query_manager.get (PreparedSqlQueryManager.Key.GET_FILE_RECORD_QUERY_BY_MANGLED_NAME, QByteArrayLiteral (GET_FILE_RECORD_QUERY " WHERE e2e_mangled_name=?1"), _db);
        if (!query) {
            return false;
        }

        query.bind_value (1, mangled_name);

        if (!query.exec ()) {
            close ();
            return false;
        }

        auto next = query.next ();
        if (!next.ok) {
            string err = query.error ();
            q_c_warning (lc_db) << "No journal entry found for mangled name" << mangled_name << "Error : " << err;
            close ();
            return false;
        }
        if (next.has_data) {
            fill_file_record_from_get_query (*rec, *query);
        }
    }
    return true;
}

bool SyncJournalDb.get_file_record_by_inode (uint64 inode, SyncJournalFileRecord *rec) {
    QMutexLocker locker (&_mutex);

    // Reset the output var in case the caller is reusing it.
    Q_ASSERT (rec);
    rec._path.clear ();
    Q_ASSERT (!rec.is_valid ());

    if (!inode || _metadata_table_is_empty)
        return true; // no error, yet nothing found (rec.is_valid () == false)

    if (!check_connect ())
        return false;
    const auto query = _query_manager.get (PreparedSqlQueryManager.Key.GET_FILE_RECORD_QUERY_BY_INODE, QByteArrayLiteral (GET_FILE_RECORD_QUERY " WHERE inode=?1"), _db);
    if (!query)
        return false;

    query.bind_value (1, inode);

    if (!query.exec ())
        return false;

    auto next = query.next ();
    if (!next.ok)
        return false;
    if (next.has_data)
        fill_file_record_from_get_query (*rec, *query);

    return true;
}

bool SyncJournalDb.get_file_records_by_file_id (QByteArray &file_id, std.function<void (SyncJournalFileRecord &)> &row_callback) {
    QMutexLocker locker (&_mutex);

    if (file_id.is_empty () || _metadata_table_is_empty)
        return true; // no error, yet nothing found (rec.is_valid () == false)

    if (!check_connect ())
        return false;

    const auto query = _query_manager.get (PreparedSqlQueryManager.Key.GET_FILE_RECORD_QUERY_BY_FILE_ID, QByteArrayLiteral (GET_FILE_RECORD_QUERY " WHERE fileid=?1"), _db);
    if (!query) {
        return false;
    }

    query.bind_value (1, file_id);

    if (!query.exec ())
        return false;

    forever {
        auto next = query.next ();
        if (!next.ok)
            return false;
        if (!next.has_data)
            break;

        SyncJournalFileRecord rec;
        fill_file_record_from_get_query (rec, *query);
        row_callback (rec);
    }

    return true;
}

bool SyncJournalDb.get_files_below_path (QByteArray &path, std.function<void (SyncJournalFileRecord&)> &row_callback) {
    QMutexLocker locker (&_mutex);

    if (_metadata_table_is_empty)
        return true; // no error, yet nothing found

    if (!check_connect ())
        return false;

    auto _exec = [&row_callback] (SqlQuery &query) {
        if (!query.exec ()) {
            return false;
        }

        forever {
            auto next = query.next ();
            if (!next.ok)
                return false;
            if (!next.has_data)
                break;

            SyncJournalFileRecord rec;
            fill_file_record_from_get_query (rec, query);
            row_callback (rec);
        }
        return true;
    };

    if (path.is_empty ()) {
        // Since the path column doesn't store the starting /, the get_files_below_path_query
        // can't be used for the root path "". It would scan for (path > '/' and path < '0')
        // and find nothing. So, unfortunately, we have to use a different query for
        // retrieving the whole tree.

        const auto query = _query_manager.get (PreparedSqlQueryManager.GetAllFilesQuery, QByteArrayLiteral (GET_FILE_RECORD_QUERY " ORDER BY path||'/' ASC"), _db);
        if (!query) {
            return false;
        }
        return _exec (*query);
    } else {
        // This query is used to skip discovery and fill the tree from the
        // database instead
        const auto query = _query_manager.get (PreparedSqlQueryManager.GetFilesBelowPathQuery, QByteArrayLiteral (GET_FILE_RECORD_QUERY " WHERE " IS_PREFIX_PATH_OF ("?1", "path")
                                                                                                                " OR " IS_PREFIX_PATH_OF ("?1", "e2e_mangled_name")
                                                                                                                // We want to ensure that the contents of a directory are sorted
                                                                                                                // directly behind the directory itself. Without this ORDER BY
                                                                                                                // an ordering like foo, foo-2, foo/file would be returned.
                                                                                                                // With the trailing /, we get foo-2, foo, foo/file. This property
                                                                                                                // is used in fill_tree_from_db ().
                                                                                                                " ORDER BY path||'/' ASC"),
            _db);
        if (!query) {
            return false;
        }
        query.bind_value (1, path);
        return _exec (*query);
    }
}

bool SyncJournalDb.list_files_in_path (QByteArray& path,
                                    const std.function<void (SyncJournalFileRecord &)>& row_callback) {
    QMutexLocker locker (&_mutex);

    if (_metadata_table_is_empty)
        return true;

    if (!check_connect ())
        return false;

    const auto query = _query_manager.get (PreparedSqlQueryManager.List_files_in_path_query, QByteArrayLiteral (GET_FILE_RECORD_QUERY " WHERE parent_hash (path) = ?1 ORDER BY path||'/' ASC"), _db);
    if (!query) {
        return false;
    }
    query.bind_value (1, get_pHash (path));

    if (!query.exec ())
        return false;

    forever {
        auto next = query.next ();
        if (!next.ok)
            return false;
        if (!next.has_data)
            break;

        SyncJournalFileRecord rec;
        fill_file_record_from_get_query (rec, *query);
        if (!rec._path.starts_with (path) || rec._path.index_of ("/", path.size () + 1) > 0) {
            q_warning (lc_db) << "hash collision" << path << rec.path ();
            continue;
        }
        row_callback (rec);
    }

    return true;
}

int SyncJournalDb.get_file_record_count () {
    QMutexLocker locker (&_mutex);

    SqlQuery query (_db);
    query.prepare ("SELECT COUNT (*) FROM metadata");

    if (!query.exec ()) {
        return -1;
    }

    if (query.next ().has_data) {
        int count = query.int_value (0);
        return count;
    }

    return -1;
}

bool SyncJournalDb.update_file_record_checksum (string &filename,
    const QByteArray &content_checksum,
    const QByteArray &content_checksum_type) {
    QMutexLocker locker (&_mutex);

    q_c_info (lc_db) << "Updating file checksum" << filename << content_checksum << content_checksum_type;

    const int64 phash = get_pHash (filename.to_utf8 ());
    if (!check_connect ()) {
        q_c_warning (lc_db) << "Failed to connect database.";
        return false;
    }

    int checksum_type_id = map_checksum_type (content_checksum_type);

    const auto query = _query_manager.get (PreparedSqlQueryManager.Set_file_record_checksum_query, QByteArrayLiteral ("UPDATE metadata"
                                                                                                                " SET content_checksum = ?2, content_checksum_type_id = ?3"
                                                                                                                " WHERE phash == ?1;"),
        _db);
    if (!query) {
        return false;
    }
    query.bind_value (1, phash);
    query.bind_value (2, content_checksum);
    query.bind_value (3, checksum_type_id);
    return query.exec ();
}

bool SyncJournalDb.update_local_metadata (string &filename,
    int64 modtime, int64 size, uint64 inode)
 {
    QMutexLocker locker (&_mutex);

    q_c_info (lc_db) << "Updating local metadata for:" << filename << modtime << size << inode;

    const int64 phash = get_pHash (filename.to_utf8 ());
    if (!check_connect ()) {
        q_c_warning (lc_db) << "Failed to connect database.";
        return false;
    }

    const auto query = _query_manager.get (PreparedSqlQueryManager.Set_file_record_local_metadata_query, QByteArrayLiteral ("UPDATE metadata"
                                                                                                                     " SET inode=?2, modtime=?3, filesize=?4"
                                                                                                                     " WHERE phash == ?1;"),
        _db);
    if (!query) {
        return false;
    }

    query.bind_value (1, phash);
    query.bind_value (2, inode);
    query.bind_value (3, modtime);
    query.bind_value (4, size);
    return query.exec ();
}

Optional<SyncJournalDb.Has_hydrated_dehydrated> SyncJournalDb.has_hydrated_or_dehydrated_files (QByteArray &filename) {
    QMutexLocker locker (&_mutex);
    if (!check_connect ())
        return {};

    const auto query = _query_manager.get (PreparedSqlQueryManager.Count_dehydrated_files_query, QByteArrayLiteral ("SELECT DISTINCT type FROM metadata"
                                                                                                               " WHERE (" IS_PREFIX_PATH_OR_EQUAL ("?1", "path") " OR ?1 == '');"),
        _db);
    if (!query) {
        return {};
    }

    query.bind_value (1, filename);
    if (!query.exec ())
        return {};

    Has_hydrated_dehydrated result;
    forever {
        auto next = query.next ();
        if (!next.ok)
            return {};
        if (!next.has_data)
            break;
        auto type = static_cast<ItemType> (query.int_value (0));
        if (type == ItemTypeFile || type == ItemTypeVirtualFileDehydration)
            result.has_hydrated = true;
        if (type == Item_type_virtual_file || type == Item_type_virtual_file_download)
            result.has_dehydrated = true;
    }

    return result;
}

static void to_download_info (SqlQuery &query, SyncJournalDb.DownloadInfo *res) {
    bool ok = true;
    res._tmpfile = query.string_value (0);
    res._etag = query.ba_value (1);
    res._error_count = query.int_value (2);
    res._valid = ok;
}

static bool delete_batch (SqlQuery &query, QStringList &entries, string &name) {
    if (entries.is_empty ())
        return true;

    q_c_debug (lc_db) << "Removing stale" << name << "entries:" << entries.join (QStringLiteral (", "));
    // FIXME : Was ported from exec_batch, check if correct!
    foreach (string &entry, entries) {
        query.reset_and_clear_bindings ();
        query.bind_value (1, entry);
        if (!query.exec ()) {
            return false;
        }
    }

    return true;
}

SyncJournalDb.DownloadInfo SyncJournalDb.get_download_info (string &file) {
    QMutexLocker locker (&_mutex);

    DownloadInfo res;

    if (check_connect ()) {
        const auto query = _query_manager.get (PreparedSqlQueryManager.Get_download_info_query, QByteArrayLiteral ("SELECT tmpfile, etag, errorcount FROM downloadinfo WHERE path=?1"), _db);
        if (!query) {
            return res;
        }

        query.bind_value (1, file);

        if (!query.exec ()) {
            return res;
        }

        if (query.next ().has_data) {
            to_download_info (*query, &res);
        }
    }
    return res;
}

void SyncJournalDb.set_download_info (string &file, SyncJournalDb.DownloadInfo &i) {
    QMutexLocker locker (&_mutex);

    if (!check_connect ()) {
        return;
    }

    if (i._valid) {
        const auto query = _query_manager.get (PreparedSqlQueryManager.Set_download_info_query, QByteArrayLiteral ("INSERT OR REPLACE INTO downloadinfo "
                                                                                                              " (path, tmpfile, etag, errorcount) "
                                                                                                              "VALUES ( ?1 , ?2, ?3, ?4 )"),
            _db);
        if (!query) {
            return;
        }
        query.bind_value (1, file);
        query.bind_value (2, i._tmpfile);
        query.bind_value (3, i._etag);
        query.bind_value (4, i._error_count);
        query.exec ();
    } else {
        const auto query = _query_manager.get (PreparedSqlQueryManager.DeleteDownloadInfoQuery);
        query.bind_value (1, file);
        query.exec ();
    }
}

QVector<SyncJournalDb.DownloadInfo> SyncJournalDb.get_and_delete_stale_download_infos (QSet<string> &keep) {
    QVector<SyncJournalDb.DownloadInfo> empty_result;
    QMutexLocker locker (&_mutex);

    if (!check_connect ()) {
        return empty_result;
    }

    SqlQuery query (_db);
    // The selected values *must* match the ones expected by to_download_info ().
    query.prepare ("SELECT tmpfile, etag, errorcount, path FROM downloadinfo");

    if (!query.exec ()) {
        return empty_result;
    }

    QStringList superfluous_paths;
    QVector<SyncJournalDb.DownloadInfo> deleted_entries;

    while (query.next ().has_data) {
        const string file = query.string_value (3); // path
        if (!keep.contains (file)) {
            superfluous_paths.append (file);
            DownloadInfo info;
            to_download_info (query, &info);
            deleted_entries.append (info);
        }
    }
 {
        const auto query = _query_manager.get (PreparedSqlQueryManager.DeleteDownloadInfoQuery);
        if (!delete_batch (*query, superfluous_paths, QStringLiteral ("downloadinfo"))) {
            return empty_result;
        }
    }

    return deleted_entries;
}

int SyncJournalDb.download_info_count () {
    int re = 0;

    QMutexLocker locker (&_mutex);
    if (check_connect ()) {
        SqlQuery query ("SELECT count (*) FROM downloadinfo", _db);

        if (!query.exec ()) {
            sql_fail (QStringLiteral ("Count number of downloadinfo entries failed"), query);
        }
        if (query.next ().has_data) {
            re = query.int_value (0);
        }
    }
    return re;
}

SyncJournalDb.UploadInfo SyncJournalDb.get_upload_info (string &file) {
    QMutexLocker locker (&_mutex);

    UploadInfo res;

    if (check_connect ()) {
        const auto query = _query_manager.get (PreparedSqlQueryManager.Get_upload_info_query, QByteArrayLiteral ("SELECT chunk, transferid, errorcount, size, modtime, content_checksum FROM "
                                                                                                            "uploadinfo WHERE path=?1"),
            _db);
        if (!query) {
            return res;
        }
        query.bind_value (1, file);

        if (!query.exec ()) {
            return res;
        }

        if (query.next ().has_data) {
            bool ok = true;
            res._chunk = query.int_value (0);
            res._transferid = query.int64Value (1);
            res._error_count = query.int_value (2);
            res._size = query.int64Value (3);
            res._modtime = query.int64Value (4);
            res._content_checksum = query.ba_value (5);
            res._valid = ok;
        }
    }
    return res;
}

void SyncJournalDb.set_upload_info (string &file, SyncJournalDb.UploadInfo &i) {
    QMutexLocker locker (&_mutex);

    if (!check_connect ()) {
        return;
    }

    if (i._valid) {
        const auto query = _query_manager.get (PreparedSqlQueryManager.Set_upload_info_query, QByteArrayLiteral ("INSERT OR REPLACE INTO uploadinfo "
                                                                                                            " (path, chunk, transferid, errorcount, size, modtime, content_checksum) "
                                                                                                            "VALUES ( ?1 , ?2, ?3 , ?4 ,  ?5, ?6 , ?7 )"),
            _db);
        if (!query) {
            return;
        }

        query.bind_value (1, file);
        query.bind_value (2, i._chunk);
        query.bind_value (3, i._transferid);
        query.bind_value (4, i._error_count);
        query.bind_value (5, i._size);
        query.bind_value (6, i._modtime);
        query.bind_value (7, i._content_checksum);

        if (!query.exec ()) {
            return;
        }
    } else {
        const auto query = _query_manager.get (PreparedSqlQueryManager.DeleteUploadInfoQuery);
        query.bind_value (1, file);

        if (!query.exec ()) {
            return;
        }
    }
}

QVector<uint> SyncJournalDb.delete_stale_upload_infos (QSet<string> &keep) {
    QMutexLocker locker (&_mutex);
    QVector<uint> ids;

    if (!check_connect ()) {
        return ids;
    }

    SqlQuery query (_db);
    query.prepare ("SELECT path,transferid FROM uploadinfo");

    if (!query.exec ()) {
        return ids;
    }

    QStringList superfluous_paths;

    while (query.next ().has_data) {
        const string file = query.string_value (0);
        if (!keep.contains (file)) {
            superfluous_paths.append (file);
            ids.append (query.int_value (1));
        }
    }

    const auto delete_upload_info_query = _query_manager.get (PreparedSqlQueryManager.DeleteUploadInfoQuery);
    delete_batch (*delete_upload_info_query, superfluous_paths, QStringLiteral ("uploadinfo"));
    return ids;
}

SyncJournalErrorBlacklistRecord SyncJournalDb.error_blacklist_entry (string &file) {
    QMutexLocker locker (&_mutex);
    SyncJournalErrorBlacklistRecord entry;

    if (file.is_empty ())
        return entry;

    if (check_connect ()) {
        const auto query = _query_manager.get (PreparedSqlQueryManager.GetErrorBlacklistQuery);
        query.bind_value (1, file);
        if (query.exec ()) {
            if (query.next ().has_data) {
                entry._last_try_etag = query.ba_value (0);
                entry._last_try_modtime = query.int64Value (1);
                entry._retry_count = query.int_value (2);
                entry._error_string = query.string_value (3);
                entry._last_try_time = query.int64Value (4);
                entry._ignore_duration = query.int64Value (5);
                entry._rename_target = query.string_value (6);
                entry._error_category = static_cast<SyncJournalErrorBlacklistRecord.Category> (
                    query.int_value (7));
                entry._request_id = query.ba_value (8);
                entry._file = file;
            }
        }
    }

    return entry;
}

bool SyncJournalDb.delete_stale_error_blacklist_entries (QSet<string> &keep) {
    QMutexLocker locker (&_mutex);

    if (!check_connect ()) {
        return false;
    }

    SqlQuery query (_db);
    query.prepare ("SELECT path FROM blacklist");

    if (!query.exec ()) {
        return false;
    }

    QStringList superfluous_paths;

    while (query.next ().has_data) {
        const string file = query.string_value (0);
        if (!keep.contains (file)) {
            superfluous_paths.append (file);
        }
    }

    SqlQuery del_query (_db);
    del_query.prepare ("DELETE FROM blacklist WHERE path = ?");
    return delete_batch (del_query, superfluous_paths, QStringLiteral ("blacklist"));
}

void SyncJournalDb.delete_stale_flags_entries () {
    QMutexLocker locker (&_mutex);
    if (!check_connect ())
        return;

    SqlQuery del_query ("DELETE FROM flags WHERE path != '' AND path NOT IN (SELECT path from metadata);", _db);
    del_query.exec ();
}

int SyncJournalDb.error_black_list_entry_count () {
    int re = 0;

    QMutexLocker locker (&_mutex);
    if (check_connect ()) {
        SqlQuery query ("SELECT count (*) FROM blacklist", _db);

        if (!query.exec ()) {
            sql_fail (QStringLiteral ("Count number of blacklist entries failed"), query);
        }
        if (query.next ().has_data) {
            re = query.int_value (0);
        }
    }
    return re;
}

int SyncJournalDb.wipe_error_blacklist () {
    QMutexLocker locker (&_mutex);
    if (check_connect ()) {
        SqlQuery query (_db);

        query.prepare ("DELETE FROM blacklist");

        if (!query.exec ()) {
            sql_fail (QStringLiteral ("Deletion of whole blacklist failed"), query);
            return -1;
        }
        return query.num_rows_affected ();
    }
    return -1;
}

void SyncJournalDb.wipe_error_blacklist_entry (string &file) {
    if (file.is_empty ()) {
        return;
    }

    QMutexLocker locker (&_mutex);
    if (check_connect ()) {
        SqlQuery query (_db);

        query.prepare ("DELETE FROM blacklist WHERE path=?1");
        query.bind_value (1, file);
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("Deletion of blacklist item failed."), query);
        }
    }
}

void SyncJournalDb.wipe_error_blacklist_category (SyncJournalErrorBlacklistRecord.Category category) {
    QMutexLocker locker (&_mutex);
    if (check_connect ()) {
        SqlQuery query (_db);

        query.prepare ("DELETE FROM blacklist WHERE error_category=?1");
        query.bind_value (1, category);
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("Deletion of blacklist category failed."), query);
        }
    }
}

void SyncJournalDb.set_error_blacklist_entry (SyncJournalErrorBlacklistRecord &item) {
    QMutexLocker locker (&_mutex);

    q_c_info (lc_db) << "Setting blacklist entry for" << item._file << item._retry_count
                 << item._error_string << item._last_try_time << item._ignore_duration
                 << item._last_try_modtime << item._last_try_etag << item._rename_target
                 << item._error_category;

    if (!check_connect ()) {
        return;
    }

    const auto query = _query_manager.get (PreparedSqlQueryManager.Set_error_blacklist_query, QByteArrayLiteral ("INSERT OR REPLACE INTO blacklist "
                                                                                                            " (path, last_try_etag, last_try_modtime, retrycount, errorstring, last_try_time, ignore_duration, rename_target, error_category, request_id) "
                                                                                                            "VALUES ( ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)"),
        _db);
    if (!query) {
        return;
    }

    query.bind_value (1, item._file);
    query.bind_value (2, item._last_try_etag);
    query.bind_value (3, item._last_try_modtime);
    query.bind_value (4, item._retry_count);
    query.bind_value (5, item._error_string);
    query.bind_value (6, item._last_try_time);
    query.bind_value (7, item._ignore_duration);
    query.bind_value (8, item._rename_target);
    query.bind_value (9, item._error_category);
    query.bind_value (10, item._request_id);
    query.exec ();
}

QVector<SyncJournalDb.Poll_info> SyncJournalDb.get_poll_infos () {
    QMutexLocker locker (&_mutex);

    QVector<SyncJournalDb.Poll_info> res;

    if (!check_connect ())
        return res;

    SqlQuery query ("SELECT path, modtime, filesize, pollpath FROM async_poll", _db);

    if (!query.exec ()) {
        return res;
    }

    while (query.next ().has_data) {
        Poll_info info;
        info._file = query.string_value (0);
        info._modtime = query.int64Value (1);
        info._file_size = query.int64Value (2);
        info._url = query.string_value (3);
        res.append (info);
    }
    return res;
}

void SyncJournalDb.set_poll_info (SyncJournalDb.Poll_info &info) {
    QMutexLocker locker (&_mutex);
    if (!check_connect ()) {
        return;
    }

    if (info._url.is_empty ()) {
        q_c_debug (lc_db) << "Deleting Poll job" << info._file;
        SqlQuery query ("DELETE FROM async_poll WHERE path=?", _db);
        query.bind_value (1, info._file);
        query.exec ();
    } else {
        SqlQuery query ("INSERT OR REPLACE INTO async_poll (path, modtime, filesize, pollpath) VALUES ( ? , ? , ? , ? )", _db);
        query.bind_value (1, info._file);
        query.bind_value (2, info._modtime);
        query.bind_value (3, info._file_size);
        query.bind_value (4, info._url);
        query.exec ();
    }
}

QStringList SyncJournalDb.get_selective_sync_list (SyncJournalDb.Selective_sync_list_type type, bool *ok) {
    QStringList result;
    ASSERT (ok);

    QMutexLocker locker (&_mutex);
    if (!check_connect ()) {
        *ok = false;
        return result;
    }

    const auto query = _query_manager.get (PreparedSqlQueryManager.Get_selective_sync_list_query, QByteArrayLiteral ("SELECT path FROM selectivesync WHERE type=?1"), _db);
    if (!query) {
        *ok = false;
        return result;
    }

    query.bind_value (1, int (type));
    if (!query.exec ()) {
        *ok = false;
        return result;
    }
    forever {
        auto next = query.next ();
        if (!next.ok) {
            *ok = false;
            return result;
        }
        if (!next.has_data)
            break;

        auto entry = query.string_value (0);
        if (!entry.ends_with (QLatin1Char ('/'))) {
            entry.append (QLatin1Char ('/'));
        }
        result.append (entry);
    }
    *ok = true;

    return result;
}

void SyncJournalDb.set_selective_sync_list (SyncJournalDb.Selective_sync_list_type type, QStringList &list) {
    QMutexLocker locker (&_mutex);
    if (!check_connect ()) {
        return;
    }

    start_transaction ();

    //first, delete all entries of this type
    SqlQuery del_query ("DELETE FROM selectivesync WHERE type == ?1", _db);
    del_query.bind_value (1, int (type));
    if (!del_query.exec ()) {
        q_c_warning (lc_db) << "SQL error when deleting selective sync list" << list << del_query.error ();
    }

    SqlQuery ins_query ("INSERT INTO selectivesync VALUES (?1, ?2)", _db);
    foreach (auto &path, list) {
        ins_query.reset_and_clear_bindings ();
        ins_query.bind_value (1, path);
        ins_query.bind_value (2, int (type));
        if (!ins_query.exec ()) {
            q_c_warning (lc_db) << "SQL error when inserting into selective sync" << type << path << del_query.error ();
        }
    }

    commit_internal (QStringLiteral ("set_selective_sync_list"));
}

void SyncJournalDb.avoid_renames_on_next_sync (QByteArray &path) {
    QMutexLocker locker (&_mutex);

    if (!check_connect ()) {
        return;
    }

    SqlQuery query (_db);
    query.prepare ("UPDATE metadata SET fileid = '', inode = '0' WHERE " IS_PREFIX_PATH_OR_EQUAL ("?1", "path"));
    query.bind_value (1, path);
    query.exec ();

    // We also need to remove the ETags so the update phase refreshes the directory paths
    // on the next sync
    schedule_path_for_remote_discovery (path);
}

void SyncJournalDb.schedule_path_for_remote_discovery (QByteArray &file_name) {
    QMutexLocker locker (&_mutex);

    if (!check_connect ()) {
        return;
    }

    // Remove trailing slash
    auto argument = file_name;
    if (argument.ends_with ('/'))
        argument.chop (1);

    SqlQuery query (_db);
    // This query will match entries for which the path is a prefix of file_name
    // Note : CSYNC_FTW_TYPE_DIR == 2
    query.prepare ("UPDATE metadata SET md5='_invalid_' WHERE " IS_PREFIX_PATH_OR_EQUAL ("path", "?1") " AND type == 2;");
    query.bind_value (1, argument);
    query.exec ();

    // Prevent future overwrite of the etags of this folder and all
    // parent folders for this sync
    argument.append ('/');
    _etag_storage_filter.append (argument);
}

void SyncJournalDb.clear_etag_storage_filter () {
    _etag_storage_filter.clear ();
}

void SyncJournalDb.force_remote_discovery_next_sync () {
    QMutexLocker locker (&_mutex);

    if (!check_connect ()) {
        return;
    }

    force_remote_discovery_next_sync_locked ();
}

void SyncJournalDb.force_remote_discovery_next_sync_locked () {
    q_c_info (lc_db) << "Forcing remote re-discovery by deleting folder Etags";
    SqlQuery delete_remote_folder_etags_query (_db);
    delete_remote_folder_etags_query.prepare ("UPDATE metadata SET md5='_invalid_' WHERE type=2;");
    delete_remote_folder_etags_query.exec ();
}

QByteArray SyncJournalDb.get_checksum_type (int checksum_type_id) {
    QMutexLocker locker (&_mutex);
    if (!check_connect ()) {
        return QByteArray ();
    }

    // Retrieve the id
    const auto query = _query_manager.get (PreparedSqlQueryManager.Get_checksum_type_query, QByteArrayLiteral ("SELECT name FROM checksumtype WHERE id=?1"), _db);
    if (!query) {
        return {};
    }
    query.bind_value (1, checksum_type_id);
    if (!query.exec ()) {
        return QByteArray ();
    }

    if (!query.next ().has_data) {
        q_c_warning (lc_db) << "No checksum type mapping found for" << checksum_type_id;
        return QByteArray ();
    }
    return query.ba_value (0);
}

int SyncJournalDb.map_checksum_type (QByteArray &checksum_type) {
    if (checksum_type.is_empty ()) {
        return 0;
    }

    auto it =  _checksym_type_cache.find (checksum_type);
    if (it != _checksym_type_cache.end ())
        return *it;

    // Ensure the checksum type is in the db {
        const auto query = _query_manager.get (PreparedSqlQueryManager.Insert_checksum_type_query, QByteArrayLiteral ("INSERT OR IGNORE INTO checksumtype (name) VALUES (?1)"), _db);
        if (!query) {
            return 0;
        }
        query.bind_value (1, checksum_type);
        if (!query.exec ()) {
            return 0;
        }
    }

    // Retrieve the id {
        const auto query = _query_manager.get (PreparedSqlQueryManager.Get_checksum_type_id_query, QByteArrayLiteral ("SELECT id FROM checksumtype WHERE name=?1"), _db);
        if (!query) {
            return 0;
        }
        query.bind_value (1, checksum_type);
        if (!query.exec ()) {
            return 0;
        }

        if (!query.next ().has_data) {
            q_c_warning (lc_db) << "No checksum type mapping found for" << checksum_type;
            return 0;
        }
        auto value = query.int_value (0);
        _checksym_type_cache[checksum_type] = value;
        return value;
    }
}

QByteArray SyncJournalDb.data_fingerprint () {
    QMutexLocker locker (&_mutex);
    if (!check_connect ()) {
        return QByteArray ();
    }

    const auto query = _query_manager.get (PreparedSqlQueryManager.Get_data_fingerprint_query, QByteArrayLiteral ("SELECT fingerprint FROM datafingerprint"), _db);
    if (!query) {
        return QByteArray ();
    }

    if (!query.exec ()) {
        return QByteArray ();
    }

    if (!query.next ().has_data) {
        return QByteArray ();
    }
    return query.ba_value (0);
}

void SyncJournalDb.set_data_fingerprint (QByteArray &data_fingerprint) {
    QMutexLocker locker (&_mutex);
    if (!check_connect ()) {
        return;
    }

    const auto set_data_fingerprint_query1 = _query_manager.get (PreparedSqlQueryManager.Set_data_fingerprint_query1, QByteArrayLiteral ("DELETE FROM datafingerprint;"), _db);
    const auto set_data_fingerprint_query2 = _query_manager.get (PreparedSqlQueryManager.Set_data_fingerprint_query2, QByteArrayLiteral ("INSERT INTO datafingerprint (fingerprint) VALUES (?1);"), _db);
    if (!set_data_fingerprint_query1 || !set_data_fingerprint_query2) {
        return;
    }

    set_data_fingerprint_query1.exec ();

    set_data_fingerprint_query2.bind_value (1, data_fingerprint);
    set_data_fingerprint_query2.exec ();
}

void SyncJournalDb.set_conflict_record (Conflict_record &record) {
    QMutexLocker locker (&_mutex);
    if (!check_connect ())
        return;

    const auto query = _query_manager.get (PreparedSqlQueryManager.Set_conflict_record_query, QByteArrayLiteral ("INSERT OR REPLACE INTO conflicts "
                                                                                                            " (path, base_file_id, base_modtime, base_etag, base_path) "
                                                                                                            "VALUES (?1, ?2, ?3, ?4, ?5);"),
        _db);
    ASSERT (query)
    query.bind_value (1, record.path);
    query.bind_value (2, record.base_file_id);
    query.bind_value (3, record.base_modtime);
    query.bind_value (4, record.base_etag);
    query.bind_value (5, record.initial_base_path);
    ASSERT (query.exec ())
}

Conflict_record SyncJournalDb.conflict_record (QByteArray &path) {
    Conflict_record entry;

    QMutexLocker locker (&_mutex);
    if (!check_connect ()) {
        return entry;
    }
    const auto query = _query_manager.get (PreparedSqlQueryManager.Get_conflict_record_query, QByteArrayLiteral ("SELECT base_file_id, base_modtime, base_etag, base_path FROM conflicts WHERE path=?1;"), _db);
    ASSERT (query)
    query.bind_value (1, path);
    ASSERT (query.exec ())
    if (!query.next ().has_data)
        return entry;

    entry.path = path;
    entry.base_file_id = query.ba_value (0);
    entry.base_modtime = query.int64Value (1);
    entry.base_etag = query.ba_value (2);
    entry.initial_base_path = query.ba_value (3);
    return entry;
}

void SyncJournalDb.delete_conflict_record (QByteArray &path) {
    QMutexLocker locker (&_mutex);
    if (!check_connect ())
        return;

    const auto query = _query_manager.get (PreparedSqlQueryManager.Delete_conflict_record_query, QByteArrayLiteral ("DELETE FROM conflicts WHERE path=?1;"), _db);
    ASSERT (query)
    query.bind_value (1, path);
    ASSERT (query.exec ())
}

QByte_array_list SyncJournalDb.conflict_record_paths () {
    QMutexLocker locker (&_mutex);
    if (!check_connect ())
        return {};

    SqlQuery query (_db);
    query.prepare ("SELECT path FROM conflicts");
    ASSERT (query.exec ());

    QByte_array_list paths;
    while (query.next ().has_data)
        paths.append (query.ba_value (0));

    return paths;
}

QByteArray SyncJournalDb.conflict_file_base_name (QByteArray &conflict_name) {
    auto conflict = conflict_record (conflict_name);
    QByteArray result;
    if (conflict.is_valid ()) {
        get_file_records_by_file_id (conflict.base_file_id, [&result] (SyncJournalFileRecord &record) {
            if (!record._path.is_empty ())
                result = record._path;
        });
    }

    if (result.is_empty ()) {
        result = Utility.conflict_file_base_name_from_pattern (conflict_name);
    }
    return result;
}

void SyncJournalDb.clear_file_table () {
    QMutexLocker lock (&_mutex);
    SqlQuery query (_db);
    query.prepare ("DELETE FROM metadata;");
    query.exec ();
}

void SyncJournalDb.mark_virtual_file_for_download_recursively (QByteArray &path) {
    QMutexLocker lock (&_mutex);
    if (!check_connect ())
        return;

    static_assert (Item_type_virtual_file == 4 && Item_type_virtual_file_download == 5, "");
    SqlQuery query ("UPDATE metadata SET type=5 WHERE "
                   " (" IS_PREFIX_PATH_OF ("?1", "path") " OR ?1 == '') "
                   "AND type=4;", _db);
    query.bind_value (1, path);
    query.exec ();

    // We also must make sure we do not read the files from the database (same logic as in schedule_path_for_remote_discovery)
    // This includes all the parents up to the root, but also all the directory within the selected dir.
    static_assert (ItemTypeDirectory == 2, "");
    query.prepare ("UPDATE metadata SET md5='_invalid_' WHERE "
                  " (" IS_PREFIX_PATH_OF ("?1", "path") " OR ?1 == '' OR " IS_PREFIX_PATH_OR_EQUAL ("path", "?1") ") AND type == 2;");
    query.bind_value (1, path);
    query.exec ();
}

Optional<PinState> SyncJournalDb.PinStateInterface.raw_for_path (QByteArray &path) {
    QMutexLocker lock (&_db._mutex);
    if (!_db.check_connect ())
        return {};

    const auto query = _db._query_manager.get (PreparedSqlQueryManager.Get_raw_pin_state_query, QByteArrayLiteral ("SELECT pin_state FROM flags WHERE path == ?1;"), _db._db);
    ASSERT (query)
    query.bind_value (1, path);
    query.exec ();

    auto next = query.next ();
    if (!next.ok)
        return {};
    // no-entry means Inherited
    if (!next.has_data)
        return PinState.Inherited;

    return static_cast<PinState> (query.int_value (0));
}

Optional<PinState> SyncJournalDb.PinStateInterface.effective_for_path (QByteArray &path) {
    QMutexLocker lock (&_db._mutex);
    if (!_db.check_connect ())
        return {};

    const auto query = _db._query_manager.get (PreparedSqlQueryManager.Get_effective_pin_state_query, QByteArrayLiteral ("SELECT pin_state FROM flags WHERE"
                                                                                                                    // explicitly allow "" to represent the root path
                                                                                                                    // (it'd be great if paths started with a / and "/" could be the root)
                                                                                                                    " (" IS_PREFIX_PATH_OR_EQUAL ("path", "?1") " OR path == '')"
                                                                                                                                                               " AND pin_state is not null AND pin_state != 0"
                                                                                                                                                               " ORDER BY length (path) DESC LIMIT 1;"),
        _db._db);
    ASSERT (query)
    query.bind_value (1, path);
    query.exec ();

    auto next = query.next ();
    if (!next.ok)
        return {};
    // If the root path has no setting, assume AlwaysLocal
    if (!next.has_data)
        return PinState.AlwaysLocal;

    return static_cast<PinState> (query.int_value (0));
}

Optional<PinState> SyncJournalDb.PinStateInterface.effective_for_path_recursive (QByteArray &path) {
    // Get the item's effective pin state. We'll compare subitem's pin states
    // against this.
    const auto base_pin = effective_for_path (path);
    if (!base_pin)
        return {};

    QMutexLocker lock (&_db._mutex);
    if (!_db.check_connect ())
        return {};

    // Find all the non-inherited pin states below the item
    const auto query = _db._query_manager.get (PreparedSqlQueryManager.Get_sub_pins_query, QByteArrayLiteral ("SELECT DISTINCT pin_state FROM flags WHERE"
                                                                                                          " (" IS_PREFIX_PATH_OF ("?1", "path") " OR ?1 == '')"
                                                                                                                                               " AND pin_state is not null and pin_state != 0;"),
        _db._db);
    ASSERT (query)
    query.bind_value (1, path);
    query.exec ();

    // Check if they are all identical
    forever {
        auto next = query.next ();
        if (!next.ok)
            return {};
        if (!next.has_data)
            break;
        const auto sub_pin = static_cast<PinState> (query.int_value (0));
        if (sub_pin != *base_pin)
            return PinState.Inherited;
    }

    return *base_pin;
}

void SyncJournalDb.PinStateInterface.set_for_path (QByteArray &path, PinState state) {
    QMutexLocker lock (&_db._mutex);
    if (!_db.check_connect ())
        return;

    const auto query = _db._query_manager.get (PreparedSqlQueryManager.Set_pin_state_query, QByteArrayLiteral (
                                                                                             // If we had sqlite >=3.24.0 everywhere this could be an upsert,
                                                                                             // making further flags columns easy
                                                                                             //"INSERT INTO flags (path, pin_state) VALUES (?1, ?2)"
                                                                                             //" ON CONFLICT (path) DO UPDATE SET pin_state=?2;"),
                                                                                             // Simple version that doesn't work nicely with multiple columns:
                                                                                             "INSERT OR REPLACE INTO flags (path, pin_state) VALUES (?1, ?2);"),
        _db._db);
    ASSERT (query)
    query.bind_value (1, path);
    query.bind_value (2, state);
    query.exec ();
}

void SyncJournalDb.PinStateInterface.wipe_for_path_and_below (QByteArray &path) {
    QMutexLocker lock (&_db._mutex);
    if (!_db.check_connect ())
        return;

    const auto query = _db._query_manager.get (PreparedSqlQueryManager.Wipe_pin_state_query, QByteArrayLiteral ("DELETE FROM flags WHERE "
                                                                                                            // Allow "" to delete everything
                                                                                                            " (" IS_PREFIX_PATH_OR_EQUAL ("?1", "path") " OR ?1 == '');"),
        _db._db);
    ASSERT (query)
    query.bind_value (1, path);
    query.exec ();
}

Optional<QVector<QPair<QByteArray, PinState>>>
SyncJournalDb.PinStateInterface.raw_list () {
    QMutexLocker lock (&_db._mutex);
    if (!_db.check_connect ())
        return {};

    SqlQuery query ("SELECT path, pin_state FROM flags;", _db._db);
    query.exec ();

    QVector<QPair<QByteArray, PinState>> result;
    forever {
        auto next = query.next ();
        if (!next.ok)
            return {};
        if (!next.has_data)
            break;
        result.append ({
            query.ba_value (0), static_cast<PinState> (query.int_value (1))
        });
    }
    return result;
}

SyncJournalDb.PinStateInterface SyncJournalDb.internal_pin_states () {
    return {this};
}

void SyncJournalDb.commit (string &context, bool start_trans) {
    QMutexLocker lock (&_mutex);
    commit_internal (context, start_trans);
}

void SyncJournalDb.commit_if_needed_and_start_new_transaction (string &context) {
    QMutexLocker lock (&_mutex);
    if (_transaction == 1) {
        commit_internal (context, true);
    } else {
        start_transaction ();
    }
}

bool SyncJournalDb.open () {
    QMutexLocker lock (&_mutex);
    return check_connect ();
}

bool SyncJournalDb.is_open () {
    QMutexLocker lock (&_mutex);
    return _db.is_open ();
}

void SyncJournalDb.commit_internal (string &context, bool start_trans) {
    q_c_debug (lc_db) << "Transaction commit" << context << (start_trans ? "and starting new transaction" : "");
    commit_transaction ();

    if (start_trans) {
        start_transaction ();
    }
}

SyncJournalDb.~SyncJournalDb () {
    close ();
}

bool operator== (SyncJournalDb.DownloadInfo &lhs,
    const SyncJournalDb.DownloadInfo &rhs) {
    return lhs._error_count == rhs._error_count
        && lhs._etag == rhs._etag
        && lhs._tmpfile == rhs._tmpfile
        && lhs._valid == rhs._valid;
}

bool operator== (SyncJournalDb.UploadInfo &lhs,
    const SyncJournalDb.UploadInfo &rhs) {
    return lhs._error_count == rhs._error_count
        && lhs._chunk == rhs._chunk
        && lhs._modtime == rhs._modtime
        && lhs._valid == rhs._valid
        && lhs._size == rhs._size
        && lhs._transferid == rhs._transferid
        && lhs._content_checksum == rhs._content_checksum;
}

} // namespace Occ
