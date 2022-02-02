/***********************************************************
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QRegularExpression>
// #include <QLoggingCategory>
// #include <Soup.Buffer>
// #pragma once

using Soup;

namespace Occ {
namespace HttpLogger {
    void log_request (Soup.Reply reply, QNetworkAccessManager.Operation operation, QIODevice device);


    /***********************************************************
    Helper to construct the HTTP verb used in the request
    ***********************************************************/
    GLib.ByteArray request_verb (QNetworkAccessManager.Operation operation, Soup.Request request);
    inline GLib.ByteArray request_verb (Soup.Reply reply) {
        return request_verb (reply.operation (), reply.request ());
    }
}

    const int64 PeekSize = 1024 * 1024;

    const GLib.ByteArray XRequestId (){
        return QByteArrayLiteral ("X-Request-ID");
    }

    bool is_text_body (string s) {
        static const QRegularExpression regexp (QStringLiteral ("^ (text/.*| (application/ (xml|json|x-www-form-urlencoded) (;|$)))"));
        return regexp.match (s).has_match ();
    }

    void log_http (GLib.ByteArray verb, string url, GLib.ByteArray id, string content_type, GLib.List<Soup.Reply.RawHeaderPair> header, QIODevice device) {
        const var reply = qobject_cast<Soup.Reply> (device);
        const var content_length = device ? device.size () : 0;
        string msg;
        QTextStream stream (&msg);
        stream << id << " : ";
        if (!reply) {
            stream << "Request : ";
        } else {
            stream << "Response : ";
        }
        stream << verb;
        if (reply) {
            stream << " " << reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        }
        stream << " " << url << " Header: { ";
        for (var it : header) {
            stream << it.first << " : ";
            if (it.first == "Authorization") {
                stream << (it.second.starts_with ("Bearer ") ? "Bearer" : "Basic");
                stream << " [redacted]";
            } else {
                stream << it.second;
            }
            stream << ", ";
        }
        stream << "} Data : [";
        if (content_length > 0) {
            if (is_text_body (content_type)) {
                if (!device.is_open ()) {
                    Q_ASSERT (dynamic_cast<Soup.Buffer> (device));
                    // should we close it again?
                    device.open (QIODevice.ReadOnly);
                }
                Q_ASSERT (device.pos () == 0);
                stream << device.peek (PeekSize);
                if (PeekSize < content_length) {
                    stream << "... (" << (content_length - PeekSize) << "bytes elided)";
                }
            } else {
                stream << content_length << " bytes of " << content_type << " data";
            }
        }
        stream << "]";
        q_c_info (lc_network_http) << msg;
    }


    void HttpLogger.log_request (Soup.Reply reply, QNetworkAccessManager.Operation operation, QIODevice device) {
        const var request = reply.request ();
        if (!lc_network_http ().is_info_enabled ()) {
            return;
        }
        const var keys = request.raw_header_list ();
        GLib.List<Soup.Reply.RawHeaderPair> header;
        header.reserve (keys.size ());
        for (var key : keys) {
            header << q_make_pair (key, request.raw_header (key));
        }
        log_http (request_verb (operation, request),
            request.url ().to_string (),
            request.raw_header (XRequestId ()),
            request.header (Soup.Request.ContentTypeHeader).to_string (),
            header,
            device);

        GLib.Object.connect (reply, &Soup.Reply.on_finished, reply, [reply] {
            log_http (request_verb (*reply),
                reply.url ().to_string (),
                reply.request ().raw_header (XRequestId ()),
                reply.header (Soup.Request.ContentTypeHeader).to_string (),
                reply.raw_header_pairs (),
                reply);
        });
    }

    GLib.ByteArray HttpLogger.request_verb (QNetworkAccessManager.Operation operation, Soup.Request request) {
        switch (operation) {
        case QNetworkAccessManager.HeadOperation:
            return QByteArrayLiteral ("HEAD");
        case QNetworkAccessManager.GetOperation:
            return QByteArrayLiteral ("GET");
        case QNetworkAccessManager.PutOperation:
            return QByteArrayLiteral ("PUT");
        case QNetworkAccessManager.PostOperation:
            return QByteArrayLiteral ("POST");
        case QNetworkAccessManager.DeleteOperation:
            return QByteArrayLiteral ("DELETE");
        case QNetworkAccessManager.CustomOperation:
            return request.attribute (Soup.Request.CustomVerbAttribute).to_byte_array ();
        case QNetworkAccessManager.UnknownOperation:
            break;
        }
        Q_UNREACHABLE ();
    }

    }
    