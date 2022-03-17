/***********************************************************
Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/

namespace Occ {
namespace LibSync {

public class GetMetadataApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    private string file_identifier;


    internal signal void signal_json_received (QJsonDocument json, int return_code);
    internal signal void singal_error (string file_identifier, int http_return_code);


    /***********************************************************
    ***********************************************************/
    public GetMetadataApiJob (
        Account account,
        string file_identifier,
        GLib.Object parent = new GLib.Object ()) {

        base (account, E2EE_BASE_URL + "meta-data/" + file_identifier, parent);
        this.file_identifier = file_identifier;
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        Soup.Request request = new Soup.Request ();
        request.raw_header ("OCS-APIREQUEST", "true");
        QUrlQuery query;
        query.add_query_item ("format", "json");
        GLib.Uri url = Utility.concat_url_path (account.url (), path ());
        url.query (query);

        GLib.info ("Requesting the metadata for the file_identifier " + this.file_identifier + " as encrypted.");
        send_request ("GET", url, request);
        AbstractNetworkJob.start ();
    }


    protected bool on_signal_finished () {
        int return_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (return_code != 200) {
            GLib.info ("Error requesting the metadata " + path () + error_string () + return_code);
            /* emit */ error (this.file_identifier, return_code);
            return true;
        }
        QJsonParseError error;
        var json = QJsonDocument.from_json (reply ().read_all (), error);
        /* emit */ signal_json_received (json, reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ());
        return true;
    }

} // class GetMetadataApiJob

} // namespace LibSync
} // namespace Occ
