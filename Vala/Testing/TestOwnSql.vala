/***********************************************************
   This software is in the public domain, furnished "as is", without technical
      support, and with no warranty, express or implied, as to its usefulness for
         any purpose.
         */

//  #include <QtTest>
//  #include <sqlite3.h>

using Occ;

namespace Testing {

class TestOwnSql : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private SqlDatabase database;

    QTemporaryDir temporary_directory;

    /***********************************************************
    ***********************************************************/
    private void testOpenDb () {
        GLib.FileInfo file_info = new GLib.FileInfo ( this.temporary_directory.path () + "/testdatabase.sqlite" );
        GLib.assert_true ( !file_info.exists () ); // must not exist
        this.database.openOrCreateReadWrite (file_info.file_path ());
        file_info.refresh ();
        GLib.assert_true (file_info.exists ());
    }


    /***********************************************************
    ***********************************************************/
    private void testCreate () {
        const string sql = "CREATE TABLE addresses ( identifier INTEGER, name VARCHAR (4096), "
                         + "address VARCHAR (4096), entered INTEGER (8), PRIMARY KEY (identifier));";

        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);
        GLib.assert_true (query.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private void testIsSelect () {
        SqlQuery query = new SqlQuery (this.database);
        query.prepare ("SELECT identifier FROM addresses;");
        GLib.assert_true ( query.isSelect () );

        query.prepare ("UPDATE addresses SET identifier = 1;");
        GLib.assert_true ( !query.isSelect ());
    }


    /***********************************************************
    ***********************************************************/
    private void testInsert () {
        const string sql = "INSERT INTO addresses (identifier, name, address, entered) VALUES "
                         + " (1, 'Gonzo Alberto', 'Moriabata 24, Palermo', 1403100844);";
        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);
        GLib.assert_true (query.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private void testInsert2 () {
        const string sql = "INSERT INTO addresses (identifier, name, address, entered) VALUES "
                         + " (?1, ?2, ?3, ?4);";
        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);
        query.bindValue (1, 2);
        query.bindValue (2, "Brucely Lafayette");
        query.bindValue (3, "Nurderway5, New York");
        query.bindValue (4, 1403101224);
        GLib.assert_true (query.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private void testSelect () {
        const string sql = "SELECT * FROM addresses;";

        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);

        query.exec ();
        while ( query.next ().hasData ) {
            GLib.debug ("Name: " + query.stringValue (1));
            GLib.debug ("Address: " + query.stringValue (2));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testSelect2 () {
        const string sql = "SELECT * FROM addresses WHERE identifier=?1";
        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);
        query.bindValue (1, 2);
        query.exec ();
        if ( query.next ().hasData ) {
            GLib.debug ("Name:" + query.stringValue (1));
            GLib.debug ("Address:" + query.stringValue (2));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testPragma () {
        const string sql = "PRAGMA table_info (addresses)";

        SqlQuery query = new SqlQuery (this.database);
        int rc = query.prepare (sql);
        GLib.debug ("Pragma: " + rc);
        query.exec ();
        if (query.next ().hasData) {
            GLib.debug ("P: " + query.stringValue (1));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testUnicode () {
        const string sql = "INSERT INTO addresses (identifier, name, address, entered) VALUES "
                         + " (?1, ?2, ?3, ?4);";
        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);
        query.bindValue (1, 3);
        query.bindValue (2, string.fromUtf8 ("пятницы"));
        query.bindValue (3, string.fromUtf8 ("проспект"));
        query.bindValue (4, 1403002224);
        GLib.assert_true (query.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private void testReadUnicode () {
        const string sql = "SELECT * FROM addresses WHERE identifier=3;";
        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);

        if (query.next ().hasData) {
            string name = query.stringValue (1);
            string address = query.stringValue (2);
            GLib.assert_true ( name == string.fromUtf8 ("пятницы") );
            GLib.assert_true ( address == string.fromUtf8 ("проспект"));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testDestructor () {
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
