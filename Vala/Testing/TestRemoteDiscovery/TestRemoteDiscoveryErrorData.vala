namespace Occ {
namespace Testing {

/***********************************************************
@class TestRemoteDiscoveryErrorData

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestRemoteDiscoveryErrorData : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestRemoteDiscoveryErrorData () {
        //  QRegisterMetaType<ErrorCategory> ();
        QTest.add_column<int> ("error_kind");
        QTest.add_column<string> ("expected_error_string");
        QTest.add_column<bool> ("sync_succeeds");

        string item_error_message = "Internal Server Fake Error";

        QTest.new_row ("400", 400, item_error_message, false);
        QTest.new_row ("401", 401, item_error_message, false);
        QTest.new_row ("403", 403, item_error_message, true);
        QTest.new_row ("404", 404, item_error_message, true);
        QTest.new_row ("500", 500, item_error_message, true);
        QTest.new_row ("503", 503, item_error_message, true);
        // 200 should be an error since propfind should return 207
        QTest.new_row ("200", 200, item_error_message, false);
        QTest.new_row ("InvalidXML", InvalidXML, "Unknown error", false);
        QTest.new_row ("Timeout", Timeout, "Operation canceled", false);
    }

} // class TestRemoteDiscoveryErrorData

} // namespace Testing
} // namespace Occ
