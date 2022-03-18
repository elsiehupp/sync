/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.
***********************************************************/


namespace Occ {
namespace Testing {

public class TestUpdater : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void on_signal_test_version_to_int () {
        int64 low_version = Updater.Helper.version_to_int (1,2,80,3000);
        GLib.assert_true (Updater.Helper.string_version_to_int ("1.2.80.3000") == low_version);

        int64 high_version = Updater.Helper.version_to_int (99,2,80,3000);
        int64 current_version = Updater.Helper.current_version_to_int ();
        GLib.assert_true (current_version > 0);
        GLib.assert_true (current_version > low_version);
        GLib.assert_true (current_version < high_version);
    }

}

} // namespace Testing
} // namespace Occ
