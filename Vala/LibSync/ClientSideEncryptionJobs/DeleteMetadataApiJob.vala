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
    public void on_start () override {
        Soup.Request req;
        req.set_raw_header ("OCS-APIREQUEST", "true");

        GLib.Uri url = Utility.concat_url_path (account ().url (), path ());
        send_request ("DELETE", url, req);

        AbstractNetworkJob.on_start ();
        GLib.Info (lc_cse_job ()) << "Starting the request to remove the metadata.";
    }


    /***********************************************************
    ***********************************************************/
    protected bool on_finished () override {
        int return_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (return_code != 200) {
            GLib.Info (lc_cse_job ()) << "error removing metadata for" << path () << error_string () << return_code;
            GLib.Info (lc_cse_job ()) << "Full Error Log" << reply ().read_all ();
            /* emit */ error (this.file_identifier, return_code);
            return true;
        }
        /* emit */ success (this.file_identifier);
        return true;
    }
}

} // namespace Occ
