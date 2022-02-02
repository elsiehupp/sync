/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
@brief The CheckServerJob class
@ingroup libsync
***********************************************************/
class CheckServerJob : AbstractNetworkJob {

    const char statusphp_c[] = "status.php";
    const char nextcloud_dir_c[] = "nextcloud/";


    /***********************************************************
    ***********************************************************/
    private bool this.subdir_fallback;


    /***********************************************************
    The permanent-redirect adjusted account url.

    Note that temporary redirects or a permanent redirect behind a temporary
    one do not affect this url.
    ***********************************************************/
    private GLib.Uri this.server_url;


    /***********************************************************
    Keep track of how many permanent redirect were applied.
    ***********************************************************/
    private int this.permanent_redirects;


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
    public CheckServerJob (AccountPointer account, GLib.Object parent = new GLib.Object ()) {
        base (account, QLatin1String (statusphp_c), parent);
        this.subdir_fallback = false;
        this.permanent_redirects = 0;
        set_ignore_credential_failure (true);
        connect (this, &AbstractNetworkJob.redirected,
            this, &CheckServerJob.on_redirected);
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () {
        this.server_url = account ().url ();
        send_request ("GET", Utility.concat_url_path (this.server_url, path ()));
        connect (reply (), &Soup.Reply.meta_data_changed, this, &CheckServerJob.meta_data_changed_slot);
        connect (reply (), &Soup.Reply.encrypted, this, &CheckServerJob.encrypted_slot);
        AbstractNetworkJob.on_start ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_timed_out () {
        GLib.warn (lc_check_server_job) << "TIMEOUT";
        if (reply () && reply ().is_running ()) {
            /* emit */ timeout (reply ().url ());
        } else if (!reply ()) {
            GLib.warn (lc_check_server_job) << "Timeout even there was no reply?";
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
    private bool on_finished () override {
        if (reply ().request ().url ().scheme () == QLatin1String ("https")
            && reply ().ssl_configuration ().session_ticket ().is_empty ()
            && reply ().error () == Soup.Reply.NoError) {
            GLib.warn (lc_check_server_job) << "No SSL session identifier / session ticket is used, this might impact sync performance negatively.";
        }

        merge_ssl_configuration_for_ssl_button (reply ().ssl_configuration (), account ());

        // The server installs to /owncloud. Let's try that if the file wasn't found
        // at the original location
        if ( (reply ().error () == Soup.Reply.ContentNotFoundError) && (!this.subdir_fallback)) {
            this.subdir_fallback = true;
            set_path (QLatin1String (nextcloud_dir_c) + QLatin1String (statusphp_c));
            on_start ();
            q_c_info (lc_check_server_job) << "Retrying with" << reply ().url ();
            return false;
        }

        GLib.ByteArray body = reply ().peek (4 * 1024);
        int http_status = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (body.is_empty () || http_status != 200) {
            GLib.warn (lc_check_server_job) << "error : status.php replied " << http_status << body;
            /* emit */ instance_not_found (reply ());
        } else {
            QJsonParseError error;
            var status = QJsonDocument.from_json (body, error);
            // empty or invalid response
            if (error.error != QJsonParseError.NoError || status.is_null ()) {
                GLib.warn (lc_check_server_job) << "status.php from server is not valid JSON!" << body << reply ().request ().url () << error.error_string ();
            }

            q_c_info (lc_check_server_job) << "status.php returns : " << status << " " << reply ().error () << " Reply : " << reply ();
            if (status.object ().contains ("installed")) {
                /* emit */ instance_found (this.server_url, status.object ());
            } else {
                GLib.warn (lc_check_server_job) << "No proper answer on " << reply ().url ();
                /* emit */ instance_not_found (reply ());
            }
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    private on_ void meta_data_changed_slot () {
        account ().set_ssl_configuration (reply ().ssl_configuration ());
        merge_ssl_configuration_for_ssl_button (reply ().ssl_configuration (), account ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void encrypted_slot () {
        merge_ssl_configuration_for_ssl_button (reply ().ssl_configuration (), account ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_redirected (Soup.Reply reply, GLib.Uri target_url, int redirect_count) {
        GLib.ByteArray slash_status_php ("/");
        slash_status_php.append (statusphp_c);

        int http_code = reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        string path = target_url.path ();
        if ( (http_code == 301 || http_code == 308) // permanent redirection
            && redirect_count == this.permanent_redirects // don't apply permanent redirects after a temporary one
            && path.ends_with (slash_status_php)) {
            this.server_url = target_url;
            this.server_url.set_path (path.left (path.size () - slash_status_php.size ()));
            q_c_info (lc_check_server_job) << "status.php was permanently redirected to"
                                    << target_url << "new server url is" << this.server_url;
            ++this.permanent_redirects;
        }
    }


    private static void merge_ssl_configuration_for_ssl_button (QSslConfiguration config, AccountPointer account) {
        if (config.peer_certificate_chain ().length () > 0) {
            account._peer_certificate_chain = config.peer_certificate_chain ();
        }
        if (!config.session_cipher ().is_null ()) {
            account._session_cipher = config.session_cipher ();
        }
        if (config.session_ticket ().length () > 0) {
            account._session_ticket = config.session_ticket ();
        }
    }
}