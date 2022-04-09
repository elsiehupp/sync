namespace Occ {
namespace Testing {

/***********************************************************
@class TestFilenamesEqual

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestFilenamesEqual : AbstractTestUtility {

    /***********************************************************
    ***********************************************************/
    private TestFilenamesEqual () {
        GLib.TemporaryDir directory;
        GLib.assert_true (directory.is_valid);
        GLib.Dir dir2 = new GLib.Dir (directory.path);
        GLib.assert_true (dir2.mkpath ("test"));
        if ( !filesystem_case_preserving () ) {
        GLib.assert_true (dir2.mkpath ("test_string"));
        }
        GLib.assert_true (dir2.mkpath ("test/TESTI"));
        GLib.assert_true (dir2.mkpath ("TESTI"));

        string a = directory.path;
        string b = directory.path;

        GLib.assert_true (file_names_equal (a, b));

        GLib.assert_true (file_names_equal (a+"/test", b+"/test")); // both exist
        GLib.assert_true (file_names_equal (a+"/test/TESTI", b+"/test/../test/TESTI")); // both exist

        GLib.ScopedValueRollback<bool> scope = new GLib.ScopedValueRollback<bool> (filesystem_case_preserving_override, true);
        GLib.assert_true (file_names_equal (a+"/test", b+"/test_string")); // both exist

        GLib.assert_true (!file_names_equal (a+"/test", b+"/test/TESTI")); // both are different

        directory.remove ();
    }

} // class TestFilenamesEqual

} // namespace Testing
} // namespace Occ
