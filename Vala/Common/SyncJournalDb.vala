/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

//  #include <QCryptographicHash>
//  #include <QLoggingCategory>
//  #include <QElapsedTimer>
//  #include <QDir>
//  #includee3;
//  #include <cstring>

//  #include <QMutex>
//  #include <functional>

namespace Occ {

/***********************************************************
@brief Class that handles the sync database

This class is thread safe. All public functions lock the mutex.
@ingroup libsync
***********************************************************/
class SyncJournalDb : GLib.Object {

    const string GET_FILE_RECORD_QUERY
        = "SELECT path, inode, modtime, type, md5, fileid, remote_perm, filesize,"
        + "  ignored_children_remote, contentchecksumtype.name || ':' || content_checksum, e2e_mangled_name, is_e2e_encrypted "
        + " FROM metadata"
        + "  LEFT JOIN checksumtype as contentchecksumtype ON metadata.content_checksum_type_id == contentchecksumtype.identifier";



    /***********************************************************
    Return value for has_hydrated_or_dehydrated_files ()
    ***********************************************************/
    public class HasHydratedDehydrated {
        bool has_hydrated = false;
        bool has_dehydrated = false;
    }


    /***********************************************************
    ***********************************************************/
    public class DownloadInfo {
        string tmpfile;
        GLib.ByteArray etag;
        int error_count = 0;
        bool valid = false;
    }


    /***********************************************************
    ***********************************************************/
    public class UploadInfo {
        int chunk = 0;
        uint32 transferid = 0;
        int64 size = 0;
        int64 modtime = 0;
        int error_count = 0;
        bool valid = false;
        GLib.ByteArray content_checksum;
        /***********************************************************
        Returns true if this entry refers to a chunked upload that can be continued.
        (As opposed to a small file transfer which is stored in the database so we can detect the case
        when the upload succeeded, but the connection was dropped before we got the answer)
        ***********************************************************/
        bool is_chunked () {
            return this.transferid != 0;
        }
    }


    /***********************************************************
    ***********************************************************/
    public class PollInfo {
        string file; // The relative path of a file
        string url; // the poll url. (This pollinfo is invalid if this.url is empty)
        int64 modtime; // The modtime of the file being uploaded
        int64 file_size;
    }


    /***********************************************************
    Grouping for all functions relating to pin states,

    Use internal_pin_states () to get at them.

    OCSYNC_EXPORT
    ***********************************************************/
    public class PinStateInterface {

        SyncJournalDb database;

        //  PinStateInterface (PinStateInterface &) = delete;
        //  PinStateInterface (PinStateInterface &&) = delete;

        /***********************************************************
        Gets the PinState for the path without considering parents.

        If a path has no explicit PinState "PinState.INHERITED" is returned.

        The path should not have a trailing slash.
        It's valid to use the root path "".

        Returns none on database error.
        ***********************************************************/
        Optional<PinState> raw_for_path (GLib.ByteArray path) {
            QMutexLocker lock = new QMutexLocker (this.database.mutex);
            if (!this.database.check_connect ())
                return {};
    
            PreparedSqlQuery query = this.database.query_manager.get (
                PreparedSqlQueryManager.Get_raw_pin_state_query,
                "SELECT pin_state FROM flags WHERE path == ?1;",
                this.database.database);
            //  ASSERT (query)
            query.bind_value (1, path);
            query.exec ();
    
            var next = query.next ();
            if (!next.ok)
                return {};
            // no-entry means PinState.INHERITED
            if (!next.has_data)
                return PinState.PinState.INHERITED;
    
            return static_cast<PinState> (query.int_value (0));
        }
    

        /***********************************************************
        Gets the PinState for the path after inheriting from parents.

        If the exact path has no entry or has an PinState.INHERITED state,
        the state of the closest parent path is returned.

        The path should not have a trailing slash.
        It's valid to use the root path "".

        Never returns PinState.PinState.INHERITED. If the root is "PinState.INHERITED"
        or there's an error, "PinState.ALWAYS_LOCAL" is returned.

        Returns none on database error.
        ***********************************************************/
        Optional<PinState> effective_for_path (GLib.ByteArray path) {
            QMutexLocker lock = new QMutexLocker (this.database.mutex);
            if (!this.database.check_connect ())
                return {};
    
            PreparedSqlQuery query = this.database.query_manager.get (
                PreparedSqlQueryManager.Get_effective_pin_state_query,
                "SELECT pin_state FROM flags WHERE"
                // explicitly allow "" to represent the root path
                // (it'd be great if paths started with a / and "/" could be the root)
                + " (" + is_prefix_path_or_equal ("path", "?1") + " OR path == '')"
                + " AND pin_state is not null AND pin_state != 0"
                + " ORDER BY length (path) DESC LIMIT 1;",
                this.database.database);
            //  ASSERT (query)
            query.bind_value (1, path);
            query.exec ();
    
            var next = query.next ();
            if (!next.ok)
                return {};
            // If the root path has no setting, assume PinState.ALWAYS_LOCAL
            if (!next.has_data)
                return PinState.PinState.ALWAYS_LOCAL;
    
            return static_cast<PinState> (query.int_value (0));
        }
    

        /***********************************************************
        Like effective_for_path () but also considers subitem pin states.

        If the path's pin state and all subitem's pin states are identical
        then that pin state will be returned.

        If some subitem's pin state is different from the path's state,
        PinState.PinState.INHERITED will be returned. PinState.INHERITED isn't returned in
        any other cases.

        It's valid to use the root path "".
        Returns none on database error.
        ***********************************************************/
        Optional<PinState> effective_for_path_recursive (GLib.ByteArray path) {
            // Get the item's effective pin state. We'll compare subitem's pin states
            // against this.
            PreparedSqlQuery base_pin = effective_for_path (path);
            if (!base_pin)
                return {};
    
            QMutexLocker lock = new QMutexLocker (this.database.mutex);
            if (!this.database.check_connect ())
                return {};
    
            // Find all the non-inherited pin states below the item
            PreparedSqlQuery query = this.database.query_manager.get (
                PreparedSqlQueryManager.Get_sub_pins_query,
                "SELECT DISTINCT pin_state FROM flags WHERE"
                + " (" + is_prefix_path_of ("?1", "path") + " OR ?1 == '')"
                + " AND pin_state is not null and pin_state != 0;",
                this.database.database);
            //  ASSERT (query)
            query.bind_value (1, path);
            query.exec ();
    
            // Check if they are all identical
            while (true) {
                var next = query.next ();
                if (!next.ok)
                    return {};
                if (!next.has_data)
                    break;
                PreparedSqlQuery sub_pin = static_cast<PinState> (query.int_value (0));
                if (sub_pin != *base_pin)
                    return PinState.PinState.INHERITED;
            }
    
            return base_pin;
        }
    

        /***********************************************************
        Sets a path's pin state.

        The path should not have a trailing slash.
        It's valid to use the root path "".
        ***********************************************************/
        void for_path (GLib.ByteArray path, PinState state) {
            QMutexLocker lock = new QMutexLocker (this.database.mutex);
            if (!this.database.check_connect ())
                return;
    
            PreparedSqlQuery query = this.database.query_manager.get (
                PreparedSqlQueryManager.Set_pin_state_query,
                // If we had sqlite >=3.24.0 everywhere this could be an upsert,
                // making further flags columns easy
                //"INSERT INTO flags (path, pin_state) VALUES (?1, ?2)"
                //" ON CONFLICT (path) DO UPDATE SET pin_state=?2;"),
                // Simple version that doesn't work nicely with multiple columns:
                "INSERT OR REPLACE INTO flags (path, pin_state) VALUES (?1, ?2);",
                this.database.database);
            //  ASSERT (query)
            query.bind_value (1, path);
            query.bind_value (2, state);
            query.exec ();
        }
    

        /***********************************************************
        Wipes pin states for a path and below.

        Used when the user asks a subtree to have a particular pin state.
        The path should not have a trailing slash.
        The path "" wipes every entry.
        ***********************************************************/
        void wipe_for_path_and_below (GLib.ByteArray path) {
            QMutexLocker lock = new QMutexLocker (this.database.mutex);
            if (!this.database.check_connect ())
                return;
    
            PreparedSqlQuery query = this.database.query_manager.get (
                PreparedSqlQueryManager.Wipe_pin_state_query,
                "DELETE FROM flags WHERE "
                // Allow "" to delete everything
                + " (" + is_prefix_path_or_equal ("?1", "path") + " OR ?1 == '');",
                this.database.database);
            //  ASSERT (query)
            query.bind_value (1, path);
            query.exec ();
        }
    

        /***********************************************************
        Returns list of all paths with their pin state as in the database.
        Returns nothing on database error.
        Note that this will have an entry for "".
        ***********************************************************/
        Optional<GLib.Vector<QPair<GLib.ByteArray, PinState>>> raw_list () {
            QMutexLocker lock = new QMutexLocker (this.database.mutex);
            if (!this.database.check_connect ())
                return {};
    
            SqlQuery query = new SqlQuery ("SELECT path, pin_state FROM flags;", this.database.database);
            query.exec ();
    
            GLib.Vector<QPair<GLib.ByteArray, PinState>> result;
            while (true) {
                var next = query.next ();
                if (!next.ok)
                    return {};
                if (!next.has_data)
                    break;
                result.append ({
                    query.byte_array_value (0), static_cast<PinState> (query.int_value (1))
                });
            }
            return result;
        }
    }


    /***********************************************************
    ***********************************************************/
    private SqlDatabase database;
    private string database_file;

    /***********************************************************
    Public functions are protected with the mutex.
    ***********************************************************/
    private QRecursiveMutex mutex;

    private GLib.HashMap<GLib.ByteArray, int> checksym_type_cache;
    private int transaction;
    private bool metadata_table_is_empty;

    /***********************************************************
    Storing etags to these folders, or their parent folders, is
    filtered out.

    When schedule_path_for_remote_discovery () is called some
    etags to this.invalid_ in the database. If this is done
    during a sync run, a later propagation job might undo that
    by writing the correct etag to the database instead. This
    filter will prevent this write and instead guarantee the
    this.invalid_ etag stays in  place.

    The list is cleared on close () (end of sync ru
    clear_etag_storage_filter () (on_signal_start of sync run).

    The contained paths have a trailing /.
    ***********************************************************/
    private GLib.List<GLib.ByteArray> etag_storage_filter;


    /***********************************************************
    The journal mode to use for the database.

    Typically WAL initially, but may be set to other modes via environment
    variable, for specific filesystems, or when WAL fails in a particular way.
    ***********************************************************/
    private GLib.ByteArray journal_mode;


    /***********************************************************
    ***********************************************************/
    private PreparedSqlQueryManager query_manager;


    /***********************************************************
    Only used for var-test:
    when positive, will decrease the counter for every database operation.
    reaching 0 makes the operation fails
    ***********************************************************/
    public int autotest_fail_counter = -1;


