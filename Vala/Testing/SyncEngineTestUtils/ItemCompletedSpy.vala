/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

struct ItemCompletedSpy : QSignalSpy {
    ItemCompletedSpy (FakeFolder folder)
        : QSignalSpy (&folder.sync_engine (), &Occ.SyncEngine.itemCompleted) {}

    Occ.SyncFileItemPtr findItem (string path);

    Occ.SyncFileItemPtr findItemWithExpectedRank (string path, int rank);
}







Occ.SyncFileItemPtr ItemCompletedSpy.findItem (string path) {
    for (GLib.List<GLib.Variant> args : *this) {
        var item = args[0].value<Occ.SyncFileItemPtr> ();
        if (item.destination () == path)
            return item;
    }
    return Occ.SyncFileItemPtr.create ();
}

Occ.SyncFileItemPtr ItemCompletedSpy.findItemWithExpectedRank (string path, int rank) {
    //  Q_ASSERT (size () > rank);
    //  Q_ASSERT (! (*this)[rank].isEmpty ());

    var item = (*this)[rank][0].value<Occ.SyncFileItemPtr> ();
    if (item.destination () == path) {
        return item;
    } else {
        return Occ.SyncFileItemPtr.create ();
    }
}