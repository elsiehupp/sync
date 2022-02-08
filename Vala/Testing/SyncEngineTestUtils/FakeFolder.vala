/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

class FakeFolder {
    QTemporaryDir this.tempDir;
    DiskFileModifier this.localModifier;
    // FIXME : Clarify ownership, double delete
    FakeQNAM this.fakeQnam;
    Occ.AccountPointer this.account;
    std.unique_ptr<Occ.SyncJournalDb> this.journalDb;
    std.unique_ptr<Occ.SyncEngine> this.syncEngine;


    /***********************************************************
    ***********************************************************/
    public FakeFolder (FileInfo fileTemplate, Occ.Optional<FileInfo> localFileInfo = {}, string remotePath = {});

    /***********************************************************
    ***********************************************************/
    public void switchToVfs (unowned<Occ.Vfs> vfs);

    /***********************************************************
    ***********************************************************/
    public Occ.AccountPointer account () { return this.account; }
    public Occ.SyncEngine syncEngine () { return this.syncEngine; }
    public Occ.SyncJournalDb syncJournal () { return this.journalDb; }


    /***********************************************************
    ***********************************************************/
    public FileModifier localModifier () { return this.localModifier; }
    public FileInfo remoteModifier () { return this.fakeQnam.currentRemoteState (); }
    public FileInfo currentLocalState ();

    /***********************************************************
    ***********************************************************/
    public FileInfo currentRemoteState () { return this.fakeQnam.currentRemoteState (); }
    public FileInfo uploadState () { return this.fakeQnam.uploadState (); }
    public FileInfo dbState ();

    /***********************************************************
    ***********************************************************/
    public struct ErrorList {
        FakeQNAM this.qnam;
        void append (string path, int error = 500) { this.qnam.errorPaths ().insert (path, error); }
        void clear () { this.qnam.errorPaths ().clear (); }
    }
    public ErrorList serverErrorPaths () { return {this.fakeQnam}; }
    public void setServerOverride (FakeQNAM.Override override) { this.fakeQnam.setOverride (override); }
    public QJsonObject forEachReplyPart (QIODevice outgoingData,
                                 const string contentType,
                                 std.function<QJsonObject (GLib.HashMap<string, GLib.ByteArray>&)> replyFunction) {
        return this.fakeQnam.forEachReplyPart (outgoingData, contentType, replyFunction);
    }


    /***********************************************************
    ***********************************************************/
    public string localPath ();

    /***********************************************************
    ***********************************************************/
    public void scheduleSync ();

    /***********************************************************
    ***********************************************************/
    public void execUntilBeforePropagation ();

    /***********************************************************
    ***********************************************************/
    public void execUntilItemCompleted (string relativePath);

    /***********************************************************
    ***********************************************************/
    public bool execUntilFinished () {
        QSignalSpy spy (this.syncEngine.get (), SIGNAL (on_signal_finished (bool)));
        bool ok = spy.wait (3600000);
        //  Q_ASSERT (ok && "Sync timed out");
        return spy[0][0].toBool ();
    }


    /***********************************************************
    ***********************************************************/
    public bool syncOnce () {
        scheduleSync ();
        return execUntilFinished ();
    }


    /***********************************************************
    ***********************************************************/
    private static void toDisk (QDir dir, FileInfo templateFi);

    /***********************************************************
    ***********************************************************/
    private static void fromDisk (QDir dir, FileInfo templateFi);
};