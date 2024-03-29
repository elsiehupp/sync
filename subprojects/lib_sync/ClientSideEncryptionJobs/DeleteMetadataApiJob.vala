namespace Occ {
namespace LibSync {

/***********************************************************
@class DeleteMetadataApiJob

Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/
public class DeleteMetadataApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    private string file_identifier;


    internal signal void signal_success (string file_identifier);
    internal signal void signal_error (string file_identifier, int http_error_code);


    /***********************************************************
    ***********************************************************/
    public DeleteMetadataApiJob (
        Account account,
        string file_identifier
    ) {

        //  base (account, E2EE_BASE_URL + "meta-data/" + file_identifier);
        //  this.file_identifier = file_identifier;
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        //  Soup.Request request = new Soup.Request ();
        //  request.raw_header ("OCS-APIREQUEST", "true");

        //  GLib.Uri url = Utility.concat_url_path (account.url, this.path);
        //  send_request ("DELETE", url, request);

        //  AbstractNetworkJob.start ();
        //  GLib.info ("Starting the request to remove the metadata.");
    }


    /***********************************************************
    ***********************************************************/
    protected bool on_signal_finished () {
        //  int return_code = this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        //  if (return_code != 200) {
        //      GLib.info ("Error removing metadata for " + this.path + this.error_string + return_code);
        //      GLib.info ("Full Error Log " + this.reply.read_all ());
        //      signal_error (this.file_identifier, return_code);
        //      return true;
        //  }
        //  signal_success (this.file_identifier);
        //  return true;
    }

} // class DeleteMetadataApiJob

} // namespace LibSync
} // namespace Occ
