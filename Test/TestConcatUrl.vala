/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.

***********************************************************/

// #include <QtTest>

// #include <GLib.Uri>
// #include <string>

using namespace Occ;

using QueryItems = GLib.List<QPair<string, string>>;

Q_DECLARE_METATYPE (QueryItems)

static QueryItems make () {
    return QueryItems ();
}

static QueryItems make (string key, string value) {
    QueryItems q;
    q.append (qMakePair (key, value));
    return q;
}

static QueryItems make (string key1, string value1,
                       string key2, string value2) {
    QueryItems q;
    q.append (qMakePair (key1, value1));
    q.append (qMakePair (key2, value2));
    return q;
}

class TestConcatUrl : public GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testFolder () {
        QFETCH (string, base);
        QFETCH (string, concat);
        QFETCH (QueryItems, query);
        QFETCH (string, expected);
        GLib.Uri baseUrl ("http://example.com" + base);
        QUrlQuery urlQuery;
        urlQuery.setQueryItems (query);
        GLib.Uri resultUrl = Utility.concatUrlPath (baseUrl, concat, urlQuery);
        string result = string.fromUtf8 (resultUrl.toEncoded ());
        string expectedFull = "http://example.com" + expected;
        QCOMPARE (result, expectedFull);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testFolder_data () {
        QTest.addColumn<string> ("base");
        QTest.addColumn<string> ("concat");
        QTest.addColumn<QueryItems> ("query");
        QTest.addColumn<string> ("expected");

        // Tests about slashes
        QTest.newRow ("noslash1")  << "/baa"  << "foo"  << make () << "/baa/foo";
        QTest.newRow ("noslash2")  << ""      << "foo"  << make () << "/foo";
        QTest.newRow ("noslash3")  << "/foo"  << ""     << make () << "/foo";
        QTest.newRow ("noslash4")  << ""      << ""     << make () << "";
        QTest.newRow ("oneslash1") << "/bar/" << "foo"  << make () << "/bar/foo";
        QTest.newRow ("oneslash2") << "/"     << "foo"  << make () << "/foo";
        QTest.newRow ("oneslash3") << "/foo"  << "/"    << make () << "/foo/";
        QTest.newRow ("oneslash4") << ""      << "/"    << make () << "/";
        QTest.newRow ("twoslash1") << "/bar/" << "/foo" << make () << "/bar/foo";
        QTest.newRow ("twoslash2") << "/"     << "/foo" << make () << "/foo";
        QTest.newRow ("twoslash3") << "/foo/" << "/"    << make () << "/foo/";
        QTest.newRow ("twoslash4") << "/"     << "/"    << make () << "/";

        // Tests about path encoding
        QTest.newRow ("encodepath")
                << "/a f/b"
                << "/a f/c"
                << make ()
                << "/a%20f/b/a%20f/c";

        // Tests about query args
        QTest.newRow ("query1")
                << "/baa"
                << "/foo"
                << make ("a=a", "b=b",
                        "c", "d")
                << "/baa/foo?a%3Da=b%3Db&c=d";
        QTest.newRow ("query2")
                << ""
                << ""
                << make ("foo", "bar")
                << "?foo=bar";
    }

};

QTEST_APPLESS_MAIN (TestConcatUrl)
#include "testconcaturl.moc"
