namespace Occ {
namespace Testing {

/***********************************************************
@class AbstractTestCSyncExclude

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public abstract class AbstractTestCSyncExclude { //: GLib.Object {

//    protected const string EXCLUDE_LIST_FILE = SOURCEDIR + "/../../sync-exclude.lst";

//    /***********************************************************
//    This global variable exists because the tests were converted
//    from the old CMocka framework.
//    ***********************************************************/
//    protected static CSync.ExcludedFiles excluded_files;

//    /***********************************************************
//    ***********************************************************/
//    protected AbstractTestCSyncExclude () {
//        up ();

//        excluded_files.add_exclude_file_path (EXCLUDE_LIST_FILE);
//        GLib.assert_true (excluded_files.reload_exclude_files ());

//        /* and add some unicode stuff */
//        excluded_files.add_manual_exclude ("*.💩"); // is this source file utf8 encoded?
//        excluded_files.add_manual_exclude ("пятницы.*");
//        excluded_files.add_manual_exclude ("*/*.out");
//        excluded_files.add_manual_exclude ("latex*/*.run.xml");
//        excluded_files.add_manual_exclude ("latex/*/*.tex.temporary");

//        GLib.assert_true (excluded_files.reload_exclude_files ());
//    }

//    /***********************************************************
//    ***********************************************************/
//    protected static void up () {
//        excluded_files = new CSync.ExcludedFiles ();
//        excluded_files.set_wildcards_match_slash (false);
//    }

//    /***********************************************************
//    ***********************************************************/
//    protected static CSync.ExcludedFiles check_file_full (string path) {
//        return excluded_files.full_pattern_match (path, ItemType.FILE);
//    }

//    /***********************************************************
//    ***********************************************************/
//    protected static CSync.ExcludedFiles check_dir_full (string path) {
//        return excluded_files.full_pattern_match (path, ItemType.DIRECTORY);
//    }

//    /***********************************************************
//    ***********************************************************/
//    protected static CSync.ExcludedFiles check_file_traversal (string path) {
//        return excluded_files.traversal_pattern_match (path, ItemType.FILE);
//    }

//    /***********************************************************
//    ***********************************************************/
//    protected static CSync.ExcludedFiles check_dir_traversal (string path) {
//        return excluded_files.traversal_pattern_match (path, ItemType.DIRECTORY);
//    }

} // class AbstractTestCSyncExclude

} // namespace Testing
} // namespace Occ
