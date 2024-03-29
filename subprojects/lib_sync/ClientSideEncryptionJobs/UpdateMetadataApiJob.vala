namespace Occ {
namespace LibSync {

/***********************************************************
@class UpdateMetadataApiJob

Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/
public class UpdateMetadataApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    private string file_identifier;
    private string b64_metadata;
    private string token;


    internal signal void signal_success (string file_identifier);
    internal signal void signal_error (string file_identifier, int http_return_code);


    /***********************************************************
    ***********************************************************/
    public UpdateMetadataApiJob (
        Account account,
        string file_identifier,
        string b64_metadata,
        string locked_token
    ) {
        //  base (account, E2EE_BASE_URL + "meta-data/" + file_identifier);
        //  this.file_identifier = file_identifier;
        //  this.b64_metadata = b64_metadata;
        //  //  this.token = token;
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        //  Soup.Request request = new Soup.Request ();
        //  request.raw_header ("OCS-APIREQUEST", "true");
        //  request.header (Soup.Request.ContentTypeHeader, "application/x-www-form-urlencoded");

        //  GLib.UrlQuery url_query;
        //  url_query.add_query_item ("format", "json");
        //  url_query.add_query_item ("e2e-token", this.token);

        //  GLib.Uri url = Utility.concat_url_path (account.url, this.path);
        //  url.query (url_query);

        //  GLib.UrlQuery parameters;
        //  parameters.add_query_item ("meta_data",GLib.Uri.to_percent_encoding (this.b64_metadata));
        //  parameters.add_query_item ("e2e-token", this.token);

        //  string data = parameters.query ().to_local8Bit ();
        //  var buffer = new Soup.Buffer (this);
        //  buffer.data (data);

        //  GLib.info ("Updating the metadata for the file_identifier " + this.file_identifier.to_string () + " as encrypted.");
        //  send_request ("PUT", url, request, buffer);
        //  AbstractNetworkJob.start ();
    }


    protected bool on_signal_finished () {
        //  int return_code = this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        //      if (return_code != 200) {
        //          GLib.info ("Error updating the metadata " + this.path + this.error_string + return_code);
        //          signal_error (this.file_identifier, return_code);
        //      }

        //      GLib.info ("Metadata submited to the server successfully.");
        //      signal_success (this.file_identifier);
        //  return true;
    }

} // class UpdateMetadataApiJob

} // namespace LibSync
} // namespace Occ
