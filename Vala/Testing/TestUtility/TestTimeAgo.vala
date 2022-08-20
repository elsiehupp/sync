namespace Occ {
namespace Testing {

/***********************************************************
@class TestTimeAgo

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestTimeAgo : AbstractTestUtility {

//    /***********************************************************
//    ***********************************************************/
//    private TestTimeAgo () {
//        // Both times in same timezone
//        GLib.DateTime d1 = GLib.DateTime.from_string ("2015-01-24T09:20:30+01:00", GLib.ISODate);
//        GLib.DateTime d2 = GLib.DateTime.from_string ("2015-01-23T09:20:30+01:00", GLib.ISODate);
//        string test_string = time_ago_in_words (d2, d1);
//        GLib.assert_true (test_string == "1 day ago");

//        // Different timezones
//        GLib.DateTime early_timestamp = GLib.DateTime.from_string ("2015-01-24T09:20:30+01:00", GLib.ISODate);
//        GLib.DateTime later_timestamp = GLib.DateTime.from_string ("2015-01-24T09:20:30-01:00", GLib.ISODate);
//        test_string = time_ago_in_words (early_timestamp, later_timestamp);
//        GLib.assert_true (test_string == "2 hours ago");

//        // 'Now' in whatever timezone
//        early_timestamp = GLib.DateTime.current_date_time ();
//        later_timestamp = early_timestamp;
//        test_string = time_ago_in_words (early_timestamp, later_timestamp );
//        GLib.assert_true (test_string == "now");

//        early_timestamp = early_timestamp.add_secs (-6);
//        test_string = time_ago_in_words (early_timestamp, later_timestamp);
//        GLib.assert_true (test_string == "Less than a minute ago");
//    }

} // class TestTimeAgo

} // namespace Testing
} // namespace Occ
