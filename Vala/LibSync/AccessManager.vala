/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <Soup.Request>
//  #include <QNetworkProxy>
//  #include <QAuthenticator>
//  #include <QSslConfigurati
//  #include <QNetworkCookie>
//  #include <QNetworkCookieJar>
//  #include <QNetwor
//  #include <QUuid>

//  #include <QNetworkAccessManager>

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The AccessManager class
@ingroup libsync
***********************************************************/
class AccessManager : QNetworkAccessManager {

    /***********************************************************
    ***********************************************************/
    public AccessManager (GLib.Object parent = new GLib.Object ()) {
        base (parent);

        cookie_jar (new CookieJar ());
    }


    /***********************************************************
    ***********************************************************/
    public static GLib.ByteArray generate_request_id () {
        return QUuid.create_uuid ().to_byte_array (QUuid.WithoutBraces);
    }


    /***********************************************************
    ***********************************************************/
    protected Soup.Reply create_request (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice outgoing_data = null) {
        Soup.Request new_request = new Soup.Request (request);

        // Respect request specific user agent if any
        if (!new_request.header (Soup.Request.UserAgentHeader).is_valid ()) {
            new_request.header (Soup.Request.UserAgentHeader, Utility.user_agent_string ());
        }

        // Some firewalls reject requests that have a "User-Agent" but no "Accept" header
        new_request.raw_header (GLib.ByteArray ("Accept"), "*/*");

        GLib.ByteArray verb = new_request.attribute (Soup.Request.CustomVerbAttribute).to_byte_array ();
        // For PROPFIND (assumed to be a WebDAV operation), set xml/utf8 as content type/encoding
        // This needs extension
        if (verb == "PROPFIND") {
            new_request.header (Soup.Request.ContentTypeHeader, "text/xml; charset=utf-8");
        }

        // Generate a new request identifier
        GLib.ByteArray request_id = generate_request_id ();
        GLib.info (operation + verb + new_request.url ().to_string () + "has X-Request-ID " + request_id);
        new_request.raw_header ("X-Request-ID", request_id);

    // #if QT_VERSION >= QT_VERSION_CHECK (5, 9, 4)
        // only enable HTTP2 with Qt 5.9.4 because old Qt have too many bugs (e.g. QTBUG-64359 is fixed in >= Qt 5.9.4)
        if (new_request.url ().scheme () == "https") { // Not for "http" : QTBUG-61397
            // http2 seems to cause issues, as with our recommended server setup we don't support http2, disable it by default for now
            const bool http2_enabled_env = q_environment_variable_int_value ("OWNCLOUD_HTTP2_ENABLED") == 1;

            new_request.attribute (Soup.Request.HTTP2AllowedAttribute, http2_enabled_env);
        }
    // #endif

        var reply = QNetworkAccessManager.create_request (operation, new_request, outgoing_data);
        HttpLogger.log_request (reply, operation, outgoing_data);
        return reply;
    }

} // class AccessManager

} // namespace LibSync
} // namespace Occ
    