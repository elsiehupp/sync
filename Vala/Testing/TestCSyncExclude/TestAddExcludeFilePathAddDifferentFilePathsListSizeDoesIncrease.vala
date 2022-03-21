namespace Occ {
namespace Testing {

/***********************************************************
@class TestAddExcludeFilePathAddDifferentFilePathsListSizeDoesIncrease

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestAddExcludeFilePathAddDifferentFilePathsListSizeDoesIncrease : AbstractTestCSyncExclude {

    /***********************************************************
    ***********************************************************/
    private TestAddExcludeFilePathAddDifferentFilePathsListSizeDoesIncrease () {
        excluded_files.on_signal_reset (new ExcludedFiles ());

        var file_path1 = "exclude1/.sync-exclude.lst";
        var file_path2 = "exclude2/.sync-exclude.lst";

        excluded_files.add_exclude_file_path (file_path1);
        excluded_files.add_exclude_file_path (file_path2);

        GLib.assert_true (excluded_files.exclude_files.size () == 2);
    }

} // class TestAddExcludeFilePathAddDifferentFilePathsListSizeDoesIncrease

} // namespace Testing
} // namespace Occ
