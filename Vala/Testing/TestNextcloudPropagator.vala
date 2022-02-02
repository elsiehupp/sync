/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.
***********************************************************/

// #include <QtTest>
// #include <QDebug>

using namespace Occ;
namespace Occ {
string createDownloadTmpFileName (string previous);
}

class TestNextcloudPropagator : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testUpdateErrorFromSession () {
        //OwncloudPropagator propagator (nullptr, QLatin1String ("test1"), QLatin1String ("test2"), new ProgressDatabase);
        QVERIFY ( true );
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testTmpDownloadFileNameGeneration () {
        string fn;
        // without dir
        for (int i = 1; i <= 1000; i++) {
            fn+="F";
            string tmpFileName = createDownloadTmpFileName (fn);
            if (tmpFileName.contains ('/')) {
                tmpFileName = tmpFileName.mid (tmpFileName.lastIndexOf ('/')+1);
            }
            QVERIFY ( tmpFileName.length () > 0);
            QVERIFY ( tmpFileName.length () <= 254);
        }
        // with absolute dir
        fn = "/Users/guruz/ownCloud/rocks/GPL";
        for (int i = 1; i < 1000; i++) {
            fn+="F";
            string tmpFileName = createDownloadTmpFileName (fn);
            if (tmpFileName.contains ('/')) {
                tmpFileName = tmpFileName.mid (tmpFileName.lastIndexOf ('/')+1);
            }
            QVERIFY ( tmpFileName.length () > 0);
            QVERIFY ( tmpFileName.length () <= 254);
        }
        // with relative dir
        fn = "rocks/GPL";
        for (int i = 1; i < 1000; i++) {
            fn+="F";
            string tmpFileName = createDownloadTmpFileName (fn);
            if (tmpFileName.contains ('/')) {
                tmpFileName = tmpFileName.mid (tmpFileName.lastIndexOf ('/')+1);
            }
            QVERIFY ( tmpFileName.length () > 0);
            QVERIFY ( tmpFileName.length () <= 254);
        }
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testParseEtag () {
        using Test = QPair<const char*, char>;
        GLib.List<Test> tests;
        tests.append (Test ("\"abcd\"", "abcd"));
        tests.append (Test ("\"\"", ""));
        tests.append (Test ("\"fii\"-gzip", "fii"));
        tests.append (Test ("W/\"foo\"", "foo"));

        foreach (var& test, tests) {
            QCOMPARE (parseEtag (test.first), GLib.ByteArray (test.second));
        }
    }
}

QTEST_APPLESS_MAIN (TestNextcloudPropagator)
