namespace Occ {
namespace LibSync {

/***********************************************************
@class SetEncryptionFlagApiJob

@brief Job to mark a folder as encrypted JSON

Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.

To be
\code
this.job = new Set
 connect (
this.job.start ();
\encode

@ingroup libsync
***********************************************************/
public class SetEncryptionFlagApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public enum FlagAction {
        CLEAR = 0,
        SET = 1
    }

    /***********************************************************
    ***********************************************************/
    private string file_identifier;
    private FlagAction flag_action = FlagAction.SET;


    internal signal void signal_success (string file_identifier);
    internal signal void signal_error (string file_identifier, int http_return_code);


    /***********************************************************
    ***********************************************************/
    public SetEncryptionFlagApiJob (
        Account account,
        string file_identifier,
        FlagAction flag_action = FlagAction.SET
    ) {
        //  base (account, E2EE_BASE_URL + "encrypted/" + file_identifier);
        //  this.file_identifier = file_identifier;
        //  this.flag_action = flag_action;
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        //  Soup.Request request = new Soup.Request ();
        //  request.raw_header ("OCS-APIREQUEST", "true");
        //  GLib.Uri url = Utility.concat_url_path (account.url, this.path);

        //  GLib.info ("marking the file with identifier" + this.file_identifier + "as" + (this.flag_action == Set ? "encrypted": "non-encrypted") + ".");

        //  send_request (this.flag_action == Set ? "PUT": "DELETE", url, request);

        //  AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    protected bool on_signal_finished () {
        //  int return_code = this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        //  GLib.info ("Encryption Flag Return " + this.reply.read_all ());
        //  if (return_code == 200) {
        //      signal_success (this.file_identifier);
        //  } else {
        //      GLib.info ("Setting the encrypted flag failed with " + this.path + this.error_string + return_code);
        //      signal_error (this.file_identifier, return_code);
        //  }
        //  return true;
    }

} // class SetEncryptionFlagApiJob

} // namespace LibSync
} // namespace Occ
