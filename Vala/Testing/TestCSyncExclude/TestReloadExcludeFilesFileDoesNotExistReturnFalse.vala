namespace Occ {
namespace Testing {

/***********************************************************
@class TestReloadExcludeFilesFileDoesNotExistReturnFalse

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestReloadExcludeFilesFileDoesNotExistReturnFalse : AbstractTestCSyncExclude {

    /***********************************************************
    ***********************************************************/
    private TestReloadExcludeFilesFileDoesNotExistReturnFalse () {
        excluded_files.on_signal_reset (new ExcludedFiles ());
        string non_existing_file = "directory/.sync-exclude.lst";
        excluded_files.add_exclude_file_path (non_existing_file);
        GLib.assert_true (excluded_files.reload_exclude_files () == false);
        GLib.assert_true (excluded_files.all_excludes.size () == 0);
    }

} // class TestReloadExcludeFilesFileDoesNotExistReturnFalse

} // namespace Testing
} // namespace Occ
