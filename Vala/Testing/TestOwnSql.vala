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

    QTemporaryDir this.temporary_directory;

    /***********************************************************
    ***********************************************************/
    private void testOpenDb () {
        GLib.FileInfo file_info = new GLib.FileInfo ( this.temporary_directory.path () + "/testdatabase.sqlite" );
        //  QVERIFY ( !file_info.exists () ); // must not exist
        this.database.openOrCreateReadWrite (file_info.filePath ());
        file_info.refresh ();
        //  QVERIFY (file_info.exists ());
    }


    /***********************************************************
    ***********************************************************/
    private void testCreate () {
        const string sql = "CREATE TABLE addresses ( identifier INTEGER, name VARCHAR (4096), "
                "address VARCHAR (4096), entered INTEGER (8), PRIMARY KEY (identifier));";

        SqlQuery q (this.database);
        q.prepare (sql);
        //  QVERIFY (q.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private void testIsSelect () {
        SqlQuery q (this.database);
        q.prepare ("SELECT identifier FROM addresses;");
        //  QVERIFY ( q.isSelect () );

        q.prepare ("UPDATE addresses SET identifier = 1;");
        //  QVERIFY ( !q.isSelect ());
    }


    /***********************************************************
    ***********************************************************/
    private void testInsert () {
        const string sql = "INSERT INTO addresses (identifier, name, address, entered) VALUES "
                " (1, 'Gonzo Alberto', 'Moriabata 24, Palermo', 1403100844);";
        SqlQuery q (this.database);
        q.prepare (sql);
        //  QVERIFY (q.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private void testInsert2 () {
        const string sql = "INSERT INTO addresses (identifier, name, address, entered) VALUES "
                " (?1, ?2, ?3, ?4);";
        SqlQuery q (this.database);
        q.prepare (sql);
        q.bindValue (1, 2);
        q.bindValue (2, "Brucely Lafayette");
        q.bindValue (3, "Nurderway5, New York");
        q.bindValue (4, 1403101224);
        //  QVERIFY (q.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private void testSelect () {
        const string sql = "SELECT * FROM addresses;";

        SqlQuery q (this.database);
        q.prepare (sql);

        q.exec ();
        while ( q.next ().hasData ) {
            GLib.debug ("Name : " + q.stringValue (1);
            GLib.debug ("Address : " + q.stringValue (2);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testSelect2 () {
        const string sql = "SELECT * FROM addresses WHERE identifier=?1";
        SqlQuery q (this.database);
        q.prepare (sql);
        q.bindValue (1, 2);
        q.exec ();
        if ( q.next ().hasData ) {
            GLib.debug ("Name:" + q.stringValue (1);
            GLib.debug ("Address:" + q.stringValue (2);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testPragma () {
        const string sql = "PRAGMA table_info (addresses)";

        SqlQuery q (this.database);
        int rc = q.prepare (sql);
        GLib.debug ("Pragma:" + rc;
        q.exec ();
        if ( q.next ().hasData ) {
            GLib.debug ("P:" + q.stringValue (1);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testUnicode () {
        const string sql = "INSERT INTO addresses (identifier, name, address, entered) VALUES "
                " (?1, ?2, ?3, ?4);";
        SqlQuery q (this.database);
        q.prepare (sql);
        q.bindValue (1, 3);
        q.bindValue (2, string.fromUtf8 ("пятницы"));
        q.bindValue (3, string.fromUtf8 ("проспект"));
        q.bindValue (4, 1403002224);
        //  QVERIFY (q.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private void testReadUnicode () {
        const string sql = "SELECT * FROM addresses WHERE identifier=3;";
        SqlQuery q (this.database);
        q.prepare (sql);

        if (q.next ().hasData) {
            string name = q.stringValue (1);
            string address = q.stringValue (2);
            //  QVERIFY ( name == string.fromUtf8 ("пятницы") );
            //  QVERIFY ( address == string.fromUtf8 ("проспект"));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testDestructor () {
        // This test make sure that the destructor of SqlQuery works even if the SqlDatabase
        // is destroyed before
        QScopedPointer<SqlDatabase> database (new SqlDatabase ());
        SqlQuery q1 (this.database);
        SqlQuery q2 (this.database);
        q2.prepare ("SELECT * FROM addresses");
        SqlQuery q3 ("SELECT * FROM addresses", this.database);
        SqlQuery q4;
        database.on_signal_reset ();
    }


    /***********************************************************
    ***********************************************************/
    private SqlDatabase this.database;
}

QTEST_APPLESS_MAIN (TestOwnSql)
