/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

class FakeMoveReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public FakeMoveReply (FileInfo remoteRootFileInfo, QNetworkAccessManager.Operation op, QNetworkRequest request, GLib.Object parent);

    public void respond ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override { }
    public int64 readData (char *, int64) override { return 0; }
};