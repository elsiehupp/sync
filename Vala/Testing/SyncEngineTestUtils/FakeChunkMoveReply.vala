
class FakeChunkMoveReply : FakeReply {
    FileInfo fileInfo;

    /***********************************************************
    ***********************************************************/
    public FakeChunkMoveReply (FileInfo uploadsFileInfo, FileInfo remoteRootFileInfo,
        QNetworkAccessManager.Operation op, QNetworkRequest request,
        GLib.Object parent);

    /***********************************************************
    ***********************************************************/
    public static FileInfo perform (FileInfo uploadsFileInfo, FileInfo remoteRootFileInfo, QNetworkRequest request);

    public virtual void respond ();

    public void respondPreconditionFailed ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override;

    /***********************************************************
    ***********************************************************/
    public int64 readData (char *, int64) override { return 0; }
};