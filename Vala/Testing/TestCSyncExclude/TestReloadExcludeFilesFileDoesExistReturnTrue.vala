namespace Occ {
namespace Testing {

/***********************************************************
@class TestReloadExcludeFilesFileDoesExistReturnTrue

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestReloadExcludeFilesFileDoesExistReturnTrue : AbstractTestCSyncExclude {

    /***********************************************************
    ***********************************************************/
    private TestReloadExcludeFilesFileDoesExistReturnTrue () {
        var temporary_directory = GLib.StandardPaths.writable_location (GLib.StandardPaths.TempLocation);
        excluded_files.reset (new ExcludedFiles (temporary_directory + "/"));

        string sub_temp_dir = "exclude";
        GLib.assert_true (new GLib.Dir (temporary_directory).mkpath (sub_temp_dir));

        string existing_file_path = temporary_directory + "/" + sub_temp_dir + "/.sync-exclude.lst";
        GLib.File exclude_list = new GLib.File (existing_file_path);
        GLib.assert_true (exclude_list.open (GLib.File.WriteOnly));
        exclude_list.close ();

        excluded_files.add_exclude_file_path (existing_file_path);
        GLib.assert_true (excluded_files.reload_exclude_files () == true);
        GLib.assert_true (excluded_files.all_excludes.size () == 1);
    }

} // class TestReloadExcludeFilesFileDoesExistReturnTrue

} // namespace Testing
} // namespace Occ
