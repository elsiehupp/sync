/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestDownloadInfo : AbstractTestSyncJournalDB {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestDownloadInfo () {
    //      Common.SyncJournalDb.DownloadInfo record = this.database.get_download_info ("nonexistant");
    //      GLib.assert_true (!record.valid);

    //      record.error_count = 5;
    //      record.etag = "ABCDEF";
    //      record.valid = true;
    //      record.temporaryfile = "/temporary/foo";
    //      this.database.set_download_info ("foo", record);

    //      Common.SyncJournalDb.DownloadInfo stored_record = this.database.get_download_info ("foo");
    //      GLib.assert_true (stored_record == record);

    //      this.database.set_download_info ("foo", Common.SyncJournalDb.DownloadInfo ());
    //      Common.SyncJournalDb.DownloadInfo wiped_record = this.database.get_download_info ("foo");
    //      GLib.assert_true (!wiped_record.valid);
    //  }

} // class TestDownloadInfo

} // namespace Testing
} // namespace Occ
