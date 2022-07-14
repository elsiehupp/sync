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

    /***********************************************************
    ***********************************************************/
    private Sqlite.Database sqlite_database = null;
    private Sqlite.Statement sqlite_statement = null;
    public string error { public get; private set; }
    public int error_id { public get; private set; }
    private string sql;

    /***********************************************************
    private friend class Sqlite.Database;
    private friend class PreparedSqlQueryManager;
    ***********************************************************/


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
        if (this.sqlite_statement != null) {
            finish ();
        }
        if (this.sql != "") {
            int n = 0;
            int rc = 0;
            do {
                rc = this.sqlite_database.prepare_v2 (this.sql, -1, this.sqlite_statement, null);
                if ( (rc == Sqlite.BUSY) || (rc == Sqlite.LOCKED)) {
                    n++;
                    Utility.usleep (Sqlite.SLEEP_TIME_USEC);
                }
            } while ( (n < Sqlite.REPEAT_COUNT) && ( (rc == Sqlite.BUSY) || (rc == Sqlite.LOCKED)));
            this.error_id = rc;

            if (this.error_id != Sqlite.OK) {
                this.error = this.sqlite_database.errmsg ();
                GLib.warning ("Sqlite prepare sqlite_statement error:" + this.error + "in" + this.sql);
                /***********************************************************
                ENFORCE (allow_failure, "SQLITE Prepare error");
                ***********************************************************/
            } else {
                GLib.assert_true (this.sqlite_statement != null);
                this.sqlite_database.queries.insert (this);
            }
        }
        return this.error_id;
    }


    /***********************************************************
    Checks whether the value at the given column index is NULL
    ***********************************************************/
    public bool null_value (int index) {
        return this.sqlite_statement.column_type (index) == Sqlite.NULL;
    }


    /***********************************************************
    ***********************************************************/
    public string string_value (int index) {
        return string.from_utf16 (
            (ushort)this.sqlite_statement.column_text16 (index)
        );
    }


    /***********************************************************
    ***********************************************************/
    public int int_value (int index) {
        return this.sqlite_statement.column_int (index);
    }


    /***********************************************************
    ***********************************************************/
    public uint64 int64_value (int index) {
        return this.sqlite_statement.column_int64 (index);
    }


    /***********************************************************
    ***********************************************************/
    public string byte_array_value (int index) {
        return (string)(
            (char)this.sqlite_statement.column_blob (index),
            this.sqlite_statement.column_bytes (index)
        );
    }


    /***********************************************************
    ***********************************************************/
    public bool is_select () {
        return this.sql.down ().has_prefix ("SELECT".down ());
    }


    /***********************************************************
    ***********************************************************/
    public bool is_pragma () {
        return this.sql.down ().has_prefix ("PRAGMA".down ());
    }


    /***********************************************************
    ***********************************************************/
    public bool exec () {
        GLib.debug ("SQL exec" + this.sql);

        if (this.sqlite_statement == null) {
            GLib.warning ("Can't exec query, sqlite_statement unprepared.");
            return false;
        }

        /***********************************************************
        Don't do anything for selects, that is how we use the lib :-|
        ***********************************************************/
        if (!is_select () && !is_pragma ()) {
            int rc = 0, n = 0;
            do {
                rc = this.sqlite_statement.step ();
                if (rc == Sqlite.LOCKED) {
                    /***********************************************************
                    This will also return Sqlite.LOCKED
                    ***********************************************************/
                    rc = this.sqlite_statement.reset ();
                    n++;
                    Utility.usleep (Sqlite.SLEEP_TIME_USEC);
                } else if (rc == Sqlite.BUSY) {
                    Utility.usleep (Sqlite.SLEEP_TIME_USEC);
                    n++;
                }
            } while ((n < Sqlite.REPEAT_COUNT) && ( (rc == Sqlite.BUSY) || (rc == Sqlite.LOCKED)));
            this.error_id = rc;

            if (this.error_id != Sqlite.DONE && this.error_id != Sqlite.ROW) {
                this.error = this.sqlite_database.errmsg ().to_string ();
                GLib.warning ("Sqlite exec sqlite_statement error:" + this.error_id.to_string () + this.error + "in" + this.sql);
                if (this.error_id == Sqlite.IOERR) {
                    GLib.warning ("IOERR errcode: " + this.sqlite_database.errcode ().to_string () + this.sqlite_database.errmsg ());
                }
            } else {
                GLib.debug ("Last exec affected " + number_of_rows_affected ().to_string () + " rows.");
            }
            /***********************************************************
            Either Sqlite.ROW or Sqlite.DONE
            ***********************************************************/
            return (this.error_id == Sqlite.DONE);
        }

        return true;
    }


    /***********************************************************
    ***********************************************************/
    public class NextResult {
        public bool ok = false;
        public bool has_data = false;
    }


    /***********************************************************
    ***********************************************************/
    public NextResult next () {
        bool first_step = !Sqlite3StmtBusy (this.sqlite_statement);

        int n = 0;
        while (true) {
            this.error_id = this.sqlite_statement.step ();
            if (n < Sqlite.REPEAT_COUNT && first_step && (this.error_id == Sqlite.LOCKED || this.error_id == Sqlite.BUSY)) {
                /***********************************************************
                reset () is not necessary after sqlite version 3.6.23.1
                ***********************************************************/
                this.sqlite_statement.reset ();
                n++;
                Utility.usleep (Sqlite.SLEEP_TIME_USEC);
            } else {
                break;
            }
        }

        NextResult result = new NextResult ();
        result.ok = this.error_id == Sqlite.ROW || this.error_id == Sqlite.DONE;
        result.has_data = this.error_id == Sqlite.ROW;
        if (!result.ok) {
            this.error = this.sqlite_database.errmsg ();
            GLib.warning ("Sqlite step sqlite_statement error:" + this.error_id.to_string () + this.error + "in" + this.sql);
        }

        return result;
    }


    /***********************************************************
    ***********************************************************/
    public void bind_value<T> (int pos, T value) {
        GLib.debug ("SQL bind" + pos.to_string () + (string)value);
        bind_value_internal (pos, (int)value);
    }


    /***********************************************************
    ***********************************************************/
    public void bind_value_string (int pos, string value) {
        GLib.debug ("SQL bind " + pos.to_string () + value.to_string ());
        bind_value_internal (pos, value);
    }


    /***********************************************************
    ***********************************************************/
    public string last_query () {
        return this.sql;
    }


    /***********************************************************
    ***********************************************************/
    public int number_of_rows_affected () {
        return this.sqlite_database.changes ();
    }


    /***********************************************************
    ***********************************************************/
    public void reset_and_clear_bindings () {
        if (this.sqlite_statement != null) {
            sqlite_do (this.sqlite_statement.reset ());
            sqlite_do (this.sqlite_statement.clear_bindings ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private void bind_value_internal (int pos, GLib.Variant value) {
        int res = -1;
        if (this.sqlite_statement == null) {
            GLib.assert_true (false);
            return;
        }

        switch (value.get_type ()) {
        case GLib.VariantType.INT:
        case GLib.VariantType.BOOLEAN:
            res = this.sqlite_statement.bind_int (pos, value.to_int ());
            break;
        case GLib.VariantType.DOUBLE:
            res = this.sqlite_statement.bind_double (pos, value.to_double ());
            break;
        case GLib.VariantType.UINT:
        case GLib.VariantType.INT64:
        case GLib.VariantType.UINT64:
            res = this.sqlite_statement.bind_int64 (pos, value.to_long_long ());
            break;
        case GLib.VariantType.DATE_TIME: {
            GLib.DateTime date_time = value.to_date_time ();
            string string_value = date_time.to_string ("yyyy-MM-dd_thh:mm:ss.zzz");
            res = this.sqlite_statement.bind_text16 (pos, string_value.utf16 (),
                string_value.length * (int)sizeof (ushort), Sqlite.TRANSIENT);
            break;
        }
        case GLib.VariantType.TIME: {
            GLib.Time time = value.to_time ();
            string string_value = time.to_string ("hh:mm:ss.zzz");
            res = this.sqlite_statement.bind_text16 (pos, string_value.utf16 (),
                string_value.length * (int)sizeof (ushort), Sqlite.TRANSIENT);
            break;
        }
        case GLib.VariantType.STRING: {
            if (value.to_string () != null) {
                /***********************************************************
                lifetime of string == lifetime of its variant
                ***********************************************************/
                string string_value = (string)value.const_data ();
                res = this.sqlite_statement.bind_text16 (pos, string_value.utf16 (),
                    (string_value.length) * (int)sizeof (char), Sqlite.TRANSIENT);
            } else {
                res = this.sqlite_statement.bind_null (pos);
            }
            break;
        }
        case GLib.VariantType.BYTE_ARRAY: {
            var ba = value.to_byte_array ();
            res = this.sqlite_statement.bind_text (pos, ba.const_data (), ba.length, Sqlite.TRANSIENT);
            break;
        }
        default: {
            string string_value = value.to_string ();
            /***********************************************************
            Sqlite.TRANSIENT makes sure that sqlite buffers the data
            ***********************************************************/
            res = this.sqlite_statement.bind_text16 (
                pos,
                value.to_string ().utf16 (),
                (value.to_string ().length) * (int)sizeof (char),
                Sqlite.TRANSIENT
            );
            break;
        }
        }
        if (res != Sqlite.OK) {
            GLib.warning ("ERROR binding SQL value:" + value.to_string () + "error:" + res.to_string ());
        }
        GLib.assert_true (res == Sqlite.OK);
    }


    /***********************************************************
    ***********************************************************/
    internal void finish () {
        if (this.sqlite_statement == null) {
            return;
        }
        sqlite_do (this.sqlite_statement.finalize ());
        this.sqlite_statement = null;
        if (this.sqlite_database != null) {
            this.sqlite_database.queries.remove (this);
        }
    }

} // class SqlQuery

} // namespace Common
} // namespace Occ
