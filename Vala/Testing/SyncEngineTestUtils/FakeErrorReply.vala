

// make public to give tests easy interface
using Soup.Reply.set_error;
using Soup.Reply.set_attribute;

namespace Testing {

public class FakeErrorReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public string body;

    /***********************************************************
    ***********************************************************/
    public FakeErrorReply (Soup.Operation operation, Soup.Request request,
        GLib.Object parent, int http_error_code, string body = "") {
            base (parent);
            this.body = body;
            set_request (request);
            set_url (request.url);
            set_operation (operation);
            open (QIODevice.ReadOnly);
            set_attribute (Soup.Request.HttpStatusCodeAttribute, http_error_code);
            set_error (InternalServerError, "Internal Server Fake Error");
            QMetaObject.invoke_method (this, &FakeErrorReply.respond, Qt.QueuedConnection);
        }

    /***********************************************************
    ***********************************************************/
    public virtual void respond ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_finished ();

    /***********************************************************
    ***********************************************************/
    public override void on_signal_abort () { }

    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char buf, int64 max);

    /***********************************************************
    ***********************************************************/
    public override int64 bytes_available ();

}







void FakeErrorReply.respond () {
    /* emit */ signal_meta_data_changed ();
    /* emit */ signal_ready_read ();
    // finishing can come strictly after signal_ready_read was called
    QTimer.single_shot (5, this, &FakeErrorReply.on_signal_finished);
}

void FakeErrorReply.on_signal_finished () {
    set_finished (true);
    /* emit */ signal_finished ();
}

int64 FakeErrorReply.read_data (char buf, int64 max) {
    max = q_min<int64> (max, this.body.size ());
    memcpy (buf, this.body.const_data (), max);
    this.body = this.body.mid (max);
    return max;
}

int64 FakeErrorReply.bytes_available () {
    return this.body.size ();
}