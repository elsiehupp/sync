/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

class FakePutMultiFileReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public FakePutMultiFileReply (FileInfo remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest request, string contentType, GLib.ByteArray putPayload, GLib.Object parent);

    /***********************************************************
    ***********************************************************/
    public static GLib.Vector<FileInfo> performMultiPart (FileInfo remoteRootFileInfo, QNetworkRequest request, GLib.ByteArray putPayload, string contentType);

    //  Q_INVOKABLE
    public virtual void respond ();

    /***********************************************************
    ***********************************************************/
    public void on_abort () override;

    /***********************************************************
    ***********************************************************/
    public int64 bytesAvailable () override;
    public int64 readData (char data, int64 maxlen) override;


    /***********************************************************
    ***********************************************************/
    private GLib.Vector<FileInfo> this.allFileInfo;

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray this.payload;
};