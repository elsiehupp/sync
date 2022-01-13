/***********************************************************
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QRegularExpression>
// #include <QLoggingCategory>
// #include <QBuffer>
// #pragma once

// #include <QNetworkReply>
// #include <QUrl>

namespace Occ {
namespace HttpLogger {
    void logRequest (QNetworkReply *reply, QNetworkAccessManager.Operation operation, QIODevice *device);

    /***********************************************************
    * Helper to construct the HTTP verb used in the request
    */
    QByteArray requestVerb (QNetworkAccessManager.Operation operation, QNetworkRequest &request);
    inline QByteArray requestVerb (QNetworkReply &reply) {
        return requestVerb (reply.operation (), reply.request ());
    }
}

    const int64 PeekSize = 1024 * 1024;
    
    const QByteArray XRequestId (){
        return QByteArrayLiteral ("X-Request-ID");
    }
    
    bool isTextBody (string &s) {
        static const QRegularExpression regexp (QStringLiteral ("^ (text/.*| (application/ (xml|json|x-www-form-urlencoded) (;|$)))"));
        return regexp.match (s).hasMatch ();
    }
    
    void logHttp (QByteArray &verb, string &url, QByteArray &id, string &contentType, QList<QNetworkReply.RawHeaderPair> &header, QIODevice *device) {
        const auto reply = qobject_cast<QNetworkReply> (device);
        const auto contentLength = device ? device.size () : 0;
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
            stream << " " << reply.attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
        }
        stream << " " << url << " Header : { ";
        for (auto &it : header) {
            stream << it.first << " : ";
            if (it.first == "Authorization") {
                stream << (it.second.startsWith ("Bearer ") ? "Bearer" : "Basic");
                stream << " [redacted]";
            } else {
                stream << it.second;
            }
            stream << ", ";
        }
        stream << "} Data : [";
        if (contentLength > 0) {
            if (isTextBody (contentType)) {
                if (!device.isOpen ()) {
                    Q_ASSERT (dynamic_cast<QBuffer> (device));
                    // should we close it again?
                    device.open (QIODevice.ReadOnly);
                }
                Q_ASSERT (device.pos () == 0);
                stream << device.peek (PeekSize);
                if (PeekSize < contentLength) {
                    stream << "... (" << (contentLength - PeekSize) << "bytes elided)";
                }
            } else {
                stream << contentLength << " bytes of " << contentType << " data";
            }
        }
        stream << "]";
        qCInfo (lcNetworkHttp) << msg;
    }
    }
    
    namespace Occ {
    
    void HttpLogger.logRequest (QNetworkReply *reply, QNetworkAccessManager.Operation operation, QIODevice *device) {
        const auto request = reply.request ();
        if (!lcNetworkHttp ().isInfoEnabled ()) {
            return;
        }
        const auto keys = request.rawHeaderList ();
        QList<QNetworkReply.RawHeaderPair> header;
        header.reserve (keys.size ());
        for (auto &key : keys) {
            header << qMakePair (key, request.rawHeader (key));
        }
        logHttp (requestVerb (operation, request),
            request.url ().toString (),
            request.rawHeader (XRequestId ()),
            request.header (QNetworkRequest.ContentTypeHeader).toString (),
            header,
            device);
    
        GLib.Object.connect (reply, &QNetworkReply.finished, reply, [reply] {
            logHttp (requestVerb (*reply),
                reply.url ().toString (),
                reply.request ().rawHeader (XRequestId ()),
                reply.header (QNetworkRequest.ContentTypeHeader).toString (),
                reply.rawHeaderPairs (),
                reply);
        });
    }
    
    QByteArray HttpLogger.requestVerb (QNetworkAccessManager.Operation operation, QNetworkRequest &request) {
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
            return request.attribute (QNetworkRequest.CustomVerbAttribute).toByteArray ();
        case QNetworkAccessManager.UnknownOperation:
            break;
        }
        Q_UNREACHABLE ();
    }
    
    }
    