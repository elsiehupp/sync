/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>

//  #pragma once

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
    private GLib.ByteArray folder_token;


    signal void finished_signal ();


    /***********************************************************
    ***********************************************************/
    public DeleteJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public DeleteJob (AccountPointer account, GLib.Uri url, GLib.Object parent)
        base (account, "", parent);
        this.url = url;
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () {
        Soup.Request req;
        if (!this.folder_token.is_empty ()) {
            req.set_raw_header ("e2e-token", this.folder_token);
        }

        if (this.url.is_valid ()) {
            send_request ("DELETE", this.url, req);
        } else {
            send_request ("DELETE", make_dav_url (path ()), req);
        }

        if (reply ().error () != Soup.Reply.NoError) {
            GLib.warn (lc_delete_job) << " Network error : " << reply ().error_string ();
        }
        AbstractNetworkJob.on_start ();
    }


    /***********************************************************
    ***********************************************************/
    public bool on_finished () {
        GLib.Info (lc_delete_job) << "DELETE of" << reply ().request ().url () << "FINISHED WITH STATUS"
                           << reply_status_string ();

        /* emit */ finished_signal ();
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray folder_token () {
        return this.folder_token;
    }


    public void set_folder_token (GLib.ByteArray folder_token) {
        this.folder_token = folder_token;
    }

} // class DeleteJob

} // namespace Occ
    