/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>

using Occ;

namespace Testing {

class TestConcatUrl {

class TestConcatUrl : GLib.Object {

    class QueryItems : GLib.List<QPair<string, string>> { }

    /***********************************************************
    ***********************************************************/
    private void on_test_folder () {
        QFETCH (string, base);
        QFETCH (string, concat);
        QFETCH (QueryItems, query);
        QFETCH (string, expected);
        GLib.Uri base_url = new GLib.Uri ("http://example.com" + base);
        QUrlQuery url_query;
        url_query.setQueryItems (query);
        GLib.Uri resultUrl = Utility.concat_url_path (base_url, concat, url_query);
        string result = string.fromUtf8 (resultUrl.toEncoded ());
        string expectedFull = "http://example.com" + expected;
        GLib.assert_cmp (result, expectedFull);
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_folder_data () {
        QTest.add_column<string> ("base");
        QTest.add_column<string> ("concat");
        QTest.add_column<QueryItems> ("query");
        QTest.add_column<string> ("expected");

        // Tests about slashes
        QTest.new_row ("noslash1")  + "/baa"  + "foo"  + make ("/baa/foo");
        QTest.new_row ("noslash2")  + ""      + "foo"  + make ("/foo");
        QTest.new_row ("noslash3")  + "/foo"  + ""     + make ("/foo");
        QTest.new_row ("noslash4")  + ""      + ""     + make ("");
        QTest.new_row ("oneslash1") + "/bar/" + "foo"  + make ("/bar/foo");
        QTest.new_row ("oneslash2") + "/"     + "foo"  + make ("/foo");
        QTest.new_row ("oneslash3") + "/foo"  + "/"    + make ("/foo/");
        QTest.new_row ("oneslash4") + ""      + "/"    + make ("/");
        QTest.new_row ("twoslash1") + "/bar/" + "/foo" + make ("/bar/foo");
        QTest.new_row ("twoslash2") + "/"     + "/foo" + make ("/foo");
        QTest.new_row ("twoslash3") + "/foo/" + "/"    + make ("/foo/");
        QTest.new_row ("twoslash4") + "/"     + "/"    + make ("/");

        // Tests about path encoding
        QTest.new_row ("encodepath")
                + "/a f/b"
                + "/a f/c"
                + make ()
                + "/a%20f/b/a%20f/c";

        // Tests about query args
        QTest.new_row ("query1")
                + "/baa"
                + "/foo"
                + make_keys_values ("a=a", "b=b",
                        "c", "d")
                + "/baa/foo?a%3Da=b%3Db&c=d";
        QTest.new_row ("query2")
                + ""
                + ""
                + make_key_value ("foo", "bar")
                + "?foo=bar";
    }

    static QueryItems make () {
        return new QueryItems ();
    }

    static QueryItems make_key_value (string key, string value) {
        QueryItems query_items;
        query_items.append (qMakePair (key, value));
        return query_items;
    }

    static QueryItems make_keys_values (string key1, string value1,
                        string key2, string value2) {
        QueryItems query_items;
        query_items.append (qMakePair (key1, value1));
        query_items.append (qMakePair (key2, value2));
        return query_items;
    }

} // class TestConcatUrl
} // namespace Testing
