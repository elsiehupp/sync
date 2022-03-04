/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>

using Occ;

namespace Testing {

class TestFolder : public GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testFolder () {
        QFETCH (string, folder);
        QFETCH (string, expectedFolder);
        Folder f = new Folder ("alias", folder, "http://foo.bar.net");
        QCOMPARE (f.path (), expectedFolder);
        delete f;
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testFolder_data () {
        QTest.addColumn<string> ("folder");
        QTest.addColumn<string> ("expectedFolder");

        QTest.newRow ("unixcase") + "/foo/bar" + "/foo/bar";
        QTest.newRow ("doubleslash") + "/foo//bar" + "/foo/bar";
        QTest.newRow ("tripleslash") + "/foo///bar" + "/foo/bar";
        QTest.newRow ("mixedslash") + "/foo/\\bar" + "/foo/bar";
        QTest.newRow ("windowsfwslash") + "C:/foo/bar" + "C:/foo/bar";
        QTest.newRow ("windowsbwslash") + "C:\\foo" + "C:/foo";
        QTest.newRow ("windowsbwslash2") + "C:\\foo\\bar" + "C:/foo/bar";
    }

}

QTEST_APPLESS_MAIN (TestFolder)
#include "testfolder.moc"
