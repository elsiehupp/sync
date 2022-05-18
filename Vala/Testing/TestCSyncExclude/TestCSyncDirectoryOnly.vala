namespace Occ {
namespace Testing {

/***********************************************************
@class TestCSyncDirectoryOnly

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCSyncDirectoryOnly : AbstractTestCSyncExclude {

    /***********************************************************
    ***********************************************************/
    private TestCSyncDirectoryOnly () {
        up ();
        excluded_files.add_manual_exclude ("filedir");
        excluded_files.add_manual_exclude ("directory/");

        GLib.assert_true (check_file_traversal ("other") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        GLib.assert_true (check_file_traversal ("filedir") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_traversal ("directory") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        GLib.assert_true (check_file_traversal ("s/other") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        GLib.assert_true (check_file_traversal ("s/filedir") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_traversal ("s/directory") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        GLib.assert_true (check_dir_traversal ("other") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        GLib.assert_true (check_dir_traversal ("filedir") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_dir_traversal ("directory") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_dir_traversal ("s/other") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        GLib.assert_true (check_dir_traversal ("s/filedir") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_dir_traversal ("s/directory") == CSync.CSync.ExcludedFiles.Type.LIST);

        GLib.assert_true (check_dir_full ("filedir/foo") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_full ("filedir/foo") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_dir_full ("directory/foo") == CSync.CSync.ExcludedFiles.Type.LIST);
        GLib.assert_true (check_file_full ("directory/foo") == CSync.CSync.ExcludedFiles.Type.LIST);
    }

} // class TestCSyncDirectoryOnly

} // namespace Testing
} // namespace Occ
