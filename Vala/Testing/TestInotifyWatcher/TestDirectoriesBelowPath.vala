namespace Occ {
namespace Testing {

/***********************************************************
@class TestDirectoriesBelowPath

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestDirectoriesBelowPath : AbstractTestInotifyWatcher {

    /***********************************************************
    Test the recursive path listing function find_folders_below
    ***********************************************************/
    private TestDirectoriesBelowPath () {
        base ();

        string[] dirs;

        bool ok = find_folders_below (GLib.Dir (this.root), dirs);
        GLib.assert_true ( dirs.index_of (this.root + "/a1")>-1);
        GLib.assert_true ( dirs.index_of (this.root + "/a1/b1")>-1);
        GLib.assert_true ( dirs.index_of (this.root + "/a1/b1/c1")>-1);
        GLib.assert_true ( dirs.index_of (this.root + "/a1/b1/c2")>-1);

        GLib.assert_true (Utility.write_random_file (this.root+"/a1/rand1.dat"));
        GLib.assert_true (Utility.write_random_file (this.root+"/a1/b1/rand2.dat"));
        GLib.assert_true (Utility.write_random_file (this.root+"/a1/b1/c1/rand3.dat"));

        GLib.assert_true ( dirs.index_of (this.root + "/a1/b2")>-1);
        GLib.assert_true ( dirs.index_of (this.root + "/a1/b2/c1")>-1);
        GLib.assert_true ( dirs.index_of (this.root + "/a1/b3")>-1);
        GLib.assert_true ( dirs.index_of (this.root + "/a1/b3/c3")>-1);

        GLib.assert_true ( dirs.index_of (this.root + "/a2"));
        GLib.assert_true ( dirs.index_of (this.root + "/a2/b3"));
        GLib.assert_true ( dirs.index_of (this.root + "/a2/b3/c3"));

        QVERIFY2 (dirs.length == 11, "Directory count wrong.");

        QVERIFY2 (ok, "find_folders_below failed.");

        delete (this);
    }

} // class TestDirectoriesBelowPath

} // namespace Testing
} // namespace Occ
