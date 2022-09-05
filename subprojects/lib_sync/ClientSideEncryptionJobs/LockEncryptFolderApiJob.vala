namespace Occ {
namespace LibSync {

/***********************************************************
@class LockEncryptFolderApiJob

Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/
public class LockEncryptFolderApiJob : AbstractNetworkJob {

    //  /***********************************************************
    //  ***********************************************************/
    //  private string file_identifier;

    //  internal signal void signal_success (string file_identifier, string token);
    //  internal signal void signal_error (string file_identifier, int httpd_error_code);

    //  /***********************************************************
    //  ***********************************************************/
    //  public LockEncryptFolderApiJob (Account account, string file_identifier, GLib.Object parent = new GLib.Object ()) {
    //      base (account, E2EE_BASE_URL + "lock/" + file_identifier, parent);
    //      this.file_identifier = file_identifier;
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  public new void start () {
    //      Soup.Request request = new Soup.Request ();
    //      request.raw_header ("OCS-APIREQUEST", "true");
    //      GLib.UrlQuery query;
    //      query.add_query_item ("format", "json");
    //      GLib.Uri url = Utility.concat_url_path (account.url, this.path);
    //      url.query (query);

    //      GLib.info ("Locking the folder with identifier " + this.file_identifier.to_string () + " as encrypted.");
    //      send_request ("POST", url, request);
    //      AbstractNetworkJob.start ();
    //  }

    //  protected bool on_signal_finished () {
    //      int return_code = this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
    //      if (return_code != 200) {
    //          GLib.info ("Error locking file " + this.path + this.error_string + return_code);
    //          signal_error (this.file_identifier, return_code);
    //          return true;
    //      }

    //      Json.ParserError error;
    //      var json = GLib.JsonDocument.from_json (this.reply.read_all (), error);
    //      var object = json.object ().to_variant_map ();
    //      var token = object["ocs"].to_map ()["data"].to_map ()["e2e-token"].to_byte_array ();
    //      GLib.info ("Got json: " + token);

    //      // TODO: Parse the token and submit.
    //      signal_success (this.file_identifier, token);
    //      return true;
    //  }

} // class LockEncryptFolderApiJob

} // namespace LibSync
} // namespace Occ
