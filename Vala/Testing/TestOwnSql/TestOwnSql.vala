/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

using Sqlite3;

namespace Occ {
namespace Testing {

public class TestOwnSql : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private SqlDatabase database;

    QTemporaryDir temporary_directory;

    /***********************************************************
    ***********************************************************/
    private TestOpenDatabase () {
        GLib.FileInfo file_info = new GLib.FileInfo ( this.temporary_directory.path + "/testdatabase.sqlite" );
        GLib.assert_true ( !file_info.exists () ); // must not exist
        this.database.open_or_create_read_write (file_info.file_path);
        file_info.refresh ();
        GLib.assert_true (file_info.exists ());
    }


    /***********************************************************
    ***********************************************************/
    private TestCreate () {
        const string sql = "CREATE TABLE addresses ( identifier INTEGER, name VARCHAR (4096), "
                         + "address VARCHAR (4096), entered INTEGER (8), PRIMARY KEY (identifier));";

        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);
        GLib.assert_true (query.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private TestIsSelect () {
        SqlQuery query = new SqlQuery (this.database);
        query.prepare ("SELECT identifier FROM addresses;");
        GLib.assert_true (query.is_select ());

        query.prepare ("UPDATE addresses SET identifier = 1;");
        GLib.assert_true (!query.is_select ());
    }


    /***********************************************************
    ***********************************************************/
    private TestInsert () {
        const string sql = "INSERT INTO addresses (identifier, name, address, entered) VALUES "
                         + " (1, 'Gonzo Alberto', 'Moriabata 24, Palermo', 1403100844);";
        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);
        GLib.assert_true (query.exec ());
    }


    /***********************************************************
    ***********************************************************/
    private TestInsert2 () {
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
    private TestSelect () {
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
    private TestSelect2 () {
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
    private TestPragma () {
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
    private TestUnicode () {
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
    private TestReadUnicode () {
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
    private TestDestructor () {
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
} // namespace Occ
