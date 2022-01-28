/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <QDateTime>
// #include <QLoggingCategory>
// #include <string>
// #include <QFile>
// #include <QFileInfo>
// #include <QDir>

// #include <Sqlite3.h>


// #include <QLoggingCategory>
// #include <QVariant>

struct Sqlite3;
struct Sqlite3Stmt;

namespace Occ {

OCSYNC_EXPORT Q_DECLARE_LOGGING_CATEGORY (lc_sql)

const int SQLITE_SLEEP_TIME_USEC = 100000
const int SQLITE_REPEAT_COUNT = 20

const int SQLITE_DO (A) {
    if (1) {
        _err_id = (A);
        if (_err_id != SQLITE_OK && _err_id != SQLITE_DONE && _err_id != SQLITE_ROW) {
            _error = string.from_utf8 (sqlite3_errmsg (_database));
        }
    }
}


/***********************************************************
@brief The SqlDatabase class
@ingroup libsync
***********************************************************/
class SqlDatabase {
    // Q_DISABLE_COPY (SqlDatabase)

    private Sqlite3 _database = nullptr;
    private string _error; // last error string
    private int _err_id = 0;

    private friend class SqlQuery;
    private QSet<SqlQuery> _queries;

    public SqlDatabase () = default;


    ~SqlDatabase () {
        close ();
    }


    public bool is_open () {
        return _database != nullptr;
    }


    public bool open_or_create_read_write (string filename) {
        if (is_open ()) {
            return true;
        }

        if (!open_helper (filename, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE)) {
            return false;
        }

        var check_result = check_database ();
        if (check_result != CheckDbResult.OK) {
            if (check_result == CheckDbResult.CANT_PREPARE) {
                // When disk space is low, preparing may fail even though the database is fine.
                // Typically CANTOPEN or IOERR.
                int64 free_space = Utility.free_disk_space (QFileInfo (filename).dir ().absolute_path ());
                if (free_space != -1 && free_space < 1000000) {
                    q_c_warning (lc_sql) << "Can't prepare consistency check and disk space is low:" << free_space;
                    close ();
                    return false;
                }

                // Even when there's enough disk space, it might very well be that the
                // file is on a read-only filesystem and can't be opened because of that.
                if (_err_id == SQLITE_CANTOPEN) {
                    q_c_warning (lc_sql) << "Can't open database to prepare consistency check, aborting";
                    close ();
                    return false;
                }
            }

            q_c_critical (lc_sql) << "Consistency check failed, removing broken database" << filename;
            close ();
            QFile.remove (filename);

            return open_helper (filename, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE);
        }

        return true;
    }


    public bool open_read_only (string filename) {
        if (is_open ()) {
            return true;
        }

        if (!open_helper (filename, SQLITE_OPEN_READONLY)) {
            return false;
        }

        if (check_database () != CheckDbResult.OK) {
            q_c_warning (lc_sql) << "Consistency check failed in read_only mode, giving up" << filename;
            close ();
            return false;
        }

        return true;
    }


    public bool transaction () {
        if (!_database) {
            return false;
        }
        SQLITE_DO (sqlite3_exec (_database, "BEGIN", nullptr, nullptr, nullptr));
        return _err_id == SQLITE_OK;
    }


    public bool commit () {
        if (!_database) {
            return false;
        }
        SQLITE_DO (sqlite3_exec (_database, "COMMIT", nullptr, nullptr, nullptr));
        return _err_id == SQLITE_OK;
    }


    public void close () {
        if (_database) {
            foreach (var q, _queries) {
                q.finish ();
            }
            SQLITE_DO (sqlite3_close (_database));
            if (_err_id != SQLITE_OK)
                q_c_warning (lc_sql) << "Closing database failed" << _error;
            _database = nullptr;
        }
    }


    public string error () {
        const string err (_error);
        // _error.clear ();
        return err;
    }


    public Sqlite3 sqlite_database () {
        return _database;
    }


    private enum class CheckDbResult {
        Ok,
        CheckDbResult.CANT_PREPARE,
        Cant_exec,
        Not_ok,
    };

