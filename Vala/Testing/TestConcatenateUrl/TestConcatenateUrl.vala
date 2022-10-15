namespace Occ {
namespace Testing {

/***********************************************************
@class TestConcatenateUrl

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestConcatenateUrl { //: GLib.Object {

    class QueryItems { //: GLib.List<GLib.Pair<string, string>> { }

    /***********************************************************
    ***********************************************************/
    private TestConcatenateUrl () {
        //  GLib.FETCH (string, base);
        //  GLib.FETCH (string, concat);
        //  GLib.FETCH (QueryItems, query);
        //  GLib.FETCH (string, expected);
        //  GLib.Uri base_url = new GLib.Uri ("http://example.com" + base);
        //  GLib.UrlQuery url_query;
        //  url_query.set_query_items (query);
        //  GLib.Uri result_url = Utility.concat_url_path (base_url, concat, url_query);
        //  string result = result_url.to_string ();
        //  string expected_full = "http://example.com" + expected;
        //  GLib.assert_true (result == expected_full);
    }


    /***********************************************************
    ***********************************************************/
    private TestConcatenateUrlData () {
        //  GLib.Test.add_column<string> ("base");
        //  GLib.Test.add_column<string> ("concat");
        //  GLib.Test.add_column<QueryItems> ("query");
        //  GLib.Test.add_column<string> ("expected");

        //  // Tests about slashes
        //  GLib.Test.new_row ("noslash1")  + "/baa"  + "foo"  + make ("/baa/foo");
        //  GLib.Test.new_row ("noslash2")  + ""      + "foo"  + make ("/foo");
        //  GLib.Test.new_row ("noslash3")  + "/foo"  + ""     + make ("/foo");
        //  GLib.Test.new_row ("noslash4")  + ""      + ""     + make ("");
        //  GLib.Test.new_row ("oneslash1") + "/bar/" + "foo"  + make ("/bar/foo");
        //  GLib.Test.new_row ("oneslash2") + "/"     + "foo"  + make ("/foo");
        //  GLib.Test.new_row ("oneslash3") + "/foo"  + "/"    + make ("/foo/");
        //  GLib.Test.new_row ("oneslash4") + ""      + "/"    + make ("/");
        //  GLib.Test.new_row ("twoslash1") + "/bar/" + "/foo" + make ("/bar/foo");
        //  GLib.Test.new_row ("twoslash2") + "/"     + "/foo" + make ("/foo");
        //  GLib.Test.new_row ("twoslash3") + "/foo/" + "/"    + make ("/foo/");
        //  GLib.Test.new_row ("twoslash4") + "/"     + "/"    + make ("/");

        //  // Tests about path encoding
        //  GLib.Test.new_row ("encodepath")
        //          + "/a f/b"
        //          + "/a f/c"
        //          + make ()
        //          + "/a%20f/b/a%20f/c";

        //  // Tests about query args
        //  GLib.Test.new_row ("query1")
        //          + "/baa"
        //          + "/foo"
        //          + make_keys_values ("a=a", "b=b",
        //                  "c", "d")
        //          + "/baa/foo?a%3Da=b%3Db&c=d";
        //  GLib.Test.new_row ("query2")
        //          + ""
        //          + ""
        //          + make_key_value ("foo", "bar")
        //          + "?foo=bar";
    }


    private static QueryItems make () {
        //  return new QueryItems ();
    }


    private static QueryItems make_key_value (string key, string value) {
        //  QueryItems query_items;
        //  query_items.append (new Pair<string, string>  (key, value));
        //  return query_items;
    }


    private static QueryItems make_keys_values (string key1, string value1,
        //                  string key2, string value2) {
        //  QueryItems query_items;
        //  query_items.append (new Pair<string, string>  (key1, value1));
        //  query_items.append (new Pair<string, string>  (key2, value2));
        //  return query_items;
    }

} // class TestConcatenateUrl

} // namespace Testing
} // namespace Occ
