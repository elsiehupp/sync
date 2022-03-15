/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

public class ItemCompletedSpy : QSignalSpy {

    ItemCompletedSpy (FakeFolder folder) {
        base (&folder.sync_engine (), &Occ.SyncEngine.item_completed);
    }


    Occ.SyncFileItemPtr find_item (string path) {
        foreach (GLib.List<GLib.Variant> args in *this) {
            var item = args[0].value<Occ.SyncFileItemPtr> ();
            if (item.destination () == path)
                return item;
        }
        return Occ.SyncFileItemPtr.create ();
    }


    Occ.SyncFileItemPtr find_item_with_expected_rank (string path, int rank) {
        GLib.assert_true (size () > rank);
        GLib.assert_true (! (*this)[rank] == "");

        var item = (*this)[rank][0].value<Occ.SyncFileItemPtr> ();
        if (item.destination () == path) {
            return item;
        } else {
            return Occ.SyncFileItemPtr.create ();
        }
    }

}
}
