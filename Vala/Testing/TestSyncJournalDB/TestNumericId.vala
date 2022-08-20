/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestNumericId : AbstractTestSyncJournalDB {

//    /***********************************************************
//    ***********************************************************/
//    private TestNumericId () {
//        Common.SyncJournalFileRecord record;

//        // Typical 8-digit padded identifier
//        record.file_identifier = "00000001abcd";
//        GLib.assert_true (record.numeric_file_id () == "00000001");

//        // When the numeric identifier overflows the 8-digit boundary
//        record.file_identifier = "123456789ocidblaabcd";
//        GLib.assert_true (record.numeric_file_id () == "123456789");
//    }

} // class TestNumericId

} // namespace Testing
} // namespace Occ
