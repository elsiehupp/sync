/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

/***********************************************************
A reply that never responds
***********************************************************/
public class FakeHangingReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public FakeHangingReply (Soup.Operation operation, Soup.Request request, GLib.Object parent) {
        base (parent);
        set_request (request);
        set_url (request.url);
        set_operation (operation);
        open (QIODevice.ReadOnly);
    }


    /***********************************************************
    ***********************************************************/
    public override void on_signal_abort () {
        // Follow more or less the implementation of QNetworkReplyImpl.on_signal_abort
        close ();
        set_error (OperationCanceledError, _("Operation canceled"));
        /* emit */ error_occurred (OperationCanceledError);
        set_finished (true);
        /* emit */ signal_finished ();
    }


    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char * data, int64 value) {
        return 0;
    }

} // class FakeHangingReply
} // namespace Testing
} // namespace Occ
