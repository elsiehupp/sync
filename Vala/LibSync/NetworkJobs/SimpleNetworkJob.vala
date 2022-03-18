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

    internal signal void signal_finished (GLib.InputStream reply);


    /***********************************************************
    ***********************************************************/
    public SimpleNetworkJob.for_account (Account account, GLib.Object parent = new GLib.Object ()) {
        base (account, "", parent);
    }


    /***********************************************************
    ***********************************************************/
    public GLib.InputStream start_request (string verb, GLib.Uri url,
        Soup.Request request = Soup.Request (),
        QIODevice request_body = null) {
        var reply = send_request (verb, url, request, request_body);
        start ();
        return reply;
    }



    /***********************************************************
    ***********************************************************/
    private bool on_signal_finished () {
        /* emit */ signal_finished (this.reply);
        return true;
    }

} // class SimpleNetworkJob

} // namespace LibSync
} // namespace Occ
