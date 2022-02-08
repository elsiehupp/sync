
class FakeErrorReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public FakeErrorReply (QNetworkAccessManager.Operation op, QNetworkRequest request,
        GLib.Object parent, int httpErrorCode, GLib.ByteArray body = GLib.ByteArray ());

    public virtual void respond ();

    // make public to give tests easy interface
    using Soup.Reply.setError;
    using Soup.Reply.setAttribute;


    /***********************************************************
    ***********************************************************/
    public void on_signal_slot_finished ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override { }
    public int64 readData (char buf, int64 max) override;
    public int64 bytesAvailable () override;

    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray this.body;
};