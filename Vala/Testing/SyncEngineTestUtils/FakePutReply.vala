/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

class FakePutReply : FakeReply {
    FileInfo fileInfo;

    /***********************************************************
    ***********************************************************/
    public FakePutReply (FileInfo remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.ByteArray putPayload, GLib.Object parent);

    /***********************************************************
    ***********************************************************/
    public static FileInfo perform (FileInfo remoteRootFileInfo, QNetworkRequest request, GLib.ByteArray putPayload);

    //  Q_INVOKABLE
    public virtual void respond ();

    /***********************************************************
    ***********************************************************/
    public void on_abort () override;
    public int64 readData (char *, int64) override { return 0; }
};