/*
 *    This software is in the public domain, furnished "as is", without technical
 *    support, and with no warranty, express or implied, as to its usefulness for
 *    any purpose.
 *
 */

// #include <QtTest>
// #include <syncengine.h>
// #include <localdiscoverytracker.h>

using namespace OCC;

class TestLockedFiles : public QObject {

private slots:
    void testBasicLockFileWatcher () {
        QTemporaryDir tmp;
        int count = 0;
        QString file;

        LockWatcher watcher;
        watcher.setCheckInterval (std.chrono.milliseconds (50));
        connect (&watcher, &LockWatcher.fileUnlocked, &watcher, [&] (QString &f) { ++count; file = f; });

        const QString tmpFile = tmp.path () + QString.fromUtf8 ("/alonglonglonglong/blonglonglonglong/clonglonglonglong/dlonglonglonglong/"
                                                               "elonglonglonglong/flonglonglonglong/glonglonglonglong/hlonglonglonglong/ilonglonglonglong/"
                                                               "jlonglonglonglong/klonglonglonglong/llonglonglonglong/mlonglonglonglong/nlonglonglonglong/"
                                                               "olonglonglonglong/file🐷.txt"); {
            // use a long file path to ensure we handle that correctly
            QVERIFY (QFileInfo (tmpFile).dir ().mkpath ("."));
            QFile tmp (tmpFile);
            QVERIFY (tmp.open (QFile.WriteOnly));
            QVERIFY (tmp.write ("ownCLoud"));
        }
        QVERIFY (QFile.exists (tmpFile));

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
#include "testlockedfiles.moc"
