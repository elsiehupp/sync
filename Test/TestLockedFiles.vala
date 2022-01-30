/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.

***********************************************************/

// #include <QtTest>
// #include <syncengine.h>
// #include <localdiscoverytracker.h>

using namespace Occ;

class TestLockedFiles : GLib.Object {

    private on_ void testBasicLockFileWatcher () {
        QTemporaryDir tmp;
        int count = 0;
        string file;

        LockWatcher watcher;
        watcher.setCheckInterval (std.chrono.milliseconds (50));
        connect (&watcher, &LockWatcher.fileUnlocked, &watcher, [&] (string f) { ++count; file = f; });

        const string tmpFile = tmp.path () + string.fromUtf8 ("/alonglonglonglong/blonglonglonglong/clonglonglonglong/dlonglonglonglong/"
                                                               "elonglonglonglong/flonglonglonglong/glonglonglonglong/hlonglonglonglong/ilonglonglonglong/"
                                                               "jlonglonglonglong/klonglonglonglong/llonglonglonglong/mlonglonglonglong/nlonglonglonglong/"
                                                               "olonglonglonglong/file🐷.txt"); {
            // use a long file path to ensure we handle that correctly
            QVERIFY (QFileInfo (tmpFile).dir ().mkpath ("."));
            GLib.File tmp (tmpFile);
            QVERIFY (tmp.open (GLib.File.WriteOnly));
            QVERIFY (tmp.write ("ownCLoud"));
        }
        QVERIFY (GLib.File.exists (tmpFile));

        QVERIFY (!FileSystem.isFileLocked (tmpFile));
        watcher.addFile (tmpFile);
        QVERIFY (watcher.contains (tmpFile));

        QEventLoop loop;
        QTimer.singleShot (120, &loop, [&] { loop.exit (); });
        loop.exec ();

        QCOMPARE (count, 1);
        QCOMPARE (file, tmpFile);
        QVERIFY (!watcher.contains (tmpFile));
        QVERIFY (tmp.remove ());
    }
};

QTEST_GUILESS_MAIN (TestLockedFiles)