    /***********************************************************
    ***********************************************************/
    public SyncJournalDb (string db_file_path, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.database_file = db_file_path;
        this.transaction = 0;
        this.metadata_table_is_empty = false;
        // Allow forcing the journal mode for debugging
        /*static*/ GLib.ByteArray env_journal_mode = qgetenv ("OWNCLOUD_SQLITE_JOURNAL_MODE");
        this.journal_mode = env_journal_mode;
        if (this.journal_mode.is_empty ()) {
            this.journal_mode = default_journal_mode (this.database_file);
        }
    }


    ~SyncJournalDb () {
        close ();
    }


    /***********************************************************
    Create a journal path for a specific configuration
    ***********************************************************/
    public static string make_database_name (string local_path,
        GLib.Uri remote_url,
        string remote_path,
        string user) {
        string journal_path = ".sync_";

        string key = "%1@%2:%3".arg (user, remote_url.to_string (), remote_path);

        GLib.ByteArray ba = QCryptographicHash.hash (key.to_utf8 (), QCryptographicHash.Md5);
        journal_path += string.from_latin1 (ba.left (6).to_hex ()) + ".db";

        // If it exists already, the path is clearly usable
        GLib.File file = new GLib.File (QDir (local_path).file_path (journal_path));
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
        GLib.warn ("Could not find a writable database path" + file.filename () + file.error_string ());
        return journal_path;
    }


    /***********************************************************
    ***********************************************************/
    static GLib.ByteArray default_journal_mode (string db_path) {
        //  Q_UNUSED (db_path)
        return "WAL";
    }


    /***********************************************************
    Migrate a csync_journal to the new path, if necessary.
    Returns false on error
    ***********************************************************/
    public static bool maybe_migrate_database (string local_path, string absolute_journal_path) {
        const string old_database_name = local_path + ".csync_journal.db";
        if (!FileSystem.file_exists (old_database_name)) {
            return true;
        }
        const string old_database_name_shm = old_database_name + "-shm";
        const string old_database_name_wal = old_database_name + "-wal";

        const string new_database_name = absolute_journal_path;
        const string new_database_name_shm = new_database_name + "-shm";
        const string new_database_name_wal = new_database_name + "-wal";

        // Whenever there is an old database file, migrate it to the new database path.
        // This is done to make switching from older versions to newer versions
        // work correctly even if the user had previously used a new version
        // and therefore already has an (outdated) new-style database file.
        string error;

        if (FileSystem.file_exists (new_database_name)) {
            if (!FileSystem.remove (new_database_name, error)) {
                GLib.warn ("Database migration : Could not remove database file" + new_database_name
                                + "due to" + error);
                return false;
            }
        }
        if (FileSystem.file_exists (new_database_name_wal)) {
            if (!FileSystem.remove (new_database_name_wal, error)) {
                GLib.warn ("Database migration : Could not remove database WAL file" + new_database_name_wal
                                + "due to" + error);
                return false;
            }
        }
        if (FileSystem.file_exists (new_database_name_shm)) {
            if (!FileSystem.remove (new_database_name_shm, error)) {
                GLib.warn ("Database migration : Could not remove database SHM file" + new_database_name_shm
                                + "due to" + error);
                return false;
            }
        }

        if (!FileSystem.rename (old_database_name, new_database_name, error)) {
            GLib.warn ("Database migration : could not rename" + old_database_name
                            + "to" + new_database_name + ":" + error);
            return false;
        }
        if (!FileSystem.rename (old_database_name_wal, new_database_name_wal, error)) {
            GLib.warn ("Database migration : could not rename" + old_database_name_wal
                            + "to" + new_database_name_wal + ":" + error);
            return false;
        }
        if (!FileSystem.rename (old_database_name_shm, new_database_name_shm, error)) {
            GLib.warn ("Database migration : could not rename" + old_database_name_shm
                            + "to" + new_database_name_shm + ":" + error);
            return false;
        }

        GLib.info ("Journal successfully migrated from" + old_database_name + "to" + new_database_name);
        return true;
    }


    /***********************************************************
    To verify that the record could be found check with
    SyncJournalFileRecord.is_valid ()
    ***********************************************************/
    //  public bool get_file_record (string filename, SyncJournalFileRecord record) {
    //      return get_file_record (filename.to_utf8 (), record);
    //  }


    /***********************************************************
    ***********************************************************/
    public bool get_file_record (GLib.ByteArray filename, SyncJournalFileRecord record) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        // Reset the output var in case the caller is reusing it.
        //  Q_ASSERT (record);
        record.path.clear ();
        //  Q_ASSERT (!record.is_valid ());

        if (this.metadata_table_is_empty)
            return true; // no error, yet nothing found (record.is_valid () == false)

        if (!check_connect ())
            return false;

        if (!filename.is_empty ()) {
            PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.Key.GET_FILE_RECORD_QUERY, GET_FILE_RECORD_QUERY + " WHERE phash=?1", this.database);
            if (!query) {
                return false;
            }

            query.bind_value (1, get_pHash (filename));

            if (!query.exec ()) {
                close ();
                return false;
            }

            var next = query.next ();
            if (!next.ok) {
                string err = query.error ();
                GLib.warn ("No journal entry found for" + filename + "Error:" + err);
                close ();
                return false;
            }
            if (next.has_data) {
                fill_file_record_from_get_query (*record, *query);
            }
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public bool get_file_record_by_e2e_mangled_name (string mangled_name, SyncJournalFileRecord record) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        // Reset the output var in case the caller is reusing it.
        //  Q_ASSERT (record);
        record.path.clear ();
        //  Q_ASSERT (!record.is_valid ());

        if (this.metadata_table_is_empty) {
            return true; // no error, yet nothing found (record.is_valid () == false)
        }

        if (!check_connect ()) {
            return false;
        }

        if (!mangled_name.is_empty ()) {
            PreparedSqlQuery query = this.query_manager.get (
                PreparedSqlQueryManager.Key.GET_FILE_RECORD_QUERY_BY_MANGLED_NAME,
                GET_FILE_RECORD_QUERY + " WHERE e2e_mangled_name=?1",
                this.database);
            if (!query) {
                return false;
            }

            query.bind_value (1, mangled_name);

            if (!query.exec ()) {
                close ();
                return false;
            }

            var next = query.next ();
            if (!next.ok) {
                string err = query.error ();
                GLib.warn ("No journal entry found for mangled name" + mangled_name + "Error : " + err);
                close ();
                return false;
            }
            if (next.has_data) {
                fill_file_record_from_get_query (*record, *query);
            }
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public bool get_file_record_by_inode (uint64 inode, SyncJournalFileRecord record) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        // Reset the output var in case the caller is reusing it.
        //  Q_ASSERT (record);
        record.path.clear ();
        //  Q_ASSERT (!record.is_valid ());

        if (!inode || this.metadata_table_is_empty)
            return true; // no error, yet nothing found (record.is_valid () == false)

        if (!check_connect ())
            return false;
        PreparedSqlQuery query = this.query_manager.get (
            PreparedSqlQueryManager.Key.GET_FILE_RECORD_QUERY_BY_INODE,
            GET_FILE_RECORD_QUERY + " WHERE inode=?1",
            this.database);
        if (!query)
            return false;

        query.bind_value (1, inode);

        if (!query.exec ())
            return false;

        var next = query.next ();
        if (!next.ok)
            return false;
        if (next.has_data)
            fill_file_record_from_get_query (record, query);

        return true;
    }


    delegate void RowCallback (SyncJournalFileRecord record);

    /***********************************************************
    ***********************************************************/
    public bool get_file_records_by_file_id (GLib.ByteArray file_id, RowCallback row_callback) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        if (file_id.is_empty () || this.metadata_table_is_empty)
            return true; // no error, yet nothing found (record.is_valid () == false)

        if (!check_connect ())
            return false;

        PreparedSqlQuery query = this.query_manager.get (
            PreparedSqlQueryManager.Key.GET_FILE_RECORD_QUERY_BY_FILE_ID,
            GET_FILE_RECORD_QUERY + " WHERE fileid=?1",
            this.database);
        if (!query) {
            return false;
        }

        query.bind_value (1, file_id);

        if (!query.exec ())
            return false;

        while (true) {
            var next = query.next ();
            if (!next.ok)
                return false;
            if (!next.has_data)
                break;

            SyncJournalFileRecord record;
            fill_file_record_from_get_query (record, *query);
            row_callback (record);
        }

        return true;
    }


    /***********************************************************
    ***********************************************************/
    public bool get_files_below_path (GLib.ByteArray path, RowCallback row_callback) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        if (this.metadata_table_is_empty) {
            return true; // no error, yet nothing found
        }

        if (!check_connect ()) {
            return false;
        }

        //  bool exec (SqlQuery query) {
        //      if (!query.exec ()) {
        //          return false;
        //      }

        //      while (true) {
        //          var next = query.next ();
        //          if (!next.ok)
        //              return false;
        //          if (!next.has_data)
        //              break;

        //          SyncJournalFileRecord record;
        //          fill_file_record_from_get_query (record, query);
        //          row_callback (record);
        //      }
        //      return true;
        //  }

        if (path.is_empty ()) {
            // Since the path column doesn't store the starting /, the get_files_below_path_query
            // can't be used for the root path "". It would scan for (path > '/' and path < '0')
            // and find nothing. So, unfortunately, we have to use a different query for
            // retrieving the whole tree.

            PreparedSqlQuery query = this.query_manager.get (
                PreparedSqlQueryManager.Key.GET_ALL_FILES_QUERY,
                GET_FILE_RECORD_QUERY + " ORDER BY path||'/' ASC",
                this.database);
            if (!query) {
                return false;
            }
            return this.exec (*query);
        } else {
            // This query is used to skip discovery and fill the tree from the
            // database instead
            PreparedSqlQuery query = this.query_manager.get (
                PreparedSqlQueryManager.Key.GET_FILES_BELOW_PATH_QUERY,
                GET_FILE_RECORD_QUERY + " WHERE " + is_prefix_path_of ("?1", "path")
                + " OR " + is_prefix_path_of ("?1", "e2e_mangled_name")
                // We want to ensure that the contents of a directory are sorted
                // directly behind the directory itself. Without this ORDER BY
                // an ordering like foo, foo-2, foo/file would be returned.
                // With the trailing /, we get foo-2, foo, foo/file. This property
                // is used in fill_tree_from_database ().
                + " ORDER BY path||'/' ASC",
                this.database);
            if (!query) {
                return false;
            }
            query.bind_value (1, path);
            return this.exec (*query);
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool list_files_in_path (GLib.ByteArray path, RowCallback row_callback) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        if (this.metadata_table_is_empty)
            return true;

        if (!check_connect ())
            return false;

        PreparedSqlQuery query = this.query_manager.get (
            PreparedSqlQueryManager.Key.LIST_FILES_IN_PATH_QUERY,
            GET_FILE_RECORD_QUERY + " WHERE parent_hash (path) = ?1 ORDER BY path||'/' ASC",
            this.database);
        if (!query) {
            return false;
        }
        query.bind_value (1, get_pHash (path));

        if (!query.exec ())
            return false;

        while (true) {
            var next = query.next ();
            if (!next.ok)
                return false;
            if (!next.has_data)
                break;

            SyncJournalFileRecord record;
            fill_file_record_from_get_query (record, *query);
            if (!record.path.starts_with (path) || record.path.index_of ("/", path.size () + 1) > 0) {
                GLib.warn ("hash collision" + path + record.path ());
                continue;
            }
            row_callback (record);
        }

        return true;
    }


