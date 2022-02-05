/***********************************************************
Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/

namespace Occ {

/***********************************************************
@brief Job to sigh the CSR that return JSON

To be
\code
this.job = new SignPubli
this.job.set_csr ( csr
connect (this.job.
this.job.on_start
\encode

@ingroup libsync
***********************************************************/
class SignPublicKeyApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public SignPublicKeyApiJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ());


    /***********************************************************
    @brief set_csr - the CSR with the public key.
    This function needs to be called before on_start () obviously.
    ***********************************************************/
    public void set_csr (GLib.ByteArray csr);


    /***********************************************************
    ***********************************************************/
    public void on_start () override;

    protected bool on_finished () override;


    /***********************************************************
    @brief json_received - signal to report the json answer from ocs
    @param json - the parsed json document
    @param status_code - the OCS status code : 100 (!) for on_success
    ***********************************************************/
    signal void json_received (QJsonDocument json, int status_code);


    /***********************************************************
    ***********************************************************/
    private Soup.Buffer this.csr;




    SignPublicKeyApiJob.SignPublicKeyApiJob (AccountPointer& account, string path, GLib.Object parent)
    : base (account, path, parent) {
    }

    void SignPublicKeyApiJob.set_csr (GLib.ByteArray csr) {
        GLib.ByteArray data = "csr=";
        data += GLib.Uri.to_percent_encoding (csr);
        this.csr.set_data (data);
    }

    void SignPublicKeyApiJob.on_start () {
        Soup.Request req;
        req.set_raw_header ("OCS-APIREQUEST", "true");
        req.set_header (Soup.Request.ContentTypeHeader, QByteArrayLiteral ("application/x-www-form-urlencoded"));
        QUrlQuery query;
        query.add_query_item (QLatin1String ("format"), QLatin1String ("json"));
        GLib.Uri url = Utility.concat_url_path (account ().url (), path ());
        url.set_query (query);

        GLib.info (lc_sign_public_key_api_job) << "Sending the CSR" << this.csr.data ();
        send_request ("POST", url, req, this.csr);
        AbstractNetworkJob.on_start ();
    }

    bool SignPublicKeyApiJob.on_finished () {
        GLib.info (lc_store_private_key_api_job ()) << "Sending CSR ended with"  << path () << error_string () << reply ().attribute (Soup.Request.HttpStatusCodeAttribute);

        QJsonParseError error;
        var json = QJsonDocument.from_json (reply ().read_all (), error);
        /* emit */ json_received (json, reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ());
        return true;
    }
}

} // namespace Occ
