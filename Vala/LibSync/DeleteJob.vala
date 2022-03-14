/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The DeleteJob class
@ingroup libsync
***********************************************************/
public class DeleteJob : AbstractNetworkJob {

    /***********************************************************
    Only used if the constructor taking a url is taken.
    ***********************************************************/
    private GLib.Uri url;

    /***********************************************************
    ***********************************************************/
    public string folder_token;


    signal void signal_finished ();


    /***********************************************************
    ***********************************************************/
    public DeleteJob.for_path (unowned Account account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public DeleteJob.for_url (unowned Account account, GLib.Uri url, GLib.Object parent) {
        base (account, "", parent);
        this.url = url;
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        Soup.Request request;
        if (!this.folder_token.is_empty ()) {
            request.raw_header ("e2e-token", this.folder_token);
        }

        if (this.url.is_valid ()) {
            send_request ("DELETE", this.url, request);
        } else {
            send_request ("DELETE", make_dav_url (path ()), request);
        }

        if (reply ().error () != Soup.Reply.NoError) {
            GLib.warning ("Network error: " + reply ().error_string ());
        }
        AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    public bool on_signal_finished () {
        GLib.info ("DELETE of " + reply ().request ().url ()
            + " finished with status " + reply_status_string ());

        /* emit */ signal_finished ();
        return true;
    }



} // class DeleteJob

} // namespace LibSync
} // namespace Occ
    