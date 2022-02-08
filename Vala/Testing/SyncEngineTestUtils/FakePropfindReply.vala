/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

class FakePropfindReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray payload;

    /***********************************************************
    ***********************************************************/
    public FakePropfindReply (FileInfo remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.Object parent);

    public void respond ();

    public void respond404 ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override { }


    /***********************************************************
    ***********************************************************/
    public int64 bytesAvailable () override;
    public int64 readData (char data, int64 maxlen) override;
};