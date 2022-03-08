/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

using Occ;

namespace Testing {

class FakePostReply : Soup.Reply {

    /***********************************************************
    ***********************************************************/
    public std.unique_ptr<QIODevice> payload;
    public bool aborted = false;
    public bool redirectToPolicy = false;
    public bool redirectToToken = false;

    /***********************************************************
    ***********************************************************/
    public FakePostReply (Soup.Operation operation, Soup.Request request,
        std.unique_ptr<QIODevice> payload_, GLib.Object parent) {
        base (parent);
        payload = std.move (payload_);
        set_request (request);
        set_url (request.url ());
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
        } else if (redirectToPolicy) {
            setHeader (Soup.Request.LocationHeader, "/my.policy");
            set_attribute (Soup.Request.RedirectionTargetAttribute, "/my.policy");
            set_attribute (Soup.Request.HttpStatusCodeAttribute, 302); // 302 might or might not lose POST data in rfc
            setHeader (Soup.Request.ContentLengthHeader, 0);
            /* emit */ signal_meta_data_changed ();
            /* emit */ signal_finished ();
            return;
        } else if (redirectToToken) {
            // Redirect to self
            GLib.Variant destination = GLib.Variant (sOAuthTestServer.to_string ()+QLatin1String ("/index.php/apps/oauth2/api/v1/token"));
            setHeader (Soup.Request.LocationHeader, destination);
            set_attribute (Soup.Request.RedirectionTargetAttribute, destination);
            set_attribute (Soup.Request.HttpStatusCodeAttribute, 307); // 307 explicitly in rfc says to not lose POST data
            setHeader (Soup.Request.ContentLengthHeader, 0);
            /* emit */ signal_meta_data_changed ();
            /* emit */ signal_finished ();
            return;
        }
        setHeader (Soup.Request.ContentLengthHeader, payload.size ());
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
