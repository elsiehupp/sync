/***********************************************************
Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/

namespace Occ {

class UnlockEncryptFolderApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray file_identifier;
    private GLib.ByteArray token;
    private Soup.Buffer token_buf;


    signal void success (GLib.ByteArray file_identifier);
    signal void error (GLib.ByteArray file_identifier, int http_return_code);


    /***********************************************************
    ***********************************************************/
    public UnlockEncryptFolderApiJob (
        AccountPointer account,
        GLib.ByteArray file_identifier,
        GLib.ByteArray token,
        GLib.Object parent = new GLib.Object ()) {
        
        base (account, E2EE_BASE_URL + "lock/" + file_identifier, parent)
        this.file_identifier = file_identifier;
        this.token = token;
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () override {
        Soup.Request req;
        req.set_raw_header ("OCS-APIREQUEST", "true");
        req.set_raw_header ("e2e-token", this.token);

        GLib.Uri url = Utility.concat_url_path (account ().url (), path ());
        send_request ("DELETE", url, req);

        AbstractNetworkJob.on_start ();
        GLib.Info (lc_cse_job ()) << "Starting the request to unlock.";
    }


    /***********************************************************
    ***********************************************************/
    protected bool on_finished () override {
        int return_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (return_code != 200) {
            GLib.Info (lc_cse_job ()) << "error unlocking file" << path () << error_string () << return_code;
            GLib.Info (lc_cse_job ()) << "Full Error Log" << reply ().read_all ();
            /* emit */ error (this.file_identifier, return_code);
            return true;
        }
        /* emit */ success (this.file_identifier);
        return true;
    }
}

} // namespace Occ
