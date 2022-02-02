
class FakeErrorReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public FakeErrorReply (QNetworkAccessManager.Operation op, QNetworkRequest request,
        GLib.Object parent, int httpErrorCode, GLib.ByteArray body = GLib.ByteArray ());

    //  Q_INVOKABLE
    public virtual void respond ();

    // make public to give tests easy interface
    using Soup.Reply.setError;
    using Soup.Reply.setAttribute;


    /***********************************************************
    ***********************************************************/
    public void on_slot_set_finished ();

    /***********************************************************
    ***********************************************************/
    public 
    public void on_abort () override { }
    public int64 readData (char buf, int64 max) override;
    public int64 bytesAvailable () override;

    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray this.body;
};