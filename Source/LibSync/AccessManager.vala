/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
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

// #include <QNetworkAccessManager>


namespace Occ {

/***********************************************************
@brief The AccessManager class
@ingroup libsync
***********************************************************/
class AccessManager : QNetworkAccessManager {

    public static GLib.ByteArray generate_request_id ();

    public AccessManager (GLib.Object *parent = nullptr);

    protected QNetworkReply *create_request (QNetworkAccessManager.Operation op, QNetworkRequest &request, QIODevice *outgoing_data = nullptr) override;
};

    AccessManager.AccessManager (GLib.Object *parent)
        : QNetworkAccessManager (parent) {

    #ifndef Q_OS_LINUX
        // Atempt to workaround for https://github.com/owncloud/client/issues/3969
        set_configuration (QNetworkConfiguration ());
    #endif
        set_cookie_jar (new CookieJar);
    }

    GLib.ByteArray AccessManager.generate_request_id () {
        return QUuid.create_uuid ().to_byte_array (QUuid.WithoutBraces);
    }

    QNetworkReply *AccessManager.create_request (QNetworkAccessManager.Operation op, QNetworkRequest &request, QIODevice *outgoing_data) {
        QNetworkRequest new_request (request);

        // Respect request specific user agent if any
        if (!new_request.header (QNetworkRequest.UserAgentHeader).is_valid ()) {
            new_request.set_header (QNetworkRequest.UserAgentHeader, Utility.user_agent_string ());
        }

        // Some firewalls reject requests that have a "User-Agent" but no "Accept" header
        new_request.set_raw_header (GLib.ByteArray ("Accept"), "*/*");

        GLib.ByteArray verb = new_request.attribute (QNetworkRequest.CustomVerbAttribute).to_byte_array ();
        // For PROPFIND (assumed to be a WebDAV op), set xml/utf8 as content type/encoding
        // This needs extension
        if (verb == "PROPFIND") {
            new_request.set_header (QNetworkRequest.ContentTypeHeader, QLatin1String ("text/xml; charset=utf-8"));
        }

        // Generate a new request id
        GLib.ByteArray request_id = generate_request_id ();
        q_info (lc_access_manager) << op << verb << new_request.url ().to_string () << "has X-Request-ID" << request_id;
        new_request.set_raw_header ("X-Request-ID", request_id);

    #if QT_VERSION >= QT_VERSION_CHECK (5, 9, 4)
        // only enable HTTP2 with Qt 5.9.4 because old Qt have too many bugs (e.g. QTBUG-64359 is fixed in >= Qt 5.9.4)
        if (new_request.url ().scheme () == "https") { // Not for "http" : QTBUG-61397
            // http2 seems to cause issues, as with our recommended server setup we don't support http2, disable it by default for now
            static const bool http2_enabled_env = q_environment_variable_int_value ("OWNCLOUD_HTTP2_ENABLED") == 1;

            new_request.set_attribute (QNetworkRequest.HTTP2AllowedAttribute, http2_enabled_env);
        }
    #endif

        const auto reply = QNetworkAccessManager.create_request (op, new_request, outgoing_data);
        HttpLogger.log_request (reply, op, outgoing_data);
        return reply;
    }

    } // namespace Occ
    