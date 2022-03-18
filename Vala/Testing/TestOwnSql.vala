/***********************************************************
   This software is in the public domain, furnished "as is", without technical
      support, and with no warranty, express or implied, as to its usefulness for
         any purpose.
         */

//  #include <QtTest>
//  #include <sqlite3.h>

using Occ;

namespace Testing {

public class TestOwnSql : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private SqlDatabase database;

    QTemporaryDir temporary_directory;

    /***********************************************************
    ***********************************************************/
    private void test_open_database () {
        GLib.FileInfo file_info = new GLib.FileInfo ( this.temporary_directory.path + "/testdatabase.sqlite" );
        GLib.assert_true ( !file_info.exists () ); // must not exist
        this.database.open_or_create_read_write (file_info.file_path);
        file_info.refresh ();
        GLib.assert_true (file_info.exists ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_create () {
        const string sql = "CREATE TABLE addresses ( identifier INTEGER, name VARCHAR (4096), "
                         + "address VARCHAR (4096), entered INTEGER (8), PRIMARY KEY (identifier));";

        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);
        GLib.assert_true (query.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_is_select () {
        SqlQuery query = new SqlQuery (this.database);
        query.prepare ("SELECT identifier FROM addresses;");
        GLib.assert_true (query.is_select ());

        query.prepare ("UPDATE addresses SET identifier = 1;");
        GLib.assert_true (!query.is_select ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_insert () {
        const string sql = "INSERT INTO addresses (identifier, name, address, entered) VALUES "
                         + " (1, 'Gonzo Alberto', 'Moriabata 24, Palermo', 1403100844);";
        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);
        GLib.assert_true (query.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_insert2 () {
        const string sql = "INSERT INTO addresses (identifier, name, address, entered) VALUES "
                         + " (?1, ?2, ?3, ?4);";
        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);
        query.bind_value (1, 2);
        query.bind_value (2, "Brucely Lafayette");
        query.bind_value (3, "Nurderway5, New York");
        query.bind_value (4, 1403101224);
        GLib.assert_true (query.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_select () {
        const string sql = "SELECT * FROM addresses;";

        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);

        query.exec ();
        while ( query.next ().has_data ) {
            GLib.debug ("Name: " + query.string_value (1));
            GLib.debug ("Address: " + query.string_value (2));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void test_select2 () {
        const string sql = "SELECT * FROM addresses WHERE identifier=?1";
        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);
        query.bind_value (1, 2);
        query.exec ();
        if (query.next ().has_data) {
            GLib.debug ("Name:" + query.string_value (1));
            GLib.debug ("Address:" + query.string_value (2));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void test_pragma () {
        const string sql = "PRAGMA table_info (addresses)";

        SqlQuery query = new SqlQuery (this.database);
        int rc = query.prepare (sql);
        GLib.debug ("Pragma: " + rc);
        query.exec ();
        if (query.next ().has_data) {
            GLib.debug ("P: " + query.string_value (1));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void test_unicode () {
        const string sql = "INSERT INTO addresses (identifier, name, address, entered) VALUES "
                         + " (?1, ?2, ?3, ?4);";
        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);
        query.bind_value (1, 3);
        query.bind_value (2, "пятницы");
        query.bind_value (3, "проспект");
        query.bind_value (4, 1403002224);
        GLib.assert_true (query.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_read_unicode () {
        const string sql = "SELECT * FROM addresses WHERE identifier=3;";
        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);

        if (query.next ().has_data) {
            string name = query.string_value (1);
            string address = query.string_value (2);
            GLib.assert_true (name == "пятницы");
            GLib.assert_true (address == "проспект");
        }
    }


    /***********************************************************
    ***********************************************************/
    private void test_destructor () {
        // This test make sure that the destructor of SqlQuery works even if the SqlDatabase
        // is destroyed before
        SqlDatabase database = new SqlDatabase ();
        SqlQuery query_1 = new SqlQuery (this.database);
        SqlQuery query_2 = new SqlQuery (this.database);
        query_2.prepare ("SELECT * FROM addresses");
        SqlQuery query_3 = new SqlQuery ("SELECT * FROM addresses", this.database);
        SqlQuery query_4;
        database.on_signal_reset ();
    }

} // class TestOwnSql
} // namespace Testing
