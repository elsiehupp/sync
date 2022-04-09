namespace Occ {
namespace Testing {

/***********************************************************
@class TestSelect2

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestSelect2 : AbstractTestOwnSql {

    /***********************************************************
    ***********************************************************/
    private TestSelect2 () {
        base ();

        string sql = "SELECT * FROM addresses;";

        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);

        query.exec ();
        while ( query.next ().has_data ) {
            GLib.debug ("Name: " + query.string_value (1));
            GLib.debug ("Address: " + query.string_value (2));
        }
    }

} // class TestSelect2

} // namespace Testing
} // namespace Occ
