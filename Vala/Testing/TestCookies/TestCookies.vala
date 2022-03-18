/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.
***********************************************************/


namespace Occ {
namespace Testing {

public class TestCookies : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestCookies () {
        QTemporaryDir temporary;
        const string nonexisting_path = temporary.file_path ("some_nonexisting_directory/test.db");
        QNetworkCookie cookie_a = new QNetworkCookie ("foo", "bar");
        // tomorrow rounded
        cookie_a.set_expiration_date (GLib.DateTime.current_date_time_utc ().add_days (1).date ().start_of_day ());
        const GLib.List<QNetworkCookie> cookies = {cookie_a, QNetworkCookie ("foo2", "bar")};
        CookieJar jar;
        jar.set_all_cookies (cookies);
        GLib.assert_true (cookies == jar.all_cookies ());
        GLib.assert_true (jar.save (temporary.file_path ("test.db")));
        // ensure we are able to create a cookie jar in a non exisitning folder (mkdir)
        GLib.assert_true (jar.save (nonexisting_path));

        CookieJar jar2;
        GLib.assert_true (jar2.restore (nonexisting_path));
        // here we should have  only cookie_a as the second one was a session cookie
        GLib.assert_true (GLib.List<QNetworkCookie> (cookie_a) == jar2.all_cookies ());

    }

}

} // namespace Testing
} // namespace Occ
