/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>

using Occ;

namespace Testing {

class TestInotifyWatcher : FolderWatcherPrivate {

    /***********************************************************
    ***********************************************************/
    private string root;

    /***********************************************************
    ***********************************************************/
    private void on_signal_init_test_case () {
        this.root = QDir.tempPath () + "/" + "test_" + string.number (Occ.Utility.rand ());
        GLib.debug ("creating test directory tree in " + this.root);
        QDir root_directory = new QDir (this.root);

        root_directory.mkpath (this.root + "/a1/b1/c1");
        root_directory.mkpath (this.root + "/a1/b1/c2");
        root_directory.mkpath (this.root + "/a1/b2/c1");
        root_directory.mkpath (this.root + "/a1/b3/c3");
        root_directory.mkpath (this.root + "/a2/b3/c3");
    }

    // Test the recursive path listing function find_folders_below
    private void test_directories_below_path () {
        string[] dirs;

        bool ok = find_folders_below (QDir (this.root), dirs);
        //  QVERIFY ( dirs.indexOf (this.root + "/a1")>-1);
        //  QVERIFY ( dirs.indexOf (this.root + "/a1/b1")>-1);
        //  QVERIFY ( dirs.indexOf (this.root + "/a1/b1/c1")>-1);
        //  QVERIFY ( dirs.indexOf (this.root + "/a1/b1/c2")>-1);

        //  QVERIFY (Utility.writeRandomFile (this.root+"/a1/rand1.dat"));
        //  QVERIFY (Utility.writeRandomFile (this.root+"/a1/b1/rand2.dat"));
        //  QVERIFY (Utility.writeRandomFile (this.root+"/a1/b1/c1/rand3.dat"));

        //  QVERIFY ( dirs.indexOf (this.root + "/a1/b2")>-1);
        //  QVERIFY ( dirs.indexOf (this.root + "/a1/b2/c1")>-1);
        //  QVERIFY ( dirs.indexOf (this.root + "/a1/b3")>-1);
        //  QVERIFY ( dirs.indexOf (this.root + "/a1/b3/c3")>-1);

        //  QVERIFY ( dirs.indexOf (this.root + "/a2"));
        //  QVERIFY ( dirs.indexOf (this.root + "/a2/b3"));
        //  QVERIFY ( dirs.indexOf (this.root + "/a2/b3/c3"));

        //  QVERIFY2 (dirs.count () == 11, "Directory count wrong.");

        //  QVERIFY2 (ok, "find_folders_below failed.");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_cleanup_test_case () {
        if (this.root.startsWith (QDir.tempPath ())) {
           system ("rm -rf %1".arg (this.root).toLocal8Bit ());
        }
    }

}
}
