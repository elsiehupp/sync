/***********************************************************
   This software is in the public domain, furnished "as is", without technical
      support, and with no warranty, express or implied, as to its usefulness for
         any purpose.
         */

// #include <QtTest>

// #include <sqlite3.h>

using namespace Occ;

class TestOwnSql : GLib.Object {

    QTemporaryDir _tempDir;

    /***********************************************************
    ***********************************************************/
    private on_ void testOpenDb () {
        QFileInfo fi ( _tempDir.path () + "/testdatabase.sqlite" );
        QVERIFY ( !fi.exists () ); // must not exist
        _database.openOrCreateReadWrite (fi.filePath ());
        fi.refresh ();
        QVERIFY (fi.exists ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testCreate () {
        const char sql = "CREATE TABLE addresses ( id INTEGER, name VARCHAR (4096), "
                "address VARCHAR (4096), entered INTEGER (8), PRIMARY KEY (id));";

        SqlQuery q (_database);
        q.prepare (sql);
        QVERIFY (q.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testIsSelect () {
        SqlQuery q (_database);
        q.prepare ("SELECT id FROM addresses;");
        QVERIFY ( q.isSelect () );

        q.prepare ("UPDATE addresses SET id = 1;");
        QVERIFY ( !q.isSelect ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testInsert () {
        const char sql = "INSERT INTO addresses (id, name, address, entered) VALUES "
                " (1, 'Gonzo Alberto', 'Moriabata 24, Palermo', 1403100844);";
        SqlQuery q (_database);
        q.prepare (sql);
        QVERIFY (q.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testInsert2 () {
        const char sql = "INSERT INTO addresses (id, name, address, entered) VALUES "
                " (?1, ?2, ?3, ?4);";
        SqlQuery q (_database);
        q.prepare (sql);
        q.bindValue (1, 2);
        q.bindValue (2, "Brucely Lafayette");
        q.bindValue (3, "Nurderway5, New York");
        q.bindValue (4, 1403101224);
        QVERIFY (q.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSelect () {
        const char sql = "SELECT * FROM addresses;";

        SqlQuery q (_database);
        q.prepare (sql);

        q.exec ();
        while ( q.next ().hasData ) {
            qDebug () << "Name : " << q.stringValue (1);
            qDebug () << "Address : " << q.stringValue (2);
        }
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSelect2 () {
        const char sql = "SELECT * FROM addresses WHERE id=?1";
        SqlQuery q (_database);
        q.prepare (sql);
        q.bindValue (1, 2);
        q.exec ();
        if ( q.next ().hasData ) {
            qDebug () << "Name:" << q.stringValue (1);
            qDebug () << "Address:" << q.stringValue (2);
        }
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testPragma () {
        const char sql = "PRAGMA table_info (addresses)";

        SqlQuery q (_database);
        int rc = q.prepare (sql);
        qDebug () << "Pragma:" << rc;
        q.exec ();
        if ( q.next ().hasData ) {
            qDebug () << "P:" << q.stringValue (1);
        }
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testUnicode () {
        const char sql = "INSERT INTO addresses (id, name, address, entered) VALUES "
                " (?1, ?2, ?3, ?4);";
        SqlQuery q (_database);
        q.prepare (sql);
        q.bindValue (1, 3);
        q.bindValue (2, string.fromUtf8 ("пятницы"));
        q.bindValue (3, string.fromUtf8 ("проспект"));
        q.bindValue (4, 1403002224);
        QVERIFY (q.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testReadUnicode () {
        const char sql = "SELECT * FROM addresses WHERE id=3;";
        SqlQuery q (_database);
        q.prepare (sql);

        if (q.next ().hasData) {
            string name = q.stringValue (1);
            string address = q.stringValue (2);
            QVERIFY ( name == string.fromUtf8 ("пятницы") );
            QVERIFY ( address == string.fromUtf8 ("проспект"));
        }
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testDestructor () {
        // This test make sure that the destructor of SqlQuery works even if the SqlDatabase
        // is destroyed before
        QScopedPointer<SqlDatabase> database (new SqlDatabase ());
        SqlQuery q1 (_database);
        SqlQuery q2 (_database);
        q2.prepare ("SELECT * FROM addresses");
        SqlQuery q3 ("SELECT * FROM addresses", _database);
        SqlQuery q4;
        database.on_reset ();
    }


    /***********************************************************
    ***********************************************************/
    private SqlDatabase _database;
};

QTEST_APPLESS_MAIN (TestOwnSql)
