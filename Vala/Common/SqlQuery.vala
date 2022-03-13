/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

using Sqlite3;
struct Sqlite3Stmt;

namespace Occ {

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
public class SqlQuery {
    // Q_DISABLE_COPY (SqlQuery)

    /***********************************************************
    ***********************************************************/
    private SqlDatabase this.sqldatabase = null;
    private Sqlite3 this.database = null;
    private Sqlite3Stmt this.stmt = null;
    private string this.error;
    private int this.err_id;
    private GLib.ByteArray this.sql;

    /***********************************************************
    ***********************************************************/
    private friend class SqlDatabase;
    private friend class PreparedSqlQueryManager;

    /***********************************************************
    ***********************************************************/
    public SqlQuery () = default;

    /***********************************************************
    ***********************************************************/
    public SqlQuery (SqlDatabase database)
        : this.sqldatabase (&database)
        this.database (database.sqlite_database ()) {
    }


    /***********************************************************
    ***********************************************************/
    public SqlQuery (GLib.ByteArray sql, SqlDatabase database)
        : this.sqldatabase (&database)
        this.database (database.sqlite_database ()) {
        prepare (sql);
    }



    ~SqlQuery () {
        if (this.stmt) {
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
        this.sql = sql.trimmed ();
        if (this.stmt) {
            finish ();
        }
        if (!this.sql.is_empty ()) {
            int n = 0;
            int rc = 0;
            do {
                rc = sqlite3_prepare_v2 (this.database, this.sql.const_data (), -1, this.stmt, null);
                if ( (rc == SQLITE_BUSY) || (rc == SQLITE_LOCKED)) {
                    n++;
                    Occ.Utility.usleep (SQLITE_SLEEP_TIME_USEC);
                }
            } while ( (n < SQLITE_REPEAT_COUNT) && ( (rc == SQLITE_BUSY) || (rc == SQLITE_LOCKED)));
            this.err_id = rc;

            if (this.err_id != SQLITE_OK) {
                this.error = string.from_utf8 (sqlite3_errmsg (this.database));
                GLib.warning ("Sqlite prepare statement error:" + this.error + "in" + this.sql;
                ENFORCE (allow_failure, "SQLITE Prepare error");
            } else {
                //  ASSERT (this.stmt);
                this.sqldatabase.queries.insert (this);
            }
        }
        return this.err_id;
    }


    /***********************************************************
    ***********************************************************/
    public string error () {
        return this.error;
    }


    /***********************************************************
    ***********************************************************/
    public int error_id () {
        return this.err_id;
    }


    /***********************************************************
    Checks whether the value at the given column index is NULL
    ***********************************************************/
    public bool null_value (int index) {
        return sqlite3_column_type (this.stmt, index) == SQLITE_NULL;
    }


    /***********************************************************
    ***********************************************************/
    public string string_value (int index) {
        return string.from_utf16 (static_cast<const ushort> (sqlite3_column_text16 (this.stmt, index)));
    }


    /***********************************************************
    ***********************************************************/
    public int int_value (int index) {
        return sqlite3_column_int (this.stmt, index);
    }


    /***********************************************************
    ***********************************************************/
    public uint64 int64_value (int index) {
        return sqlite3_column_int64 (this.stmt, index);
    }


    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray byte_array_value (int index) {
        return GLib.ByteArray (static_cast<const char> (sqlite3_column_blob (this.stmt, index)),
            sqlite3_column_bytes (this.stmt, index));
    }


    /***********************************************************
    ***********************************************************/
    public bool is_select () {
        return starts_with_insensitive (this.sql, QByteArrayLiteral ("SELECT"));
    }


    /***********************************************************
    ***********************************************************/
    public bool is_pragma () {
        return starts_with_insensitive (this.sql, QByteArrayLiteral ("PRAGMA"));
    }


    /***********************************************************
    There is no overloads to GLib.ByteArray.start_with that takes Qt.CaseInsensitive.
    Returns true if 'a' starts with 'b' in a case insensitive way
    ***********************************************************/
    private static bool starts_with_insensitive (GLib.ByteArray a, GLib.ByteArray b) {
        return a.size () >= b.size () && qstrnicmp (a.const_data (), b.const_data (), static_cast<uint32> (b.size ())) == 0;
    }


    /***********************************************************
    ***********************************************************/
    public bool exec () {
        GLib.debug ("SQL exec" + this.sql;

        if (!this.stmt) {
            GLib.warning ("Can't exec query, statement unprepared.";
            return false;
        }

        // Don't do anything for selects, that is how we use the lib :-|
        if (!is_select () && !is_pragma ()) {
            int rc = 0, n = 0;
            do {
                rc = sqlite3_step (this.stmt);
                if (rc == SQLITE_LOCKED) {
                    rc = sqlite3_reset (this.stmt); // This will also return SQLITE_LOCKED
                    n++;
                    Occ.Utility.usleep (SQLITE_SLEEP_TIME_USEC);
                } else if (rc == SQLITE_BUSY) {
                    Occ.Utility.usleep (SQLITE_SLEEP_TIME_USEC);
                    n++;
                }
            } while ( (n < SQLITE_REPEAT_COUNT) && ( (rc == SQLITE_BUSY) || (rc == SQLITE_LOCKED)));
            this.err_id = rc;

            if (this.err_id != SQLITE_DONE && this.err_id != SQLITE_ROW) {
                this.error = string.from_utf8 (sqlite3_errmsg (this.database));
                GLib.warning ("Sqlite exec statement error:" + this.err_id + this.error + "in" + this.sql;
                if (this.err_id == SQLITE_IOERR) {
                    GLib.warning ("IOERR extended errcode: " + sqlite3_extended_errcode (this.database);
    #if SQLITE_VERSION_NUMBER >= 3012000
                    GLib.warning ("IOERR system errno: " + sqlite3_system_errno (this.database);
    #endif
                }
            } else {
                GLib.debug ("Last exec affected" + num_rows_affected ("rows.";
            }
            return (this.err_id == SQLITE_DONE); // either SQLITE_ROW or SQLITE_DONE
        }

        return true;
    }


    /***********************************************************
    ***********************************************************/
    public struct NextResult {
        bool ok = false;
        bool has_data = false;
    }


    /***********************************************************
    ***********************************************************/
    public NextResult next () {
        const bool first_step = !Sqlite3StmtBusy (this.stmt);

        int n = 0;
        while (true) {
            this.err_id = sqlite3_step (this.stmt);
            if (n < SQLITE_REPEAT_COUNT && first_step && (this.err_id == SQLITE_LOCKED || this.err_id == SQLITE_BUSY)) {
                sqlite3_reset (this.stmt); // not necessary after sqlite version 3.6.23.1
                n++;
                Occ.Utility.usleep (SQLITE_SLEEP_TIME_USEC);
            } else {
                break;
            }
        }

        NextResult result;
        result.ok = this.err_id == SQLITE_ROW || this.err_id == SQLITE_DONE;
        result.has_data = this.err_id == SQLITE_ROW;
        if (!result.ok) {
            this.error = string.from_utf8 (sqlite3_errmsg (this.database));
            GLib.warning ("Sqlite step statement error:" + this.err_id + this.error + "in" + this.sql;
        }

        return result;
    }


    /***********************************************************
    ***********************************************************/
    public template<class T, typename std.enable_if<std.is_enum<T>.value, int>.type = 0>
    public void bind_value (int pos, T value) {
        GLib.debug ("SQL bind" + pos + value;
        bind_value_internal (pos, static_cast<int> (value));
    }


    /***********************************************************
    ***********************************************************/
    public template<class T, typename std.enable_if<!std.is_enum<T>.value, int>.type = 0>
    public void bind_value (int pos, T value) {
        GLib.debug ("SQL bind" + pos + value;
        bind_value_internal (pos, value);
    }


    /***********************************************************
    ***********************************************************/
    public void bind_value (int pos, GLib.ByteArray value) {
        GLib.debug ("SQL bind" + pos + string.from_utf8 (value);
        bind_value_internal (pos, value);
    }


    /***********************************************************
    ***********************************************************/
    public const GLib.ByteArray last_query () {
        return this.sql;
    }


    /***********************************************************
    ***********************************************************/
    public int num_rows_affected () {
        return sqlite3_changes (this.database);
    }


    /***********************************************************
    ***********************************************************/
    public void reset_and_clear_bindings () {
        if (this.stmt) {
            sqlite_do (sqlite3_reset (this.stmt));
            sqlite_do (sqlite3_clear_bindings (this.stmt));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void bind_value_internal (int pos, GLib.Variant value) {
        int res = -1;
        if (!this.stmt) {
            //  ASSERT (false);
            return;
        }

        switch (value.type ()) {
        case GLib.Variant.Int:
        case GLib.Variant.Bool:
            res = sqlite3_bind_int (this.stmt, pos, value.to_int ());
            break;
        case GLib.Variant.Double:
            res = sqlite3_bind_double (this.stmt, pos, value.to_double ());
            break;
        case GLib.Variant.UInt:
        case GLib.Variant.Long_long:
        case GLib.Variant.ULong_long:
            res = sqlite3_bind_int64 (this.stmt, pos, value.to_long_long ());
            break;
        case GLib.Variant.Date_time: {
            const GLib.DateTime date_time = value.to_date_time ();
            const string string_value = date_time.to_string ("yyyy-MM-dd_thh:mm:ss.zzz");
            res = sqlite3_bind_text16 (this.stmt, pos, string_value.utf16 (),
                string_value.size () * static_cast<int> (sizeof (ushort)), SQLITE_TRANSIENT);
            break;
        }
        case GLib.Variant.Time: {
            const QTime time = value.to_time ();
            const string string_value = time.to_string ("hh:mm:ss.zzz");
            res = sqlite3_bind_text16 (this.stmt, pos, string_value.utf16 (),
                string_value.size () * static_cast<int> (sizeof (ushort)), SQLITE_TRANSIENT);
            break;
        }
        case GLib.Variant.String: {
            if (!value.to_string ().is_null ()) {
                // lifetime of string == lifetime of its qvariant
                const var string_value = static_cast<const string> (value.const_data ());
                res = sqlite3_bind_text16 (this.stmt, pos, string_value.utf16 (),
                    (string_value.size ()) * static_cast<int> (sizeof (char)), SQLITE_TRANSIENT);
            } else {
                res = sqlite3_bind_null (this.stmt, pos);
            }
            break;
        }
        case GLib.Variant.Byte_array: {
            var ba = value.to_byte_array ();
            res = sqlite3_bind_text (this.stmt, pos, ba.const_data (), ba.size (), SQLITE_TRANSIENT);
            break;
        }
        default: {
            string string_value = value.to_string ();
            // SQLITE_TRANSIENT makes sure that sqlite buffers the data
            res = sqlite3_bind_text16 (this.stmt, pos, string_value.utf16 (),
                (string_value.size ()) * static_cast<int> (sizeof (char)), SQLITE_TRANSIENT);
            break;
        }
        }
        if (res != SQLITE_OK) {
            GLib.warning ("ERROR binding SQL value:" + value + "error:" + res;
        }
        //  ASSERT (res == SQLITE_OK);
    }


    /***********************************************************
    ***********************************************************/
    private void finish () {
        if (!this.stmt)
            return;
        sqlite_do (sqlite3_finalize (this.stmt));
        this.stmt = null;
        if (this.sqldatabase) {
            this.sqldatabase.queries.remove (this);
        }
    }
}

} // namespace Occ
