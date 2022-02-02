/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

class FakePayloadReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public FakePayloadReply (QNetworkAccessManager.Operation op, QNetworkRequest request,

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public st GLib.ByteArra

    /***********************************************************
    ***********************************************************/
    public void respond ();

    public void on_abort () override {}
    public int64 readData (char buf, int64 max) override;
    public int64 bytesAvailable () override;
    public GLib.ByteArray this.body;

    /***********************************************************
    ***********************************************************/
    public static const int defaultDelay = 10;
};