namespace Occ {
namespace Testing {

/***********************************************************
@class TestSelect1

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestSelect1 : AbstractTestOwnSql {

    /***********************************************************
    ***********************************************************/
    private TestSelect1 () {
        base ();

        SqlQuery query = new SqlQuery (this.database);
        query.prepare ("SELECT identifier FROM addresses;");
        GLib.assert_true (query.is_select ());

        query.prepare ("UPDATE addresses SET identifier = 1;");
        GLib.assert_true (!query.is_select ());
    }

} // class TestSelect1

} // namespace Testing
} // namespace Occ
