/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
@brief A basic job around a network request without extra funtionality
@ingroup libsync

Primarily adds timeout and redirection handling.
***********************************************************/
class SimpleNetworkJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public SimpleNetworkJob (AccountPointer account, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public Soup.Reply start_request (GLib.ByteArray verb, GLib.Uri url,
        Soup.Request req = Soup.Request (),
        QIODevice request_body = nullptr);

signals:
    void finished_signal (Soup.Reply reply);

    /***********************************************************
    ***********************************************************/
    private on_ bool on_finished () override;





    SimpleNetworkJob.SimpleNetworkJob (AccountPointer account, GLib.Object parent)
        : AbstractNetworkJob (account, "", parent) {
    }

    Soup.Reply *SimpleNetworkJob.start_request (GLib.ByteArray verb, GLib.Uri url,
        Soup.Request req, QIODevice request_body) {
        var reply = send_request (verb, url, req, request_body);
        on_start ();
        return reply;
    }

    bool SimpleNetworkJob.on_finished () {
        /* emit */ finished_signal (reply ());
        return true;
    }
};