/***********************************************************
Here are all of the network jobs for the client side
encryption. Anything that goes through the server and
expects a response is here.
***********************************************************/

namespace Occ {

class LockEncryptFolderApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public LockEncryptFolderApiJob (AccountPointer account, GLib.ByteArray file_identifier, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public void on_start () override;

    protected bool on_finished () override;


    signal void success (GLib.ByteArray file_identifier, GLib.ByteArray token);
    signal void error (GLib.ByteArray file_identifier, int httpd_error_code);


    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray file_identifier;




    LockEncryptFolderApiJob.LockEncryptFolderApiJob (AccountPointer& account, GLib.ByteArray file_identifier, GLib.Object parent)
    : AbstractNetworkJob (account, e2ee_base_url () + QStringLiteral ("lock/") + file_identifier, parent), this.file_identifier (file_identifier) {
    }

    void LockEncryptFolderApiJob.on_start () {
        Soup.Request req;
        req.set_raw_header ("OCS-APIREQUEST", "true");
        QUrlQuery query;
        query.add_query_item (QLatin1String ("format"), QLatin1String ("json"));
        GLib.Uri url = Utility.concat_url_path (account ().url (), path ());
        url.set_query (query);

        q_c_info (lc_cse_job ()) << "locking the folder with id" << this.file_identifier << "as encrypted";
        send_request ("POST", url, req);
        AbstractNetworkJob.on_start ();
    }

    bool LockEncryptFolderApiJob.on_finished () {
        int return_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (return_code != 200) {
            q_c_info (lc_cse_job ()) << "error locking file" << path () << error_string () << return_code;
            /* emit */ error (this.file_identifier, return_code);
            return true;
        }

        QJsonParseError error;
        var json = QJsonDocument.from_json (reply ().read_all (), error);
        var obj = json.object ().to_variant_map ();
        var token = obj["ocs"].to_map ()["data"].to_map ()["e2e-token"].to_byte_array ();
        q_c_info (lc_cse_job ()) << "got json:" << token;

        //TODO : Parse the token and submit.
        /* emit */ success (this.file_identifier, token);
        return true;
    }
}

} // namespace Occ
