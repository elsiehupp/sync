/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QJsonDocument>
// #include <QLoggingCategory>
// #include <Soup.Request>
// #include <QNetworkAccessManager>
// #include <QNetworkReply>
// #include <Soup.Request>
// #include <QSslConfiguration>
// #include <QSslCipher>
// #include <Soup.Buffer>
// #include <QXmlStreamReader>
// #include <string[]>
// #include <QStack>
// #include <QTimer>
// #include <QMutex>
// #include <QCoreApplication>
// #include <QJsonDocument>
// #include <QJsonObject>
// #include <qloggingcategory.h>
//  #ifndef TOKEN_AUTH_ONLY
// #include <QPainter>
// #include <QPainterPath>
//  #endif

// #include <Soup.Buffer>
// #include <QUrlQuery>
// #include <QJsonDocument>
// #include <functional>


namespace Occ {

    /***********************************************************
    Strips quotes and gzip annotations
    ***********************************************************/
    GLib.ByteArray parse_etag (char header) {
        if (!header)
            return GLib.ByteArray ();
        GLib.ByteArray arr = header;

        // Weak E-Tags can appear when gzip compression is on, see #3946
        if (arr.starts_with ("W/"))
            arr = arr.mid (2);

        // https://github.com/owncloud/client/issues/1195
        arr.replace ("-gzip", "");

        if (arr.length () >= 2 && arr.starts_with ('"') && arr.ends_with ('"')) {
            arr = arr.mid (1, arr.length () - 2);
        }
        return arr;
    }

    struct HttpError {
        int code; // HTTP error code
        string message;
    };

    template <typename T>
    using HttpResult = Result<T, HttpError>;



    struct ExtraFolderInfo {
        GLib.ByteArray file_identifier;
        int64 size = -1;
    };


    /***********************************************************
    @brief Runs a PROPFIND to figure out the private link url

    The numeric_file_id is used only to build the deprecated_private_link_url
    locally as a fallback. If it's empty an
    will be called with an empty string.

    The job and signal connections are parented to the target
    GLib.Object.

    Note: target_function is guaranteed to be called only
    through the event loop and never directly.
    ***********************************************************/
    void fetch_private_link_url (
        AccountPointer account,
        string remote_path,
        GLib.ByteArray numeric_file_id,
        GLib.Object target,
        std.function<void (string url)> target_function) {
        string old_url;
        if (!numeric_file_id.is_empty ())
            old_url = account.deprecated_private_link_url (numeric_file_id).to_string (GLib.Uri.FullyEncoded);

        // Retrieve the new link by PROPFIND
        var job = new PropfindJob (account, remote_path, target);
        job.set_properties (
            GLib.List<GLib.ByteArray> ()
            << "http://owncloud.org/ns:fileid" // numeric file id for fallback private link generation
            << "http://owncloud.org/ns:privatelink");
        job.on_set_timeout (10 * 1000);
        GLib.Object.connect (job, &PropfindJob.result, target, [=] (QVariantMap result) {
            var private_link_url = result["privatelink"].to_string ();
            var numeric_file_id = result["fileid"].to_byte_array ();
            if (!private_link_url.is_empty ()) {
                target_function (private_link_url);
            } else if (!numeric_file_id.is_empty ()) {
                target_function (account.deprecated_private_link_url (numeric_file_id).to_string (GLib.Uri.FullyEncoded));
            } else {
                target_function (old_url);
            }
        });
        GLib.Object.connect (job, &PropfindJob.finished_with_error, target, [=] (QNetworkReply *) {
            target_function (old_url);
        });
        job.on_start ();
    }

} // namespace Occ
