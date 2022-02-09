/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QDir>

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

    GLib.HashTable<GLib.ByteArray, GLib.ByteArray> extra_headers;

    signal void finished_signal ();

    /***********************************************************
    ***********************************************************/
    public MoveJob.for_path (AccountPointer account, string path, string destination, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
        this.destination = destination;
    }

    /***********************************************************
    ***********************************************************/
    public MoveJob.for_url (AccountPointer account, GLib.Uri url, string destination,
        GLib.HashTable<GLib.ByteArray, GLib.ByteArray> extra_headers, GLib.Object parent) {
        base (account, "", parent);
        this.destination = destination;
        this.url = url;
        this.extra_headers = extra_headers;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        Soup.Request request;
        request.raw_header ("Destination", GLib.Uri.to_percent_encoding (this.destination, "/"));
        for (var it = this.extra_headers.const_begin (); it != this.extra_headers.const_end (); ++it) {
            request.raw_header (it.key (), it.value ());
        }
        if (this.url.is_valid ()) {
            send_request ("MOVE", this.url, request);
        } else {
            send_request ("MOVE", make_dav_url (path ()), request);
        }

        if (reply ().error () != Soup.Reply.NoError) {
            GLib.warning (" Network error : " + reply ().error_string ();
        }
        AbstractNetworkJob.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    public bool on_signal_finished () {
        GLib.info ("MOVE of" + reply ().request ().url ("FINISHED WITH STATUS"
                        + reply_status_string ();

        /* emit */ finished_signal ();
        return true;
    }

} // class MoveJob

} // namespace Occ