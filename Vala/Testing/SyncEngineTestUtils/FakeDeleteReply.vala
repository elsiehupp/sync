
class FakeDeleteReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public FakeDeleteReply (FileInfo remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.Object parent);

    //  Q_INVOKABLE
    public void respond ();

    /***********************************************************
    ***********************************************************/
    public void on_abort () override { }
    public int64 readData (char *, int64) override { return 0; }
};