/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class ItemCompletedSpy : GLib.SignalSpy {

    ItemCompletedSpy (FakeFolder folder) {
        base (folder.sync_engine, LibSync.SyncEngine.signal_item_completed);
    }


    public LibSync.SyncFileItem find_item (string path) {
        foreach (GLib.List<GLib.Variant> args in *this) {
            var item = args[0].value<LibSync.SyncFileItem> ();
            if (item.destination () == path)
                return item;
        }
        return LibSync.SyncFileItem.create ();
    }


    public LibSync.SyncFileItem find_item_with_expected_rank (string path, int rank) {
        GLib.assert_true (size () > rank);
        GLib.assert_true (! (this)[rank] == "");

        var item = (this)[rank][0].value<LibSync.SyncFileItem> ();
        if (item.destination () == path) {
            return item;
        } else {
            return LibSync.SyncFileItem.create ();
        }
    }

}

} // namespace Testing
} // namespace Occ
