/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief The CheckServerJob class
@ingroup libsync
***********************************************************/
class CheckServerJob : AbstractNetworkJob {

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
    signal void instance_found (GLib.Uri url, QJsonObject info);


    /***********************************************************
    Emitted on invalid status.php reply.

    \a reply is never null
    ***********************************************************/
    signal void instance_not_found (Soup.Reply reply);


    /***********************************************************
    A timeout occurred.

    \a url The specific url where the timeout happened.
    ***********************************************************/
    signal void timeout (GLib.Uri url);



    /***********************************************************
    ***********************************************************/
    public CheckServerJob.for_account (AccountPointer account, GLib.Object parent = new GLib.Object ()) {
        base (account, QLatin1String (STATUS_PHP_C), parent);
        this.subdir_fallback = false;
        this.permanent_redirects = 0;
        ignore_credential_failure (true);
        connect (this, AbstractNetworkJob.redirected,
            this, CheckServerJob.on_signal_redirected);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        this.server_url = account ().url ();
        send_request ("GET", Utility.concat_url_path (this.server_url, path ()));
        connect (reply (), Soup.Reply.meta_data_changed, this, CheckServerJob.meta_data_changed_slot);
        connect (reply (), Soup.Reply.encrypted, this, CheckServerJob.on_signal_encrypted);
        AbstractNetworkJob.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_timed_out () {
        GLib.warning ("TIMEOUT";
        if (reply () && reply ().is_running ()) {
            /* emit */ timeout (reply ().url ());
        } else if (!reply ()) {
            GLib.warning ("Timeout even there was no reply?";
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
        if (reply ().request ().url ().scheme () == QLatin1String ("https")
            && reply ().ssl_configuration ().session_ticket ().is_empty ()
            && reply ().error () == Soup.Reply.NoError) {
            GLib.warning ("No SSL session identifier / session ticket is used, this might impact sync performance negatively.";
        }

        merge_ssl_configuration_for_ssl_button (reply ().ssl_configuration (), account ());

        // The server installs to /owncloud. Let's try that if the file wasn't found
        // at the original location
        if ( (reply ().error () == Soup.Reply.ContentNotFoundError) && (!this.subdir_fallback)) {
            this.subdir_fallback = true;
            path (QLatin1String (NEXTCLOUD_DIR_C) + QLatin1String (STATUS_PHP_C));
            on_signal_start ();
            GLib.info ("Retrying with" + reply ().url ();
            return false;
        }

        GLib.ByteArray body = reply ().peek (4 * 1024);
        int http_status = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (body.is_empty () || http_status != 200) {
            GLib.warning ("error : status.php replied " + http_status + body;
            /* emit */ instance_not_found (reply ());
        } else {
            QJsonParseError error;
            var status = QJsonDocument.from_json (body, error);
            // empty or invalid response
            if (error.error != QJsonParseError.NoError || status.is_null ()) {
                GLib.warning ("status.php from server is not valid JSON!" + body + reply ().request ().url () + error.error_string ();
            }

            GLib.info ("status.php returns: " + status + " " + reply ().error (" Reply: " + reply ();
            if (status.object ().contains ("installed")) {
                /* emit */ instance_found (this.server_url, status.object ());
            } else {
                GLib.warning ("No proper answer on " + reply ().url ();
                /* emit */ instance_not_found (reply ());
            }
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    private on_ void meta_data_changed_slot () {
        account ().ssl_configuration (reply ().ssl_configuration ());
        merge_ssl_configuration_for_ssl_button (reply ().ssl_configuration (), account ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_encrypted () {
        merge_ssl_configuration_for_ssl_button (reply ().ssl_configuration (), account ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_redirected (Soup.Reply reply, GLib.Uri target_url, int redirect_count) {
        GLib.ByteArray slash_status_php ("/");
        slash_status_php.append (STATUS_PHP_C);

        int http_code = reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        string path = target_url.path ();
        if ( (http_code == 301 || http_code == 308) // permanent redirection
            && redirect_count == this.permanent_redirects // don't apply permanent redirects after a temporary one
            && path.has_suffix (slash_status_php)) {
            this.server_url = target_url;
            this.server_url.path (path.left (path.size () - slash_status_php.size ()));
            GLib.info ("status.php was permanently redirected to"
                                    + target_url + "new server url is" + this.server_url;
            ++this.permanent_redirects;
        }
    }


    private static void merge_ssl_configuration_for_ssl_button (QSslConfiguration config, AccountPointer account) {
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

} // namespace Occ
