/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief sends a DELETE http request to a url.

See Nextcloud API usage for the possible DELETE requests.

This does not* delete files, it does a http request.
***********************************************************/
class DeleteApiJob : AbstractNetworkJob {

    signal void result (int http_code);

    /***********************************************************
    ***********************************************************/
    public DeleteApiJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () {
        Soup.Request req;
        req.set_raw_header ("OCS-APIREQUEST", "true");
        GLib.Uri url = Utility.concat_url_path (account ().url (), path ());
        send_request ("DELETE", url, req);
        AbstractNetworkJob.on_start ();
    }


    /***********************************************************
    ***********************************************************/
    private bool on_finished () {
        GLib.Info (lc_json_api_job) << "JsonApiJob of" << reply ().request ().url () << "FINISHED WITH STATUS"
                            << reply ().error ()
                            << (reply ().error () == Soup.Reply.NoError ? QLatin1String ("") : error_string ());

        int http_status = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();

        if (reply ().error () != Soup.Reply.NoError) {
            GLib.warn (lc_json_api_job) << "Network error : " << path () << error_string () << http_status;
            /* emit */ result (http_status);
            return true;
        }

        const var reply_data = string.from_utf8 (reply ().read_all ());
        GLib.Info (lc_json_api_job ()) << "TMX Delete Job" << reply_data;
        /* emit */ result (http_status);
        return true;
    }

} // class DeleteApiJob

} // namespace Occ
