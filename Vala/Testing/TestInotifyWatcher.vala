/***********************************************************
   This software is in the public domain, furnished "as is", without technical
      support, and with no warranty, express or implied, as to its usefulness for
         any purpose.
         */

//  #include <QtTest>

using namespace Occ;

class TestInotifyWatcher : public FolderWatcherPrivate {

    /***********************************************************
    ***********************************************************/
    private string this.root;

    /***********************************************************
    ***********************************************************/
    private void on_init_test_case () {
        this.root = QDir.tempPath () + "/" + "test_" + string.number (Occ.Utility.rand ());
        qDebug () << "creating test directory tree in " << this.root;
        QDir rootDir (this.root);

        rootDir.mkpath (this.root + "/a1/b1/c1");
        rootDir.mkpath (this.root + "/a1/b1/c2");
        rootDir.mkpath (this.root + "/a1/b2/c1");
        rootDir.mkpath (this.root + "/a1/b3/c3");
        rootDir.mkpath (this.root + "/a2/b3/c3");
    }

    // Test the recursive path listing function findFoldersBelow
    private on_ void testDirsBelowPath () {
        string[] dirs;

        bool ok = findFoldersBelow (QDir (this.root), dirs);
        QVERIFY ( dirs.indexOf (this.root + "/a1")>-1);
        QVERIFY ( dirs.indexOf (this.root + "/a1/b1")>-1);
        QVERIFY ( dirs.indexOf (this.root + "/a1/b1/c1")>-1);
        QVERIFY ( dirs.indexOf (this.root + "/a1/b1/c2")>-1);

        QVERIFY (Utility.writeRandomFile (this.root+"/a1/rand1.dat"));
        QVERIFY (Utility.writeRandomFile (this.root+"/a1/b1/rand2.dat"));
        QVERIFY (Utility.writeRandomFile (this.root+"/a1/b1/c1/rand3.dat"));

        QVERIFY ( dirs.indexOf (this.root + "/a1/b2")>-1);
        QVERIFY ( dirs.indexOf (this.root + "/a1/b2/c1")>-1);
        QVERIFY ( dirs.indexOf (this.root + "/a1/b3")>-1);
        QVERIFY ( dirs.indexOf (this.root + "/a1/b3/c3")>-1);

        QVERIFY ( dirs.indexOf (this.root + "/a2"));
        QVERIFY ( dirs.indexOf (this.root + "/a2/b3"));
        QVERIFY ( dirs.indexOf (this.root + "/a2/b3/c3"));

        QVERIFY2 (dirs.count () == 11, "Directory count wrong.");

        QVERIFY2 (ok, "findFoldersBelow failed.");
    }


    /***********************************************************
    ***********************************************************/
    private void on_cleanup_test_case () {
        if ( this.root.startsWith (QDir.tempPath () )) {
           system ( string ("rm -rf %1").arg (this.root).toLocal8Bit () );
        }
    }
}

QTEST_APPLESS_MAIN (TestInotifyWatcher)
