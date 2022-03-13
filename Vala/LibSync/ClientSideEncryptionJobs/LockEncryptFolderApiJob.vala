/***********************************************************
Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/

namespace Occ {
namespace LibSync {

public class LockEncryptFolderApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray file_identifier;

    signal void success (GLib.ByteArray file_identifier, GLib.ByteArray token);
    signal void error (GLib.ByteArray file_identifier, int httpd_error_code);

    /***********************************************************
    ***********************************************************/
    public LockEncryptFolderApiJob (unowned Account account, GLib.ByteArray file_identifier, GLib.Object parent = new GLib.Object ()) {
        base (account, E2EE_BASE_URL + "lock/" + file_identifier, parent);
        this.file_identifier = file_identifier;
    }

    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        Soup.Request request;
        request.raw_header ("OCS-APIREQUEST", "true");
        QUrlQuery query;
        query.add_query_item ("format", "json");
        GLib.Uri url = Utility.concat_url_path (account ().url (), path ());
        url.query (query);

        GLib.info ("Locking the folder with identifier " + this.file_identifier.to_string () + " as encrypted.");
        send_request ("POST", url, request);
        AbstractNetworkJob.on_signal_start ();
    }

    protected bool on_signal_finished () {
        int return_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (return_code != 200) {
            GLib.info ("Error locking file " + path () + error_string () + return_code);
            /* emit */ error (this.file_identifier, return_code);
            return true;
        }

        QJsonParseError error;
        var json = QJsonDocument.from_json (reply ().read_all (), error);
        var object = json.object ().to_variant_map ();
        var token = object["ocs"].to_map ()["data"].to_map ()["e2e-token"].to_byte_array ();
        GLib.info ("Got json: " + token);

        //TODO : Parse the token and submit.
        /* emit */ success (this.file_identifier, token);
        return true;
    }

} // class LockEncryptFolderApiJob

} // namespace LibSync
} // namespace Occ
