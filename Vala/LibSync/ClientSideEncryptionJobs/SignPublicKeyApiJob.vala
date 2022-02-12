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
this.job.csr ( csr
connect (this.job.
this.job.on_signal_start
\encode

@ingroup libsync
***********************************************************/
class SignPublicKeyApiJob : AbstractNetworkJob {

    /***********************************************************
    @brief csr - the CSR with the public key.
    This function needs to be called before on_signal_start () obviously.
    ***********************************************************/
    Soup.Buffer csr {
        private get {
            return this.csr;
        }
        public set {
            GLib.ByteArray data = new GLib.ByteArray ("csr=");
            data += GLib.Uri.to_percent_encoding (value);
            this.csr.data (data);
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
    public SignPublicKeyApiJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public new void on_signal_start () {
        Soup.Request request;
        request.raw_header ("OCS-APIREQUEST", "true");
        request.header (Soup.Request.ContentTypeHeader, "application/x-www-form-urlencoded");
        QUrlQuery query;
        query.add_query_item ("format", "json");
        GLib.Uri url = Utility.concat_url_path (account ().url (), path ());
        url.query (query);

        GLib.info ("Sending the CSR " + this.csr.data ());
        send_request ("POST", url, request, this.csr);
        AbstractNetworkJob.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    protected bool on_signal_finished () {
        GLib.info ("Sending CSR ended with " + path () + error_string () + reply ().attribute (Soup.Request.HttpStatusCodeAttribute));

        QJsonParseError error;
        var json = QJsonDocument.from_json (reply ().read_all (), error);
        /* emit */ signal_json_received (json, reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ());
        return true;
    }

} // class SignPublicKeyApiJob

} // namespace Occ
