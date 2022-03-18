/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The CheckServerJob class
@ingroup libsync
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
    \a info The status.php reply information
    ***********************************************************/
    internal signal void instance_found (GLib.Uri url, QJsonObject info);


    /***********************************************************
    Emitted on invalid status.php reply.

    \a reply is never null
    ***********************************************************/
    internal signal void instance_not_found (GLib.InputStream reply);


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
        ignore_credential_failure (true);
        connect (
            this, AbstractNetworkJob.redirected,
            this, CheckServerJob.on_signal_redirected
        );
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        this.server_url = account.url;
        send_request ("GET", Utility.concat_url_path (this.server_url, path ()));
        connect (
            this.reply, Soup.Reply.meta_data_changed,
            this, CheckServerJob.on_signal_metadata_changed
        );
        connect (
            this.reply, Soup.Reply.encrypted,
            this, CheckServerJob.on_signal_encrypted
        );
        AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    public new void on_signal_timed_out () {
        GLib.warning ("TIMEOUT");
        if (this.reply && this.reply.is_running ()) {
            /* emit */ timeout (this.reply.url);
        } else if (!this.reply) {
            GLib.warning ("Timeout even there was no reply?");
        }
        delete_later ();
    }


    /***********************************************************
    ***********************************************************/
    public string version (QJsonObject info) {
        return info.value ("version").to_string ();
    }


    /***********************************************************
    ***********************************************************/
    public static string version_string (QJsonObject info) {
        return info.value ("versionstring").to_string ();
    }


    /***********************************************************
    ***********************************************************/
    public static bool installed (QJsonObject info) {
        return info.value ("installed").to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_finished () {
        if (this.reply.request ().url.scheme () == "https"
            && this.reply.ssl_configuration ().session_ticket () == ""
            && this.reply.error () == Soup.Reply.NoError) {
            GLib.warning ("No SSL session identifier / session ticket is used, this might impact sync performance negatively.");
        }

        merge_ssl_configuration_for_ssl_button (this.reply.ssl_configuration (), account);

        // The server installs to /owncloud. Let's try that if the file wasn't found
        // at the original location
        if ((this.reply.error () == Soup.Reply.ContentNotFoundError) && (!this.subdir_fallback)) {
            this.subdir_fallback = true;
            path (NEXTCLOUD_DIR_C + STATUS_PHP_C);
            start ();
            GLib.info ("Retrying with " + this.reply.url);
            return false;
        }

        string body = this.reply.peek (4 * 1024);
        int http_status = this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (body == "" || http_status != 200) {
            GLib.warning ("Error: status.php replied " + http_status + body);
            /* emit */ instance_not_found (this.reply);
        } else {
            QJsonParseError error;
            var status = QJsonDocument.from_json (body, error);
            // empty or invalid response
            if (error.error != QJsonParseError.NoError || status.is_null ()) {
                GLib.warning ("status.php from server is not valid JSON!" + body + this.reply.request ().url + error.error_string ());
            }

            GLib.info ("status.php returns: " + status + " " + this.reply.error () + " Reply: " + this.reply);
            if (status.object ().contains ("installed")) {
                /* emit */ instance_found (this.server_url, status.object ());
            } else {
                GLib.warning ("No proper answer on " + this.reply.url);
                /* emit */ instance_not_found (this.reply);
            }
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_metadata_changed () {
        account.ssl_configuration (this.reply.ssl_configuration ());
        merge_ssl_configuration_for_ssl_button (this.reply.ssl_configuration (), account);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_encrypted () {
        merge_ssl_configuration_for_ssl_button (this.reply.ssl_configuration (), account);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_redirected (GLib.InputStream reply, GLib.Uri target_url, int redirect_count) {
        string slash_status_php = "/";
        slash_status_php.append (STATUS_PHP_C);

        int http_code = reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        string path = target_url.path ();
        if ( (http_code == 301 || http_code == 308) // permanent redirection
            && redirect_count == this.permanent_redirects // don't apply permanent redirects after a temporary one
            && path.has_suffix (slash_status_php)) {
            this.server_url = target_url;
            this.server_url.path (path.left (path.size () - slash_status_php.size ()));
            GLib.info (
                "status.php was permanently redirected to "
                + target_url + " new server url is " + this.server_url);
            ++this.permanent_redirects;
        }
    }


    private static void merge_ssl_configuration_for_ssl_button (QSslConfiguration config, Account account) {
        if (config.peer_certificate_chain ().length () > 0) {
            account.peer_certificate_chain = config.peer_certificate_chain ();
        }
        if (!config.session_cipher ().is_null ()) {
            account.session_cipher = config.session_cipher ();
        }
        if (config.session_ticket ().length () > 0) {
            account.session_ticket = config.session_ticket ();
        }
    }

} // class CheckServerJob

} // namespace LibSync
} // namespace Occ
