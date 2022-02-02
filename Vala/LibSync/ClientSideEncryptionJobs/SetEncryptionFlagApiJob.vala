/***********************************************************
Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/

namespace Occ {

/***********************************************************
@brief Job to mark a folder as encrypted JSON

To be
\code
this.job = new Set
 connect (
this.job.on_start ();
\encode

@ingroup libsync
***********************************************************/
class SetEncryptionFlagApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public enum FlagAction {
        Clear = 0,
        Set = 1
    };

    /***********************************************************
    ***********************************************************/
    public SetEncryptionFlagApiJob (AccountPointer account, GLib.ByteArray file_identifier, FlagAction flag_action = Set, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 
    public void on_start () override;

    protected bool on_finished () override;


    signal void success (GLib.ByteArray file_identifier);
    signal void error (GLib.ByteArray file_identifier, int http_return_code);


    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray file_identifier;
    private FlagAction this.flag_action = Set;



    SetEncryptionFlagApiJob.SetEncryptionFlagApiJob (AccountPointer& account, GLib.ByteArray file_identifier, FlagAction flag_action, GLib.Object parent)
    : AbstractNetworkJob (account, e2ee_base_url () + QStringLiteral ("encrypted/") + file_identifier, parent), this.file_identifier (file_identifier), this.flag_action (flag_action) {
    }

    void SetEncryptionFlagApiJob.on_start () {
        Soup.Request req;
        req.set_raw_header ("OCS-APIREQUEST", "true");
        GLib.Uri url = Utility.concat_url_path (account ().url (), path ());

        q_c_info (lc_cse_job ()) << "marking the file with id" << this.file_identifier << "as" << (this.flag_action == Set ? "encrypted" : "non-encrypted") << ".";

        send_request (this.flag_action == Set ? "PUT" : "DELETE", url, req);

        AbstractNetworkJob.on_start ();
    }

    bool SetEncryptionFlagApiJob.on_finished () {
        int return_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        q_c_info (lc_cse_job ()) << "Encryption Flag Return" << reply ().read_all ();
        if (return_code == 200) {
            /* emit */ success (this.file_identifier);
        } else {
            q_c_info (lc_cse_job ()) << "Setting the encrypted flag failed with" << path () << error_string () << return_code;
            /* emit */ error (this.file_identifier, return_code);
        }
        return true;
    }
}

} // namespace Occ
