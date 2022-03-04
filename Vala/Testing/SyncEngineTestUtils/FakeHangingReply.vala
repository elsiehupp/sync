/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

/***********************************************************
A reply that never responds
***********************************************************/
class FakeHangingReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public FakeHangingReply (QNetworkAccessManager.Operation operation, Soup.Request request, GLib.Object parent);

    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override;

    /***********************************************************
    ***********************************************************/
    public int64 read_data (char *, int64) override {
        return 0;
    }

}
}





FakeHangingReply.FakeHangingReply (QNetworkAccessManager.Operation operation, Soup.Request request, GLib.Object parent)
    : FakeReply (parent) {
    setRequest (request);
    setUrl (request.url ());
    setOperation (operation);
    open (QIODevice.ReadOnly);
}

void FakeHangingReply.on_signal_abort () {
    // Follow more or less the implementation of QNetworkReplyImpl.on_signal_abort
    close ();
    setError (OperationCanceledError, _("Operation canceled"));
    /* emit */ errorOccurred (OperationCanceledError);
    setFinished (true);
    /* emit */ finished ();
}