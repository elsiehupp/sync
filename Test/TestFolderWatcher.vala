/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.

***********************************************************/

// #include <QtTest>

void touch (string file) {
    string cmd;
    cmd = string ("touch %1").arg (file);
    qDebug () << "Command : " << cmd;
    system (cmd.toLocal8Bit ());
}

void mkdir (string file) {
    string cmd = string ("mkdir %1").arg (file);
    qDebug () << "Command : " << cmd;
    system (cmd.toLocal8Bit ());
}

void rmdir (string file) {
    string cmd = string ("rmdir %1").arg (file);
    qDebug () << "Command : " << cmd;
    system (cmd.toLocal8Bit ());
}

void rm (string file) {
    string cmd = string ("rm %1").arg (file);
    qDebug () << "Command : " << cmd;
    system (cmd.toLocal8Bit ());
}

void mv (string file1, string file2) {
    string cmd = string ("mv %1 %2").arg (file1, file2);
    qDebug () << "Command : " << cmd;
    system (cmd.toLocal8Bit ());
}

using namespace Occ;

class TestFolderWatcher : GLib.Object {

    QTemporaryDir this.root;
    string this.rootPath;
    QScopedPointer<FolderWatcher> this.watcher;
    QScopedPointer<QSignalSpy> this.pathChangedSpy;

    bool waitForPathChanged (string path) {
        QElapsedTimer t;
        t.on_start ();
        while (t.elapsed () < 5000) {
            // Check if it was already reported as changed by the watcher
            for (int i = 0; i < this.pathChangedSpy.size (); ++i) {
                const var args = this.pathChangedSpy.at (i);
                if (args.first ().toString () == path)
                    return true;
            }
            // Wait a bit and test again (don't bother checking if we timed out or not)
            this.pathChangedSpy.wait (200);
        }
        return false;
    }

#ifdef Q_OS_LINUX
const int CHECK_WATCH_COUNT (n) QCOMPARE (this.watcher.testLinuxWatchCount (), (n))
#else
const int CHECK_WATCH_COUNT (n) do {} while (false)
#endif

    /***********************************************************
    ***********************************************************/
    public TestFolderWatcher () {
        QDir rootDir (this.root.path ());
        this.rootPath = rootDir.canonicalPath ();
        qDebug () << "creating test directory tree in " << this.rootPath;

        rootDir.mkpath ("a1/b1/c1");
        rootDir.mkpath ("a1/b1/c2");
        rootDir.mkpath ("a1/b2/c1");
        rootDir.mkpath ("a1/b3/c3");
        rootDir.mkpath ("a2/b3/c3");
        Utility.writeRandomFile ( this.rootPath+"/a1/random.bin");
        Utility.writeRandomFile ( this.rootPath+"/a1/b2/todelete.bin");
        Utility.writeRandomFile ( this.rootPath+"/a2/renamefile");
        Utility.writeRandomFile ( this.rootPath+"/a1/movefile");

        this.watcher.on_reset (new FolderWatcher);
        this.watcher.on_init (this.rootPath);
        this.pathChangedSpy.on_reset (new QSignalSpy (this.watcher.data (), SIGNAL (pathChanged (string))));
    }


    /***********************************************************
    ***********************************************************/
    public int countFolders (string path) {
        int n = 0;
        for (var sub : QDir (path).entryList (QDir.Dirs | QDir.NoDotAndDotDot))
            n += 1 + countFolders (path + '/' + sub);
        return n;
    }


    /***********************************************************
    ***********************************************************/
    private void on_init () {
        this.pathChangedSpy.clear ();
        CHECK_WATCH_COUNT (countFolders (this.rootPath) + 1);
    }


