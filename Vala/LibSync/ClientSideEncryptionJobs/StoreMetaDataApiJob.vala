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
    private GLib.ByteArray this.b64_metadata;


    signal void success (GLib.ByteArray file_identifier);
    signal void error (GLib.ByteArray file_identifier, int http_return_code);


    /***********************************************************
    ***********************************************************/
    public StoreMetaDataApiJob (
        AccountPointer account,
        GLib.ByteArray file_identifier,
        GLib.ByteArray b64_metadata,
        GLib.Object parent = new GLib.Object ()) {

        base (account, e2ee_base_url () + "meta-data/" + file_identifier, parent)
        this.file_identifier = file_identifier;
        this.b64_metadata = b64_metadata;
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () override {
        Soup.Request req;
        req.set_raw_header ("OCS-APIREQUEST", "true");
        req.set_header (Soup.Request.ContentTypeHeader, QByteArrayLiteral ("application/x-www-form-urlencoded"));
        QUrlQuery query;
        query.add_query_item (QLatin1String ("format"), QLatin1String ("json"));
        GLib.Uri url = Utility.concat_url_path (account ().url (), path ());
        url.set_query (query);

        GLib.ByteArray data = GLib.ByteArray ("meta_data=") + GLib.Uri.to_percent_encoding (this.b64_metadata);
        var buffer = new Soup.Buffer (this);
        buffer.set_data (data);

        q_c_info (lc_cse_job ()) << "sending the metadata for the file_identifier" << this.file_identifier << "as encrypted";
        send_request ("POST", url, req, buffer);
        AbstractNetworkJob.on_start ();
    }


    /***********************************************************
    ***********************************************************/
    protected bool on_finished () override {
        int return_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
            if (return_code != 200) {
                q_c_info (lc_cse_job ()) << "error sending the metadata" << path () << error_string () << return_code;
                emit error (this.file_identifier, return_code);
            }

            q_c_info (lc_cse_job ()) << "Metadata submited to the server successfully";
            emit success (this.file_identifier);
        return true;
    }
}

} // namespace Occ
