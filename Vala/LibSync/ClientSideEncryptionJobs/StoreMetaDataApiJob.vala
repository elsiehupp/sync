/***********************************************************
Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/

namespace Occ {

class StoreMetaDataApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray file_identifier;
    private GLib.ByteArray b64_metadata;


    signal void success (GLib.ByteArray file_identifier);
    signal void error (GLib.ByteArray file_identifier, int http_return_code);


    /***********************************************************
    ***********************************************************/
    public StoreMetaDataApiJob (
        AccountPointer account,
        GLib.ByteArray file_identifier,
        GLib.ByteArray b64_metadata,
        GLib.Object parent = new GLib.Object ()) {

        base (account, E2EE_BASE_URL + "meta-data/" + file_identifier, parent);
        this.file_identifier = file_identifier;
        this.b64_metadata = b64_metadata;
    }


    /***********************************************************
    ***********************************************************/
    public new void on_signal_start () {
        Soup.Request request;
        request.raw_header ("OCS-APIREQUEST", "true");
        request.header (Soup.Request.ContentTypeHeader, "application/x-www-form-urlencoded");
        QUrlQuery query;
        query.add_query_item (QLatin1String ("format"), QLatin1String ("json"));
        GLib.Uri url = Utility.concat_url_path (account ().url (), path ());
        url.query (query);

        GLib.ByteArray data = new GLib.ByteArray ("meta_data=") + GLib.Uri.to_percent_encoding (this.b64_metadata);
        var buffer = new Soup.Buffer (this);
        buffer.data (data);

        GLib.info ("Sending the metadata for the file_identifier " + this.file_identifier + " as encrypted.");
        send_request ("POST", url, request, buffer);
        AbstractNetworkJob.on_signal_start ();
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

} // namespace Occ
