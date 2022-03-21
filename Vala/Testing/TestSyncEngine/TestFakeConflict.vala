/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestFakeConflict : AbstractTestSyncEngine {

    /***********************************************************
    ***********************************************************/
    private TestFakeConflict () {
        QFETCH (bool, same_mtime);
        QFETCH (string, checksums);
        QFETCH (int, expected_get);

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        int n_get = 0;
        fake_folder.set_server_override (this.override_delegate_fake_conflict);

        // For directly editing the remote checksum
        var remote_info = fake_folder.remote_modifier ();

        // Base mtime with no ms content (filesystem is seconds only)
        var mtime = GLib.DateTime.current_date_time_utc ().add_days (-4);
        mtime.set_msecs_since_epoch (mtime.to_m_secs_since_epoch () / 1000 * 1000);

        fake_folder.local_modifier.set_contents ("A/a1", 'C');
        fake_folder.local_modifier.set_modification_time ("A/a1", mtime);
        fake_folder.remote_modifier ().set_contents ("A/a1", 'C');
        if (!same_mtime)
            mtime = mtime.add_days (1);
        fake_folder.remote_modifier ().set_modification_time ("A/a1", mtime);
        remote_info.find ("A/a1").checksums = checksums;
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (n_get == expected_get);

        // check that mtime in journal and filesystem agree
        string a1path = fake_folder.local_path + "A/a1";
        SyncJournalFileRecord a1record;
        fake_folder.sync_journal ().get_file_record ("A/a1", a1record);
        GLib.assert_true (a1record.modtime == (int64)FileSystem.get_mod_time (a1path));

        // Extra sync reads from database, no difference
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (n_get == expected_get);
    }


    private Soup.Reply override_delegate_fake_conflict (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.GetOperation)
            ++n_get;
        return null;
    }

} // class TestFakeConflict

} // namespace Testing
} // namespace Occ
