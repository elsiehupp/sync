namespace Occ {
namespace LibSync {

/***********************************************************
@class GetMetadataApiJob

Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/
public class GetMetadataApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    private string file_identifier;


    internal signal void signal_json_received (GLib.JsonDocument json, int return_code);
    internal signal void singal_error (string file_identifier, int http_return_code);


    /***********************************************************
    ***********************************************************/
    public GetMetadataApiJob (
        Account account,
        string file_identifier,
        GLib.Object parent = new GLib.Object ()
    ) {

        //  base (account, E2EE_BASE_URL + "meta-data/" + file_identifier, parent);
        //  this.file_identifier = file_identifier;
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        //  Soup.Request request = new Soup.Request ();
        //  request.raw_header ("OCS-APIREQUEST", "true");
        //  GLib.UrlQuery query;
        //  query.add_query_item ("format", "json");
        //  GLib.Uri url = Utility.concat_url_path (account.url, this.path);
        //  url.query (query);

        //  GLib.info ("Requesting the metadata for the file_identifier " + this.file_identifier + " as encrypted.");
        //  send_request ("GET", url, request);
        //  AbstractNetworkJob.start ();
    }


    protected bool on_signal_finished () {
        //  int return_code = this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        //  if (return_code != 200) {
        //      GLib.info ("Error requesting the metadata " + this.path + this.error_string + return_code);
        //      signal_error (this.file_identifier, return_code);
        //      return true;
        //  }
        //  Json.ParserError error;
        //  var json = GLib.JsonDocument.from_json (this.reply.read_all (), error);
        //  signal_json_received (this, json, this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ());
        //  return true;
    }

} // class GetMetadataApiJob

} // namespace LibSync
} // namespace Occ
