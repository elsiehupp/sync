/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QNetworkAccessManager>


namespace Occ {

/***********************************************************
@brief The AccessManager class
@ingroup libsync
***********************************************************/
class AccessManager : QNetworkAccessManager {

public:
    static QByteArray generateRequestId ();

    AccessManager (GLib.Object *parent = nullptr);

protected:
    QNetworkReply *createRequest (QNetworkAccessManager.Operation op, QNetworkRequest &request, QIODevice *outgoingData = nullptr) override;
};

} // namespace Occ

#endif







/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QNetworkRequest>
// #include <QNetworkReply>
// #include <QNetworkProxy>
// #include <QAuthenticator>
// #include <QSslConfiguration>
// #include <QNetworkCookie>
// #include <QNetworkCookieJar>
// #include <QNetworkConfiguration>
// #include <QUuid>

namespace Occ {

    Q_LOGGING_CATEGORY (lcAccessManager, "nextcloud.sync.accessmanager", QtInfoMsg)
    
    AccessManager.AccessManager (GLib.Object *parent)
        : QNetworkAccessManager (parent) {
    
    #ifndef Q_OS_LINUX
        // Atempt to workaround for https://github.com/owncloud/client/issues/3969
        setConfiguration (QNetworkConfiguration ());
    #endif
        setCookieJar (new CookieJar);
    }
    
    QByteArray AccessManager.generateRequestId () {
        return QUuid.createUuid ().toByteArray (QUuid.WithoutBraces);
    }
    
    QNetworkReply *AccessManager.createRequest (QNetworkAccessManager.Operation op, QNetworkRequest &request, QIODevice *outgoingData) {
        QNetworkRequest newRequest (request);
    
        // Respect request specific user agent if any
        if (!newRequest.header (QNetworkRequest.UserAgentHeader).isValid ()) {
            newRequest.setHeader (QNetworkRequest.UserAgentHeader, Utility.userAgentString ());
        }
    
        // Some firewalls reject requests that have a "User-Agent" but no "Accept" header
        newRequest.setRawHeader (QByteArray ("Accept"), "*/*");
    
        QByteArray verb = newRequest.attribute (QNetworkRequest.CustomVerbAttribute).toByteArray ();
        // For PROPFIND (assumed to be a WebDAV op), set xml/utf8 as content type/encoding
        // This needs extension
        if (verb == "PROPFIND") {
            newRequest.setHeader (QNetworkRequest.ContentTypeHeader, QLatin1String ("text/xml; charset=utf-8"));
        }
    
        // Generate a new request id
        QByteArray requestId = generateRequestId ();
        qInfo (lcAccessManager) << op << verb << newRequest.url ().toString () << "has X-Request-ID" << requestId;
        newRequest.setRawHeader ("X-Request-ID", requestId);
    
    #if QT_VERSION >= QT_VERSION_CHECK (5, 9, 4)
        // only enable HTTP2 with Qt 5.9.4 because old Qt have too many bugs (e.g. QTBUG-64359 is fixed in >= Qt 5.9.4)
        if (newRequest.url ().scheme () == "https") { // Not for "http" : QTBUG-61397
            // http2 seems to cause issues, as with our recommended server setup we don't support http2, disable it by default for now
            static const bool http2EnabledEnv = qEnvironmentVariableIntValue ("OWNCLOUD_HTTP2_ENABLED") == 1;
    
            newRequest.setAttribute (QNetworkRequest.HTTP2AllowedAttribute, http2EnabledEnv);
        }
    #endif
    
        const auto reply = QNetworkAccessManager.createRequest (op, newRequest, outgoingData);
        HttpLogger.logRequest (reply, op, outgoingData);
        return reply;
    }
    
    } // namespace Occ
    