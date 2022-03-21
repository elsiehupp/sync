namespace Occ {
namespace Testing {

/***********************************************************
@class TestAddExcludeFilePathAddDefaultExcludeFileReturnCorrectMap

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestAddExcludeFilePathAddDefaultExcludeFileReturnCorrectMap : AbstractTestCSyncExclude {

    /***********************************************************
    ***********************************************************/
    private TestAddExcludeFilePathAddDefaultExcludeFileReturnCorrectMap () {
        const string base_path = "sync_folder/";
        const string folder1 = "sync_folder/folder1/";
        const string folder2 = folder1 + "folder2/";
        excluded_files.on_signal_reset (new ExcludedFiles (base_path));

        const string default_exclude_list = "desktop-client/config-folder/sync-exclude.lst";
        const string folder1_exclude_list = folder1 + ".sync-exclude.lst";
        const string folder2_exclude_list = folder2 + ".sync-exclude.lst";

        excluded_files.add_exclude_file_path (default_exclude_list);
        excluded_files.add_exclude_file_path (folder1_exclude_list);
        excluded_files.add_exclude_file_path (folder2_exclude_list);

        GLib.assert_true (excluded_files.exclude_files.size () == 3);
        GLib.assert_true (excluded_files.exclude_files[base_path].first () == default_exclude_list);
        GLib.assert_true (excluded_files.exclude_files[folder1].first () == folder1_exclude_list);
        GLib.assert_true (excluded_files.exclude_files[folder2].first () == folder2_exclude_list);
    }

} // class TestAddExcludeFilePathAddDefaultExcludeFileReturnCorrectMap

} // namespace Testing
} // namespace Occ
