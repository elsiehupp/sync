namespace Occ {
namespace Testing {

/***********************************************************
@class TestCSyncBNameTrigger

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCSyncBNameTrigger : AbstractTestCSyncExclude {

//    /***********************************************************
//    ***********************************************************/
//    private TestCSyncBNameTrigger () {
//        up ();
//        bool wildcards_match_slash = false;
//        string storage;

//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "") == "");
//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "a/b/") == "");
//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "a/b/c") == "c");
//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "c") == "c");
//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "a/foo*") == "foo*");
//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "a/abc*foo*") == "abc*foo*");

//        wildcards_match_slash = true;

//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "") == "");
//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "a/b/") == "");
//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "a/b/c") == "c");
//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "c") == "c");
//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "*") == "*");
//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "a/foo*") == "foo*");
//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "a/abc?foo*") == "*foo*");
//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "a/abc*foo*") == "*foo*");
//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "a/abc?foo?") == "*foo?");
//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "a/abc*foo?*") == "*foo?*");
//        GLib.assert_true (translate_to_bname_trigger (wildcards_match_slash, "a/abc*/foo*") == "foo*");
//    }


//    /***********************************************************
//    ***********************************************************/
//    protected static string translate_to_bname_trigger (bool wildcards_match_slash, string pattern) {
//        return storage = CSync.ExcludedFiles.extract_bname_trigger (pattern, wildcards_match_slash).const_data ();
//    }

} // class TestCSyncBNameTrigger

} // namespace Testing
} // namespace Occ
