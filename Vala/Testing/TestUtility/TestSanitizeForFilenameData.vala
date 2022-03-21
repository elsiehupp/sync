namespace Occ {
namespace Testing {

/***********************************************************
@class TestSanitizeForFilenameData

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public abstract class TestSanitizeForFilenameData : AbstractTestUtility {

    /***********************************************************
    ***********************************************************/
    private TestSanitizeForFilenameData () {
        QTest.add_column<string> ("input");
        QTest.add_column<string> ("output");

        QTest.new_row ("")
            + "foobar"
            + "foobar";
        QTest.new_row ("")
            + "a/b?c<d>e\\f:g*h|i\"j"
            + "abcdefghij";
        QTest.new_row ("")
            + "a\x01 b\x1f c\x80 d\x9f"
            + "a b c d";
    }

} // class TestSanitizeForFilenameData

} // namespace Testing
} // namespace Occ
