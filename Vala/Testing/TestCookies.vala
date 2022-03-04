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
    private on_ void testCookies () {
        QTemporaryDir tmp;
        const string nonexistingPath = tmp.filePath ("someNonexistingDir/test.db");
        QNetworkCookie cookieA = QNetworkCookie ("foo", "bar");
        // tomorrow rounded
        cookieA.setExpirationDate (GLib.DateTime.currentDateTimeUtc ().addDays (1).date ().startOfDay ());
        const GLib.List<QNetworkCookie> cookies = {cookieA, QNetworkCookie ("foo2", "bar")};
        CookieJar jar;
        jar.setAllCookies (cookies);
        QCOMPARE (cookies, jar.allCookies ());
        QVERIFY (jar.save (tmp.filePath ("test.db")));
        // ensure we are able to create a cookie jar in a non exisitning folder (mkdir)
        QVERIFY (jar.save (nonexistingPath));

        CookieJar jar2;
        QVERIFY (jar2.restore (nonexistingPath));
        // here we should have  only cookieA as the second one was a session cookie
        QCOMPARE (GLib.List<QNetworkCookie>{cookieA}, jar2.allCookies ());

    }

}

QTEST_APPLESS_MAIN (TestCookies)
#include "testcookies.moc"
