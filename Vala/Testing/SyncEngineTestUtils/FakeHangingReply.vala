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
    public FakeHangingReply (Soup.Operation operation, Soup.Request request, GLib.Object parent);

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





FakeHangingReply.FakeHangingReply (Soup.Operation operation, Soup.Request request, GLib.Object parent)
    : FakeReply (parent) {
    set_request (request);
    set_url (request.url ());
    set_operation (operation);
    open (QIODevice.ReadOnly);
}

void FakeHangingReply.on_signal_abort () {
    // Follow more or less the implementation of QNetworkReplyImpl.on_signal_abort
    close ();
    set_error (OperationCanceledError, _("Operation canceled"));
    /* emit */ errorOccurred (OperationCanceledError);
    setFinished (true);
    /* emit */ signal_finished ();
}