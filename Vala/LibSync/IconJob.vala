/***********************************************************
Copyright (C) by Camila Ayres <hello@camila.codes>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <Soup.Session>
using Soup;

namespace Occ {
namespace LibSync {

/***********************************************************
@brief Job to fetch a icon
@ingroup gui
***********************************************************/
public class IconJob : GLib.Object {

    internal signal void signal_job_finished (string icon_data);
    internal signal void signal_error (Soup.Reply.NetworkError error_type);


    /***********************************************************
    ***********************************************************/
    public IconJob.for_account (Account account, GLib.Uri url, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        Soup.Request request = new Soup.Request (url);
        request.attribute (Soup.Request.FollowRedirectsAttribute, true);
        var reply = account.send_raw_request ("GET", url, request);
        reply.signal_finished.connect (
            this.on_signal_finished
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_finished () {
        var reply = qobject_cast<GLib.InputStream> (sender ());
        if (!reply) {
            return;
        }
        delete_later ();

        var network_error = reply.error;
        if (network_error != Soup.Reply.NoError) {
            /* emit */ signal_error (signal_network_error);
            return;
        }

        /* emit */ signal_job_finished (reply.read_all ());
    }

} // class IconJob

} // namespace LibSync
} // namespace Occ
