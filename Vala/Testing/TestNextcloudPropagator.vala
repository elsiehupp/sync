/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <QDebug>

using Occ;
namespace Occ {
string createDownloadTmpFileName (string previous);
}

namespace Testing {

class TestNextcloudPropagator : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void testUpdateErrorFromSession () {
        //OwncloudPropagator propagator (null, "test1", "test2", new ProgressDatabase);
        GLib.assert_true ( true );
    }


    /***********************************************************
    ***********************************************************/
    private void testTmpDownloadFileNameGeneration () {
        string fn;
        // without directory
        for (int i = 1; i <= 1000; i++) {
            fn+="F";
            string tmpFileName = createDownloadTmpFileName (fn);
            if (tmpFileName.contains ('/')) {
                tmpFileName = tmpFileName.mid (tmpFileName.last_index_of ('/')+1);
            }
            GLib.assert_true ( tmpFileName.length () > 0);
            GLib.assert_true ( tmpFileName.length () <= 254);
        }
        // with absolute directory
        fn = "/Users/guruz/ownCloud/rocks/GPL";
        for (int i = 1; i < 1000; i++) {
            fn+="F";
            string tmpFileName = createDownloadTmpFileName (fn);
            if (tmpFileName.contains ('/')) {
                tmpFileName = tmpFileName.mid (tmpFileName.last_index_of ('/')+1);
            }
            GLib.assert_true ( tmpFileName.length () > 0);
            GLib.assert_true ( tmpFileName.length () <= 254);
        }
        // with relative directory
        fn = "rocks/GPL";
        for (int i = 1; i < 1000; i++) {
            fn+="F";
            string tmpFileName = createDownloadTmpFileName (fn);
            if (tmpFileName.contains ('/')) {
                tmpFileName = tmpFileName.mid (tmpFileName.last_index_of ('/')+1);
            }
            GLib.assert_true ( tmpFileName.length () > 0);
            GLib.assert_true ( tmpFileName.length () <= 254);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testParseEtag () {
        using Test = QPair<const char*, char>;
        GLib.List<Test> tests;
        tests.append (Test ("\"abcd\"", "abcd"));
        tests.append (Test ("\"\"", ""));
        tests.append (Test ("\"fii\"-gzip", "fii"));
        tests.append (Test ("W/\"foo\"", "foo"));

        foreach (var& test, tests) {
            GLib.assert_cmp (parseEtag (test.first), GLib.ByteArray (test.second));
        }
    }
}

QTEST_APPLESS_MAIN (TestNextcloudPropagator)
