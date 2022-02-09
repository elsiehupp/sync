/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <QTemporaryDir>

using namespace Occ.Utility;

namespace Occ {
OCSYNC_EXPORT extern bool fsCasePreserving_override;
}

class TestUtility : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void on_signal_init_test_case () {
        QStandardPaths.setTestModeEnabled (true);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_format_fingerprint () {
        QVERIFY2 (formatFingerprint ("68ac906495480a3404beee4874ed853a037a7a8f")
                 == "68:ac:90:64:95:48:0a:34:04:be:ee:48:74:ed:85:3a:03:7a:7a:8f",
		"Utility.formatFingerprint () is broken");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_octets_to_string () {
        QLocale.setDefault (QLocale ("en"));
        QCOMPARE (octetsToString (999) , string ("999 B"));
        QCOMPARE (octetsToString (1024) , string ("1 KB"));
        QCOMPARE (octetsToString (1364) , string ("1 KB"));

        QCOMPARE (octetsToString (9110) , string ("9 KB"));
        QCOMPARE (octetsToString (9910) , string ("10 KB"));
        QCOMPARE (octetsToString (10240) , string ("10 KB"));

        QCOMPARE (octetsToString (123456) , string ("121 KB"));
        QCOMPARE (octetsToString (1234567) , string ("1.2 MB"));
        QCOMPARE (octetsToString (12345678) , string ("12 MB"));
        QCOMPARE (octetsToString (123456789) , string ("118 MB"));
        QCOMPARE (octetsToString (1000LL*1000*1000 * 5) , string ("4.7 GB"));

        QCOMPARE (octetsToString (1), string ("1 B"));
        QCOMPARE (octetsToString (2), string ("2 B"));
        QCOMPARE (octetsToString (1024), string ("1 KB"));
        QCOMPARE (octetsToString (1024*1024), string ("1 MB"));
        QCOMPARE (octetsToString (1024LL*1024*1024), string ("1 GB"));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_launch_on_signal_startup () {
        string postfix = string.number (Occ.Utility.rand ());

        const string appName = string.fromLatin1 ("on_signal_test_launch_on_signal_startup.%1").arg (postfix);
        const string guiName = "LaunchOnStartup GUI Name";

        QVERIFY (hasLaunchOnStartup (appName) == false);
        setLaunchOnStartup (appName, guiName, true);
        QVERIFY (hasLaunchOnStartup (appName) == true);
        setLaunchOnStartup (appName, guiName, false);
        QVERIFY (hasLaunchOnStartup (appName) == false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_duration_to_descriptive_"" {
        QLocale.setDefault (QLocale ("C"));
        //Note: in order for the plural to work we would need to load the english translation

        uint64 sec = 1000;
        uint64 hour = 3600 * sec;

        GLib.DateTime current = GLib.DateTime.currentDateTimeUtc ();

        QCOMPARE (durationToDescriptiveString2 (0), string ("0 second (s)") );
        QCOMPARE (durationToDescriptiveString2 (5), string ("0 second (s)") );
        QCOMPARE (durationToDescriptiveString2 (1000), string ("1 second (s)") );
        QCOMPARE (durationToDescriptiveString2 (1005), string ("1 second (s)") );
        QCOMPARE (durationToDescriptiveString2 (56123), string ("56 second (s)") );
        QCOMPARE (durationToDescriptiveString2 (90*sec), string ("1 minute (s) 30 second (s)") );
        QCOMPARE (durationToDescriptiveString2 (3*hour), string ("3 hour (s)") );
        QCOMPARE (durationToDescriptiveString2 (3*hour + 20*sec), string ("3 hour (s)") );
        QCOMPARE (durationToDescriptiveString2 (3*hour + 70*sec), string ("3 hour (s) 1 minute (s)") );
        QCOMPARE (durationToDescriptiveString2 (3*hour + 100*sec), string ("3 hour (s) 2 minute (s)") );
        QCOMPARE (durationToDescriptiveString2 (current.msecsTo (current.addYears (4).addMonths (5).addDays (2).addSecs (23*60*60))),
                 string ("4 year (s) 5 month (s)") );
        QCOMPARE (durationToDescriptiveString2 (current.msecsTo (current.addDays (2).addSecs (23*60*60))),
                 string ("2 day (s) 23 hour (s)") );

        QCOMPARE (durationToDescriptiveString1 (0), string ("0 second (s)") );
        QCOMPARE (durationToDescriptiveString1 (5), string ("0 second (s)") );
        QCOMPARE (durationToDescriptiveString1 (1000), string ("1 second (s)") );
        QCOMPARE (durationToDescriptiveString1 (1005), string ("1 second (s)") );
        QCOMPARE (durationToDescriptiveString1 (56123), string ("56 second (s)") );
        QCOMPARE (durationToDescriptiveString1 (90*sec), string ("2 minute (s)") );
        QCOMPARE (durationToDescriptiveString1 (3*hour), string ("3 hour (s)") );
        QCOMPARE (durationToDescriptiveString1 (3*hour + 20*sec), string ("3 hour (s)") );
        QCOMPARE (durationToDescriptiveString1 (3*hour + 70*sec), string ("3 hour (s)") );
        QCOMPARE (durationToDescriptiveString1 (3*hour + 100*sec), string ("3 hour (s)") );
        QCOMPARE (durationToDescriptiveString1 (current.msecsTo (current.addYears (4).addMonths (5).addDays (2).addSecs (23*60*60))),
                 string ("4 year (s)") );
        QCOMPARE (durationToDescriptiveString1 (current.msecsTo (current.addDays (2).addSecs (23*60*60))),
                 string ("3 day (s)") );

    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_version_of_installed_binary () {
        if (isLinux ()) {
            // pass the cmd client from our build dir
            // this is a bit inaccurate as it does not test the "real thing"
            // but cmd and gui have the same --version handler by now
            // and cmd works without X in CI
            string ver = versionOfInstalledBinary (QStringLiteral (OWNCLOUD_BIN_PATH  "/" APPLICATION_EXECUTABLE "cmd"));
            GLib.debug ("Version of installed Nextcloud : " + ver;
            QVERIFY (!ver.isEmpty ());

            const QRegularExpression rx (QRegularExpression.anchoredPattern (APPLICATION_SHORTNAME R" ( version \d+\.\d+\.\d+.*)"));
            QVERIFY (rx.match (ver).hasMatch ());
        } else {
            QVERIFY (versionOfInstalledBinary ().isEmpty ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_time_ago () {
        // Both times in same timezone
        GLib.DateTime d1 = GLib.DateTime.fromString ("2015-01-24T09:20:30+01:00", Qt.ISODate);
        GLib.DateTime d2 = GLib.DateTime.fromString ("2015-01-23T09:20:30+01:00", Qt.ISODate);
        string s = timeAgoInWords (d2, d1);
        QCOMPARE (s, QLatin1String ("1 day ago"));

        // Different timezones
        GLib.DateTime earlyTS = GLib.DateTime.fromString ("2015-01-24T09:20:30+01:00", Qt.ISODate);
        GLib.DateTime laterTS = GLib.DateTime.fromString ("2015-01-24T09:20:30-01:00", Qt.ISODate);
        s = timeAgoInWords (earlyTS, laterTS);
        QCOMPARE (s, QLatin1String ("2 hours ago"));

        // 'Now' in whatever timezone
        earlyTS = GLib.DateTime.currentDateTime ();
        laterTS = earlyTS;
        s = timeAgoInWords (earlyTS, laterTS );
        QCOMPARE (s, QLatin1String ("now"));

        earlyTS = earlyTS.addSecs (-6);
        s = timeAgoInWords (earlyTS, laterTS );
        QCOMPARE (s, QLatin1String ("Less than a minute ago"));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_fs_case_preserving () {
        QVERIFY (isMac () || isWindows () ? fsCasePreserving () : ! fsCasePreserving ());
        QScopedValueRollback<bool> scope (Occ.fsCasePreserving_override);
        Occ.fsCasePreserving_override = true;
        QVERIFY (fsCasePreserving ());
        Occ.fsCasePreserving_override = false;
        QVERIFY (! fsCasePreserving ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_filenames_equal () {
        QTemporaryDir dir;
        QVERIFY (dir.isValid ());
        QDir dir2 (dir.path ());
        QVERIFY (dir2.mkpath ("test"));
        if ( !fsCasePreserving () ) {
        QVERIFY (dir2.mkpath ("TEST"));
        }
        QVERIFY (dir2.mkpath ("test/TESTI"));
        QVERIFY (dir2.mkpath ("TESTI"));

        string a = dir.path ();
        string b = dir.path ();

        QVERIFY (fileNamesEqual (a, b));

        QVERIFY (fileNamesEqual (a+"/test", b+"/test")); // both exist
        QVERIFY (fileNamesEqual (a+"/test/TESTI", b+"/test/../test/TESTI")); // both exist

        QScopedValueRollback<bool> scope (Occ.fsCasePreserving_override, true);
        QVERIFY (fileNamesEqual (a+"/test", b+"/TEST")); // both exist

        QVERIFY (!fileNamesEqual (a+"/test", b+"/test/TESTI")); // both are different

        dir.remove ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_sanitize_for_filename_data () {
        QTest.addColumn<string> ("input");
        QTest.addColumn<string> ("output");

        QTest.newRow ("")
            + "foobar"
            + "foobar";
        QTest.newRow ("")
            + "a/b?c<d>e\\f:g*h|i\"j"
            + "abcdefghij";
        QTest.newRow ("")
            + string.fromLatin1 ("a\x01 b\x1f c\x80 d\x9f")
            + "a b c d";
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testSanitizeForFileName () {
        QFETCH (string, input);
        QFETCH (string, output);
        QCOMPARE (sanitizeForFileName (input), output);
    }

    void testNormalizeEtag () {
        GLib.ByteArray string_value;

const int CHECK_NORMALIZE_ETAG (TEST, EXPECT)
    string_value = Occ.Utility.normalizeEtag (TEST);
    QCOMPARE (string_value.constData (), EXPECT);

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
        QVERIFY (!isPathWindowsDrivePartitionRoot ("c:"));
        QVERIFY (!isPathWindowsDrivePartitionRoot ("c:/"));
        QVERIFY (!isPathWindowsDrivePartitionRoot ("c:\\"));
    }
}

QTEST_GUILESS_MAIN (TestUtility)