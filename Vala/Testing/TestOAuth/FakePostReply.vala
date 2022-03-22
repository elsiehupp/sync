/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class FakePostReply : GLib.InputStream {

    /***********************************************************
    ***********************************************************/
    public std.unique_ptr<QIODevice> payload;
    public bool aborted = false;
    public bool redirect_to_policy = false;
    public bool redirect_to_token = false;

    /***********************************************************
    ***********************************************************/
    public FakePostReply (Soup.Operation operation, Soup.Request request,
        std.unique_ptr<QIODevice> payload_, GLib.Object parent) {
        base (parent);
        payload = std.move (payload_);
        set_request (request);
        set_url (request.url);
        set_operation (operation);
        open (QIODevice.ReadOnly);
        payload.open (QIODevice.ReadOnly);
        QMetaObject.invoke_method (this, "respond", Qt.QueuedConnection);
    }

    public virtual void respond () {
        if (aborted) {
            set_error (OperationCanceledError, "Operation Canceled");
            /* emit */ signal_meta_data_changed ();
            /* emit */ signal_finished ();
            return;
        } else if (redirect_to_policy) {
            set_header (Soup.Request.LocationHeader, "/my.policy");
            set_attribute (Soup.Request.RedirectionTargetAttribute, "/my.policy");
            set_attribute (Soup.Request.HttpStatusCodeAttribute, 302); // 302 might or might not lose POST data in rfc
            set_header (Soup.Request.ContentLengthHeader, 0);
            /* emit */ signal_meta_data_changed ();
            /* emit */ signal_finished ();
            return;
        } else if (redirect_to_token) {
            // Redirect to self
            GLib.Variant destination = GLib.Variant (s_oauth_test_server.to_string () + "/index.php/apps/oauth2/api/v1/token");
            set_header (Soup.Request.LocationHeader, destination);
            set_attribute (Soup.Request.RedirectionTargetAttribute, destination);
            set_attribute (Soup.Request.HttpStatusCodeAttribute, 307); // 307 explicitly in rfc says to not lose POST data
            set_header (Soup.Request.ContentLengthHeader, 0);
            /* emit */ signal_meta_data_changed ();
            /* emit */ signal_finished ();
            return;
        }
        set_header (Soup.Request.ContentLengthHeader, payload.size ());
        set_attribute (Soup.Request.HttpStatusCodeAttribute, 200);
        /* emit */ signal_meta_data_changed ();
        if (bytes_available ())
            /* emit */ signal_ready_read ();
        /* emit */ signal_finished ();
    }


    /***********************************************************
    ***********************************************************/
    public override void on_signal_abort () {
        aborted = true;
    }


    /***********************************************************
    ***********************************************************/
    public override int64 bytes_available () {
        if (aborted) {
            return 0;
        }
        return payload.bytes_available ();
    }

    public override int64 read_data (char *data, int64 maxlen) {
        return payload.read (data, maxlen);
    }

} // class FakePostReply
} // namespace Testing
} // namespace Occ
