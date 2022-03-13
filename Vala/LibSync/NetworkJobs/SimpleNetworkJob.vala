/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief A basic job around a network request without extra funtionality
@ingroup libsync

Primarily adds timeout and redirection handling.
***********************************************************/
public class SimpleNetworkJob : AbstractNetworkJob {

    signal void signal_finished (Soup.Reply reply);


    /***********************************************************
    ***********************************************************/
    public SimpleNetworkJob.for_account (unowned Account account, GLib.Object parent = new GLib.Object ()) {
        base (account, "", parent);
    }


    /***********************************************************
    ***********************************************************/
    public Soup.Reply start_request (GLib.ByteArray verb, GLib.Uri url,
        Soup.Request request = Soup.Request (),
        QIODevice request_body = null) {
        var reply = send_request (verb, url, request, request_body);
        on_signal_start ();
        return reply;
    }



    /***********************************************************
    ***********************************************************/
    private bool on_signal_finished () {
        /* emit */ signal_finished (reply ());
        return true;
    }

} // class SimpleNetworkJob

} // namespace LibSync
} // namespace Occ