    /***********************************************************
    ***********************************************************/
    private void on_cleanup () {
        CHECK_WATCH_COUNT (countFolders (this.rootPath) + 1);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testACreate () { // create a new file
        string file (this.rootPath + "/foo.txt");
        string cmd;
        cmd = string ("echo \"xyz\" > %1").arg (file);
        qDebug () << "Command : " << cmd;
        system (cmd.toLocal8Bit ());

        QVERIFY (waitForPathChanged (file));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testATouch () { // touch an existing file.
        string file (this.rootPath + "/a1/random.bin");
        touch (file);
        QVERIFY (waitForPathChanged (file));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testMove3LevelDirWithFile () {
        string file (this.rootPath + "/a0/b/c/empty.txt");
        mkdir (this.rootPath + "/a0");
        mkdir (this.rootPath + "/a0/b");
        mkdir (this.rootPath + "/a0/b/c");
        touch (file);
        mv (this.rootPath + "/a0", this.rootPath + "/a");
        QVERIFY (waitForPathChanged (this.rootPath + "/a/b/c/empty.txt"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testCreateADir () {
        string file (this.rootPath+"/a1/b1/new_dir");
        mkdir (file);
        QVERIFY (waitForPathChanged (file));

        // Notifications from that new folder arrive too
        string file2 (this.rootPath + "/a1/b1/new_dir/contained");
        touch (file2);
        QVERIFY (waitForPathChanged (file2));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testRemoveADir () {
        string file (this.rootPath+"/a1/b3/c3");
        rmdir (file);
        QVERIFY (waitForPathChanged (file));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testRemoveAFile () {
        string file (this.rootPath+"/a1/b2/todelete.bin");
        QVERIFY (GLib.File.exists (file));
        rm (file);
        QVERIFY (!GLib.File.exists (file));

        QVERIFY (waitForPathChanged (file));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testRenameAFile () {
        string file1 (this.rootPath+"/a2/renamefile");
        string file2 (this.rootPath+"/a2/renamefile.renamed");
        QVERIFY (GLib.File.exists (file1));
        mv (file1, file2);
        QVERIFY (GLib.File.exists (file2));

        QVERIFY (waitForPathChanged (file1));
        QVERIFY (waitForPathChanged (file2));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testMoveAFile () {
        string old_file (this.rootPath+"/a1/movefile");
        string new_file (this.rootPath+"/a2/movefile.renamed");
        QVERIFY (GLib.File.exists (old_file));
        mv (old_file, new_file);
        QVERIFY (GLib.File.exists (new_file));

        QVERIFY (waitForPathChanged (old_file));
        QVERIFY (waitForPathChanged (new_file));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testRenameDirectorySameBase () {
        string old_file (this.rootPath+"/a1/b1");
        string new_file (this.rootPath+"/a1/brename");
        QVERIFY (GLib.File.exists (old_file));
        mv (old_file, new_file);
        QVERIFY (GLib.File.exists (new_file));

        QVERIFY (waitForPathChanged (old_file));
        QVERIFY (waitForPathChanged (new_file));

        // Verify that further notifications end up with the correct paths

        string file (this.rootPath+"/a1/brename/c1/random.bin");
        touch (file);
        QVERIFY (waitForPathChanged (file));

        string dir (this.rootPath+"/a1/brename/newfolder");
        mkdir (dir);
        QVERIFY (waitForPathChanged (dir));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testRenameDirectoryDifferentBase () {
        string old_file (this.rootPath+"/a1/brename");
        string new_file (this.rootPath+"/bren");
        QVERIFY (GLib.File.exists (old_file));
        mv (old_file, new_file);
        QVERIFY (GLib.File.exists (new_file));

        QVERIFY (waitForPathChanged (old_file));
        QVERIFY (waitForPathChanged (new_file));

        // Verify that further notifications end up with the correct paths

        string file (this.rootPath+"/bren/c1/random.bin");
        touch (file);
        QVERIFY (waitForPathChanged (file));

        string dir (this.rootPath+"/bren/newfolder2");
        mkdir (dir);
        QVERIFY (waitForPathChanged (dir));
    }
};

    QTEST_GUILESS_MAIN (TestFolderWatcher)

#include "testfolderwatcher.moc"
