/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

class FakeGetReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public const FileInfo fileInfo;
    public char payload;
    public int size;
    public bool aborted = false;

    /***********************************************************
    ***********************************************************/
    public FakeGetReply (FileInfo remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.Object parent);

    //  Q_INVOKABLE
    public void respond ();

    /***********************************************************
    ***********************************************************/
    public void on_abort () override;

    /***********************************************************
    ***********************************************************/
    public 
    public int64 readData (char data, int64 maxlen) override;
};