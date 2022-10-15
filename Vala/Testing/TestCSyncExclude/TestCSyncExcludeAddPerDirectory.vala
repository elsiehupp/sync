namespace Occ {
namespace Testing {

/***********************************************************
@class TestCSyncExcludeAddPerDirectory

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCSyncExcludeAddPerDirectory : AbstractTestCSyncExclude {

    /***********************************************************
    ***********************************************************/
    private TestCSyncExcludeAddPerDirectory () {
        //  up ();
        //  excluded_files.add_manual_exclude ("*", "/temporary/check_csync1/");
        //  GLib.assert_true (check_file_full ("/temporary/check_csync1/foo") == CSync.CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_full ("/temporary/check_csync2/foo") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (excluded_files.all_excludes["/temporary/check_csync1/"].contains ("*"));

        //  excluded_files.add_manual_exclude ("foo");
        //  GLib.assert_true (excluded_files.full_regex_file["/"].pattern ().contains ("foo"));

        //  excluded_files.add_manual_exclude ("foo/bar", "/temporary/check_csync1/");
        //  GLib.assert_true (excluded_files.full_regex_file["/temporary/check_csync1/"].pattern ().contains ("bar"));
        //  GLib.assert_true (excluded_files.full_traversal_regex_file["/temporary/check_csync1/"].pattern ().contains ("bar"));
        //  GLib.assert_true (!excluded_files.bname_traversal_regex_file["/temporary/check_csync1/"].pattern ().contains ("foo"));
    }

} // class TestCSyncExcludeAddPerDirectory

} // namespace Testing
} // namespace Occ
