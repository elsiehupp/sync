/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <string[]>
// #include <QDir>
// #pragma once

namespace Occ {


/***********************************************************
@brief The Move_job class
@ingroup libsync
***********************************************************/
class Move_job : AbstractNetworkJob {
    const string this.destination;
    const GLib.Uri this.url; // Only used (instead of path) when the constructor taking an URL is used
    GLib.HashMap<GLib.ByteArray, GLib.ByteArray> this.extra_headers;

    /***********************************************************
    ***********************************************************/
    public Move_job (AccountPointer account, string path, string destination, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public p<GLib.ByteArray, GLib.ByteArray> this.extra_headers, GLib.Object parent = new GLib.Object ());

    public void on_start () override;
    public bool on_finished () override;

signals:
    void finished_signal ();
}



Move_job.Move_job (AccountPointer account, string path,
    const string destination, GLib.Object parent)
    : AbstractNetworkJob (account, path, parent)
    , this.destination (destination) {
}

Move_job.Move_job (AccountPointer account, GLib.Uri url, string destination,
    GLib.HashMap<GLib.ByteArray, GLib.ByteArray> extra_headers, GLib.Object parent)
    : AbstractNetworkJob (account, "", parent)
    , this.destination (destination)
    , this.url (url)
    , this.extra_headers (extra_headers) {
}

void Move_job.on_start () {
    Soup.Request req;
    req.set_raw_header ("Destination", GLib.Uri.to_percent_encoding (this.destination, "/"));
    for (var it = this.extra_headers.const_begin (); it != this.extra_headers.const_end (); ++it) {
        req.set_raw_header (it.key (), it.value ());
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

bool Move_job.on_finished () {
    q_c_info (lc_move_job) << "MOVE of" << reply ().request ().url () << "FINISHED WITH STATUS"
                      << reply_status_"";

    /* emit */ finished_signal ();
    return true;
}