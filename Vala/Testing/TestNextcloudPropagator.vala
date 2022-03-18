/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <QDebug>

using Occ;
namespace Occ {
string create_download_temporary_filename (string previous);
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
    private void test_temporary_download_file_name_generation () {
        string fn;
        // without directory
        for (int i = 1; i <= 1000; i++) {
            fn+="F";
            string temporary_file_name = create_download_temporary_filename (fn);
            if (temporary_file_name.contains ('/')) {
                temporary_file_name = temporary_file_name.mid (temporary_file_name.last_index_of ('/')+1);
            }
            GLib.assert_true ( temporary_file_name.length > 0);
            GLib.assert_true ( temporary_file_name.length <= 254);
        }
        // with absolute directory
        fn = "/Users/guruz/own_cloud/rocks/GPL";
        for (int i = 1; i < 1000; i++) {
            fn+="F";
            string temporary_file_name = create_download_temporary_filename (fn);
            if (temporary_file_name.contains ('/')) {
                temporary_file_name = temporary_file_name.mid (temporary_file_name.last_index_of ('/')+1);
            }
            GLib.assert_true ( temporary_file_name.length > 0);
            GLib.assert_true ( temporary_file_name.length <= 254);
        }
        // with relative directory
        fn = "rocks/GPL";
        for (int i = 1; i < 1000; i++) {
            fn+="F";
            string temporary_file_name = create_download_temporary_filename (fn);
            if (temporary_file_name.contains ('/')) {
                temporary_file_name = temporary_file_name.mid (temporary_file_name.last_index_of ('/')+1);
            }
            GLib.assert_true ( temporary_file_name.length > 0);
            GLib.assert_true ( temporary_file_name.length <= 254);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void test_parse_etag () {
        //  using Test = QPair<const char*, char>;
        GLib.HashTable<string, string> tests = new GLib.HashTable<string, string> ();
        tests.append ("\"abcd\"", "abcd");
        tests.append ("\"\"", "");
        tests.append ("\"fii\"-gzip", "fii");
        tests.append ("W/\"foo\"", "foo");

        foreach (var test in tests) {
            GLib.assert_true (parse_etag (test.first) == test.second);
        }
    }

}
}
