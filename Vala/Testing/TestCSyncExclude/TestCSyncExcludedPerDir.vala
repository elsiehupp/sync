namespace Occ {
namespace Testing {

/***********************************************************
@class TestCSyncExcludedPerDir

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCSyncExcludedPerDir : AbstractTestCSyncExclude {

    /***********************************************************
    ***********************************************************/
    private TestCSyncExcludedPerDir () {
        //  var temporary_directory = GLib.StandardPaths.writable_location (GLib.StandardPaths.TempLocation);
        //  excluded_files.reset (new CSync.ExcludedFiles (temporary_directory + "/"));
        //  excluded_files.set_wildcards_match_slash (false);
        //  excluded_files.add_manual_exclude ("A");
        //  excluded_files.reload_exclude_files ();

        //  GLib.assert_true (check_file_full ("A") == CSync.ExcludedFiles.Type.LIST);

        //  excluded_files.clear_manual_excludes ();
        //  excluded_files.add_manual_exclude ("A", temporary_directory + "/B/");
        //  excluded_files.reload_exclude_files ();

        //  GLib.assert_true (check_file_full ("A") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_full ("B/A") == CSync.ExcludedFiles.Type.LIST);

        //  excluded_files.clear_manual_excludes ();
        //  excluded_files.add_manual_exclude ("A/a1", temporary_directory + "/B/");
        //  excluded_files.reload_exclude_files ();

        //  GLib.assert_true (check_file_full ("A") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_full ("B/A/a1") == CSync.ExcludedFiles.Type.LIST);

        //  string foo_directory = "check_csync1/foo";
        //  GLib.assert_true (new GLib.Dir (temporary_directory).mkpath (foo_directory));

        //  string foo_exclude_list = temporary_directory + "/" + foo_directory + "/.sync-exclude.lst";
        //  GLib.File exclude_list = new GLib.File (foo_exclude_list);
        //  GLib.assert_true (exclude_list.open (GLib.File.WriteOnly));
        //  GLib.assert_true (exclude_list.write ("bar") == 3);
        //  exclude_list.close ();

        //  excluded_files.add_exclude_file_path (foo_exclude_list);
        //  excluded_files.reload_exclude_files ();
        //  GLib.assert_true (check_file_full (foo_directory + "/bar") == CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_full (oo_directory + "/baz") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
    }

} // class TestCSyncExcludedPerDir

} // namespace Testing
} // namespace Occ
