namespace Occ {
namespace LibSync {

/***********************************************************
@class SignPublicKeyApiJob

@brief Job to sign the CSR that return JSON

Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.

To be
\code
this.job = new SignPubli
this.job.csr ( csr
this.job.connect (
this.job.start
\encode

@ingroup libsync
***********************************************************/
public class SignPublicKeyApiJob : AbstractNetworkJob {

    /***********************************************************
    @brief csr - the CSR with the public key.
    This function needs to be called before start () obviously.
    ***********************************************************/
    public Soup.Buffer csr {
        private get {
            return this.csr;
        }
        public set {
            string data = "csr=";
            data += GLib.Uri.to_percent_encoding (value);
            this.csr.data = data;
        }
    }


    /***********************************************************
    @brief signal_json_received - signal to report the json answer from ocs
    @param json - the parsed json document
    @param status_code - the OCS status code : 100 (!) for on_signal_success
    ***********************************************************/
    internal signal void signal_json_received (LibSync.JsonApiJob json_api_job, QJsonDocument json, int return_code);


    /***********************************************************
    ***********************************************************/
    public SignPublicKeyApiJob (Account account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        Soup.Request request = new Soup.Request ();
        request.raw_header ("OCS-APIREQUEST", "true");
        request.header (Soup.Request.ContentTypeHeader, "application/x-www-form-urlencoded");
        QUrlQuery query;
        query.add_query_item ("format", "json");
        GLib.Uri url = Utility.concat_url_path (account.url, this.path);
        url.query (query);

        GLib.info ("Sending the CSR " + this.csr.to_string ());
        send_request ("POST", url, request, this.csr);
        AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    protected bool on_signal_finished () {
        GLib.info ("Sending CSR ended with " + this.path + this.error_string + this.reply.attribute (Soup.Request.HttpStatusCodeAttribute));

        Json.ParserError error;
        var json = QJsonDocument.from_json (this.reply.read_all (), error);
        /* emit */ signal_json_received (this, json, this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ());
        return true;
    }

} // class SignPublicKeyApiJob

} // namespace LibSync
} // namespace Occ
