namespace Occ {
namespace Testing {

/***********************************************************
@class TestUnicodeRead

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestUnicodeRead : AbstractTestOwnSql {

    /***********************************************************
    ***********************************************************/
    private TestUnicodeRead () {
        //  base ();

        //  string sql = "SELECT * FROM addresses WHERE identifier=3;";
        //  SqlQuery query = new SqlQuery (this.database);
        //  query.prepare (sql);

        //  if (query.next ().has_data) {
        //      string name = query.string_value (1);
        //      string address = query.string_value (2);
        //      GLib.assert_true (name == "пятницы");
        //      GLib.assert_true (address == "проспект");
        //  }
    }

} // class TestUnicodeRead

} // namespace Testing
} // namespace Occ
