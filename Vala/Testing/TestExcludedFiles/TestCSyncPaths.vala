namespace Occ {
namespace Testing {

/***********************************************************
@class TestCSyncPaths

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCSyncPaths : AbstractTestCSyncExclude {

    /***********************************************************
    ***********************************************************/
    private TestCSyncPaths () {
        base ();
        excluded_files.add_manual_exclude ("/exclude");
        excluded_files.reload_exclude_files ();

        /* Check toplevel directory, the pattern only works for toplevel directory. */
        GLib.assert_cassert_truemp (check_dir_full ("/exclude") == CSync.ExcludedFiles.Type.LIST);

        GLib.assert_true (check_dir_full ("/foo/exclude") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        /* check for a file called exclude. Must still work */
        GLib.assert_true (check_file_full ("/exclude") == CSync.ExcludedFiles.Type.LIST);

        GLib.assert_true (check_file_full ("/foo/exclude") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        /* Add an exclude for directories only : excl/ */
        excluded_files.add_manual_exclude ("excl/");
        excluded_files.reload_exclude_files ();
        GLib.assert_true (check_dir_full ("/excl") == CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_dir_full ("meep/excl") == CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_full ("meep/excl/file") == CSync.ExcludedFiles.Type.LIST);

        GLib.assert_true (check_file_full ("/excl") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        excluded_files.add_manual_exclude ("/excludepath/withsubdir");
        excluded_files.reload_exclude_files ();

        GLib.assert_true (check_dir_full ("/excludepath/withsubdir") == CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_full ("/excludepath/withsubdir") == CSync.ExcludedFiles.Type.LIST);

        GLib.assert_true (check_dir_full ("/excludepath/withsubdir2") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        GLib.assert_true (check_dir_full ("/excludepath/withsubdir/foo") == CSync.ExcludedFiles.Type.LIST);
    }

} // class TestCSyncPaths

} // namespace Testing
} // namespace Occ
