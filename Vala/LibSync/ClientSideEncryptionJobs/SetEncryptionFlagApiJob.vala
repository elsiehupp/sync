/***********************************************************
Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief Job to mark a folder as encrypted JSON

To be
\code
this.job = new Set
 connect (
this.job.on_signal_start ();
\encode

@ingroup libsync
***********************************************************/
class SetEncryptionFlagApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public enum FlagAction {
        Clear = 0,
        Set = 1
    }

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray file_identifier;
    private FlagAction flag_action = Set;


    signal void success (GLib.ByteArray file_identifier);
    signal void error (GLib.ByteArray file_identifier, int http_return_code);

    
    /***********************************************************
    ***********************************************************/
    public SetEncryptionFlagApiJob (unowned Account account, GLib.ByteArray file_identifier, FlagAction flag_action = Set, GLib.Object parent = new GLib.Object ()) {
        base (account, E2EE_BASE_URL + "encrypted/" + file_identifier, parent);
        this.file_identifier = file_identifier;
        this.flag_action = flag_action;
    }


    /***********************************************************
    ***********************************************************/
    public new void on_signal_start () {
        Soup.Request request;
        request.raw_header ("OCS-APIREQUEST", "true");
        GLib.Uri url = Utility.concat_url_path (account ().url (), path ());

        GLib.info ("marking the file with identifier" + this.file_identifier + "as" + (this.flag_action == Set ? "encrypted": "non-encrypted") + ".");

        send_request (this.flag_action == Set ? "PUT": "DELETE", url, request);

        AbstractNetworkJob.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    protected bool on_signal_finished () {
        int return_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        GLib.info ("Encryption Flag Return " + reply ().read_all ());
        if (return_code == 200) {
            /* emit */ success (this.file_identifier);
        } else {
            GLib.info ("Setting the encrypted flag failed with " + path () + error_string () + return_code);
            /* emit */ error (this.file_identifier, return_code);
        }
        return true;
    }

} // class SetEncryptionFlagApiJob

} // namespace LibSync
} // namespace Occ
