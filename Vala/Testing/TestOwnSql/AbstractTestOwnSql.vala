namespace Occ {
namespace Testing {

/***********************************************************
@class AbstractTestOwnSql

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public abstract class AbstractTestOwnSql { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    private Sqlite.Database database;

    GLib.TemporaryDir temporary_directory;

    /***********************************************************
    TestOpenDatabase
    ***********************************************************/
    protected AbstractTestOwnSql () {
        //  GLib.FileInfo file_info = new GLib.FileInfo ( this.temporary_directory.path + "/testdatabase.sqlite" );
        //  GLib.assert_true ( !file_info.exists () ); // must not exist
        //  this.database.open_or_create_read_write (file_info.file_path);
        //  file_info.refresh ();
        //  GLib.assert_true (file_info.exists ());
    }

} // class AbstractTestOwnSql

} // namespace Testing
} // namespace Occ
