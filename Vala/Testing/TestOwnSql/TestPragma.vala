namespace Occ {
namespace Testing {

/***********************************************************
@class TestPragma

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestPragma : AbstractTestOwnSql {

    /***********************************************************
    ***********************************************************/
    private TestPragma () {
        base ();

        const string sql = "PRAGMA table_info (addresses)";

        SqlQuery query = new SqlQuery (this.database);
        int rc = query.prepare (sql);
        GLib.debug ("Pragma: " + rc);
        query.exec ();
        if (query.next ().has_data) {
            GLib.debug ("P: " + query.string_value (1));
        }
    }

} // class TestPragma

} // namespace Testing
} // namespace Occ
