namespace Occ {
namespace Testing {

/***********************************************************
@class TestFormatFingerprint

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestFormatFingerprint : AbstractTestUtility {

    /***********************************************************
    ***********************************************************/
    private TestFormatFingerprint () {
        GLib.VERIFY2 (format_fingerprint ("68ac906495480a3404beee4874ed853a037a7a8f")
                 == "68:ac:90:64:95:48:0a:34:04:be:ee:48:74:ed:85:3a:03:7a:7a:8f",
		"Utility.format_fingerprint () is broken");
    }

} // class TestFormatFingerprint

} // namespace Testing
} // namespace Occ
