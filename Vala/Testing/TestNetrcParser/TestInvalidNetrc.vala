namespace Occ {
namespace Testing {

/***********************************************************
@class TestInvalidNetrc

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestInvalidNetrc : AbstractTestNetrcParser {

    private const string TESTFILE = "/invalid";

    /***********************************************************
    ***********************************************************/
    private TestInvalidNetrc () {
        base ();

        NetrcParser parser = new NetrcParser (TESTFILE);
        GLib.assert_true (!parser.parse ());

        delete (this);
    }

} // class TestInvalidNetrc

} // namespace Testing
} // namespace Occ
