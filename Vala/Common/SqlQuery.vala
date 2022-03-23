namespace Occ {
namespace Common {

/***********************************************************
@class SqlQuery

@brief The SqlQuery class

@details There are basically 3 ways to initialize and use a
query: {

    SqlQuery q1;
    [...]
    q1.init_or_reset (...);
    q1.bind_value (...);
    q1.exec (...)

    SqlQuery q2 (sqlite_database);
    q2.prepare (...);
    [...]
    q2.reset_and_clear_bindings ();
    q2.bind_value (...);
    q2.exec (...)

    SqlQuery q3 ("...", sqlite_database);
    q3.bind_value (...);
    q3.exec (...)
}

@author Klaas Freitag <freitag@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/
public class SqlQuery : GLib.Object {

    // Q_DISABLE_COPY (SqlQuery)

    /***********************************************************
    ***********************************************************/
    private Sqlite.Database sqlite_database = null;
    private Sqlite.Statement sqlite_statement = null;
    public string error { public get; private set; }
    private int err_id;
    private string sql;

    /***********************************************************
    ***********************************************************/
    //  private friend class Sqlite.Database;
    //  private friend class PreparedSqlQueryManager;

    /***********************************************************
    ***********************************************************/
    //  public SqlQuery () = default;

    /***********************************************************
    ***********************************************************/
    public SqlQuery (Sqlite.Database sqlite_database) {
        this.sqlite_database = sqlite_database;
    }


    /***********************************************************
    ***********************************************************/
    public SqlQuery.with_string (string sql, Sqlite.Database sqlite_database) {
        this.sqlite_database = sqlite_database;
        prepare (sql);
    }


    ~SqlQuery () {
        if (this.sqlite_statement != null) {
            finish ();
        }
    }


    /***********************************************************
    Prepare the SqlQuery.
    If the query was already prepared, this will first call
    finish (), and re-prepare it. This function must only be
    used if the constructor was setting a Sqlite.Database
    ***********************************************************/
    public int prepare (string sql, bool allow_failure = false) {
        this.sql = sql.trimmed ();
        if (this.sqlite_statement) {
            finish ();
        }
        if (!this.sql == "") {
            int n = 0;
            int rc = 0;
            do {
                rc = sqlite3_prepare_v2 (this.sqlite_database, this.sql.const_data (), -1, this.sqlite_statement, null);
                if ( (rc == Sqlite.BUSY) || (rc == Sqlite.LOCKED)) {
                    n++;
                    Utility.usleep (Sqlite.SLEEP_TIME_USEC);
                }
            } while ( (n < Sqlite.REPEAT_COUNT) && ( (rc == Sqlite.BUSY) || (rc == Sqlite.LOCKED)));
            this.err_id = rc;

            if (this.err_id != Sqlite.OK) {
                this.error = string.from_utf8 (sqlite3_errmsg (this.sqlite_database));
                GLib.warning ("Sqlite prepare sqlite_statement error:" + this.error + "in" + this.sql;
                //  ENFORCE (allow_failure, "SQLITE Prepare error");
            } else {
                //  ASSERT (this.sqlite_statement);
                this.sqlite_database.queries.insert (this);
            }
        }
        return this.err_id;
    }


    /***********************************************************
    ***********************************************************/
    public int error_id {
        public get;
    }


    /***********************************************************
    Checks whether the value at the given column index is NULL
    ***********************************************************/
    public bool null_value (int index) {
        return sqlite3_column_type (this.sqlite_statement, index) == Sqlite.NULL;
    }


    /***********************************************************
    ***********************************************************/
    public string string_value (int index) {
        return string.from_utf16 (static_cast<const ushort> (sqlite3_column_text16 (this.sqlite_statement, index)));
    }


    /***********************************************************
    ***********************************************************/
    public int int_value (int index) {
        return sqlite3_column_int (this.sqlite_statement, index);
    }


    /***********************************************************
    ***********************************************************/
    public uint64 int64_value (int index) {
        return sqlite3_column_int64 (this.sqlite_statement, index);
    }


    /***********************************************************
    ***********************************************************/
    public string byte_array_value (int index) {
        return string (static_cast<const char> (sqlite3_column_blob (this.sqlite_statement, index)),
            sqlite3_column_bytes (this.sqlite_statement, index));
    }


    /***********************************************************
    ***********************************************************/
    public bool is_select () {
        return starts_with_insensitive (this.sql, "SELECT");
    }


    /***********************************************************
    ***********************************************************/
    public bool is_pragma () {
        return starts_with_insensitive (this.sql, "PRAGMA");
    }


    /***********************************************************
    There is no overloads to string.start_with that takes Qt.CaseInsensitive.
    Returns true if 'a' starts with 'b' in a case insensitive way
    ***********************************************************/
    private static bool starts_with_insensitive (string a, string b) {
        return a.length >= b.length && qstrnicmp (a.const_data (), b.const_data (), static_cast<uint32> (b.length)) == 0;
    }


    /***********************************************************
    ***********************************************************/
    public bool exec () {
        GLib.debug ("SQL exec" + this.sql;

        if (!this.sqlite_statement) {
            GLib.warning ("Can't exec query, sqlite_statement unprepared.";
            return false;
        }

        // Don't do anything for selects, that is how we use the lib :-|
        if (!is_select () && !is_pragma ()) {
            int rc = 0, n = 0;
            do {
                rc = sqlite3_step (this.sqlite_statement);
                if (rc == Sqlite.LOCKED) {
                    rc = sqlite3_reset (this.sqlite_statement); // This will also return Sqlite.LOCKED
                    n++;
                    Utility.usleep (Sqlite.SLEEP_TIME_USEC);
                } else if (rc == Sqlite.BUSY) {
                    Utility.usleep (Sqlite.SLEEP_TIME_USEC);
                    n++;
                }
            } while ( (n < Sqlite.REPEAT_COUNT) && ( (rc == Sqlite.BUSY) || (rc == Sqlite.LOCKED)));
            this.err_id = rc;

            if (this.err_id != Sqlite.DONE && this.err_id != Sqlite.ROW) {
                this.error = string.from_utf8 (sqlite3_errmsg (this.sqlite_database));
                GLib.warning ("Sqlite exec sqlite_statement error:" + this.err_id + this.error + "in" + this.sql;
                if (this.err_id == Sqlite.IOERR) {
                    GLib.warning ("IOERR extended errcode: " + sqlite3_extended_errcode (this.sqlite_database);
    #if Sqlite.VERSION_NUMBER >= 3012000
                    GLib.warning ("IOERR system errno: " + sqlite3_system_errno (this.sqlite_database);
    #endif
                }
            } else {
                GLib.debug ("Last exec affected" + number_of_rows_affected ("rows.";
            }
            return (this.err_id == Sqlite.DONE); // either Sqlite.ROW or Sqlite.DONE
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
        const bool first_step = !Sqlite3StmtBusy (this.sqlite_statement);

        int n = 0;
        while (true) {
            this.err_id = sqlite3_step (this.sqlite_statement);
            if (n < Sqlite.REPEAT_COUNT && first_step && (this.err_id == Sqlite.LOCKED || this.err_id == Sqlite.BUSY)) {
                sqlite3_reset (this.sqlite_statement); // not necessary after sqlite version 3.6.23.1
                n++;
                Utility.usleep (Sqlite.SLEEP_TIME_USEC);
            } else {
                break;
            }
        }

        NextResult result;
        result.ok = this.err_id == Sqlite.ROW || this.err_id == Sqlite.DONE;
        result.has_data = this.err_id == Sqlite.ROW;
        if (!result.ok) {
            this.error = string.from_utf8 (sqlite3_errmsg (this.sqlite_database));
            GLib.warning ("Sqlite step sqlite_statement error:" + this.err_id + this.error + "in" + this.sql;
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
    //  public template<class T, typename std.enable_if<!std.is_enum<T>.value, int>.type = 0>
    public void bind_value_generic<T> (int pos, T value) {
        GLib.debug ("SQL bind " + pos + value);
        bind_value_internal (pos, value.to_string ());
    }


    /***********************************************************
    ***********************************************************/
    public void bind_value (int pos, string value) {
        GLib.debug ("SQL bind " + pos + value);
        bind_value_internal (pos, value);
    }


    /***********************************************************
    ***********************************************************/
    public const string last_query () {
        return this.sql;
    }


    /***********************************************************
    ***********************************************************/
    public int number_of_rows_affected () {
        return sqlite3_changes (this.sqlite_database);
    }


    /***********************************************************
    ***********************************************************/
    public void reset_and_clear_bindings () {
        if (this.sqlite_statement) {
            sqlite_do (sqlite3_reset (this.sqlite_statement));
            sqlite_do (sqlite3_clear_bindings (this.sqlite_statement));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void bind_value_internal (int pos, GLib.Variant value) {
        int res = -1;
        if (!this.sqlite_statement) {
            //  ASSERT (false);
            return;
        }

        switch (value.type ()) {
        case GLib.Variant.Int:
        case GLib.Variant.Bool:
            res = sqlite3_bind_int (this.sqlite_statement, pos, value.to_int ());
            break;
        case GLib.Variant.Double:
            res = sqlite3_bind_double (this.sqlite_statement, pos, value.to_double ());
            break;
        case GLib.Variant.UInt:
        case GLib.Variant.Long_long:
        case GLib.Variant.ULong_long:
            res = sqlite3_bind_int64 (this.sqlite_statement, pos, value.to_long_long ());
            break;
        case GLib.Variant.Date_time: {
            const GLib.DateTime date_time = value.to_date_time ();
            const string string_value = date_time.to_string ("yyyy-MM-dd_thh:mm:ss.zzz");
            res = sqlite3_bind_text16 (this.sqlite_statement, pos, string_value.utf16 (),
                string_value.length * static_cast<int> (sizeof (ushort)), Sqlite.TRANSIENT);
            break;
        }
        case GLib.Variant.Time: {
            const QTime time = value.to_time ();
            const string string_value = time.to_string ("hh:mm:ss.zzz");
            res = sqlite3_bind_text16 (this.sqlite_statement, pos, string_value.utf16 (),
                string_value.length * static_cast<int> (sizeof (ushort)), Sqlite.TRANSIENT);
            break;
        }
        case GLib.Variant.String: {
            if (!value.to_string () == null) {
                // lifetime of string == lifetime of its qvariant
                const var string_value = static_cast<const string> (value.const_data ());
                res = sqlite3_bind_text16 (this.sqlite_statement, pos, string_value.utf16 (),
                    (string_value.length) * static_cast<int> (sizeof (char)), Sqlite.TRANSIENT);
            } else {
                res = sqlite3_bind_null (this.sqlite_statement, pos);
            }
            break;
        }
        case GLib.Variant.Byte_array: {
            var ba = value.to_byte_array ();
            res = sqlite3_bind_text (this.sqlite_statement, pos, ba.const_data (), ba.length, Sqlite.TRANSIENT);
            break;
        }
        default: {
            string string_value = value.to_string ();
            // Sqlite.TRANSIENT makes sure that sqlite buffers the data
            res = sqlite3_bind_text16 (this.sqlite_statement, pos, string_value.utf16 (),
                (string_value.length) * static_cast<int> (sizeof (char)), Sqlite.TRANSIENT);
            break;
        }
        }
        if (res != Sqlite.OK) {
            GLib.warning ("ERROR binding SQL value:" + value + "error:" + res;
        }
        //  ASSERT (res == Sqlite.OK);
    }


    /***********************************************************
    ***********************************************************/
    private void finish () {
        if (!this.sqlite_statement)
            return;
        sqlite_do (sqlite3_finalize (this.sqlite_statement));
        this.sqlite_statement = null;
        if (this.sqlite_database) {
            this.sqlite_database.queries.remove (this);
        }
    }

} // class SqlQuery

} // namespace Common
} // namespace Occ
