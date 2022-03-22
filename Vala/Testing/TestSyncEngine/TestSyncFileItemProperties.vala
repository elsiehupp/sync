/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestSyncFileItemProperties : AbstractTestSyncEngine {

    /***********************************************************
    Checks whether SyncFileItem instances have the expected
    properties before start of propagation.
    ***********************************************************/
    private TestSyncFileItemProperties () {
        var initial_mtime = GLib.DateTime.current_date_time_utc ().add_days (-7);
        var changed_mtime = GLib.DateTime.current_date_time_utc ().add_days (-4);
        var changed_mtime2 = GLib.DateTime.current_date_time_utc ().add_days (-3);

        // Base mtime with no ms content (filesystem is seconds only)
        initial_mtime.set_msecs_since_epoch (initial_mtime.to_m_secs_since_epoch () / 1000 * 1000);
        changed_mtime.set_msecs_since_epoch (changed_mtime.to_m_secs_since_epoch () / 1000 * 1000);
        changed_mtime2.set_msecs_since_epoch (changed_mtime2.to_m_secs_since_epoch () / 1000 * 1000);

        // Ensure the initial mtimes are as expected
        var initial_file_info = FileInfo.A12_B12_C12_S12 ();
        initial_file_info.set_modification_time ("A/a1", initial_mtime);
        initial_file_info.set_modification_time ("B/b1", initial_mtime);
        initial_file_info.set_modification_time ("C/c1", initial_mtime);

        FakeFolder fake_folder = new FakeFolder (initial_file_info);

        // upload a
        fake_folder.local_modifier.append_byte ("A/a1");
        fake_folder.local_modifier.set_modification_time ("A/a1", changed_mtime);
        // download b
        fake_folder.remote_modifier ().append_byte ("B/b1");
        fake_folder.remote_modifier ().set_modification_time ("B/b1", changed_mtime);
        // conflict c
        fake_folder.local_modifier.append_byte ("C/c1");
        fake_folder.local_modifier.append_byte ("C/c1");
        fake_folder.local_modifier.set_modification_time ("C/c1", changed_mtime);
        fake_folder.remote_modifier ().append_byte ("C/c1");
        fake_folder.remote_modifier ().set_modification_time ("C/c1", changed_mtime2);

        fake_folder.sync_engine.signal_about_to_propagate.connect (
            this.on_signal_sync_engine_about_to_propagate
        );

        GLib.assert_true (fake_folder.sync_once ());
    }


    private void on_signal_sync_engine_about_to_propagate (SyncFileItemVector items) {
        SyncFileItem a1, b1, c1;
        foreach (var item in items) {
            if (item.file == "A/a1") {
                a1 = item;
            }
            if (item.file == "B/b1") {
                b1 = item;
            }
            if (item.file == "C/c1") {
                c1 = item;
            }
        }

        // a1 : should have local size and modtime
        GLib.assert_true (a1);
        GLib.assert_true (a1.instruction == CSync.SyncInstructions.SYNC);
        GLib.assert_true (a1.direction == SyncFileItem.Direction.UP);
        GLib.assert_true (a1.size == (int64) 5);

        GLib.assert_true (Utility.date_time_from_time_t (a1.modtime) == changed_mtime);
        GLib.assert_true (a1.previous_size == (int64) 4);
        GLib.assert_true (Utility.date_time_from_time_t (a1.previous_modtime) == initial_mtime);

        // b2 : should have remote size and modtime
        GLib.assert_true (b1);
        GLib.assert_true (b1.instruction == CSync.SyncInstructions.SYNC);
        GLib.assert_true (b1.direction == SyncFileItem.Direction.DOWN);
        GLib.assert_true (b1.size == (int64) 17);
        GLib.assert_true (Utility.date_time_from_time_t (b1.modtime) == changed_mtime);
        GLib.assert_true (b1.previous_size == (int64) 16);
        GLib.assert_true (Utility.date_time_from_time_t (b1.previous_modtime) == initial_mtime);

        // c1 : conflicts are downloads, so remote size and modtime
        GLib.assert_true (c1);
        GLib.assert_true (c1.instruction == CSync.SyncInstructions.CONFLICT);
        GLib.assert_true (c1.direction == SyncFileItem.Direction.NONE);
        GLib.assert_true (c1.size == (int64) 25);
        GLib.assert_true (Utility.date_time_from_time_t (c1.modtime) == changed_mtime2);
        GLib.assert_true (c1.previous_size == (int64) 26);
        GLib.assert_true (Utility.date_time_from_time_t (c1.previous_modtime) == changed_mtime);
    }

} // class TestSyncFileItemProperties

} // namespace Testing
} // namespace Occ
