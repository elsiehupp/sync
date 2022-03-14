/***********************************************************
Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/

namespace Occ {
namespace LibSync {

public class StoreMetaDataApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    private string file_identifier;
    private string b64_metadata;


    signal void success (string file_identifier);
    signal void error (string file_identifier, int http_return_code);


    /***********************************************************
    ***********************************************************/
    public StoreMetaDataApiJob (
        unowned Account account,
        string file_identifier,
        string b64_metadata,
        GLib.Object parent = new GLib.Object ()) {

        base (account, E2EE_BASE_URL + "meta-data/" + file_identifier, parent);
        this.file_identifier = file_identifier;
        this.b64_metadata = b64_metadata;
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        Soup.Request request;
        request.raw_header ("OCS-APIREQUEST", "true");
        request.header (Soup.Request.ContentTypeHeader, "application/x-www-form-urlencoded");
        QUrlQuery query;
        query.add_query_item ("format", "json");
        GLib.Uri url = Utility.concat_url_path (account ().url (), path ());
        url.query (query);

        string data = "meta_data=" + GLib.Uri.to_percent_encoding (this.b64_metadata);
        var buffer = new Soup.Buffer (this);
        buffer.data (data);

        GLib.info ("Sending the metadata for the file_identifier " + this.file_identifier + " as encrypted.");
        send_request ("POST", url, request, buffer);
        AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    protected bool on_signal_finished () {
        int return_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
            if (return_code != 200) {
                GLib.info ("Error sending the metadata " + path () + error_string () + return_code);
                /* emit */ error (this.file_identifier, return_code);
            }

            GLib.info ("Metadata submited to the server successfully");
            /* emit */ success (this.file_identifier);
        return true;
    }

} // class StoreMetaDataApiJob

} // namespace LibSync
} // namespace Occ
