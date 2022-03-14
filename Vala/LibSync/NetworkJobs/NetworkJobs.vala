/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QJsonDocument>
//  #include <QLoggingCategory>
//  #include <Soup.Request>
//  #include <QNetworkAccessManager>
//  #include <Soup.Request>
//  #include <QSslConfigu
//  #include <QSslCipher>
//  #include <Soup.Buffer>
//  #include <QXmlStrea
//  #include <string[
//  #include <GLib.List>
//  #include <QTimer>
//  #include <QMutex>
//  #include <QCoreApplicati
//  #include <QJsonDocumen
//  #include <QJsonObject>
//  #include <qloggingc
//  #include TOKEN_AUTH_ONLY
//  #include <QPainter>
//  #include <QPainterPath>
//  #endif

//  #include <Soup.Buffer>
//  #include <QUrlQuery>
//  #include <QJsonDocument>
//  #include <functional>

namespace Occ {
namespace LibSync {

/***********************************************************
Strips quotes and gzip annotations
***********************************************************/
string parse_etag (char header) {
    if (!header)
        return string ();
    string arr = header;

    // Weak E-Tags can appear when gzip compression is on, see #3946
    if (arr.starts_with ("W/"))
        arr = arr.mid (2);

    // https://github.com/owncloud/client/issues/1195
    arr.replace ("-gzip", "");

    if (arr.length () >= 2 && arr.starts_with ('"') && arr.has_suffix ('"')) {
        arr = arr.mid (1, arr.length () - 2);
    }
    return arr;
}

struct HttpError {
    int code; // HTTP error code
    string message;
}


struct HttpResult : Result<T, HttpError> { }


struct ExtraFolderInfo {
    string file_identifier;
    int64 size = -1;
}

} // namespace LibSync
} // namespace Occ
