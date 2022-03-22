namespace Occ {
namespace Common {

/***********************************************************
@class SqlDatabase

@brief The SqlDatabase class

@author Klaas Freitag <freitag@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/
public class SqlDatabase : GLib.Object {

    using Sqlite3;

    // Q_DISABLE_COPY (SqlDatabase)

    /***********************************************************
    ***********************************************************/
    private enum CheckDbResult {
        OK,
        CANT_PREPARE,
        CANT_EXEC,
        NOT_OKAY,
    }

    const int SQLITE_SLEEP_TIME_USEC = 100000;
    const int SQLITE_REPEAT_COUNT = 20;


    /***********************************************************
    ***********************************************************/
    private Sqlite3 database = null;

    /***********************************************************
    Last error string
    ***********************************************************/
    public string error {
        public get {
            unowned string last_error = this.error;
            this.error = ""; // was commented out
            return last_error;
        }
        private set {
            error = value;
        }
    }


    /***********************************************************
    ***********************************************************/
    private int err_id = 0;

    /***********************************************************
    ***********************************************************/
    //  private friend class SqlQuery;
    private GLib.Set<SqlQuery> queries;

    /***********************************************************
    ***********************************************************/
    //  public SqlDatabase () = default;


    ~SqlDatabase () {
        close ();
    }


    int sqlite_do (var A) {
        this.err_id = (A);
        if (this.err_id != SQLITE_OK && this.err_id != SQLITE_DONE && this.err_id != SQLITE_ROW) {
            this.error = string.from_utf8 (sqlite3_errmsg (this.database));
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool is_open {
        public get {
            return this.database != null;
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool open_or_create_read_write (string filename) {
        if (is_open) {
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
                int64 free_space = Utility.free_disk_space (GLib.FileInfo (filename).directory ().absolute_path);
                if (free_space != -1 && free_space < 1000000) {
                    GLib.warning ("Can't prepare consistency check and disk space is low: " + free_space);
                    close ();
                    return false;
                }

                // Even when there's enough disk space, it might very well be that the
                // file is on a read-only filesystem and can't be opened because of that.
                if (this.err_id == SQLITE_CANTOPEN) {
                    GLib.warning ("Can't open database to prepare consistency check, aborting.");
                    close ();
                    return false;
                }
            }

            GLib.critical ("Consistency check failed, removing broken database " + filename);
            close ();
            GLib.File.remove (filename);

            return open_helper (filename, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE);
        }

        return true;
    }


    /***********************************************************
    ***********************************************************/
    public bool open_read_only (string filename) {
        if (is_open) {
            return true;
        }

        if (!open_helper (filename, SQLITE_OPEN_READONLY)) {
            return false;
        }

        if (check_database () != CheckDbResult.OK) {
            GLib.warning ("Consistency check failed in read_only mode, giving up " + filename);
            close ();
            return false;
        }

        return true;
    }


    /***********************************************************
    ***********************************************************/
    public bool transaction () {
        if (this.database == null) {
            return false;
        }
        sqlite_do (sqlite3_exec (this.database, "BEGIN", null, null, null));
        return this.err_id == SQLITE_OK;
    }


    /***********************************************************
    ***********************************************************/
    public bool commit () {
        if (this.database == null) {
            return false;
        }
        sqlite_do (sqlite3_exec (this.database, "COMMIT", null, null, null));
        return this.err_id == SQLITE_OK;
    }


    /***********************************************************
    ***********************************************************/
    public void close () {
        if (this.database != null) {
            foreach (var q in this.queries) {
                q.finish ();
            }
            sqlite_do (sqlite3_close (this.database));
            if (this.err_id != SQLITE_OK)
                GLib.warning ("Closing database failed" + this.error);
            this.database = null;
        }
    }


    /***********************************************************
    ***********************************************************/
    public Sqlite3 sqlite_database () {
        return this.database;
    }


    /***********************************************************
    ***********************************************************/
    private bool open_helper (string filename, int sqlite_flags) {
        if (is_open) {
            return true;
        }

        sqlite_flags |= SQLITE_OPEN_NOMUTEX;

        sqlite_do (sqlite3_open_v2 (filename.to_utf8 ().const_data (), this.database, sqlite_flags, null));

        if (this.err_id != SQLITE_OK) {
            GLib.warning ("Error:" + this.error + "for" + filename);
            if (this.err_id == SQLITE_CANTOPEN) {
                //  GLib.warning ("CANTOPEN extended errcode: " + sqlite3_extended_errcode (this.database);
    //  #if SQLITE_VERSION_NUMBER >= 3012000
                GLib.warning ("CANTOPEN system errno: " + sqlite3_system_errno (this.database));
    //  #endif
            }
            close ();
            return false;
        }

        if (this.database == null) {
            GLib.warning ("Error : no database for" + filename);
            return false;
        }

        sqlite3_busy_timeout (this.database, 5000);

        return true;
    }


    /***********************************************************
    ***********************************************************/
    private CheckDbResult check_database () {
        // quick_check can fail with a disk IO error when diskspace is low
        SqlQuery quick_check = new SqlQuery (*this);

        if (quick_check.prepare ("PRAGMA quick_check;", /*allow_failure=*/true) != SQLITE_OK) {
            GLib.warning ("Error preparing quick_check on database");
            this.err_id = quick_check.error_id ();
            this.error = quick_check.error;
            return CheckDbResult.CANT_PREPARE;
        }
        if (!quick_check.exec ()) {
            GLib.warning ("Error running quick_check on database");
            this.err_id = quick_check.error_id ();
            this.error = quick_check.error;
            return CheckDbResult.CANT_EXEC;
        }

        quick_check.next ();
        string result = quick_check.string_value (0);
        if (result != "ok") {
            GLib.warning ("quick_check returned failure:" + result);
            return CheckDbResult.NOT_OKAY;
        }

        return CheckDbResult.OK;
    }

} // class SqlDatabase

} // namespace Common
} // namespace Occ
