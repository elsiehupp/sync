/***********************************************************
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QRegularExpression>
//  #include <QLoggingCategory>
//  #include <Soup.Buffer>

using Soup;

namespace Occ {
namespace LibSync {

public class HttpLogger {

    const int64 PEEK_SIZE = 1024 * 1024;

    const string X_REQUEST_ID = "X-Request-ID";

    public static void log_request (Soup.Reply reply, QNetworkAccessManager.Operation operation, QIODevice device) {
        var request = reply.request ();
        if (!lc_network_http ().is_info_enabled ()) {
            return;
        }
        var keys = request.raw_header_list ();
        GLib.List<Soup.Reply.RawHeaderPair> header;
        header.reserve (keys.size ());
        foreach (var key in keys) {
            header += q_make_pair (key, request.raw_header (key));
        }
        log_http (request_verb (operation, request),
            request.url ().to_string (),
            request.raw_header (X_REQUEST_ID ()),
            request.header (Soup.Request.ContentTypeHeader).to_string (),
            header,
            device);

        GLib.Object.connect (
            reply,
            Soup.Reply.on_signal_finished,
            reply,
            () => {
            log_http (request_verb (*reply),
                reply.url ().to_string (),
                reply.request ().raw_header (X_REQUEST_ID ()),
                reply.header (Soup.Request.ContentTypeHeader).to_string (),
                reply.raw_header_pairs (),
                reply);
        });
    }


    /***********************************************************
    Helper to construct the HTTP verb used in the request
    ***********************************************************/
    public static GLib.ByteArray request_verb (QNetworkAccessManager.Operation operation, Soup.Request request) {
        switch (operation) {
        case QNetworkAccessManager.HeadOperation:
            return GLib.ByteArray ("HEAD");
        case QNetworkAccessManager.GetOperation:
            return GLib.ByteArray ("GET");
        case QNetworkAccessManager.PutOperation:
            return GLib.ByteArray ("PUT");
        case QNetworkAccessManager.PostOperation:
            return GLib.ByteArray ("POST");
        case QNetworkAccessManager.DeleteOperation:
            return GLib.ByteArray ("DELETE");
        case QNetworkAccessManager.CustomOperation:
            return request.attribute (Soup.Request.CustomVerbAttribute).to_byte_array ();
        case QNetworkAccessManager.UnknownOperation:
            break;
        }
        Q_UNREACHABLE ();
    }


    public static bool is_text_body (string s) {
        const QRegularExpression regex = new QRegularExpression ("^ (text/.*| (application/ (xml|json|x-www-form-urlencoded) (;|$)))");
        return regex.match (s).has_match ();
    }


    public static void log_http (GLib.ByteArray verb, string url, GLib.ByteArray identifier, string content_type, GLib.List<Soup.Reply.RawHeaderPair> header, QIODevice device) {
        var reply = (Soup.Reply) device;
        var content_length = device ? device.size () : 0;
        string message;
        QTextStream stream = new QTextStream (&message);
        stream += identifier + ": ";
        if (!reply) {
            stream += "Request: ";
        } else {
            stream += "Response: ";
        }
        stream += verb;
        if (reply) {
            stream += " " + reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        }
        stream += " " + url + " Header: { ";
        foreach (var item in header) {
            stream += item.first + ": ";
            if (item.first == "Authorization") {
                stream += (item.second.starts_with ("Bearer ") ? "Bearer": "Basic");
                stream += " [redacted]";
            } else {
                stream += item.second;
            }
            stream += ", ";
        }
        stream += "} Data : [";
        if (content_length > 0) {
            if (is_text_body (content_type)) {
                if (!device.is_open ()) {
                    GLib.assert (dynamic_cast<Soup.Buffer> (device));
                    // should we close item again?
                    device.open (QIODevice.ReadOnly);
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