    private bool open_helper (string filename, int sqlite_flags) {
        if (is_open ()) {
            return true;
        }

        sqlite_flags |= SQLITE_OPEN_NOMUTEX;

        SQLITE_DO (sqlite3_open_v2 (filename.to_utf8 ().const_data (), &_database, sqlite_flags, nullptr));

        if (_err_id != SQLITE_OK) {
            q_c_warning (lc_sql) << "Error:" << _error << "for" << filename;
            if (_err_id == SQLITE_CANTOPEN) {
                q_c_warning (lc_sql) << "CANTOPEN extended errcode : " << sqlite3_extended_errcode (_database);
    #if SQLITE_VERSION_NUMBER >= 3012000
                q_c_warning (lc_sql) << "CANTOPEN system errno : " << sqlite3_system_errno (_database);
    #endif
            }
            close ();
            return false;
        }

        if (!_database) {
            q_c_warning (lc_sql) << "Error : no database for" << filename;
            return false;
        }

        sqlite3_busy_timeout (_database, 5000);

        return true;
    }


    private CheckDbResult check_database () {
        // quick_check can fail with a disk IO error when diskspace is low
        SqlQuery quick_check (*this);

        if (quick_check.prepare ("PRAGMA quick_check;", /*allow_failure=*/true) != SQLITE_OK) {
            q_c_warning (lc_sql) << "Error preparing quick_check on database";
            _err_id = quick_check.error_id ();
            _error = quick_check.error ();
            return CheckDbResult.CANT_PREPARE;
        }
        if (!quick_check.exec ()) {
            q_c_warning (lc_sql) << "Error running quick_check on database";
            _err_id = quick_check.error_id ();
            _error = quick_check.error ();
            return CheckDbResult.Cant_exec;
        }

        quick_check.next ();
        string result = quick_check.string_value (0);
        if (result != QLatin1String ("ok")) {
            q_c_warning (lc_sql) << "quick_check returned failure:" << result;
            return CheckDbResult.Not_ok;
        }

        return CheckDbResult.OK;
    }
};

/***********************************************************
@brief The SqlQuery class
@ingroup libsync

There is basically 3 ways to initialize and use a query:

    SqlQuery q1;
    [...]
    q1.init_or_reset (...);
    q1.bind_value (...);
    q1.exec (...)

    SqlQuery q2 (database);
    q2.prepare (...);
    [...]
    q2.reset_and_clear_bindings ();
    q2.bind_value (...);
    q2.exec (...)

    SqlQuery q3 ("...", database);
    q3.bind_value (...);
    q3.exec (...)

***********************************************************/
class SqlQuery {
    // Q_DISABLE_COPY (SqlQuery)

    private SqlDatabase _sqldatabase = nullptr;
    private Sqlite3 _database = nullptr;
    private Sqlite3Stmt _stmt = nullptr;
    private string _error;
    private int _err_id;
    private GLib.ByteArray _sql;

    private friend class SqlDatabase;
    private friend class PreparedSqlQueryManager;

    public SqlQuery () = default;


    public SqlQuery (SqlDatabase &database)
        : _sqldatabase (&database)
        , _database (database.sqlite_database ()) {
    }


    public SqlQuery (GLib.ByteArray sql, SqlDatabase database)
        : _sqldatabase (&database)
        , _database (database.sqlite_database ()) {
        prepare (sql);
    }



    ~SqlQuery () {
        if (_stmt) {
            finish ();
        }
    }


    /***********************************************************
    Prepare the SqlQuery.
    If the query was already prepared, this will first call
    finish (), and re-prepare it. This function must only be
    used if the constructor was setting a SqlDatabase
    ***********************************************************/
    public int prepare (GLib.ByteArray sql, bool allow_failure = false) {
        _sql = sql.trimmed ();
        if (_stmt) {
            finish ();
        }
        if (!_sql.is_empty ()) {
            int n = 0;
            int rc = 0;
            do {
                rc = sqlite3_prepare_v2 (_database, _sql.const_data (), -1, &_stmt, nullptr);
                if ( (rc == SQLITE_BUSY) || (rc == SQLITE_LOCKED)) {
                    n++;
                    Occ.Utility.usleep (SQLITE_SLEEP_TIME_USEC);
                }
            } while ( (n < SQLITE_REPEAT_COUNT) && ( (rc == SQLITE_BUSY) || (rc == SQLITE_LOCKED)));
            _err_id = rc;

            if (_err_id != SQLITE_OK) {
                _error = string.from_utf8 (sqlite3_errmsg (_database));
                q_c_warning (lc_sql) << "Sqlite prepare statement error:" << _error << "in" << _sql;
                ENFORCE (allow_failure, "SQLITE Prepare error");
            } else {
                ASSERT (_stmt);
                _sqldatabase._queries.insert (this);
            }
        }
        return _err_id;
    }


