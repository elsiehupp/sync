namespace Occ {
namespace Testing {

/***********************************************************
@class TestCSyncWildcards

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCSyncWildcards : AbstractTestCSyncExclude {

    /***********************************************************
    ***********************************************************/
    private TestCSyncWildcards () {
        up ();
        excluded_files.add_manual_exclude ("a/foo*bar");
        excluded_files.add_manual_exclude ("b/foo*bar*");
        excluded_files.add_manual_exclude ("c/foo?bar");
        excluded_files.add_manual_exclude ("d/foo?bar*");
        excluded_files.add_manual_exclude ("e/foo?bar?");
        excluded_files.add_manual_exclude ("g/bar*");
        excluded_files.add_manual_exclude ("h/bar?");

        excluded_files.set_wildcards_match_slash (false);

        GLib.assert_true (check_file_traversal ("a/foo_xyz_bar") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_traversal ("a/foo_x/z_bar") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        GLib.assert_true (check_file_traversal ("b/foo_xyz_bar_abc") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_traversal ("b/foo_x/z_bar_abc") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        GLib.assert_true (check_file_traversal ("c/foo_x_bar") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_traversal ("c/foo/bar") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        GLib.assert_true (check_file_traversal ("d/foo_x_bar_abc") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_traversal ("d/foo/bar_abc") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        GLib.assert_true (check_file_traversal ("e/foo_x_bar_a") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_traversal ("e/foo/bar_a") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        GLib.assert_true (check_file_traversal ("g/bar_abc") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_traversal ("g/x_bar_abc") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        GLib.assert_true (check_file_traversal ("h/bar_z") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_traversal ("h/x_bar_z") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        excluded_files.set_wildcards_match_slash (true);

        GLib.assert_true (check_file_traversal ("a/foo_x/z_bar") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_traversal ("b/foo_x/z_bar_abc") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_traversal ("c/foo/bar") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_traversal ("d/foo/bar_abc") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_traversal ("e/foo/bar_a") == CSync.CSync.ExcludedFiles.Type.LIST);
    }

} // class TestCSyncWildcards

} // namespace Testing
} // namespace Occ
