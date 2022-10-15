namespace Occ {
namespace Testing {

/***********************************************************
@class TestFun

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestFun : AbstractTestCSyncExclude {

    /***********************************************************
    ***********************************************************/
    private TestFun () {
        //  CSync.ExcludedFiles excluded;
        //  bool exclude_hidden = true;
        //  bool keep_hidden = false;

        //  GLib.assert_true (!excluded.is_excluded ("/a/b", "/a", keep_hidden));
        //  GLib.assert_true (!excluded.is_excluded ("/a/b~", "/a", keep_hidden));
        //  GLib.assert_true (!excluded.is_excluded ("/a/.b", "/a", keep_hidden));
        //  GLib.assert_true (excluded.is_excluded ("/a/.b", "/a", exclude_hidden));

        //  excluded.add_exclude_file_path (EXCLUDE_LIST_FILE);
        //  excluded.reload_exclude_files ();

        //  GLib.assert_true (!excluded.is_excluded ("/a/b", "/a", keep_hidden));
        //  GLib.assert_true (excluded.is_excluded ("/a/b~", "/a", keep_hidden));
        //  GLib.assert_true (!excluded.is_excluded ("/a/.b", "/a", keep_hidden));
        //  GLib.assert_true (excluded.is_excluded ("/a/.Trashes", "/a", keep_hidden));
        //  GLib.assert_true (excluded.is_excluded ("/a/foo_conflict-bar", "/a", keep_hidden));
        //  GLib.assert_true (excluded.is_excluded ("/a/foo (conflicted copy bar)", "/a", keep_hidden));
        //  GLib.assert_true (excluded.is_excluded ("/a/.b", "/a", exclude_hidden));

        //  GLib.assert_true (excluded.is_excluded ("/a/#b#", "/a", keep_hidden));
    }

} // class TestFun

} // namespace Testing
} // namespace Occ
