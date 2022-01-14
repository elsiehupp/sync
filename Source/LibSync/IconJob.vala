/***********************************************************
Copyright (C) by Camila Ayres <hello@camila.codes>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Object>
// #include <QByteArray>
// #include <QNetworkAccessManager>
// #include <QNetworkRequest>
// #include <QNetworkReply>

namespace Occ {

/***********************************************************
@brief Job to fetch a icon
@ingroup gui
***********************************************************/
class IconJob : GLib.Object {
public:
    IconJob (AccountPtr account, QUrl &url, GLib.Object *parent = nullptr);

signals:
    void job_finished (QByteArray icon_data);
    void error (QNetworkReply.NetworkError error_type);

private slots:
    void finished ();
};

    IconJob.IconJob (AccountPtr account, QUrl &url, GLib.Object *parent)
        : GLib.Object (parent) {
        QNetworkRequest request (url);
    #if (QT_VERSION >= 0x050600)
        request.set_attribute (QNetworkRequest.FollowRedirectsAttribute, true);
    #endif
        const auto reply = account.send_raw_request (QByteArrayLiteral ("GET"), url, request);
        connect (reply, &QNetworkReply.finished, this, &IconJob.finished);
    }

    void IconJob.finished () {
        const auto reply = qobject_cast<QNetworkReply> (sender ());
        if (!reply) {
            return;
        }
        delete_later ();

        const auto network_error = reply.error ();
        if (network_error != QNetworkReply.NoError) {
            emit error (network_error);
            return;
        }

        emit job_finished (reply.read_all ());
    }
    }
    