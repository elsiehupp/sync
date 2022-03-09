/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.
***********************************************************/

//  #include <QtTest>

using Occ;

namespace Testing {

class TestCookies : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void testCookies () {
        QTemporaryDir tmp;
        const string nonexistingPath = tmp.file_path ("someNonexistingDir/test.db");
        QNetworkCookie cookieA = QNetworkCookie ("foo", "bar");
        // tomorrow rounded
        cookieA.setExpirationDate (GLib.DateTime.current_date_time_utc ().add_days (1).date ().startOfDay ());
        const GLib.List<QNetworkCookie> cookies = {cookieA, QNetworkCookie ("foo2", "bar")};
        CookieJar jar;
        jar.setAllCookies (cookies);
        GLib.assert_cmp (cookies, jar.allCookies ());
        GLib.assert_true (jar.save (tmp.file_path ("test.db")));
        // ensure we are able to create a cookie jar in a non exisitning folder (mkdir)
        GLib.assert_true (jar.save (nonexistingPath));

        CookieJar jar2;
        GLib.assert_true (jar2.restore (nonexistingPath));
        // here we should have  only cookieA as the second one was a session cookie
        GLib.assert_cmp (GLib.List<QNetworkCookie>{cookieA}, jar2.allCookies ());

    }

}
}
