/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <QDebug>

using Occ;
namespace Occ {
string create_download_tmp_filename (string previous);
}

namespace Testing {

public class TestNextcloudPropagator : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void test_update_error_from_session () {
        //OwncloudPropagator propagator (null, "test1", "test2", new ProgressDatabase);
        GLib.assert_true ( true );
    }


    /***********************************************************
    ***********************************************************/
    private void test_tmp_download_file_name_generation () {
        string fn;
        // without directory
        for (int i = 1; i <= 1000; i++) {
            fn+="F";
            string tmp_file_name = create_download_tmp_filename (fn);
            if (tmp_file_name.contains ('/')) {
                tmp_file_name = tmp_file_name.mid (tmp_file_name.last_index_of ('/')+1);
            }
            GLib.assert_true ( tmp_file_name.length () > 0);
            GLib.assert_true ( tmp_file_name.length () <= 254);
        }
        // with absolute directory
        fn = "/Users/guruz/own_cloud/rocks/GPL";
        for (int i = 1; i < 1000; i++) {
            fn+="F";
            string tmp_file_name = create_download_tmp_filename (fn);
            if (tmp_file_name.contains ('/')) {
                tmp_file_name = tmp_file_name.mid (tmp_file_name.last_index_of ('/')+1);
            }
            GLib.assert_true ( tmp_file_name.length () > 0);
            GLib.assert_true ( tmp_file_name.length () <= 254);
        }
        // with relative directory
        fn = "rocks/GPL";
        for (int i = 1; i < 1000; i++) {
            fn+="F";
            string tmp_file_name = create_download_tmp_filename (fn);
            if (tmp_file_name.contains ('/')) {
                tmp_file_name = tmp_file_name.mid (tmp_file_name.last_index_of ('/')+1);
            }
            GLib.assert_true ( tmp_file_name.length () > 0);
            GLib.assert_true ( tmp_file_name.length () <= 254);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void test_parse_etag () {
        using Test = QPair<const char*, char>;
        GLib.List<Test> tests;
        tests.append (Test ("\"abcd\"", "abcd"));
        tests.append (Test ("\"\"", ""));
        tests.append (Test ("\"fii\"-gzip", "fii"));
        tests.append (Test ("W/\"foo\"", "foo"));

        foreach (var test in tests) {
            GLib.assert_cmp (parse_etag (test.first), GLib.ByteArray (test.second));
        }
    }

}
}
