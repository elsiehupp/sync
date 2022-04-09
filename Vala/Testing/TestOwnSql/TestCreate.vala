namespace Occ {
namespace Testing {

/***********************************************************
@class TestCreate

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCreate : AbstractTestOwnSql {

    /***********************************************************
    ***********************************************************/
    private TestCreate () {
        base ();

        string sql = "CREATE TABLE addresses ( identifier INTEGER, name VARCHAR (4096), "
                         + "address VARCHAR (4096), entered INTEGER (8), PRIMARY KEY (identifier));";

        SqlQuery query = new SqlQuery (this.database);
        query.prepare (sql);
        GLib.assert_true (query.exec ());
    }

} // class TestCreate

} // namespace Testing
} // namespace Occ
