/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief sends a DELETE http request to a url.

See Nextcloud API usage for the possible DELETE requests.

This does not* delete files, it does a http request.
***********************************************************/
public class DeleteApiJob : AbstractNetworkJob {

    internal signal void signal_result (int http_code);

    /***********************************************************
    ***********************************************************/
    public DeleteApiJob.for_account (Account account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        Soup.Request request = new Soup.Request ();
        request.raw_header ("OCS-APIREQUEST", "true");
        GLib.Uri url = Utility.concat_url_path (account.url, path ());
        send_request ("DELETE", url, request);
        AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_finished () {
        GLib.info ("JsonApiJob of" + this.reply.request ().url
            + " finished with status " + this.reply.error ()
            + (this.reply.error () == Soup.Reply.NoError ? "" : error_string ()));

        int http_status = this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();

        if (this.reply.error () != Soup.Reply.NoError) {
            GLib.warning ("Network error: " + path () + error_string () + http_status);
            /* emit */ signal_result (http_status);
            return true;
        }

        var reply_data = string.from_utf8 (this.reply.read_all ());
        GLib.info ("TMX Delete Job " + reply_data);
        /* emit */ signal_result (http_status);
        return true;
    }

} // class DeleteApiJob

} // namespace LibSync
} // namespace Occ
