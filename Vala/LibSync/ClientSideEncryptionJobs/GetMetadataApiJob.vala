/***********************************************************
Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/

namespace Occ {

class GetMetadataApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray file_identifier;


    signal void json_received (QJsonDocument json, int status_code);
    signal void error (GLib.ByteArray file_identifier, int http_return_code);


    /***********************************************************
    ***********************************************************/
    public GetMetadataApiJob (
        AccountPointer account,
        GLib.ByteArray file_identifier,
        GLib.Object parent = new GLib.Object ()) {

        base (account, e2ee_base_url () + "meta-data/" + file_identifier, parent)
        this.file_identifier = file_identifier;
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () override {
        Soup.Request req;
        req.set_raw_header ("OCS-APIREQUEST", "true");
        QUrlQuery query;
        query.add_query_item (QLatin1String ("format"), QLatin1String ("json"));
        GLib.Uri url = Utility.concat_url_path (account ().url (), path ());
        url.set_query (query);

        q_c_info (lc_cse_job ()) << "Requesting the metadata for the file_identifier" << this.file_identifier << "as encrypted";
        send_request ("GET", url, req);
        AbstractNetworkJob.on_start ();
    }


    protected bool on_finished () override {
        int return_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (return_code != 200) {
            q_c_info (lc_cse_job ()) << "error requesting the metadata" << path () << error_string () << return_code;
            /* emit */ error (this.file_identifier, return_code);
            return true;
        }
        QJsonParseError error;
        var json = QJsonDocument.from_json (reply ().read_all (), error);
        /* emit */ json_received (json, reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ());
        return true;
    }
}

} // namespace Occ
