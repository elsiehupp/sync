/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/


namespace Occ {
namespace Testing {

public class TestInotifyWatcher : FolderWatcherPrivate {

    /***********************************************************
    ***********************************************************/
    private string root;

    /***********************************************************
    ***********************************************************/
    private void on_signal_init_test_case () {
        this.root = GLib.Dir.temporary_path + "/" + "test_" + string.number (Utility.rand ());
        GLib.debug ("creating test directory tree in " + this.root);
        GLib.Dir root_directory = new GLib.Dir (this.root);

        root_directory.mkpath (this.root + "/a1/b1/c1");
        root_directory.mkpath (this.root + "/a1/b1/c2");
        root_directory.mkpath (this.root + "/a1/b2/c1");
        root_directory.mkpath (this.root + "/a1/b3/c3");
        root_directory.mkpath (this.root + "/a2/b3/c3");
    }


    /***********************************************************
    Test the recursive path listing function find_folders_below
    ***********************************************************/
    private TestDirectoriesBelowPath () {
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

        QVERIFY2 (dirs.count () == 11, "Directory count wrong.");

        QVERIFY2 (ok, "find_folders_below failed.");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_cleanup_test_case () {
        if (this.root.starts_with (GLib.Dir.temporary_path)) {
           system ("rm -rf %1".printf (this.root).to_local_8_bit ());
        }
    }

}

} // namespace Testing
} // namespace Occ
