using Soup;

namespace Occ {
namespace LibSync {

/***********************************************************
@class HttpLogger

@author Hannah von Reth <hannah.vonreth@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class HttpLogger : GLib.Object {

    const int64 PEEK_SIZE = 1024 * 1024;

    const string X_REQUEST_ID = "X-Request-ID";

    public static void log_request (GLib.InputStream reply, Soup.Session.Operation operation, GLib.OutputStream device) {
        var request = reply.request ();
        if (!lc_network_http ().is_info_enabled ()) {
            return;
        }
        var keys = request.raw_header_list ();
        GLib.List<GLib.InputStream.RawHeaderPair> header;
        header.reserve (keys.size ());
        foreach (var key in keys) {
            header += q_make_pair (key, request.raw_header (key));
        }
        log_http (request_verb (operation, request),
            request.url.to_string (),
            request.raw_header (X_REQUEST_ID ()),
            request.header (Soup.Request.ContentTypeHeader).to_string (),
            header,
            device);

        GLib.Object.connect (
            reply,
            GLib.InputStream.signal_finished,
            reply,
            () => {
            log_http (request_verb (*reply),
                reply.url.to_string (),
                reply.request ().raw_header (X_REQUEST_ID ()),
                reply.header (Soup.Request.ContentTypeHeader).to_string (),
                reply.raw_header_pairs (),
                reply);
        });
    }


    /***********************************************************
    Helper to construct the HTTP verb used in the request
    ***********************************************************/
    public static string request_verb (Soup.Session.Operation operation, Soup.Request request) {
        switch (operation) {
        case Soup.Session.HeadOperation:
            return "HEAD";
        case Soup.Session.GetOperation:
            return "GET";
        case Soup.Session.PutOperation:
            return "PUT";
        case Soup.Session.PostOperation:
            return "POST";
        case Soup.Session.DeleteOperation:
            return "DELETE";
        case Soup.Session.CustomOperation:
            return request.attribute (Soup.Request.CustomVerbAttribute).to_byte_array ();
        case Soup.Session.UnknownOperation:
            break;
        }
        Q_UNREACHABLE ();
    }


    public static bool is_text_body (string s) {
        const GLib.Regex regular_expression = new GLib.Regex ("^ (text/.*| (application/ (xml|json|x-www-form-urlencoded) (;|$)))");
        return regular_expression.match (s).has_match ();
    }


    public static void log_http (string verb, string url, string identifier, string content_type, GLib.List<GLib.InputStream.RawHeaderPair> header, GLib.OutputStream device) {
        var reply = (GLib.InputStream) device;
        var content_length = device.size ();
        string message;
        GLib.OutputStream stream = new GLib.OutputStream (&message);
        stream += identifier + ": ";
        if (reply == null) {
            stream += "Request: ";
        } else {
            stream += "Response: ";
        }
        stream += verb;
        if (reply != null) {
            stream += " " + reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        }
        stream += " " + url + " Header: { ";
        foreach (var item in header) {
            stream += item.first + ": ";
            if (item.first == "Authorization") {
                stream += (item.second.has_prefix ("Bearer ") ? "Bearer": "Basic");
                stream += " [redacted]";
            } else {
                stream += item.second;
            }
            stream += ", ";
        }
        stream += "} Data : [";
        if (content_length > 0) {
            if (is_text_body (content_type)) {
                if (!device.is_open) {
                    GLib.assert (dynamic_cast<Soup.Buffer> (device));
                    // should we close item again?
                    device.open (GLib.IODevice.ReadOnly);
                }
                GLib.assert (device.position () == 0);
                stream += device.peek (PEEK_SIZE);
                if (PEEK_SIZE < content_length) {
                    stream += "... (" + (content_length - PEEK_SIZE) + "bytes elided)";
                }
            } else {
                stream += content_length + " bytes of " + content_type + " data";
            }
        }
        stream += "]";
        GLib.info (message);
    }

} // class HttpLogger

} // namespace LibSync
} // namespace Occ
