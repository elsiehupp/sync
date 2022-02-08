/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

class FakeGetWithDataReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public const FileInfo fileInfo;
    public GLib.ByteArray payload;
    public uint64 offset = 0;
    public bool aborted = false;

    /***********************************************************
    ***********************************************************/
    public FakeGetWithDataReply (FileInfo remoteRootFileInfo, GLib.ByteArray data, QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.Object parent);

    public void respond ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override;

    /***********************************************************
    ***********************************************************/
    public int64 readData (char data, int64 maxlen) override;
};