namespace Occ {
namespace Testing {

/***********************************************************
@class TestOctetsToString

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestOctetsToString : AbstractTestUtility {

    /***********************************************************
    ***********************************************************/
    private TestOctetsToString () {
        GLib.Locale.set_default (GLib.Locale ("en"));
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

} // class TestOctetsToString

} // namespace Testing
} // namespace Occ
