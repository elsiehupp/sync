namespace Occ {
namespace LibSync {

/***********************************************************
@class StoreMetadataApiJob

Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/
public class StoreMetadataApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    private string file_identifier;
    private string b64_metadata;


    internal signal void signal_success (string file_identifier);
    internal signal void signal_error (string file_identifier, int http_return_code);


    /***********************************************************
    ***********************************************************/
    public StoreMetadataApiJob (
        Account account,
        string file_identifier,
        string b64_metadata
    ) {

        //  base (account, E2EE_BASE_URL + "meta-data/" + file_identifier);
        //  this.file_identifier = file_identifier;
        //  this.b64_metadata = b64_metadata;
    }


    /***********************************************************
    ***********************************************************/
    public override void start () {
        //  Soup.Request request = new Soup.Request ();
        //  request.raw_header ("OCS-APIREQUEST", "true");
        //  request.header (Soup.Request.ContentTypeHeader, "application/x-www-form-urlencoded");
        //  GLib.UrlQuery query;
        //  query.add_query_item ("format", "json");
        //  GLib.Uri url = Utility.concat_url_path (account.url, this.path);
        //  url.query (query);

        //  string data = "meta_data=" + GLib.Uri.to_percent_encoding (this.b64_metadata);
        //  var buffer = new Soup.Buffer (this);
        //  buffer.data (data);

        //  GLib.info ("Sending the metadata for the file_identifier " + this.file_identifier + " as encrypted.");
        //  send_request ("POST", url, request, buffer);
        //  AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    protected bool on_signal_finished () {
        //  int return_code = this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        //      if (return_code != 200) {
        //          GLib.info ("Error sending the metadata " + this.path + this.error_string + return_code);
        //          signal_error (this.file_identifier, return_code);
        //      }

        //      GLib.info ("Metadata submited to the server successfully");
        //      signal_success (this.file_identifier);
        //  return true;
    }

} // class StoreMetadataApiJob

} // namespace LibSync
} // namespace Occ
