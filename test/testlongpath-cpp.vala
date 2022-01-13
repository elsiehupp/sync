/*
libcsync -- a library to sync a directory with another

Copyright (c) 2013 by Klaas Freitag <freitag@owncloud.com>

This library is free software; you can redistribute it and/o
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later vers

This library is distributed in the hope that it wi
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
*/

// #include <QTemporaryFile>
// #include <QTest>

class TestLongWindowsPath : GLib.Object {

private slots:

    void testLongPathStat_data () {
        QTest.addColumn<QString> ("name");

        QTest.newRow ("long") << QStringLiteral ("/alonglonglonglong/blonglonglonglong/clonglonglonglong/dlonglonglonglong/"
                                                "elonglonglonglong/flonglonglonglong/glonglonglonglong/hlonglonglonglong/ilonglonglonglong/"
                                                "jlonglonglonglong/klonglonglonglong/llonglonglonglong/mlonglonglonglong/nlonglonglonglong/"
                                                "olonglonglonglong/file.txt");
        QTest.newRow ("long emoji") << QString.fromUtf8 ("/alonglonglonglong/blonglonglonglong/clonglonglonglong/dlonglonglonglong/"
                                                         "elonglonglonglong/flonglonglonglong/glonglonglonglong/hlonglonglonglong/ilonglonglonglong/"
                                                         "jlonglonglonglong/klonglonglonglong/llonglonglonglong/mlonglonglonglong/nlonglonglonglong/"
                                                         "olonglonglonglong/file🐷.txt");
        QTest.newRow ("long russian") << QString.fromUtf8 ("/alonglonglonglong/blonglonglonglong/clonglonglonglong/dlonglonglonglong/"
                                                           "elonglonglonglong/flonglonglonglong/glonglonglonglong/hlonglonglonglong/ilonglonglonglong/"
                                                           "jlonglonglonglong/klonglonglonglong/llonglonglonglong/mlonglonglonglong/nlonglonglonglong/"
                                                           "olonglonglonglong/собственное.txt");
        QTest.newRow ("long arabic") << QString.fromUtf8 ("/alonglonglonglong/blonglonglonglong/clonglonglonglong/dlonglonglonglong/"
                                                          "elonglonglonglong/flonglonglonglong/glonglonglonglong/hlonglonglonglong/ilonglonglonglong/"
                                                          "jlonglonglonglong/klonglonglonglong/llonglonglonglong/mlonglonglonglong/nlonglonglonglong/"
                                                          "olonglonglonglong/السحاب.txt");
        QTest.newRow ("long chinese") << QString.fromUtf8 ("/alonglonglonglong/blonglonglonglong/clonglonglonglong/dlonglonglonglong/"
                                                           "elonglonglonglong/flonglonglonglong/glonglonglonglong/hlonglonglonglong/ilonglonglonglong/"
                                                           "jlonglonglonglong/klonglonglonglong/llonglonglonglong/mlonglonglonglong/nlonglonglonglong/"
                                                           "olonglonglonglong/自己的云.txt");
    }

    void testLongPathStat () {
        QTemporaryDir tmp;
        QFETCH (QString, name);
        const QFileInfo longPath (tmp.path () + name);

        const auto data = QByteArrayLiteral ("hello");
        qDebug () << longPath;
        QVERIFY (longPath.dir ().mkpath ("."));

        QFile file (longPath.filePath ());
        QVERIFY (file.open (QFile.WriteOnly));
        QVERIFY (file.write (data.constData ()) == data.size ());
        file.close ();

        csync_file_stat_t buf;
        QVERIFY (csync_vio_local_stat (longPath.filePath (), &buf) != -1);
        QVERIFY (buf.size == data.size ());
        QVERIFY (buf.size == longPath.size ());

        QVERIFY (tmp.remove ());
    }
};

QTEST_GUILESS_MAIN (TestLongWindowsPath)
#include "testlongpath.moc"
