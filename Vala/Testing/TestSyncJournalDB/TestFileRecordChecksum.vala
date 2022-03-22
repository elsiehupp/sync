/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestFileRecordChecksum : AbstractTestSyncJournalDB {

    /***********************************************************
    Try with and without a checksum
    ***********************************************************/
    private TestFileRecordChecksum () {
        SyncJournalFileRecord record = new SyncJournalFileRecord ();
        record.path = "foo-checksum";
        record.remote_permissions = RemotePermissions.from_database_value (" ");
        record.checksum_header = "MD5:mychecksum";
        record.modtime = Utility.date_time_to_time_t (GLib.DateTime.current_date_time_utc ());
        GLib.assert_true (this.database.set_file_record (record));

        SyncJournalFileRecord stored_record = new SyncJournalFileRecord ();
        GLib.assert_true (this.database.get_file_record ("foo-checksum", stored_record));
        GLib.assert_true (stored_record.path == record.path);
        GLib.assert_true (stored_record.remote_permissions == record.remote_permissions);
        GLib.assert_true (stored_record.checksum_header == record.checksum_header);

        // GLib.debug ("OOOOO " + stored_record.modtime.to_time_t () + record.modtime.to_time_t ());

        // Attention: compare time_t types here, as GLib.DateTime seem to maintain
        // milliseconds internally, which disappear in sqlite. Go for full seconds here.
        GLib.assert_true (stored_record.modtime == record.modtime);
        GLib.assert_true (stored_record == record);

        record = new SyncJournalFileRecord ()
        record.path = "foo-nochecksum";
        record.remote_permissions = RemotePermissions.from_database_value ("RW");
        record.modtime = Utility.date_time_to_time_t (GLib.DateTime.current_date_time_utc ());

        GLib.assert_true (this.database.set_file_record (record));

        stored_record = new SyncJournalFileRecord ();
        GLib.assert_true (this.database.get_file_record ("foo-nochecksum", stored_record));
        GLib.assert_true (stored_record == record);
    }

} // class TestFileRecordChecksum

} // namespace Testing
} // namespace Occ
