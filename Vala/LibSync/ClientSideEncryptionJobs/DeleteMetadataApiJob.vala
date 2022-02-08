/***********************************************************
Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/

namespace Occ {

class DeleteMetadataApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray file_identifier;


    signal void success (GLib.ByteArray file_identifier);
    signal void error (GLib.ByteArray file_identifier, int http_error_code);


    /***********************************************************
    ***********************************************************/
    public DeleteMetadataApiJob (
        AccountPointer account,
        GLib.ByteArray file_identifier,
        GLib.Object parent = new GLib.Object ()) {

        base (account, E2EE_BASE_URL + "meta-data/" + file_identifier, parent)
        this.file_identifier = file_identifier;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        Soup.Request reques;
        reques.raw_header ("OCS-APIREQUEST", "true");

        GLib.Uri url = Utility.concat_url_path (account ().url (), path ());
        send_request ("DELETE", url, reques);

        AbstractNetworkJob.on_signal_start ();
        GLib.info ()) + "Starting the request to remove the metadata.";
    }


    /***********************************************************
    ***********************************************************/
    protected bool on_signal_finished () {
        int return_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (return_code != 200) {
            GLib.info ()) + "error removing metadata for" + path () + error_string () + return_code;
            GLib.info ()) + "Full Error Log" + reply ().read_all ();
            /* emit */ error (this.file_identifier, return_code);
            return true;
        }
        /* emit */ success (this.file_identifier);
        return true;
    }
}

} // namespace Occ
