namespace Occ {
namespace LibSync {

/***********************************************************
@class KeychainChunkDeleteJob2

@brief The KeychainChunkDeleteJob2 class

@author Olivier Goffart <ogoffart@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class KeychainChunkDeleteJob2 : AbstractNetworkJob {

    /***********************************************************
    Only used if the constructor taking a url is taken.
    ***********************************************************/
    private GLib.Uri url;

    /***********************************************************
    ***********************************************************/
    public string folder_token;


    internal signal void signal_finished ();


    /***********************************************************
    ***********************************************************/
    public KeychainChunkDeleteJob2.for_path (Account account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public KeychainChunkDeleteJob2.for_url (Account account, GLib.Uri url, GLib.Object parent) {
        base (account, "", parent);
        this.url = url;
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        Soup.Request request = new Soup.Request ();
        if (this.folder_token != "") {
            request.raw_header ("e2e-token", this.folder_token);
        }

        if (GLib.Uri.is_valid (this.url)) {
            send_request ("DELETE", this.url, request);
        } else {
            send_request ("DELETE", make_dav_url (path), request);
        }

        if (this.reply.error != GLib.InputStream.NoError) {
            GLib.warning ("Network error: " + this.reply.error_string);
        }
        AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    public bool on_signal_finished () {
        GLib.info ("DELETE of " + this.reply.request ().url
            + " finished with status " + reply_status_string ());

        signal_finished ();
        return true;
    }



} // class KeychainChunkDeleteJob2

} // namespace LibSync
} // namespace Occ
    