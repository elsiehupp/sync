/***********************************************************
@author Olivier Goffart <ogoffart@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.Dir>

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The MoveJob class
@ingroup libsync
***********************************************************/
public class MoveJob : AbstractNetworkJob {

    const string destination;

    /***********************************************************
    Only used (instead of path) when the constructor taking an URL is used
    ***********************************************************/
    const GLib.Uri url;

    GLib.HashTable<string, string> extra_headers;

    internal signal void signal_finished ();

    /***********************************************************
    ***********************************************************/
    public MoveJob.for_path (Account account, string path, string destination, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
        this.destination = destination;
    }

    /***********************************************************
    ***********************************************************/
    public MoveJob.for_url (Account account, GLib.Uri url, string destination,
        GLib.HashTable<string, string> extra_headers, GLib.Object parent) {
        base (account, "", parent);
        this.destination = destination;
        this.url = url;
        this.extra_headers = extra_headers;
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        Soup.Request request = new Soup.Request ();
        request.raw_header ("Destination", GLib.Uri.to_percent_encoding (this.destination, "/"));
        for (var it = this.extra_headers.const_begin (); it != this.extra_headers.const_end (); ++it) {
            request.raw_header (it.key (), it.value ());
        }
        if (this.url.is_valid ()) {
            send_request ("MOVE", this.url, request);
        } else {
            send_request ("MOVE", make_dav_url (path), request);
        }

        if (this.reply.error != Soup.Reply.NoError) {
            GLib.warning ("Network error: " + this.reply.error_string);
        }
        AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    public bool on_signal_finished () {
        GLib.info ("MOVE of " + this.reply.request ().url
            + " finished with status " + reply_status_string ());

        /* emit */ signal_finished ();
        return true;
    }

} // class MoveJob

} // namespace LibSync
} // namespace Occ
