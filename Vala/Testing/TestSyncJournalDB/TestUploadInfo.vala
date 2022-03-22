/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestUploadInfo : AbstractTestSyncJournalDB {

    /***********************************************************
    ***********************************************************/
    private TestUploadInfo () {
        Common.SyncJournalDb.UploadInfo record = this.database.get_upload_info ("nonexistant");
        GLib.assert_true (!record.valid);

        record.error_count = 5;
        record.chunk = 12;
        record.transferid = 812974891;
        record.size = 12894789147;
        record.modtime = drop_msecs (GLib.DateTime.current_date_time ());
        record.valid = true;
        this.database.set_upload_info ("foo", record);

        Common.SyncJournalDb.UploadInfo stored_record = this.database.get_upload_info ("foo");
        GLib.assert_true (stored_record == record);

        this.database.set_upload_info ("foo", Common.SyncJournalDb.UploadInfo ());
        Common.SyncJournalDb.UploadInfo wiped_record = this.database.get_upload_info ("foo");
        GLib.assert_true (!wiped_record.valid);
    }

} // class TestUploadInfo

} // namespace Testing
} // namespace Occ
