
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

    //  Q_INVOKABLE
    public virtual void respond ();

    //  Q_INVOKABLE
    public void respondPreconditionFailed ();

    /***********************************************************
    ***********************************************************/
    public void on_abort () override;

    /***********************************************************
    ***********************************************************/
    public int64 readData (char *, int64) override { return 0; }
};