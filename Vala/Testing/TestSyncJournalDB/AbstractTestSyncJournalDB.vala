/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public abstract class AbstractTestSyncJournalDB : GLib.Object {

    protected SyncJournalDb database;
    protected GLib.TemporaryDir temporary_directory;

    /***********************************************************
    ***********************************************************/
    protected AbstractTestSyncJournalDB () {
        this.database = this.temporary_directory.path + "/sync.db";
        GLib.assert_true (this.temporary_directory.is_valid);
    }


    /***********************************************************
    ***********************************************************/
    ~AbstractTestSyncJournalDB () {
        string file = this.database.database_file_path;
        GLib.File.remove (file);
    }


    protected PinState get_pin_state (string path)  {
        var state = this.database.internal_pin_states.effective_for_path (path);
        if (!state) {
            GLib.assert_fail ("couldn't read pin state", __FILE__, __LINE__);
            return PinState.PinState.INHERITED;
        }
        return state;
    }


    protected PinState get_recursive (string path) {
        var state = this.database.internal_pin_states.effective_for_path_recursive (path);
        if (!state) {
            GLib.assert_fail ("couldn't read pin state", __FILE__, __LINE__);
            return PinState.PinState.INHERITED;
        }
        return state;
    }


    protected PinState get_raw (string path) {
        var state = this.database.internal_pin_states.raw_for_path (path);
        if (!state) {
            GLib.assert_fail ("couldn't read pin state", __FILE__, __LINE__);
            return PinState.PinState.INHERITED;
        }
        return state;
    }


    /***********************************************************
    ***********************************************************/
    protected static int64 drop_msecs (GLib.DateTime time) {
        return Utility.date_time_to_time_t (time);
    }

} // class TestSyncJournalDB

} // namespace Testing
} // namespace Occ
