

/***********************************************************
***********************************************************/
// make public to give tests easy interface
    //  using GLib.InputStream.set_error;
    //  using GLib.InputStream.set_attribute;

namespace Occ {
namespace Testing {

public class FakeErrorReply : FakeReply {

    //  /***********************************************************
    //  ***********************************************************/
    //  public string body;

    //  /***********************************************************
    //  ***********************************************************/
    //  public FakeErrorReply (Soup.Operation operation, Soup.Request request,
    //      GLib.Object parent, int http_error_code, string body = ""
    //  ) {
    //      base (parent);
    //      this.body = body;
    //      set_request (request);
    //      set_url (request.url);
    //      set_operation (operation);
    //      open (GLib.IODevice.ReadOnly);
    //      set_attribute (Soup.Request.HttpStatusCodeAttribute, http_error_code);
    //      set_error (InternalServerError, "Internal Server Fake Error");
    //      GLib.Object.invoke_method (this, FakeErrorReply.respond, GLib.QueuedConnection);
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  public virtual void respond () {
    //      signal_meta_data_changed ();
    //      signal_ready_read ();
    //      // finishing can come strictly after signal_ready_read was called
    //      GLib.Timeout.add (5, this.on_signal_finished);
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  public bool on_signal_finished () {
    //      set_finished (true);
    //      signal_finished ();
    //      return false; // only run once
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  public override bool on_signal_abort () {
    //      return false; // only run once
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  public override int64 read_data (char *buf, int64 *max) {
    //      max = int64.min (max, this.body.size ());
    //      memcpy (buf, this.body.const_data (), max);
    //      this.body = this.body.mid (max);
    //      return max;
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  public override int64 bytes_available () {
    //      return this.body.size ();
    //  }

}

} // namespace Testing
} // namespace Occ
