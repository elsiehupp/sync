namespace Occ {
namespace Testing {

/***********************************************************
@class TestCSyncRegexTraversal

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCSyncRegexTraversal : AbstractTestCSyncExclude {

    /***********************************************************
    ***********************************************************/
    private TestCSyncRegexTraversal () {
        up ();
        string storage;

        GLib.assert_true (translate_to_regexp_syntax ("") == "");
        GLib.assert_true (translate_to_regexp_syntax ("abc") == "abc");
        GLib.assert_true (translate_to_regexp_syntax ("a*c") == "a[^/]*c");
        GLib.assert_true (translate_to_regexp_syntax ("a?c") == "a[^/]c");
        GLib.assert_true (translate_to_regexp_syntax ("a[xyz]c") == "a[xyz]c");
        GLib.assert_true (translate_to_regexp_syntax ("a[xyzc") == "a\\[xyzc");
        GLib.assert_true (translate_to_regexp_syntax ("a[!xyz]c") == "a[^xyz]c");
        GLib.assert_true (translate_to_regexp_syntax ("a\\*b\\?c\\[d\\\\e") == "a\\*b\\?c\\[d\\\\e");
        GLib.assert_true (translate_to_regexp_syntax ("a.c") == "a\\.c");
        GLib.assert_true (translate_to_regexp_syntax ("?𠜎?") == "[^/]\\𠜎[^/]"); // 𠜎 is 4-byte utf8
    }


    /***********************************************************
    ***********************************************************/
    private string translate_to_regexp_syntax (string pattern) {
        string storage = CSync.ExcludedFiles.convert_to_regexp_syntax (pattern, false);
        return storage.const_data ();
    }

} // class TestCSyncRegexTraversal

} // namespace Testing
} // namespace Occ
