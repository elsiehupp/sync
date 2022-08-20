/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestFileRecord : AbstractTestSyncJournalDB {

//    /***********************************************************
//    ***********************************************************/
//    private TestFileRecord () {
//        Common.SyncJournalFileRecord record;
//        GLib.assert_true (this.database.get_file_record ("nonexistant", record));
//        GLib.assert_true (!record.is_valid);

//        record.path = "foo";
//        // Use a value that exceeds uint32 and isn't representable by the
//        // signed int being cast to uint64 either (like uint64.max would be)
//        record.inode = std.numeric_limits<uint32>.max () + 12ull;
//        record.modtime = drop_msecs (GLib.DateTime.current_date_time ());
//        record.type = ItemType.DIRECTORY;
//        record.etag = "789789";
//        record.file_identifier = "abcd";
//        record.remote_permissions = Common.RemotePermissions.from_database_value ("RW");
//        record.file_size = 213089055;
//        record.checksum_header = "MD5:mychecksum";
//        GLib.assert_true (this.database.set_file_record (record));

//        Common.SyncJournalFileRecord stored_record;
//        GLib.assert_true (this.database.get_file_record ("foo", stored_record));
//        GLib.assert_true (stored_record == record);

//        // Update checksum
//        record.checksum_header = "Adler32:newchecksum";
//        this.database.update_file_record_checksum ("foo", "newchecksum", "Adler32");
//        GLib.assert_true (this.database.get_file_record ("foo", stored_record));
//        GLib.assert_true (stored_record == record);

//        // Update metadata
//        record.modtime = drop_msecs (GLib.DateTime.current_date_time ().add_days (1));
//        // try a value that only fits uint64, not int64
//        record.inode = std.numeric_limits<uint64>.max () - std.numeric_limits<uint32>.max () - 1;
//        record.type = ItemType.FILE;
//        record.etag = "789FFF";
//        record.file_identifier = "efg";
//        record.remote_permissions = Common.RemotePermissions.from_database_value ("NV");
//        record.file_size = 289055;
//        this.database.set_file_record (record);
//        GLib.assert_true (this.database.get_file_record ("foo", stored_record));
//        GLib.assert_true (stored_record == record);

//        GLib.assert_true (this.database.delete_file_record ("foo"));
//        GLib.assert_true (this.database.get_file_record ("foo", record));
//        GLib.assert_true (!record.is_valid);
//    }

} // class TestFileRecord

} // namespace Testing
} // namespace Occ