    public string error () {
        return _error;
    }


    public int error_id () {
        return _err_id;
    }


    /// Checks whether the value at the given column index is NULL
    public bool null_value (int index) {
        return sqlite3_column_type (_stmt, index) == SQLITE_NULL;
    }


    public string string_value (int index) {
        return string.from_utf16 (static_cast<const ushort> (sqlite3_column_text16 (_stmt, index)));
    }


    public int int_value (int index) {
        return sqlite3_column_int (_stmt, index);
    }


    public uint64 int64_value (int index) {
        return sqlite3_column_int64 (_stmt, index);
    }


    public GLib.ByteArray byte_array_value (int index) {
        return GLib.ByteArray (static_cast<const char> (sqlite3_column_blob (_stmt, index)),
            sqlite3_column_bytes (_stmt, index));
    }


    public bool is_select () {
        return starts_with_insensitive (_sql, QByteArrayLiteral ("SELECT"));
    }


    public bool is_pragma () {
        return starts_with_insensitive (_sql, QByteArrayLiteral ("PRAGMA"));
    }


    /***********************************************************
    There is no overloads to GLib.ByteArray.start_with that takes Qt.CaseInsensitive.
    Returns true if 'a' starts with 'b' in a case insensitive way
    ***********************************************************/
    private static bool starts_with_insensitive (GLib.ByteArray a, GLib.ByteArray b) {
        return a.size () >= b.size () && qstrnicmp (a.const_data (), b.const_data (), static_cast<uint32> (b.size ())) == 0;
    }


    public bool exec () {
        q_c_debug (lc_sql) << "SQL exec" << _sql;

        if (!_stmt) {
            q_c_warning (lc_sql) << "Can't exec query, statement unprepared.";
            return false;
        }

        // Don't do anything for selects, that is how we use the lib :-|
        if (!is_select () && !is_pragma ()) {
            int rc = 0, n = 0;
            do {
                rc = sqlite3_step (_stmt);
                if (rc == SQLITE_LOCKED) {
                    rc = sqlite3_reset (_stmt); // This will also return SQLITE_LOCKED
                    n++;
                    Occ.Utility.usleep (SQLITE_SLEEP_TIME_USEC);
                } else if (rc == SQLITE_BUSY) {
                    Occ.Utility.usleep (SQLITE_SLEEP_TIME_USEC);
                    n++;
                }
            } while ( (n < SQLITE_REPEAT_COUNT) && ( (rc == SQLITE_BUSY) || (rc == SQLITE_LOCKED)));
            _err_id = rc;

            if (_err_id != SQLITE_DONE && _err_id != SQLITE_ROW) {
                _error = string.from_utf8 (sqlite3_errmsg (_database));
                q_c_warning (lc_sql) << "Sqlite exec statement error:" << _err_id << _error << "in" << _sql;
                if (_err_id == SQLITE_IOERR) {
                    q_c_warning (lc_sql) << "IOERR extended errcode : " << sqlite3_extended_errcode (_database);
    #if SQLITE_VERSION_NUMBER >= 3012000
                    q_c_warning (lc_sql) << "IOERR system errno : " << sqlite3_system_errno (_database);
    #endif
                }
            } else {
                q_c_debug (lc_sql) << "Last exec affected" << num_rows_affected () << "rows.";
            }
            return (_err_id == SQLITE_DONE); // either SQLITE_ROW or SQLITE_DONE
        }

        return true;
    }


    public struct NextResult {
        bool ok = false;
        bool has_data = false;
    };


    public NextResult next () {
        const bool first_step = !Sqlite3Stmt_busy (_stmt);

        int n = 0;
        forever {
            _err_id = sqlite3_step (_stmt);
            if (n < SQLITE_REPEAT_COUNT && first_step && (_err_id == SQLITE_LOCKED || _err_id == SQLITE_BUSY)) {
                sqlite3_reset (_stmt); // not necessary after sqlite version 3.6.23.1
                n++;
                Occ.Utility.usleep (SQLITE_SLEEP_TIME_USEC);
            } else {
                break;
            }
        }

        NextResult result;
        result.ok = _err_id == SQLITE_ROW || _err_id == SQLITE_DONE;
        result.has_data = _err_id == SQLITE_ROW;
        if (!result.ok) {
            _error = string.from_utf8 (sqlite3_errmsg (_database));
            q_c_warning (lc_sql) << "Sqlite step statement error:" << _err_id << _error << "in" << _sql;
        }

        return result;
    }

