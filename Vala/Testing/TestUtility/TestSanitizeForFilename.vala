namespace Occ {
namespace Testing {

/***********************************************************
@class TestSanitizeForFilename

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public abstract class TestSanitizeForFilename : AbstractTestUtility {

    /***********************************************************
    ***********************************************************/
    private TestSanitizeForFilename () {
        QFETCH (string, input);
        QFETCH (string, output);
        GLib.assert_true (sanitize_for_filename (input), output);
    }

} // class TestSanitizeForFilename

} // namespace Testing
} // namespace Occ
