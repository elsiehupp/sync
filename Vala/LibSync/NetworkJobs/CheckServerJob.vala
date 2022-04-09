namespace Occ {
namespace LibSync {

/***********************************************************
@class CheckServerJob

@brief The CheckServerJob class

@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class CheckServerJob : AbstractNetworkJob {

    const string STATUS_PHP_C = "status.php";
    const string NEXTCLOUD_DIR_C = "nextcloud/";


    /***********************************************************
    ***********************************************************/
    private bool subdir_fallback;


    /***********************************************************
    The permanent-redirect adjusted account url.

    Note that temporary redirects or a permanent redirect behind a temporary
    one do not affect this url.
    ***********************************************************/
    private GLib.Uri server_url;


    /***********************************************************
    Keep track of how many permanent redirect were applied.
    ***********************************************************/
    private int permanent_redirects;


    /***********************************************************
    Emitted when a status.php was successfully read.

    \a url see this.server_status_url (does not include "/status.php")
    \a info The status.php input_stream information
    ***********************************************************/
    internal signal void instance_found (GLib.Uri url, Json.Object info);


    /***********************************************************
    Emitted on invalid status.php input_stream.

    \a input_stream is never null
    ***********************************************************/
    internal signal void instance_not_found (GLib.InputStream input_stream);


    /***********************************************************
    A timeout occurred.

    \a url The specific url where the timeout happened.
    ***********************************************************/
    internal signal void timeout (GLib.Uri url);



    /***********************************************************
    ***********************************************************/
    public CheckServerJob.for_account (Account account, GLib.Object parent = new GLib.Object ()) {
        base (account, STATUS_PHP_C, parent);
        this.subdir_fallback = false;
        this.permanent_redirects = 0;
        this.ignore_credential_failure = true;
        this.signal_redirected.connect (
            this.on_signal_redirected
        );
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        this.server_url = account.url;
        send_request ("GET", Utility.concat_url_path (this.server_url, this.path));
        this.input_stream.meta_data_changed.connect (
            this.on_signal_metadata_changed
        );
        this.input_stream.encrypted.connect (
            this, CheckServerJob.on_signal_encrypted
        );
        AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    public new void on_signal_timed_out () {
        GLib.warning ("TIMEOUT");
        if (this.input_stream != null && this.input_stream.is_running ()) {
            /* emit */ timeout (this.input_stream.url);
        } else if (this.input_stream == null) {
            GLib.warning ("Timeout even there was no input_stream?");
        }
        delete_later ();
    }


    /***********************************************************
    ***********************************************************/
    public string version (Json.Object info) {
        return info.value ("version").to_string ();
    }


    /***********************************************************
    ***********************************************************/
    public static string version_string (Json.Object info) {
        return info.value ("versionstring").to_string ();
    }


    /***********************************************************
    ***********************************************************/
    public static bool installed (Json.Object info) {
        return info.value ("installed").to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_finished () {
        if (this.input_stream.request ().url.scheme () == "https"
            && this.input_stream.ssl_configuration ().session_ticket () == ""
            && this.input_stream.error == GLib.InputStream.NoError) {
            GLib.warning ("No SSL session identifier / session ticket is used, this might impact sync performance negatively.");
        }

        merge_ssl_configuration_for_ssl_button (this.input_stream.ssl_configuration (), account);

        // The server installs to /owncloud. Let's try that if the file wasn't found
        // at the original location
        if ((this.input_stream.error == GLib.InputStream.ContentNotFoundError) && (!this.subdir_fallback)) {
            this.subdir_fallback = true;
            this.path = NEXTCLOUD_DIR_C + STATUS_PHP_C;
            this.start ();
            GLib.info ("Retrying with " + this.input_stream.url);
            return false;
        }

        string body = this.input_stream.peek (4 * 1024);
        int http_status = this.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (body == "" || http_status != 200) {
            GLib.warning ("Error: status.php replied " + http_status + body);
            /* emit */ instance_not_found (this.input_stream);
        } else {
            Json.ParserError error;
            var status = GLib.JsonDocument.from_json (body, error);
            // empty or invalid response
            if (error.error != Json.ParserError.NoError || status == null) {
                GLib.warning ("status.php from server is not valid JSON!" + body + this.input_stream.request ().url + error.error_string);
            }

            GLib.info ("status.php returns: " + status + " " + this.input_stream.error + " Reply: " + this.input_stream);
            if (status.object ().contains ("installed")) {
                /* emit */ instance_found (this.server_url, status.object ());
            } else {
                GLib.warning ("No proper answer on " + this.input_stream.url);
                /* emit */ instance_not_found (this.input_stream);
            }
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_metadata_changed () {
        this.account.ssl_configuration = this.input_stream.ssl_configuration ();
        merge_ssl_configuration_for_ssl_button (this.input_stream.ssl_configuration (), account);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_encrypted () {
        merge_ssl_configuration_for_ssl_button (this.input_stream.ssl_configuration (), account);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_redirected (GLib.InputStream input_stream, GLib.Uri target_url, int redirect_count) {
        string slash_status_php = "/" + STATUS_PHP_C;

        int http_code = input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        string path = target_url.path;
        if ( (http_code == 301 || http_code == 308) // permanent redirection
            && redirect_count == this.permanent_redirects // don't apply permanent redirects after a temporary one
            && path.has_suffix (slash_status_php)) {
            this.server_url = target_url;
            this.server_url.path (path.left (path.size () - slash_status_php.size ()));
            GLib.info (
                "status.php was permanently redirected to "
                + target_url.to_string () + " new server url is " + this.server_url.to_string ());
            ++this.permanent_redirects;
        }
    }


    private static void merge_ssl_configuration_for_ssl_button (GLib.SslConfiguration config, Account account) {
        if (config.peer_certificate_chain ().length > 0) {
            account.peer_certificate_chain = config.peer_certificate_chain ();
        }
        if (!config.session_cipher () == null) {
            account.session_cipher = config.session_cipher ();
        }
        if (config.session_ticket ().length > 0) {
            account.session_ticket = config.session_ticket ();
        }
    }

} // class CheckServerJob

} // namespace LibSync
} // namespace Occ
