/***********************************************************
Copyright (C) by Camila Ayres <hello@camila.codes>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QNetworkAccessManager>
// #include <QNetworkRequest>
// #include <QNetworkReply>

namespace Occ {

/***********************************************************
@brief Job to fetch a icon
@ingroup gui
***********************************************************/
class IconJob : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public IconJob (AccountPointer account, GLib.Uri url, GLib.Object parent = new GLib.Object ());

signals:
    void job_finished (GLib.ByteArray icon_data);
    void error (QNetworkReply.NetworkError error_type);


    /***********************************************************
    ***********************************************************/
    private void on_finished ();
};

    IconJob.IconJob (AccountPointer account, GLib.Uri url, GLib.Object parent)
        : GLib.Object (parent) {
        QNetworkRequest request (url);
    #if (QT_VERSION >= 0x050600)
        request.set_attribute (QNetworkRequest.FollowRedirectsAttribute, true);
    #endif
        const var reply = account.send_raw_request (QByteArrayLiteral ("GET"), url, request);
        connect (reply, &QNetworkReply.on_finished, this, &IconJob.on_finished);
    }

    void IconJob.on_finished () {
        const var reply = qobject_cast<QNetworkReply> (sender ());
        if (!reply) {
            return;
        }
        delete_later ();

        const var network_error = reply.error ();
        if (network_error != QNetworkReply.NoError) {
            /* emit */ error (network_error);
            return;
        }

        /* emit */ job_finished (reply.read_all ());
    }
    }
    