    /***********************************************************
    ***********************************************************/
    public Result<void, string> file_record (SyncJournalFileRecord record) {
        SyncJournalFileRecord record = this.record;
        QMutexLocker locker = new QMutexLocker (this.mutex);

        if (!this.etag_storage_filter.is_empty ()) {
            // If we are a directory that should not be read from database next time, don't write the etag
            GLib.ByteArray prefix = record.path + "/";
            foreach (GLib.ByteArray it in this.etag_storage_filter) {
                if (it.starts_with (prefix)) {
                    GLib.info ("Filtered writing the etag of" + prefix + "because it is a prefix of" + it);
                    record.etag = "this.invalid_";
                    break;
                }
            }
        }

        GLib.info (
            + "Updating file record for path:" + record.path ("inode:") + record.inode
            + "modtime:" + record.modtime + "type:" + record.type
            + "etag:" + record.etag + "file_id:" + record.file_id + "remote_perm:" + record.remote_perm.to_string ()
            + "file_size:" + record.file_size + "checksum:" + record.checksum_header
            + "e2e_mangled_name:" + record.e2e_mangled_name ("is_e2e_encrypted:") + record.is_e2e_encrypted);

        const int64 phash = get_pHash (record.path);
        if (check_connect ()) {
            int plen = record.path.length ();

            GLib.ByteArray etag = new GLib.ByteArray (record.etag);
            if (etag.is_empty ())
                etag = "";
            GLib.ByteArray file_id = new GLib.ByteArray (record.file_id);
            if (file_id.is_empty ())
                file_id = "";
            GLib.ByteArray remote_perm = record.remote_perm.to_database_value ();
            GLib.ByteArray checksum_type;
            GLib.ByteArray checksum;
            parse_checksum_header (record.checksum_header, checksum_type, checksum);
            int content_checksum_type_id = map_checksum_type (checksum_type);

            PreparedSqlQuery query = this.query_manager.get (
                PreparedSqlQueryManager.Key.SET_FILE_RECORD_QUERY,
                "INSERT OR REPLACE INTO metadata "
                + " (phash, pathlen, path, inode, uid, gid, mode, modtime, type, md5, fileid, remote_perm, filesize, ignored_children_remote, content_checksum, content_checksum_type_id, e2e_mangled_name, is_e2e_encrypted) "
                + "VALUES (?1 , ?2, ?3 , ?4 , ?5 , ?6 , ?7,  ?8 , ?9 , ?10, ?11, ?12, ?13, ?14, ?15, ?16, ?17, ?18);",
                this.database);
            if (!query) {
                return query.error ();
            }

            query.bind_value (1, phash);
            query.bind_value (2, plen);
            query.bind_value (3, record.path);
            query.bind_value (4, record.inode);
            query.bind_value (5, 0); // uid Not used
            query.bind_value (6, 0); // gid Not used
            query.bind_value (7, 0); // mode Not used
            query.bind_value (8, record.modtime);
            query.bind_value (9, record.type);
            query.bind_value (10, etag);
            query.bind_value (11, file_id);
            query.bind_value (12, remote_perm);
            query.bind_value (13, record.file_size);
            query.bind_value (14, record.server_has_ignored_files ? 1 : 0);
            query.bind_value (15, checksum);
            query.bind_value (16, content_checksum_type_id);
            query.bind_value (17, record.e2e_mangled_name);
            query.bind_value (18, record.is_e2e_encrypted);

            if (!query.exec ()) {
                return query.error ();
            }

            // Can't be true anymore.
            this.metadata_table_is_empty = false;

            return {};
        } else {
            GLib.warn ("Failed to connect database.");
            return _("Failed to connect database."); // check_connect failed.
        }
    }


    /***********************************************************
    ***********************************************************/
    public void key_value_store_set (string key, GLib.Variant value) {
        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (!check_connect ()) {
            return;
        }

        PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.SetKeyValueStoreQuery, QByteArrayLiteral ("INSERT OR REPLACE INTO key_value_store (key, value) VALUES (?1, ?2);"), this.database);
        if (!query) {
            return;
        }

