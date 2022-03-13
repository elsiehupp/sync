/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The MkColJob class
@ingroup libsync
***********************************************************/
class MkColJob : AbstractNetworkJob {

    /***********************************************************
    Only used if the constructor taking a url is taken.
    ***********************************************************/
    GLib.Uri url;

    GLib.HashTable<GLib.ByteArray, GLib.ByteArray> extra_headers;


    signal void finished_with_error (Soup.Reply reply);
    signal void finished_without_error ();


    /***********************************************************
    ***********************************************************/
    public MkColJob.for_account (unowned Account account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public MkColJob.for_url (unowned Account account, GLib.Uri url,
        GLib.HashTable<GLib.ByteArray, GLib.ByteArray> extra_headers, GLib.Object parent) {
        base (account, "", parent);
        this.url = url;
        this.extra_headers = extra_headers;
    }


    /***********************************************************
    ***********************************************************/
    public MkColJob.for_path (unowned Account account, string path,
        GLib.HashTable<GLib.ByteArray, GLib.ByteArray> extra_headers, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
        this.extra_headers = extra_headers;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        // add 'Content-Length : 0' header (see https://github.com/owncloud/client/issues/3256)
        Soup.Request request;
        request.raw_header ("Content-Length", "0");
        for (var it = this.extra_headers.const_begin (); it != this.extra_headers.const_end (); ++it) {
            request.raw_header (it.key (), it.value ());
        }

        // assumes ownership
        if (this.url.is_valid ()) {
            send_request ("MKCOL", this.url, request);
        } else {
            send_request ("MKCOL", make_dav_url (path ()), request);
        }
        AbstractNetworkJob.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_finished () {
        GLib.info ("MKCOL of" + reply ().request ().url ()
            + " finished with status " + reply_status_string ());

        if (reply ().error () != Soup.Reply.NoError) {
            /* Q_EMIT */ finished_with_error (reply ());
        } else {
            /* Q_EMIT */ finished_without_error ();
        }
        return true;
    }

} // class MkColJobs

} // namespace LibSync
} // namespace Occ
