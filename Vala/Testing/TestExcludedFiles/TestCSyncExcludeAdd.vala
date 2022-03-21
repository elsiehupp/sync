namespace Occ {
namespace Testing {

/***********************************************************
@class TestCSyncExcludeAdd

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCSyncExcludeAdd : AbstractTestCSyncExclude {

    /***********************************************************
    ***********************************************************/
    private TestCSyncExcludeAdd () {
        up ();
        excluded_files.add_manual_exclude ("/temporary/check_csync1/*");
        GLib.assert_true (check_file_full ("/temporary/check_csync1/foo") == CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_full ("/temporary/check_csync2/foo") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        GLib.assert_true (excluded_files.all_excludes["/"].contains ("/temporary/check_csync1/*"));

        GLib.assert_true (excluded_files.full_regex_file["/"].pattern ().contains ("csync1"));
        GLib.assert_true (excluded_files.full_traversal_regex_file["/"].pattern ().contains ("csync1"));
        GLib.assert_true (!excluded_files.bname_traversal_regex_file["/"].pattern ().contains ("csync1"));

        excluded_files.add_manual_exclude ("foo");
        GLib.assert_true (excluded_files.bname_traversal_regex_file["/"].pattern ().contains ("foo"));
        GLib.assert_true (excluded_files.full_regex_file["/"].pattern ().contains ("foo"));
        GLib.assert_true (!excluded_files.full_traversal_regex_file["/"].pattern ().contains ("foo"));
    }

} // class TestCSyncExcludeAdd

} // namespace Testing
} // namespace Occ
