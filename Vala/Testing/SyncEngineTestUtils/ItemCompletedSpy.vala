/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class ItemCompletedSpy : QSignalSpy {

    ItemCompletedSpy (FakeFolder folder) {
        base (&folder.sync_engine (), &Occ.SyncEngine.itemCompleted);
    }



    Occ.SyncFileItemPtr findItem (string path) {
        foreach (GLib.List<GLib.Variant> args in *this) {
            var item = args[0].value<Occ.SyncFileItemPtr> ();
            if (item.destination () == path)
                return item;
        }
        return Occ.SyncFileItemPtr.create ();
    }

    Occ.SyncFileItemPtr findItemWithExpectedRank (string path, int rank) {
        //  Q_ASSERT (size () > rank);
        //  Q_ASSERT (! (*this)[rank].isEmpty ());

        var item = (*this)[rank][0].value<Occ.SyncFileItemPtr> ();
        if (item.destination () == path) {
            return item;
        } else {
            return Occ.SyncFileItemPtr.create ();
        }
    }

}
}
