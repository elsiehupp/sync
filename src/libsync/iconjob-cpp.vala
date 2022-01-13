/***********************************************************
Copyright (C) by Camila Ayres <hello@camila.codes>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {

IconJob.IconJob (AccountPtr account, QUrl &url, GLib.Object *parent)
    : GLib.Object (parent) {
    QNetworkRequest request (url);
#if (QT_VERSION >= 0x050600)
    request.setAttribute (QNetworkRequest.FollowRedirectsAttribute, true);
#endif
    const auto reply = account.sendRawRequest (QByteArrayLiteral ("GET"), url, request);
    connect (reply, &QNetworkReply.finished, this, &IconJob.finished);
}

void IconJob.finished () {
    const auto reply = qobject_cast<QNetworkReply> (sender ());
    if (!reply) {
        return;
    }
    deleteLater ();

    const auto networkError = reply.error ();
    if (networkError != QNetworkReply.NoError) {
        emit error (networkError);
        return;
    }

    emit jobFinished (reply.readAll ());
}
}
