/***********************************************************
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/
// #pragma once

// #include <QNetworkReply>
// #include <QUrl>

namespace Occ {
namespace HttpLogger {
    void OWNCLOUDSYNC_EXPORT logRequest (QNetworkReply *reply, QNetworkAccessManager.Operation operation, QIODevice *device);

    /***********************************************************
    * Helper to construct the HTTP verb used in the request
    */
    QByteArray OWNCLOUDSYNC_EXPORT requestVerb (QNetworkAccessManager.Operation operation, QNetworkRequest &request);
    inline QByteArray requestVerb (QNetworkReply &reply) {
        return requestVerb (reply.operation (), reply.request ());
    }
}
}
