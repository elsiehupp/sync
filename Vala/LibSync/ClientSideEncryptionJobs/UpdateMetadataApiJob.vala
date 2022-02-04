/***********************************************************
Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/

namespace Occ {

class UpdateMetadataApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray file_identifier;
    private GLib.ByteArray this.b64_metadata;
    private GLib.ByteArray token;


    signal void success (GLib.ByteArray file_identifier);
    signal void error (GLib.ByteArray file_identifier, int http_return_code);


    /***********************************************************
    ***********************************************************/
    public UpdateMetadataApiJob (
        AccountPointer account,
        GLib.ByteArray file_identifier,
        GLib.ByteArray b64_metadata,
        GLib.ByteArray locked_token,
        GLib.Object parent = new GLib.Object ()) {
        
        base (account, E2EE_BASE_URL + "meta-data/" + file_identifier, parent)
        this.file_identifier = file_identifier;
        this.b64_metadata = b64_metadata;
        this.token = token;
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () override {
        Soup.Request req;
        req.set_raw_header ("OCS-APIREQUEST", "true");
        req.set_header (Soup.Request.ContentTypeHeader, QByteArrayLiteral ("application/x-www-form-urlencoded"));

        QUrlQuery url_query;
        url_query.add_query_item (QStringLiteral ("format"), QStringLiteral ("json"));
        url_query.add_query_item (QStringLiteral ("e2e-token"), this.token);

        GLib.Uri url = Utility.concat_url_path (account ().url (), path ());
        url.set_query (url_query);

        QUrlQuery parameters;
        parameters.add_query_item ("meta_data",GLib.Uri.to_percent_encoding (this.b64_metadata));
        parameters.add_query_item ("e2e-token", this.token);

        GLib.ByteArray data = parameters.query ().to_local8Bit ();
        var buffer = new Soup.Buffer (this);
        buffer.set_data (data);

        GLib.Info (lc_cse_job ()) << "updating the metadata for the file_identifier" << this.file_identifier << "as encrypted";
        send_request ("PUT", url, req, buffer);
        AbstractNetworkJob.on_start ();
    }


    protected bool on_finished () override {
        int return_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
            if (return_code != 200) {
                GLib.Info (lc_cse_job ()) << "error updating the metadata" << path () << error_string () << return_code;
                emit error (this.file_identifier, return_code);
            }

            GLib.Info (lc_cse_job ()) << "Metadata submited to the server successfully";
            emit success (this.file_identifier);
        return true;
    }
}

} // namespace Occ
