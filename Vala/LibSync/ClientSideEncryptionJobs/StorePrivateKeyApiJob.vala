/***********************************************************
Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/

namespace Occ {

/***********************************************************
@brief Job to upload the PrivateKey that return JSON

To be
\code
this.job = new StorePrivateKeyApiJob
this.job.private_key
connect (this.job.
this.job.on_signal_start
\encode

@ingroup libsync
***********************************************************/
class StorePrivateKeyApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public StorePrivateKeyApiJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ());


    /***********************************************************
    @brief csr - the CSR with the public key.
    This function needs to be called before on_signal_start () obviously.
    ***********************************************************/
    public void private_key (GLib.ByteArray private_key);


    /***********************************************************
    ***********************************************************/
    public void on_signal_start ();

    protected bool on_signal_finished ();


    /***********************************************************
    @brief json_received - signal to report the json answer from ocs
    @param json - the parsed json document
    @param status_code - the OCS status code : 100 (!) for on_signal_success
    ***********************************************************/
    signal void json_received (QJsonDocument json, int status_code);


    /***********************************************************
    ***********************************************************/
    private Soup.Buffer this.priv_key;



    StorePrivateKeyApiJob.StorePrivateKeyApiJob (AccountPointer& account, string path, GLib.Object parent)
    : base (account, path, parent) {
    }

    void StorePrivateKeyApiJob.private_key (GLib.ByteArray priv_key) {
        GLib.ByteArray data = "private_key=";
        data += GLib.Uri.to_percent_encoding (priv_key);
        this.priv_key.data (data);
    }

    void StorePrivateKeyApiJob.on_signal_start () {
        Soup.Request reques;
        reques.raw_header ("OCS-APIREQUEST", "true");
        QUrlQuery query;
        query.add_query_item (QLatin1String ("format"), QLatin1String ("json"));
        GLib.Uri url = Utility.concat_url_path (account ().url (), path ());
        url.query (query);

        GLib.info ("Sending the private key" + this.priv_key.data ();
        send_request ("POST", url, reques, this.priv_key);
        AbstractNetworkJob.on_signal_start ();
    }

    bool StorePrivateKeyApiJob.on_signal_finished () {
        int return_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (return_code != 200)
            GLib.info ("Sending private key ended with"  + path () + error_string () + return_code;

        QJsonParseError error;
        var json = QJsonDocument.from_json (reply ().read_all (), error);
        /* emit */ json_received (json, reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ());
        return true;
    }

}

} // namespace Occ
