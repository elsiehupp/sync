/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QDir>
//  #pragma once

namespace Occ {

/***********************************************************
@brief The MoveJob class
@ingroup libsync
***********************************************************/
class MoveJob : AbstractNetworkJob {

    const string destination;

    /***********************************************************
    Only used (instead of path) when the constructor taking an URL is used
    ***********************************************************/
    const GLib.Uri url;

    GLib.HashMap<GLib.ByteArray, GLib.ByteArray> extra_headers;

    signal void finished_signal ();

    /***********************************************************
    ***********************************************************/
    public MoveJob (AccountPointer account, string path, string destination, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
        this.destination = destination;
    }

    /***********************************************************
    ***********************************************************/
    public MoveJob (AccountPointer account, GLib.Uri url, string destination,
        GLib.HashMap<GLib.ByteArray, GLib.ByteArray> extra_headers, GLib.Object parent) {
        base (account, "", parent);
        this.destination = destination;
        this.url = url;
        this.extra_headers = extra_headers;
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () {
        Soup.Request req;
        req.raw_header ("Destination", GLib.Uri.to_percent_encoding (this.destination, "/"));
        for (var it = this.extra_headers.const_begin (); it != this.extra_headers.const_end (); ++it) {
            req.raw_header (it.key (), it.value ());
        }
        if (this.url.is_valid ()) {
            send_request ("MOVE", this.url, req);
        } else {
            send_request ("MOVE", make_dav_url (path ()), req);
        }

        if (reply ().error () != Soup.Reply.NoError) {
            GLib.warn (lc_propagate_remote_move) << " Network error : " << reply ().error_string ();
        }
        AbstractNetworkJob.on_start ();
    }


    /***********************************************************
    ***********************************************************/
    public bool on_finished () {
        GLib.info (lc_move_job) << "MOVE of" << reply ().request ().url () << "FINISHED WITH STATUS"
                        << reply_status_string ();

        /* emit */ finished_signal ();
        return true;
    }

} // class MoveJob

} // namespace Occ
