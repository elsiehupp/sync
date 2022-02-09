/***********************************************************
Copyright (C) by Camila Ayres <hello@camila.codes>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QNetworkAccessManager>
//  #include <Soup.Request>
using Soup;

namespace Occ {

/***********************************************************
@brief Job to fetch a icon
@ingroup gui
***********************************************************/
class IconJob : GLib.Object {

    signal void job_finished (GLib.ByteArray icon_data);
    signal void error (Soup.Reply.NetworkError error_type);


    /***********************************************************
    ***********************************************************/
    public IconJob.for_account (AccountPointer account, GLib.Uri url, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        Soup.Request request (url);
    // #if (QT_VERSION >= 0x050600)
        request.attribute (Soup.Request.FollowRedirectsAttribute, true);
    // #endif
        var reply = account.send_raw_request (QByteArrayLiteral ("GET"), url, request);
        connect (reply, &Soup.Reply.on_signal_finished, this, &IconJob.on_signal_finished);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_finished () {
        var reply = qobject_cast<Soup.Reply> (sender ());
        if (!reply) {
            return;
        }
        delete_later ();

        var network_error = reply.error ();
        if (network_error != Soup.Reply.NoError) {
            /* emit */ error (network_error);
            return;
        }

        /* emit */ job_finished (reply.read_all ());
    }

} // class IconJob

} // namespace Occ