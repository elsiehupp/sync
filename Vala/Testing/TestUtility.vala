/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <QTemporaryDir>

using Occ.Utility;

//  namespace Occ {
//  OCSYNC_EXPORT extern bool filesystem_case_preserving_override;
//  }

namespace Testing {

public class TestUtility : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void on_signal_init_test_case () {
        QStandardPaths.set_test_mode_enabled (true);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_format_fingerprint () {
        QVERIFY2 (format_fingerprint ("68ac906495480a3404beee4874ed853a037a7a8f")
                 == "68:ac:90:64:95:48:0a:34:04:be:ee:48:74:ed:85:3a:03:7a:7a:8f",
		"Utility.format_fingerprint () is broken");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_octets_to_string () {
        QLocale.set_default (QLocale ("en"));
        GLib.assert_true (octets_to_string (999) == "999 B");
        GLib.assert_true (octets_to_string (1024) == "1 KB");
        GLib.assert_true (octets_to_string (1364) == "1 KB");

        GLib.assert_true (octets_to_string (9110) == "9 KB");
        GLib.assert_true (octets_to_string (9910) == "10 KB");
        GLib.assert_true (octets_to_string (10240) == "10 KB");

        GLib.assert_true (octets_to_string (123456) == "121 KB");
        GLib.assert_true (octets_to_string (1234567) == "1.2 MB");
        GLib.assert_true (octets_to_string (12345678) == "12 MB");
        GLib.assert_true (octets_to_string (123456789) == "118 MB");
        GLib.assert_true (octets_to_string (1000LL * 1000 * 1000 * 5) == "4.7 GB");

        GLib.assert_true (octets_to_string (1) == "1 B");
        GLib.assert_true (octets_to_string (2) == "2 B");
        GLib.assert_true (octets_to_string (1024) == "1 KB");
        GLib.assert_true (octets_to_string (1024 * 1024) == "1 MB");
        GLib.assert_true (octets_to_string (1024LL * 1024 * 1024) == "1 GB");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_launch_on_signal_startup () {
        string postfix = Occ.Utility.rand ().to_string ();

        const string app_name = "on_signal_test_launch_on_signal_startup.%1".printf (postfix);
        const string gui_name = "LaunchOnStartup GUI Name";

        GLib.assert_true (has_launch_on_startup (app_name) == false);
        set_launch_on_startup (app_name, gui_name, true);
        GLib.assert_true (has_launch_on_startup (app_name) == true);
        set_launch_on_startup (app_name, gui_name, false);
        GLib.assert_true (has_launch_on_startup (app_name) == false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_duration_to_descriptive_string () {
        QLocale.set_default (QLocale ("C"));
        //Note: in order for the plural to work we would need to load the english translation

        uint64 sec = 1000;
        uint64 hour = 3600 * sec;

        GLib.DateTime current = GLib.DateTime.current_date_time_utc ();

        GLib.assert_true (duration_to_descriptive_string2 (0) == "0 second (s)");
        GLib.assert_true (duration_to_descriptive_string2 (5) == "0 second (s)");
        GLib.assert_true (duration_to_descriptive_string2 (1000) == "1 second (s)");
        GLib.assert_true (duration_to_descriptive_string2 (1005) == "1 second (s)");
        GLib.assert_true (duration_to_descriptive_string2 (56123) == "56 second (s)");
        GLib.assert_true (duration_to_descriptive_string2 (90 * sec) == "1 minute (s) 30 second (s)");
        GLib.assert_true (duration_to_descriptive_string2 (3 * hour) == "3 hour (s)");
        GLib.assert_true (duration_to_descriptive_string2 (3 * hour + 20 * sec) == "3 hour (s)");
        GLib.assert_true (duration_to_descriptive_string2 (3 * hour + 70 * sec) == "3 hour (s) 1 minute (s)");
        GLib.assert_true (duration_to_descriptive_string2 (3 * hour + 100 * sec) == "3 hour (s) 2 minute (s)");
        GLib.assert_true (duration_to_descriptive_string2 (current.msecs_to (current.add_years (4).add_months (5).add_days (2).add_secs (23 * 60 * 60))) ==
            "4 year (s) 5 month (s)");
        GLib.assert_true (duration_to_descriptive_string2 (current.msecs_to (current.add_days (2).add_secs (23 * 60 * 60))) ==
            "2 day (s) 23 hour (s)");

        GLib.assert_true (duration_to_descriptive_string1 (0) == "0 second (s)");
        GLib.assert_true (duration_to_descriptive_string1 (5) == "0 second (s)");
        GLib.assert_true (duration_to_descriptive_string1 (1000) == "1 second (s)");
        GLib.assert_true (duration_to_descriptive_string1 (1005) == "1 second (s)");
        GLib.assert_true (duration_to_descriptive_string1 (56123) == "56 second (s)");
        GLib.assert_true (duration_to_descriptive_string1 (90 * sec) == "2 minute (s)");
        GLib.assert_true (duration_to_descriptive_string1 (3 * hour) == "3 hour (s)");
        GLib.assert_true (duration_to_descriptive_string1 (3 * hour + 20 * sec) == "3 hour (s)");
        GLib.assert_true (duration_to_descriptive_string1 (3 * hour + 70 * sec) == "3 hour (s)");
        GLib.assert_true (duration_to_descriptive_string1 (3 * hour + 100 * sec) == "3 hour (s)");
        GLib.assert_true (duration_to_descriptive_string1 (current.msecs_to (current.add_years (4).add_months (5).add_days (2).add_secs (23 * 60 * 60))) ==
            "4 year (s)");
        GLib.assert_true (duration_to_descriptive_string1 (current.msecs_to (current.add_days (2).add_secs (23 * 60 * 60))) ==
            "3 day (s)");

    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_version_of_installed_binary () {
        if (is_linux ()) {
            // pass the command client from our build directory
            // this is a bit inaccurate as it does not test the "real thing"
            // but command and gui have the same --version handler by now
            // and command works without X in CI
            string version = version_of_installed_binary (OWNCLOUD_BIN_PATH + "/" + APPLICATION_EXECUTABLE + "command");
            GLib.debug ("Version of installed Nextcloud: " + version);
            GLib.assert_true (!version == "");

            const QRegularExpression rx = new QRegularExpression (QRegularExpression.anchored_pattern (APPLICATION_SHORTNAME + " ( version \d+\.\d+\.\d+.*)"));
            GLib.assert_true (rx.match (version).has_match ());
        } else {
            GLib.assert_true (version_of_installed_binary () == "");
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_time_ago () {
        // Both times in same timezone
        GLib.DateTime d1 = GLib.DateTime.from_string ("2015-01-24T09:20:30+01:00", Qt.ISODate);
        GLib.DateTime d2 = GLib.DateTime.from_string ("2015-01-23T09:20:30+01:00", Qt.ISODate);
        string test_string = time_ago_in_words (d2, d1);
        GLib.assert_true (test_string == "1 day ago");

        // Different timezones
        GLib.DateTime early_timestamp = GLib.DateTime.from_string ("2015-01-24T09:20:30+01:00", Qt.ISODate);
        GLib.DateTime later_timestamp = GLib.DateTime.from_string ("2015-01-24T09:20:30-01:00", Qt.ISODate);
        test_string = time_ago_in_words (early_timestamp, later_timestamp);
        GLib.assert_true (test_string == "2 hours ago");

        // 'Now' in whatever timezone
        early_timestamp = GLib.DateTime.current_date_time ();
        later_timestamp = early_timestamp;
        test_string = time_ago_in_words (early_timestamp, later_timestamp );
        GLib.assert_true (test_string == "now");

        early_timestamp = early_timestamp.add_secs (-6);
        test_string = time_ago_in_words (early_timestamp, later_timestamp);
        GLib.assert_true (test_string == "Less than a minute ago");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_fs_case_preserving () {
        GLib.assert_true (is_mac () || is_windows () ? filesystem_case_preserving () : ! filesystem_case_preserving ());
        QScopedValueRollback<bool> scope = new QScopedValueRollback<bool> (Occ.filesystem_case_preserving_override);
        Occ.filesystem_case_preserving_override = true;
        GLib.assert_true (filesystem_case_preserving ());
        Occ.filesystem_case_preserving_override = false;
        GLib.assert_true (! filesystem_case_preserving ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_filenames_equal () {
        QTemporaryDir directory;
        GLib.assert_true (directory.is_valid ());
        GLib.Dir dir2 = new GLib.Dir (directory.path ());
        GLib.assert_true (dir2.mkpath ("test"));
        if ( !filesystem_case_preserving () ) {
        GLib.assert_true (dir2.mkpath ("TEST"));
        }
        GLib.assert_true (dir2.mkpath ("test/TESTI"));
        GLib.assert_true (dir2.mkpath ("TESTI"));

        string a = directory.path ();
        string b = directory.path ();

        GLib.assert_true (file_names_equal (a, b));

        GLib.assert_true (file_names_equal (a+"/test", b+"/test")); // both exist
        GLib.assert_true (file_names_equal (a+"/test/TESTI", b+"/test/../test/TESTI")); // both exist

        QScopedValueRollback<bool> scope = new QScopedValueRollback<bool> (Occ.filesystem_case_preserving_override, true);
        GLib.assert_true (file_names_equal (a+"/test", b+"/TEST")); // both exist

        GLib.assert_true (!file_names_equal (a+"/test", b+"/test/TESTI")); // both are different

        directory.remove ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_sanitize_for_filename_data () {
        QTest.add_column<string> ("input");
        QTest.add_column<string> ("output");

        QTest.new_row ("")
            + "foobar"
            + "foobar";
        QTest.new_row ("")
            + "a/b?c<d>e\\f:g*h|i\"j"
            + "abcdefghij";
        QTest.new_row ("")
            + "a\x01 b\x1f c\x80 d\x9f"
            + "a b c d";
    }


    /***********************************************************
    ***********************************************************/
    private void test_sanitize_for_filename () {
        QFETCH (string, input);
        QFETCH (string, output);
        GLib.assert_true (sanitize_for_filename (input), output);
    }

    void test_normalize_etag () {
        string string_value;
    }

    int CHECK_NORMALIZE_ETAG (string TEST, string EXPECT) {
        string_value = Occ.Utility.normalize_etag (TEST);
        GLib.assert_true (string_value.const_data (), EXPECT);

        CHECK_NORMALIZE_ETAG ("foo", "foo");
        CHECK_NORMALIZE_ETAG ("\"foo\"", "foo");
        CHECK_NORMALIZE_ETAG ("\"nar123\"", "nar123");
        CHECK_NORMALIZE_ETAG ("", "");
        CHECK_NORMALIZE_ETAG ("\"\"", "");

        /* Test with -gzip (all combinaison) */
        CHECK_NORMALIZE_ETAG ("foo-gzip", "foo");
        CHECK_NORMALIZE_ETAG ("\"foo\"-gzip", "foo");
        CHECK_NORMALIZE_ETAG ("\"foo-gzip\"", "foo");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_is_path_windows_drive_partition_root () {
        // should always return false on non-Windows
        GLib.assert_true (!is_path_windows_drive_partition_root ("c:"));
        GLib.assert_true (!is_path_windows_drive_partition_root ("c:/"));
        GLib.assert_true (!is_path_windows_drive_partition_root ("c:\\"));
    }

} // class TestUtility 
} // namespace Testing
