/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

struct ItemCompletedSpy : QSignalSpy {
    ItemCompletedSpy (FakeFolder folder)
        : QSignalSpy (&folder.syncEngine (), &Occ.SyncEngine.itemCompleted) {}

    Occ.SyncFileItemPtr findItem (string path);

    Occ.SyncFileItemPtr findItemWithExpectedRank (string path, int rank);
}
