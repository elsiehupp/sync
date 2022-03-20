/***********************************************************
Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/

namespace Occ {
namespace LibSync {

public class UnlockEncryptFolderApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    private string file_identifier;
    private string token;
    private Soup.Buffer token_buf;


    internal signal void signal_success (string file_identifier);
    internal signal void signal_error (string file_identifier, int http_return_code);


    /***********************************************************
    ***********************************************************/
    public UnlockEncryptFolderApiJob (
        Account account,
        string file_identifier,
        string token,
        GLib.Object parent = new GLib.Object ()) {

        base (account, E2EE_BASE_URL + "lock/" + file_identifier, parent);
        this.file_identifier = file_identifier;
        this.token = token;
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        Soup.Request request = new Soup.Request ();
        request.raw_header ("OCS-APIREQUEST", "true");
        request.raw_header ("e2e-token", this.token);

        GLib.Uri url = Utility.concat_url_path (account.url, this.path);
        send_request ("DELETE", url, request);

        AbstractNetworkJob.start ();
        GLib.info ("Starting the request to unlock.");
    }


    /***********************************************************
    ***********************************************************/
    protected bool on_signal_finished () {
        int return_code = this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (return_code != 200) {
            GLib.info ("Error unlocking file " + this.path + this.error_string + return_code);
            GLib.info ("Full Error Log" + this.reply.read_all ());
            /* emit */ signal_error (this.file_identifier, return_code);
            return true;
        }
        /* emit */ signal_success (this.file_identifier);
        return true;
    }

} // class UnlockEncryptFolderApiJob

} // namespace LibSync
} // namespace Occ
