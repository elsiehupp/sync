/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestConflictRecord : AbstractTestSyncJournalDB {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestConflictRecord () {
    //      ConflictRecord record;
    //      record.path = "abc";
    //      record.base_file_id = "def";
    //      record.base_modtime = 1234;
    //      record.base_etag = "ghi";

    //      GLib.assert_true (!this.database.conflict_record (record.path).is_valid);

    //      this.database.set_conflict_record (record);
    //      var new_record = this.database.conflict_record (record.path);
    //      GLib.assert_true (new_record.is_valid);
    //      GLib.assert_true (new_record.path == record.path);
    //      GLib.assert_true (new_record.base_file_id == record.base_file_id);
    //      GLib.assert_true (new_record.base_modtime == record.base_modtime);
    //      GLib.assert_true (new_record.base_etag == record.base_etag);

    //      this.database.delete_conflict_record (record.path);
    //      GLib.assert_true (!this.database.conflict_record (record.path).is_valid);
    //  }

} // class TestConflictRecord

} // namespace Testing
} // namespace Occ
