/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>


namespace Occ {

/***********************************************************
@brief The DeleteJob class
@ingroup libsync
***********************************************************/
class DeleteJob : AbstractNetworkJob {

    /***********************************************************
    Only used if the constructor taking a url is taken.
    ***********************************************************/
    private GLib.Uri url;

    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray folder_token;


    signal void finished_signal ();


    /***********************************************************
    ***********************************************************/
    public DeleteJob.for_account (AccountPointer account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public DeleteJob.for_account (AccountPointer account, GLib.Uri url, GLib.Object parent)
        base (account, "", parent);
        this.url = url;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
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
            GLib.warning (" Network error : " + reply ().error_string ();
        }
        AbstractNetworkJob.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    public bool on_signal_finished () {
        GLib.info ("DELETE of" + reply ().request ().url ("FINISHED WITH STATUS"
                           + reply_status_string ();

        /* emit */ finished_signal ();
        return true;
    }



} // class DeleteJob

} // namespace Occ
    