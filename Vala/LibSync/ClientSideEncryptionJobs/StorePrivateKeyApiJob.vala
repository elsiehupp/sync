/***********************************************************
Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief Job to upload the PrivateKey that return JSON

To be
\code
this.job = new StorePrivateKeyApiJob
this.job.private_key
this.job.connect (
this.job.start
\encode

@ingroup libsync
***********************************************************/
public class StorePrivateKeyApiJob : AbstractNetworkJob {

    /***********************************************************
    @brief csr - the CSR with the public key.
    This function needs to be called before start () obviously.
    ***********************************************************/
    Soup.Buffer private_key {
        private get {
            return this.private_key;
        }
        public set {
            string data = "private_key=";
            data += GLib.Uri.to_percent_encoding (value);
            this.private_key.data (data);
        }
    }


    /***********************************************************
    @brief signal_json_received - signal to report the json answer from ocs
    @param json - the parsed json document
    @param status_code - the OCS status code : 100 (!) for on_signal_success
    ***********************************************************/
    internal signal void signal_json_received (QJsonDocument json, int return_code);


    /***********************************************************
    ***********************************************************/
    public StorePrivateKeyApiJob (Account account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        Soup.Request request = new Soup.Request ();
        request.raw_header ("OCS-APIREQUEST", "true");
        QUrlQuery query;
        query.add_query_item ("format", "json");
        GLib.Uri url = Utility.concat_url_path (account.url, path ());
        url.query (query);

        GLib.info ("Sending the private key" + this.private_key);
        send_request ("POST", url, request, this.private_key);
        AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    protected bool on_signal_finished () {
        int return_code = this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (return_code != 200)
            GLib.info ("Sending private key ended with "  + path () + error_string () + return_code);

        QJsonParseError error;
        var json = QJsonDocument.from_json (this.reply.read_all (), error);
        /* emit */ signal_json_received (json, this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ());
        return true;
    }

} // class StorePrivateKeyApiJob

} // namespace LibSync
} // namespace Occ
