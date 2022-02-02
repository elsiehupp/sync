/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QFileInfo>
// #include <QDir>

using Sqlite3;


// #include <QLoggingCategory>

using Sqlite3;
struct Sqlite3Stmt;

namespace Occ {

OCSYNC_EXPORT Q_DECLARE_LOGGING_CATEGORY (lc_sql)

const int SQLITE_SLEEP_TIME_USEC = 100000
const int SQLITE_REPEAT_COUNT = 20

const int SQLITE_DO (A) {
    if (1) {
        this.err_id = (A);
        if (this.err_id != SQLITE_OK && this.err_id != SQLITE_DONE && this.err_id != SQLITE_ROW) {
            this.error = string.from_utf8 (sqlite3_errmsg (this.database));
        }
    }
}


/***********************************************************
@brief The SqlDatabase class
@ingroup libsync
***********************************************************/
class SqlDatabase {
    // Q_DISABLE_COPY (SqlDatabase)

    /***********************************************************
    ***********************************************************/
    private Sqlite3 this.database = nullptr;
    private string this.error; // last error string
    private int this.err_id = 0;

    /***********************************************************
    ***********************************************************/
    private friend class SqlQuery;
    private GLib.Set<SqlQuery> this.queries;

    /***********************************************************
    ***********************************************************/
    public SqlDatabase () = default;


    ~SqlDatabase () {
        close ();
    }


    /***********************************************************
    ***********************************************************/
    public bool is_open () {
        return this.database != nullptr;
    }


    /***********************************************************
    ***********************************************************/
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
                    GLib.warn (lc_sql) << "Can't prepare consistency check and disk space is low:" << free_space;
                    close ();
                    return false;
                }

                // Even when there's enough disk space, it might very well be that the
                // file is on a read-only filesystem and can't be opened because of that.
                if (this.err_id == SQLITE_CANTOPEN) {
                    GLib.warn (lc_sql) << "Can't open database to prepare consistency check, aborting";
                    close ();
                    return false;
                }
            }

            q_c_critical (lc_sql) << "Consistency check failed, removing broken database" << filename;
            close ();
            GLib.File.remove (filename);

            return open_helper (filename, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE);
        }

        return true;
    }


    /***********************************************************
    ***********************************************************/
    public bool open_read_only (string filename) {
        if (is_open ()) {
            return true;
        }

        if (!open_helper (filename, SQLITE_OPEN_READONLY)) {
            return false;
        }

        if (check_database () != CheckDbResult.OK) {
            GLib.warn (lc_sql) << "Consistency check failed in read_only mode, giving up" << filename;
            close ();
            return false;
        }

        return true;
    }


    /***********************************************************
    ***********************************************************/
    public bool transaction () {
        if (!this.database) {
            return false;
        }
        SQLITE_DO (sqlite3_exec (this.database, "BEGIN", nullptr, nullptr, nullptr));
        return this.err_id == SQLITE_OK;
    }


    /***********************************************************
    ***********************************************************/
    public bool commit () {
        if (!this.database) {
            return false;
        }
        SQLITE_DO (sqlite3_exec (this.database, "COMMIT", nullptr, nullptr, nullptr));
        return this.err_id == SQLITE_OK;
    }


    /***********************************************************
    ***********************************************************/
    public void close () {
        if (this.database) {
            foreach (var q, this.queries) {
                q.finish ();
            }
            SQLITE_DO (sqlite3_close (this.database));
            if (this.err_id != SQLITE_OK)
                GLib.warn (lc_sql) << "Closing database failed" << this.error;
            this.database = nullptr;
        }
    }


    /***********************************************************
    ***********************************************************/
    public string error () {
        const string err (this.error);
        // this.error.clear ();
        return err;
    }


    /***********************************************************
    ***********************************************************/
    public Sqlite3 sqlite_database () {
        return this.database;
    }


    /***********************************************************
    ***********************************************************/
    private enum CheckDbResult {
        Ok,
        CheckDbResult.CANT_PREPARE,
        Cant_exec,
        Not_ok,
    };

    /***********************************************************
    ***********************************************************/
    private bool open_helper (string filename, int sqlite_flags) {
        if (is_open ()) {
            return true;
        }

        sqlite_flags |= SQLITE_OPEN_NOMUTEX;

        SQLITE_DO (sqlite3_open_v2 (filename.to_utf8 ().const_data (), this.database, sqlite_flags, nullptr));

        if (this.err_id != SQLITE_OK) {
            GLib.warn (lc_sql) << "Error:" << this.error << "for" << filename;
            if (this.err_id == SQLITE_CANTOPEN) {
                GLib.warn (lc_sql) << "CANTOPEN extended errcode : " << sqlite3_extended_errcode (this.database);
    #if SQLITE_VERSION_NUMBER >= 3012000
                GLib.warn (lc_sql) << "CANTOPEN system errno : " << sqlite3_system_errno (this.database);
    #endif
            }
            close ();
            return false;
        }

        if (!this.database) {
            GLib.warn (lc_sql) << "Error : no database for" << filename;
            return false;
        }

        sqlite3_busy_timeout (this.database, 5000);

        return true;
    }


    /***********************************************************
    ***********************************************************/
    private CheckDbResult check_database () {
        // quick_check can fail with a disk IO error when diskspace is low
        SqlQuery quick_check (*this);

        if (quick_check.prepare ("PRAGMA quick_check;", /*allow_failure=*/true) != SQLITE_OK) {
            GLib.warn (lc_sql) << "Error preparing quick_check on database";
            this.err_id = quick_check.error_id ();
            this.error = quick_check.error ();
            return CheckDbResult.CANT_PREPARE;
        }
        if (!quick_check.exec ()) {
            GLib.warn (lc_sql) << "Error running quick_check on database";
            this.err_id = quick_check.error_id ();
            this.error = quick_check.error ();
            return CheckDbResult.Cant_exec;
        }

        quick_check.next ();
        string result = quick_check.string_value (0);
        if (result != QLatin1String ("ok")) {
            GLib.warn (lc_sql) << "quick_check returned failure:" << result;
            return CheckDbResult.Not_ok;
        }

        return CheckDbResult.OK;
    }
}

} // namespace Occ