        query.bind_value (1, key);
        query.bind_value (2, value);
        query.exec ();
    }


    /***********************************************************
    ***********************************************************/
    public int64 key_value_store_get_int (string key, int64 default_value) {
        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (!check_connect ()) {
            return default_value;
        }

        PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.GetKeyValueStoreQuery, QByteArrayLiteral ("SELECT value FROM key_value_store WHERE key=?1"), this.database);
        if (!query) {
            return default_value;
        }

        query.bind_value (1, key);
        query.exec ();
        var result = query.next ();

        if (!result.ok || !result.has_data) {
            return default_value;
        }

        return query.int64_value (0);
    }


    /***********************************************************
    ***********************************************************/
    public void key_value_store_delete (string key) {
        PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.DeleteKeyValueStoreQuery, QByteArrayLiteral ("DELETE FROM key_value_store WHERE key=?1;"), this.database);
        if (!query) {
            GLib.warn ("Failed to init_or_reset this.delete_key_value_store_query");
            //  Q_ASSERT (false);
        }
        query.bind_value (1, key);
        if (!query.exec ()) {
            GLib.warn ("Failed to exec this.delete_key_value_store_query for key" + key);
            //  Q_ASSERT (false);
        }
    }


    /***********************************************************
    TODO: filename -> QBytearray?
    ***********************************************************/
    public bool delete_file_record (string filename, bool recursively = false) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        if (check_connect ()) {
            // if (!recursively) {
            // always delete the actual file.
            {
                PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.Key.DELETE_FILE_RECORD_PHASH, QByteArrayLiteral ("DELETE FROM metadata WHERE phash=?1"), this.database);
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
                PreparedSqlQuery query = this.query_manager.get (
                    PreparedSqlQueryManager.Key.DELETE_FILE_RECORD_RECURSIVELY,
                    "DELETE FROM metadata WHERE " + is_prefix_path_of ("?1", "path"),
                    this.database);
                if (!query)
                    return false;
                query.bind_value (1, filename);
                if (!query.exec ()) {
                    return false;
                }
            }
            return true;
        } else {
            GLib.warn ("Failed to connect database.");
            return false; // check_connect failed.
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool update_file_record_checksum (string filename,
        GLib.ByteArray content_checksum,
        GLib.ByteArray content_checksum_type) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        GLib.info ("Updating file checksum" + filename + content_checksum + content_checksum_type);

        const int64 phash = get_pHash (filename.to_utf8 ());
        if (!check_connect ()) {
            GLib.warn ("Failed to connect database.");
            return false;
        }

        int checksum_type_id = map_checksum_type (content_checksum_type);

        PreparedSqlQuery query = this.query_manager.get (
            PreparedSqlQueryManager.Key.SET_FILE_RECORD_CHECKSUM_QUERY,
            "UPDATE metadata"
            + " SET content_checksum = ?2, content_checksum_type_id = ?3"
            +" WHERE phash == ?1;",
            this.database);
        if (!query) {
            return false;
        }
        query.bind_value (1, phash);
        query.bind_value (2, content_checksum);
        query.bind_value (3, checksum_type_id);
        return query.exec ();
    }


    /***********************************************************
    ***********************************************************/
    public bool update_local_metadata (string filename,
        int64 modtime, int64 size, uint64 inode) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        GLib.info ("Updating local metadata for:" + filename + modtime + size + inode);

        const int64 phash = get_pHash (filename.to_utf8 ());
        if (!check_connect ()) {
            GLib.warn ("Failed to connect database.");
            return false;
        }

        PreparedSqlQuery query = this.query_manager.get (
            PreparedSqlQueryManager.Key.SET_FILE_LOCAL_METADATA_QUERY,
            "UPDATE metadata"
            + " SET inode=?2, modtime=?3, filesize=?4"
            + " WHERE phash == ?1;",
            this.database);
        if (!query) {
            return false;
        }

        query.bind_value (1, phash);
        query.bind_value (2, inode);
        query.bind_value (3, modtime);
        query.bind_value (4, size);
        return query.exec ();
    }


    /***********************************************************
    Returns whether the item or any subitems are dehydrated
    ***********************************************************/
    public Optional<HasHydratedDehydrated> has_hydrated_or_dehydrated_files (GLib.ByteArray filename) {
        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (!check_connect ())
            return {};

        PreparedSqlQuery query = this.query_manager.get (
            PreparedSqlQueryManager.Count_dehydrated_files_query,
            "SELECT DISTINCT type FROM metadata"
            + " WHERE (" + is_prefix_path_or_equal ("?1", "path") + " OR ?1 == '');",
            this.database);
        if (!query) {
            return {};
        }

        query.bind_value (1, filename);
        if (!query.exec ())
            return {};

        HasHydratedDehydrated result;
        while (true) {
            var next = query.next ();
            if (!next.ok)
                return {};
            if (!next.has_data)
                break;
            var type = static_cast<ItemType> (query.int_value (0));
            if (type == ItemTypeFile || type == ItemTypeVirtualFileDehydration)
                result.has_hydrated = true;
            if (type == ItemTypeVirtualFile || type == ItemTypeVirtualFileDownload)
                result.has_dehydrated = true;
        }

        return result;
    }


    /***********************************************************
    ***********************************************************/
    public bool exists () {
        QMutexLocker locker = new QMutexLocker (this.mutex);
        return (!this.database_file.is_empty () && GLib.File.exists (this.database_file));
    }


    /***********************************************************
    Note that this does not change the size of the -wal file,
    but it is supposed to make the normal .db faster since the
    changes from the wal will be incorporated into it. Then the
    next sync (and the SocketApi) will have a faster access.
    ***********************************************************/
    public void wal_checkpoint () {
        QElapsedTimer t;
        t.on_signal_start ();
        SqlQuery pragma1 = new SqlQuery (this.database);
        pragma1.prepare ("PRAGMA wal_checkpoint (FULL);");
        if (pragma1.exec ()) {
            GLib.debug ("took" + t.elapsed ("msec"));
        }
    }


    /***********************************************************
    ***********************************************************/
    public string database_file_path () {
        return this.database_file;
    }


    /***********************************************************
    ***********************************************************/
    public static int64 get_pHash (GLib.ByteArray file) {
        int64 h = 0;
        int len = file.length ();

        h = c_jhash64 ( (uint8_t *)file.data (), len, 0);
        return h;
    }


    /***********************************************************
    ***********************************************************/
    public void error_blocklist_entry_for_item (SyncJournalErrorBlocklistRecord item) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        GLib.info ("Setting blocklist entry for" + item.file + item.retry_count
                    + item.error_string + item.last_try_time + item.ignore_duration
                    + item.last_try_modtime + item.last_try_etag + item.rename_target
                    + item.error_category);

        if (!check_connect ()) {
            return;
        }

        PreparedSqlQuery query = this.query_manager.get (
            PreparedSqlQueryManager.SetErrorBlocklistQuery,
            "INSERT OR REPLACE INTO blocklist "
            + " (path, last_try_etag, last_try_modtime, retrycount, errorstring, last_try_time, ignore_duration, rename_target, error_category, request_id) "
            + "VALUES ( ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)",
            this.database);
        if (!query) {
            return;
        }

        query.bind_value (1, item.file);
        query.bind_value (2, item.last_try_etag);
        query.bind_value (3, item.last_try_modtime);
        query.bind_value (4, item.retry_count);
        query.bind_value (5, item.error_string);
        query.bind_value (6, item.last_try_time);
        query.bind_value (7, item.ignore_duration);
        query.bind_value (8, item.rename_target);
        query.bind_value (9, item.error_category);
        query.bind_value (10, item.request_id);
        query.exec ();
    }


    /***********************************************************
    ***********************************************************/
    public void wipe_error_blocklist_entry (string file) {
        if (file.is_empty ()) {
            return;
        }

        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (check_connect ()) {
            SqlQuery query = new SqlQuery (this.database);

            query.prepare ("DELETE FROM blocklist WHERE path=?1");
            query.bind_value (1, file);
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("Deletion of blocklist item failed."), query);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public void wipe_error_blocklist_category (SyncJournalErrorBlocklistRecord.Category category) {
        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (check_connect ()) {
            SqlQuery query = new SqlQuery (this.database);

            query.prepare ("DELETE FROM blocklist WHERE error_category=?1");
            query.bind_value (1, category);
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("Deletion of blocklist category failed."), query);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public int wipe_error_blocklist () {
        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (check_connect ()) {
            SqlQuery query = new SqlQuery (this.database);

            query.prepare ("DELETE FROM blocklist");

            if (!query.exec ()) {
                sql_fail (QStringLiteral ("Deletion of whole blocklist failed"), query);
                return -1;
            }
            return query.num_rows_affected ();
        }
        return -1;
    }


    /***********************************************************
    ***********************************************************/
    public int on_signal_error_block_list_entry_count () {
        int re = 0;

        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (check_connect ()) {
            SqlQuery query = new SqlQuery ("SELECT count (*) FROM blocklist", this.database);

            if (!query.exec ()) {
                sql_fail (QStringLiteral ("Count number of blocklist entries failed"), query);
            }
            if (query.next ().has_data) {
                re = query.int_value (0);
            }
        }
        return re;
    }


    /***********************************************************
    ***********************************************************/
    public DownloadInfo get_download_info (string file) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        DownloadInfo res;

        if (check_connect ()) {
            PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.Key.GET_DOWNLOAD_INFO_QUERY, QByteArrayLiteral ("SELECT tmpfile, etag, errorcount FROM downloadinfo WHERE path=?1"), this.database);
            if (!query) {
                return res;
            }

            query.bind_value (1, file);

            if (!query.exec ()) {
                return res;
            }

            if (query.next ().has_data) {
                to_download_info (*query, res);
            }
        }
        return res;
    }


    /***********************************************************
    ***********************************************************/
    public void download_info (string file, DownloadInfo i) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        if (!check_connect ()) {
            return;
        }

        if (i.valid) {
            PreparedSqlQuery query = this.query_manager.get (
                PreparedSqlQueryManager.Key.SET_DOWNLOAD_INFO_QUERY,
                "INSERT OR REPLACE INTO downloadinfo "
                + " (path, tmpfile, etag, errorcount) "
                + "VALUES ( ?1 , ?2, ?3, ?4 )",
                this.database);
            if (!query) {
                return;
            }
            query.bind_value (1, file);
            query.bind_value (2, i.tmpfile);
            query.bind_value (3, i.etag);
            query.bind_value (4, i.error_count);
            query.exec ();
        } else {
            PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.Key.DELETE_DOWNLOAD_INFO_QUERY);
            query.bind_value (1, file);
            query.exec ();
        }
    }


    /***********************************************************
    ***********************************************************/
    static void to_download_info (SqlQuery query, SyncJournalDb.DownloadInfo res) {
        bool ok = true;
        res.tmpfile = query.string_value (0);
        res.etag = query.byte_array_value (1);
        res.error_count = query.int_value (2);
        res.valid = ok;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Vector<DownloadInfo> get_and_delete_stale_download_infos (GLib.Set<string> keep) {
        GLib.Vector<SyncJournalDb.DownloadInfo> empty_result;
        QMutexLocker locker = new QMutexLocker (this.mutex);

        if (!check_connect ()) {
            return empty_result;
        }

        SqlQuery query = new SqlQuery (this.database);
        // The selected values must* match the ones expected by to_download_info ().
        query.prepare ("SELECT tmpfile, etag, errorcount, path FROM downloadinfo");

        if (!query.exec ()) {
            return empty_result;
        }

        string[] superfluous_paths;
        GLib.Vector<SyncJournalDb.DownloadInfo> deleted_entries;

        while (query.next ().has_data) {
            const string file = query.string_value (3); // path
            if (!keep.contains (file)) {
                superfluous_paths.append (file);
                DownloadInfo info;
                to_download_info (query, info);
                deleted_entries.append (info);
            }
        }
        {
            PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.Key.DELETE_DOWNLOAD_INFO_QUERY);
            if (!delete_batch (*query, superfluous_paths, QStringLiteral ("downloadinfo"))) {
                return empty_result;
            }
        }

        return deleted_entries;
    }


    /***********************************************************
    ***********************************************************/
    public int on_signal_download_info_count () {
        int re = 0;

        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (check_connect ()) {
            SqlQuery query = new SqlQuery ("SELECT count (*) FROM downloadinfo", this.database);

            if (!query.exec ()) {
                sql_fail (QStringLiteral ("Count number of downloadinfo entries failed"), query);
            }
            if (query.next ().has_data) {
                re = query.int_value (0);
            }
        }
        return re;
    }


    /***********************************************************
    ***********************************************************/
    public UploadInfo get_upload_info (string file) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        UploadInfo res;

        if (check_connect ()) {
            PreparedSqlQuery query = this.query_manager.get (
                PreparedSqlQueryManager.Key.GET_UPLOAD_INFO_QUERY,
                "SELECT chunk, transferid, errorcount, size, modtime, content_checksum FROM "
                + "uploadinfo WHERE path=?1",
                this.database);
            if (!query) {
                return res;
            }
            query.bind_value (1, file);

            if (!query.exec ()) {
                return res;
            }

            if (query.next ().has_data) {
                bool ok = true;
                res.chunk = query.int_value (0);
                res.transferid = query.int64_value (1);
                res.error_count = query.int_value (2);
                res.size = query.int64_value (3);
                res.modtime = query.int64_value (4);
                res.content_checksum = query.byte_array_value (5);
                res.valid = ok;
            }
        }
        return res;
    }


    /***********************************************************
    ***********************************************************/
    public void upload_info (string file, UploadInfo i) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        if (!check_connect ()) {
            return;
        }

        if (i.valid) {
            PreparedSqlQuery query = this.query_manager.get (
                PreparedSqlQueryManager.Key.SET_UPLOAD_INFO_QUERY,
                "INSERT OR REPLACE INTO uploadinfo "
                + " (path, chunk, transferid, errorcount, size, modtime, content_checksum) "
                + "VALUES ( ?1 , ?2, ?3 , ?4 ,  ?5, ?6 , ?7 )",
                this.database);
            if (!query) {
                return;
            }

            query.bind_value (1, file);
            query.bind_value (2, i.chunk);
            query.bind_value (3, i.transferid);
            query.bind_value (4, i.error_count);
            query.bind_value (5, i.size);
            query.bind_value (6, i.modtime);
            query.bind_value (7, i.content_checksum);

            if (!query.exec ()) {
                return;
            }
        } else {
            PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.Key.DELETE_UPLOAD_INFO_QUERY);
            query.bind_value (1, file);

            if (!query.exec ()) {
                return;
            }
        }
    }


    /***********************************************************
    Return the list of transfer ids that were removed.
    ***********************************************************/
    public GLib.Vector<uint32> delete_stale_upload_infos (GLib.Set<string> keep) {
        QMutexLocker locker = new QMutexLocker (this.mutex);
        GLib.Vector<uint32> ids;

        if (!check_connect ()) {
            return ids;
        }

        SqlQuery query = new SqlQuery (this.database);
        query.prepare ("SELECT path,transferid FROM uploadinfo");

        if (!query.exec ()) {
            return ids;
        }

        string[] superfluous_paths;

        while (query.next ().has_data) {
            const string file = query.string_value (0);
            if (!keep.contains (file)) {
                superfluous_paths.append (file);
                ids.append (query.int_value (1));
            }
        }

        PreparedSqlQuery delete_upload_info_query = this.query_manager.get (PreparedSqlQueryManager.Key.DELETE_UPLOAD_INFO_QUERY);
        delete_batch (*delete_upload_info_query, superfluous_paths, QStringLiteral ("uploadinfo"));
        return ids;
    }


    /***********************************************************
    ***********************************************************/
    public SyncJournalErrorBlocklistRecord error_blocklist_entry_for_file (string file) {
        QMutexLocker locker = new QMutexLocker (this.mutex);
        SyncJournalErrorBlocklistRecord entry;

        if (file.is_empty ())
            return entry;

        if (check_connect ()) {
            PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.GetErrorBlocklistQuery);
            query.bind_value (1, file);
            if (query.exec ()) {
                if (query.next ().has_data) {
                    entry.last_try_etag = query.byte_array_value (0);
                    entry.last_try_modtime = query.int64_value (1);
                    entry.retry_count = query.int_value (2);
                    entry.error_string = query.string_value (3);
                    entry.last_try_time = query.int64_value (4);
                    entry.ignore_duration = query.int64_value (5);
                    entry.rename_target = query.string_value (6);
                    entry.error_category = static_cast<SyncJournalErrorBlocklistRecord.Category> (
                        query.int_value (7));
                    entry.request_id = query.byte_array_value (8);
                    entry.file = file;
                }
            }
        }

        return entry;
    }


    /***********************************************************
    ***********************************************************/
    public bool delete_stale_error_blocklist_entries (GLib.Set<string> keep) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        if (!check_connect ()) {
            return false;
        }

        SqlQuery query = new SqlQuery (this.database);
        query.prepare ("SELECT path FROM blocklist");

        if (!query.exec ()) {
            return false;
        }

        string[] superfluous_paths;

        while (query.next ().has_data) {
            const string file = query.string_value (0);
            if (!keep.contains (file)) {
                superfluous_paths.append (file);
            }
        }

        SqlQuery del_query = new SqlQuery (this.database);
        del_query.prepare ("DELETE FROM blocklist WHERE path = ?");
        return delete_batch (del_query, superfluous_paths, QStringLiteral ("blocklist"));
    }


    /***********************************************************
    Delete flags table entries that have no metadata correspondent
    ***********************************************************/
    public void delete_stale_flags_entries () {
        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (!check_connect ())
            return;

        SqlQuery del_query = new SqlQuery ("DELETE FROM flags WHERE path != '' AND path NOT IN (SELECT path from metadata);", this.database);
        del_query.exec ();
    }


    //  public void avoid_renames_on_signal_next_sync (string path) {
    //      avoid_renames_on_signal_next_sync (path.to_utf8 ());
    //  }


    /***********************************************************
    ***********************************************************/
    public void avoid_renames_on_signal_next_sync (GLib.ByteArray path) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        if (!check_connect ()) {
            return;
        }

        SqlQuery query = new SqlQuery (this.database);
        query.prepare ("UPDATE metadata SET fileid = '', inode = '0' WHERE " + is_prefix_path_or_equal ("?1", "path"));
        query.bind_value (1, path);
        query.exec ();

        // We also need to remove the ETags so the update phase refreshes the directory paths
        // on the next sync
        schedule_path_for_remote_discovery (path);
    }


    /***********************************************************
    ***********************************************************/
    public void poll_info (PollInfo info) {
        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (!check_connect ()) {
            return;
        }

        if (info.url.is_empty ()) {
            GLib.debug ("Deleting Poll job" + info.file);
            SqlQuery query = new SqlQuery ("DELETE FROM async_poll WHERE path=?", this.database);
            query.bind_value (1, info.file);
            query.exec ();
        } else {
            SqlQuery query = new SqlQuery ("INSERT OR REPLACE INTO async_poll (path, modtime, filesize, pollpath) VALUES ( ? , ? , ? , ? )", this.database);
            query.bind_value (1, info.file);
            query.bind_value (2, info.modtime);
            query.bind_value (3, info.file_size);
            query.bind_value (4, info.url);
            query.exec ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Vector<PollInfo> get_poll_infos () {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        GLib.Vector<SyncJournalDb.PollInfo> res;

        if (!check_connect ())
            return res;

        SqlQuery query = new SqlQuery ("SELECT path, modtime, filesize, pollpath FROM async_poll", this.database);

        if (!query.exec ()) {
            return res;
        }

        while (query.next ().has_data) {
            PollInfo info;
            info.file = query.string_value (0);
            info.modtime = query.int64_value (1);
            info.file_size = query.int64_value (2);
            info.url = query.string_value (3);
            res.append (info);
        }
        return res;
    }


    /***********************************************************
    ***********************************************************/
    public enum SelectiveSyncListType {
        /***********************************************************
        The block list is the list of folders that are unselected in the selective sync dialog.
        For the sync engine, those folders are considered as if they were not there, so the local
        folders will be deleted
        ***********************************************************/
        SELECTIVE_SYNC_BLOCKLIST = 1,
        /***********************************************************
        When a shared folder has a size bigger than a configured size, it is by default not sync'ed
        Unless it is in the allow list, in which case the folder is sync'ed and all its children.
        If a folder is both on the block and the allow list, the block list wins
        ***********************************************************/
        SELECTIVE_SYNC_ALLOWLIST = 2,
        /***********************************************************
        List of big sync folders that have not been confirmed by the user yet and that the UI
        should notify about
        ***********************************************************/
        SELECTIVE_SYNC_UNDECIDEDLIST = 3
    }


    /***********************************************************
    return the specified list from the database
    ***********************************************************/
    public string[] get_selective_sync_list (SelectiveSyncListType type, bool ok) {
        string[] result;
        //  ASSERT (ok);

        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (!check_connect ()) {
            *ok = false;
            return result;
        }

        PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.Get_selective_sync_list_query, QByteArrayLiteral ("SELECT path FROM selectivesync WHERE type=?1"), this.database);
        if (!query) {
            *ok = false;
            return result;
        }

        query.bind_value (1, int (type));
        if (!query.exec ()) {
            *ok = false;
            return result;
        }
        while (true) {
            var next = query.next ();
            if (!next.ok) {
                *ok = false;
                return result;
            }
            if (!next.has_data)
                break;

            var entry = query.string_value (0);
            if (!entry.ends_with ('/')) {
                entry.append ('/');
            }
            result.append (entry);
        }
        *ok = true;

        return result;
    }


    /***********************************************************
    Write the selective sync list (remove all other entries of that list
    ***********************************************************/
    public void selective_sync_list (SelectiveSyncListType type, string[] list) {
        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (!check_connect ()) {
            return;
        }

        start_transaction ();

        // first, delete all entries of this type
        SqlQuery del_query = new SqlQuery ("DELETE FROM selectivesync WHERE type == ?1", this.database);
        del_query.bind_value (1, int (type));
        if (!del_query.exec ()) {
            GLib.warn ("SQL error when deleting selective sync list" + list + del_query.error ());
        }

        SqlQuery ins_query = new SqlQuery ("INSERT INTO selectivesync VALUES (?1, ?2)", this.database);
        foreach (var path in list) {
            ins_query.reset_and_clear_bindings ();
            ins_query.bind_value (1, path);
            ins_query.bind_value (2, int (type));
            if (!ins_query.exec ()) {
                GLib.warn ("SQL error when inserting into selective sync" + type + path + del_query.error ());
            }
        }

        commit_internal ("selective_sync_list");
    }


    /***********************************************************
    Make sure that on the next sync filename and its parents are discovered from the server.

    That means its metadata and, if it's a directory, its direct contents.

    Specifically, etag
    That causes a metadata difference and a resulting discovery from the remote f
    affected folders.

    Since folders in the selective sync list will not be rediscovered (csync_ftw,
    this.csync_detect_update skip them), the this.invalid_ marker will stay. And any
    child items in the database will be ignored when reading a remote tree from the database.

    Any file_record () call to affected directories before the next sync run will be
    adjusted to retain the invalid etag via this.etag_storage_filter.
    ***********************************************************/
    //  public void schedule_path_for_remote_discovery (string filename) {
    //      schedule_path_for_remote_discovery (filename.to_utf8 ());
    //  }


    /***********************************************************
    ***********************************************************/
    public void schedule_path_for_remote_discovery (GLib.ByteArray filename) {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        if (!check_connect ()) {
            return;
        }

        // Remove trailing slash
        var argument = filename;
        if (argument.ends_with ('/'))
            argument.chop (1);

        SqlQuery query = new SqlQuery (this.database);
        // This query will match entries for which the path is a prefix of filename
        // Note: CSYNC_FTW_TYPE_DIR == 2
        query.prepare ("UPDATE metadata SET md5='this.invalid_' WHERE " + is_prefix_path_or_equal ("path", "?1") + " AND type == 2;");
        query.bind_value (1, argument);
        query.exec ();

        // Prevent future overwrite of the etags of this folder and all
        // parent folders for this sync
        argument.append ('/');
        this.etag_storage_filter.append (argument);
    }


    /***********************************************************
    Wipe this.etag_storage_filter. Also done implicitly on close ().
    ***********************************************************/
    public void clear_etag_storage_filter () {
        this.etag_storage_filter.clear ();
    }


    /***********************************************************
    Ensures full remote discovery happens on the next sync.

    Equivalent to calling schedule_path_for_remote_discovery ()
    for all files.
    ***********************************************************/
    public void force_remote_discovery_next_sync () {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        if (!check_connect ()) {
            return;
        }

        force_remote_discovery_next_sync_locked ();
    }


    /***********************************************************
    Because sqlite transactions are really slow, we encapsulate
    everything in big transactions
    Commit will actually commit the transaction and create a new one.
    ***********************************************************/
    public void commit (string context, bool start_trans = true) {
        QMutexLocker lock = new QMutexLocker (this.mutex);
        commit_internal (context, start_trans);
    }


    /***********************************************************
    ***********************************************************/
    public void commit_if_needed_and_start_new_transaction (string context) {
        QMutexLocker lock = new QMutexLocker (this.mutex);
        if (this.transaction == 1) {
            commit_internal (context, true);
        } else {
            start_transaction ();
        }
    }


    /***********************************************************
    Open the database if it isn't already.

    This usually creates some temporary files next to the
    database file, like $dbfile-shm or $dbfile-wal.

    returns true if it could be openend or is currently opened.
    ***********************************************************/
    public bool open () {
        QMutexLocker lock = new QMutexLocker (this.mutex);
        return check_connect ();
    }


    /***********************************************************
    Returns whether the database is currently openend.
    ***********************************************************/
    public bool is_open () {
        QMutexLocker lock = new QMutexLocker (this.mutex);
        return this.database.is_open ();
    }


    /***********************************************************
    Close the database
    ***********************************************************/
    public void close () {
        QMutexLocker locker = new QMutexLocker (this.mutex);
        GLib.info ("Closing DB" + this.database_file);

        commit_transaction ();

        this.database.close ();
        clear_etag_storage_filter ();
        this.metadata_table_is_empty = false;
    }


    /***********************************************************
    Returns the checksum type for an identifier.
    ***********************************************************/
    public GLib.ByteArray get_checksum_type (int checksum_type_id) {
        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (!check_connect ()) {
            return GLib.ByteArray ();
        }

        // Retrieve the identifier
        PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.Get_checksum_type_query, QByteArrayLiteral ("SELECT name FROM checksumtype WHERE identifier=?1"), this.database);
        if (!query) {
            return {};
        }
        query.bind_value (1, checksum_type_id);
        if (!query.exec ()) {
            return GLib.ByteArray ();
        }

        if (!query.next ().has_data) {
            GLib.warn ("No checksum type mapping found for" + checksum_type_id);
            return GLib.ByteArray ();
        }
        return query.byte_array_value (0);
    }


    /***********************************************************
    The data-fingerprint used to detect backup
    ***********************************************************/
    GLib.ByteArray data_fingerprint {
        set {
            QMutexLocker locker = new QMutexLocker (this.mutex);
            if (!check_connect ()) {
                return;
            }

            PreparedSqlQuery data_fingerprint_query1 = this.query_manager.get (PreparedSqlQueryManager.Set_data_fingerprint_query1, QByteArrayLiteral ("DELETE FROM datafingerprint;"), this.database);
            PreparedSqlQuery data_fingerprint_query2 = this.query_manager.get (PreparedSqlQueryManager.Set_data_fingerprint_query2, QByteArrayLiteral ("INSERT INTO datafingerprint (fingerprint) VALUES (?1);"), this.database);
            if (!data_fingerprint_query1 || !data_fingerprint_query2) {
                return;
            }

            data_fingerprint_query1.exec ();

            data_fingerprint_query2.bind_value (1, value);
            data_fingerprint_query2.exec ();
        }
        get {
            QMutexLocker locker = new QMutexLocker (this.mutex);
            if (!check_connect ()) {
                return GLib.ByteArray ();
            }

            PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.Get_data_fingerprint_query, QByteArrayLiteral ("SELECT fingerprint FROM datafingerprint"), this.database);
            if (!query) {
                return GLib.ByteArray ();
            }

            if (!query.exec ()) {
                return GLib.ByteArray ();
            }

            if (!query.next ().has_data) {
                return GLib.ByteArray ();
            }
            return query.byte_array_value (0);
        }
    }


    /***********************************************************
    Conflict record functions
    ***********************************************************/

    /***********************************************************
    Store a new or updated record in the database
    ***********************************************************/
    public void store_conflict_record (ConflictRecord record) {
        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (!check_connect ())
            return;

        PreparedSqlQuery query = this.query_manager.get (
            PreparedSqlQueryManager.Set_conflict_record_query,
            "INSERT OR REPLACE INTO conflicts "
            + " (path, base_file_id, base_modtime, base_etag, base_path) "
            + "VALUES (?1, ?2, ?3, ?4, ?5);",
            this.database);
        //  ASSERT (query)
        query.bind_value (1, record.path);
        query.bind_value (2, record.base_file_id);
        query.bind_value (3, record.base_modtime);
        query.bind_value (4, record.base_etag);
        query.bind_value (5, record.initial_base_path);
        //  ASSERT (query.exec ())
    }


    /***********************************************************
    Retrieve a conflict record by path of the file with the conflict tag
    ***********************************************************/
    public ConflictRecord conflict_record_for_path (GLib.ByteArray path) {
        ConflictRecord entry;

        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (!check_connect ()) {
            return entry;
        }
        PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.Get_conflict_record_query, QByteArrayLiteral ("SELECT base_file_id, base_modtime, base_etag, base_path FROM conflicts WHERE path=?1;"), this.database);
        //  ASSERT (query)
        query.bind_value (1, path);
        //  ASSERT (query.exec ())
        if (!query.next ().has_data)
            return entry;

        entry.path = path;
        entry.base_file_id = query.byte_array_value (0);
        entry.base_modtime = query.int64_value (1);
        entry.base_etag = query.byte_array_value (2);
        entry.initial_base_path = query.byte_array_value (3);
        return entry;
    }


    /***********************************************************
    Delete a conflict record by path of the file with the
    conflict tag
    ***********************************************************/
    public void delete_conflict_record (GLib.ByteArray path) {
        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (!check_connect ())
            return;

        PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.Delete_conflict_record_query, QByteArrayLiteral ("DELETE FROM conflicts WHERE path=?1;"), this.database);
        //  ASSERT (query)
        query.bind_value (1, path);
        //  ASSERT (query.exec ())
    }


    /***********************************************************
    Return all paths of files with a conflict tag in the name and records in the database
    ***********************************************************/
    public QByte_array_list conflict_record_paths () {
        QMutexLocker locker = new QMutexLocker (this.mutex);
        if (!check_connect ())
            return {};

        SqlQuery query = new SqlQuery (this.database);
        query.prepare ("SELECT path FROM conflicts");
        //  ASSERT (query.exec ());

        QByte_array_list paths;
        while (query.next ().has_data)
            paths.append (query.byte_array_value (0));

        return paths;
    }


    /***********************************************************
    Find the base name for a conflict file name, using journal or name pattern

    The path must be sync-folder relative.

    Will return an empty string if it's not even a conflict file by pattern.
    ***********************************************************/
    public GLib.ByteArray conflict_file_base_name (GLib.ByteArray conflict_name) {
        var conflict = conflict_record (conflict_name);
        GLib.ByteArray result;
        //  if (conflict.is_valid ()) {
        //      get_file_records_by_file_id (conflict.base_file_id, [&result] (SyncJournalFileRecord record) => {
        //          if (!record.path.is_empty ()) {
        //              result = record.path;
        //          }
        //      });
        //  }

        if (result.is_empty ()) {
            result = Utility.conflict_file_base_name_from_pattern (conflict_name);
        }
        return result;
    }


    /***********************************************************
    Delete any file entry. This will force the next sync to re-sync everything as if it was new,
    restoring everyfile on every remote. If a file is there both on the client and server side,
    it will be a conflict that will be automatically resolved if the file is the same.
    ***********************************************************/
    public void clear_file_table () {
        QMutexLocker lock = new QMutexLocker (this.mutex);
        SqlQuery query = new SqlQuery (this.database);
        query.prepare ("DELETE FROM metadata;");
        query.exec ();
    }


    /***********************************************************
    Set the 'ItemTypeVirtualFileDownload' to all the files that have the ItemTypeVirtualFile flag
    within the directory specified path path

    The path "" marks everything.
    ***********************************************************/
    public void mark_virtual_file_for_download_recursively (GLib.ByteArray path) {
        QMutexLocker lock = new QMutexLocker (this.mutex);
        if (!check_connect ())
            return;

        static_assert (ItemTypeVirtualFile == 4 && ItemTypeVirtualFileDownload == 5, "");
        SqlQuery query = new SqlQuery (
            "UPDATE metadata SET type=5 WHERE "
            + " (" + is_prefix_path_of ("?1", "path") + " OR ?1 == '') "
            + "AND type=4;",
            this.database);
        query.bind_value (1, path);
        query.exec ();

        // We also must make sure we do not read the files from the database (same logic as in schedule_path_for_remote_discovery)
        // This includes all the parents up to the root, but also all the directory within the selected dir.
        static_assert (ItemTypeDirectory == 2, "");
        query.prepare (
            "UPDATE metadata SET md5='this.invalid_' WHERE "
            + " (" + is_prefix_path_of ("?1", "path") + " OR ?1 == '' OR " + is_prefix_path_or_equal ("path", "?1") + ") AND type == 2;");
        query.bind_value (1, path);
        query.exec ();
    }


    /***********************************************************
    ***********************************************************/
    //  public friend struct PinStateInterface;


    /***********************************************************
    Access to PinStates stored in the database.

    Important : Not all vfs plugins store the pin states in the database,
    prefer to use Vfs.pin_state () etc.
    ***********************************************************/
    public PinStateInterface internal_pin_states () {
        return {this};
    }


    /***********************************************************
    ***********************************************************/
    private int get_file_record_count () {
        QMutexLocker locker = new QMutexLocker (this.mutex);

        SqlQuery query = new SqlQuery (this.database);
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

    /***********************************************************
    ***********************************************************/
    private void commit_internal (string context, bool start_trans) {
        GLib.debug ("Transaction commit" + context + (start_trans ? "and starting new transaction" : ""));
        commit_transaction ();

        if (start_trans) {
            start_transaction ();
        }
    }

    /***********************************************************
    ***********************************************************/
    private bool update_database_structure () {
        if (!update_metadata_table_structure ())
            return false;
        if (!update_error_blocklist_table_structure ())
            return false;
        return true;
    }


    /***********************************************************
    ***********************************************************/
    private GLib.Vector<GLib.ByteArray> table_columns (GLib.ByteArray table) {
        GLib.Vector<GLib.ByteArray> columns;
        if (!check_connect ()) {
            return columns;
        }
        SqlQuery query = new SqlQuery ("PRAGMA table_info ('" + table + "');", this.database);
        if (!query.exec ()) {
            return columns;
        }
        while (query.next ().has_data) {
            columns.append (query.byte_array_value (1));
        }
        GLib.debug ("Columns in the current journal:" + columns);
        return columns;
    }


    /***********************************************************
    ***********************************************************/
    private bool update_metadata_table_structure () {

        var columns = table_columns ("metadata");
        bool re = true;

        // check if the file_id column is there and create it if not
        if (columns.is_empty ()) {
            return false;
        }

        if (columns.index_of ("fileid") == -1) {
            SqlQuery query = new SqlQuery (this.database);
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
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("ALTER TABLE metadata ADD COLUMN remote_perm VARCHAR (128);");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_metadata_table_structure : add column remote_perm"), query);
                re = false;
            }
            commit_internal (QStringLiteral ("update database structure (remote_perm)"));
        }
        if (columns.index_of ("filesize") == -1) {
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("ALTER TABLE metadata ADD COLUMN filesize BIGINT;");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_database_structure : add column filesize"), query);
                re = false;
            }
            commit_internal (QStringLiteral ("update database structure : add filesize col"));
        }

        if (true) {
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("CREATE INDEX IF NOT EXISTS metadata_inode ON metadata (inode);");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_metadata_table_structure : create index inode"), query);
                re = false;
            }
            commit_internal (QStringLiteral ("update database structure : add inode index"));
        }

        if (true) {
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("CREATE INDEX IF NOT EXISTS metadata_path ON metadata (path);");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_metadata_table_structure : create index path"), query);
                re = false;
            }
            commit_internal (QStringLiteral ("update database structure : add path index"));
        }

        if (true) {
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("CREATE INDEX IF NOT EXISTS metadata_parent ON metadata (parent_hash (path));");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_metadata_table_structure : create index parent"), query);
                re = false;
            }
            commit_internal (QStringLiteral ("update database structure : add parent index"));
        }

        if (columns.index_of ("ignored_children_remote") == -1) {
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("ALTER TABLE metadata ADD COLUMN ignored_children_remote INT;");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_metadata_table_structure : add ignored_children_remote column"), query);
                re = false;
            }
            commit_internal (QStringLiteral ("update database structure : add ignored_children_remote col"));
        }

        if (columns.index_of ("content_checksum") == -1) {
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("ALTER TABLE metadata ADD COLUMN content_checksum TEXT;");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_metadata_table_structure : add content_checksum column"), query);
                re = false;
            }
            commit_internal (QStringLiteral ("update database structure : add content_checksum col"));
        }
        if (columns.index_of ("content_checksum_type_id") == -1) {
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("ALTER TABLE metadata ADD COLUMN content_checksum_type_id INTEGER;");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_metadata_table_structure : add content_checksum_type_id column"), query);
                re = false;
            }
            commit_internal (QStringLiteral ("update database structure : add content_checksum_type_id col"));
        }

        if (!columns.contains ("e2e_mangled_name")) {
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("ALTER TABLE metadata ADD COLUMN e2e_mangled_name TEXT;");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_metadata_table_structure : add e2e_mangled_name column"), query);
                re = false;
            }
            commit_internal (QStringLiteral ("update database structure : add e2e_mangled_name col"));
        }

        if (!columns.contains ("is_e2e_encrypted")) {
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("ALTER TABLE metadata ADD COLUMN is_e2e_encrypted INTEGER;");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_metadata_table_structure : add is_e2e_encrypted column"), query);
                re = false;
            }
            commit_internal (QStringLiteral ("update database structure : add is_e2e_encrypted col"));
        }

        var upload_info_columns = table_columns ("uploadinfo");
        if (upload_info_columns.is_empty ())
            return false;
        if (!upload_info_columns.contains ("content_checksum")) {
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("ALTER TABLE uploadinfo ADD COLUMN content_checksum TEXT;");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_metadata_table_structure : add content_checksum column"), query);
                re = false;
            }
            commit_internal (QStringLiteral ("update database structure : add content_checksum col for uploadinfo"));
        }

        var conflicts_columns = table_columns ("conflicts");
        if (conflicts_columns.is_empty ())
            return false;
        if (!conflicts_columns.contains ("base_path")) {
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("ALTER TABLE conflicts ADD COLUMN base_path TEXT;");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_metadata_table_structure : add base_path column"), query);
                re = false;
            }
        }

        if (true) {
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("CREATE INDEX IF NOT EXISTS metadata_e2e_id ON metadata (e2e_mangled_name);");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_metadata_table_structure : create index e2e_mangled_name"), query);
                re = false;
            }
            commit_internal (QStringLiteral ("update database structure : add e2e_mangled_name index"));
        }

        return re;
    }


    /***********************************************************
    ***********************************************************/
    private bool update_error_blocklist_table_structure () {
        var columns = table_columns ("blocklist");
        bool re = true;

        if (columns.is_empty ()) {
            return false;
        }

        if (columns.index_of ("last_try_time") == -1) {
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("ALTER TABLE blocklist ADD COLUMN last_try_time INTEGER (8);");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_blocklist_table_structure : Add last_try_time fileid"), query);
                re = false;
            }
            query.prepare ("ALTER TABLE blocklist ADD COLUMN ignore_duration INTEGER (8);");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_blocklist_table_structure : Add ignore_duration fileid"), query);
                re = false;
            }
            commit_internal (QStringLiteral ("update database structure : add last_try_time, ignore_duration cols"));
        }
        if (columns.index_of ("rename_target") == -1) {
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("ALTER TABLE blocklist ADD COLUMN rename_target VARCHAR (4096);");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_blocklist_table_structure : Add rename_target"), query);
                re = false;
            }
            commit_internal (QStringLiteral ("update database structure : add rename_target col"));
        }

        if (columns.index_of ("error_category") == -1) {
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("ALTER TABLE blocklist ADD COLUMN error_category INTEGER (8);");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_blocklist_table_structure : Add error_category"), query);
                re = false;
            }
            commit_internal (QStringLiteral ("update database structure : add error_category col"));
        }

        if (columns.index_of ("request_id") == -1) {
            SqlQuery query = new SqlQuery (this.database);
            query.prepare ("ALTER TABLE blocklist ADD COLUMN request_id VARCHAR (36);");
            if (!query.exec ()) {
                sql_fail (QStringLiteral ("update_blocklist_table_structure : Add request_id"), query);
                re = false;
            }
            commit_internal (QStringLiteral ("update database structure : add error_category col"));
        }

        SqlQuery query = new SqlQuery (this.database);
        query.prepare ("CREATE INDEX IF NOT EXISTS blocklist_index ON blocklist (path collate nocase);");
        if (!query.exec ()) {
            sql_fail (QStringLiteral ("update_error_blocklist_table_structure : create index blocklit"), query);
            re = false;
        }

        return re;
    }

    /***********************************************************
    ***********************************************************/
    private bool sql_fail (string log, SqlQuery query) {
        commit_transaction ();
        GLib.warn ("SQL Error" + log + query.error ());
        this.database.close ();
        //  ASSERT (false);
        return false;
    }


    /***********************************************************
    ***********************************************************/
    private void start_transaction () {
        if (this.transaction == 0) {
            if (!this.database.transaction ()) {
                GLib.warn ("ERROR starting transaction:" + this.database.error ());
                return;
            }
            this.transaction = 1;
        } else {
            GLib.debug ("Database Transaction is running, not starting another one!");
        }
    }


    /***********************************************************
    ***********************************************************/
    private void commit_transaction () {
        if (this.transaction == 1) {
            if (!this.database.commit ()) {
                GLib.warn ("ERROR committing to the database:" + this.database.error ());
                return;
            }
            this.transaction = 0;
        } else {
            GLib.debug ("No database Transaction to commit");
        }
    }


    /***********************************************************
    ***********************************************************/
    private bool check_connect () {
        if (autotest_fail_counter >= 0) {
            if (!autotest_fail_counter--) {
                GLib.info ("Error Simulated");
                return false;
            }
        }

        if (this.database.is_open ()) {
            // Unfortunately the sqlite is_open check can return true even when the underlying storage
            // has become unavailable - and then some operations may cause crashes. See #6049
            if (!GLib.File.exists (this.database_file)) {
                GLib.warn ("Database open, but file" + this.database_file + "does not exist");
                close ();
                return false;
            }
            return true;
        }

        if (this.database_file.is_empty ()) {
            GLib.warn ("Database filename" + this.database_file + "is empty");
            return false;
        }

        // The database file is created by this call (SQLITE_OPEN_CREATE)
        if (!this.database.open_or_create_read_write (this.database_file)) {
            string error = this.database.error ();
            GLib.warn ("Error opening the database:" + error);
            return false;
        }

        if (!GLib.File.exists (this.database_file)) {
            GLib.warn ("Database file" + this.database_file + "does not exist");
            return false;
        }

        SqlQuery pragma1 = new SqlQuery (this.database);
        pragma1.prepare ("SELECT sqlite_version ();");
        if (!pragma1.exec ()) {
            return sql_fail ("SELECT sqlite_version ()", pragma1);
        } else {
            pragma1.next ();
            GLib.info ("Sqlite3 version" + pragma1.string_value (0));
        }

        // Set locking mode to avoid issues with WAL on Windows
        GLib.ByteArray locking_mode_env = qgetenv ("OWNCLOUD_SQLITE_LOCKING_MODE");
        if (locking_mode_env.is_empty ())
            locking_mode_env = "EXCLUSIVE";
        pragma1.prepare ("PRAGMA locking_mode=" + locking_mode_env + ";");
        if (!pragma1.exec ()) {
            return sql_fail ("Set PRAGMA locking_mode", pragma1);
        } else {
            pragma1.next ();
            GLib.info ("Sqlite3 locking_mode=" + pragma1.string_value (0));
        }

        pragma1.prepare ("PRAGMA journal_mode=" + this.journal_mode + ";");
        if (!pragma1.exec ()) {
            return sql_fail ("Set PRAGMA journal_mode", pragma1);
        } else {
            pragma1.next ();
            GLib.info ("Sqlite3 journal_mode=" + pragma1.string_value (0));
        }

        // For debugging purposes, allow temp_store to be set
        GLib.ByteArray env_temp_store = qgetenv ("OWNCLOUD_SQLITE_TEMP_STORE");
        if (!env_temp_store.is_empty ()) {
            pragma1.prepare ("PRAGMA temp_store = " + env_temp_store + ";");
            if (!pragma1.exec ()) {
                return sql_fail ("Set PRAGMA temp_store", pragma1);
            }
            GLib.info ("Sqlite3 with temp_store =" + env_temp_store);
        }

        // With WAL journal the NORMAL sync mode is safe from corruption,
        // otherwise use the standard FULL mode.
        GLib.ByteArray synchronous_mode = "FULL";
        if (string.from_utf8 (this.journal_mode).compare ("wal", Qt.CaseInsensitive) == 0)
            synchronous_mode = "NORMAL";
        pragma1.prepare ("PRAGMA synchronous = " + synchronous_mode + ";");
        if (!pragma1.exec ()) {
            return sql_fail ("Set PRAGMA synchronous", pragma1);
        } else {
            GLib.info ("Sqlite3 synchronous=" + synchronous_mode);
        }

        pragma1.prepare ("PRAGMA case_sensitive_like = ON;");
        if (!pragma1.exec ()) {
            return sql_fail ("Set PRAGMA case_sensitivity", pragma1);
        }

        //  sqlite3_create_function (
        //      this.database.sqlite_database (),
        //      "parent_hash",
        //      1,
        //      SQLITE_UTF8 | SQLITE_DETERMINISTIC,
        //      null,
        //      [] (sqlite3_context context, int, sqlite3_value **argv) {
        //          var text = (const char)sqlite3_value_text (argv[0]);
        //          const string end = std.strrchr (text, '/');
        //          if (!end) {
        //              end = text;
        //          }
        //          sqlite3_result_int64 (
        //              context,
        //              c_jhash64 (
        //                  (const uint8)text,
        //                  end - text,
        //                  0
        //              )
        //          );
        //      }, null, null);

        // Because insert is so slow, we do everything in a transaction, and only need one call to commit
        start_transaction ();

        SqlQuery create_query = new SqlQuery (this.database);
        create_query.prepare ("CREATE TABLE IF NOT EXISTS metadata ("
                             + "phash INTEGER (8),"
                             + "pathlen INTEGER,"
                             + "path VARCHAR (4096),"
                             + "inode INTEGER,"
                             + "uid INTEGER,"
                             + "gid INTEGER,"
                             + "mode INTEGER,"
                             + "modtime INTEGER (8),"
                             + "type INTEGER,"
                             + "md5 VARCHAR (32)," // This is the etag.  Called md5 for compatibility
                            // update_database_structure () will add
                            // fileid
                            // remote_perm
                            // filesize
                            // ignored_children_remote
                            // content_checksum
                            // content_checksum_type_id
                            + "PRIMARY KEY (phash)"
                            + ");");

    //  #ifndef SQLITE_IOERR_SHMMAP
    //  // Requires sqlite >= 3.7.7 but old CentOS6 has sqlite-3.6.20
    //  // Definition taken from https://sqlite.org/c3ref/c_abort_rollback.html
    //  const int SQLITE_IOERR_SHMMAP            (SQLITE_IOERR | (21<<8))
    //  #endif

        if (!create_query.exec ()) {
            // In certain situations the io error can be avoided by switching
            // to the DELETE journal mode, see #5723
            if (this.journal_mode != "DELETE"
                && create_query.error_id () == SQLITE_IOERR
                && sqlite3_extended_errcode (this.database.sqlite_database ()) == SQLITE_IOERR_SHMMAP) {
                GLib.warn ("IO error SHMMAP on table creation, attempting with DELETE journal mode");
                this.journal_mode = "DELETE";
                commit_transaction ();
                this.database.close ();
                return check_connect ();
            }

            return sql_fail (QStringLiteral ("Create table metadata"), create_query);
        }

        create_query.prepare ("CREATE TABLE IF NOT EXISTS key_value_store (key VARCHAR (4096), value VARCHAR (4096), PRIMARY KEY (key));");

        if (!create_query.exec ()) {
            return sql_fail (QStringLiteral ("Create table key_value_store"), create_query);
        }

        create_query.prepare ("CREATE TABLE IF NOT EXISTS downloadinfo ("
                             + "path VARCHAR (4096),"
                             + "tmpfile VARCHAR (4096),"
                             + "etag VARCHAR (32),"
                             + "errorcount INTEGER,"
                             + "PRIMARY KEY (path)"
                             + ");");

        if (!create_query.exec ()) {
            return sql_fail (QStringLiteral ("Create table downloadinfo"), create_query);
        }

        create_query.prepare ("CREATE TABLE IF NOT EXISTS uploadinfo ("
                             + "path VARCHAR (4096),"
                             + "chunk INTEGER,"
                             + "transferid INTEGER,"
                             + "errorcount INTEGER,"
                             + "size INTEGER (8),"
                             + "modtime INTEGER (8),"
                             + "content_checksum TEXT,"
                             + "PRIMARY KEY (path)"
                             + ");");

        if (!create_query.exec ()) {
            return sql_fail (QStringLiteral ("Create table uploadinfo"), create_query);
        }

        // create the blocklist table.
        create_query.prepare ("CREATE TABLE IF NOT EXISTS blocklist ("
                             + "path VARCHAR (4096),"
                             + "last_try_etag VARCHAR[32],"
                             + "last_try_modtime INTEGER[8],"
                             + "retrycount INTEGER,"
                             + "errorstring VARCHAR[4096],"
                             + "PRIMARY KEY (path)"
                             + ");");

        if (!create_query.exec ()) {
            return sql_fail (QStringLiteral ("Create table blocklist"), create_query);
        }

        create_query.prepare ("CREATE TABLE IF NOT EXISTS async_poll ("
                             + "path VARCHAR (4096),"
                             + "modtime INTEGER (8),"
                             + "filesize BIGINT,"
                             + "pollpath VARCHAR (4096));");
        if (!create_query.exec ()) {
            return sql_fail (QStringLiteral ("Create table async_poll"), create_query);
        }

        // create the selectivesync table.
        create_query.prepare ("CREATE TABLE IF NOT EXISTS selectivesync ("
                             + "path VARCHAR (4096),"
                             + "type INTEGER"
                             + ");");

        if (!create_query.exec ()) {
            return sql_fail (QStringLiteral ("Create table selectivesync"), create_query);
        }

        // create the checksumtype table.
        create_query.prepare ("CREATE TABLE IF NOT EXISTS checksumtype ("
                             + "identifier INTEGER PRIMARY KEY,"
                             + "name TEXT UNIQUE"
                             + ");");
        if (!create_query.exec ()) {
            return sql_fail (QStringLiteral ("Create table checksumtype"), create_query);
        }

        // create the datafingerprint table.
        create_query.prepare ("CREATE TABLE IF NOT EXISTS datafingerprint ("
                             + "fingerprint TEXT UNIQUE"
                             + ");");
        if (!create_query.exec ()) {
            return sql_fail (QStringLiteral ("Create table datafingerprint"), create_query);
        }

        // create the flags table.
        create_query.prepare ("CREATE TABLE IF NOT EXISTS flags ("
                             + "path TEXT PRIMARY KEY,"
                             + "pin_state INTEGER"
                             + ");");
        if (!create_query.exec ()) {
            return sql_fail (QStringLiteral ("Create table flags"), create_query);
        }

        // create the conflicts table.
        create_query.prepare ("CREATE TABLE IF NOT EXISTS conflicts ("
                             + "path TEXT PRIMARY KEY,"
                             + "base_file_id TEXT,"
                             + "base_etag TEXT,"
                             + "base_modtime INTEGER"
                             + ");");
        if (!create_query.exec ()) {
            return sql_fail (QStringLiteral ("Create table conflicts"), create_query);
        }

        create_query.prepare ("CREATE TABLE IF NOT EXISTS version ("
                             + "major INTEGER (8),"
                             + "minor INTEGER (8),"
                             + "patch INTEGER (8),"
                             + "custom VARCHAR (256)"
                             + ");");
        if (!create_query.exec ()) {
            return sql_fail (QStringLiteral ("Create table version"), create_query);
        }

        bool force_remote_discovery = false;

        SqlQuery version_query = new SqlQuery ("SELECT major, minor, patch FROM version;", this.database);
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
                GLib.info ("possible_upgrade_from_mirall_1_8_0_or_1 detected!");
                force_remote_discovery = true;
            }

            // There was a bug in versions <2.3.0 that could lead to stale
            // local files and a remote discovery will fix them.
            // See #5190 #5242.
            if (major == 2 && minor < 3) {
                GLib.info ("upgrade form client < 2.3.0 detected! forcing remote discovery");
                force_remote_discovery = true;
            }

            // Not comparing the BUILD identifier here, correct?
            if (! (major == MIRALL_VERSION_MAJOR && minor == MIRALL_VERSION_MINOR && patch == MIRALL_VERSION_PATCH)) {
                create_query.prepare (
                    "UPDATE version SET major=?1, minor=?2, patch =?3, custom=?4 "
                    + "WHERE major=?5 AND minor=?6 AND patch=?7;");
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
            GLib.warn ("Failed to update the database structure!");
        }


        /***********************************************************
        If we are upgrading from a client version older than 1.5,
        we cannot read from the database because we need to fetch the files identifier and etags.

        If 1.8.0 caused missing data in the l
        to get back the files that were gone.
        In 1.8.1 we had a fix to re-get the data, but this one here is better
        ***********************************************************/
        if (force_remote_discovery) {
            force_remote_discovery_next_sync_locked ();
        }
        PreparedSqlQuery delete_download_info = this.query_manager.get (PreparedSqlQueryManager.Key.DELETE_DOWNLOAD_INFO_QUERY, QByteArrayLiteral ("DELETE FROM downloadinfo WHERE path=?1"), this.database);
        if (!delete_download_info) {
            return sql_fail ("prepare this.delete_download_info_query", *delete_download_info);
        }

        PreparedSqlQuery delete_upload_info_query = this.query_manager.get (PreparedSqlQueryManager.Key.DELETE_UPLOAD_INFO_QUERY, QByteArrayLiteral ("DELETE FROM uploadinfo WHERE path=?1"), this.database);
        if (!delete_upload_info_query) {
            return sql_fail ("prepare this.delete_upload_info_query", *delete_upload_info_query);
        }

        GLib.ByteArray sql = new GLib.ByteArray (
            "SELECT last_try_etag, last_try_modtime, retrycount, errorstring, last_try_time, ignore_duration, rename_target, error_category, request_id "
            + "FROM blocklist WHERE path=?1");
        if (Utility.fs_case_preserving ()) {
            // if the file system is case preserving we have to check the blocklist
            // case insensitively
            sql += " COLLATE NOCASE";
        }
        PreparedSqlQuery get_error_blocklist_query = this.query_manager.get (PreparedSqlQueryManager.GetErrorBlocklistQuery, sql, this.database);
        if (!get_error_blocklist_query) {
            return sql_fail (QStringLiteral ("prepare this.get_error_blocklist_query"), *get_error_blocklist_query);
        }

        // don't on_signal_start a new transaction now
        commit_internal (QStringLiteral ("check_connect End"), false);

        // This avoid reading from the DB if we already know it is empty
        // thereby speeding up the initial discovery significantly.
        this.metadata_table_is_empty = (get_file_record_count () == 0);

        // Hide 'em all!
        FileSystem.file_hidden (database_file_path (), true);
        FileSystem.file_hidden (database_file_path () + QStringLiteral ("-wal"), true);
        FileSystem.file_hidden (database_file_path () + QStringLiteral ("-shm"), true);
        FileSystem.file_hidden (database_file_path () + QStringLiteral ("-journal"), true);

        return rc;
    }


    /***********************************************************
    Same as force_remote_discovery_next_sync but without
    acquiring the lock
    ***********************************************************/
    private void force_remote_discovery_next_sync_locked () {
        GLib.info ("Forcing remote re-discovery by deleting folder Etags");
        SqlQuery delete_remote_folder_etags_query = new SqlQuery (this.database);
        delete_remote_folder_etags_query.prepare ("UPDATE metadata SET md5='this.invalid_' WHERE type=2;");
        delete_remote_folder_etags_query.exec ();
    }


    /***********************************************************
    Returns the integer identifier of the checksum type

    Returns 0 on failure and for empty checksum types.
    ***********************************************************/
    private int map_checksum_type (GLib.ByteArray checksum_type) {
        if (checksum_type.is_empty ()) {
            return 0;
        }

        var it =  this.checksym_type_cache.find (checksum_type);
        if (it != this.checksym_type_cache.end ())
            return it;

        // Ensure the checksum type is in the database
        {
            PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.Insert_checksum_type_query, QByteArrayLiteral ("INSERT OR IGNORE INTO checksumtype (name) VALUES (?1)"), this.database);
            if (!query) {
                return 0;
            }
            query.bind_value (1, checksum_type);
            if (!query.exec ()) {
                return 0;
            }
        }

        // Retrieve the identifier
        {
            PreparedSqlQuery query = this.query_manager.get (PreparedSqlQueryManager.Get_checksum_type_id_query, QByteArrayLiteral ("SELECT identifier FROM checksumtype WHERE name=?1"), this.database);
            if (!query) {
                return 0;
            }
            query.bind_value (1, checksum_type);
            if (!query.exec ()) {
                return 0;
            }

            if (!query.next ().has_data) {
                GLib.warn ("No checksum type mapping found for" + checksum_type);
                return 0;
            }
            var value = query.int_value (0);
            this.checksym_type_cache[checksum_type] = value;
            return value;
        }
    }




    /***********************************************************
    SQL expression to check whether path.startswith (prefix + '/')
    Note: '/' + 1 == '0'
    ***********************************************************/
    static string is_prefix_path_of (string prefix, string path) {
        return " (" + path + " > (" + prefix + "||'/') AND " + path + " < (" + prefix + "||'0'))";
    }

    static string is_prefix_path_or_equal (string prefix, string path) {
        return " (" + path + " == " + prefix + " OR " + is_prefix_path_of (prefix, path) + ")";
    }


    /***********************************************************
    ***********************************************************/
    static void fill_file_record_from_get_query (SyncJournalFileRecord record, SqlQuery query) {
        record.path = query.byte_array_value (0);
        record.inode = query.int64_value (1);
        record.modtime = query.int64_value (2);
        record.type = static_cast<ItemType> (query.int_value (3));
        record.etag = query.byte_array_value (4);
        record.file_id = query.byte_array_value (5);
        record.remote_perm = RemotePermissions.from_database_value (query.byte_array_value (6));
        record.file_size = query.int64_value (7);
        record.server_has_ignored_files = (query.int_value (8) > 0);
        record.checksum_header = query.byte_array_value (9);
        record.e2e_mangled_name = query.byte_array_value (10);
        record.is_e2e_encrypted = query.int_value (11) > 0;
    }


    /***********************************************************
    ***********************************************************/
    static bool delete_batch (SqlQuery query, string[] entries, string name) {
        if (entries.is_empty ())
            return true;

        GLib.debug ("Removing stale" + name + "entries:" + entries.join (", "));
        // FIXME : Was ported from exec_batch, check if correct!
        foreach (string entry in entries) {
            query.reset_and_clear_bindings ();
            query.bind_value (1, entry);
            if (!query.exec ()) {
                return false;
            }
        }

        return true;
    }


    //  OCSYNC_EXPORT
    //  bool operator== (SyncJournalDb.DownloadInfo lhs,
    //      SyncJournalDb.DownloadInfo rhs) {
    //      return lhs.error_count == rhs.error_count
    //          && lhs.etag == rhs.etag
    //          && lhs.tmpfile == rhs.tmpfile
    //          && lhs.valid == rhs.valid;
    //  }


    //  OCSYNC_EXPORT
    //  bool operator== (SyncJournalDb.UploadInfo lhs,
    //      SyncJournalDb.UploadInfo rhs) {
    //      return lhs.error_count == rhs.error_count
    //          && lhs.chunk == rhs.chunk
    //          && lhs.modtime == rhs.modtime
    //          && lhs.valid == rhs.valid
    //          && lhs.size == rhs.size
    //          && lhs.transferid == rhs.transferid
    //          && lhs.content_checksum == rhs.content_checksum;
    //  }

} // class SyncJournalDb

} // namespace Occ