    public template<class T, typename std.enable_if<std.is_enum<T>.value, int>.type = 0>
    public void bind_value (int pos, T &value) {
        q_c_debug (lc_sql) << "SQL bind" << pos << value;
        bind_value_internal (pos, static_cast<int> (value));
    }


    public template<class T, typename std.enable_if<!std.is_enum<T>.value, int>.type = 0>
    public void bind_value (int pos, T &value) {
        q_c_debug (lc_sql) << "SQL bind" << pos << value;
        bind_value_internal (pos, value);
    }


    public void bind_value (int pos, GLib.ByteArray value) {
        q_c_debug (lc_sql) << "SQL bind" << pos << string.from_utf8 (value);
        bind_value_internal (pos, value);
    }


    public const GLib.ByteArray last_query () {
        return _sql;
    }


    public int num_rows_affected () {
        return sqlite3_changes (_database);
    }


    public void reset_and_clear_bindings () {
        if (_stmt) {
            SQLITE_DO (sqlite3_reset (_stmt));
            SQLITE_DO (sqlite3_clear_bindings (_stmt));
        }
    }


    private void bind_value_internal (int pos, QVariant &value) {
        int res = -1;
        if (!_stmt) {
            ASSERT (false);
            return;
        }

        switch (value.type ()) {
        case QVariant.Int:
        case QVariant.Bool:
            res = sqlite3_bind_int (_stmt, pos, value.to_int ());
            break;
        case QVariant.Double:
            res = sqlite3_bind_double (_stmt, pos, value.to_double ());
            break;
        case QVariant.UInt:
        case QVariant.Long_long:
        case QVariant.ULong_long:
            res = sqlite3_bind_int64 (_stmt, pos, value.to_long_long ());
            break;
        case QVariant.Date_time: {
            const QDateTime date_time = value.to_date_time ();
            const string str = date_time.to_string (QStringLiteral ("yyyy-MM-dd_thh:mm:ss.zzz"));
            res = sqlite3_bind_text16 (_stmt, pos, str.utf16 (),
                str.size () * static_cast<int> (sizeof (ushort)), SQLITE_TRANSIENT);
            break;
        }
        case QVariant.Time: {
            const QTime time = value.to_time ();
            const string str = time.to_string (QStringLiteral ("hh:mm:ss.zzz"));
            res = sqlite3_bind_text16 (_stmt, pos, str.utf16 (),
                str.size () * static_cast<int> (sizeof (ushort)), SQLITE_TRANSIENT);
            break;
        }
        case QVariant.String: {
            if (!value.to_string ().is_null ()) {
                // lifetime of string == lifetime of its qvariant
                const var str = static_cast<const string> (value.const_data ());
                res = sqlite3_bind_text16 (_stmt, pos, str.utf16 (),
                    (str.size ()) * static_cast<int> (sizeof (QChar)), SQLITE_TRANSIENT);
            } else {
                res = sqlite3_bind_null (_stmt, pos);
            }
            break;
        }
        case QVariant.Byte_array: {
            var ba = value.to_byte_array ();
            res = sqlite3_bind_text (_stmt, pos, ba.const_data (), ba.size (), SQLITE_TRANSIENT);
            break;
        }
        default: {
            string str = value.to_string ();
            // SQLITE_TRANSIENT makes sure that sqlite buffers the data
            res = sqlite3_bind_text16 (_stmt, pos, str.utf16 (),
                (str.size ()) * static_cast<int> (sizeof (QChar)), SQLITE_TRANSIENT);
            break;
        }
        }
        if (res != SQLITE_OK) {
            q_c_warning (lc_sql) << "ERROR binding SQL value:" << value << "error:" << res;
        }
        ASSERT (res == SQLITE_OK);
    }


    private void finish () {
        if (!_stmt)
            return;
        SQLITE_DO (sqlite3_finalize (_stmt));
        _stmt = nullptr;
        if (_sqldatabase) {
            _sqldatabase._queries.remove (this);
        }
    }
};

} // namespace Occ
